FROM alpine:3.9

CMD ["tail", "-f", "/dev/null"]
STOPSIGNAL SIGKILL

ENV BORG_BASE_DIR=/var/lib/borg \
    BORG_RELOCATED_REPO_ACCESS_IS_OK=yes
VOLUME $BORG_BASE_DIR

RUN apk add --no-cache "borgbackup=~1.1"
