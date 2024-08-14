import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'add_user_page.dart';
import 'login.dart';
import 'fees.dart';

class HomePage extends StatefulWidget {
  final bool isAdmin;

  HomePage({required this.isAdmin});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _messageController = TextEditingController();
  List<String> messages = [];
  String? selectedClass;
  final List<String> classes = ['All', '5th', '6th', '7th', '8th', '9th', '10th'];
  File? _selectedFile;

  void _addMessage() {
    String message = _messageController.text.trim();
    if (message.isNotEmpty && selectedClass != null) {
      setState(() {
        messages.add('Class $selectedClass: $message');
        _messageController.clear();
        selectedClass = null;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter a message and select a class')),
      );
    }
  }

  void _logout() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LoginPage()),
    );
  }

  Future<void> _uploadFile() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _selectedFile = File(pickedFile.path);
      });

      try {
        // Create a reference to the storage bucket
        final storageRef = FirebaseStorage.instance.ref().child('uploads/${DateTime.now().millisecondsSinceEpoch}_${_selectedFile!.path.split('/').last}');

        // Upload the file
        await storageRef.putFile(_selectedFile!);

        // Get the download URL
        String downloadUrl = await storageRef.getDownloadURL();

        // Save the file reference in Firestore
        await FirebaseFirestore.instance.collection('uploads').add({
          'fileUrl': downloadUrl,
          'uploadedAt': Timestamp.now(),
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('File uploaded successfully!')),
        );

        setState(() {
          _selectedFile = null; // Clear the selected file
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
      // Get the file name from the URL
      final fileName = fileUrl.split('/').last;

      // Get the temporary directory for storing the downloaded file
      final directory = await getTemporaryDirectory();
      final localPath = '${directory.path}/$fileName';

      // Download the file from Firebase Storage
      await FirebaseStorage.instance.refFromURL(fileUrl).writeToFile(File(localPath));

      // Open the downloaded file
      await OpenFile.open(localPath);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to download file: $e')),
      );
    }
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
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => AddUserPage()),
                );
              },
            ),
          IconButton(
            icon: Icon(Icons.money),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => FeesPage(isAdmin: widget.isAdmin)),
              );
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
              child: ListView.builder(
                itemCount: messages.length + 1,
                itemBuilder: (context, index) {
                  if (index < messages.length) {
                    return Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Text(
                          messages[index],
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    );
                  } else {
                    return StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance.collection('uploads').snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.hasData) {
                          final uploads = snapshot.data!.docs;
                          return ListView.builder(
                            shrinkWrap: true,
                            physics: NeverScrollableScrollPhysics(),
                            itemCount: uploads.length,
                            itemBuilder: (context, uploadIndex) {
                              final upload = uploads[uploadIndex];
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
                                    child: Text(
                                      'Downloaded file: ${fileUrl.split('/').last}',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
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
                    );
                  }
                },
              ),
            ),
            if (widget.isAdmin) ...[
              SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedClass,
                hint: Text('Select Class'),
                items: classes.map((className) {
                  return DropdownMenuItem<String>(
                    value: className,
                    child: Text(className),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedClass = value;
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
                controller: _messageController,
                decoration: InputDecoration(
                  hintText: 'Enter a message or task',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(Icons.add),
                    onPressed: _addMessage,
                  ),
                ),
              ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: _uploadFile,
                child: Text('Upload File'),
              ),
              if (_selectedFile != null) ...[
                SizedBox(height: 16),
                Text('Selected file: ${_selectedFile!.path.split('/').last}'),
              ],
            ],
          ],
        ),
      ),
    );
  }
}