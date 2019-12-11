FROM ruby:2.3-alpine
ENV APP_HOME /app
RUN apk add --no-cache build-base=0.5-r1 && gem install bundler:1.17.3 --no-document

WORKDIR $APP_HOME
COPY . $APP_HOME
RUN cd /$APP_HOME && bundle install

ENV SERVER_IP 127.0.0.1
ENV REPO_NAME kovtalex/reddit
ENV DEPLOY_USER deploy

CMD ["bundle exec cap production deploy:initial"]
