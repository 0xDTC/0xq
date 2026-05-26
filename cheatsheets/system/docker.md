# Docker

> Container platform for building, running, and managing isolated application environments

<!-- tags: docker, container, image, compose, devops -->

---

## run container interactive shell
Run a container with interactive terminal and auto-remove on exit.

```bash
docker run -it --rm --name {{NAME:str:mybox}} {{IMAGE:str:ubuntu:latest}} /bin/bash
```

<!-- meta: risk=low | phase=misc | tags=run,interactive,shell -->

---

## run container port volume mount
Run a container with port mapping and volume mount.

```bash
docker run -d --name {{NAME:str:webapp}} -p {{HPORT:port:8080}}:{{CPORT:port:80}} -v {{HOSTPATH:dir:./data}}:{{CONTPATH:str:/app/data}} {{IMAGE:str:nginx:latest}}
```

<!-- meta: risk=low | phase=misc | tags=run,port,volume,mount -->

---

## exec shell running container
Open a shell in an already-running container.

```bash
docker exec -it {{CONTAINER:str:webapp}} /bin/bash
```

<!-- meta: risk=low | phase=misc | tags=exec,shell,attach -->

---

## build image dockerfile
Build a Docker image from a Dockerfile.

```bash
docker build -t {{TAG:str:myimage:latest}} {{PATH:dir:.}}
```

<!-- meta: risk=low | phase=misc | tags=build,image,dockerfile -->

---

## list containers and images
Show running containers and available images.

```bash
docker ps -a && docker images
```

<!-- meta: risk=safe | phase=misc | tags=ps,list,images,containers -->

---

## view container logs
Stream logs from a running container.

```bash
docker logs -f --tail {{LINES:int:100}} {{CONTAINER:str:webapp}}
```

<!-- meta: risk=safe | phase=misc | tags=logs,follow,debug -->

---

## stop and remove container
Stop a running container and remove it.

```bash
docker stop {{CONTAINER:str:webapp}} && docker rm {{CONTAINER:str:webapp}}
```

<!-- meta: risk=med | phase=misc | tags=stop,remove,cleanup -->

---

## compose up services
Start all services defined in a compose file.

```bash
docker compose -f {{FILE:file:docker-compose.yml}} up -d
```

<!-- meta: risk=low | phase=misc | tags=compose,up,services -->

---

## compose down volumes
Stop and remove all containers, networks, and volumes from compose.

```bash
docker compose -f {{FILE:file:docker-compose.yml}} down --volumes
```

<!-- meta: risk=med | phase=misc | tags=compose,down,cleanup -->

---

## prune system disk cleanup
Remove all stopped containers, unused networks, dangling images, and build cache.

```bash
docker system prune -af --volumes
```

<!-- meta: risk=high | phase=misc | tags=prune,cleanup,disk -->

---

## list inspect networks
List, create, and inspect Docker networks.

```bash
docker network ls && docker network inspect {{NETWORK:str:bridge}}
```

<!-- meta: risk=safe | phase=misc | tags=network,inspect,list -->
