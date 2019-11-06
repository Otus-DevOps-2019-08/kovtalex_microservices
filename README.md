# kovtalex_microservices

## Технология контейнеризации. Введение в Docker

(venv) ➜  kovtalex_microservices git:(docker-2) sudo docker run -it ubuntu:16.04 /bin/bash
root@5762a59a8283:/# 
root@5762a59a8283:/# 
root@5762a59a8283:/#  echo 'Hello world!' > /tmp/file
root@5762a59a8283:/# exit
exit
(venv) ➜  kovtalex_microservices git:(docker-2) sudo docker ps -a                         
CONTAINER ID        IMAGE               COMMAND             CREATED             STATUS                     PORTS               NAMES
5762a59a8283        ubuntu:16.04        "/bin/bash"         13 seconds ago      Exited (0) 3 seconds ago                       stupefied_fermi
(venv) ➜  kovtalex_microservices git:(docker-2) sudo  docker commit 5762a59a8283 kovtalex/ubuntu-tmp-file
sha256:68b5ebc9d2dedfc49276fa5e5c28015f4891693346579b98572b6dd06287a07f
(venv) ➜  kovtalex_microservices git:(docker-2) docker images
Got permission denied while trying to connect to the Docker daemon socket at unix:///var/run/docker.sock: Get http://%2Fvar%2Frun%2Fdocker.sock/v1.40/images/json: dial unix /var/run/docker.sock: connect: permission denied
(venv) ➜  kovtalex_microservices git:(docker-2) sudo docker images
REPOSITORY                 TAG                 IMAGE ID            CREATED             SIZE
kovtalex/ubuntu-tmp-file   latest              68b5ebc9d2de        14 seconds ago      123MB
ubuntu                     16.04               5f2bf26e3524        5 days ago          123MB
nginx                      latest              540a289bab6c        2 weeks ago         126MB
hello-world                latest              fce289e99eb9        10 months ago       1.84kB