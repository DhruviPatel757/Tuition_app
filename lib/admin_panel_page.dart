import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:charts_flutter/flutter.dart' as charts;

class AdminPanelPage extends StatefulWidget {
  @override
  _AdminPanelPageState createState() => _AdminPanelPageState();
}

class _AdminPanelPageState extends State<AdminPanelPage> {
  List<Map<String, dynamic>> tasks = [];
  List<Map<String, dynamic>> users = [];
  List<Map<String, dynamic>> fees = [];
  List<charts.Series<dynamic, String>> _taskSeriesBarData = [];
  List<charts.Series<dynamic, String>> _feeSeriesBarData = [];
  List<charts.Series<dynamic, String>> _userSeriesBarData = [];
  bool _isDataLoaded = false;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      final taskResponse = await http.get(Uri.parse('http://192.168.0.16:6787/admin/tasks'));
      final userResponse = await http.get(Uri.parse('http://192.168.0.16:6787/admin/users'));
      final feeResponse = await http.get(Uri.parse('http://192.168.0.16:6787/admin/fees'));

      if (taskResponse.statusCode == 200 &&
          userResponse.statusCode == 200 &&
          feeResponse.statusCode == 200) {
        setState(() {
          tasks = List<Map<String, dynamic>>.from(jsonDecode(taskResponse.body));
          users = List<Map<String, dynamic>>.from(jsonDecode(userResponse.body));
          fees = List<Map<String, dynamic>>.from(jsonDecode(feeResponse.body));
          _isDataLoaded = true;
          _generateBarChartData();
        });
      } else {
        _showError('Error fetching data');
      }
    } catch (e) {
      _showError('An error occurred: $e');
    }
  }

  void _generateBarChartData() {
    // Clear previous data
    _taskSeriesBarData.clear();
    _feeSeriesBarData.clear();
    _userSeriesBarData.clear();

    // Generate bar chart data for tasks
    var taskData = [
      {'category': 'Completed', 'count': tasks.where((task) => task['completed'] == true).length},
      {'category': 'Pending', 'count': tasks.where((task) => task['completed'] != true).length},
    ];

    _taskSeriesBarData.add(
      charts.Series<dynamic, String>(
        id: 'Tasks',
        domainFn: (datum, index) => datum['category'] as String,
        measureFn: (datum, index) => datum['count'] as int,
        data: taskData,
        colorFn: (_, __) => charts.MaterialPalette.blue.shadeDefault,
      ),
    );

    // Generate bar chart data for fees
    var feeData = [
      {'status': 'Paid', 'count': fees.where((fee) => fee['paid'] == true).length},
      {'status': 'Unpaid', 'count': fees.where((fee) => fee['paid'] != true).length},
    ];

    _feeSeriesBarData.add(
      charts.Series<dynamic, String>(
        id: 'Fees',
        domainFn: (datum, index) => datum['status'] as String,
        measureFn: (datum, index) => datum['count'] as int,
        data: feeData,
        colorFn: (_, __) => charts.MaterialPalette.red.shadeDefault,
      ),
    );

    // Generate bar chart data for users
    var userData = [
      {'role': 'Admin', 'count': users.where((user) => user['isAdmin'] == true).length},
      {'role': 'Regular', 'count': users.where((user) => user['isAdmin'] != true).length},
    ];

    _userSeriesBarData.add(
      charts.Series<dynamic, String>(
        id: 'Users',
        domainFn: (datum, index) => datum['role'] as String,
        measureFn: (datum, index) => datum['count'] as int,
        data: userData,
        colorFn: (_, __) => charts.MaterialPalette.green.shadeDefault,
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final totalTasks = tasks.length.toString();
    final totalFees = fees.length.toString();
    final paidFees = fees.where((fee) => fee['paid'] == true).length.toString();
    final unpaidFees = fees.where((fee) => fee['paid'] == false).length.toString();

    return Scaffold(
      appBar: AppBar(
        title: Text('Admin Panel'),
        backgroundColor: Colors.blueAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _isDataLoaded
            ? ListView(
          children: [
            Row(
              children: [
                Expanded(
                  child: _buildStatCard('Total Tasks', totalTasks, Colors.blue),
                ),
                Expanded(
                  child: _buildStatCard('Total Fees', totalFees, Colors.orange),
                ),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard('Paid Fees', paidFees, Colors.green),
                ),
                Expanded(
                  child: _buildStatCard('Unpaid Fees', unpaidFees, Colors.red),
                ),
              ],
            ),
            SizedBox(height: 16),
            _buildBarChartSection('Tasks', _taskSeriesBarData),
            SizedBox(height: 16),
            _buildBarChartSection('Fees', _feeSeriesBarData),
            SizedBox(height: 16),
            _buildBarChartSection('Users', _userSeriesBarData),
          ],
        )
            : Center(child: CircularProgressIndicator()),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, Color color) {
    return Card(
      color: color,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: TextStyle(color: Colors.white, fontSize: 24)),
            SizedBox(height: 10),
            Text(value, style: TextStyle(color: Colors.white, fontSize: 36)),
          ],
        ),
      ),
    );
  }

  Widget _buildBarChartSection(String title, List<charts.Series<dynamic, String>> seriesData) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        SizedBox(height: 8),
        SizedBox(
          height: 300,
          child: seriesData.isNotEmpty
              ? charts.BarChart(
            seriesData,
            animate: true,
            barGroupingType: charts.BarGroupingType.grouped,
            behaviors: [
              charts.SeriesLegend(
                position: charts.BehaviorPosition.end,
                horizontalFirst: false,
                desiredMaxRows: 2,
                cellPadding: EdgeInsets.only(right: 4.0, bottom: 4.0),
                entryTextStyle: charts.TextStyleSpec(
                  color: charts.MaterialPalette.black,
                  fontSize: 11,
                ),
              ),
            ],
          )
              : Center(child: Text("No Data Available")),
        ),
      ],
    );
  }
}

void main() {
  runApp(MaterialApp(
    home: AdminPanelPage(),
  ));
}
