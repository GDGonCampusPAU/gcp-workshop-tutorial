# GCP Cloud Run Workshop Tutorial

Gemini AI ile YouTube videolarını özetleyen uygulama oluşturup Google Cloud Run'a deploy etmeyi öğreten interaktif workshop.

## Başlatmak için:

[![Open in Cloud Shell](https://gstatic.com/cloudssh/images/open-btn.svg)](https://shell.cloud.google.com/cloudshell/open?git_repo=https://github.com/GDGonCampusPAU/gcp-workshop-tutorial&tutorial=tutorial.md&cloudshell_git_branch=fix/workshop-hardening)

### Hesap sorunu yaşıyorsanız:

Cloud Shell'i açıp şu komutları sırayla çalıştırın:

```bash
git clone -b vertex-ai https://github.com/GDGonCampusPAU/gcp-workshop-tutorial.git
```

```bash
cloudshell launch-tutorial ~/gcp-workshop-tutorial/tutorial.md
```
Already Exists Hatası Alırsanız:

```bash
rm -rf ~/gcp-workshop-tutorial && git clone -b vertex-ai https://github.com/GDGonCampusPAU/gcp-workshop-tutorial.git && cloudshell launch-tutorial ~/gcp-workshop-tutorial/tutorial.md
```


## Ne Öğreneceksiniz?

- Cloud Shell kullanımı
- Python Flask ile REST API oluşturma
- Docker ile container paketleme
- Vertex AI ve Gemini API entegrasyonu
- Google Cloud Run'a serverless deploy
- GCP kredi yönetimi ve maliyet takibi
