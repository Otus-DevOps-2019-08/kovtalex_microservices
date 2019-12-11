FROM ubuntu:16.04

RUN apt-get update
RUN apt-get install -y mongodb-server ruby-full ruby-dev build-essential
RUN gem install bundler

COPY mongod.conf /etc/mongod.conf

RUN bundle install
RUN chmod 0777 /start.sh
RUN /usr/bin/mongod --fork --logpath /var/log/mongod.log --config /etc/mongodb.conf
RUN source db_config

CMD ["puma || exit"]
