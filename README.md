# FreePBX with Asterisk engine
Asterisk communication server with FreePBX GUI.

## Quick reference
* Where to file issues:
[GitHub](https://github.com/rardcode/astpbx/issues)

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
### Upgrade (...to be tested)
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
v20.17.16 - 31.12.2025
- Debian v. 13.2
- Asterisk v. 20.17.0
- FreePBX v. 16.0
