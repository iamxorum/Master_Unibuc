# DW_BI Docker Compose Setup

This project runs Oracle 19c in a Docker container using Docker Compose. To avoid network conflicts, this setup requires a **pre-created Docker network** with a fixed subnet.

---

## 1. Pre-requisites

- Docker 20.10+ installed  
- Docker Compose 2.x installed (compatible also with v1)
- Sufficient memory: at least 8 GB available for Oracle  
- Ports `1515` and `1516` available on localhost  

---

## 2. Pull/Clone the repository

```bash
git clone https://gitea.xrm-test.de/UniBuc/DW_BI.git /path/
```

---

## 3. Copy .env.example and set proper .env (REQUIRED)

After the clone, set your .env by copying it from .env.example.

```bash
cp .env.example .env
```

Then you have to set/define your credentials/keys (STAY ATTENTIVE, INSERT IF NOT ALREADY - it should be - .env into .gitignore!)

---

## 4. Create the Docker network

Before starting the container, create the external network that Docker Compose will use:

```bash
docker network create \
  --subnet=172.20.0.0/24 \
  dwbi-net
```

---

## 5. Create container with Docker compose (v2)

After the creation of the docker network, go into the folder where it is the docker-compose.yml and run the following:

```bash
docker compose up -d
```

---

# 6. Check status

At the end, after the installation of the container, it should be everything fine (healthy)

```bash
root@XRM-UNIBUC02:/opt/dwbi_project (master)
$ docker ps
CONTAINER ID   IMAGE                                                        COMMAND                  CREATED          STATUS                                 PORTS                                                                                      NAMES
8e9c673a69d1   container-registry.oracle.com/database/enterprise:19.3.0.0   "/bin/bash -c 'exec …"   8 minutes ago    Up About a minute (health: starting)   127.0.0.1:1515->1521/tcp, 127.0.0.1:1516->5500/tcp                                         DW_BI
```
