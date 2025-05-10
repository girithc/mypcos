from supabase import create_client, Client

SUPABASE_URL =    "https://itbezvuwkxkjvmwazicb.supabase.co"
SUPABASE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Iml0YmV6dnV3a3hranZtd2F6aWNiIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzI3ODk4NDIsImV4cCI6MjA0ODM2NTg0Mn0.TI1t_5chVA3x0vhMsbTWQPQIWZIoLnpz8-odSKSQ-C4"

supabase: Client = create_client(SUPABASE_URL, SUPABASE_KEY)
