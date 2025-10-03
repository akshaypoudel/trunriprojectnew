import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:trunriproject/chat_module/screens/tabs/community_chat_page.dart';
import 'package:trunriproject/chat_module/screens/tabs/groups_chat_list_page.dart';
import 'package:trunriproject/chat_module/screens/tabs/inquiry_details_page.dart';
import 'package:trunriproject/chat_module/screens/tabs/people_chats_list_page.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key, this.index});
  final int? index;

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    _tabController = TabController(
        length: 4,
        vsync: this,
        initialIndex: (widget.index != null) ? widget.index! : 1);
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
                Tab(
                  icon: Icon(
                    FontAwesomeIcons.solidCircleQuestion,
                    size: 20,
                  ),
                  text: 'Inquiry',
                ),
                Tab(
                  icon: Icon(
                    MingCute.user_2_fill,
                    size: 20,
                  ),
                  text: 'People',
                ),
                Tab(
                  icon: Icon(
                    FontAwesomeIcons.users,
                    size: 20,
                  ),
                  text: 'Groups',
                ),
                Tab(
                  icon: Icon(
                    FontAwesome.comments_solid,
                    size: 20,
                  ),
                  text: 'Forum',
                ),
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
