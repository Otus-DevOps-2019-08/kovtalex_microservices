FROM ubuntu:16.04

RUN apt-get update
RUN apt-get install -y mongodb-server ruby-full ruby-dev build-essential
RUN gem install bundler

COPY mongod.conf /etc/mongod.conf

RUN ls -la
RUN bundle install
RUN /usr/bin/mongod --fork --logpath /var/log/mongod.log --config /etc/mongodb.conf
RUN ls -la
RUN source db_config

CMD ["puma || exit"]
