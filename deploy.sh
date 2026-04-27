#!/bin/bash
# =============================================================================
# YouTube Summarizer - Cloud Run Deploy Script (Robust Version)
# =============================================================================
# Bu script, atolye katilimcilarinda surekli cikan
# "retry budget exhausted" ve "Buildpacks build failed" hatalarini
# tamamen onlemek icin yazildi.
#
# Kapsadigi root cause'lar:
# 1. Eksik API'ler (Cloud Build, Artifact Registry, Cloud Run, Vertex AI)
# 2. Eksik IAM yetkileri (hem Cloud Build SA hem Compute SA)
# 3. IAM propagation gecikmesi
# 4. Artifact Registry repository'sinin onceden olusmamasi
# 5. Yanlis klasorden deploy (Dockerfile bulunamayinca Buildpacks fallback)
# =============================================================================

set -e  # Herhangi bir komut hata verirse script dursun

# --- 1. Argument kontrolu ---
if [ -z "$1" ]; then
  echo "HATA: PROJECT_ID verilmedi."
  echo "Kullanim: bash deploy.sh PROJECT_ID"
  exit 1
fi

PROJECT_ID=$1
REGION=${2:-us-central1}
SERVICE_NAME="youtube-summarizer"
REPO_NAME="cloud-run-source-deploy"

# --- 1b. Dogru klasoru bul ---
# Script hem repo kokunden hem de summarizer-app icinden calistirilabilir.
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

if [ -f "$SCRIPT_DIR/Dockerfile" ]; then
  APP_DIR="$SCRIPT_DIR"
elif [ -f "$SCRIPT_DIR/summarizer-app/Dockerfile" ]; then
  APP_DIR="$SCRIPT_DIR/summarizer-app"
else
  echo "HATA: Dockerfile bulunamadi."
  echo "       Aranan: $SCRIPT_DIR/Dockerfile"
  echo "       Veya:   $SCRIPT_DIR/summarizer-app/Dockerfile"
  exit 1
fi

echo "=========================================="
echo "  YouTube Summarizer Deploy"
echo "=========================================="
echo "  Proje:    $PROJECT_ID"
echo "  Bolge:    $REGION"
echo "  Servis:   $SERVICE_NAME"
echo "  Klasor:   $APP_DIR"
echo "=========================================="
echo ""

# --- 2. Aktif projeyi ayarla ---
gcloud config set project "$PROJECT_ID" --quiet

# --- 3. Project number'i al ---
echo "[1/6] Proje bilgileri aliniyor..."
PROJECT_NUMBER=$(gcloud projects describe "$PROJECT_ID" --format='value(projectNumber)')
if [ -z "$PROJECT_NUMBER" ]; then
  echo "HATA: Proje bulunamadi veya erisim yok: $PROJECT_ID"
  exit 1
fi
echo "      Proje numarasi: $PROJECT_NUMBER"

# --- 4. Gerekli API'leri etkinlestir ---
echo ""
echo "[2/6] Gerekli API'ler etkinlestiriliyor..."
gcloud services enable \
  run.googleapis.com \
  cloudbuild.googleapis.com \
  artifactregistry.googleapis.com \
  aiplatform.googleapis.com \
  --project="$PROJECT_ID" --quiet
echo "      API'ler hazir."

# --- 5. IAM yetkilerini ver ---
echo ""
echo "[3/6] IAM yetkileri veriliyor..."

CLOUDBUILD_SA="${PROJECT_NUMBER}@cloudbuild.gserviceaccount.com"
COMPUTE_SA="${PROJECT_NUMBER}-compute@developer.gserviceaccount.com"

for SA in "$CLOUDBUILD_SA" "$COMPUTE_SA"; do
  for ROLE in "roles/artifactregistry.writer" \
              "roles/artifactregistry.admin" \
              "roles/storage.admin" \
              "roles/run.admin" \
              "roles/iam.serviceAccountUser" \
              "roles/logging.logWriter" \
              "roles/aiplatform.user"; do
    gcloud projects add-iam-policy-binding "$PROJECT_ID" \
      --member="serviceAccount:${SA}" \
      --role="$ROLE" \
      --condition=None \
      --quiet >/dev/null 2>&1 || true
  done
done
echo "      IAM yetkileri verildi."

# --- 6. Artifact Registry repository ---
echo ""
echo "[4/6] Artifact Registry repository hazirlaniyor..."
if ! gcloud artifacts repositories describe "$REPO_NAME" \
     --location="$REGION" --project="$PROJECT_ID" >/dev/null 2>&1; then
  gcloud artifacts repositories create "$REPO_NAME" \
    --repository-format=docker \
    --location="$REGION" \
    --project="$PROJECT_ID" \
    --quiet
  echo "      Repository olusturuldu: $REPO_NAME"
else
  echo "      Repository zaten var: $REPO_NAME"
fi

# --- 7. IAM propagation ---
echo ""
echo "[5/6] IAM yetkilerinin yayilmasi bekleniyor (30 saniye)..."
sleep 30

# --- 8. Deploy ---
echo ""
echo "[6/6] Cloud Run'a deploy ediliyor (3-5 dakika surebilir)..."
echo "      Kaynak klasor: $APP_DIR"
echo ""

cd "$APP_DIR"

gcloud run deploy "$SERVICE_NAME" \
  --source . \
  --region "$REGION" \
  --project "$PROJECT_ID" \
  --allow-unauthenticated \
  --set-env-vars="GOOGLE_CLOUD_PROJECT=$PROJECT_ID,GOOGLE_CLOUD_LOCATION=global" \
  --quiet

# --- 9. URL ---
echo ""
SERVICE_URL=$(gcloud run services describe "$SERVICE_NAME" \
  --region "$REGION" \
  --project "$PROJECT_ID" \
  --format='value(status.url)' 2>/dev/null || echo "")

if [ -n "$SERVICE_URL" ]; then
  echo "=========================================="
  echo "  Deploy basarili!"
  echo "=========================================="
  echo "  URL: $SERVICE_URL"
  echo "=========================================="
else
  echo "UYARI: Deploy tamamlandi ama URL alinamadi."
fi
