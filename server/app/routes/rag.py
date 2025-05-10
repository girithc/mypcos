from fastapi import APIRouter, HTTPException
from typing import Any, List, Dict
from app.models.rag import AskRequest
from app.utils.firebase import verify_firebase_and_get_user

router = APIRouter(tags=["rag"])

def create_rag_router(rag_chain):
    r = APIRouter(prefix="/rag")

    @r.post("/ask")
    def ask(req: AskRequest) -> Any:
        user = verify_firebase_and_get_user(req.firebase_token)
        answer, docs = rag_chain(req.q)

        sources = []
        seen = set()
        for d in docs:
            meta = d.metadata
            key = (meta.get("source"), meta.get("page"))
            if key in seen: continue
            seen.add(key)
            sources.append({
                "page": meta.get("page", "N/A"),
                "title": meta.get("title", "Online article"),
                "source": meta.get("source", "Unknown"),
                "snippet": d.page_content[:300].strip()
            })

        return {"question": req.q, "answer": answer.strip(), "sources": sources}

    @r.get("/inspect")
    def inspect(q: str):
        answer, docs = rag_chain(q)
        return {
            "query": q,
            "source_documents": [d.page_content[:300] for d in docs]
        }

    return r
