from typing import List
import unicodedata
from ftfy import fix_text
import openai
from app.utils.supabase_client import supabase

def clean_text(text: str) -> str:
    # Step 1: Use ftfy to repair mojibake and bad encodings
    cleaned = fix_text(text)

    # Step 2: Normalize for good measure (helps with diacritics, etc.)
    cleaned = unicodedata.normalize("NFKC", cleaned)

    # Step 3: Final cleanups for any remaining weirdness (optional)
    cleaned = (
        cleaned.replace("�", "")  # Remove unrecognized characters
               .replace("Â", "")  # Fix leftover encoding artifact
    )

    return cleaned

def summarize_individual_message(message: str) -> str:
    if len(message.strip()) <= 0:
        return ""
    response = openai.chat.completions.create(
        model="gpt-4.1-nano",
        messages=[
            {"role": "system", "content": "Summarize this text concisely in under 20 words."},
            {"role": "user", "content": message}
        ],
        temperature=0.3,
        max_tokens=50
    )
    return response.choices[0].message.content.strip()


def build_conversation_history(user_id: str) -> List[dict]:
    # 1) Fetch up to 50 of the oldest-first messages
    resp = supabase.table("chat_messages")\
        .select("*")\
        .eq("user_id", user_id)\
        .order("id", desc=False)\
        .limit(50)\
        .execute()
    history = resp.data or []

    # 2) Group into “interactions” of (user_message, ai_message)
    interactions = []
    i = 0
    while i < len(history):
        u = history[i]  # candidate user message
        a = None
        # If next exists and is from AI, pair it
        if i + 1 < len(history) and history[i+1]["sender"] == "ai":
            a = history[i+1]
            i += 2
        else:
            i += 1
        # Only keep tuples where the first element is a user message
        if u["sender"] == "user":
            interactions.append((u, a))
        else:
            # (edge case) an AI message with no preceding user
            interactions.append((None, u))

    # 3) If 10 or fewer interactions (≤20 messages), return them all
    if len(interactions) <= 10:
        convo = []
        for u, a in interactions:
            if u:
                convo.append({"role": "user",      "content": u["message"]})
            if a:
                convo.append({"role": "assistant", "content": a["message"]})
        return convo

    # 4) Otherwise, split into “early” and “recent” interactions
    early_ints  = interactions[:-10]  # everything except the last 10 pairs
    recent_ints = interactions[-10:]  # exactly the last 10 pairs

    # 5) Build one combined summary from all early interactions’ summaries
    early_summaries = []
    for u, a in early_ints:
        if u and u.get("summary"):
            early_summaries.append(u["summary"])
        if a and a.get("summary"):
            early_summaries.append(a["summary"])
    combined = " ".join(early_summaries).strip()

    # 6) Start with a system message containing that combined summary
    conversation = [{
        "role": "system",
        "content": f"Summary of earlier conversation:\n{combined}"
    }]

    # 7) Append the last 10 interactions in full (i.e. 20 messages)
    for u, a in recent_ints:
        if u:
            conversation.append({"role": "user",      "content": u["message"]})
        if a:
            conversation.append({"role": "assistant", "content": a["message"]})

    return conversation
    

def is_pcos_query(text: str) -> bool:
    keywords = ["pcos", "polycystic", "ovary", "cycle", "hormone", "androgen"]
    lowered = text.lower()
    return any(k in lowered for k in keywords)
