use chrono::{Duration, Utc, DateTime};

pub fn nonce_expiration() -> DateTime<Utc> {
    Utc::now() + Duration::minutes(5)
}
