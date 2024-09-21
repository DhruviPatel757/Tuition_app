import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:charts_flutter/flutter.dart' as charts;

class AdminPanelPage extends StatefulWidget {
  @override
  _AdminPanelPageState createState() => _AdminPanelPageState();
}

class _AdminPanelPageState extends State<AdminPanelPage> {
  List<charts.Series<dynamic, String>> _taskSeriesPieData = [];
  List<charts.Series<dynamic, String>> _feeSeriesPieData = [];
  List<charts.Series<dynamic, String>> _userSeriesPieData = [];
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
      _generatePieChartData();
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

  void _generatePieChartData() {
    debugPrint('Tasks: $tasks');
    debugPrint('Users: $users');
    debugPrint('Fees: $fees');
    var taskData = [
      {'task': 'Completed', 'count': tasks.where((task) => task['completed'] == true).length},
      {'task': 'Pending', 'count': tasks.where((task) => task['completed'] != true).length},
    ];

    if (taskData.isNotEmpty) {
      _taskSeriesPieData.add(
        charts.Series<dynamic, String>(
          id: 'Tasks',
          domainFn: (datum, index) => datum['task'],
          measureFn: (datum, index) => datum['count'],
          data: taskData,
        ),
      );
    }
    var feeData = [
      {'status': 'Paid', 'count': fees.where((fee) => fee['paid'] == true).length},
      {'status': 'Unpaid', 'count': fees.where((fee) => fee['paid'] != true).length},
    ];

    if (feeData.isNotEmpty) {
      _feeSeriesPieData.add(
        charts.Series<dynamic, String>(
          id: 'Fees',
          domainFn: (datum, index) => datum['status'],
          measureFn: (datum, index) => datum['count'],
          data: feeData,
        ),
      );
    }
    var userData = [
      {'role': 'Admin', 'count': users.where((user) => user['isAdmin'] == true).length},
      {'role': 'Regular', 'count': users.where((user) => user['isAdmin'] != true).length},
    ];

    if (userData.isNotEmpty) {
      _userSeriesPieData.add(
        charts.Series<dynamic, String>(
          id: 'Users',
          domainFn: (datum, index) => datum['role'],
          measureFn: (datum, index) => datum['count'],
          data: userData,
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
            _buildPieChartSection('Tasks', _taskSeriesPieData),
            SizedBox(height: 16),
            _buildPieChartSection('Fees', _feeSeriesPieData),
            SizedBox(height: 16),
            _buildPieChartSection('Users', _userSeriesPieData),
          ],
        ),
      ),
    );
  }

  Widget _buildPieChartSection(String title, List<charts.Series<dynamic, String>> seriesData) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        SizedBox(height: 8),
        SizedBox(
          height: 300,
          child: seriesData.isNotEmpty
              ? charts.PieChart<String>(
            seriesData,
            animate: true,
            behaviors: [
              charts.DatumLegend(
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
            defaultRenderer: charts.ArcRendererConfig<String>(
              arcWidth: 100,
              strokeWidthPx: 0,
            ),
          )
              : Center(child: Text("No Data Available")),
        ),
      ],
    );
  }
}
