# GCP Cloud Run Workshop Tutorial

Gemini AI ile YouTube videolarını özetleyen uygulama oluşturup Google Cloud Run'a deploy etmeyi öğreten interaktif workshop.

## Başlatmak için:

[![Open in Cloud Shell](https://gstatic.com/cloudssh/images/open-btn.svg)](https://shell.cloud.google.com/cloudshell/open?git_repo=https://github.com/GDGonCampusPAU/gcp-workshop-tutorial&tutorial=tutorial.md&cloudshell_git_branch=vertex-ai)

### Hesap sorunu yaşıyorsanız:

Cloud Shell'i açıp şu komutları çalıştırın:

```bash
cd $(find ~ -name "gcp-workshop-tutorial" -type d 2>/dev/null | head -1) 2>/dev/null || git clone -b vertex-ai https://github.com/GDGonCampusPAU/gcp-workshop-tutorial.git && cd gcp-workshop-tutorial
cloudshell launch-tutorial tutorial.md
```

## Ne Öğreneceksiniz?

- Cloud Shell kullanımı
- Python Flask ile REST API oluşturma
- Docker ile container paketleme
- Vertex AI ve Gemini API entegrasyonu
- Google Cloud Run'a serverless deploy
- GCP kredi yönetimi ve maliyet takibi
