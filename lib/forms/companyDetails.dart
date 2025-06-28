import 'package:fdmsgateway/common/button.dart';
import 'package:fdmsgateway/database.dart';
import 'package:fdmsgateway/models/jsonModels.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

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
  
  @override
  void initState() {
    super.initState();
    fetchTaxPayerDetails();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: <Widget>[
          Align(
            alignment: Alignment.topLeft,
            child: IconButton(
              icon: const Icon(Icons.arrow_circle_left_outlined, size: 40,),
              onPressed: () {
                Navigator.pop(context);
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
                                        child: SingleChildScrollView(
                                          controller: _horizontalScroll,
                                          scrollDirection: Axis.horizontal,
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
                                                          onPressed: () {},
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
                    ],
                  ),
                )
            ),
            SizedBox(height: 30,),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CustomOutlineBtn(
                    icon: const Icon(Icons.add, color: Colors.white,),
                    height: 40,
                    width: 250,
                    text: "Create",
                    color: Colors.green,
                    color2: Colors.green,
                    onTap: () {
                      showAddDialog();
                    },
                  ),
                  const SizedBox(width: 10,),
                  CustomOutlineBtn(
                    icon: const Icon(Icons.edit, color: Colors.white,),
                    width: 250,
                    text: "Edit",
                    color: Colors.blue,
                    color2: Colors.blue,
                    height: 40,
                    onTap: (){
              
                    },
                  ),
                  CustomOutlineBtn(
                    icon: const Icon(Icons.remove_red_eye, color: Colors.white,),
                    width: 250,
                    text: "View",
                    color: Colors.blue,
                    color2: Colors.blue,
                    height: 40,
                    onTap: (){
              
                    },
                  ),
                  CustomOutlineBtn(
                    icon: Icon(Icons.delete, color: Colors.white,),
                    width: 250,
                    text: "Delete",
                    color: Colors.red,
                    color2: Colors.red,
                    height: 40,
                    onTap: (){
              
                    },
                  )
                ],
              ),
            )
        ],
      ),
    );
  }
}