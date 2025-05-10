from fastapi import HTTPException
from firebase_admin import auth
from app.utils.supabase_client import  supabase  # ✅ import your initialized client



def verify_firebase_and_get_user(firebase_token: str):
    try:
        decoded_token = auth.verify_id_token(firebase_token)
        uid = decoded_token.get("uid")
        if not uid:
            raise HTTPException(status_code=401, detail="UID not found in Firebase token")
    except Exception:
        raise HTTPException(status_code=401, detail="Invalid Firebase token")

    response = supabase.table("user_accounts").select("*").eq("uid", uid).execute()
    if not response.data:
        raise HTTPException(status_code=404, detail="User not found")
    
    return response.data[0]