import os
from typing import Tuple, List
from sentence_transformers import SentenceTransformer
from qdrant_client import QdrantClient
from qdrant_client.http.models import PointStruct, ScoredPoint
from openai import OpenAI

from app.utils.text_processing import clean_text
from .load_documents import load_and_split_documents
from uuid import uuid4
from dotenv import load_dotenv

load_dotenv()

QDRANT_URL = os.getenv("QDRANT_URL")
QDRANT_API_KEY = os.getenv("QDRANT_API_KEY")
QDRANT_COLLECTION_NAME = "pcos"
OPENAI_API_KEY = os.getenv("OPENAI_API_KEY")

# Initialize OpenAI client
openai_client = OpenAI(api_key=OPENAI_API_KEY)

# Initialize embedding model
embedding_model = SentenceTransformer("sentence-transformers/all-MiniLM-L6-v2")

# Initialize Qdrant client
qdrant = QdrantClient(
    url=QDRANT_URL,
    api_key=QDRANT_API_KEY,
)

# ✅ Lightweight Document class
class Document:
    def __init__(self, page_content: str, metadata: dict = None):
        self.page_content = page_content
        self.metadata = metadata or {}

def embed(texts: List[str]) -> List[List[float]]:
    return embedding_model.encode(texts, convert_to_tensor=False).tolist()

def upsert_documents():
    print("📄 Loading and indexing documents...")
    documents = load_and_split_documents()
    texts = [doc.page_content for doc in documents]
    vectors = embed(texts)

    payloads = [{"text": doc.page_content, "metadata": doc.metadata} for doc in documents]
    points = [
        PointStruct(id=str(uuid4()), vector=vec, payload=payload)
        for vec, payload in zip(vectors, payloads)
    ]

    qdrant.recreate_collection(
        collection_name=QDRANT_COLLECTION_NAME,
        vectors_config={"size": len(vectors[0]), "distance": "Cosine"},
    )
    qdrant.upsert(collection_name=QDRANT_COLLECTION_NAME, points=points)
    print("✅ Indexing completed.")

def search_similar_docs(query: str, top_k=5) -> List[Tuple[float, Document]]:
    query_vec = embed([query])[0]
    results: List[ScoredPoint] = qdrant.search(
        collection_name=QDRANT_COLLECTION_NAME,
        query_vector=query_vec,
        limit=top_k,
        with_payload=True,
        with_vectors=False,
    )
    return [
        (hit.score, Document(
            page_content=hit.payload.get("text", ""),
            metadata=hit.payload.get("metadata", {})
        ))
        for hit in results
    ]

def generate_prompt(context: str, question: str, mode: str = "chat") -> str:
    if mode == "upload":
        return f"""
            You're a data-informed PCOS clinical assistant helping a user who has just uploaded lab results. Use the user's hormone and metabolic data alongside the research-based context below to make firm, medically-reasonable lifestyle recommendations.

            Avoid vague generalities like "eat healthy" or "reduce stress". Instead, be specific about *what to do, why it's needed*, and *how it addresses the abnormalities in the lab data*. Use evidence or mechanistic reasoning when possible. If values are missing or normal, you may omit them.

            Context:
            {context}

            Lab Report (JSON):
            {question}

            Give:
            1. Exercise plan
            2. Diet suggestions
            3. Supplement or medicine ideas (non-prescriptive, but clear and research-informed)
            4. Explain *why* each of those helps, grounded in the lab data above
                    """.strip()
    else:
        # fallback to chat mode
        return f"""
        You're a supportive and knowledgeable assistant, here to help users with questions related to PCOS and general health. 
        You’re conversational, friendly, and to-the-point — like a smart, caring friend who knows her stuff.

        Don’t repeat that you're an assistant, and don’t over-explain what PCOS is unless the user asks directly. 
        Stick to the facts in the context provided, and if something isn’t covered, it’s okay to say you’re not sure.

        Keep your answers clear, human, and warm — like you’re talking to someone you care about, not like you're reading from a script.

        Context:
        {context}

        User Question:
        {question}

        Answer:""".strip()

def setup_rag():
    collections = [col.name for col in qdrant.get_collections().collections]
    if QDRANT_COLLECTION_NAME not in collections:
        upsert_documents()

    def rag_chain_fn(query: str, mode: str = "chat", history: List[dict] = None) -> Tuple[str, List[Document]]:
        results = search_similar_docs(query)


        
        docs = [doc for _, doc in results]
        context = "\n\n".join(doc.page_content for doc in docs)

        prompt = generate_prompt(context, query, mode=mode)

        # Construct chat history
        messages = history[:] if history else []
        messages.append({"role": "user", "content": prompt})

        response = openai_client.chat.completions.create(
            model="gpt-4.1-nano",
            messages=messages,
            temperature=0.3,
        )
        raw_answer = response.choices[0].message.content
        answer = clean_text(raw_answer)
        return answer, docs

    return rag_chain_fn