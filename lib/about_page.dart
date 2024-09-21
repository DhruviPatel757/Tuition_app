import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AboutPage extends StatefulWidget {
  @override
  _AboutPageState createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage> {
  List tasks = [];
  List users = [];
  List fees = [];

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future _fetchData() async {
    await Future.wait([_fetchTasks(), _fetchUsers(), _fetchFees()]);
  }

  Future _fetchTasks() async {
    final response = await http.get(Uri.parse('http://192.168.0.16:6787/admin/tasks'));
    if (response.statusCode == 200) {
      setState(() {
        tasks = jsonDecode(response.body);
      });
    } else {
      _showError('Error fetching tasks');
    }
  }

  Future _fetchUsers() async {
    final response = await http.get(Uri.parse('http://192.168.0.16:6787/admin/users'));
    if (response.statusCode == 200) {
      setState(() {
        users = jsonDecode(response.body);
      });
    } else {
      _showError('Error fetching users');
    }
  }

  Future _fetchFees() async {
    final response = await http.get(Uri.parse('http://192.168.0.16:6787/admin/fees'));
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

  Future<void> _updateFeeStatus(String feeId, bool paid) async {
    final response = await http.put(
      Uri.parse('http://192.168.0.16:6787/updateFee/$feeId'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'paid': paid}),
    );

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Fee updated successfully!')));
      _fetchFees(); // Refresh the fees list
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error updating fee status')));
    }
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
            _buildFeesSection('Fees', fees),
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

  Widget _buildFeesSection(String title, List data) {
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
              final fee = data[index];
              return _buildFeeItem(fee);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFeeItem(Map fee) {
    // Add null checks for userId and username
    String username = fee['userId'] != null && fee['userId']['username'] != null
        ? fee['userId']['username']
        : 'Unknown user';
    double amount = fee['amount']?.toDouble() ?? 0.0;
    bool paid = fee['paid'] ?? false;

    return ListTile(
      title: Text('User: $username'),
      subtitle: Text('Amount: \$${amount.toStringAsFixed(2)}'),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Checkbox(
            value: paid,
            onChanged: (value) {
              _updateFeeStatus(fee['_id'], value!);
            },
          ),
          Text(
            paid ? 'Paid' : 'Unpaid',
            style: TextStyle(
              color: paid ? Colors.green : Colors.red,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}