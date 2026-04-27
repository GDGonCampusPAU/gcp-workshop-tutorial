# aGemini ile YouTube Ozetleyici — Cloud Run Workshop

Bu tutorial'da Google'in Gemini AI modelini kullanarak YouTube videolarini ozetleyen bir web uygulamasi olusturacak ve Cloud Run'a deploy edeceksiniz.

**Tahmini sure:** 45-60 dakika
**Maliyet:** Workshop kredisi kullanilir (Vertex AI token bazli ucretlendirme)

Baslamak icin **Start** butonuna tiklayin.

> **Onemli:** Tutorial paneli yuklenmiyorsa VPN'inizi kapatin ve tekrar deneyin.
> 
> **Hesap:** Bu linke tıklamadan once workshop icin kullanacaginiz Google hesabiyla [console.cloud.google.com](https://console.cloud.google.com) adresine giris yaptiginizdan emin olun.

## Proje Secimi

Once mevcut projelerinizi listeleyin:

```sh
gcloud projects list
```

Listeden kullanacaginiz projenin **PROJECT_ID** sutunundaki degeri kopyalayin. Sonra asagidaki komutu calistirin, `PROJE_ID_BURAYA` kismini degistirin:

```sh
gcloud config set project PROJE_ID_BURAYA
```

```sh
export PROJECT_ID=$(gcloud config get-value project)
```

```sh
echo "Aktif proje: $PROJECT_ID"
```

Proje ID'nizi gormelisiniz. Dogru projeyi goruyorsaniz **Next** butonuna basin.

## Billing Hesabini Baglama

API'leri etkinlestirebilmek icin projenize bir billing hesabi baglanmis olmali. Kredi bu billing hesabinda olacak.

### Proje ID'nizi dogrulayin

```sh
echo "Aktif proje: $PROJECT_ID"
```

Proje ID'nizi gormelisiniz. Bos geliyorsa onceki adima donup tekrar deneyin.

### Billing hesabini baglayin

Billing sayfasina gidin:

Tarayicinizda yeni sekme ac ve su adrese git: [console.cloud.google.com/billing](https://console.cloud.google.com/billing)

**Your projects** sekmesine tiklayin, projenizi bulun ve **Actions (3 nokta)** → **Change billing** secin. Acilan listeden workshop kredinizin bulundugu billing hesabini secin ve **Set account** butonuna basin.

Sonra terminalde billing'in aktif oldugunu dogrulayin:

```sh
gcloud billing projects describe $PROJECT_ID --format="value(billingEnabled)"
```

`billingEnabled: true` gormelisiniz. Gormuyorsaniz billing baglamayi tekrar deneyin.

## Gerekli API'leri Etkinlestirme

Bu projede hem AI hem de deploy hizmetlerini kullanacagiz. Asagidaki butona tiklayarak hepsini bir seferde etkinlestirin:

```sh
gcloud services enable run.googleapis.com cloudbuild.googleapis.com
```

```sh
gcloud services enable artifactregistry.googleapis.com aiplatform.googleapis.com
```

```sh
gcloud services enable cloudresourcemanager.googleapis.com
```

**Ne etkinlestirdik?**

- **Cloud Run** — Uygulamamizi serverless olarak calistiracak platform
- **Cloud Build** — Kaynak koddan otomatik Docker image olusturacak servis
- **Cloud Resource Manager** — Proje ve kaynak yonetimi
- **Artifact Registry** — Docker image deposu
- **Vertex AI** — Google'in AI platformu, Gemini modeline erisim saglar

**Tip:** Etkinlestirme birkac saniye surebilir. Yesil tik gorunene kadar bekleyin.

## Vertex AI Izin Kurulumu

Bu uygulama Vertex AI uzerinden Gemini modeline baglanarak YouTube videolarini ozetliyor. Bunun icin Cloud Run servisinin Vertex AI'a erisim iznine ihtiyaci var.

### Proje ID'nizi kaydedin

Once aktif projenizi bir degiskene atayin — bu degiskeni tutorial boyunca kullanacagiz:

```sh
export PROJECT_ID=$(gcloud config get-value project)
```

```sh
echo "Proje ID: $PROJECT_ID"
```

Proje ID'nizi gormelisiniz. Bos geliyorsa proje secmeden devam etmissiniz demektir — geri donup proje secin.

### Gerekli izinleri verin

Bu adimda gerekli tum izinleri tek seferde verecek bir script calistiriyoruz.

Once script dosyasini indirin:

```sh
curl -o setup-iam.sh "https://tinyurl.com/gcp-setup-iam"
```

Sonra calistirin:

```sh
bash setup-iam.sh $PROJECT_ID
```

Script ne yapar:
- Cloud Run servisine Vertex AI, Storage ve Logging izinleri verir
- Cloud Build servisine Artifact Registry, Cloud Run ve IAM izinleri verir

**Ne yapti bu komutlar?**

- **aiplatform.user** — Gemini modeline istek gonderme izni (Compute SA)
- **storage.admin** — Deploy sirasinda kaynak dosyalari Cloud Storage'a yukleme izni (Compute SA)
- **logging.logWriter** — Uygulama loglarini Cloud Logging'e yazma izni (Compute SA)
- **artifactregistry.writer** — Cloud Build'in Docker image'i Artifact Registry'e push etme izni
- **run.admin** — Cloud Build'in Cloud Run servisini olusturma ve guncelleme izni
- **iam.serviceAccountUser** — Cloud Build'in service account adina islem yapabilme izni

**Neden Vertex AI?**
Vertex AI, Google'in kurumsal AI platformudur. Her Gemini cagrisi dogrudan GCP kredinizden dusuler — boylece workshop kredinizi somut olarak kullanmis olursunuz.

## Proje Dosyalarini Indirme

Uygulama dosyalari GitHub'da hazir bekliyor.

```sh
export APP_DIR=$(find ~ -name "summarizer-app" -type d 2>/dev/null | head -1)
echo $APP_DIR
```

```sh
cd $APP_DIR
```

Dosyalari listeleyin:

```sh
ls -la
```

Su dosyalari gormelisiniz:

- **app.py** — Flask backend + Gemini AI entegrasyonu
- **requirements.txt** — Python kutuphaneleri
- **Dockerfile** — Docker paketleme tarifi
- **templates/index.html** — Web arayuzu

**Not:** Bu repo tutorial baslarken otomatik olarak klonlandi. Dosyalar hazir!

## Projeyi Anlama: app.py

Backend kodunu inceleyelim:

```sh
cat app.py
```

### Kodun yaptiklari

**1) Vertex AI baglantisi:**
Uygulama, Vertex AI uzerinden Gemini 2.5 Flash modeline baglanir. API key gerekmez — Cloud Run'un service account kimligini kullanir.

**2) YouTube ozeti nasil calisir:**
Gemini'ye YouTube video URL'si ve bir prompt gonderilir. Gemini videoyu analiz edip ozet uretir. Altyazi zorunlu degil — Gemini videoyu direkt anlayabilir.

**3) Iki temel route (endpoint):**
- `GET /` — Ana sayfayi gosterir (HTML form)
- `POST /summarize` — Video linkini alir, Gemini'ye gonderir, ozeti dondurur

## Projeyi Anlama: index.html

Frontend kodunu inceleyelim:

```sh
cat templates/index.html
```

Kullanicidan iki sey aliyor:

- **YouTube URL** — Ozetlenecek videonun linki
- **Custom Instructions** (opsiyonel) — "Summarize in Turkish" veya "List key points" gibi ozel talimatlar

## Vertex AI ve Gemini Nedir?

Bu projede kullandigimiz en onemli kavram Gemini API.

**Vertex AI:** Google'in kurumsal AI platformu. Gemini dahil tum Google AI modellerine API uzerinden erisim saglar. Her istek GCP kredinizden dusulur.

**Gemini 2.5 Flash:** Google'in hizli ve ekonomik AI modelidir. Metin anlama, ozetleme, soru-cevap gibi gorevlerde cok basarilidir.

**Kodda nasil kullaniliyor?**
```python
import vertexai
from vertexai.generative_models import GenerativeModel

# Vertex AI baslat (proje ID otomatik okunur)
vertexai.init(project=PROJECT_ID, location="us-central1")

# Modeli sec
model = GenerativeModel("gemini-2.5-flash")

# Prompt gonder, ozet al
response = model.generate_content(f"Summarize: {youtube_url}")
```

Bu uc adim tum AI ozetleme mekanizmasinin ozudur.

## Kredi ve Budget Kurulumu

Workshop'ta size verilen krediyi bu projede kullanacaksiniz. Deploy etmeden once budget kurarak harcamayi takip altina alalim.

### Kredinizi kontrol edin

Billing sayfasina gidin:

Tarayicinizda yeni sekme ac ve su adrese git: [console.cloud.google.com/billing](https://console.cloud.google.com/billing)

Sol menuden **Credits** sekmesine tiklayin. Size verilen workshop kredisini burada gormelisiniz.

### Budget Alert kurun

Budget'i Cloud Console uzerinden olusturun:

Tarayicinizda yeni sekme ac ve su adrese git: [console.cloud.google.com/billing](https://console.cloud.google.com/billing)

Sol menuden **Budgets & alerts** sekmesine tiklayin, sonra **Create budget** butonuna basin:

1. Name: "Workshop Budget"
2. Amount: $5
3. Alert thresholds: %50, %90, %100
4. **Finish** butonuna basin

**Tip:** Budget sadece uyari verir, hizmetleri otomatik durdurmaz. Ama ne kadar harcadigini her an bilirsin.

## Cloud Run'a Deploy Etme

Simdi uygulamayi internete aciyoruz!

### Deploy komutunu calistirin

```sh
cd $APP_DIR
```

```sh
export SVC=youtube-summarizer && export SRC=.
```

```sh
gcloud run deploy $SVC --source $SRC --region $REGION --project $PROJECT_ID --allow-unauthenticated
```

Ilk seferde "Do you want to continue (Y/n)?" sorusu gelecek — **Y** yazip Enter'a basin.

**Bu adim 3-5 dakika surebilir.** Python image indiriliyor ve kutuphaneler kuruluyor.

### Basarili deploy ciktisi

```terminal
Service [youtube-summarizer] revision [youtube-summarizer-00001-xxx]
    has been deployed and is serving 100 percent of traffic.
Service URL: https://youtube-summarizer-xxxxx-uc.a.run.app
```

Bu URL sizin AI uygulamanizin adresi!

## Uygulamayi Test Etme

URL'yi bir degiskene atayin:

```sh
export SVC=youtube-summarizer
export FMT='value(status.url)'
```

```sh
export SERVICE_URL=$(gcloud run services describe $SVC --region $REGION --project $PROJECT_ID --format=$FMT)
echo $SERVICE_URL
echo $SERVICE_URL
```

```sh
echo $SERVICE_URL
```

Ana sayfanin calisiyor mu kontrol edin:

```sh
curl -s $SERVICE_URL/ | head -5
```

### Tarayicida test edin

URL'yi kopyalayip tarayicinizin adres cubuguna yapistirin.

1. Herhangi bir YouTube video URL'si yapistirin
2. Opsiyonel: Custom Instructions girin — ornegin "Summarize in Turkish, use bullet points"
3. **Summarize Content** butonuna basin
4. Gemini birkaç saniye icinde ozeti uretecek!

## Cloud Console'dan Inceleme

Deploy ettigimiz servisi goruntusel arayuzden inceleyelim.

Tarayicinizda yeni sekme ac ve su adrese git: [console.cloud.google.com/run](https://console.cloud.google.com/run)

`youtube-summarizer` servisine tiklayip su sekmeleri inceleyin:

- **METRICS** — Kac istek geldi, Gemini kac saniyede yanit verdi
- **LOGS** — Her ozetleme istegi burada gorunur
- **REVISIONS** — Deploy gecmisi, her deploy yeni bir revision olusturur

## Temizlik

Workshop bittikten sonra gereksiz ucret olusmamaasi icin kaynaklari temizleyin.

Cloud Run servisini silin:

```sh
gcloud run services delete $SVC --region $REGION --project $PROJECT_ID
```

Artifact Registry deposunu silin:

```sh
export REPO=cloud-run-source-deploy
gcloud artifacts repositories delete $REPO --location=$REGION --project=$PROJECT_ID
```


Veya projenin tamamini silin:

```sh
gcloud projects delete $PROJECT_ID
```

## Harcama Ozeti — Krediniz Nereye Gitti?

Servisleri sildikten sonra bu projenin toplam ne kadara mal oldugunu goreceğiz.

### Billing Reports sayfasina gidin

Tarayicinizda yeni sekme ac ve su adrese git: [console.cloud.google.com/billing](https://console.cloud.google.com/billing)

Sol menuden **Reports** sekmesine tiklayin.

### Ne goreceksiniz?

Grafik halinde hizmet bazinda harcama dagilimini goreceksiniz:

- **Vertex AI** — Her Gemini cagrisi token basina ucretlendirilir. Kisa bir video ozeti yaklasik $0.001-0.01 arasinda.
- **Cloud Run** — Container calisma suresi. Serverless oldugu icin sadece istek geldiginde ucret olusur.
- **Cloud Build** — Image build suresi. Ilk deploy sonrasi ucret olusur.
- **Artifact Registry** — Docker image depolama.

Sag ust kosedeki tarih filtresini bugunle sinirlandirin. Projenin toplam maliyetini $0.05 - $0.30 arasinda gormeniz beklenir.

**Onemli Not:** Harcamalar anlık gozukmez — birkac saat, bazen 24 saate kadar surebilir. Simdi $0.00 goruyorsaniz normal, birkaç saat sonra tekrar bakin.

**Iste bu kadar!** Workshop boyunca harcanan gercek maliyeti gordunuz. Kredinizin geri kalani diger projelerde kullanilabilir.

## Tebrikler!

Gercek bir AI uygulamasi olusturup internete deploy ettiniz!

**Bu projede ogrendikleriniz:**

- **Vertex AI** — Google'in kurumsal AI platformu uzerinden Gemini modeline erisim
- **IAM** — Service account ile guvenli yetkilendirme
- **Flask full-stack** — Backend + frontend entegrasyonu
- **Cloud Run deploy** — AI destekli uygulamalari serverless deploy etme
- **Budget & Credits** — GCP kredi yonetimi ve maliyet takibi

### Challenge

Kendi basiniza deneyin: Custom Instructions kutusuna farkli diller ve formatlar deneyin:
- "Summarize in Turkish using bullet points"
- "Extract only the key statistics mentioned"
- "Write a tweet-sized summary"

### Faydali linkler

- [Vertex AI dokumantasyonu](https://cloud.google.com/vertex-ai/docs)
- [Gemini on Vertex AI](https://cloud.google.com/vertex-ai/generative-ai/docs/model-reference/gemini)
- [Cloud Run dokumantasyonu](https://cloud.google.com/run/docs)
