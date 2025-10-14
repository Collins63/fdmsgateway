import 'dart:convert';
import 'dart:typed_data';
import 'package:basic_utils/basic_utils.dart';
import 'package:crypto/crypto.dart';
import 'package:fdmsgateway/database.dart';
import 'package:flutter/material.dart';
import 'package:pointycastle/export.dart';

class ValidationError{
  final String code;
  final String message;
  final String severity;

  ValidationError(this.code , this.message, this.severity);

  @override
  String toString() => "[$severity] $code: $message";

}

class ReceiptValidator{
  final Map<String, dynamic> receipt;
  final String publicKeypem;
  final previousReceiptHash;

  ReceiptValidator(this.receipt , this.publicKeypem, this.previousReceiptHash);
  ///verify RSA SHA256 signature
  bool _verifySignature(String data, String base64Signature){
    final hashBytes = sha256.convert(utf8.encode(data)).bytes;

    final publicKey = CryptoUtils.rsaPublicKeyFromPem(publicKeypem);
    final verifier = RSASigner(SHA256Digest(), '0609608648016503040201')
    ..init(false, PublicKeyParameter<RSAPublicKey>(publicKey));

    final sigBytes = base64Decode(base64Signature);
    return verifier.verifySignature(
      Uint8List.fromList(utf8.encode(data)),
      RSASignature(sigBytes),
    );
  }
  
  DatabaseHelper dbHelper = DatabaseHelper();

  Future<int> getTaxPayerDetails() async{
    final data = await dbHelper.getTaxPayerDetails();
    int deviceID  = 0;
    String deviceid = data.isNotEmpty ? data[0]['deviceID'].toString() : '';
      if(deviceid != ""){
        deviceID = int.tryParse(deviceid)!;
      }
    return deviceID;
  }
  
  String generateReceiptString({
    required int deviceID,
    required String receiptType,
    required String receiptCurrency,
    required int receiptGlobalNo,
    required String receiptDate,
    required double receiptTotal,
    required List<dynamic> receiptItems,
    required String getPreviousReceiptHash,
  }) {
    //String formattedDate = receiptDate.toIso8601String().split('.').first;
    //print("Formatted Date: $formattedDate");
    String formattedTotal = receiptTotal.toStringAsFixed(2);
    double receiptTotal_numeric = receiptTotal;
    int receiptTotal_ampl = (receiptTotal_numeric * 100).round();
    String receiptTotal_adj = receiptTotal_ampl.toString();
    String receiptTaxes = generateTaxSummary(receiptItems);

    return "$deviceID$receiptType$receiptCurrency$receiptGlobalNo$receiptDate$receiptTotal_adj$receiptTaxes$getPreviousReceiptHash";
  }
  String generateTaxSummary(List<dynamic> receiptItems) {
  Map<int, Map<String, dynamic>> taxGroups = {};

  for (var item in receiptItems) {
    int taxID = item["taxID"];
    double lineTotal =
        double.tryParse(item["receiptLineTotal"].toString()) ?? 0.0;
    String taxCode = item["taxCode"];

    // Preserve empty taxPercent when missing
    String? taxPercentValue = item["taxPercent"];
    double taxPercent = (taxPercentValue == null || taxPercentValue.isEmpty)
        ? 0.0
        : double.parse(taxPercentValue);

    if (!taxGroups.containsKey(taxID)) {
      taxGroups[taxID] = {
        "taxCode": taxCode,
        "taxPercent": (taxPercentValue == null || taxPercentValue.isEmpty)
            ? 0
            : (taxPercent % 1 == 0
                ? "${taxPercent.toInt()}.00"
                : taxPercent.toStringAsFixed(2)),
        "taxAmount": 0.0,
        "salesAmountWithTax": 0.0
      };
    }

    // Tax calculation: round to 2 decimals BEFORE accumulating
    double taxAmount = 0.0;
    if (taxPercent > 0) {
      double base = lineTotal / (1 + taxPercent / 100);
      taxAmount = lineTotal - base;
      taxAmount = double.parse(taxAmount.toStringAsFixed(2)); // ZIMRA style
    }

    taxGroups[taxID]!["taxAmount"] += taxAmount;
    taxGroups[taxID]!["salesAmountWithTax"] += lineTotal;
  }

  List<Map<String, dynamic>> sortedTaxes = taxGroups.values.toList()
    ..sort((a, b) => a["taxCode"].compareTo(b["taxCode"]));

  return sortedTaxes.map((tax) {
    final taxCode = tax["taxCode"];
    final taxPercent = tax["taxPercent"];
    final taxAmount =
        (double.parse(tax["taxAmount"].toString()) * 100).round().toString();
    final salesAmount =
        (double.parse(tax["salesAmountWithTax"].toString()) * 100)
            .round()
            .toString();

    // Omit taxPercent for exempt code "A"
    if (taxCode == "C") {
      return "$taxCode$taxAmount$salesAmount";
    }

    return "$taxCode$taxPercent$taxAmount$salesAmount";
  }).join("");
}

  Future<List<ValidationError>> validate() async{
    List<ValidationError> errors = [];
    int deviceId = await getTaxPayerDetails();
    print("lines ${receipt['receipt']['receiptLines']}");
    // --- REQUIRED FIELDS ---
    if (!receipt['receipt'].containsKey('receiptLines') || (receipt['receipt']['receiptLines'] as List).isEmpty) {
      errors.add(ValidationError("RCPT016", "No receipt lines provided", "Red"));
    }

    if (!receipt['receipt'].containsKey('receiptPayments') || (receipt['receipt']['receiptPayments'] as List).isEmpty) {
      errors.add(ValidationError("RCPT018", "No payment information provided", "Red"));
    }

    if (!receipt['receipt'].containsKey('receiptTaxes') || (receipt['receipt']['receiptTaxes'] as List).isEmpty) {
      errors.add(ValidationError("RCPT017", "No tax information provided", "Red"));
    }

    // --- RECEIPT TOTAL CHECKS ---
    double receiptTotal = double.tryParse(receipt['receipt']['receiptTotal'].toString()) ?? 0.0;

    double sumLines = 0;
    for (var line in receipt['receipt']['receiptLines']) {
      double price = double.tryParse(line['receiptLinePrice'].toString()) ?? 0.0;
      double qty = double.tryParse(line['receiptLineQuantity'].toString()) ?? 0.0;
      double total = double.tryParse(line['receiptLineTotal'].toString()) ?? 0.0;

      // RCPT024: total must equal price * quantity
      if ((price * qty).toStringAsFixed(2) != total.toStringAsFixed(2)) {
        errors.add(ValidationError("RCPT024",
            "Line ${line['receiptLineNo']} total mismatch (expected ${price * qty}, got $total)", "Red"));
      }
      sumLines += total;

      // RCPT022: Sale/Discount sign validation
      String type = line['receiptLineType'];
      if (receipt['receipt']['receiptType'] == "FISCALINVOICE" && type == "Sale" && price <= 0) {
        errors.add(ValidationError("RCPT022", "Sale price must be > 0 for invoice", "Red"));
      }
      if (receipt['receipt']['receiptType'] == "CREDITNOTE" && type == "Sale" && price >= 0) {
        errors.add(ValidationError("RCPT022", "Sale price must be < 0 for credit note", "Red"));
      }
    }
    // RCPT019: receipt total = sum of lines + taxes (if exclusive)
    bool inclusive = receipt['receipt']['receiptLinesTaxInclusive'] ?? false;
    double sumTaxes = 0;
    for (var t in receipt['receipt']['receiptTaxes']) {
      sumTaxes += double.tryParse(t['taxAmount'].toString()) ?? 0.0;
    }
    double expectedTotal = inclusive ? sumLines : sumLines + sumTaxes;
    if (receiptTotal.toStringAsFixed(2) != expectedTotal.toStringAsFixed(2)) {
      errors.add(ValidationError("RCPT019",
          "Receipt total mismatch. Expected $expectedTotal, got $receiptTotal", "Red"));
    }
    // RCPT039: payments must equal receiptTotal
    double sumPayments = 0;
    for (var p in receipt['receipt']['receiptPayments']) {
      sumPayments += double.tryParse(p['paymentAmount'].toString()) ?? 0.0;
    }
    if (sumPayments.toStringAsFixed(2) != receiptTotal.toStringAsFixed(2)) {
      errors.add(ValidationError("RCPT039",
          "Payments do not match receipt total. Expected $receiptTotal, got $sumPayments", "Red"));
    }
    // RCPT040: total must be >= 0 for invoice, <= 0 for credit note
    if (receipt['receipt']['receiptType'] == "FISCALINVOICE" && receiptTotal < 0) {
      errors.add(ValidationError("RCPT040", "Invoice total must be >= 0", "Red"));
    }
    if (receipt['receipt']['receiptType'] == "CREDITNOTE" && receiptTotal > 0) {
      errors.add(ValidationError("RCPT040", "Credit note total must be <= 0", "Red"));
    }
    try {
      // Step 1: Regenerate receipt string
      String receiptString = generateReceiptString(
        deviceID: deviceId,
        receiptType: receipt['receipt']["receiptType"],
        receiptCurrency: receipt['receipt']["receiptCurrency"],
        receiptGlobalNo: receipt['receipt']["receiptGlobalNo"],
        receiptDate: receipt['receipt']["receiptDate"],
        receiptTotal: double.parse(receipt['receipt']["receiptTotal"].toString()),
        receiptItems: receipt['receipt']["receiptLines"],
        getPreviousReceiptHash: previousReceiptHash ?? "",
      );
       // Step 2: Generate hash
      final generatedHash = base64Encode(
        sha256.convert(utf8.encode(receiptString)).bytes,
      );
      print("verified hash: $generatedHash");
      // Step 3: Extract from JSON
      final providedHash = receipt['receipt']["receiptDeviceSignature"]["hash"];
      final providedSig = receipt['receipt']["receiptDeviceSignature"]["signature"];

      // Step 4: Compare hash
      if (generatedHash != providedHash) {
        errors.add(ValidationError(
          "RCPTHash",
          "Hash mismatch. Expected $generatedHash, got $providedHash",
          "Red",
        ));
      } else {
        // Step 5: Verify signature
        final valid = _verifySignature(receiptString, providedSig);
        if (!valid) {
          errors.add(ValidationError(
            "RCPT020",
            "Invalid receipt signature",
            "Red",
          ));
        }
      }

    } catch (e) {
      errors.add(ValidationError(
        "RCPTSystemError",
        "Signature validation failed: ${e.toString()}",
        "Red",
      ));
    }
    return errors;
  }
}