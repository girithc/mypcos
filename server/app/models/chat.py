from typing import List, Optional
from pydantic import BaseModel


class ChatSendRequest(BaseModel):
            firebase_token: str
            message: str
    
class SourceDocument(BaseModel):
    page: str
    title: str
    source: str
    snippet: str

class ChatSendResponse(BaseModel):
    reply: str
    sources: List[SourceDocument]


class ChatGetRequest(BaseModel):
    firebase_token: str

class ChatMessage(BaseModel):
    id: Optional[int] = None
    user_id: int
    content: str

class ChatMessage2(BaseModel):
    id: int
    sender: str
    message: str
    created_at: str

class ChatGetResponse(BaseModel):
    messages: List[ChatMessage2]