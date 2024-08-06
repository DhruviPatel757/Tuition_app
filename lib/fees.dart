import 'package:flutter/material.dart';

class FeesPage extends StatefulWidget {
  final bool isAdmin;

  FeesPage({required this.isAdmin});

  @override
  _FeesPageState createState() => _FeesPageState();
}

class _FeesPageState extends State<FeesPage> {
  final TextEditingController _amountController = TextEditingController();
  String? selectedUser;
  final List<String> users = ['User1', 'User2', 'User3'];

  void _addFees() {
    String amount = _amountController.text.trim();
    if (selectedUser != null && amount.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Fees of \$${amount} added for $selectedUser!')),
      );
      _amountController.clear();
      selectedUser = null;
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
                items: users.map((user) {
                  return DropdownMenuItem<String>(
                    value: user,
                    child: Text(user),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedUser = value;
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
            ],
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