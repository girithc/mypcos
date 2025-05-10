"""
import datetime
import os
import tempfile
from typing import Dict, List, Any, Optional, Callable
import uuid
from fastapi import APIRouter, File, HTTPException, UploadFile
from pydantic import BaseModel, HttpUrl
from datetime import datetime, timedelta, date
from datetime import date
from firebase_admin import storage




from app.agents.health_report_agent import HealthReportAgent
from app.models.user import AuthLoginRequest, AuthUser, User
from app.rag import setup_rag
from app.utils.firebase import verify_firebase_and_get_user
from app.utils.supabase_client import supabase_client as supabase


# ---------------------
# Pydantic models
# ---------------------
class ChatMessage(BaseModel):
    id: Optional[int] = None
    user_id: int
    content: str

class AskRequest(BaseModel):
    q: str
    firebase_token: str


# ---------------------
# Create router with injected rag_chain
# ---------------------
def create_router(rag_chain: Callable[[str], Any]):
    router = APIRouter()

    def check_response(response):
        if response.status_code != 200:
            raise HTTPException(status_code=response.status_code, detail=response.data)
        return response

    # ---------------------
    # User Endpoints
    # ---------------------
    @router.get("/users", response_model=List[User])
    def get_users():
        response = supabase.table("user_account").select("*").execute()
        if response.data is None:
            raise HTTPException(status_code=500, detail="Error fetching users")
        return response.data

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

    @router.put("/users/{user_id}", response_model=User)
    def update_user(user_id: int, user: User):
        user_data = user.dict(exclude_unset=True)
        response = supabase.table("user").update(user_data).eq("id", user_id).execute()
        check_response(response)
        if not response.data:
            raise HTTPException(status_code=404, detail="User not found")
        return response.data[0]

    @router.delete("/users/{user_id}")
    def delete_user(user_id: int):
        response = supabase.table("user").delete().eq("id", user_id).execute()
        check_response(response)
        return {"detail": "User deleted successfully"}

    # ---------------------
    # Chat Message Endpoints
    # ---------------------
    @router.get("/chat_messages", response_model=List[ChatMessage])
    def get_chat_messages():
        response = supabase.table("chat_message").select("*").execute()
        check_response(response)
        return response.data

    @router.get("/chat_messages/{message_id}", response_model=ChatMessage)
    def get_chat_message(message_id: int):
        response = supabase.table("chat_message").select("*").eq("id", message_id).execute()
        check_response(response)
        if not response.data:
            raise HTTPException(status_code=404, detail="Chat message not found")
        return response.data[0]

    @router.post("/chat_messages", response_model=ChatMessage)
    def create_chat_message(message: ChatMessage):
        response = supabase.table("chat_message").insert(message.dict(exclude_unset=True)).execute()
        check_response(response)
        return response.data[0]

    @router.put("/chat_messages/{message_id}", response_model=ChatMessage)
    def update_chat_message(message_id: int, message: ChatMessage):
        response = supabase.table("chat_message").update(message.dict(exclude_unset=True)).eq("id", message_id).execute()
        check_response(response)
        if not response.data:
            raise HTTPException(status_code=404, detail="Chat message not found")
        return response.data[0]

    @router.delete("/chat_messages/{message_id}")
    def delete_chat_message(message_id: int):
        response = supabase.table("chat_message").delete().eq("id", message_id).execute()
        check_response(response)
        return {"detail": "Chat message deleted successfully"}

    # ---------------------
    # PCOS GPT RAG Endpoints
    # ---------------------
    @router.post("/ask")
    def ask(request: AskRequest) -> Any:
        user = verify_firebase_and_get_user(request.firebase_token)
        answer, source_docs = rag_chain(request.q)
        print("Answer {answer} from {source_docs}")

        sources = []
        seen = set()
        for doc in source_docs:
            snippet = doc.page_content[:300].strip()
            meta = doc.metadata
            key = (meta.get("source"), meta.get("page", None))
            if key not in seen:
                seen.add(key)
                sources.append({
                    "page": meta.get("page", "N/A"),
                    "title": meta.get("title", "Online article" if meta.get("source") == "DuckDuckGo" else "Untitled"),
                    "source": meta.get("source", "Unknown"),
                    "snippet": snippet
                })

        return {
            "question": request.q,
            "answer": answer.strip(),
            "sources": sources
        }

    @router.get("/inspect")
    def inspect(q: str):
        answer, source_docs = rag_chain(q)
        return {
            "query": q,
            "source_documents": [doc.page_content[:300] for doc in source_docs]
        }
    
    # ---------------------
    # Period Calendar Endpoints
    # ---------------------

    class PeriodUpdateRequest(BaseModel):
        firebase_token: str
        month: int
        year: int
        period_dates: List[date]  # ← good

    @router.post("/period-calendar-update")
    def update_period_calendar(request: PeriodUpdateRequest):
        user = verify_firebase_and_get_user(request.firebase_token)
        user_id = user["id"]

        if not request.period_dates:
            raise HTTPException(status_code=400, detail="No period dates provided")

        # Calculate start and end dates
        start_date = min(request.period_dates).isoformat()
        end_date   = max(request.period_dates).isoformat()

        # Define month range
        month_start = date(request.year, request.month, 1)
        next_month_start = (
            date(request.year + 1, 1, 1)
            if request.month == 12
            else date(request.year, request.month + 1, 1)
        )

        now_iso = datetime.utcnow().isoformat()

        # Check for existing period entry
        existing = (
            supabase
            .table("periods")
            .select("*")
            .eq("user_id", user_id)
            .gte("start_date", month_start.isoformat())
            .lt("start_date", next_month_start.isoformat())
            .execute()
        )

        if existing.data:
            pid = existing.data[0]["id"]
            supabase.table("periods").update({
                "start_date":  start_date,
                "end_date":    end_date,
                "updated_at":  now_iso
            }).eq("id", pid).execute()

            return {
                "message": "Period updated",
                "period_id": pid
            }

        # Create new period entry
        insert = supabase.table("periods").insert({
            "user_id":     user_id,
            "start_date":  start_date,
            "end_date":    end_date,
            "created_at":  now_iso,
            "updated_at":  now_iso
        }).execute()

        if insert.data:
            return {
                "message": "Period created",
                "period_id": insert.data[0]["id"]
            }

        # Fallback error
        raise HTTPException(status_code=500, detail="Failed to create period")
    class PeriodGetRequest(BaseModel):
        firebase_token: str

    @router.post("/period-calendar-get")
    def get_period_calendar(request: PeriodGetRequest):
        user = verify_firebase_and_get_user(request.firebase_token)
        user_id = user["id"]

        today = datetime.utcnow().date()

        # Go back to the 1st day of the month 4 months ago
        first_day_this_month = today.replace(day=1)
        four_months_ago = first_day_this_month
        for _ in range(4):
            four_months_ago = (four_months_ago - timedelta(days=1)).replace(day=1)

        response = supabase.table("periods")\
            .select("*")\
            .eq("user_id", user_id)\
            .gte("start_date", four_months_ago.isoformat())\
            .order("start_date", desc=True)\
            .execute()

        return {"periods": response.data or []}
    
  

    class PeriodSymptomsUpdateRequest(BaseModel):
        firebase_token: str
        period_id: int
        symptoms: Dict[str, bool]
        notes: Optional[str] = None
        # e.g. { "Cramps": true, "Bloating": false, "Headache": true }


    @router.post("/period-symptoms-update")
    def update_period_symptoms(req: PeriodSymptomsUpdateRequest):
        # 0) Authenticate
        user = verify_firebase_and_get_user(req.firebase_token)
        user_id = user["id"]

        # 1) Verify ownership
        p_resp = (
            supabase.table("periods")
            .select("user_id")
            .eq("id", req.period_id)
            .limit(1)
            .execute()
        )
        if not p_resp.data or p_resp.data[0]["user_id"] != user_id:
            raise HTTPException(404, "Period not found")

        # 2) Optionally update the notes on the period itself
        if req.notes is not None:
            supabase.table("periods")\
                .update({
                    "notes":      req.notes,
                    "updated_at": datetime.utcnow().isoformat()
                })\
                .eq("id", req.period_id)\
                .execute()

        # 3) Clear existing symptoms
        supabase.table("period_symptoms")\
            .delete()\
            .eq("period_id", req.period_id)\
            .execute()

        # 4) Upsert each selected symptom
        to_insert = []
        for name, selected in req.symptoms.items():
            if not selected:
                continue

            # find or create symptom
            sym_resp = supabase.table("symptoms").select("id").eq("name", name).execute()
            if sym_resp.data:
                symptom_id = sym_resp.data[0]["id"]
            else:
                new_resp = supabase.table("symptoms").insert({"name": name}).execute()
                if not new_resp.data:
                    raise HTTPException(500, f"Failed to create symptom '{name}'")
                symptom_id = new_resp.data[0]["id"]

            to_insert.append({
                "period_id":  req.period_id,
                "symptom_id": symptom_id,
                "severity":   1
            })

        # 5) Bulk‐insert
        if to_insert:
            supabase.table("period_symptoms").insert(to_insert).execute()

        return {
            "message":  "Symptoms and notes updated",
            "inserted": len(to_insert)
        }   
    
    class PeriodSymptomsGetRequest(BaseModel):
            firebase_token: str
            period_id: int


    class SymptomOut(BaseModel):
        id: int
        name: str
        severity: int


    class PeriodOut(BaseModel):
        id: int
        user_id: int
        start_date: str
        end_date: str
        flow_level: Optional[str] = None
        pain_level: Optional[int] = None
        notes: Optional[str] = None
        created_at: str
        updated_at: str


    class PeriodSymptomsGetResponse(BaseModel):
        period: PeriodOut
        symptoms: List[SymptomOut]


    @router.post(
        "/period-symptoms-get",
        response_model=PeriodSymptomsGetResponse
    )
    def get_period_symptoms(req: PeriodSymptomsGetRequest):
        user = verify_firebase_and_get_user(req.firebase_token)

        # 1) Load the period record (limit(1) instead of .single())
        p_resp = (
            supabase
            .table("periods")
            .select("*")
            .eq("id", req.period_id)
            .limit(1)
            .execute()
        )

        if not p_resp.data:
            raise HTTPException(404, "Period not found with period_id")

        period = p_resp.data[0]

        # 2) Verify this period belongs to our authenticated user
        if period["user_id"] != user["id"]:
            raise HTTPException(
                    status_code=404,
                    detail={
                        "error": "Period not found",
                        "request_user_id": user["id"],
                        "period_owner_id": period["user_id"]
            }
    )
        # 3) Fetch all linked symptoms
        ps = (
            supabase
            .table("period_symptoms")
            .select("symptom_id", "severity")
            .eq("period_id", req.period_id)
            .execute()
        )
        rows = ps.data or []

        # 4) Batch‐fetch symptom names if any
        output: List[Dict[str, Any]] = []
        if rows:
            symptom_ids = [r["symptom_id"] for r in rows]
            sy = (
                supabase
                .table("symptoms")
                .select("id", "name")
                .in_("id", symptom_ids)
                .execute()
            )
            name_map = {item["id"]: item["name"] for item in (sy.data or [])}

            for r in rows:
                sid = r["symptom_id"]
                output.append({
                    "id":       sid,
                    "name":     name_map.get(sid, "Unknown"),
                    "severity": r["severity"],
                })

        # 5) Return both the period record and its symptoms
        return {
            "period":   period,
            "symptoms": output
        }
    
    
    class PeriodResetRequest(BaseModel):
        firebase_token: str
        month: int
        year: int

    @router.post("/period-calendar-reset")
    def reset_period_calendar(request: PeriodResetRequest):
        user = verify_firebase_and_get_user(request.firebase_token)
        user_id = user["id"]

        # Compute the first day of the month and the next month's start
        start_of_month = date(request.year, request.month, 1)
        next_month = (
            date(request.year + 1, 1, 1) if request.month == 12
            else date(request.year, request.month + 1, 1)
        )

        # 1. Find all periods within that month for the user
        periods_to_delete = supabase.table("periods")\
            .select("id")\
            .eq("user_id", user_id)\
            .gte("start_date", start_of_month.isoformat())\
            .lt("start_date", next_month.isoformat())\
            .execute()

        if not periods_to_delete.data:
            return {"message": "No period data to delete"}

        period_ids = [p["id"] for p in periods_to_delete.data]

        # 2. Delete linked symptoms
        supabase.table("period_symptoms")\
            .delete()\
            .in_("period_id", period_ids)\
            .execute()

        # 3. Delete the period records themselves
        supabase.table("periods")\
            .delete()\
            .in_("id", period_ids)\
            .execute()

        return {"message": "Period data reset successfully", "deleted": len(period_ids)}
        # ---- `/chat-send-message ----

    class ChatSendRequest(BaseModel):
        firebase_token: str
        message: str

    class SourceDocument(BaseModel):
        page: str
        title: str
        source: str
        snippet: str

    class ChatSendResponse(BaseModel):
        reply: str
        sources: List[SourceDocument]


    class ChatGetRequest(BaseModel):
        firebase_token: str

    class ChatMessage2(BaseModel):
        id: int
        sender: str
        message: str
        created_at: str

    class ChatGetResponse(BaseModel):
        messages: List[ChatMessage2]


    @router.post("/chat-send-message", response_model=ChatSendResponse)
    def chat_send_message(req: ChatSendRequest):
        user = verify_firebase_and_get_user(req.firebase_token)

        # 1. Store user message
        supabase.table("chat_messages").insert({
            "user_id": user["id"],
            "sender": "user",
            "message": req.message
        }).execute()

        # 2. Generate reply using RAG
        answer, source_docs = rag_chain(req.message)

        # 3. Store AI message
        supabase.table("chat_messages").insert({
            "user_id": user["id"],
            "sender": "ai",
            "message": answer.strip()
        }).execute()

        # 4. Build source metadata
        sources = []
        seen = set()
        for doc in source_docs:
            snippet = doc.page_content[:300].strip()
            meta = doc.metadata
            key = (meta.get("source"), meta.get("page"))
            if key not in seen:
                seen.add(key)
                sources.append({
                    "page": str(meta.get("page", "N/A")),  # 👈 Fix: cast to string
                    "title": meta.get(
                        "title",
                        "Online article" if meta.get("source") == "DuckDuckGo" else "Untitled"
                    ),
                    "source": meta.get("source", "Unknown"),
                    "snippet": snippet
                })

        return {
            "reply": answer.strip(),
            "sources": sources
        }
# ---- /chat-get-message ----

    @router.post("/chat-get-message", response_model=ChatGetResponse)
    def chat_get_message(req: ChatGetRequest):
        user = verify_firebase_and_get_user(req.firebase_token)

        response = (
            supabase
            .table("chat_messages")
            .select("*")
            .eq("user_id", user["id"])
            .order("id", desc=False)  # 👈 ascending order by id
            .limit(20)
            .execute()
        )

        messages = response.data or []

        return {
            "messages": [
                {
                    "id": msg["id"],
                    "sender": msg["sender"],
                    "message": msg["message"],
                    "created_at": msg["created_at"]
                } for msg in messages
            ]
        }


    agent = HealthReportAgent(rag_chain=rag_chain)
    class UploadDocumentRequest(BaseModel):
        firebase_token: str
        image_url: HttpUrl
        file_name: str

    @router.post("/upload-document")
    async def upload_document(payload: UploadDocumentRequest):
        try:
            user = verify_firebase_and_get_user(payload.firebase_token)
            user_id = user["id"]

            rag_output = {
                "summary": "This is a placeholder analysis output."
            }

            insert_result = supabase.table("medical_reports").insert({
                "user_id": user_id,
                "image_url": str(payload.image_url),
                "filename": payload.file_name,  # ⬅️ Use provided filename
                "rag_output": rag_output,
                "created_at": datetime.utcnow().isoformat()
            }).execute()

            if insert_result.data is None:
                raise HTTPException(status_code=500, detail=insert_result["error"]["message"])

            return {
                "message": "File metadata uploaded successfully.",
                "file_name": payload.file_name,
                "file_type": "image/jpeg",
                "file_url": payload.image_url
            }

        except Exception as e:
            print(f"Upload error: {e}")
            raise HTTPException(status_code=400, detail=str(e))
    class GetDocumentsRequest(BaseModel):
            firebase_token: str

    @router.post("/get-documents")
    async def get_documents(payload: GetDocumentsRequest):
        try:
            user = verify_firebase_and_get_user(payload.firebase_token)
            user_id = user["id"]

            # Fetch documents - this returns the data directly if successful
            data, count = supabase.table("medical_reports")\
                .select("id, filename, image_url, created_at")\
                .eq("user_id", user_id)\
                .order("created_at", desc=True)\
                .execute()
            
            return {"documents": data}

        except Exception as e:
            raise HTTPException(status_code=400, detail=str(e))


    class EditDocumentNameRequest(BaseModel):
        firebase_token: str
        document_id: int
        new_filename: str

    @router.post("/edit-document-name")
    async def edit_document_name(payload: EditDocumentNameRequest):
        try:
            # 1. Verify Firebase token
            user = verify_firebase_and_get_user(payload.firebase_token)
            user_id = user["id"]

            # 2. Update the filename
            update_data = {
                "filename": payload.new_filename,
                "updated_at": datetime.utcnow().isoformat()
            }

            # For supabase-py v2+
            data, count = supabase.table("medical_reports") \
                .update(update_data) \
                .eq("id", payload.document_id) \
                .eq("user_id", user_id) \
                .execute()

            # Check if any rows were actually updated
            if count == 0:
                raise HTTPException(
                    status_code=404,
                    detail="Document not found or you don't have permission to edit it"
                )

            return {"message": "Filename updated successfully"}

        except HTTPException:
            raise  # Re-raise HTTPException as-is
        except Exception as e:
            print(f"Error updating filename: {str(e)}")
            raise HTTPException(
                status_code=500,
                detail=str(e)
            )
        
    class DeleteDocumentRequest(BaseModel):
        firebase_token: str
        document_id: int

    @router.post("/delete-document")
    async def delete_document(payload: DeleteDocumentRequest):
        try:
            # 1. Verify the user
            user = verify_firebase_and_get_user(payload.firebase_token)
            user_id = user["id"]

            # 2. Attempt to delete the record
            data, count = supabase.table("medical_reports") \
                .delete() \
                .eq("user_id", user_id) \
                .eq("id", payload.document_id) \
                .execute()

            # Check if any rows were actually deleted
            if count == 0:
                raise HTTPException(
                    status_code=404,
                    detail="Document not found or you don't have permission to delete it"
                )

            return {"message": "Document deleted successfully."}

        except HTTPException:
            raise  # Re-raise existing HTTP exceptions
        except Exception as e:
            print(f"Delete error: {str(e)}")
            raise HTTPException(
                status_code=500,
                detail="Failed to delete document"
            )
    return router



    """