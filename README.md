# FreePBX with Asterisk engine
Asterisk communication server.

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
v2322.17-3 - 15.03.2026
- Debian v.13.3

v2322.17 - 06.02.2026
- Asterisk v.23.2.2
- Debian v.13.2
