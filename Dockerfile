FROM crystallang/crystal:1.3-alpine as BUILDER

WORKDIR /app

COPY entrypoint.cr /app
COPY sshd_config.ecr /app

RUN crystal build entrypoint.cr --release --static

FROM alpine:3.15.0

LABEL org.opencontainers.image.source https://github.com/Container-Driven-Development/sftp

ENV SSHD_PORT=36622
ENV HOME=/var/www

ENTRYPOINT ["/entrypoint"]

EXPOSE "${SSHD_PORT}/tcp"

COPY --from=BUILDER /app/entrypoint /entrypoint

RUN delgroup www-data && addgroup -g 1001 -S www-data && adduser -u 1001 -S www-data -G www-data

# Install openssh-server for sftp
RUN apk --no-cache add openssh-server

# Add sshd config file
# COPY sshd_config.ecr /etc/ssh/sshd_config

# Prepare dir for user keys
RUN mkdir -p /var/www/.ssh && chown -R www-data:www-data /var/www/.ssh
