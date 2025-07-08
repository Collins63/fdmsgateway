import 'package:fdmsgateway/database.dart';
import 'package:flutter/material.dart';

class FiscalreportsPage extends StatefulWidget {
  const FiscalreportsPage({super.key});

  @override
  State<FiscalreportsPage> createState() => _FiscalreportsPageState();
}

class _FiscalreportsPageState extends State<FiscalreportsPage> {

  DateTime? _startDate;
  DateTime? _endDate;
  String? selectedCurrency;
  List<String> currencies = ['ZWG' , 'USD' , 'ZAR'];
  double? periodTotal;
  double? periodTaxTotal;
  double? periodTotal15;
  double? periodTotalZero;
  double? periodTotalNonVAT;
  DatabaseHelper dbHelper = DatabaseHelper();

  Future<void> selectedStartDate(BuildContext context) async{
    final DateTime? picked = await showDatePicker(
      context: context,
      firstDate: DateTime(2024),
      lastDate: DateTime(2100)
    );
    if(picked != null){
      setState(() {
        _startDate = picked;
      });
      await updateTaxTotal();
      await updateTotalNonVATSales();
      await updateTotalVATSales();
      await updateTotalZeroVATSales();
    }
  }

  Future<void> selectEndDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: _startDate ?? DateTime(2024),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _endDate = picked;
      });
      await updateTaxTotal();
    }
  }

  
  Future<void> updateTotalVATSales() async {
    if (_startDate != null && _endDate != null && selectedCurrency != null) {
      final total = await dbHelper.getTotal15WithinDateRange(
        currency: selectedCurrency!,
        startDate: _startDate!.toIso8601String(),
        endDate: _endDate!
            .add(const Duration(hours: 23, minutes: 59, seconds: 59))
            .toIso8601String(),
      );
      setState(() {
        periodTotal15 = total;
      });
    }
  }

  Future<void> updateTotalNonVATSales() async {
    if (_startDate != null && _endDate != null && selectedCurrency != null) {
      final total = await dbHelper.getTotalNonVatWithinDateRange(
        currency: selectedCurrency!,
        startDate: _startDate!.toIso8601String(),
        endDate: _endDate!
            .add(const Duration(hours: 23, minutes: 59, seconds: 59))
            .toIso8601String(),
      );
      setState(() {
        periodTotalNonVAT = total;
      });
    }
  }

  Future<void> updateTotalZeroVATSales() async {
    if (_startDate != null && _endDate != null && selectedCurrency != null) {
      final total = await dbHelper.getTotalNonVatWithinDateRange(
        currency: selectedCurrency!,
        startDate: _startDate!.toIso8601String(),
        endDate: _endDate!
            .add(const Duration(hours: 23, minutes: 59, seconds: 59))
            .toIso8601String(),
      );
      setState(() {
        periodTotalZero = total;
      });
    }
  }

  Future<void> updateTaxTotal() async {
    if (_startDate != null && _endDate != null && selectedCurrency != null) {
      final total = await dbHelper.getTotalTaxWithinDateRange(
        currency: selectedCurrency!,
        startDate: _startDate!.toIso8601String(),
        endDate: _endDate!
            .add(const Duration(hours: 23, minutes: 59, seconds: 59))
            .toIso8601String(),
      );
      setState(() {
        periodTaxTotal = total;
      });
    }
  }


  // Future<List<String>> fetchCurrencies() async{
  //   final List<Map<String, dynamic>> currencies = await dbHelper.getAllCurrencies();
  //   print(currencies);
  //   return currencies.map((row) => row['currency'] as String).toList();
  // }

  //   Future<void> loadCurrencies()async{
  //   final results = await fetchCurrencies();
  //   setState(() {
  //     currencies = results;
  //   });
  // }


  @override
  void initState(){
    
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children:<Widget> [
          Align(
            alignment: Alignment.topLeft,
            child: IconButton(
              icon: const Icon(Icons.arrow_circle_left_outlined, size: 40,),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ),
          const Text('Fiscal Tax Reports', style: TextStyle(fontWeight: FontWeight.w600 , fontSize: 18),),
          Container(
            width: 250,
            height: 5,
            decoration: BoxDecoration(
              color:Colors.green,
              borderRadius: BorderRadius.circular(10.0)
            ),
          ),
          const SizedBox(height: 20,),
          Container(
            height: 150,
            width: 1000,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  offset: const Offset(0, 6),
                  blurRadius: 5,
                  spreadRadius: 2
                )
              ]
            ),
            child: Column(
              children: [
                const SizedBox(height:20,),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        ElevatedButton(
                          onPressed: ()=> selectedStartDate(context),
                          child: const Text("Selcted Start Date")
                        ),
                        Text(_startDate != null
                          ? _startDate!.toLocal().toString().split('T').first
                          : "No Date"
                        )
                      ],
                    ),
                            Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                ElevatedButton(
                              onPressed: () => selectEndDate(context),
                              child: Text("Select End Date"),
                            ),
                            Text(_endDate != null
                                ? _endDate!.toLocal().toString().split('T').first
                                : "No date"
                            ),
                              ],
                            )
                            
                          ],
                        ),
                Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: DropdownButton<String>(
                        menuWidth: 200,
                        hint: Text("Select Currency"),
                        value: selectedCurrency,
                        onChanged: (value) async{
                          setState(() {
                            selectedCurrency = value;
                          });
                          await updateTaxTotal();
                        },
                        items: currencies.map((currency) {
                          return DropdownMenuItem<String>(
                            value: currency,
                            child: Text(currency),
                          );
                        }).toList(),
                      ),
                    ),
              ],
            ),
          ),
          
          const SizedBox(height: 20,),
          Container(
            height: 400,
            width: 1000,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10.0),
              boxShadow: [
                BoxShadow(
                  blurRadius: 5,
                  spreadRadius: 2,
                  color: Colors.black.withOpacity(0.3),
                  offset: const Offset(0, 6),
                )
              ]
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 480,
                    height: 350,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(10.0)
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(18),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                width:200,
                                height:150,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(10.0)
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 20,),
                                    const Text("Total Tax Returns" , style: TextStyle(fontWeight: FontWeight.w600),),
                                    const SizedBox(height: 10,),
                                    Icon(
                                      Icons.attach_money_rounded, size: 40,
                                    ),
                                    const SizedBox(height: 10,),
                                    Text("\$${periodTaxTotal?.toStringAsFixed(2)}" , style: TextStyle(fontWeight: FontWeight.w600, color: Colors.green),),
                                  ],
                                ),
                              ),
                              Container(
                                width:200,
                                height:150,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(10.0)
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 20,),
                                    const Text("Total 15% VAT" , style: TextStyle(fontWeight: FontWeight.w600),),
                                    const SizedBox(height: 10,),
                                    Icon(
                                      Icons.attach_money_rounded, size: 40,
                                    ),
                                    const SizedBox(height: 10,),
                                    Text("\$${periodTotal15?.toStringAsFixed(2)}" , style: TextStyle(fontWeight: FontWeight.w600, color: Colors.green),),
                                  ],
                                ),
                              )
                            ],
                          ),
                          const SizedBox(height: 10,),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                width:200,
                                height:150,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(10.0)
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 20,),
                                    const Text("Total Zero VAT" , style: TextStyle(fontWeight: FontWeight.w600),),
                                    const SizedBox(height: 10,),
                                    Icon(
                                      Icons.attach_money_rounded, size: 40,
                                    ),
                                    const SizedBox(height: 10,),
                                    Text("\$${periodTotalZero?.toStringAsFixed(2)}" , style: TextStyle(fontWeight: FontWeight.w600, color: Colors.green),),
                                  ],
                                ),
                              ),
                              Container(
                                width:200,
                                height:150,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(10.0)
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 20,),
                                    const Text("Total Tax Exempt" , style: TextStyle(fontWeight: FontWeight.w600),),
                                    const SizedBox(height: 10,),
                                    Icon(
                                      Icons.attach_money_rounded, size: 40,
                                    ),
                                    const SizedBox(height: 10,),
                                    Text("\$${periodTotalNonVAT?.toStringAsFixed(2)}" , style: TextStyle(fontWeight: FontWeight.w600, color: Colors.green),),
                                  ],
                                ),
                              )
                            ],
                          )
                        ],
                      ),
                    ),
                  ),
                  Container(
                    width: 480,
                    height: 350,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(10.0)
                    ),
                  )
                ],
              ),
            ),
          )

        ],
      ),
    );
  }
}