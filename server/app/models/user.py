
import datetime
from typing import Optional
from pydantic import BaseModel


class User(BaseModel):
    id: Optional[int] = None
    name: Optional[str] = None  # Allow name to be None.
    email: str


# Existing response model
class AuthUser(BaseModel):
    id: Optional[int] = None
    uid: str
    email: Optional[str] = None  # 👈 Allow null emails
    created_at: Optional[datetime.datetime] = None

class AuthLoginRequest(BaseModel):
    firebase_token: str
    email: Optional[str] = None  # 👈 Allows email to be null