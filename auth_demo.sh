#!/bin/bash

set -e

echo "$(date) - Starting digest authentication process demo..."

USERNAME="testuser"
PASSWORD="testpassword"
SERVER="http://localhost:8080"

echo "$(date) - Registering user..."
REGISTER_RESPONSE=$(curl -s -X POST -H "Content-Type: application/json" -d "{\"username\":\"$USERNAME\", \"password\":\"$PASSWORD\"}" "$SERVER/register")
echo "$(date) - Response from register user: $REGISTER_RESPONSE"
echo "$(date) - User registered."

echo "$(date) - Getting nonce..."
NONCE_RESPONSE=$(curl -s -G --data-urlencode "username=$USERNAME" "$SERVER/nonce")
echo "$(date) - Nonce received: $NONCE_RESPONSE"

NONCE=$(echo $NONCE_RESPONSE | jq -r '.nonce')
if [ -z "$NONCE" ]; then
    echo "$(date) - Failed to get nonce"
    exit 1
fi

echo "$(date) - Calculating response..."
HA1=$(echo -n "$USERNAME:realm:$PASSWORD" | md5)
HA2=$(echo -n "GET:/protected" | md5)
RESPONSE=$(echo -n "$HA1:$NONCE:$HA2" | md5)
echo "$(date) - HA1: $HA1"
echo "$(date) - HA2: $HA2"
echo "$(date) - Response calculated: $RESPONSE"

echo "$(date) - Authenticating user..."
AUTH_RESPONSE=$(curl -s -X POST -H "Content-Type: application/json" -d "{\"username\":\"$USERNAME\", \"nonce\":\"$NONCE\", \"uri\":\"/protected\", \"response\":\"$RESPONSE\"}" "$SERVER/authenticate")
echo "$(date) - Response from authenticate user: $AUTH_RESPONSE"

TOKEN=$(echo $AUTH_RESPONSE | jq -r '.token')
if [ -z "$TOKEN" ]; then
    echo "$(date) - Failed to get JWT token"
    exit 1
fi

echo "$(date) - JWT Token received: $TOKEN"

echo "$(date) - Getting user info..."
USER_INFO_RESPONSE=$(curl -s -H "Authorization: Bearer $TOKEN" "$SERVER/user")
echo "$(date) - Response from get user info: $USER_INFO_RESPONSE"

echo "$(date) - Digest authentication process demo completed."