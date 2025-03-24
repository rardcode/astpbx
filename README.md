# FreePBX with Asterisk, based on Debian.

## Quick reference
* Where to file issues:
[GitHub](https://github.com/rardcode/astpbx)

* Supported architectures: amd64 , armv7 , arm64v8

## Run by docker-compose file:
```
services:
  db:
    image: linuxserver/mariadb
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
## Tag:
Ex. 1210.20111.16\
"1210" is the Debian version. Ex 12.10\
"20111" is the Aterisk version. Ex. 20.11.1\
"16" is the FreePBX version. Ex. 16.0\
"1"    if there's, is a minor fix update.
