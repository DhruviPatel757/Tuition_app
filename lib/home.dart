import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'login.dart';

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
  File? _selectedFile;
  List<dynamic> tasks = [];

  @override
  void initState() {
    super.initState();
    _fetchTasks();
  }

  Future<void> _fetchTasks() async {
    final response = await http.get(
      Uri.parse('http://192.168.249.15:5000/tasks?group=$selectedGroup'),//192.168.11.15:5000
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

  Future<void> _addTask() async {
    String title = _taskTitleController.text.trim();

    if (title.isNotEmpty) {
      final response = await http.post(
        Uri.parse('http://192.168.249.15:5000/addTask'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, dynamic>{
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

  Future<void> _uploadFile() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedFile = File(pickedFile.path);
      });
      try {
        final storageRef = FirebaseStorage.instance.ref().child('uploads/${DateTime.now().millisecondsSinceEpoch}_${_selectedFile!.path.split('/').last}');
        await storageRef.putFile(_selectedFile!);
        String downloadUrl = await storageRef.getDownloadURL();
        await FirebaseFirestore.instance.collection('uploads').add({
          'fileUrl': downloadUrl,
          'uploadedAt': Timestamp.now(),
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('File uploaded successfully!')),
        );
        setState(() {
          _selectedFile = null;
        });
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

  Future<void> _downloadFile(String fileUrl) async {
    try {
      final fileName = fileUrl.split('/').last;
      final directory = await getTemporaryDirectory();
      final localPath = '${directory.path}/$fileName';
      await FirebaseStorage.instance.refFromURL(fileUrl).writeToFile(File(localPath));
      await OpenFile.open(localPath);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to download file: $e')),
      );
    }
  }

  void _logout() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LoginPage()),
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
              onPressed: () {

              },
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
            Expanded(
              flex: 2,
              child: StreamBuilder(
                stream: FirebaseFirestore.instance.collection('uploads').snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    final uploads = snapshot.data!.docs;
                    return ListView.builder(
                      itemCount: uploads.length,
                      itemBuilder: (context, index) {
                        final upload = uploads[index];
                        final fileUrl = upload['fileUrl'] as String;
                        return Card(
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: InkWell(
                            onTap: () {
                              _downloadFile(fileUrl);
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      'Downloaded file: ${fileUrl.split('/').last}',
                                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Icon(Icons.download, color: Colors.blue),
                                ],
                              ),
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
            Expanded(
              flex: 2,
              child: ListView.builder(
                itemCount: tasks.length,
                itemBuilder: (context, index) {
                  final task = tasks[index];
                  return Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Text(
                        task['title'],
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                  );
                },
              ),
            ),
            SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: selectedGroup,
              hint: Text('Select Group'),
              items: groups.map((group) {
                return DropdownMenuItem<String>(
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
              if (_selectedFile != null) ...[
                SizedBox(height: 16),
                Text(
                  'Selected file: ${_selectedFile!.path.split('/').last}',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}