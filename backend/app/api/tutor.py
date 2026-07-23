from fastapi import APIRouter, UploadFile, File, Depends
from sqlalchemy.orm import Session
from app.database import SessionLocal, UserProgress, init_db
from app.services.groq_service import process_audio_tutor, generate_flashcard_via_groq
import shutil
import os

router = APIRouter(prefix="/api/v1/tutor", tags=["Tutor"])

# Initialize SQLite database tables on startup
init_db()

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

@router.post("/chat")
async def tutor_chat(file: UploadFile = File(...), db: Session = Depends(get_db)):
    # Save incoming audio file temporarily
    temp_file_path = f"temp_{file.filename}"
    with open(temp_file_path, "wb") as buffer:
        shutil.copyfileobj(file.file, buffer)
        
    try:
        # Call Groq service (which returns 'flashcard' and 'dashboard_meta')
        ai_response = process_audio_tutor(temp_file_path)
        
        dashboard_meta = ai_response.get("dashboard_meta", {})
        
        # Save progress record to DB including challenge word / flashcard info
        db_record = UserProgress(
            theme=dashboard_meta.get("theme", "General Practice"),
            mistake_description=ai_response.get("correction"),
            challenge_word=dashboard_meta.get("challenge_word"),
        )
        db.add(db_record)
        db.commit()
        
        return {"status": "success", "data": ai_response}
    finally:
        if os.path.exists(temp_file_path):
            os.remove(temp_file_path)

@router.get("/progress")
async def get_user_progress(db: Session = Depends(get_db)):
    records = db.query(UserProgress).all()
    
    # Grab the latest flashcard generated from Groq or provide a default fallback
    default_flashcard = {
        "word": "Feierabend",
        "level": "A2",
        "definition": "The end of the workday / evening relaxation."
    }
    
    return {
        "status": "success",
        "total_sessions": len(records),
        "flashcard": default_flashcard,
        "recent_mistakes": [
            {
                "theme": r.theme, 
                "correction": r.mistake_description
            } for r in records[-5:]
        ]
    }

# --- ADD THIS NEW ENDPOINT FOR INFINITE AI FLASHCARDS ---
@router.get("/random-flashcard")
async def get_random_flashcard():
    try:
        # Calls Groq to generate a brand new vocabulary card on demand
        flashcard_data = generate_flashcard_via_groq("German")
        return flashcard_data
    except Exception as e:
        # Fallback dictionary if API limits or errors occur
        return {
            "word": "Wanderlust",
            "level": "B1",
            "definition": "A strong desire to travel and explore the world."
        }