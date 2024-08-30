import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class FeesPage extends StatefulWidget {
  final bool isAdmin;
  final List users;
  final String userId; // Add userId to identify the current user

  FeesPage({required this.isAdmin, required this.users, required this.userId});

  @override
  _FeesPageState createState() => _FeesPageState();
}

class _FeesPageState extends State<FeesPage> {
  final TextEditingController _amountController = TextEditingController();
  String? selectedUser;
  List fees = [];

  @override
  void initState() {
    super.initState();
    if (widget.isAdmin) {
      if (widget.users.isNotEmpty) {
        selectedUser = widget.users.first['_id'];
      }
      _fetchFees();
    } else {
      selectedUser = widget.userId; // Use the current user's ID
      _fetchFees();
    }
  }

  Future _fetchFees() async {
    if (selectedUser != null) {
      final response = await http.get(
        Uri.parse('http://192.168.203.15:6787/fees/$selectedUser'),
      );

      if (response.statusCode == 200) {
        setState(() {
          fees = jsonDecode(response.body);
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching fees')),
        );
      }
    }
  }

  void _addFees() async {
    String amount = _amountController.text.trim();
    if (selectedUser != null && amount.isNotEmpty) {
      final response = await http.post(
        Uri.parse('http://192.168.203.15:6787/addFees'),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode({
          'userId': selectedUser,
          'amount': double.parse(amount),
        }),
      );

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fees of \$${amount} added for user!')),
        );
        _amountController.clear();
        _fetchFees();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding fees')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select a user and enter an amount')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Fees Management'),
        backgroundColor: Colors.blueAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            if (widget.isAdmin) ...[
              DropdownButtonFormField<String>(
                value: selectedUser,
                hint: Text('Select User'),
                items: widget.users.map((user) {
                  return DropdownMenuItem<String>(
                    value: user['_id'],
                    child: Text(user['username']),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedUser = value;
                    _fetchFees();
                  });
                },
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              SizedBox(height: 16),
              TextField(
                controller: _amountController,
                decoration: InputDecoration(
                  labelText: 'Enter Fee Amount',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                keyboardType: TextInputType.number,
              ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: _addFees,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  'Add Fees',
                  style: TextStyle(fontSize: 18),
                ),
              ),
              SizedBox(height: 16),
            ],
            Expanded(
              child: ListView.separated(
                itemCount: fees.length,
                separatorBuilder: (context, index) => SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final fee = fees[index];
                  return Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.2),
                          spreadRadius: 2,
                          blurRadius: 5,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Text(
                      'Amount: \$${fee['amount'].toStringAsFixed(2)}',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  );
                },
              ),
            ),
            if (!widget.isAdmin) ...[
              Center(
                child: Text(
                  'You are not authorized to manage fees.',
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
