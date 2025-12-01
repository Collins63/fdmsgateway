
import 'dart:io';
import 'dart:typed_data';

import 'package:fdmsgateway/common/button.dart';
import 'package:fdmsgateway/database.dart';
import 'package:fdmsgateway/main.dart';
import 'package:fdmsgateway/models/jsonModels.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CompanydetailsPage extends StatefulWidget {
  const CompanydetailsPage({super.key});

  @override
  State<CompanydetailsPage> createState() => _CompanydetailsPageState();
}

class _CompanydetailsPageState extends State<CompanydetailsPage> {

  bool isLoading = true;
  List<Map<String, dynamic>> taxPayerDetails= [];
  final ScrollController _verticalScroll = ScrollController();
  final ScrollController _horizontalScroll = ScrollController();
  List<int> selectedReceipt = [];
  final saveCompanyDetailsKey = GlobalKey<FormState>();
  DatabaseHelper dbHelper = DatabaseHelper();
  bool isReceipt = false;
  bool isInvoice = false;
  
  @override
  void initState() {
    super.initState();
    fetchTaxPayerDetails();
    showSelectedPrinter();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      isReceipt = prefs.getBool('isReceipt') ?? false; // default = false
      isInvoice = prefs.getBool('isInvoice') ?? false;
    });
  }

  Future<void> _saveInvoiceSetting(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isInvoice', value);
  }

  Future<void> _saveReceiptSetting(bool value) async{
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isReceipt', value);
  }

  //get submitted receipts
  Future<void> fetchTaxPayerDetails() async {
    List<Map<String, dynamic>> data = await dbHelper.getTaxPayerDetails();
    setState(() {
      taxPayerDetails = data;
      isLoading = false;
    });
  }

  void toggleSelection(int payerId) {
    setState(() {
      if (selectedReceipt.contains(payerId)) {
        selectedReceipt.remove(payerId);
      } else {
        selectedReceipt.add(payerId);
      }
    });
  }

  //get logo file
  Future<File> getLogoFile()async{
    final appDir = await getApplicationDocumentsDirectory();
    final logoPath = File('${appDir.path}/company_logo.png');
    return logoPath;
  }

  //File picker
  Future<void> pickAndSaveLogo() async{
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true
    );
    if(result != null && result.files.single.bytes != null){
      final file = await getLogoFile();
      await file.writeAsBytes(result.files.single.bytes!);
      print("logo saved to: ${file.path}");
    }
    loadLogoBytes();
  }

  //delete logo
  Future<void> deleteLogo() async {
    final file = await getLogoFile();
    if (await file.exists()) {
      await file.delete();
      print("🗑️ Logo deleted");
    }
    loadLogoBytes();
  }

  Future<Uint8List?> loadLogoBytes() async {
    final logoFile = await getLogoFile();
    if (await logoFile.exists()) {
      return await logoFile.readAsBytes();
    }
    return null;
  }

  TextEditingController taxPayerName = TextEditingController();
  TextEditingController taxPayerTin = TextEditingController();
  TextEditingController taxPayerVat = TextEditingController();
  TextEditingController taxPayerAddress = TextEditingController();
  TextEditingController email = TextEditingController();
  TextEditingController phoneNumber = TextEditingController();
  TextEditingController website= TextEditingController();
  TextEditingController deviceID = TextEditingController();
  TextEditingController activationKey = TextEditingController();
  TextEditingController deviceModelName = TextEditingController();
  TextEditingController deviceModelVErsion = TextEditingController();

  void clearFields(){
    taxPayerName.clear();
    taxPayerTin.clear();
    taxPayerVat.clear();
    taxPayerAddress.clear();
    email.clear();
    phoneNumber.clear();
    website.clear();
    deviceID.clear();
    activationKey.clear();
    deviceModelName.clear();
    deviceModelVErsion.clear();
  }


  showUpdatePrompt(){
    final TextEditingController updateTaxPayerName = TextEditingController();
    final TextEditingController updateTaxPayerTin = TextEditingController();
    final TextEditingController updateTaxPayerVat = TextEditingController();
    final TextEditingController updateTaxPayerAddress = TextEditingController();
    final TextEditingController updateEmail = TextEditingController();
    final TextEditingController updatePhonenumber = TextEditingController();
    final TextEditingController updateWebsite = TextEditingController();
    final TextEditingController updateDeviceId = TextEditingController();
    final TextEditingController updateActivationkey = TextEditingController();
    final TextEditingController updateModelname = TextEditingController();
    final TextEditingController updateVersion = TextEditingController();

    int taxPayerID = taxPayerDetails[0]['taxPayerId'];
  
    updateTaxPayerName.text = taxPayerDetails.isNotEmpty ? taxPayerDetails[0]['taxPayerName'].toString() : '';
    updateTaxPayerTin.text = taxPayerDetails.isNotEmpty ? taxPayerDetails[0]['taxPayerTin'].toString() : '';
    updateTaxPayerVat.text = taxPayerDetails.isNotEmpty ? taxPayerDetails[0]['taxPayerVatNumber'].toString() : '';
    updateTaxPayerAddress.text = taxPayerDetails.isNotEmpty ? taxPayerDetails[0]['taxPayerAddress'].toString() : '';
    updateEmail.text = taxPayerDetails.isNotEmpty ? taxPayerDetails[0]['taxPayerEmail'].toString() : '';
    updatePhonenumber.text = taxPayerDetails.isNotEmpty ? taxPayerDetails[0]['taxPayerPhone'].toString() : '';
    updateWebsite.text = taxPayerDetails.isNotEmpty ? taxPayerDetails[0]['taxPayerWebsite'].toString() : '';
    updateDeviceId.text = taxPayerDetails.isNotEmpty ? taxPayerDetails[0]['deviceID'].toString() : '';
    updateActivationkey.text = taxPayerDetails.isNotEmpty ? taxPayerDetails[0]['activationKey'].toString() : '';
    updateModelname.text = taxPayerDetails.isNotEmpty ? taxPayerDetails[0]['deviceModelName'].toString() : '';
    updateVersion.text = taxPayerDetails.isNotEmpty ? taxPayerDetails[0]['deviceModelVersion'].toString() : '';


    return showDialog(
    barrierDismissible: false,
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: SizedBox(
            width: 1000,
            height: 800,
            child: Form(
              key: saveCompanyDetailsKey,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Center(
                      child: Container(
                        height: 5,
                        width: 100,
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(20), 
                        ),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: TextFormField(
                          controller: updateTaxPayerName  ,
                          decoration: InputDecoration(
                              labelText: 'Trade Name',
                              labelStyle: TextStyle(color:Colors.grey.shade600 ),
                              filled: true,
                              fillColor: Colors.grey.shade300,
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12.0),
                                  borderSide: BorderSide.none
                              )
                          ),
                          style: const TextStyle(color: Colors.black),
                          validator: (value){
                            if(value!.isEmpty){
                              return "required";
                            }return null;
                          },
                                                ),
                        ),
                      // Password Field
                        const SizedBox(width: 10,),
                        Expanded(
                          child: TextFormField(
                            controller: updateTaxPayerTin,
                            decoration: InputDecoration(
                              labelText: 'TIN Number',
                              labelStyle:  TextStyle(color: Colors.grey.shade600),
                              filled: true,
                              fillColor: Colors.grey.shade300,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12.0),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            style: const TextStyle(color: Colors.black),
                            validator: (value){
                            if(value!.isEmpty){
                              return "required";
                            }return null;
                          },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: TextFormField(
                          controller: updateTaxPayerVat,
                          decoration: InputDecoration(
                            labelText: 'VAT Number',
                            labelStyle:  TextStyle(color: Colors.grey.shade600),
                            filled: true,
                            fillColor: Colors.grey.shade300,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12.0),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          style: const TextStyle(color: Colors.black),
                          validator: (value){
                            if(value!.isEmpty){
                              return "required";
                            }return null;
                          },
                                                ),
                        ),
                        const SizedBox(width: 10,),
                        Expanded(
                          child: TextFormField(
                            controller:updateTaxPayerAddress,
                            decoration: InputDecoration(
                              labelText: 'Full Address',
                              labelStyle:  TextStyle(color: Colors.grey.shade600),
                              filled: true,
                              fillColor: Colors.grey.shade300,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12.0),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            style: const TextStyle(color: Colors.black),
                            validator: (value){
                            if(value!.isEmpty){
                              return "required";
                            }return null;
                          },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: TextFormField(
                          controller: updateEmail,
                          decoration: InputDecoration(
                            labelText: 'Email Address',
                            labelStyle:  TextStyle(color: Colors.grey.shade600),
                            filled: true,
                            fillColor: Colors.grey.shade300,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12.0),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          style: const TextStyle(color: Colors.black),
                          validator: (value){
                            if(value!.isEmpty){
                              return "Required";
                            }return null;
                          },
                                                ),
                        ),
                        const SizedBox(width: 10,),
                        Expanded(
                          child: TextFormField(
                            controller: updatePhonenumber,
                            decoration: InputDecoration(
                              labelText: 'Phone Number',
                              labelStyle:  TextStyle(color: Colors.grey.shade600),
                              filled: true,
                              fillColor: Colors.grey.shade300,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12.0),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            style: const TextStyle(color: Colors.black),
                            validator: (value){
                            if(value!.isEmpty){
                              return "required";
                            }return null;
                          },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: TextFormField(
                          controller:updateWebsite,
                          decoration: InputDecoration(
                            labelText: 'Website',
                            labelStyle:  TextStyle(color: Colors.grey.shade600),
                            filled: true,
                            fillColor: Colors.grey.shade300,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12.0),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          style: const TextStyle(color: Colors.black),
                                                ),
                        ),
                        const SizedBox(width: 10,),
                        Expanded(
                          child: TextFormField(
                            controller: updateDeviceId,
                            decoration: InputDecoration(
                              labelText: 'ZIMRA Device ID',
                              labelStyle:  TextStyle(color: Colors.grey.shade600),
                              filled: true,
                              fillColor: Colors.grey.shade300,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12.0),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            style: const TextStyle(color: Colors.black),
                            validator: (value){
                              if(value!.isEmpty){
                                return "Required";
                              }return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller:updateActivationkey,
                            decoration: InputDecoration(
                              labelText: 'Activation Key',
                              labelStyle:  TextStyle(color: Colors.grey.shade600),
                              filled: true,
                              fillColor: Colors.grey.shade300,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12.0),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            style: const TextStyle(color: Colors.black),
                            
                          ),
                        ),
                        const SizedBox(width: 10,),
                        Expanded(
                          child: TextFormField(
                            controller: updateModelname,
                            decoration: InputDecoration(
                              labelText: 'Device Model Name',
                              labelStyle:  TextStyle(color: Colors.grey.shade600),
                              filled: true,
                              fillColor: Colors.grey.shade300,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12.0),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            style: const TextStyle(color: Colors.black),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10,),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: updateVersion,
                            decoration: InputDecoration(
                              labelText: 'Device Model Version',
                              labelStyle:  TextStyle(color: Colors.grey.shade600),
                              filled: true,
                              fillColor: Colors.grey.shade300,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12.0),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            style: const TextStyle(color: Colors.black),
                          ),
                        ),
                        const SizedBox(width: 10,),
                      ],
                    ),
                      const SizedBox(height: 10,),
                      // Signup Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () async {
                            if (saveCompanyDetailsKey.currentState!.validate()) {
                              try {
                                await dbHelper.updateTaxpayer(taxPayerID ,updateTaxPayerName.text , updateTaxPayerTin.text , updateTaxPayerVat.text , updateTaxPayerAddress.text , updateEmail.text,
                                updatePhonenumber.text , updateWebsite.text , updateDeviceId.text , updateActivationkey.text , updateModelname.text , updateVersion.text);
                                // Navigate to the HomePage after successful product addition
                                clearFields();
                                Navigator.pop(context);
                                 Get.snackbar(
                                  "Success",
                                  "Details updated successfully",
                                  icon:const Icon(Icons.check),
                                  colorText: Colors.white,
                                  backgroundColor: Colors.green,
                                  snackPosition: SnackPosition.TOP
                                );
                                fetchTaxPayerDetails();
                                } catch (e) {
                                  Get.snackbar(
                                    "Error",
                                    "Error adding details: $e",
                                    icon:const Icon(Icons.error),
                                    colorText: Colors.white,
                                    backgroundColor: Colors.red,
                                    snackPosition: SnackPosition.TOP
                                  );
                                }
                            }
//25792
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            padding:const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.0),
                            ),
                          ),
                          child: const Text(
                            'Save Company Details',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ),
                      
                      ),const SizedBox(height: 10,),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: (){
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            padding:const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.0),
                            ),
                          ),
                          child: const Text(
                            "Close Form",
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                          )
                        ),
                      ),
                      const SizedBox(height: 20,)  
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
  //show create dialog
   showAddDialog(){
   return showDialog(
    barrierDismissible: false,
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: SizedBox(
            width: 1000,
            height: 800,
            child: Form(
              key: saveCompanyDetailsKey,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Center(
                      child: Container(
                        height: 5,
                        width: 100,
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(20), 
                        ),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: TextFormField(
                          controller: taxPayerName,
                          decoration: InputDecoration(
                              labelText: 'Trade Name',
                              labelStyle: TextStyle(color:Colors.grey.shade600 ),
                              filled: true,
                              fillColor: Colors.grey.shade300,
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12.0),
                                  borderSide: BorderSide.none
                              )
                          ),
                          style: const TextStyle(color: Colors.black),
                          validator: (value){
                            if(value!.isEmpty){
                              return "required";
                            }return null;
                          },
                                                ),
                        ),
                      // Password Field
                        const SizedBox(width: 10,),
                        Expanded(
                          child: TextFormField(
                            controller: taxPayerTin,
                            decoration: InputDecoration(
                              labelText: 'TIN Number',
                              labelStyle:  TextStyle(color: Colors.grey.shade600),
                              filled: true,
                              fillColor: Colors.grey.shade300,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12.0),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            style: const TextStyle(color: Colors.black),
                            validator: (value){
                            if(value!.isEmpty){
                              return "required";
                            }return null;
                          },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: TextFormField(
                          controller: taxPayerVat,
                          decoration: InputDecoration(
                            labelText: 'VAT Number',
                            labelStyle:  TextStyle(color: Colors.grey.shade600),
                            filled: true,
                            fillColor: Colors.grey.shade300,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12.0),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          style: const TextStyle(color: Colors.black),
                          validator: (value){
                            if(value!.isEmpty){
                              return "required";
                            }return null;
                          },
                                                ),
                        ),
                        const SizedBox(width: 10,),
                        Expanded(
                          child: TextFormField(
                            controller: taxPayerAddress,
                            decoration: InputDecoration(
                              labelText: 'Full Address',
                              labelStyle:  TextStyle(color: Colors.grey.shade600),
                              filled: true,
                              fillColor: Colors.grey.shade300,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12.0),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            style: const TextStyle(color: Colors.black),
                            validator: (value){
                            if(value!.isEmpty){
                              return "required";
                            }return null;
                          },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: TextFormField(
                          controller: email,
                          decoration: InputDecoration(
                            labelText: 'Email Address',
                            labelStyle:  TextStyle(color: Colors.grey.shade600),
                            filled: true,
                            fillColor: Colors.grey.shade300,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12.0),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          style: const TextStyle(color: Colors.black),
                          validator: (value){
                            if(value!.isEmpty){
                              return "Required";
                            }return null;
                          },
                                                ),
                        ),
                        const SizedBox(width: 10,),
                        Expanded(
                          child: TextFormField(
                            controller: phoneNumber,
                            decoration: InputDecoration(
                              labelText: 'Phone Number',
                              labelStyle:  TextStyle(color: Colors.grey.shade600),
                              filled: true,
                              fillColor: Colors.grey.shade300,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12.0),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            style: const TextStyle(color: Colors.black),
                            validator: (value){
                            if(value!.isEmpty){
                              return "required";
                            }return null;
                          },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: TextFormField(
                          controller:website,
                          decoration: InputDecoration(
                            labelText: 'Website',
                            labelStyle:  TextStyle(color: Colors.grey.shade600),
                            filled: true,
                            fillColor: Colors.grey.shade300,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12.0),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          style: const TextStyle(color: Colors.black),
                                                ),
                        ),
                        const SizedBox(width: 10,),
                        Expanded(
                          child: TextFormField(
                            controller: deviceID,
                            decoration: InputDecoration(
                              labelText: 'ZIMRA Device ID',
                              labelStyle:  TextStyle(color: Colors.grey.shade600),
                              filled: true,
                              fillColor: Colors.grey.shade300,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12.0),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            style: const TextStyle(color: Colors.black),
                            validator: (value){
                              if(value!.isEmpty){
                                return "Required";
                              }return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller:activationKey,
                            decoration: InputDecoration(
                              labelText: 'Activation Key',
                              labelStyle:  TextStyle(color: Colors.grey.shade600),
                              filled: true,
                              fillColor: Colors.grey.shade300,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12.0),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            style: const TextStyle(color: Colors.black),
                            
                          ),
                        ),
                        const SizedBox(width: 10,),
                        Expanded(
                          child: TextFormField(
                            controller: deviceModelName,
                            decoration: InputDecoration(
                              labelText: 'Device Model Name',
                              labelStyle:  TextStyle(color: Colors.grey.shade600),
                              filled: true,
                              fillColor: Colors.grey.shade300,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12.0),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            style: const TextStyle(color: Colors.black),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10,),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: deviceModelVErsion,
                            decoration: InputDecoration(
                              labelText: 'Device Model Version',
                              labelStyle:  TextStyle(color: Colors.grey.shade600),
                              filled: true,
                              fillColor: Colors.grey.shade300,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12.0),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            style: const TextStyle(color: Colors.black),
                          ),
                        ),
                        const SizedBox(width: 10,),
                      ],
                    ),
                      const SizedBox(height: 10,),
                      // Signup Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () async {
                            if (saveCompanyDetailsKey.currentState!.validate()) {
                              try {
                                await dbHelper.addtaxPayerDetails(TaxPayerDetails(
                                  taxPayerName: taxPayerName.text.toUpperCase(),
                                  taxPayerTin: taxPayerTin.text,
                                  taxPayerVat: taxPayerVat.text,
                                  taxPayerAddress: taxPayerAddress.text.toUpperCase(),
                                  email: email.text, 
                                  phoneNumber: phoneNumber.text, 
                                  deviceId: deviceID.text,
                                  deviceModelName: deviceModelName.text,
                                  deviceModelVersion: deviceModelVErsion.text
                                ));
                                // Navigate to the HomePage after successful product addition
                                clearFields();
                                Navigator.pop(context);
                                 Get.snackbar(
                                  "Success",
                                  "Details added successfully",
                                  icon:const Icon(Icons.check),
                                  colorText: Colors.white,
                                  backgroundColor: Colors.green,
                                  snackPosition: SnackPosition.TOP
                                );
                                fetchTaxPayerDetails();
                                } catch (e) {
                                  Get.snackbar(
                                    "Error",
                                    "Error adding details: $e",
                                    icon:const Icon(Icons.error),
                                    colorText: Colors.white,
                                    backgroundColor: Colors.red,
                                    snackPosition: SnackPosition.TOP
                                  );
                                }
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            padding:const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.0),
                            ),
                          ),
                          child: const Text(
                            'Save Company Details',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ),
                      
                      ),const SizedBox(height: 10,),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: (){
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            padding:const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.0),
                            ),
                          ),
                          child: const Text(
                            "Close Form",
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                          )
                        ),
                      ),
                      const SizedBox(height: 20,)  
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );

  }

  Future<void> saveSelectedPrinter(String printerName) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('preferred_printer', printerName);
    setState(() {
      selectedPrinter  = printerName;
    });
  }

  Future<String?> getSelectedPrinter() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('preferred_printer');
  }

  Future<void> clearSelectedPrinter() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('preferred_printer');
    setState(() {
      selectedPrinter = "No printer selected";
    });
  }

  String? selectedPrinter;
  Future<void> showSelectedPrinter() async{
    final selectedPrinter1 = await getSelectedPrinter();
    setState(() {
      selectedPrinter = selectedPrinter1;
    });
  }

  Future<void> showPrinterSelectionDialog(BuildContext context) async {
  final printers = await Printing.listPrinters();

  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text("Select a printer"),
        content: SizedBox(
          width: 300,
          height: 300,
          child: ListView.builder(
            itemCount: printers.length,
            itemBuilder: (context, index) {
              final printer = printers[index];
              return ListTile(
                title: Text(printer.name),
                onTap: () async {
                  await saveSelectedPrinter(printer.name);
                  Navigator.of(context).pop();
                  Get.snackbar("Printer Settings",
                  "${printer.name} saved as the default printer",
                  backgroundColor: Colors.green,
                  colorText: Colors.white,
                  icon: const Icon(Icons.message , color: Colors.white,)
                  );
                },
              );
            },
          ),
        ),
      );
    },
  );
}

  


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            Align(
              alignment: Alignment.topLeft,
              child: IconButton(
                icon: const Icon(Icons.arrow_circle_left_outlined, size: 40,),
                onPressed: () {
                  Navigator.pushReplacement(context, MaterialPageRoute(builder: (context)=> MyHomePage()));
                },
              ),
            ),
            const Text('Company Details Page'),
            const SizedBox(height: 20,),
            Container(
                width: 1200,
                height: 150,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      blurRadius: 10,
                      spreadRadius: 4,
                      offset: Offset(0, 6),
                      color: Colors.black.withOpacity(0.3),
                    )
                  ]
                ),
                child: isLoading
                ? const Center(child: CircularProgressIndicator(),)
                : Padding(
                    padding: const EdgeInsets.all(5.0),
                    child: Column(
                      children: [
                        const SizedBox(height: 10),
                        Expanded(
                          child: Scrollbar(
                            thumbVisibility: true,
                            controller: _verticalScroll,
                            child: SingleChildScrollView(
                              controller: _verticalScroll,
                              scrollDirection: Axis.vertical,
                              child: Scrollbar(
                                thumbVisibility: true,
                                controller: _horizontalScroll,
                                notificationPredicate: (notif) => notif.depth == 1,
                                child: SingleChildScrollView(
                                  controller: _horizontalScroll,
                                  scrollDirection: Axis.horizontal,
                                  child: ConstrainedBox(
                                    constraints: BoxConstraints(minWidth: MediaQuery.of(context).size.width),
                                    child: ConstrainedBox(
                                      constraints: const BoxConstraints(
                                        minWidth: 900, // Force overflow
                                      ),
                                      child: DataTable(
                                        headingTextStyle: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        headingRowColor: MaterialStateProperty.all(Colors.blue),
                                        columns: const [
                                          DataColumn(label: Text('TradeName')),
                                          DataColumn(label: Text('TIN Number')),
                                          DataColumn(label: Text('VAT Number')),
                                          DataColumn(label: Text('Address')),
                                          DataColumn(label: Text('Email')),
                                          DataColumn(label: Text('Phone Number')),
                                          DataColumn(label: Text('Website')),
                                          DataColumn(label: Text('Device Id')),
                                          DataColumn(label: Text('Activation Key')),
                                          DataColumn(label: Text('Device Model Name')),
                                          DataColumn(label: Text('Model Version')),
                                          DataColumn(label:Text("Actions"))
                                        ],
                                        rows: taxPayerDetails.map((sales) {
                                          return DataRow(
                                            selected: selectedReceipt.contains(sales['taxPayerId']),
                                            onSelectChanged: (selected) {
                                              toggleSelection(sales['taxPayerId']);
                                            },
                                            cells: [
                                              DataCell(Text(sales['taxPayerName'].toString())),
                                              DataCell(Text(sales['taxPayerTin'].toString())),
                                              DataCell(Text(sales['taxPayerVatNumber'].toString())),
                                              DataCell(Text(sales['taxPayerAddress'].toString())),
                                              DataCell(Text(sales['taxPayerEmail'].toString())),
                                              DataCell(Text(sales['taxPayerPhone'].toString())),
                                              DataCell(Text(sales['taxPayerWebsite'].toString())),
                                              DataCell(Text(sales['deviceID'].toString())),
                                              DataCell(Text(sales['activationKey'].toString())),
                                              DataCell(Text(sales['deviceModelName'].toString())),
                                              DataCell(Text(sales['deviceModelVersion'].toString())),
                                              DataCell(
                                                Row(
                                                  children: [
                                                    IconButton(
                                                      icon: const Icon(Icons.edit, color: Colors.blue),
                                                      onPressed: () {
                                                        showUpdatePrompt();
                                                      },
                                                    ),
                                                    IconButton(
                                                      icon: const Icon(Icons.credit_card_outlined, color: Colors.blue),
                                                      onPressed: () {
                                                        
                                                      },
                                                    ),
                                                    IconButton(
                                                      icon: const Icon(Icons.delete, color: Colors.red),
                                                      onPressed: () async {
                                                        
                                                      },
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          );
                                        }).toList(),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
              ),

              const SizedBox(height: 20,),
              taxPayerDetails.isEmpty ?
              CustomOutlineBtn(
                height: 45,
                width: 300,
                text: "Create",
                color: Colors.green,
                color2: Colors.green,
                icon:const Icon(Icons.add, color: Colors.white,),
                onTap: () {
                  showAddDialog();
                },
              )
              :const SizedBox(height: 2,),
              const SizedBox(height: 30,),
              Container(
                height: 400,
                width: 1200,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10.0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      offset: Offset(0, 6),
                      spreadRadius: 4,
                      blurRadius: 6
                    )
                  ]
                ),
                child: Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        width: 550,
                        height: 350,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(10)
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                              Padding(
                                padding: const EdgeInsets.all(30.0),
                                child: CustomOutlineBtn(
                                  text: "Select Printer",
                                  height: 45,
                                  width: 600,
                                  color: Colors.green,
                                  color2: Colors.green,
                                  icon: const Icon(Icons.print_rounded, color: Colors.white,),
                                  onTap: (){
                                    showPrinterSelectionDialog(context);
                                  },
                                ),
                              ),
                              const SizedBox(height: 5,),
                              const Text("Printer name", style: TextStyle(fontSize: 14 , color: Colors.black),),
                              Container(
                                height: 45,
                                width: 480,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(10.0),
                                  boxShadow: [
                                    BoxShadow(
                                      offset: const Offset(0, 6),
                                      color: Colors.black.withOpacity(0.3),
                                      blurRadius: 10,
                                      spreadRadius: 4
                                    )
                                  ]
                                ),
                                child: Center(
                                  child: Text("${selectedPrinter}" , style: TextStyle(fontWeight: FontWeight.w600),),
                                ),
                              ),
                              const SizedBox(height: 5,),
                              Padding(
                                padding: const EdgeInsets.all(30.0),
                                child: CustomOutlineBtn(
                                  text: "Clear Printer Name",
                                  height: 45,
                                  width: 600,
                                  color: Colors.green,
                                  color2: Colors.green,
                                  icon: const Icon(Icons.print_rounded, color: Colors.white,),
                                  onTap: (){
                                    clearSelectedPrinter();
                                  },
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 30),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.start,
                                      children: [
                                        const Text("Use invoices" , style: TextStyle(fontSize: 14, color: Colors.black),),
                                        const SizedBox(width: 10,),
                                        Switch(
                                          activeColor: Colors.blue,
                                          value: isInvoice,
                                          onChanged: (value){
                                            setState(() {
                                              isInvoice = value;
                                              isReceipt = false;
                                              _saveReceiptSetting(false);
                                            });
                                            _saveInvoiceSetting(value);
                                          }
                                        ),
                                      ],
                                    ),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.start,
                                      children: [
                                        const Text("Use receipts" , style: TextStyle(fontSize: 14  , color: Colors.black),),
                                        const SizedBox(width: 10,),
                                        Switch(
                                          activeColor: Colors.blue,
                                          value: isReceipt,
                                          onChanged: (value){
                                            setState(() {
                                              isReceipt = value;
                                              isInvoice = false;
                                              _saveInvoiceSetting(false);
                                            });
                                            _saveReceiptSetting(value);
                                          }
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),  
                              
                          ],
                        ),
                      ),
                      Container(
                        width: 550,
                        height: 350,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10.0),
                          color: Colors.grey.shade200
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            const SizedBox(
                              height: 20,
                            ),
                            Container(
                              height: 200,
                              width: 200,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10.0),
                                border: Border.all(color: Colors.green , width: 1)
                              ),
                              child: FutureBuilder(
                                future: loadLogoBytes(),
                                builder: (context , snapshot){
                                  if(snapshot.hasData){
                                    return Image.memory(snapshot.data!, width: 100,);
                                  }else{
                                    return Center(child: Text("No logo uploaded"));
                                  }
                                }),
                            ),
                            const SizedBox(height: 5,),
                            CustomOutlineBtn(
                              text: "Pick Logo",
                              height: 40,
                              width: 200,
                              color: Colors.green,
                              color2: Colors.green,
                              icon: const Icon(Icons.image, color: Colors.white,),
                              onTap: ()async{
                                await pickAndSaveLogo();
                                Navigator.pushReplacement(
                                  context,
                                  PageRouteBuilder(
                                    pageBuilder: (_, __, ___) => const CompanydetailsPage(),
                                    transitionDuration: Duration.zero,
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 10,),
                            CustomOutlineBtn(
                              text: "Remove Logo",
                              height: 40,
                              width: 200,
                              color: Colors.redAccent,
                              color2: Colors.red,
                              icon: const Icon(Icons.delete, color: Colors.white,),
                              onTap: ()async{
                                await deleteLogo();
                                Navigator.pushReplacement(
                                  context,
                                  PageRouteBuilder(
                                    pageBuilder: (_, __, ___) => const CompanydetailsPage(),
                                    transitionDuration: Duration.zero,
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      )
                    ],
                  ),
                ),
              )  ,
              
          ],
        ),
      ),
    );
  }
}