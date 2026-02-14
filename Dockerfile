FROM python:3.11-slim

WORKDIR /data

RUN pip install --no-cache-dir django==3.2 PyMySQL==1.1.1 psycopg2-binary==2.9.10

COPY . .

RUN python manage.py migrate

EXPOSE 8000

CMD ["python","manage.py","runserver","0.0.0.0:8000"]
