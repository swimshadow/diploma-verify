# ECP (Electronic Signature) Login System

## Overview

The ECP (Electronic Signature) system provides an alternative authentication method for universities and employers. Instead of using only email/password, they can sign in using their electronic signature (RSA-2048 or ECDSA P-256).

This is similar to SSH key-based authentication, but for web applications.

## How It Works

1. **Client** requests a challenge:
   ```
   POST /auth/ecp/challenge
   ```

2. **Client** signs the challenge with their private key

3. **Client** sends the signed challenge for verification:
   ```
   POST /auth/ecp/verify
   ```

4. **Server** verifies the signature and issues JWT tokens

## Setup

### 1. Generate Keypair

Navigate to the auth-service directory and run:

```bash
cd backend/auth-service
python utils/generate_ecp_keys.py --algorithm RS256 --name "MIT Main Key"
```

This creates two files:
- `mit_main_key_private.pem` - Keep this SECRET!
- `mit_main_key_public.pem` - Upload this to the platform

Supported algorithms:
- `RS256` - RSA-2048 (recommended for production)
- `ES256` - ECDSA P-256 (faster, smaller keys)

### 2. Register Public Key

First, obtain a JWT token by logging in with email/password:

```bash
curl -X POST http://localhost:8000/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "mgu@example.com",
    "password": "secure_password",
    "role": "university"
  }'

curl -X POST http://localhost:8000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "mgu@example.com",
    "password": "secure_password"
  }'
```

Export the access_token:
```bash
export JWT_TOKEN="your_access_token_here"
```

Register your public key:

```bash
curl -X POST http://localhost:8000/api/auth/ecp/keys \
  -H "Authorization: Bearer $JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d @- << 'EOF'
{
  "key_name": "MIT Main Key",
  "algorithm": "RS256",
  "public_key_pem": "$(cat backend/auth-service/mit_main_key_public.pem)"
}
EOF
```

Or using direct file reading:

```bash
PUBLIC_KEY=$(cat backend/auth-service/mit_main_key_public.pem | sed 's/\n/\\n/g' | sed 's/"/\\"/g')
curl -X POST http://localhost:8000/api/auth/ecp/keys \
  -H "Authorization: Bearer $JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d "{
    \"key_name\": \"MIT Main Key\",
    \"algorithm\": \"RS256\",
    \"public_key_pem\": \"$PUBLIC_KEY\"
  }"
```

Response:
```json
{
  "key_id": "550e8400-e29b-41d4-a716-446655440000",
  "fingerprint": "a1b2c3d4e5f6...",
  "algorithm": "RS256",
  "created_at": "2026-04-03T22:00:00"
}
```

### 3. List Registered Keys

```bash
curl http://localhost:8000/api/auth/ecp/keys \
  -H "Authorization: Bearer $JWT_TOKEN"
```

Response:
```json
[
  {
    "key_id": "550e8400-e29b-41d4-a716-446655440000",
    "key_name": "MIT Main Key",
    "fingerprint": "a1b2c3d4e5f6...",
    "algorithm": "RS256",
    "is_active": true,
    "created_at": "2026-04-03T22:00:00",
    "last_used_at": null
  }
]
```

## Login Flow

### Step 1: Request Challenge

```bash
curl -X POST http://localhost:8000/api/auth/ecp/challenge \
  -H "Content-Type: application/json" \
  -d '{"email": "mgu@example.com"}'
```

Response:
```json
{
  "challenge": "a3f8c2e1d7b9f5a4c6e8d2b9f7a5c3e1a9f5d2b8e4c1a7f3d5b9c6e2a8f4d1",
  "expires_in": 300
}
```

The challenge is valid for 5 minutes.

### Step 2: Sign the Challenge

Save the challenge to a file:
```bash
echo -n "a3f8c2e1d7b9f5a4c6e8d2b9f7a5c3e1a9f5d2b8e4c1a7f3d5b9c6e2a8f4d1" > challenge.txt
```

Sign it with your private key:

**For RSA (RS256):**
```bash
openssl dgst -sha256 -sign backend/auth-service/mit_main_key_private.pem \
  -out signature.bin challenge.txt

# Convert to base64
SIGNATURE=$(base64 -w0 signature.bin)
echo $SIGNATURE
```

**For ECDSA (ES256):**
```bash
openssl dgst -sha256 -sign backend/auth-service/mit_main_key_private.pem \
  -out signature.bin challenge.txt

# Convert to base64
SIGNATURE=$(base64 -w0 signature.bin)
echo $SIGNATURE
```

### Step 3: Verify Signature and Login

```bash
curl -X POST http://localhost:8000/api/auth/ecp/verify \
  -H "Content-Type: application/json" \
  -d "{
    \"email\": \"mgu@example.com\",
    \"challenge\": \"a3f8c2e1d7b9f5a4c6e8d2b9f7a5c3e1a9f5d2b8e4c1a7f3d5b9c6e2a8f4d1\",
    \"signature\": \"$SIGNATURE\"
  }"
```

Response:
```json
{
  "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "refresh_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "role": "university",
  "auth_method": "ecp",
  "key_fingerprint": "a1b2c3d4e5f6..."
}
```

You now have valid JWT tokens! Use `access_token` for API calls.

## Deactivate a Key

If a key is compromised:

```bash
curl -X DELETE http://localhost:8000/api/auth/ecp/keys/550e8400-e29b-41d4-a716-446655440000 \
  -H "Authorization: Bearer $JWT_TOKEN"
```

Response:
```json
{
  "status": "deactivated"
}
```

## Security Considerations

1. **Private Key Management**
   - Store private keys securely
   - Never commit to Git
   - Use HSM or secure vault in production
   - Rotate keys periodically

2. **Rate Limiting**
   - Maximum 5 challenge requests per minute per IP
   - Maximum 3 challenges per 5 minutes per email
   - Protects against brute force attacks

3. **Challenge Expiration**
   - Challenges expire after 5 minutes
   - Challenges are one-time use (deleted after verification)
   - Cannot be reused

4. **Audit Logging**
   - All ECP login attempts are logged
   - Failed attempts are recorded
   - Key usage is tracked (last_used_at)

## Complete Example Script

```bash
#!/bin/bash
set -e

EMAIL="mgu@example.com"
JWT_TOKEN="your_jwt_here"
PRIVATE_KEY="backend/auth-service/mit_main_key_private.pem"

# 1. Get challenge
RESPONSE=$(curl -s -X POST http://localhost:8000/api/auth/ecp/challenge \
  -H "Content-Type: application/json" \
  -d "{\"email\": \"$EMAIL\"}")

CHALLENGE=$(echo $RESPONSE | jq -r '.challenge')
echo "Challenge: $CHALLENGE"

# 2. Sign challenge
echo -n "$CHALLENGE" > /tmp/challenge.txt
openssl dgst -sha256 -sign "$PRIVATE_KEY" \
  -out /tmp/signature.bin /tmp/challenge.txt

SIGNATURE=$(base64 -w0 /tmp/signature.bin)

# 3. Verify and login
curl -X POST http://localhost:8000/api/auth/ecp/verify \
  -H "Content-Type: application/json" \
  -d "{
    \"email\": \"$EMAIL\",
    \"challenge\": \"$CHALLENGE\",
    \"signature\": \"$SIGNATURE\"
  }" | jq .

# Cleanup
rm -f /tmp/challenge.txt /tmp/signature.bin
```

## Troubleshooting

### "No active ECP keys registered"
- Make sure you've registered a key with POST /auth/ecp/keys
- Check that the key's is_active flag is true
- Try registering a new key

### "Invalid signature"
- Verify you're signing the exact challenge string
- Check that you're using the correct private key
- Ensure the algorithm matches (RS256 or ES256)
- Make sure you haven't modified the challenge

### "Invalid or expired challenge"
- Request a new challenge (5 minute timeout)
- Challenges can only be used once

### "Too many challenge requests"
- Wait a minute before requesting another challenge
- Rate limits prevent brute force attacks

## Development

To test ECP without physical keys, create test keys:

```bash
python backend/auth-service/utils/generate_ecp_keys.py \
  --algorithm RS256 \
  --name "test_key"
```

These test keys can be committed to your test environment (but never production keys!).
