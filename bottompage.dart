import 'package:flutter/material.dart';
import 'package:my_app/bottom_screens/add_contacts.dart';
import 'package:my_app/bottom_screens/dialer.dart';
import 'package:my_app/bottom_screens/profile_page.dart';
import 'package:my_app/bottom_screens/review_page.dart';
import 'package:my_app/home.dart';

class BottomPage extends StatefulWidget {
  const BottomPage({super.key});

  @override
  State<BottomPage> createState() => _BottomPageState();
}

class _BottomPageState extends State<BottomPage> {
  int currentIndex = 0;
  List<Widget> pages = [
    UnifiedHomePage(),
    AddContactsPage(),
    Dialer(),
    CommunityPage(),
    ProfilePage(),
  ];

  onTapped(int index) {
    setState(() {
      currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: pages[currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        type: BottomNavigationBarType.fixed,
        onTap: onTapped,
        items: [
          BottomNavigationBarItem(label: 'Home', icon: Icon(Icons.home,)),
          BottomNavigationBarItem(label: 'Contacts', icon: Icon(Icons.contacts,)),
          BottomNavigationBarItem(label: 'Emergency', icon: Icon(Icons.policy,)),
          BottomNavigationBarItem(label: 'Community', icon: Icon(Icons.question_answer,)),
          BottomNavigationBarItem(label: 'Profile', icon: Icon(Icons.person,)),
        ],
      ),
    );
  }
}
