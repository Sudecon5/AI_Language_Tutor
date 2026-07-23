from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
import uvicorn
from app.api.tutor import router as tutor_router
from app.api.quiz_router import router as quiz_router  # Adjusted relative import path for consistency

app = FastAPI(title="AI Language Tutor API")

# Enable CORS for Flutter Web / Local debugging
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include both routers
app.include_router(tutor_router)
app.include_router(quiz_router)

@app.get("/")
def read_root():
    return {"message": "Tutor API is running successfully!"}

if __name__ == "__main__":
    port = int(os.environ.get("PORT", 8000))
    uvicorn.run("main:app", host="0.0.0.0", port=port)