#!/bin/bash
# GCP Workshop - IAM Izin Kurulum Scripti

PROJECT_ID=$1

if [ -z "$PROJECT_ID" ]; then
  echo "Hata: Proje ID gerekli!"
  echo "Kullanim: bash setup-iam.sh PROJECT_ID"
  exit 1
fi

echo "Proje: $PROJECT_ID icin izinler veriliyor..."

PROJECT_NUMBER=$(gcloud projects describe $PROJECT_ID --format='value(projectNumber)')
echo "Proje numarasi: $PROJECT_NUMBER"

COMPUTE_SA="${PROJECT_NUMBER}-compute@developer.gserviceaccount.com"
CLOUDBUILD_SA="${PROJECT_NUMBER}@cloudbuild.gserviceaccount.com"

# Yardimci: hata mesaji bastirmadan rol ata
# (Yeni GCP projelerinde cloudbuild SA otomatik olusturulmadigi icin
#  o SA'ya yapilan atamalar sessizce gecilir; Compute SA fallback gorevi yapar.)
grant() {
  gcloud projects add-iam-policy-binding "$PROJECT_ID" \
    --member="serviceAccount:$1" \
    --role="$2" \
    --condition=None \
    --quiet >/dev/null 2>&1 || true
}

echo "Compute service account izinleri veriliyor..."
grant "$COMPUTE_SA" "roles/aiplatform.user"
grant "$COMPUTE_SA" "roles/storage.admin"
grant "$COMPUTE_SA" "roles/logging.logWriter"

echo "Cloud Build service account izinleri veriliyor..."
grant "$CLOUDBUILD_SA" "roles/artifactregistry.writer"
grant "$CLOUDBUILD_SA" "roles/run.admin"
grant "$CLOUDBUILD_SA" "roles/iam.serviceAccountUser"

# Yeni projelerde Cloud Build varsayilan olarak Compute SA kullaniyor —
# bu yuzden ayni rolleri Compute SA'ya da fallback olarak veriyoruz.
grant "$COMPUTE_SA" "roles/artifactregistry.writer"
grant "$COMPUTE_SA" "roles/run.admin"
grant "$COMPUTE_SA" "roles/iam.serviceAccountUser"

echo "Tum izinler basariyla verildi!"
