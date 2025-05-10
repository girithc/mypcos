from fastapi import APIRouter
from pydantic import BaseModel
from app.utils.supabase_client import supabase

from app.utils.firebase import verify_firebase_and_get_user


router = APIRouter(prefix= "/mood",tags=["mood"])

class MoodRequest(BaseModel):
    firebase_token: str
    mood: str

@router.post("/log-mood")
def log_mood(req: MoodRequest):
    # 1) verify Firebase token → get user
    user = verify_firebase_and_get_user(req.firebase_token)

    # 2) insert mood into database
    insert_response = (
        supabase
        .table("moods")
        .insert({"user_id": user["id"], "name": req.mood})
        .execute()
    )

    return {"message": "Mood logged successfully"}