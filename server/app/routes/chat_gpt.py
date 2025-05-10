import re
from fastapi import APIRouter, HTTPException
from typing import List

import openai

from app.models.chat import (
    ChatSendRequest,
    ChatGetRequest,
    ChatSendResponse,
    ChatGetResponse,
    ChatMessage2,
    SourceDocument,
)
from app.utils.firebase import verify_firebase_and_get_user
from app.utils.supabase_client import supabase
from app.utils.text_processing import build_conversation_history, summarize_individual_message

# ── Patterns that signal “remember our prior chat” ────────────────────────────
_HISTORY_TRIGGERS = [
    r"\bremember\b",
    r"\bearlier\b",
    r"\blast time\b",
    r"\bpreviously\b",
    r"\bas I said\b",
    r"\byou told me\b",
    r"\bwe discussed\b",
    r"\brecall\b",
    r"\bcontext\b",
    r"\babove\b",
]

def needs_history(message: str) -> bool:
    text = message.lower()
    return any(re.search(pat, text) for pat in _HISTORY_TRIGGERS)


# ── Factory to create a router bound to your RAG chain ────────────────────────
def create_gpt_router(rag_chain) -> APIRouter:
    router = APIRouter(tags=["chat_interaction"])

    @router.post("/chat-send-message", response_model=ChatSendResponse)
    def chat_send(req: ChatSendRequest):
        user = verify_firebase_and_get_user(req.firebase_token)
        user_id = user["id"]

        # 1) Summarize & store the incoming user message
        usr_sum = summarize_individual_message(req.message)
        supabase.table("chat_messages").insert({
            "user_id": user_id,
            "sender": "user",
            "message": req.message,
            "summary": usr_sum
        }).execute()

        # 2) Only build history if user explicitly asks to “remember”
        if needs_history(req.message):
            print("User asked to remember prior chat.")
            history = build_conversation_history(user_id)
        else:
            print("User did not ask to remember prior chat.")
            history = [
                {
                    "role": "system",
                    "content": "You are a helpful AI assistant focused on PCOS & women's health."
                }
            ]

        # 3) Invoke your RAG chain with that history
        try:
            answer, docs = rag_chain(req.message, history=history)
        except Exception as e:
            raise HTTPException(status_code=500, detail=f"RAG chain error: {e}")

        # 4) Summarize & store AI reply
        ai_sum = summarize_individual_message(answer)
        supabase.table("chat_messages").insert({
            "user_id": user_id,
            "sender": "ai",
            "message": answer.strip(),
            "summary": ai_sum
        }).execute()

        # 5) Format any source documents
        sources, seen = [], set()
        for d in docs:
            m = d.metadata
            key = (m.get("source"), m.get("page"))
            if key in seen:
                continue
            seen.add(key)
            sources.append(SourceDocument(
                page=str(m.get("page", "N/A")),
                title=m.get("title", "Untitled"),
                source=m.get("source", "Unknown"),
                snippet=d.page_content[:300].strip()
            ))

        return ChatSendResponse(reply=answer.strip(), sources=sources)

    @router.post("/chat-get-message", response_model=ChatGetResponse)
    def chat_get(req: ChatGetRequest):
        user = verify_firebase_and_get_user(req.firebase_token)
        resp = (
            supabase.table("chat_messages")
            .select("*")
            .eq("user_id", user["id"])
            .order("id", desc=False)
            .limit(20)
            .execute()
        )
        msgs = [
            ChatMessage2(
                id=m["id"],
                sender=m["sender"],
                message=m["message"],
                created_at=m["created_at"]
            )
            for m in (resp.data or [])
        ]
        return ChatGetResponse(messages=msgs)

    return router