USERNAME=kovtalex

# Деплоим наше приложение с мониторингом
deploy_app:
	cd docker && docker-compose up -d && docker-compose -f docker-compose-monitoring.yml up -d

# Останавливаем работу приложения
stop_app:
	cd docker && docker-compose down && docker-compose -f docker-compose-monitoring.yml down

# Билдим всё
build_all: build_comment build_post build_comment build_prometheus build_alertmanager

build_comment:
	export USER_NAME=$(USERNAME) && cd src/comment && bash docker_build.sh
build_post:
	export USER_NAME=$(USERNAME) && cd src/post-py && bash docker_build.sh
build_ui:
	export USER_NAME=$(USERNAME) && src/ui && bash docker_build.sh
build_prometheus:
	cd monitoring/prometheus && docker build -t $(USERNAME)/prometheus .
build_alertmanager:
	cd monitoring/alertmanager && docker push $USER_NAME/alertmanager .

# Пушим всё
push_all: push_comment push_post push_ui push_prometheus push_alertmanager

push_comment:
	docker push $(USERNAME)/comment:latest
push_post:
	docker push $(USERNAME)/post:latest
push_ui:
	docker push $(USERNAME)/ui:latest
push_prometheus:
	docker push $(USERNAME)/prometheus:latest
push_alertmanager:
	docker push $(USERNAME)/alertmanager:latest