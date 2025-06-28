import 'package:fdmsgateway/database.dart';
import 'package:flutter/material.dart';


class Submittedreceipts extends StatefulWidget {

  const Submittedreceipts({super.key});

  @override
  State<Submittedreceipts> createState() => _SubmittedReceiptsState();
}

class _SubmittedReceiptsState extends State<Submittedreceipts> {
  bool isLoading = true;
  final DatabaseHelper dbHelper = DatabaseHelper();
  List<Map<String, dynamic>> submittedReceipts = [];
  final ScrollController _verticalScroll = ScrollController();
  final ScrollController _horizontalScroll = ScrollController();
  List<int> selectedReceipt = [];

  @override
  void initState() {
    super.initState();
    fetchSubmittedReceipts();
  }

  //get submitted receipts
  Future<void> fetchSubmittedReceipts() async {
    List<Map<String, dynamic>> data = await dbHelper.getSubmittedReceipts();
    setState(() {
      submittedReceipts = data;
      isLoading = false;
    });
  }

  void toggleSelection(int saleId) {
    setState(() {
      if (selectedReceipt.contains(saleId)) {
        selectedReceipt.remove(saleId);
      } else {
        selectedReceipt.add(saleId);
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
            const Text('Submitted Receipts', style: TextStyle(fontSize: 18, color: Colors.black, fontWeight: FontWeight.bold),),
            
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
                                              DataColumn(label: Text('ReceiptGlobalNo')),
                                              DataColumn(label: Text('ReceiptCounter')),
                                              DataColumn(label: Text('FiscalDayNo')),
                                              DataColumn(label: Text('InvoiceNo')),
                                              DataColumn(label: Text('ReceiptID')),
                                              DataColumn(label: Text('ReceiptType')),
                                              DataColumn(label: Text('ReceiptCurrency')),
                                              DataColumn(label: Text('MoneyType')),
                                              DataColumn(label: Text('ReceiptDate')),
                                              DataColumn(label: Text('ReceiptTime')),
                                              DataColumn(label: Text('ReceiptTotal')),
                                              DataColumn(label: Text('TaxCode')),
                                              DataColumn(label: Text('taxPercent')),
                                              DataColumn(label:Text('taxAmount')),
                                              DataColumn(label:Text('salesAmountwithTax')),
                                              DataColumn(label:Text('receiptHash')),
                                              DataColumn(label:Text('receiptJsonbody')),
                                              DataColumn(label:Text('statustoFdms')),
                                              DataColumn(label:Text('qrurl')),
                                              DataColumn(label:Text('receiptServerSignature')),
                                              DataColumn(label:Text('submitReceiptServerresponseJson')),
                                              DataColumn(label:Text('total15Vat')),
                                              DataColumn(label:Text('totalNonVat')),
                                              DataColumn(label:Text('totalExempt')),
                                              DataColumn(label:Text('totalWT')),
                                            ],
                                            rows: submittedReceipts.map((sales) {
                                              return DataRow(
                                                selected: selectedReceipt.contains(sales['receiptGlobalNo']),
                                                onSelectChanged: (selected) {
                                                  toggleSelection(sales['receiptGlobalNo']);
                                                },
                                                cells: [
                                                  DataCell(Text(sales['receiptGlobalNo'].toString())),
                                                  DataCell(Text(sales['receiptCounter'].toString())),
                                                  DataCell(Text(sales['FiscalDayNo'].toString())),
                                                  DataCell(Text(sales['InvoiceNo'].toString())),
                                                  DataCell(Text(sales['receiptID'].toString())),
                                                  DataCell(Text(sales['receiptType'].toString())),
                                                  DataCell(Text(sales['receiptCurrency'].toString())),
                                                  DataCell(Text(sales['moneyType'].toString())),
                                                  DataCell(Text(sales['receiptDate'].toString())),
                                                  DataCell(Text(sales['receiptTime'].toString())),
                                                  DataCell(Text(sales['receiptTotal'].toString())),
                                                  DataCell(Text(sales['taxCode'].toString())),
                                                  DataCell(Text(sales['taxPercent'].toString())),
                                                  DataCell(Text(sales['taxAmount'].toString())),
                                                  DataCell(Text(sales['SalesAmountwithTax'].toString())),
                                                  DataCell(Text(sales['receiptHash'].toString())),
                                                  DataCell(Text(sales['receiptJsonbody'].toString())),
                                                  DataCell(Text(sales['StatustoFDMS'].toString())),
                                                  DataCell(Text(sales['qrurl'].toString())),
                                                  DataCell(Text(sales['receiptServerSignature'].toString())),
                                                  DataCell(Text(sales['submitReceiptServerresponseJSON'].toString())),
                                                  DataCell(Text(sales['Total15VAT'].toString())),
                                                  DataCell(Text(sales['TotalNonVAT'].toString())),
                                                  DataCell(Text(sales['TotalExempt'].toString())),
                                                  DataCell(Text(sales['TotalWT'].toString())),
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