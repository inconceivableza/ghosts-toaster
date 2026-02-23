#!/bin/bash
# Ensures .secrets contains all required credentials.
# For each key: keeps existing value in .secrets, transfers from .env if present, otherwise generates a new one.
# Safe to run multiple times - will not overwrite existing values.

SECRETS_FILE="$(dirname "$0")/../.secrets"
ENV_FILE="$(dirname "$0")/../.env"

generate_secret() {
    head -c 32 /dev/urandom | sha256sum | head -c 32
}

# Ensure the key is present in .secrets.
# If already there, do nothing. If in .env, transfer it. Otherwise generate.
ensure_secret() {
    local key="$1"

    if grep -q "^${key}=" "$SECRETS_FILE" 2>/dev/null; then
        return 0
    fi

    local env_val
    env_val=$(grep "^${key}=" "$ENV_FILE" 2>/dev/null | cut -d= -f2)
    if [ -n "$env_val" ]; then
        echo "${key}=${env_val}" >> "$SECRETS_FILE"
        echo "Transferred $key from .env to $SECRETS_FILE (consider removing it from .env)"
    else
        echo "${key}=$(generate_secret)" >> "$SECRETS_FILE"
        echo "Generated new $key in $SECRETS_FILE"
    fi
}

if [ ! -f "$SECRETS_FILE" ]; then
    echo "# Auto-generated secrets - do not commit this file" > "$SECRETS_FILE"
    chmod 600 "$SECRETS_FILE"
fi

changed_before=$(wc -l < "$SECRETS_FILE")
ensure_secret MYSQL_ROOT_PASSWORD
ensure_secret WEBHOOK_SECRET
changed_after=$(wc -l < "$SECRETS_FILE")

[ "$changed_before" -eq "$changed_after" ] && echo "Secrets file already exists and is complete."
