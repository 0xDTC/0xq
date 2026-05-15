# Docker

> Container platform for building, running, and managing isolated application environments

<!-- tags: docker, container, image, compose, devops -->

---

## Run Container Interactive
Run a container with interactive terminal and auto-remove on exit.

```bash
docker run -it --rm --name {{NAME:str:mybox}} {{IMAGE:str:ubuntu:latest}} /bin/bash
```

<!-- meta: risk=low | phase=misc | tags=run,interactive,shell -->

---

## Run with Port and Volume Mount
Run a container with port mapping and volume mount.

```bash
docker run -d --name {{NAME:str:webapp}} -p {{HPORT:port:8080}}:{{CPORT:port:80}} -v {{HOSTPATH:dir:./data}}:{{CONTPATH:str:/app/data}} {{IMAGE:str:nginx:latest}}
```

<!-- meta: risk=low | phase=misc | tags=run,port,volume,mount -->

---

## Exec into Running Container
Open a shell in an already-running container.

```bash
docker exec -it {{CONTAINER:str:webapp}} /bin/bash
```

<!-- meta: risk=low | phase=misc | tags=exec,shell,attach -->

---

## Build Image
Build a Docker image from a Dockerfile.

```bash
docker build -t {{TAG:str:myimage:latest}} {{PATH:dir:.}}
```

<!-- meta: risk=low | phase=misc | tags=build,image,dockerfile -->

---

## List Containers and Images
Show running containers and available images.

```bash
docker ps -a && docker images
```

<!-- meta: risk=safe | phase=misc | tags=ps,list,images,containers -->

---

## View Logs
Stream logs from a running container.

```bash
docker logs -f --tail {{LINES:int:100}} {{CONTAINER:str:webapp}}
```

<!-- meta: risk=safe | phase=misc | tags=logs,follow,debug -->

---

## Stop and Remove Container
Stop a running container and remove it.

```bash
docker stop {{CONTAINER:str:webapp}} && docker rm {{CONTAINER:str:webapp}}
```

<!-- meta: risk=med | phase=misc | tags=stop,remove,cleanup -->

---

## Docker Compose Up
Start all services defined in a compose file.

```bash
docker compose -f {{FILE:file:docker-compose.yml}} up -d
```

<!-- meta: risk=low | phase=misc | tags=compose,up,services -->

---

## Docker Compose Down
Stop and remove all containers, networks, and volumes from compose.

```bash
docker compose -f {{FILE:file:docker-compose.yml}} down --volumes
```

<!-- meta: risk=med | phase=misc | tags=compose,down,cleanup -->

---

## System Prune
Remove all stopped containers, unused networks, dangling images, and build cache.

```bash
docker system prune -af --volumes
```

<!-- meta: risk=high | phase=misc | tags=prune,cleanup,disk -->

---

## Network Management
List, create, and inspect Docker networks.

```bash
docker network ls && docker network inspect {{NETWORK:str:bridge}}
```

<!-- meta: risk=safe | phase=misc | tags=network,inspect,list -->
