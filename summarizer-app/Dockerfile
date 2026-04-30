FROM python:3.11-slim
 
WORKDIR /app
 
# Once requirements kopyala (layer caching icin)
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
 
# Uygulama kodunu kopyala
COPY . .
 
# Cloud Run PORT degiskenini dinle
ENV PORT=8080
 
CMD exec gunicorn --bind :$PORT --workers 1 --threads 8 app:app
