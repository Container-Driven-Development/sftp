# BUILDER
FROM --platform=linux/amd64 crystallang/crystal:1.12 as BUILDER

WORKDIR /app

COPY entrypoint.cr /app
COPY sshd_config.ecr /app

RUN crystal build entrypoint.cr --release --no-debug

# IMAGE
FROM --platform=linux/amd64 ubuntu:22.04

LABEL org.opencontainers.image.source https://github.com/Container-Driven-Development/sftp

ENV SSHD_PORT=36622
ENV SSH_USER_NAME=www-data
ENV SSH_USER_ID=1000
ENV SSH_GROUP_NAME=www-data
ENV SSH_GROUP_ID=1000
ENV SSH_HOMEDIR=/var/www
ENV SSHD_ENABLE_SSH=false

ENTRYPOINT ["/entrypoint"]

EXPOSE "${SSHD_PORT}/tcp"

  # pcre \
  # libgcc \
  # busybox-extras \


RUN apt-get update && apt-get install -y openssh-server \
  openssh-sftp-server \
  mariadb-client \
  curl \
  libevent-2.1-7 \
  && rm -rf /var/lib/apt/lists/*

RUN mkdir /var/run/sshd

COPY --from=BUILDER /app/entrypoint /entrypoint

RUN deluser ${SSH_USER_NAME} && \
  addgroup --gid ${SSH_GROUP_ID} ${SSH_USER_NAME} && \
  adduser --home ${SSH_HOMEDIR} --uid ${SSH_USER_ID} --ingroup ${SSH_GROUP_NAME} --shell /bin/sh ${SSH_USER_NAME} && \
  echo "${SSH_USER_NAME}:*" | chpasswd -e && \
  chown root:root ${SSH_HOMEDIR} && \
  chmod 755 /var/www && \
  mkdir ${SSH_HOMEDIR}/data && \
  chown ${SSH_USER_NAME}:${SSH_GROUP_NAME} ${SSH_HOMEDIR}/data

# ⚠️ chown root:root is important see docs below
# ChrootDirectory
# 	     Specifies the pathname of a directory to chroot(2)	to after au-
# 	     thentication.  At session startup sshd(8) checks that all compo-
# 	     nents of the pathname are root-owned directories which are	not
# 	     writable by any other user	or group.
