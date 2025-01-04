import 'package:exam_guide/global.dart';
import 'package:exam_guide/student_screens/tabPages/CourseTab.dart';
import 'package:exam_guide/student_screens/tabPages/ExamTab.dart';
import 'package:exam_guide/student_screens/tabPages/HomeTab.dart';
import 'package:exam_guide/student_screens/tabPages/ReportTab.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../security/LoginScreen.dart';

class StudentMainScreen extends StatefulWidget {
  const StudentMainScreen({Key? key}) : super(key: key);

  @override
  _StudentMainScreenState createState() => _StudentMainScreenState();
}

class _StudentMainScreenState extends State<StudentMainScreen> {
  int _selectedIndex = 0;
  Map<String, dynamic>? userData;

  final List<Widget> _pages = [
    HomeTab(),
    CourseTab(),
    ExamTab(),
    ReportTab()
  ];

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final response = await http.get(
        Uri.parse('$api/user/getUserById/$globalUserId'),
      );

      if (response.statusCode == 200) {
        setState(() {
          userData = json.decode(response.body);
        });
      }
    } catch (e) {
      print('Error loading user data: $e');
    }
  }

  void _logout() {
    globalUserId = null;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (context) => const LoginScreen(),
      ),
          (route) => false,  // This removes all previous routes
    );

  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Student Dashboard"),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.blue,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 30,
                    child: Text(
                      userData?['fname']?.substring(0, 1).toUpperCase() ?? '',
                      style: TextStyle(fontSize: 24),
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    '${userData?['fname'] ?? ''} ${userData?['lname'] ?? ''}',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                    ),
                  ),
                  Text(
                    userData?['email'] ?? '',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: Icon(Icons.person),
              title: Text('Profile'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.settings),
              title: Text('Settings'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.logout),
              title: Text('Logout'),
              onTap: _logout,
            ),
          ],
        ),
      ),
      body: AnimatedSwitcher(
        duration: Duration(milliseconds: 300),
        child: _pages[_selectedIndex],
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.blueAccent,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.book),
            label: 'Courses',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.event_note),
            label: 'Exam Holes',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: 'Reports',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}