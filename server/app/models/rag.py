from pydantic import BaseModel


class AskRequest(BaseModel):
    q: str
    firebase_token: str
