#!/bin/bash

# Constants
SERVER_URL="http://localhost:8080"
USERNAME="testuser"
PASSWORD="testpass"
REALM="realm"
URI="/requested/uri"
JWT_TOKEN=""
LOG_FILE="digest_auth_demo.log"

# Function to log messages
log() {
    echo "$(date +"%Y-%m-%d %H:%M:%S") - $1" | tee -a $LOG_FILE
}

# Function to register a user
register_user() {
    log "Registering user..."
    RESPONSE=$(curl -s -X POST "$SERVER_URL/register" -H "Content-Type: application/json" -d "{\"username\": \"$USERNAME\", \"password\": \"$PASSWORD\"}")
    log "Response from register user: $RESPONSE"
    log "User registered."
}

# Function to get a nonce
get_nonce() {
    log "Getting nonce..."
    NONCE=$(curl -s -G "$SERVER_URL/nonce" --data-urlencode "username=$USERNAME")
    log "Nonce received: $NONCE"
}

# Function to calculate the digest response
calculate_response() {
    log "Calculating response..."
    HA1=$(echo -n "$USERNAME:$REALM:$PASSWORD" | md5sum | awk '{print $1}')
    log "HA1: $HA1"
    HA2=$(echo -n "GET:$URI" | md5sum | awk '{print $1}')
    log "HA2: $HA2"
    RESPONSE=$(echo -n "$HA1:$NONCE:$HA2" | md5sum | awk '{print $1}')
    log "Response calculated: $RESPONSE"
}

# Function to authenticate the user
authenticate_user() {
    log "Authenticating user..."
    RESPONSE=$(curl -s -X POST "$SERVER_URL/authenticate" -H "Content-Type: application/json" -d "{\"username\": \"$USERNAME\", \"nonce\": \"$NONCE\", \"uri\": \"$URI\", \"response\": \"$RESPONSE\"}")
    log "Response from authenticate user: $RESPONSE"
    JWT_TOKEN=$(echo $RESPONSE | jq -r '.token')
    log "JWT Token received: $JWT_TOKEN"
}

# Function to get authenticated user information
get_user_info() {
    log "Getting user info..."
    RESPONSE=$(curl -s -H "Authorization: Bearer $JWT_TOKEN" "$SERVER_URL/user")
    log "Response from get user info: $RESPONSE"
}

# Main script execution
log "Starting digest authentication process demo..."
register_user
get_nonce
calculate_response
authenticate_user
get_user_info
log "Digest authentication process demo completed."
