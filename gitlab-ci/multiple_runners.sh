#!/bin/bash

# How to run
# sudo sh multiple_runners.sh <number> <gitlab_url> <gitlab_token>

i=1
while [ "$i" -le $1 ]; do
  docker run -d --name gitlab-runner$i --restart always \
  -v /srv/gitlab-runner$i/config:/etc/gitlab-runner \
  -v /var/run/docker.sock:/var/run/docker.sock \
  gitlab/gitlab-runner:latest 

  docker exec -it gitlab-runner$i gitlab-runner \
  register --non-interactive --executor "docker" \
  --docker-image alpine:latest --url "$2" --registration-token $3 \
  --description "docker-runner"$i --tag-list "linux,xenial,ubuntu,docker" \
  --run-untagged="true" --locked="false" --access-level="not_protected"
  i=$(( i + 1 ))
done
