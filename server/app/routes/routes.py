# app/routes/routes.py

from fastapi import APIRouter
from app.routes.users import router as users_router
from app.routes.chat_messages import router as chat_messages_router
from app.routes.rag import create_rag_router
from app.routes.period_calendar import router as period_calendar_router
from app.routes.period_symptoms import router as period_symptoms_router
from app.routes.chat_gpt import create_gpt_router
from app.routes.documents import router as documents_router
from app.routes.pcos_symptoms import router as pcos_symptoms_router
from app.routes.diet import router as diet_router
from app.routes.mood import router as mood_router
from app.routes.body_data import router as body_data_router

def create_router(rag_chain):
    router = APIRouter()

    # user/account management
    router.include_router(users_router)

    # simple CRUD for standalone chat_messages table
    router.include_router(chat_messages_router)

    # RAG endpoints (needs rag_chain injected)
    router.include_router(create_rag_router(rag_chain))
    router.include_router(create_gpt_router(rag_chain))    
    # period calendar endpoints
    router.include_router(period_calendar_router)

    # period symptoms endpoints
    router.include_router(period_symptoms_router)


    # document upload/get/edit/delete
    router.include_router(documents_router)

    router.include_router(pcos_symptoms_router)

    router.include_router(diet_router)

    router.include_router(mood_router)

    router.include_router(body_data_router)

    return router
