from fastapi import APIRouter, HTTPException
from pydantic import BaseModel

from app.utils.firebase import verify_firebase_and_get_user
from app.utils.supabase_client import supabase

router = APIRouter(prefix="/pcos-symptoms", tags=["pcos_symptoms"])




class SymptomAddRequest(BaseModel):
    firebase_token: str
    symptom_id: int


class MySymptomsRequest(BaseModel):
    firebase_token: str

@router.post("/get-all")
def get_all_symptoms(req: MySymptomsRequest):
    # 1) verify Firebase token → get user
    user = verify_firebase_and_get_user(req.firebase_token)

    # 2) fetch every symptom
    all_response = (
        supabase
        .table("pcos_symptoms")
        .select("*")
        .execute()
    )
    all_symptoms = all_response.data  # List of { "id": ..., "name": ... }

    # 3) fetch only this user’s symptoms
    user_response = (
        supabase
        .table("pcos_symptoms_user")
        .select("symptom_id, pcos_symptoms(name)")
        .eq("user_id", user["id"])
        .execute()
    )
    user_ids = {row["symptom_id"] for row in user_response.data}

    # 4) annotate each symptom with `added: true/false`
    annotated = [
        {
            **symptom,
            "added": symptom["id"] in user_ids
        }
        for symptom in all_symptoms
    ]

    # 5) return annotated list plus the raw my_symptoms if you still need them
    my_symptoms = [
        {"id": row["symptom_id"], "name": row.get("pcos_symptoms", {}).get("name", "")}
        for row in user_response.data
    ]

    return {
        "pcos_symptoms": annotated,
        "my_symptoms":   my_symptoms,
    }

@router.post("/add")
def add_symptom(req: SymptomAddRequest):
    user = verify_firebase_and_get_user(req.firebase_token)
    supabase.table("pcos_symptoms_user").insert({"user_id": user["id"], "symptom_id": req.symptom_id}).execute()
    return {"message": "Symptom added successfully"}



@router.post("/get-my-symptoms")
def get_my_symptoms(req: MySymptomsRequest):
    # 1) verify Firebase token → get your user record
    user = verify_firebase_and_get_user(req.firebase_token)

    # 2) pull from pcos_symptoms_user, selecting the FK + related name
    response = (
        supabase
        .table("pcos_symptoms_user")
        .select("symptom_id, pcos_symptoms(name)")
        .eq("user_id", user["id"])
        .execute()
    )

    # 4) flatten into a simple list
    my_symptoms = [
        {"id": row["symptom_id"], "name": row["pcos_symptoms"]["name"]}
        for row in response.data
    ]

    return {"my_symptoms": my_symptoms}

@router.post("/remove")
def remove_symptom(req: SymptomAddRequest):
    user = verify_firebase_and_get_user(req.firebase_token)
    supabase.table("pcos_symptoms_user").delete().eq("user_id", user["id"]).eq("symptom_id", req.symptom_id).execute()
    return {"message": "Symptom removed successfully"}

