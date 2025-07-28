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
    _tabController = TabController(length: 4, vsync: this);
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
      appBar: AppBar(
        title: const Text('Messages'),
        backgroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.orange,
          labelColor: Colors.orange,
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(text: 'Inquiry'),
            Tab(text: 'People'),
            Tab(text: 'Groups'),
            Tab(text: 'Community'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        physics: const BouncingScrollPhysics(),
        children: const [
          InquiryDetailsPage(),
          PeopleChatsPage(),
          GroupsChatPage(),
          CommunityPage(),
        ],
      ),
    );
  }
}
