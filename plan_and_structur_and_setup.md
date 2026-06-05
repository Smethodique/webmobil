# 📂 FMP Prep AI - Full Stack Project Structure
## Flutter Frontend + Django Backend Architecture

---

## 📁 Project Root Directory

```
fmp-prep-ai/
├── backend/                    # Django Backend
├── frontend/                   # Flutter Frontend
├── README.md
├── .gitignore
└── docker-compose.yml          # Optional: For containerization
```

---

## 🔙 BACKEND - Django REST API

### Directory Structure

```
backend/
├── manage.py
├── requirements.txt
├── .env.example
├── .gitignore
├── db.sqlite3                  # Local SQLite (development)
├── Dockerfile                  # Docker configuration
├── docker-compose.yml          # Docker compose for local dev
│
├── fmp_prep/                   # Main Django Project
│   ├── __init__.py
│   ├── settings.py             # Project settings
│   ├── urls.py                 # Main URL router
│   ├── asgi.py
│   ├── wsgi.py
│   └── settings/
│       ├── __init__.py
│       ├── base.py
│       ├── development.py
│       ├── production.py
│       └── test.py
│
├── apps/
│   ├── __init__.py
│   │
│   ├── accounts/               # User Authentication & Profiles
│   │   ├── migrations/
│   │   │   └── __init__.py
│   │   ├── __init__.py
│   │   ├── models.py           # CustomUser model
│   │   ├── serializers.py      # User serializers
│   │   ├── views.py            # Auth endpoints (register, login, profile)
│   │   ├── urls.py
│   │   ├── admin.py
│   │   └── tests.py
│   │
│   ├── questions/              # QCM Questions Management
│   │   ├── migrations/
│   │   │   └── __init__.py
│   │   ├── __init__.py
│   │   ├── models.py           # Question, Option, Subject, SubTopic models
│   │   ├── serializers.py      # Question/Option serializers
│   │   ├── views.py            # Question endpoints (CRUD, filtering)
│   │   ├── urls.py
│   │   ├── filters.py          # Filter questions by subject/difficulty
│   │   ├── admin.py
│   │   └── tests.py
│   │
│   ├── exams/                  # Exams/Concours Management
│   │   ├── migrations/
│   │   │   └── __init__.py
│   │   ├── __init__.py
│   │   ├── models.py           # Exam, ExamQuestion models
│   │   ├── serializers.py      # Exam serializers
│   │   ├── views.py            # Exam endpoints
│   │   ├── urls.py
│   │   ├── admin.py
│   │   └── tests.py
│   │
│   ├── submissions/            # Student Exam Submissions & Responses
│   │   ├── migrations/
│   │   │   └── __init__.py
│   │   ├── __init__.py
│   │   ├── models.py           # Submission, StudentAnswer models
│   │   ├── serializers.py      # Submission serializers
│   │   ├── views.py            # Submit answers, get results
│   │   ├── urls.py
│   │   ├── scoring.py          # Scoring logic
│   │   ├── admin.py
│   │   └── tests.py
│   │
│   ├── progress/               # Student Progress Tracking
│   │   ├── migrations/
│   │   │   └── __init__.py
│   │   ├── __init__.py
│   │   ├── models.py           # StudentProgress, TopicProgress models
│   │   ├── serializers.py      # Progress serializers
│   │   ├── views.py            # Progress endpoints
│   │   ├── urls.py
│   │   ├── calculations.py     # Taux de Progression formula
│   │   ├── admin.py
│   │   └── tests.py
│   │
│   ├── ai_explanations/        # AI-Powered Explanations & Cloning
│   │   ├── migrations/
│   │   │   └── __init__.py
│   │   ├── __init__.py
│   │   ├── models.py           # Explanation, ClonedQuestion models
│   │   ├── serializers.py      # Explanation serializers
│   │   ├── views.py            # Generate explanations & clones
│   │   ├── urls.py
│   │   ├── services/
│   │   │   ├── __init__.py
│   │   │   ├── anthropic_api.py    # Anthropic API integration
│   │   │   ├── question_generator.py  # AI question cloning logic
│   │   │   └── explanation_generator.py  # AI explanation logic
│   │   ├── admin.py
│   │   └── tests.py
│   │
│   └── common/                 # Shared Utilities & Helpers
│       ├── __init__.py
│       ├── models.py           # Abstract base models
│       ├── serializers.py      # Base serializers
│       ├── permissions.py      # Custom permission classes
│       ├── pagination.py       # Pagination configs
│       ├── exceptions.py       # Custom exceptions
│       ├── utils.py            # Helper functions
│       └── constants.py        # App-wide constants
│
├── static/
│   └── admin/                  # Static files
│
├── media/
│   └── questions/              # Question images/attachments
│
└── tests/                      # Integration & E2E tests
    ├── __init__.py
    ├── conftest.py            # Pytest configuration
    └── api_tests.py
```

### Key Django Models (models.py Structure)

```python
# accounts/models.py
- CustomUser (extends AbstractUser)
  - role (student/teacher/admin)
  - date_joined_cohort
  - is_verified

# questions/models.py
- Subject (Suites Numériques, Fonctions, etc.)
  - name
  - description
  - order
  
- SubTopic (TVI, Dérivabilité, etc.)
  - subject (FK)
  - name
  - description
  - difficulty_level
  
- Question
  - subject (FK)
  - sub_topic (FK)
  - question_text (TextField with math)
  - difficulty_level (ENUM: easy/medium/hard)
  - year (exam year)
  - source_exam
  - created_at
  
- Option
  - question (FK)
  - option_letter (A/B/C/D/E)
  - option_text
  - is_correct
  - explanation
  
# exams/models.py
- Exam
  - title (e.g., "FMP Casablanca 2017")
  - year
  - duration_minutes
  - total_questions
  - questions (M2M)
  - created_at

# submissions/models.py
- Submission
  - student (FK to CustomUser)
  - exam (FK to Exam)
  - started_at
  - submitted_at
  - score
  - accuracy_rate
  
- StudentAnswer
  - submission (FK)
  - question (FK)
  - selected_option (FK to Option)
  - is_correct (boolean)
  - time_spent_seconds
  - is_bookmarked
  
# progress/models.py
- StudentProgress
  - student (FK)
  - overall_taux
  - last_updated
  
- TopicProgress
  - student (FK)
  - sub_topic (FK)
  - taux_value (percentage)
  - correct_attempts (last 20)
  - average_time
  - last_updated

# ai_explanations/models.py
- Explanation
  - question (FK)
  - explanation_text
  - step_by_step_latex
  - concours_shortcuts
  - generated_by_ai (boolean)
  - created_at
  
- ClonedQuestion
  - original_question (FK)
  - cloned_question_text
  - student (FK)
  - generated_at
```

### Key API Endpoints Structure

```
/api/v1/
│
├── auth/
│   ├── POST   /register/                 # User registration
│   ├── POST   /login/                    # User login (JWT)
│   ├── POST   /logout/                   # User logout
│   ├── POST   /refresh-token/            # JWT refresh
│   └── GET    /profile/                  # Get current user profile
│
├── questions/
│   ├── GET    /subjects/                 # List all subjects
│   ├── GET    /subjects/{id}/            # Get subject with sub-topics
│   ├── GET    /questions/                # List questions (with filters)
│   ├── GET    /questions/{id}/           # Get single question
│   ├── GET    /questions/?subject=X&difficulty=medium
│   └── GET    /questions/{id}/options/   # Get all options for question
│
├── exams/
│   ├── GET    /exams/                    # List all exams
│   ├── GET    /exams/{id}/               # Get exam details
│   ├── GET    /exams/random-concours/    # Start random concours (20 QCM)
│   └── GET    /exams/{year}/questions/   # Get questions for exam year
│
├── submissions/
│   ├── POST   /submissions/               # Create new submission
│   ├── POST   /submissions/{id}/submit/   # Submit exam
│   ├── GET    /submissions/{id}/          # Get submission result
│   ├── POST   /submissions/{id}/answers/  # Submit individual answer
│   └── GET    /submissions/{id}/review/   # Get detailed review
│
├── progress/
│   ├── GET    /progress/dashboard/       # Get overall progress
│   ├── GET    /progress/topics/          # Get all topic progress
│   ├── GET    /progress/topics/{id}/     # Get specific topic progress
│   └── GET    /progress/stats/           # Get learning stats
│
└── ai/
    ├── POST   /explanations/             # Generate AI explanation
    ├── GET    /explanations/{question_id}/
    ├── POST   /clone-question/           # Generate cloned question
    ├── POST   /clone-question/{id}/answer/  # Submit clone answer
    └── POST   /shortcuts/                # Get FMP shortcuts for question
```

### requirements.txt

```
Django==4.2.13
djangorestframework==3.14.0
django-cors-headers==4.3.1
djangorestframework-simplejwt==5.3.2
django-filter==23.5
python-decouple==3.8
Pillow==10.1.0
celery==5.3.4
redis==5.0.1
anthropic==0.21.0
psycopg2-binary==2.9.9
gunicorn==21.2.0
pytest==7.4.3
pytest-django==4.7.0
```

---

## 🎯 FRONTEND - Flutter Mobile App

### Directory Structure

```
frontend/
├── pubspec.yaml                # Flutter dependencies
├── pubspec.lock
├── analysis_options.yaml       # Lint rules
├── .env.example
├── .gitignore
├── Dockerfile
│
├── android/
│   ├── app/
│   ├── gradle.properties
│   └── local.properties
│
├── ios/
│   ├── Runner/
│   └── Pods/
│
├── web/
│   ├── index.html
│   └── manifest.json
│
├── lib/
│   ├── main.dart               # App entry point
│   ├── config.dart             # App configuration
│   │
│   ├── constants/              # App-wide constants
│   │   ├── colors.dart         # Color palette (dark mode)
│   │   ├── strings.dart        # All string constants
│   │   ├── sizes.dart          # Spacing, padding, border radius
│   │   ├── durations.dart      # Animation durations
│   │   └── routes.dart         # Route names
│   │
│   ├── models/                 # Data Models & DTOs
│   │   ├── user/
│   │   │   ├── user_model.dart
│   │   │   └── user_response.dart
│   │   │
│   │   ├── question/
│   │   │   ├── question_model.dart
│   │   │   ├── option_model.dart
│   │   │   └── subject_model.dart
│   │   │
│   │   ├── exam/
│   │   │   ├── exam_model.dart
│   │   │   └── submission_model.dart
│   │   │
│   │   ├── progress/
│   │   │   ├── progress_model.dart
│   │   │   └── topic_progress_model.dart
│   │   │
│   │   ├── ai/
│   │   │   ├── explanation_model.dart
│   │   │   └── cloned_question_model.dart
│   │   │
│   │   └── response/
│   │       ├── api_response.dart
│   │       └── error_response.dart
│   │
│   ├── services/               # API & Business Logic
│   │   ├── api/
│   │   │   ├── api_client.dart         # HTTP client setup (Dio)
│   │   │   ├── api_endpoints.dart      # API URL endpoints
│   │   │   └── interceptors.dart       # Token interceptor
│   │   │
│   │   ├── auth_service.dart           # Authentication logic
│   │   ├── question_service.dart       # Question fetch & filtering
│   │   ├── exam_service.dart           # Exam operations
│   │   ├── submission_service.dart     # Submit answers
│   │   ├── progress_service.dart       # Fetch progress data
│   │   ├── ai_service.dart             # AI explanations & cloning
│   │   ├── local_storage_service.dart  # SharedPreferences wrapper
│   │   └── notification_service.dart   # Push notifications
│   │
│   ├── providers/              # State Management (Riverpod)
│   │   ├── auth_provider.dart          # Auth state
│   │   ├── question_provider.dart      # Questions & filters
│   │   ├── exam_provider.dart          # Current exam state
│   │   ├── submission_provider.dart    # Submission tracking
│   │   ├── progress_provider.dart      # Progress data
│   │   ├── ui_provider.dart            # UI state (theme, etc.)
│   │   └── cache_provider.dart         # Data caching
│   │
│   ├── screens/                # UI Screens
│   │   ├── splash/
│   │   │   ├── splash_screen.dart
│   │   │   └── splash_screen_notifier.dart
│   │   │
│   │   ├── auth/
│   │   │   ├── login_screen.dart
│   │   │   ├── register_screen.dart
│   │   │   ├── forgot_password_screen.dart
│   │   │   └── widgets/
│   │   │       ├── auth_form_field.dart
│   │   │       └── social_login_buttons.dart
│   │   │
│   │   ├── dashboard/
│   │   │   ├── dashboard_screen.dart
│   │   │   ├── dashboard_notifier.dart
│   │   │   └── widgets/
│   │   │       ├── progress_ring_card.dart
│   │   │       ├── subject_expansion_panel.dart
│   │   │       ├── quick_action_buttons.dart
│   │   │       └── topic_mastery_checklist.dart
│   │   │
│   │   ├── qcm/
│   │   │   ├── qcm_screen.dart          # Main QCM interface
│   │   │   ├── qcm_notifier.dart        # QCM state management
│   │   │   └── widgets/
│   │   │       ├── qcm_header.dart      # Progress bar + timer
│   │   │       ├── question_render.dart # KaTeX math renderer
│   │   │       ├── option_selector.dart # A-E option buttons
│   │   │       ├── chrono_widget.dart   # Countdown timer
│   │   │       ├── utility_panel.dart   # Bookmark & skip buttons
│   │   │       └── question_navigator.dart # Jump between Qs
│   │   │
│   │   ├── review/
│   │   │   ├── review_screen.dart       # Post-exam review
│   │   │   ├── review_notifier.dart
│   │   │   └── widgets/
│   │   │       ├── performance_card.dart
│   │   │       ├── question_feed.dart
│   │   │       ├── answer_card.dart
│   │   │       ├── action_buttons.dart
│   │   │       └── statistics_panel.dart
│   │   │
│   │   ├── ai_solver/
│   │   │   ├── ai_solver_screen.dart    # Bottom drawer
│   │   │   ├── ai_solver_notifier.dart
│   │   │   └── widgets/
│   │   │       ├── proof_accordion.dart
│   │   │       ├── step_by_step_section.dart
│   │   │       ├── shortcuts_section.dart
│   │   │       ├── voice_synthesis_button.dart
│   │   │       └── why_wrong_section.dart
│   │   │
│   │   ├── clone_generator/
│   │   │   ├── clone_screen.dart        # Infinite exercise generator
│   │   │   ├── clone_notifier.dart
│   │   │   └── widgets/
│   │   │       ├── cloned_question_card.dart
│   │   │       ├── clone_timer.dart
│   │   │       ├── validation_feedback.dart
│   │   │       └── action_buttons.dart
│   │   │
│   │   ├── profile/
│   │   │   ├── profile_screen.dart
│   │   │   └── widgets/
│   │   │       ├── profile_header.dart
│   │   │       └── settings_tiles.dart
│   │   │
│   │   ├── offline/
│   │   │   └── offline_screen.dart      # No internet screen
│   │   │
│   │   └── error/
│   │       └── error_screen.dart        # Error handling screen
│   │
│   ├── widgets/                # Reusable Widgets
│   │   ├── custom_appbar.dart
│   │   ├── custom_button.dart
│   │   ├── custom_card.dart
│   │   ├── loading_shimmer.dart
│   │   ├── empty_state.dart
│   │   ├── error_widget.dart
│   │   ├── math_formula_renderer.dart   # KaTeX wrapper
│   │   ├── progress_ring.dart           # Circular progress
│   │   ├── glassmorphic_card.dart       # Glassmorphism effect
│   │   └── animated_counter.dart        # Score animation
│   │
│   ├── utils/                  # Helper Functions & Extensions
│   │   ├── extensions.dart     # String, DateTime, etc. extensions
│   │   ├── validators.dart     # Form validation
│   │   ├── formatters.dart     # Number, time formatting
│   │   ├── logger.dart         # Logging utility
│   │   ├── date_time_utils.dart
│   │   ├── math_latex_helper.dart  # KaTeX helper
│   │   └── permission_handler.dart
│   │
│   ├── theme/                  # Theme & Styling
│   │   ├── app_theme.dart      # Dark theme configuration
│   │   ├── text_styles.dart    # Typography
│   │   └── theme_data.dart     # Material theme
│   │
│   ├── router/                 # Navigation & Routing
│   │   ├── app_router.dart     # GoRouter configuration
│   │   └── route_transitions.dart
│   │
│   └── generated/              # Auto-generated files (freezed, etc.)
│       ├── freezed_models.dart
│       └── json_serializable.dart
│
└── test/
    ├── widget_test.dart
    ├── unit/
    │   ├── models_test.dart
    │   ├── utils_test.dart
    │   └── formatters_test.dart
    ├── integration/
    │   └── app_flow_test.dart
    └── fixtures/
        └── sample_data.dart
```

### pubspec.yaml Dependencies

```yaml
dependencies:
  flutter:
    sdk: flutter
  
  # State Management
  riverpod: ^2.4.0
  flutter_riverpod: ^2.4.0
  
  # Networking
  dio: ^5.3.0
  retrofit: ^4.1.0
  
  # Local Storage
  shared_preferences: ^2.2.0
  hive: ^2.2.0
  
  # JSON Serialization
  json_serializable: ^6.7.0
  freezed_annotation: ^2.4.0
  
  # Math & LaTeX
  flutter_math_fork: ^0.7.0
  
  # UI & Animation
  flutter_animate: ^4.0.0
  shimmer: ^3.0.0
  lottie: ^2.6.0
  
  # JWT & Auth
  flutter_secure_storage: ^9.0.0
  jwt_decoder: ^2.0.0
  
  # HTTP Cache
  http_cache_manager: ^3.0.0
  
  # Navigation
  go_router: ^12.0.0
  
  # Text to Speech
  flutter_tts: ^8.1.0
  
  # Time/Date
  intl: ^0.19.0
  
  # PDF & File Handling
  pdf: ^3.10.0
  
  # Analytics
  firebase_analytics: ^10.4.0
  firebase_messaging: ^14.6.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^2.0.0
  build_runner: ^2.4.0
  freezed: ^2.4.0
  json_serializable: ^6.7.0
  riverpod_generator: ^2.3.0
  retrofit_generator: ^7.1.0
  test: ^1.24.0
  mockito: ^5.4.0
```

---

## 🔗 Integration Points

### Frontend → Backend Communication Flow

```
Flutter App
    ↓
[API Client - Dio]
    ↓
JWT Token Management
    ↓
Django REST API
    ↓
Django Views (CRUD)
    ↓
Database Models
    ↓
AI Services (Anthropic API)
    ↓
Response back to Flutter
    ↓
Riverpod State Update
    ↓
UI Rebuild
```

---

## 🚀 Deployment & DevOps

### Docker Setup

```dockerfile
# Django Dockerfile
FROM python:3.11-slim
WORKDIR /app
COPY requirements.txt .
RUN pip install -r requirements.txt
COPY . .
CMD ["gunicorn", "fmp_prep.wsgi:application", "--bind", "0.0.0.0:8000"]

# Flutter Build (Web)
FROM node:18 as build
COPY frontend/ .
RUN flutter build web --release

FROM nginx:alpine
COPY --from=build /app/build/web /usr/share/nginx/html
```

### docker-compose.yml Structure

```yaml
version: '3.8'
services:
  db:
    image: postgres:15-alpine
    volumes:
      - postgres_data:/var/lib/postgresql/data
    environment:
      POSTGRES_DB: fmp_prep_db
      POSTGRES_USER: fmp_user
      POSTGRES_PASSWORD: secure_password

  redis:
    image: redis:7-alpine
    ports:
      - "6379:6379"

  backend:
    build: ./backend
    command: >
      sh -c "python manage.py migrate &&
             python manage.py runserver 0.0.0.0:8000"
    volumes:
      - ./backend:/app
    ports:
      - "8000:8000"
    depends_on:
      - db
      - redis

  frontend:
    build: ./frontend
    ports:
      - "3000:3000"
    depends_on:
      - backend
```

---

## 📊 Database Schema (Overview)

```
Users
├── CustomUser (id, email, password_hash, role, date_joined)

Subjects & Topics
├── Subject (id, name, order)
├── SubTopic (id, subject_id, name, difficulty)

Questions
├── Question (id, subject_id, sub_topic_id, text, difficulty, year)
├── Option (id, question_id, letter, text, is_correct)

Exams
├── Exam (id, title, year, duration_minutes)
├── ExamQuestion (exam_id, question_id)

Student Data
├── Submission (id, student_id, exam_id, score, submitted_at)
├── StudentAnswer (id, submission_id, question_id, selected_option_id, time_spent)
├── StudentProgress (student_id, overall_taux, updated_at)
├── TopicProgress (student_id, sub_topic_id, taux_value)

AI & Explanations
├── Explanation (id, question_id, text, latex, shortcuts)
├── ClonedQuestion (id, original_q_id, student_id, cloned_text)
```

---

## 🔐 Environment Variables

### Backend (.env)

```
DEBUG=False
SECRET_KEY=your-secret-key-here
ALLOWED_HOSTS=localhost,127.0.0.1,yourdomain.com

# Database
DATABASE_URL=postgresql://user:password@localhost/fmp_prep_db

# JWT
JWT_SECRET=your-jwt-secret
JWT_ALGORITHM=HS256

# AI
ANTHROPIC_API_KEY=sk-...
ANTHROPIC_MODEL=claude-3-sonnet-20240229

# CORS
CORS_ALLOWED_ORIGINS=http://localhost:3000,https://yourdomain.com

# Email
EMAIL_HOST=smtp.gmail.com
EMAIL_HOST_USER=your-email@gmail.com
EMAIL_HOST_PASSWORD=your-app-password

# Redis
REDIS_URL=redis://localhost:6379/0
```

### Frontend (.env)

```
API_BASE_URL=http://localhost:8000/api/v1/
SOCKET_IO_URL=http://localhost:8000
APP_ENV=development
LOG_LEVEL=debug
```

---

## 📋 Git Structure

```
.gitignore (includes __pycache__, node_modules, .env, *.lock)
README.md
CONTRIBUTING.md
LICENSE
```

---

## 🏃 Quick Start Commands

### Backend Setup
```bash
cd backend
python -m venv venv
source venv/bin/activate  # Windows: venv\Scripts\activate
pip install -r requirements.txt
cp .env.example .env
python manage.py migrate
python manage.py createsuperuser
python manage.py runserver
```

### Frontend Setup
```bash
cd frontend
flutter pub get
flutter run -d chrome  # or your device
```

---

## 📱 Key Features by Screen

| Screen | Key Responsibilities |
|--------|---------------------|
| **Dashboard** | Load subjects, display progress rings, quick actions |
| **QCM** | Question rendering, timer, option selection, bookmarking |
| **Review** | Load submission results, display performance, action buttons |
| **AI Solver** | Fetch & display explanation, render LaTeX, TTS |
| **Clone Generator** | Generate new question, validate answer, generate next |

---

This structure ensures:
✅ Scalability & modularity
✅ Clear separation of concerns
✅ Easy testing & maintenance
✅ Proper state management
✅ Secure API communication
✅ Offline-first architecture (local caching)
