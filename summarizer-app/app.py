import os
from flask import Flask, render_template, request, redirect
import vertexai
from vertexai.generative_models import GenerativeModel, Part

app = Flask(__name__)

PROJECT_ID = os.environ.get("GOOGLE_CLOUD_PROJECT")
LOCATION = "us-central1"

vertexai.init(project=PROJECT_ID, location=LOCATION)
model = GenerativeModel("gemini-2.5-flash")

@app.route("/", methods=["GET"])
def index():
    return render_template("index.html")

def generate(youtube_link, additional_prompt):
    if not additional_prompt:
        additional_prompt = "Please provide a detailed summary."
    video_part = Part.from_uri(uri=youtube_link, mime_type="video/*")
    contents = [video_part, additional_prompt]
    response = model.generate_content(contents)
    return response.text

@app.route("/summarize", methods=["GET", "POST"])
def summarize():
    if request.method == "POST":
        youtube_link = request.form["youtube_link"]
        additional_prompt = request.form["additional_prompt"]
        try:
            summary = generate(youtube_link, additional_prompt)
            return summary
        except Exception as e:
            return f"Error: {str(e)}", 500
    return redirect("/")

if __name__ == "__main__":
    port = int(os.environ.get("PORT", "8080"))
    app.run(debug=False, port=port, host="0.0.0.0")
