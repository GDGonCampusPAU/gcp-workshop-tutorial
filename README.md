# GCP Cloud Run Workshop Tutorial

Vertex AI Gemini ile YouTube videolarını özetleyen bir uygulama oluşturup Google Cloud Run'a deploy etmeyi öğreten interaktif workshop. Sıfırdan başlayıp kendi AI uygulamanızı internete açıyorsunuz.

---

## ⏱️ Workshop hakkında

- **Süre:** ~45-60 dakika
- **Tahmini maliyet:** $0.05 – $0.30 (workshop kredinizden düşer)
- **Hedef çıktı:** Public URL'iniz olan, Gemini destekli bir YouTube özetleyici Cloud Run servisi

---

## ✅ Başlamadan önce

1. Workshop kredinizin tanımlı olduğu Google hesabıyla [console.cloud.google.com](https://console.cloud.google.com) üzerinde oturum açın.
2. **VPN'inizi kapatın** — açık VPN, Cloud Shell tutorial panelinin yüklenmesini engelleyebilir.
3. Tarayıcı olarak **Chrome** kullanmanızı öneriyoruz (en stabil Cloud Shell deneyimi).

---

## 🚀 Başlatmak için

Aşağıdaki butona tıklayın — Cloud Shell otomatik açılır, repo klonlanır ve tutorial paneli sağda görünür:

[![Open in Cloud Shell](https://gstatic.com/cloudssh/images/open-btn.svg)](https://shell.cloud.google.com/cloudshell/open?git_repo=https://github.com/GDGonCampusPAU/gcp-workshop-tutorial&tutorial=tutorial.md&cloudshell_git_branch=fix/workshop-hardening)

---

## 📚 Workshop akışı

Tutorial paneli sizi şu adımlardan tek tek geçirir:

1. **Proje seçimi & billing** — Workshop kredinizi projeye bağlama
2. **API'ler & IAM izinleri** — Cloud Run, Cloud Build, Vertex AI, Artifact Registry
3. **Kod inceleme** — Flask backend, Gemini 2.5 Flash entegrasyonu, frontend
4. **Cloud Run'a deploy** — Tek komutla container build + deploy
5. **Test & inceleme** — Public bir YouTube videosu özetleyin, metrics/logs görün
6. **Temizlik** — Kaynakları silip harcama özetini görme

---

## 🎯 Ne öğreneceksiniz?

- Cloud Shell ve `gcloud` CLI temelleri
- Python Flask ile REST API + Docker container paketleme
- Vertex AI Gemini API entegrasyonu (multimodal video analizi)
- Cloud Run'a serverless deploy
- IAM, service account ve principle of least privilege
- GCP kredi yönetimi, budget kurulumu, maliyet takibi

---

## 🛠️ Sorun giderme

### "Open in Cloud Shell" butonu çalışmıyorsa (manuel başlatma)

Cloud Shell'i [shell.cloud.google.com](https://shell.cloud.google.com) üzerinden açıp şu komutları sırayla çalıştırın:

```bash
git clone -b fix/workshop-hardening https://github.com/GDGonCampusPAU/gcp-workshop-tutorial.git
```

```bash
cloudshell launch-tutorial ~/gcp-workshop-tutorial/tutorial.md
```

### "Already Exists" / klasör zaten var hatası

```bash
rm -rf ~/gcp-workshop-tutorial && git clone -b fix/workshop-hardening https://github.com/GDGonCampusPAU/gcp-workshop-tutorial.git && cloudshell launch-tutorial ~/gcp-workshop-tutorial/tutorial.md
```

### "No such file or directory" / "deploy.sh bulunamadı"

Cloud Shell daha önce eski bir klon kullanmış olabilir. Tek komutla sıfırlayın:

```bash
rm -rf ~/cloudshell_open/gcp-workshop-tutorial* ~/gcp-workshop-tutorial && git clone -b fix/workshop-hardening https://github.com/GDGonCampusPAU/gcp-workshop-tutorial.git && cloudshell launch-tutorial ~/gcp-workshop-tutorial/tutorial.md
```

Sonra tutorial'ı baştan **Proje Seçimi** adımıyla başlatın.

### Tutorial paneli kayboldu (F5 attınız veya başka hesaba geçtiniz)

Cloud Shell sayfasını yenilediğinizde veya farklı bir Google hesabına geçtiğinizde sağdaki tutorial paneli otomatik kapanır. **Terminale şu komutu yapıştırın** — paneli geri açar (gerekirse repo'yu da yeniden klonlar):

```bash
TUT=$(find ~ -name "tutorial.md" -path "*gcp-workshop*" 2>/dev/null | head -1); [ -z "$TUT" ] && git clone -b fix/workshop-hardening https://github.com/GDGonCampusPAU/gcp-workshop-tutorial.git ~/gcp-workshop-tutorial && TUT=~/gcp-workshop-tutorial/tutorial.md; cloudshell launch-tutorial "$TUT"
```

Tutorial **kaldığınız adımdan** açılmaz; başlangıçtan başlayıp ilerlediğiniz adıma kadar **Next** ile gidin (komutları tekrar çalıştırmanıza gerek yok — `gcloud` ayarlarınız korunur).

### Vertex AI'dan "429 / Resource exhausted" hatası alırsanız

Workshop yoğun saatlerde geçici olabilir. Uygulama otomatik olarak **5 kez tekrar** dener (üstel backoff ile). Yine de hata sürerse 10-20 saniye bekleyip **Summarize Content** butonuna tekrar basın.

---

## 🧹 Workshop sonunda

Tutorial'ın **Temizlik** adımındaki komutları **mutlaka çalıştırın** — Cloud Run servisi ve Artifact Registry repo'su silinir, sonraki günlerde gereksiz ücret oluşmaz. Workshop kredinizin geri kalanı diğer projelerinizde kullanılabilir.

---

## 📞 Destek

Workshop sırasında takıldığınız bir nokta olursa GDG on Campus PAÜ ekibinden yardım isteyin — yanınızdaki eğitmen size eşlik etmek için orada.
