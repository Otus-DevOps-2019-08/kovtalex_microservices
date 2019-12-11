FROM ubuntu:16.04

RUN apt-get update
RUN apt-get install -y mongodb-server ruby-full ruby-dev build-essential git
RUN gem install bundler

WORKDIR /reddit

COPY mongod.conf /etc/mongod.conf
COPY . /reddit

RUN cd /reddit && bundle install
RUN /usr/bin/mongod --fork --logpath /var/log/mongod.log --config /etc/mongodb.conf
RUN source /reddit/db_config

CMD ["cd /reddit && puma || exit"]
