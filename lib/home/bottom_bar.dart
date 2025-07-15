import 'package:flutter/material.dart';
import 'package:trunriproject/chat_module/screens/chat_list_screen.dart';
import 'package:trunriproject/profile/profileScreen.dart';
import 'explorScreen.dart';
import 'home_screen.dart';

class MyBottomNavBar extends StatefulWidget {
  const MyBottomNavBar({super.key});

  @override
  State<MyBottomNavBar> createState() => _MyBottomNavBarState();
}

class _MyBottomNavBarState extends State<MyBottomNavBar> {
  int myCurrentIndex = 0;
  List<Widget> pages = [
    const HomeScreen(),
    const ExplorScreen(),
    const ChatListScreen(),
    const ProfileScreen()
  ];

  @override
  void initState() {
    super.initState();
    // listenToIncomingMessages(FirebaseAuth.instance.currentUser!.uid);
  }

  // void listenToIncomingMessages(String currentUserEmail) {
  //   FirebaseFirestore.instance
  //       .collection('chat_rooms')
  //       .snapshots()
  //       .listen((snapshot) {
  //     for (final doc in snapshot.docs) {
  //       final chatRoomId = doc.id;

  //       // Check if current user is part of this chat room
  //       if (!chatRoomId.contains(currentUserEmail)) continue;

  //       FirebaseFirestore.instance
  //           .collection('chat_rooms')
  //           .doc(chatRoomId)
  //           .collection('messages')
  //           .orderBy('timestamp', descending: true)
  //           .limit(1)
  //           .snapshots()
  //           .listen((msgSnapshot) {
  //         if (msgSnapshot.docs.isEmpty) return;

  //         final data = msgSnapshot.docs.first.data();
  //         final receiverId = data['receiverId'];
  //         final senderId = data['senderId'];
  //         final message = data['message'];

  //         if (receiverId == currentUserEmail && senderId != currentUserEmail) {
  //           // Show local notification
  //           LocalNotificationService.showNotification(
  //               "New Message", message.toString());

  //           // Update badge count
  //           BadgeHelper.incrementBadge();
  //         }
  //       });
  //     }
  //   });
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      extendBody: true,
      body: IndexedStack(
        index: myCurrentIndex,
        children: pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.orange,
        unselectedItemColor: Colors.blueGrey,
        currentIndex: myCurrentIndex,
        onTap: (index) {
          setState(() {
            myCurrentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(
              Icons.home,
              size: 30,
            ),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: 'Search',
            activeIcon: Icon(
              Icons.search,
              size: 30,
            ),
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.message_outlined),
            activeIcon: Icon(
              Icons.message_rounded,
              size: 30,
            ),
            label: 'Messages',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_3_outlined),
            activeIcon: Icon(
              Icons.person_3,
              size: 30,
            ),
            label: 'Profile',
          ),
        ],
      ),
      // body: pages[myCurrentIndex],
    );
  }
}
