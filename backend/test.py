import os
from dotenv import load_dotenv
from groq import Groq

# Load environment variables from .env
load_dotenv()

# Initialize the Groq client
client = Groq(api_key=os.environ.get("GROQ_API_KEY"))

def test_llama_connection():
    print("Testing Groq Llama connection...")
    try:
        completion = client.chat.completions.create(
            model="llama-3.3-70b-versatile",
            messages=[
                {
                    "role": "system",
                    "content": "You are a helpful language tutor. Reply in one short sentence."
                },
                {
                    "role": "user",
                    "content": "Hallo! Wie geht es dir?"
                }
            ],
            temperature=0.7,
            max_tokens=100
        )
        print("Success! Llama Response:")
        print(completion.choices[0].message.content)
    except Exception as e:
        print(f"Error connecting to Llama: {e}")

if __name__ == "__main__":
    test_llama_connection()