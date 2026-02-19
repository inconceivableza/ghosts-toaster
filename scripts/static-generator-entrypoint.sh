#!/bin/sh

# Create group if it doesn't exist
if ! getent group ${STATIC_GID:=100} >/dev/null 2>&1; then
    addgroup -g ${STATIC_GID} ${STATIC_GROUP:=appgroup}
fi

# Create user if it doesn't exist
if ! getent passwd ${STATIC_UID:=1000} >/dev/null 2>&1; then
    adduser -D -u ${STATIC_UID} -G ${STATIC_GROUP} ${STATIC_USER:=appuser}
fi

# Execute the command as the target user
exec su-exec ${STATIC_UID}:${STATIC_GID} "$@"
