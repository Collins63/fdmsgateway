import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class SSLContextProvider {
  //void initState(){
    //requestStoragePermission1();
  //}
  Future<void> requestStoragePermission1() async {
  if (await Permission.storage.request().isGranted) {
    print("✅ Storage permission granted!");
  } else {
    print("❌ Storage permission denied!");
  }
  
  if (await Permission.manageExternalStorage.request().isGranted) {
    print("✅ Manage External Storage permission granted!");
  } else {
    // print("❌ Manage External Storage permission denied! Redirecting to settings...");
    // openAppSettings();  // Opens app settings for manual permission grant
    if (await Permission.manageExternalStorage.isPermanentlyDenied) {
      openAppSettings(); // Only do this once and show a dialog beforehand
    }
  }
}

  Future<bool> requestStoragePermission() async {
  if (await Permission.storage.isGranted) {
    return true;
  }
  
  var status = await Permission.storage.request();
  return status.isGranted;
}

//from mobile application
  // Future<SecurityContext> createSSLContext() async {
  //   requestStoragePermission1();
  //   // Get the local directory for app files
  //   Directory? appDir = await getApplicationDocumentsDirectory();
  //   //bool hasPermission = await requestStoragePermission();
  //   // Construct the correct path to the keystore
  //   String keystorePath = "/storage/emulated/0/Pulse/Configurations/steamTest_T_certificate.p12";
  //   String keystorePassword = "steamTest123"; // Replace with actual password
  //   SecurityContext securityContext = SecurityContext.defaultContext;
    

  // // if (!hasPermission) {
  // //   print("Permission denied. Cannot access external storage.");
  // // }

  // File keystoreFile = File(keystorePath);
  // if (!keystoreFile.existsSync()) {
  //   print("Keystore file not found at: $keystorePath");
  // }

  // print("Keystore file exists and is accessible!");

  //   try {
  //     File keystoreFile = File(keystorePath);
  //     if (!keystoreFile.existsSync()) {
  //       throw Exception("Keystore file not found at: $keystorePath");
  //     }

  //     securityContext.useCertificateChain(keystorePath, password: keystorePassword);
  //     securityContext.usePrivateKey(keystorePath, password: keystorePassword);

  //     print("SSL Context parameterization complete.");
  //   } catch (e) {
  //     print("Error initializing SSL Context: $e");
  //   }

  //   return securityContext;
  // }

  Future<SecurityContext> createSSLContext() async {
  final Directory appDir = await getApplicationDocumentsDirectory();

  // Define paths to store the extracted files
  final certFile = File('${appDir.path}/certificate.pem');
  final keyFile = File('${appDir.path}/private_key.pem');

  // Copy certificate.pem from assets to temp storage
final certBytes = await rootBundle.load('assets/certificate.pem');
await certFile.writeAsBytes(certBytes.buffer.asUint8List(), flush: true);


  // Copy private_key.pem from assets to temp storage
final keyBytes = await rootBundle.load('assets/private_key.pem');
await keyFile.writeAsBytes(keyBytes.buffer.asUint8List(), flush: true);


  // Now load into the SecurityContext
  final securityContext = SecurityContext();

  try {
    securityContext.useCertificateChain(certFile.path);
    securityContext.usePrivateKey(keyFile.path);
    print("SSL Context configured successfully.");
  } catch (e) {
    print("Error loading certificate/private key into SecurityContext: $e");
  }

  return securityContext;
}
}
