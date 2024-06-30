CREATE DATABASE auth_db;
-- \c auth_db

CREATE TABLE users
(
    id            SERIAL PRIMARY KEY,
    username      VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255)        NOT NULL
);

CREATE TABLE nonces
(
    id         SERIAL PRIMARY KEY,
    nonce      VARCHAR(255) NOT NULL,
    username   VARCHAR(255) NOT NULL,
    expires_at TIMESTAMPTZ  NOT NULL
);
