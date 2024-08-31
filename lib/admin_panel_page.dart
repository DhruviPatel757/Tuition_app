import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AdminPanelPage extends StatefulWidget {
  @override
  _AdminPanelPageState createState() => _AdminPanelPageState();
}

class _AdminPanelPageState extends State<AdminPanelPage> {
  List tasks = [];
  List users = [];
  List fees = [];

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future _fetchData() async {
    await Future.wait([
      _fetchTasks(),
      _fetchUsers(),
      _fetchFees(),
    ]);
  }

  Future _fetchTasks() async {
    final response = await http.get(Uri.parse('http://192.168.203.15:6787/admin/tasks'));
    if (response.statusCode == 200) {
      setState(() {
        tasks = jsonDecode(response.body);
      });
    } else {
      _showError('Error fetching tasks');
    }
  }

  Future _fetchUsers() async {
    final response = await http.get(Uri.parse('http://192.168.203.15:6787/admin/users'));
    if (response.statusCode == 200) {
      setState(() {
        users = jsonDecode(response.body);
      });
    } else {
      _showError('Error fetching users');
    }
  }

  Future _fetchFees() async {
    final response = await http.get(Uri.parse('http://192.168.203.15:6787/admin/fees'));
    if (response.statusCode == 200) {
      setState(() {
        fees = jsonDecode(response.body);
      });
    } else {
      _showError('Error fetching fees');
    }
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
            _buildSection('Tasks', tasks),
            SizedBox(height: 16),
            _buildSection('Users', users),
            SizedBox(height: 16),
            _buildSection('Fees', fees),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, List data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        SizedBox(height: 8),
        Container(
          height: 200,
          child: ListView.separated(
            scrollDirection: Axis.vertical,
            itemCount: data.length,
            separatorBuilder: (context, index) => Divider(),
            itemBuilder: (context, index) {
              final item = data[index];
              return ListTile(
                title: Text(item is Map ? item['title'] ?? item['username'] ?? 'No title' : 'No data'),
                subtitle: item is Map ? Text(item['assignedTo'] ?? '') : null,
              );
            },
          ),
        ),
      ],
    );
  }
}
