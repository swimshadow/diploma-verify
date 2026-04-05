import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:pointycastle/asn1.dart';
import 'package:pointycastle/export.dart';

/// Сервис для работы с электронной подписью (ЭП / ECP).
/// Поддерживает RSA-2048 SHA-256 подпись и верификацию.
class EcpService {
  /// Парсит RSA приватный ключ из PEM-строки.
  RSAPrivateKey parsePrivateKeyPem(String pem) {
    final rows = pem
        .split('\n')
        .where((r) => !r.startsWith('-----'))
        .join();
    final der = base64Decode(rows);
    final parser = ASN1Parser(Uint8List.fromList(der));
    final seq = parser.nextObject() as ASN1Sequence;
    final objects = seq.elements!;

    final modulus = (objects[1] as ASN1Integer).integer!;
    final pubExp = (objects[2] as ASN1Integer).integer!;
    final privExp = (objects[3] as ASN1Integer).integer!;
    final p = (objects[4] as ASN1Integer).integer!;
    final q = (objects[5] as ASN1Integer).integer!;

    return RSAPrivateKey(modulus, privExp, p, q, pubExp);
  }

  /// Извлекает публичный ключ из приватного.
  RSAPublicKey extractPublicKey(RSAPrivateKey privateKey) {
    return RSAPublicKey(privateKey.modulus!, privateKey.publicExponent!);
  }

  /// Экспортирует публичный ключ в PEM-формат (PKCS#8 SubjectPublicKeyInfo).
  String publicKeyToPem(RSAPublicKey publicKey) {
    // RSAPublicKey DER: SEQUENCE { INTEGER modulus, INTEGER exponent }
    final pubKeySeq = ASN1Sequence()
      ..add(ASN1Integer(publicKey.modulus!))
      ..add(ASN1Integer(publicKey.publicExponent!));
    final pubKeyDer = pubKeySeq.encode();

    // AlgorithmIdentifier: SEQUENCE { OID rsaEncryption, NULL }
    final algorithmSeq = ASN1Sequence()
      ..add(ASN1ObjectIdentifier([1, 2, 840, 113549, 1, 1, 1]))
      ..add(ASN1Null());

    // BIT STRING wrapping the public key DER
    final bitString = ASN1BitString(stringValues: Uint8List.fromList(pubKeyDer));

    // SubjectPublicKeyInfo: SEQUENCE { algorithmId, bitString }
    final topLevel = ASN1Sequence()
      ..add(algorithmSeq)
      ..add(bitString);

    return _toPem(topLevel.encode(), 'PUBLIC KEY');
  }

  /// Подписывает данные RSA-SHA256 (PKCS1v15).
  String sign(String data, RSAPrivateKey privateKey) {
    final signer = Signer('SHA-256/RSA');
    signer.init(true, PrivateKeyParameter<RSAPrivateKey>(privateKey));
    final sig = signer.generateSignature(
      Uint8List.fromList(utf8.encode(data)),
    ) as RSASignature;
    return base64Encode(sig.bytes);
  }

  /// Формирует payload для подписания одобрения организации.
  String buildApprovalPayload(String universityId) {
    final timestamp = DateTime.now().toUtc().toIso8601String();
    return 'APPROVE_ORG:$universityId:$timestamp';
  }

  /// Генерирует RSA-2048 ключевую пару.
  AsymmetricKeyPair<RSAPublicKey, RSAPrivateKey> generateKeyPair() {
    final keyGen = KeyGenerator('RSA');
    keyGen.init(ParametersWithRandom(
      RSAKeyGeneratorParameters(BigInt.parse('65537'), 2048, 64),
      _secureRandom(),
    ));
    final pair = keyGen.generateKeyPair();
    return AsymmetricKeyPair<RSAPublicKey, RSAPrivateKey>(
      pair.publicKey as RSAPublicKey,
      pair.privateKey as RSAPrivateKey,
    );
  }

  /// Экспортирует приватный ключ в PEM-формат (PKCS#1).
  String privateKeyToPem(RSAPrivateKey privateKey) {
    final seq = ASN1Sequence()
      ..add(ASN1Integer(BigInt.zero)) // version
      ..add(ASN1Integer(privateKey.modulus!))
      ..add(ASN1Integer(privateKey.publicExponent!))
      ..add(ASN1Integer(privateKey.privateExponent!))
      ..add(ASN1Integer(privateKey.p!))
      ..add(ASN1Integer(privateKey.q!))
      ..add(ASN1Integer(
          privateKey.privateExponent! % (privateKey.p! - BigInt.one)))
      ..add(ASN1Integer(
          privateKey.privateExponent! % (privateKey.q! - BigInt.one)))
      ..add(ASN1Integer(privateKey.q!.modInverse(privateKey.p!)));

    return _toPem(seq.encode(), 'RSA PRIVATE KEY');
  }

  String _toPem(Uint8List der, String label) {
    final b64 = base64Encode(der);
    final lines = <String>[];
    for (var i = 0; i < b64.length; i += 64) {
      lines.add(b64.substring(i, i + 64 > b64.length ? b64.length : i + 64));
    }
    return '-----BEGIN $label-----\n${lines.join('\n')}\n-----END $label-----';
  }

  SecureRandom _secureRandom() {
    final rng = Random.secure();
    final seed = Uint8List(32);
    for (var i = 0; i < seed.length; i++) {
      seed[i] = rng.nextInt(256);
    }
    final random = FortunaRandom();
    random.seed(KeyParameter(seed));
    return random;
  }
}
