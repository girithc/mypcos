import datetime
from fastapi import APIRouter, HTTPException
from app.models.user import AuthLoginRequest, AuthUser, User
from app.utils.firebase import verify_firebase_and_get_user
from app.utils.supabase_client import supabase

router = APIRouter(prefix="", tags=["users"])

def check_response(response):
    if response.status_code != 200:
        raise HTTPException(status_code=response.status_code, detail=response.data)
    return response

@router.get("/users", response_model=list[User])
def get_users():
    resp = supabase.table("user_account").select("*").execute()
    if resp.data is None:
        raise HTTPException(500, "Error fetching users")
    return resp.data

@router.post("/users/me", response_model=User)
def get_current_user(auth_req: AuthLoginRequest):
    return verify_firebase_and_get_user(auth_req.firebase_token)

@router.post("/auth-login", response_model=AuthUser)
def auth_login(auth_req: AuthLoginRequest):
    from firebase_admin import auth
    try:
        decoded_token = auth.verify_id_token(auth_req.firebase_token)
        uid = decoded_token.get("uid")
        if not uid:
            raise HTTPException(status_code=401, detail="Invalid Firebase token")
    except Exception:
        raise HTTPException(status_code=401, detail="Invalid Firebase token")

    response = supabase.table("user_accounts").select("*").eq("uid", uid).execute()
    if response.data:
        return response.data[0]

    now = datetime.datetime.utcnow().isoformat()
    user_data = {"uid": uid, "email": auth_req.email, "created_at": now}
    insert_response = supabase.table("user_accounts").insert(user_data).execute()
    if insert_response.data is None:
        raise HTTPException(status_code=500, detail="Error inserting user")
    return insert_response.data[0]

@router.put("/{user_id}", response_model=User)
def update_user(user_id: int, user: User):
    data = user.dict(exclude_unset=True)
    resp = supabase.table("user").update(data).eq("id", user_id).execute()
    check_response(resp)
    if not resp.data:
        raise HTTPException(404, "User not found")
    return resp.data[0]

@router.delete("/{user_id}")
def delete_user(user_id: int):
    resp = supabase.table("user").delete().eq("id", user_id).execute()
    check_response(resp)
    return {"detail": "User deleted successfully"}
