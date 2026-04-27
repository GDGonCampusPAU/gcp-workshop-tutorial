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

gcloud run deploy youtube-summarizer \
  --source . \
  --region us-central1 \
  --project $PROJECT_ID \
  --allow-unauthenticated

echo ""
echo "Deploy tamamlandi!"
echo "Servis URL:"
gcloud run services describe youtube-summarizer \
  --region us-central1 \
  --project $PROJECT_ID \
  --format='value(status.url)'
