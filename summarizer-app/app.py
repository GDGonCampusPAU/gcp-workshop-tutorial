import os
import re
import time
import random
import logging
from flask import Flask, render_template, request, redirect
import vertexai
from vertexai.generative_models import GenerativeModel, Part

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = Flask(__name__)

PROJECT_ID = os.environ.get("GOOGLE_CLOUD_PROJECT")
# vertexai 1.71.1 SDK'si "global"'i validate_region listesinde tanimiyor —
# us-central1 stabil. 429 riskini retry logic absorbe ediyor.
LOCATION = os.environ.get("GOOGLE_CLOUD_LOCATION", "us-central1")
DEFAULT_MODEL = "gemini-2.5-flash"
ALLOWED_MODELS = {"gemini-2.5-flash", "gemini-2.5-pro"}
MAX_RETRIES = 5

# Kullanici 3 sabit secenekten birini seciyor — frontend serbest metin almiyor,
# bu yuzden prompt-injection / off-topic riski mimari olarak yok.
DEFAULT_SUMMARY_TYPE = "detailed"
SUMMARY_PROMPTS = {
    "quick": (
        "Bu videoyu 2-3 cumlede, ana konuyu vurgulayarak Turkce ozetle. "
        "Cok oz tut, detaya girme."
    ),
    "detailed": (
        "Bu videoyu Turkce, detayli sekilde ozetle. Ana noktalari ve onemli "
        "detaylari iceren akici bir ozet uret. Onemli yerleri madde madde "
        "veya alt basliklarla yapilandir."
    ),
    "broad": (
        "Bu videoyu Turkce, kapsamli ve derinlemesine ozetle. Bolumlere ayir, "
        "her bolumun anahtar tartisma noktalarini, somut ornekleri ve onemli "
        "alintilari belirt. Sonunda kisa bir tematik degerlendirme ekle."
    ),
}

SYSTEM_INSTRUCTION = (
    "Sen bir YouTube video ozetleme asistanisin. Sana bir video ve istenilen "
    "ozet formati verilir. Sadece o videoyu, istenilen formatta Turkce ozetle. "
    "Cevabini Markdown formatinda uret."
)

if not PROJECT_ID:
    logger.error(
        "GOOGLE_CLOUD_PROJECT env var bos! deploy.sh tarafindan set edilmesi gerekiyor. "
        "Cloud Run servisini --set-env-vars ile yeniden deploy edin."
    )

vertexai.init(project=PROJECT_ID, location=LOCATION)
logger.info("Vertex AI baslatildi: project=%s location=%s", PROJECT_ID, LOCATION)

YOUTUBE_URL_PATTERN = re.compile(
    r"^https?://(?:www\.|m\.)?(?:youtube\.com/(?:watch\?v=|shorts/|embed/|live/)|youtu\.be/)[\w\-]+",
    re.IGNORECASE,
)


def is_valid_youtube_url(url: str) -> bool:
    return bool(url) and bool(YOUTUBE_URL_PATTERN.match(url.strip()))


@app.route("/", methods=["GET"])
def index():
    return render_template("index.html")


def _is_retryable(exc: Exception) -> bool:
    msg = str(exc).lower()
    return (
        "429" in msg
        or "resource exhausted" in msg
        or "resource_exhausted" in msg
        or "rate" in msg and "limit" in msg
        or "503" in msg
        or "unavailable" in msg
    )


def generate(youtube_link: str, summary_type: str, model_name: str) -> str:
    if model_name not in ALLOWED_MODELS:
        model_name = DEFAULT_MODEL

    if summary_type not in SUMMARY_PROMPTS:
        summary_type = DEFAULT_SUMMARY_TYPE

    prompt = SUMMARY_PROMPTS[summary_type]

    model = GenerativeModel(model_name, system_instruction=SYSTEM_INSTRUCTION)
    video_part = Part.from_uri(uri=youtube_link, mime_type="video/mp4")
    contents = [video_part, prompt]

    # 429/503 icin truncated exponential backoff + jitter — workshop'ta kapasite tikanmasini gizler
    for attempt in range(MAX_RETRIES):
        try:
            response = model.generate_content(contents)
            return response.text
        except Exception as exc:
            if attempt == MAX_RETRIES - 1 or not _is_retryable(exc):
                raise
            wait = min(2 ** attempt, 16) + random.uniform(0, 1)
            logger.warning(
                "Vertex AI retry %d/%d after %.1fs (reason: %s)",
                attempt + 1, MAX_RETRIES, wait, str(exc).splitlines()[0][:200],
            )
            time.sleep(wait)
    raise RuntimeError("generate(): unreachable")


@app.route("/summarize", methods=["GET", "POST"])
def summarize():
    if request.method != "POST":
        return redirect("/")

    youtube_link = request.form.get("youtube_link", "").strip()
    summary_type = request.form.get("summary_type", DEFAULT_SUMMARY_TYPE).strip()
    model_name = request.form.get("model", DEFAULT_MODEL).strip()

    if not is_valid_youtube_url(youtube_link):
        return "Hata: Lutfen gecerli bir YouTube URL'si girin.", 400

    try:
        return generate(youtube_link, summary_type, model_name)
    except Exception as e:
        logger.exception("Summarization failed")
        if _is_retryable(e):
            return (
                "Vertex AI suan yogun (kapasite gecici dolu). "
                "Lutfen 10-20 saniye bekleyip 'Summarize Content' butonuna tekrar basin.",
                503,
            )
        return f"Hata: {str(e)}", 500


@app.route("/healthz", methods=["GET"])
def healthz():
    return {"status": "ok"}, 200


if __name__ == "__main__":
    port = int(os.environ.get("PORT", "8080"))
    app.run(debug=False, port=port, host="0.0.0.0")
