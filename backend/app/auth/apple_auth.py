import os
import jwt
from jwt import PyJWKClient

APPLE_JWKS_URL = "https://appleid.apple.com/auth/keys"
APPLE_ISSUER  = "https://appleid.apple.com"

APPLE_BUNDLE_ID = os.environ.get("APPLE_BUNDLE_ID", "com.VladKarpov.PlateSpotter")

def verify_apple_identity_token(identity_token: str) -> dict:
    jwk_client = PyJWKClient(APPLE_JWKS_URL)
    signing_key = jwk_client.get_signing_key_from_jwt(identity_token)

    payload = jwt.decode(
        identity_token,
        signing_key.key,
        algorithms=["RS256"],
        audience=APPLE_BUNDLE_ID,
        issuer=APPLE_ISSUER,
    )
    return payload
