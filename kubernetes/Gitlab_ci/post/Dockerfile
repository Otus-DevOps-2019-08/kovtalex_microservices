FROM python:3.6.0-alpine
ENV APP_HOME /app
WORKDIR $APP_HOME
COPY requirements.txt $APP_HOME

RUN apk add --no-cache --virtual .build-deps gcc=5.3.0-r0 musl-dev=1.1.14-r16 && pip install -r /app/requirements.txt && \
    apk del .build-deps

COPY . $APP_HOME

ENV POST_DATABASE_HOST post_db
ENV POST_DATABASE posts

ENTRYPOINT ["python3", "post_app.py"]
