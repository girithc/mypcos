from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from typing import Dict, List, Any, Optional
from datetime import datetime
from app.utils.firebase import verify_firebase_and_get_user
from app.utils.supabase_client import supabase

router = APIRouter(prefix="/period-symptoms", tags=["period_symptoms"])

class PeriodSymptomsUpdateRequest(BaseModel):
    firebase_token: str
    period_id: int
    symptoms: Dict[str, bool]
    notes: Optional[str] = None

class PeriodSymptomsGetRequest(BaseModel):
    firebase_token: str
    period_id: int

@router.post("/update")
def update_period_symptoms(req: PeriodSymptomsUpdateRequest):
    user = verify_firebase_and_get_user(req.firebase_token)
    owner = supabase.table("periods").select("user_id").eq("id", req.period_id).limit(1).execute()
    if not owner.data or owner.data[0]["user_id"] != user["id"]:
        raise HTTPException(404, "Period not found")

    if req.notes is not None:
        supabase.table("periods").update({
            "notes":      req.notes,
            "updated_at": datetime.utcnow().isoformat()
        }).eq("id", req.period_id).execute()

    # clear existing
    supabase.table("period_symptoms").delete().eq("period_id", req.period_id).execute()

    to_insert = []
    for name, sel in req.symptoms.items():
        if not sel:
            continue
        s = supabase.table("symptoms").select("id").eq("name", name).execute()
        if s.data:
            sid = s.data[0]["id"]
        else:
            new = supabase.table("symptoms").insert({"name": name}).execute()
            if not new.data:
                raise HTTPException(500, f"Failed to create symptom '{name}'")
            sid = new.data[0]["id"]
        to_insert.append({"period_id": req.period_id, "symptom_id": sid, "severity": 1})

    if to_insert:
        supabase.table("period_symptoms").insert(to_insert).execute()

    return {"message": "Symptoms and notes updated", "inserted": len(to_insert)}

@router.post("/get")
def get_period_symptoms(req: PeriodSymptomsGetRequest):
    user = verify_firebase_and_get_user(req.firebase_token)
    per = supabase.table("periods").select("*").eq("id", req.period_id).limit(1).execute()
    if not per.data:
        raise HTTPException(404, "Period not found")
    period = per.data[0]
    if period["user_id"] != user["id"]:
        raise HTTPException(404, "Period not found")

    ps = supabase.table("period_symptoms").select("symptom_id","severity")\
        .eq("period_id", req.period_id).execute()
    rows = ps.data or []

    out = []
    if rows:
        ids = [r["symptom_id"] for r in rows]
        sy = supabase.table("symptoms").select("id","name").in_("id", ids).execute()
        name_map = {item["id"]: item["name"] for item in sy.data or []}
        for r in rows:
            out.append({"id": r["symptom_id"], "name": name_map.get(r["symptom_id"], "Unknown"), "severity": r["severity"]})

    return {"period": period, "symptoms": out}
