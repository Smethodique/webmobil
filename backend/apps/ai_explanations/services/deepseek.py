"""DeepSeek API client — synchronous, optimized for math tutoring."""
import os
import base64
import httpx
try:
    import pytesseract
    from PIL import Image
    import io
    pytesseract.pytesseract.tesseract_cmd = "/usr/bin/tesseract"
    HAS_OCR = True
except ImportError:
    HAS_OCR = False

DEEPSEEK_BASE = "https://api.deepseek.com/v1"
DEEPSEEK_MODEL = "deepseek-chat"
DEEPSEEK_VISION_MODEL = "deepseek-chat"  # try chat first, fallback to vl2 if needed

def _get_api_key():
    return os.environ.get("DEEPSEEK_API_KEY", "")

SYSTEM_PROMPT_SOLVE = """Tu es un professeur de mathematiques pour le concours FMP Maroc (bac sciences). Tu aides un etudiant a resoudre un QCM.

REGLES:
- Mathematiques du bac sciences marocain UNIQUEMENT. Sinon: "Je reponds uniquement aux questions de mathematiques du programme du bac scientifique marocain."
- Toute formule en LaTeX: $formule$
- Reponds TOUJOURS en 3 parties bien distinctes, separees par des sauts de ligne.

FORMAT OBLIGATOIRE:

**Raisonnement**
Explique la methode: quel concept, quelle formule appliquer, quel piege eviter. 2-4 phrases claires.

**Reponse correcte: X**
X = A, B, C, D ou E. Si pas de QCM: **Reponse:** $resultat$

**Astuce concours**
2-3 phrases: methode express pour le jour J, verification rapide, erreur classique a ne pas faire."""

SYSTEM_PROMPT_CHAT = """Tu es un professeur de mathematiques pour le concours FMP Maroc (bac sciences).

Tu analyses le travail d'un etudiant (texte extrait d'une photo) et tu donnes une correction claire.

REGLES DE FORMATAGE IMPERATIVES:
1. TOUTES les formules mathematiques en LaTeX entre $...$ (ex: $x^2$, $\frac{a}{b}$, $\sqrt{x}$, $\lim_{x\to 0}$).
2. JAMAIS de texte brut pour les maths (PAS "x^2" ni "lim(x->0)" — utilise TOUJOURS $...$).
3. Structure ta reponse en 4 parties, avec des sauts de ligne entre chaque:

**Ce qui est correct:** 1-2 phrases.

**Ce qui est faux:** 1-2 phrases. Explique pourquoi.

**Methode correcte:** 2-3 phrases. La bonne demarche avec les formules en LaTeX.

**Astuce:** 1-2 phrases. Conseil pour le concours.

4. Sois CONCIS. Maximum 400 tokens.
5. Mathematiques uniquement. Sinon: "Je reponds uniquement aux questions de mathematiques."""

SYSTEM_PROMPT_SIMILAR = """Tu es un generateur d'exercices de mathematiques pour le concours FMP Maroc (bac sciences).

A partir d'un exercice donne, genere un exercice SIMILAIRE mais DIFFERENT:
- Meme THEME mathematique et meme NIVEAU de difficulte
- MAIS: change les nombres, les fonctions, le contexte. PAS un clone.
- Exemple: si l'original est sur $f(x)=x^{2}-4x+3$, cree un exercice sur $g(x)=2x^{2}+6x-5$ ou un autre trinome avec des coefficients differents.
- Si l'original est une limite en 0, fais une limite en $+\\infty$ ou en 1.
- Si l'original est une derivee de polynome, fais une derivee de fonction rationnelle ou trigonometrique.
- Les options (A-E) doivent etre CREDIBLES: inclure les erreurs classiques que les etudiants font.
- Format QCM avec 5 options (A, B, C, D, E)
- Reponse correcte a la fin avec [REPONSE: X]

REGLES DE FORMATAGE IMPERATIVES:
1. TOUTES les formules mathematiques DOIVENT etre entre $...$ (LaTeX inline). AUCUNE formule en texte brut.
   - Fractions: $\\frac{a}{b}$
   - Puissances: $x^{2}$, indices: $u_{n}$
   - Racines: $\\sqrt{x}$, $\\sqrt[n]{x}$
   - Integrales: $\\int_{a}^{b} f(x)dx$
   - Limites: $\\lim_{x \\to +\\infty}$
   - Vecteurs: $\\vec{AB}$
   - Ensembles: $\\mathbb{R}$, $\\mathbb{N}$, $\\mathbb{C}$
   - Symboles: $\\Rightarrow$, $\\Leftrightarrow$, $\\geq$, $\\leq$, $\\neq$, $\\in$, $\\forall$, $\\exists$, $\\times$, $\\infty$
   - Trigonometrie: $\\sin$, $\\cos$, $\\tan$, $\\pi$
   - Logarithmes: $\\ln$, $\\log$, $e^{x}$
   - Matrices/determinants: commence par $\\begin{pmatrix}...\\end{pmatrix}$
2. Chaque option sur sa PROPRE LIGNE. JAMAIS plusieurs options sur la meme ligne.
3. Les options doivent contenir des expressions mathematiques en LaTeX.
4. Utilise **Enonce:** (gras) pour le titre de l'enonce.
5. JAMAIS de texte brut pour des maths (ex: PAS "x^2" mais "$x^{2}$", PAS "lim(x->+inf)" mais "$\\lim_{x \\to +\\infty}$").
6. Pas de retour a la ligne dans une formule LaTeX — garde chaque $...$ sur une ligne.

FORMAT EXACT (a suivre strictement):

**Enonce:** Soit $f$ la fonction definie sur $\\mathbb{R}$ par $f(x) = x^{3} - 3x + 1$. Calculer $f'(x)$.

**A)** $f'(x) = 3x^{2} - 3$
**B)** $f'(x) = x^{2} - 3$
**C)** $f'(x) = 3x^{2} + 3$
**D)** $f'(x) = 3x^{2} - 3x$
**E)** $f'(x) = x^{3} - 3$

[REPONSE: A]

EXEMPLES DE BON FORMAT:

Pour les limites:
**Enonce:** Calculer $\\lim_{x \\to 0} \\frac{\\sin(3x)}{x}$.

**A)** $0$
**B)** $1$
**C)** $3$
**D)** $+\\infty$
**E)** $\\frac{1}{3}$

[REPONSE: C]

Pour les nombres complexes:
**Enonce:** Soit $z = 1 + i\\sqrt{3}$. Le module de $z$ est:

**A)** $|z| = 1$
**B)** $|z| = 2$
**C)** $|z| = \\sqrt{3}$
**D)** $|z| = 4$
**E)** $|z| = \\sqrt{2}$

[REPONSE: B]

IMPORTANT: Chaque option DOIT etre precedee de **X)** ou X est la lettre, puis un espace, puis le contenu (souvent une formule LaTeX)."""


def _call_deepseek(messages, max_tokens=500, temperature=0.3):
    key = _get_api_key()
    if not key:
        return "Erreur: Cle API DeepSeek non configuree."
    try:
        resp = httpx.post(
            DEEPSEEK_BASE + "/chat/completions",
            headers={"Authorization": "Bearer " + key, "Content-Type": "application/json"},
            json={"model": DEEPSEEK_MODEL, "messages": messages, "max_tokens": max_tokens, "temperature": temperature},
            timeout=30.0,
        )
        data = resp.json()
        if "choices" in data and len(data["choices"]) > 0:
            return data["choices"][0]["message"]["content"]
        return "Erreur API: " + str(data.get("error", {}).get("message", str(data)))
    except Exception as e:
        return "Erreur connexion: " + str(e)


def solve_question(question_text, subject="", choices=None):
    user_msg = "Matiere: " + subject + "\n\nQuestion:\n" + question_text if subject else question_text
    if choices and len(choices) > 0:
        letters = ["A", "B", "C", "D", "E"]
        choix_formatted = "\n".join(f"{letters[i]}) {c}" for i, c in enumerate(choices[:5]) if c)
        user_msg += "\n\nChoix:\n" + choix_formatted
    return _call_deepseek([
        {"role": "system", "content": SYSTEM_PROMPT_SOLVE},
        {"role": "user", "content": user_msg},
    ], max_tokens=900)


def generate_similar(question_text, subject=""):
    user_msg = "Matiere: " + subject + "\n\nExercice original:\n" + question_text if subject else question_text
    return _call_deepseek([
        {"role": "system", "content": SYSTEM_PROMPT_SIMILAR},
        {"role": "user", "content": user_msg},
    ], max_tokens=800)


def _openrouter_vision_extract(image_base64):
    """Use OpenRouter free vision model (Gemma 4) to extract text from image."""
    api_key = os.environ.get("OPENROUTER_API_KEY", "")
    if not api_key:
        return None
    try:
        img_bytes = base64.b64decode(image_base64)
        img_b64 = base64.b64encode(img_bytes).decode()
        resp = httpx.post(
            "https://openrouter.ai/api/v1/chat/completions",
            headers={
                "Authorization": "Bearer " + api_key,
                "Content-Type": "application/json",
            },
            json={
                "model": "google/gemma-4-31b-it:free",
                "messages": [{
                    "role": "user",
                    "content": [
                        {"type": "text", "text": "Extrais UNIQUEMENT le texte de cette image d'exercice de mathematiques. Retourne le texte exact, mot pour mot. N'ajoute RIEN d'autre. Juste le texte brut."},
                        {"type": "image_url", "image_url": {"url": "data:image/jpeg;base64," + img_b64}},
                    ]
                }],
                "max_tokens": 500,
                "temperature": 0.1,
            },
            timeout=30.0,
        )
        data = resp.json()
        choices = data.get("choices", [])
        if choices:
            text = choices[0].get("message", {}).get("content", "").strip()
            if len(text) > 10:
                return text
    except Exception:
        pass
    return None


def _ocr_image(image_base64):
    """Extract text from image. Tries OpenRouter → OCR.space → Tesseract."""
    # 1) Try OpenRouter free vision (Gemma 4 31B)
    text = _openrouter_vision_extract(image_base64)
    if text:
        return text

    # 2) Try OCR.space with best AI engine (Engine 3)
    try:
        img_bytes = base64.b64decode(image_base64)
        resp = httpx.post(
            "https://api.ocr.space/parse/image",
            headers={"apikey": "helloworld"},
            files={"file": ("img.jpg", img_bytes, "image/jpeg")},
            data={
                "language": "fre",
                "OCREngine": "3",         # best AI engine
                "isOverlayRequired": "false",
                "scale": "true",           # upscale for better accuracy
                "detectOrientation": "true",
            },
            timeout=25.0,
        )
        data = resp.json()
        results = data.get("ParsedResults", [])
        if results:
            text = results[0].get("ParsedText", "").strip()
            if len(text) > 10:
                return text
    except Exception:
        pass

    # 2) Fallback: local Tesseract with preprocessing
    if HAS_OCR:
        try:
            from PIL import ImageEnhance
            img_bytes = base64.b64decode(image_base64)
            img = Image.open(io.BytesIO(img_bytes))
            img = img.convert("L")
            # Increase contrast
            enhancer = ImageEnhance.Contrast(img)
            img = enhancer.enhance(2.0)
            # Resize for better OCR (2x)
            img = img.resize((img.width * 2, img.height * 2), Image.LANCZOS)
            text = pytesseract.image_to_string(img, lang="fra+eng", config="--psm 6")
            text = text.strip()
            return text if len(text) > 10 else None
        except Exception:
            pass

    return None


def ai_chat(user_text, image_base64=None):
    key = _get_api_key()
    if not key:
        return "Erreur: Cle API DeepSeek non configuree."

    ocr_text = None
    if image_base64:
        ocr_text = _ocr_image(image_base64)

    if ocr_text:
        # OCR succeeded — use extracted text directly
        user_content = (
            "Voici le texte extrait d'une photo d'exercice:\n\n" + ocr_text + "\n\n"
            + (user_text or "Analyse cet exercice et donne ton avis.")
        )
    elif image_base64:
        # OCR failed, try vision; if that fails, text-only fallback
        user_content = [
            {"type": "text", "text": user_text or "Analyse cet exercice de mathematiques et donne ton avis."},
            {"type": "image_url", "image_url": {"url": "data:image/jpeg;base64," + image_base64}},
        ]
    else:
        user_content = user_text or "Analyse cet exercice et donne ton avis."

    model = DEEPSEEK_MODEL
    messages = [{"role": "system", "content": SYSTEM_PROMPT_CHAT}]
    messages.append({"role": "user", "content": user_content})

    try:
        resp = httpx.post(
            DEEPSEEK_BASE + "/chat/completions",
            headers={"Authorization": "Bearer " + key, "Content-Type": "application/json"},
            json={"model": model, "messages": messages, "max_tokens": 500, "temperature": 0.3},
            timeout=45.0,
        )
        data = resp.json()
        if "choices" in data and len(data["choices"]) > 0:
            return data["choices"][0]["message"]["content"]

        err = data.get("error", {})
        err_msg = str(err.get("message", str(data)))

        # If image failed, retry without the image
        if image_base64 and "image" in err_msg.lower():
            messages[1]["content"] = user_text or "Analyse cet exercice de mathematiques (l'etudiant a envoye une photo). Donne ton avis."
            resp2 = httpx.post(
                DEEPSEEK_BASE + "/chat/completions",
                headers={"Authorization": "Bearer " + key, "Content-Type": "application/json"},
                json={"model": model, "messages": messages, "max_tokens": 500, "temperature": 0.3},
                timeout=45.0,
            )
            data2 = resp2.json()
            if "choices" in data2 and len(data2["choices"]) > 0:
                return data2["choices"][0]["message"]["content"]

        return "Erreur API: " + err_msg
    except Exception as e:
        return "Erreur connexion: " + str(e)
