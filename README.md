# AI Language Tutor

An intelligent, full-stack language tutoring application built with **FastAPI**, **Flutter**, **Supabase**, and integrated AI capabilities.

## 🚀 Project Architecture

* **Backend (`/backend`)**: Python FastAPI server handling API routing, database models, and AI/Groq integrations.
* **Frontend (`/frontend`)**: Cross-platform Flutter application supporting mobile and web interfaces.
* **Database & Auth**: Supabase handles user authentication, session management, and relational data storage.

---

## 🛠️ Getting Started Locally

### Prerequisites
* Python 3.10+
* Flutter SDK
* Supabase Account / Project

### 1. Environment Setup
Create a single unified `.env` file at the root of your project workspace with the following keys:
```env
SUPABASE_URL=your_supabase_url
SUPABASE_ANON_KEY=your_supabase_anon_key
GROQ_API_KEY=your_groq_api_key