import 'package:fdmsgateway/common/button.dart';
import 'package:fdmsgateway/database.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';


class OpenDayPage extends StatefulWidget {
  const OpenDayPage({super.key});

  @override
  State<OpenDayPage> createState() => _openDayState();
}

class _openDayState extends State<OpenDayPage> {
  bool isLoading = true;
  final DatabaseHelper dbHelper = DatabaseHelper();
  List<Map<String, dynamic>> fiscalDays = [];
  final ScrollController _verticalScroll = ScrollController();
  final ScrollController _horizontalScroll = ScrollController();
  List<int> selectedDay = [];
  final saveCompanyDetailsKey = GlobalKey<FormState>();
  TextEditingController fiscalDay = TextEditingController();
  TextEditingController status = TextEditingController();
  TextEditingController opened = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchFiscalDays();
  }

  void clearFields(){
    fiscalDay.clear();
    status.clear();
    opened.clear();
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
                          controller: fiscalDay,
                          decoration: InputDecoration(
                              labelText: 'Fiscal Day',
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
                            controller: status,
                            decoration: InputDecoration(
                              labelText: 'Status',
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
                          controller: opened,
                          decoration: InputDecoration(
                            labelText: 'Opened',
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
                        
                      ],
                    ),
                    const SizedBox(height: 10),
                      // Signup Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () async {
                            if (saveCompanyDetailsKey.currentState!.validate()) {
                              try {
                                await dbHelper.manualinsertOpenDay(
                                  int.tryParse(fiscalDay.text)! , status.text , opened.text
                                );
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
                                fetchFiscalDays();
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
                            'Save Details',
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

  Future<void> fetchFiscalDays() async {
    List<Map<String, dynamic>> data = await dbHelper.getOpenDay();
    setState(() {
      fiscalDays = data;
      isLoading = false;
    });
  }

    void toggleSelection(int dayId) {
    setState(() {
      if (selectedDay.contains(dayId)) {
        selectedDay.remove(dayId);
      } else {
        selectedDay.add(dayId);
      }
    });
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
                  icon:const Icon(Icons.arrow_circle_left_outlined),
                  onPressed:() {
                    Navigator.pop(context);
                  },
                ),
              ),
            const SizedBox(height: 20,),
            Container(
              width: 1200,
              height: 550,
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
                      Text("Fiscal Days", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black),),
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
                                              DataColumn(label: Text("Fiscla Day")),
                                              DataColumn(label: Text("1st Receipt Status")),
                                              DataColumn(label: Text("Opened")),
                                              DataColumn(label: Text("Closed")),
                                              DataColumn(label: Text("TaxExempt")),
                                              DataColumn(label: Text("TaxZero")),
                                              DataColumn(label: Text("Tax15")),
                                              DataColumn(label: Text("TaxWT")),
                                              //DataColumn(label: Text("Actions")),
                                            ],
                                            rows: fiscalDays.map((sales) {
                                              return DataRow(
                                                selected: selectedDay.contains(sales['FiscalDayNo']),
                                                onSelectChanged: (selected) {
                                                  toggleSelection(sales['FiscalDayNo']);
                                                },
                                                cells: [
                                                  DataCell(Text(sales['FiscalDayNo'].toString())),
                                                  DataCell(Text(sales['StatusOfFirstReceipt'].toString())),
                                                  DataCell(Text(sales['FiscalDayOpened'].toString())),
                                                  DataCell(Text(sales['FiscalDayClosed'].toString())),
                                                  DataCell(Text(sales['TaxExempt'].toString())),
                                                  DataCell(Text(sales['TaxZero'].toString())),
                                                  DataCell(Text(sales['Tax15'].toString())),
                                                  DataCell(Text(sales['TaxWT'].toString())),
                                                ],
                                              );
                                            }).toList(),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                        CustomOutlineBtn(
                          text: "Add day field",
                          color: Colors.green,
                          icon: const Icon(Icons.add, color: Colors.white,),
                          onTap: (){
                            showAddDialog();
                          },
                          color2: Colors.green,
                          width: 300,
                          height: 50,
                        ),
                    ],
                  ),
                )
            ),
            
          ],
        ),
    );
  }
}