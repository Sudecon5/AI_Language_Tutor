import os
import json
from groq import Groq
from app.config import settings

client = Groq(api_key=settings.GROQ_API_KEY)

def process_audio_tutor(audio_file_path: str, target_language: str = "German") -> dict:
    # Step 1: Transcribe audio using Groq Whisper
    with open(audio_file_path, "rb") as file:
        transcription = client.audio.transcriptions.create(
            file=(os.path.basename(audio_file_path), file.read()),
            model="whisper-large-v3-turbo",
            response_format="json"
        )
    
    # Handle response whether it returns an object or a dictionary
    user_text = transcription.text if hasattr(transcription, "text") else transcription.get("text", "")

    # Step 2: Send transcript to Groq Llama with structured tutor persona & flashcard generation
    system_prompt = (
        f"You are a friendly, patient, and expert {target_language} language tutor. "
        "Analyze the user's input text for any grammar, spelling, or vocabulary mistakes. "
        "You must respond ONLY with a raw JSON object containing these exact keys:\n"
        "1. 'reply': Your conversational response back to the user in {target_language}.\n"
        "2. 'correction': A clear explanation of any mistakes they made (in English), or 'None' if it was perfect.\n"
        "3. 'transcription': The exact text the user spoke.\n"
        "4. 'dashboard_meta': An object containing:\n"
        "   - 'theme': The core grammar topic category (e.g., 'Accusative Case', 'Vocabulary Builder', 'Prepositions', 'General Practice').\n"
        "   - 'challenge_word': A notable word or phrase the user struggled with, or null.\n"
        "5. 'flashcard': An object containing a curated flashcard for vocabulary practice (A1 to B1 level German words like Schatz, Feierabend, Wanderlust, etc.) with these sub-keys:\n"
        "   - 'word': The German vocabulary word.\n"
        "   - 'level': The CEFR level (e.g., 'A1', 'A2', or 'B1').\n"
        "   - 'definition': A concise English definition and brief usage note."
    )

    chat_completion = client.chat.completions.create(
        model="llama-3.3-70b-versatile",
        messages=[
            {"role": "system", "content": system_prompt},
            {"role": "user", "content": user_text},
        ],
        response_format={"type": "json_object"},
        temperature=0.3
    )

    raw_content = chat_completion.choices[0].message.content
    
    try:
        return json.loads(raw_content)
    except json.JSONDecodeError:
        clean_content = raw_content.replace("```json", "").replace("```", "").strip()
        return json.loads(clean_content)


# --- ADD THIS NEW FUNCTION FOR INFINITE FLASHCARDS ---
def generate_flashcard_via_groq(target_language: str = "German") -> dict:
    prompt = (
        f"Generate a useful and interesting {target_language} vocabulary word for an intermediate learner. "
        "You must respond ONLY with a raw JSON object containing these exact keys:\n"
        "1. 'word': The target language vocabulary word.\n"
        "2. 'level': The CEFR level (e.g., 'A1', 'A2', 'B1', 'B2').\n"
        "3. 'definition': A concise English definition and brief usage context."
    )

    chat_completion = client.chat.completions.create(
        model="llama-3.3-70b-versatile",
        messages=[
            {"role": "system", "content": "You are a helpful language learning assistant that outputs strictly structured JSON."},
            {"role": "user", "content": prompt},
        ],
        response_format={"type": "json_object"},
        temperature=0.7
    )

    raw_content = chat_completion.choices[0].message.content
    
    try:
        return json.loads(raw_content)
    except json.JSONDecodeError:
        clean_content = raw_content.replace("```json", "").replace("```", "").strip()
        return json.loads(clean_content)