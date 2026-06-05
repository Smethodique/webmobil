# 📱 FMP Prep AI: Frontend Features & Screen Specifications

This document outlines the complete frontend architecture, user experience (UX) flows, and interactive feature specifications for the **FMP Prep AI** mobile application. 

---

## 🎨 1. Global UI/UX & Design Guidelines

To match premium design standards, the mobile interface must adopt a high-fidelity, high-contrast, and dynamic visual language:
* **Color Palette:** Curated Sleek Dark Mode.
  * **Background:** Deep obsidian black (`#0B0F17`)
  * **Card Surface:** Glassmorphic dark slate (`#161F30`) with a subtle border color (`#22324D`)
  * **Primary Accent:** Royal Mediterranean Blue (`#3B82F6` to `#1D4ED8` gradients)
  * **Success/Validation:** Emerald Mint (`#10B981`)
  * **Alert/Incorrect:** Crimson Coral (`#EF4444`)
  * **Warning/Chrono:** Amber Gold (`#F59E0B`)
* **Typography:** Modern sans-serif typography (e.g., *Outfit* or *Inter* from Google Fonts).
* **Math Renders:** KaTeX integration natively to display math formulas elegantly with custom zoom sliders for complex formulas.

---

## 🗺️ 2. Core User Experience Flow

The interactive student journey through **FMP Prep AI** is designed as a continuous, closed-loop learning system that guides the student from self-assessment to deep conceptual mastery:

### 📍 Step 1: Entry Point & Diagnostic Dashboard
1. The student opens the app to their **Dashboard**, greeted by a dynamic overview of their **Taux de Progression** across the 8 core math subjects.
2. The student has two primary actions:
   * **Real past paper training:** They select an official FMP concours year (e.g., FMP Casablanca 2017) to test their overall readiness under strict exam rules.
   * **Focused sub-topic training:** They expand a specific math subject (e.g., *Fonctions Numériques*), choose a weak sub-topic (e.g., *Théorème des Valeurs Intermédiaires*), and launch a customized practice set.

### ⏱️ Step 2: The Timed QCM Session (The Sandbox)
1. The student enters the QCM interface where the **Chronometer** begins counting down.
2. The screen displays mathematical questions beautifully rendered via **KaTeX**. 
3. The student:
   * Selects their answer among options **A to E** (large, tactile rows with smooth active scaling).
   * Bookmarks hard or doubtful questions with a double-tap to return to them later.
   * Swipes or uses navigation shortcuts to move rapidly between questions.
4. When finished, or if the countdown hits `00:00`, the student clicks **Valider et Soumettre** to complete the session.

### 📊 Step 3: Interactive Post-Exam Review Screen
1. The student is instantly presented with their overall results card: score, accuracy rate, and average speed.
2. A scrollable feed shows every question color-coded:
   * **Green (Correct):** Validated answers.
   * **Crimson (Incorrect):** Highlights the student's wrong selection next to the highlighted correct option.
3. Beneath **every question card**, the student has two direct interactive buttons:
   * 🤖 **"Explication par l'IA" (Ask AI):** To instantly understand why they got it wrong.
   * 🪄 **"Cloner cette Question" (Clone Question):** To immediately test if they have understood the logic by generating an identical clone.

### 🧠 Step 4: The AI Solver Drawer (Conceptual Tutoring)
1. Tapping "Explication" slides up a gorgeous bottom drawer.
2. The AI Tutor explains:
   * **The Core Mathematical Rule:** The underlying theorem or formula.
   * **Step-by-Step Resolution:** A detailed algebra breakdown using LaTeX.
   * **The Concours Shortcut:** A premium time-saving trick showing how to eliminate 3 wrong options instantly (e.g., parity check, domain bounds) to solve it in under 30 seconds.

### ♾️ Step 5: Infinite Exercise Generator & Repetition Sandbox
1. Tapping "Cloner cette Question" transitions the student to the **Infinite Practice Sandbox**.
2. The AI instantly generates a **fresh, mathematically valid question** using the exact same difficulty and structure (e.g., changing limits variables, complex number parameters) as the original question.
3. The student attempts this new clone with a localized question timer.
4. Once answered, they validate it:
   * If correct: They can click **"Générer un autre clone"** to reinforce, or exit.
   * If incorrect: They can launch the **AI Solver** on this cloned question and repeat the process until they answer correctly.

### 🔄 Step 6: Instant Progress Tracking Loop
1. The moment the student completes any exercise or clone, their answers, correctness, and time spent are synced locally.
2. The backend recalculates their **Taux de Progression** for that specific sub-topic.
3. Upon returning to the main Dashboard, the subject progression rings animate to reflect their new mastery level, creating a rewarding gamification loop.

---

## 🔍 3. Screen-by-Screen Frontend Specifications

### 🖥️ Screen 1: Interactive Dashboard (Syllabus & Taux de Progression)
This is the app's central hub. It presents the student's mastery tree over the **8 official FMP Math Subjects**.

* **Subject Progression Cards:** Each of the 8 subjects features a progress ring displaying its overall *Taux de Progression* (calculated in real time). Clicking a card expands it to reveal its specific sub-topics with checklist-style mastery indexes:

| Main Subject | Sub-Topics & Concepts Tracked |
| :--- | :--- |
| **1. Suites Numériques** | <ul><li>Suites arithmétiques et géométriques</li><li>Convergence et limites de suites</li><li>Suites récurrentes</li><li>Monotonie et bornes</li></ul> |
| **2. Fonctions Numériques** | <ul><li>Domaine de définition</li><li>Limites (calculs de limites, formes indéterminées)</li><li>Continuité et Théorème des Valeurs Intermédiaires (TVI)</li><li>Dérivabilité, calcul de dérivées, sens de variation</li><li>Branches infinies et asymptotes (horizontales, verticales, obliques)</li><li>Dalles trigonométriques, logarithmiques (ln) et exponentielles (exp)</li><li>Fonctions circulaires inverses (Arctan)</li></ul> |
| **3. Calcul Intégral** | <ul><li>Calcul de primitives</li><li>Calcul d'intégrales (par parties, changement de variable)</li><li>Calcul d'aires et de volumes</li></ul> |
| **4. Nombres Complexes** | <ul><li>Forme algébrique, trigonométrique et exponentielle</li><li>Module et argument</li><li>Équations dans $\mathbb{C}$</li><li>Interprétation géométrique</li></ul> |
| **5. Géométrie dans l'Espace** | <ul><li>Vecteurs dans l'espace, repère orthonormé</li><li>Équations de plans et de droites</li><li>Équations de sphères</li><li>Distances (point à plan, point à droite)</li><li>Intersections (plan-plan, plan-sphère)</li></ul> |
| **6. Dénombrement & Probabilités** | <ul><li>Analyse combinatoire (Arrangements, Combinaisons, Permutations)</li><li>Calcul de probabilités élémentaires</li><li>Probabilités conditionnelles</li><li>Variables aléatoires et lois (Loi binomiale, Bernoulli)</li></ul> |
| **7. Équations Différentielles** | <ul><li>Équations du premier ordre ($y' + ay = b$)</li><li>Équations du second ordre ($y'' + ay' + by = 0$)</li></ul> |
| **8. Raisonnement & Arithmétique** | <ul><li>Logique mathématique</li><li>Propriétés des nombres entiers (parité, divisibilité)</li></ul> |

* **Quick Play Actions:**
  * **"Mode Concours":** Start a random past exam (20 QCM questions mixed from all subjects) under a global 30-minute countdown.
  * **"Entraînement Libre":** Filter and practice questions exclusively from a single weak sub-topic.

---

### ⏱️ Screen 2: QCM Quiz Sandbox (The Chrono View)
A high-performance interface built for extreme speed and concentration.

* **Top Navigation Bar:**
  * **Progress Bar:** Dots showing answered, remaining, and bookmarked questions.
  * **Countdown Timer (Chrono):** Glows amber when time runs short, turns crimson in the last 60 seconds. Can be paused in *Practice Mode*, locked in *Concours Mode*.
* **Question Render Engine:** Uses KaTeX to seamlessly render high-level formulas inline with Arabic and French texts.
* **Option Selectors:** Large, tap-friendly rows (labeled A to E) with smooth, active scale-down animations upon selection. Supports **Multiple Choice Validation** (if enabled by specific exam criteria) or single choice selection.
* **Floating Utility Panel:**
  * **Bookmark Flag:** Highlight a question to jump back to it before validating the whole exam.
  * **"Passer":** Fast skipping system.

---

### 📊 Screen 3: Post-Exam Review (Response Analysis)
The retrospective screen loaded immediately after the user validates their quiz or when the countdown timer hits `00:00`.

* **Performance Overview Card:** Shows a big score badge (e.g., `14 / 20`), absolute accuracy, average time spent per question, and overall progress score modification.
* **Question Feed Navigator:** Scrollable carousel of all questions color-coded for quick scanning:
  * **Green Border:** Correctly answered.
  * **Crimson Border:** Incorrectly answered (shows user's wrong answer + the green correct answer).
  * **Grey Border:** Unanswered questions.
* **Contextual Actions per Question:**
  * 🪄 **"Cloner cette Question" (Generate similar question):** Uses AI to generate a brand new question with the identical style, difficulty level, and subject matter.
  * 🤖 **"Explication par l'IA" (AI Explanatory Solution):** Launches a sliding overlay drawer containing a personalized step-by-step explanation.

---

### 🤖 Screen 4: AI Solver & Tutor (Bottom Drawer)
A glassmorphic slide-up overlay designed to feel like an interactive, personal tutor session.

* **Step-by-Step Proof Accordion:** Breaks down the math logic behind the question:
  * *Section 1: What is the question asking?* (Conceptual breakdown).
  * *Section 2: The Proof.* (KaTeX equations showing step-by-step substitutions).
  * *Section 3: Why your choice was incorrect.* (Calculates what mistake leads to the user's specific wrong answer).
* **FMP Fast Shortcuts:** A premium section with a gold border that reveals **time-saving tricks**—such as testing extreme values, evaluating symmetry, or parity checks—enabling the student to eliminate options and solve it in under 30 seconds.
* **Voice Synthesis Option:** Built-in Text-to-Speech allowing students to listen to the explanation in Moroccan Darija/French blend.

---

### 🪄 Screen 5: Infinite Exercise Generator View (Simulated Clone Playback)
This screen is triggered when the user clicks **"Cloner cette Question"** from their exam review or chooses to train on a specific sub-topic.

* **Visual Identity:** Sleek glowing cyan border, indicating it is an AI-generated, custom live exercise.
* **Cloned Question Card:** Features a fresh, synthetically generated question matching the target question’s format and formulas, but with updated values, coefficients, or trigonometric limits.
* **Interactive Playback:**
  * Has its own sub-timer (chrono) to measure response speed.
  * Once the student selects their option and clicks **Validate**, the screen turns green (correct) or red (incorrect) instantly.
  * Click **"Nouveau Clone"** to generate another one infinitely, or **"Explication"** to read the customized resolution.

---

## 📊 4. The "Taux de Progression" Mastery Calculation

To ensure students are motivated by accurate visual progress metrics, the frontend tracks and processes user history:
* **The Progression Score formula:**
  $$\text{Taux per Sub-Topic} = \left( \frac{\text{Correct Answers in Last 20 Attempts}}{\text{20}} \times 70\% \right) + \left( \frac{\text{Target Time (e.g., 90s)}}{\text{User Average Time}} \times 30\% \right)$$
* **Real-time updates:** Every time a user validates a clone or standard past paper question, their sub-topic progression increments/decrements, immediately updating the main dashboard tree.

