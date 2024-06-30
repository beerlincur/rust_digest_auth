import hashlib

# Данные для расчета
username = "testuser"
realm = "example"
password = "$2b$04$bzErrhqer06f2dlqE6kHb.0uRN/0UtSr/8ceP3XsE2u8Nr9VL0XoG"
nonce = "ot4upEI0KuHJwXS29CH2wnjgg7ygkH"
uri = "/authenticate"
nc = "00000001"
cnonce = "0a4f113b"
qop = "auth"

# Вычисление HA1
ha1 = hashlib.md5(f"{username}:{realm}:{password}".encode()).hexdigest()
print("HA1:", ha1)

# Вычисление HA2
ha2 = hashlib.md5(f"POST:{uri}".encode()).hexdigest()
print("HA2:", ha2)

# Вычисление response
response = hashlib.md5(f"{ha1}:{nonce}:{nc}:{cnonce}:{qop}:{ha2}".encode()).hexdigest()
print("Response:", response)
