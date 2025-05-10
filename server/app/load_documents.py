import os
from typing import List
import pdfplumber
from pathlib import Path

from nltk.tokenize import sent_tokenize
import nltk

nltk.download('punkt')

class Document:
    def __init__(self, page_content: str, metadata: dict = None):
        self.page_content = page_content
        self.metadata = metadata or {}

def load_txt_file(file_path: str) -> str:
    with open(file_path, "r", encoding="utf-8") as f:
        return f.read()

def load_pdf_file(file_path: str) -> str:
    text = ""
    with pdfplumber.open(file_path) as pdf:
        for page in pdf.pages:
            text += page.extract_text() or ""
    return text

def chunk_text(text: str, chunk_size: int = 500, overlap: int = 100) -> List[str]:
    sentences = sent_tokenize(text)
    chunks = []
    current_chunk = ""

    for sentence in sentences:
        if len(current_chunk) + len(sentence) < chunk_size:
            current_chunk += " " + sentence
        else:
            chunks.append(current_chunk.strip())
            current_chunk = sentence

    if current_chunk:
        chunks.append(current_chunk.strip())

    # Add overlap
    final_chunks = []
    for i in range(0, len(chunks)):
        combined = " ".join(chunks[max(0, i - 1):i + 1])
        final_chunks.append(combined)

    return final_chunks

def load_and_split_documents(path="./docs") -> List[Document]:
    documents = []

    for root, _, files in os.walk(path):
        for file in files:
            ext = Path(file).suffix.lower()
            full_path = os.path.join(root, file)

            try:
                if ext == ".txt":
                    content = load_txt_file(full_path)
                elif ext == ".pdf":
                    content = load_pdf_file(full_path)
                else:
                    continue

                chunks = chunk_text(content)
                for chunk in chunks:
                    documents.append(Document(page_content=chunk, metadata={"source": full_path}))
            except Exception as e:
                print(f"⚠️ Failed to load {full_path}: {e}")

    print(f"✅ Loaded {len(documents)} chunks.")
    return documents
