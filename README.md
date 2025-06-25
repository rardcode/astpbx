# FreePBX with Asterisk engine
Asterisk communication server with FreePBX GUI.

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

2. Run with:
```
docker compose up -d
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
