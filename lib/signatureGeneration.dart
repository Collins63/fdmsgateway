import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:asn1lib/asn1lib.dart';
import 'package:pointycastle/export.dart';

class PemSigner {
  /// Securely extract and decode only the Base64 section of the PEM
  static Uint8List _extractDerFromPem(String pemFilePath) {
    final lines = File(pemFilePath).readAsLinesSync();
    final keyLines = <String>[];
    bool inKey = false;

    for (var line in lines) {
      if (line.startsWith('-----BEGIN')) {
        inKey = true;
        continue; // skip BEGIN line
      }
      if (line.startsWith('-----END')) {
        break; // stop at END line
      }
      if (inKey) {
        keyLines.add(line.trim());
      }
    }

    if (keyLines.isEmpty) {
      throw FormatException("No key block found in PEM file.");
    }

    final base64Str = keyLines.join('');
    return base64.decode(base64Str);
  }

  /// Loads an RSA private key from a PEM file
  static RSAPrivateKey loadPrivateKey(String pemFilePath) {
    final derBytes = _extractDerFromPem(pemFilePath);
    final parser = ASN1Parser(derBytes);
    final topLevel = parser.nextObject() as ASN1Sequence;

    ASN1Sequence privateKeySeq;

    // PKCS#8: PrivateKeyInfo => [version, algo, OCTET STRING]
    if (topLevel.elements!.length == 3 &&
        topLevel.elements![2] is ASN1OctetString) {
      final innerBytes =
          (topLevel.elements![2] as ASN1OctetString).valueBytes()!;
      final innerParser = ASN1Parser(innerBytes);
      privateKeySeq = innerParser.nextObject() as ASN1Sequence;
    } else {
      // PKCS#1: already the key
      privateKeySeq = topLevel;
    }

    final modulus =
        (privateKeySeq.elements![1] as ASN1Integer).valueAsBigInteger!;
    final privateExponent =
        (privateKeySeq.elements![3] as ASN1Integer).valueAsBigInteger!;
    final p = (privateKeySeq.elements![4] as ASN1Integer).valueAsBigInteger!;
    final q = (privateKeySeq.elements![5] as ASN1Integer).valueAsBigInteger!;

    return RSAPrivateKey(modulus, privateExponent, p, q);
  }

  /// Signs data and returns signature info: MD5 hex, Base64, and MD5 first 16 chars
  static Map<String, String> signDataWithMd5({
    required String data,
    required String privateKeyPath,
  }) {
    final privateKey = loadPrivateKey(privateKeyPath);
    final signer = Signer('SHA-256/RSA');
    signer.init(true, PrivateKeyParameter<RSAPrivateKey>(privateKey));

    final dataBytes = Uint8List.fromList(utf8.encode(data));
    final signature =
        signer.generateSignature(dataBytes) as RSASignature;

    final signedBytes = signature.bytes;

    // Compute MD5 hash
    final md5 = Digest("MD5");
    final digest = md5.process(signedBytes);

    final hexDigest = digest.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    final base64Signature = base64Encode(signedBytes);
    final first16Chars = hexDigest.substring(0, 16);

    return {
      "receiptDeviceSignature_signature_hex": hexDigest,
      "receiptDeviceSignature_signature": base64Signature,
      "receiptDeviceSignature_signature_md5_first16": first16Chars,
    };
  }
}
