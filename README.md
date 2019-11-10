# kovtalex_microservices

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

***

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

***

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

***

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

***

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
