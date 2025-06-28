import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:fdmsgateway/common/button.dart';
import 'package:fdmsgateway/database.dart';
import 'package:fdmsgateway/fiscalization/get_status.dart';
import 'package:fdmsgateway/fiscalization/openDay.dart';
import 'package:fdmsgateway/fiscalization/ping.dart';
import 'package:fdmsgateway/fiscalization/sslContextualization.dart';
import 'package:fdmsgateway/fiscalization/submitReceipts.dart';
import 'package:fdmsgateway/fiscalization/submittedReceipts.dart';
import 'package:fdmsgateway/forms/companyDetails.dart';
import 'package:fdmsgateway/signatureGeneration.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:pdf/pdf.dart';
import 'package:pdf_text/pdf_text.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:path/path.dart' as path;
import 'package:watcher/watcher.dart';
import 'package:pdf/widgets.dart' as pw;

void main() {

  sqfliteFfiInit(); 
  databaseFactory = databaseFactoryFfi;
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }
  bool isRunning = false;
  bool isProcessing = false;
  final Directory inputFolder = Directory(r'C:\Fiscal\Input');
  final Directory signedFolder = Directory(r'C:\Fiscal\Signed');
  DatabaseHelper dbHelper =  DatabaseHelper();

  StreamSubscription<WatchEvent>? inputSub;
  StreamSubscription<WatchEvent>? signedSub;
  final List<String> logs = [];
  double salesAmountwithTax =0.0;
  List<Map<String, dynamic>> receiptItems = [];
    bool _isSubmitting = false;
  DateTime? currentDateTime;
  final pdf = pw.Document();
  final paidKey = GlobalKey<FormState>();
  bool isActve = true;
  double? defaultRate;
  int currentFiscal = 0;
  String? transactionCurrency; 

  double totalAmount = 0.0; 
  double taxAmount = 0.0;
  String? generatedJson;
  String? fiscalResponse;
  double taxPercent = 0.0 ;
  String? taxCode;

  String? encodedSignature;
  String? encodedHash;
  String? signature64 ;
  String? signatureMD5 ;
  int deviceID = 25792;
  String genericzimraqrurl = "https://fdmstest.zimra.co.zw/";
  List<Map<String, dynamic>> receiptsPending= [];
  List<Map<String, dynamic>> receiptsSubmitted= [];
  List<Map<String , dynamic>> allReceipts=[];
  List<Map<String,dynamic>> dayReceiptCounter = [];
    String? receiptDeviceSignature_signature_hex ;
  String? first16Chars;
  String? receiptDeviceSignature_signature;
  List<Map<String, dynamic>> selectedCustomer =[];
  String? currentInvoiceNumber;
  String? currentReceiptGlobalNo;
  String? currentUrl;
  String? currentDayNo;
  String? tradeName;
  String? taxPayerTIN;
  String? taxPayerVatNumber;
  String? serialNo;
  String? modelName;
  int receiptCounter = 0;
  int receiptsSubmittedToFDMS =0;
  int receiptsPendingSubmission =0;




  @override
  void initState() {
    super.initState();
    getTaxPayerDetails();
    getlatestFiscalDay();
    fetchDayReceiptCounter();
    fetchReceiptsPending();
    fetchReceiptsSubmitted();
  }


  ///=================================FDMS FUNCTIOMNS============================================
  ///
  Future<void> fetchReceiptsPending() async {
    List<Map<String, dynamic>> data = await dbHelper.getReceiptsPending();
    setState(() {
      receiptsPending = data;
    });
  }
  Future <void> fetchReceiptsSubmitted() async{
    List<Map<String ,dynamic>> data  = await dbHelper.getSubmittedReceipts();
    setState(() {
      receiptsSubmitted = data;
    });
  }
  Future <void> fetchAllReceipts() async{
    List<Map<String ,dynamic>> data  = await dbHelper.getAllReceipts();
    setState(() {
      allReceipts = data;
    });
  }
  Future<void> fetchDayReceiptCounter() async {
    int latestFiscDay = await dbHelper.getlatestFiscalDay();
    setState(() {
      currentFiscal = latestFiscDay;
    });
    List<Map<String, dynamic>> data = await dbHelper.getReceiptsSubmittedToday(currentFiscal);
    setState(() {
      dayReceiptCounter = data;
    });
  }

  ///MANUAL OPENDAY
  Future<String> openDayManual() async {
  final dbHelper = DatabaseHelper();
  final previousData = await dbHelper.getPreviousReceiptData();
  final previousFiscalDayNo = await dbHelper.getPreviousFiscalDayNo();
  final taxIDSetting = await getConfig();

  int fiscalDayNo = (previousData["receiptCounter"] == 0 &&
          previousData["receiptGlobalNo"] == 0)
      ? 1
      : previousFiscalDayNo + 1;

  String iso8601 = DateFormat("yyyy-MM-dd'T'HH:mm:ss").format(DateTime.now());

  String openDayRequest = jsonEncode({
    "fiscalDayNo": fiscalDayNo,
    "fiscalDayOpened": iso8601,
    "taxID": taxIDSetting,
  });

  print("Open Day Request JSON: $openDayRequest");

  SSLContextProvider sslContextProvider = SSLContextProvider();
  SecurityContext securityContext = await sslContextProvider.createSSLContext();
  final client = HttpClient(context: securityContext)
  ..badCertificateCallback = (cert , host , port) => true;

  final ioClient = IOClient(client);

  try {
    final response = await ioClient.post(
      Uri.parse("https://fdmsapitest.zimra.co.zw/Device/v1/$deviceID/OpenDay"), // Update this URL
      headers: {
        "Content-Type": "application/json",
        "DeviceModelName": "Server",
        "DeviceModelVersion": "v1"
      },
      body: openDayRequest,
    );
    if (response.statusCode == 200) {
      print("Open Day posted successfully!");
      await dbHelper.insertOpenDay(fiscalDayNo, "unprocessed", iso8601);
      return "Open Day Successfully Recorded!";
    } else {
      print("Failed to post Open Day: ${response.body}");
      return "Failed to post Open Day";
    }
  } catch (e) {
    print("Error sending request: $e");
    return "Connection error";
  }
}

Future<String> getConfig() async {
  String apiEndpointGetConfig = "https://fdmsapitest.zimra.co.zw/Device/v1/$deviceID/GetConfig"; // Replace with actual API endpoint
  String responseMessage = "There was no response from the server. Check your connection !!";
  //final securityContext = await createSSLContext(); // Your working method
  SSLContextProvider sslContextProvider = SSLContextProvider();
  SecurityContext securityContext = await sslContextProvider.createSSLContext();
  final client = HttpClient(context: securityContext)
  ..badCertificateCallback = (cert , host , port) => true;
  try {
    // final uri = Uri.parse(apiEndpointGetConfig);

    // final response = await http.get(
    //   uri,
    //   headers: {
    //     'Content-Type': 'application/json',
    //     'DeviceModelName': 'Server', // Replace with actual model
    //     'DeviceModelVersion': 'v1' // Replace with actual version
    //   },
    // );
    final request = await client.getUrl(Uri.parse(apiEndpointGetConfig));

    request.headers.set(HttpHeaders.contentTypeHeader, 'application/json');
    request.headers.set('DeviceModelName', 'Server');
    request.headers.set('DeviceModelVersion', 'v1');

    final response = await request.close();
    final responseBody = await response.transform(utf8.decoder).join();

    if (response.statusCode == 200) {
      print("Get Config request sent successfully :)");
      print(responseBody);

      Map<String, dynamic> jsonResponse = jsonDecode(responseBody);

      // Extract data from JSON
      String taxPayerName = jsonResponse["taxPayerName"];
    String taxPayerTIN = jsonResponse["taxPayerTIN"]; // Keep as String
    String vatNumber = jsonResponse["vatNumber"]; // Keep as String
    String deviceSerialNo = jsonResponse["deviceSerialNo"];
    String deviceBranchName = jsonResponse["deviceBranchName"];

      // Extract address details
    Map<String, dynamic> deviceBranchAddress = jsonResponse["deviceBranchAddress"];
    String province = deviceBranchAddress["province"];
    String street = deviceBranchAddress["street"];
    String houseNo = deviceBranchAddress["houseNo"];
    String city = deviceBranchAddress["city"];

      // Extract contact details
    Map<String, dynamic> deviceBranchContacts = jsonResponse["deviceBranchContacts"];
    String phoneNo = deviceBranchContacts["phoneNo"];
    String email = deviceBranchContacts["email"];

     // Other device details
    String deviceOperatingMode = jsonResponse["deviceOperatingMode"];
    int taxPayerDayMaxHrs = jsonResponse["taxPayerDayMaxHrs"]; // Already an int
    String certificateValidTill = jsonResponse["certificateValidTill"];
    String qrUrl = jsonResponse["qrUrl"];
    int taxpayerDayEndNotificationHrs = jsonResponse["taxpayerDayEndNotificationHrs"]; // Already an int
    String operationID = jsonResponse["operationID"];
    
      // Extract applicable taxes
      List<dynamic> applicableTaxes = jsonResponse["applicableTaxes"];
      Map<String, int> taxIDs = {};

      for (var tax in applicableTaxes) {
        String taxName = tax["taxName"];
        int taxID = int.tryParse(tax["taxID"].toString()) ?? 0; 

        if (taxName == "Standard rated 15%") {
          taxIDs["VAT15"] = taxID;
        } else if (taxName == "Zero rated 0%" || taxName == "Zero rate 0%") {
          taxIDs["Zero"] = taxID;
        } else if (taxName == "Exempt") {
          taxIDs["Exempt"] = taxID;
        } else if (taxName == "Non-VAT Withholding Tax") {
          taxIDs["WT"] = taxID;
        }
      }

      // Store tax details in SQLite database
      DatabaseHelper dbHelper = DatabaseHelper();
      await dbHelper.updateDatabase(taxIDs);

      responseMessage = """
        taxPayerName: $taxPayerName
        taxPayerTIN: $taxPayerTIN
        vatNumber: $vatNumber
        deviceSerialNo: $deviceSerialNo
        deviceBranchName: $deviceBranchName
        Address: $houseNo $street, $city, $province
        Contacts: Phone - $phoneNo, Email - $email
        Operating Mode: $deviceOperatingMode
        Max Hrs: $taxPayerDayMaxHrs
        Certificate Valid Till: $certificateValidTill
        QR URL: $qrUrl
        Notification Hrs: $taxpayerDayEndNotificationHrs
        Operation ID: $operationID
        Taxes: ${taxIDs.entries.map((e) => '${e.key}: ${e.value}').join(', ')}
      """;

      print("Response received: $responseMessage");

      Get.snackbar("Zimra Response", responseMessage , 
      icon:const Icon(Icons.message),
      colorText: Colors.white,
      backgroundColor: Colors.green,
      snackPosition: SnackPosition.TOP
      );

    } else {
      print("Failed to get config. Status code: ${response.statusCode}");
      Get.snackbar("Zimra Response", "Failed to get config. Status code: ${response.statusCode}" , 
      icon:const Icon(Icons.message),
      colorText: Colors.white,
      backgroundColor: Colors.red,
      snackPosition: SnackPosition.TOP
      );
    }
  } catch (e) {
    print("Error getting config: $e");
    Get.snackbar("Zimra Response", "Error getting config: $e" , 
      icon:const Icon(Icons.message),
      colorText: Colors.white,
      backgroundColor: Colors.red,
      snackPosition: SnackPosition.TOP
      );

  }

  return responseMessage;
}


  ///GETSTATUS
  
  Future<void> getStatus() async {
    String apiEndpointGetStatus =
      "https://fdmsapitest.zimra.co.zw/Device/v1/$deviceID/GetStatus";
    const String deviceModelName = "Server";
    const String deviceModelVersion = "v1";

    SSLContextProvider sslContextProvider = SSLContextProvider();
    SecurityContext securityContext = await sslContextProvider.createSSLContext();

    final String response = await GetStatus.getStatus(
      apiEndpointGetStatus: apiEndpointGetStatus,
      deviceModelName: deviceModelName,
      deviceModelVersion: deviceModelVersion,
      securityContext: securityContext,
    );
    //print("Response: \n$response");
    Get.snackbar(
      "Zimra Response", "$response",
      snackPosition: SnackPosition.TOP,
      colorText: Colors.white,
      backgroundColor: Colors.green,
      icon: const Icon(Icons.message, color: Colors.white),
    );
  }



  Future<String> ping() async {
  String apiEndpointPing =
      "https://fdmsapitest.zimra.co.zw/Device/v1/$deviceID/Ping";
  const String deviceModelName = "Server";
  const String deviceModelVersion = "v1"; 

  SSLContextProvider sslContextProvider = SSLContextProvider();
  SecurityContext securityContext = await sslContextProvider.createSSLContext();

  // Call the Ping function
  final String response = await PingService.ping(
    apiEndpointPing: apiEndpointPing,
    deviceModelName: deviceModelName,
    deviceModelVersion: deviceModelVersion,
    securityContext: securityContext,
  );

  //print("Response: \n$response");
  Get.snackbar(
      "Zimra Response", "$response",
      snackPosition: SnackPosition.TOP,
      colorText: Colors.white,
      backgroundColor: Colors.green,
      icon: const Icon(Icons.message, color: Colors.white),
    );
  return response;
}
  Future<String> submitUnsubmittedReceipts(DatabaseHelper dbHelper) async {
  String sql = "SELECT * FROM submittedReceipts WHERE StatustoFDMS = 'NotSubmitted'";
  int resubmittedCount = 0;

  // String pingResponse = await ping();
  String pingResponse = "200";

  if (pingResponse == "200") {
    try {
      print("entered submit missing");
    // Get the database instance
    final db = await dbHelper.initDB();
    String apiEndpointSubmitReceipt =
      "https://fdmsapitest.zimra.co.zw/Device/v1/$deviceID/SubmitReceipt";
    const String deviceModelName = "Server";
    const String deviceModelVersion = "v1"; 
    SSLContextProvider sslContextProvider = SSLContextProvider();
    SecurityContext securityContext = await sslContextProvider.createSSLContext();
    // Retrieve unsubmitted receipts
    //List<Map<String, dynamic>> receipts = await db.rawQuery(sql);
    List<Map<String, dynamic>> receipts = await dbHelper.getReceiptsNotSubmitted();
    print(receipts);
    File file = File("/storage/emulated/0/Pulse/Configurations/unsubmittedReceipts.txt");
    await file.writeAsString(receipts.toString());

    for (var row in receipts) {
      print("submitting receipts");
      //UnsubmittedReceipt receipt = UnsubmittedReceipt.fromMap(row);
      final String unsubmittedJsonBody = row["receiptJsonbody"];
      final int receiptGlobalNo = row["receiptGlobalNo"];
      print("unsubmittedJsonBody: $unsubmittedJsonBody");
      // Submit the receipt via HTTP
      Map<String, dynamic> submitResponse = await SubmitReceipts.submitReceipts(
        apiEndpointSubmitReceipt: apiEndpointSubmitReceipt,
        deviceModelName: deviceModelName,
        deviceModelVersion: deviceModelVersion, 
        securityContext: securityContext,
        receiptjsonBody: unsubmittedJsonBody,
      );
      Map<String, dynamic> responseBody = jsonDecode(submitResponse["responseBody"]);
      int statusCode = submitResponse["statusCode"];
      print("server response is $submitResponse");

      if (statusCode == 200) {
        String submitReceiptServerresponseJson = responseBody.toString();
        // Parse the server response
        int receiptID = responseBody['receiptID'] ?? 0;
        String receiptServerSignature = responseBody['receiptServerSignature']?['signature'].toString() ?? "";

        print("receiptID: $receiptID");
        print("receiptServerSignature: $receiptServerSignature");

        // Update database record
        String updateSql = '''
          UPDATE SubmittedReceipts 
          SET receiptID = ?, receiptServerSignature = ?, submitReceiptServerResponseJSON = ?, StatustoFDMS = 'Submitted' 
          WHERE receiptGlobalNo = ?
        ''';

        await db.rawUpdate(updateSql, [
          receiptID,
          receiptServerSignature,
          submitReceiptServerresponseJson,
          //receipt.receiptGlobalNo
          receiptGlobalNo
        ]);

        resubmittedCount++;
      }
      else{
        Get.snackbar("Response message", "$submitResponse",
          snackPosition: SnackPosition.TOP,
          colorText: Colors.white,
          backgroundColor: Colors.green,
          icon: const Icon(Icons.message, color: Colors.white),
        );
      }
    }
  } catch (e) {
    print("Error: $e");
  }
  Get.snackbar("Submit Successs", "The number of receipts resubmitted is: $resubmittedCount"
  , snackPosition: SnackPosition.TOP,
      colorText: Colors.white,
      backgroundColor: Colors.green,
      icon: const Icon(Icons.message, color: Colors.white),
  );
  return "The number of receipts resubmitted is: $resubmittedCount";
  }
  Get.snackbar("No Submission", "Failed to ping the server. Check your connection!"
  , snackPosition: SnackPosition.TOP,
      colorText: Colors.black,
      backgroundColor: Colors.amber,
      icon: const Icon(Icons.message, color: Colors.black),
  );
  return "Failed to ping the server. Check your connection!";

}
Future<int> getlatestFiscalDay() async {
  int latestFiscDay = await dbHelper.getlatestFiscalDay();
  setState(() {
    currentFiscal = latestFiscDay;
  });
  return latestFiscDay;
}

  
  ///==================================END FDMS FUNCTIONS========================================
  ///
  ///
  

  void startEngine() {
    totalAmount = 0.0;
    taxAmount = 0.0;
    receiptItems.clear();
    if (isRunning) return;
    setState(() => isRunning = true);
    print("🟢 Engine Started");

    final inputWatcher = DirectoryWatcher(inputFolder.path);
    final signedWatcher = DirectoryWatcher(signedFolder.path);

    inputSub = inputWatcher.events.listen((event) async {
      if (event.type == ChangeType.ADD && event.path.toLowerCase().endsWith('.pdf')) {
        await processNext();
      }
    });

    signedSub = signedWatcher.events.listen((event) async {
      if (event.type == ChangeType.ADD && event.path.toLowerCase().endsWith('.pdf')) {
        await processNext();
      }
    });

    // Start immediately if any files exist
    processNext();
  }

   void killEngine() {
    setState(() => isRunning = false);
    print("🔴 Engine Stopped");

    inputSub?.cancel();
    signedSub?.cancel();
  }

  Future<void> stampInvoice({
    required File pdfFile,
    required String dayNo,
    required String receiptGlobalNo,
    required String signature,
  }) async {
    final uri = Uri.parse("http://localhost:5000/stamp_invoice");
    final request = http.MultipartRequest('POST', uri)
      ..fields['day_no'] = dayNo
      ..fields['receipt_global_no'] = receiptGlobalNo
      ..fields['signature'] = signature
      ..files.add(await http.MultipartFile.fromPath('file', pdfFile.path));

    final response = await request.send();

    if (response.statusCode == 200) {
      // Save or open the stamped PDF
      final bytes = await response.stream.toBytes();
      final file = File('C:/Fiscal/Done/stamped_invoice$receiptGlobalNo.pdf');
      await file.writeAsBytes(bytes);
      print("Stamped invoice saved at: ${file.path}");
    } else {
      print("Error stamping invoice: ${response.statusCode}");
    }
  }

  //Process next PDF file
  Map<String, dynamic> invoiceDetails = {};
  Future<void> processNext() async {
    if (!isRunning || isProcessing) return;

    final files = inputFolder
        .listSync()
        .whereType<File>()
        .where((f) => f.path.toLowerCase().endsWith('.pdf'))
        .toList();

    if (files.isEmpty) {
      print("📭 No more PDFs to process.");
      return;
    }

    isProcessing = true;
    final file = files.first;
    print("📤 Uploading: ${path.basename(file.path)}");

    try {
      final uri = Uri.parse("http://localhost:5000/extract_invoice");
      final request = http.MultipartRequest('POST', uri)
        ..files.add(await http.MultipartFile.fromPath('file', file.path));

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      if (response.statusCode == 200) {
        print("✅ Extracted invoice");
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        final List<dynamic> tableData = responseData['line_items'];
        final Map<String, dynamic> invoiceDetailsInner = responseData['invoice_details'];
        setState(() {
          invoiceDetails = invoiceDetailsInner;
          transactionCurrency = invoiceDetailsInner['currency'];
          currentInvoiceNumber = invoiceDetailsInner['invoice_number'];
          selectedCustomer.add({
            'customerVAT': invoiceDetailsInner['buyer_vat'] ?? 'Unknown',
            'customerTIN': invoiceDetailsInner['buyer_tin'] ?? 'Unknown',
            //'customerAddress': invoiceDetailsInner['customerAddress'] ?? 'Unknown',
            'customerPhone': invoiceDetailsInner['phone'] ?? 'Unknown',
            'customerEmail': invoiceDetailsInner['email'] ?? 'Unknown',
          });
        });
        print(tableData);
        print("adding items");
        await addItem(tableData);
        print("done with adding items");
        await generateFiscalJSON();
        await submitReceipt();
        //await stampInvoice(pdfFile: file, dayNo: currentDayNo.toString(), receiptGlobalNo: currentReceiptGlobalNo.toString(), signature: currentUrl.toString());
        final destPath = path.join(signedFolder.path, path.basename(file.path));
        await file.rename(destPath);
        print("📁 Moved to Signed: ${path.basename(destPath)}");
      } else {
        print("❌ Server Error: ${response.statusCode}");
      }
    } catch (e) {
      print("❌ Exception: $e");
    } finally {
      isProcessing = false;
    }
  }

  Future<void> uploadAndExtractTable(File pdfFile) async {
    final uri = Uri.parse("http://localhost:5000/extract_invoice");
    final request = http.MultipartRequest('POST', uri)
      ..files.add(await http.MultipartFile.fromPath('file', pdfFile.path));

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      //final List<dynamic> tableData = jsonDecode(response.body);
      final Map<String, dynamic> responseData = jsonDecode(response.body);
      final List<dynamic> tableData = responseData['line_items'];
      final Map<String, dynamic> invoiceDetails = responseData['invoice_details'];
      print("Invoice Details: $invoiceDetails");
      for (final row in tableData) {
        print("Row: $row");
      }
    } else {
      print("Error: ${response.body}");
    }
  }

  //add to receipt items
Future<void> addItem(List<dynamic> tableData) async {
  final List<Map<String, dynamic>> lineItems = tableData.cast<Map<String, dynamic>>();
  final newItems = <Map<String, dynamic>>[];

  for (var item in lineItems) {
    // Validate required fields
    if (item['Description'] == null || item['Unit Price'] == null || item['Qty'] == null || item['Sub Total'] == null) {
      continue;
    }

    double unitPrice = (item['Unit Price'] is String)
        ? double.tryParse(item['Unit Price']) ?? 0
        : (item['Unit Price'] ?? 0).toDouble();

    int quantity = (item['Qty'] is String)
        ? int.tryParse(item['Qty']) ?? 1
        : (item['Qty'] ?? 1);

    double totalPrice = double.tryParse(item['Sub Total'].toString()) ?? 0;
    double itemTotal = totalPrice / quantity;

    double itemTax;
    int taxID;
    String taxCode;
    String taxPercent;
    


    final vatValue = item['Total VAT'];
    if (vatValue != null && vatValue != '-' && double.tryParse(vatValue) != null && double.parse(vatValue) > 0.0) {
      taxID = 3;
      taxPercent = "15.00";
      taxCode = "C";
      itemTax = totalPrice / 1.15;
      salesAmountwithTax += totalPrice;
    } else if (vatValue == '-') {
      taxID = 1;
      taxPercent = "0";
      taxCode = "A";
      itemTax = 0;
    } else {
      taxID = 2;
      taxPercent = "0.00";
      taxCode = "B";
      itemTax = totalPrice * double.parse(taxPercent);
    }

    newItems.add({
      'productName': item['Description'] ?? item['Product Code'] ?? 'Unknown',
      'price': itemTotal,
      'quantity': quantity,
      'total': totalPrice,
      'taxID': taxID,
      'taxPercent': taxPercent,
      'taxCode': taxCode,
    });
    totalAmount += totalPrice;
    taxAmount += itemTax;
  }

    setState(() {
    receiptItems.addAll(newItems);
  });
  

  print("receiptItems: $receiptItems");
}

  String generateTaxSummary(List<dynamic> receiptItems) {
  Map<int, Map<String, dynamic>> taxGroups = {};

  for (var item in receiptItems) {
    int taxID = item["taxID"];
    double total = item["total"];
    String taxCode = item["taxCode"];
    
    // Preserve empty taxPercent when missing
    String? taxPercentValue = item["taxPercent"];
    double taxPercent = (taxPercentValue == null || taxPercentValue == "")
        ? 0.0
        : double.parse(taxPercentValue);

    if (!taxGroups.containsKey(taxID)) {
      taxGroups[taxID] = {
        "taxCode": taxCode,
        "taxPercent": taxPercentValue == null || taxPercentValue == "" 
          ? 0
          : (taxPercent % 1 == 0 
              ? "${taxPercent.toInt()}.00" 
              : taxPercent.toStringAsFixed(2)),
        "taxAmount": 0.0,
        "salesAmountWithTax": 0.0
      };
    }
    double taxAmount ;
    if(taxPercentValue=="15.00"){
      taxAmount = total - double.parse((total / 1.15).toString());
    }else{
      taxAmount = total * 0;
    }
    taxGroups[taxID]!["taxAmount"] += taxAmount;
    taxGroups[taxID]!["salesAmountWithTax"] += total;
  }

  List<Map<String, dynamic>> sortedTaxes = taxGroups.values.toList()
    ..sort((a, b) => a["taxCode"].compareTo(b["taxCode"]));

  // return sortedTaxes.map((tax) {
  //   return "${tax["taxCode"]}${tax["taxPercent"]}${(tax["taxAmount"] * 100).round().toString()}${(tax["salesAmountWithTax"] * 100).round().toString()}";
  // }).join("");
  return sortedTaxes.map((tax) {
    final taxCode = tax["taxCode"];
    final taxPercent = tax["taxPercent"];
    final taxAmount = (tax["taxAmount"] * 100).round().toString();
    final salesAmount = (tax["salesAmountWithTax"] * 100).round().toString();

    // Omit taxPercent for taxCode A
    if (taxCode == "A") {
      return "$taxCode$taxAmount$salesAmount";
    }

    return "$taxCode$taxPercent$taxAmount$salesAmount";
  }).join("");
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
  
  

  //use raw string
  useRawString(String date) async {
    int latestFiscDay = await dbHelper.getlatestFiscalDay();
    setState(() {
      currentFiscal = latestFiscDay;
    });
    List<Map<String, dynamic>> data = await dbHelper.getReceiptsSubmittedToday(currentFiscal);
    setState(() {
      dayReceiptCounter = data;
    });
    int latestReceiptGlobalNo = await dbHelper.getLatestReceiptGlobalNo();
    int currentGlobalNo = latestReceiptGlobalNo + 1;
    String getLatestReceiptHash = await dbHelper.getLatestReceiptHash();
    if (dayReceiptCounter.isEmpty){
      String receiptString = generateReceiptString(
        deviceID:deviceID,
        receiptType: "FISCALINVOICE",
        receiptCurrency: transactionCurrency.toString(),
        receiptGlobalNo: currentGlobalNo,
        receiptDate: date,
        receiptTotal: totalAmount,
        receiptItems: receiptItems,
        getPreviousReceiptHash:"",
      );
      print("Concatenated Receipt String: $receiptString");
      return receiptString;
    }else{
      String receiptString = generateReceiptString(
        deviceID: deviceID,
        receiptType: "FISCALINVOICE",
        receiptCurrency: transactionCurrency.toString(),
        receiptGlobalNo: currentGlobalNo,
        receiptDate: date,
        receiptTotal: totalAmount,
        receiptItems: receiptItems,
        getPreviousReceiptHash: getLatestReceiptHash,
      );
      print("Concatenated Receipt String: $receiptString");
      return receiptString;
    }
    
  
  }

  //gnerate receipt taxes
    List<Map<String, dynamic>> generateReceiptTaxes(List<dynamic> receiptItems) {
  Map<int, Map<String, dynamic>> taxGroups = {}; // Store tax summaries

  for (var item in receiptItems) {
    int taxID = item["taxID"];
    String taxPercent = item["taxPercent"];
    double total = item["total"];

    if (!taxGroups.containsKey(taxID)) {
      taxGroups[taxID] = {
        "taxID": taxID,
        "taxPercent": taxPercent.isEmpty ? "" : taxPercent, // Leave blank if empty
        "taxCode": item["taxCode"],
        "taxAmount": 0.0,
        "salesAmountWithTax": 0.0
      };
    }

    // Calculate tax amount
    //double taxAmount = taxPercent.isEmpty
      //  ? 0.00  // If taxPercent is empty, set taxAmount to 0.00
       // : total - double.parse((total / 1.15).toString());
    double taxAmount;
    if(taxPercent.isEmpty){
      taxAmount = 0.00;
    }
    else if(taxPercent=="15.00"){
      taxAmount = total - double.parse((total / 1.15).toString());
    }
    else{
      taxAmount = total * 0;
    }
    taxGroups[taxID]!["taxAmount"] += taxAmount;
    taxGroups[taxID]!["salesAmountWithTax"] += total;
  }

  // Convert map to list and round values
  // return taxGroups.values.map((tax) {
  //   return {
  //     "taxID": tax["taxID"],
  //     "taxPercent": tax["taxPercent"],  // Blank if empty
  //     "taxCode": tax["taxCode"],
  //     "taxAmount": tax["taxAmount"].toStringAsFixed(2), // Rounded to 2 decimal places
  //     "salesAmountWithTax": tax["salesAmountWithTax"],
  //   };
  // }).toList();
  return taxGroups.values.map((tax) {
    final taxID = tax["taxID"];
    final taxCode = tax["taxCode"];
    final isGroupA = (taxCode == "A" || taxID == 1);

    return {
      "taxID": taxID.toString(),
      if (!isGroupA) "taxPercent": tax["taxPercent"], // Omit if group A
      "taxCode": taxCode,
      "taxAmount": isGroupA ? "0" : tax["taxAmount"].toStringAsFixed(2),
      "salesAmountWithTax": tax["salesAmountWithTax"],
    };
  }).toList();
}

  //generate hash
  generateHash(String date) async {
    String saleCurrency = transactionCurrency.toString();
    int latestFiscDay = await dbHelper.getlatestFiscalDay();
    String receiptString;
    setState(() {
      currentFiscal = latestFiscDay;
    });
    List<Map<String, dynamic>> data = await dbHelper.getReceiptsSubmittedToday(currentFiscal);
    setState(() {
      dayReceiptCounter = data;
    });
    int latestReceiptGlobalNo = await dbHelper.getLatestReceiptGlobalNo();
    int currentGlobalNo = latestReceiptGlobalNo + 1;
    String getLatestReceiptHash = await dbHelper.getLatestReceiptHash();
    if(dayReceiptCounter.isEmpty){
      receiptString = generateReceiptString(
        deviceID: deviceID,
        receiptType: "FISCALINVOICE",
        receiptCurrency: saleCurrency,
        receiptGlobalNo: currentGlobalNo,
        receiptDate: date,
        receiptTotal: totalAmount,
        receiptItems: receiptItems,
        getPreviousReceiptHash:"",
      );
      print("Concatenated Receipt String:$receiptString");
      receiptString.trim();
    }
    else{
      receiptString = generateReceiptString(
        deviceID: deviceID,
        receiptType: "FISCALINVOICE",
        receiptCurrency: saleCurrency,
        receiptGlobalNo: currentGlobalNo,
        receiptDate: date,
        receiptTotal: totalAmount,
        receiptItems: receiptItems,
        getPreviousReceiptHash: getLatestReceiptHash,
      );
    }
  print("Concatenated Receipt String:$receiptString");
  receiptString.trim();
    var bytes = utf8.encode(receiptString);
    var digest = sha256.convert(bytes);
    final hash = base64.encode(digest.bytes);
    print(hash);
    return hash;
  }
  
  
  //generate fiscal JSON

  Future<String> generateFiscalJSON() async {
    String encodedreceiptDeviceSignature_signature;
  try {
    print("Entered generateFiscalJSON");

    // Ensure signing does not fail
    DateTime now = DateTime.now();
    String formattedDate = DateFormat("yyyy-MM-ddTHH:mm:ss").format(now);
    try {
      print("Using raw string for signing");
      String data = await useRawString(formattedDate);
      //List<String>? signature = await getSignatureSignature(data);
      //receiptDeviceSignature_signature_hex = signature?[0];
      //receiptDeviceSignature_signature  = signature?[1];
      final Map<String, String> signedDataMap  = PemSigner.signDataWithMd5(
        data: data,
        privateKeyPath: 'assets/private_key.pem',
      );
      //final Map<String, dynamic> signedDataMap = jsonDecode(signedDataString);
      receiptDeviceSignature_signature_hex = signedDataMap["receiptDeviceSignature_signature_hex"] ?? "";
      receiptDeviceSignature_signature = signedDataMap["receiptDeviceSignature_signature"] ?? "";
      first16Chars = signedDataMap["receiptDeviceSignature_signature_md5_first16"] ?? "";
      
    } catch (e) {
      Get.snackbar("Signing Error", "$e", snackPosition: SnackPosition.TOP);
      return "{}";
    }
    print("Signed Data: $receiptDeviceSignature_signature");
    if (receiptItems.isEmpty) {
      print("Receipt items are empty, returning empty JSON.");
      return "{}";
    }

    int fiscalDayNo = await dbHelper.getlatestFiscalDay();
    int nextReceiptCounter = await dbHelper.getNextReceiptCounter(fiscalDayNo);
   

    int nextInvoice = await dbHelper.getNextInvoiceId();
    int getNextReceiptGlobalNo = await dbHelper.getLatestReceiptGlobalNo();

    // Ensure tax calculation does not fail
    List<Map<String, dynamic>> taxes = [];
    try {
      taxes = generateReceiptTaxes(receiptItems);
    } catch (e) {
      Get.snackbar("Tax Calculation Error", "$e", snackPosition: SnackPosition.TOP);
      return "{}";
    }



    String hash = await generateHash(formattedDate);
    print("Hash generated successfully");

    Map<String, dynamic> jsonData = {
      "receipt": {
        "receiptLines": receiptItems.asMap().entries.map((entry) {
          int index = entry.key + 1;
          var item = entry.value;
          if (item["taxPercent"] != "0"){
            return {
            "receiptLineNo": "$index",
            "receiptLineHSCode": "04021099",
            "receiptLinePrice": item["price"].toStringAsFixed(2),
            "taxID": item["taxID"],
            //if  "taxPercent":  item["taxPercent"] == "" ? 0.00  : double.parse(item["taxPercent"].toString()).toStringAsFixed(2),
            "taxPercent": item["taxPercent"],   
            "receiptLineType": "Sale",
            "receiptLineQuantity": item["quantity"].toString(),
            "taxCode": item["taxCode"],
            "receiptLineTotal": item["total"].toStringAsFixed(2),
            "receiptLineName": item["productName"],
          };
          }
          else{
            return {
            "receiptLineNo": "$index",
            "receiptLineHSCode": "99001000",
            "receiptLinePrice": item["price"].toStringAsFixed(2),
            "taxID": item["taxID"], 
            "receiptLineType": "Sale",
            "receiptLineQuantity": item["quantity"].toString(),
            "taxCode": item["taxCode"],
            "receiptLineTotal": item["total"].toStringAsFixed(2),
            "receiptLineName": item["productName"],
          };
          }
          
          // Only add taxPercent if it's not an empty strin
        }).toList(),
        "receiptType": "FISCALINVOICE",
        "receiptGlobalNo": getNextReceiptGlobalNo + 1,
        "receiptCurrency": transactionCurrency.toString(),
        "receiptPrintForm": "InvoiceA4",
        "receiptDate": formattedDate,
        "receiptPayments": [
          {"moneyTypeCode": "Cash", "paymentAmount": totalAmount.toStringAsFixed(2)}
        ],
        "receiptCounter": nextReceiptCounter,
        "receiptTaxes": taxes,
        "receiptDeviceSignature": {
          "signature": receiptDeviceSignature_signature,
          "hash": hash,
        },
        "buyerData": {
          "VATNumber": selectedCustomer.isNotEmpty? selectedCustomer[0]['customerVAT'].toString() : "123456789",
          "buyerTradeName":  "Rivosect Investments",
          "buyerTIN": selectedCustomer.isNotEmpty? selectedCustomer[0]['customerTIN'].toString() : "0000000000",
          "buyerRegisterName": "Rivosect Investments",   
        },
        "receiptTotal": totalAmount.toStringAsFixed(2),
        "receiptLinesTaxInclusive": true,
        "invoiceNo": currentInvoiceNumber.toString() ,
      }
    };

    // Ensure JSON encoding does not fail
    final jsonString;
    try {
      jsonString = jsonEncode(jsonData);
    } catch (e) {
      Get.snackbar("JSON Encoding Error", "$e", snackPosition: SnackPosition.TOP);
      return "{}";
    }
    // String getLatestReceiptHash = await dbHelper.getLatestReceiptHash();

    // String verifyString =  buildZimraCanonicalString(receipt: jsonData, deviceID: "25395", previousReceiptHash: getLatestReceiptHash);
    // verifyString.trim();
    // var bytes = utf8.encode(verifyString);
    // var digest = sha256.convert(bytes);
    // final hashVerify = base64.encode(digest.bytes);
    // verifySignatureAndShowResult2(context, filePath, password, hashVerify, receiptDeviceSignature_signature.toString());
    File file = File("C:/FMDS-gateway/Files/jsonFile.txt");
    await file.writeAsString(jsonString);
    print("Generated JSON: $jsonString");
    return jsonString;

  } catch (e) {
    Get.snackbar(
      "Error Message",
      "$e",
      snackPosition: SnackPosition.TOP,
      colorText: Colors.white,
      backgroundColor: Colors.red,
      icon: const Icon(Icons.error),
      shouldIconPulse: true
    );
    return "{}"; // Ensure the function always returns something
  }
}


//print invoice
Future<void> generateInvoiceFromJson(Map<String , dynamic> receiptJson , String qrUrl) async{
    final receipt = receiptJson['receipt'];
    final supplier = {
      'name': 'Pulse Pvt Ltd',
      'tin': '1234567890',
      'address': '16 Ganges Road, Harare',
      'phone': '+263 77 14172798',
    };
    final customer = {
      'name': receipt['buyerData']?['buyerTradeName'] ?? 'Customer',
      'tin': receipt['buyerData']?['buyerTIN'] ?? '0000000000',
      'vat': receipt['buyerData']?['VATNumber'] ?? '00000000',
    };
    String receiptGlobalNo = receipt['receiptGlobalNo'].toString().padLeft(10, '0');
    String deviceID = "25395";
    final receiptLines = List<Map<String, dynamic>>.from(receipt['receiptLines']);
    final receiptTaxes = List<Map<String, dynamic>>.from(receipt['receiptTaxes']);
    final receiptTotal = double.tryParse(receipt['receiptTotal'].toString()) ?? 0.0;
    final signature = receipt['receiptDeviceSignature']?['signature'] ?? 'No Signature';
    double totalTax = 0.0;
    for (var tax in receiptTaxes) {
      totalTax += double.tryParse(tax['taxAmount'].toString()) ?? 0.0;
    }
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('FISCAL TAX INVOICE', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
                      pw.SizedBox(height: 8),
                      pw.Text('Supplier: ${supplier['name']}'),
                      pw.Text('TIN: ${supplier['tin']}'),
                      pw.Text('Address: ${supplier['address']}'),
                      pw.Text('Phone: ${supplier['phone']}'),
                    ],
                  ),
                  pw.Container(
                    width: 100,
                    height: 100,
                    child: pw.BarcodeWidget(
                      barcode: pw.Barcode.qrCode(),
                      data: qrUrl,
                      drawText: false,
                    ),
                  ),
                ],
              ),
              pw.Divider(
                thickness: 5,
                color: PdfColors.blue,
              ),
              pw.SizedBox(height: 8),
              pw.Text('Customer: ${customer['name']}'),
              pw.Text('TIN: ${customer['tin']}'),
              pw.Text('VAT: ${customer['vat']}'),
              pw.SizedBox(height: 12),
              pw.Text('Invoice No: ${receipt['invoiceNo']}', style: pw.TextStyle(fontSize: 14)),
              pw.Text('Date: ${receipt['receiptDate']}'),
              pw.SizedBox(height: 12),
              pw.Table.fromTextArray(
                headers: ['No.', 'Item', 'Qty', 'Unit Price', 'Tax %', 'Total'],
                data: receiptLines.map((item) {
                  return [
                    item['receiptLineNo'],
                    item['receiptLineName'],
                    item['receiptLineQuantity'].toString(),
                    '\$${item['receiptLinePrice'].toString()}',
                    '${item['taxPercent'] ?? '0'}%',
                    '\$${item['receiptLineTotal'].toString()}',
                  ];
                }).toList(),
              ),
              pw.Divider(),
              pw.SizedBox(height: 10),
              pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text('Total Tax: \$${totalTax.toStringAsFixed(2)}'),
                    pw.Text('Grand Total: \$${receiptTotal.toStringAsFixed(2)}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),
              pw.Text('Signature Hash:', style: pw.TextStyle(fontSize: 10)),
              pw.Text(receipt['receiptDeviceSignature']?['hash'] ?? '', style: pw.TextStyle(fontSize: 8)),
              pw.Text("You can verify this manually at:", style: pw.TextStyle(fontSize: 10)),
              pw.Text("https://fdmstest.zimra.co.zw", style: pw.TextStyle(fontSize: 8, color: PdfColors.blue)),
              pw.Text("Device ID: $deviceID", style: pw.TextStyle(fontSize: 10)),
              pw.Text("Receipt Global No: $receiptGlobalNo", style: pw.TextStyle(fontSize: 10)),
            ],
          );
        },
      ),
    );
    try {
      final directory = Directory(r'C:\Fiscal\Done');

      // Create the directory if it doesn't exist
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }
      final filePath = p.join(directory.path, 'invoice_${receipt['invoiceNo']}.pdf');
      final file = File(filePath);
      await file.writeAsBytes(await pdf.save());

      print('Invoice saved at ${file.path}');
    } catch (e) {
      print('Error saving invoice: $e');
    }
  }


//submit receipts
Future<void> submitReceipt() async {
    String jsonString  = await generateFiscalJSON();
    final receiptJson = jsonEncode(jsonString);
    Get.snackbar(
      'Fiscalizing',
      'Processing',
      icon: const Icon(Icons.check, color: Colors.white,),
      colorText: Colors.white,
      backgroundColor: Colors.green,
      snackPosition: SnackPosition.TOP,
      showProgressIndicator: true,
    );
    String pingResponse = await ping();
    final receiptJsonbody = await generateFiscalJSON();
    
    Map<String, dynamic> jsonData = jsonDecode(receiptJsonbody);
    final db=DatabaseHelper();
      String moneyType = (jsonData['receipt']['receiptPayments'] != null && jsonData['receipt']['receiptPayments'].isNotEmpty)
      ? jsonData['receipt']['receiptPayments'][0]['moneyTypeCode'].toString()
      : "";
      print("your date is ${jsonData['receipt']?['receiptDate']}");
      print("your invoice number is ${jsonData['receipt']?['invoiceNo']?.toString()}");
      print(jsonData);
      int fiscalDayNo = await db.getlatestFiscalDay();
      print("fiscal day no is $fiscalDayNo");
      double receiptTotal = double.parse(jsonData['receipt']?['receiptTotal']?.toString() ?? "0");
      String formattedDeviceID = deviceID.toString().padLeft(10, '0');
      String parseDate = jsonData['receipt']?['receiptDate'];
      DateTime formattedDate = DateTime.parse(parseDate);
      String formattedDateStr = DateFormat("ddMMyyyy").format(formattedDate);
      int latestReceiptGlobalNo = await db.getLatestReceiptGlobalNo();
      
      int currentGlobalNo = latestReceiptGlobalNo + 1;
      String formatedReceiptGlobalNo = currentGlobalNo.toString().padLeft(10, '0');
      String receiptDeviceSignatureSignatureHex= receiptDeviceSignature_signature_hex.toString();
      //String receiptQrData = getReceiptQrData(receiptDeviceSignatureSignatureHex);
      String receiptQrData = first16Chars.toString();
      String qrurl = genericzimraqrurl + formattedDeviceID + formattedDateStr + formatedReceiptGlobalNo + receiptQrData;

      setState(() {
        currentUrl = qrurl;
        currentDayNo = fiscalDayNo.toString();
        currentReceiptGlobalNo = currentGlobalNo.toString();
      });
      print("QR URL: $qrurl");
      
    if(pingResponse=="200"){
      String apiEndpointSubmitReceipt =
      "https://fdmsapitest.zimra.co.zw/Device/v1/$deviceID/SubmitReceipt";
      const String deviceModelName = "Server";
      const String deviceModelVersion = "v1";  

      SSLContextProvider sslContextProvider = SSLContextProvider();
      SecurityContext securityContext = await sslContextProvider.createSSLContext();
      
      print(receiptJsonbody);
      // Call the Ping function
      Map<String, dynamic> response = await SubmitReceipts.submitReceipts(
        apiEndpointSubmitReceipt: apiEndpointSubmitReceipt,
        deviceModelName: deviceModelName,
        deviceModelVersion: deviceModelVersion,
        securityContext: securityContext,
        receiptjsonBody:receiptJsonbody,
      );
      print(response);
      Get.snackbar(
        "Zimra Response", "$response",
        snackPosition: SnackPosition.TOP,
        colorText: Colors.white,
        backgroundColor: Colors.green,
        icon: const Icon(Icons.message, color: Colors.white),
      );
      Map<String, dynamic> responseBody = jsonDecode(response["responseBody"]);
      int statusCode = response["statusCode"];
      String submitReceiptServerresponseJson = responseBody.toString();
      print("your server server response is $submitReceiptServerresponseJson");
      if (statusCode == 200) {
      print("Code is 200, saving receipt...");

      // Check if 'receiptPayments' is non-empty before accessing index 0
      
      try {
        final Database dbinit = await dbHelper.initDB();
        await dbinit.insert('submittedReceipts',
          {
            'receiptCounter': jsonData['receipt']?['receiptCounter'] ?? 0,
            'FiscalDayNo' : fiscalDayNo,
            'InvoiceNo': int.tryParse(jsonData['receipt']?['invoiceNo']?.toString() ?? "0") ?? 0,
            'receiptID': responseBody['receiptID'] ?? 0,
            'receiptType': jsonData['receipt']['receiptType']?.toString() ?? "",
            'receiptCurrency': jsonData['receipt']?['receiptCurrency']?.toString() ?? "",
            'moneyType': moneyType,
            'receiptDate': jsonData['receipt']?['receiptDate']?.toString() ?? "",
            'receiptTime': jsonData['receipt']?['receiptDate']?.toString() ?? "",
            'receiptTotal': receiptTotal,
            'taxCode': "C",
            'taxPercent': "15.00",
            'taxAmount': taxAmount ?? 0,
            'SalesAmountwithTax': salesAmountwithTax ?? 0,
            'receiptHash': jsonData['receipt']?['receiptDeviceSignature']?['hash']?.toString() ?? "",
            'receiptJsonbody': receiptJsonbody?.toString() ?? "",
            'StatustoFDMS': "Submitted".toString(),
            'qrurl': qrurl,
            'receiptServerSignature': responseBody['receiptServerSignature']?['signature'].toString() ?? "",
            'submitReceiptServerresponseJSON': "$submitReceiptServerresponseJson" ?? "noresponse",
            'Total15VAT': '0.0',
            'TotalNonVAT': 0.0,
            'TotalExempt': 0.0,
            'TotalWT': 0.0,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
         //print("Data inserted successfully!");
        generateInvoiceFromJson(jsonData, qrurl);
        //print58mmAdvanced(jsonData, qrurl);
        receiptItems.clear();
        totalAmount = 0.0;
        taxAmount = 0.0;
        currentReceiptGlobalNo = "";
        currentUrl = "";
        currentDayNo = "";
      } catch (e) {
        Get.snackbar(" Db Error",
          "$e",
          snackPosition: SnackPosition.TOP,
          colorText: Colors.white,
          backgroundColor: Colors.red,
          icon: const Icon(Icons.error),
        );
    }
    
  }
  else{
    try {
        final Database dbinit = await dbHelper.initDB();
        await dbinit.insert('submittedReceipts',
          {
            'receiptCounter': jsonData['receipt']?['receiptCounter'] ?? 0,
            'FiscalDayNo' : fiscalDayNo,
            'InvoiceNo': int.tryParse(jsonData['receipt']?['invoiceNo']?.toString() ?? "0") ?? 0,
            'receiptID': 0,
            'receiptType': jsonData['receipt']['receiptType']?.toString() ?? "",
            'receiptCurrency': jsonData['receipt']?['receiptCurrency']?.toString() ?? "",
            'moneyType': moneyType,
            'receiptDate': jsonData['receipt']?['receiptDate']?.toString() ?? "",
            'receiptTime': jsonData['receipt']?['receiptDate']?.toString() ?? "",
            'receiptTotal': receiptTotal,
            'taxCode': "C",
            'taxPercent': "15.00",
            'taxAmount': taxAmount ?? 0,
            'SalesAmountwithTax': salesAmountwithTax ?? 0,
            'receiptHash': jsonData['receipt']?['receiptDeviceSignature']?['hash']?.toString() ?? "",
            'receiptJsonbody': receiptJsonbody?.toString() ?? "",
            'StatustoFDMS': "NOTSubmitted".toString(),
            'qrurl': qrurl,
            'receiptServerSignature':"",
            'submitReceiptServerresponseJSON':"noresponse",
            'Total15VAT': '0.0',
            'TotalNonVAT': 0.0,
            'TotalExempt': 0.0,
            'TotalWT': 0.0,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
         print("Data inserted successfully!");
         totalAmount = 0.0;
          taxAmount = 0.0;
         generateInvoiceFromJson(jsonData, qrurl);
         //print58mmAdvanced(jsonData, qrurl);
         receiptItems.clear();
      } catch (e) {
        Get.snackbar("Db Error",
          "$e",
          snackPosition: SnackPosition.TOP,
          colorText: Colors.white,
          backgroundColor: Colors.red,
          icon: const Icon(Icons.error),
        );
    }
  }
    }
    else{
      
      try {
        final Database dbinit = await dbHelper.initDB();
        await dbinit.insert('submittedReceipts',
          {
            'receiptCounter': jsonData['receipt']?['receiptCounter'] ?? 0,
            'FiscalDayNo' : fiscalDayNo,
            'InvoiceNo': int.tryParse(jsonData['receipt']?['invoiceNo']?.toString() ?? "0") ?? 0,
            'receiptID': 0,
            'receiptType': jsonData['receipt']['receiptType']?.toString() ?? "",
            'receiptCurrency': jsonData['receipt']?['receiptCurrency']?.toString() ?? "",
            'moneyType': moneyType,
            'receiptDate': jsonData['receipt']?['receiptDate']?.toString() ?? "",
            'receiptTime': jsonData['receipt']?['receiptDate']?.toString() ?? "",
            'receiptTotal': receiptTotal,
            'taxCode': "C",
            'taxPercent': "15.00",
            'taxAmount': taxAmount ?? 0,
            'SalesAmountwithTax': salesAmountwithTax ?? 0,
            'receiptHash': jsonData['receipt']?['receiptDeviceSignature']?['hash']?.toString() ?? "",
            'receiptJsonbody': receiptJsonbody?.toString() ?? "",
            'StatustoFDMS': "NOTSubmitted".toString(),
            'qrurl': qrurl,
            'receiptServerSignature':"",
            'submitReceiptServerresponseJSON':"noresponse",
            'Total15VAT': '0.0',
            'TotalNonVAT': 0.0,
            'TotalExempt': 0.0,
            'TotalWT': 0.0,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
         print("Data inserted successfully!");
         totalAmount = 0.0;
          taxAmount = 0.0;
         generateInvoiceFromJson(jsonData, qrurl);
         //print58mmAdvanced(jsonData, qrurl);
         receiptItems.clear();
      } catch (e) {
        Get.snackbar("DB error Error",
          "$e",
          snackPosition: SnackPosition.TOP,
          colorText: Colors.white,
          backgroundColor: Colors.red,
          icon: const Icon(Icons.error),
        );
    }
    }
  }

  void getTaxPayerDetails() async{
    final data = await dbHelper.getTaxPayerDetails();
    setState(() {
      tradeName = data[0]['taxPayerName'];
      taxPayerTIN = data[0]['taxPayerTin'];
      taxPayerVatNumber = data[0]['taxPayerVatNumber'];
      deviceID = data[0]['deviceID'];
      serialNo = data[0]['deviceModelName'];
    });
  }

  @override
  void dispose() {
    inputSub?.cancel();
    signedSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.green,
        title: const Text("FDMS GateWay", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            Container(
              height: 100,
              width: 150,
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/zimra.PNG'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal:20.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    height: 450,
                    width: 600,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: Colors.white,
                      boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3), // shadow color
                              spreadRadius: 4, // how much the shadow spreads
                              blurRadius: 10,  // how soft the shadow is
                              offset: Offset(0, 6), // horizontal and vertical offset
                            ),
                          ],
                    ),
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 20, horizontal: 20),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("TAXPAYER NAME: $tradeName " , style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),),
                          SizedBox(height: 10,),
                          Text("TAXPAYER TIN: $taxPayerTIN" , style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),),
                          SizedBox(height: 10,),
                          Text("VAT NUMBER: $taxPayerVatNumber" , style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),),
                          SizedBox(height: 10,),
                          Text("DEVICE ID: $deviceID" , style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),),
                          SizedBox(height: 10,),
                          Text("SERIAL NO: $serialNo" , style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),),
                          SizedBox(height: 10,),
                          Text("MODEL NAME: Server" , style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),),
                          SizedBox(height: 10,),
                          Text("FISCAL DAY: $currentFiscal" , style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),),
                          SizedBox(height: 10,),
                          Text("CLOSEDAY TIME: " , style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),),
                          SizedBox(height: 10,),
                          Text("RECEIPT COUNTER: ${dayReceiptCounter.length}" , style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),),
                          SizedBox(height: 10,),
                          Text("RECEIPTS SUBMITTED:${receiptsSubmitted.length} " , style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),),
                          SizedBox(height: 10,),
                          Text("RECEIPTS PENDING: ${receiptsPending.length}" , style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),),
                        ],
                      ),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Container(
                        height: 450,
                        width: 200,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.only(topLeft: Radius.circular(20), bottomLeft: Radius.circular(20)),
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3), // shadow color
                              spreadRadius: 4, // how much the shadow spreads
                              blurRadius: 10,  // how soft the shadow is
                              offset: const Offset(0, 6), // horizontal and vertical offset
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 10),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              const Text("Engine Options", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),),
                              const SizedBox(height: 20,),
                              CustomOutlineBtn(
                                icon:const  Icon(Icons.broadcast_on_home_outlined, color: Colors.white,),
                                text: isRunning? "Processing" :"Start Engine", 
                                color: Colors.green,
                                color2: Colors.green,
                                height: 50,
                                onTap: isRunning ? null : startEngine,
                              ),
                              const SizedBox(height: 20,),
                              CustomOutlineBtn(
                                icon:const  Icon(Icons.stop, color: Colors.white,),
                                text: "Stop Engine", 
                                color: Colors.red,
                                color2: Colors.red,
                                height: 50,
                                onTap: isRunning ? killEngine : null ,
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(width: 3,),
                      Container(
                        height: 450,
                        width: 397,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.only(topRight: Radius.circular(20), bottomRight: Radius.circular(20)),
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3), // shadow color
                              spreadRadius: 4, // how much the shadow spreads
                              blurRadius: 10,  // how soft the shadow is
                              offset: Offset(0, 6), // horizontal and vertical offset
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 20, horizontal: 20),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              const Text("FDMS Options", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),),
                              const SizedBox(height: 20,),
                              CustomOutlineBtn(
                                icon:const  Icon(Icons.open_in_browser, color: Colors.white,),
                                text: "Manual Open Day", 
                                color: Colors.green,
                                color2: Colors.green,
                                height: 50,
                                onTap: (){
                                  //extractFromFiscalFolder();
                                  openDayManual();
                                },
                              ),
                              const SizedBox(height: 10,),
                              CustomOutlineBtn(
                                icon: const Icon(Icons.settings_accessibility, color: Colors.white,),
                                text: "Device Configuration", 
                                color: Colors.green,
                                color2: Colors.green,
                                height: 50,
                                onTap: (){
                                  //extractFromFiscalFolder();
                                  getConfig();
                                },
                              ),
                              const SizedBox(height: 10,),
                              CustomOutlineBtn(
                                icon:const Icon(Icons.satellite_alt, color: Colors.white,),
                                text: "Device Status", 
                                color: Colors.green,
                                color2: Colors.green,
                                height: 50,
                                onTap: (){
                                  //extractFromFiscalFolder();
                                  getStatus();
                                },
                              ),
                              const SizedBox(height: 10,),
                              CustomOutlineBtn(
                                icon: const Icon(Icons.pinch, color: Colors.white,),
                                text: "Ping", 
                                color: Colors.green,
                                color2: Colors.green,
                                height: 50,
                                onTap: (){
                                  //extractFromFiscalFolder();
                                  ping();
                                },
                              ),
                              const SizedBox(height: 10,),
                              CustomOutlineBtn(
                                icon: const Icon(Icons.send, color: Colors.white,),
                                text: "Submit Missing Receipts", 
                                color: Colors.green,
                                color2: Colors.green,
                                height: 50,
                                onTap: (){
                                  //extractFromFiscalFolder()
                                  submitUnsubmittedReceipts(dbHelper);
                                },
                              ),
                              const SizedBox(height: 10,),
                              CustomOutlineBtn(
                                icon:const Icon(Icons.close, color: Colors.white,),
                                text: "Close Day", 
                                color: Colors.green,
                                color2: Colors.green,
                                height: 50,
                                onTap: (){
                                  //extractFromFiscalFolder();
                                  
                                },
                              ),
                            ],
                          ),
                        ),
                      )
                    ],
                  ),
                ],
              ),
            )
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed:(){
          showModalBottomSheet(
            context: context,
            builder: (BuildContext context) {
              return Wrap(
                children: [
                  ListTile(
                    leading: Icon(Icons.business),
                    title:const Text('Company Details'),
                    onTap: () {
                      Get.to(()=> const CompanydetailsPage());
                      // handle tap
                    },
                  ),
                  ListTile(
                    leading: Icon(Icons.calendar_month_outlined),
                    title:const Text('Open Day Table'),
                    onTap: () {
                      Get.to(()=> const OpenDayPage());
                    },
                  ),
                  ListTile(
                    leading: Icon(Icons.send_and_archive_outlined),
                    title: Text('Submitted Receipts'),
                    onTap: () {
                      Get.to(()=> const Submittedreceipts());
                      // handle tap
                    },
                  ),
                  // ListTile(
                  //   leading: Icon(Icons.photo_library),
                  //   title: Text('Choose from Gallery'),
                  //   onTap: () {
                  //     Navigator.pop(context);
                  //     // handle tap
                  //   },
                  // ),
                  ListTile(
                    leading: Icon(Icons.cancel),
                    title: Text('Cancel'),
                    onTap: () => Navigator.pop(context),
                  ),
                  const SizedBox(height: 20,)
                ],
              );
            },
          );
        } ,
        tooltip: 'Menu',
        child: const Icon(Icons.settings),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}

class InvoiceData {
  final String customerName;
  final String invoiceNumber;
  final String date;
  final String currency;
  final String tax;
  final String total;
  final String tin;
  final String vat;
  final List<Map<String, dynamic>> products;
  final String phone;

  InvoiceData({
    required this.customerName,
    required this.invoiceNumber,
    required this.date,
    required this.currency,
    required this.tax,
    required this.total,
    required this.tin,
    required this.vat,
    required this.products,
    required this.phone,
  });

  @override
  String toString() {
    return '''
Customer: $customerName
Invoice #: $invoiceNumber
Date: $date
Currency: $currency
Tax: $tax
Total: $total
TIN: $tin
VAT: $vat
Phone: $phone
Products:
${products.map((p) => '  - ${p['desc']} x${p['qty']} @ ${p['unit']} = ${p['total']}').join('\n')}
''';
  }
}


