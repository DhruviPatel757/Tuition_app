import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:charts_flutter/flutter.dart' as charts;

class AdminPanelPage extends StatefulWidget {
  @override
  _AdminPanelPageState createState() => _AdminPanelPageState();
}

class _AdminPanelPageState extends State<AdminPanelPage> {
  List<charts.Series<dynamic, String>> _taskSeriesBarData = [];
  List<charts.Series<dynamic, String>> _feeSeriesBarData = [];
  List<charts.Series<dynamic, String>> _userSeriesBarData = [];
  List tasks = [];
  List users = [];
  List fees = [];

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    await Future.wait([_fetchTasks(), _fetchUsers(), _fetchFees()]);
    setState(() {
      _generateBarChartData();
    });
  }

  Future<void> _fetchTasks() async {
    final response = await http.get(Uri.parse('http://192.168.0.16:6787/admin/tasks'));
    if (response.statusCode == 200) {
      setState(() {
        tasks = jsonDecode(response.body);
      });
    } else {
      _showError('Error fetching tasks');
    }
  }

  Future<void> _fetchUsers() async {
    final response = await http.get(Uri.parse('http://192.168.0.16:6787/admin/users'));
    if (response.statusCode == 200) {
      setState(() {
        users = jsonDecode(response.body);
      });
    } else {
      _showError('Error fetching users');
    }
  }

  Future<void> _fetchFees() async {
    final response = await http.get(Uri.parse('http://192.168.0.16:6787/admin/fees'));
    if (response.statusCode == 200) {
      setState(() {
        fees = jsonDecode(response.body);
      });
    } else {
      _showError('Error fetching fees');
    }
  }

  void _generateBarChartData() {
    debugPrint('Tasks: $tasks');
    debugPrint('Users: $users');
    debugPrint('Fees: $fees');

    // Generate bar chart data for tasks
    var taskData = [
      {'category': 'Completed', 'count': tasks.where((task) => task['completed'] == true).length},
      {'category': 'Pending', 'count': tasks.where((task) => task['completed'] != true).length},
    ];

    if (taskData.isNotEmpty) {
      _taskSeriesBarData.add(
        charts.Series<dynamic, String>(
          id: 'Tasks',
          domainFn: (datum, index) => datum['category'],
          measureFn: (datum, index) => datum['count'],
          data: taskData,
          colorFn: (_, __) => charts.MaterialPalette.blue.shadeDefault,
        ),
      );
    }

    // Generate bar chart data for fees
    var feeData = [
      {'status': 'Paid', 'count': fees.where((fee) => fee['paid'] == true).length},
      {'status': 'Unpaid', 'count': fees.where((fee) => fee['paid'] != true).length},
    ];

    if (feeData.isNotEmpty) {
      _feeSeriesBarData.add(
        charts.Series<dynamic, String>(
          id: 'Fees',
          domainFn: (datum, index) => datum['status'],
          measureFn: (datum, index) => datum['count'],
          data: feeData,
          colorFn: (_, __) => charts.MaterialPalette.red.shadeDefault,
        ),
      );
    }

    // Generate bar chart data for users
    var userData = [
      {'role': 'Admin', 'count': users.where((user) => user['isAdmin'] == true).length},
      {'role': 'Regular', 'count': users.where((user) => user['isAdmin'] != true).length},
    ];

    if (userData.isNotEmpty) {
      _userSeriesBarData.add(
        charts.Series<dynamic, String>(
          id: 'Users',
          domainFn: (datum, index) => datum['role'],
          measureFn: (datum, index) => datum['count'],
          data: userData,
          colorFn: (_, __) => charts.MaterialPalette.green.shadeDefault,
        ),
      );
    }

    setState(() {});
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Admin Panel'),
        backgroundColor: Colors.blueAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            _buildBarChartSection('Tasks', _taskSeriesBarData),
            SizedBox(height: 16),
            _buildBarChartSection('Fees', _feeSeriesBarData),
            SizedBox(height: 16),
            _buildBarChartSection('Users', _userSeriesBarData),
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
