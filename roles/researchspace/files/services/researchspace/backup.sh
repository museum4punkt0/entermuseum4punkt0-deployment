#!/bin/sh

set -e

PREFIX="researchspace-${WEB_DOMAIN}-"
NAME="${PREFIX}$(date -Im)"
COMMON_ARGS="--show-rc -v --lock-wait 1800"

echo -e "\nCreating archive ${NAME} in ${BORG_REPO}"
borg create ${COMMON_ARGS} --stats "::${NAME}" /src/*

echo -e "\nPruning old archives"
borg prune ${COMMON_ARGS} --list --force --prefix ${PREFIX} --keep-daily 28 --keep-monthly 12 --keep-yearly 1
