# kovtalex_microservices

## Технология контейнеризации. Введение в Docker

### Знакомство с командами docker

Команды:
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

sudo docker run -it ubuntu:16.04 /bin/bash
root@5762a59a8283:/# 
root@5762a59a8283:/# 
root@5762a59a8283:/#  echo 'Hello world!' > /tmp/file
root@5762a59a8283:/# exit

sudo docker ps -a                         
CONTAINER ID        IMAGE               COMMAND             CREATED             STATUS                     PORTS               NAMES
5762a59a8283        ubuntu:16.04        "/bin/bash"         13 seconds ago      Exited (0) 3 seconds ago                       stupefied_fermi

sudo  docker commit 5762a59a8283 kovtalex/ubuntu-tmp-file
sha256:68b5ebc9d2dedfc49276fa5e5c28015f4891693346579b98572b6dd06287a07f

sudo docker images
REPOSITORY                 TAG                 IMAGE ID            CREATED             SIZE
kovtalex/ubuntu-tmp-file   latest              68b5ebc9d2de        14 seconds ago      123MB
ubuntu                     16.04               5f2bf26e3524        5 days ago          123MB
nginx                      latest              540a289bab6c        2 weeks ago         126MB
hello-world                latest              fce289e99eb9        10 months ago       1.84kB



 docker-machine create --driver google \
 --google-machine-image https://www.googleapis.com/compute/v1/projects/ubuntu-os-cloud/global/images/family/ubuntu-1604-lts \
 --google-machine-type n1-standard-1 \
 --google-zone europe-west1-b \
 docker-host

docker-machine ls
```
NAME          ACTIVE   DRIVER   STATE     URL                        SWARM   DOCKER     ERRORS
docker-host   -        google   Running   tcp://35.233.48.104:2376           v19.03.4  
```

eval $(docker-machine env docker-host)

 docker build -t reddit:latest .
```
- Точка в конце обязательна, она указывает на путь до Docker-контекста
- Флаг -t задает тег для собранного образа
```

Successfully built b9dc7f4c5c8d
Successfully tagged reddit:latest

docker images -a 

docker run --name reddit -d --network=host reddit:latest
9bfcfa27173e268fa2f0b2bc7131d76269dd31b6cf8b5c3e2c099d985ad9d949

docker-machine ls
NAME          ACTIVE   DRIVER   STATE     URL                        SWARM   DOCKER     ERRORS
docker-host   *        google   Running   tcp://35.233.48.104:2376           v19.03.4   

 gcloud compute firewall-rules create reddit-app \
 --allow tcp:9292 \
 --target-tags=docker-machine \
 --description="Allow PUMA connections" \
 --direction=INGRESS

NAME        NETWORK  DIRECTION  PRIORITY  ALLOW     DENY  DISABLED
reddit-app  default  INGRESS    1000      tcp:9292        False

docker tag reddit:latest kovtalex/otus-reddit:1.0

docker run --name reddit -d -p 9292:9292 kovtalex/otus-reddit:1.0





 packer build -var-file=packer/variables.json packer/docker.json
 terraform apply -auto-approve
 cd ansible
 ansible-playbook playbooks/deploy.yml