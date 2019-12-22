USERNAME=kovtalex

# Деплоим всё
deploy: deploy_app deploy_mon

# Деплоим приложение
deploy_app:
	cd docker && docker-compose up -d

# Деплоим мониторинг
deploy_mon:
	cd docker && docker-compose -f docker-compose-monitoring.yml up -d

# Останавливаем всё
stop: stop_app stop_mon

# Останавливаем приложение
stop_app:
	cd docker && docker-compose down

# Останавливаем мониторинг
stop_mon:
	cd docker && docker-compose -f docker-compose-monitoring.yml down

# Билдим всё
build: build_app build_mon

# Билдим приложение
build_app: build_comment build_post build_comment

# Билдим мониторинг
build_mon: build_prometheus build_alertmanager

build_comment:
	export USER_NAME=$(USERNAME) && cd src/comment && bash docker_build.sh
build_post:
	export USER_NAME=$(USERNAME) && cd src/post-py && bash docker_build.sh
build_ui:
	export USER_NAME=$(USERNAME) && src/ui && bash docker_build.sh
build_prometheus:
	cd monitoring/prometheus && docker build -t $(USERNAME)/prometheus .
build_alertmanager:
	cd monitoring/alertmanager && docker build -t $(USER_NAME)/alertmanager .

# Пушим всё
push: push_app push_mon

# Пушим приложение
push_app: push_comment push_post push_ui

# Пушим мониторинг
push_mon: push_prometheus push_alertmanager

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
