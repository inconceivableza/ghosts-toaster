#!/bin/bash
# Generates .secrets with random values for auto-managed credentials if not already present.
# Safe to run multiple times - will not overwrite existing values.

SECRETS_FILE="$(dirname "$0")/../.secrets"

generate_secret() {
    head -c 32 /dev/urandom | sha256sum | head -c 32
}

if [ ! -f "$SECRETS_FILE" ]; then
    echo "Creating $SECRETS_FILE with auto-generated secrets..."
    cat > "$SECRETS_FILE" <<EOF
# Auto-generated secrets - do not commit this file
MYSQL_ROOT_PASSWORD=$(generate_secret)
WEBHOOK_SECRET=$(generate_secret)
EOF
    chmod 600 "$SECRETS_FILE"
    echo "Secrets file created."
else
    # File exists; ensure both keys are present
    changed=0
    if ! grep -q "^MYSQL_ROOT_PASSWORD=" "$SECRETS_FILE"; then
        echo "MYSQL_ROOT_PASSWORD=$(generate_secret)" >> "$SECRETS_FILE"
        echo "Added missing MYSQL_ROOT_PASSWORD to $SECRETS_FILE"
        changed=1
    fi
    if ! grep -q "^WEBHOOK_SECRET=" "$SECRETS_FILE"; then
        echo "WEBHOOK_SECRET=$(generate_secret)" >> "$SECRETS_FILE"
        echo "Added missing WEBHOOK_SECRET to $SECRETS_FILE"
        changed=1
    fi
    [ $changed -eq 0 ] && echo "Secrets file already exists and is complete."
fi
