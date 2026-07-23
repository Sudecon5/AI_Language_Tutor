import shutil
import os
from fastapi import APIRouter, UploadFile, File, HTTPException
from app.services.groq_service import process_audio_tutor

router = APIRouter(prefix="/api/v1/tutor", tags=["Tutor"])

@router.post("/chat")
async def chat_with_audio(file: UploadFile = File(...)):
    # Save incoming audio temporarily
    temp_audio_path = f"temp_{file.filename}"
    try:
        with open(temp_audio_path, "wb") as buffer:
            shutil.copyfileobj(file.file, buffer)
        
        # Process via Groq Whisper & Llama
        result = process_audio_tutor(temp_audio_path)
        return {"status": "success", "data": result}

    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
    
    finally:
        # Clean up temporary audio file
        if os.path.exists(temp_audio_path):
            os.remove(temp_audio_path)