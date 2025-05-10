from fastapi import APIRouter, HTTPException
from typing import List
from openai import APIError
from pydantic import BaseModel, HttpUrl
from datetime import datetime
from app.utils.firebase import verify_firebase_and_get_user
from app.utils.supabase_client import supabase

router = APIRouter(prefix="/documents", tags=["documents"])

class UploadDocumentRequest(BaseModel):
    firebase_token: str
    image_url: HttpUrl
    file_name: str

class GetDocumentsRequest(BaseModel):
    firebase_token: str

class EditDocumentNameRequest(BaseModel):
    firebase_token: str
    document_id: int
    new_filename: str

class DeleteDocumentRequest(BaseModel):
    firebase_token: str
    document_id: int

@router.post("/upload-document")
async def upload_document(payload: UploadDocumentRequest):
    user = verify_firebase_and_get_user(payload.firebase_token)
    now = datetime.utcnow().isoformat()

    insert = supabase.table("medical_reports").insert({
        "user_id": user["id"],
        "image_url": str(payload.image_url),
        "filename": payload.file_name,
        "rag_output": {"summary": "placeholder"},
        "created_at": now
    }).execute()

    if insert.data is None:
        raise HTTPException(500, "Error saving metadata")
    return {
        "message": "File metadata uploaded successfully",
        "file_name": payload.file_name,
        "file_url": payload.image_url
    }

@router.post("/get-documents")
async def get_documents(req: GetDocumentsRequest):
    # 1) Verify Firebase token → user record
    user = verify_firebase_and_get_user(req.firebase_token)

    # 2) Attempt to fetch rows; execute() will raise APIError on bad status
    try:
        resp = (
            supabase
            .table("medical_reports")
            .select("id, filename, image_url, created_at")
            .eq("user_id", user["id"])
            .order("created_at", desc=True)
            .execute()
        )
    except APIError as e:
        # e.message / str(e) contains PostgREST error info
        raise HTTPException(status_code=500, detail=f"Supabase error: {e}")    

    # 3) resp.data is a List[...] of your rows   [oai_citation:2‡Supabase](https://supabase.com/docs/reference/python/insert?utm_source=chatgpt.com)
    rows = resp.data or []

    # 4) Build the nested wrapper your Dart code expects
    nested = [None, rows]

    return {"documents": nested}

@router.post("/edit-document-name")
async def edit_name(req: EditDocumentNameRequest):
    user = verify_firebase_and_get_user(req.firebase_token)
    update = supabase.table("medical_reports").update({
        "filename": req.new_filename,
        "updated_at": datetime.utcnow().isoformat()
    }).eq("id", req.document_id).eq("user_id", user["id"]).execute()

    # supabase-py v2 returns (data, count)
    count = update.count if hasattr(update, "count") else (update.data and len(update.data))
    if not count:
        raise HTTPException(404, "Document not found or no permission")
    return {"message": "Filename updated successfully"}

@router.post("/delete-document")
async def delete_document(req: DeleteDocumentRequest):
    user = verify_firebase_and_get_user(req.firebase_token)
    delete = supabase.table("medical_reports")\
        .delete()\
        .eq("id", req.document_id)\
        .eq("user_id", user["id"])\
        .execute()
    count = delete.count if hasattr(delete, "count") else (delete.data and len(delete.data))
    if not count:
        raise HTTPException(404, "Document not found or no permission")
    return {"message": "Document deleted successfully"}
