# kovtalex_microservices

[![Build Status](https://travis-ci.com/Otus-DevOps-2019-08/kovtalex_microservices.svg?branch=master)](https://travis-ci.com/Otus-DevOps-2019-08/kovtalex_microservices)





helm install reddit --name reddit-test
NAME:   reddit-test
LAST DEPLOYED: Mon Feb 24 22:53:35 2020
NAMESPACE: default
STATUS: DEPLOYED

RESOURCES:
==> v1/Deployment
NAME                 AGE
reddit-test-comment  1s
reddit-test-mongodb  1s
reddit-test-post     1s
reddit-test-ui       1s

==> v1/PersistentVolumeClaim
NAME                 AGE
reddit-test-mongodb  1s

==> v1/Pod(related)
NAME                                  AGE
reddit-test-comment-67f446fd65-tlcfm  1s
reddit-test-mongodb-5f647684fd-5jzvq  1s
reddit-test-post-6d77f85b68-7xf9h     1s
reddit-test-ui-5587d6c6d6-52s49       1s

==> v1/Service
NAME                 AGE
reddit-test-comment  1s
reddit-test-mongodb  1s
reddit-test-post     1s
reddit-test-ui       1s

==> v1beta1/Ingress
NAME            AGE
reddit-test-ui  1s


kubectl delete deployment tiller-deploy -n kube-system

helm plugin install https://github.com/rimusz/helm-tiller


helm tiller run -- helm upgrade --install --wait --namespace=reddit-ns reddit reddit/
Installed Helm version v2.16.3
Installed Tiller version v2.16.3
Helm and Tiller are the same version!
Starting Tiller...
Tiller namespace: kube-system
Running: helm upgrade --install --wait --namespace=reddit-ns reddit reddit/

Release "reddit" does not exist. Installing it now.
NAME:   reddit
LAST DEPLOYED: Mon Feb 24 23:07:22 2020
NAMESPACE: reddit-ns
STATUS: DEPLOYED

RESOURCES:
==> v1/Deployment
NAME            AGE
reddit-comment  38s
reddit-mongodb  38s
reddit-post     38s
reddit-ui       38s

==> v1/PersistentVolumeClaim
NAME            AGE
reddit-mongodb  39s

==> v1/Pod(related)
NAME                             AGE
reddit-comment-6b9948f5bc-l2g8l  38s
reddit-mongodb-956b47dc7-hdgvs   38s
reddit-post-c4b7df4b8-9qqj6      38s
reddit-ui-86c87d7467-mx6kr       38s

==> v1/Service
NAME            AGE
reddit-comment  39s
reddit-mongodb  39s
reddit-post     39s
reddit-ui       39s

==> v1beta1/Ingress
NAME       AGE
reddit-ui  38s


Stopping Tiller...



kubectl get ingress -n reddit-ns
NAME        HOSTS   ADDRESS        PORTS   AGE
reddit-ui   *       35.241.63.88   80      84s


brew install helm@2
brew install helm
cd /usr/local/bin
ln -s /usr/local/opt/helm@2/bin/tiller tiller
ln -s /usr/local/opt/helm@2/bin/helm helm2
ln -s helm helm3


kubectl create ns new-helm

helm3 upgrade --install --namespace=new-helm --wait reddit-release reddit/
Release "reddit-release" does not exist. Installing it now.
NAME: reddit-release
LAST DEPLOYED: Mon Feb 24 23:30:24 2020
NAMESPACE: new-helm
STATUS: deployed
REVISION: 1
TEST SUITE: None

helm init --service-account tiller --upgrade

kubectl get pods -n kube-system --selector app=helm



helm upgrade gitlab . -f values.yaml


kubectl get service -n nginx-ingress nginx 
NAME    TYPE           CLUSTER-IP    EXTERNAL-IP      PORT(S)                                   AGE
nginx   LoadBalancer   10.64.15.27   35.187.174.131   80:32757/TCP,443:31324/TCP,22:30117/TCP   8m18s

kubectl get pods
NAME                                        READY   STATUS    RESTARTS   AGE
gitlab-gitlab-74bbf4bddf-fqlvz              1/1     Running   0          8m18s
gitlab-gitlab-postgresql-6b4477dd4c-7l7ft   1/1     Running   0          8m18s
gitlab-gitlab-redis-5b6db96bf9-wqrmw        1/1     Running   0          8m18s
gitlab-gitlab-runner-844d9b68b7-42s9s       1/1     Running   5          8m18s

git init
git remote add origin http://gitlab-gitlab/kovtalex/ui.git
git add .
git commit -m “init”
git push origin master

git init
git remote add origin http://gitlab-gitlab/kovtalex/post.git
git add .
git commit -m “init”
git push origin master

git init
git remote add origin http://gitlab-gitlab/kovtalex/comment.git
git add .
git commit -m “init”
git push origin master

git init
git remote add origin http://gitlab-gitlab/kovtalex/reddit-deploy.git
git add .
git commit -m “init”
git push origin master


## Kubernetes. Networks and Storages

### Service

**Service** - определяет **конечные узлы доступа** (Endpoint’ы):

- селекторные сервисы (k8s сам находит POD-ы по label’ам)
- безселекторные сервисы (мы вручную описываем конкретные endpoint’ы)

и **способ коммуникации** с ними (тип (type) сервиса):

- ClusterIP - дойти до сервиса можно только изнутри кластера
- nodePort - клиент снаружи кластера приходит на опубликованный порт
- LoadBalancer - клиент приходит на облачный (aws elb, Google gclb) ресурс балансировки
- ExternalName - внешний ресурс по отношению к кластеру

Вспомним, как выглядели Service’ы:

post-service.yml

```yml
---
apiVersion: v1
kind: Service
metadata:
  name: post
  labels:
    app: reddit
    component: post
spec:
  ports:
  - port: 5000
    protocol: TCP
    targetPort: 5000
  selector:
    app: reddit
    component: post
```

Это селекторный сервис типа **ClusetrIP** (тип не указан, т.к. этот тип по-умолчанию)
> selector:
>
> app: reddit
>
> component: post

**ClusterIP** - это виртуальный (в реальности нет интерфейса, pod’а или машины с таким адресом) IP-адрес из диапазона адресов для работы внутри, скрывающий за собой IP-адреса реальных POD-ов. Сервису любого **типа** (кроме ExternalName) назначается этот IP-адрес.

```console
kubectl get services -n dev

NAME         TYPE        CLUSTER-IP   EXTERNAL-IP   PORT(S)          AGE
comment      ClusterIP   10.0.2.59    <none>        9292/TCP         5h16m
comment-db   ClusterIP   10.0.8.157   <none>        27017/TCP        5h16m
mongodb      ClusterIP   10.0.11.37   <none>        27017/TCP        5h16m
post         ClusterIP   10.0.4.39    <none>        5000/TCP         5h16m
post-db      ClusterIP   10.0.7.234   <none>        27017/TCP        5h16m
ui           NodePort    10.0.6.3     <none>        9292:32093/TCP   5h16m
```

### Kube-dns

Отметим, что **Service** - это лишь абстракция и описание того, как получить доступ к сервису. Но опирается она на реальные механизмы и объекты: DNS-сервер, балансировщики, iptables. Для того, чтобы дойти до сервиса, нам нужно узнать его адрес по имени. Kubernetes не имеет своего собственного DNS сервера для разрешения имен. Поэтому используется плагин **kube-dns** (это тоже Pod).

Его задачи:

- ходить в API Kubernetes’a и отслеживать Service-объекты
- заносить DNS-записи о Service’ах в собственную базу
- предоставлять DNS-сервис для разрешения имен в IP-адреса (как внутренних, так и внешних)

Можем убедиться, что при отключенном **kube-dns** сервисе связность между компонентами reddit-app пропадет и он перестанет работать.

- Проскейлим в 0 сервис, который следит, чтобы dns-kube подов всегда хватало:

```console
kubectl scale deployment --replicas 0 -n kube-system kube-dns-autoscaler
```

- Проскейлим в 0 сам kube-dns:

```console
kubectl scale deployment --replicas 0 -n kube-system kube-dns
```

- Попробуем достучатсья по имени до любого сервиса:

```console:
 kubectl exec -ti -n dev post-5f6bd9dfc7-wcbjl ping comment

ping: bad address 'comment'
command terminated with exit code 1
```

- Вернем kube-dns-autoscale в исходную:

```console
kubectl scale deployment --replicas 1 -n kube-system kube-dns-autoscaler
kubectl scale deployment --replicas 1 -n kube-system kube-dns
```

- Проверим, что приложение заработало.

Как уже говорилось, **ClusterIP** - виртуальный и не принадлежит ни одной реальной физической сущности. Его чтением и дальнейшими действиями с пакетами,  принадлежащими ему, занимается в нашем случае **iptables**, который настраивается утилитой **kube-proxy** (забирающей инфу с API-сервера).

Сам kube-proxy, можно настроить на прием трафика, но это устаревшее поведение и **не рекомендуется** его применять.

На любой из нод кластера можно посмотреть эти правила **IPTABLES**.

На самом деле, независимо от того, на одной ноде находятся поды или на разных - трафик проходит через цепочку, изображенную на предыдущем слайде.

Kubernetes не имеет в комплекте механизма организации overlayсетей (как у Docker Swarm). Он лишь предоставляет интерфейс для этого. Для создания Overlay-сетей используются отдельные аддоны: Weave, Calico, Flannel, … . В Google Kontainer Engine (GKE) используется собственный плагин **kubenet** (он - часть kubelet).

Он работает **только** вместе с платформой **GCP** и, по-сути занимается тем, что настраивает google-сети для передачи трафика Kubernetes. Поэтому в конфигурации Docker сейчас мы не увидим никаких Overlay-сетей.

Посмотреть правила, согласно которым трафик отправляется на ноды можно здесь: <https://console.cloud.google.com/networking/routes/

### NodePort

Service с типом **NodePort** - похож на сервис типа **ClusterIP**, только к нему прибавляется прослушивание портов нод (всех нод) для доступа к сервисам **снаружи**. При этом **ClusterIP** также назначается этому сервису для доступа к нему изнутри кластера.

**kube-proxy** прослушивается либо заданный порт (nodePort: 32092), либо порт из диапазона 30000-32670.

Дальше IPTables решает, на какой Pod попадет трафик.

Сервис UI мы уже публиковали наружу с помощью **NodePort**.

ui-service.yml

```yml
---
apiVersion: v1
kind: Service
metadata:
  name: ui
  labels:
    app: reddit
    component: ui
spec:
  type: NodePort
  ports:
  - port: 9292
    nodePort: 32092
    protocol: TCP
    targetPort: 9292
  selector:
    app: reddit
    component: ui
```

> type: NodePort
> nodePort: 32092

### LoadBalancer

Тип NodePort хоть и предоставляет доступ к сервису снаружи, но открывать все порты наружу или искать IPадреса наших нод (которые вообще динамические) не очень удобно.

Тип **LoadBalancer** позволяет нам использовать **внешний облачный** балансировщик нагрузки как единую точку входа в наши сервисы, а не полагаться на IPTables и не открывать наружу весь кластер.

Настроим соответствующим образом Service UI:

ui-service.yml

```yml
---
apiVersion: v1
kind: Service
metadata:
  name: ui
  labels:
    app: reddit
    component: ui
spec:
  type: LoadBalancer
  ports:
  - port: 80
    nodePort: 32092
    protocol: TCP
    targetPort: 9292
  selector:
    app: reddit
    component: ui
```

> type: LoadBalancer
>
> port: 80 - Порт, который будет открыт на балансировщике.
>
> nodePort: 32092 - Также на ноде будет открыт порт, но нам он не нужен и его можно даже убрать.
>
> targetPort: 9292 - Порт POD-а.

Настроим соответствующим образом Service UI:

```console
kubectl apply -f ui-service.yml -n dev
```

Посмотрим что там:

```console
kubectl get service  -n dev --selector component=ui
NAME   TYPE           CLUSTER-IP   EXTERNAL-IP   PORT(S)        AGE
ui     LoadBalancer   10.0.6.3     <pending>     80:31433/TCP   5h29m
```

Немного подождем (идет настройка ресурсов GCP):

```console
kubectl get service  -n dev --selector component=ui
NAME   TYPE           CLUSTER-IP   EXTERNAL-IP   PORT(S)        AGE
ui     LoadBalancer   10.0.6.3     35.230.0.46   80:31433/TCP   5h30m
```

> Наш адрес: 35.230.0.46

Проверим в браузере: <http://external-ip:port>

А что за кулисами? Откроем консоль GCP и увидим, что создано правило для балансировки.

Балансировка с помощью Service типа LoadBalancing имеет ряд недостатков:

- нельзя управлять с помощью http URI (L7-балансировка)
- используются только облачные балансировщики (AWS, GCP)
- нет гибких правил работы с трафиком

### Ingress

Для более удобного управления входящим снаружи трафиком и решения недостатков LoadBalancer можно использовать другой объект Kubernetes - **Ingress**.

**Ingress** – это набор правил внутри кластера Kubernetes, предназначенных для того, чтобы входящие подключения могли достичь сервисов (Services).

Сами по себе Ingress’ы это просто правила. Для их применения нужен **Ingress Controller**.

Для работы Ingress-ов необходим **Ingress Controller**. В отличие остальных контроллеров k8s - он не стартует вместе с кластером.

**Ingress Controller** - это скорее плагин (а значит и отдельный POD), который состоит из 2-х функциональных частей:

- Приложение, которое отслеживает через k8s API новые объекты Ingress и обновляет конфигурацию балансировщика
- Балансировщик (Nginx, haproxy, traefik,…), который и занимается управлением сетевым трафиком

Основные задачи, решаемые с помощью Ingress’ов:

- Организация единой точки входа в приложения снаружи
- Обеспечение балансировки трафика
- Терминация SSL
- Виртуальный хостинг на основе имен и т.д

Посколько у нас web-приложение, нам вполне было бы логично использовать L7-балансировщик вместо Service LoadBalancer.

Google в GKE уже предоставляет возможность использовать их собственные решения балансирощик в качестве Ingress controller-ов.

Перейдем в настройки кластера в веб-консоли [gcloud](https://console.cloud.google.com/kubernetes).

Убедимся, что встроенный Ingress включен. Если нет - включим.

Создадим Ingress для сервиса UI:

ui-ingress.yml

```yml
---
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  name: ui
spec:
  backend:
    serviceName: ui
    servicePort: 80
```

> kind: Ingress
>
> Это Singe Service Ingress - значит, что весь ingress контроллер будет просто балансировать нагрузку на Node-ы для одного сервиса (очень похоже на Service LoadBalancer)

Применим конфиг:

```console
kubectl apply -f ui-ingress.yml -n dev
```

Зайдем в [консоль GCP](https://console.cloud.google.com/net-services/loadbalancing/loadBalancers/list) и увидим уже несколько правил.

Нас интересует 1-е: **port30229**

> Это NodePort опубликованного сервиса.
>
> Т.е. для работы с Ingress в GCP нам нужен минимум Service с типом NodePor (он уже есть).

Посмотрим в сам кластер:

```console
kubectl get ingress -n dev
NAME   HOSTS   ADDRESS          PORTS   AGE
ui     *       34.107.150.169   80      103m
```

> Адрес сервиса: 34.107.150.169

В текущей схеме есть несколько недостатков:

- у нас 2 балансировщика для 1 сервиса
- Мы не умеем управлять трафиком на уровне HTTP

Один балансировщик можно спокойно убрать. Обновим сервис для UI:

ui-service.yml

```yml
---
apiVersion: v1
kind: Service
metadata:
  name: ui
  labels:
    app: reddit
    component: ui
spec:
  type: NodePort
  ports:
  - port: 9292
    protocol: TCP
    targetPort: 9292
  selector:
    app: reddit
    component: ui
```

> type: NodePort
>
> port: 9292

Применим:

```console
```

kubectl apply -f ui-service.yml -n dev

Заставим работать Ingress Controller как классический веб:

ui-ingress.yml

```yml
---
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  name: ui
spec:
  rules:
  - http:
      paths:
      - path: /*
        backend:
          serviceName: ui
          servicePort: 9292
```

### Secret

Теперь защитим наш сервис с помощью TLS.
Для начала вспомним Ingress IP:

```console
kubectl get ingress -n dev
NAME   HOSTS   ADDRESS          PORTS   AGE
ui     *       34.107.150.169   80      103m
```

Далее подготовим сертификат используя IP как CN:

```console
openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout tls.key -out tls crt -subj "/CN=34.107.150.169"
```

И загрузит сертификат в кластер kubernetes:

```console
kubectl create secret tls ui-ingress --key tls.key --cert tls.crt -n dev
```

Проверить можно командой:

```console
kubectl describe secret ui-ingress -n dev
Name:         ui-ingress
Namespace:    dev
Labels:       <none>
Annotations:  <none>

Type:  kubernetes.io/tls

Data
====
tls.crt:  1127 bytes
tls.key:  1704 bytes
```

### TLS Termination

Теперь настроим Ingress на прием только HTTPS траффика:

ui-ingress.yml

```yml
---
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  name: ui
  annotations:
    kubernetes.io/ingress.allow-http: "false"
spec:
  tls:
  - secretName: ui-ingress
  backend:
    serviceName: ui
    servicePort: 9292
```

> annotations:
>
> kubernetes.io/ingress.allow-http: "false" - Отключаем проброс HTTP.
>
> tls:
> secretName: ui-ingress - Подключаем наш сертификат.

Применим:

```console
kubectl apply -f ui-ingress.yml -n dev
```

Зайдем на страницу [web console](https://console.cloud.google.com/net-services/loadbalancing/loadBalancers/list) и увидим в описании нашего балансировщика только один протокол HTTPS.

Иногда протокол HTTP может не удалиться у существующего Ingress правила, тогда нужно его вручную удалить и пересоздать:

```console
kubectl delete ingress ui -n dev
kubectl apply -f ui-ingress.yml -n dev
```

Заходим на страницу нашего приложения по https, подтверждаем исключение безопасности (у нас сертификат самоподписанный) и видим что все работает.

Правила Ingress могут долго применяться, если не получилось зайти с первой попытки - подождем и попробуем еще раз.

### Задание со*

Опишем создаваемый объект Secret в виде Kubernetes-манифеста.

ui-secret.yml

```yml
---
apiVersion: v1
kind: Secret
metadata:
  name: ui-ingress
  namespace: dev
type: kubernetes.io/tls
data:
  tls.key: ...
  tls.crt: ...
```

### Network Policy

В прошлых проектах мы договорились о том, что хотелось бы разнести сервисы базы данных и сервис фронтенда по разным сетям, сделав их недоступными друг для друга.

В Kubernetes у нас так сделать не получится с помощью отдельных сетей, так как все POD-ы могут достучаться друг до друга по-умолчанию.

Мы будем использовать **NetworkPolicy** - инструмент для декларативного описания потоков трафика. Отметим, что не все сетевые плагины поддерживают политики сети.

В частности, у GKE эта функция пока в Beta-тесте и для её работы отдельно будет включен сетевой плагин **Calico** (вместо Kubenet).

Протеструем.

Наша задача - ограничить трафик, поступающий на mongodb отовсюду, кроме сервисов post и comment.

Найдем имя кластера:

```console
gcloud beta container clusters list

NAME         LOCATION    MASTER_VERSION  MASTER_IP        MACHINE_TYPE  NODE_VERSION    NUM_NODES  STATUS
k8s-cluster  us-west1-b  1.14.10-gke.17  104.196.254.214  g1-small      1.14.10-gke.17  2          RUNNING
```

Включим network-policy для GKE:

```console
gcloud beta container clusters update k8s-cluster --zone=europe-west1-b --update-addons=NetworkPolicy=ENABLED
gcloud beta container clusters update k8s-cluster --zone=europe-west1-b --enable-network-policy
```

Дождемся, пока кластер обновится.

mongo-network-policy.yml

```yml
---
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: deny-db-traffic
  labels:
    app: reddit
spec:
  podSelector:
    matchLabels:
      app: reddit
      component: mongo
  policyTypes:
  - Ingress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          app: reddit
          component: comment
```

Выбираем объекты политики (pod’ы с mongodb):
> podSelector:
>
> matchLabels:
>
> app: reddit
>
> component: mongo

Запрещаем все входящие подключения. Исходящие разрешены:
> policyTypes:
> Ingress

Разрешаем все входящие подключения от POD-ов с label-ами comment:
> ingress:
>
> from:
>
> podSelector:
>
> matchLabels:
>
> app: reddit
>
> component: comment

Применяем политику:

```console
kubectl apply -f mongo-network-policy.yml -n dev
```

Заходим в приложение и видим что Postt-сервис не может достучаться до базы.

Обновим mongo-network-policy.yml так, чтобы post-сервис дошел до базы данных:

```yml
---
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: deny-db-traffic
  labels:
    app: reddit
spec:
  podSelector:
    matchLabels:
      app: reddit
      component: mongo
  policyTypes:
  - Ingress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          app: reddit
          component: post
  - from:
    - podSelector:
        matchLabels:
          app: reddit
          component: comment
```

### Хранилище для базы

Рассмотрим вопросы хранения данных. Основной Stateful сервис в нашем приложении - это база данных MongoDB.

В текущий момент она запускается в виде Deployment и хранит данные в стаднартный Docker Volume-ах. Это имеет несколько проблем:

- при удалении POD-а удаляется и Volume
- потеря Nod’ы с mongo грозит потерей данных
- запуск базы на другой ноде запускает новый экземпляр данных

mongo-deployment.yml

```yml
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: mongo
  labels:
    app: reddit
    component: mongo
    post-db: "true"
    comment-db: "true"
spec:
  replicas: 1
  selector:
    matchLabels:
      app: reddit
      component: mongo
  template:
    metadata:
      name: mongo
      labels:
        app: reddit
        component: mongo
        post-db: "true"
        comment-db: "true"
    spec:
      containers:
      - image: mongo:3.2
        name: mongo
        volumeMounts:
        - name: mongo-persistent-storage
          mountPath: /data/db
      volumes:
      - name: mongo-persistent-storage
        emptyDir: {}
```

Подключаем Volume:
> volumeMounts:
>
> name: mongo-persistent-storage
>
> mountPath: /data/db

Объявляем Volume:
> volumes:
>
> name: mongo-persistent-storage
>
> emptyDir: {}

### Volume

Сейчас используется тип Volume **emptyDir**. При создании пода с таким типом просто создается пустой docker volume.

При остановке POD’a содержимое emtpyDir удалится навсегда. Хотя в общем случае падение POD’a не вызывает удаления Volume’a.

Вместо того, чтобы хранить данные локально на ноде, имеет смысл подключить удаленное хранилище. В нашем случае можем использовать Volume gcePersistentDisk, который будет складывать данные в хранилище GCE.

Создадим диск в Google Cloud:

```console
gcloud compute disks create --size=25GB --zone=europe-west1-b reddit-mongo-disk
```

Добавим новый Volume POD-у базы:

mongo-deployment.yml

```yml
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: mongo
  labels:
    app: reddit
    component: mongo
    post-db: "true"
    comment-db: "true"
spec:
  replicas: 1
  selector:
    matchLabels:
      app: reddit
      component: mongo
  template:
    metadata:
      name: mongo
      labels:
        app: reddit
        component: mongo
        post-db: "true"
        comment-db: "true"
    spec:
      containers:
      - image: mongo:3.2
        name: mongo
        volumeMounts:
        - name: mongo-gce-pd-storage
          mountPath: /data/db
      volumes:
      - name: mongo-persistent-storage
        emptyDir: {}
        volumes:
      - name: mongo-gce-pd-storage
        gcePersistentDisk:
          pdName: reddit-mongo-disk
          fsType: ext4
```

Меняем Volume на другой тип:
> gcePersistentDisk:
>
> pdName: reddit-mongo-disk
>
> fsType: ext4

Монтируем выделенный диск к POD’у mongo:

```console
kubectl apply -f mongo-deployment.yml -n dev
```

Дождемся, пересоздания Pod'а (занимает до 10 минут). Зайдем в приложение и добавим пост.

Удалим deployment:

```console
kubectl delete deploy mongo -n dev
```

Снова создадим деплой mongo:

```console
kubectl apply -f mongo-deployment.yml -n dev
```

Наш пост все еще на месте. [Здесь](https://console.cloud.google.com/compute/disks) можно посмотреть на созданный диск и увидеть какой машиной он используется.

### PersistentVolume

Используемый механизм Volume-ов можно сделать удобнее. Мы можем использовать не целый выделенный диск для каждого пода, а целый ресурс хранилища, общий для всего кластера. Тогда при запуске Stateful-задач в кластере, мы сможем запросить хранилище в виде такого же ресурса, как CPU или оперативная память.

Для этого будем использовать механизм **PersistentVolume**.

Создадим описание PersistentVolume:

mongo-volume.yml

```yml
---
apiVersion: v1
kind: PersistentVolume
metadata:
  name: reddit-mongo-disk
spec:
  capacity:
    storage: 25Gi
  accessModes:
    - ReadWriteOnce
  persistentVolumeReclaimPolicy: Retain
  gcePersistentDisk:
    fsType: "ext4"
    pdName: "reddit-mongo-disk"
```

> name: reddit-mongo-disk - Имя PersistentVolume'а
>
> pdName: "reddit-mongo-disk" - Имя диска в GCE

Добавим PersistentVolume в кластер:

```console
kubectl apply -f mongo-volume.yml -n dev
```

Мы создали PersistentVolume в виде диска в GCP.

### PersistentVolumeClaim

Мы создали ресурс дискового хранилища, распространенный на весь кластер, в виде PersistentVolume.

Чтобы выделить приложению часть такого ресурса - нужно создать запрос на выдачу - **PersistentVolumeClaim**. Claim - это именно запрос, а не само хранилище.

С помощью запроса можно выделить место как из конкретного **PersistentVolume** (тогда параметры accessModes и StorageClass должны соответствовать, а места должно хватать), так и просто создать отдельный PersistentVolume под конкретный запрос.

Создадим описание PersistentVolumeClaim (PVC):

mongo-claim.yml:

```yml
---
kind: PersistentVolumeClaim
apiVersion: v1
metadata:
  name: mongo-pvc
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 15Gi
```

> name: mongo-pvc - Имя PersistentVolumeClame'а.
>
> accessModes:
>
> ReadWriteOnce - accessMode у PVC и у PV должен совпадать.

Добавим PersistentVolumeClaim в кластер:

```console
kubectl apply -f mongo-claim.yml -n dev
```

Мы выделили место в PV по запросу для нашей базы. Одновременно использовать один PV можно только по **одному** Claim’у.

Если Claim не найдет по заданным параметрам PV внутри кластера, либо тот будет занят другим Claim’ом то он сам создаст нужный ему PV воспользовавшись стандартным StorageClass.

```console
kubectl describe storageclass standard -n dev
Name:                  standard
IsDefaultClass:        Yes
Annotations:           storageclass.kubernetes.io/is-default-class=true
Provisioner:           kubernetes.io/gce-pd
Parameters:            type=pd-standard
AllowVolumeExpansion:  True
MountOptions:          <none>
ReclaimPolicy:         Delete
VolumeBindingMode:     Immediate
```

В нашем случае это обычный медленный Google Cloud Persistent Drive.

Подключим PVC к нашим Pod'ам:

mongo-deployment.yml

```yml
---
apiVersion: apps/v1beta1
kind: Deployment
metadata:
  name: mongo
  labels:
    app: reddit
    component: mongo
    post-db: "true"
    comment-db: "true"
spec:
  replicas: 1
  selector:
    matchLabels:
      app: reddit
      component: mongo
  template:
    metadata:
      name: mongo
      labels:
        app: reddit
        component: mongo
        post-db: "true"
        comment-db: "true"
    spec:
      containers:
      - image: mongo:3.2
        name: mongo
        volumeMounts:
        - name: mongo-gce-pd-storage
          mountPath: /data/db
      volumes:
      - name: mongo-gce-pd-storage
        persistentVolumeClaim:
          claimName: mongo-pvc
```

> volumes:
>
> name: mongo-gce-pd-storage - Имя PersistentVolumeClame'а.
>
> persistentVolumeClaim:
>
> claimName: mongo-pvc

Обновим описание нашего Deployment’а:

```console
kubectl apply -f mongo-deployment.yml -n dev
```

Монтируем выделенное по PVC хранилище к POD’у mongo.

### Динамическое выделение Volume'ов

Создав PersistentVolume мы отделили объект "хранилища" от наших Service'ов и Pod'ов. Теперь мы можем его при необходимости переиспользовать.

Но нам гораздо интереснее создавать хранилища при необходимости и в автоматическом режиме. В этом нам помогут **StorageClass’ы**. Они описывают где (какой провайдер) и какие хранилища создаются.

В нашем случае создадим StorageClass **Fast** так, чтобы монтировались SSD-диски для работы нашего хранилища.

### StorageClass

Создадим описание StorageClass’а:

storage-fast.yml

```yml
---
kind: StorageClass
apiVersion: storage.k8s.io/v1beta1
metadata:
  name: fast
provisioner: kubernetes.io/gce-pd
parameters:
  type: pd-ssd
```

> name: fast - Имя StorageClass'а
>
> provisioner: kubernetes.io/gce-pd - Провайдер хранилища
>
> type: pd-ssd - Тип предоставляемого хранилища

Добавим StorageClass в кластер:

```console
kubectl apply -f storage-fast.yml -n dev
```

### PVC + StorageClass

Создадим описание PersistentVolumeClaim:

mongo-claim-dynamic.yml

```yml
---
kind: PersistentVolumeClaim
apiVersion: v1
metadata:
  name: mongo-pvc-dynamic
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: fast
  resources:
    requests:
      storage: 10Gi
```

> storageClassName: fast - Вместо ссылки на созданный диск, теперь мы ссылаемся на StorageClass.

Добавим StorageClass в кластер:

```console
kubectl apply -f mongo-claim-dynamic.yml -n dev
```

Подключим PVC к нашим Pod'ам:

mongo-deployment.yml

```yml
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: mongo
  labels:
    app: reddit
    component: mongo
    post-db: "true"
    comment-db: "true"
spec:
  replicas: 1
  selector:
    matchLabels:
      app: reddit
      component: mongo
  template:
    metadata:
      name: mongo
      labels:
        app: reddit
        component: mongo
        post-db: "true"
        comment-db: "true"
    spec:
      containers:
      - image: mongo:3.2
        name: mongo
        volumeMounts:
        - name: mongo-gce-pd-storage
          mountPath: /data/db
      volumes:
      - name: mongo-gce-pd-storage
        persistentVolumeClaim:
          claimName: mongo-pvc-dynamic
```

> claimName: mongo-pvc-dynamic - Обновим PersistentVolumeClaim.

Обновим описание нашего Deployment'а:

```console
kubectl apply -f mongo-deployment.yml -n dev
```

Посмотрит какие в итоге у нас получились PersistentVolume'ы:

```console
kubectl get persistentvolume -n dev

NAME                                       CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS      CLAIM                   STORAGECLASS   REASON   AGE
pvc-197f4dc0-53c1-11ea-97a3-42010a840fde   10Gi       RWO            Delete           Bound       dev/mongo-pvc-dynamic   fast                    88s
pvc-acdce3a9-5322-11ea-97a3-42010a840fde   15Gi       RWO            Delete           Bound       dev/mongo-pvc           standard                18h
reddit-mongo-disk
```

На созданные Kubernetes'ом диски можно посмотреть в [web console](https://console.cloud.google.com/compute/disks).

## Kubernetes. Запуск кластера и приложения. Модель безопасности

### Развернуть локальное окружение для работы с Kubernetes

Для дальнейшей работы нам нужно подготовить локальное окружение, которое будет состоять из:

1. **kubectl** - фактически, главной утилиты для работы c Kubernetes API (все, что делает kubectl, можно сделать с помощью HTTP-запросов к API k8s)
2. Директории **~/.kube** - содержит служебную инфу для kubectl (конфиги, кеши, схемы API)
3. **minikube** - утилиты для разворачивания локальной инсталляции Kubernetes.

#### Установка kubectl

Все способы установки **kubectl** доступны по [ссылке](https://kubernetes.io/docs/tasks/tools/install-kubectl/).

```console
curl -LO https://storage.googleapis.com/kubernetes-release/release/`curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt`/bin/linux/amd64/kubectl
chmod +x ./kubectl
sudo mv ./kubectl /usr/local/bin/kubectl
kubectl version

Client Version: version.Info{Major:"1", Minor:"17", GitVersion:"v1.17.0", GitCommit:"70132b0f130acc0bed193d9ba59dd186f0e634cf", GitTreeState:"clean", BuildDate:"2019-12-07T21:20:10Z", GoVersion:"go1.13.4", Compiler:"gc", Platform:"linux/amd64"}
Server Version: version.Info{Major:"1", Minor:"13+", GitVersion:"v1.13.11-gke.14", GitCommit:"56d89863d1033f9668ddd6e1c1aea81cd846ef88", GitTreeState:"clean", BuildDate:"2019-11-07T19:12:22Z", GoVersion:"go1.12.11b4", Compiler:"gc", Platform:"linux/amd64"}
```

#### Установка Minikube

Для работы Minukube нам понадобится локальный гипервизор:

1. Для OS X: или [xhyve driver](https://git.k8s.io/minikube/docs/drivers.md#xhyve-driver), или [VirtualBox](https://www.virtualbox.org/wiki/Downloads), или [VMware](https://www.vmware.com/products/fusion)
Fusion.
2. Для Linux: [VirtualBox](https://www.virtualbox.org/wiki/Downloads) или [KVM](http://www.linux-kvm.org/).
3. Для Windows: [VirtualBox](https://www.virtualbox.org/wiki/Downloads) или [Hyper-V](https://msdn.microsoft.com/en-us/virtualization/hyperv_on_windows/quick_start/walkthrough_install).

Воспользуемся KVM из прошлых ДЗ по infra.

Установим [Minikube](https://kubernetes.io/docs/tasks/tools/install-minikube/):

```console
grep -E --color 'vmx|svm' /proc/cpuinfo
curl -Lo minikube https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64 \
  && chmod +x minikube
sudo mkdir -p /usr/local/bin/
sudo install minikube /usr/local/bin/
```

Запустим наш Minikube-кластер:

```console
minikube start --vm-driver=kvm2

😄  minikube v1.6.2 on Ubuntu 18.04
✨  Selecting 'kvm2' driver from user configuration (alternates: [none])
🔥  Creating kvm2 VM (CPUs=2, Memory=2000MB, Disk=20000MB) ...
🐳  Preparing Kubernetes v1.17.0 on Docker '19.03.5' ...
🚜  Pulling images ...
🚀  Launching Kubernetes ...
⌛  Waiting for cluster to come online ...
🏄  Done! kubectl is now configured to use "minikube"
```

>Если нужна конкретная версия kubernetes, указываем флаг --kubernetes-version \<version\> (v1.8.0).
>
>По-умолчанию используется VirtualBox. Если нужен другой гипервизор, то ставим флаг --vm-driver=\<hypervisor\>

#### Kubectl

Наш Minikube-кластер развернут. При этом автоматически был настроен конфиг kubectl.

Проверим, что это так:

```console
kubectl get nodes
NAME       STATUS   ROLES    AGE   VERSION
minikube   Ready    master   21s   v1.17.0
```

Конфигурация kubectl - это **контекст**.

Контекст - это комбинация:

1. **cluster** - API-сервер
2. **user** - пользователь для подключения к кластеру
3. **namespace** - область видимости (не обязательно, поумолчанию default)

Информацию о контекстах kubectl сохраняет в файле **~/.kube/config**

Файл **~/.kube/config** - это такой же манифест kubernetes в YAML-формате (есть и Kind, и ApiVersion).

Кластер (**cluster**) - это:

1. **server** - адрес kubernetes API-сервера
2. **certificate-authority** - корневой сертификат (которым подписан SSL-сертификат самого сервера), чтобы убедиться, что нас не обманывают и перед нами тот самый сервер

\+ **name** (Имя) для идентификации в конфиге

Пользователь (**user**) - это:

1. Данные для аутентификации (зависит от того, как настроен
сервер). Это могут быть:

- username + password (Basic Auth
- client key + client certificate
- token
- auth-provider config (например GCP)

\+ **name** (Имя) для идентификации в конфиге

Контекст (**context**) - это:

1. **cluster** - имя кластера из списка clusters
2. **user** - имя пользователя из списка users
3. **namespace** - область видимости по-умолчанию (не обязательно)

\+ **name** (Имя) для идентификации в конфиге

Обычно порядок конфигурирования kubectl следующий:

1. Создать cluster:
kubectl config set-cluster … cluster_name

2. Создать данные пользователя (credentials):
kubectl config set-credentials … user_name

3. Создать контекст:
kubectl config set-context context_name \
--cluster=cluster_name \
--user=user_name

4. Использовать контекст:
kubectl config use-context context_name

Таким образом kubectl конфигурируется для подключения к разным кластерам, под разными пользователями.

Текущий контекст можно увидеть так:

```console
kubectl config current-context

minikube
```

Список всех контекстов можно увидеть так:

```console
kubectl config get-contexts

CURRENT   NAME                                            CLUSTER                                         AUTHINFO                                        NAMESPACE
          kubernetes-the-hard-way                         kubernetes-the-hard-way                         admin
*         minikube                                        minikube                                        minikube
```

Для работы в приложения kubernetes, нам необходимо описать их желаемое состояние либо в YAML-манифестах, либо с помощью командной строки.

Всю конфигурацию поместим в каталог **./kubernetes/reddit** внутри вашего репозитория.

#### Deployment

Основные объекты - это ресурсы **Deployment**.

Как помним из предыдущего занятия, основные его задачи:

- Создание ReplicationSet (следит, чтобы число запущенных Pod-ов соответствовало описанному)
- Ведение истории версий запущенных Pod-ов (для различных стратегий деплоя, для возможностей отката)
- Описание процесса деплоя (стратегия, параметры стратегий)

ui-deployment.yml

```yml
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: ui
  labels:
    app: reddit
    component: ui
spec:
  replicas: 3
  selector:
    matchLabels:
      app: reddit
      component: ui
  template:
    metadata:
      name: ui-pod
      labels:
        app: reddit
        component: ui
    spec:
      containers:
      - image: kovtalex/ui:logging
        name: ui
```

> metadata: Блок метаданных деплоя
>
> spec: Блок метаданных деплоя
>
> template: Блок описания POD-ов
>
> selector описывает, как ему отслеживать POD-ы. В данном случае - контроллер будет считать POD-ы с метками: app=reddit И component=ui.
>
> Поэтому важно в описании POD-а задать нужные метки (labels).
>
> Для более гибкой выборки вводим 2 метки (app и component).

Запустим в Minikube ui-компоненту:

```console
kubectl apply -f ui-deployment.yml

deployment "ui" created
```

Убедитесь, что во 2,3,4 и 5 столбцах стоит число 3 (число реплик ui):

```console
kubectl get deployment

NAME   READY   UP-TO-DATE   AVAILABLE   AGE
ui     3/3     3            3           34s
```

> **kubectl apply -f \<filename\>** может принимать не только
отдельный файл, но и папку с ними. Например: kubectl apply -f ./kubernetes/reddit

Пока что мы не можем использовать наше приложение полностью, потому что никак не настроена сеть для общения с ним.

Но **kubectl** умеет пробрасывать сетевые порты POD-ов на локальную
машину.

Найдем, используя selector, POD-ы приложения:

```console
kubectl get pods --selector component=ui

NAME                  READY   STATUS    RESTARTS   AGE
ui-67f8b7668d-htbz6   1/1     Running   0          6m28s
ui-67f8b7668d-klb7b   1/1     Running   0          6m28s
ui-67f8b7668d-llgnv   1/1     Running   0          6m28s

kubectl port-forward ui-67f8b7668d-htbz6 8080:9292
```

> где 8080:9292 - local-port:pod-port

Зайдем в браузере на <http://localhost:8080/> и убедимся, что UI работает, подключим остальные компоненты.

comment-deployment.yml

```yml
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: comment
  labels:
    app: reddit
    component: comment
spec:
  replicas: 3
  selector:
    matchLabels:
      app: reddit
      component: comment
  template:
    metadata:
      name: comment
      labels:
        app: reddit
        component: comment
    spec:
      containers:
      - image: kovtlaex/comment:logging
        name: comment
```

> Компонент comment описывается похожим образом. Меняется только имя образа и метки и применяем (kubectl apply).
>
> Проверить можно так же, пробросив \<local-port\>: 9292 и зайдя на адрес <http://localhost:local-port/healthcheck>

```console
kubectl apply -f comment-deployment.yml

kubectl get pods --selector component=comment

NAME                  READY   STATUS    RESTARTS   AGE
ui-67f8b7668d-htbz6   1/1     Running   0          6m28s
ui-67f8b7668d-klb7b   1/1     Running   0          6m28s
ui-67f8b7668d-llgnv   1/1     Running   0          6m28s

kubectl port-forward comment-5b68d8f856-6wlcx 8080:9292
```

Проверяем в браузере по адресу: <http://localhost:8080/healthcheck>

post-deployment.yml

```yml
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: post
  labels:
    app: reddit
    component: post
spec:
  replicas: 3
  selector:
    matchLabels:
      app: reddit
      component: post
  template:
    metadata:
      name: post
      labels:
        app: reddit
        component: post
    spec:
      containers:
      - image: kovtalex/post:logging
        name: post
```

```console
kubectl apply -f post-deployment.yml

kubectl get pods --selector component=post

NAME                    READY   STATUS    RESTARTS   AGE
post-858ffcfffd-488r2   1/1     Running   0          95s
post-858ffcfffd-5t4qf   1/1     Running   0          95s
post-858ffcfffd-gh4cr   1/1     Running   0          95s

kubectl port-forward post-858ffcfffd-488r2 8080:5000
```

Проверяем в браузере по адресу: <http://localhost:8080/healthcheck>

mongo-deployment.yml

```yml
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: mongo
  labels:
    app: reddit
    component: mongo
spec:
  replicas: 1
  selector:
    matchLabels:
      app: reddit
      component: mongo
  template:
    metadata:
      name: mongo
      labels:
        app: reddit
        component: mongo
    spec:
      containers:
      - image: mongo:3.2
        name: mongo
        volumeMounts:
        - name: mongo-persistent-storage
          mountPath: /data/db
      volumes:
      - name: mongo-persistent-storage
        emptyDir: {}
```

Также примонтируем стандартный Volume для хранения данных вне контейнера.

Точка монтирования в контейнере (не в POD-е):

```yml
volumeMounts:
- name: mongo-persistent-storage
  mountPath: /data/db
```

Ассоциированные с POD-ом Volume-ы:

```yml
volumes:
- name: mongo-persistent-storage
  emptyDir: {}
```

```console
kubectl apply -f mongo-deployment.yml
```

### service

В текущем состоянии приложение не будет работать, так его компоненты ещё не знают как найти друг друга.

Для связи компонент между собой и с внешним миром используется объект **Service** - абстракция, которая определяет набор POD-ов (Endpoints) и способ доступа к ним.

Для связи ui с post и comment нужно создать им по
объекту Service.

comment-service.yml

```yml
---
apiVersion: v1
kind: Service
metadata:
  name: comment
  labels:
    app: reddit
    component: comment
spec:
  ports:
  - port: 9292
    protocol: TCP
    targetPort: 9292
  selector:
    app: reddit
    component: comment
```

```console
kubectl apply -f comment-service.yml
```

Когда объект service будет создан:

1. В DNS появится запись для comment
2. При обращении на адрес post:9292 изнутри любого из POD-ов текущего namespace нас переправит на 9292-ный порт одного из POD-ов приложения post, выбранных по label-ам

По label-ам должны были быть найдены соответствующие POD-ы. Посмотреть можно с помощью:

```console
kubectl describe service comment | grep Endpoints

Endpoints:         172.17.0.4:9292,172.17.0.5:9292,172.17.0.6:9292
```

post-service.yml

```yml
---
apiVersion: v1
kind: Service
metadata:
  name: post
  labels:
    app: reddit
    component: post
spec:
  ports:
  - port: 5000
    protocol: TCP
    targetPort: 5000
  selector:
    app: reddit
    component: post
```

```console
kubectl apply -f post-service.yml
```

А изнутри любого POD-а должно разрешаться:

```console
kubectl exec -ti ui-67f8b7668d-dp8js nslookup post
nslookup: can't resolve '(null)': Name does not resolve

Name:      post
Address 1: 10.96.176.52 post.default.svc.cluster.local


kubectl exec -ti ui-67f8b7668d-dp8js nslookup comment
nslookup: can't resolve '(null)': Name does not resolve

Name:      comment
Address 1: 10.96.93.222 comment.default.svc.cluster.local
```

Post и Comment также используют mongodb, следовательно ей тоже нужен объект Service.

mongodb-service.yml

```yml
---
apiVersion: v1
kind: Service
metadata:
  name: mongodb
  labels:
    app: reddit
    component: mongo
spec:
  ports:
  - port: 27017
    protocol: TCP
    targetPort: 27017
  selector:
    app: reddit
    component: mongo
```

```console
kubectl apply -f mongodb-service.yml
```

Пробрасываем порт на ui pod:

```console
kubectl port-forward ui-67f8b7668d-dp8js 9292:9292
```

Заходим на <http://localhost:9292>

И видим, что проблема с сервисом post. Смотрим логи ui:

```console
kubectl logs ui-67f8b7668d-dp8js

E, [2020-01-08T18:45:10.581192 #1] ERROR -- : service=ui | event=show_all_posts | request_id=5e2b50e6-8dad-445f-b0e8-dc3e7f12527d | message='Failed to read from Post service. Reason: 784: unexpected token at 'Internal Server Error'' | params: "{}"
I, [2020-01-08T18:45:10.615695 #1]  INFO -- : service=ui | event=request | path=/ | request_id=5e2b50e6-8dad-445f-b0e8-dc3e7f12527d | remote_addr=127.0.0.1 | method= GET | response_status=200
E, [2020-01-08T18:45:56.228010 #1] ERROR -- : service=ui | event=show_all_posts | request_id=210fe956-d010-43fa-b085-fd0d9afd488d | message='Failed to read from Post service. Reason: 784: unexpected token at 'Internal Server Error'' | params: "{}"
I, [2020-01-08T18:45:56.379062 #1]  INFO -- : service=ui | event=request | path=/ | request_id=210fe956-d010-43fa-b085-fd0d9afd488d | remote_addr=127.0.0.1 | method= GET | response_status=200
```

Вспоминаем, что для сервисы ищут адреса: **comment_db** и **post_db**, а не **mongodb**.

Эти адреса заданы в их Dockerfile-ах в виде переменных
окружения:

```Dockerfile
post/Dockerfile
…
ENV POST_DATABASE_HOST=post_db
comment/Dockerfile
…
ENV COMMENT_DATABASE_HOST=comment_db
```

В Docker Swarm проблема доступа к одному ресурсу под разными именами решалась с помощью сетевых алиасов.

В Kubernetes такого функционала нет. Мы эту проблему можем решить с помощью тех же Service-ов.

Сделаем Service для БД comment.

comment-mongodb-service.yml

```yml
---
apiVersion: v1
kind: Service
metadata:
  name: comment-db
  labels:
    app: reddit
    component: mongo
    comment-db: "true"
spec:
  ports:
  - port: 27017
    protocol: TCP
    targetPort: 27017
  selector:
    app: reddit
    component: mongo
    comment-db: "true"
```

> metadata ... comment-db: "true" - добавим метку, чтобы различать сервисы
>
> selector ... comment-db: Отдельный лейбл для comment-db
>
> В имени нельзя использовать “_”

Так же придется обновить файл deployment для mongodb, чтобы новый Service смог найти нужный POD

mongo-deployment.yml

```yml
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: mongo
  labels:
    app: reddit
    component: mongo
    comment-db: "true"
spec:
  replicas: 1
  selector:
    matchLabels:
      app: reddit
      component: mongo
  template:
    metadata:
      name: mongo
      labels:
        app: reddit
        component: mongo
        comment-db: "true"
    spec:
      containers:
      - image: mongo:3.2
        name: mongo
        volumeMounts:
        - name: mongo-persistent-storage
          mountPath: /data/db
      volumes:
      - name: mongo-persistent-storage
        emptyDir: {}
```

> metadata ... comment-db: Лейбл в deployment чтобы было понятно, что развернуто
>
> template ... comment-db: label в pod, который нужно найти

comment-deployment.yml

```yml
...
      containers:
      - image: kovtalex/comment:logging
        name: comment
        env:
        - name: COMMENT_DATABASE_HOST
          value: comment-db
```

> Зададим pod-ам comment переменную окружения для обращения к базе

Мы сделали базу доступной для comment.

Проделаем аналогичные действия для post сервиса. Название сервиса должно быть post-db.

post-deployment.yml

```yml
...
      containers:
      - image: kovtalex/post:logging
        name: post
        env:
        - name: POST_DATABASE_HOST
          value: post-db
```

post-mongodb-service.yml

```yml
---
apiVersion: v1
kind: Service
metadata:
  name: post-db
  labels:
    app: reddit
    component: mongo
    post-db: "true"
spec:
  ports:
  - port: 27017
    protocol: TCP
    targetPort: 27017
  selector:
    app: reddit
    component: mongo
    post-db: "true"
```

mongo-deployment.yml

```yml
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: mongo
  labels:
    app: reddit
    component: mongo
    comment-db: "true"
    post-db: "true"
spec:
  replicas: 1
  selector:
    matchLabels:
      app: reddit
      component: mongo
  template:
    metadata:
      name: mongo
      labels:
        app: reddit
        component: mongo
        comment-db: "true"
        post-db: "true"
    spec:
      containers:
      - image: mongo:3.2
        name: mongo
        volumeMounts:
        - name: mongo-persistent-storage
          mountPath: /data/db
      volumes:
      - name: mongo-persistent-storage
        emptyDir: {}
```

Применяем новые и обновленные ymls.

Пробрасываем порт на ui pod:

```console
kubectl port-forward ui-67f8b7668d-dp8js 9292:9292
```

Заходим на <http://localhost:9292> и видим, что наше приложение работает и посты создаются.

Удалим объект mongodb-service:

```console
kubectl delete -f mongodb-service.yml

Или

kubectl delete service mongodb
```

Нам нужно как-то обеспечить доступ к ui-сервису снаружи.
Для этого нам понадобится Service для UI-компоненты.

ui-service.yml

```yml
---
apiVersion: v1
kind: Service
metadata:
  name: ui
  labels:
    app: reddit
    component: ui
spec:
  type: NodePort
  ports:  
  - port: 9292
      protocol: TCP
      targetPort: 9292
    selector:
      app: reddit
      component: ui
```

> Главное отличие - тип сервиса **NodePort**.

По-умолчанию все сервисы имеют тип **ClusterIP** - это значит, что сервис распологается на внутреннем диапазоне IP-адресов кластера. Снаружи до него
нет доступа.

Тип **NodePort** - на каждой ноде кластера открывает порт из диапазона **30000-32767** и переправляет трафик с этого порта на тот, который указан в **targetPort** Pod (похоже на стандартный expose в docker).

Теперь до сервиса можно дойти по \<Node-IP\>:\<NodePort\>
Также можно указать самим NodePort (но все равно из **диапазона**):

```yml
spec:
 type: NodePort
 ports:
- nodePort: 32092
 port: 9292
 protocol: TCP
 targetPort: 9292
 selector:
 ...
```

Т.е. в описании service

- NodePort - для доступа снаружи кластера
- port - для доступа к сервису изнутри кластера

#### Minikube

Minikube может выдавать web-странцы с сервисами которые были помечены типом **NodePort**.

Попробуем:

```console
minikube service ui
```

Minikube может перенаправлять на web-странцы с сервисами которые были помечены типом **NodePort**.

Посмотрим на список сервисов:

```console
minikube service list

|-------------|------------|----------------------------|-----|
|  NAMESPACE  |    NAME    |        TARGET PORT         | URL |
|-------------|------------|----------------------------|-----|
| default     | comment    | No node port               |
| default     | comment-db | No node port               |
| default     | kubernetes | No node port               |
| default     | post       | No node port               |
| default     | post-db    | No node port               |
| default     | ui         | http://192.168.39.79:32092 |
| kube-system | kube-dns   | No node port               |
|-------------|------------|----------------------------|-----|
```

Minikube также имеет в комплекте несколько стандартных аддонов (расширений) для Kubernetes (kube-dns, dashboard, monitoring,…).

Каждое расширение - это такие же PODы и сервисы, какие создавались нами, только они еще общаются с API самого Kubernetes.

Получить список расширений:

```console
minikube addons list

- addon-manager: enabled
- dashboard: disabled
- default-storageclass: enabled
- efk: disabled
- freshpod: disabled
- gvisor: disabled
- helm-tiller: disabled
- ingress: disabled
- ingress-dns: disabled
- logviewer: disabled
- metrics-server: disabled
- nvidia-driver-installer: disabled
- nvidia-gpu-device-plugin: disabled
- registry: disabled
- registry-creds: disabled
- storage-provisioner: enabled
- storage-provisioner-gluster: disabled
```

Интересный аддон - dashboard. Это UI для работы с kubernetes. По умолчанию в новых версиях он выключен.
Как и многие kubernetes add-on'ы, dashboard запускается в
виде pod'а.

Если мы посмотрим на запущенные pod'ы с помощью команды **kubectl get pods**, то обнаружим только наше приложение.

Потому что поды и сервисы для dashboard-а были запущены в **namespace** (пространстве имен) **kube-system**. Мы же запросили пространство имен **default**.

#### Namespaces

**Namespace** - это, по сути, виртуальный кластер Kubernetes внутри самого Kubernetes. Внутри каждого такого кластера находятся свои объекты (POD-ы, Service-ы, Deployment-ы и т.д.), кроме объектов, общих на все namespace-ы (nodes, ClusterRoles, PersistentVolumes).

В разных namespace-ах могут находится объекты с одинаковым именем, но в рамках одного namespace имена объектов должны быть уникальны.

При старте Kubernetes кластер уже имеет 3 namespace:

- default - для объектов для которых не определен другой Namespace (в нем мы работали все это время)
- kube-system - для объектов созданных Kubernetes’ом и для управления им
- kube-public - для объектов к которым нужен доступ из любой точки кластера

> Для того, чтобы выбрать конкретное пространство имен, нужно указать флаг -n \<namespace\> или --namespace \<namespace\> при запуске kubectl

Включим dasboard:

```console
minikube dashboard

🤔  Verifying dashboard health ...
🚀  Launching proxy ...
🤔  Verifying proxy health ...
🎉  Opening http://127.0.0.1:39633/api/v1/namespaces/kubernetes-dashboard/services/http:kubernetes-dashboard:/proxy/ in your default browser...
```

В другой консолы выполняем:

```console
kubectl get all -n kubernetes-dashboard --selector k8s-app=kubernetes-dashboard

NAME                                       READY   STATUS    RESTARTS   AGE
pod/kubernetes-dashboard-79d9cd965-cd7lx   1/1     Running   0          7m23s

NAME                           TYPE        CLUSTER-IP     EXTERNAL-IP   PORT(S)   AGE
service/kubernetes-dashboard   ClusterIP   10.96.142.50   <none>        80/TCP    7m26s

NAME                                   READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/kubernetes-dashboard   1/1     1            1           7m23s

NAME                                             DESIRED   CURRENT   READY   AGE
replicaset.apps/kubernetes-dashboard-79d9cd965   1         1         1       7m23s
```

Мы вывели все объекты из неймспейса **kubernetes-dashboard**, имеющие label
app=kubernetes-dashboard

#### Dashboard

Зайдем в Dashboard: <http://127.0.0.1:39633/api/v1/namespaces/kubernetes-dashboard/services/http:kubernetes-dashboard:/proxy/>

В самом Dashboard можно:

- отслеживать состояние кластера и рабочих нагрузок в нем
- создавать новые объекты (загружать YAML-файлы)
- Удалять и изменять объекты (кол-во реплик, yaml-файлы)
- отслеживать логи в Pod-ах
- при включении Heapster-аддона смотреть нагрузку на Podах
- и т.д.

#### Namespace dev

Используем же namespace в наших целях. Отделим среду для разработки приложения от всего остального кластера.

Для этого создадим свой Namespace **dev**.

dev-namespace.yml

```yml
---
apiVersion: v1
kind: Namespace
metadata:
  name: dev
```

```console
kubectl apply -f dev-namespace.yml
```

Запустим приложение в dev неймспейсе:

```console
kubectl apply -n dev -f ...
```

Так как возник конфликт портов у ui-service, то изменим описания значение NodePort.

Смотрим результат:

```console
minikube service ui -n dev

|-----------|------|-------------|----------------------------|
| NAMESPACE | NAME | TARGET PORT |            URL             |
|-----------|------|-------------|----------------------------|
| dev       | ui   |             | http://192.168.39.79:32093 |
|-----------|------|-------------|----------------------------|
🎉  Opening service dev/ui in default browser...
Error: no DISPLAY environment variable specified  
```

Добавим инфу об окружении внутрь контейнера UI.

ui-deployment.yml

```yml
      containers:
      - image: kovtalex/ui:logging
        name: ui
        env:
        - name: ENV
          valueFrom:
            fieldRef:
              fieldPath: metadata.namespace
```

> valueFrom: - извлекаем значения из контекста запуска.

```console
kubectl apply -f ui-deployment.yml -n dev
```

Проверяем и видим на главной страницу, что указано наше dev окружение.

### Разворачиваем Kubernetes в GKE

Мы подготовили наше приложение в локальном окружении.
Теперь самое время запустить его на реальном кластере
Kubernetes.

В качестве основной платформы будем использовать **Google Kubernetes Engine**.

- Зайдем в нашу gcloud console, перейдем в “kubernetes clusters”
- Нажмем “создать Cluster”
- Укажем следующие настройки кластера:
  - Тип машины - небольшая машина (1,7 ГБ) (для экономии
ресурсов)
  - Размер - 2
  - Базовая аутентификация - отключена
  - Устаревшие права доступа - отключено
  - Панель управления Kubernetes - отключено
  - Размер загрузочного диска - 20 ГБ (для экономии)
  - тэг - kubernetes
- Жмем “Создать” и ждем, пока поднимется кластер

Компоненты управления кластером запускаются в container engine и управляются Google:

- kube-apiserver
- kube-scheduler
- kube-controller-manager
- etcd

Рабочая нагрузка (собственные POD-ы), аддоны, мониторинг, логирование и т.д. запускаются на **рабочих нодах**.

Рабочие ноды - стандартные ноды Google compute engine. Их можно увидеть в списке запущенных узлов.
На них всегда можно зайти по ssh.
Их можно остановить и запустить.

Подключимся к GKE для запуска нашего приложения:

```console
gcloud container clusters get-credentials k8s-cluster1 --zone europe-west1-b --project docker-258208
```

В результате в файл ~/.kube/config будут добавлены **user**, **cluster** и **context** для подключения к кластеру в GKE.
Также текущий контекст будет выставлен для подключения к этому кластеру.

Убедиться можно, введя:

```console
kubectl config current-context

gke_docker-258208_europe-west1-b_k8s-cluster1
```

### Запустим наше приложение в GKE

Создадим dev namespace:

```console
kubectl apply -f dev-namespace.yml
```

Задеплоим все компоненты приложения в namespace dev:

```console
kubectl apply -f . -n dev
```

Откроем Reddit для внешнего мира:

- Зайдем в "правила брандмауэра"
- Нажмем "создать правило брандмауэра"
- Откроем диапазон портов kubernetes для публикации
сервисов
- Настроим:
  - Название - kubernetes
  - тэг - kubernetes
  - Целевые экземпляры - все экземпляры в сети
  - Диапазоны IP-адресов источников  - 0.0.0.0/0
  - Протоколы и порты - Указанные протоколы и порты tcp:**30000-32767**
- Жмем "Создать"

Найдем внешний IP-адрес любой ноды из кластера либо в веб-консоли, либо **External IP** в выводе:

```console
kubectl get nodes -o wide

NAME                                      STATUS     ROLES    AGE    VERSION           INTERNAL-IP   EXTERNAL-IP      OS-IMAGE                             KERNEL-VERSION   CONTAINER-RUNTIME
gke-k8s-cluster-node-pool-a894d092-c3sg   Ready      <none>   20h    v1.13.11-gke.14   10.132.0.53   35.195.195.166   Container-Optimized OS from Google   4.14.138+        docker://18.9.7
gke-k8s-cluster-node-pool-a894d092-wqtn   NotReady   <none>   122m   v1.13.11-gke.14   10.132.0.54   34.77.138.193    Container-Optimized OS from Google   4.14.138+        docker://18.9.7
```

Найдем порт публикации сервиса ui:

```console
kubectl describe service ui -n dev | grep NodePort

Type:                     NodePort
NodePort:                 <unset>  32093/TCP
```

Идем по адресу <http://35.195.195.166:32093> и <http://34.77.138.193:32093> и проверяем работу нашего приложения.

> Так как по умолчанию у нас включен HTTP load balancing, то мы можем легко поднять Ingress для удобства доступа к приложению пользователя по 80 порту с балансировкой: <http://34.107.150.169/>

![GKE](/kubernetes/GKE.jpg)

В GKE также можно запустить Dashboard для кластера:

- Жмем на имя кластера
- Изменить
- Далее нам нужно включить дополнение - “Панель управления Kubernetes”
- Ждем пока кластер загрузится
- **kubectl proxy**

Заходим по адресу: <http://localhost:8001/api/v1/namespaces/kube-system/services/https:kubernetes-dashboard:/proxy/#!/login>

У нас отсутсует кнопка SKIP.
Тогда идем в консоль и получаем Token:

```console
kubectl -n kube-system describe secrets    `kubectl -n kube-system get secrets | awk '/clusterrole-aggregation-controller/ {print $1}'` | awk '/token:/ {print $2}'
```

Возвращаемся на страницу входа, вводим токен и жмем SING IN. Мы в дашборде.

#### Security

Если бы у нас присутствовала кнопка SKIP, то после нажания на неё мы получили бы сообщение о нехватки прав.

У dashboard не хватает прав, чтобы посмотреть на кластер.
Его не пускает RBAC (ролевая система контроля доступа).
Нужно нашему Service Account назначить роль с достаточными правами на просмотр информации о кластере.

Dashboard застрял на шаге Autorization.

Нужно нашему Service Account назначить роль с достаточными правами на просмотр информации о кластере.

В кластере уже есть объект ClusterRole с названием **cluster-admin**. Тот, кому назначена эта роль имеет полный доступ ко всем объектам кластера.

Давайте назначим эту роль service account-у dashboard-а с помощью clusterrolebinding (привязки):

```console
kubectl create clusterrolebinding kubernetes-dashboard  --clusterrole=cluster-admin --serviceaccount=kube-system:kubernetes-dashboard
```

> Для clusterrole, serviceaccount - это комбинация serviceaccount и namespace, в котором он создан.

Заходим на <http://localhost:8001/ui> и видим, что доступ появился.

Для задания со * был применен [модуль Terraform](https://www.terraform.io/docs/providers/google/r/container_cluster.html) для работы с GKE.

Конфигурация в \kubernetes\terraform

## Введение в Kubernetes

### Создание примитивов

Опишем приложение в контексте Kubernetes с помощью manifest-ов в YAML-формате.
Основным примитивом будет Deployment.

Основные задачи сущности Deployment:

- создание Replication Controller-а (следит, чтобы число запущенных Pod-ов соответствовало описанному)
- ведение истории версий запущенных Pod-ов (для различных стратегий деплоя, для возможностей отката)
- описание процесса деплоя (стратегия, параметры стратегий)

Теперь:

- cоздадим директорию kubernetes в корне репозитория
- внутри директории kubernetes создадим директорию reddit
- сохраним файл post-deployment.yml в директории kubernetes/reddit
- создадим собственные файлы с Deployment манифестами приложений и сохраните в папке kubernetes/reddit
  - ui-deployment.yml
  - comment-deployment.yml
  - mongo-deployment.yml
  - post-deployment.yml

```yml
---
apiVersion: apps/v1beta2
kind: Deployment
metadata:
  name: post-deployment
spec:
  replicas: 1
  selector:
    matchLabels:
      app: post
  template:
    metadata:
      name: post
      labels:
        app: post
    spec:
      containers:
      - image: chromko/post
        name: post
```

Эти файлы нужны для создания структуры и проверки работоспособности kubernetes-кластера.

### Kubernetes The Hard Way

Пройдем этапы Kubernetes [The Hard Way](https://github.com/kelseyhightower/kubernetes-the-hard-way)

Туториал представляет собой:

- пошаговое руководство по ручной инсталляции основных компонентов Kubernetes кластера
- краткое описание необходимых действий и объектов

Что сделаем:

- создадим отдельную директорию the_hard_way в директории kubernetes
- пройдем Kubernetes The Hard Way
- проверим, что kubectl apply -f filename проходит по созданным до этого deployment-ам (ui, post, mongo, comment) и поды запускаются
- удалим кластер после прохождения THW
- все созданные в ходе прохождения THW файлы (кроме бинарных) поместим в папку kubernetes/the_hard_way репозитория

#### Подготовка

Для начала установим tmux и запустим его:

```console
sudo apt-get install -y tmux
tmux attach || tmux new
```

>Краткая шпаргалка по [tmux](https://habr.com/ru/post/126996/)
Включение синхронизации панелей ctrl+b и затем shift+:
set synchronize-panes on/off

Воспользуемся [Google Cloud Platform](https://cloud.google.com/).

Проверим версию Google Cloud SDK, должна быть выше 262.0.0:

```console
gcloud version
```

Зададим зону и регион:

```console
gcloud config set compute/region europe-west1
gcloud config set compute/zone europe-west1-b
```

#### Установка клиенских утилит

Далее мы установим утилиты коммандной строки: [cfssl](https://github.com/cloudflare/cfssl), [cfssljson](https://github.com/cloudflare/cfssl) и [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl).

##### Установим cfssl и cfssljson

Утилиты командной строки `cfssl` и `cfssljson` используются для обеспечения [инфраструктуры PKI](https://en.wikipedia.org/wiki/Public_key_infrastructure) и создания сертификатов TLS.

Установим их:

```console
wget -q --show-progress --https-only --timestamping \
  https://storage.googleapis.com/kubernetes-the-hard-way/cfssl/linux/cfssl \
  https://storage.googleapis.com/kubernetes-the-hard-way/cfssl/linux/cfssljson
chmod +x cfssl cfssljson
sudo mv cfssl cfssljson /usr/local/bin/
```

Проверим, что `cfssl` и `cfssljson` имеют версию выше 1.3.4:

```console
cfssl version

Version: 1.3.4
Revision: dev
Runtime: go1.13
```

```console
cfssljson --version

Version: 1.3.4
Revision: dev
Runtime: go1.13
```

##### Установим kubectl

Утилита командной строки `kubectl` используется для взаимодействия с Kubernetes API Server.

```console
wget https://storage.googleapis.com/kubernetes-release/release/v1.15.3/bin/linux/amd64/kubectl
chmod +x kubectl
sudo mv kubectl /usr/local/bin/
```

Проверим, что `kubelet` имеет версию выше 1.15.3:

```console
kubectl version --client

Client Version: version.Info{Major:"1", Minor:"15", GitVersion:"v1.15.3", GitCommit:"2d3c76f9091b6bec110a5e63777c332469e0cba2", GitTreeState:"clean", BuildDate:"2019-08-19T11:13:54Z", GoVersion:"go1.12.9", Compiler:"gc", Platform:"linux/amd64"}
```

#### Предоставление VM

Для Kubernetes требуется набор VM для размещения управляющего уровня Kubernetes и рабочих нодов, на которых в конечном итоге запускаются контейнеры. Далее мы предоставим VM, необходимые для запуска безопасного и высокодоступного кластера Kubernetes в одной [compute zone](https://cloud.google.com/compute/docs/regions-zones/regions-zones).

##### Сети

[Сетевая модель](https://kubernetes.io/docs/concepts/cluster-administration/networking/#kubernetes-model) Kubernetes предполагает плоскую сеть, в которой контейнеры и ноды могут взаимодействовать друг с другом. В тех случаях, когда это нежелательно, [сетевые политики](https://kubernetes.io/docs/concepts/services-networking/network-policies/) могут ограничивать способы взаимодействия групп контейнеров друг с другом и с внешними конечными точками сети.

##### Virtual Private Cloud Network

В этом разделе мы настроим [Virtual Private Cloud](https://cloud.google.com/compute/docs/networks-and-firewalls#networks) (VPC) сеть для размещения кластера Kubernetes.

Создаем `kubernetes-the-hard-way` пользовательскую VPC сеть:

```console
gcloud compute networks create kubernetes-the-hard-way --subnet-mode custom
```

Для [подсети](https://cloud.google.com/compute/docs/vpc/#vpc_networks_and_subnets) должен быть предусмотрен диапазон IP-адресов, достаточно большой для назначения приватного IP-адреса каждой ноде в кластере Kubernetes.

Создаем `kubernetes` подсеть в `kubernetes-the-hard-way` VPC сети:

```console
gcloud compute networks subnets create kubernetes \
  --network kubernetes-the-hard-way \
  --range 10.240.0.0/24
```

##### Создаем правило фаервола для внутренего взаимодействия

Создадим правило фаервола, которое разрешает внутреннюю связь по всем протоколам:

```console
gcloud compute firewall-rules create kubernetes-the-hard-way-allow-internal \
  --allow tcp,udp,icmp \
  --network kubernetes-the-hard-way \
  --source-ranges 10.240.0.0/24,10.200.0.0/16
```

Создаем правило фаервола для внешнего доступа по SSH, ICMP и HTTPS:

```console
gcloud compute firewall-rules create kubernetes-the-hard-way-allow-external \
  --allow tcp:22,tcp:6443,icmp \
  --network kubernetes-the-hard-way \
  --source-ranges 0.0.0.0/0
```

>Внешний балансировщик нагрузки будет использоваться для предоставления Kubernetes API Servers удаленным клиентам.

Просмотрим список правил нашей `kubernetes-the-hard-way` VPC:

```console
gcloud compute firewall-rules list --filter="network:kubernetes-the-hard-way"

NAME                                    NETWORK                  DIRECTION  PRIORITY  ALLOW                 DENY
kubernetes-the-hard-way-allow-external  kubernetes-the-hard-way  INGRESS    1000      tcp:22,tcp:6443,icmp
kubernetes-the-hard-way-allow-internal  kubernetes-the-hard-way  INGRESS    1000      tcp,udp,icmp
```

##### Публичный IP-адрес Kubernetes

Назначаем статический IP, который будет назначен на внешний балансировщик нагрузки Kubernetes API Server:

```console
gcloud compute addresses create kubernetes-the-hard-way \
  --region $(gcloud config get-value compute/region)
```

Убедимся что в нашем compute region по умолчанию создан статический IP-адрес `kubernetes-the-hard-way`:

```console
gcloud compute addresses list --filter="name=('kubernetes-the-hard-way')"

NAME                     REGION        ADDRESS        STATUS
kubernetes-the-hard-way  europe-west1  35.240.96.49   RESERVED
```

##### Создание экземпляров VM

Далее будут подготовлены VM с использованием [Ubuntu Server](https://www.ubuntu.com/server) 18.04, которая хорошо поддерживает [containerd container runtime](https://github.com/containerd/containerd). Каждой VM будет предоставлен фиксированный приватный IP-адрес, чтобы упростить процесс запуска Kubernetes.

##### Kubernetes контроллеры

Создадим три VM, в которых будет размещен управляющий уровень Kubernetes:

```console
for i in 0 1 2; do
  gcloud compute instances create controller-${i} \
    --async \
    --boot-disk-size 200GB \
    --can-ip-forward \
    --image-family ubuntu-1804-lts \
    --image-project ubuntu-os-cloud \
    --machine-type n1-standard-1 \
    --private-network-ip 10.240.0.1${i} \
    --scopes compute-rw,storage-ro,service-management,service-control,logging-write,monitoring \
    --subnet kubernetes \
    --tags kubernetes-the-hard-way,controller
done
```

##### Kubernetes рабочие ноды

Каждая рабочая нода требуется выделение подсети pod из диапазона CIDR кластера Kubernetes. Выделение pod подсети будет использоваться для настройки сети контейнера в дальнейших шагах. Метаданные VM `pod-cidr` будут использоваться для предоставления выделения pod подсетей в VM во время выполнения.

>Диапазон CIDR кластера Kubernetes определяется флагом Controller Manager `--cluster-cidr`. В этом руководстве диапазон CIDR кластера будет установлен на `10.200.0.0/16`, который поддерживает 254 подсети.

Создайте три VM, в которых будут размещаться рабочие ноды Kubernetes:

```console
for i in 0 1 2; do
  gcloud compute instances create worker-${i} \
    --async \
    --boot-disk-size 200GB \
    --can-ip-forward \
    --image-family ubuntu-1804-lts \
    --image-project ubuntu-os-cloud \
    --machine-type n1-standard-1 \
    --metadata pod-cidr=10.200.${i}.0/24 \
    --private-network-ip 10.240.0.2${i} \
    --scopes compute-rw,storage-ro,service-management,service-control,logging-write,monitoring \
    --subnet kubernetes \
    --tags kubernetes-the-hard-way,worker
done
```

- Проверка

Получим список VM нашей зоны по умолчанию:

```console
gcloud compute instances list

NAME          ZONE            MACHINE_TYPE   PREEMPTIBLE  INTERNAL_IP  EXTERNAL_IP      STATUS
controller-0  europe-west1-b  n1-standard-1               10.240.0.10  35.233.123.235   RUNNING
controller-1  europe-west1-b  n1-standard-1               10.240.0.11  146.148.7.86     RUNNING
controller-2  europe-west1-b  n1-standard-1               10.240.0.12  35.195.97.219    RUNNING
worker-0      europe-west1-b  n1-standard-1               10.240.0.20  35.189.249.239   RUNNING
worker-1      europe-west1-b  n1-standard-1               10.240.0.21  35.240.55.107    RUNNING
worker-2      europe-west1-b  n1-standard-1               10.240.0.22  104.155.119.210  RUNNING
```

##### Настройка SSH доступа

SSH будет использоваться для настройки контроллеров и рабочих нод. При первом подключении к VM ключи SSH будут сгенерированы для нас и сохранены в метаданных проекта или экземпляра, как описано в документации [по подключению к экземплярам](https://cloud.google.com/compute/docs/instances/connecting-to-instance).

Проверка SSH поделючения к `controller-0` VM:

```console
gcloud compute ssh controller-0
```

Если мы впервые подключаетесь к VM, то для нас будут сгенерированы SSH-ключи. Введем пароль в ответ на приглашение продолжить:

```console
WARNING: The public SSH key file for gcloud does not exist.
WARNING: The private SSH key file for gcloud does not exist.
WARNING: You do not have an SSH key for gcloud.
WARNING: SSH keygen will be executed to generate a key.
Generating public/private rsa key pair.
Enter passphrase (empty for no passphrase):
Enter same passphrase again:
```

На этом этапе сгенерированные ключи SSH будут загружены и сохранены в нашем проекте:

```console
Your identification has been saved in /home/$USER/.ssh/google_compute_engine.
Your public key has been saved in /home/$USER/.ssh/google_compute_engine.pub.
The key fingerprint is:
SHA256:nz1i8jHmgQuGt+WscqP5SeIaSy5wyIJeL71MuV+QruE $USER@$HOSTNAME
The key's randomart image is:
+---[RSA 2048]----+
|                 |
|                 |
|                 |
|        .        |
|o.     oS        |
|=... .o .o o     |
|+.+ =+=.+.X o    |
|.+ ==O*B.B = .   |
| .+.=EB++ o      |
+----[SHA256]-----+
Updating project ssh metadata...-Updated [https://www.googleapis.com/compute/v1/projects/$PROJECT_ID].
Updating project ssh metadata...done.
Waiting for SSH key to propagate.
```

После обновления ключей SSH мы подключимся к `controller-0`:

```console
Welcome to Ubuntu 18.04.3 LTS (GNU/Linux 4.15.0-1042-gcp x86_64)
...

Last login: Mon Dec 30 14:34:27 2019 from XX.XX.XX.XX
```

Ввведем `exit` в командной строке для выхода из `controller-0`:

```console
$USER@controller-0:~$ exit

logout
Connection to XX.XXX.XXX.XXX closed
```

#### Предоставление CA и создание TLS сертификатов

Далее мы развернем [PKI инфраструктуру](https://en.wikipedia.org/wiki/Public_key_infrastructure) используя инструменты CloudFlare's PKI, [cfssl](https://github.com/cloudflare/cfssl) и затем применим для запуска Certificate Authority и создания TLS сертификатов для следующих компонентов: etcd, kube-apiserver, kube-controller-manager, kube-scheduler, kubelet и kube-proxy.

##### Certificate Authority

В этой части мы развернем Certificate Authority, который будет использован для создания дополнительных сертификатов TLS.

Создадим CA файла конфигурации, сертификат и закрытый ключ:

```console
{

cat > ca-config.json <<EOF
{
  "signing": {
    "default": {
      "expiry": "8760h"
    },
    "profiles": {
      "kubernetes": {
        "usages": ["signing", "key encipherment", "server auth", "client auth"],
        "expiry": "8760h"
      }
    }
  }
}
EOF

cat > ca-csr.json <<EOF
{
  "CN": "Kubernetes",
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "US",
      "L": "Portland",
      "O": "Kubernetes",
      "OU": "CA",
      "ST": "Oregon"
    }
  ]
}
EOF

cfssl gencert -initca ca-csr.json | cfssljson -bare ca

}
```

Результат:

```console
ca-key.pem
ca.pem
```

##### Сертификаты клиента и сервера

В этом разделе мы создадим сертификаты сервера и клиента для каждого Kubernetes компонента для пользователя `admin`.

Клиентский сертификат пользователя `admin`:

```console
{

cat > admin-csr.json <<EOF
{
  "CN": "admin",
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "US",
      "L": "Portland",
      "O": "system:masters",
      "OU": "Kubernetes The Hard Way",
      "ST": "Oregon"
    }
  ]
}
EOF

cfssl gencert \
  -ca=ca.pem \
  -ca-key=ca-key.pem \
  -config=ca-config.json \
  -profile=kubernetes \
  admin-csr.json | cfssljson -bare admin

}
```

Результат:

```console
admin-key.pem
admin.pem
```

#### Клиентские сертификаты Kubelet

Kubernetes использует [специальный режим авторизации](https://kubernetes.io/docs/admin/authorization/node/), называемый Node Authorizer, который авторизует запросы API, сделанные [Kubelets](https://kubernetes.io/docs/concepts/overview/components/#kubelet). Чтобы авторизоваться Node Authorizer, Kubelets должны использовать учетные данные, которые идентифицируют их как принадлежащие к группе system:node с именем пользователя `system:node:<nodeName>`. В этом разделе мы создадим сертификат для каждой рабочей ноды Kubernetes, который отвечает требованиям Node Authorizer.

Создадим сертификат и закрытый ключ для каждой рабочей ноды:

```console
for instance in worker-0 worker-1 worker-2; do
cat > ${instance}-csr.json <<EOF
{
  "CN": "system:node:${instance}",
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "US",
      "L": "Portland",
      "O": "system:nodes",
      "OU": "Kubernetes The Hard Way",
      "ST": "Oregon"
    }
  ]
}
EOF

EXTERNAL_IP=$(gcloud compute instances describe ${instance} \
  --format 'value(networkInterfaces[0].accessConfigs[0].natIP)')

INTERNAL_IP=$(gcloud compute instances describe ${instance} \
  --format 'value(networkInterfaces[0].networkIP)')

cfssl gencert \
  -ca=ca.pem \
  -ca-key=ca-key.pem \
  -config=ca-config.json \
  -hostname=${instance},${EXTERNAL_IP},${INTERNAL_IP} \
  -profile=kubernetes \
  ${instance}-csr.json | cfssljson -bare ${instance}
done
```

Результат:

```console
worker-0-key.pem
worker-0.pem
worker-1-key.pem
worker-1.pem
worker-2-key.pem
worker-2.pem
```

##### Клиенский сертификат Controller Manager

Создадим клиентский сертификат и закрытый ключ для `kube-controller-manager`:

```console
{

cat > kube-controller-manager-csr.json <<EOF
{
  "CN": "system:kube-controller-manager",
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "US",
      "L": "Portland",
      "O": "system:kube-controller-manager",
      "OU": "Kubernetes The Hard Way",
      "ST": "Oregon"
    }
  ]
}
EOF

cfssl gencert \
  -ca=ca.pem \
  -ca-key=ca-key.pem \
  -config=ca-config.json \
  -profile=kubernetes \
  kube-controller-manager-csr.json | cfssljson -bare kube-controller-manager

}
```

Результат:

```console
kube-controller-manager-key.pem
kube-controller-manager.pem
```

##### Клиенский сертификат Kube Proxy

Создадим клиентский сертификат и закрытый ключ для `kube-proxy`:

```console
{

cat > kube-proxy-csr.json <<EOF
{
  "CN": "system:kube-proxy",
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "US",
      "L": "Portland",
      "O": "system:node-proxier",
      "OU": "Kubernetes The Hard Way",
      "ST": "Oregon"
    }
  ]
}
EOF

cfssl gencert \
  -ca=ca.pem \
  -ca-key=ca-key.pem \
  -config=ca-config.json \
  -profile=kubernetes \
  kube-proxy-csr.json | cfssljson -bare kube-proxy

}
```

Результат:

```console
kube-proxy-key.pem
kube-proxy.pem
```

##### Клиентский сертификат Scheduler

Создадим клиентский сертификат и закрытый ключ для `kube-scheduler`:

```console
{

cat > kube-scheduler-csr.json <<EOF
{
  "CN": "system:kube-scheduler",
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "US",
      "L": "Portland",
      "O": "system:kube-scheduler",
      "OU": "Kubernetes The Hard Way",
      "ST": "Oregon"
    }
  ]
}
EOF

cfssl gencert \
  -ca=ca.pem \
  -ca-key=ca-key.pem \
  -config=ca-config.json \
  -profile=kubernetes \
  kube-scheduler-csr.json | cfssljson -bare kube-scheduler

}
```

Результат:

```console
kube-scheduler-key.pem
kube-scheduler.pem
```

##### Сертификат Kubernetes API Server

Статический IP-адрес `kubernetes-the-hard-way` будет включен в список альтернативных имен субъектов для сертификата сервера Kubernetes API. Это гарантирует, что сертификат может быть проверен удаленными клиентами.

Создадим сертификат сервера и закрытый ключ для Kubernetes API:

```console
{

KUBERNETES_PUBLIC_ADDRESS=$(gcloud compute addresses describe kubernetes-the-hard-way \
  --region $(gcloud config get-value compute/region) \
  --format 'value(address)')

KUBERNETES_HOSTNAMES=kubernetes,kubernetes.default,kubernetes.default.svc,kubernetes.default.svc.cluster,kubernetes.svc.cluster.local

cat > kubernetes-csr.json <<EOF
{
  "CN": "kubernetes",
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "US",
      "L": "Portland",
      "O": "Kubernetes",
      "OU": "Kubernetes The Hard Way",
      "ST": "Oregon"
    }
  ]
}
EOF

cfssl gencert \
  -ca=ca.pem \
  -ca-key=ca-key.pem \
  -config=ca-config.json \
  -hostname=10.32.0.1,10.240.0.10,10.240.0.11,10.240.0.12,${KUBERNETES_PUBLIC_ADDRESS},127.0.0.1,${KUBERNETES_HOSTNAMES} \
  -profile=kubernetes \
  kubernetes-csr.json | cfssljson -bare kubernetes

}
```

>Серверу API Kubernetes автоматически присваивается внутреннее DNS-имя `kubernetes`, которое будет связано с первым IP-адресом (`10.32.0.1`) из диапазона адресов (`10.32.0.0/24`), зарезервированного для внутренних сервисов кластера во время запуска управляющейго уровня.

Результат:

```console
kubernetes-key.pem
kubernetes.pem
```

##### Пара ключей Service Account

Kubernetes Controller Manager использует пару ключей для создания и подписи токенов Service Account, как описано в документации [по управлению учетными записями сервисов](https://kubernetes.io/docs/admin/service-accounts-admin/).

Создадим сертификат и закрытый ключ для `service-account`:

```console
{

cat > service-account-csr.json <<EOF
{
  "CN": "service-accounts",
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "US",
      "L": "Portland",
      "O": "Kubernetes",
      "OU": "Kubernetes The Hard Way",
      "ST": "Oregon"
    }
  ]
}
EOF

cfssl gencert \
  -ca=ca.pem \
  -ca-key=ca-key.pem \
  -config=ca-config.json \
  -profile=kubernetes \
  service-account-csr.json | cfssljson -bare service-account

}
```

Результат:

```console
service-account-key.pem
service-account.pem
```

##### Копирование сертификатов на ноды

Скопируем соответствующие сертификаты и закрытые ключи на каждую рабочую ноду:

```console
for instance in worker-0 worker-1 worker-2; do
  gcloud compute scp ca.pem ${instance}-key.pem ${instance}.pem ${instance}:~/
done
```

Скопируем соответствующие сертификаты и закрытые ключи на каждую ноду контроллера:

```console
for instance in controller-0 controller-1 controller-2; do
  gcloud compute scp ca.pem ca-key.pem kubernetes-key.pem kubernetes.pem \
    service-account-key.pem service-account.pem ${instance}:~/
done
```

>Клиентские сертификаты `kube-proxy`, `kube-controller-manager`, `kube-scheduler` и `kubelet` будут использоваться для создания файлов конфигурации аутентификации клиента далее.

#### Создание конфигурационных файлов Kubernetes для аутентификации

Далее мы создадим [файлы конфигурации Kubernetes](https://kubernetes.io/docs/concepts/configuration/organize-cluster-access-kubeconfig/), также известные как kubeconfigs, которые позволяют клиентам Kubernetes обнаруживать и проверять подлинность на серверах API Kubernetes.

##### Конфигурации аутентификации клиента

В этои разделе мы создадим файлы kubeconfig для `controller manager`, `kubelet`, `kube-proxy`, `scheduler clients` и пользователя `admin`.

##### Публичный IP адрес Kubernetes

Каждому kubeconfig требуется сервер API Kubernetes для подключения. Для обеспечения высокой доступности будет использоваться IP-адрес, назначенный нашему балансировщику нагрузки на серверах API Kubernetes.

Получим статический IP-адрес `kubernetes-the-hard-way`:

```console
KUBERNETES_PUBLIC_ADDRESS=$(gcloud compute addresses describe kubernetes-the-hard-way \
  --region $(gcloud config get-value compute/region) \
  --format 'value(address)')
```

##### Файл конфигурации kubelet Kubernetes

При создании файлов kubeconfig для Kubelets должен использоваться сертификат клиента, соответствующий имени узла Kubelet. Это обеспечит Kubelets надлежащую авторизацию [Node Authorizer](https://kubernetes.io/docs/admin/authorization/node/).

Создадим файл kubeconfig для каждой рабочей ноды:

```console
for instance in worker-0 worker-1 worker-2; do
  kubectl config set-cluster kubernetes-the-hard-way \
    --certificate-authority=ca.pem \
    --embed-certs=true \
    --server=https://${KUBERNETES_PUBLIC_ADDRESS}:6443 \
    --kubeconfig=${instance}.kubeconfig

  kubectl config set-credentials system:node:${instance} \
    --client-certificate=${instance}.pem \
    --client-key=${instance}-key.pem \
    --embed-certs=true \
    --kubeconfig=${instance}.kubeconfig

  kubectl config set-context default \
    --cluster=kubernetes-the-hard-way \
    --user=system:node:${instance} \
    --kubeconfig=${instance}.kubeconfig

  kubectl config use-context default --kubeconfig=${instance}.kubeconfig
done
```

Результат:

```console
worker-0.kubeconfig
worker-1.kubeconfig
worker-2.kubeconfig
```

##### Файл конфигурации kube-proxy Kubernetes

Создадим файл kubeconfig для `kube-proxy` сервиса:

```console
{
  kubectl config set-cluster kubernetes-the-hard-way \
    --certificate-authority=ca.pem \
    --embed-certs=true \
    --server=https://${KUBERNETES_PUBLIC_ADDRESS}:6443 \
    --kubeconfig=kube-proxy.kubeconfig

  kubectl config set-credentials system:kube-proxy \
    --client-certificate=kube-proxy.pem \
    --client-key=kube-proxy-key.pem \
    --embed-certs=true \
    --kubeconfig=kube-proxy.kubeconfig

  kubectl config set-context default \
    --cluster=kubernetes-the-hard-way \
    --user=system:kube-proxy \
    --kubeconfig=kube-proxy.kubeconfig

  kubectl config use-context default --kubeconfig=kube-proxy.kubeconfig
}
```

Результат:

```console
kube-proxy.kubeconfig
```

##### Файл конфигурации kube-controller-manager Kubernetes

Создадим файл kubeconfig для `kube-controller-manager` сервиса:

```console
{
  kubectl config set-cluster kubernetes-the-hard-way \
    --certificate-authority=ca.pem \
    --embed-certs=true \
    --server=https://127.0.0.1:6443 \
    --kubeconfig=kube-controller-manager.kubeconfig

  kubectl config set-credentials system:kube-controller-manager \
    --client-certificate=kube-controller-manager.pem \
    --client-key=kube-controller-manager-key.pem \
    --embed-certs=true \
    --kubeconfig=kube-controller-manager.kubeconfig

  kubectl config set-context default \
    --cluster=kubernetes-the-hard-way \
    --user=system:kube-controller-manager \
    --kubeconfig=kube-controller-manager.kubeconfig

  kubectl config use-context default --kubeconfig=kube-controller-manager.kubeconfig
}
```

Результат:

```console
kube-controller-manager.kubeconfig
```

##### Файл конфигурации kube-scheduler Kubernetes

Создадим файл kubeconfig для `kube-scheduler` сервиса:

```console
{
  kubectl config set-cluster kubernetes-the-hard-way \
    --certificate-authority=ca.pem \
    --embed-certs=true \
    --server=https://127.0.0.1:6443 \
    --kubeconfig=kube-scheduler.kubeconfig

  kubectl config set-credentials system:kube-scheduler \
    --client-certificate=kube-scheduler.pem \
    --client-key=kube-scheduler-key.pem \
    --embed-certs=true \
    --kubeconfig=kube-scheduler.kubeconfig

  kubectl config set-context default \
    --cluster=kubernetes-the-hard-way \
    --user=system:kube-scheduler \
    --kubeconfig=kube-scheduler.kubeconfig

  kubectl config use-context default --kubeconfig=kube-scheduler.kubeconfig
}
```

Результат:

```console
kube-scheduler.kubeconfig
```

##### Файл конфигурации пользователя admin

Создадим файл kubeconfig для пользователя `admin`:

```console
{
  kubectl config set-cluster kubernetes-the-hard-way \
    --certificate-authority=ca.pem \
    --embed-certs=true \
    --server=https://127.0.0.1:6443 \
    --kubeconfig=admin.kubeconfig

  kubectl config set-credentials admin \
    --client-certificate=admin.pem \
    --client-key=admin-key.pem \
    --embed-certs=true \
    --kubeconfig=admin.kubeconfig

  kubectl config set-context default \
    --cluster=kubernetes-the-hard-way \
    --user=admin \
    --kubeconfig=admin.kubeconfig

  kubectl config use-context default --kubeconfig=admin.kubeconfig
}
```

Результат:

```console
admin.kubeconfig
```

##### Копирование конфигурационных файлов на ноды

Скопируем соответствующие kubeconfig файлы `kubelet` и `kube-proxy` на каждую рабочую ноду:

```console
for instance in worker-0 worker-1 worker-2; do
  gcloud compute scp ${instance}.kubeconfig kube-proxy.kubeconfig ${instance}:~/
done
```

Скопируем соответствующие kubeconfig файлы `kube-controller-manager` и `kube-scheduler` на каждую ноду контроллера:

```console
for instance in controller-0 controller-1 controller-2; do
  gcloud compute scp admin.kubeconfig kube-controller-manager.kubeconfig kube-scheduler.kubeconfig ${instance}:~/
done
```

#### Создание конфигурации шифрования данных и ключа

Kubernetes хранит различные данные, включая состояние кластера, конфигурации приложений и секреты. Kubernetes поддерживает возможность [шифрования](https://kubernetes.io/docs/tasks/administer-cluster/encrypt-data) данных кластера в состоянии покоя.

Далее мы создадим ключ шифрования и [конфигурацию шифрования](https://kubernetes.io/docs/tasks/administer-cluster/encrypt-data/#understanding-the-encryption-at-rest-configuration), подходящую для шифрования секретов Kubernetes.

##### Ключ шифрования

Создадим ключа шифрования:

```console
ENCRYPTION_KEY=$(head -c 32 /dev/urandom | base64)
```

#### Файл конфигурации шифрования

Создадим файл конфигурации `encryption-config.yaml`:

```console
cat > encryption-config.yaml <<EOF
kind: EncryptionConfig
apiVersion: v1
resources:
  - resources:
      - secrets
    providers:
      - aescbc:
          keys:
            - name: key1
              secret: ${ENCRYPTION_KEY}
      - identity: {}
EOF
```

Скопируем файлы конфигурации шифровния `encryption-config.yaml` на каждую ноду контроллера:

```console
for instance in controller-0 controller-1 controller-2; do
  gcloud compute scp encryption-config.yaml ${instance}:~/
done
```

#### Запуск кластера etcd

Компоненты Kubernetes не имеют состояния и хранят состояние кластера в [etcd.](https://github.com/etcd-io/etcd) Далее мы запустим кластер с тремя etcd нодами и настроим его для обеспечения высокой доступности и безопасного удаленного доступа.

Подготовка

Далее мы должны выполнить команды на каждой ноде контроллера: `controller-0`, `controller-1` и `controller-2`. Зайдем на каждую ноду контроллера с помощью команды `gcloud`. Пример:

```console
gcloud compute ssh controller-0
```

- tmux

##### Загрузим и установим бинарники [etcd](https://github.com/etcd-io/etcd)

```console
wget -q --show-progress --https-only --timestamping \
  "https://github.com/etcd-io/etcd/releases/download/v3.4.0/etcd-v3.4.0-linux-amd64.tar.gz"
```

Извлечем и установим `etcd` и утилиту командной строки `etcdctl`:

```console
{
  tar -xvf etcd-v3.4.0-linux-amd64.tar.gz
  sudo mv etcd-v3.4.0-linux-amd64/etcd* /usr/local/bin/
}
```

##### Настроим etcd

```console
{
  sudo mkdir -p /etc/etcd /var/lib/etcd
  sudo cp ca.pem kubernetes-key.pem kubernetes.pem /etc/etcd/
}
```

Внутренний IP-адрес VM будет использоваться для обслуживания клиентских запросов и связи с одноранговыми кластерами etcd. Получим внутренний IP-адрес для текущей VM:

```console
INTERNAL_IP=$(curl -s -H "Metadata-Flavor: Google" \
  http://metadata.google.internal/computeMetadata/v1/instance/network-interfaces/0/ip)
```

Каждый участник etcd должен иметь уникальное имя в кластере etcd. Установим имя etcd в соответствии с именем хоста текущей VM:

```console
ETCD_NAME=$(hostname -s)
```

Создадим `etcd.service` system unit файл:

```console
cat <<EOF | sudo tee /etc/systemd/system/etcd.service
[Unit]
Description=etcd
Documentation=https://github.com/coreos

[Service]
Type=notify
ExecStart=/usr/local/bin/etcd \\
  --name ${ETCD_NAME} \\
  --cert-file=/etc/etcd/kubernetes.pem \\
  --key-file=/etc/etcd/kubernetes-key.pem \\
  --peer-cert-file=/etc/etcd/kubernetes.pem \\
  --peer-key-file=/etc/etcd/kubernetes-key.pem \\
  --trusted-ca-file=/etc/etcd/ca.pem \\
  --peer-trusted-ca-file=/etc/etcd/ca.pem \\
  --peer-client-cert-auth \\
  --client-cert-auth \\
  --initial-advertise-peer-urls https://${INTERNAL_IP}:2380 \\
  --listen-peer-urls https://${INTERNAL_IP}:2380 \\
  --listen-client-urls https://${INTERNAL_IP}:2379,https://127.0.0.1:2379 \\
  --advertise-client-urls https://${INTERNAL_IP}:2379 \\
  --initial-cluster-token etcd-cluster-0 \\
  --initial-cluster controller-0=https://10.240.0.10:2380,controller-1=https://10.240.0.11:2380,controller-2=https://10.240.0.12:2380 \\
  --initial-cluster-state new \\
  --data-dir=/var/lib/etcd
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
```

##### Стартуем etcd

```console
{
  sudo systemctl daemon-reload
  sudo systemctl enable etcd
  sudo systemctl start etcd
}
```

- Проверка

Вывод списка участников кластера:

```console
sudo ETCDCTL_API=3 etcdctl member list \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/etcd/ca.pem \
  --cert=/etc/etcd/kubernetes.pem \
  --key=/etc/etcd/kubernetes-key.pem

3a57933972cb5131, started, controller-2, https://10.240.0.12:2380, https://10.240.0.12:2379
f98dc20bce6225a0, started, controller-0, https://10.240.0.10:2380, https://10.240.0.10:2379
ffed16798470cab5, started, controller-1, https://10.240.0.11:2380, https://10.240.0.11:2379
```

#### Запуск управлящего уровня Kubernetes

Далее мы запустим управляющий уровень Kubernetes на трех VM и сконфигурируем их для высокой доступности. Мы также создадим внешний балансировщик нагрузки, который предоставляет доступ к серверам API Kubernetes для удаленных клиентов. На каждой ноде будут установлены следующие компоненты: Kubernetes API Server, Scheduler и Controller Manager.

Подготовка

В этом разделе мы должны выполнить команды на каждой ноде контроллера: `controller-0`, `controller-1` и `controller-2`. Зайдем на каждую ноду контроллера с помощью команды `gcloud`. Пример:

```console
gcloud compute ssh controller-0
```

- tmux

##### Предоставление управляющего уровня

Создадим директории для конфигурации Kubernetes:

```console
sudo mkdir -p /etc/kubernetes/config
```

##### Загрузиим и установим бинарники Kubernetes Controller

```console
wget -q --show-progress --https-only --timestamping \
  "https://storage.googleapis.com/kubernetes-release/release/v1.15.3/bin/linux/amd64/kube-apiserver" \
  "https://storage.googleapis.com/kubernetes-release/release/v1.15.3/bin/linux/amd64/kube-controller-manager" \
  "https://storage.googleapis.com/kubernetes-release/release/v1.15.3/bin/linux/amd64/kube-scheduler" \
  "https://storage.googleapis.com/kubernetes-release/release/v1.15.3/bin/linux/amd64/kubectl"
```

Установим бинарники:

```console
{
  chmod +x kube-apiserver kube-controller-manager kube-scheduler kubectl
  sudo mv kube-apiserver kube-controller-manager kube-scheduler kubectl /usr/local/bin/
}
```

##### Настроим Kubernetes API Server

```console
{
  sudo mkdir -p /var/lib/kubernetes/

  sudo mv ca.pem ca-key.pem kubernetes-key.pem kubernetes.pem \
    service-account-key.pem service-account.pem \
    encryption-config.yaml /var/lib/kubernetes/
}
```

Внутренний IP-адрес VM будет использоваться для объявления API серверу участника кластера. Получим внутренний IP-адрес для текущей VM:

```console
INTERNAL_IP=$(curl -s -H "Metadata-Flavor: Google" \
  http://metadata.google.internal/computeMetadata/v1/instance/network-interfaces/0/ip)
```

Создадим `kube-apiserver.service` system unit файл:

```console
cat <<EOF | sudo tee /etc/systemd/system/kube-apiserver.service
[Unit]
Description=Kubernetes API Server
Documentation=https://github.com/kubernetes/kubernetes

[Service]
ExecStart=/usr/local/bin/kube-apiserver \\
  --advertise-address=${INTERNAL_IP} \\
  --allow-privileged=true \\
  --apiserver-count=3 \\
  --audit-log-maxage=30 \\
  --audit-log-maxbackup=3 \\
  --audit-log-maxsize=100 \\
  --audit-log-path=/var/log/audit.log \\
  --authorization-mode=Node,RBAC \\
  --bind-address=0.0.0.0 \\
  --client-ca-file=/var/lib/kubernetes/ca.pem \\
  --enable-admission-plugins=NamespaceLifecycle,NodeRestriction,LimitRanger,ServiceAccount,DefaultStorageClass,ResourceQuota \\
  --etcd-cafile=/var/lib/kubernetes/ca.pem \\
  --etcd-certfile=/var/lib/kubernetes/kubernetes.pem \\
  --etcd-keyfile=/var/lib/kubernetes/kubernetes-key.pem \\
  --etcd-servers=https://10.240.0.10:2379,https://10.240.0.11:2379,https://10.240.0.12:2379 \\
  --event-ttl=1h \\
  --encryption-provider-config=/var/lib/kubernetes/encryption-config.yaml \\
  --kubelet-certificate-authority=/var/lib/kubernetes/ca.pem \\
  --kubelet-client-certificate=/var/lib/kubernetes/kubernetes.pem \\
  --kubelet-client-key=/var/lib/kubernetes/kubernetes-key.pem \\
  --kubelet-https=true \\
  --runtime-config=api/all \\
  --service-account-key-file=/var/lib/kubernetes/service-account.pem \\
  --service-cluster-ip-range=10.32.0.0/24 \\
  --service-node-port-range=30000-32767 \\
  --tls-cert-file=/var/lib/kubernetes/kubernetes.pem \\
  --tls-private-key-file=/var/lib/kubernetes/kubernetes-key.pem \\
  --v=2
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
```

##### Настроим Kubernetes Controller Manager

Переместим `kube-controller-manager` kubeconfig:

```console
sudo mv kube-controller-manager.kubeconfig /var/lib/kubernetes/
```

Создадим `kube-controller-manager.service` system unit файл:

```console
cat <<EOF | sudo tee /etc/systemd/system/kube-controller-manager.service
[Unit]
Description=Kubernetes Controller Manager
Documentation=https://github.com/kubernetes/kubernetes

[Service]
ExecStart=/usr/local/bin/kube-controller-manager \\
  --address=0.0.0.0 \\
  --cluster-cidr=10.200.0.0/16 \\
  --cluster-name=kubernetes \\
  --cluster-signing-cert-file=/var/lib/kubernetes/ca.pem \\
  --cluster-signing-key-file=/var/lib/kubernetes/ca-key.pem \\
  --kubeconfig=/var/lib/kubernetes/kube-controller-manager.kubeconfig \\
  --leader-elect=true \\
  --root-ca-file=/var/lib/kubernetes/ca.pem \\
  --service-account-private-key-file=/var/lib/kubernetes/service-account-key.pem \\
  --service-cluster-ip-range=10.32.0.0/24 \\
  --use-service-account-credentials=true \\
  --v=2
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
```

##### Настроим Kubernetes Scheduler

Переместим `kube-scheduler` kubeconfig:

```console
sudo mv kube-scheduler.kubeconfig /var/lib/kubernetes/
```

Создадим файл конфигурации `kube-scheduler.yaml`:

```console
cat <<EOF | sudo tee /etc/kubernetes/config/kube-scheduler.yaml
apiVersion: kubescheduler.config.k8s.io/v1alpha1
kind: KubeSchedulerConfiguration
clientConnection:
  kubeconfig: "/var/lib/kubernetes/kube-scheduler.kubeconfig"
leaderElection:
  leaderElect: true
EOF
```

Создадим `kube-scheduler.service` system unit файл:

```console
cat <<EOF | sudo tee /etc/systemd/system/kube-scheduler.service
[Unit]
Description=Kubernetes Scheduler
Documentation=https://github.com/kubernetes/kubernetes

[Service]
ExecStart=/usr/local/bin/kube-scheduler \\
  --config=/etc/kubernetes/config/kube-scheduler.yaml \\
  --v=2
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
```

##### Запустим Controller Services

```console
{
  sudo systemctl daemon-reload
  sudo systemctl enable kube-apiserver kube-controller-manager kube-scheduler
  sudo systemctl start kube-apiserver kube-controller-manager kube-scheduler
}
```

>Подождем 10 секунд для полной инициализации Kubernetes API Server.

##### Включим HTTP Health Checks

[Балансировщик сетевой нагрузки Google](https://cloud.google.com/compute/docs/load-balancing/network) будет использоваться для распределения трафика между тремя API-серверами и позволит каждому API-серверу завершать соединения TLS и проверять сертификаты клиентов. Балансировщик сетевой нагрузки поддерживает только проверки работоспособности HTTP, что означает, что конечная точка HTTPS, предоставляемая сервером API, не может использоваться. В качестве обходного пути можно использовать веб-сервер nginx для проверки работоспособности HTTP-прокси. В этом разделе будет установлен и настроен nginx для принятия проверок состояния HTTP на порт 80 и прокси-соединений к серверу API по адресу `https://127.0.0.1:6443/healthz`.

>Конечная точка `/healthz` API сервера не требует аутентификации по умолчанию.

Установим простой веб-сервер для обработки проверок состояния HTTP:

```console
sudo apt-get update
sudo apt-get install -y nginx

cat > kubernetes.default.svc.cluster.local <<EOF
server {
  listen      80;
  server_name kubernetes.default.svc.cluster.local;

  location /healthz {
     proxy_pass                    https://127.0.0.1:6443/healthz;
     proxy_ssl_trusted_certificate /var/lib/kubernetes/ca.pem;
  }
}
EOF

{
  sudo mv kubernetes.default.svc.cluster.local \
    /etc/nginx/sites-available/kubernetes.default.svc.cluster.local

  sudo ln -s /etc/nginx/sites-available/kubernetes.default.svc.cluster.local /etc/nginx/sites-enabled/
}

sudo systemctl restart nginx
sudo systemctl enable nginx
```

- Проверка

```console
kubectl get componentstatuses --kubeconfig admin.kubeconfig

NAME                 STATUS    MESSAGE              ERROR
controller-manager   Healthy   ok
scheduler            Healthy   ok
etcd-2               Healthy   {"health": "true"}
etcd-0               Healthy   {"health": "true"}
etcd-1               Healthy   {"health": "true"}
```

Проверим nginx HTTP healthcheck proxy:

```console
curl -H "Host: kubernetes.default.svc.cluster.local" -i http://127.0.0.1/healthz

HTTP/1.1 200 OK
Server: nginx/1.14.0 (Ubuntu)
Date: Sat, 14 Sep 2019 18:34:11 GMT
Content-Type: text/plain; charset=utf-8
Content-Length: 2
Connection: keep-alive
X-Content-Type-Options: nosniff

ok
```

- RBAC для авторизации Kubelet

Далее мы настроим разрешения RBAC, чтобы позволить серверу API Kubernetes получать доступ к API Kubelet на каждой рабочей ноде. Доступ к API Kubelet необходим для получения метрик, журналов и выполнения команд в pods.

>В нашем случае установлен флаг Kubelet `--authorization-mode` в `Webhook`. В режиме Webhook используется [SubjectAccessReview](https://kubernetes.io/docs/admin/authorization/#checking-api-access) API для определения авторизации.

Выполняем команды только на одном контроллере:

```console
gcloud compute ssh controller-0
```

Создадим `system:kube-apiserver-to-kubelet` [ClusterRole](https://kubernetes.io/docs/admin/authorization/rbac/#role-and-clusterrole) с разрешениями для доступа к API Kubelet и выполнения наиболее распространенных задач, связанных с управлением pods:

```console
cat <<EOF | kubectl apply --kubeconfig admin.kubeconfig -f -
apiVersion: rbac.authorization.k8s.io/v1beta1
kind: ClusterRole
metadata:
  annotations:
    rbac.authorization.kubernetes.io/autoupdate: "true"
  labels:
    kubernetes.io/bootstrapping: rbac-defaults
  name: system:kube-apiserver-to-kubelet
rules:
  - apiGroups:
      - ""
    resources:
      - nodes/proxy
      - nodes/stats
      - nodes/log
      - nodes/spec
      - nodes/metrics
    verbs:
      - "*"
EOF
```

Kubernetes API Server аутентифицируется в Kubelet как пользователь `kubernetes`, используя сертификат клиента, как определено флагом `--kubelet-client-certificate`.

Свяжем `system:kube-apiserver-to-kubelet` ClusterRole с пользователем `kubernetes`:

```console
cat <<EOF | kubectl apply --kubeconfig admin.kubeconfig -f -
apiVersion: rbac.authorization.k8s.io/v1beta1
kind: ClusterRoleBinding
metadata:
  name: system:kube-apiserver
  namespace: ""
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: system:kube-apiserver-to-kubelet
subjects:
  - apiGroup: rbac.authorization.k8s.io
    kind: User
    name: kubernetes
EOF
```

##### Балансер нагрузки внешнего интерфейса Kubernetes

Далее мы предоставим внешний балансировщик нагрузки для фронта серверов Kubernetes API. Статический IP-адрес `kubernetes-the-hard-way` будет привязан к результирующему балансировщику нагрузки.

- Выполним следующие команды с того же компьютера, который использовался для создания VM

##### Предоставим сетевой балансировщик нагрузки

Создадим external load balancer network resources:

```console
{
  KUBERNETES_PUBLIC_ADDRESS=$(gcloud compute addresses describe kubernetes-the-hard-way \
    --region $(gcloud config get-value compute/region) \
    --format 'value(address)')

  gcloud compute http-health-checks create kubernetes \
    --description "Kubernetes Health Check" \
    --host "kubernetes.default.svc.cluster.local" \
    --request-path "/healthz"

  gcloud compute firewall-rules create kubernetes-the-hard-way-allow-health-check \
    --network kubernetes-the-hard-way \
    --source-ranges 209.85.152.0/22,209.85.204.0/22,35.191.0.0/16 \
    --allow tcp

  gcloud compute target-pools create kubernetes-target-pool \
    --http-health-check kubernetes

  gcloud compute target-pools add-instances kubernetes-target-pool \
   --instances controller-0,controller-1,controller-2

  gcloud compute forwarding-rules create kubernetes-forwarding-rule \
    --address ${KUBERNETES_PUBLIC_ADDRESS} \
    --ports 6443 \
    --region $(gcloud config get-value compute/region) \
    --target-pool kubernetes-target-pool
}
```

- Проверка

Получим статический IP-адрес `kubernetes-the-hard-way`:

```console
KUBERNETES_PUBLIC_ADDRESS=$(gcloud compute addresses describe kubernetes-the-hard-way \
  --region $(gcloud config get-value compute/region) \
  --format 'value(address)')
```

Выполним HTTP запрос для получения информации о версии Kubernetes:

```console
curl --cacert ca.pem https://${KUBERNETES_PUBLIC_ADDRESS}:6443/version

{
  "major": "1",
  "minor": "15",
  "gitVersion": "v1.15.3",
  "gitCommit": "2d3c76f9091b6bec110a5e63777c332469e0cba2",
  "gitTreeState": "clean",
  "buildDate": "2019-08-19T11:05:50Z",
  "goVersion": "go1.12.9",
  "compiler": "gc",
  "platform": "linux/amd64"
}
```

#### Запуск рабочих нод Kubernetes

Далее мы запустим три рабочих ноды Kubernetes. Следующие компоненты будут установлены на каждом узле: [runc](https://github.com/opencontainers/runc), [container networking plugins](https://github.com/containernetworking/cni), [containerd](https://github.com/containerd/containerd), [kubelet](https://kubernetes.io/docs/admin/kubelet) и [kube-proxy](https://kubernetes.io/docs/concepts/cluster-administration/proxies).

- Подготовка

Далее мы должны выполнить команды на каждой рабочей ноде: `worker-0`, `worker-1` и `worker-2`. Зайдем на каждую рабочую ноду с помощью команды `gcloud`. Пример:

```console
gcloud compute ssh worker-0
```

- tmux

##### Предоставление рабочей ноды Kubernetes

Устанавливаем зависимости:

```console
{
  sudo apt-get update
  sudo apt-get -y install socat conntrack ipset
}
```

>Бинарный файл socat включает поддержку команды `kubectl port-forward`.

##### Отключаем swap

По умолчанию kubelet не запустится, если включен [swap](https://help.ubuntu.com/community/SwapFaq). [Рекомендуется](https://github.com/kubernetes/kubernetes/issues/7294) отключить swap, чтобы Kubernetes мог обеспечить правильное распределение ресурсов и качество обслуживания.

Проверим что swap включен:

```console
sudo swapon --show
```

Если вывод пуст, то swap не включен. Если swap включен, выполним следующую команду, чтобы немедленно отключить swap:

```console
sudo swapoff -a
```

>Чтобы swap остался выключенным после перезагрузки, обратимся к документации по дистрибутиву Linux

##### Скачиваем и устанавливаем бинарники рабочих нод

```console
wget -q --show-progress --https-only --timestamping \
  https://github.com/kubernetes-sigs/cri-tools/releases/download/v1.15.0/crictl-v1.15.0-linux-amd64.tar.gz \
  https://github.com/opencontainers/runc/releases/download/v1.0.0-rc8/runc.amd64 \
  https://github.com/containernetworking/plugins/releases/download/v0.8.2/cni-plugins-linux-amd64-v0.8.2.tgz \
  https://github.com/containerd/containerd/releases/download/v1.2.9/containerd-1.2.9.linux-amd64.tar.gz \
  https://storage.googleapis.com/kubernetes-release/release/v1.15.3/bin/linux/amd64/kubectl \
  https://storage.googleapis.com/kubernetes-release/release/v1.15.3/bin/linux/amd64/kube-proxy \
  https://storage.googleapis.com/kubernetes-release/release/v1.15.3/bin/linux/amd64/kubelet
```

Создаем установочные директории:

```console
sudo mkdir -p \
  /etc/cni/net.d \
  /opt/cni/bin \
  /var/lib/kubelet \
  /var/lib/kube-proxy \
  /var/lib/kubernetes \
  /var/run/kubernetes
```

Устанавливаем бинарники:

```console
{
  mkdir containerd
  tar -xvf crictl-v1.15.0-linux-amd64.tar.gz
  tar -xvf containerd-1.2.9.linux-amd64.tar.gz -C containerd
  sudo tar -xvf cni-plugins-linux-amd64-v0.8.2.tgz -C /opt/cni/bin/
  sudo mv runc.amd64 runc
  chmod +x crictl kubectl kube-proxy kubelet runc
  sudo mv crictl kubectl kube-proxy kubelet runc /usr/local/bin/
  sudo mv containerd/bin/* /bin/
}
```

##### Настройка Container Networking Interface

Получим диапазон Pod CIDR для текущей VM:

```console
POD_CIDR=$(curl -s -H "Metadata-Flavor: Google" \
  http://metadata.google.internal/computeMetadata/v1/instance/attributes/pod-cidr)
```

Создадим файл конфигурации для `bridge`:

```console
cat <<EOF | sudo tee /etc/cni/net.d/10-bridge.conf
{
    "cniVersion": "0.3.1",
    "name": "bridge",
    "type": "bridge",
    "bridge": "cnio0",
    "isGateway": true,
    "ipMasq": true,
    "ipam": {
        "type": "host-local",
        "ranges": [
          [{"subnet": "${POD_CIDR}"}]
        ],
        "routes": [{"dst": "0.0.0.0/0"}]
    }
}
EOF
```

Создадим файл конфигурации для `loopback`:

```console
cat <<EOF | sudo tee /etc/cni/net.d/99-loopback.conf
{
    "cniVersion": "0.3.1",
    "name": "lo",
    "type": "loopback"
}
EOF
```

##### Настроим containerd

Создадим файл конфигурации `containerd`:

```console
sudo mkdir -p /etc/containerd/

cat << EOF | sudo tee /etc/containerd/config.toml
[plugins]
  [plugins.cri.containerd]
    snapshotter = "overlayfs"
    [plugins.cri.containerd.default_runtime]
      runtime_type = "io.containerd.runtime.v1.linux"
      runtime_engine = "/usr/local/bin/runc"
      runtime_root = ""
EOF
```

Создадим `containerd.service` system unit файл:

```console
cat <<EOF | sudo tee /etc/systemd/system/containerd.service
[Unit]
Description=containerd container runtime
Documentation=https://containerd.io
After=network.target

[Service]
ExecStartPre=/sbin/modprobe overlay
ExecStart=/bin/containerd
Restart=always
RestartSec=5
Delegate=yes
KillMode=process
OOMScoreAdjust=-999
LimitNOFILE=1048576
LimitNPROC=infinity
LimitCORE=infinity

[Install]
WantedBy=multi-user.target
EOF
```

##### Настроим Kubelet

```console
{
  sudo mv ${HOSTNAME}-key.pem ${HOSTNAME}.pem /var/lib/kubelet/
  sudo mv ${HOSTNAME}.kubeconfig /var/lib/kubelet/kubeconfig
  sudo mv ca.pem /var/lib/kubernetes/
}
```

Создадим файл конфигурации `kubelet-config.yaml`:

```console
cat <<EOF | sudo tee /var/lib/kubelet/kubelet-config.yaml
kind: KubeletConfiguration
apiVersion: kubelet.config.k8s.io/v1beta1
authentication:
  anonymous:
    enabled: false
  webhook:
    enabled: true
  x509:
    clientCAFile: "/var/lib/kubernetes/ca.pem"
authorization:
  mode: Webhook
clusterDomain: "cluster.local"
clusterDNS:
  - "10.32.0.10"
podCIDR: "${POD_CIDR}"
resolvConf: "/run/systemd/resolve/resolv.conf"
runtimeRequestTimeout: "15m"
tlsCertFile: "/var/lib/kubelet/${HOSTNAME}.pem"
tlsPrivateKeyFile: "/var/lib/kubelet/${HOSTNAME}-key.pem"
EOF
```

>Конфигурация `resolvConf` используется, чтобы избежать петель при использовании CoreDNS для service discovery в системах с запущенным `systemd-resolved`.

Создадим `kubelet.service` system unit файл:

```console
cat <<EOF | sudo tee /etc/systemd/system/kubelet.service
[Unit]
Description=Kubernetes Kubelet
Documentation=https://github.com/kubernetes/kubernetes
After=containerd.service
Requires=containerd.service

[Service]
ExecStart=/usr/local/bin/kubelet \\
  --config=/var/lib/kubelet/kubelet-config.yaml \\
  --container-runtime=remote \\
  --container-runtime-endpoint=unix:///var/run/containerd/containerd.sock \\
  --image-pull-progress-deadline=2m \\
  --kubeconfig=/var/lib/kubelet/kubeconfig \\
  --network-plugin=cni \\
  --register-node=true \\
  --v=2
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
```

##### Настроим Kubernetes Proxy

```console
sudo mv kube-proxy.kubeconfig /var/lib/kube-proxy/kubeconfig
```

Создадим файл конфигурации `kube-proxy-config.yaml`:

```console
cat <<EOF | sudo tee /var/lib/kube-proxy/kube-proxy-config.yaml
kind: KubeProxyConfiguration
apiVersion: kubeproxy.config.k8s.io/v1alpha1
clientConnection:
  kubeconfig: "/var/lib/kube-proxy/kubeconfig"
mode: "iptables"
clusterCIDR: "10.200.0.0/16"
EOF
```

Создадим `kube-proxy.service` system unit файл:

```console
cat <<EOF | sudo tee /etc/systemd/system/kube-proxy.service
[Unit]
Description=Kubernetes Kube Proxy
Documentation=https://github.com/kubernetes/kubernetes

[Service]
ExecStart=/usr/local/bin/kube-proxy \\
  --config=/var/lib/kube-proxy/kube-proxy-config.yaml
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
```

##### Запустим сервисы

```console
{
  sudo systemctl daemon-reload
  sudo systemctl enable containerd kubelet kube-proxy
  sudo systemctl start containerd kubelet kube-proxy
}
```

- Проверка

- Выполним следующие команды с того же компьютера, который использовался для создания VM

Вывод списка рабочих нод Kubernetes:

```console
gcloud compute ssh controller-0 \
  --command "kubectl get nodes --kubeconfig admin.kubeconfig"

NAME       STATUS   ROLES    AGE   VERSION
worker-0   Ready    <none>   15s   v1.15.3
worker-1   Ready    <none>   15s   v1.15.3
worker-2   Ready    <none>   15s   v1.15.3
```

#### Настройка kubectl для удаленного доступа

Далее мы создадим файл kubeconfig для утилиты командной строки `kubectl` на основе учетных данных пользователя `admin`.

##### Файл конфигурации для пользователя admin

Каждому kubeconfig требуется сервер API Kubernetes для подключения. Для обеспечения высокой доступности будет использоваться IP-адрес, назначенный внешнему балансировщику нагрузки на серверах API Kubernetes.

Сгенерируем файл kubeconfig, подходящий для аутентификации пользователя как `admin`:

```console
{
  KUBERNETES_PUBLIC_ADDRESS=$(gcloud compute addresses describe kubernetes-the-hard-way \
    --region $(gcloud config get-value compute/region) \
    --format 'value(address)')

  kubectl config set-cluster kubernetes-the-hard-way \
    --certificate-authority=ca.pem \
    --embed-certs=true \
    --server=https://${KUBERNETES_PUBLIC_ADDRESS}:6443

  kubectl config set-credentials admin \
    --client-certificate=admin.pem \
    --client-key=admin-key.pem

  kubectl config set-context kubernetes-the-hard-way \
    --cluster=kubernetes-the-hard-way \
    --user=admin

  kubectl config use-context kubernetes-the-hard-way
}
```

- Проверка

Проверим работоспособность удаленного кластера Kubernetes:

```console
kubectl get componentstatuses

NAME                 STATUS    MESSAGE             ERROR
controller-manager   Healthy   ok
scheduler            Healthy   ok
etcd-1               Healthy   {"health":"true"}
etcd-2               Healthy   {"health":"true"}
etcd-0               Healthy   {"health":"true"}
```

Получим список рабочих нод удаленного кластера Kubernetes:

```console
kubectl get nodes

NAME       STATUS   ROLES    AGE    VERSION
worker-0   Ready    <none>   2m9s   v1.15.3
worker-1   Ready    <none>   2m9s   v1.15.3
worker-2   Ready    <none>   2m9s   v1.15.3
```

#### Предоставление сетевых маршрутов Pod

Pods, запланированные для ноды, получают IP-адрес из Pod CIDR диапазона ноды. На этом этапе pods не могут связываться с другими pods, работающими на разных нодах из-за отсутствия сетевых [маршрутов](https://cloud.google.com/compute/docs/vpc/routes).

Далее мы создадим маршрут для каждой рабочей ноды, который сопоставляет диапазон Pod CIDR узла с внутренним IP-адресом ноды.

> Также есть и [другие способы](https://kubernetes.io/docs/concepts/cluster-administration/networking/#how-to-achieve-this) реализации сетевой модели Kubernetes.

##### Таблица маршрутизации

В данном разделе мы соберете информацию, необходимую для создания маршрутов в сети VPC `kubernetes-the-hard-way`.

Получим внутренний IP-адрес и диапазон Pod CIDR для каждого рабочей ноды:

```console
for instance in worker-0 worker-1 worker-2; do
  gcloud compute instances describe ${instance} \
    --format 'value[separator=" "](networkInterfaces[0].networkIP,metadata.items[0].value)'
done

10.240.0.20 10.200.0.0/24
10.240.0.21 10.200.1.0/24
10.240.0.22 10.200.2.0/24
```

##### Маршруты

Создадим сетевые маршруты для каждой рабочей ноды:

```console
for i in 0 1 2; do
  gcloud compute routes create kubernetes-route-10-200-${i}-0-24 \
    --network kubernetes-the-hard-way \
    --next-hop-address 10.240.0.2${i} \
    --destination-range 10.200.${i}.0/24
done
```

Получим список маршрутов в сети VPC `kubernetes-the-hard-way`:

```console
gcloud compute routes list --filter "network: kubernetes-the-hard-way"

NAME                            NETWORK                  DEST_RANGE     NEXT_HOP                  PRIORITY
default-route-081879136902de56  kubernetes-the-hard-way  10.240.0.0/24  kubernetes-the-hard-way   1000
default-route-55199a5aa126d7aa  kubernetes-the-hard-way  0.0.0.0/0      default-internet-gateway  1000
kubernetes-route-10-200-0-0-24  kubernetes-the-hard-way  10.200.0.0/24  10.240.0.20               1000
kubernetes-route-10-200-1-0-24  kubernetes-the-hard-way  10.200.1.0/24  10.240.0.21               1000
kubernetes-route-10-200-2-0-24  kubernetes-the-hard-way  10.200.2.0/24  10.240.0.22               1000
```

#### Развертывание надстройки DNS кластера

Далее мы развернем [надстройку DNS](https://kubernetes.io/docs/concepts/services-networking/dns-pod-service/), которая обеспечивает DNS service discovery на основе [CoreDNS](https://coredns.io/), для приложений работающих в кластере Kubernetes.

##### Надстройка DNS-кластера

Развертывание надстройки кластера `coredns`:

```console
kubectl apply -f https://storage.googleapis.com/kubernetes-the-hard-way/coredns.yaml

serviceaccount/coredns created
clusterrole.rbac.authorization.k8s.io/system:coredns created
clusterrolebinding.rbac.authorization.k8s.io/system:coredns created
configmap/coredns created
deployment.extensions/coredns created
service/kube-dns created
```

Выведем список pods созданных `kube-dns` deployment:

```console
kubectl get pods -l k8s-app=kube-dns -n kube-system

NAME                       READY   STATUS    RESTARTS   AGE
coredns-699f8ddd77-94qv9   1/1     Running   0          20s
coredns-699f8ddd77-gtcgb   1/1     Running   0          20s
```

- Проверка

Создадим `busybox` deployment:

```console
kubectl run --generator=run-pod/v1 busybox --image=busybox:1.28 --command -- sleep 3600
```

Получим список pods созданных `busybox` deployment:

```console
kubectl get pods -l run=busybox

NAME      READY   STATUS    RESTARTS   AGE
busybox   1/1     Running   0          3s
```

Получим полное имя `busybox` pod:

```console
POD_NAME=$(kubectl get pods -l run=busybox -o jsonpath="{.items[0].metadata.name}")
```

Выполним DNS lookup для kubernetes сервиса внутри `busybox` pod:

```console
kubectl exec -ti $POD_NAME -- nslookup kubernetes

Server:    10.32.0.10
Address 1: 10.32.0.10 kube-dns.kube-system.svc.cluster.local

Name:      kubernetes
Address 1: 10.32.0.1 kubernetes.default.svc.cluster.local
```

#### Smoke Test

Далее мы выполним ряд задач, чтобы убедиться, что наш кластер Kubernetes работает правильно.

##### Шифрование данных

В данном разделе мы проверим возможность [шифрования секретных данных в состоянии покоя](https://kubernetes.io/docs/tasks/administer-cluster/encrypt-data/#verifying-that-data-is-encrypted).

Создадим обычный секрет:

```console
kubectl create secret generic kubernetes-the-hard-way \
  --from-literal="mykey=mydata"
```

Получим hexdump секрета `kubernetes-the-hard-way`, хранящегося в etcd:

```console
gcloud compute ssh controller-0 \
  --command "sudo ETCDCTL_API=3 etcdctl get \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/etcd/ca.pem \
  --cert=/etc/etcd/kubernetes.pem \
  --key=/etc/etcd/kubernetes-key.pem\
  /registry/secrets/default/kubernetes-the-hard-way | hexdump -C"

00000000  2f 72 65 67 69 73 74 72  79 2f 73 65 63 72 65 74  |/registry/secret|
00000010  73 2f 64 65 66 61 75 6c  74 2f 6b 75 62 65 72 6e  |s/default/kubern|
00000020  65 74 65 73 2d 74 68 65  2d 68 61 72 64 2d 77 61  |etes-the-hard-wa|
00000030  79 0a 6b 38 73 3a 65 6e  63 3a 61 65 73 63 62 63  |y.k8s:enc:aescbc|
00000040  3a 76 31 3a 6b 65 79 31  3a 44 ac 6e ac 11 2f 28  |:v1:key1:D.n../(|
00000050  02 46 3d ad 9d cd 68 be  e4 cc 63 ae 13 e4 99 e8  |.F=...h...c.....|
00000060  6e 55 a0 fd 9d 33 7a b1  17 6b 20 19 23 dc 3e 67  |nU...3z..k .#.>g|
00000070  c9 6c 47 fa 78 8b 4d 28  cd d1 71 25 e9 29 ec 88  |.lG.x.M(..q%.)..|
00000080  7f c9 76 b6 31 63 6e ea  ac c5 e4 2f 32 d7 a6 94  |..v.1cn..../2...|
00000090  3c 3d 97 29 40 5a ee e1  ef d6 b2 17 01 75 a4 a3  |<=.)@Z.......u..|
000000a0  e2 c2 70 5b 77 1a 0b ec  71 c3 87 7a 1f 68 73 03  |..p[w...q..z.hs.|
000000b0  67 70 5e ba 5e 65 ff 6f  0c 40 5a f9 2a bd d6 0e  |gp^.^e.o.@Z.*...|
000000c0  44 8d 62 21 1a 30 4f 43  b8 03 69 52 c0 b7 2e 16  |D.b!.0OC..iR....|
000000d0  14 a5 91 21 29 fa 6e 03  47 e2 06 25 45 7c 4f 8f  |...!).n.G..%E|O.|
000000e0  6e bb 9d 3b e9 e5 2d 9e  3e 0a                    |n..;..-.>.|
```

Ключу etcd должен предшествовать `k8s:enc:aescbc:v1:key1`, который указывает, что поставщик `aescbc` использовался для шифрования данных с ключом шифрования `key1`.

##### Deployments

В этом разделе мы проверим возможность создания и управления [Deployments](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/).

Создадим deployments для [nginx](https://nginx.org/en/) веб сервера:

```console
kubectl create deployment nginx --image=nginx
```

Выведем список pods созданных `nginx` deployment:

```console
kubectl get pods -l app=nginx

NAME                     READY   STATUS    RESTARTS   AGE
nginx-554b9c67f9-vt5rn   1/1     Running   0          10s
```

##### Port Forwarding

В этом разделе мы проверим возможность удаленного доступа к приложениям с помощью [переадресации портов](https://kubernetes.io/docs/tasks/access-application-cluster/port-forward-access-application-cluster/).

Получим полное имя `nginx` pod:

```console
POD_NAME=$(kubectl get pods -l app=nginx -o jsonpath="{.items[0].metadata.name}")
```

Перенаправим порт `8080` на нашем локальном компьютере на порт `80` `nginx` pod:

```console
kubectl port-forward $POD_NAME 8080:80

Forwarding from 127.0.0.1:8080 -> 80
Forwarding from [::1]:8080 -> 80
```

В новом окне терминала создадим HTTP запрос используя адрес переадресации:

```console
curl --head http://127.0.0.1:8080

HTTP/1.1 200 OK
Server: nginx/1.17.6
Date: Mon, 30 Dec 2019 14:35:23 GMT
Content-Type: text/html
Content-Length: 612
Last-Modified: Tue, 19 Nov 2019 12:50:08 GMT
Connection: keep-alive
ETag: "5dd3e500-264"
Accept-Ranges: bytes
```

Вернемся к предыдущему терминалу и остановим переадресацию порта на `nginx` pod:

```console
Forwarding from 127.0.0.1:8080 -> 80
Forwarding from [::1]:8080 -> 80
Handling connection for 8080
^C
```

##### Логирование

В этом разделе мы проверим возможность [получения логов контейнера](https://kubernetes.io/docs/concepts/cluster-administration/logging/).

Выведем лог `nginx` pod:

```console
kubectl logs $POD_NAME

127.0.0.1 - - [30/Dec/2019:14:35:23 +0000] "HEAD / HTTP/1.1" 200 0 "-" "curl/7.58.0" "-"
```

##### Exec

В этом разделе мы проверим возможность [выполнения команд в контейнере](https://kubernetes.io/docs/tasks/debug-application-cluster/get-shell-running-container/#running-individual-commands-in-a-container).

Выведем версию nginx, выполнив команду `nginx -v` в контейнере `nginx`:

```console
kubectl exec -ti $POD_NAME -- nginx -v

nginx version: nginx/1.17.6
```

##### Services

В этом разделе мы проверим возможность выставлять приложения, используя [Service](https://kubernetes.io/docs/concepts/services-networking/service/).

Предоставим `nginx` deployment с помощью [NodePort](https://kubernetes.io/docs/concepts/services-networking/service/#type-nodeport) сервиса:

```console
kubectl expose deployment nginx --port 80 --type NodePort
```

>Нельзя использовать тип службы LoadBalancer, поскольку в нашем кластере не настроена [интеграция с облачным провайдером](https://kubernetes.io/docs/getting-started-guides/scratch/#cloud-provider). Настройка интеграции с облачным провайдером выходит за рамки данного руководства.

Получим список нодов назначенных `nginx` сервису:

```console
NODE_PORT=$(kubectl get svc nginx \
  --output=jsonpath='{range .spec.ports[0]}{.nodePort}')
```

Создадим правило фаервола разрешающее удаленный доступ к `nginx` порту ноды:

```console
gcloud compute firewall-rules create kubernetes-the-hard-way-allow-nginx-service \
  --allow=tcp:${NODE_PORT} \
  --network kubernetes-the-hard-way
```

Получим внешний IP-адрес рабочей ноды:

```console
EXTERNAL_IP=$(gcloud compute instances describe worker-0 \
  --format 'value(networkInterfaces[0].accessConfigs[0].natIP)')
```

Создадим HTTP запрос используя внешний IP-адрес и `nginx` порт ноды:

```console
curl -I http://${EXTERNAL_IP}:${NODE_PORT}

HTTP/1.1 200 OK
Server: nginx/1.17.6
Date: Mon, 30 Dec 2019 14:35:23 GMT
Content-Type: text/html
Content-Length: 612
Last-Modified: Tue, 19 Nov 2019 12:50:08 GMT
Connection: keep-alive
ETag: "5dd3e500-264"
Accept-Ranges: bytes
```

##### Проверка создания deployments нашего приложения

Перед удалнием кластера, проверим прохождение создания deployments для нашего приложения:

```console
cd kubernetes/reddit
kubectl apply -f ui-deployment.yml
kubectl apply -f comment-deployment.yml
kubectl apply -f mongo-deployment.yml
kubectl apply -f post-deployment.yml

kubectl get pods
NAME                                  READY   STATUS    RESTARTS   AGE
busybox                               1/1     Running   0          40m
comment-deployment-5878bc6dbf-at8tz   1/1     Running   0          43s
mongo-deployment-36d49115c4-ra6vs     1/1     Running   0          34s
nginx-587b9c67f9-jmlrh                1/1     Running   0          58m
post-deployment-79115fc5df-zn3zl      1/1     Running   0          12s
ui-deployment-ab9f4cab3-ndtdl         1/1     Running   0          54s
```

#### Удаление кластера после прохождения THW

Далее мы удалим VM, созданные для работы.

##### VM

Удалим рабочие и контроллер VM:

```console
gcloud -q compute instances delete \
  controller-0 controller-1 controller-2 \
  worker-0 worker-1 worker-2 \
  --zone $(gcloud config get-value compute/zone)
```

##### Networks

Удалим внешние сетевые ресурсы балансировщика нагрузки:

```console
{
  gcloud -q compute forwarding-rules delete kubernetes-forwarding-rule \
    --region $(gcloud config get-value compute/region)

  gcloud -q compute target-pools delete kubernetes-target-pool

  gcloud -q compute http-health-checks delete kubernetes

  gcloud -q compute addresses delete kubernetes-the-hard-way
}
```

Удалим правила фаервола `kubernetes-the-hard-way`:

```console
gcloud -q compute firewall-rules delete \
  kubernetes-the-hard-way-allow-nginx-service \
  kubernetes-the-hard-way-allow-internal \
  kubernetes-the-hard-way-allow-external \
  kubernetes-the-hard-way-allow-health-check
```

Удалим VPC сеть `kubernetes-the-hard-way`:

```console
{
  gcloud -q compute routes delete \
    kubernetes-route-10-200-0-0-24 \
    kubernetes-route-10-200-1-0-24 \
    kubernetes-route-10-200-2-0-24

  gcloud -q compute networks subnets delete kubernetes

  gcloud -q compute networks delete kubernetes-the-hard-way
}
```

- Задание со *

Для выполнения задания воспользуемся [Kubernetes on Google Computing Engine](https://github.com/Zenika/k8s-on-gce).

Данный проект позволит автоматизировать развертывание Kubernetes на примере 3 контроллеров и 3 рабочих нод на GCE.

Также полезный материал - [A custom Kubernetes Cluster on GCP in 7 minutes with Terraform and Ansible](https://medium.zenika.com/a-custom-kubernetes-cluster-on-gcp-in-7-minutes-with-terraform-and-ansible-75875f89309e).

## Логирование и распределенная трассировка

- Подготовка

- обновим код микросервисов, в который был добавлен функционала логирования <https://github.com/express42/reddit/tree/logging> (git clone -b logging --single-branch <https://github.com/express42/reddit.git>)
- выполним сборку образов при помощи скриптов docker_build.sh в директории каждого сервиса:

```console
bash docker_build.sh && docker push $USER_NAME/ui
bash docker_build.sh && docker push $USER_NAME/post
bash docker_build.sh && docker push $USER_NAME/comment
```

- или сразу все из корня репозитория: for i in ui post-py comment; do cd src/$i; bash docker_build.sh; cd -; done
- или c помощью Makefile: make build_app
- создадим Docker хост в GCE и настроим локальное окружение на работу с ним, откроем порты файрволла:

```console
export GOOGLE_PROJECT=docker-258208

docker-machine create --driver google \
--google-machine-image https://www.googleapis.com/compute/v1/projects/ubuntu-os-cloud/global/images/family/ubuntu-1604-lts  \
--google-machine-type n1-standard-1 \
--google-zone europe-west1-b \
--google-machine-type n1-standard-1 \
--google-open-port 5601/tcp \
--google-open-port 9292/tcp \
--google-open-port 9411/tcp \
logging

eval $(docker-machine env logging)
docker-machine ip logging
```

### Логирование Docker контейнеров

Как упоминалось на лекции хранить все логи стоит централизованно: на одном (нескольких) серверах. В этом ДЗ мы рассмотрим пример системы централизованного логирования на примере Elastic стека (ранее известного как ELK): который включает в себя 3 основных компонента:

- ElasticSearch (TSDB и поисковый движок для хранения данных)
- Logstash (для агрегации и трансформации данных)
- Kibana (для визуализации)

Однако для агрегации логов вместо Logstash мы будем использовать Fluentd, таким образом получая еще одно популярное сочетание этих инструментов, получившее название EFK.

Создадим отдельный compose-файл для нашей системы логирования в папке docker/docker-compose-logging.yml

```y
version: '3'
services:
  fluentd:
    image: ${USERNAME}/fluentd
    ports:
      - "24224:24224"
      - "24224:24224/udp"

  elasticsearch:
    image: elasticsearch:7.5.0
    expose:
      - 9200
    ports:
      - "9200:9200"

  kibana:
    image: kibana:7.5.0
    ports:
      - "5601:5601"
```

Fluentd инструмент, который может использоваться для отправки, агрегации и преобразования лог-сообщений. Мы будем использовать Fluentd для агрегации (сбора в одной месте) и парсинга логов сервисов нашего приложения.
Создадим образ Fluentd с нужной нам конфигурацией.
Создадим в проекте microservices директорию logging/fluentd
В созданной директорий, создадим простой Dockerfile со следущим содержимым:

```dockerfile
FROM fluent/fluentd:v0.12
RUN fluent-gem install fluent-plugin-elasticsearch --no-rdoc --no-ri --version 1.9.5
RUN fluent-gem install fluent-plugin-grok-parser --no-rdoc --no-ri --version 1.0.0
ADD fluent.conf /fluentd/etc
```

В директории logging/fluentd создадим файл конфигурации logging/fluentd/fluent.conf

```console
<source>
  @type forward
  port 24224
  bind 0.0.0.0
</source>

<match *.**>
  @type copy
  <store>
    @type elasticsearch
    host elasticsearch
    port 9200
    logstash_format true
    logstash_prefix fluentd
    logstash_dateformat %Y%m%d
    include_tag_key true
    type_name access_log
    tag_key @log_name
    flush_interval 1s
  </store>
  <store>
    @type stdout
  </store>
</match>
```

Соберем docker image для fluentd из директории logging/fluentd

docker build -t $USER_NAME/fluentd .

### Структурированные логи

Логи должны иметь заданную (единую) структуру и содержать необходимую для нормальной эксплуатации данного сервиса информацию о его работе.
Лог-сообщения также должны иметь понятный для выбранной системы логирования формат, чтобы избежать ненужной траты ресурсов на преобразование данных в нужный вид.

Структурированные логи мы рассмотрим на примере сервиса post.

Правим .env файл и меняем теги нашего приложения на logging

Запустим сервисы приложения:

docker-compose up -d

И выполним команду для просмотра логов post сервиса:

docker-compose logs -f post

Откроем приложение в браузере и создадим несколько постов, и пронаблюдаем, как пишутся логи post серсиса в терминале.

Каждое событие, связанное с работой нашего приложения логируется в JSON формате и имеет нужную нам структуру: тип события (event), сообщение (message),переданные функции параметры (params), имя сервиса (service) и др.

По умолчанию Docker контейнерами используется json-file драйвер для логирования информации, которая пишется сервисом внутри контейнера в stdout (и stderr).
Для отправки логов во Fluentd используем docker драйвер fluentd.

Определим драйвер для логирования для сервиса post внутри compose-файла docker-compose.yml

```yml
    logging:
      driver: "fluentd"
      options:
        fluentd-address: localhost:24224
        tag: service.post
```

Поднимем инфраструктуру централизованной системы логирования и перезапустим сервисы приложения из каталога docker или с помощью Makefile

```console
docker-compose -f docker-compose-logging.yml up -d
docker-compose down
docker-compose up -d
```

У нас возникла проблема с запуском elasticsearch. Смотрим логи elasticsearch и видим две ошибки, которые нам предстоит исправить:

```console
ERROR: [2] bootstrap checks failed
[1]: max virtual memory areas vm.max_map_count [65530] is too low, increase to at least [262144]
[2]: the default discovery settings are unsuitable for production use; at least one of [discovery.seed_hosts, discovery.seed_providers, cluster.initial_master_nodes] must be configured
```

Немного погуглим и находим ответы

Решение первой: sudo sysctl -w vm.max_map_count=262144
Решение второй: <https://medium.com/@TimvanBaarsen/how-to-run-an-elasticsearch-7-x-single-node-cluster-for-local-development-using-docker-compose-2b7ab73d8b82>

Снова пытаемся запустить нашу систему логирования и проверяем успешность старта.

Kibana - инструмент для визуализации и анализа логов от компании Elastic.
Откроем WEB-интерфейс Kibana для просмотра собранных в ElasticSearch логов Post-сервиса (kibana слушает на порту 5601)

- введем в поле индекса паттерна: fluentd-* и создадим индекс маппинг
- нажмем "Discovery" чтобы посмотреть информацию о полученных лог сообщениях (график покажет в какой момент времени поступало то или иное количество лог сообщений)
- нажмем на знак "развернуть" напротив одного из лог сообщений, чтобы посмотреть подробную информацию о нем

Мы увидим лог-сообщение, которые мы недавно наблюдали в терминале. Теперь эти лог-сообщения хранятся централизованно в ElasticSearch. Также видим доп. информацию о том, откуда поступил данный лог.

Обратим внимание на то, что наименования в левом столбце, называются полями. По полям можно производить поиск для быстрого нахождения нужной информации.

Для того чтобы посмотреть некоторые примеры поиска, можно ввести в поле поиска произвольное выражение.
К примеру, посмотрев список доступных полей, мы можем выполнить поиск всех логов, поступивших с контейнера reddit_post_1.

Заметим, что поле log содержит в себе JSON объект, который содержит много интересной нам информации.

Нам хотелось бы выделить эту информацию в поля, чтобы иметь возможность производить по ним поиск. Например, для того чтобы найти все логи, связанные с определенным событием (event) или конкретным сервисов (service).

Мы можем достичь этого за счет использования фильтров для выделения нужной информации.

Добавим фильтр для парсинга json логов, приходящих от post сервиса, в конфиг fluentd.conf

```console
<filter service.post>
  @type parser
  format json
  key_name log
</filter>
```

После этого персоберем образ и перезапустим сервис fluentd.
Создадим пару новых постов, чтобы проверить парсинг логов.

Вернемся в Kibana, взглянем на одно из сообщений и увидим, что вместо одного
поля log появилось множество полей с нужной нам информацией.

### Неструктурированные логи

Неструктурированные логи отличаются отсутствием четкой структуры данных. Также часто бывает, что формат лог-сообщений не подстроен под систему централизованного логирования, что существенно увеличивает затраты вычислительных и временных ресурсов на обработку данных и выделение нужной информации.
На примере сервиса ui мы рассмотрим пример логов с неудобным форматом сообщений.

По аналогии с post сервисом определим для ui сервиса драйвер для логирования fluentd в compose-файле docker-compose.yml

```yml
    logging:
      driver: "fluentd"
      options:
        fluentd-address: localhost:24224
        tag: service.ui
```

Перезапустим ui сервис из каталога docker:

```console
docker-compose stop ui
docker-compose rm ui
docker-compose up -d
```

И посмотрим на формат собираемых сообщений

Когда приложение или сервис не пишет структурированные логи, приходится использовать старые добрые регулярные выражения для их парсинга в /docker fluentd/fluent.conf.
Следующее регулярное выражение нужно, чтобы успешно выделить интересующую нас информацию из лога UI-сервиса в поля:

```console
<filter service.ui>
  @type parser
  format /\[(?<time>[^\]]*)\]  (?<level>\S+) (?<user>\S+)[\W]*service=(?<service>\S+)[\W]*event=(?<event>\S+)[\W]*(?:path=(?<path>\S+)[\W]*)?request_id=(?<request_id>\S+)[\W]*(?:remote_addr=(?<remote_addr>\S+)[\W]*)?(?:method= (?<method>\S+)[\W]*)?(?:response_status=(?<response_status>\S+)[\W]*)?(?:message='(?<message>[^\']*)[\W]*)?/
  key_name log
</filter>
```

Обновим образ fluentd и перезапустим kibana

```console
docker build -t $USER_NAME/fluentd .
docker-compose -f docker-compose-logging.yml down
docker-compose -f docker-compose-logging.yml up -d
```

Проверим результат

Созданные регулярки могут иметь ошибки, их сложно менять и невозможно читать. Для облегчения задачи парсинга вместо стандартных регулярок можно использовать grok-шаблоны. По-сути grok’и - это именованные шаблоны регулярных выражеий (очень похоже на функции). Можно использовать готовый regexp, просто сославшись на него как на функцию docker/fluentd/fluent.conf

```console
<filter service.ui>
  @type parser
  key_name log
  format grok
  grok_pattern %{RUBY_LOGGER}
</filter>
```

Это grok-шаблон, зашитый в плагин для fluentd
Как мы можем заметить часть логов все еще нужно распарсить. Для этого используем несколько Grok-ов по-очереди:

```console
<filter service.ui>
  @type parser
  format grok
  grok_pattern service=%{WORD:service} \| event=%{WORD:event} \| request_id=%{GREEDYDATA:request_id} \| message='%{GREEDYDATA:message}'
  key_name message
  reserve_data true
</filter>
```

Задание со * - UI-сервис шлет логи в нескольких форматах. Такой лог остался неразобранным.
Дополним наш fluent.conf для разбора обоих форматор логов UI-сервиса одновременно:

```console
<filter service.ui>
  @type parser
  format grok
  <grok>
    pattern service=%{WORD:service} \| event=%{WORD:event} \| request_id=%{GREEDYDATA:request_id} \| message='%{GREEDYDATA:message}'
  </grok>
  <grok>
    pattern service=%{WORD:service} \| event=%{WORD:event} \| path=%{URIPATH:path} \| request_id=%{GREEDYDATA:request_id} \| remote_addr=%{IP:remote_addr} \| method= %{WORD:message} \| response_status=%{INT:response_status}
  </grok>
  key_name message
  reserve_data true
</filter>
```

### Распределенный трейсинг

Добавим в compose-файл для сервисов логирования сервис распределенного трейсинга Zipkin:

```yml
services:
  zipkin:
    image: openzipkin/zipkin
    ports:
      - "9411:9411"
```

Правим наш docker/docker-compose-logging.yml
Добавим для каждого сервиса поддержку ENV переменных и зададим параметризованный параметр ZIPKIN_ENABLED

```yml
environment:
- ZIPKIN_ENABLED=${ZIPKIN_ENABLED}
```

В .env файле укажем: ZIPKIN_ENABLED=true

Пересоздадим наши сервисы:

```console
docker-compose -f docker-compose-logging.yml -f docker-compose.yml down
docker-compose -f docker-compose-logging.yml -f docker-compose.yml up -d
```

Откроем главную страницу приложения и обновим ее несколько
раз.
Заглянув затем в UI Zipkin (страницу потребуется обновить), мы должны найти несколько трейсов (следов, которые оставили запросы проходя через систему наших сервисов).

Нажмем на один из трейсов, чтобы посмотреть, как запрос шел через нашу систему микросервисов и каково общее время обработки запроса у нашего приложения при запросе главной страницы.

Видим, что первым делом наш запрос попал к ui сервису, который смог обработать наш запрос за суммарное время равное 72.075ms.
Из этих 72.075ms ушло 18.147ms на то чтобы ui мог направить запрос post сервису по пути /posts и получить от него ответ в виде списка постов. Post сервис в свою очередь использовал функцию обращения к БД за списком постов, на что ушло 3.572ms.

Синие полоски со временем называются span и представляют собой одну операцию, которая произошла при обработке запроса. Набор span-ов называется трейсом. Суммарное время обработки нашего запроса равно верхнему span-у, который включает в себя время всех span-ов, расположенных под ним.

### Задание со *

С нашим приложением происходит что-то странное.
Пользователи жалуются, что при нажатии на пост они вынуждены долго ждать, пока у них загрузится страница с постом. Жалоб на загрузку других страниц не поступало.
Выясним в чем проблема, используя Zipkin.

<https://github.com/Artemmkin/bugged-code>

- скачиваем код микросервисов
- правим docker_build.sh добавляя тег bugged при создании образов
- дополняем наш Makefile для более легкой сборки и развертывния
- развертывем наше приложение
- откроем главную страницу приложения и пробуем нажать на пост, видим задержку загрузки страницы с постом
- идем в Zipkin и смотрим на время каждого span
- по span сервиса post отвечающего за db_find_single_post видим время обработки более 3 секунд
- далее идем в /bugged-code/post-py/post_app.py и ищем, что связано с db_find_single_post
- ниже находим и правим проблему нашей задержки - time.sleep(3)
- пересобираем образ микросервиса post, деплоим и снова проверяем работу приложения

Проблема решена!

## Мониторинг приложения и инфраструктуры

Мой Docker Hub <https://hub.docker.com/u/kovtalex/>

### Мониторинг Docker контейнеров

Подготовка окружения

```console
export GOOGLE_PROJECT=docker-258208
docker-machine create --driver google \
    --google-machine-image https://www.googleapis.com/compute/v1/projects/ubuntu-os-cloud/global/images/family/ubuntu-1604-lts \
    --google-machine-type n1-standard-1 \
    --google-zone europe-west1-b \
    docker-host
eval $(docker-machine env docker-host)
```

Разделим файлы Docker Compose.
В данный момент и мониторинг и приложения у нас описаны в одном большом docker-compose.yml. С одной стороны это просто, а с другой - мы смешиваем различные сущности, и сам файл быстро растет.
Оставим описание приложений в docker-compose.yml, а мониторинг выделим в отдельный файл docker-composemonitoring.yml.
Для запуска приложений будем как и ранее использовать docker-compose up -d, а для мониторинга - docker-compose -f docker-compose-monitoring.yml up -d

Мы будем использовать cAdvisor для наблюдения за состоянием наших Docker контейнеров.
cAdvisor собирает информацию о ресурсах потребляемых контейнерами и характеристиках их работы.
Примерами метрик являются:

- процент использования контейнером CPU и памяти, выделенные для его запуска
- объем сетевого трафика
- и др.

cAdvisor также будем запускать в контейнере. Для этого добавим новый сервис в наш компоуз файл мониторинга docker-compose-monitoring.yml

```yml
...
  cadvisor:
    image: google/cadvisor:${CADVISOR_VER}
    volumes:
      - '/:/rootfs:ro'
      - '/var/run:/var/run:rw'
      - '/sys:/sys:ro'
      - '/var/lib/docker/:/var/lib/docker:ro'
    ports:
      - '8080:8080'
    networks:
      back_net:
```

Добавим информацию о новом сервисе в конфигурацию Prometheus, чтобы он начал собирать метрики:

```yml
...
  - job_name: 'cadvisor'
    static_configs:
      - targets:
        - 'cadvisor:8080'
```

Пересоберем образ Prometheus с обновленной конфигурацией:

```console
export USER_NAME=kovtalex
docker build -t $USER_NAME/prometheus .
```

Запустим сервисы:

```console
docker-compose up -d
docker-compose -f docker-compose-monitoring.yml up -d
```

cAdvisor имеет UI, в котором отображается собираемая о контейнерах информация
Откроем страницу Web UI по адресу <http://docker-machinehost-ip:8080>

По пути /metrics все собираемые метрики публикуются для сбора Prometheus

### Визуализация метрик

Используем инструмент Grafana для визуализации данных из Prometheus

docker-compose-monitoring.yml

```yml
...
  grafana:
    image: grafana/grafana:5.0.0
    volumes:
      - grafana_data:/var/lib/grafana
    environment:
      - GF_SECURITY_ADMIN_USER=admin
      - GF_SECURITY_ADMIN_PASSWORD=secret
    depends_on:
      - prometheus
    ports:
      - 3000:3000

volumes:
  grafana_data:
```

Запустим новый сервис:

$ docker-compose -f docker-compose-monitoring.yml up -d grafana

Откроем страницу Web UI Grafana по адресу <http://dockermachine-host-ip:3000> и используем для входа логин и пароль администратора, которые мы передали через переменные окружения

Добавим источник данных:

- Name: Prometheus Server
- Type: Prometheus
- URL: <http://prometheus:9090>
- Access: Proxy

Перейдем на Grafana <https://grafana.com/dashboards>, где можно найти и скачать большое количество уже созданных официальных и комьюнити дашбордов для визуализации различного типа метрик для разных систем мониторинга и баз данных.
Выберем в качестве источника данных нашу систему мониторинга (Prometheus) и выполним поиск по категории Docker.
Затем выберем популярный дашборд, к примеру Docker and system monitoring.
Загрузим JSON. В директории monitoring создадим директории grafana/dashboards куда поместим скачанный дашборд.
Поменяем название файла дашборда на DockerMonitoring.json
Затем импортируем данный шаблон в Grafana.
Появиться набор графиков с информацией о состоянии хостовой системы и работе контейнеров.

### Сбор метрик работы приложения и бизнес метрик

В качестве примера метрик приложения в сервис UI были добавлены:

- счетчик ui_request_count, который считает каждый приходящий HTTP-запрос
- гистограмму ui_request_latency_seconds, которая позволяет отслеживать информацию о времени обработки каждого запроса

В качестве примера метрик приложения в сервис Post были добавлены:

- гистограмма post_read_db_seconds, которая позволяет отследить информацию о времени требуемом для поиска поста в БД

prometheus.yml

```yml
...
  - job_name: 'post'
    static_configs:
      - targets:
        - 'post:5000'
```

Пересоздадим нашу Docker инфраструктуру мониторинга:

```console
docker build -t $USER_NAME/prometheus .
docker-compose -f docker-compose-monitoring.yml down
docker-compose -f docker-compose-monitoring.yml up -d
```

### Построим графики собираемых метрик приложения

Для поиска всех http запросов, у которых код возврата начинается либо с 4 либо с 5 будем использовать функцию rate(), чтобы посмотреть не просто значение
счетчика за весь период наблюдения, но и скорость увеличения данной величины за промежуток времени равный 1 минуте:

- rate(ui_request_count{http_status=~"^[45].*"}[1m])

Используем функцию rate() для оценки роста количества запросов:

- rate(ui_request_count[5m])

Для вычисления 95 процентиля времени ответа на запрос создадим гистограмму:

- histogram_quantile(0.95, sum(rate(ui_request_response_time_bucket[5m])) by (le))

Экспортируем созданный дашборд UI_Service_Monitoring.json в monitoring/grafana/dashboards

### Сбор метрик бизнес логики

В качестве примера метрик бизнес логики мы в наше приложение мы добавили счетчики количества постов и комментариев post_count, comment_count.
Мы построим график скорости роста значения счетчика за последний час, используя функцию rate(). Это позволит нам получать информацию об активности пользователей приложения.

- cоздадим новый дашборд, назовите его Business_Logic_Monitoring и построим график функции rate(post_count[1h])
- построим еще один график для счетчика comment

Экспортируем созданный дашборд и сохраним его в директории monitoring/grafana/dashboards под названием Business_Logic_Monitoring.json

### Алертинг

Мы определим несколько правил, в которых зададим условия состояний наблюдаемых систем, при которых мы должны получать оповещения, т.к. заданные условия могут привести к недоступности или неправильной работе нашего приложения.
P.S. Стоит заметить, что в самой Grafana тоже есть alerting. Но по функционалу он уступает Alertmanager в Prometheus.

Alertmanager

Alertmanager - дополнительный компонент для системы мониторинга Prometheus, который отвечает за первичную обработку алертов и дальнейшую отправку оповещений по заданному назначению.

Создадим новую директорию monitoring/alertmanager. В этой директории создадим Dockerfile со следующим содержимым:

```dockerfile
FROM prom/alertmanager:v0.14.0
ADD config.yml /etc/alertmanager/
```

Настройки Alertmanager-а как и Prometheus задаются через YAML файл или опции командой строки.
В директории monitoring/alertmanager создадим файл config.yml в котором определим отправку нотификаций в свой тестовый слак канал.
Для отправки нотификаций в слак канал потребуется создать Incoming Webhook

```yml
global:
  slack_api_url: 'https://hooks.slack.com/services/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'

route:
  receiver: 'slack-notifications'

receivers:
- name: 'slack-notifications'
  slack_configs:
  - channel: '#alexey_kovtunovich'
```

Соберем образ alertmanager: docker build -t $USER_NAME/alertmanager .

Добавим новый сервис в компоуз файл мониторинга:

```yml
...
  alertmanager:
    image: ${USER_NAME}/alertmanager:${ALERTMANAGER_VER}
    command:
      - '--config.file=/etc/alertmanager/config.yml'
    ports:
      - 9093:9093
    networks:
      back_net:
```

Создадим файл alerts.yml в директории prometheus, в котором определим условия при которых должен срабатывать алерт и посылаться Alertmanager-у. Мы создадим простой алерт, который будет срабатывать в ситуации, когда одна из наблюдаемых систем (endpoint) недоступна для сбора метрик (в этом случае метрика up с лейблом instance равным имени данного эндпоинта будет равна нулю).

alerts.yml

```yml
groups:
  - name: alert.rules
    rules:
    - alert: InstanceDown
      expr: up == 0
      for: 1m
      labels:
        severity: page
      annotations:
        description: '{{ $labels.instance }} of job {{ $labels.job }} has been down for more than 1 minute'
        summary: 'Instance {{ $labels.instance }} down'
```

Добавим операцию копирования данного файла в Dockerfile: monitoring/prometheus/Dockerfile

```dockerfile
...
ADD alerts.yml /etc/prometheus/
```

Добавим информацию о правилах, в конфиг Prometheus:

```yml
rule_files:
  - "alerts.yml"

alerting:
  alertmanagers:
  - scheme: http
    static_configs:
    - targets:
      - "alertmanager:9093"
```

Пересоберем образ Prometheus: docker build -t $USER_NAME/prometheus .

Пересоздадим нашу Docker инфраструктуру мониторинга:

```console
docker-compose -f docker-compose-monitoring.yml down
docker-compose -f docker-compose-monitoring.yml up -d
```

Остановим один из сервисов и подождем одну минуту

```console
docker-compose stop post
```

В канал должно придти сообщение с информацией о статусе сервиса

У Alertmanager также есть свой веб интерфейс, доступный на порту 9093, который мы прописали в компоуз файле.
P.S. Проверить работу вебхуков слака можно через обычным curl.

Запушим собранные вами образы на DockerHub и удалим виртуалку

- Задание со *

#### Обновим наш Makefile добавив билд и публикацию сервисов из ДЗ

#### Включим отдачу метрик в формате Prometheus в Docker в экспериментальном режиме

Для этого создадим /etc/docker/daemon.json на машине с Docker со следующим содержимым и перезапустим сервис

```console
{
  "metrics-addr" : "0.0.0.0:9323",
  "experimental" : true
}
```

Метрики Docker можно будет посмотреть по адресу <http://dockermachine-host-ip:9323/metrics>

Обновим наш prometheus.yml

```yml
...
  - job_name: 'docker'
    static_configs:
      - targets: ['docker-host:9323']
```

Пересоберем и запушим наш образ, пересоздадим инфраструктуру
Новые метрики можно будет наблюдать в GUI Prometheus

#### *** Реализация схемы с проксированием запросов от Grafana к Prometheus через Trickster кеширующий прокси

Для реализации воспользуемся <https://github.com/Comcast/trickster>

Trickster будет забирать данные с Prometheus и отдавать их в Grafana по своему порту 9090
Метрики Trickster будут доступны по порту 8082 их можно также мониторить в Prometheus

Создадим файл конфигурации trickster.conf и закинем его на машину с Docker в /tmp/

```console
[main]
[proxy_server]
  listen_port = 9090
[cache]
cache_type = 'memory'
compression = true
[origins]
    [origins.default]
    # Note: This points to your Prometheus installation, not Grafana!
    origin_url = 'http://prometheus:9090'
    api_path = '/api/v1'
    default_step = 300
    max_value_age_secs = 86400
[metrics]
listen_port = 8082
[logging]
log_level = 'info'
```

docker-compose-monitoring.yml

```yml
...
  trickster:
    image: tricksterio/trickster
    volumes:
      - /tmp/trickster.conf:/etc/trickster/trickster.conf
    networks:
      back_net:
```

prometheus.yml

```yml
...
  - job_name: 'trickster'
    static_configs:
      - targets:
        - 'trickster:8082'
```

Пересоберем и запушим наш образ Prometheus, пересоздадим инфраструктуру
В GUI Grafana изменим адрес источника данных на <http://trickster:9090>

## Введение в мониторинг. Системы мониторинга

Мой Docker Hub <https://hub.docker.com/u/kovtalex/>

### Prometheus: запуск, конфигурация, знакомство с Web UI

Создадим правило фаервола для Prometheus и Puma:

```console
gcloud compute firewall-rules create prometheus-default --allow tcp:9090
gcloud compute firewall-rules create puma-default --allow tcp:9292
```

Создадим Docker хост в GCE и настроим локальное окружение на работу с ним

```console
export GOOGLE_PROJECT=docker-258208

docker-machine create --driver google \
 --google-machine-image https://www.googleapis.com/compute/v1/projects/ubuntu-os-cloud/global/images/family/ubuntu-1604-lts \
 --google-machine-type n1-standard-1 \
 --google-zone europe-west1-b \
 docker-host

eval $(docker-machine env docker-host)
```

Воспользуемся готовым образом с DockerHub

```console
docker run --rm -p 9090:9090 -d --name prometheus prom/prometheus:v2.1.0
docker ps
docker-machine ip docker-host
```

Ознакомимся с работой Prometheus в Web UI

Пример метрики

```console
prometheus_build_info{branch="HEAD",goversion="go1.9.1",instance="localhost:9090", job="prometheus", revision="3a7c51ab70fc7615cd318204d3aa7c078b7c5b20",version="1.8.1"} 1
```

- название метрики - идентификатор собранной информации.
- лейбл - добавляет метаданных метрике, уточняет ее.
Использование лейблов дает нам возможность не ограничиваться лишь одним названием метрик для идентификации получаемой информации.
Лейблы содержаться в {} скобках и представлены наборами "ключ=значение".
- значение метрики - численное значение метрики, либо NaN, если значение недоступно.

Остановим контейнер и переупорядочим структуру директорий

docker stop prometheus

Создадим Docker образ и в директории monitoring/prometheus напишем простой конфигурационный файл для сбора метрик с наших микросервисов

prometheus.yml

```yml
---
global:
  scrape_interval: '5s'

scrape_configs:
  - job_name: 'prometheus'
    static_configs:
      - targets:
        - 'localhost:9090'

  - job_name: 'ui'
    static_configs:
      - targets:
        - 'ui:9292'

  - job_name: 'comment'
    static_configs:
      - targets:
        - 'comment:9292'
```

```console
export USER_NAME=kovtalex
docker build -t $USER_NAME/prometheus .
```

Выполним сборку образов при помощи скриптов docker_build.sh в директории каждого сервиса

/src/ui      $ bash docker_build.sh
/src/post-py $ bash docker_build.sh
/src/comment $ bash docker_build.sh

Или сразу все из корня репозитория

for i in ui post-py comment; do cd src/$i; bash docker_build.sh; cd -; done

Будем поднимать наш Prometheus совместно с микросервисами. Определите в нашем docker/docker-compose.yml файле новый сервис

docker-compose.yml

```yml
services:
...
  prometheus:
    image: ${USERNAME}/prometheus
    ports:
      - '9090:9090'
    volumes:
      - prometheus_data:/prometheus
    command:
      - '--config.file=/etc/prometheus/prometheus.yml'
      - '--storage.tsdb.path=/prometheus'
      - '--storage.tsdb.retention=1d'

volumes:
  prometheus_data:
```

Поднимем сервисы, определенные в docker/docker-compose.yml

docker-compose up -d

### Мониторинг состояния микросервисов

Посмотрим список endpoint-ов, с которых собирает информацию Prometheus.
Endpoint-ы должны быть в состоянии UP.

Healthcheck-и представляют собой проверки того, что наш сервис здоров и работает в ожидаемом режиме. В нашем случае healthcheck выполняется внутри кода микросервиса и выполняет проверку того, что все сервисы, от которых зависит его работа, ему доступны. Если требуемые для его работы сервисы здоровы, то healthcheck проверка возвращает status = 1, что соответсвует тому, что сам сервис здоров. Если один из нужных ему сервисов нездоров или недоступен, то проверка вернет status = 0.

В веб интерфейсе Prometheus выполним поиск по названию метрики ui_health, проверим ее значение и построим график.

Попробуем остановить сервис post на некоторое время и проверим, как изменится статус ui сервиса, который зависим от post

docker-compose stop post

Метрика изменила свое значение на 0, что означает, что UI сервис стал нездоров

Далее вернем в строй наш сервис post

docker-compose start post

### Сбор метрик хоста с использованием экспортера

Экспортер похож на вспомогательного агента для сбора метрик.
В ситуациях, когда мы не можем реализовать отдачу метрик Prometheus в коде приложения, мы можем использовать экспортер, который будет транслироватьметрики приложения или системы в формате доступном для чтения Prometheus.

Exporters

- Программа, которая делает метрики доступными для сбора Prometheus
- Дает возможность конвертировать метрики в нужный для Prometheus формат
- Используется когда нельзя поменять код приложения
- Примеры: PostgreSQL, RabbitMQ, Nginx, Node exporter, cAdvisor

Воспользуемся Node экспортер для сбора информации о работе Docker хоста (виртуалки, где у нас запущены контейнеры) и предоставлению этой информации в Prometheus

Дополним наш docker-compose.yml

```yml
services:

  node-exporter:
    image: prom/node-exporter:v0.15.2
    user: root
    volumes:
      - /proc:/host/proc:ro
      - /sys:/host/sys:ro
      - /:/rootfs:ro
    command:
      - '--path.procfs=/host/proc'
      - '--path.sysfs=/host/sys'
      - '--collector.filesystem.ignored-mount-points="^/(sys|proc|dev|host|etc)($$|/)"'
```

и prometheus.yml

```yml
scrape_configs:
...
 - job_name: 'node'
 static_configs:
 - targets:
 - 'node-exporter:9100'
```

Не забудем собрать новый Docker для Prometheus

```console
docker build -t $USER_NAME/prometheus
docker-compose down
docker-compose up -d
```

В списке endpoint-ов Prometheus - должен появится еще один endpoint

- Зайдем на хост: docker-machine ssh docker-host
- Добавим нагрузки: yes > /dev/null

Проверим по метрике node_load1 как выросла нагрузка CPU

Запушим собранные нами образы на DockerHub

```console
docker login
docker push $USER_NAME/ui
docker push $USER_NAME/comment
docker push $USER_NAME/post
docker push $USER_NAME/prometheus
```

- Задание со *

#### Добавляем мониторинг MongoDB с использованием необходимого экспортера

Для реализации выберем Percona MongoDB Exporter - форкнут из dcu/mongodb_exporter, но при этом свежей версии и обновляемый
<https://github.com/percona/mongodb_exporter>

Билдим образ по документации и пушим его в наш репозитарий:

```console
sudo docker tag blackbox_exporter kovtalex/mongodb_exporter:0.10.0
sudo docker push kovtalex/mongodb_exporter:0.10.0
```

Также правим наш prometheus.yml

```yml
  - job_name: 'mongodb-exporter'
    static_configs:
      - targets:
        - 'mongodb-exporter:9216'
```

И docker-compose.yml

```yml
  mongodb-exporter:
    image: kovtalex/mongodb_exporter:${MONGODB_EXPORTER_VER}
    command:
      '--mongodb.uri=mongodb://mongo_db:27017'
    networks:
      back_net:
```

Проверяем метрики связанные с mongodb в нашем Prometheus

#### Добавляем в Prometheus мониторинг сервисов comment, post, ui с помощью blackbox экспортера

Выберем Cloudprober от Google <https://github.com/google/cloudprober>

Будем мониторить по HTTP:

- ui ожидая ответа 200-299 по порту 9292
- comment по порту 9292
- post по порту 5000

Напишем наш cloudprober.cfg и закинем его в /tmp на docker-host, т.к. docker-compose будем искать его именно там для передачи в контейнер

```yml
probe {
    name: "ui-http"
    type: HTTP
    targets {
        host_names: "ui"
    }
    interval_msec: 5000
    timeout_msec: 1000
    http_probe {
        port: 9292
    }
    validator {
        name: "status_code_2xx"
        http_validator {
            success_status_codes: "200-299"
        }
    }
}
probe {
    name: "comment-http"
    type: HTTP
    targets {
        host_names: "comment"
    }
    interval_msec: 5000
    timeout_msec: 1000
    http_probe {
        port: 9292
    }
}
probe {
    name: "post-http"
    type: HTTP
    targets {
        host_names: "post"
    }
    interval_msec: 5000
    timeout_msec: 1000
    http_probe {
        port: 5000
    }
}
```

Также правим наш prometheus.yml

```yml
  - job_name: 'cloudprobe-exporter'
    static_configs:
      - targets:
        - 'cloudprobe-exporter:9313'
```

И docker-compose.yml

```yml
  cloudprobe-exporter:
    image: cloudprober/cloudprober:${CLOUDPROBER_VER}
    volumes:
      - /tmp/cloudprober.cfg:/etc/cloudprober.cfg
    networks:
      front_net:
```

В результате в нашем Prometheus будут доступны метрики: (total, succes, latency) для наших микросервисов, (validation_failure) для ui и другие

#### Напишем Makefile, который в минимальном варианте умеет

- собирать все образы, которые сейчас используются
- пушить их в докер хаб

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

```console
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

```console
sudo  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository "deb https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
sudo apt-get update
sudo apt-get install docker-ce docker-compose -y
sudo mkdir -p /srv/gitlab/config /srv/gitlab/data /srv/gitlab/logs
cd /srv/gitlab/
sudo touch docker-compose.yml
```

docker-compose.yml

```yml
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

```console
git checkout -b gitlab-ci-1
git remote add gitlab http://34.76.25.244/homework/example.git
git push gitlab gitlab-ci-1
```

### Опишем для приложения этапы пайплайна

Теперь мы можем переходить к определению CI/CD Pipeline для проекта

.gitlab-ci.yml

```yml
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

```console
git add .gitlab-ci.yml
git commit -m 'add pipeline definition'
git push gitlab gitlab-ci-1
```

Теперь если перейти в раздел CI/CD мы увидим, что пайплайн готов к запуску.
Но находится в статусе pending / stuck так как у нас нет runner.
Запустим Runner и зарегистрируем его в интерактивном режиме.

На сервере, где работает Gitlab CI выполним команду:

```console
docker run -d --name gitlab-runner --restart always \
-v /srv/gitlab-runner/config:/etc/gitlab-runner \
-v /var/run/docker.sock:/var/run/docker.sock \
gitlab/gitlab-runner:latest
```

После запуска Runner нужно зарегистрировать, это можно сделать командой:

```console
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

```console
git clone https://github.com/express42/reddit.git && rm -rf ./reddit/.git
git add reddit/
git commit -m “Add reddit app”
git push gitlab gitlab-ci-1
```

Изменим описание пайплайна в .gitlab-ci.yml

```yml
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

```rb
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

```console
git commit -a -m ‘#4 add logout button to profile page’
git tag 2.4.10
git push gitlab gitlab-ci-1 --tags
```

Динамические окружения

Gitlab CI позволяет определить динамические окружения, это мощная функциональность позволяет вам иметь выделенный стенд для, например, каждой feature-ветки в git

Этот job определяет динамическое окружение для каждой ветки в репозитории, кроме ветки master

```yml
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

- Задание со *

#### В шаг build добавить сборку контейнера с приложением reddit

Воспользуемся одним из способов сборки, позволящим собирать образы в контейнере и при этом обойтись без Docker: <https://docs.gitlab.com/ee/ci/docker/using_kaniko.html>

В Gitlab определим переменные для сохранения собранного образа в docker hub

- CI_REGISTRY - <https://index.docker.io/v1/>
- CI_REGISTRY_BASE64 - вывод команды "echo -n USER:PASSWORD | base64" с данными авторизации к нашему docker hub
- CI_REGISTRY_IMAGE - kovtalex/reddit

Модифицируем наш .gitlab-ci.yml

```yml
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

```yml
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

```console
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

## Docker: сети, docker-compose

### Работа с сетями в Docker

Подключаемся к ранее созданному docker host’у

```console
docker-machine ls
eval $(docker-machine env docker-host)
```

#### None network driver

```console
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

```console
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

```console
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

```console
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

```console
eb4bdda43b65
default
```

ip netns exec namespace command - позволит выполнять команды в выбранном namespace: sudo ip netns exec eb4bdda43b65 ifconfig

#### Bridge network driver

Создадим bridge-сеть в docker (флаг --driver указывать не обязательно, т.к. по-умолчанию используется bridge)

docker network create reddit --driver bridge

Запустим наш проект reddit с использованием bridge-сети

```console
docker run -d --network=reddit mongo:latest
docker run -d --network=reddit kovtalex/post:3.0
docker run -d --network=reddit kovtalex/comment:3.0
docker run -d --network=reddit -p 9292:9292 kovtalex/ui:3.0
```

Сервис не заработает. Тогда решением проблемы будет присвоение контейнерам имен или сетевых алиасов при старте:

```console
--name <name> (можно задать только 1 имя)
--network-alias <alias-name> (можно задать множество алиасов)
```

```console
docker kill $(docker ps -q)
docker run -d --network=reddit --network-alias=post_db --network-alias=comment_db mongo:latest
docker run -d --network=reddit --network-alias=post kovtalex/post:3.0
docker run -d --network=reddit --network-alias=comment kovtalex/comment:3.0
docker run -d --network=reddit -p 9292:9292 kovtalex/ui:3.0
```

Теперь сервис работает!

Далее запустим наш проект в 2-х bridge сетях. Так , чтобы сервис ui не имел доступа к базе данных

```console
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

```console
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

```console
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

```yml
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

- Задание со *

Создадим docker-compose.override.yml для reddit проекта, который позволит

- изменять код каждого из приложений, не выполняя сборку образа задействовав volumes
- добавим команды перезаписи для выполнения puma с флагами --debug -w 2

```console
docker ps
CONTAINER ID        IMAGE                  COMMAND                  CREATED             STATUS              PORTS                    NAMES
54ad7a2726d8        mongo:3.2              "docker-entrypoint.s…"   5 minutes ago       Up 5 minutes        27017/tcp                reddit_mongo_db_1
d5dd525a5e91        kovtalex/comment:3.0   "puma --debug -w 2"      5 minutes ago       Up 5 minutes                                 reddit_comment_1
cf7cb9809d85        kovtalex/post:3.0      "python3 post_app.py"    5 minutes ago       Up 5 minutes                                 reddit_post_1
f58fa18fb28e        kovtalex/ui:3.0        "puma --debug -w 2"      5 minutes ago       Up 5 minutes        0.0.0.0:9292->9292/tcp   reddit_ui_1
```

docker-compose.override.yml

```yml
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

## Docker-образы. Микросервисы

Для выполнения ДЗ и проверки Dockerfile воспользуемся линтером: <https://github.com/hadolint/hadolint>

Также для оптимизации инструкций Dockerfile воспользуемся практиками из: <https://docs.docker.com/engine/userguide/eng-image/dockerfile_best-practices/#sort-multi-line-arguments>

```console
docker pull hadolint/hadolint

docker run --rm -i hadolint/hadolint < ./ui/Dockerfile
docker run --rm -i hadolint/hadolint < ./comment/Dockerfile  
docker run --rm -i hadolint/hadolint < ./post-py/Dockerfile
```

### Опишем и соберем Docker-образы для сервисного приложения

Подключимся к ранее созданному Docker хосту

```console
docker-machine ls
eval $(docker-machine env docker-host)
```

Для удаления

```console
docker-machine rm <имя>
```

Для переключения на локальный docker

```console
eval $(docker-machine env --unset)
```

Скачаем, распакуем и переименуем в src наше приложение: <https://github.com/express42/reddit/archive/microservices.zip>

Теперь наше приложение состоит из трех компонентов:

- post-py - сервис отвечающий за написание постов
- comment - сервис отвечающий за написание комментариев
- ui - веб-интерфейс, работающий с другими сервисами

Для работы нашего приложения также требуется база данных MongoDB

./post-py/Dockerfile

```dockerfile
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

```dockerfile
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

```dockerfile
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

```console
docker build -t kovtalex/post:1.0 ./post-py
docker build -t kovtalex/comment:1.0 ./comment
docker build -t kovtalex/ui:1.0 ./ui
```

Создадим специальную сеть для приложения и запустим наши контейнеры:

```console
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

```console
docker run -d --network=reddit --network-alias=reddit_post_db --network-alias=reddit_comment_db mongo:latest
docker run -d --network=reddit --network-alias=reddit_post -e POST_DATABASE_HOST=reddit_post_db kovtalex/post:1.0
docker run -d --network=reddit --network-alias=reddit_comment -e COMMENT_DATABASE_HOST=reddit_comment_db kovtalex/comment:1.0
docker run -d --network=reddit -p 9292:9292 -e POST_SERVICE_HOST=reddit_post -e COMMENT_SERVICE_HOST=reddit_comment kovtalex/ui:1.0
```

- Проверяем работоспособность сервиса

Так как наши образы занимают немало места, начнем их улучшение с ./ui/Dockerfile

```dockerfile
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

```console
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

```dockerfile
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

```dockerfile
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

```dockerfile
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

```console
docker build -t kovtalex/post:3.0 ./post-py
docker build -t kovtalex/comment:3.0 ./comment
docker build -t kovtalex/ui:3.0 ./ui
```

Выключим старые копии контейнеров: docker kill $(docker ps -q)

Запустим новые копии контейнеров и проверим работу приложения:

```console
docker run -d --network=reddit --network-alias=post_db --network-alias=comment_db mongo:latest
docker run -d --network=reddit --network-alias=post kovtalex/post:3.0
docker run -d --network=reddit --network-alias=comment kovtalex/comment:3.0
docker run -d --network=reddit -p 9292:9292 kovtalex/ui:3.0
```

Так как наши данные пропадают при каждой остановке контейнера mongo воспользуемся Docker Volume: docker volume create reddit_db

Выключим старые копии контейнеров: docker kill $(docker ps -q)

Запустим новые копии контейнеров и mongo с подключенным Docker Volume:

```console
docker run -d --network=reddit --network-alias=post_db --network-alias=comment_db -v reddit_db:/data/db mongo:latest
docker run -d --network=reddit --network-alias=post kovtalex/post:3.0
docker run -d --network=reddit --network-alias=comment kovtalex/comment:3.0
docker run -d --network=reddit -p 9292:9292 kovtalex/ui:3.0
```

- Зайдем на <http://IP:9292/> и проверим работу приложения
- Напишем пост
- Перезапустим контейнеры снова
- Проверим, что пост остался на месте

Также проверим, что после оптимизаци наши образы стали занимать меньше места: docker images

```console
REPOSITORY          TAG                 IMAGE ID            CREATED             SIZE
kovtalex/ui         3.0                 b3594948cd1a        About an hour ago   297MB
kovtalex/ui         2.0                 696f9010f0b4        About an hour ago   411MB
kovtalex/ui         1.0                 ee289401bd4c        About an hour ago   783MB
kovtalex/post       3.0                 ee39d83673df        About an hour ago   109MB
kovtalex/post       1.0                 5cfd7419f2f5        About an hour ago   109MB
kovtalex/comment    3.0                 84bbc760cf18        About an hour ago   295MB
kovtalex/comment    1.0                 013c2292f299        About an hour ago   770MB
```

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

```console
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

```console
docker kill $(docker ps -q)
```

- docker stop - stop посылает SIGTERM (безусловное завершение процесса) и через 10 секунд(настраивается) посылает SIGKILL
- docker system df - отображает сколько дискового пространства занято образами, контейнерами и volume’ами. Отображает сколько из них не используется и возможно удалить
- docker rm - удаляет контейнер, можно добавить флаг -f, чтобы удалялся работающий container(будет послан sigkill)
- docker rmi  - удаляет image, если от него не зависят запущенные контейнеры
- docker inspect - получение метаданных о контейнере или образе

Создаем и запускаем контейнер из образа:

```console
sudo docker run -it ubuntu:16.04 /bin/bash
echo 'Hello world!' > /tmp/file
exit
```

Вывод списка всех контейнеров

```console
sudo docker ps -a
CONTAINER ID        IMAGE               COMMAND             CREATED             STATUS                     PORTS               NAMES
5762a59a8283        ubuntu:16.04        "/bin/bash"         13 seconds ago      Exited (0) 3 seconds ago                       stupefied_fermi
```

Создание образа из контейнера

```console
sudo  docker commit 5762a59a8283 kovtalex/ubuntu-tmp-file
sha256:68b5ebc9d2dedfc49276fa5e5c28015f4891693346579b98572b6dd06287a07f
```

Вывод списка образов

```console
sudo docker images
REPOSITORY                 TAG                 IMAGE ID            CREATED             SIZE
kovtalex/ubuntu-tmp-file   latest              68b5ebc9d2de        14 seconds ago      123MB
```

### Docker контейнеры в GCE

- Создаем новый проект <https://console.cloud.google.com/compute> и называем его docker
- Выполняем gcloud init и выбираем наш новый проект
- Далее gcloud auth application-default login
- Устанавливаем Docker machine <https://docs.docker.com/machine/install-machine/>

```console
- docker-machine - встроенный в докер инструмент для создания хостов и установки на них docker engine. Имеет поддержку облаков и систем виртуализации (Virtualbox, GCP и др.)
- Команда создания - docker-machine create <имя>. Имен может быть много, переключение между ними через eval $(docker-machine env <имя>). Переключение на локальный докер
- eval $(docker-machine env --unset). Удаление - docker-machine rm <имя>.
- docker-machine создает хост для докер демона со указываемым образом в --googlemachine-image, в ДЗ используется ubuntu-16.04. Образы которые используются для построения докер контейнеров к этому никак не относятся.
- Все докер команды, которые запускаются в той же консоли после eval $(docker-machine env <имя>) работают с удаленным докер демоном в GCP.
```

- выполняем  export GOOGLE_PROJECT=docker-258208
- выполняем

```console
 docker-machine create --driver google \
 --google-machine-image https://www.googleapis.com/compute/v1/projects/ubuntu-os-cloud/global/images/family/ubuntu-1604-lts \
 --google-machine-type n1-standard-1 \
 --google-zone europe-west1-b \
 docker-host
```

- docker-machine ls - проверяем, что наш Docker-хост успешно создан

```console
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

```yml
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

```console
#!/bin/bash

/usr/bin/mongod --fork --logpath /var/log/mongod.log --config /etc/mongodb.conf

source /reddit/db_config

cd /reddit && puma || exit
```

db_config

```console
DATABASE_URL=127.0.0.1
```

Dockerfile

```dockerfile
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

```console
 docker build -t reddit:latest .

- Точка в конце обязательна, она указывает на путь до Docker-контекста
- Флаг -t задает тег для собранного образа
```

Посмотрим на все образы (в том числе промежуточные)

```console
docker images -a
REPOSITORY             TAG                 IMAGE ID            CREATED             SIZE
kovtalex/otus-reddit   1.0                 b9dc7f4c5c8d        33 hours ago        691MB
```

Запускаем наш контейнер

```console
docker run --name reddit -d --network=host reddit:latest

9bfcfa27173e268fa2f0b2bc7131d76269dd31b6cf8b5c3e2c099d985ad9d949
```

Проверим результат

```console
docker-machine ls

NAME          ACTIVE   DRIVER   STATE     URL                        SWARM   DOCKER     ERRORS
docker-host   *        google   Running   tcp://35.233.48.104:2376           v19.03.4
```

Разрешим входящий TCP-трафик на порт 9292 выполнив команду

```console
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

```console
docker tag reddit:latest kovtalex/otus-reddit:1.0
docker push kovtalex/otus-reddit:1.0
```

Т.к. теперь наш образ есть в докер хабе, то мы можем запустить его не только в докер хосте в GCP, но и в нашем локальном докере или на другом хосте.

Выполним в другой консоли

```console
docker run --name reddit -d -p 9292:9292 kovtalex/otus-reddit:1.0
```

И проверим, что в локальный докер скачался загруженный ранее образ и приложение работает

- Задание со *

Для выполнения задания со * в виде прототипа в директории /docker-monolith/infra/ было релизовано:

- поднятие инстансов с помощью Terraform (количество инстансов задается переменной node_count в variables.json)

```console
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

```console
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

```console
packer
├── docker.json
└── variables.json

packer build -var-file=packer/variables.json packer/docker.json
```
