FROM ubuntu:16.04

RUN apt-get update
RUN apt-get install -y mongodb-server ruby-full ruby-dev build-essential git
RUN gem install bundler

WORKDIR /reddit

COPY . /reddit
COPY mongod.conf /etc/mongod.conf

RUN cd /reddit && bundle install
RUN ls -la
RUN chmod 0777 /reddit/start.sh

CMD ["sh start.sh"]
