# Rust HTTP Server with Digest Authentication

## Описание

Этот проект реализует HTTP-сервер на Rust с использованием `actix-web`, `tokio`, `deadpool-postgres` и других библиотек для поддержки Digest Authentication с использованием реляционной базы данных PostgreSQL.

## Требования

- Rust (установите с помощью [rustup](https://rustup.rs/))
- PostgreSQL (установите с помощью [официального сайта PostgreSQL](https://www.postgresql.org/download/))
- `cargo` (должен быть установлен вместе с Rust)
- `jq` (установите с помощью [brew](https://brew.sh/) или аналогичного менеджера пакетов)

## Настройка PostgreSQL

1. Запустите PostgreSQL сервер.
2. Создайте базу данных:

```sh
psql -U postgres -c "CREATE DATABASE auth_db;"
```

3. Настройте подключение к базе данных:

Создайте пользователя и задайте ему пароль:
```sh
psql -U postgres -c "CREATE USER myuser WITH PASSWORD 'mypassword';"
```

Дайте пользователю права на вашу базу данных:
```sh
psql -U postgres -c "GRANT ALL PRIVILEGES ON DATABASE auth_db TO myuser;"
```

4. Создайте таблицы. Для этого выполните следующие команды в psql или используйте любой другой клиент для взаимодействия с PostgreSQL:
```sh
\c auth_db;

CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    username VARCHAR(255) UNIQUE NOT NULL,
    password VARCHAR(255) NOT NULL
);

CREATE TABLE nonces (
    id SERIAL PRIMARY KEY,
    username VARCHAR(255) NOT NULL,
    nonce VARCHAR(255) NOT NULL,
    expires_at TIMESTAMP NOT NULL
);
```

## Настройка проекта

1. Клонируйте репозиторий:
```sh
git clone https://github.com/yourusername/auth_server.git
cd auth_server
```

3. Настройте зависимости в Cargo.toml:
```sh
[dependencies]
actix-web = "4.0"
tokio = { version = "1", features = ["full"] }
deadpool-postgres = { version = "0.10", features = ["with-actix"] }
tokio-postgres = "0.7"
jsonwebtoken = "8.3.0"
bcrypt = "0.12.1"
uuid = { version = "1", features = ["v4"] }
serde = { version = "1.0", features = ["derive"] }
serde_json = "1.0"
thiserror = "1.0"
```

5. Создайте файл .env в корне проекта и добавьте туда строку подключения к базе данных:
```sh
DATABASE_URL=postgres://myuser:mypassword@localhost/auth_db
```

## Запуск проекта

1. Соберите и запустите проект:
```sh
cargo run
```

Сервер должен запуститься на `http://127.0.0.1:8080`.

## Использование

Для демонстрации работы проекта предусмотрен скрипт auth_demo.sh, который выполняет следующие действия:
- Регистрирует пользователя
- Получает nonce
- Завершает аутентификацию
- Получает аутентифицированного пользователя

### Запуск скрипта:
```sh
/bin/bash auth_demo.sh
```

### auth_demo.sh
```sh
#!/bin/bash

log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1"
}

log "Starting digest authentication process demo..."

log "Registering user..."
RESPONSE=$(curl -s -X POST http://localhost:8080/register -H "Content-Type: application/json" -d '{"username": "testuser", "password": "testpassword"}')
log "Response from register user: $RESPONSE"
log "User registered."

log "Getting nonce..."
NONCE_RESPONSE=$(curl -s -X GET "http://localhost:8080/nonce?username=testuser")
log "Nonce received: $NONCE_RESPONSE"
NONCE=$(echo $NONCE_RESPONSE | jq -r '.nonce')

log "Calculating response..."
HA1=$(echo -n "testuser:auth_server:testpassword" | md5sum | awk '{print $1}')
HA2=$(echo -n "GET:/protected" | md5sum | awk '{print $1}')
RESPONSE=$(echo -n "$HA1:$NONCE:$HA2" | md5sum | awk '{print $1}')
log "HA1: $HA1"
log "HA2: $HA2"
log "Response calculated: $RESPONSE"

log "Authenticating user..."
AUTH_RESPONSE=$(curl -s -X POST http://localhost:8080/authenticate -H "Content-Type: application/json" -d "{\"username\": \"testuser\", \"nonce\": \"$NONCE\", \"response\": \"$RESPONSE\"}")
log "Response from authenticate user: $AUTH_RESPONSE"
TOKEN=$(echo $AUTH_RESPONSE | jq -r '.token')
log "JWT Token received: $TOKEN"

log "Getting user info..."
USER_INFO=$(curl -s -X GET http://localhost:8080/user -H "Authorization: Bearer $TOKEN")
log "Response from get user info: $USER_INFO"
log "Digest authentication process demo completed."
```

## Примечания

- Убедитесь, что ваш PostgreSQL сервер запущен и доступен.
- При изменении конфигурации базы данных не забудьте обновить файл .env.

## Лицензия

Этот проект лицензирован на условиях MIT License.
