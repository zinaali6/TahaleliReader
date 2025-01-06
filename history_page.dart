import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'chat_page.dart';
import 'pdf_viewer_page.dart';
import 'image_viewer_page.dart';
import 'welcome_page.dart';
import 'profile_page.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  _HistoryPageState createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final TextEditingController _pinController = TextEditingController();
  bool _isAuthenticated = false;
  bool _isLoading = true;
  List<Map<String, dynamic>> _history = [];
  Map<String, dynamic>? _userData;

  @override
  void initState() {
    super.initState();
    _checkPin();
    _fetchUserData();
  }

  /// Check if a PIN is set and prompt the user to authenticate
  Future<void> _checkPin() async {
    String? storedPin = await _secureStorage.read(key: 'userPin');

    if (storedPin == null) {
      // No PIN set, prompt the user to set one
      await _setPin();
    } else {
      // PIN is set, prompt the user to enter it
      await _promptPin();
    }
  }

  /// Set a 4-digit PIN
  Future<void> _setPin() async {
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Set a 4-digit PIN'),
          content: TextField(
            controller: _pinController,
            maxLength: 4,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(hintText: 'Enter a 4-digit PIN'),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                if (_pinController.text.length == 4) {
                  await _secureStorage.write(key: 'userPin', value: _pinController.text);
                  _pinController.clear();
                  Navigator.pop(context);
                  setState(() {
                    _isAuthenticated = true;
                  });
                  _fetchHistory();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('PIN must be 4 digits')),
                  );
                }
              },
              child: const Text('Set PIN'),
            ),
          ],
        );
      },
    );
  }

  /// Prompt the user to enter their PIN
  Future<void> _promptPin() async {
    String? storedPin = await _secureStorage.read(key: 'userPin');

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Enter your PIN'),
          content: TextField(
            controller: _pinController,
            maxLength: 4,
            obscureText: true,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(hintText: 'Enter your 4-digit PIN'),
          ),
          actions: [
            TextButton(
              onPressed: () {
                if (_pinController.text == storedPin) {
                  setState(() {
                    _isAuthenticated = true;
                  });
                  _pinController.clear();
                  Navigator.pop(context);
                  _fetchHistory();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Incorrect PIN')),
                  );
                }
              },
              child: const Text('Verify'),
            ),
          ],
        );
      },
    );
  }

  /// Fetch the user's history from Firestore
  Future<void> _fetchHistory() async {
    try {
      String? userId = _auth.currentUser?.uid;
      if (userId == null) return;

      QuerySnapshot snapshot = await _firestore
          .collection('messages')
          .where('userId', isEqualTo: userId)
          .where('type', whereIn: ['image', 'file']) // Filter by type
          .orderBy('createdAt', descending: true)
          .get();

      setState(() {
        _history = snapshot.docs.map((doc) {
          return {
            'type': doc['type'] ?? 'Unknown', // Default to 'Unknown' if 'type' is missing
            'content': doc['content'] ?? '', // Default to empty string if 'content' is missing
            'fileName': doc['type'] == 'file' ? doc['fileName'] : 'Image', // Default to 'Image' for pictures
            'createdAt': doc['createdAt'] ?? FieldValue.serverTimestamp(), // Default to server timestamp if 'createdAt' is missing
          };
        }).toList();
        _isLoading = false;
      });
    } catch (e) {
      print("Error fetching history: $e");
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Open the item (image or PDF)
  void _openItem(Map<String, dynamic> item) {
    final type = item['type'];
    final content = item['content'];

    if (type == 'image') {
      // Open Image Viewer
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ImageViewerPage(imageUrl: content),
        ),
      );
    } else if (type == 'file') {
      // Open PDF Viewer
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PDFViewerPage(pdfUrl: content),
        ),
      );
    } else {
      // Handle unsupported types
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unsupported file type')),
      );
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
                Navigator.pop(context);
              },
              child: const Text('No'),
            ),
            TextButton(
              onPressed: () async {
                // Clear local messages
                setState(() {

                });

                String? userId = _auth.currentUser?.uid;
                if (userId != null) {
                  try {
                    final userMessagesQuery = await _firestore
                        .collection('messages')
                        .where('userId', isEqualTo: userId)
                        .get();

                    for (var doc in userMessagesQuery.docs) {
                      await _firestore.collection('messages').doc(doc.id).delete();
                    }
                  } catch (e) {
                    print("Error deleting user messages: $e");
                  }
                }

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

  @override
  Widget build(BuildContext context) {
    if (!_isAuthenticated) {
      return Scaffold(
        backgroundColor: const Color(0xFF141E46),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock, color: Colors.white, size: 50),
              const SizedBox(height: 16),
              const Text(
                'Authentication Required',
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _promptPin,
                child: const Text('Enter PIN'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
        backgroundColor: const Color(0xFF141E46),
        appBar: AppBar(
          backgroundColor: const Color(0xFF141E46),
          title: const Text('History', style: TextStyle(color: Colors.white)),
          iconTheme: const IconThemeData(
            color: Colors.white,
          ),
        ), drawer: Drawer(
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
            onTap: () {Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ChatPage(
                  userName: _userData?['firstName'] ?? '',
                ),
              ),
            );
            },
          ),
          ListTile(
            leading: const Icon(Icons.history, color: Colors.white),
            title: const Text('History', style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.pop(context);
              // Navigate to the History Page
            },
          ),
          ListTile(
            leading: const Icon(Icons.more_horiz, color: Colors.white),
            title: const Text('More', style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => ProfilePage()));
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
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _history.isEmpty
            ? const Center(
          child: Text(
            'No history available',
            style: TextStyle(color: Colors.grey),
          ),
        )
            : ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _history.length,
          itemBuilder: (context, index) {
            final item = _history[index];
            return Card(
              color: const Color(0xFF1C2A4B),
              child: ListTile(
                leading: item['type'] == 'image'
                    ? Image.network(
                  item['content'],
                  width: 50,
                  height: 50,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                  const Icon(Icons.broken_image, color: Colors.white),
                )
                    : const Icon(Icons.picture_as_pdf, color: Colors.red),
                title: Text(
                  item['fileName'] ?? 'Test ${index + 1}', // Default to 'Test' if 'fileName' is missing
                  style: const TextStyle(color: Colors.white),
                ),
                subtitle: Text(
                  item['createdAt'] != null
                      ? (item['createdAt'] as Timestamp).toDate().toString()
                      : 'Unknown',
                  style: const TextStyle(color: Colors.grey),
                ),
                onTap: () => _openItem(item),
              ),
            );
          },
        )
    );
  }
}