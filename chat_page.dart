import 'dart:developer';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tahaleli/Screens/pdf_viewer_page.dart';
import 'package:tahaleli/model/patient.dart';
import 'package:tahaleli/utils/api_exceptions.dart';
import '../Services/ocr_services.dart';
import '../model/patient_file.dart';
import '../model/test_result.dart';
import '../utils/app_utils.dart';
import 'welcome_page.dart';
import 'history_page.dart';
import 'profile_page.dart';
import 'dart:io';
import 'dart:convert';
import 'package:path/path.dart' as path;

class ChatPage extends StatefulWidget {
  final String userName;

  const ChatPage({
    super.key,
    required this.userName,
  });

  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final List<Map<String, dynamic>> _messages = [];
  FilePickerResult? _selectedFile;
  Map<String, dynamic>? _userData;
  bool _isLoading = false;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ImagePicker picker = ImagePicker();
  final FirebaseStorage _storage = FirebaseStorage.instance;
  bool awaitingHeight = false; // Track if waiting for height input
  bool awaitingWeight = false; // Track if waiting for weight input
  bool bmiFlowActive = false; // Track if BMI flow is active
  final ScrollController _scrollController = ScrollController();
  double? userHeight;
  bool awaitingDocument = false;
  String welcomeMessage = "";

  Future<void> _openCamera() async {
    print("User ID: ${_auth.currentUser?.uid}");
    try {
      final XFile? photo = await picker.pickImage(source: ImageSource.camera);
      if (photo != null) {
        File file = File(photo.path);
        await _uploadImage(file); // Use the same _uploadImage method as before
      }
    } catch (e) {
      print("Error capturing image: $e");
    }
  }

  Future<void> _uploadDocument(File file, String fileName) async {
    print("User ID: ${_auth.currentUser?.uid}");
    try {
      String? userID = _auth.currentUser?.uid;
      if (userID == null) {
        print("User is not logged in.");
        return;
      }

      // Upload to Firebase Storage
      Reference storageRef =
      _storage.ref().child('user_files/$userID/$fileName');
      await storageRef.putFile(file);

      // Get the download URL
      String downloadURL = await storageRef.getDownloadURL();

      // Save metadata to Firestore
      Map<String, dynamic> fMessage = {
        'type': 'file',
        'content': downloadURL,
        'fileName': fileName,
        'createdAt': FieldValue.serverTimestamp(),
        'userId': userID,
      };

      await _firestore.collection('messages').add(fMessage);
    } catch (e) {
      print("Error uploading file: $e");
    }
  }

  Future<void> _uploadImage(File file) async {
    print("User ID: ${_auth.currentUser?.uid}");
    try {
      String? userID = _auth.currentUser?.uid;
      if (userID == null) {
        print("User is not logged in.");
        return;
      }

      // Generate a unique file name
      String fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';

      // Upload to Firebase Storage
      Reference storageRef =
      _storage.ref().child('user_files/$userID/$fileName');
      await storageRef.putFile(file);

      // Get the download URL
      String downloadURL = await storageRef.getDownloadURL();

      // Save metadata to Firestore
      Map<String, dynamic> iMessage = {
        'type': 'image',
        'content': downloadURL,
        'createdAt': FieldValue.serverTimestamp(),
        'userId': userID,
      };

      await _firestore.collection('messages').add(iMessage);
      setState(() {
        _messages.add(iMessage);
      });
    } catch (e) {
      print("Error uploading image: $e");
    }
  }

  Future<void> _pickFile() async {
    try {
      showModalBottomSheet(
        context: context,
        builder: (BuildContext context) {
          return SafeArea(
            child: Wrap(
              children: <Widget>[
                ListTile(
                  leading: const Icon(Icons.photo),
                  title: const Text('Upload from Photos'),
                  onTap: () async {
                    Navigator.pop(context);

                    _selectedFile = await FilePicker.platform.pickFiles(
                      type: FileType.image,
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.insert_drive_file),
                  title: const Text('Upload Document'),
                  onTap: () async {
                    Navigator.pop(context);

                    _selectedFile = await FilePicker.platform.pickFiles(
                      type: FileType.any,
                    );

                  },
                ),
              ],
            ),
          );
        },
      );
    } catch (e) {
      print("File selection error: $e");
    }
  }

  Future<void> registerUser(
      String email, String password, String fullName) async {
    try {
      UserCredential userCredential =
      await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Save the user's name in Firestore
      await _firestore.collection('users').doc(userCredential.user?.uid).set({
        'fullName': fullName,
        'email': email,
      });
      print("User registered and name saved in Firestore.");
    } catch (e) {
      print("Error registering user: $e");
    }
  }

  Future<PatientRes?> _getPatientInfo() async {
    try {
      File file = File(_selectedFile!.files.first.path!);
      String base64File = convertIntoBase64(file);

      PatientFileReq patientFileModel =
      PatientFileReq(base64string: base64File);

      Map<String, dynamic> respnse =
      await OCRService().uploadFile(patientFileModel.toJson());

      return PatientRes.fromJson(respnse);
    } on BadRequestException catch (e) {
      return null;
    } on Exception {
      return null;
    }
  }

  Future<void> _comparePationResult() async {
    PatientRes? res = await _getPatientInfo();

    if (res != null) {
      if ((res.testresults ?? []).isNotEmpty) {
        for (var testResult in res.testresults!) {
          QuerySnapshot<Map<String, dynamic>> doc =
          await _firestore.collection('bloodTests').get();

          Map<String, dynamic> data = doc.docs
              .singleWhere(
                (element) => element.data()["testName"] == testResult.testName,
          )
              .data();

          showResult(
            testName: testResult.testName ?? "",
            result: testResult.displaymessage ?? "",
            description: data["description"] ?? "",
          );
        }
      }
    }
  }


  void showResult(
      {required String testName,
        required String result,
        required String description}) {
    // Create a new chat message entry for the test result
    Map<String, dynamic> resultMessage = {
      'type': 'result',
      'content': 'Test: $testName\nResult: $result\nDescription: $description',
      'createdAt': FieldValue.serverTimestamp(),
      'userId': "System",
    };

    // Add the result message to your chat messages in Firestore or local list
    _firestore.collection('messages').add(resultMessage);
    setState(() {
      _messages.add(resultMessage);
    });
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.isNotEmpty || _selectedFile != null) {
      String? userID = _auth.currentUser?.uid;
      if (userID == null) return;

      final input = _messageController.text.trim();

      if (awaitingDocument) {
        if (_selectedFile != null) {

          // Upload the document/picture
          String fileName = _selectedFile!.files.single.name;
          File file = File(_selectedFile!.files.single.path!);
          if(path.extension(file.path) == ".pdf"){
            await _uploadDocument(file, fileName);
          }
          else{
            await _uploadImage(file);
          }
          _getMessageList();
          await _comparePationResult();

          // Reset the document flag
          awaitingDocument = false;
          _selectedFile = null; // Clear the selected file
        } else {
          // No file uploaded, prompt the user again
          var response = {
            'userId': 'System',
            'type': 'text',
            'content':
            'Please upload a document or picture for test results interpretation.',
            'createdAt': FieldValue.serverTimestamp(),
          };

          await _firestore.collection('messages').add(response);
          await _getMessageList();
        }
      } else {
        // Handle regular user messages
        var textMessage = {
          'type': 'text',
          'content': input,
          'createdAt': FieldValue.serverTimestamp(),
          'userId': userID,
        };
        await _firestore.collection('messages').add(textMessage);
        await _getMessageList();

        // Process the input (Options 1 or 2)
        if (bmiFlowActive) {
          await handleBMIFlow(input);
        } else {
          handleResponse(input);
        }
        await _getMessageList();
      }
      _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      // Clear the message input field
      setState(() {
        _messageController.clear();
      });
    }
  }

  Future<void> _getMessageList() async {
    QuerySnapshot<Map<String, dynamic>> snapshot = await _firestore
        .collection('messages')
        .orderBy('createdAt', descending: false) // Oldest to newest
        .get();

    if (mounted) {
      var data = snapshot.docs.last;
      print("Fetched chat message: ${data.data()}");
      setState(() {
        _messages.add(data.data());
      });
    }
  }

  Widget _buildMessageWidget(Map<String, dynamic> item) {
    final type = item['type'];
    final content = item['content'];
    final fileName = item['fileName'] ?? 'File'; // Default file name

    // Determine if it's a user or system message
    bool isUserMessage = item['userId'] == _auth.currentUser?.uid;

    String userName =
    isUserMessage ? (_auth.currentUser?.displayName ?? '${_userData?['firstName']}') : 'System';

    // Alignment and color settings
    CrossAxisAlignment alignment =
    isUserMessage ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    Color? messageBoxColor =
    isUserMessage ? Colors.blue[300] : Colors.blueGrey[300];
    Color textColor = Colors.white;

    // Create the widget for displaying the message
    Widget messageWidget;

    switch (type) {
      case 'image':
        messageWidget = Image.network(
          content,
          width: 150,
          height: 150,
          fit: BoxFit.cover,
        );
        break;
      case 'file':
      // Check if the file is a PDF by checking the file name or content type
        if (fileName.endsWith('.pdf')) {
          messageWidget = ListTile(
            leading: Icon(Icons.picture_as_pdf,
                color: isUserMessage ? Colors.blue : Colors.grey),
            title: Text(
              fileName,
              style: TextStyle(color: textColor),
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PDFViewerPage(pdfUrl: content),
                ),
              );
            },
          );
        } else {
          // Default handling if the file isn't a PDF or isn't recognized
          messageWidget = Text(
            'Unsupported file type',
            style: TextStyle(color: textColor),
          );
        }
        break;
      default:
        messageWidget = Text(
          content,
          style: TextStyle(color: textColor),
        );
        break;
    }

    // Return a column with optional name label and the message widget
    return MessageWidget(
      alignment: alignment,
      userName: userName,
      isUserMessage: isUserMessage,
      messageBoxColor: messageBoxColor,
      messageWidget: messageWidget,
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Logout Confirmation'),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('No'),
            ),
            TextButton(
              onPressed: () async {
                // Clear local messages
                setState(() {
                  _messages.clear();
                  _messageController.clear();
                  _selectedFile = null;
                });

                // Clear user messages
                String? userId = _auth.currentUser?.uid;
                if (userId != null) {
                  try {
                    final userMessagesQuery = await _firestore
                        .collection('messages')
                        .where('userId', isEqualTo: userId)
                        .get();

                    for (var doc in userMessagesQuery.docs) {
                      await _firestore
                          .collection('messages')
                          .doc(doc.id)
                          .delete();
                    }
                    print("User messages cleared.");
                  } catch (e) {
                    print("Error deleting user messages: $e");
                  }
                }

                // Clear system messages
                await clearSystemMessages();

                // Sign out the user
                await _auth.signOut();

                // Navigate to the Welcome Page
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const WelcomePage()),
                      (route) => false, // Remove all routes
                );
              },
              child: const Text('Yes'),
            ),
          ],
        );
      },
    );
  }

  Future<void> clearSystemMessages() async {
    try {
      // Query system messages from Firestore
      final systemMessagesQuery = await _firestore
          .collection('messages')
          .where('userId', isEqualTo: 'System')
          .get();

      // Delete each system message
      for (var doc in systemMessagesQuery.docs) {
        await _firestore.collection('messages').doc(doc.id).delete();
      }

      print("System messages cleared.");
    } catch (e) {
      print("Error clearing system messages: $e");
    }
  }

  Future<void> _fetchUserData() async {
    setState(() {
      _isLoading = true;
    });
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        DocumentSnapshot userDoc =
        await _firestore.collection('users').doc(user.uid).get();

        if (userDoc.exists) {
          setState(() {
            _userData = userDoc.data() as Map<String, dynamic>?;
          });
        } else {
          print("User document does not exist.");
        }
      }
    } catch (e) {
      print("Error fetching user data: $e");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _fetchMessages() async {
    try {
      // Fetch the welcome message
      String displayName = _auth.currentUser?.displayName ?? '${_userData?['firstName']}';

      setState(() {
        welcomeMessage =
        "Welcome $displayName, choose an option:\n1. Test Results Interpretation\n2. BMI Calculator";
      });
    } catch (e) {
      print("Error fetching messages: $e");
    }
  }

  Future<void> handleResponse(String input) async {
    if (input == '1') {
      // Option 1: Test Results Interpretation
      awaitingDocument = true; // Set the flag to wait for document upload
      var response = {
        'userId': 'System',
        'type': 'text',
        'content':
        'Please upload your test results as a pdf document or picture.',
        'createdAt': FieldValue.serverTimestamp(),
      };
      _firestore.collection('messages').add(response);
    } else if (input == '2') {
      // Option 2: BMI Calculator
      bmiFlowActive = true;
      awaitingHeight = true; // Start BMI flow
      var response = {
        'userId': 'System',
        'type': 'text',
        'content': 'Please enter your height in meters (e.g., 1.75):',
        'createdAt': FieldValue.serverTimestamp(),
      };
      _firestore.collection('messages').add(response);
    } else {
      // Invalid input
      var response = {
        'userId': 'System',
        'type': 'text',
        'content':
        'Invalid option. Please select:\n1. Test Results Interpretation\n2. BMI Calculator',
        'createdAt': FieldValue.serverTimestamp(),
      };
      _firestore.collection('messages').add(response);
    }
  }

  Future<void> handleBMIFlow(String input) async {
    double? parsedValue = double.tryParse(input); // Parse input once

    if (awaitingHeight) {
      if (parsedValue == null || parsedValue <= 0) {
        // Invalid height input
        var response = {
          'userId': 'System',
          'type': 'text',
          'content':
          'Invalid height. Please enter a valid height in meters (e.g., 1.75):',
          'createdAt': FieldValue.serverTimestamp(),
        };
        _firestore.collection('messages').add(response);
      } else {
        // Valid height, now ask for weight
        awaitingHeight = false;
        awaitingWeight = true;
        userHeight = parsedValue; // Store height
        var response = {
          'userId': 'System',
          'type': 'text',
          'content':
          'Thank you. Now, please enter your weight in kilograms (e.g., 70):',
          'createdAt': FieldValue.serverTimestamp(),
        };
        _firestore.collection('messages').add(response);
      }
    } else if (awaitingWeight) {
      if (parsedValue == null || parsedValue <= 0) {
        // Invalid weight input
        var response = {
          'userId': 'System',
          'type': 'text',
          'content':
          'Invalid weight. Please enter a valid weight in kilograms (e.g., 70):',
          'createdAt': FieldValue.serverTimestamp(),
        };
        _firestore.collection('messages').add(response);
      } else {
        // Valid weight, calculate BMI
        awaitingWeight = false;
        bmiFlowActive = false; // End BMI flow
        calculateBMI(
            userHeight!, parsedValue); // Use stored height and current weight
      }
    }
  }

  void calculateBMI(double height, double weight) {
    double bmi = weight / (height * height); // Correct BMI formula
    String status;

    if (bmi < 18.5) {
      status = "Underweight";
    } else if (bmi < 25) {
      status = "Normal weight";
    } else if (bmi < 30) {
      status = "Overweight";
    } else if (bmi < 35) {
      status = "Obesity class I";
    } else if (bmi < 40) {
      status = "Obesity class II";
    } else {
      status = "Obesity class III (Severe obesity)";
    }

    var response = {
      'userId': 'System',
      'type': 'text',
      'content': 'Your BMI is: ${bmi.toStringAsFixed(2)}\nStatus: $status',
      'createdAt': FieldValue.serverTimestamp(),
    };
    _firestore.collection('messages').add(response);
  }

  @override
  void initState() {
    super.initState();
    _fetchUserData();
    print("Starting message fetch...");
    clearSystemMessages().then((_) {
      print("System messages cleared.");

      print("Welcome message sent.");
      _fetchMessages(); // Ensure this is called
      // sendWelcomeMessage().then((_) {
      //   print("Welcome message sent.");
      //   _fetchMessages(); // Ensure this is called
      // });
    }).catchError((e) {
      print("Error in initState: $e");
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF141E46),
        title: const Text('Chat Page', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(
          color: Colors.white,
        ),
      ),
      drawer: Drawer(
        backgroundColor: const Color(0xFF26345D),
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            UserAccountsDrawerHeader(
              decoration: const BoxDecoration(color: Colors.white),
              accountName: Text(
                'Hello, ${_userData?['firstName'] ?? 'User'} :)',
                style: const TextStyle(color: Color(0xFF141E46)),
              ),
              accountEmail: const Text(''),
            ),
            ListTile(
              leading: const Icon(Icons.chat, color: Colors.white),
              title: const Text('Chat', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context); // Stay on the chat page
              },
            ),
            ListTile(
              leading: const Icon(Icons.history, color: Colors.white),
              title:
              const Text('History', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => HistoryPage()));
                // Navigate to the History Page
              },
            ),
            ListTile(
              leading: const Icon(Icons.more_horiz, color: Colors.white),
              title: const Text('More', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => ProfilePage()));
                // Navigate to the More Page
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Logout', style: TextStyle(color: Colors.red)),
              onTap: _showLogoutDialog, // Show logout confirmation dialog
            ),
          ],
        ),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Expanded(
            child: Align(
              alignment: Alignment.bottomLeft,
              child: SingleChildScrollView(
                controller: _scrollController,
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    MessageWidget(
                      alignment: CrossAxisAlignment.start,
                      userName: "",
                      isUserMessage: false,
                      messageBoxColor: Colors.blueGrey[300],
                      messageWidget: Text(welcomeMessage),
                    ),
                    ListView.builder(
                      shrinkWrap: true,
                      reverse: true, // Show latest messages at the bottom
                      physics: NeverScrollableScrollPhysics(),
                      itemCount: _messages.length,
                      itemBuilder: (context, index) {
                        final message = _messages[_messages.length - 1 - index];
                        return _buildMessageWidget(message);
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.attach_file, color: Colors.white),
                  onPressed: _pickFile,
                ),
                IconButton(
                  icon: const Icon(Icons.camera_alt_outlined,
                      color: Colors.white),
                  onPressed: _openCamera,
                ),
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      hintStyle: const TextStyle(color: Colors.white54),
                      filled: true,
                      fillColor: const Color(0xFF3C4A73),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: Colors.white),
                  onPressed: () => _sendMessage(),
                ),
              ],
            ),
          ),
        ],
      ),
      backgroundColor: const Color(0xFF141E46),
    );
  }
}

class MessageWidget extends StatelessWidget {
  const MessageWidget({
    super.key,
    required this.alignment,
    required this.userName,
    required this.isUserMessage,
    required this.messageBoxColor,
    required this.messageWidget,
  });

  final CrossAxisAlignment alignment;
  final String userName;
  final bool isUserMessage;
  final Color? messageBoxColor;
  final Widget messageWidget;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: alignment,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Text(
            userName,
            style: TextStyle(
              fontSize: 12,
              color: isUserMessage ? Colors.blue : Colors.grey,
            ),
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(vertical: 4.0),
          padding:
          const EdgeInsets.all(10.0), // Increased padding for larger box
          decoration: BoxDecoration(
            color: messageBoxColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: messageWidget,
        ),
      ],
    );
  }
}
