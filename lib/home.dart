import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'login.dart';
import 'add_user_page.dart';

class HomePage extends StatefulWidget {
  final bool isAdmin;

  HomePage({required this.isAdmin});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _taskTitleController = TextEditingController();
  String? selectedGroup = 'All';
  final List<String> groups = ['All', '5th', '6th', '7th', '8th', '9th', '10th'];
  List tasks = [];

  @override
  void initState() {
    super.initState();
    _fetchTasks();
  }

  Future _fetchTasks() async {
    final response = await http.get(
      Uri.parse('http://192.168.203.15:6787/tasks?group=$selectedGroup'),
    );

    if (response.statusCode == 200) {
      setState(() {
        tasks = jsonDecode(response.body);
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching tasks')),
      );
    }
  }

  Future _addTask() async {
    String title = _taskTitleController.text.trim();
    if (title.isNotEmpty) {
      final response = await http.post(
        Uri.parse('http://192.168.203.15:6787/addTask'),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode({
          'title': title,
          'assignedTo': 'defaultUser',
          'group': selectedGroup!,
        }),
      );

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Task added successfully!')),
        );
        _taskTitleController.clear();
        _fetchTasks();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding task')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please fill all fields')),
      );
    }
  }

  Future _uploadFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();

    if (result != null) {
      Uint8List? fileBytes = result.files.single.bytes;
      String fileName = result.files.single.name;
      try {
        final storageRef = FirebaseStorage.instance.ref().child('uploads/$fileName');

        await storageRef.putData(fileBytes!);
        String downloadUrl = await storageRef.getDownloadURL();
        await FirebaseFirestore.instance.collection('uploads').add({
          'fileUrl': downloadUrl,
          'fileName': fileName,
          'uploadedAt': Timestamp.now(),
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('File uploaded successfully!')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to upload file: $e')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No file selected.')),
      );
    }
  }

  Future _downloadFile(String fileUrl) async {
    if (await canLaunch(fileUrl)) {
      await launch(fileUrl);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to download file: $fileUrl')),
      );
    }
  }

  void _logout() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LoginPage()),
    );
  }

  void _navigateToAddUserPage() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AddUserPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Home Page'),
        backgroundColor: Colors.blueAccent,
        actions: [
          if (widget.isAdmin)
            IconButton(
              icon: Icon(Icons.person_add),
              onPressed: _navigateToAddUserPage,
            ),
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Uploaded Files',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Expanded(
              child: StreamBuilder(
                stream: FirebaseFirestore.instance.collection('uploads').snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    final uploads = snapshot.data!.docs;
                    return ListView.separated(
                      itemCount: uploads.length,
                      separatorBuilder: (context, index) => SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final upload = uploads[index];
                        final fileUrl = upload['fileUrl'] as String;
                        final fileName = upload['fileName'] as String;
                        return GestureDetector(
                          onTap: () {
                            _downloadFile(fileUrl);
                          },
                          child: Container(
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
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    fileName,
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Icon(Icons.download, color: Colors.blue),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  } else {
                    return Center(child: CircularProgressIndicator());
                  }
                },
              ),
            ),
            SizedBox(height: 16),
            Text(
              'Tasks',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Expanded(
              child: ListView.separated(
                itemCount: tasks.length,
                separatorBuilder: (context, index) => SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final task = tasks[index];
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
                      task['title'],
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  );
                },
              ),
            ),
            SizedBox(height: 16),
            DropdownButtonFormField(
              value: selectedGroup,
              hint: Text('Select Group'),
              items: groups.map((group) {
                return DropdownMenuItem(
                  value: group,
                  child: Text(group),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedGroup = value;
                  _fetchTasks();
                });
              },
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            if (widget.isAdmin) ...[
              SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _taskTitleController,
                      decoration: InputDecoration(
                        labelText: 'Enter Task Title',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 8),
                  IconButton(
                    icon: Icon(Icons.add, size: 30),
                    onPressed: _addTask,
                    color: Colors.green,
                  ),
                  SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _uploadFile,
                    child: Text('Upload'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      padding: EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}