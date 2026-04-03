#!/usr/bin/env python3
"""
Generator for ECP (Electronic Signature) key pairs for diploma-verify platform.

Usage:
    python generate_ecp_keys.py --algorithm RS256 --name "МГУ основной ключ"
    python generate_ecp_keys.py --algorithm ES256 --name "Diasoft ключ"

The script generates a keypair and saves:
    - {name}_private.pem (keep secret!)
    - {name}_public.pem (upload to platform)
"""

import argparse
import hashlib
from pathlib import Path

from cryptography.hazmat.primitives import serialization
from cryptography.hazmat.primitives.asymmetric import ec, rsa


def generate_rsa_keypair():
    """Generate RSA-2048 keypair"""
    private_key = rsa.generate_private_key(
        public_exponent=65537,
        key_size=2048,
    )
    return private_key


def generate_ec_keypair():
    """Generate ECDSA P-256 keypair"""
    private_key = ec.generate_private_key(ec.SECP256R1())
    return private_key


def save_keypair(private_key, name: str, algorithm: str):
    """
    Save keypair to PEM files and print instructions.
    
    Args:
        private_key: Private key object
        name: Name for the keypair (will be sanitized for filenames)
        algorithm: "RS256" or "ES256"
    """
    # Serialize private key to PEM
    private_pem = private_key.private_bytes(
        encoding=serialization.Encoding.PEM,
        format=serialization.PrivateFormat.PKCS8,
        encryption_algorithm=serialization.NoEncryption(),
    ).decode()

    # Serialize public key to PEM
    public_pem = private_key.public_key().public_bytes(
        encoding=serialization.Encoding.PEM,
        format=serialization.PublicFormat.SubjectPublicKeyInfo,
    ).decode()

    # Calculate fingerprint (SHA-256)
    fingerprint = hashlib.sha256(public_pem.encode()).hexdigest()

    # Sanitize name for filenames
    safe_name = name.replace(" ", "_").lower()
    safe_name = "".join(c for c in safe_name if c.isalnum() or c == "_")

    private_path = Path(f"{safe_name}_private.pem")
    public_path = Path(f"{safe_name}_public.pem")

    # Write files
    private_path.write_text(private_pem)
    public_path.write_text(public_pem)

    # Print summary
    print("\n" + "=" * 70)
    print("✅ ECP Keypair Generated Successfully")
    print("=" * 70)
    print()
    print(f"📁 Private key:  {private_path}")
    print(f"   ⚠️  KEEP THIS FILE SECRET! Never share it!")
    print()
    print(f"📁 Public key:   {public_path}")
    print(f"   Upload this to the diploma-verify platform")
    print()
    print(f"🔑 Algorithm:    {algorithm}")
    print(f"📌 Fingerprint:  {fingerprint}")
    print(f"   (Shorter: {fingerprint[:16]}...)")
    print()
    print("-" * 70)
    print("NEXT STEPS:")
    print("-" * 70)
    print()
    print("1️⃣  Register the public key on the platform:")
    print()
    print("   curl -X POST http://localhost:8000/api/auth/ecp/keys \\")
    print("     -H 'Authorization: Bearer YOUR_JWT_TOKEN' \\")
    print("     -H 'Content-Type: application/json' \\")
    print("     -d '{")
    print(f'       "key_name": "{name}",')
    print(f'       "algorithm": "{algorithm}",')
    with open(public_path) as f:
        pub_key = f.read()
    pub_key_escaped = pub_key.replace('"', '\\"').replace("\n", "\\n")
    print(f'       "public_key_pem": "{pub_key_escaped}"')
    print("     }'")
    print()
    print()
    print("2️⃣  To sign a challenge:")
    print()
    if algorithm == "RS256":
        print(f"   openssl dgst -sha256 -sign {safe_name}_private.pem \\")
        print(f"     -out signature.bin challenge.txt")
        print(f"   base64 signature.bin")
    else:  # ES256
        print(f"   openssl dgst -sha256 -sign {safe_name}_private.pem \\")
        print(f"     -out signature.bin challenge.txt")
        print(f"   base64 signature.bin")
    print()
    print("-" * 70)
    print()


def main():
    parser = argparse.ArgumentParser(
        description="Generate ECP keypair for diploma-verify platform",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  python generate_ecp_keys.py --algorithm RS256 --name "МГУ основной ключ"
  python generate_ecp_keys.py --algorithm ES256 --name "Diasoft"
        """,
    )

    parser.add_argument(
        "--algorithm",
        choices=["RS256", "ES256"],
        default="RS256",
        help="Cryptographic algorithm (default: RS256)",
    )
    parser.add_argument(
        "--name",
        default="my_ecp_key",
        help="Key name/description (default: my_ecp_key)",
    )

    args = parser.parse_args()

    print(f"\n🔐 Generating {args.algorithm} keypair...")
    print(f"   This may take a few seconds...\n")

    if args.algorithm == "RS256":
        print("   (Generating RSA-2048 key)")
        key = generate_rsa_keypair()
    else:
        print("   (Generating ECDSA P-256 key)")
        key = generate_ec_keypair()

    save_keypair(key, args.name, args.algorithm)


if __name__ == "__main__":
    main()
