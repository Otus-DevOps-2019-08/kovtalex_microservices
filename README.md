# kovtalex_microservices

[![Build Status](https://travis-ci.com/Otus-DevOps-2019-08/kovtalex_microservices.svg?branch=master)](https://travis-ci.com/Otus-DevOps-2019-08/kovtalex_microservices)

## Введение в Kubernetes

### Создание примитивов

### Kubernetes The Hard Way

Погнали...

## Логирование и распределенная трассировка

### Подготовка

- обновим код микросервисов, в который был добавлен функционала логирования <https://github.com/express42/reddit/tree/logging> (git clone -b logging  --single-branch https://github.com/express42/reddit.git)
- выполним сборку образов при помощи скриптов docker_build.sh в директории каждого сервиса:
```
bash docker_build.sh && docker push $USER_NAME/ui
bash docker_build.sh && docker push $USER_NAME/post
bash docker_build.sh && docker push $USER_NAME/comment
```
- или сразу все из корня репозитория: for i in ui post-py comment; do cd src/$i; bash docker_build.sh; cd -; done
- или c помощью Makefile: make build_app
- создадим Docker хост в GCE и настроим локальное окружение на работу с ним, откроем порты файрволла:
```
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

```
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

```
FROM fluent/fluentd:v0.12
RUN fluent-gem install fluent-plugin-elasticsearch --no-rdoc --no-ri --version 1.9.5
RUN fluent-gem install fluent-plugin-grok-parser --no-rdoc --no-ri --version 1.0.0
ADD fluent.conf /fluentd/etc
```

В директории logging/fluentd создадим файл конфигурации logging/fluentd/fluent.conf

```
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

```
    logging:
      driver: "fluentd"
      options:
        fluentd-address: localhost:24224
        tag: service.post
```

Поднимем инфраструктуру централизованной системы логирования и перезапустим сервисы приложения из каталога docker или с помощью Makefile

```
docker-compose -f docker-compose-logging.yml up -d
docker-compose down
docker-compose up -d
```

У нас возникла проблема с запуском elasticsearch. Смотрим логи elasticsearch и видим две ошибки, которые нам предстоит исправить:

```
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

```
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

```
    logging:
      driver: "fluentd"
      options:
        fluentd-address: localhost:24224
        tag: service.ui
```

Перезапустим ui сервис из каталога docker:

```
docker-compose stop ui
docker-compose rm ui
docker-compose up -d
```

И посмотрим на формат собираемых сообщений

Когда приложение или сервис не пишет структурированные логи, приходится использовать старые добрые регулярные выражения для их парсинга в /docker fluentd/fluent.conf.
Следующее регулярное выражение нужно, чтобы успешно выделить интересующую нас информацию из лога UI-сервиса в поля:

```
<filter service.ui>
  @type parser
  format /\[(?<time>[^\]]*)\]  (?<level>\S+) (?<user>\S+)[\W]*service=(?<service>\S+)[\W]*event=(?<event>\S+)[\W]*(?:path=(?<path>\S+)[\W]*)?request_id=(?<request_id>\S+)[\W]*(?:remote_addr=(?<remote_addr>\S+)[\W]*)?(?:method= (?<method>\S+)[\W]*)?(?:response_status=(?<response_status>\S+)[\W]*)?(?:message='(?<message>[^\']*)[\W]*)?/
  key_name log
</filter>
```

Обновим образ fluentd и перезапустим kibana

```
docker build -t $USER_NAME/fluentd .
docker-compose -f docker-compose-logging.yml down
docker-compose -f docker-compose-logging.yml up -d
```

Проверим результат

Созданные регулярки могут иметь ошибки, их сложно менять и невозможно читать. Для облегчения задачи парсинга вместо стандартных регулярок можно использовать grok-шаблоны. По-сути grok’и - это именованные шаблоны регулярных выражеий (очень похоже на функции). Можно использовать готовый regexp, просто сославшись на него как на функцию docker/fluentd/fluent.conf

```
<filter service.ui>
  @type parser
  key_name log
  format grok
  grok_pattern %{RUBY_LOGGER}
</filter>
```

Это grok-шаблон, зашитый в плагин для fluentd
Как мы можем заметить часть логов все еще нужно распарсить. Для этого используем несколько Grok-ов по-очереди:

```
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

```
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

```
services:
  zipkin:
    image: openzipkin/zipkin
    ports:
      - "9411:9411"
```

Правим наш docker/docker-compose-logging.yml
Добавим для каждого сервиса поддержку ENV переменных и зададим параметризованный параметр ZIPKIN_ENABLED

```
environment:
- ZIPKIN_ENABLED=${ZIPKIN_ENABLED}
```

В .env файле укажем: ZIPKIN_ENABLED=true

Пересоздадим наши сервисы:

```
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

```
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

```
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

```
...
  - job_name: 'cadvisor'
    static_configs:
      - targets:
        - 'cadvisor:8080'
```

Пересоберем образ Prometheus с обновленной конфигурацией:

```
export USER_NAME=kovtalex
docker build -t $USER_NAME/prometheus .
```

Запустим сервисы:

```
docker-compose up -d
docker-compose -f docker-compose-monitoring.yml up -d
```

cAdvisor имеет UI, в котором отображается собираемая о контейнерах информация
Откроем страницу Web UI по адресу http://<docker-machinehost-ip>:8080

По пути /metrics все собираемые метрики публикуются для сбора Prometheus

### Визуализация метрик

Используем инструмент Grafana для визуализации данных из Prometheus

docker-compose-monitoring.yml

```
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

Откроем страницу Web UI Grafana по адресу http://<dockermachine-host-ip>:3000 и используем для входа логин и пароль администратора, которые мы передали через переменные окружения

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

```
...
  - job_name: 'post'
    static_configs:
      - targets:
        - 'post:5000'
```

Пересоздадим нашу Docker инфраструктуру мониторинга:

```
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

```
FROM prom/alertmanager:v0.14.0
ADD config.yml /etc/alertmanager/
```

Настройки Alertmanager-а как и Prometheus задаются через YAML файл или опции командой строки.
В директории monitoring/alertmanager создадим файл config.yml в котором определим отправку нотификаций в свой тестовый слак канал.
Для отправки нотификаций в слак канал потребуется создать Incoming Webhook

```
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

```
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

```
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

```
...
ADD alerts.yml /etc/prometheus/
```

Добавим информацию о правилах, в конфиг Prometheus:

```
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

```
docker-compose -f docker-compose-monitoring.yml down
docker-compose -f docker-compose-monitoring.yml up -d
```

Остановим один из сервисов и подождем одну минуту

```
docker-compose stop post
```

В канал должно придти сообщение с информацией о статусе сервиса

У Alertmanager также есть свой веб интерфейс, доступный на порту 9093, который мы прописали в компоуз файле.
P.S. Проверить работу вебхуков слака можно через обычным curl.

Запушим собранные вами образы на DockerHub и удалим виртуалку

### Задание со *

#### Обновим наш Makefile добавив билд и публикацию сервисов из ДЗ

#### Включим отдачу метрик в формате Prometheus в Docker в экспериментальном режиме

Для этого создадим /etc/docker/daemon.json на машине с Docker со следующим содержимым и перезапустим сервис

```
{
  "metrics-addr" : "0.0.0.0:9323",
  "experimental" : true
}
```

Метрики Docker можно будет посмотреть по адресу http://<dockermachine-host-ip>:9323/metrics

Обновим наш prometheus.yml

```
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

```
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

```
...
  trickster:
    image: tricksterio/trickster
    volumes:
      - /tmp/trickster.conf:/etc/trickster/trickster.conf
    networks:
      back_net:
```

prometheus.yml

```
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

```
gcloud compute firewall-rules create prometheus-default --allow tcp:9090
gcloud compute firewall-rules create puma-default --allow tcp:9292
```

Создадим Docker хост в GCE и настроим локальное окружение на работу с ним

```
export GOOGLE_PROJECT=docker-258208

docker-machine create --driver google \
 --google-machine-image https://www.googleapis.com/compute/v1/projects/ubuntu-os-cloud/global/images/family/ubuntu-1604-lts \
 --google-machine-type n1-standard-1 \
 --google-zone europe-west1-b \
 docker-host

eval $(docker-machine env docker-host)
```

Воспользуемся готовым образом с DockerHub

```
docker run --rm -p 9090:9090 -d --name prometheus prom/prometheus:v2.1.0
docker ps
docker-machine ip docker-host
```

Ознакомимся с работой Prometheus в Web UI

Пример метрики

```
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

```
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

```
export USER_NAME=kovtalex
docker build -t $USER_NAME/prometheus .
```

Выполним сборку образов при помощи скриптов docker_build.sh в директории каждого сервиса

/src/ui      $ bash docker_build.sh
/src/post-py $ bash docker_build.sh
/src/comment $ bash docker_build.sh

Или сразу все из корня репозитория

for i in ui post-py comment; do cd src/$i; bash docker_build.sh; cd -; done

Будем поднимать наш Prometheus совместно с микросервисами. Определите в вашем docker/docker-compose.yml файле новый сервис

docker-compose.yml

```
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

```
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

```
scrape_configs:
...
 - job_name: 'node'
 static_configs:
 - targets:
 - 'node-exporter:9100'
```

Не забудем собрать новый Docker для Prometheus

```
docker build -t $USER_NAME/prometheus
docker-compose down
docker-compose up -d
```

В списке endpoint-ов Prometheus - должен появится еще один endpoint

- Зайдем на хост: docker-machine ssh docker-host
- Добавим нагрузки: yes > /dev/null

Проверим по метрике node_load1 как выросла нагрузка CPU

Запушим собранные нами образы на DockerHub

```
docker login
docker push $USER_NAME/ui
docker push $USER_NAME/comment
docker push $USER_NAME/post
docker push $USER_NAME/prometheus
```

### Задание со *

#### Добавляем мониторинг MongoDB с использованием необходимого экспортера

Для реализации выберем Percona MongoDB Exporter - форкнут из dcu/mongodb_exporter, но при этом свежей версии и обновляемый
<https://github.com/percona/mongodb_exporter>

Билдим образ по документации и пушим его в наш репозитарий:

```
sudo docker tag blackbox_exporter kovtalex/mongodb_exporter:0.10.0
sudo docker push kovtalex/mongodb_exporter:0.10.0
```

Также правим наш prometheus.yml

```
  - job_name: 'mongodb-exporter'
    static_configs:
      - targets:
        - 'mongodb-exporter:9216'
```

И docker-compose.yml

```
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

```
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

```
  - job_name: 'cloudprobe-exporter'
    static_configs:
      - targets:
        - 'cloudprobe-exporter:9313'
```

И docker-compose.yml

```
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
docker push kovtalex/otus-reddit:1.0
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
