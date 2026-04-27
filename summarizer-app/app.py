import os
import re
import logging
from flask import Flask, render_template, request, redirect
import vertexai
from vertexai.generative_models import GenerativeModel, Part

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = Flask(__name__)

PROJECT_ID = os.environ.get("GOOGLE_CLOUD_PROJECT")
LOCATION = os.environ.get("GOOGLE_CLOUD_LOCATION", "us-central1")
DEFAULT_MODEL = "gemini-2.5-flash"
ALLOWED_MODELS = {"gemini-2.5-flash", "gemini-2.5-pro"}

if not PROJECT_ID:
    logger.warning("GOOGLE_CLOUD_PROJECT environment variable is not set.")

vertexai.init(project=PROJECT_ID, location=LOCATION)

YOUTUBE_URL_PATTERN = re.compile(
    r"^https?://(?:www\.|m\.)?(?:youtube\.com/(?:watch\?v=|shorts/|embed/|live/)|youtu\.be/)[\w\-]+",
    re.IGNORECASE,
)


def is_valid_youtube_url(url: str) -> bool:
    return bool(url) and bool(YOUTUBE_URL_PATTERN.match(url.strip()))


@app.route("/", methods=["GET"])
def index():
    return render_template("index.html")


def generate(youtube_link: str, additional_prompt: str, model_name: str) -> str:
    if model_name not in ALLOWED_MODELS:
        model_name = DEFAULT_MODEL

    if not additional_prompt:
        additional_prompt = "Please provide a detailed summary."

    model = GenerativeModel(model_name)
    video_part = Part.from_uri(uri=youtube_link, mime_type="video/mp4")
    contents = [video_part, additional_prompt]
    response = model.generate_content(contents)
    return response.text


@app.route("/summarize", methods=["GET", "POST"])
def summarize():
    if request.method != "POST":
        return redirect("/")

    youtube_link = request.form.get("youtube_link", "").strip()
    additional_prompt = request.form.get("additional_prompt", "").strip()
    model_name = request.form.get("model", DEFAULT_MODEL).strip()

    if not is_valid_youtube_url(youtube_link):
        return "Error: Lutfen gecerli bir YouTube URL'si girin.", 400

    try:
        return generate(youtube_link, additional_prompt, model_name)
    except Exception as e:
        logger.exception("Summarization failed")
        return f"Error: {str(e)}", 500


@app.route("/healthz", methods=["GET"])
def healthz():
    return {"status": "ok"}, 200


if __name__ == "__main__":
    port = int(os.environ.get("PORT", "8080"))
    app.run(debug=False, port=port, host="0.0.0.0")
