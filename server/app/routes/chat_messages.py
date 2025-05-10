from fastapi import APIRouter, HTTPException
from typing import List
from app.models.chat import ChatMessage
from app.utils.supabase_client import supabase

router = APIRouter(prefix="/chat_messages", tags=["chat_messages"])

def check_response(resp):
    if resp.status_code != 200:
        raise HTTPException(resp.status_code, resp.data)
    return resp

@router.get("/", response_model=List[ChatMessage])
def list_messages():
    resp = supabase.table("chat_message").select("*").execute()
    check_response(resp)
    return resp.data or []

@router.get("/{message_id}", response_model=ChatMessage)
def get_message(message_id: int):
    resp = supabase.table("chat_message").select("*").eq("id", message_id).execute()
    check_response(resp)
    if not resp.data:
        raise HTTPException(404, "Chat message not found")
    return resp.data[0]

@router.post("/", response_model=ChatMessage)
def create_message(msg: ChatMessage):
    resp = supabase.table("chat_message").insert(msg.dict(exclude_unset=True)).execute()
    check_response(resp)
    return resp.data[0]

@router.put("/{message_id}", response_model=ChatMessage)
def update_message(message_id: int, msg: ChatMessage):
    resp = supabase.table("chat_message").update(msg.dict(exclude_unset=True)).eq("id", message_id).execute()
    check_response(resp)
    if not resp.data:
        raise HTTPException(404, "Chat message not found")
    return resp.data[0]

@router.delete("/{message_id}")
def delete_message(message_id: int):
    resp = supabase.table("chat_message").delete().eq("id", message_id).execute()
    check_response(resp)
    return {"detail": "Chat message deleted successfully"}
