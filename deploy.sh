#!/bin/bash
# GCP Workshop - Deploy Scripti

PROJECT_ID=$1

if [ -z "$PROJECT_ID" ]; then
  echo "Hata: Proje ID gerekli!"
  echo "Kullanim: bash deploy.sh PROJECT_ID"
  exit 1
fi

echo "Deploy basliyor... Proje: $PROJECT_ID"
echo "Bu adim 3-5 dakika surebilir."

# Gerekli izinleri ver (daha once verilmisse hata vermez)
echo "Izinler kontrol ediliyor..."
PROJECT_NUMBER=$(gcloud projects describe $PROJECT_ID --format='value(projectNumber)')
gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:${PROJECT_NUMBER}-compute@developer.gserviceaccount.com" \
  --role="roles/storage.admin" --quiet 2>/dev/null
gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:${PROJECT_NUMBER}@cloudbuild.gserviceaccount.com" \
  --role="roles/artifactregistry.writer" --quiet 2>/dev/null
gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:${PROJECT_NUMBER}@cloudbuild.gserviceaccount.com" \
  --role="roles/run.admin" --quiet 2>/dev/null
echo "Izinler tamam!"

gcloud run deploy youtube-summarizer \
  --source . \
  --region us-central1 \
  --project $PROJECT_ID \
  --allow-unauthenticated

if [ $? -eq 0 ]; then
  echo ""
  echo "Deploy tamamlandi!"
  echo "Servis URL:"
  gcloud run services describe youtube-summarizer \
    --region us-central1 \
    --project $PROJECT_ID \
    --format='value(status.url)'
else
  echo ""
  echo "Deploy basarisiz oldu. Loglari kontrol edin."
fi
