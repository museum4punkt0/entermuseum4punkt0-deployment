#!/bin/sh

set -e

PREFIX="acme-certificates-"
NAME="${PREFIX}$(date -Im)"
COMMON_ARGS="--show-rc -v --lock-wait 1800"

echo -e "\nCreating archive ${NAME} in ${BORG_REPO}"
borg create ${COMMON_ARGS} --stats "::${NAME}" /src/*

echo -e "\nPruning old archives"
borg prune ${COMMON_ARGS} --list --force --prefix ${PREFIX} --keep-weekly 12 --keep-monthly 12
