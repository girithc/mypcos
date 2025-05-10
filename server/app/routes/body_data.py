from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from app.utils.firebase import verify_firebase_and_get_user
from app.utils.supabase_client import supabase

router = APIRouter(prefix="/body-data", tags=["body_data"])


# ----------------------------
# Request Models
# ----------------------------

class GetBodyDataRequest(BaseModel):
    firebase_token: str


class UpdateBodyDataRequest(BaseModel):
    firebase_token: str
    age: int
    height_cm: float
    weight_kg: float
    waist_in: float
    bmi: float


# ----------------------------
# Routes
# ----------------------------

@router.post("/get")
def get_body_data(req: GetBodyDataRequest):
    user = verify_firebase_and_get_user(req.firebase_token)
    user_id = user["id"]

    # First try to get the record without forcing .single()
    response = supabase.table("body_data_user").select("*").eq("user_id", user_id).limit(1).execute()

    # If no record exists, insert default
    if not response.data:
        supabase.table("body_data_user").insert({
            "user_id": user_id,
            "age": 0,
            "height_cm": 0,
            "weight_kg": 0,
            "waist_in": 0,
            "bmi": 0
        }).execute()

        # Fetch again
        response = supabase.table("body_data_user").select("*").eq("user_id", user_id).limit(1).execute()

    return {"body_data": response.data[0]}

@router.post("/update")
def update_body_data(req: UpdateBodyDataRequest):
    user = verify_firebase_and_get_user(req.firebase_token)
    user_id = user["id"]

    # Update all values
    update_response = supabase.table("body_data_user").update({
        "age": req.age,
        "height_cm": req.height_cm,
        "weight_kg": req.weight_kg,
        "waist_in": req.waist_in,
        "bmi": req.bmi
    }).eq("user_id", user_id).execute()

    # Return updated record
    updated_data = supabase.table("body_data_user").select("*").eq("user_id", user_id).single().execute()

    if updated_data.data is None:
        raise HTTPException(status_code=500, detail="Update failed.")

    return {"body_data": updated_data.data}