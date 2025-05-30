import 'package:flutter/material.dart';
import '../../../database/estimate_database.dart';
import '../models/woodwork_estimate.dart';
import 'woodwork_estimate_detail_page.dart';

class WoodworkEstimateListPage extends StatefulWidget {
  const WoodworkEstimateListPage({super.key});

  @override
  _WoodworkEstimateListPageState createState() =>
      _WoodworkEstimateListPageState();
}

class _WoodworkEstimateListPageState extends State<WoodworkEstimateListPage> {
  late Future<List<WoodworkEstimate>> _estimatesFuture;

  @override
  void initState() {
    super.initState();
    _loadEstimates();
  }

  Future<void> _loadEstimates() async {
    try {
      // Directly fetch the estimates using your API call
      _estimatesFuture = EstimateDatabase
          .getEstimates(); // Use the API method directly to fetch estimates

      // After assigning the future, call setState to trigger UI updates
      setState(() {});
    } catch (error) {
      print("Error loading estimates: $error");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load estimates: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0x0fffffff),
        title: const Text('Woodwork Estimates'),
        // actions: [
        //   IconButton(
        //     icon: const Icon(Icons.visibility, color: Colors.blue),
        //     onPressed: () async {
        //       try {
        //         final fullEstimate =
        //             await EstimateDatabase.getEstimateById(estimate.id!);
        //         Navigator.push(
        //           context,
        //           MaterialPageRoute(
        //             builder: (context) => WoodworkEstimateDetailPage(
        //               estimate: fullEstimate,
        //             ),
        //           ),
        //         ).then((_) {
        //           setState(() {
        //             _loadEstimates();
        //           });
        //         });
        //       } catch (error) {
        //         print('❌ Error fetching estimate: $error');
        //         ScaffoldMessenger.of(context).showSnackBar(
        //           SnackBar(
        //             content: Text('Failed to load estimate details: $error'),
        //           ),
        //         );
        //       }
        //     },
        //   ),
        // ],
      ),
      backgroundColor: Colors.white,
      body: FutureBuilder<List<WoodworkEstimate>>(
        future: _estimatesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              // child:
              //     Text('No estimates found.', style: TextStyle(fontSize: 18)),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image(
                    image: AssetImage('empty-page.png'),
                    width: 350,
                    height: 350,
                  ),
                  Text(
                    'Oops! No Estimates Found...',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        letterSpacing: 1.0),
                  )
                ],
              ),
            );
          }

          final estimates = snapshot.data!;
          print('Fetched estimates: $estimates');
          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('ID')),
                    DataColumn(label: Text('Version')),
                    DataColumn(label: Text('Customer Name')),
                    DataColumn(label: Text('Customer Email')),
                    DataColumn(label: Text('Mobile Number')),
                    DataColumn(label: Text('Stage')),
                    DataColumn(label: Text('Status')),
                    DataColumn(label: Text('Total Amount 1')),
                    DataColumn(label: Text('Total Amount 2')),
                    DataColumn(label: Text('Total Amount 3')),
                    DataColumn(label: Text('Actions')),
                  ],
                  rows: estimates.map((estimate) {
                    return DataRow(
                      cells: [
                        DataCell(Text(estimate.id.toString())),
                        DataCell(Text(estimate.version.toString())),
                        DataCell(Text(estimate.customerName.toString())),
                        DataCell(Text(estimate.customerEmail.toString())),
                        DataCell(Text(estimate.customerPhone.toString())),
                        DataCell(Text(estimate.status ?? '')),
                        DataCell(Text(estimate.stage ?? '')),
                        DataCell(Text(
                            '₹${estimate.totalAmount.toStringAsFixed(2)}')),
                        DataCell(Text(
                            '₹${estimate.totalAmount2.toStringAsFixed(2)}')),
                        DataCell(Text(
                            '₹${estimate.totalAmount3.toStringAsFixed(2)}')),
                        DataCell(
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.visibility,
                                    color: Colors.blue),
                                onPressed: () async {
                                  try {
                                    // Create an instance of EstimateDatabase
                                    final estimateDatabase = EstimateDatabase();

                                    // Now call the instance method on the object
                                    final fullEstimate = await estimateDatabase
                                        .getEstimateById(estimate.id!);

                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            WoodworkEstimateDetailPage(
                                                estimate: fullEstimate),
                                      ),
                                    ).then((_) {
                                      setState(() {
                                        _loadEstimates();
                                      });
                                    });
                                  } catch (error) {
                                    print('❌ Error fetching estimate: $error');
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                          content: Text(
                                              'Failed to load estimate details: $error')),
                                    );
                                  }
                                },
                              )
                            ],
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
