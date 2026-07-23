from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from typing import List
import os
import json
from groq import Groq

router = APIRouter(prefix="/api/v1/tutor", tags=["Quiz"])

# Initialize Groq client (Make sure GROQ_API_KEY is set in your environment variables)
client = Groq(api_key=os.environ.get("GROQ_API_KEY"))

class QuizResponse(BaseModel):
    question: str
    options: List[str]
    answer: str
    explanation: str

@router.get("/random-quiz", response_model=QuizResponse)
def get_random_quiz():
    try:
        # Prompt Groq to generate a German grammar or vocabulary quiz in valid JSON format
        chat_completion = client.chat.completions.create(
            messages=[
                {
                    "role": "system",
                    "content": (
                        "You are an expert German language tutor. Generate a single, unique multiple-choice quiz challenge "
                        "for a student learning German. "
                        "You MUST respond with a strict JSON object containing exactly these keys: "
                        "\"question\" (string), \"options\" (array of 3 or 4 strings), "
                        "\"answer\" (string matching one of the options), and \"explanation\" (string explaining why). "
                        "Do not include any markdown formatting like ```json or extra text, just raw JSON."
                    ),
                },
                {
                    "role": "user",
                    "content": "Generate a new random German grammar or vocabulary quiz question.",
                }
            ],
            model="llama-3.3-70b-versatile", # Or "llama-3.1-8b-instant" for faster/lighter responses
            temperature=0.8, # Higher temperature ensures a wide variety of fresh questions each time
        )

        content = chat_completion.choices[0].message.content.strip()
        
        # Clean up potential markdown wrappers if the model outputs them anyway
        if content.startswith("```json"):
            content = content[7:]
        if content.endswith("```"):
            content = content[:-3]
        content = content.strip()

        quiz_data = json.loads(content)
        return quiz_data

    except Exception as e:
        # Fallback dictionary if API fails or rate-limits
        print(f"Groq API Error: {e}")
        return {
            "question": "Complete the sentence: ___ Apfel ist lecker.",
            "options": ["Der", "Die", "Das"],
            "answer": "Der",
            "explanation": "'Apfel' is a masculine noun, so it takes the article 'Der'."
        }