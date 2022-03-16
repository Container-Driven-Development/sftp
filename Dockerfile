# BUILDER
FROM crystallang/crystal:1.3-alpine as BUILDER

WORKDIR /app

COPY entrypoint.cr /app
COPY sshd_config.ecr /app

RUN crystal build entrypoint.cr --release --no-debug

# IMAGE
FROM alpine:3.15.0

LABEL org.opencontainers.image.source https://github.com/Container-Driven-Development/sftp

ENV SSHD_PORT=36622
ENV SSH_USER_NAME=www-data
ENV SSH_USER_ID=1001
ENV SSH_GROUP_NAME=www-data
ENV SSH_GROUP_ID=1001
ENV SSH_HOMEDIR=/var/www

ENTRYPOINT ["/entrypoint"]

EXPOSE "${SSHD_PORT}/tcp"

RUN apk --no-cache add openssh openssh-sftp-server pcre libgcc

COPY --from=BUILDER /app/entrypoint /entrypoint

RUN delgroup ${SSH_GROUP_NAME} && \
  addgroup -g ${SSH_GROUP_ID} -S ${SSH_USER_NAME} && \ 
  adduser -D -h ${SSH_HOMEDIR} -u ${SSH_USER_ID} -G ${SSH_GROUP_NAME} ${SSH_USER_NAME} && \
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
