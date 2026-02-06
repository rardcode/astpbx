# FreePBX with Asterisk engine
Asterisk communication server with FreePBX GUI, Fail2Ban & Postfix.

## Quick reference
* Where to file issues:
[GitHub](https://github.com/rardcode/astpbx/issues)

* Supported architectures: amd64 , armv7 , arm64v8

## Installation
```
cd /opt
git clone https://github.com/rardcode/astpbx.git
cd astpbx
```
1. First set MySQL root pass in `envfile` & enable other envs according to your needs.

2. Run with:
```
docker compose up -d
```

## Backup
AstPbx has a script for auto-backup db asterisk & asteriskcdrdb.\
Db backup go in `/var/spool/asterisk/backup/`.\
Suggested: config a backup via GUI for __ASTETCDIR__, __ASTLIBDIR__ & __ASTSPOOLDIR__. In this last exclude pattern *tar.gz.


## Update
```
cd /opt/astpbx
docker compose pull && docker compose up -d
```

## Changelog
v2322.17 - 06.02.2026
- Asterisk v.23.2.2

v2321.17 - 30.01.2026
- Asterisk v.23.2.1

v23.2.17 - 20.01.2026
- Asterisk v.23.2.0

v23.1.17 - 20.01.2026
- Debian v.13.3
- Asterisk v.23.1.0

v22.7.17 - 02.12.2025
- Debian v.13.2
- Asterisk v.22.7.0
- FreePBX v.17.0
