import 'package:flutter/material.dart';
import 'package:trunriproject/chat_module/screens/tabs/community_chat_page.dart';
import 'package:trunriproject/chat_module/screens/tabs/groups_chat_list_page.dart';
import 'package:trunriproject/chat_module/screens/tabs/inquiry_details_page.dart';
import 'package:trunriproject/chat_module/screens/tabs/people_chats_list_page.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    _tabController = TabController(length: 4, vsync: this, initialIndex: 1);
    super.initState();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            TabBar(
              controller: _tabController,
              indicatorColor: Colors.orange,
              labelColor: Colors.orange,
              unselectedLabelColor: Colors.grey,
              tabs: const [
                Tab(icon: Icon(Icons.question_answer), text: 'Inquiry'),
                Tab(icon: Icon(Icons.person_2_rounded), text: 'People'),
                Tab(icon: Icon(Icons.people_alt_sharp), text: 'Groups'),
                Tab(icon: Icon(Icons.forum), text: 'Forum'),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                physics: const BouncingScrollPhysics(),
                children: const [
                  InquiryDetailsPage(),
                  PeopleChatsPage(),
                  GroupsChatPage(),
                  CommunityPage(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
