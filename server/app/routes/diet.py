from typing import Dict, List
from fastapi import APIRouter
from pydantic import BaseModel

from app.utils.firebase import verify_firebase_and_get_user
from app.utils.supabase_client import supabase


router = APIRouter(prefix="/diet", tags=["diet"])

class DietChoice(BaseModel):
    firebase_token: str

@router.post("/get-diets")
def get_diets(req: DietChoice):
    # 1) verify Firebase token → get user ID
    user = verify_firebase_and_get_user(req.firebase_token)
    user_id = user["id"]

    # 2) fetch every diet option
    all_resp = (
        supabase
        .table("diet_choices")
        .select("*")
        .execute()
    )

    all_diets = all_resp.data  # e.g. [{"id":1, "name":"Keto"}, ...]

    # 3) fetch only this user’s diet choices
    user_resp = (
        supabase
        .table("diet_choices_user")
        .select("diet_id")
        .eq("user_id", user_id)
        .execute()
    )
    
    chosen_ids = {row["diet_id"] for row in user_resp.data}

    # 4) annotate each diet with added: true/false
    annotated = [
        { **diet, "added": diet["id"] in chosen_ids }
        for diet in all_diets
    ]

    # 5) return the full list with flags
    return {"diets": annotated}


class DietPrefItem(BaseModel):
    diet_id: int
    added:   bool

class UpdateDietRequest(BaseModel):
    firebase_token: str
    preferences:    List[DietPrefItem]


@router.post("/update")
def update_diets(req: UpdateDietRequest):
    # 1. verify user
    user = verify_firebase_and_get_user(req.firebase_token)
    user_id = user["id"]

    # 2. fetch current choices
    current_resp = (
        supabase
        .table("diet_choices_user")
        .select("diet_id")
        .eq("user_id", user_id)
        .execute()
    )
    
    current_ids = {row["diet_id"] for row in current_resp.data}

    # 3. build a map from the incoming list
    prefs_map: Dict[int, bool] = {
        item.diet_id: item.added for item in req.preferences
    }
    desired_ids = {did for did, added in prefs_map.items() if added}

    to_add    = desired_ids - current_ids
    to_remove = current_ids - desired_ids

    # 4. batch insert new choices
    if to_add:
        supabase.table("diet_choices_user") \
            .insert([{"user_id": user_id, "diet_id": did} for did in to_add]) \
            .execute()

    # 5. batch delete removed choices
    if to_remove:
        supabase.table("diet_choices_user") \
            .delete() \
            .eq("user_id", user_id) \
            .in_("diet_id", list(to_remove)) \
            .execute()

    return {
        "status":  "success",
        "added":   list(to_add),
        "removed": list(to_remove),
    }