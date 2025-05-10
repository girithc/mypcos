from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from typing import List
from datetime import date, datetime, timedelta
from app.utils.firebase import verify_firebase_and_get_user
from app.utils.supabase_client import supabase

router = APIRouter(prefix="/period-calendar", tags=["period_calendar"])

class PeriodUpdateRequest(BaseModel):
    firebase_token: str
    month: int
    year: int
    period_dates: List[date]

class PeriodGetRequest(BaseModel):
    firebase_token: str

@router.post("/update")
def update_period_calendar(req: PeriodUpdateRequest):
    user = verify_firebase_and_get_user(req.firebase_token)
    if not req.period_dates:
        raise HTTPException(400, "No period dates provided")

    start_iso = min(req.period_dates).isoformat()
    end_iso   = max(req.period_dates).isoformat()

    ms = date(req.year, req.month, 1)
    nm = date(req.year + 1 if req.month==12 else req.year,
              1 if req.month==12 else req.month+1, 1)
    now = datetime.utcnow().isoformat()

    existing = supabase.table("periods")\
        .select("*")\
        .eq("user_id", user["id"])\
        .gte("start_date", ms.isoformat())\
        .lt("start_date", nm.isoformat())\
        .execute()

    if existing.data:
        pid = existing.data[0]["id"]
        supabase.table("periods").update({
            "start_date": start_iso,
            "end_date":   end_iso,
            "updated_at": now
        }).eq("id", pid).execute()
        return {"message": "Period updated", "period_id": pid}

    ins = supabase.table("periods").insert({
        "user_id":    user["id"],
        "start_date": start_iso,
        "end_date":   end_iso,
        "created_at": now,
        "updated_at": now
    }).execute()

    if ins.data:
        return {"message": "Period created", "period_id": ins.data[0]["id"]}
    raise HTTPException(500, "Failed to create period")

@router.post("/get")
def get_period_calendar(req: PeriodGetRequest):
    user = verify_firebase_and_get_user(req.firebase_token)
    today = datetime.utcnow().date()
    first = today.replace(day=1)
    four_months_ago = first
    for _ in range(4):
        four_months_ago = (four_months_ago - timedelta(days=1)).replace(day=1)

    resp = supabase.table("periods")\
        .select("*")\
        .eq("user_id", user["id"])\
        .gte("start_date", four_months_ago.isoformat())\
        .order("start_date", desc=True)\
        .execute()

    return {"periods": resp.data or []}

@router.post("/reset")
class PeriodResetRequest(BaseModel):
    firebase_token: str
    month: int
    year: int

@router.post("/reset")
def reset_period_calendar(req: PeriodResetRequest):
    user = verify_firebase_and_get_user(req.firebase_token)
    start_of_month = date(req.year, req.month, 1)
    next_month = date(req.year + 1 if req.month==12 else req.year,
                      1 if req.month==12 else req.month+1, 1)

    to_del = supabase.table("periods")\
        .select("id")\
        .eq("user_id", user["id"])\
        .gte("start_date", start_of_month.isoformat())\
        .lt("start_date", next_month.isoformat())\
        .execute()

    if not to_del.data:
        return {"message": "No period data to delete"}

    ids = [p["id"] for p in to_del.data]
    supabase.table("period_symptoms").delete().in_("period_id", ids).execute()
    supabase.table("periods").delete().in_("id", ids).execute()
    return {"message": "Period data reset successfully", "deleted": len(ids)}
