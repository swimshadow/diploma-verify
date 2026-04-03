"""
Utility functions for ECP (Electronic Signature) operations
"""

import hashlib
from typing import Literal

from cryptography.hazmat.primitives import hashes, serialization
from cryptography.hazmat.primitives.asymmetric import ec, padding, rsa
from cryptography.exceptions import InvalidSignature


def calculate_fingerprint(public_key_pem: str) -> str:
    """
    Calculate SHA-256 fingerprint of a public key (PEM format).
    
    Args:
        public_key_pem: Public key in PEM format (string)
        
    Returns:
        Hex string of SHA-256 hash (64 characters)
    """
    fingerprint = hashlib.sha256(public_key_pem.encode()).hexdigest()
    return fingerprint


def parse_public_key(
    public_key_pem: str,
    algorithm: Literal["RS256", "ES256"],
):
    """
    Parse and validate a public key in PEM format.
    
    Args:
        public_key_pem: Public key in PEM format (string)
        algorithm: Either "RS256" (RSA) or "ES256" (ECDSA)
        
    Returns:
        Parsed public key object
        
    Raises:
        ValueError: If key format is invalid or mismatched algorithm
    """
    try:
        public_key = serialization.load_pem_public_key(
            public_key_pem.encode()
        )
    except Exception as e:
        raise ValueError(f"Failed to parse public key: {str(e)}")

    # Validate algorithm matches key type
    if algorithm == "RS256":
        if not isinstance(public_key, rsa.RSAPublicKey):
            raise ValueError(
                f"Expected RSA key for {algorithm}, got {type(public_key).__name__}"
            )
        # Check key size is at least 2048 bits
        if public_key.key_size < 2048:
            raise ValueError(f"RSA key must be at least 2048 bits")
    elif algorithm == "ES256":
        if not isinstance(public_key, ec.EllipticCurvePublicKey):
            raise ValueError(
                f"Expected EC key for {algorithm}, got {type(public_key).__name__}"
            )
        # Check it's a P-256 curve
        if not isinstance(public_key.curve, ec.SECP256R1):
            raise ValueError(
                f"EC key must use SECP256R1 (P-256) curve, got {public_key.curve.name}"
            )

    return public_key


def verify_signature(
    challenge: str,
    signature: bytes,
    public_key_pem: str,
    algorithm: Literal["RS256", "ES256"],
) -> bool:
    """
    Verify a signature of a challenge string using a public key.
    
    Args:
        challenge: The challenge string that was signed
        signature: The signature bytes (raw format, not base64)
        public_key_pem: Public key in PEM format
        algorithm: Either "RS256" (RSA) or "ES256" (ECDSA)
        
    Returns:
        True if signature is valid
        
    Raises:
        InvalidSignature: If signature verification fails
    """
    # Parse public key
    public_key = parse_public_key(public_key_pem, algorithm)

    # Verify based on algorithm
    challenge_bytes = challenge.encode()

    try:
        if algorithm == "RS256":
            public_key.verify(
                signature,
                challenge_bytes,
                padding.PKCS1v15(),
                hashes.SHA256(),
            )
        elif algorithm == "ES256":
            public_key.verify(
                signature,
                challenge_bytes,
                ec.ECDSA(hashes.SHA256()),
            )
        return True
    except InvalidSignature as e:
        raise InvalidSignature(f"Signature verification failed")
