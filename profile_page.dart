import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tahaleli/Widgets/ProfileInfoField.dart';
import 'package:tahaleli/user_auth/firebase_auth_services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';
import 'history_page.dart';
import 'chat_page.dart';
import 'reset_password_page.dart';
import 'welcome_page.dart';

class ProfilePage extends StatefulWidget{
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  File? _image;
  String phoneNum = '';
  final String adminEmail = "admin@gmail.com";
  String adminPhoneNum = "0795637990";
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Map<String, dynamic>? _userData;
  bool _isLoading = true;

  Future<void> _launchEmail(String email) async{
    final Uri emailUri = Uri(scheme: 'mailto', path: email, query: 'subject=Support Request',);
    if (await canLaunchUrl(emailUri)){
      await launchUrl(emailUri);
    }
    else{
      throw 'Could not launch email app';
    }
  }

  Future<void> _launchPhone(String phone) async{
    final Uri phoneUri = Uri(scheme: 'tel', path: phone);
    if(await canLaunchUrl(phoneUri)){
      await launchUrl(phoneUri);
    }
    else{
      print('Could not launch dialer');
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
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
                Navigator.pop(context); // Close the dialog
              },
              child: const Text('No'),
            ),
            TextButton(
              onPressed: () {
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

  Future<void> _updatePhoneNum(String newPhoneNum) async{
    try{
      User? user = _auth.currentUser;
      if(user != null){
        await _firestore.collection('users').doc(user.uid).update({'phoneNum': newPhoneNum});
        setState(() {
          phoneNum = newPhoneNum;
        });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Phone number updated successfully!')));
      }
    }
      catch(e){        
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failled to update phone number!')));
      }
    }
  

  Future<void> _fetchUserData() async{
    setState(() {
      _isLoading = true;
    });

    try{
      User? user = _auth.currentUser;
      if(user != null){
        DocumentSnapshot userDoc = await _firestore.collection('users').doc(user.uid).get();
        setState(() {
          _userData = userDoc.data() as Map<String, dynamic>?;
          _isLoading = false;
        });
      }
    }
    catch (e){
        print("Error fetching user data: $e");
        setState(() {
          _isLoading = false;
        });
    }
    }


@override
void initState() {
  super.initState();
  _fetchUserData();
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF141E46),
      appBar: AppBar(
        backgroundColor: Color(0xFF141E46),
        elevation: 0,
        title: Text('More', style: TextStyle(color: Colors.white,)),
        iconTheme: const IconThemeData(
          color: Colors.white,),
      ),
     drawer: Drawer(
        backgroundColor: const Color(0xFF26345D),
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            UserAccountsDrawerHeader(
              decoration: const BoxDecoration(color: Colors.white),
              accountName: Text(
                'Hello, ${_userData?['firstName'] ?? ''} :)',
                style: const TextStyle(color: Color(0xFF141E46)),
              ),
              accountEmail: Text(''),
            ),
            ListTile(
              leading: const Icon(Icons.chat, color: Colors.white),
              title: const Text('Chat', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => ChatPage(userName: _userData?['firstName'] ?? '',)));
              },
            ),
            ListTile(
              leading: const Icon(Icons.history, color: Colors.white),
              title: const Text('History', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => HistoryPage()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.more_horiz, color: Colors.white),
              title: const Text('More', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
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
      body: _isLoading ? const Center(child: CircularProgressIndicator()):
      Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          Divider(color: Colors.grey[700]),
          Row(
        children: [
        GestureDetector(
        onTap: _pickImage,
          child: CircleAvatar(
            radius: 50,
            backgroundColor: Colors.grey,
            backgroundImage: _image != null ? FileImage(_image!) : null,
            child: _image == null
                ? Text(
              "${_userData?['firstName']?.substring(0, 1).toUpperCase() ?? ''}${_userData?['lastName']?.substring(0, 1).toUpperCase() ?? ''}",
              style: const TextStyle(
                fontSize: 40,
                color: Colors.white,
              ),
            )
                : null,
          ),
        ),
        SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_auth.currentUser?.email ?? '', style: TextStyle(color: Colors.grey[300], fontSize: 16)),
            SizedBox(height: 4),
            GestureDetector(
              onTap: () async {
                String? newPhoneNum = await showDialog<String>(
                  context: context,
                  builder: (context) {
                    String tempPhoneNum = phoneNum;
                    return AlertDialog(
                      title: Text("Enter Phone Number"),
                      content: TextField(
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(hintText: "Phone number"),
                        onChanged: (value) {
                          tempPhoneNum = value;
                        },
                      ),
                      actions: <Widget>[
                        TextButton(
                          onPressed: () => Navigator.pop(context, null),
                          child: Text("Cancel"),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, tempPhoneNum),
                          child: Text("Save"),
                        ),
                      ],
                    );
                  },
                );
                if (newPhoneNum != null && newPhoneNum.isNotEmpty) {
                  final isVaildPhone = RegExp(r'^\+?[0-9]{10,15}$').hasMatch(newPhoneNum);
                 if(isVaildPhone){
                   await _updatePhoneNum(newPhoneNum);
                 }else{
                   ScaffoldMessenger.of(context).showSnackBar(
                       const SnackBar(content: Text('Invalid phone number format!')),);
                 }
                }
              },
              child: Row(
                children: [
                  Icon(Icons.edit_outlined, color: Colors.grey[700],),
                  SizedBox(width: 4,),
                  Text(phoneNum.isNotEmpty ? phoneNum : "Phone Number", style: TextStyle(color: Colors.grey[700], fontSize: 16),)
                ],
              ),
            ),
          ],
        ),
        ],
          ),
       SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ProfileInfoField(label: _userData?['firstName'] ?? 'First Name'),
              ProfileInfoField(label: _userData?['lastName'] ?? 'Last Name'),
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12.0), // Adjust as needed
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ResetPasswordPage()),
                );
              },
              child: ProfileInfoField(label: "Change password"),
            ),
          ),

          SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ProfileInfoField(label: _userData?['gender'] ?? 'Gender'),
              ProfileInfoField(label: _userData?['dateOfBirth']?.toString() ?? 'Age'),
            ],
          ),

          Spacer(),
          Divider(color: Colors.grey[700]),
          ListTile(
            leading: Icon(Icons.support_agent_outlined, color: Colors.grey),
            title: Text("Contact and support", style: TextStyle(color: Colors.grey)),
            onTap: () {
            showDialog(
              context: context,
              builder: (BuildContext context){
               return AlertDialog(
                 backgroundColor: Colors.white60,
                 title: Text("Contact Information"),
                 content: Column(
                   mainAxisSize: MainAxisSize.min,
                   crossAxisAlignment: CrossAxisAlignment.start,
                   children: [
                     ListTile(
                       leading: Icon(Icons.email_outlined, color: Colors.blueAccent[600],),
                       subtitle: Text("${adminEmail}", style: TextStyle(color: Colors.blueAccent[600]),),
                       onTap: () => _launchEmail(adminEmail),
                     ),

                     ListTile(
                       leading: Icon(Icons.phone_enabled_rounded, color: Colors.blueAccent[600],),
                       subtitle: Text("${adminPhoneNum.isNotEmpty ? adminPhoneNum : "Not available"}", style: TextStyle(fontSize: 16, color: Colors.blueAccent[600],)),
                       onTap: () {
                        if(adminPhoneNum.isNotEmpty){
                          _launchPhone(adminPhoneNum);
                        }
                      },
                    ),
                  ],
                ),
                actions: <Widget>[
                  TextButton(onPressed: (){Navigator.of(context).pop();},
                      child: Text("Close")),
                ],
              );
            },
            );
            },
          ),
        ],
      ),
    ),
    );
  }
}