use actix_web::{web, HttpResponse};
use serde::{Deserialize, Serialize};
use tokio_postgres::Row;
use bcrypt::{hash, DEFAULT_COST};
use uuid::Uuid;
use chrono::Utc;
use jsonwebtoken::{encode, Header, EncodingKey};
use crate::models::AppState;
use crate::schema::nonce_expiration;

#[derive(Serialize, Deserialize)]
struct User {
    username: String,
    password: String,
}

#[derive(Serialize)]
struct TokenResponse {
    token: String,
}

#[derive(Serialize, Deserialize)]
struct AuthRequest {
    username: String,
    nonce: String,
    uri: String,
    response: String,
}

#[derive(Serialize, Deserialize)]
struct Claims {
    sub: String,
    exp: usize,
}

pub fn init_routes(cfg: &mut web::ServiceConfig) {
    cfg.service(
        web::resource("/register")
            .route(web::post().to(register_user))
    )
        .service(
            web::resource("/nonce")
                .route(web::get().to(get_nonce))
        )
        .service(
            web::resource("/authenticate")
                .route(web::post().to(authenticate_user))
        )
        .service(
            web::resource("/user")
                .route(web::get().to(get_user_info))
        );
}

async fn register_user(
    data: web::Data<AppState>,
    user: web::Json<User>,
) -> HttpResponse {
    let client = data.db.get().await.unwrap();
    let hashed_password = hash(&user.password, DEFAULT_COST).unwrap();
    client
        .execute(
            "INSERT INTO users (username, password_hash) VALUES ($1, $2)",
            &[&user.username, &hashed_password],
        )
        .await
        .unwrap();
    HttpResponse::Ok().finish()
}

async fn get_nonce(data: web::Data<AppState>, query: web::Query<User>) -> HttpResponse {
    let client = data.db.get().await.unwrap();
    let nonce = Uuid::new_v4().to_string();
    let expires_at = nonce_expiration().to_string();
    client
        .execute(
            "INSERT INTO nonces (nonce, username, expires_at) VALUES ($1, $2, $3)",
            &[&nonce, &query.username, &expires_at],
        )
        .await
        .unwrap();
    HttpResponse::Ok().json(nonce)
}

async fn authenticate_user(
    data: web::Data<AppState>,
    auth_request: web::Json<AuthRequest>,
) -> HttpResponse {
    let client = data.db.get().await.unwrap();
    let rows: Vec<Row> = client
        .query(
            "SELECT password_hash FROM users WHERE username = $1",
            &[&auth_request.username],
        )
        .await
        .unwrap();

    if rows.is_empty() {
        return HttpResponse::Unauthorized().finish();
    }

    let password_hash: &str = rows[0].get(0);

    let calculated_response = format!(
        "{:x}",
        md5::compute(format!(
            "{}:{}:{}:{}:{}",
            auth_request.nonce,
            auth_request.username,
            "realm",
            auth_request.uri,
            password_hash
        ))
    );

    if calculated_response != auth_request.response {
        return HttpResponse::Unauthorized().finish();
    }

    let claims = Claims {
        sub: auth_request.username.clone(),
        exp: (Utc::now() + chrono::Duration::hours(1)).timestamp() as usize,
    };

    let token = encode(
        &Header::default(),
        &claims,
        &EncodingKey::from_secret(data.secret_key.as_bytes()),
    )
        .unwrap();

    HttpResponse::Ok().json(TokenResponse { token })
}

async fn get_user_info(data: web::Data<AppState>, req: actix_web::HttpRequest) -> HttpResponse {
    let auth_header = req.headers().get("Authorization");

    if auth_header.is_none() {
        return HttpResponse::Unauthorized().finish();
    }

    let token = auth_header.unwrap().to_str().unwrap().replace("Bearer ", "");

    let decoding_key = jsonwebtoken::DecodingKey::from_secret(data.secret_key.as_bytes());

    match jsonwebtoken::decode::<Claims>(&token, &decoding_key, &jsonwebtoken::Validation::default())
    {
        Ok(token_data) => HttpResponse::Ok().json(token_data.claims),
        Err(_) => HttpResponse::Unauthorized().finish(),
    }
}
