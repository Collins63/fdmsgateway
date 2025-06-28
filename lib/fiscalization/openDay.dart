import 'package:fdmsgateway/database.dart';
import 'package:flutter/material.dart';


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

  @override
  void initState() {
    super.initState();
    fetchFiscalDays();
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
                    ],
                  ),
                )
            )
          ],
        ),
    );
  }
}