use actix_web::{web, App, HttpServer};
use dotenv::dotenv;
use std::env;

mod handlers;
mod models;
mod schema;

#[actix_web::main]
async fn main() -> std::io::Result<()> {
    dotenv().ok();
    let database_url = env::var("DATABASE_URL").expect("DATABASE_URL must be set");
    let secret_key = env::var("SECRET_KEY").expect("SECRET_KEY must be set");

    let db_pool = models::connect(&database_url).await.unwrap();

    HttpServer::new(move || {
        App::new()
            .app_data(web::Data::new(models::AppState {
                db: db_pool.clone(),
                secret_key: secret_key.clone(),
            }))
            .configure(handlers::init_routes)
    })
        .bind("127.0.0.1:8080")?
        .run()
        .await
}
