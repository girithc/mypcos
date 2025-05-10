from fastapi import FastAPI
from dotenv import load_dotenv
import firebase_admin
from firebase_admin import credentials
from app.rag import setup_rag
from app.routes.routes import create_router  # 👈 updated to use router factory

# Initialize Firebase Admin
if not firebase_admin._apps:
    cred = credentials.Certificate("pcos-8baf9-firebase-adminsdk-fbsvc-8f2129d9ae.json")
    firebase_admin.initialize_app(cred)

# Load .env variables
load_dotenv()

# Initialize app
app = FastAPI()

# Initialize RAG pipeline once
rag_chain = setup_rag()

# Include router with rag_chain injected
app.include_router(create_router(rag_chain))