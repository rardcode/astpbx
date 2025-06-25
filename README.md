# FreePBX
FreePBX server based on Debian.

## Quick reference
* Where to file issues:
[GitHub](https://github.com/rardcode/astpbx)

* Supported architectures: amd64 , armv7 , arm64v8

## How to use
### First installation
```
cd /opt
git clone https://github.com/rardcode/astpbx.git
cd astpbx
```
1. First set MySQL root pass in `envfile` & enable other envs according to your needs.

2. Run by:
* ...docker run:
```
docker run -d \
  --name astpbx-db \
  -e env_file="envfile" \
  -v ./data/db:/config" \
  -p 3306:3306 \
  --restart unless-stopped \
  mariadb:10.11.13
```
```
docker run -d \
  --name astpbx \
  -e env_file="envfile" \
  -v ./data/pbx:/data" \
  --network host \
  --restart unless-stopped \
  rardcode/astpbx
```
* ...or by docker-compose file:
```
services:
  db:
    image: mariadb:10.11.13
    container_name: astpbx-db
    env_file:
    - envfile
    volumes:
      - ./data/db:/config
    ports:
      - 3306:3306
    restart: unless-stopped
  app:
    image: rardcode/astpbx
    container_name: astpbx
    #hostname: astpbx.domain.com
    volumes:
      - ./data/pbx:/data
    env_file:
      - envfile
    network_mode: host
    depends_on:
    - db
    restart: unless-stopped
```

### Upgrade
1. Clone repo
```
cd /opt/astpbx
git checkout main
git pull
git fetch --tags --all -f
git checkout tags/$(git tag | sort --version-sort | tail -1)
```
2. Upgrade with:
```
docker compose pull
docker compose up -d
```

## Changelog
v1.0.0 - 25.06.2025
- Debian v. 12.11
- Asterisk v. 20.14.1
- FreePBX v. 16.0
