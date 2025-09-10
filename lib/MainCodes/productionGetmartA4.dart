// import 'dart:async';
// import 'dart:collection';
// import 'dart:convert';
// import 'dart:io';
// import 'package:crypto/crypto.dart';
// import 'package:decimal/decimal.dart';
// import 'package:fdmsgateway/common/button.dart';
// import 'package:fdmsgateway/database.dart';
// import 'package:fdmsgateway/fiscalization/closeday.dart';
// import 'package:fdmsgateway/fiscalization/get_status.dart';
// import 'package:fdmsgateway/fiscalization/openDay.dart';
// import 'package:fdmsgateway/fiscalization/ping.dart';
// import 'package:fdmsgateway/fiscalization/sslContextualization.dart';
// import 'package:fdmsgateway/fiscalization/submitReceipts.dart';
// import 'package:fdmsgateway/fiscalization/submittedReceipts.dart';
// import 'package:fdmsgateway/forms/companyDetails.dart';
// import 'package:fdmsgateway/forms/fiscalReports.dart';
// import 'package:fdmsgateway/signatureGeneration.dart';
// import 'package:file_picker/file_picker.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:get/get.dart';
// import 'package:http/http.dart' as http;
// import 'package:http/io_client.dart';
// import 'package:intl/intl.dart';
// import 'package:path/path.dart' as p;
// import 'package:path/path.dart';
// import 'package:path_provider/path_provider.dart';
// import 'package:pdf/pdf.dart';
// import 'package:pdf_text/pdf_text.dart';
// import 'package:permission_handler/permission_handler.dart';
// import 'package:printing/printing.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:sqflite_common_ffi/sqflite_ffi.dart';
// import 'package:syncfusion_flutter_pdf/pdf.dart';
// import 'package:path/path.dart' as path;
// import 'package:watcher/watcher.dart';
// import 'package:pdf/widgets.dart' as pw;

// void main() {

//   sqfliteFfiInit(); 
//   databaseFactory = databaseFactoryFfi;
//   WidgetsFlutterBinding.ensureInitialized();
//   //_startFolderWatcher();
//   runApp(const MyApp());
// }

// class MyApp extends StatelessWidget {
//   const MyApp({super.key});

//   // This widget is the root of your application.
//   @override
//   Widget build(BuildContext context) {
//     return GetMaterialApp(
//       title: 'Flutter Demo',
//       debugShowCheckedModeBanner: false,
//       theme: ThemeData(
//         colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
//         useMaterial3: true,
//       ),
//       home: const MyHomePage(),
//     );
//   }
// }

// final Directory watchDir = Directory(r'C:\Fiscal\Done');
// final List<File> _printQueue = [];
// bool _isPrinting = false;

// void _startFolderWatcher() {
//   if (!watchDir.existsSync()) {
//     print("❌ Folder doesn't exist: ${watchDir.path}");
//     return;
//   }

//   print("👀 Watching: ${watchDir.path}");

//   watchDir.watch(events: FileSystemEvent.create).listen((event) async {
//     if (event is FileSystemCreateEvent && event.path.endsWith('.pdf')) {
//       final file = File(event.path);
//       await _waitForFileReady(file);
//       print("📄 Detected new PDF: ${file.path}");
//       _printQueue.add(file);
//       _processQueue();
//     }
//   });
// }

// Future<void> _waitForFileReady(File file) async {
//   int lastSize = -1;
//   while (true) {
//     await Future.delayed(Duration(milliseconds: 500));
//     if (!file.existsSync()) continue;
//     final currentSize = file.lengthSync();
//     if (currentSize == lastSize) break;
//     lastSize = currentSize;
//   }
// }

// void _processQueue() async {
//   if (_isPrinting || _printQueue.isEmpty) return;

//   _isPrinting = true;
//   final file = _printQueue.removeAt(0);

//   try {
//     final prefs = await SharedPreferences.getInstance();
//     final printerName = prefs.getString('preferred_printer');
//     final pdfBytes = await file.readAsBytes();

//     final printers = await Printing.listPrinters();

//     final selectedPrinter = printerName != null
//         ? printers.firstWhere(
//             (p) => p.name == printerName,
//             orElse: () => printers.first,
//           )
//         : null;

//     if (selectedPrinter == null) {
//       print("⚠️ Printer not found. Printing to default...");
//       await Printing.layoutPdf(
//         onLayout: (_) => Future.value(pdfBytes),
//         name: file.uri.pathSegments.last,
//       );
//     } else {
//       print("🖨️ Printing to: ${selectedPrinter.name}");
//       await Printing.directPrintPdf(
//         printer: selectedPrinter,
//         onLayout: (_) => Future.value(pdfBytes),
//         name: file.uri.pathSegments.last,
//       );
//     }

//     print("✅ Printed: ${file.path}");
//   } catch (e) {
//     print("❌ Print failed: $e");
//   } finally {
//     _isPrinting = false;
//     if (_printQueue.isNotEmpty) _processQueue();
//   }
// }

// class MyHomePage extends StatefulWidget {
//   const MyHomePage({super.key});

//   @override
//   State<MyHomePage> createState() => _MyHomePageState();
// }

// class _MyHomePageState extends State<MyHomePage> {
//   int _counter = 0;

//   void _incrementCounter() {
//     setState(() {
//       _counter++;
//     });
//   }
//   bool isRunning = false;
//   bool isProcessing = false;
//   final Directory inputFolder = Directory(r'C:\Fiscal\Input');
//   final Directory signedFolder = Directory(r'C:\Fiscal\Signed');
//   final Directory originalFilesFolder = Directory(r'C:\Fiscal\OriginalFiles');
//   final Directory unsignedFolder = Directory(r'C:\Fiscal\UnSigned');
//   final Directory doneFolder = Directory(r'C:\Fiscal\Done');
//   DatabaseHelper dbHelper =  DatabaseHelper();
//   StreamSubscription<WatchEvent>? inputSub;
//   StreamSubscription<WatchEvent>? signedSub;
//   final List<String> logs = [];
//   double salesAmountwithTax =0.0;
//   List<Map<String, dynamic>> receiptItems = [];
//     bool _isSubmitting = false;
//   DateTime? currentDateTime;
//   final pdf = pw.Document();
//   final paidKey = GlobalKey<FormState>();
//   bool isActve = true;
//   double? defaultRate;
//   int currentFiscal = 0;
//   String? transactionCurrency; 
//   String? dateForCreditNote;
//   double totalAmount = 0.0; 
//   double taxAmount = 0.0;
//   String? generatedJson;
//   String? fiscalResponse;
//   double taxPercent = 0.0 ;
//   String? taxCode;
//   String? encodedSignature;
//   String? encodedHash;
//   String? signature64 ;
//   String? signatureMD5 ;
//   int deviceID = 0000;
//   String genericzimraqrurl = "https://fdms.zimra.co.zw/";
//   List<Map<String, dynamic>> receiptsPending= [];
//   List<Map<String, dynamic>> receiptsSubmitted= [];
//   List<Map<String , dynamic>> allReceipts=[];
//   List<Map<String,dynamic>> dayReceiptCounter = [];
//     String? receiptDeviceSignature_signature_hex ;
//   String? first16Chars;
//   String? receiptDeviceSignature_signature;
//   List<Map<String, dynamic>> selectedCustomer =[];
//   String? currentInvoiceNumber;
//   String? currentReceiptGlobalNo;
//   String? currentUrl;
//   String? currentDayNo;
//   String? tradeName;
//   String? taxPayerTIN;
//   String? taxPayerVatNumber;
//   String? taxPayerAddress;
//   String? taxPayerEmail;
//   String? taxPayerPhone;
//   String? serialNo;
//   String? modelName;
//   int receiptCounter = 0;
//   int receiptsSubmittedToFDMS =0;
//   int receiptsPendingSubmission =0;
//   String? creditReason;
//   String? creditedInvoice;
//   int isReceipt = 0;
//   int isInvoice = 1;
//   String? currentInvoiceSubtotal;
//   String? receipttotalVat;
//   String? receiptinvoiceTotal;
//   String? paid;
//   String? change;
//   int isReceiptCreditNote = 0;
//   String? stampVerificationCode;
//   String? stampQRData;
//   String? stampDayNo;
//   String? stampReceiptGlobalNumber;

//   @override
//   void initState() {
//     super.initState();
//     getTaxPayerDetails();
//     getlatestFiscalDay();
//     fetchDayReceiptCounter();
//     fetchReceiptsPending();
//     fetchReceiptsSubmitted();
//   }


//   ///=================================FDMS FUNCTIOMNS============================================
//   ///
//   Future<void> fetchReceiptsPending() async {
//     List<Map<String, dynamic>> data = await dbHelper.getReceiptsPending();
//     setState(() {
//       receiptsPending = data;
//     });
//   }

//   Future <void> fetchReceiptsSubmitted() async{
//     List<Map<String ,dynamic>> data  = await dbHelper.getSubmittedReceipts();
//     setState(() {
//       receiptsSubmitted = data;
//     });
//   }

//   Future <void> fetchAllReceipts() async{
//     List<Map<String ,dynamic>> data  = await dbHelper.getAllReceipts();
//     setState(() {
//       allReceipts = data;
//     });
//   }

//   Future<void> fetchDayReceiptCounter() async {
//     int latestFiscDay = await dbHelper.getlatestFiscalDay();
//     setState(() {
//       currentFiscal = latestFiscDay;
//     });
//     List<Map<String, dynamic>> data = await dbHelper.getReceiptsSubmittedToday(currentFiscal);
//     setState(() {
//       dayReceiptCounter = data;
//     });
//   }

//   ///MANUAL OPENDAY
//   Future<String> openDayManual() async {
//     final dbHelper = DatabaseHelper();
//     final previousData = await dbHelper.getPreviousReceiptData();
//     final previousFiscalDayNo = await dbHelper.getPreviousFiscalDayNo();
//     final taxIDSetting = await getConfig();

//     int fiscalDayNo = (previousData["receiptCounter"] == 0 &&
//             previousData["receiptGlobalNo"] == 0)
//         ? 1
//         : previousFiscalDayNo + 1;

//     String iso8601 = DateFormat("yyyy-MM-dd'T'HH:mm:ss").format(DateTime.now());

//     String openDayRequest = jsonEncode({
//       "fiscalDayNo": fiscalDayNo,
//       "fiscalDayOpened": iso8601,
//       "taxID": taxIDSetting,
//     });

//     print("Open Day Request JSON: $openDayRequest");

//     SSLContextProvider sslContextProvider = SSLContextProvider();
//     SecurityContext securityContext = await sslContextProvider.createSSLContext();
//     final client = HttpClient(context: securityContext)
//     ..badCertificateCallback = (cert , host , port) => true;

//     final ioClient = IOClient(client);

//     try {
//       final response = await ioClient.post(
//         Uri.parse("https://fdmsapi.zimra.co.zw/Device/v1/$deviceID/OpenDay"), // Update this URL
//         headers: {
//           "Content-Type": "application/json",
//           "DeviceModelName": "Server",
//           "DeviceModelVersion": "v1"
//         },
//         body: openDayRequest,
//       );
//       if (response.statusCode == 200) {
//         print("Open Day posted successfully!");
//         await dbHelper.insertOpenDay(fiscalDayNo, "unprocessed", iso8601);
//         return "Open Day Successfully Recorded!";
//       } else {
//         print("Failed to post Open Day: ${response.body}");
//         return "Failed to post Open Day";
//       }
//     } catch (e) {
//       print("Error sending request: $e");
//       return "Connection error";
//     }
//   }

// Future<String> getConfig() async {
//   String apiEndpointGetConfig = "https://fdmsapi.zimra.co.zw/Device/v1/$deviceID/GetConfig"; // Replace with actual API endpoint
//   String responseMessage = "There was no response from the server. Check your connection !!";
//   //final securityContext = await createSSLContext(); // Your working method
//   SSLContextProvider sslContextProvider = SSLContextProvider();
//   SecurityContext securityContext = await sslContextProvider.createSSLContext();
//   final client = HttpClient(context: securityContext)
//   ..badCertificateCallback = (cert , host , port) => true;
//   try {
//     // final uri = Uri.parse(apiEndpointGetConfig);

//     // final response = await http.get(
//     //   uri,
//     //   headers: {
//     //     'Content-Type': 'application/json',
//     //     'DeviceModelName': 'Server', // Replace with actual model
//     //     'DeviceModelVersion': 'v1' // Replace with actual version
//     //   },
//     // );
//     final request = await client.getUrl(Uri.parse(apiEndpointGetConfig));

//     request.headers.set(HttpHeaders.contentTypeHeader, 'application/json');
//     request.headers.set('DeviceModelName', 'Server');
//     request.headers.set('DeviceModelVersion', 'v1');

//     final response = await request.close();
//     final responseBody = await response.transform(utf8.decoder).join();

//     if (response.statusCode == 200) {
//       print("Get Config request sent successfully :)");
//       print(responseBody);

//       Map<String, dynamic> jsonResponse = jsonDecode(responseBody);

//       // Extract data from JSON
//       String taxPayerName = jsonResponse["taxPayerName"];
//     String taxPayerTIN = jsonResponse["taxPayerTIN"]; // Keep as String
//     String vatNumber = jsonResponse["vatNumber"]; // Keep as String
//     String deviceSerialNo = jsonResponse["deviceSerialNo"];
//     String deviceBranchName = jsonResponse["deviceBranchName"];

//       // Extract address details
//     Map<String, dynamic> deviceBranchAddress = jsonResponse["deviceBranchAddress"];
//     String province = deviceBranchAddress["province"];
//     String street = deviceBranchAddress["street"];
//     String houseNo = deviceBranchAddress["houseNo"];
//     String city = deviceBranchAddress["city"];

//       // Extract contact details
//     Map<String, dynamic> deviceBranchContacts = jsonResponse["deviceBranchContacts"];
//     String phoneNo = deviceBranchContacts["phoneNo"];
//     String email = deviceBranchContacts["email"];

//      // Other device details
//     String deviceOperatingMode = jsonResponse["deviceOperatingMode"];
//     int taxPayerDayMaxHrs = jsonResponse["taxPayerDayMaxHrs"]; // Already an int
//     String certificateValidTill = jsonResponse["certificateValidTill"];
//     String qrUrl = jsonResponse["qrUrl"];
//     int taxpayerDayEndNotificationHrs = jsonResponse["taxpayerDayEndNotificationHrs"]; // Already an int
//     String operationID = jsonResponse["operationID"];
    
//       // Extract applicable taxes
//       List<dynamic> applicableTaxes = jsonResponse["applicableTaxes"];
//       Map<String, int> taxIDs = {};

//       for (var tax in applicableTaxes) {
//         String taxName = tax["taxName"];
//         int taxID = int.tryParse(tax["taxID"].toString()) ?? 0; 

//         if (taxName == "Standard rated 15%") {
//           taxIDs["VAT15"] = taxID;
//         } else if (taxName == "Zero rated 0%" || taxName == "Zero rate 0%") {
//           taxIDs["Zero"] = taxID;
//         } else if (taxName == "Exempt") {
//           taxIDs["Exempt"] = taxID;
//         } else if (taxName == "Non-VAT Withholding Tax") {
//           taxIDs["WT"] = taxID;
//         }
//       }

//       // Store tax details in SQLite database
//       DatabaseHelper dbHelper = DatabaseHelper();
//       await dbHelper.updateDatabase(taxIDs);

//       responseMessage = """
//         taxPayerName: $taxPayerName
//         taxPayerTIN: $taxPayerTIN
//         vatNumber: $vatNumber
//         deviceSerialNo: $deviceSerialNo
//         deviceBranchName: $deviceBranchName
//         Address: $houseNo $street, $city, $province
//         Contacts: Phone - $phoneNo, Email - $email
//         Operating Mode: $deviceOperatingMode
//         Max Hrs: $taxPayerDayMaxHrs
//         Certificate Valid Till: $certificateValidTill
//         QR URL: $qrUrl
//         Notification Hrs: $taxpayerDayEndNotificationHrs
//         Operation ID: $operationID
//         Taxes: ${taxIDs.entries.map((e) => '${e.key}: ${e.value}').join(', ')}
//       """;

//       print("Response received: $responseMessage");

//       Get.snackbar("Zimra Response", responseMessage , 
//       icon:const Icon(Icons.message),
//       colorText: Colors.white,
//       backgroundColor: Colors.green,
//       snackPosition: SnackPosition.TOP
//       );

//     } else {
//       print("Failed to get config. Status code: ${response.statusCode}");
//       Get.snackbar("Zimra Response", "Failed to get config. Status code: ${response.statusCode}" , 
//       icon:const Icon(Icons.message),
//       colorText: Colors.white,
//       backgroundColor: Colors.red,
//       snackPosition: SnackPosition.TOP
//       );
//     }
//   } catch (e) {
//     print("Error getting config: $e");
//     Get.snackbar("Zimra Response", "Error getting config: $e" , 
//       icon:const Icon(Icons.message),
//       colorText: Colors.white,
//       backgroundColor: Colors.red,
//       snackPosition: SnackPosition.TOP
//       );

//   }

//   return responseMessage;
// }
//   ///GETSTATUS
  
//   Future<void> getStatus() async {
//     String apiEndpointGetStatus =
//       "https://fdmsapi.zimra.co.zw/Device/v1/$deviceID/GetStatus";
//     const String deviceModelName = "Server";
//     const String deviceModelVersion = "v1";

//     SSLContextProvider sslContextProvider = SSLContextProvider();
//     SecurityContext securityContext = await sslContextProvider.createSSLContext();

//     final String response = await GetStatus.getStatus(
//       apiEndpointGetStatus: apiEndpointGetStatus,
//       deviceModelName: deviceModelName,
//       deviceModelVersion: deviceModelVersion,
//       securityContext: securityContext,
//     );
//     //print("Response: \n$response");
//     Get.snackbar(
//       "Zimra Response", "$response",
//       snackPosition: SnackPosition.TOP,
//       colorText: Colors.white,
//       backgroundColor: Colors.green,
//       icon: const Icon(Icons.message, color: Colors.white),
//     );
//   }


//   Future<String> ping() async {
//     String apiEndpointPing =
//         "https://fdmsapi.zimra.co.zw/Device/v1/$deviceID/Ping";
//     const String deviceModelName = "Server";
//     const String deviceModelVersion = "v1"; 

//     SSLContextProvider sslContextProvider = SSLContextProvider();
//     SecurityContext securityContext = await sslContextProvider.createSSLContext();

//     // Call the Ping function
//     final String response = await PingService.ping(
//       apiEndpointPing: apiEndpointPing,
//       deviceModelName: deviceModelName,
//       deviceModelVersion: deviceModelVersion,
//       securityContext: securityContext,
//     );

//     //print("Response: \n$response");
//     Get.snackbar(
//         "Zimra Response", "$response",
//         snackPosition: SnackPosition.TOP,
//         colorText: Colors.white,
//         backgroundColor: Colors.green,
//         icon: const Icon(Icons.message, color: Colors.white),
//       );
//     return response;
//   }

//   String dayOpened = '';
  
//   Future<void> getopendayData() async {
//     final dayData = await dbHelper.getDayOpenedDate(currentFiscal);
//     String dayOpened1 = dayData[0]['FiscalDayOpened'];
//     print(dayOpened1);
//     setState(() {
//       dayOpened = dayOpened1;
//     });
//   }

//   Future<String> submitUnsubmittedReceipts() async {
//   String sql = "SELECT * FROM submittedReceipts WHERE StatustoFDMS = 'NotSubmitted'";
//   int resubmittedCount = 0;

//   // String pingResponse = await ping();
//   String pingResponse = "200";

//   if (pingResponse == "200") {
//     try {
//       print("entered submit missing");
//     // Get the database instance
//     final db = await dbHelper.initDB();
//     String apiEndpointSubmitReceipt =
//       "https://fdmsapi.zimra.co.zw/Device/v1/$deviceID/SubmitReceipt";
//     const String deviceModelName = "Server";
//     const String deviceModelVersion = "v1"; 
//     SSLContextProvider sslContextProvider = SSLContextProvider();
//     SecurityContext securityContext = await sslContextProvider.createSSLContext();
//     // Retrieve unsubmitted receipts
//     List<Map<String, dynamic>> receipts = await dbHelper.getReceiptsNotSubmitted();
//     print(receipts);
//     for (var row in receipts) {
//       print("submitting receipts");
//       //UnsubmittedReceipt receipt = UnsubmittedReceipt.fromMap(row);
//       final String unsubmittedJsonBody = row["receiptJsonbody"];
//       final int receiptGlobalNo = row["receiptGlobalNo"];
//       print("unsubmittedJsonBody: $unsubmittedJsonBody");
//       // Submit the receipt via HTTP
//       Map<String, dynamic> submitResponse = await SubmitReceipts.submitReceipts(
//         apiEndpointSubmitReceipt: apiEndpointSubmitReceipt,
//         deviceModelName: deviceModelName,
//         deviceModelVersion: deviceModelVersion, 
//         securityContext: securityContext,
//         receiptjsonBody: unsubmittedJsonBody,
//       );
//       Map<String, dynamic> responseBody = jsonDecode(submitResponse["responseBody"]);
//       int statusCode = submitResponse["statusCode"];
//       print("server response is $submitResponse");

//       if (statusCode == 200) {
//         String submitReceiptServerresponseJson = responseBody.toString();
//         // Parse the server response
//         int receiptID = responseBody['receiptID'] ?? 0;
//         String receiptServerSignature = responseBody['receiptServerSignature']?['signature'].toString() ?? "";

//         print("receiptID: $receiptID");
//         print("receiptServerSignature: $receiptServerSignature");

//         // Update database record
//         String updateSql = '''
//           UPDATE SubmittedReceipts 
//           SET receiptID = ?, receiptServerSignature = ?, submitReceiptServerResponseJSON = ?, StatustoFDMS = 'Submitted' 
//           WHERE receiptGlobalNo = ?
//         ''';

//         await db.rawUpdate(updateSql, [
//           receiptID,
//           receiptServerSignature,
//           submitReceiptServerresponseJson,
//           //receipt.receiptGlobalNo
//           receiptGlobalNo
//         ]);

//         resubmittedCount++;
//         fetchReceiptsPending();
//       }
//       else{
//         Get.snackbar("Response message", "$submitResponse",
//           snackPosition: SnackPosition.TOP,
//           colorText: Colors.white,
//           backgroundColor: Colors.green,
//           icon: const Icon(Icons.message, color: Colors.white),
//         );
//       }
//     }
//   } catch (e) {
//     print("Error: $e");
//   }
//   Get.snackbar("Submit Successs", "The number of receipts resubmitted is: $resubmittedCount"
//   , snackPosition: SnackPosition.TOP,
//       colorText: Colors.white,
//       backgroundColor: Colors.green,
//       icon: const Icon(Icons.message, color: Colors.white),
//   );
//   return "The number of receipts resubmitted is: $resubmittedCount";
//   }
//   Get.snackbar("No Submission", "Failed to ping the server. Check your connection!"
//   , snackPosition: SnackPosition.TOP,
//       colorText: Colors.black,
//       backgroundColor: Colors.amber,
//       icon: const Icon(Icons.message, color: Colors.black),
//   );
//   return "Failed to ping the server. Check your connection!";

// }

//   Future<int> getlatestFiscalDay() async {
//     int latestFiscDay = await dbHelper.getlatestFiscalDay();
//     setState(() {
//       currentFiscal = latestFiscDay;
//     });
//     return latestFiscDay;
//   }
//   ///==================================END FDMS FUNCTIONS========================================
//   ///
//   ///
//   String formatString(String input) {
//     final buffer = StringBuffer();
//     for (int i = 0; i < input.length; i += 4) {
//       if (i + 4 <= input.length) {
//         buffer.write(input.substring(i, i + 4));
//       } else {
//         buffer.write(input.substring(i));
//       }

//       if (i + 4 < input.length) {
//         buffer.write('-');
//       }
//     }
//     return buffer.toString();
//   }
//   // This function might be called after signing

//   //==========================Printer Handlers===================================================================

//   Future<String?> getSelectedPrinter() async {
//     final prefs = await SharedPreferences.getInstance();
//     return prefs.getString('preferred_printer');
//   }

//   Future<void> handleReceiptPrint(Map<String, dynamic> receiptData, String qrData , String receiptQrData) async {
//     print("Now printing on 80mm");
//     final storedPrinterName = await getSelectedPrinter();
//     try {
//     // Optional: fetch printers and pre-select one (to avoid dialog)
//     final printers = await Printing.listPrinters();
//     final selected = printers.firstWhere((p) => p.name.contains(storedPrinterName.toString())); // Your printer
//     final receiptDataData = receiptData['receipt'];
//     print(receiptDataData);
//       await print80mmReceipt(
//         receipt: receiptDataData,
//         qrUrl: qrData,
//         qrData: receiptQrData,
//         selectedPrinter: selected, // Uncomment for silent print
//       );
//     } catch (e) {
//       print("Print failed: $e");
//     }
//   }

//   Future<void> handleReceiptPrint58mm(Map<String, dynamic> receiptData, String qrData , String receiptQrData) async {
//     print("Now printing on 80mm");
//     final storedPrinterName = await getSelectedPrinter();
//     try {
//     // Optional: fetch printers and pre-select one (to avoid dialog)
//     final printers = await Printing.listPrinters();
//     final selected = printers.firstWhere((p) => p.name.contains(storedPrinterName.toString())); // Your printer
//     final receiptDataData = receiptData['receipt'];
//     print(receiptDataData);
//       await print58mmReceipt(
//         receipt: receiptDataData,
//         qrUrl: qrData,
//         qrData: receiptQrData,
//         selectedPrinter: selected, // Uncomment for silent print
//       );
//     } catch (e) {
//       print("Print failed: $e");
//     }
//   }

//   Future<void> handleZReportPrint() async{
//     final storedPrinterName = await getSelectedPrinter();
//     try {
//       final printers = await Printing.listPrinters();
//       final selected = printers.firstWhere((p) => p.name.contains(storedPrinterName.toString())); // Your printer
//       await print80mmZReport(
//         selectedPrinter: selected
//       ); 
//     } catch (e) {
//       Get.snackbar(
//         "Z Report Print Eror",
//         "$e",
//         snackPosition: SnackPosition.TOP,
//         backgroundColor: Colors.red,
//         colorText: Colors.white,
//         icon: const Icon(Icons.error)
//       );
//     }
//   }

//   Future<void> handle58mmZreport() async{
//     final storedPrinterName = await getSelectedPrinter();
//     try {
//       final printers = await Printing.listPrinters();
//       final selected = printers.firstWhere((p) => p.name.contains(storedPrinterName.toString())); // Your printer
//       await print58mmZReport(
//         selectedPrinter: selected
//       ); 
//     } catch (e) {
//       Get.snackbar(
//         "Z Report Print Eror",
//         "$e",
//         snackPosition: SnackPosition.TOP,
//         backgroundColor: Colors.red,
//         colorText: Colors.white,
//         icon: const Icon(Icons.error)
//       );
//     }
//   }

//   //=================================Z-REPORT CALCULATIONS==================================================================

//     double GrossTotalZWG = 0;
//     double TaxTotalZWG = 0;
//     double NetVAT15TotalZWG = 0;
//     double NetNonVATTotalZWG = 0;
//     double NetExemptTotalZWG = 0;
//     double NetTotalZWG = 0;
//     double TaxVAT15ZWG = 0;
//     double getGrossTotalVAT15ZWG = 0;
//     double getGrossTotalNonVATZWG =0;
//     double getGrossTotalExemptZWG = 0;
//     double GrossTotalVAT15ZWG = 0;
//     double GrossTotalNonVATZWG = 0;
//     double GrossTotalExemptZWG = 0;
//     double getTotalTaxAmount = 0;

//     double GrossTotalUSD = 0;
//     double TaxTotalUSD = 0;
//     double NetVAT15TotalUSD = 0;
//     double NetNonVATTotalUSD = 0;
//     double NetExemptTotalUSD = 0;
//     double NetTotalUSD = 0;
//     double TaxVAT15USD = 0;
//     double getGrossTotalVAT15USD = 0;
//     double getGrossTotalNonVATUSD =0;
//     double getGrossTotalExemptUSD = 0;
//     double GrossTotalVAT15USD = 0;
//     double GrossTotalNonVATUSD = 0;
//     double GrossTotalExemptUSD = 0;
//     double getTotalTaxAmountUSD = 0;

//     double GrossTotalZAR = 0;
//     double TaxTotalZAR = 0;
//     double NetVAT15TotalZAR = 0;
//     double NetNonVATTotalZAR = 0;
//     double NetExemptTotalZAR = 0;
//     double NetTotalZAR = 0;
//     double TaxVAT15ZAR = 0;
//     double getGrossTotalVAT15ZAR = 0;
//     double getGrossTotalNonVATZAR =0;
//     double getGrossTotalExemptZAR = 0;
//     double GrossTotalVAT15ZAR = 0;
//     double GrossTotalNonVATZAR = 0;
//     double GrossTotalExemptZAR = 0;
//     double getTotalTaxAmountZAR = 0;

//     int InvoicesCountZWG = 0;
//   	double InvoicesTotalAmountZWG = 0;
//   	int CreditNotesCountZWG = 0; 
//   	double CreditNotesTotalAmountZWG = 0;
//   	int TotalDocumentsCountZWG = 0;
//   	double TotalDocumentsTotalAmountZWG = 0;

//     int InvoicesCountUSD = 0;
//   	double InvoicesTotalAmountUSD = 0;
//   	int CreditNotesCountUSD = 0; 
//   	double CreditNotesTotalAmountUSD = 0;
//   	int TotalDocumentsCountUSD = 0;
//   	double TotalDocumentsTotalAmountUSD = 0;

//     int InvoicesCountZAR = 0;
//   	double InvoicesTotalAmountZAR = 0;
//   	int CreditNotesCountZAR = 0; 
//   	double CreditNotesTotalAmountZAR = 0;
//   	int TotalDocumentsCountZAR = 0;
//   	double TotalDocumentsTotalAmountZAR = 0;

//     Future<void> prepareZWGZReportTotals() async{
//       final ZWGtotals = await dbHelper.getZReportTotals(currentFiscal ,  'ZWG');
//       GrossTotalZWG  = ZWGtotals[0]['sumZWGReceiptTotal'] ?? 0.0;
//       TaxTotalZWG  = ZWGtotals[0]['sumZWGTaxAmount'] ?? 0.0;
//       getGrossTotalVAT15ZWG =  ZWGtotals[0]['sumZWG15VAT']?? 0.0;
//       getGrossTotalNonVATZWG = ZWGtotals[0]['sumZWGNonVAT']?? 0.0;
//       getGrossTotalExemptZWG = ZWGtotals[0]['sumZWGExempt']?? 0.0;
//       setState(() {
//         TaxVAT15ZWG = TaxTotalZWG;
//         GrossTotalVAT15ZWG = getGrossTotalVAT15ZWG;
//         GrossTotalNonVATZWG =getGrossTotalNonVATZWG;
//         GrossTotalExemptZWG = getGrossTotalExemptZWG;
//       });
//       //getZWLVAT gross total
//       getTotalTaxAmount = ZWGtotals[0]['sumZWGTaxAmount']?? 0.0;
//       NetVAT15TotalZWG = GrossTotalVAT15ZWG - getTotalTaxAmount;
//       NetNonVATTotalZWG = GrossTotalNonVATZWG ;
//       NetExemptTotalZWG = GrossTotalExemptZWG;
//     }

//     Future<void> prepareUSZreportTotals()async{
//       final USDtotals = await dbHelper.getZReportTotals(currentFiscal ,  'USD');
//       GrossTotalUSD  = USDtotals[0]['sumZWGReceiptTotal']?? 0.0;
//       TaxTotalUSD  = USDtotals[0]['sumZWGTaxAmount']?? 0.0;
//       getGrossTotalVAT15USD =  USDtotals[0]['sumZWG15VAT']?? 0.0;
//       getGrossTotalNonVATUSD = USDtotals[0]['sumZWGNonVAT']?? 0.0;
//       getGrossTotalExemptUSD = USDtotals[0]['sumZWGExempt']?? 0.0;
//       setState(() {
//         TaxVAT15USD = TaxTotalUSD;
//         GrossTotalVAT15USD = getGrossTotalVAT15USD;
//         GrossTotalNonVATUSD =getGrossTotalNonVATUSD;
//         GrossTotalExemptUSD = getGrossTotalExemptUSD;
//       });

//       getTotalTaxAmountUSD = USDtotals[0]['sumZWGTaxAmount']?? 0.0;
//       NetVAT15TotalUSD = GrossTotalVAT15USD - getTotalTaxAmountUSD;
//       NetNonVATTotalUSD = GrossTotalNonVATUSD ;
//       NetExemptTotalUSD = GrossTotalExemptUSD;

//     }

//     Future<void> prepareZARZreportTotals()async{
//       final ZARtotals = await dbHelper.getZReportTotals(currentFiscal ,  'ZAR');
//       GrossTotalZAR  = ZARtotals[0]['sumZWGReceiptTotal']?? 0.0;
//       TaxTotalZAR  = ZARtotals[0]['sumZWGTaxAmount']?? 0.0;
//       getGrossTotalVAT15ZAR =  ZARtotals[0]['sumZWG15VAT']?? 0.0;
//       getGrossTotalNonVATZAR = ZARtotals[0]['sumZWGNonVAT']?? 0.0;
//       getGrossTotalExemptZAR = ZARtotals[0]['sumZWGExempt']?? 0.0;
//       setState(() {
//         TaxVAT15ZAR = TaxTotalZAR;
//         GrossTotalVAT15ZAR = getGrossTotalVAT15ZAR;
//         GrossTotalNonVATZAR =getGrossTotalNonVATZAR;
//         GrossTotalExemptZAR= getGrossTotalExemptZAR;
//       });
//       //getZWLVAT gross total

//       getTotalTaxAmountZAR = ZARtotals[0]['sumZWGTaxAmount'] ?? 0.0;
//       NetVAT15TotalZAR = GrossTotalVAT15ZAR - getTotalTaxAmountZAR;
//       NetNonVATTotalZAR = GrossTotalNonVATZAR;
//       NetExemptTotalZAR = GrossTotalExemptZAR;
//     }

//     Future<void> prepareZWGDocuments() async{
//       final Invoices  = await dbHelper.getDocumentsCounter(currentFiscal, 'ZWG', 'FISCALINVOICE');
//       final InvoicesTotal = await dbHelper.getZreportDocumentTotals(currentFiscal ,'FISCALINVOICE' , 'ZWG');
//       final Creditnotes = await dbHelper.getDocumentsCounter(currentFiscal, 'ZWG', 'CREDITNOTE');
//       final CreditnotesTotals = await dbHelper.getZreportDocumentTotals(currentFiscal, 'CREDITNOTE', 'ZWG');
//       setState(() {
//         InvoicesCountZWG = Invoices[0]['count']?? 0;
//         InvoicesTotalAmountZWG = InvoicesTotal[0]['total']?? 0.0;
//         CreditNotesCountZWG = Creditnotes[0]['count']?? 0;
//         CreditNotesTotalAmountZWG = CreditnotesTotals[0]['total']?? 0.0;
//       });
//     }

//     Future<void> prepareUSDDocuments() async{
//       final Invoices  = await dbHelper.getDocumentsCounter(currentFiscal, 'USD', 'FISCALINVOICE');
//       final InvoicesTotal = await dbHelper.getZreportDocumentTotals(currentFiscal ,'FISCALINVOICE' , 'USD');
//       final Creditnotes = await dbHelper.getDocumentsCounter(currentFiscal, 'USD', 'CREDITNOTE');
//       final CreditnotesTotals = await dbHelper.getZreportDocumentTotals(currentFiscal, 'CREDITNOTE', 'USD');
//       setState(() {
//         InvoicesCountUSD = Invoices[0]['count']?? 0;
//         InvoicesTotalAmountUSD = InvoicesTotal[0]['total']?? 0.0;
//         CreditNotesCountUSD = Creditnotes[0]['count']?? 0;
//         CreditNotesTotalAmountUSD = CreditnotesTotals[0]['total']?? 0.0;
//       });
//     }

//     Future<void> prepareZARDocuments() async{
//       final Invoices  = await dbHelper.getDocumentsCounter(currentFiscal, 'ZAR', 'FISCALINVOICE');
//       final InvoicesTotal = await dbHelper.getZreportDocumentTotals(currentFiscal ,'FISCALINVOICE' , 'ZAR');
//       final Creditnotes = await dbHelper.getDocumentsCounter(currentFiscal, 'ZAR', 'CREDITNOTE');
//       final CreditnotesTotals = await dbHelper.getZreportDocumentTotals(currentFiscal, 'CREDITNOTE', 'ZAR');
//       setState(() {
//         InvoicesCountZAR = Invoices[0]['count']?? 0;
//         InvoicesTotalAmountZAR = InvoicesTotal[0]['total']?? 0.0;
//         CreditNotesCountZAR = Creditnotes[0]['count']?? 0;
//         CreditNotesTotalAmountZAR = CreditnotesTotals[0]['total']?? 0.0;
//       });
//     }

//   //=========================PRINT 80mm Z REPORT=======================================================================  

//   Future<void> print80mmZReport({
//     Printer? selectedPrinter
//   }) async{

//     await prepareZWGZReportTotals();
//     await prepareZWGDocuments();
//     await prepareUSZreportTotals();
//     await prepareUSDDocuments();
//     await prepareZARZreportTotals();
//     await prepareZARDocuments();

//     final pdf = pw.Document();
//     pdf.addPage(
//       pw.MultiPage(
//         pageFormat: PdfPageFormat(80 * PdfPageFormat.mm, PdfPageFormat.a4.height), // Or set custom height
//         maxPages: 100,
//         build: (pw.Context context) => [
//           pw.Column(
//             crossAxisAlignment: pw.CrossAxisAlignment.start,
//             children: [
//               pw.Container(
//                 alignment: pw.Alignment.center,
//                 child: pw.Text(
//                 "$tradeName",
//                 style: pw.TextStyle(fontSize:10, fontWeight: pw.FontWeight.bold),
//                 textAlign: pw.TextAlign.center,
//               ),
//               ),
//               pw.Container(
//                 alignment: pw.Alignment.center,
//                 child: pw.Text(
//                 "TIN: $taxPayerTIN",
//                 style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.normal),
//                 textAlign: pw.TextAlign.center,
//               ),
//               ),
//               pw.SizedBox(height: 3),
//               pw.Container(
//                 alignment: pw.Alignment.center,
//                 child: pw.Text(
//                 "VAT No: $taxPayerVatNumber",
//                 style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.normal),
//                 textAlign: pw.TextAlign.center,
//               ),
//               ),
//               pw.SizedBox(height: 3),
//               pw.Container(
//                 alignment: pw.Alignment.center,
//                 child: pw.Text(
//                 "$taxPayerAddress",
//                 style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.normal),
//                 textAlign: pw.TextAlign.center,
//               ),
//               ),
//               pw.SizedBox(height: 3),
//               pw.Container(
//                 alignment: pw.Alignment.center,
//                   child: pw.Text(
//                   "$taxPayerEmail",
//                   style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.normal),
//                   textAlign: pw.TextAlign.center,
//                 ),
//               ),
//               pw.SizedBox(height: 3),
//               pw.Container(
//                 alignment: pw.Alignment.center,
//                 child: pw.SizedBox(
//                   child: pw.Text(
//                     "$taxPayerPhone",
//                     style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.normal),
//                     textAlign: pw.TextAlign.center,
//                   ),
//                 ),
//               ),
//               pw.Divider(),
//               pw.Container(
//                 alignment: pw.Alignment.center,
//                 child: pw.SizedBox(
//                   child: pw.Text(
//                     "Z REPORT",
//                     style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.normal),
//                     textAlign: pw.TextAlign.center,
//                   ),
//                 ),
//               ),
//               pw.Divider(),
//               pw.Text("Fiscal Day No: $currentFiscal",
//                 style: pw.TextStyle(fontSize:9, fontWeight: pw.FontWeight.normal)
//               ),
//               pw.Text("Fiscal Day Opened: $dayOpened",
//                 style: pw.TextStyle(fontSize:9, fontWeight: pw.FontWeight.normal)
//               ),
//               pw.Text("Device Serial No: $serialNo",
//                 style: pw.TextStyle(fontSize:9, fontWeight: pw.FontWeight.normal)
//               ),
//               pw.Text("Device Id: $deviceID",
//                 style: pw.TextStyle(fontSize:9, fontWeight: pw.FontWeight.normal)
//               ),
//               pw.Divider(),
//               pw.Container(
//                 alignment: pw.Alignment.center,
//                 child: pw.SizedBox(
//                   child: pw.Text(
//                     "Daily Totals",
//                     style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.normal),
//                     textAlign: pw.TextAlign.center,
//                   ),
//                 ),
//               ),
//               pw.Divider(),
//               pw.Text("ZWG",
//                 style: pw.TextStyle(fontSize:9, fontWeight: pw.FontWeight.bold)
//               ),
//               pw.SizedBox(height: 20),
//               pw.Text("TOTAL NET SALES",
//                 style: pw.TextStyle(fontSize:9, fontWeight: pw.FontWeight.bold)
//               ),
//               pw.Text("Net , VAT 15%: ${NetVAT15TotalZWG.toStringAsFixed(2)}",
//                 style: pw.TextStyle(fontSize:9, fontWeight: pw.FontWeight.normal)
//               ),
//               pw.Text("Net , Non-VAT 0%: ${NetNonVATTotalZWG.toStringAsFixed(2)}",
//                 style: pw.TextStyle(fontSize:9, fontWeight: pw.FontWeight.normal)
//               ),
//               pw.Text("Net , Exempt: ${NetExemptTotalZWG.toStringAsFixed(2)}",
//                 style: pw.TextStyle(fontSize:9, fontWeight: pw.FontWeight.normal)
//               ),
//               pw.Text("Total Net Amount: ${NetTotalZWG.toStringAsFixed(2)}",
//                 style: pw.TextStyle(fontSize:9, fontWeight: pw.FontWeight.normal)
//               ),
//               pw.SizedBox(height: 20),
//               pw.Text("TOTAL TAXES",
//                 style: pw.TextStyle(fontSize:9, fontWeight: pw.FontWeight.bold)
//               ),
//               pw.Text("Tax , VAT 15 %: ${TaxVAT15ZWG.toStringAsFixed(2)}",
//                 style: pw.TextStyle(fontSize:9, fontWeight: pw.FontWeight.normal)
//               ),
//               pw.Text("Total tax amount: ${TaxTotalZWG.toStringAsFixed(2)}",
//                 style: pw.TextStyle(fontSize:9, fontWeight: pw.FontWeight.normal)
//               ),
//               pw.SizedBox(height: 20),
//               pw.Text("TOTAL GROSS SALES",
//                 style: pw.TextStyle(fontSize:9, fontWeight: pw.FontWeight.bold)
//               ),
//               pw.Text("Total , VAT 15 %: ${GrossTotalVAT15ZWG.toStringAsFixed(2)}",
//                 style: pw.TextStyle(fontSize:9, fontWeight: pw.FontWeight.normal)
//               ),
//               pw.Text("Total , Non-VAT 0 %: ${GrossTotalNonVATZWG.toStringAsFixed(2)}",
//                 style: pw.TextStyle(fontSize:9, fontWeight: pw.FontWeight.normal)
//               ),
//               pw.Text("Total , Exempt: ${GrossTotalExemptZWG.toStringAsFixed(2)}",
//                 style: pw.TextStyle(fontSize:9, fontWeight: pw.FontWeight.normal)
//               ),
//               pw.Text("Total gross amount: ${GrossTotalZWG.toStringAsFixed(2)}",
//                 style: pw.TextStyle(fontSize:9, fontWeight: pw.FontWeight.normal)
//               ),
//               pw.SizedBox(height: 20),
//               pw.Text("Documents               Quantity                Total", 
//                 style: pw.TextStyle(fontWeight: pw.FontWeight.bold,fontSize: 10)
//               ),
//               pw.Row(
//                 mainAxisAlignment: pw.MainAxisAlignment.start,
//                 children: [
//                   // Quantity (tight width)
//                   pw.SizedBox(
//                     width: 40,
//                     child: pw.Text(
//                       "Invoices",
//                       style: pw.TextStyle(fontSize: 8),
//                       textAlign: pw.TextAlign.left,
//                     ),
//                   ),
//                   // Small space
//                   pw.SizedBox(width: 35),
//                   pw.SizedBox(
//                     width: 40,
//                     child: pw.Text(
//                       InvoicesCountZWG.toStringAsFixed(2),
//                       style: pw.TextStyle(fontSize: 8),
//                       textAlign: pw.TextAlign.right,
//                     ),
//                   ),
//                   pw.SizedBox(width:35),
//                   pw.SizedBox(
//                     width: 40,
//                     child: pw.Text(
//                       InvoicesTotalAmountZWG.toStringAsFixed(2),
//                       style: pw.TextStyle(fontSize: 8),
//                       textAlign: pw.TextAlign.right,
//                     ),
//                   ),
//                 ],
//               ),
//               pw.Row(
//                 mainAxisAlignment: pw.MainAxisAlignment.start,
//                 children: [
//                   pw.SizedBox(
//                     width: 60,
//                     child: pw.Text(
//                       "Credit notes",
//                       style: pw.TextStyle(fontSize: 8),
//                       textAlign: pw.TextAlign.left,
//                     ),
//                   ),
//                   // Small space
//                   pw.SizedBox(width: 15),

//                   pw.SizedBox(
//                     width: 40,
//                     child: pw.Text(
//                       CreditNotesCountZWG.toStringAsFixed(2),
//                       style: pw.TextStyle(fontSize: 8),
//                       textAlign: pw.TextAlign.right,
//                     ),
//                   ),
//                   pw.SizedBox(width: 35),
//                   pw.SizedBox(
//                     width: 40,
//                     child: pw.Text(
//                       CreditNotesTotalAmountZWG.toStringAsFixed(2),
//                       style: pw.TextStyle(fontSize: 8),
//                       textAlign: pw.TextAlign.right,
//                     ),
//                   ),
//                 ],
//               ),
//               pw.Row(
//                 mainAxisAlignment: pw.MainAxisAlignment.start,
//                 children: [
//                   pw.SizedBox(
//                     width: 70,
//                     child: pw.Text(
//                       "Total documents",
//                       style: pw.TextStyle(fontSize: 8),
//                       textAlign: pw.TextAlign.left,
//                     ),
//                   ),
//                   // Small space
//                   pw.SizedBox(width: 10),

//                   pw.SizedBox(
//                     width: 40,
//                     child: pw.Text(
//                       TotalDocumentsCountZWG.toString(),
//                       style: pw.TextStyle(fontSize: 8),
//                       textAlign: pw.TextAlign.right,
//                     ),
//                   ),
//                   pw.SizedBox(width: 30),
//                   pw.SizedBox(
//                     width: 40,
//                     child: pw.Text(
//                       TotalDocumentsTotalAmountZWG.toString(),
//                       style: pw.TextStyle(fontSize: 8),
//                       textAlign: pw.TextAlign.right,
//                     ),
//                   ),
//                 ],
//               ),
//               pw.Divider(),
//               pw.Text("USD",
//                 style: pw.TextStyle(fontSize:9, fontWeight: pw.FontWeight.bold)
//               ),
//               pw.SizedBox(height: 20),
//               pw.Text("TOTAL NET SALES",
//                 style: pw.TextStyle(fontSize:9, fontWeight: pw.FontWeight.bold)
//               ),
//               pw.Text("Net , VAT 15%: ${NetVAT15TotalUSD.toStringAsFixed(2)}",
//                 style: pw.TextStyle(fontSize:9, fontWeight: pw.FontWeight.normal)
//               ),
//               pw.Text("Net , Non-VAT 0%: ${NetNonVATTotalUSD.toStringAsFixed(2)}",
//                 style: pw.TextStyle(fontSize:9, fontWeight: pw.FontWeight.normal)
//               ),
//               pw.Text("Net , Exempt: ${NetExemptTotalUSD.toStringAsFixed(2)}",
//                 style: pw.TextStyle(fontSize:9, fontWeight: pw.FontWeight.normal)
//               ),
//               pw.Text("Total Net Amount: ${NetTotalUSD.toStringAsFixed(2)}",
//                 style: pw.TextStyle(fontSize:9, fontWeight: pw.FontWeight.normal)
//               ),
//               pw.SizedBox(height: 20),
//               pw.Text("TOTAL TAXES",
//                 style: pw.TextStyle(fontSize:9, fontWeight: pw.FontWeight.bold)
//               ),
//               pw.Text("Tax , VAT 15 %: ${TaxVAT15USD.toStringAsFixed(2)}",
//                 style: pw.TextStyle(fontSize:9, fontWeight: pw.FontWeight.normal)
//               ),
//               pw.Text("Total tax amount: ${TaxTotalUSD.toStringAsFixed(2)}",
//                 style: pw.TextStyle(fontSize:9, fontWeight: pw.FontWeight.normal)
//               ),
//               pw.SizedBox(height: 20),
//               pw.Text("TOTAL GROSS SALES",
//                 style: pw.TextStyle(fontSize:9, fontWeight: pw.FontWeight.bold)
//               ),
//                 pw.Text("Total , VAT 15 %: ${GrossTotalVAT15USD.toStringAsFixed(2)}",
//                 style: pw.TextStyle(fontSize:9, fontWeight: pw.FontWeight.normal)
//               ),
//               pw.Text("Total , Non-VAT 0 %: ${GrossTotalNonVATUSD.toStringAsFixed(2)}",
//                 style: pw.TextStyle(fontSize:9, fontWeight: pw.FontWeight.normal)
//               ),
//               pw.Text("Total , Exempt: ${GrossTotalExemptUSD.toStringAsFixed(2)}",
//                 style: pw.TextStyle(fontSize:9, fontWeight: pw.FontWeight.normal)
//               ),
//               pw.Text("Total gross amount: ${GrossTotalUSD.toStringAsFixed(2)}",
//                 style: pw.TextStyle(fontSize:9, fontWeight: pw.FontWeight.normal)
//               ),
//               pw.SizedBox(height: 20),
//               pw.Text("Documents               Quantity                Total", 
//                 style: pw.TextStyle(fontWeight: pw.FontWeight.bold,fontSize: 10)
//               ),
//               pw.Row(
//                 mainAxisAlignment: pw.MainAxisAlignment.start,
//                 children: [
//                   // Quantity (tight width)
//                   pw.SizedBox(
//                     width: 40,
//                     child: pw.Text(
//                       "Invoices",
//                       style: pw.TextStyle(fontSize: 8),
//                       textAlign: pw.TextAlign.left,
//                     ),
//                   ),
//                   // Small space
//                   pw.SizedBox(width: 35),
//                   pw.SizedBox(
//                     width: 40,
//                     child: pw.Text(
//                       InvoicesCountUSD.toStringAsFixed(2),
//                       style: pw.TextStyle(fontSize: 8),
//                       textAlign: pw.TextAlign.right,
//                     ),
//                   ),
//                   pw.SizedBox(width: 35),
//                   pw.SizedBox(
//                     width: 40,
//                     child: pw.Text(
//                       InvoicesTotalAmountUSD.toStringAsFixed(2),
//                       style: pw.TextStyle(fontSize: 8),
//                       textAlign: pw.TextAlign.right,
//                     ),
//                   ),
//                 ],
//               ),
//               pw.Row(
//                 mainAxisAlignment: pw.MainAxisAlignment.start,
//                 children: [
//                   pw.SizedBox(
//                     width: 60,
//                     child: pw.Text(
//                       "Credit notes",
//                       style: pw.TextStyle(fontSize: 8),
//                       textAlign: pw.TextAlign.left,
//                     ),
//                   ),
//                   // Small space
//                   pw.SizedBox(width: 15),

//                   pw.SizedBox(
//                     width: 40,
//                     child: pw.Text(
//                       CreditNotesCountUSD.toStringAsFixed(2),
//                       style: pw.TextStyle(fontSize: 8),
//                       textAlign: pw.TextAlign.right,
//                     ),
//                   ),
//                   pw.SizedBox(width: 35),
//                   pw.SizedBox(
//                     width: 40,
//                     child: pw.Text(
//                       CreditNotesTotalAmountUSD.toStringAsFixed(2),
//                       style: pw.TextStyle(fontSize: 8),
//                       textAlign: pw.TextAlign.right,
//                     ),
//                   ),
//                 ],
//               ),
//               pw.Row(
//                 mainAxisAlignment: pw.MainAxisAlignment.start,
//                 children: [
//                   pw.SizedBox(
//                     width: 70,
//                     child: pw.Text(
//                       "Total documents",
//                       style: pw.TextStyle(fontSize: 8),
//                       textAlign: pw.TextAlign.left,
//                     ),
//                   ),
//                   // Small space
//                   pw.SizedBox(width: 10),

//                   pw.SizedBox(
//                     width: 40,
//                     child: pw.Text(
//                       TotalDocumentsCountUSD.toStringAsFixed(2),
//                       style: pw.TextStyle(fontSize: 8),
//                       textAlign: pw.TextAlign.right,
//                     ),
//                   ),
//                   pw.SizedBox(width: 30),
//                   pw.SizedBox(
//                     width: 40,
//                     child: pw.Text(
//                       TotalDocumentsTotalAmountUSD.toStringAsFixed(2),
//                       style: pw.TextStyle(fontSize: 8),
//                       textAlign: pw.TextAlign.right,
//                     ),
//                   ),
//                 ],
//               ),
//               pw.Divider(),
//               pw.Text("ZAR",
//                 style: pw.TextStyle(fontSize:9, fontWeight: pw.FontWeight.bold)
//               ),
//               pw.SizedBox(height: 20),
//               pw.Text("TOTAL NET SALES",
//                 style: pw.TextStyle(fontSize:9, fontWeight: pw.FontWeight.bold)
//               ),
//               pw.Text("Net , VAT 15%: ${NetVAT15TotalZAR.toStringAsFixed(2)}",
//                 style: pw.TextStyle(fontSize:9, fontWeight: pw.FontWeight.normal)
//               ),
//               pw.Text("Net , Non-VAT 0%: ${NetNonVATTotalZAR.toStringAsFixed(2)}",
//                 style: pw.TextStyle(fontSize:9, fontWeight: pw.FontWeight.normal)
//               ),
//               pw.Text("Net , Exempt: ${NetExemptTotalZAR.toStringAsFixed(2)}",
//                 style: pw.TextStyle(fontSize:9, fontWeight: pw.FontWeight.normal)
//               ),
//               pw.Text("Total Net Amount: ${NetTotalZAR.toStringAsFixed(2)}",
//                 style: pw.TextStyle(fontSize:9, fontWeight: pw.FontWeight.normal)
//               ),
//               pw.SizedBox(height: 20),
//               pw.Text("TOTAL TAXES",
//                 style: pw.TextStyle(fontSize:9, fontWeight: pw.FontWeight.bold)
//               ),
//               pw.Text("Tax , VAT 15 %: ${TaxVAT15ZAR.toStringAsFixed(2)}",
//                 style: pw.TextStyle(fontSize:9, fontWeight: pw.FontWeight.normal)
//               ),
//               pw.Text("Total tax amount: ${TaxTotalZAR.toStringAsFixed(2)}",
//                 style: pw.TextStyle(fontSize:9, fontWeight: pw.FontWeight.normal)
//               ),
//               pw.SizedBox(height: 20),
//               pw.Text("TOTAL GROSS SALES",
//                 style: pw.TextStyle(fontSize:9, fontWeight: pw.FontWeight.bold)
//               ),
//               pw.Text("Total , VAT 15 %: ${GrossTotalVAT15ZAR.toStringAsFixed(2)}",
//                 style: pw.TextStyle(fontSize:9, fontWeight: pw.FontWeight.normal)
//               ),
//               pw.Text("Total , Non-VAT 0 %: ${GrossTotalNonVATZAR.toStringAsFixed(2)}",
//                 style: pw.TextStyle(fontSize:9, fontWeight: pw.FontWeight.normal)
//               ),
//               pw.Text("Total , Exempt: ${GrossTotalExemptZAR.toStringAsFixed(2)}",
//                 style: pw.TextStyle(fontSize:9, fontWeight: pw.FontWeight.normal)
//               ),
//               pw.Text("Total gross amount: ${GrossTotalZAR.toStringAsFixed(2)}",
//                 style: pw.TextStyle(fontSize:9, fontWeight: pw.FontWeight.normal)
//               ),
//               pw.SizedBox(height: 20),
//               pw.Text("Documents               Quantity                Total Amount", 
//                 style: pw.TextStyle(fontWeight: pw.FontWeight.bold,fontSize: 10)
//               ),
//               pw.Row(
//                 mainAxisAlignment: pw.MainAxisAlignment.start,
//                 children: [
//                   // Quantity (tight width)
//                   pw.SizedBox(
//                     width: 40,
//                     child: pw.Text(
//                       "Invoices",
//                       style: pw.TextStyle(fontSize: 8),
//                       textAlign: pw.TextAlign.left,
//                     ),
//                   ),
//                   // Small space
//                   pw.SizedBox(width: 35),
//                   pw.SizedBox(
//                     width: 40,
//                     child: pw.Text(
//                       InvoicesCountZAR.toStringAsFixed(2),
//                       style: pw.TextStyle(fontSize: 8),
//                       textAlign: pw.TextAlign.right,
//                     ),
//                   ),
//                   pw.SizedBox(width: 35),
//                   pw.SizedBox(
//                     width: 40,
//                     child: pw.Text(
//                       InvoicesTotalAmountZAR.toStringAsFixed(2),
//                       style: pw.TextStyle(fontSize: 8),
//                       textAlign: pw.TextAlign.right,
//                     ),
//                   ),
//                 ],
//               ),
//               pw.Row(
//                 mainAxisAlignment: pw.MainAxisAlignment.start,
//                 children: [
//                   pw.SizedBox(
//                     width: 60,
//                     child: pw.Text(
//                       "Credit notes",
//                       style: pw.TextStyle(fontSize: 8),
//                       textAlign: pw.TextAlign.left,
//                     ),
//                   ),
//                   // Small space
//                   pw.SizedBox(width: 15),

//                   pw.SizedBox(
//                     width: 40,
//                     child: pw.Text(
//                       CreditNotesCountZAR.toStringAsFixed(2),
//                       style: pw.TextStyle(fontSize: 8),
//                       textAlign: pw.TextAlign.right,
//                     ),
//                   ),
//                   pw.SizedBox(width: 35),
//                   pw.SizedBox(
//                     width: 40,
//                     child: pw.Text(
//                       CreditNotesTotalAmountZAR.toStringAsFixed(2),
//                       style: pw.TextStyle(fontSize: 8),
//                       textAlign: pw.TextAlign.right,
//                     ),
//                   ),
//                 ],
//               ),
//               pw.Row(
//                 mainAxisAlignment: pw.MainAxisAlignment.start,
//                 children: [
//                   pw.SizedBox(
//                     width: 70,
//                     child: pw.Text(
//                       "Total documents",
//                       style: pw.TextStyle(fontSize: 8),
//                       textAlign: pw.TextAlign.left,
//                     ),
//                   ),
//                   // Small space
//                   pw.SizedBox(width: 10),
//                   pw.SizedBox(
//                     width: 40,
//                     child: pw.Text(
//                       TotalDocumentsCountZAR.toStringAsFixed(2),
//                       style: pw.TextStyle(fontSize: 8),
//                       textAlign: pw.TextAlign.right,
//                     ),
//                   ),
//                   pw.SizedBox(width: 30),
//                   pw.SizedBox(
//                     width: 40,
//                     child: pw.Text(
//                       TotalDocumentsTotalAmountZAR.toStringAsFixed(2),
//                       style: pw.TextStyle(fontSize: 8),
//                       textAlign: pw.TextAlign.right,
//                     ),
//                   ),
//                 ],
//               ),
//             ]
//           )
//         ]
//       )
//     );
//     if (selectedPrinter != null) {
//       await Printing.directPrintPdf(
//         printer: selectedPrinter,
//         onLayout: (PdfPageFormat format) async => pdf.save(),
//       );
//     } else {
//       // Otherwise open the print dialog
//       await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save());
//     }
//   }

//   //========================PRINT 58 MM Z report=====================================================================
  
//   Future<void> print58mmZReport({
//     Printer? selectedPrinter
//   }) async{
//     await prepareZWGZReportTotals();
//     await prepareZWGDocuments();
//     await prepareUSZreportTotals();
//     await prepareUSDDocuments();
//     await prepareZARZreportTotals();
//     await prepareZARDocuments();

//     final pdf = pw.Document();
//     pdf.addPage(
//       pw.MultiPage(
//         pageFormat: PdfPageFormat(58 * PdfPageFormat.mm, PdfPageFormat.a4.height), // Or set custom height
//         maxPages: 100,
//         build: (pw.Context context) => [
//           pw.Column(
//             crossAxisAlignment: pw.CrossAxisAlignment.start,
//             children: [
//               pw.Container(
//                 alignment: pw.Alignment.center,
//                 child: pw.Text(
//                 "$tradeName",
//                 style: pw.TextStyle(fontSize:10, fontWeight: pw.FontWeight.bold),
//                 textAlign: pw.TextAlign.center,
//               ),
//               ),
//               pw.Container(
//                 alignment: pw.Alignment.center,
//                 child: pw.Text(
//                 "TIN: $taxPayerTIN",
//                 style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.normal),
//                 textAlign: pw.TextAlign.center,
//               ),
//               ),
//               pw.SizedBox(height: 3),
//               pw.Container(
//                 alignment: pw.Alignment.center,
//                 child: pw.Text(
//                 "VAT No: $taxPayerVatNumber",
//                 style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.normal),
//                 textAlign: pw.TextAlign.center,
//               ),
//               ),
//               pw.SizedBox(height: 3),
//               pw.Container(
//                 alignment: pw.Alignment.center,
//                 child: pw.Text(
//                 "$taxPayerAddress",
//                 style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.normal),
//                 textAlign: pw.TextAlign.center,
//               ),
//               ),
//               pw.SizedBox(height: 3),
//               pw.Container(
//                 alignment: pw.Alignment.center,
//                   child: pw.Text(
//                   "$taxPayerEmail",
//                   style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.normal),
//                   textAlign: pw.TextAlign.center,
//                 ),
//               ),
//               pw.SizedBox(height: 3),
//               pw.Container(
//                 alignment: pw.Alignment.center,
//                 child: pw.SizedBox(
//                   child: pw.Text(
//                     "$taxPayerPhone",
//                     style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.normal),
//                     textAlign: pw.TextAlign.center,
//                   ),
//                 ),
//               ),
//               pw.Divider(),
//               pw.Container(
//                 alignment: pw.Alignment.center,
//                 child: pw.SizedBox(
//                   child: pw.Text(
//                     "Z REPORT",
//                     style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.normal),
//                     textAlign: pw.TextAlign.center,
//                   ),
//                 ),
//               ),
//               pw.Divider(),
//               pw.Text("Fiscal Day No: $currentFiscal",
//                 style: pw.TextStyle(fontSize:9, fontWeight: pw.FontWeight.normal)
//               ),
//               pw.Text("Fiscal Day Opened: $dayOpened",
//                 style: pw.TextStyle(fontSize:9, fontWeight: pw.FontWeight.normal)
//               ),
//               pw.Text("Device Serial No: $serialNo",
//                 style: pw.TextStyle(fontSize:9, fontWeight: pw.FontWeight.normal)
//               ),
//               pw.Text("Device Id: $deviceID",
//                 style: pw.TextStyle(fontSize:9, fontWeight: pw.FontWeight.normal)
//               ),
//               pw.Divider(),
//               pw.Container(
//                 alignment: pw.Alignment.center,
//                 child: pw.SizedBox(
//                   child: pw.Text(
//                     "Daily Totals",
//                     style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.normal),
//                     textAlign: pw.TextAlign.center,
//                   ),
//                 ),
//               ),
//               pw.Divider(),
//               pw.Text("ZWG",
//                 style: pw.TextStyle(fontSize:9, fontWeight: pw.FontWeight.bold)
//               ),
//               pw.SizedBox(height: 20),
//               pw.Text("TOTAL NET SALES",
//                 style: pw.TextStyle(fontSize:9, fontWeight: pw.FontWeight.bold)
//               ),
//               pw.Text("Net , VAT 15%: ${NetVAT15TotalZWG.toStringAsFixed(2)}",
//                 style: pw.TextStyle(fontSize:9, fontWeight: pw.FontWeight.normal)
//               ),
//               pw.Text("Net , Non-VAT 0%: ${NetNonVATTotalZWG.toStringAsFixed(2)}",
//                 style: pw.TextStyle(fontSize:9, fontWeight: pw.FontWeight.normal)
//               ),
//               pw.Text("Net , Exempt: ${NetExemptTotalZWG.toStringAsFixed(2)}",
//                 style: pw.TextStyle(fontSize:9, fontWeight: pw.FontWeight.normal)
//               ),
//               pw.Text("Total Net Amount: ${NetTotalZWG.toStringAsFixed(2)}",
//                 style: pw.TextStyle(fontSize:9, fontWeight: pw.FontWeight.normal)
//               ),
//               pw.SizedBox(height: 20),
//               pw.Text("TOTAL TAXES",
//                 style: pw.TextStyle(fontSize:9, fontWeight: pw.FontWeight.bold)
//               ),
//               pw.Text("Tax , VAT 15 %: ${TaxVAT15ZWG.toStringAsFixed(2)}",
//                 style: pw.TextStyle(fontSize:9, fontWeight: pw.FontWeight.normal)
//               ),
//               pw.Text("Total tax amount: ${TaxTotalZWG.toStringAsFixed(2)}",
//                 style: pw.TextStyle(fontSize:9, fontWeight: pw.FontWeight.normal)
//               ),
//               pw.SizedBox(height: 20),
//               pw.Text("TOTAL GROSS SALES",
//                 style: pw.TextStyle(fontSize:9, fontWeight: pw.FontWeight.bold)
//               ),
//               pw.Text("Total , VAT 15 %: ${GrossTotalVAT15ZWG.toStringAsFixed(2)}",
//                 style: pw.TextStyle(fontSize:9, fontWeight: pw.FontWeight.normal)
//               ),
//               pw.Text("Total , Non-VAT 0 %: ${GrossTotalNonVATZWG.toStringAsFixed(2)}",
//                 style: pw.TextStyle(fontSize:9, fontWeight: pw.FontWeight.normal)
//               ),
//               pw.Text("Total , Exempt: ${GrossTotalExemptZWG.toStringAsFixed(2)}",
//                 style: pw.TextStyle(fontSize:9, fontWeight: pw.FontWeight.normal)
//               ),
//               pw.Text("Total gross amount: ${GrossTotalZWG.toStringAsFixed(2)}",
//                 style: pw.TextStyle(fontSize:9, fontWeight: pw.FontWeight.normal)
//               ),
//               pw.SizedBox(height: 20),
//               pw.Text("Documents--Quantity--Total", 
//                 style: pw.TextStyle(fontWeight: pw.FontWeight.bold,fontSize: 10)
//               ),
//               pw.Text("Invoice--${InvoicesCountZWG.toStringAsFixed(2)}--${InvoicesTotalAmountZWG.toStringAsFixed(2)}", 
//                 style: pw.TextStyle(fontWeight: pw.FontWeight.bold,fontSize: 10)
//               ),
//               pw.Text("CreditNotes--${CreditNotesCountZWG.toStringAsFixed(2)}--${CreditNotesTotalAmountZWG.toStringAsFixed(2)}", 
//                 style: pw.TextStyle(fontWeight: pw.FontWeight.bold,fontSize: 10)
//               ),
//               pw.Text("Docs--${TotalDocumentsCountZWG.toString()}--${TotalDocumentsTotalAmountZWG.toStringAsFixed(2)}", 
//                 style: pw.TextStyle(fontWeight: pw.FontWeight.bold,fontSize: 10)
//               ),
//               pw.Divider(),
//               pw.Text("USD",
//                 style: pw.TextStyle(fontSize:9, fontWeight: pw.FontWeight.bold)
//               ),
//               pw.SizedBox(height: 20),
//               pw.Text("TOTAL NET SALES",
//                 style: pw.TextStyle(fontSize:9, fontWeight: pw.FontWeight.bold)
//               ),
//               pw.Text("Net , VAT 15%: ${NetVAT15TotalUSD.toStringAsFixed(2)}",
//                 style: pw.TextStyle(fontSize:9, fontWeight: pw.FontWeight.normal)
//               ),
//               pw.Text("Net , Non-VAT 0%: ${NetNonVATTotalUSD.toStringAsFixed(2)}",
//                 style: pw.TextStyle(fontSize:9, fontWeight: pw.FontWeight.normal)
//               ),
//               pw.Text("Net , Exempt: ${NetExemptTotalUSD.toStringAsFixed(2)}",
//                 style: pw.TextStyle(fontSize:9, fontWeight: pw.FontWeight.normal)
//               ),
//               pw.Text("Total Net Amount: ${NetTotalUSD.toStringAsFixed(2)}",
//                 style: pw.TextStyle(fontSize:9, fontWeight: pw.FontWeight.normal)
//               ),
//               pw.SizedBox(height: 20),
//               pw.Text("TOTAL TAXES",
//                 style: pw.TextStyle(fontSize:9, fontWeight: pw.FontWeight.bold)
//               ),
//               pw.Text("Tax , VAT 15 %: ${TaxVAT15USD.toStringAsFixed(2)}",
//                 style: pw.TextStyle(fontSize:9, fontWeight: pw.FontWeight.normal)
//               ),
//               pw.Text("Total tax amount: ${TaxTotalUSD.toStringAsFixed(2)}",
//                 style: pw.TextStyle(fontSize:9, fontWeight: pw.FontWeight.normal)
//               ),
//               pw.SizedBox(height: 20),
//               pw.Text("TOTAL GROSS SALES",
//                 style: pw.TextStyle(fontSize:9, fontWeight: pw.FontWeight.bold)
//               ),
//                 pw.Text("Total , VAT 15 %: ${GrossTotalVAT15USD.toStringAsFixed(2)}",
//                 style: pw.TextStyle(fontSize:9, fontWeight: pw.FontWeight.normal)
//               ),
//               pw.Text("Total , Non-VAT 0 %: ${GrossTotalNonVATUSD.toStringAsFixed(2)}",
//                 style: pw.TextStyle(fontSize:9, fontWeight: pw.FontWeight.normal)
//               ),
//               pw.Text("Total , Exempt: ${GrossTotalExemptUSD.toStringAsFixed(2)}",
//                 style: pw.TextStyle(fontSize:9, fontWeight: pw.FontWeight.normal)
//               ),
//               pw.Text("Total gross amount: ${GrossTotalUSD.toStringAsFixed(2)}",
//                 style: pw.TextStyle(fontSize:9, fontWeight: pw.FontWeight.normal)
//               ),
//               pw.SizedBox(height: 20),
//               pw.Text("Documents--Quantity--Total", 
//                 style: pw.TextStyle(fontWeight: pw.FontWeight.bold,fontSize: 10)
//               ),
//               pw.Text("Invoice--${InvoicesCountUSD.toStringAsFixed(2)}--${InvoicesTotalAmountUSD.toStringAsFixed(2)}", 
//                 style: pw.TextStyle(fontWeight: pw.FontWeight.bold,fontSize: 10)
//               ),
//               pw.Text("CreditNotes--${CreditNotesCountUSD.toStringAsFixed(2)}--${CreditNotesTotalAmountUSD.toStringAsFixed(2)}", 
//                 style: pw.TextStyle(fontWeight: pw.FontWeight.bold,fontSize: 10)
//               ),
//               pw.Text("Docs--${TotalDocumentsCountUSD.toStringAsFixed(2)}--${TotalDocumentsTotalAmountUSD.toStringAsFixed(2)}", 
//                 style: pw.TextStyle(fontWeight: pw.FontWeight.bold,fontSize: 10)
//               ),
//               pw.Divider(),
//               pw.Text("ZAR",
//                 style: pw.TextStyle(fontSize:9, fontWeight: pw.FontWeight.bold)
//               ),
//               pw.SizedBox(height: 20),
//               pw.Text("TOTAL NET SALES",
//                 style: pw.TextStyle(fontSize:9, fontWeight: pw.FontWeight.bold)
//               ),
//               pw.Text("Net , VAT 15%: ${NetVAT15TotalZAR.toStringAsFixed(2)}",
//                 style: pw.TextStyle(fontSize:9, fontWeight: pw.FontWeight.normal)
//               ),
//               pw.Text("Net , Non-VAT 0%: ${NetNonVATTotalZAR.toStringAsFixed(2)}",
//                 style: pw.TextStyle(fontSize:9, fontWeight: pw.FontWeight.normal)
//               ),
//               pw.Text("Net , Exempt: ${NetExemptTotalZAR.toStringAsFixed(2)}",
//                 style: pw.TextStyle(fontSize:9, fontWeight: pw.FontWeight.normal)
//               ),
//               pw.Text("Total Net Amount: ${NetTotalZAR.toStringAsFixed(2)}",
//                 style: pw.TextStyle(fontSize:9, fontWeight: pw.FontWeight.normal)
//               ),
//               pw.SizedBox(height: 20),
//               pw.Text("TOTAL TAXES",
//                 style: pw.TextStyle(fontSize:9, fontWeight: pw.FontWeight.bold)
//               ),
//               pw.Text("Tax , VAT 15 %: ${TaxVAT15ZAR.toStringAsFixed(2)}",
//                 style: pw.TextStyle(fontSize:9, fontWeight: pw.FontWeight.normal)
//               ),
//               pw.Text("Total tax amount: ${TaxTotalZAR.toStringAsFixed(2)}",
//                 style: pw.TextStyle(fontSize:9, fontWeight: pw.FontWeight.normal)
//               ),
//               pw.SizedBox(height: 20),
//               pw.Text("TOTAL GROSS SALES",
//                 style: pw.TextStyle(fontSize:9, fontWeight: pw.FontWeight.bold)
//               ),
//               pw.Text("Total , VAT 15 %: ${GrossTotalVAT15ZAR.toStringAsFixed(2)}",
//                 style: pw.TextStyle(fontSize:9, fontWeight: pw.FontWeight.normal)
//               ),
//               pw.Text("Total , Non-VAT 0 %: ${GrossTotalNonVATZAR.toStringAsFixed(2)}",
//                 style: pw.TextStyle(fontSize:9, fontWeight: pw.FontWeight.normal)
//               ),
//               pw.Text("Total , Exempt: ${GrossTotalExemptZAR.toStringAsFixed(2)}",
//                 style: pw.TextStyle(fontSize:9, fontWeight: pw.FontWeight.normal)
//               ),
//               pw.Text("Total gross amount: ${GrossTotalZAR.toStringAsFixed(2)}",
//                 style: pw.TextStyle(fontSize:9, fontWeight: pw.FontWeight.normal)
//               ),
//               pw.SizedBox(height: 20),
//               pw.Text("Documents--Quantity--Total", 
//                 style: pw.TextStyle(fontWeight: pw.FontWeight.bold,fontSize: 10)
//               ),
//               pw.Text("Invoice--${InvoicesCountZAR.toStringAsFixed(2)}--${InvoicesTotalAmountZAR.toStringAsFixed(2)}", 
//                 style: pw.TextStyle(fontWeight: pw.FontWeight.bold,fontSize: 10)
//               ),
//               pw.Text("CreditNotes--${CreditNotesCountZAR.toStringAsFixed(2)}--${CreditNotesTotalAmountZAR.toStringAsFixed(2)}", 
//                 style: pw.TextStyle(fontWeight: pw.FontWeight.bold,fontSize: 10)
//               ),
//               pw.Text("Docs--${TotalDocumentsCountZAR.toStringAsFixed(2)}--${TotalDocumentsTotalAmountZAR.toStringAsFixed(2)}", 
//                 style: pw.TextStyle(fontWeight: pw.FontWeight.bold,fontSize: 10)
//               ),
//             ]
//           )
//         ]
//       )
//     );
//     if (selectedPrinter != null) {
//       await Printing.directPrintPdf(
//         printer: selectedPrinter,
//         onLayout: (PdfPageFormat format) async => pdf.save(),
//       );
//     } else {
//       // Otherwise open the print dialog
//       await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save());
//     }
//   }

//   //======================== PRINT 80MM RECEIPT======================================================================

//   Future<void> print80mmReceipt({
//     required Map<String, dynamic> receipt,
//     required String qrUrl,
//     required String qrData,
//     Printer? selectedPrinter, // Optional silent print
//   }) async {
//     final pdf = pw.Document();

//     String formattedQrData = formatString(qrData);   
//     pdf.addPage(
//       pw.MultiPage(
//         pageFormat: PdfPageFormat(80 * PdfPageFormat.mm, PdfPageFormat.a4.height), // Or set custom height
//         maxPages: 100,
//         build: (pw.Context context) => [
//           pw.Padding(
//             padding: const pw.EdgeInsets.symmetric(horizontal: 10),
//             child:
//           pw.Column(
//             crossAxisAlignment: pw.CrossAxisAlignment.start,
//             children: [
//               pw.Container(
//                 alignment: pw.Alignment.center,
//                 child: pw.Text(
//                 "$tradeName",
//                 style: pw.TextStyle(fontSize:10, fontWeight: pw.FontWeight.bold),
//                 textAlign: pw.TextAlign.center,
//               ),
//               ),
//               pw.Container(
//                 alignment: pw.Alignment.center,
//                 child: pw.Text(
//                 "TIN: $taxPayerTIN",
//                 style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.normal),
//                 textAlign: pw.TextAlign.center,
//               ),
//               ),
//               pw.SizedBox(height: 3),
//               pw.Container(
//                 alignment: pw.Alignment.center,
//                 child: pw.Text(
//                 "VAT No: $taxPayerVatNumber",
//                 style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.normal),
//                 textAlign: pw.TextAlign.center,
//               ),
//               ),
//               pw.SizedBox(height: 3),
//               pw.Container(
//                 alignment: pw.Alignment.center,
//                 child: pw.Text(
//                 "$taxPayerAddress",
//                 style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.normal),
//                 textAlign: pw.TextAlign.center,
//               ),
//               ),
//               pw.SizedBox(height: 3),
//               pw.Container(
//                 alignment: pw.Alignment.center,
//                   child: pw.Text(
//                   "$taxPayerEmail",
//                   style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.normal),
//                   textAlign: pw.TextAlign.center,
//                 ),
//               ),
//               pw.SizedBox(height: 3),
//               pw.Container(
//                 alignment: pw.Alignment.center,
//                 child: pw.SizedBox(
//                 child: pw.Text(
//                 "$taxPayerPhone",
//                 style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.normal),
//                 textAlign: pw.TextAlign.center,
//               ),
//               ),
//               ),
//               pw.Divider(),
//               isReceiptCreditNote == 1 ?
//                 pw.Container(
//                 alignment: pw.Alignment.center,
//                 child: pw.Text(
//                   "FISCAL CREDIT NOTE",
//                   style: pw.TextStyle(fontSize:9, fontWeight: pw.FontWeight.bold),
//                   textAlign: pw.TextAlign.center,
//                 ),
//               ): 
//               pw.Container(
//                 alignment: pw.Alignment.center,
//                 child: pw.Text(
//                   "FISCAL TAX INVOICE",
//                   style: pw.TextStyle(fontSize:9, fontWeight: pw.FontWeight.bold),
//                   textAlign: pw.TextAlign.center,
//                 ),
//               ),
//               pw.Divider(),
//               pw.Container(
//                 alignment: pw.Alignment.center,
//                 child: pw.Text(
//                 "Buyer",
//                 style: pw.TextStyle(fontSize:9, fontWeight: pw.FontWeight.bold),
//                 textAlign: pw.TextAlign.center,
//               ),
//               ),
//               pw.Container(
//                 alignment: pw.Alignment.center,
//                 child: pw.Text(
//                 "${receipt['buyerData']?['buyerTradeName'] ?? 'Walk-in Customer'}",
//                 style: pw.TextStyle(fontSize:9, fontWeight: pw.FontWeight.normal),
//                 textAlign: pw.TextAlign.center,
//               ),
//               ),
//               pw.Container(
//                 alignment: pw.Alignment.center,
//                 child: pw.Text(
//                 "TIN: ${receipt['buyerData']?['buyerTIN'] ?? 'N/A'}",
//                 style: pw.TextStyle(fontSize:9, fontWeight: pw.FontWeight.normal),
//                 textAlign: pw.TextAlign.center,
//               ),
//               ),
//               pw.Container(
//                 alignment: pw.Alignment.center,
//                 child: pw.Text(
//                 "VAT: ${receipt['buyerData']?['VATNumber'] ?? 'N/A'}",
//                 style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.normal),
//                 textAlign: pw.TextAlign.center,
//               ),
//               ),
//               // pw.Container(
//               //   alignment: pw.Alignment.center,
//               //   child: pw.Text(
//               //   "${receipt['buyerData']?['buyerAddress']['houseNo'] ?? 'N/A'}, ${receipt['buyerData']?['buyerAddress']['street'] ?? 'N/A'} ",
//               //   style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.normal),
//               //   textAlign: pw.TextAlign.center,
//               // ),
//               // ),
//               // pw.Container(
//               //   alignment: pw.Alignment.center,
//               //   child: pw.Text(
//               //   "${receipt['buyerData']?['buyerAddress']['city'] ?? 'N/A'}, ${receipt['buyerData']?['buyerAddress']['province'] ?? 'N/A'} ",
//               //   style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.normal),
//               //   textAlign: pw.TextAlign.center,
//               // ),
//               // ),
//               // pw.Container(
//               //   alignment: pw.Alignment.center,
//               //   child: pw.Text(
//               //   "${receipt['buyerData']?['buyerContactS']['email'] ?? 'N/A'}",
//               //   style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.normal),
//               //   textAlign: pw.TextAlign.center,
//               // ),
//               // ),
//               // pw.Container(
//               //   alignment: pw.Alignment.center,
//               //   child: pw.Text(
//               //   "${receipt['buyerData']?['buyerContactS']['phoneNo'] ?? 'N/A'}",
//               //   style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.normal),
//               //   textAlign: pw.TextAlign.center,
//               // ),
//               // ),
//               pw.Divider(),
//               pw.Text("Date: ${receipt['receiptDate'] ?? ''}",style: pw.TextStyle(fontSize:9, fontWeight: pw.FontWeight.normal)),
//               pw.Text("Currency: ${receipt['receiptCurrency'] ?? ''}",style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.normal)),
//               isReceiptCreditNote == 1 ?
//               pw.Text("CreditNote No: ${receipt['invoiceNo'] ?? '#########'}",style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.normal)) :
//               pw.Text("Invoice No: ${receipt['invoiceNo'] ?? '#########'}",style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.normal)),
//               isReceiptCreditNote == 1 ? 
//                 pw.Text("Credit Reason: ${receipt['receiptNotes'] ?? 'No reason provided'}",style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.normal)) :
//                 pw.SizedBox.shrink(),
//               pw.Divider(),
//               isReceiptCreditNote == 1 ?
//                 pw.Container(
//                   alignment: pw.Alignment.center,
//                   child: pw.Text(
//                   "Credited Invoice",
//                   style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
//                   textAlign: pw.TextAlign.center,
//                 ),
//                 ) :
//                 pw.SizedBox.shrink(),
//               isReceiptCreditNote == 1 ?
//                 pw.Text("Device Serial No: $serialNo", style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.normal)) :
//                 pw.SizedBox.shrink(),
//               isReceiptCreditNote == 1 ?
//                 pw.Text("Invoice No: ${receipt['creditDebitNote']['receiptGlobalNo']}", style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.normal)) :
//                 pw.SizedBox.shrink(),
//               isReceiptCreditNote == 1 ?
//                 pw.Text("Date: $dateForCreditNote", style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.normal)) :
//                 pw.SizedBox.shrink(),
//               isReceiptCreditNote == 1 ?
//                 pw.Text("Customer Reference No: CR-127" , style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.normal)) :
//                 pw.SizedBox.shrink(),
//               pw.Divider(),
//               pw.Text("Description", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
//               pw.Text("  Qty          UnitPrice          Vat              Total", style: pw.TextStyle(fontWeight: pw.FontWeight.bold,fontSize: 10)),
//               isReceiptCreditNote == 1 ? 
//               pw.Divider() : pw.SizedBox.shrink(),
//               ...List<pw.Widget>.from(
//                 (receipt['receiptLines'] as List<dynamic>).map((item) {
//                   double productUnitPrice = double.tryParse(item['receiptLinePrice']) ?? 0.0;
//                   final double productVat;
//                   final double producttax;
//                   final double totalAmount = double.tryParse(item['receiptLineTotal'].toString()) ?? 0.0;
//                   if(item['taxCode'] == 'C' || item['taxCode'] == 'B'){
//                     productVat = 0.00;
//                   } else{
//                     productVat = productUnitPrice - (productUnitPrice/1.15);
//                     productUnitPrice = productUnitPrice/1.15;
//                   }
//                   // return pw.Text(
//                   //   "${item['receiptLineName']} \n     ${item['receiptLineQuantity']}                    ${productUnitPrice.toStringAsFixed(2)}                     ${productVat.toStringAsFixed(2)}                 ${item['receiptLineTotal']}",
//                   //   style: pw.TextStyle(fontSize: 8,),
//                   // );
//                 return pw.Column(
//                   crossAxisAlignment: pw.CrossAxisAlignment.start,
//                   children: [
//                     pw.Text(
//                       "${item['receiptLineName']}",
//                       style: pw.TextStyle(fontSize: 8),
//                     ),
//                     pw.SizedBox(height: 2),
//                     pw.Row(
//                       mainAxisAlignment: pw.MainAxisAlignment.start,
//                       children: [
//                         // Quantity (tight width)
//                         pw.SizedBox(
//                           width: 25,
//                           child: pw.Text(
//                             "${item['receiptLineQuantity']}",
//                             style: pw.TextStyle(fontSize: 8),
//                             textAlign: pw.TextAlign.left,
//                           ),
//                         ),
//                         // Small space
//                         pw.SizedBox(width: 15),

//                         // Unit Price (fixed width)
//                         pw.SizedBox(
//                           width: 40,
//                           child: pw.Text(
//                             productUnitPrice.toStringAsFixed(2),
//                             style: pw.TextStyle(fontSize: 8),
//                             textAlign: pw.TextAlign.right,
//                           ),
//                         ),

//                         pw.SizedBox(width: 20),

//                         // VAT (tight width)
//                         pw.SizedBox(
//                           width: 35,
//                           child: pw.Text(
//                             productVat.toStringAsFixed(2),
//                             style: pw.TextStyle(fontSize: 8),
//                             textAlign: pw.TextAlign.right,
//                           ),
//                         ),

//                         pw.SizedBox(width: 15),

//                         // Total (takes remaining space)
//                         pw.SizedBox(
//                           width: 50,
//                           child: pw.Text(
//                             "${item['receiptLineTotal']}",
//                             style: pw.TextStyle(fontSize: 8),
//                             textAlign: pw.TextAlign.right,
//                             softWrap: false,
//                             overflow: pw.TextOverflow.clip,
//                           ),
//                         ),
//                       ],
//                     ),
//                     pw.SizedBox(height: 4),
//                   ],
//                 );

//                 }),
//               ),
//               pw.Divider(),
//               // pw.Row(
//               //   mainAxisAlignment: pw.MainAxisAlignment.start,
//               //   children: [
//               //     pw.Text("SUBTOTAL:",style: pw.TextStyle(fontSize: 8,)),
//               //     pw.SizedBox(
//               //             width: 154,
//               //             child: pw.Text(
//               //               "$currentInvoiceSubtotal",
//               //               style: pw.TextStyle(fontSize: 8),
//               //               textAlign: pw.TextAlign.right,
//               //               softWrap: false,
//               //               overflow: pw.TextOverflow.clip,
//               //             ),
//               //           ),
//               //   ]
//               // ),
//               pw.SizedBox(height: 3),
//               //pw.Text("TOTAL VAT                                                                $receipttotalVat", style: pw.TextStyle(fontSize: 8,)),
//               pw.Row(
//                 mainAxisAlignment: pw.MainAxisAlignment.start,
//                 children: [
//                   pw.Text("TOTAL VAT:",style: pw.TextStyle(fontSize: 8,)),
//                   pw.SizedBox(
//                           width: 154,
//                           child: pw.Text(
//                             "$receipttotalVat",
//                             style: pw.TextStyle(fontSize: 8),
//                             textAlign: pw.TextAlign.right,
//                             softWrap: false,
//                             overflow: pw.TextOverflow.clip,
//                           ),
//                         ),
//                 ]
//               ),
//               pw.SizedBox(height: 3),
//               //pw.Text("TOTAL                                                                      $receiptinvoiceTotal" , style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
//               pw.Row(
//                 mainAxisAlignment: pw.MainAxisAlignment.start,
//                 children: [
//                   pw.Text("TOTAL         :",style: pw.TextStyle(fontSize: 8,)),
//                   pw.SizedBox(
//                           width: 152,
//                           child: pw.Text(
//                             "$receiptinvoiceTotal",
//                             style: pw.TextStyle(fontSize: 8),
//                             textAlign: pw.TextAlign.right,
//                             softWrap: false,
//                             overflow: pw.TextOverflow.clip,
//                           ),
//                         ),
//                 ]
//               ),
//               pw.Divider(),
//               //pw.Text("PAID                                                                        $paid", style: pw.TextStyle(fontSize: 8,)),

//               isReceiptCreditNote == 1 ? pw.SizedBox.shrink() :
//               pw.Row(
//                 mainAxisAlignment: pw.MainAxisAlignment.start,
//                 children: [
//                   pw.Text("PAID           :",style: pw.TextStyle(fontSize: 8,)),
//                   pw.SizedBox(
//                           width: 152,
//                           child: pw.Text(
//                             "$paid",
//                             style: pw.TextStyle(fontSize: 8),
//                             textAlign: pw.TextAlign.right,
//                             softWrap: false,
//                             overflow: pw.TextOverflow.clip,
//                           ),
//                         ),
//                 ]
//               ),
//               //pw.Text("CHANGE                                                                   $change", style: pw.TextStyle(fontSize: 8,)),
//               isReceiptCreditNote == 1 ? pw.SizedBox.shrink() :
//               pw.Row(
//                 mainAxisAlignment: pw.MainAxisAlignment.start,
//                 children: [
//                   pw.Text("CHANGE     :",style: pw.TextStyle(fontSize: 8,)),
//                   pw.SizedBox(
//                           width: 152,
//                           child: pw.Text(
//                             "$change",
//                             style: pw.TextStyle(fontSize: 8),
//                             textAlign: pw.TextAlign.right,
//                             softWrap: false,
//                             overflow: pw.TextOverflow.clip,
//                           ),
//                         ),
//                 ]
//               ),
//               pw.Divider(),
//               pw.Align(
//                 alignment: pw.Alignment.center,
//                 child: pw.BarcodeWidget(
//                 barcode: pw.Barcode.qrCode(),
//                 data: qrUrl,
//                 width: 50,
//                 height: 50,
//               ),
//               ),
//               pw.SizedBox(height: 3),
//               pw.Container(
//                 alignment: pw.Alignment.center,
//                 child: pw.Text(
//                 "You can verify this manually at https://fdms.zimra.co.zw",
//                 style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.normal),
//                 textAlign: pw.TextAlign.center,
//               ),
//               ),
//               pw.SizedBox(height: 3),
//               pw.Container(
//                 alignment: pw.Alignment.center,
//                 child: pw.Text(
//                 "Verification Code:\n$formattedQrData",
//                 style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.normal),
//                 textAlign: pw.TextAlign.center,
//               ),
//               ),
//               pw.Container(
//                 alignment: pw.Alignment.center,
//                 child: pw.Text(
//                 "DeviceID : $deviceID",
//                 style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.normal),
//                 textAlign: pw.TextAlign.center,
//               ),
//               ),
//               pw.Container(
//                 alignment: pw.Alignment.center,
//                 child: pw.Text(
//                 "Fiscal Day No: $currentFiscal",
//                 style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.normal),
//                 textAlign: pw.TextAlign.center,
//               ),
//               ),
//               pw.Container(
//                 alignment: pw.Alignment.center,
//                 child: pw.Text(
//                 "Invoice No: ${receipt['receiptGlobalNo']}",
//                 style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.normal),
//                 textAlign: pw.TextAlign.center,
//               ),
//               ),
//               pw.SizedBox(height: 8),
//               pw.Container(
//                 alignment: pw.Alignment.center,
//                 child: pw.Text(
//                 "Powered by tigerweb.co.zw",
//                 style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.normal),
//                 textAlign: pw.TextAlign.center,
//               ),
//               ),
//               pw.Text("", textAlign: pw.TextAlign.center),
//             ],
//           )
//           )
//       ],
//     ),
//   );

//   // Print silently if printer is provided
//   if (selectedPrinter != null) {
//     await Printing.directPrintPdf(
//       printer: selectedPrinter,
//       onLayout: (PdfPageFormat format) async => pdf.save(),
//     );
//   } else {
//     // Otherwise open the print dialog
//     await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save());
//   }
// }

//   ///======================================Print 58mm Receipt================================================
//   Future<void> print58mmReceipt({
//     required Map<String, dynamic> receipt,
//     required String qrUrl,
//     required String qrData,
//     Printer? selectedPrinter, // Optional silent print
//   }) async {
//     final pdf = pw.Document();

//     String formattedQrData = formatString(qrData);   
//     pdf.addPage(
//       pw.MultiPage(
//         pageFormat: PdfPageFormat(58 * PdfPageFormat.mm, PdfPageFormat.a4.height), // Or set custom height
//         maxPages: 100,
//         build: (pw.Context context) => [
//           pw.Column(
//             crossAxisAlignment: pw.CrossAxisAlignment.start,
//             children: [
//               pw.Container(
//                 alignment: pw.Alignment.center,
//                 child: pw.Text(
//                 "$tradeName",
//                 style: pw.TextStyle(fontSize:10, fontWeight: pw.FontWeight.bold),
//                 textAlign: pw.TextAlign.center,
//               ),
//               ),
//               pw.Container(
//                 alignment: pw.Alignment.center,
//                 child: pw.Text(
//                 "TIN: $taxPayerTIN",
//                 style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.normal),
//                 textAlign: pw.TextAlign.center,
//               ),
//               ),
//               pw.SizedBox(height: 3),
//               pw.Container(
//                 alignment: pw.Alignment.center,
//                 child: pw.Text(
//                 "VAT No: $taxPayerVatNumber",
//                 style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.normal),
//                 textAlign: pw.TextAlign.center,
//               ),
//               ),
//               pw.SizedBox(height: 3),
//               pw.Container(
//                 alignment: pw.Alignment.center,
//                 child: pw.Text(
//                 "$taxPayerAddress",
//                 style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.normal),
//                 textAlign: pw.TextAlign.center,
//               ),
//               ),
//               pw.SizedBox(height: 3),
//               pw.Container(
//                 alignment: pw.Alignment.center,
//                   child: pw.Text(
//                   "$taxPayerEmail",
//                   style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.normal),
//                   textAlign: pw.TextAlign.center,
//                 ),
//               ),
//               pw.SizedBox(height: 3),
//               pw.Container(
//                 alignment: pw.Alignment.center,
//                 child: pw.SizedBox(
//                 child: pw.Text(
//                 "$taxPayerPhone",
//                 style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.normal),
//                 textAlign: pw.TextAlign.center,
//               ),
//               ),
//               ),
//               pw.Divider(),
//               isReceiptCreditNote == 1 ?
//                 pw.Container(
//                 alignment: pw.Alignment.center,
//                 child: pw.Text(
//                   "FISCAL CREDIT NOTE",
//                   style: pw.TextStyle(fontSize:9, fontWeight: pw.FontWeight.bold),
//                   textAlign: pw.TextAlign.center,
//                 ),
//               ): 
//               pw.Container(
//                 alignment: pw.Alignment.center,
//                 child: pw.Text(
//                   "FISCAL TAX INVOICE",
//                   style: pw.TextStyle(fontSize:9, fontWeight: pw.FontWeight.bold),
//                   textAlign: pw.TextAlign.center,
//                 ),
//               ),
//               pw.Divider(),
//               pw.Container(
//                 alignment: pw.Alignment.center,
//                 child: pw.Text(
//                 "Buyer",
//                 style: pw.TextStyle(fontSize:9, fontWeight: pw.FontWeight.bold),
//                 textAlign: pw.TextAlign.center,
//               ),
//               ),
//               pw.Container(
//                 alignment: pw.Alignment.center,
//                 child: pw.Text(
//                 "${receipt['buyerData']?['buyerTradeName'] ?? 'Walk-in Customer'}",
//                 style: pw.TextStyle(fontSize:9, fontWeight: pw.FontWeight.normal),
//                 textAlign: pw.TextAlign.center,
//               ),
//               ),
//               pw.Container(
//                 alignment: pw.Alignment.center,
//                 child: pw.Text(
//                 "TIN: ${receipt['buyerData']?['buyerTIN'] ?? 'N/A'}",
//                 style: pw.TextStyle(fontSize:9, fontWeight: pw.FontWeight.normal),
//                 textAlign: pw.TextAlign.center,
//               ),
//               ),
//               pw.Container(
//                 alignment: pw.Alignment.center,
//                 child: pw.Text(
//                 "VAT: ${receipt['buyerData']?['VATNumber'] ?? 'N/A'}",
//                 style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.normal),
//                 textAlign: pw.TextAlign.center,
//               ),
//               ),
//               pw.Container(
//                 alignment: pw.Alignment.center,
//                 child: pw.Text(
//                 "${receipt['buyerData']?['buyerAddress']['houseNo'] ?? 'N/A'}, ${receipt['buyerData']?['buyerAddress']['street'] ?? 'N/A'} ",
//                 style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.normal),
//                 textAlign: pw.TextAlign.center,
//               ),
//               ),
//               pw.Container(
//                 alignment: pw.Alignment.center,
//                 child: pw.Text(
//                 "${receipt['buyerData']?['buyerAddress']['city'] ?? 'N/A'}, ${receipt['buyerData']?['buyerAddress']['province'] ?? 'N/A'} ",
//                 style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.normal),
//                 textAlign: pw.TextAlign.center,
//               ),
//               ),
//               pw.Container(
//                 alignment: pw.Alignment.center,
//                 child: pw.Text(
//                 "${receipt['buyerData']?['buyerContactS']['email'] ?? 'N/A'}",
//                 style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.normal),
//                 textAlign: pw.TextAlign.center,
//               ),
//               ),
//               pw.Container(
//                 alignment: pw.Alignment.center,
//                 child: pw.Text(
//                 "${receipt['buyerData']?['buyerContactS']['phoneNo'] ?? 'N/A'}",
//                 style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.normal),
//                 textAlign: pw.TextAlign.center,
//               ),
//               ),
//               pw.Divider(),
//               pw.Text("Date: ${receipt['receiptDate'] ?? ''}",style: pw.TextStyle(fontSize:9, fontWeight: pw.FontWeight.normal)),
//               pw.Text("Currency: ${receipt['receiptCurrency'] ?? ''}",style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.normal)),
//               isReceiptCreditNote == 1 ?
//               pw.Text("CreditNote No: ${receipt['invoiceNo'] ?? '#########'}",style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.normal)) :
//               pw.Text("Invoice No: ${receipt['invoiceNo'] ?? '#########'}",style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.normal)),
//               isReceiptCreditNote == 1 ? 
//                 pw.Text("Credit Reason: ${receipt['receiptNotes'] ?? 'No reason provided'}",style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.normal)) :
//                 pw.SizedBox.shrink(),
//               pw.Divider(),
//               isReceiptCreditNote == 1 ?
//                 pw.Container(
//                   alignment: pw.Alignment.center,
//                   child: pw.Text(
//                   "Credited Invoice",
//                   style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
//                   textAlign: pw.TextAlign.center,
//                 ),
//                 ) :
//                 pw.SizedBox.shrink(),
//               isReceiptCreditNote == 1 ?
//                 pw.Text("Device Serial No: $serialNo", style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.normal)) :
//                 pw.SizedBox.shrink(),
//               isReceiptCreditNote == 1 ?
//                 pw.Text("Invoice No: ${receipt['creditDebitNote']['receiptGlobalNo']}", style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.normal)) :
//                 pw.SizedBox.shrink(),
//               isReceiptCreditNote == 1 ?
//                 pw.Text("Date: $dateForCreditNote", style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.normal)) :
//                 pw.SizedBox.shrink(),
//               isReceiptCreditNote == 1 ?
//                 pw.Text("Customer Reference No: CR-127" , style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.normal)) :
//                 pw.SizedBox.shrink(),
//               pw.Divider(),
//               pw.Text("Description x Qty", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
//               pw.Text("UnitPrice---Vat---Total", style: pw.TextStyle(fontWeight: pw.FontWeight.bold,fontSize: 10)),
//               isReceiptCreditNote == 1 ? 
//               pw.Divider() : pw.SizedBox.shrink(),
//               ...List<pw.Widget>.from(
//                 (receipt['receiptLines'] as List<dynamic>).map((item) {
//                   double productUnitPrice = double.tryParse(item['receiptLinePrice']) ?? 0.0;
//                   final double productVat;
//                   final double producttax;
//                   final double totalAmount = double.tryParse(item['receiptLineTotal'].toString()) ?? 0.0;
//                   if(item['taxCode'] == 'C' || item['taxCode'] == 'B'){
//                     productVat = 0.00;
//                   } else{
//                     productVat = productUnitPrice - (productUnitPrice/1.15);
//                     productUnitPrice = productUnitPrice/1.15;
//                   }
//                   // return pw.Text(
//                   //   "${item['receiptLineName']} \n     ${item['receiptLineQuantity']}                    ${productUnitPrice.toStringAsFixed(2)}                     ${productVat.toStringAsFixed(2)}                 ${item['receiptLineTotal']}",
//                   //   style: pw.TextStyle(fontSize: 8,),
//                   // );
//                 return pw.Column(
//                   crossAxisAlignment: pw.CrossAxisAlignment.start,
//                   children: [
//                     pw.Text(
//                       "${item['receiptLineName']} x ${item['receiptLineQuantity']}",
//                       style: pw.TextStyle(fontSize: 8),
//                     ),
//                     pw.SizedBox(height: 2),
//                      pw.Text(
//                       "${productUnitPrice.toStringAsFixed(2)}---${productVat.toStringAsFixed(2)}---${item['receiptLineTotal']}",
//                       style: pw.TextStyle(fontSize: 8),
//                     ),
//                   ],
//                 );

//                 }),
//               ),
//               pw.Divider(),
//               pw.Text("SUBTOTAL:-----$currentInvoiceSubtotal",style: pw.TextStyle(fontSize: 8,)),
//               pw.Text("TOTAL VAT:----$receipttotalVat",style: pw.TextStyle(fontSize: 8,)),
//               pw.Text("TOTAL:--------$receiptinvoiceTotal",style: pw.TextStyle(fontSize: 8,)),
//               pw.Divider(),
//               isReceiptCreditNote == 1 ? pw.SizedBox.shrink() :
//               pw.Text("PAID:---------$paid",style: pw.TextStyle(fontSize: 8,)),
//               isReceiptCreditNote == 1 ? pw.SizedBox.shrink() :
//               pw.Text("CHANGE:-------$change",style: pw.TextStyle(fontSize: 8,)),
//               pw.Divider(),
//               pw.Align(
//                 alignment: pw.Alignment.center,
//                 child: pw.BarcodeWidget(
//                 barcode: pw.Barcode.qrCode(),
//                 data: qrUrl,
//                 width: 50,
//                 height: 50,
//               ),
//               ),
//               pw.SizedBox(height: 3),
//               pw.Container(
//                 alignment: pw.Alignment.center,
//                 child: pw.Text(
//                 "Verify at https://fdms.zimra.co.zw",
//                 style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.normal),
//                 textAlign: pw.TextAlign.center,
//               ),
//               ),
//               pw.SizedBox(height: 3),
//               pw.Container(
//                 alignment: pw.Alignment.center,
//                 child: pw.Text(
//                 "Verification Code:\n$formattedQrData",
//                 style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.normal),
//                 textAlign: pw.TextAlign.center,
//               ),
//               ),
//               pw.Container(
//                 alignment: pw.Alignment.center,
//                 child: pw.Text(
//                 "DeviceID : $deviceID",
//                 style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.normal),
//                 textAlign: pw.TextAlign.center,
//               ),
//               ),
//               pw.Container(
//                 alignment: pw.Alignment.center,
//                 child: pw.Text(
//                 "Fiscal Day No: $currentFiscal",
//                 style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.normal),
//                 textAlign: pw.TextAlign.center,
//               ),
//               ),
//               pw.Container(
//                 alignment: pw.Alignment.center,
//                 child: pw.Text(
//                 "Invoice No: ${receipt['receiptGlobalNo']}",
//                 style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.normal),
//                 textAlign: pw.TextAlign.center,
//               ),
//               ),
//               pw.SizedBox(height: 8),
//               pw.Container(
//                 alignment: pw.Alignment.center,
//                 child: pw.Text(
//                 "Powered by tigerweb.co.zw",
//                 style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.normal),
//                 textAlign: pw.TextAlign.center,
//               ),
//               ),
//               pw.Text("", textAlign: pw.TextAlign.center),
//             ],
//           )
//       ],
//     ),
//   );

//   // Print silently if printer is provided
//   if (selectedPrinter != null) {
//     await Printing.directPrintPdf(
//       printer: selectedPrinter,
//       onLayout: (PdfPageFormat format) async => pdf.save(),
//     );
//   } else {
//     // Otherwise open the print dialog
//     await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save());
//   }
// }

//   Queue<File> pendingFiles = Queue<File>();


//   //=====================UPDATED START ENGINE==================================================///////
//   Future<bool> waitForFileComplete(File file, {Duration timeout = const Duration(seconds: 5)}) async {
//     final stopwatch = Stopwatch()..start();
//     int lastSize = -1;

//     while (stopwatch.elapsed < timeout) {
//       await Future.delayed(Duration(milliseconds: 200));
//       final currentSize = await file.length();
//       if (currentSize == lastSize) {
//         return true; // File size hasn't changed → likely complete
//       }
//       lastSize = currentSize;
//     }
//     return false; // Timed out
//   }

//   void startEngine() {
//     totalAmount = 0.0;
//     taxAmount = 0.0;
//     receiptItems.clear();
//     selectedCustomer.clear();
//     currentReceiptGlobalNo = "";
//     currentUrl = "";
//     currentDayNo = "";
//     if (isRunning) return;
//     setState(() => isRunning = true);
//     print("🟢 Engine Started");

//     final inputWatcher = DirectoryWatcher(inputFolder.path);
//     final signedWatcher = DirectoryWatcher(signedFolder.path);

//     inputSub = inputWatcher.events.listen((event) async {
//       if (event.type == ChangeType.ADD && event.path.toLowerCase().endsWith('.pdf')) {
//         final file = File(event.path);

//         if (!pendingFiles.any((f) => f.path == file.path)) {
//           final isComplete = await waitForFileComplete(file);
//           if (isComplete) {
//             pendingFiles.add(file);
//             print("📥 Queued: ${file.path}");
//             processNext();
//           } else {
//             print("⚠️ Skipped (incomplete): ${file.path}");
//           }
//         }
//       }
//     });

//     signedSub = signedWatcher.events.listen((event) async {
//       if (event.type == ChangeType.ADD && event.path.toLowerCase().endsWith('.pdf')) {
//         await processNext();
//       }
//     });

//     // 🔍 Scan and queue any existing .pdf files in the input folder at startup
//     final existingFiles = inputFolder
//         .listSync()
//         .whereType<File>()
//         .where((file) => file.path.toLowerCase().endsWith('.pdf'));

//     for (final file in existingFiles) {
//       if (!pendingFiles.any((f) => f.path == file.path)) {
//         pendingFiles.add(file);
//         print("📁 Found existing: ${file.path}");
//       }
//     }

//     // ▶️ Start processing queue
//     processNext();
//   }

//    void killEngine() {
//     setState(() => isRunning = false);
//     print("🔴 Engine Stopped");

//     inputSub?.cancel();
//     signedSub?.cancel();
//   }

//   //Process next PDF file
//   Map<String, dynamic> invoiceDetails = {};

//   ////==========================UPDATED PROCESS NEXT ===================================================////
//   ///
//   ///
//   void logToFile(String message) async {
//     final logFile = File('C:/FDMS-gateway/Files/log.txt'); // or better, use app data dir
//     final timestamp = DateTime.now().toIso8601String();
//     await logFile.writeAsString('[$timestamp] $message\n', mode: FileMode.append);
//   }

//   Future<void> stampInvoice(File file, String dayNo, String receiptGlobalNo, String qrData , String verificationCode) async {
//     final uri = Uri.parse('http://127.0.0.1:5000/stamp_invoice'); // or use your server IP

//     final request = http.MultipartRequest('POST', uri)
//       ..fields['day_no'] = dayNo
//       ..fields['receipt_global_no'] = receiptGlobalNo
//       ..fields['qrURL'] = qrData
//       ..fields['verification'] = verificationCode
//       ..files.add(await http.MultipartFile.fromPath('file', file.path));

//     final response = await request.send();

//     if (response.statusCode == 200) {
//       final bytes = await response.stream.toBytes();
//       final stampedFile = File('${file.parent.path}/Stamped_${path.basename(file.path)}');
//       await stampedFile.writeAsBytes(bytes);
//       print('✅ Stamped invoice saved at: ${stampedFile.path}');
//     } else {
//       print('❌ Failed to stamp invoice. Status: ${response.statusCode}');
//     }
//   }

//   Future<void> processNext() async {
//     print("🚦 processNext called | isProcessing: $isProcessing | queue: ${pendingFiles.length}");
//     if (!isRunning || isProcessing || pendingFiles.isEmpty) return;

//     isProcessing = true;
//     final file = pendingFiles.removeFirst();
//     receiptItems.clear();

//     print("📤 Uploading: ${path.basename(file.path)}");

//     try {
//       final uri = Uri.parse(
//         isReceipt == 1
//             ? "http://localhost:5000/extract_receipt"
//             : "http://localhost:5000/extract_invoice"
//       );

//       final request = http.MultipartRequest('POST', uri)
//         ..files.add(await http.MultipartFile.fromPath('file', file.path));

//       final streamedResponse = await request.send();
//       final response = await http.Response.fromStream(streamedResponse);

//       if (response.statusCode == 200) {
//         final Map<String, dynamic> responseData = jsonDecode(response.body);
//         final String documentType = responseData['document_type'];

//         if (isReceipt == 1) {
//           if (documentType == 'receipt') {
//             final List<dynamic> tableData = responseData['line_items'];
//             final Map<String, dynamic> customerDetails = responseData['customer_details'];
//             final Map<String, dynamic> totals = responseData['totals'];
//             final buyerAddress = customerDetails['buyerAddress'];

//             setState(() {
//               currentInvoiceSubtotal = totals['invoice_subtotal'];
//               receipttotalVat = totals['total_vat'];
//               transactionCurrency = responseData['invoice_currency'];
//               currentInvoiceNumber = responseData['invoice_number'];
//               receiptinvoiceTotal = totals['invoice_total'];
//               paid = totals['paid'];
//               change = totals['change'];

//               if (customerDetails['name'] == 'Cash' || customerDetails['name'] == null) {
//                 selectedCustomer.clear();
//               } else {
//                 selectedCustomer.add({
//                   'customerName': customerDetails['name'],
//                   'customerVAT': customerDetails['vat_number'],
//                   'customerTIN': customerDetails['tin'],
//                   'customerPhone': customerDetails['phone'],
//                   'customerEmail': customerDetails['email'] != "null"
//                       ? customerDetails['email']
//                       : 'noemail@email.com',
//                   'houseNO': buyerAddress['houseNo'],
//                   'street': buyerAddress['street'],
//                   'province': buyerAddress['province'],
//                   'city': buyerAddress['city']
//                 });
//               }
//             });

//             print("adding items");
//             await addReceiptItem(tableData);
//             print("done with adding items");
//             await generateFiscalJSON();
//             await submitReceipt();

//             final destPath = path.join(signedFolder.path, path.basename(file.path));
//             await file.rename(destPath);
//             print("📁 Moved to Signed: ${path.basename(destPath)}");

//           } else if (documentType == 'credit_note') {
//             isReceiptCreditNote = 1;
//             final Map<String, dynamic> creditNoteDetails = responseData['credit_note_details'];
//             final List<dynamic> tableData = responseData['line_items'];
//             //final Map<String, dynamic> totals = responseData['totals'];
//             final Map<String, dynamic> totals = creditNoteDetails['creditNote_totals'];
//             final String reference = creditNoteDetails['reference_number'];
//             final String reason = creditNoteDetails['reason_for_credit'] ?? 'Not Provided';

//             currentInvoiceNumber = creditNoteDetails['credit_note_number'];

//             setState(() {
//               creditReason = reason;
//               creditedInvoice = reference;
//               //receiptinvoiceTotal = totals['invoice_total'];
//               receiptinvoiceTotal = totals['credit_total'];
//               //currentInvoiceSubtotal = totals['invoice_subtotal'];
//               receipttotalVat = totals['total_vat'];
//               //paid = totals['paid'];
//             });

//             await generateCreditFiscalJSON();
//             final destPath = path.join(signedFolder.path, path.basename(file.path));
//             await file.rename(destPath);
//             print("📁 Moved to Signed: ${path.basename(destPath)}");
//           }

//         } else {
//           // Invoice branch
//           if (documentType == 'invoice') {

//             final List<dynamic> tableData = responseData['line_items'];
//             final Map<String, dynamic> invoiceDetailsInner = responseData['invoice_details'];

//             setState(() {
//               invoiceDetails = invoiceDetailsInner;
//               transactionCurrency = responseData['currency'];
//               currentInvoiceNumber = responseData['invoice_number'];

//               if (invoiceDetailsInner['customer_name'] == 'Cash' || invoiceDetailsInner['customer_name'] == '') {
//                 selectedCustomer.clear();
//               } else {
//                 final buyerAddress = invoiceDetailsInner['buyerAddress'];
//                 selectedCustomer.add({
//                   'customerName': invoiceDetailsInner['customer_name'],
//                   'customerVAT': invoiceDetailsInner['buyer_vat'],
//                   'customerTIN': invoiceDetailsInner['buyer_tin'],
//                   'customerPhone': invoiceDetailsInner['phone'],
//                   'customerEmail': invoiceDetailsInner['email'],
//                   'houseNO': buyerAddress['houseNo'],
//                   'street': buyerAddress['street'],
//                   'province': buyerAddress['province'],
//                   'city': buyerAddress['city']
//                 });
//               }
//             });
//             print("adding items");
//             await addItem(tableData);
//             print("done with adding items");
//             await generateFiscalJSON();
//             bool success = await submitReceipt();
//             if(success == true){
//               final destPath = path.join(originalFilesFolder.path, path.basename(file.path));
//               await file.rename(destPath);
//               print("📁 Moved to Original Files: ${path.basename(destPath)}");
//               await stampInvoice(
//                 File(destPath),
//                   "$stampDayNo",                         // replace with your dynamic day number
//                   "$stampReceiptGlobalNumber",                 // replace with actual global receipt number
//                   "$stampQRData",
//                   "$stampVerificationCode"          // replace with the actual QR data
//               );
//             }else{
//               final destPath = path.join(unsignedFolder.path , path.basename(file.path));
//               await file.rename(destPath);
//             }
//           } else if (documentType == 'credit_note') {
//             final Map<String, dynamic> creditNoteDetails = responseData['credit_note_details'];
//             final List<dynamic> tableData = responseData['line_items'];
//             final String reference = creditNoteDetails['reference_number'];
//             final String reason = creditNoteDetails['reason_for_credit'] ?? 'Not Provided';

//             currentInvoiceNumber = creditNoteDetails['credit_note_number'];

//             setState(() {
//               creditReason = reason;
//               creditedInvoice = reference;
//             });

//             await generateCreditFiscalJSON();
//             final destPath = path.join(signedFolder.path, path.basename(file.path));
//             await file.rename(destPath);
//             print("📁 Moved to Signed: ${path.basename(destPath)}");
//             await stampInvoice(
//               File(destPath),
//               "$stampDayNo",                         // replace with your dynamic day number
//               "$stampReceiptGlobalNumber",                 // replace with actual global receipt number
//               "$stampQRData",
//               "$stampVerificationCode"          // replace with the actual QR data
//             );
//           }
//         }
//       } else {
//         print("❌ Server Error: ${response.statusCode}");
//       }
//     } catch (e) {
//       print("❌ Exception: $e");
//     } finally {
//       isProcessing = false;
//       await processNext(); // 🔁 Continue to next file
//     }
//   }

//   Future<String> createCreditNote(String receiptJsonString,
// {
//   required String fiscalDay ,
//   required String newReceiptGlobalNo,
//   required int newReceiptCounter,
//   required String newReceiptDate,
//   required String receiptID,
//   required String newSignature,
//   required String newHash,
// }) async {
//   // Parse the original receipt
//   final Map<String, dynamic> original = json.decode(receiptJsonString);
//   final Map<String, dynamic> receipt = original["receipt"];

//   // Clone the receipt to a new object
//   final Map<String, dynamic> creditNoteBody = Map.from(receipt);

//   String creditNoteNumber = await dbHelper.getNextCreditNoteNumber();
  
//   // 1. Negate receiptTaxes values
//   List<dynamic> originalTaxes = creditNoteBody["receiptTaxes"];
//   creditNoteBody["receiptTaxes"] = originalTaxes.map((tax) {
//     return {
//       ...tax,
//       "salesAmountWithTax": -1 * (double.tryParse(tax["salesAmountWithTax"].toString()) ?? 0.0),
//       "taxAmount": tax["taxAmount"] != "0" && tax["taxAmount"] !="0.00" ? (-1 * double.parse(tax["taxAmount"].toString())).toStringAsFixed(2) : tax["taxAmount"].toString(),
//     };
//   }).toList();

//   //negate receipt payments
//   List<dynamic> originalPayments = creditNoteBody["receiptPayments"];
//   creditNoteBody["receiptPayments"] = originalPayments.map((payment) {
//     return {
//       ...payment,
//       "paymentAmount":
//           (-1 * double.parse(payment["paymentAmount"].toString())).toStringAsFixed(2),
      
//     };
//   }).toList();
//   // 2. Negate receiptLines totals
//   List<dynamic> originalLines = creditNoteBody["receiptLines"];
//   creditNoteBody["receiptLines"] = originalLines.map((line) {
//     return {
//       ...line,
//       "receiptLineTotal":
//           (-1 * double.parse(line["receiptLineTotal"].toString())).toStringAsFixed(2),
//       "receiptLinePrice": (-1 * double.parse(line["receiptLinePrice"].toString())).toStringAsFixed(2) ,
//     };
//   }).toList();

//   // 3. Negate receiptTotal
//   creditNoteBody["receiptTotal"] =
//       (-1 * double.parse(creditNoteBody["receiptTotal"].toString())).toStringAsFixed(2);

//   // Update receiptGlobalNo, receiptCounter, receiptDate, and add receiptNotes
//   creditNoteBody["receiptGlobalNo"] = int.parse(newReceiptGlobalNo);
//   creditNoteBody["receiptCounter"] = newReceiptCounter;
//   creditNoteBody["receiptDate"] = newReceiptDate ;
//   creditNoteBody["receiptNotes"] = creditReason ?? "Credit Note";
//   creditNoteBody["invoiceNo"] = creditNoteNumber;
//   creditNoteBody["receiptType"] = "CREDITNOTE";
//   creditNoteBody["receiptDeviceSignature"]={
//     "signature" : newSignature,
//     "hash" : newHash
//   };

//   // 4. Wrap in creditDebitNote and add required fields
//   Map<String, dynamic> creditNote = {
//     "receipt":{
//     "creditDebitNote": {
//       "receiptGlobalNo": receipt["receiptGlobalNo"].toString(),
//       "fiscalDayNo": fiscalDay, // You can change this
//       "receiptID": receiptID, // You can generate or pass this
//       "deviceID": deviceID.toString(), // Set your device ID here
//     },
//     ...creditNoteBody,
//     }
//   };

//   // 5. Convert to JSON string
//   return json.encode(creditNote);
// }

// Future<void> generateCreditFiscalJSON() async{
//   final String invoiceId = creditedInvoice.toString();
//   print (" creditted Invoice ID: $invoiceId");
//   try {
//     print("Entered generate credit FiscalJSON");

//     String filePath = "/storage/emulated/0/Pulse/Configurations/steamTest_T_certificate.p12";
//     String password = "steamTest123";


//     int fiscalDayNo = await dbHelper.getlatestFiscalDay();
//     int nextReceiptCounter = await dbHelper.getNextReceiptCounter(fiscalDayNo);
//     int nextInvoice = await dbHelper.getNextInvoiceId();
//     int getReceiptGlobalNo = await dbHelper.getLatestReceiptGlobalNo();
//     int nextReceiptGlobalNo = getReceiptGlobalNo + 1;

//     DateTime now = DateTime.now();
//     String formattedDate = DateFormat("yyyy-MM-ddTHH:mm:ss").format(now);

//     List<Map<String, dynamic>> getSubmittedReceipt =  await dbHelper.getReceiptSubmittedById(invoiceId);
//     //int deviceId = 25395; // Replace with your actual device ID
//     String receiptJsonbody = getSubmittedReceipt[0]['receiptJsonbody'].toString();
//     String receiptID = getSubmittedReceipt[0]['receiptID'].toString();
//     String receiptGlobalNo = getSubmittedReceipt[0]['receiptGlobalNo'].toString();
//     String receiptFiscDayNo = getSubmittedReceipt[0]['FiscalDayNo'].toString();
//     String receiptDatetable = getSubmittedReceipt[0]['receiptDate'].toString();
//     setState(() {
//       dateForCreditNote = receiptDatetable;
//     });
//     Map<String, dynamic> jsonMap = jsonDecode(receiptJsonbody);
//     Map<String, dynamic> receipt = jsonMap["receipt"];
//     print(receipt);
//     String receiptType = "CREDITNOTE";
//     final String invoiceNumber = receipt['invoiceNo'].toString();
//     final String receiptDate = receipt['receiptDate'].toString();
//     String currency = receipt['receiptCurrency'].toString();
//     String totalAmount = receipt['receiptTotal'].toString();
//     double totalAmountDouble = double.parse(totalAmount);
//     int totalAmountInCents = (totalAmountDouble * 100 *-1).round();
//     //22662FISCALINVOICEUSD572025-04-18T12:57:41600B0.000200C15.00524006VTloJCYlWhu4kvKaGCnRkhP9CIlW66+W3QhQAnhkeI=
//     String taxesConcat = "";
//     String previousReceiptHash = await dbHelper.getLatestReceiptHash();
//     List<dynamic> taxes = receipt['receiptTaxes'];
//     print("taxes concat");
//     taxes.sort((a, b) => a['taxCode'].compareTo(b['taxCode']));
//     for(var tax in taxes){
//       String taxcode = tax['taxCode'].toString();
//       String taxPercent = tax['taxPercent'].toString();
//       //String taxId = tax['taxId'].toString();
//       //double taxAmount = double.parse(tax['taxAmount']);
//       double taxAmount = tax['taxAmount'] is String
//         ? double.parse(tax['taxAmount'])
//         : tax['taxAmount'].toDouble();
//       int taxAmountInCents = (taxAmount * 100 *-1).round();
//       //double SalesAmountwithTax = double.parse(tax['salesAmountWithTax']);
//       double SalesAmountwithTax = tax['salesAmountWithTax'] is String
//         ? double.parse(tax['salesAmountWithTax'])
//         : tax['salesAmountWithTax'].toDouble();
//       int salesAmountInCents = (SalesAmountwithTax * 100 *-1).round();
//       if(taxcode == "C"){
//         taxesConcat += "$taxcode$taxAmountInCents$salesAmountInCents";
//       }else{
//         taxesConcat += "$taxcode$taxPercent$taxAmountInCents$salesAmountInCents";
//       }
      
//     }
//     print(" after taxes concat");
//     String finalString = "$deviceID$receiptType$currency$nextReceiptGlobalNo$formattedDate$totalAmountInCents$taxesConcat$previousReceiptHash";
//     //CODE BELOW TO FOLLOW AFTER RECEIPT SUBMITTI
//     // Update the invoice status in the database (add your implementation here)f
//     finalString.trim();
//     var bytes = utf8.encode(finalString);
//     var digest = sha256.convert(bytes);
//     final hash = base64.encode(digest.bytes);

//     print(finalString);
//     print("Hash  : $hash");
//     //create creditnote json body

//     //ensure that signing does not fail
//     try {
//       //String data = await useRawString();
//       //List<String>? signature = await getSignatureSignature(data);
//       //receiptDeviceSignature_signature_hex = signature?[0];
//       //receiptDeviceSignature_signature  = signature?[1];
//       //final Map<String, String> signedDataMap  = await signData(filePath, password, finalString);
//       final byteData = await rootBundle.load('assets/private_key.pem');
//       final buffer = byteData.buffer;
//       // Write to a temp file
//       final tempDir = Directory.systemTemp;
//       final pemFile = File('${tempDir.path}/private_key.pem');
//       await pemFile.writeAsBytes(
//         buffer.asUint8List(byteData.offsetInBytes, byteData.lengthInBytes),
//       );
//       final Map<String, String> signedDataMap  = PemSigner.signDataWithMd5(
//         data: finalString,
//         privateKeyPath: pemFile.path,
//       );
//       //final Map<String, dynamic> signedDataMap = jsonDecode(signedDataString);
//       receiptDeviceSignature_signature_hex = signedDataMap["receiptDeviceSignature_signature_hex"] ?? "";
//       receiptDeviceSignature_signature = signedDataMap["receiptDeviceSignature_signature"] ?? "";
//       first16Chars = signedDataMap["receiptDeviceSignature_signature_md5_first16"] ?? "";
//     } catch (e) {
//       Get.snackbar("Signing Error", "$e", snackPosition: SnackPosition.TOP);
      
//     }
//     print("Signed Data: $receiptDeviceSignature_signature");
//     print("gettinf to json body");
//     print("receipt json body is $receiptJsonbody");
//     print("new hash is $hash");
//     print("new signature is $receiptDeviceSignature_signature");
//     print("fiscal day no is $receiptFiscDayNo");
//     print("new receipt global no is $nextReceiptGlobalNo");
//     print("new receipt counter is $nextReceiptCounter");
//     print("new receipt date is $formattedDate");
//     print("receipt ID is $receiptID");
  
//     final futurecreditNoteJson = await createCreditNote(receiptJsonbody,newHash: hash , newSignature: receiptDeviceSignature_signature.toString()  , fiscalDay: receiptFiscDayNo ,newReceiptGlobalNo: nextReceiptGlobalNo.toString(), newReceiptCounter: nextReceiptCounter, newReceiptDate: formattedDate , receiptID: receiptID);
//     print("Getting to date");
//     //creditnote qrurl
//     DateTime parsedDate = DateTime.parse(formattedDate);
//     String ddMMDate = DateFormat('ddMMyyyy').format(parsedDate);
//     print("Date : $ddMMDate");
//     String formattedDeviceID = deviceID.toString().padLeft(10, '0');
//     print("device is :  $formattedDeviceID");
//     String formattedReceiptGlobalNo = nextReceiptGlobalNo.toString().padLeft(10, '0');
//     print("global number $formattedReceiptGlobalNo ");
//     String creditQrData  = first16Chars.toString();
//     print("qr data : $creditQrData");
//     String qrurl  = genericzimraqrurl + formattedDeviceID + ddMMDate + formattedReceiptGlobalNo + creditQrData;
//     print("QRURL: $qrurl");
//     String creditNoteJson = futurecreditNoteJson.toString();

//     // ping
//     String pingResponse = await ping();

//     Map<String , dynamic> jsonData  = jsonDecode(creditNoteJson);
//     final List<dynamic> receiptTaxes =jsonData['receipt']['receiptTaxes'];
//     double totalTaxAmount = 0.0;
//     double totalSalesAmountWithTax = 0.0;
//     for (var tax in receiptTaxes) {
//       // Parse taxAmount
//       double taxAmount = 0.0;
//       var taxAmountRaw = tax['taxAmount'];
//       if (taxAmountRaw is String) {
//         taxAmount = double.tryParse(taxAmountRaw) ?? 0.0;
//       } else if (taxAmountRaw is num) {
//         taxAmount = taxAmountRaw.toDouble();
//       }
//       totalTaxAmount += taxAmount;

//       // Parse SalesAmountwithTax
//       double salesAmount = 0.0;
//       var salesAmountRaw = tax['SalesAmountwithTax'];
//       if (salesAmountRaw is String) {
//         salesAmount = double.tryParse(salesAmountRaw) ?? 0.0;
//       } else if (salesAmountRaw is num) {
//         salesAmount = salesAmountRaw.toDouble();
//       }
//       totalSalesAmountWithTax += salesAmount;
//     }

//     final totals = jsonData['receipt']?['receiptTaxes'];
//       double total15VAT = 0.0;
//       double totalNonVAT = 0.0;
//       double totalExempt = 0.0;
//       for (var items in totals){
//         double sum = items['salesAmountWithTax'];
//         int? taxId = int.tryParse(items['taxID']);
//         if(taxId == 1){
//           total15VAT += sum;
//         }else if(taxId == 2){
//           totalNonVAT += sum;
//         }else{
//           totalExempt += sum;
//         }
//       }

//     if (creditNoteJson.isNotEmpty) {
//       String creditNoteNumber = await dbHelper.getNextCreditNoteNumber();
//       if(pingResponse=="200"){
//         try {
//           String apiEndpointSubmitReceipt =
//           "https://fdmsapi.zimra.co.zw/Device/v1/$deviceID/SubmitReceipt";
//         const String deviceModelName = "Server";
//         const String deviceModelVersion = "v1";  

//         SSLContextProvider sslContextProvider = SSLContextProvider();
//         SecurityContext securityContext = await sslContextProvider.createSSLContext();
      
//         print(creditNoteJson);
//         // Call the Ping function
//         Map<String, dynamic> response = await SubmitReceipts.submitReceipts(
//           apiEndpointSubmitReceipt: apiEndpointSubmitReceipt,
//           deviceModelName: deviceModelName,
//           deviceModelVersion: deviceModelVersion,
//           securityContext: securityContext,
//           receiptjsonBody:creditNoteJson,
//         );
//         Get.snackbar(
//           "Zimra Response", "$response",
//           snackPosition: SnackPosition.TOP,
//           colorText: Colors.white,
//           backgroundColor: Colors.green,
//           icon: const Icon(Icons.message, color: Colors.white),
//         );
//         Map<String, dynamic> responseBody = jsonDecode(response["responseBody"]);
//         int statusCode = response["statusCode"];
//         String submitReceiptServerresponseJson = responseBody.toString();
//         print("your server server response is $submitReceiptServerresponseJson");
//         if(statusCode == 200){
//           print("Code is 200, saving receipt...");
//           try {
//             final Database dbinit= await dbHelper.initDB();
//             await dbinit.insert('submittedReceipts', {
//               'receiptCounter': jsonData['receipt']?['receiptCounter'] ?? 0,
//             'FiscalDayNo' : fiscalDayNo,
//             'InvoiceNo': jsonData['receipt']?['invoiceNo']?.toString(),
//             'receiptID': responseBody['receiptID'] ?? 0,
//             'receiptType': jsonData['receipt']['receiptType']?.toString() ?? "",
//             'receiptCurrency': jsonData['receipt']?['receiptCurrency']?.toString() ?? "",
//             'moneyType': jsonData['receipt']?['receiptCurrency']?.toString() ?? "",
//             'receiptDate': jsonData['receipt']?['receiptDate']?.toString() ?? "",
//             'receiptTime': jsonData['receipt']?['receiptDate']?.toString() ?? "",
//             'receiptTotal': jsonData['receipt']?['receiptTotal']?.toString() ?? "",
//             'taxCode': "C",
//             'taxPercent': "15.00",
//             'taxAmount': totalTaxAmount,
//             'SalesAmountwithTax': totalSalesAmountWithTax,
//             'receiptHash': jsonData['receipt']?['receiptDeviceSignature']?['hash']?.toString() ?? "",
//             'receiptJsonbody': creditNoteJson,
//             'StatustoFDMS': "Submitted".toString(),
//             'qrurl': qrurl,
//             'receiptServerSignature': responseBody['receiptServerSignature']?['signature'].toString() ?? "",
//             'submitReceiptServerresponseJSON': "$submitReceiptServerresponseJson" ?? "noresponse",
//             'Total15VAT': total15VAT.toString(),
//             'TotalNonVAT': totalNonVAT,
//             'TotalExempt': totalExempt,
//             'TotalWT': 0.0,
//             },conflictAlgorithm: ConflictAlgorithm.replace);
//             print("Data inserted successfully!");
//             //print58mmAdvanced(jsonData, qrurl,invoiceId);
//             handleReceiptPrint(jsonData, qrurl, creditQrData);
//            // handleReceiptPrint58mm(jsonData, qrurl, creditQrData);
//             //generateCreditnoteFromJson(jsonData , qrurl , creditQrData , invoiceNumber);
//             taxAmount = 0.0;
//             currentReceiptGlobalNo = "";
//             currentUrl = "";
//             currentDayNo = "";
//             selectedCustomer.clear();
//             isReceiptCreditNote =0;
//             //print58mmAdvanced(jsonData, qrurl);
//             receiptItems.clear();
//             isReceiptCreditNote =0;
//             fetchDayReceiptCounter();
//             fetchReceiptsPending();
//             fetchReceiptsSubmitted();
//           } catch (e) {
//             Get.snackbar(" Db Error",
//             "$e",
//             snackPosition: SnackPosition.TOP,
//             colorText: Colors.white,
//             backgroundColor: Colors.red,
//             icon: const Icon(Icons.error),
//             ); 
//           }
//         }
//         else{
//           try {
//             final Database dbinit= await dbHelper.initDB();
//             await dbinit.insert('submittedReceipts', {
//             'receiptCounter': jsonData['receipt']?['receiptCounter'] ?? 0,
//             'FiscalDayNo' : fiscalDayNo,
//             'InvoiceNo': jsonData['receipt']?['invoiceNo']?.toString(),
//             'receiptID': 0,
//             'receiptType': jsonData['receipt']['receiptType']?.toString() ?? "",
//             'receiptCurrency': jsonData['receipt']?['receiptCurrency']?.toString() ?? "",
//             'moneyType': jsonData['receipt']?['receiptCurrency']?.toString() ?? "",
//             'receiptDate': jsonData['receipt']?['receiptDate']?.toString() ?? "",
//             'receiptTime': jsonData['receipt']?['receiptDate']?.toString() ?? "",
//             'receiptTotal': jsonData['receipt']?['receiptTotal']?.toString() ?? "",
//             'taxCode': "C",
//             'taxPercent': "15.00",
//             'taxAmount': totalTaxAmount,
//             'SalesAmountwithTax': totalSalesAmountWithTax,
//             'receiptHash': jsonData['receipt']?['receiptDeviceSignature']?['hash']?.toString() ?? "",
//             'receiptJsonbody': creditNoteJson,
//             'StatustoFDMS': "NOTSubmitted".toString(),
//             'qrurl': qrurl,
//             'receiptServerSignature': "",
//             'submitReceiptServerresponseJSON': "noresponse",
//             'Total15VAT': total15VAT.toString(),
//             'TotalNonVAT': totalNonVAT,
//             'TotalExempt': totalExempt,
//             'TotalWT': 0.0,
//             },conflictAlgorithm: ConflictAlgorithm.replace);
//             print("Data inserted successfully!");
//             //print58mmAdvanced(jsonData, qrurl, invoiceId);
//             handleReceiptPrint(jsonData, qrurl, creditQrData);
//             //generateCreditnoteFromJson(jsonData , qrurl , creditQrData , invoiceNumber);
//             //handleReceiptPrint58mm(jsonData, qrurl, creditQrData);

//             taxAmount = 0.0;
//             currentReceiptGlobalNo = "";
//             currentUrl = "";
//             currentDayNo = "";
//             selectedCustomer.clear();
//             isReceiptCreditNote =0;
//             //print58mmAdvanced(jsonData, qrurl);
//             receiptItems.clear();
//             isReceiptCreditNote =0;
//             fetchDayReceiptCounter();
//             fetchReceiptsPending();
//             fetchReceiptsSubmitted();
//           } catch (e) {
//             Get.snackbar(" Db Error",
//             "$e",
//             snackPosition: SnackPosition.TOP,
//             colorText: Colors.white,
//             backgroundColor: Colors.red,
//             icon: const Icon(Icons.error),
//             );
//           }
//         }
//         } catch (e) {
//           try {
//             final Database dbinit= await dbHelper.initDB();
//             await dbinit.insert('submittedReceipts', {
//             'receiptCounter': jsonData['receipt']?['receiptCounter'] ?? 0,
//             'FiscalDayNo' : fiscalDayNo,
//             'InvoiceNo': jsonData['receipt']?['invoiceNo']?.toString(),
//             'receiptID': 0,
//             'receiptType': jsonData['receipt']['receiptType']?.toString() ?? "",
//             'receiptCurrency': jsonData['receipt']?['receiptCurrency']?.toString() ?? "",
//             'moneyType': jsonData['receipt']?['receiptCurrency']?.toString() ?? "",
//             'receiptDate': jsonData['receipt']?['receiptDate']?.toString() ?? "",
//             'receiptTime': jsonData['receipt']?['receiptDate']?.toString() ?? "",
//             'receiptTotal': jsonData['receipt']?['receiptTotal']?.toString() ?? "",
//             'taxCode': "C",
//             'taxPercent': "15.00",
//             'taxAmount': totalTaxAmount,
//             'SalesAmountwithTax': totalSalesAmountWithTax,
//             'receiptHash': jsonData['receipt']?['receiptDeviceSignature']?['hash']?.toString() ?? "",
//             'receiptJsonbody': creditNoteJson,
//             'StatustoFDMS': "NOTSubmitted".toString(),
//             'qrurl': qrurl,
//             'receiptServerSignature': "",
//             'submitReceiptServerresponseJSON': "noresponse",
//             'Total15VAT': total15VAT.toString(),
//             'TotalNonVAT': totalNonVAT,
//             'TotalExempt': totalExempt,
//             'TotalWT': 0.0,
//             },conflictAlgorithm: ConflictAlgorithm.replace);
//             print("Data inserted successfully!");
//             //print58mmAdvanced(jsonData, qrurl, invoiceId);
//             handleReceiptPrint(jsonData, qrurl, creditQrData);
//             //generateCreditnoteFromJson(jsonData , qrurl , creditQrData , invoiceNumber);
//             //handleReceiptPrint58mm(jsonData, qrurl, creditQrData);
//             taxAmount = 0.0;
//             currentReceiptGlobalNo = "";
//             currentUrl = "";
//             currentDayNo = "";
//             selectedCustomer.clear();
//             isReceiptCreditNote =0;
//             //print58mmAdvanced(jsonData, qrurl);
//             receiptItems.clear();
//             isReceiptCreditNote =0;
//             fetchDayReceiptCounter();
//             fetchReceiptsPending();
//             fetchReceiptsSubmitted();
//           } catch (e) {
//             Get.snackbar(" Db Error",
//             "$e",
//             snackPosition: SnackPosition.TOP,
//             colorText: Colors.white,
//             backgroundColor: Colors.red,
//             icon: const Icon(Icons.error),
//             );
//           }
//         }
//       }
//       else
//       {
//         try {
//             final Database dbinit= await dbHelper.initDB();
//             await dbinit.insert('submittedReceipts', {
//             'receiptCounter': jsonData['receipt']?['receiptCounter'] ?? 0,
//             'FiscalDayNo' : fiscalDayNo,
//             'InvoiceNo': jsonData['receipt']?['invoiceNo']?.toString(),
//             'receiptID': 0,
//             'receiptType': jsonData['receipt']['receiptType']?.toString() ?? "",
//             'receiptCurrency': jsonData['receipt']?['receiptCurrency']?.toString() ?? "",
//             'moneyType': jsonData['receipt']?['receiptCurrency']?.toString() ?? "",
//             'receiptDate': jsonData['receipt']?['receiptDate']?.toString() ?? "",
//             'receiptTime': jsonData['receipt']?['receiptDate']?.toString() ?? "",
//             'receiptTotal': jsonData['receipt']?['receiptTotal']?.toString() ?? "",
//             'taxCode': "C",
//             'taxPercent': "15.00",
//             'taxAmount': totalTaxAmount,
//             'SalesAmountwithTax': totalSalesAmountWithTax,
//             'receiptHash': jsonData['receipt']?['receiptDeviceSignature']?['hash']?.toString() ?? "",
//             'receiptJsonbody': creditNoteJson,
//             'StatustoFDMS': "NOTSubmitted".toString(),
//             'qrurl': qrurl,
//             'receiptServerSignature': "",
//             'submitReceiptServerresponseJSON': "noresponse",
//             'Total15VAT': total15VAT.toString(),
//             'TotalNonVAT': totalNonVAT,
//             'TotalExempt': totalExempt,
//             'TotalWT': 0.0,
//             },conflictAlgorithm: ConflictAlgorithm.replace);
//             print("Data inserted successfully!");
//             //print58mmAdvanced(jsonData, qrurl, invoiceId);
//             handleReceiptPrint(jsonData, qrurl, creditQrData);
//             //generateCreditnoteFromJson(jsonData , qrurl , creditQrData , invoiceNumber);
//             //handleReceiptPrint58mm(jsonData, qrurl, creditQrData);
//             taxAmount = 0.0;
//             currentReceiptGlobalNo = "";
//             currentUrl = "";
//             currentDayNo = "";
//             selectedCustomer.clear();
//             isReceiptCreditNote =0;
//             //print58mmAdvanced(jsonData, qrurl);
//             receiptItems.clear();
//             isReceiptCreditNote =0;
//             fetchDayReceiptCounter();
//             fetchReceiptsPending();
//             fetchReceiptsSubmitted();
//           } catch (e) {
//             Get.snackbar(" Db Error",
//             "$e",
//             snackPosition: SnackPosition.TOP,
//             colorText: Colors.white,
//             backgroundColor: Colors.red,
//             icon: const Icon(Icons.error),
//             );
//           }
//       }

//       try {
//         final Database dbinit= await dbHelper.initDB();
//         await dbinit.insert('credit_notes',
//         {
//           'receiptGlobalNo': receiptGlobalNo,
//           'receiptID': receiptID,
//           'receiptDate': formattedDate,
//           'receiptTotal': totalAmountInCents /100,
//           'receiptNotes': creditReason,
//           'creditNoteNumber': creditNoteNumber,
//         },
//         conflictAlgorithm: ConflictAlgorithm.replace,
//         );
//       print("Saved to DB successfully");
//       Get.snackbar("Saved to DB", "Saved to DB successfully",
//         snackPosition: SnackPosition.TOP,
//         backgroundColor: Colors.green,
//         colorText: Colors.white,
//         icon: const Icon(Icons.check, color: Colors.white,),
//       );
//       } catch (e) {
//         print("Saving error  $e");
//         Get.snackbar("Saving Error", "$e",
//         snackPosition: SnackPosition.TOP,
//         backgroundColor: Colors.red,
//         colorText: Colors.white,
//         icon: const Icon(Icons.error, color: Colors.white,),
//         );
//       }
//     }
//     File file = File("C:/FDMS-gateway/Files/jsonFile.txt");
//     await file.writeAsString(creditNoteJson);
//     print(creditNoteJson);

//   } catch (e) {
//     print("tryyyy  Error: $e");
//     Get.snackbar("Try Error", "$e",
//     snackPosition: SnackPosition.TOP);
//   }
// }

//   Future<void> uploadAndExtractTable(File pdfFile) async {
//     final uri = Uri.parse("http://localhost:5000/extract_invoice");
//     final request = http.MultipartRequest('POST', uri)
//       ..files.add(await http.MultipartFile.fromPath('file', pdfFile.path));

//     final streamedResponse = await request.send();
//     final response = await http.Response.fromStream(streamedResponse);

//     if (response.statusCode == 200) {
//       //final List<dynamic> tableData = jsonDecode(response.body);
//       final Map<String, dynamic> responseData = jsonDecode(response.body);
//       final List<dynamic> tableData = responseData['line_items'];
//       final Map<String, dynamic> invoiceDetails = responseData['invoice_details'];
//       print("Invoice Details: $invoiceDetails");
//       for (final row in tableData) {
//         print("Row: $row");
//       }
//     } else {
//       print("Error: ${response.body}");
//     }
//   }

//   //add to receipt items
//   Future<void> addItem(List<dynamic> tableData) async {
  
//   final List<Map<String, dynamic>> lineItems = tableData.cast<Map<String, dynamic>>();
//   final newItems = <Map<String, dynamic>>[];
  
//   for (var item in lineItems) {
//     // Validate required fields
//     if (item['Description'] == null || item['Unit Price'] == null) {
//       continue;
//     }
//     double unitPrice = (item['Unit Price'] is String)
//       ? double.tryParse(item['Unit Price'].replaceAll(',', '')) ?? 0
//       : (item['Unit Price'] ?? 0).toDouble();

//     int quantity = (item['Qty'] is String)
//         ? int.tryParse(item['Qty']) ?? 1
//         : (item['Qty'] ?? 1);

    
//     //double totalPrice = double.tryParse(item['unit_price'].toString().replaceAll(',', '')) ?? 0;
//     double itemTax;
//     int taxID;
//     String taxCode;
//     String taxPercent;
//     double lineItemTax = 0;
//     double itemTotal = 0 ;
//     double totalPrice =  0 ;
//     final vatValue = item['Total VAT'];
    
//     if ((vatValue) != null && vatValue != "-" && double.parse(vatValue.toString()) > 0.0 ) {
//       lineItemTax = unitPrice * 0.15;
//       itemTotal = roundTo2(unitPrice + lineItemTax);
//       totalPrice = roundTo2(itemTotal * quantity);
//       taxID = 1;
//       taxPercent = "15.00";
//       taxCode = "A";
//       itemTax = roundTo2(unitPrice * quantity * 0.15);
//       salesAmountwithTax += totalPrice;
//     } else if (vatValue == '-') {
//       itemTotal = unitPrice;
//       totalPrice = itemTotal * quantity;
//       taxID = 3;
//       taxPercent = "0";
//       taxCode = "C";
//       itemTax = 0;
//     } else {
//       itemTotal = unitPrice;
//       totalPrice = itemTotal * quantity;
//       taxID =2;
//       taxPercent = "0.00";
//       taxCode = "B";
//       itemTax = 0;
//     }

//     newItems.add({
//       'productName': item['Description'] ?? 'Unknown',
//       'unitPrice': unitPrice,
//       'price': itemTotal,
//       'quantity': quantity,
//       'total': totalPrice,
//       'taxID': taxID,
//       'taxPercent': taxPercent,
//       'taxCode': taxCode,
//     });
//     totalAmount += totalPrice;
//     taxAmount += itemTax;
//   }

//     setState(() {
//     receiptItems.addAll(newItems);
//   });
  

//   print("receiptItems: $receiptItems");
// }

// double roundTo2(double value) {
//   final Decimal decimalValue = Decimal.parse(value.toString());
//   final Decimal rounded = decimalValue.round(scale: 2);
//   return double.parse(rounded.toString());
// }

//  //add to receipt items
// Future<void> addReceiptItem(List<dynamic> tableData) async {
//   final List<Map<String, dynamic>> lineItems = tableData.cast<Map<String, dynamic>>();
//   final newItems = <Map<String, dynamic>>[];

//   for (var item in lineItems) {
//     // Validate required fields
//     if (item['description'] == null || item['unit_price'] == null || item['quantity'] == null || item['amount_incl'] == null) {
//       continue;
//     }

//     double unitPrice = (item['unit_price'] is String)
//         ? double.tryParse(item['unit_price']) ?? 0
//         : (item['unit_price'] ?? 0).toDouble();

//     int quantity = (item['quantity'] is String)
//         ? int.tryParse(item['quantity']) ?? 1
//         : (item['quantity'] ?? 1);

//     // double totalPrice = double.tryParse(item['amount_incl'].toString()) ?? 0;
//     // double itemTotal = totalPrice / quantity;

//     double lineItemTax = 0;
//     double itemTotal = 0 ;
//     double totalPrice =  0 ;

//     double itemTax;
//     int taxID;
//     String taxCode;
//     String taxPercent;
    
//     final vatValue = item['vat'];
//     final taxLetter = item['tax_letter'];
//     if (taxLetter=='T' ) {
//       lineItemTax = roundTo2(unitPrice * 0.15);
//       itemTotal = roundTo2( unitPrice + lineItemTax);
//       totalPrice = roundTo2(itemTotal * quantity);
//       taxID = 1;
//       taxPercent = "15.00";
//       taxCode = "A";
//       itemTax = roundTo2(unitPrice * quantity * 0.15);
//       salesAmountwithTax += totalPrice;
//     } else if (taxLetter == 'Z') {
//       itemTotal = unitPrice;
//       totalPrice = itemTotal * quantity;
//       taxID =2;
//       taxPercent = "0.00";
//       taxCode = "B";
//       itemTax = 0;
//     } else {
//       itemTotal = unitPrice;
//       totalPrice = itemTotal * quantity;
//       taxID = 3;
//       taxPercent = "0";
//       taxCode = "C";
//       itemTax = 0;
//     }
//     print("adding new items");
//     newItems.add({
//       'productName': item['description'] ?? item['hs_code'] ?? 'Unknown',
//       'unitPrice': unitPrice,
//       'price': itemTotal,
//       'quantity': quantity,
//       'total': totalPrice,
//       'taxID': taxID,
//       'taxPercent': taxPercent,
//       'taxCode': taxCode,
//     });
//     totalAmount += totalPrice;
//     taxAmount += itemTax;
//   }

//     setState(() {
//     receiptItems.addAll(newItems);
//   });
  

//   print("receiptItems: $receiptItems");
// }

//   String generateTaxSummary(List<dynamic> receiptItems) {
//     Map<int, Map<String, dynamic>> taxGroups = {};
    
//     for (var item in receiptItems) {
//       int taxID = item["taxID"];
//       print("date generating tax summary");
//       double total = item["total"];
//       double unitPrice = item["unitPrice"];
//       String taxCode = item["taxCode"];
      
//       // Preserve empty taxPercent when missing
//       String? taxPercentValue = item["taxPercent"];
//       double taxPercent = (taxPercentValue == null || taxPercentValue == "")
//           ? 0.0
//           : double.parse(taxPercentValue);
      
//       if (!taxGroups.containsKey(taxID)) {
//         taxGroups[taxID] = {
//           "taxCode": taxCode,
//           "taxPercent": taxPercentValue == null || taxPercentValue == "" 
//             ? 0
//             : (taxPercent % 1 == 0 
//                 ? "${taxPercent.toInt()}.00" 
//                 : taxPercent.toStringAsFixed(2)),
//           "taxAmount": 0.0,
//           "salesAmountWithTax": 0.0
//         };
//       }
//       double taxAmount ;
//       if(taxPercentValue=="15.00"){
//         taxAmount = total - double.parse((total / 1.15).toString());
//       }else{
//         taxAmount = total * 0;
//       }
//       taxGroups[taxID]!["taxAmount"] += taxAmount;
//       taxGroups[taxID]!["salesAmountWithTax"] += total;
//     }
    
//     List<Map<String, dynamic>> sortedTaxes = taxGroups.values.toList()
//       ..sort((a, b) => a["taxCode"].compareTo(b["taxCode"]));

    


//     // return sortedTaxes.map((tax) {
//     //   return "${tax["taxCode"]}${tax["taxPercent"]}${(tax["taxAmount"] * 100).round().toString()}${(tax["salesAmountWithTax"] * 100).round().toString()}";
//     // }).join("");
//     return sortedTaxes.map((tax) {
//       double taxAmountcents = roundTo2(tax["taxAmount"]);
//       double salesAmountcents = roundTo2(tax["salesAmountWithTax"]);
//       final taxCode = tax["taxCode"];
//       final taxPercent = tax["taxPercent"];
//       final taxAmount = (taxAmountcents * 100).round().toString();
//       final salesAmount = (salesAmountcents * 100).round().toString();

//       // Omit taxPercent for taxCode A
//       if (taxCode == "C") {
//         return "$taxCode$taxAmount$salesAmount";
//       }

//       return "$taxCode$taxPercent$taxAmount$salesAmount";
//     }).join("");
//   }

//   String generateReceiptString({
//     required int deviceID,
//     required String receiptType,
//     required String receiptCurrency,
//     required int receiptGlobalNo,
//     required String receiptDate,
//     required double receiptTotal,
//     required List<dynamic> receiptItems,
//     required String getPreviousReceiptHash,
//   }) {
//     //String formattedDate = receiptDate.toIso8601String().split('.').first;
//     //print("Formatted Date: $formattedDate");
//     String formattedTotal = receiptTotal.toStringAsFixed(2);
//     double receiptTotal_numeric = receiptTotal;
//     int receiptTotal_ampl = (receiptTotal_numeric * 100).round();
//     String receiptTotal_adj = receiptTotal_ampl.toString();
//     String receiptTaxes = generateTaxSummary(receiptItems);

//     return "$deviceID$receiptType$receiptCurrency$receiptGlobalNo$receiptDate$receiptTotal_adj$receiptTaxes$getPreviousReceiptHash";
//   }
  
//   //use raw string
//   useRawString(String date) async {
//     int latestFiscDay = await dbHelper.getlatestFiscalDay();
//     setState(() {
//       currentFiscal = latestFiscDay;
//     });
//     List<Map<String, dynamic>> data = await dbHelper.getReceiptsSubmittedToday(currentFiscal);
//     setState(() {
//       dayReceiptCounter = data;
//     });
//     int latestReceiptGlobalNo = await dbHelper.getLatestReceiptGlobalNo();
//     int currentGlobalNo = latestReceiptGlobalNo + 1;
//     String getLatestReceiptHash = await dbHelper.getLatestReceiptHash();
//     if (dayReceiptCounter.isEmpty){
//       String receiptString = generateReceiptString(
//         deviceID:deviceID,
//         receiptType: "FISCALINVOICE",
//         receiptCurrency: transactionCurrency.toString(),
//         receiptGlobalNo: currentGlobalNo,
//         receiptDate: date,
//         receiptTotal: totalAmount,
//         receiptItems: receiptItems,
//         getPreviousReceiptHash:"",
//       );
//       print("Concatenated Receipt String: $receiptString");
//       logToFile(receiptString);
//       return receiptString;
//     }else{
//       String receiptString = generateReceiptString(
//         deviceID: deviceID,
//         receiptType: "FISCALINVOICE",
//         receiptCurrency: transactionCurrency.toString(),
//         receiptGlobalNo: currentGlobalNo,
//         receiptDate: date,
//         receiptTotal: totalAmount,
//         receiptItems: receiptItems,
//         getPreviousReceiptHash: getLatestReceiptHash,
//       );
//       print("Concatenated Receipt String: $receiptString");
//       logToFile(receiptString);
//       return receiptString;
//     }  
//   }

//   List<Map<String, dynamic>> generateReceiptTaxes(List<dynamic> receiptItems) {
//     Map<int, Map<String, dynamic>> taxGroups = {}; // Store tax summaries

//     for (var item in receiptItems) {
//       int taxID = item["taxID"];
//       String taxPercent = item["taxPercent"];
//       double total = item["total"];

//       if (!taxGroups.containsKey(taxID)) {
//         taxGroups[taxID] = {
//           "taxID": taxID,
//           "taxPercent": taxPercent.isEmpty ? "" : taxPercent, // Leave blank if empty
//           "taxCode": item["taxCode"],
//           "taxAmount": 0.0,
//           "salesAmountWithTax": 0.0
//         };
//       }
//       double taxAmount;
//       double taxamountpre;
//       double taxAmountfinal = 0;
//       double totalfinal = 0 ;
//       if(taxPercent.isEmpty){
//         taxAmount = 0.00;
//       }
//       else if(taxPercent=="15.00"){
//         taxAmount = total - double.parse((total / 1.15).toString());
//       }
//       else{
//         taxAmount = total * 0;
//       }
//       taxGroups[taxID]!["taxAmount"] += taxAmount;
//       taxGroups[taxID]!["salesAmountWithTax"] += total;

//     }
//     return taxGroups.values.map((tax) {
//       final taxID = tax["taxID"];
//       final taxCode = tax["taxCode"];
//       final isGroupA = (taxCode == "C" || taxID == 3);
      
//       double tax1 = (tax["salesAmountWithTax"] is String)
//       ? double.tryParse(tax["salesAmountWithTax"]) ?? 0
//       : (tax["salesAmountWithTax"] ?? 0).toDouble();

//       return {
//         "taxID": taxID.toString(),
//         if (!isGroupA) "taxPercent": tax["taxPercent"], // Omit if group C
//         "taxCode": taxCode,
//         "taxAmount": isGroupA ? "0" : roundTo2(tax["taxAmount"]),
//         "salesAmountWithTax": roundTo2(tax1),
//       };
//     }).toList();
//   }

//   Future<Map<String, String>> generateHash(String date) async {
//     String saleCurrency = transactionCurrency.toString();
//     int latestFiscDay = await dbHelper.getlatestFiscalDay();
//     String receiptString;

//     setState(() {
//       currentFiscal = latestFiscDay;
//     });

//     List<Map<String, dynamic>> data = await dbHelper.getReceiptsSubmittedToday(currentFiscal);

//     setState(() {
//       dayReceiptCounter = data;
//     });

//     int latestReceiptGlobalNo = await dbHelper.getLatestReceiptGlobalNo();
//     int currentGlobalNo = latestReceiptGlobalNo + 1;

//     setState(() {
//       currentReceiptGlobalNo = currentGlobalNo.toString();
//     });

//     String getLatestReceiptHash = await dbHelper.getLatestReceiptHash();

//     if (dayReceiptCounter.isEmpty) {
//       receiptString = generateReceiptString(
//         deviceID: deviceID,
//         receiptType: "FISCALINVOICE",
//         receiptCurrency: saleCurrency,
//         receiptGlobalNo: currentGlobalNo,
//         receiptDate: date,
//         receiptTotal: totalAmount,
//         receiptItems: receiptItems,
//         getPreviousReceiptHash: "",
//       );
//     } else {
//       receiptString = generateReceiptString(
//         deviceID: deviceID,
//         receiptType: "FISCALINVOICE",
//         receiptCurrency: saleCurrency,
//         receiptGlobalNo: currentGlobalNo,
//         receiptDate: date,
//         receiptTotal: totalAmount,
//         receiptItems: receiptItems,
//         getPreviousReceiptHash: getLatestReceiptHash,
//       );
//     }

//     print("Concatenated Receipt String: $receiptString");
//     logToFile(receiptString);

//     var bytes = utf8.encode(receiptString.trim());
//     var digest = sha256.convert(bytes);
//     final hash = base64.encode(digest.bytes);

//     print(hash);
//     logToFile(hash);
//     // ✅ Return both
//     return {
//       "receiptString": receiptString,
//       "hash": hash,
//     };
//   }

   
//   //generate fiscal JSON
//   Future<String> generateFiscalJSON() async {
//     String encodedreceiptDeviceSignature_signature;
//   try {
//     print("Entered generateFiscalJSON");
//     // Ensure signing does not fail
//     DateTime now = DateTime.now();
//     String formattedDate = DateFormat("yyyy-MM-ddTHH:mm:ss").format(now);
//     final hashData = await generateHash(formattedDate);

//     try {
//       print("Using raw string for signing");
//       //String data = await useRawString(formattedDate);
//       String data = hashData['receiptString'].toString();
//       final byteData = await rootBundle.load('assets/private_key.pem');
//       final buffer = byteData.buffer;
//       // Write to a temp file
//       final tempDir = Directory.systemTemp;
//       final pemFile = File('${tempDir.path}/private_key.pem');
//       await pemFile.writeAsBytes(
//         buffer.asUint8List(byteData.offsetInBytes, byteData.lengthInBytes),
//       );
//       final Map<String, String> signedDataMap  = PemSigner.signDataWithMd5(
//         data: data,
//         privateKeyPath: pemFile.path,
//       );
//       //final Map<String, dynamic> signedDataMap = jsonDecode(signedDataString);
//       receiptDeviceSignature_signature_hex = signedDataMap["receiptDeviceSignature_signature_hex"] ?? "";
//       receiptDeviceSignature_signature = signedDataMap["receiptDeviceSignature_signature"] ?? "";
//       first16Chars = signedDataMap["receiptDeviceSignature_signature_md5_first16"] ?? "";
      
//     } catch (e) {
//       Get.snackbar("Signing Error", "$e", snackPosition: SnackPosition.TOP);
//       return "{}";
//     }
//     print("Signed Data: $receiptDeviceSignature_signature");
//     if (receiptItems.isEmpty) {
//       print("Receipt items are empty, returning empty JSON.");
//       return "{}";
//     }

//     int fiscalDayNo = await dbHelper.getlatestFiscalDay();
//     int nextReceiptCounter = await dbHelper.getNextReceiptCounter(fiscalDayNo);
//     int nextInvoice = await dbHelper.getNextInvoiceId();
//     int latestReceiptGlobalNo = await dbHelper.getLatestReceiptGlobalNo();
//     int currentGlobalNo = latestReceiptGlobalNo + 1;

//     // Ensure tax calculation does not fail
//     List<Map<String, dynamic>> taxes = [];
//     try {
//       taxes = generateReceiptTaxes(receiptItems);
//     } catch (e) {
//       Get.snackbar("Tax Calculation Error", "$e", snackPosition: SnackPosition.TOP);
//       return "{}";
//     }

//     //String hash = await generateHash(formattedDate);
//     String hash = hashData['hash'].toString();
//     print("Hash generated successfully");

//     Map<String, dynamic> jsonData = {
//       "receipt": {
//         "receiptLines": receiptItems.asMap().entries.map((entry) {
//           int index = entry.key + 1;
//           var item = entry.value;
//           if (item["taxPercent"] != "0"){
//             return {
//             "receiptLineNo": "$index",
//             "receiptLineHSCode": "04021099",
//             "receiptLinePrice": item["price"].toStringAsFixed(2),
//             "taxID": item["taxID"],
//             //if  "taxPercent":  item["taxPercent"] == "" ? 0.00  : double.parse(item["taxPercent"].toString()).toStringAsFixed(2),
//             "taxPercent": item["taxPercent"],   
//             "receiptLineType": "Sale",
//             "receiptLineQuantity": item["quantity"].toString(),
//             "taxCode": item["taxCode"],
//             "receiptLineTotal": item["total"].toStringAsFixed(2),
//             "receiptLineName": item["productName"],
//           };
//           }
//           else{
//             return {
//             "receiptLineNo": "$index",
//             "receiptLineHSCode": "99001000",
//             "receiptLinePrice": item["price"].toStringAsFixed(2),
//             "taxID": item["taxID"], 
//             "receiptLineType": "Sale",
//             "receiptLineQuantity": item["quantity"].toString(),
//             "taxCode": item["taxCode"],
//             "receiptLineTotal": item["total"].toStringAsFixed(2),
//             "receiptLineName": item["productName"],
//           };
//           }
          
//           // Only add taxPercent if it's not an empty strin
//         }).toList(),
//         "receiptType": "FISCALINVOICE",
//         "receiptGlobalNo": currentGlobalNo,
//         "receiptCurrency": transactionCurrency.toString(),
//         "receiptPrintForm": "InvoiceA4",
//         "receiptDate": formattedDate,
//         "receiptPayments": [
//           {"moneyTypeCode": "Cash", "paymentAmount": totalAmount.toStringAsFixed(2)}
//         ],
//         "receiptCounter": nextReceiptCounter,
//         "receiptTaxes": taxes,
//         "receiptDeviceSignature": {
//           "signature": receiptDeviceSignature_signature,
//           "hash": hash,
//         },
//         "buyerData": {
//           "VATNumber": selectedCustomer.isNotEmpty? selectedCustomer[0]['customerVAT'].toString() : "000000000",
//           "buyerTradeName":  selectedCustomer.isNotEmpty? selectedCustomer[0]['customerName'].toString() : "Cash Sale",
//           "buyerTIN": selectedCustomer.isNotEmpty? selectedCustomer[0]['customerTIN'].toString() : "0000000000",
//           "buyerRegisterName": selectedCustomer.isNotEmpty? selectedCustomer[0]['customerName'].toString() : "Cash Sale",
//           "buyerAddress": {
//             'province' : selectedCustomer.isNotEmpty? selectedCustomer[0]['province'].toString() : "Zimbabwe",
//             'city' : selectedCustomer.isNotEmpty? selectedCustomer[0]['city'].toString() : "Zimbawe",
//             'street': selectedCustomer.isNotEmpty? selectedCustomer[0]['street'].toString() : "Zimbabwe",
//             'houseNo': selectedCustomer.isNotEmpty? selectedCustomer[0]['houseNO'].toString() : "0000",
//           },
//           "buyerContactS":{
//             "email" : selectedCustomer.isNotEmpty? selectedCustomer[0]['customerEmail'].toString() : "buyer@buyer.com",
//             "phoneNo":selectedCustomer.isNotEmpty? selectedCustomer[0]['customerPhone'].toString() : "0000000000"
//           }
//         },
//         "receiptTotal": totalAmount.toStringAsFixed(2),
//         "receiptLinesTaxInclusive": true,
//         "invoiceNo": currentInvoiceNumber.toString() ,
//       }
//     };
//     // Ensure JSON encoding does not fail
//     final jsonString;
//     try {
//       jsonString = jsonEncode(jsonData);
//     } catch (e) {
//       Get.snackbar("JSON Encoding Error", "$e", snackPosition: SnackPosition.TOP);
//       return "{}";
//     }
//     // String getLatestReceiptHash = await dbHelper.getLatestReceiptHash();

//     // String verifyString =  buildZimraCanonicalString(receipt: jsonData, deviceID: "25395", previousReceiptHash: getLatestReceiptHash);
//     // verifyString.trim();
//     // var bytes = utf8.encode(verifyString);
//     // var digest = sha256.convert(bytes);
//     // final hashVerify = base64.encode(digest.bytes);
//     // verifySignatureAndShowResult2(context, filePath, password, hashVerify, receiptDeviceSignature_signature.toString());
//     File file = File("C:/FDMS-gateway/Files/jsonFile.txt");
//     await file.writeAsString(jsonString);
//     print("Generated JSON: $jsonString");
//     return jsonString;

//   } catch (e) {
//     Get.snackbar(
//       "Error Message",
//       "$e",
//       snackPosition: SnackPosition.TOP,
//       colorText: Colors.white,
//       backgroundColor: Colors.red,
//       icon: const Icon(Icons.error),
//       shouldIconPulse: true
//     );
//     return "{}"; // Ensure the function always returns something
//   }
// }


// Future<Uint8List?> loadLogoBytes() async {
//   final logoFile = await getLogoFile();
//   if (await logoFile.exists()) {
//     return await logoFile.readAsBytes();
//   }
//   return null;
// }

// Future<File> getLogoFile() async {
//   final appDir = await getApplicationDocumentsDirectory();
//   final logoPath = File('${appDir.path}/company_logo.png');
//   return logoPath;
// }
// //print invoice
// //print invoice
// Future<void> generateInvoiceFromJson(Map<String , dynamic> receiptJson , String qrUrl, String receiptQrData) async{
//   String formattedQrData = formatString(receiptQrData); 
//   final logoBytes = await loadLogoBytes();
//   final imageLogo = logoBytes != null ? pw.MemoryImage(logoBytes) : null;
//   final pdf = pw.Document();
//     final receipt = receiptJson['receipt'];
//     final supplier = {
//       'name': 'Pulse Pvt Ltd',
//       'tin': '1234567890',
//       'address': '16 Ganges Road, Harare',
//       'phone': '+263 77 14172798',
//     };
//     final customer = {
//       'name': receipt['buyerData']?['buyerTradeName'] ?? 'Customer',
//       'tin': receipt['buyerData']?['buyerTIN'] ?? '0000000000',
//       'vat': receipt['buyerData']?['VATNumber'] ?? '00000000',
//       'address' : '${receipt['buyerData']?['buyerAddress']?['houseNo'] ?? '0000'} , ${receipt['buyerData']?['buyerAddress']?['street'] ?? '0000'} , ${receipt['buyerData']?['buyerAddress']?['city'] ?? '0000'} ',
//       'province' : '${receipt['buyerData']?['buyerAddress']?['province'] ?? '0000'}',
//       'email': '${receipt['buyerData']?['buyerContactS']?['email'] ?? '0000'}',
//       'phoneNo': '${receipt['buyerData']?['buyerContactS']?['phoneNo'] ?? '0000'}',
//     };
//     String receiptGlobalNo = receipt['receiptGlobalNo'].toString().padLeft(10, '0');
//     final receiptLines = List<Map<String, dynamic>>.from(receipt['receiptLines']);
//     final receiptTaxes = List<Map<String, dynamic>>.from(receipt['receiptTaxes']);
//     final receiptTotal = double.tryParse(receipt['receiptTotal'].toString()) ?? 0.0;
//     final signature = receipt['receiptDeviceSignature']?['signature'] ?? 'No Signature';
//     double totalTax = 0.0;
//     for (var tax in receiptTaxes) {
//       totalTax += double.tryParse(tax['taxAmount'].toString()) ?? 0.0;
//     }
//     pdf.addPage(
//       pw.MultiPage(
//         pageFormat: PdfPageFormat.a4,
//         maxPages: 100,
//         margin: const pw.EdgeInsets.all(24),
//         build: (pw.Context context) => [
//           pw.Column(
//             crossAxisAlignment: pw.CrossAxisAlignment.start,
//             children: [
//               pw.Row(
//                 mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
//                 children: [
//                   pw.Column(
//                     crossAxisAlignment: pw.CrossAxisAlignment.start,
//                     children: [
//                       pw.Text('$tradeName' ,style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
//                       pw.Text('TIN: $taxPayerTIN'),
//                       pw.Text('VAT: $taxPayerVatNumber'),
//                       pw.Text('Phone: $taxPayerPhone'),
//                       pw.Text('Address: $taxPayerAddress'),
//                     ],
//                   ),
//                   pw.SizedBox(width: 15),
//                   if (imageLogo != null)
//                     pw.Center(
//                       child: pw.Image(imageLogo, height: 80), // adjust height as needed
//                     ),
//                 ],
//               ),
//               pw.Divider(
//                 thickness: 5,
//                 color: PdfColors.blue,
//               ),
//               pw.Container(
//                   alignment: pw.Alignment.center,
//                   child: pw.Text(
//                   "FISCAL TAX INVOICE",
//                   style: pw.TextStyle(fontSize:  24, fontWeight: pw.FontWeight.bold),
//                   textAlign: pw.TextAlign.center,
//                 ),
//               ) ,
//               //pw.Text('FISCAL TAX INVOICE', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
//               pw.Divider(
//                 thickness: 5,
//                 color: PdfColors.blue,
//               ),
//               pw.SizedBox(height: 8),
//               pw.Text('Buyer Data' , style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
//               pw.Text('Customer: ${customer['name']}'),
//               pw.Text('TIN: ${customer['tin']}'),
//               pw.Text('VAT: ${customer['vat']}'),
//               pw.Text('Address: ${customer['address']}'),
//               pw.Text('Email: ${customer['email']}'),
//               pw.Text('Phone: ${customer['phoneNo']}'),
//               pw.Divider(
//                 thickness: 2,
//                 color: PdfColors.blue,
//               ),
//               pw.Row(
//                 mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
//                 children: [
//                   pw.Column(
//                     crossAxisAlignment: pw.CrossAxisAlignment.start,
//                     children: [
//                       pw.Text('Invoice No: ${receipt['receiptGlobalNo']}'),
//                       pw.Text('Document No: ${receipt['invoiceNo']}'),
//                       pw.Text('Serial No: $serialNo'),
//                     ]
//                   ),
//                   pw.Column(
//                     crossAxisAlignment: pw.CrossAxisAlignment.start,
//                     children: [
//                       pw.Text('Fiscal Day No: $currentFiscal'),
//                       pw.Text('Date: ${receipt['receiptDate']}'),
//                       pw.Text('Device ID: $deviceID'),
//                     ]
//                   )
//                 ]
//               ),
//               pw.Divider(
//                 thickness: 2,
//                 color: PdfColors.blue,
//               ),
//               // pw.Text('Invoice No: ${receipt['invoiceNo']}', style: pw.TextStyle(fontSize: 14)),
//               // pw.Text('Date: ${receipt['receiptDate']}'),
//               pw.SizedBox(height: 12),
//               pw.Text('Currency: ${receipt['receiptCurrency']}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
//               pw.SizedBox(height: 12),
//               pw.Table.fromTextArray(
//                 headers: ['Code', 'Item', 'Qty', 'Unit Price', 'Tax', 'Total'],
//                 headerCellDecoration: pw.BoxDecoration(
//                   color: PdfColors.blue
//                 ),
//                 headerStyle: pw.TextStyle(color: PdfColors.white),
//                 data: receiptLines.map((item) {
//                   double productUnitPrice = double.tryParse(item['receiptLinePrice']) ?? 0.0;
//                   final double productVat;
//                   final double producttax;
//                   final double totalAmount = double.tryParse(item['receiptLineTotal'].toString()) ?? 0.0;
//                   if(item['taxCode'] == 'B'){
//                     productVat = 0.00;
//                   } else if(item['taxCode'] == 'A'){
//                     productVat = productUnitPrice - (productUnitPrice/1.15);
//                     productUnitPrice = productUnitPrice/1.15;
//                   }else{
//                     productVat = 0.01;
//                   }
//                   return [
//                     item['receiptLineHSCode'],
//                     item['receiptLineName'],
//                     item['receiptLineQuantity'].toString(),
//                     '\$${item['receiptLinePrice'].toString()}',
//                     '${productVat == 0.01 ? '-' : productVat.toStringAsFixed(2)}',
//                     '\$${item['receiptLineTotal'].toString()}',
//                   ];
//                 }).toList(),
//               ),
//               pw.SizedBox(height: 20),
//               pw.Divider(
//                 thickness: 5,
//                 color: PdfColors.blue,
//               ),
//               pw.SizedBox(height: 10),
//               pw.Align(
//                 alignment: pw.Alignment.centerRight,
//                 child: pw.Column(
//                   crossAxisAlignment: pw.CrossAxisAlignment.end,
//                   children: [
//                     pw.Text('Total Tax: \$${totalTax.toStringAsFixed(2)}'),
//                     pw.Text('Grand Total: \$${receiptTotal.toStringAsFixed(2)}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
//                   ],
//                 ),
//               ),
//               pw.Divider(
//                 thickness: 5,
//                 color: PdfColors.blue,
//               ),
//               pw.SizedBox(height: 20),
//               pw.Row(
//                 mainAxisAlignment: pw.MainAxisAlignment.start,
//                 children: [
//                   pw.Container(
//                     width: 100,
//                     height: 100,
//                     child: pw.BarcodeWidget(
//                       barcode: pw.Barcode.qrCode(),
//                       data: qrUrl,
//                       drawText: false,
//                     ),
//                   ),
//                   pw.SizedBox(width: 10),
//                   pw.Column(
//                     crossAxisAlignment: pw.CrossAxisAlignment.start,
//                     children: [
//                       pw.Text("Verication Code:", textAlign: pw.TextAlign.center ,style: pw.TextStyle(fontSize: 10),),
//                       pw.Text("$formattedQrData", textAlign: pw.TextAlign.center ,style: pw.TextStyle(fontSize: 10)),
//                       pw.Text("You can verify this manually at:",textAlign: pw.TextAlign.center  ,style: pw.TextStyle(fontSize: 10)),
//                       pw.Text("https://fdms.zimra.co.zw", textAlign: pw.TextAlign.center ,style: pw.TextStyle(fontSize: 8, color: PdfColors.blue)),
//                     ]
//                   ),
//                 ]
//               )
//             ],
//           )
//         ]
//       ),
//     );
//     try {
//       final directory = Directory(r'C:\Fiscal\Done');

//       // Create the directory if it doesn't exist
//       if (!await directory.exists()) {
//         await directory.create(recursive: true);
//       }
//       final filePath = p.join(directory.path, 'invoice_${receipt['invoiceNo']}.pdf');
//       final file = File(filePath);
//       await file.writeAsBytes(await pdf.save());

//       print('Invoice saved at ${file.path}');
//     } catch (e) {
//       print('Error saving invoice: $e');
//     }
//   }

//   Future<void> generateCreditnoteFromJson(Map<String , dynamic> receiptJson , String qrUrl, String receiptQrData , String ogInvoice) async{
//   String formattedQrData = formatString(receiptQrData); 
//   final logoBytes = await loadLogoBytes();
//   final imageLogo = logoBytes != null ? pw.MemoryImage(logoBytes) : null;
//   final pdf = pw.Document();
//     final receipt = receiptJson['receipt'];
//     final supplier = {
//       'name': 'Pulse Pvt Ltd',
//       'tin': '1234567890',
//       'address': '16 Ganges Road, Harare',
//       'phone': '+263 77 14172798',
//     };
//     final customer = {
//       'name': receipt['buyerData']?['buyerTradeName'] ?? 'Customer',
//       'tin': receipt['buyerData']?['buyerTIN'] ?? '0000000000',
//       'vat': receipt['buyerData']?['VATNumber'] ?? '00000000',
//       'address' : '${receipt['buyerData']?['buyerAddress']?['houseNo'] ?? '0000'} , ${receipt['buyerData']?['buyerAddress']?['street'] ?? '0000'} , ${receipt['buyerData']?['buyerAddress']?['city'] ?? '0000'} ',
//       'province' : '${receipt['buyerData']?['buyerAddress']?['province'] ?? '0000'}',
//       'email': '${receipt['buyerData']?['buyerContactS']?['email'] ?? '0000'}',
//       'phoneNo': '${receipt['buyerData']?['buyerContactS']?['phoneNo'] ?? '0000'}',
//     };
//     String receiptGlobalNo = receipt['receiptGlobalNo'].toString().padLeft(10, '0');
//     final receiptLines = List<Map<String, dynamic>>.from(receipt['receiptLines']);
//     final receiptTaxes = List<Map<String, dynamic>>.from(receipt['receiptTaxes']);
//     final receiptTotal = double.tryParse(receipt['receiptTotal'].toString()) ?? 0.0;
//     final signature = receipt['receiptDeviceSignature']?['signature'] ?? 'No Signature';
//     double totalTax = 0.0;
//     for (var tax in receiptTaxes) {
//       totalTax += double.tryParse(tax['taxAmount'].toString()) ?? 0.0;
//     }
//     pdf.addPage(
//       pw.MultiPage(
//         pageFormat: PdfPageFormat.a4,
//         maxPages: 100,
//         margin: const pw.EdgeInsets.all(24),
//         build: (pw.Context context) => [
//           pw.Column(
//             crossAxisAlignment: pw.CrossAxisAlignment.start,
//             children: [
//               pw.Row(
//                 mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
//                 children: [
//                   pw.Column(
//                     crossAxisAlignment: pw.CrossAxisAlignment.start,
//                     children: [
//                       pw.Text('$tradeName' ,style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
//                       pw.Text('TIN: $taxPayerTIN'),
//                       pw.Text('VAT: $taxPayerVatNumber'),
//                       pw.Text('Phone: $taxPayerPhone'),
//                       pw.Text('Address: $taxPayerAddress'),
//                     ],
//                   ),
//                   pw.SizedBox(width: 15),
//                   if (imageLogo != null)
//                     pw.Center(
//                       child: pw.Image(imageLogo, height: 80), // adjust height as needed
//                     ),
//                 ],
//               ),
//               pw.Divider(
//                 thickness: 5,
//                 color: PdfColors.blue,
//               ),
//               pw.Container(
//                   alignment: pw.Alignment.center,
//                   child: pw.Text(
//                   "FISCAL CREDIT NOTE",
//                   style: pw.TextStyle(fontSize:  24, fontWeight: pw.FontWeight.bold),
//                   textAlign: pw.TextAlign.center,
//                 ),
//               ) ,
//               //pw.Text('FISCAL TAX INVOICE', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
//               pw.Divider(
//                 thickness: 5,
//                 color: PdfColors.blue,
//               ),
//               pw.SizedBox(height: 8),
//               pw.Text('Buyer Data' , style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
//               pw.Text('Customer: ${customer['name']}'),
//               pw.Text('TIN: ${customer['tin']}'),
//               pw.Text('VAT: ${customer['vat']}'),
//               pw.Text('Address: ${customer['address']}'),
//               pw.Text('Email: ${customer['email']}'),
//               pw.Text('Phone: ${customer['phoneNo']}'),
//               pw.Divider(
//                 thickness: 2,
//                 color: PdfColors.blue,
//               ),
//               pw.Row(
//                 mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
//                 children: [
//                   pw.Column(
//                     crossAxisAlignment: pw.CrossAxisAlignment.start,
//                     children: [
//                       pw.Text('Invoice No: ${receipt['receiptGlobalNo']}'),
//                       pw.Text('Document No: ${receipt['invoiceNo']}'),
//                       pw.Text('Serial No: $serialNo'),
//                     ]
//                   ),
//                   pw.Column(
//                     crossAxisAlignment: pw.CrossAxisAlignment.start,
//                     children: [
//                       pw.Text('Fiscal Day No: $currentFiscal'),
//                       pw.Text('Date: ${receipt['receiptDate']}'),
//                       pw.Text('Device ID: $deviceID'),
//                     ]
//                   )
//                 ]
//               ),
//               pw.Divider(
//                 thickness: 2,
//                 color: PdfColors.blue,
//               ),
//               pw.Container(
//                   alignment: pw.Alignment.center,
//                   child: pw.Text(
//                   "Credited Invoice",
//                   style: pw.TextStyle(fontSize:  14, fontWeight: pw.FontWeight.bold),
//                   textAlign: pw.TextAlign.center,
//                 ),
//               ),
//               pw.Column(
//                     crossAxisAlignment: pw.CrossAxisAlignment.start,
//                     children: [
//                       pw.Text('Invoice No: ${receipt['creditDebitNote']['receiptGlobalNo']}'),
//                       pw.Text('Document Reference: $ogInvoice'),
//                       pw.Text("Credit Reason: ${receipt['receiptNotes']}")
//                     ]
//               ),
//               pw.Divider(
//                 thickness: 2,
//                 color: PdfColors.blue,
//               ),
//               // pw.Text('Invoice No: ${receipt['invoiceNo']}', style: pw.TextStyle(fontSize: 14)),
//               // pw.Text('Date: ${receipt['receiptDate']}'),
//               pw.SizedBox(height: 12),
//               pw.Text('Currency: ${receipt['receiptCurrency']}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
//               pw.SizedBox(height: 12),
//               pw.Table.fromTextArray(
//                 headers: ['Code', 'Item', 'Qty', 'Unit Price', 'Tax', 'Total'],
//                 headerCellDecoration: pw.BoxDecoration(
//                   color: PdfColors.blue
//                 ),
//                 headerStyle: pw.TextStyle(color: PdfColors.white),
//                 data: receiptLines.map((item) {
//                   double productUnitPrice = double.tryParse(item['receiptLinePrice']) ?? 0.0;
//                   final double productVat;
//                   final double producttax;
//                   final double totalAmount = double.tryParse(item['receiptLineTotal'].toString()) ?? 0.0;
//                   if(item['taxCode'] == 'B'){
//                     productVat = 0.00;
//                   } else if(item['taxCode'] == 'A'){
//                     productVat = productUnitPrice - (productUnitPrice/1.15);
//                     productUnitPrice = productUnitPrice/1.15;
//                   }else{
//                     productVat = 0.01;
//                   }
//                   return [
//                     item['receiptLineHSCode'],
//                     item['receiptLineName'],
//                     item['receiptLineQuantity'].toString(),
//                     '\$${item['receiptLinePrice'].toString()}',
//                     '${productVat == 0.01 ? '-' : productVat.toStringAsFixed(2)}',
//                     '\$${item['receiptLineTotal'].toString()}',
//                   ];
//                 }).toList(),
//               ),
//               pw.SizedBox(height: 20),
//               pw.Divider(
//                 thickness: 5,
//                 color: PdfColors.blue,
//               ),
//               pw.SizedBox(height: 10),
//               pw.Align(
//                 alignment: pw.Alignment.centerRight,
//                 child: pw.Column(
//                   crossAxisAlignment: pw.CrossAxisAlignment.end,
//                   children: [
//                     pw.Text('Total Tax: \$${totalTax.toStringAsFixed(2)}'),
//                     pw.Text('Grand Total: \$${receiptTotal.toStringAsFixed(2)}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
//                   ],
//                 ),
//               ),
//               pw.Divider(
//                 thickness: 5,
//                 color: PdfColors.blue,
//               ),
//               pw.SizedBox(height: 20),
//               pw.Row(
//                 mainAxisAlignment: pw.MainAxisAlignment.start,
//                 children: [
//                   pw.Container(
//                     width: 100,
//                     height: 100,
//                     child: pw.BarcodeWidget(
//                       barcode: pw.Barcode.qrCode(),
//                       data: qrUrl,
//                       drawText: false,
//                     ),
//                   ),
//                   pw.SizedBox(width: 10),
//                   pw.Column(
//                     crossAxisAlignment: pw.CrossAxisAlignment.start,
//                     children: [
//                       pw.Text("Verication Code:", textAlign: pw.TextAlign.center ,style: pw.TextStyle(fontSize: 10),),
//                       pw.Text("$formattedQrData", textAlign: pw.TextAlign.center ,style: pw.TextStyle(fontSize: 10)),
//                       pw.Text("You can verify this manually at:",textAlign: pw.TextAlign.center  ,style: pw.TextStyle(fontSize: 10)),
//                       pw.Text("https://fdms.zimra.co.zw", textAlign: pw.TextAlign.center ,style: pw.TextStyle(fontSize: 8, color: PdfColors.blue)),
//                     ]
//                   ),
//                 ]
//               )
//             ],
//           )
//         ]
//       ),
//     );
//     try {
//       final directory = Directory(r'C:\Fiscal\Done');

//       // Create the directory if it doesn't exist
//       if (!await directory.exists()) {
//         await directory.create(recursive: true);
//       }
//       final filePath = p.join(directory.path, 'creditnote_$ogInvoice.pdf');
//       final file = File(filePath);
//       await file.writeAsBytes(await pdf.save());

//       print('Invoice saved at ${file.path}');
//     } catch (e) {
//       print('Error saving invoice: $e');
//     }
//   }

// //submit receipts
// Future<bool> submitReceipt() async {
//     String jsonString  = await generateFiscalJSON();
//     final receiptJson = jsonEncode(jsonString);
//     Get.snackbar(
//       'Fiscalizing',
//       'Processing',
//       icon: const Icon(Icons.check, color: Colors.white,),
//       colorText: Colors.white,
//       backgroundColor: Colors.green,
//       snackPosition: SnackPosition.TOP,
//       showProgressIndicator: true,
//     );
//     String pingResponse = await ping();
//     final receiptJsonbody = await generateFiscalJSON();
    
//     Map<String, dynamic> jsonData = jsonDecode(receiptJsonbody);
//     final db=DatabaseHelper();
//       String moneyType = (jsonData['receipt']['receiptPayments'] != null && jsonData['receipt']['receiptPayments'].isNotEmpty)
//       ? jsonData['receipt']['receiptPayments'][0]['moneyTypeCode'].toString()
//       : "";
//       print("your date is ${jsonData['receipt']?['receiptDate']}");
//       print("your invoice number is ${jsonData['receipt']?['invoiceNo']?.toString()}");
//       print(jsonData);
//       int fiscalDayNo = await db.getlatestFiscalDay();
//       print("fiscal day no is $fiscalDayNo");
//       double receiptTotal = double.parse(jsonData['receipt']?['receiptTotal']?.toString() ?? "0");
//       String formattedDeviceID = deviceID.toString().padLeft(10, '0');
//       String parseDate = jsonData['receipt']?['receiptDate'];
//       DateTime formattedDate = DateTime.parse(parseDate);
//       String formattedDateStr = DateFormat("ddMMyyyy").format(formattedDate);
//       int latestReceiptGlobalNo = await db.getLatestReceiptGlobalNo();
//       final totals = jsonData['receipt']?['receiptTaxes'];
//       double total15VAT = 0.0;
//       double totalNonVAT = 0.0;
//       double totalExempt = 0.0;
//       for (var items in totals){
//         double sum = double.tryParse(items['salesAmountWithTax'].toString())!;
//         int? taxId = int.tryParse(items['taxID']);
//         if(taxId == 1){
//           total15VAT += sum;
//         }else if(taxId == 2){
//           totalNonVAT += sum;
//         }else{
//           totalExempt += sum;
//         }
//       }
//       int currentGlobalNo = latestReceiptGlobalNo + 1;
//       String formatedReceiptGlobalNo = currentGlobalNo.toString().padLeft(10, '0');
//       String receiptDeviceSignatureSignatureHex= receiptDeviceSignature_signature_hex.toString();
//       //String receiptQrData = getReceiptQrData(receiptDeviceSignatureSignatureHex);
//       String receiptQrData = first16Chars.toString();
//       String qrurl = genericzimraqrurl + formattedDeviceID + formattedDateStr + formatedReceiptGlobalNo + receiptQrData;

//       setState(() {
//         currentUrl = qrurl;
//         currentDayNo = fiscalDayNo.toString();
//         currentReceiptGlobalNo = currentGlobalNo.toString();
//         stampDayNo = fiscalDayNo.toString();
//         stampQRData = qrurl;
//         stampReceiptGlobalNumber = currentGlobalNo.toString();
//         stampVerificationCode = receiptQrData; 
//       });
//       print("QR URL: $qrurl");
      
//     if(pingResponse=="200"){
//       try {
//         String apiEndpointSubmitReceipt =
//         "https://fdmsapi.zimra.co.zw/Device/v1/$deviceID/SubmitReceipt";
//         const String deviceModelName = "Server";
//         const String deviceModelVersion = "v1";  

//         SSLContextProvider sslContextProvider = SSLContextProvider();
//         SecurityContext securityContext = await sslContextProvider.createSSLContext();
        
//         print(receiptJsonbody);
//         // Call the Ping function
//         Map<String, dynamic> response = await SubmitReceipts.submitReceipts(
//           apiEndpointSubmitReceipt: apiEndpointSubmitReceipt,
//           deviceModelName: deviceModelName,
//           deviceModelVersion: deviceModelVersion,
//           securityContext: securityContext,
//           receiptjsonBody:receiptJsonbody,
//         );
//         print(response);
//         Get.snackbar(
//           "Zimra Response", "$response",
//           snackPosition: SnackPosition.TOP,
//           colorText: Colors.white,
//           backgroundColor: Colors.green,
//           icon: const Icon(Icons.message, color: Colors.white),
//         );
//         Map<String, dynamic> responseBody = jsonDecode(response["responseBody"]);
//         int statusCode = response["statusCode"];
//         String submitReceiptServerresponseJson = responseBody.toString();
//         print("your server server response is $submitReceiptServerresponseJson");
//         if (statusCode == 200) {
//         print("Code is 200, saving receipt...");

//         // Check if 'receiptPayments' is non-empty before accessing index 0
        
//         try {
//           final Database dbinit = await dbHelper.initDB();
//           await dbinit.insert('submittedReceipts',
//             {
//               'receiptCounter': jsonData['receipt']?['receiptCounter'] ?? 0,
//               'FiscalDayNo' : fiscalDayNo,
//               'InvoiceNo': int.tryParse(jsonData['receipt']?['invoiceNo']?.toString() ?? "0") ?? 0,
//               'receiptID': responseBody['receiptID'] ?? 0,
//               'receiptType': jsonData['receipt']['receiptType']?.toString() ?? "",
//               'receiptCurrency': jsonData['receipt']?['receiptCurrency']?.toString() ?? "",
//               'moneyType': moneyType,
//               'receiptDate': jsonData['receipt']?['receiptDate']?.toString() ?? "",
//               'receiptTime': jsonData['receipt']?['receiptDate']?.toString() ?? "",
//               'receiptTotal': receiptTotal,
//               'taxCode': "C",
//               'taxPercent': "15.00",
//               'taxAmount': taxAmount ?? 0,
//               'SalesAmountwithTax': salesAmountwithTax ?? 0,
//               'receiptHash': jsonData['receipt']?['receiptDeviceSignature']?['hash']?.toString() ?? "",
//               'receiptJsonbody': receiptJsonbody?.toString() ?? "",
//               'StatustoFDMS': "Submitted".toString(),
//               'qrurl': qrurl,
//               'receiptServerSignature': responseBody['receiptServerSignature']?['signature'].toString() ?? "",
//               'submitReceiptServerresponseJSON': "$submitReceiptServerresponseJson" ?? "noresponse",
//               'Total15VAT': total15VAT.toString(),
//               'TotalNonVAT': totalNonVAT,
//               'TotalExempt': totalExempt,
//               'TotalWT': 0.0,
//             },
//             conflictAlgorithm: ConflictAlgorithm.replace,
//           );
//           //print("Data inserted successfully!");
//           handleReceiptPrint(jsonData, qrurl, receiptQrData);
//           //generateInvoiceFromJson(jsonData, qrurl, receiptQrData);
//           //handleReceiptPrint58mm(jsonData, qrurl, receiptQrData);
//           receiptItems.clear();
//           totalAmount = 0.0;
//           taxAmount = 0.0;
//           currentReceiptGlobalNo = "";
//           currentUrl = "";
//           currentDayNo = "";
//           selectedCustomer.clear();
//           isReceiptCreditNote =0;
//           fetchDayReceiptCounter();
//           fetchReceiptsPending();
//           fetchReceiptsSubmitted();
//         } catch (e) {
//           Get.snackbar(" Db Error",
//             "$e",
//             snackPosition: SnackPosition.TOP,
//             colorText: Colors.white,
//             backgroundColor: Colors.red,
//             icon: const Icon(Icons.error),
//           );
//       }
//       return true;
//     }
//     else{
//       return false;
//     }
//       } catch (e) {
//         return false;
//       }
//     }
//     else{
      
//       try {
//         final Database dbinit = await dbHelper.initDB();
//         await dbinit.insert('submittedReceipts',
//           {
//             'receiptCounter': jsonData['receipt']?['receiptCounter'] ?? 0,
//             'FiscalDayNo' : fiscalDayNo,
//             'InvoiceNo': int.tryParse(jsonData['receipt']?['invoiceNo']?.toString() ?? "0") ?? 0,
//             'receiptID': 0,
//             'receiptType': jsonData['receipt']['receiptType']?.toString() ?? "",
//             'receiptCurrency': jsonData['receipt']?['receiptCurrency']?.toString() ?? "",
//             'moneyType': moneyType,
//             'receiptDate': jsonData['receipt']?['receiptDate']?.toString() ?? "",
//             'receiptTime': jsonData['receipt']?['receiptDate']?.toString() ?? "",
//             'receiptTotal': receiptTotal,
//             'taxCode': "C",
//             'taxPercent': "15.00",
//             'taxAmount': taxAmount ?? 0,
//             'SalesAmountwithTax': salesAmountwithTax ?? 0,
//             'receiptHash': jsonData['receipt']?['receiptDeviceSignature']?['hash']?.toString() ?? "",
//             'receiptJsonbody': receiptJsonbody?.toString() ?? "",
//             'StatustoFDMS': "NOTSubmitted".toString(),
//             'qrurl': qrurl,
//             'receiptServerSignature':"",
//             'submitReceiptServerresponseJSON':"noresponse",
//             'Total15VAT': total15VAT.toString(),
//             'TotalNonVAT': totalNonVAT,
//             'TotalExempt':totalExempt,
//             'TotalWT': 0.0,
//           },
//           conflictAlgorithm: ConflictAlgorithm.replace,
//         );
//         print("Data inserted successfully!");
//         totalAmount = 0.0;
//         taxAmount = 0.0;
//         //generateInvoiceFromJson(jsonData, qrurl, receiptQrData);
//         handleReceiptPrint(jsonData, qrurl,receiptQrData);
//         //handleReceiptPrint58mm(jsonData, qrurl, receiptQrData);
//         totalAmount = 0.0;
//         taxAmount = 0.0;
//         currentReceiptGlobalNo = "";
//         currentUrl = "";
//         currentDayNo = "";
//         selectedCustomer.clear();
//         isReceiptCreditNote =0;
//          //print58mmAdvanced(jsonData, qrurl);
//         receiptItems.clear();
//         isReceiptCreditNote =0;
//         fetchDayReceiptCounter();
//         fetchReceiptsPending();
//         fetchReceiptsSubmitted();
//       } catch (e) {
//         Get.snackbar("DB error Error",
//           "$e",
//           snackPosition: SnackPosition.TOP,
//           colorText: Colors.white,
//           backgroundColor: Colors.red,
//           icon: const Icon(Icons.error),
//         );
//       }
//       return true;
//     }
//   }

//   void getTaxPayerDetails() async{
//     final data = await dbHelper.getTaxPayerDetails();
//     setState(() {
//       tradeName = data[0]['taxPayerName'];
//       taxPayerTIN = data[0]['taxPayerTin'];
//       taxPayerVatNumber = data[0]['taxPayerVatNumber'];
//       deviceID = data[0]['deviceID'];
//       serialNo = data[0]['deviceModelName'];
//       taxPayerAddress = data[0]['taxPayerAddress'];
//       taxPayerEmail = data[0]['taxPayerEmail'];
//       taxPayerPhone = data[0]['taxPayerPhone'];
//     });
//   }

//   final databaseName1 = "pulse.db";

//   Future<void> loadBackupSQLFileWithPicker(Database db) async {
//   try {
//     final result = await FilePicker.platform.pickFiles(
//       type: FileType.custom,
//       allowedExtensions: ['sql'],
//     );

//     if (result == null || result.files.single.path == null) {
//       print("❌ No file selected.");
//       return;
//     }

//     final sqlFilePath = result.files.single.path!;
//     final file = File(sqlFilePath);

//     if (!await file.exists()) {
//       print("❌ Selected file not found.");
//       return;
//     }

//     final sqlContent = await file.readAsString();

//     // 🔍 Remove comment and empty lines before splitting
//     final cleanedContent = sqlContent
//         .split('\n')
//         .where((line) => !line.trim().startsWith('--') && line.trim().isNotEmpty)
//         .join('\n');

//     // 🔍 Split SQL statements by semicolon
//     final rawStatements = cleanedContent
//         .split(';')
//         .map((s) => s.trim())
//         .where((s) => s.isNotEmpty)
//         .toList();

//     print("📦 Executing ${rawStatements.length} SQL statements...");

//     for (final stmt in rawStatements) {
//       final stmtTrimmed = stmt.trimLeft();
//       final stmtLower = stmtTrimmed.toLowerCase();

//       try {
//         // Force 'INSERT INTO' to become 'INSERT OR REPLACE INTO'
//         String cleanStmt;
//         if (stmtLower.startsWith('insert into')) {
//           cleanStmt = 'INSERT OR REPLACE INTO' + stmtTrimmed.substring(11);
//         } else {
//           cleanStmt = stmtTrimmed;
//         }

//         await db.execute(cleanStmt);
//       } catch (e) {
//         print("🧨 Error executing: $stmtTrimmed");
//         print("   👉 $e");
//       }
//     }
//     print("✅ Backup loaded successfully.");
//     Get.snackbar(
//       "Backup Restore",
//       "Backup restored successfully!",
//       icon: const Icon(Icons.check, color: Colors.white),
//       colorText: Colors.white,
//       backgroundColor: Colors.green,
//       snackPosition: SnackPosition.TOP,
//     );
//   } catch (e) {
//     print("❌ Exception during backup restore: $e");
//   }
// }



//   void restoreBackup() async {
//     final databasePath = await databaseFactoryFfi.getDatabasesPath();
//     final fullPath = path.join(databasePath, databaseName1);
//     final db = await openDatabase(fullPath);

//     await loadBackupSQLFileWithPicker(db);
//   }

//   @override
//   void dispose() {
//     inputSub?.cancel();
//     signedSub?.cancel();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.white,
//       appBar: AppBar(
//         backgroundColor: Colors.green,
//         title: const Text("FDMS GateWay", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),),
//         centerTitle: true,
//       ),
//       body: Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.start,
//           children: <Widget>[
//             Container(
//               height: 100,
//               width: 150,
//               decoration: BoxDecoration(
//                 image: DecorationImage(
//                   image: AssetImage('assets/tigerwebLogo.PNG'),
//                   fit: BoxFit.cover,
//                 ),
//               ),
//             ),
//             const SizedBox(height: 10),
//             Padding(
//               padding: const EdgeInsets.symmetric(horizontal:20.0),
//               child: Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   Container(
//                     height: 450,
//                     width: 600,
//                     decoration: BoxDecoration(
//                       borderRadius: BorderRadius.circular(20),
//                       color: Colors.white,
//                       boxShadow: [
//                             BoxShadow(
//                               color: Colors.black.withOpacity(0.3), // shadow color
//                               spreadRadius: 4, // how much the shadow spreads
//                               blurRadius: 10,  // how soft the shadow is
//                               offset: Offset(0, 6), // horizontal and vertical offset
//                             ),
//                           ],
//                     ),
//                     child: Padding(
//                       padding: EdgeInsets.symmetric(vertical: 20, horizontal: 20),
//                       child: Column(
//                         mainAxisAlignment: MainAxisAlignment.start,
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Text("TAXPAYER NAME: $tradeName " , style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),),
//                           SizedBox(height: 10,),
//                           Text("TAXPAYER TIN: $taxPayerTIN" , style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),),
//                           SizedBox(height: 10,),
//                           Text("VAT NUMBER: $taxPayerVatNumber" , style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),),
//                           SizedBox(height: 10,),
//                           Text("DEVICE ID: $deviceID" , style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),),
//                           SizedBox(height: 10,),
//                           Text("SERIAL NO: $serialNo" , style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),),
//                           SizedBox(height: 10,),
//                           Text("MODEL NAME: Server" , style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),),
//                           SizedBox(height: 10,),
//                           Text("FISCAL DAY: $currentFiscal" , style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),),
//                           SizedBox(height: 10,),
//                           Text("CLOSEDAY TIME: " , style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),),
//                           SizedBox(height: 10,),
//                           Text("RECEIPT COUNTER: ${dayReceiptCounter.length}" , style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),),
//                           SizedBox(height: 10,),
//                           Text("RECEIPTS SUBMITTED:${receiptsSubmitted.length} " , style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),),
//                           SizedBox(height: 10,),
//                           Text("RECEIPTS PENDING: ${receiptsPending.length}" , style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),),
//                           // ElevatedButton(
//                           //   child: Text('Test Printing'),
//                           //   onPressed: () async {
//                           //     final printers = await Printing.listPrinters();
//                           //     print("Available printers: $printers");})
//                         ],
//                       ),
//                     ),
//                   ),
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.start,
//                     children: [
//                       Container(
//                         height: 450,
//                         width: 200,
//                         decoration: BoxDecoration(
//                           borderRadius: BorderRadius.only(topLeft: Radius.circular(20), bottomLeft: Radius.circular(20)),
//                           color: Colors.white,
//                           boxShadow: [
//                             BoxShadow(
//                               color: Colors.black.withOpacity(0.3), // shadow color
//                               spreadRadius: 4, // how much the shadow spreads
//                               blurRadius: 10,  // how soft the shadow is
//                               offset: const Offset(0, 6), // horizontal and vertical offset
//                             ),
//                           ],
//                         ),
//                         child: Padding(
//                           padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 10),
//                           child: Column(
//                             mainAxisAlignment: MainAxisAlignment.start,
//                             children: [
//                               const Text("Engine Options", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),),
//                               const SizedBox(height: 20,),
//                               CustomOutlineBtn(
//                                 icon:const  Icon(Icons.broadcast_on_home_outlined, color: Colors.white,),
//                                 text: isRunning? "Processing" :"Start Engine", 
//                                 color: Colors.green,
//                                 color2: Colors.green,
//                                 height: 50,
//                                 onTap: isRunning ? null : startEngine,
//                               ),
//                               const SizedBox(height: 20,),
//                               CustomOutlineBtn(
//                                 icon:const  Icon(Icons.stop, color: Colors.white,),
//                                 text: "Stop Engine", 
//                                 color: Colors.red,
//                                 color2: Colors.red,
//                                 height: 50,
//                                 onTap: isRunning ? killEngine : null ,
//                               ),
//                             ],
//                           ),
//                         ),
//                       ),
//                       SizedBox(width: 3,),
//                       Container(
//                         height: 450,
//                         width: 397,
//                         decoration: BoxDecoration(
//                           borderRadius: BorderRadius.only(topRight: Radius.circular(20), bottomRight: Radius.circular(20)),
//                           color: Colors.white,
//                           boxShadow: [
//                             BoxShadow(
//                               color: Colors.black.withOpacity(0.3), // shadow color
//                               spreadRadius: 4, // how much the shadow spreads
//                               blurRadius: 10,  // how soft the shadow is
//                               offset: Offset(0, 6), // horizontal and vertical offset
//                             ),
//                           ],
//                         ),
//                         child: Padding(
//                           padding: EdgeInsets.symmetric(vertical: 20, horizontal: 20),
//                           child: Column(
//                             mainAxisAlignment: MainAxisAlignment.start,
//                             children: [
//                               const Text("FDMS Options", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),),
//                               const SizedBox(height: 20,),
//                               CustomOutlineBtn(
//                                 icon:const  Icon(Icons.open_in_browser, color: Colors.white,),
//                                 text: "Manual Open Day", 
//                                 color: Colors.green,
//                                 color2: Colors.green,
//                                 height: 50,
//                                 onTap: (){
//                                   //extractFromFiscalFolder();
//                                   openDayManual();
//                                 },
//                               ),
//                               const SizedBox(height: 10,),
//                               CustomOutlineBtn(
//                                 icon: const Icon(Icons.settings_accessibility, color: Colors.white,),
//                                 text: "Device Configuration", 
//                                 color: Colors.green,
//                                 color2: Colors.green,
//                                 height: 50,
//                                 onTap: (){
//                                   //extractFromFiscalFolder();
//                                   getConfig();
//                                 },
//                               ),
//                               const SizedBox(height: 10,),
//                               CustomOutlineBtn(
//                                 icon:const Icon(Icons.satellite_alt, color: Colors.white,),
//                                 text: "Device Status", 
//                                 color: Colors.green,
//                                 color2: Colors.green,
//                                 height: 50,
//                                 onTap: (){
//                                   //extractFromFiscalFolder();
//                                   getStatus();
//                                 },
//                               ),
//                               const SizedBox(height: 10,),
//                               CustomOutlineBtn(
//                                 icon: const Icon(Icons.pinch, color: Colors.white,),
//                                 text: "Ping", 
//                                 color: Colors.green,
//                                 color2: Colors.green,
//                                 height: 50,
//                                 onTap: (){
//                                   //extractFromFiscalFolder();
//                                   ping();
//                                 },
//                               ),
//                               const SizedBox(height: 10,),
//                               CustomOutlineBtn(
//                                 icon: const Icon(Icons.send, color: Colors.white,),
//                                 text: "Submit Missing Receipts", 
//                                 color: Colors.green,
//                                 color2: Colors.green,
//                                 height: 50,
//                                 onTap: (){
//                                   //extractFromFiscalFolder()
//                                   submitUnsubmittedReceipts();
//                                 },
//                               ),
//                               const SizedBox(height: 10,),
//                               CustomOutlineBtn(
//                                 icon:const Icon(Icons.close, color: Colors.white,),
//                                 text: "Close Day", 
//                                 color: Colors.green,
//                                 color2: Colors.green,
//                                 height: 50,
//                                 onTap: ()async{
//                                   //extractFromFiscalFolder();
//                                   String filePath = "/storage/emulated/0/Pulse/Configurations/steamTest_T_certificate.p12";
//                                   String password = "steamTest123";
//                                   int fiscalDay = currentFiscal;
//                                   List<Map<String , dynamic>> openDayData = await dbHelper.getDayOpenedDate(fiscalDay);
//                                   String openDayDate = openDayData[0]["FiscalDayOpened"];
//                                   DateTime parseDate = DateTime.parse(openDayDate);
//                                   String formattedDate = DateFormat('yyyy-MM-dd').format(parseDate);
//                                   //APIService.sendReceipt();
//                                   final (invoices, creditNotes, balances, concatStr) =
//                                     await buildFiscalDayCountersAndConcat(fiscalDay);
//                                   String finalStringConcat = "$deviceID$fiscalDay$formattedDate$concatStr";
//                                   DateTime closeDate = DateTime.now();
//                                   String formattedCloseDate = DateFormat("yyyy-MM-ddTHH:mm:ss").format(closeDate);
//                                   // Hash generation
//                                   finalStringConcat.trim();
                  
//                                   var bytes = utf8.encode(finalStringConcat);
//                                   var digest = sha256.convert(bytes);
//                                   final hash = base64.encode(digest.bytes);
//                                   print("Close day Hash :$hash");
                  
//                                   //signature generation
//                                   try {
//                                     final byteData = await rootBundle.load('assets/private_key.pem');
//                                     final buffer = byteData.buffer;
//                                     // Write to a temp file
//                                     final tempDir = Directory.systemTemp;
//                                     final pemFile = File('${tempDir.path}/private_key.pem');
//                                     await pemFile.writeAsBytes(
//                                       buffer.asUint8List(byteData.offsetInBytes, byteData.lengthInBytes),
//                                     );
//                                     final Map<String, String> signedDataMap  = PemSigner.signDataWithMd5(
//                                       data: finalStringConcat,
//                                       privateKeyPath: pemFile.path,
//                                     );
//                                     //final Map<String, String> signedDataMap = await signData(filePath, password, finalStringConcat);
//                                     receiptDeviceSignature_signature_hex = signedDataMap["receiptDeviceSignature_signature_hex"] ?? "";
//                                     receiptDeviceSignature_signature = signedDataMap["receiptDeviceSignature_signature"] ?? "";
//                                     first16Chars = signedDataMap["receiptDeviceSignature_signature_md5_first16"] ?? "";
//                                   } catch (e) {
//                                     Get.snackbar("Signing Error", "$e", snackPosition: SnackPosition.TOP);
//                                   }
                  
//                                   try {
//                                     String apiEndpointCloseDay =
//                                     "https://fdmsapi.zimra.co.zw/Device/v1/$deviceID/CloseDay";
//                                     const String deviceModelName = "Server";
//                                     const String deviceModelVersion = "v1";  
                    
//                                     SSLContextProvider sslContextProvider = SSLContextProvider();
//                                     SecurityContext securityContext = await sslContextProvider.createSSLContext();
//                                     // JSON payload:
//                                     final payload = { 
//                                     'deviceID': deviceID,
//                                     'fiscalDayNo': fiscalDay,
//                                     'fiscalDayCounters': [
//                                       ...invoices.map((c) => c.toJson()),
//                                       ...creditNotes.map((c) => c.toJson()),
//                                       ...balances.map((c) => c.toJson()),
//                                     ],
//                                     'fiscalDayDeviceSignature': {
//                                       'hash' : hash,
//                                       'signature': receiptDeviceSignature_signature,
//                                     },
//                                     'receiptCounter': dayReceiptCounter.length,
//                                     };
                    
//                                     Map<String , dynamic> response = await CloseDay.submitCloseDay(
//                                       apiEndpoint: apiEndpointCloseDay,
//                                       deviceModelName: deviceModelName,
//                                       deviceModelVersion: deviceModelVersion,
//                                       securityContext: securityContext,
//                                       payload: payload,
//                                     );
//                                     Get.snackbar(
//                                       "Zimra Response", "$response",
//                                       snackPosition: SnackPosition.TOP,
//                                       colorText: Colors.white,
//                                       backgroundColor: Colors.green,
//                                       icon: const Icon(Icons.message, color: Colors.white),
//                                     );
//                                     print("Response: $response");
//                                     // And your concatenated string is:
//                                     print(finalStringConcat);
//                                     print(payload); 
//                                     await dbHelper.updateFiscalDay(fiscalDay, formattedCloseDate);
//                                     // File file = File("/storage/emulated/0/Pulse/Configurations/jsonFile.txt");
//                                     // await file.writeAsString(jsonEncode(payload));
//                                     await handleZReportPrint();
//                                     // await getopendayData();
//                                     // await handle58mmZreport();
//                                   } catch (e) {
//                                     Get.snackbar('Close Day Request Error', "$e" , snackPosition: SnackPosition.TOP , colorText: Colors.white , backgroundColor: Colors.red , icon: Icon(Icons.error));
//                                   }
//                                 },
//                               ),
//                             ],
//                           ),
//                         ),
//                       )
//                     ],
//                   ),
//                 ],
//               ),
//             ),
//             const SizedBox(height: 10,),
//             receiptsPending.isEmpty ? SizedBox(height: 10,)
//             : Container(
//               height: 40,
//               width: 600,
//               decoration: BoxDecoration(
//                 color: Colors.amber,
//                 borderRadius: BorderRadius.circular(10),
//               ),
//               child: Center(
//                 child: Text("Please Submit Missing Receipts!!" , style: TextStyle(fontWeight: FontWeight.bold),),
//               ),
//             )
//           ],
//         ),
//       ),
//       floatingActionButton: FloatingActionButton(
//         onPressed:(){
//           showModalBottomSheet(
//             context: context,
//             builder: (BuildContext context) {
//               return Wrap(
//                 children: [
//                   ListTile(
//                     leading: const Icon(Icons.business),
//                     title:const Text('Company Settings'),
//                     onTap: () {
//                       Get.to(()=> const CompanydetailsPage());
//                       // handle tap
//                     },
//                   ),
//                   ListTile(
//                     leading: const Icon(Icons.calendar_month_outlined),
//                     title:const Text('Open Day Table'),
//                     onTap: () {
//                       Get.to(()=> const OpenDayPage());
//                     },
//                   ),
//                   ListTile(
//                     leading: const Icon(Icons.send_and_archive_outlined),
//                     title: const Text('Submitted Receipts'),
//                     onTap: () {
//                       Get.to(()=> const Submittedreceipts());
//                       // handle tap
//                     },
//                   ),
//                   ListTile(
//                     leading: const Icon(Icons.data_thresholding_sharp),
//                     title: const Text('Reporting'),
//                     onTap: () => Get.to(()=> const FiscalreportsPage()),
//                   ),
//                   ListTile(
//                     leading: const Icon(Icons.print),
//                     title: const Text('Print Fiscal Day Z Report'),
//                     onTap: ()async{
//                       try {
//                         await getopendayData();
//                         await handle58mmZreport();
//                         //await handleZReportPrint();
//                       } catch (e) {
//                         Get.snackbar("Z Report Printing Error", "$e" , snackPosition: SnackPosition.TOP, backgroundColor: Colors.red , colorText: Colors.white );
//                       }
//                     },
//                   ),
//                   ListTile(
//                     leading:const Icon(Icons.storage_rounded),
//                     title:const Text('Database backup'),
//                     onTap: () async {
//                       try {
//                         DatabaseBackupService backupService = DatabaseBackupService();
      
//                         // Request permissions first
//                         bool hasPermission = await backupService.requestStoragePermission();
//                         if (!hasPermission) {
//                           print('Storage permission denied');
//                           return;
//                         }
//                         Database db = await openDatabase('pulse.db');
//                         //createDatabaseFileBackup();
//                         String? fileCopyPath = await backupService.createDatabaseFileBackup();
//                         if (fileCopyPath != null) {
//                           print('File backup created at: $fileCopyPath');
//                         }
//                         //exportDatabaseAsSQL(db);
//                         String? sqlPath = await backupService.exportDatabaseAsSQL(db);
//                         if (sqlPath != null) {
//                           print('SQL backup created at: $sqlPath');
//                         }
//                         Get.snackbar(
//                           "Backup Created", 
//                           "Database backup created successfully.",
//                           snackPosition: SnackPosition.TOP,
//                           backgroundColor: Colors.green,
//                           colorText: Colors.white,
//                           icon: const Icon(Icons.check_circle, color: Colors.white),
//                         );
//                       } catch (e) {
//                         Get.snackbar(
//                           "Create Creating Backups", 
//                           "$e",
//                           snackPosition: SnackPosition.TOP,
//                           backgroundColor: Colors.red,
//                           colorText: Colors.white,
//                           icon: const Icon(Icons.error, color: Colors.white),
//                         );
//                       }
//                     },
//                   ),
//                   ListTile(
//                     leading: const Icon(Icons.refresh_sharp),
//                     title: const Text('Load Data Back File'),
//                     onTap: (){
//                       restoreBackup();
//                     },
//                   ),
//                    ListTile(
//                     leading: const Icon(Icons.delete),
//                     title: const Text('Clear Data'),
//                     onTap: ()async {
//                       try {
//                         await dbHelper.clearAllData();
//                         Get.snackbar("Delete Confirmed", "Database records cleared" , snackPosition: SnackPosition.TOP, backgroundColor: Colors.green , colorText: Colors.white);
//                       } catch (e) {
//                         Get.snackbar(
//                           "Error Clearing Database","$e", snackPosition: SnackPosition.TOP, backgroundColor: Colors.red , colorText: Colors.white);
//                       }
//                     },
//                   ),
                  
//                   ListTile(
//                     leading: const Icon(Icons.cancel),
//                     title: const Text('Cancel'),
//                     onTap: () => Navigator.pop(context),
//                   ),
//                   const SizedBox(height: 20,),

//                 ],
//               );
//             },
//           );
//         } ,
//         tooltip: 'Menu',
//         child: const Icon(Icons.settings),
//       ), // This trailing comma makes auto-formatting nicer for build methods.
//     );
//   }
// }

// class InvoiceData {
//   final String customerName;
//   final String invoiceNumber;
//   final String date;
//   final String currency;
//   final String tax;
//   final String total;
//   final String tin;
//   final String vat;
//   final List<Map<String, dynamic>> products;
//   final String phone;

//   InvoiceData({
//     required this.customerName,
//     required this.invoiceNumber,
//     required this.date,
//     required this.currency,
//     required this.tax,
//     required this.total,
//     required this.tin,
//     required this.vat,
//     required this.products,
//     required this.phone,
//   });

//   @override
//   String toString() {
//     return '''
// Customer: $customerName
// Invoice #: $invoiceNumber
// Date: $date
// Currency: $currency
// Tax: $tax
// Total: $total
// TIN: $tin
// VAT: $vat
// Phone: $phone
// Products:
// ${products.map((p) => '  - ${p['desc']} x${p['qty']} @ ${p['unit']} = ${p['total']}').join('\n')}
// ''';
//   }
// }

// class FiscalDayCounter {
//   final String type;
//   final String currency;
//   final double? percent;
//   final int? taxID;
//   final String? moneyType;
//   double value;

//   FiscalDayCounter({
//     required this.type,
//     required this.currency,
//     this.percent,
//     this.taxID,
//     this.moneyType,
//     this.value = 0,
//   });

//   String get key {
//     if (type == 'BalanceByMoneyType') {
//       return '$type|$currency|$moneyType';
//     }
//     return '$type|$currency|${percent!.toStringAsFixed(2)}|$taxID';
//   }

//   void accumulate(double addMe) => value += addMe;

//   Map<String, dynamic> toJson() {
//     final double roundedValue = double.parse(value.toStringAsFixed(2));
//     if (roundedValue == 0.0) return {}; // skip if zero

//     final m = {
//       'fiscalCounterType': type,
//       'fiscalCounterCurrency': currency,
//       'fiscalCounterValue': type.startsWith('CreditNote') ? roundedValue : roundedValue.abs(),
//     };
//     if (percent != null) m['fiscalCounterTaxPercent'] = percent!.toStringAsFixed(2);
//     if (taxID != null) m['fiscalCounterTaxID'] = taxID.toString();
//     if (moneyType != null) m['fiscalCounterMoneyType'] = moneyType.toString();
//     return m;
//   }

//   String toConcatString() {
//     if (type == 'SaleTaxByTax' && percent?.toStringAsFixed(2) != '15.00') return '';
//     if (type == 'CreditNoteTaxByTax' && percent?.toStringAsFixed(2) != '15.00') return '';

//     final buf = StringBuffer(type.toUpperCase());
//     buf.write(currency.toUpperCase());

//     if (type == 'BalanceByMoneyType') {
//       if(value == 0.0) return ''; // skip zero balances
//       buf.write(moneyType!.toUpperCase());
//     } else if (taxID != 3 && percent != null) {
//       buf.write(percent!.toStringAsFixed(2));
//     }

//     if (type.startsWith('CreditNote')) {
//       buf.write((value * 100).round());
//     } else {
//       buf.write((value.abs() * 100).round());
//     }

//     return buf.toString();
//   }
// }

// Future<(
//   List<FiscalDayCounter> invoices,
//   List<FiscalDayCounter> creditNotes,
//   List<FiscalDayCounter> balances,
//   String concatenatedString
// )> buildFiscalDayCountersAndConcat(int fiscalDayNo) async {
//   final invMap = <String, FiscalDayCounter>{};
//   final crdMap = <String, FiscalDayCounter>{};
//   final balMap = <String, FiscalDayCounter>{};

//   DatabaseHelper dbHelper = DatabaseHelper();
//   final db = await dbHelper.initDB();

//   final rows = await db.query(
//     'submittedReceipts',
//     columns: ['receiptType', 'receiptJsonbody'],
//     where: 'FiscalDayNo = ?',
//     whereArgs: [fiscalDayNo],
//   );

//   for (final row in rows) {
//     final receiptType = row['receiptType'] as String;
//     final body = json.decode(row['receiptJsonbody'] as String);
//     final r = body['receipt'] as Map<String, dynamic>;
//     final curr = r['receiptCurrency'] as String;
//     final isCredit = receiptType != 'FISCALINVOICE';

//     for (final t in r['receiptTaxes'] as List<dynamic>) {
//       final rawTaxAmt = t['taxAmount'];
//       final rawSales = t['salesAmountWithTax'];
//       final taxAmt = rawTaxAmt is num ? rawTaxAmt.toDouble() : double.tryParse(rawTaxAmt.toString()) ?? 0;
//       final salesAmt = rawSales is num ? rawSales.toDouble() : double.tryParse(rawSales.toString()) ?? 0;
//       final taxCode = t['taxCode'];
//       final perc = (taxCode == "C") ? 0.0 : double.parse(t['taxPercent'] as String);
//       final taxId = int.parse(t['taxID'].toString());

//       if (!isCredit) {
//         if (taxCode == "C") {
//           final sbtKey = 'SaleByTax|$curr|${perc.toStringAsFixed(2)}|$taxId';
//           invMap.putIfAbsent(sbtKey, () => FiscalDayCounter(
//             type: 'SaleByTax', currency: curr, taxID: taxId))
//             .accumulate(salesAmt);

//           final sttKey = 'SaleTaxByTax|$curr|${perc.toStringAsFixed(2)}|$taxId';
//           invMap.putIfAbsent(sttKey, () => FiscalDayCounter(
//             type: 'SaleTaxByTax', currency: curr, taxID: taxId))
//             .accumulate(taxAmt);
//         } else {
//           final sbtKey = 'SaleByTax|$curr|${perc.toStringAsFixed(2)}|$taxId';
//           invMap.putIfAbsent(sbtKey, () => FiscalDayCounter(
//             type: 'SaleByTax', currency: curr, percent: perc, taxID: taxId))
//             .accumulate(salesAmt);

//           final sttKey = 'SaleTaxByTax|$curr|${perc.toStringAsFixed(2)}|$taxId';
//           invMap.putIfAbsent(sttKey, () => FiscalDayCounter(
//             type: 'SaleTaxByTax', currency: curr, percent: perc, taxID: taxId))
//             .accumulate(taxAmt);
//         }
//       } else {
//         if (taxCode == "C") {
//           final cbtKey = 'CreditNoteByTax|$curr|${perc.toStringAsFixed(2)}|$taxId';
//           crdMap.putIfAbsent(cbtKey, () => FiscalDayCounter(
//             type: 'CreditNoteByTax', currency: curr, taxID: taxId))
//             .accumulate(salesAmt);

//           final cttKey = 'CreditNoteTaxByTax|$curr|${perc.toStringAsFixed(2)}|$taxId';
//           crdMap.putIfAbsent(cttKey, () => FiscalDayCounter(
//             type: 'CreditNoteTaxByTax', currency: curr, taxID: taxId))
//             .accumulate(taxAmt);
//         } else {
//           final cbtKey = 'CreditNoteByTax|$curr|${perc.toStringAsFixed(2)}|$taxId';
//           crdMap.putIfAbsent(cbtKey, () => FiscalDayCounter(
//             type: 'CreditNoteByTax', currency: curr, percent: perc, taxID: taxId))
//             .accumulate(salesAmt);

//           final cttKey = 'CreditNoteTaxByTax|$curr|${perc.toStringAsFixed(2)}|$taxId';
//           crdMap.putIfAbsent(cttKey, () => FiscalDayCounter(
//             type: 'CreditNoteTaxByTax', currency: curr, percent: perc, taxID: taxId))
//             .accumulate(taxAmt);
//         }
//       }
//     }

//     for (final p in r['receiptPayments'] as List<dynamic>) {
//       final mType = p['moneyTypeCode'] as String;
//       final rawAmt = p['paymentAmount'];
//       final amt = rawAmt is num ? rawAmt.toDouble() : double.tryParse(rawAmt.toString()) ?? 0;

//       final bKey = 'BalanceByMoneyType|$curr|$mType';
//       balMap.putIfAbsent(bKey, () => FiscalDayCounter(
//         type: 'BalanceByMoneyType', currency: curr, moneyType: mType))
//         .accumulate(amt);
//     }
//   }

//   final allCounters = [
//     ...invMap.values,
//     ...crdMap.values,
//     ...balMap.values,
//   ];

//   // ✅ Fixed: Canonical sort by type → currency → taxID or moneyType
//   allCounters.sort((a, b) {
//     const counterOrder = [
//       'SaleByTax',
//       'SaleTaxByTax',
//       'CreditNoteByTax',
//       'CreditNoteTaxByTax',
//       'BalanceByMoneyType',
//     ];

//     final typeComparison = counterOrder.indexOf(a.type).compareTo(counterOrder.indexOf(b.type));
//     if (typeComparison != 0) return typeComparison;

//     final currencyComparison = a.currency.compareTo(b.currency);
//     if (currencyComparison != 0) return currencyComparison;

//     if (a.type == 'BalanceByMoneyType') {
//       final mA = a.moneyType ?? '';
//       final mB = b.moneyType ?? '';
//       return mA.compareTo(mB);
//     }

//     if (a.taxID != null && b.taxID != null) {
//       return a.taxID!.compareTo(b.taxID!);
//     }

//     return 0;
//   });

//   final concat = StringBuffer();
//   for (final c in allCounters) {
//     final concatStr = c.toConcatString();
//     if (concatStr.isNotEmpty) {
//       concat.write(concatStr);
//     }
//   }

//   final invoices = allCounters
//       .where((c) => c.type.startsWith('Sale') && double.parse(c.value.toStringAsFixed(2)) != 0.0)
//       .toList();
//   final creditNotes = allCounters
//       .where((c) => c.type.startsWith('CreditNote') && double.parse(c.value.toStringAsFixed(2)) != 0.0)
//       .toList();
//   final balances = allCounters
//       .where((c) => c.type == 'BalanceByMoneyType' && double.parse(c.value.toStringAsFixed(2)) != 0.0)
//       .toList();

//   debugPrint("Canonical Signature String: ${concat.toString()}");

//   return (invoices, creditNotes, balances, concat.toString());
// }


// class DatabaseBackupService{
//   Future<String?> createDatabaseFileBackup() async{
//     try {
//       String databasePath  = await getDatabasesPath();
//       String dbPath = join(databasePath, "pulse.db");
//       if(!await File(dbPath).exists()){
//         Get.snackbar(
//           "Error", 
//           "Database Not Found",
//           snackPosition: SnackPosition.TOP,
//           backgroundColor: Colors.red,
//           colorText: Colors.white,
//           icon: const Icon(Icons.error, color: Colors.white),
//         );
//       }
//       String backupDir = 'C:/Fiscal/Configurations/DatabaseBackups';
//       await Directory(backupDir).create(recursive: true);

//       //create a backup file name with timestamp
//       String timestamp = DateTime.now().toIso8601String().replaceAll(':', '_');
//       String backupPath = '$backupDir/backup_$timestamp.db';

//       await File(dbPath).copy(backupPath);
//       return backupPath;
//     } catch (e) {
//       Get.snackbar(
//           "Error Creating File Backup", 
//           "$e",
//           snackPosition: SnackPosition.TOP,
//           backgroundColor: Colors.red,
//           colorText: Colors.white,
//           icon: const Icon(Icons.error, color: Colors.white),
//       );
//       return '';
//     }
//   }

//   // Method 2: Export as SQL statements first code
//   Future<String?> exportDatabaseAsSQL(Database database) async {
//     try {
//       // Get all table names
//       List<Map<String, dynamic>> tables = await database.rawQuery(
//         "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'"
//       );
      
//       StringBuffer sqlBuffer = StringBuffer();
//       sqlBuffer.writeln('-- Database Backup Generated: ${DateTime.now()}');
//       sqlBuffer.writeln('-- Begin Transaction');
//       sqlBuffer.writeln('BEGIN TRANSACTION;');
//       sqlBuffer.writeln();
      
//       for (Map<String, dynamic> table in tables) {
//         String tableName = table['name'];
        
//         // Get table schema
//         List<Map<String, dynamic>> schema = await database.rawQuery(
//           "SELECT sql FROM sqlite_master WHERE type='table' AND name='$tableName'"
//         );
        
//         if (schema.isNotEmpty) {
//           sqlBuffer.writeln('-- Table: $tableName');
//           sqlBuffer.writeln('DROP TABLE IF EXISTS $tableName;');
//           sqlBuffer.writeln('${schema[0]['sql']};');
//           sqlBuffer.writeln();
          
//           // Get table data
//           List<Map<String, dynamic>> rows = await database.query(tableName);
          
//           if (rows.isNotEmpty) {
//             // Get column names
//             List<String> columns = rows[0].keys.toList();
//             String columnsList = columns.join(', ');
            
//             sqlBuffer.writeln('-- Data for table: $tableName');
            
//             for (Map<String, dynamic> row in rows) {
//               List<String> values = [];
//               for (String column in columns) {
//                 dynamic value = row[column];
//                 if (value == null) {
//                   values.add('NULL');
//                 } else if (value is String) {
//                   // Escape single quotes
//                   String escapedValue = value.replaceAll("'", "''");
//                   values.add("'$escapedValue'");
//                 } else {
//                   values.add(value.toString());
//                 }
//               }
              
//               String valuesList = values.join(', ');
//               sqlBuffer.writeln('INSERT INTO $tableName ($columnsList) VALUES ($valuesList);');
//             }
//             sqlBuffer.writeln();
//           }
//         }
//       }
      
//       sqlBuffer.writeln('-- End Transaction');
//       sqlBuffer.writeln('COMMIT;');
      
      
//       String backupDir = 'C:/Fiscal/Configurations/DatabaseBackups';
//       await Directory(backupDir).create(recursive: true);
      
//       String timestamp = DateTime.now().toIso8601String().replaceAll(':', '_');
//       String backupPath = '$backupDir/backup_$timestamp.sql';
      
//       File backupFile = File(backupPath);
//       await backupFile.writeAsString(sqlBuffer.toString());
      
//       print('SQL backup created: $backupPath');
//       return backupPath;
      
//     } catch (e) {
//       Get.snackbar(
//         "Error Creating SQL Backup", 
//         "$e",
//         snackPosition: SnackPosition.TOP,
//         colorText: Colors.white,
//         backgroundColor: Colors.red,
//         icon: const Icon(Icons.error, color: Colors.white),
//       );
//       //print('Error creating SQL backup: $e');
//       return null;
//     }
//   }

//   Future<bool> requestStoragePermission() async {
//     if (Platform.isAndroid) {
//       var status = await Permission.storage.status;
//       if (!status.isGranted) {
//         status = await Permission.storage.request();
//       }
//       return status.isGranted;
//     }
//     return true; // iOS doesn't need explicit storage permission for app documents
//   }


// }







