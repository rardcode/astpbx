
## https://hub.docker.com/_/debian/tags
FROM debian:13.2-slim

LABEL org.opencontainers.image.authors="rardcode <sak37564@ik.me>"
LABEL Description="FreePBX with Asterisk, based on Debian."

ENV APP_NAME="astpbx"
ENV DEBIAN_FRONTEND="noninteractive"

## https://downloads.asterisk.org/pub/telephony/asterisk/releases/
## https://www.asterisk.org/downloads/asterisk/all-asterisk-versions/
ARG ASTERISK_VER="23.2.1"

## https://github.com/FreePBX/core/tags
ARG FREEPBX_VER="17.0"

#ENV FREEPBX_VER=${FREEPBX_VER}

ARG PHP_VER="8.2"

RUN set -xe && \
  : "---------- ESSENTIAL packages INSTALLATION ----------" && \
  apt update && \
  apt-get upgrade -y && \
  apt install -y \
    iputils-ping \
    bison \
    flex \
    build-essential \
    git \
    curl \
    wget \
    libnewt-dev \
    libssl-dev \
    libncurses5-dev \
    subversion \
    libsqlite3-dev \
    libjansson-dev \
    libxml2-dev \
    uuid \
    uuid-dev \
    default-libmysqlclient-dev \
    htop \
    sngrep \
    lame \
    ffmpeg \
    mpg123 \
    supervisor \
    rsync \
    vim \
    expect \
    sox \
    sqlite3 \
    pkg-config \
    automake \
    libtool \
    autoconf \
    unixodbc-dev \
    libasound2-dev \
    libogg-dev \
    libvorbis-dev \
    libicu-dev \
    libcurl4-openssl-dev \
    odbc-mariadb \
    libical-dev \
    libneon27-dev \
    libsrtp2-dev \
    libspandsp-dev \
    sudo \
    libtool-bin \
    python-dev-is-python3 \
    unixodbc\
    libjansson-dev \
    nodejs \
    npm \
    ipset \
    openssh-server \
    postfix \
    apache2 \
    mariadb-server \
    mariadb-client  \
    mpg123 \
    lame \
    ffmpeg \
    sqlite3 \
    unixodbc \
    odbc-mariadb \
    fail2ban \
    rsyslog \
    cron \
    lsb-release \
  && \
  update-ca-certificates \
  && \
  apt-get clean && apt-get autoremove -y && \
  rm -rf /var/lib/apt/lists/* /tmp/*

RUN set -xe && \
  : "---------- PHP ${PHP_VER} INSTALLATION ----------" && \
  wget -O /etc/apt/trusted.gpg.d/php.gpg https://packages.sury.org/php/apt.gpg && \
  echo "deb https://packages.sury.org/php/ $(lsb_release -sc) main" | tee /etc/apt/sources.list.d/php.list && \
  apt update && \
  apt-get upgrade -y && \
  apt install -y \
    php${PHP_VER} \
    php${PHP_VER}-curl \
    php${PHP_VER}-cli \
    php${PHP_VER}-common \
    php${PHP_VER}-mysql \
    php${PHP_VER}-gd \
    php${PHP_VER}-mbstring \
    php${PHP_VER}-intl \
    php${PHP_VER}-xml \
    php-pear \
    php-soap \
  && \
  apt-get clean && apt-get autoremove -y && \
  rm -rf /var/lib/apt/lists/* /tmp/*

RUN set -xe && \
  : "---------- Asterisk ${ASTERISK_VER} INSTALLATION ----------" && \
  apt update && \
  apt-get upgrade -y && \
  cd /usr/src && \
  mkdir asterisk && \
  wget https://downloads.asterisk.org/pub/telephony/asterisk/releases/asterisk-${ASTERISK_VER}.tar.gz  && \
  tar xvzf asterisk-${ASTERISK_VER}.tar.gz --strip 1 -C /usr/src/asterisk && \
  rm asterisk-${ASTERISK_VER}.tar.gz && \
  cd /usr/src/asterisk && \
  ./contrib/scripts/get_mp3_source.sh && \
  ./contrib/scripts/install_prereq install && \
  ./configure --libdir=/usr/lib64 --prefix=/usr --with-pjproject-bundled --with-jansson-bundled --with-resample --with-ssl=ssl --with-srtp && \
  make menuselect && \
  make && \
  make install && \
  make samples && \
  make config && \
  ldconfig \
  && \
  apt-get clean && apt-get autoremove -y && \
  rm -rf /var/lib/apt/lists/* /tmp/*

RUN set -xe && \
  : "---------- Asterisk ${ASTERISK_VER} setup ---------" && \
  groupadd asterisk && \
  useradd -r -d /var/lib/asterisk -g asterisk asterisk && \
  usermod -aG audio,dialout asterisk && \
  chown -R asterisk:asterisk /etc/asterisk && \
  chown -R asterisk:asterisk /var/lib/asterisk && \
  chown -R asterisk:asterisk /var/log/asterisk && \
  chown -R asterisk:asterisk /var/spool/asterisk && \
  chown -R asterisk:asterisk /usr/lib64/asterisk && \
  sed -i 's|#AST_USER|AST_USER|' /etc/default/asterisk && \
  sed -i 's|#AST_GROUP|AST_GROUP|' /etc/default/asterisk && \
  sed -i 's|;runuser|runuser|' /etc/asterisk/asterisk.conf && \
  sed -i 's|;rungroup|rungroup|' /etc/asterisk/asterisk.conf && \
  echo "/usr/lib64" >> /etc/ld.so.conf.d/x86_64-linux-gnu.conf && \
  ldconfig

RUN set -xe && \
  : "---------- Apache2 setup ----------" && \
  sed -i 's/\(^upload_max_filesize = \).*/\120M/' /etc/php/${PHP_VER}/apache2/php.ini && \
  sed -i 's/\(^memory_limit = \).*/\1256M/' /etc/php/${PHP_VER}/apache2/php.ini && \
  sed -i 's/^\(User\|Group\).*/\1 asterisk/' /etc/apache2/apache2.conf && \
  sed -i 's/AllowOverride None/AllowOverride All/' /etc/apache2/apache2.conf && \
  a2enmod rewrite && \
  rm /var/www/html/index.html

RUN set -xe && \
  : "---------- DOWNLOAD ${FREEPBX_VER} Freepbx ----------" && \
  cd /usr/local/src && \
  mkdir freepbx && \
  wget http://mirror.freepbx.org/modules/packages/freepbx/freepbx-${FREEPBX_VER}-latest-EDGE.tgz  && \
  tar zxvf freepbx-${FREEPBX_VER}-latest-EDGE.tgz --strip 1 -C freepbx && \
  rm -rf freepbx-${FREEPBX_VER}-latest-EDGE.tgz

ENV POSTFIX_SENDER_MAIL="sender@domain.com"
ENV POSTFIX_RECIPIENT_MAIL="recipient@domain.com"
ENV POSTFIX_SMTP_SERVER=""
ENV POSTFIX_SMTP_PORT="25"
ENV POSTFIX_SMTP_TLS="OFF"
ENV POSTFIX_SMTP_USER="smtp_user"
ENV POSTFIX_SMTP_PASSWD="smtp_passwd"

RUN ln -snf /usr/share/zoneinfo/Europe/Rome /etc/localtime && echo Europe/Rome > /etc/timezone

ADD rootfs /

ENTRYPOINT ["/entrypoint.sh"]
CMD ["supervisord", "-c", "/etc/supervisor/supervisord.conf"]
