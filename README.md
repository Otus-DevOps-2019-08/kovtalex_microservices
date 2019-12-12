# kovtalex_microservices

[![Build Status](https://travis-ci.com/Otus-DevOps-2019-08/kovtalex_microservices.svg?branch=master)](https://travis-ci.com/Otus-DevOps-2019-08/kovtalex_microservices)

## Устройство Gitlab CI. Построение процесса непрерывной поставки

### Инсталляция Gitlab CI

CI-сервис является одним из ключевых инфраструктурных сервисов в процессе выпуска ПО и к его доступности, бесперебойной работе и безопасности должны предъявляться повышенные требования

Gitlab CI состоит из множества компонент и выполняет ресурсозатратную работу, например, компиляция приложений

Нам потребуется создать в Google Cloud новую виртуальную машину со следующими параметрами:

- 1 CPU
- 3.75GB RAM
- 50-100 GB HDD
- Ubuntu 16.04

В официальной документации описаны рекомендуемые характеристики сервера: <https://docs.gitlab.com/ce/install/requirements.html>

Для создания сервера мы можем использовать любой из удобных нам способов:

- Веб-интерфейс облака Google
- Terraform
- Утилиту gcloud
- Docker-machine

Также нужно разрешить подключение по HTTP/HTTPS

Воспользуемся docker-machine для развертывания виртуальной машины и установки docker на хост

```
docker-machine create --driver google \
 --google-project docker-258208 \
 --google-machine-image https://www.googleapis.com/compute/v1/projects/ubuntu-os-cloud/global/images/family/ubuntu-1604-lts \
 --google-machine-type n1-standard-1 \
 --google-zone europe-west1-b \
 --google-disk-size "100" \
 --google-tags http-server,https-server

eval $(docker-machine env gitlab-ci)
```

Для запуска Gitlab CI мы будем использовать omnibus-установку, у этого подхода есть как свои плюсы, так и минусы.
Основной плюс для нас в том, что мы можем быстро запустить сервис и сконцентрироваться на процессе непрерывной поставки.
Минусом такого типа установки является то, что такую инсталляцию тяжелее эксплуатировать и дорабатывать, но долговременная эксплуатация этого сервиса не входит в наши цели.

Более подробно об этом в документации:

- <https://docs.gitlab.com/omnibus/README.html>
- <https://docs.gitlab.com/omnibus/docker/README.html>

Если потребуется сделать это руками, а также незабудем установить docker-compose

```
sudo  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository "deb https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
sudo apt-get update
sudo apt-get install docker-ce docker-compose -y
sudo mkdir -p /srv/gitlab/config /srv/gitlab/data /srv/gitlab/logs
cd /srv/gitlab/
sudo touch docker-compose.yml
```

docker-compose.yml

```
web:
  image: 'gitlab/gitlab-ce:latest'
  restart: always
  hostname: 'gitlab.example.com'
  environment:
    GITLAB_OMNIBUS_CONFIG: |
      external_url 'http://35.214.222.73'
  ports:
    - '80:80'
    - '443:443'
    - '2222:22'
  volumes:
    - '/srv/gitlab/config:/etc/gitlab'
    - '/srv/gitlab/logs:/var/log/gitlab'
    - '/srv/gitlab/data:/var/opt/gitlab'
```

В той же директории, где docker-compose.yml ( /srv/gitlab )

docker-compose up -d

Для первого запуска Gitlab CI необходимо подождать несколько минут, пока он стартует можно почитать, откуда мы взяли содержимое файла docker-compose.yml: <https://docs.gitlab.com/omnibus/docker/README.html#install-gitlab-using-docker-compose>

Если все прошло успешно, то мы можем в браузере перейти на <http://35.214.222.73> и увидеть там страницу смены пароля (логин root)

Далее

- в настройках Gitlab отключаем Sing-up
- создаем новую группу
- создаем наш новый проект

### Подготовим репозиторий с кодом приложения

выполняем

```
git checkout -b gitlab-ci-1
git remote add gitlab http://34.76.25.244/homework/example.git
git push gitlab gitlab-ci-1
```

### Опишем для приложения этапы пайплайна

Теперь мы можем переходить к определению CI/CD Pipeline для проекта

.gitlab-ci.yml

```
stages:
  - build
  - test
  - deploy

build_job:
  stage: build
  script:
    - echo 'Building'

test_unit_job:
  stage: test
  script:
    - echo 'Testing 1'

test_integration_job:
  stage: test
  script:
    - echo 'Testing 2'

deploy_job:
  stage: deploy
  script:
    - echo 'Deploy'
```

После чего сохраняем файл

```
git add .gitlab-ci.yml
git commit -m 'add pipeline definition'
git push gitlab gitlab-ci-1
```

Теперь если перейти в раздел CI/CD мы увидим, что пайплайн готов к запуску.
Но находится в статусе pending / stuck так как у нас нет runner.
Запустим Runner и зарегистрируем его в интерактивном режиме.

На сервере, где работает Gitlab CI выполним команду:

```
docker run -d --name gitlab-runner --restart always \
-v /srv/gitlab-runner/config:/etc/gitlab-runner \
-v /var/run/docker.sock:/var/run/docker.sock \
gitlab/gitlab-runner:latest
```

После запуска Runner нужно зарегистрировать, это можно сделать командой:

```
Please enter the gitlab-ci coordinator URL (e.g. https://gitlab.com/):
http://35.214.222.73/
Please enter the gitlab-ci token for this runner:
<TOKEN>
Please enter the gitlab-ci description for this runner:
[38689f5588fe]: my-runner
Please enter the gitlab-ci tags for this runner (comma separated):
linux,xenial,ubuntu,docker
Please enter the executor:
docker
Please enter the default Docker image (e.g. ruby:2.1):
alpine:latest
Runner registered successfully.
```

После добавления Runner пайплайн должен был запуститься

Добавим исходный код reddit в репозиторий

```
git clone https://github.com/express42/reddit.git && rm -rf ./reddit/.git
git add reddit/
git commit -m “Add reddit app”
git push gitlab gitlab-ci-1
```

Изменим описание пайплайна в .gitlab-ci.yml

```
image: ruby:2.4.2
stages:
...
variables:
 DATABASE_URL: 'mongodb://mongo/user_posts'
before_script:
 - cd reddit
 - bundle install
...
test_unit_job:
 stage: test
 services:
 - mongo:latest
 script:
 - ruby simpletest.rb
...
...
```

В описании pipeline мы добавили вызов теста в файле simpletest.rb, нужно создать его в папке reddit

simpletest.rb

```
require_relative './app'
require 'test/unit'
require 'rack/test'

set :environment, :test

class MyAppTest < Test::Unit::TestCase
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end

  def test_get_request
    get '/'
    assert last_response.ok?
  end
end
```

Последним шагом нам нужно добавить библиотеку для тестирования в reddit/Gemfile приложения

Добавим gem 'rack-test'

Теперь на каждое изменение в коде приложения будет запущен тест

### Определим окружения

Dev-окружение
Если на dev мы можем выкатывать последнюю версию кода, то к production окружению это может быть неприменимо, если, конечно, ме не стремимся к continuous deployment.

Staging и Production
Определим два новых этапа: stage и production, первый будет содержать job имитирующий выкатку на staging окружение, второй на production окружение.
Определим эти job таким образом, чтобы они запускались с кнопки.
Обычно, на production окружение выводится приложение с явно зафиксированной версией (например, 2.4.10).
Добавим в описание pipeline директиву, которая не позволит нам выкатить на staging и production код не помеченный с помощью тэга в git.

Директива only описывает список условий, которые должны быть истинны, чтобы job мог запуститься.

Регулярное выражение  /^\d+\.\d+\.\d+/ означает, что должен стоять semver тэг в git, например, 2.4.10

Изменение, помеченное тэгом в git запустит полный пайплайн

```
git commit -a -m ‘#4 add logout button to profile page’
git tag 2.4.10
git push gitlab gitlab-ci-1 --tags
```

Динамические окружения

Gitlab CI позволяет определить динамические окружения, это мощная функциональность позволяет вам иметь выделенный стенд для, например, каждой feature-ветки в git

Этот job определяет динамическое окружение для каждой ветки в репозитории, кроме ветки master

```
branch review:
  stage: review
  script: echo "Deploy to $CI_ENVIRONMENT_SLUG"
  environment:
  name: branch/$CI_COMMIT_REF_NAME
  url: http://$CI_ENVIRONMENT_SLUG.example.com
  only:
    - branches
  except:
    - master
```

### Задание со *

#### В шаг build добавить сборку контейнера с приложением reddit

Воспользуемся одним из способов сборки, позволящим собирать образы в контейнере и при этом обойтись без Docker: <https://docs.gitlab.com/ee/ci/docker/using_kaniko.html>

В Gitlab определим переменные для сохранения собранного образа в docker hub

- CI_REGISTRY - https://index.docker.io/v1/
- CI_REGISTRY_BASE64 - вывод команды "echo -n USER:PASSWORD | base64" с данными авторизации к нашему docker hub
- CI_REGISTRY_IMAGE - kovtalex/reddit

Модифицируем наш .gitlab-ci.yml

```
build_job:
  stage: build
  image:
    name: gcr.io/kaniko-project/executor:debug
    entrypoint: [""]
  script:
    - echo 'Building'
    - echo "{\"auths\":{\"$CI_REGISTRY\":{\"auth\":\"$CI_REGISTRY_BASE64\"}}}" > /kaniko/.docker/config.json
    - /kaniko/executor --context $CI_PROJECT_DIR/${PWD##*/} --dockerfile $CI_PROJECT_DIR/${PWD##*/}/Dockerfile --destination $CI_REGISTRY_IMAGE:$CI_COMMIT_TAG
```

В результате будет собран образ и залит в Docker Hub

#### Деплой контейнера с reddit на созданный для ветки сервер

Для деплоя и остановка нашего dev окружения с приложением в контейнере воспользуемся Cloud SDK Docker Image
<https://cloud.google.com/sdk/docs/downloads-docker?refresh=1%29%2C&hl=ru>

- создадим service account на GCP с соответствующей ролью и сгенерируем ключ в формете json
- в Gitlab определим переменную GCLOUD_SERVICE_KEY и запишем данный ключ
- определим переменные для зоны GOOGLE_COMPUTE_ZONE и проекта GOOGLE_PROJECT_ID в .gitlab-ci.yml

Модифицируем наш .gitlab-ci.yml

```
deploy_dev_job:
  stage: review
  image: google/cloud-sdk
  script:
    - echo 'Deploy'
    - echo $GCLOUD_SERVICE_KEY | gcloud auth activate-service-account --key-file=-
    - gcloud --quiet config set project $GOOGLE_PROJECT_ID
    - gcloud --quiet config set compute/zone $GOOGLE_COMPUTE_ZONE
    - gcloud compute ssh docker-host --force-key-file-overwrite --command="docker run --rm -d --name reddit -p 9292:9292 kovtalex/reddit\$(if [ ${CI_COMMIT_TAG} ]; then echo \":\"$CI_COMMIT_TAG; fi)"
  environment:
    name: dev
    url: http://35.233.123.235:9292
    on_stop: stop_dev_job

stop_dev_job:
  stage: review
  image: google/cloud-sdk
  variables:
    GIT_STRATEGY: none
  script:
    - echo "Remove dev env"
    - echo $GCLOUD_SERVICE_KEY | gcloud auth activate-service-account --key-file=-
    - gcloud --quiet config set project $GOOGLE_PROJECT_ID
    - gcloud --quiet config set compute/zone $GOOGLE_COMPUTE_ZONE
    - gcloud compute ssh docker-host --force-key-file-overwrite --command="docker stop \$(docker container ls -q --filter name=reddit)"
  when: manual
  environment:
    name: dev
    action: stop
```

В результате будет развернуто dev окружение с нашим приложением в контейнере на виртуальной машине docker-host в GCP.
Также в Gitlab предусмотрена кнопка ручной остановки данного окружения и нашего приложения

#### Для автоматизации развертывания и регистрации большого количества Runners был подготовлен скрипт multiple_runners.sh

multiple_runners.sh

```
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
```

#### Настройка интеграции Pipeline с текстовым Slack-чатом

Для интеграции был использован материал: <https://docs.gitlab.com/ee/user/project/integrations/slack.html>

Ссылка на канал: <https://devops-team-otus.slack.com/archives/CNET2DVGW>

***

## Docker: сети, docker-compose

### Работа с сетями в Docker

Подключаемся к ранее созданному docker host’у

```
docker-machine ls
eval $(docker-machine env docker-host)
```

#### None network driver

```
docker run -ti --rm --network none joffotron/docker-net-tools -c ifconfig

lo        Link encap:Local Loopback  
          inet addr:127.0.0.1  Mask:255.0.0.0
          UP LOOPBACK RUNNING  MTU:65536  Metric:1
          RX packets:0 errors:0 dropped:0 overruns:0 frame:0
          TX packets:0 errors:0 dropped:0 overruns:0 carrier:0
          collisions:0 txqueuelen:1000
          RX bytes:0 (0.0 B)  TX bytes:0 (0.0 B)
```

В результате, видим:

- что внутри контейнера из сетевых интерфейсов существует только loopback
- сетевой стек самого контейнера работает (ping localhost), но без возможности контактировать с внешним миром
- значит, можно даже запускать сетевые сервисы внутри такого контейнера, но лишь для локальных экспериментов (тестирование, контейнеры для выполнения разовых задач и т.д.)

#### Host network driver

```
docker run -ti --rm --network host joffotron/docker-net-tools -c ifconfig

docker0   Link encap:Ethernet  HWaddr 02:42:40:10:DB:61  
          inet addr:172.17.0.1  Bcast:172.17.255.255  Mask:255.255.0.0
          UP BROADCAST MULTICAST  MTU:1500  Metric:1
          RX packets:0 errors:0 dropped:0 overruns:0 frame:0
          TX packets:0 errors:0 dropped:0 overruns:0 carrier:0
          collisions:0 txqueuelen:0
          RX bytes:0 (0.0 B)  TX bytes:0 (0.0 B)

ens4      Link encap:Ethernet  HWaddr 42:01:0A:84:00:14  
          inet addr:10.132.0.20  Bcast:10.132.0.20  Mask:255.255.255.255
          inet6 addr: fe80::4001:aff:fe84:14%32695/64 Scope:Link
          UP BROADCAST RUNNING MULTICAST  MTU:1460  Metric:1
          RX packets:5032 errors:0 dropped:0 overruns:0 frame:0
          TX packets:3996 errors:0 dropped:0 overruns:0 carrier:0
          collisions:0 txqueuelen:1000
          RX bytes:108579982 (103.5 MiB)  TX bytes:397988 (388.6 KiB)

lo        Link encap:Local Loopback  
          inet addr:127.0.0.1  Mask:255.0.0.0
          inet6 addr: ::1%32695/128 Scope:Host
          UP LOOPBACK RUNNING  MTU:65536  Metric:1
          RX packets:0 errors:0 dropped:0 overruns:0 frame:0
          TX packets:0 errors:0 dropped:0 overruns:0 carrier:0
          collisions:0 txqueuelen:1000
          RX bytes:0 (0.0 B)  TX bytes:0 (0.0 B)
```

Сравним вывод команды с:

```
docker-machine ssh docker-host ifconfig

docker0   Link encap:Ethernet  HWaddr 02:42:40:10:db:61  
          inet addr:172.17.0.1  Bcast:172.17.255.255  Mask:255.255.0.0
          UP BROADCAST MULTICAST  MTU:1500  Metric:1
          RX packets:0 errors:0 dropped:0 overruns:0 frame:0
          TX packets:0 errors:0 dropped:0 overruns:0 carrier:0
          collisions:0 txqueuelen:0
          RX bytes:0 (0.0 B)  TX bytes:0 (0.0 B)

ens4      Link encap:Ethernet  HWaddr 42:01:0a:84:00:14  
          inet addr:10.132.0.20  Bcast:10.132.0.20  Mask:255.255.255.255
          inet6 addr: fe80::4001:aff:fe84:14/64 Scope:Link
          UP BROADCAST RUNNING MULTICAST  MTU:1460  Metric:1
          RX packets:5073 errors:0 dropped:0 overruns:0 frame:0
          TX packets:4043 errors:0 dropped:0 overruns:0 carrier:0
          collisions:0 txqueuelen:1000
          RX bytes:108589111 (108.5 MB)  TX bytes:406354 (406.3 KB)

lo        Link encap:Local Loopback  
          inet addr:127.0.0.1  Mask:255.0.0.0
          inet6 addr: ::1/128 Scope:Host
          UP LOOPBACK RUNNING  MTU:65536  Metric:1
          RX packets:0 errors:0 dropped:0 overruns:0 frame:0
          TX packets:0 errors:0 dropped:0 overruns:0 carrier:0
          collisions:0 txqueuelen:1000
          RX bytes:0 (0.0 B)  TX bytes:0 (0.0 B)
```

Запустим несколько раз (2-4)

```
docker run --network host -d nginx

docker ps
CONTAINER ID        IMAGE               COMMAND                  CREATED             STATUS              PORTS               NAMES
4d877e0422d9        nginx               "nginx -g 'daemon of…"   48 seconds ago      Up 45 seconds                           fervent_nash

docker ps -a
CONTAINER ID        IMAGE               COMMAND                  CREATED              STATUS                          PORTS               NAMES
dc9911e01a6a        nginx               "nginx -g 'daemon of…"   About a minute ago   Exited (1) About a minute ago                       stoic_tereshkova
f403f8e20bbe        nginx               "nginx -g 'daemon of…"   About a minute ago   Exited (1) About a minute ago                       determined_nobel
4d877e0422d9        nginx               "nginx -g 'daemon of…"   About a minute ago   Up About a minute                                   fervent_nash
```

При повторных выполениях команды видно, что в работе остается только один контейнер с nginx, так как при работе с host network driver невозможно задействовать один и тот же порт nginx всеми контейнерами одновременно

docker kill $(docker ps -q)

#### Docker networks

На docker-host машине выполним команду: sudo ln -s /var/run/docker/netns /var/run/netns

Теперь мы можем просматривать существующие в данный момент net-namespaces с помощью команды: sudo ip netns

Повторим запуски контейнеров с использованием драйверов none и host и посмотрим, как меняется список namespace-ов

```
eb4bdda43b65
default
```

ip netns exec <namespace> <command> - позволит выполнять команды в выбранном namespace: sudo ip netns exec eb4bdda43b65 ifconfig

#### Bridge network driver

Создадим bridge-сеть в docker (флаг --driver указывать не обязательно, т.к. по-умолчанию используется bridge)

docker network create reddit --driver bridge

Запустим наш проект reddit с использованием bridge-сети

```
docker run -d --network=reddit mongo:latest
docker run -d --network=reddit kovtalex/post:3.0
docker run -d --network=reddit kovtalex/comment:3.0
docker run -d --network=reddit -p 9292:9292 kovtalex/ui:3.0
```

Сервис не заработает. Тогда решением проблемы будет присвоение контейнерам имен или сетевых алиасов при старте:

```
--name <name> (можно задать только 1 имя)
--network-alias <alias-name> (можно задать множество алиасов)
```

```
docker kill $(docker ps -q)
docker run -d --network=reddit --network-alias=post_db --network-alias=comment_db mongo:latest
docker run -d --network=reddit --network-alias=post kovtalex/post:3.0
docker run -d --network=reddit --network-alias=comment kovtalex/comment:3.0
docker run -d --network=reddit -p 9292:9292 kovtalex/ui:3.0
```

Теперь сервис работает!

Далее запустим наш проект в 2-х bridge сетях. Так , чтобы сервис ui не имел доступа к базе данных

```
docker kill $(docker ps -q)

docker network create back_net --subnet=10.0.2.0/24
docker network create front_net --subnet=10.0.1.0/24

docker run -d --network=front_net -p 9292:9292 --name ui kovtalex/ui:3.0
docker run -d --network=back_net --name comment kovtalex/comment:3.0
docker run -d --network=back_net --name post kovtalex/post:3.0
docker run -d --network=back_net --name mongo_db --network-alias=post_db --network-alias=comment_db mongo:latest

docker network connect front_net post
docker network connect front_net comment
```

Теперь давайте посмотрим как выглядит сетевой стек Linux в текущий момент

```
docker-machine ssh docker-host
sudo apt-get update && sudo apt-get install bridge-utils

sudo docker network ls
NETWORK ID          NAME                DRIVER              SCOPE
7af5f06d2dcf        front_net           bridge              local
f21294d0f6b1        back_net            bridge              local

ifconfig | grep br
br-7af5f06d2dcf Link encap:Ethernet  HWaddr 02:42:85:5b:e9:06  
br-f21294d0f6b1 Link encap:Ethernet  HWaddr 02:42:74:7d:78:98  

brctl show br-7af5f06d2dcf
bridge name     bridge id               STP enabled     interfaces
br-7af5f06d2dcf         8000.0242855be906       no      veth6a9774a
                                                        veth75576e0
                                                        vethfc21e18
brctl show br-f21294d0f6b1
bridge name     bridge id               STP enabled     interfaces
br-f21294d0f6b1         8000.0242747d7898       no      vethd6d46a0
                                                        vethdd9f4f2
                                                        vethfffcad1

Отображаемые veth-интерфейсы - это те части виртуальных пар интерфейсов, которые лежат в сетевом пространстве хоста и также отображаются в ifconfig. Вторые их части лежат внутри контейнеров

sudo iptables -nL -t nat

Правила ниже отвечают за выпуск во внешнюю сеть контейнеров из bridge-сетей
Chain POSTROUTING (policy ACCEPT)
target     prot opt source               destination
MASQUERADE  all  --  10.0.1.0/24          0.0.0.0/0
MASQUERADE  all  --  10.0.2.0/24          0.0.0.0/0
MASQUERADE  all  --  172.18.0.0/16        0.0.0.0/0
MASQUERADE  all  --  172.17.0.0/16        0.0.0.0/0

Строка ниже отвечает за перенаправление трафика на адреса уже конкретных контейнеров
DNAT       tcp  --  0.0.0.0/0            0.0.0.0/0            tcp dpt:9292 to:10.0.1.2:9292

ps ax | grep docker-proxy
15933 ?        Sl     0:00 /usr/bin/docker-proxy -proto tcp -host-ip 0.0.0.0 -host-port 9292 -container-ip 10.0.1.2 -container-port 9292
22290 pts/1    S+     0:00 grep --color=auto docker-proxy

Мы можем увидеть хотя бы 1 запущенный процесс docker-proxy. Этот процесс в данный момент слушает сетевой tcp-порт 9292
```

### Docker-compose

Установка: pip install docker-compose

Создадим docker-compose.yml и выполним

```
docker kill $(docker ps -q)
export USRNAME=kovtalex
docker-compose up -d

docker-compose ps
    Name                  Command             State           Ports
----------------------------------------------------------------------------
src_comment_1   puma                          Up
src_post_1      python3 post_app.py           Up
src_post_db_1   docker-entrypoint.sh mongod   Up      27017/tcp
src_ui_1        puma                          Up      0.0.0.0:9292->9292/tcp
```

Далее

- изменить docker-compose под кейс с множеством сетей, сетевых алиасов
- параметиризуем с помощью переменных окружений: порт публикации сервиса ui, версии сервисов и другие параметры
- параметризованные параметры запишем в отдельный файл c расширением .env
- docker-compose будет подхватить переменные из этого файла автоматически

Базовое имя проекта в нашем случае формируется из имени родительской папки

Изменим базовое имя проекта, к примеру записав переменную в .env: COMPOSE_PROJECT_NAME=reddit

В итоге наш docker-compose.yml будет выглядеть так

```
version: '3.3'
services:
  mongo_db:
    image: mongo:${DB_VER}
    volumes:
      - mongo_db:/data/db
    networks:
      back_net:
        aliases:
          - comment_db
          - post_db
  ui:
    build: ./ui
    image: ${USRNAME}/ui:${UI_VER}
    ports:
      - ${UI_PORT}:${APP_PORT}/tcp
    networks:
      front_net:
          aliases:
            - ui
  post:
    build: ./post-py
    image: ${USRNAME}/post:${POST_VER}
    networks:
      front_net:
        aliases:
          - post
      back_net:

  comment:
    build: ./comment
    image: ${USRNAME}/comment:${COMMENT_VER}
    networks:
      front_net:
        aliases:
          - comment
      back_net:


volumes:
  mongo_db:

networks:
  back_net:
  front_net:
```

### Задание со *

Создадим docker-compose.override.yml для reddit проекта, который позволит

- изменять код каждого из приложений, не выполняя сборку образа задействовав volumes
- добавим команды перезаписи для выполнения puma с флагами --debug -w 2

```
docker ps
CONTAINER ID        IMAGE                  COMMAND                  CREATED             STATUS              PORTS                    NAMES
54ad7a2726d8        mongo:3.2              "docker-entrypoint.s…"   5 minutes ago       Up 5 minutes        27017/tcp                reddit_mongo_db_1
d5dd525a5e91        kovtalex/comment:3.0   "puma --debug -w 2"      5 minutes ago       Up 5 minutes                                 reddit_comment_1
cf7cb9809d85        kovtalex/post:3.0      "python3 post_app.py"    5 minutes ago       Up 5 minutes                                 reddit_post_1
f58fa18fb28e        kovtalex/ui:3.0        "puma --debug -w 2"      5 minutes ago       Up 5 minutes        0.0.0.0:9292->9292/tcp   reddit_ui_1
```

docker-compose.override.yml

```
version: '3.3'
services:
  ui:
    command: 'puma --debug -w 2'
    volumes:
      - ui:/app
  post:
    volumes:
      - post:/app
  comment:
    command: 'puma --debug -w 2'
    volumes:
      - comment:/app
volumes:
  ui:
  post:
  comment:
```

***

## Docker-образы. Микросервисы

Для выполнения ДЗ и проверки Dockerfile воспользуемся линтером: <https://github.com/hadolint/hadolint>

Также для оптимизации инструкций Dockerfile воспользуемся практиками из: <https://docs.docker.com/engine/userguide/eng-image/dockerfile_best-practices/#sort-multi-line-arguments>

```
docker pull hadolint/hadolint

docker run --rm -i hadolint/hadolint < ./ui/Dockerfile
docker run --rm -i hadolint/hadolint < ./comment/Dockerfile  
docker run --rm -i hadolint/hadolint < ./post-py/Dockerfile
```

### Опишем и соберем Docker-образы для сервисного приложения

Подключимся к ранее созданному Docker хосту

```
docker-machine ls
eval $(docker-machine env docker-host)
```

Для удаления
```
docker-machine rm <имя>
```

Для переключения на локальный docker
```
eval $(docker-machine env --unset)
```

Скачаем, распакуем и переименуем в src наше приложение: <https://github.com/express42/reddit/archive/microservices.zip>

Теперь наше приложение состоит из трех компонентов:

- post-py - сервис отвечающий за написание постов
- comment - сервис отвечающий за написание комментариев
- ui - веб-интерфейс, работающий с другими сервисами

Для работы нашего приложения также требуется база данных MongoDB

./post-py/Dockerfile

```
FROM python:3.6.0-alpine

WORKDIR /app
COPY . /app

RUN apk add --no-cache --virtual .build-deps gcc=5.3.0-r0 musl-dev=1.1.14-r16 && pip install -r /app/requirements.txt \
  && apk del .build-deps

ENV POST_DATABASE_HOST post_db
ENV POST_DATABASE posts

ENTRYPOINT ["python3", "post_app.py"]
```

./comment/Dockerfile

```
FROM ruby:2.2
RUN apt-get update -qq && apt-get install --no-install-recommends -y build-essential=11.7 \
  && apt-get clean && rm -rf /var/lib/apt/lists/*

ENV APP_HOME /app
RUN mkdir $APP_HOME
WORKDIR $APP_HOME

COPY Gemfile* $APP_HOME/
RUN bundle install
COPY . $APP_HOME

ENV COMMENT_DATABASE_HOST comment_db
ENV COMMENT_DATABASE comments

CMD ["puma"]
```

./ui/Dockerfile

```
FROM ruby:2.2
RUN apt-get update -qq && apt-get install -y build-essential

ENV APP_HOME /app
RUN mkdir $APP_HOME

WORKDIR $APP_HOME
ADD Gemfile* $APP_HOME/
RUN bundle install
ADD . $APP_HOME

ENV POST_SERVICE_HOST post
ENV POST_SERVICE_PORT 5000
ENV COMMENT_SERVICE_HOST comment
ENV COMMENT_SERVICE_PORT 9292

CMD ["puma"]
```

Скачаем последний образ MongoDB: docker pull mongo:latest

И соберем образы

```
docker build -t kovtalex/post:1.0 ./post-py
docker build -t kovtalex/comment:1.0 ./comment
docker build -t kovtalex/ui:1.0 ./ui
```

Создадим специальную сеть для приложения и запустим наши контейнеры:

```
docker network create reddit

docker run -d --network=reddit --network-alias=post_db --network-alias=comment_db mongo:latest
docker run -d --network=reddit --network-alias=post kovtalex/post:1.0
docker run -d --network=reddit --network-alias=comment kovtalex/comment:1.0
docker run -d --network=reddit -p 9292:9292 kotvalex/ui:1.0
```

- Мы создали bridge-сеть для контейнеров, так как сетевые алиасы не работают в сети по умолчанию.
- Запустили наши контейнеры в этой сети.
- Добавили сетевые алиасы контейнерам.
- Сетевые алиасы могут быть использованы для сетевых соединений, как доменные имена.

Проверим работу: <http://IP:9292/>

Задание со *

- Остановливаем контейнеры: docker kill $(docker ps -q)
- Запускаем контейнеры с другими сетевыми алиасами через переменные окружения передаваемые при старте контейнеров

```
docker run -d --network=reddit --network-alias=reddit_post_db --network-alias=reddit_comment_db mongo:latest
docker run -d --network=reddit --network-alias=reddit_post -e POST_DATABASE_HOST=reddit_post_db kovtalex/post:1.0
docker run -d --network=reddit --network-alias=reddit_comment -e COMMENT_DATABASE_HOST=reddit_comment_db kovtalex/comment:1.0
docker run -d --network=reddit -p 9292:9292 -e POST_SERVICE_HOST=reddit_post -e COMMENT_SERVICE_HOST=reddit_comment kovtalex/ui:1.0
```

- Проверяем работоспособность сервиса

Так как наши образы занимают немало места, начнем их улучшение с ./ui/Dockerfile

```
FROM ubuntu:16.04
RUN apt-get update \
    && apt-get install --no-install-recommends -y ruby-full=* ruby-dev=* build-essential=* \
    && gem install bundler:1.17.3 --no-ri --no-rdoc && apt-get clean && rm -rf /var/lib/apt/lists/*

ENV APP_HOME /app
RUN mkdir $APP_HOME

WORKDIR $APP_HOME
COPY Gemfile* $APP_HOME/
RUN bundle install
COPY . $APP_HOME

ENV POST_SERVICE_HOST post
ENV POST_SERVICE_PORT 5000
ENV COMMENT_SERVICE_HOST comment
ENV COMMENT_SERVICE_PORT 9292

CMD ["puma"]
```

Пересоберем образ ui и проверим его размер

```
docker build -t kovtalex/ui:2.0 ./ui
docker images

REPOSITORY          TAG                 IMAGE ID            CREATED             SIZE
kovtalex/ui         2.0                 6c68271947b0        24 seconds ago      458MB
```

Задание со *

- попробуем уменьшить размер наших образов и начнем с Alpine Linux
- используем apk вместо apt
- уберем mkdir app, так как WORKDIR уже создает необходимую папку
- после установки необходих зависимостей и установки основных компонентов, удалим их
- объеденим поседовательные похожие инструкции в одну

./comment/Dockerfile

```
FROM ruby:2.3-alpine
ENV APP_HOME /app
RUN apk add --no-cache build-base=0.5-r1 && gem install bundler:1.17.3 --no-document

WORKDIR $APP_HOME
COPY . $APP_HOME
RUN bundle install

ENV COMMENT_DATABASE_HOST comment_db
ENV COMMENT_DATABASE comments

CMD ["puma"]
```

./post-py/Dockerfile

```
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
```

./ui/Dockerfile

```
FROM ruby:2.3-alpine
ENV APP_HOME /app
RUN apk add --no-cache build-base=0.5-r1 && gem install bundler:1.17.3 --no-document

WORKDIR $APP_HOME
COPY . $APP_HOME
RUN bundle install

ENV POST_SERVICE_HOST post
ENV POST_SERVICE_PORT 5000
ENV COMMENT_SERVICE_HOST comment
ENV COMMENT_SERVICE_PORT 9292

CMD ["puma"]
```

Пересоберем:

```
docker build -t kovtalex/post:3.0 ./post-py
docker build -t kovtalex/comment:3.0 ./comment
docker build -t kovtalex/ui:3.0 ./ui
```

Выключим старые копии контейнеров: docker kill $(docker ps -q)

Запустим новые копии контейнеров и проверим работу приложения:

```
docker run -d --network=reddit --network-alias=post_db --network-alias=comment_db mongo:latest
docker run -d --network=reddit --network-alias=post kovtalex/post:3.0
docker run -d --network=reddit --network-alias=comment kovtalex/comment:3.0
docker run -d --network=reddit -p 9292:9292 kovtalex/ui:3.0
```

Так как наши данные пропадают при каждой остановке контейнера mongo воспользуемся Docker Volume: docker volume create reddit_db

Выключим старые копии контейнеров: docker kill $(docker ps -q)

Запустим новые копии контейнеров и mongo с подключенным Docker Volume:

```
docker run -d --network=reddit --network-alias=post_db --network-alias=comment_db -v reddit_db:/data/db mongo:latest
docker run -d --network=reddit --network-alias=post kovtalex/post:3.0
docker run -d --network=reddit --network-alias=comment kovtalex/comment:3.0
docker run -d --network=reddit -p 9292:9292 kovtalex/ui:3.0
```

- Зайдем на http://IP:9292/ и проверим работу приложения
- Напишем пост
- Перезапустим контейнеры снова
- Проверим, что пост остался на месте

Также проверим, что после оптимизаци наши образы стали занимать меньше места: docker images

```
REPOSITORY          TAG                 IMAGE ID            CREATED             SIZE
kovtalex/ui         3.0                 b3594948cd1a        About an hour ago   297MB
kovtalex/ui         2.0                 696f9010f0b4        About an hour ago   411MB
kovtalex/ui         1.0                 ee289401bd4c        About an hour ago   783MB
kovtalex/post       3.0                 ee39d83673df        About an hour ago   109MB
kovtalex/post       1.0                 5cfd7419f2f5        About an hour ago   109MB
kovtalex/comment    3.0                 84bbc760cf18        About an hour ago   295MB
kovtalex/comment    1.0                 013c2292f299        About an hour ago   770MB
```

***

## Технология контейнеризации. Введение в Docker

### Знакомство с Docker

Устанавливаем

- Docker – 17.06+
- docker-compose – 1.14+
- docker-machine – 0.12.0+

- Ubuntu Linux: <https://docs.docker.com/engine/installation/linux/docker-ce/ubuntu/>
- Mac OS: <https://download.docker.com/mac/stable/Docker.dmg>
- Windows: <https://download.docker.com/win/stable/Docker%20for%20Windows%20Installer.exe>

Команды

- docker version - вывод версии docker client и server
- docker info – вывод информации о текущем состоянии docker daemon
- docker run - создание и запуск контейнера из image (каждый раз запускает новый контейнер)

```
docker run = docker create + docker start + docker attach если указан флаг -i
Если не указывать флаг --rm при запуске docker run, то после остановки контейнер вместе с содержимым остается на диске

Через параметры передаются лимиты(cpu/mem/disk), ip, volumes
-i – запускает контейнер в foreground режиме (docker attach)
-d – запускает контейнер в background режиме
-t создает TTY

docker run -it ubuntu:16.04 bash
docker run -dt nginx:latest
```  

- docker ps - вывод списока запущенных контейнеров
- docker ps -a - вывод списока всех контейнеров (--format "table {{.ID}}\t{{.Image}}\t{{.CreatedAt}}\t{{.Names}}" )
- docker images - вывод списока сохранненных образов
- docker start - запускает остановленный (уже созданный) контейнер
- docker attach - подсоединяет терминал к созданному контейнеру
- docker create - используется, когда не нужно стартовать контейнер сразу
- docker exec - запускает новый процесс внутри контейнера (например /bin/bash внутри контейнера с приложением)
- docker commit - создает image из контейнера (контейнер при этом остается запущенным)
- docker kill - kill сразу посылает SIGKILL (сигнал остановки приложения)

```
docker kill $(docker ps -q)
```

- docker stop - stop посылает SIGTERM (безусловное завершение процесса) и через 10 секунд(настраивается) посылает SIGKILL
- docker system df - отображает сколько дискового пространства занято образами, контейнерами и volume’ами. Отображает сколько из них не используется и возможно удалить
- docker rm - удаляет контейнер, можно добавить флаг -f, чтобы удалялся работающий container(будет послан sigkill)
- docker rmi  - удаляет image, если от него не зависят запущенные контейнеры
- docker inspect - получение метаданных о контейнере или образе

Создаем и запускаем контейнер из образа:

```
sudo docker run -it ubuntu:16.04 /bin/bash
echo 'Hello world!' > /tmp/file
exit
```

Вывод списка всех контейнеров

```
sudo docker ps -a
CONTAINER ID        IMAGE               COMMAND             CREATED             STATUS                     PORTS               NAMES
5762a59a8283        ubuntu:16.04        "/bin/bash"         13 seconds ago      Exited (0) 3 seconds ago                       stupefied_fermi
```

Создание образа из контейнера

```
sudo  docker commit 5762a59a8283 kovtalex/ubuntu-tmp-file
sha256:68b5ebc9d2dedfc49276fa5e5c28015f4891693346579b98572b6dd06287a07f
```

Вывод списка образов

```
sudo docker images
REPOSITORY                 TAG                 IMAGE ID            CREATED             SIZE
kovtalex/ubuntu-tmp-file   latest              68b5ebc9d2de        14 seconds ago      123MB
```

### Docker контейнеры в GCE

- Создаем новый проект <https://console.cloud.google.com/compute> и называем его docker
- Выполняем gcloud init и выбираем наш новый проект
- Далее gcloud auth application-default login
- Устанавливаем Docker machine <https://docs.docker.com/machine/install-machine/>

```
- docker-machine - встроенный в докер инструмент для создания хостов и установки на них docker engine. Имеет поддержку облаков и систем виртуализации (Virtualbox, GCP и др.)
- Команда создания - docker-machine create <имя>. Имен может быть много, переключение между ними через eval $(docker-machine env <имя>). Переключение на локальный докер
- eval $(docker-machine env --unset). Удаление - docker-machine rm <имя>.
- docker-machine создает хост для докер демона со указываемым образом в --googlemachine-image, в ДЗ используется ubuntu-16.04. Образы которые используются для построения докер контейнеров к этому никак не относятся.
- Все докер команды, которые запускаются в той же консоли после eval $(docker-machine env <имя>) работают с удаленным докер демоном в GCP.
```

- выполняем  export GOOGLE_PROJECT=docker-258208
- выполняем

```
 docker-machine create --driver google \
 --google-machine-image https://www.googleapis.com/compute/v1/projects/ubuntu-os-cloud/global/images/family/ubuntu-1604-lts \
 --google-machine-type n1-standard-1 \
 --google-zone europe-west1-b \
 docker-host
```

- docker-machine ls - проверяем, что наш Docker-хост успешно создан

```
NAME          ACTIVE   DRIVER   STATE     URL                        SWARM   DOCKER     ERRORS
docker-host   -        google   Running   tcp://35.233.48.104:2376           v19.03.4  
```

- eval $(docker-machine env docker-host) - и начинаем с ним работу

Повторение практики из демо на лекции по сравнению вывода htop внутри контейнера и хоста:

- docker run --rm -ti tehbilly/htop (htop контейнера)
- docker run --rm --pid host -ti tehbilly/htop (htop хостовой машины)

### Создание своего образа

- Dockerfile - текстовое описание нашего образа
- mongod.conf - подготовленный конфиг для mongodb
- db_config - содержит переменную окружения со ссылкой на mongodb
- start.sh - скрипт запуска приложения

Вся работа происходит в папке docker-monolith

mongod.conf

```
# Where and how to store data.
storage:
  dbPath: /var/lib/mongodb
  journal:
    enabled: true

# where to write logging data.
systemLog:
  destination: file
  logAppend: true
  path: /var/log/mongodb/mongod.log

# network interfaces
net:
  port: 27017
  bindIp: 127.0.0.1
```

start.sh

```
#!/bin/bash

/usr/bin/mongod --fork --logpath /var/log/mongod.log --config /etc/mongodb.conf

source /reddit/db_config

cd /reddit && puma || exit
```

db_config

```
DATABASE_URL=127.0.0.1
```

Dockerfile

```
FROM ubuntu:16.04

RUN apt-get update
RUN apt-get install -y mongodb-server ruby-full ruby-dev build-essential git
RUN gem install bundler
RUN git clone -b monolith https://github.com/express42/reddit.git

COPY mongod.conf /etc/mongod.conf
COPY db_config /reddit/db_config
COPY start.sh /start.sh

RUN cd /reddit && bundle install
RUN chmod 0777 /start.sh

CMD ["/start.sh"]
```

Собираем образ

```
 docker build -t reddit:latest .

- Точка в конце обязательна, она указывает на путь до Docker-контекста
- Флаг -t задает тег для собранного образа
```

Посмотрим на все образы (в том числе промежуточные)

```
docker images -a
REPOSITORY             TAG                 IMAGE ID            CREATED             SIZE
kovtalex/otus-reddit   1.0                 b9dc7f4c5c8d        33 hours ago        691MB
```

Запускаем наш контейнер

```
docker run --name reddit -d --network=host reddit:latest

9bfcfa27173e268fa2f0b2bc7131d76269dd31b6cf8b5c3e2c099d985ad9d949
```

Проверим результат

```
docker-machine ls

NAME          ACTIVE   DRIVER   STATE     URL                        SWARM   DOCKER     ERRORS
docker-host   *        google   Running   tcp://35.233.48.104:2376           v19.03.4
```

Разрешим входящий TCP-трафик на порт 9292 выполнив команду

```
gcloud compute firewall-rules create reddit-app \
--allow tcp:9292 \
--target-tags=docker-machine \
--description="Allow PUMA connections" \
--direction=INGRESS

NAME        NETWORK  DIRECTION  PRIORITY  ALLOW     DENY  DISABLED
reddit-app  default  INGRESS    1000      tcp:9292        False
```

Открываем ссылку <http://IP:9292> и проверяем работу нашего приложения

### Работа с Docker hub

Docker Hub - это облачный registry сервис от компании Docker. В него можно выгружать и загружать из него докер образы. Docker по умолчанию скачивает образы из докер хаба.

Регистрируемся <https://hub.docker.com/>

Аутентифицируемся на docker hub для продолжения работы: docker login

Загрузим наш образ на docker hub для использования в будущем:

```
docker tag reddit:latest kovtalex/otus-reddit:1.0
```

Т.к. теперь наш образ есть в докер хабе, то мы можем запустить его не только в докер хосте в GCP, но и в вашем локальном докере или на другом хосте.

Выполним в другой консоли

```
docker run --name reddit -d -p 9292:9292 kovtalex/otus-reddit:1.0
```

И проверим, что в локальный докер скачался загруженный ранее образ и приложение работает

### Задание со *

Для выполнения задания со * в виде прототипа в директории /docker-monolith/infra/ было релизовано:

- поднятие инстансов с помощью Terraform (количество инстансов задается переменной node_count в variables.json)

```
terrform
├── backend.tf
├── main.tf
├── modules
│   ├── docker
│   │   ├── main.tf
│   │   ├── outputs.tf
│   │   └── variables.tf
│   └── vpc
│       ├── main.tf
│       └── variables.tf
├── outputs.tf
├── terraform.tfvars
├── terraform.tfvars.example
└── variables.tf

terraform apply -auto-approve
```

- Написан плейбук Ansible с ипользованием динамического инвентори для установки докера на хост: docker_host.yml
- Написан плейбук Ansible с ипользованием динамического инвентори для запуска образа приложения на хосте: deploy.yml

```
ansible
├── ansible.cfg
├── inventory.gcp.yml
├── playbooks
│   ├── deploy.yml
│   └── docker_host.yml
└── requirements.txt

ansible-playbook playbooks/docker_host.yml
ansible-playbook playbooks/deploy.yml
````

- Написан шаблон для Packer по созданию образа с уже установленным Docker

```
packer
├── docker.json
└── variables.json

packer build -var-file=packer/variables.json packer/docker.json
```
