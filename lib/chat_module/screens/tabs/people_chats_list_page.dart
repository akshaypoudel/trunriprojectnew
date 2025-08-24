import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/route_manager.dart';
import 'package:provider/provider.dart';
import 'package:trunriproject/chat_module/components/user_tiles.dart';
import 'package:trunriproject/chat_module/screens/chat_screen.dart';
import 'package:trunriproject/home/provider/location_data.dart';
import 'package:trunriproject/subscription/subscription_data.dart';
import 'package:trunriproject/subscription/subscription_screen.dart';

class PeopleChatsPage extends StatefulWidget {
  const PeopleChatsPage({super.key});

  @override
  State<PeopleChatsPage> createState() => _PeopleChatsPageState();
}

class _PeopleChatsPageState extends State<PeopleChatsPage>
    with AutomaticKeepAliveClientMixin {
  List<Map<String, dynamic>> friendsList = [];
  List<Map<String, dynamic>> addFriendsList = [];
  List<Map<String, dynamic>> receivedRequestsList = [];
  String? currentEmail;
  bool isLoading = false;
  List<String> friends = [];
  List<String> sentRequests = [];
  List<String> receivedRequests = [];

  @override
  void initState() {
    super.initState();
    isLoading = true;
    _loadChats();
  }

  Future<void> _loadChats() async {
    final provider = Provider.of<LocationData>(context, listen: false);
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      final meDoc =
          await FirebaseFirestore.instance.collection('User').doc(uid).get();
      currentEmail = meDoc.get('email');
      String currentCity = meDoc.get('city');

      final myFriends = meDoc.data()?['friends'] ?? [];
      final myRequests = meDoc.data()?['friendRequests'] ?? {};

      friends = List<String>.from(myFriends);
      sentRequests = List<String>.from(myRequests['sent'] ?? []);
      receivedRequests = List<String>.from(myRequests['received'] ?? []);

      final allUsers =
          await FirebaseFirestore.instance.collection('User').get();

      List<Map<String, dynamic>> tempFriends = [];
      List<Map<String, dynamic>> tempOthers = [];
      List<Map<String, dynamic>> tempReceived = [];

      if (allUsers.docs.isEmpty) {
        return;
      }

      for (var doc in allUsers.docs) {
        final email = doc['email'];
        final name = doc['name'];
        final userCity = doc['city'];

        if (email == currentEmail) continue;

        // if (userCity != currentCity) continue;

        final userMap = {
          'email': email,
          'name': name,
          'profile': doc['profile'] ?? '',
        };

        if (friends.contains(email)) {
          // Fetch last message & time
          String roomId = _getChatRoomId(currentEmail!, email);
          final messageSnapshot = await FirebaseFirestore.instance
              .collection('chat_rooms')
              .doc(roomId)
              .collection('messages')
              .orderBy('timestamp', descending: true)
              .limit(1)
              .get();

          String lastMessage = '';
          String lastMessageTime = '';
          Timestamp? timestamp;

          if (messageSnapshot.docs.isNotEmpty) {
            final msg = messageSnapshot.docs.first;
            lastMessage = msg['message'] ?? '';
            timestamp = msg['timestamp'];
            if (timestamp != null) {
              final dateTime = timestamp.toDate();
              lastMessageTime =
                  TimeOfDay.fromDateTime(dateTime).format(context);
            }
          }

          tempFriends.add({
            ...userMap,
            'relation': 'friend',
            'lastMessage': lastMessage,
            'lastMessageTime': lastMessageTime,
            'timestamp': timestamp, // Add this for sorting
          });
        } else if (sentRequests.contains(email)) {
          tempOthers.add({...userMap, 'relation': 'sent'});
        } else if (receivedRequests.contains(email)) {
          tempReceived.add({...userMap, 'relation': 'received'});
        } else {
          if (currentCity != userCity) continue;

          tempOthers.add({...userMap, 'relation': 'none'});
        }
      }

      // Sort by timestamp descending
      tempFriends.sort((a, b) {
        final tsA = a['timestamp'] as Timestamp?;
        final tsB = b['timestamp'] as Timestamp?;
        if (tsA == null && tsB == null) return 0;
        if (tsA == null) return 1;
        if (tsB == null) return -1;
        return tsB.compareTo(tsA);
      });

      // Remove timestamp from final display
      for (var friend in tempFriends) {
        friend.remove('timestamp');
      }

      setState(() {
        friendsList = tempFriends;
        addFriendsList = tempOthers;
        receivedRequestsList = tempReceived;
        isLoading = false;
      });
    } catch (e) {
      log('error in load chat === $e');
    }
  }

  String _getChatRoomId(String email1, String email2) {
    final emails = [email1, email2]..sort();
    return '${emails[0]}_${emails[1]}';
  }

  Future<void> _sendFriendRequest(String receiverEmail) async {
    final provider = Provider.of<SubscriptionData>(context, listen: false);
    if (!provider.isUserSubscribed) {
      _showSubscriptionDialog();
      return;
    }
    _showLoadingDialog();

    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      final meRef = FirebaseFirestore.instance.collection('User').doc(uid);

      final receiverSnap = await FirebaseFirestore.instance
          .collection('User')
          .where('email', isEqualTo: receiverEmail)
          .limit(1)
          .get();

      if (receiverSnap.docs.isEmpty) return;

      final receiverDoc = receiverSnap.docs.first;
      final receiverRef = receiverDoc.reference;

      await FirebaseFirestore.instance.runTransaction((tx) async {
        final meSnapshot = await tx.get(meRef);
        final receiverSnapshot = await tx.get(receiverRef);

        final myRequests =
            meSnapshot.get('friendRequests') ?? {'sent': [], 'received': []};
        final receiverRequests = receiverSnapshot.get('friendRequests') ??
            {'sent': [], 'received': []};

        final mySent = List<String>.from(myRequests['sent'] ?? []);
        final receiverReceived =
            List<String>.from(receiverRequests['received'] ?? []);

        if (!mySent.contains(receiverEmail)) mySent.add(receiverEmail);
        if (!receiverReceived.contains(currentEmail)) {
          receiverReceived.add(currentEmail!);
        }

        tx.update(meRef, {'friendRequests.sent': mySent});
        tx.update(receiverRef, {'friendRequests.received': receiverReceived});
      });

      setState(() {
        addFriendsList = addFriendsList.map((user) {
          if (user['email'] == receiverEmail) {
            return {...user, 'relation': 'sent'};
          }
          return user;
        }).toList();
      });
      sentRequests.add(receiverEmail);
    } catch (e) {
      log('sendFriendRequest error: $e');
    } finally {
      _hideLoadingDialog();
    }
  }

  Future<void> _acceptFriendRequest(String senderEmail) async {
    try {
      _showLoadingDialog();

      final uid = FirebaseAuth.instance.currentUser!.uid;
      final meRef = FirebaseFirestore.instance.collection('User').doc(uid);

      final senderSnap = await FirebaseFirestore.instance
          .collection('User')
          .where('email', isEqualTo: senderEmail)
          .limit(1)
          .get();

      if (senderSnap.docs.isEmpty) {
        Navigator.pop(context);
        return;
      }

      final senderDoc = senderSnap.docs.first;
      final senderRef = senderDoc.reference;
      final senderName = senderDoc['name'];
      final senderProfile = senderDoc['profile'] ?? '';

      await FirebaseFirestore.instance.runTransaction((tx) async {
        final meSnapshot = await tx.get(meRef);
        final senderSnapshot = await tx.get(senderRef);

        List<String> myFriends =
            List<String>.from(meSnapshot.get('friends') ?? []);
        List<String> senderFriends =
            List<String>.from(senderSnapshot.get('friends') ?? []);

        Map<String, dynamic> myRequests =
            meSnapshot.get('friendRequests') ?? {};
        Map<String, dynamic> senderRequests =
            senderSnapshot.get('friendRequests') ?? {};

        List<String> myReceived =
            List<String>.from(myRequests['received'] ?? []);
        List<String> senderSent =
            List<String>.from(senderRequests['sent'] ?? []);

        myFriends.add(senderEmail);
        senderFriends.add(currentEmail!);

        myReceived.remove(senderEmail);
        senderSent.remove(currentEmail);

        tx.update(meRef, {
          'friends': myFriends,
          'friendRequests.received': myReceived,
        });

        tx.update(senderRef, {
          'friends': senderFriends,
          'friendRequests.sent': senderSent,
        });
      });

      // Add to top of friendsList with no message
      setState(() {
        friendsList.insert(0, {
          'email': senderEmail,
          'name': senderName,
          'profile': senderProfile,
          'relation': 'friend',
          'lastMessage': '',
          'lastMessageTime': '',
        });

        // Remove from friend request UI
        receivedRequestsList.removeWhere((u) => u['email'] == senderEmail);
        receivedRequests.remove(senderEmail);
      });

      Navigator.pop(context);
    } catch (e) {
      Navigator.pop(context);
      log('error accepting friend request === $e');
    }
  }

  Future<void> _declineFriendRequest(String senderEmail) async {
    _showLoadingDialog();

    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      final meRef = FirebaseFirestore.instance.collection('User').doc(uid);

      final senderSnap = await FirebaseFirestore.instance
          .collection('User')
          .where('email', isEqualTo: senderEmail)
          .limit(1)
          .get();

      if (senderSnap.docs.isEmpty) {
        setState(() => isLoading = false);
        return;
      }

      final senderDoc = senderSnap.docs.first;
      final senderRef = senderDoc.reference;

      await FirebaseFirestore.instance.runTransaction((tx) async {
        final meSnapshot = await tx.get(meRef);
        final senderSnapshot = await tx.get(senderRef);

        Map<String, dynamic> myRequests =
            meSnapshot.get('friendRequests') ?? {};
        Map<String, dynamic> senderRequests =
            senderSnapshot.get('friendRequests') ?? {};

        List<String> myReceived =
            List<String>.from(myRequests['received'] ?? []);
        List<String> senderSent =
            List<String>.from(senderRequests['sent'] ?? []);

        myReceived.remove(senderEmail);
        senderSent.remove(currentEmail);

        tx.update(meRef, {'friendRequests.received': myReceived});
        tx.update(senderRef, {'friendRequests.sent': senderSent});
      });

      // Update UI locally
      final declinedUser = receivedRequestsList.firstWhere(
        (u) => u['email'] == senderEmail,
        orElse: () => {},
      );

      setState(() {
        receivedRequestsList.removeWhere((u) => u['email'] == senderEmail);
        receivedRequests.remove(senderEmail);

        if (declinedUser.isNotEmpty) {
          addFriendsList.add({
            ...declinedUser,
            'relation': 'none',
          });
        }

        //isLoading = false; // Hide loading indicator
      });
    } catch (e) {
      log('error === $e');
    } finally {
      _hideLoadingDialog();
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    setState(() {
      // log('friend request = $receivedRequestsList');
    });
    return Scaffold(
      backgroundColor: Colors.white,
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadChats,
              backgroundColor: Colors.white,
              color: Colors.deepOrange,
              child: receivedRequestsList.isEmpty &&
                      friendsList.isEmpty &&
                      addFriendsList.isEmpty
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: const [
                        SizedBox(height: 200),
                        Center(
                          child: Text(
                            'No Person Found in your Area',
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                      ],
                    )
                  : ListView(
                      children: [
                        if (receivedRequestsList.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Row(
                              children: [
                                const Text(
                                  'Friend Requests',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  ' (${receivedRequestsList.length})',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ...receivedRequestsList.map(
                          (user) => UserTiles(
                            chatType: 'user',
                            userName: user['name'],
                            lastMessage: 'Sent you a friend request',
                            lastMessageTime: '',
                            imageUrl: user['profile'],
                            status: 'received',
                            onAcceptRequest: () => _acceptFriendRequest(
                              user['email'],
                            ),
                            onDeclineRequest: () => _declineFriendRequest(
                              user['email'],
                            ),
                          ),
                        ),
                        if (friendsList.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Row(
                              children: [
                                const Text(
                                  'Friends',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  ' (${friendsList.length})',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ...friendsList.map(
                          (user) => UserTiles(
                            chatType: 'user',
                            userName: user['name'],
                            lastMessage: user['lastMessage'],
                            lastMessageTime: user['lastMessageTime'],
                            imageUrl: user['profile'],
                            status: 'friend',
                            onOpenChat: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ChatScreen(
                                    receiversName: user['name'],
                                    receiversID: user['email'],
                                    imageUrl: user['profile'],
                                  ),
                                ),
                              ).then((_) => _loadChats());
                            },
                          ),
                        ),
                        if (addFriendsList.isNotEmpty)
                          const Padding(
                            padding: EdgeInsets.all(12.0),
                            child: Text('Add Friends',
                                style: TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold)),
                          ),
                        ...addFriendsList.map(
                          (user) => UserTiles(
                            chatType: 'user',
                            userName: user['name'],
                            lastMessage: '',
                            lastMessageTime: '',
                            imageUrl: user['profile'],
                            status: user['relation'],
                            onSendFriendRequest: () {
                              if (user['relation'] == 'none') {
                                _sendFriendRequest(user['email']);
                              }
                            },
                          ),
                        ),
                      ],
                    ),
            ),
    );
  }

  @override
  bool get wantKeepAlive => true;

  void _showLoadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.3),
      builder: (_) => const Center(
        child: CircularProgressIndicator(
          color: Colors.deepOrangeAccent,
          semanticsLabel: 'Loading...',
        ),
      ),
    );
  }

  void _hideLoadingDialog() {
    Navigator.of(context, rootNavigator: true).pop();
  }

  void _showSubscriptionDialog({bool isGroup = false}) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Premium Icon or Image
              const Icon(Icons.lock_outline_rounded,
                  size: 48, color: Colors.deepOrange),

              const SizedBox(height: 12),

              // Title
              const Text(
                'Premium Feature',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),

              const SizedBox(height: 8),

              // Description
              (isGroup)
                  ? const Text(
                      'Creating Group is a premium feature.\nSubscribe now to unlock this and more!',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, color: Colors.black87),
                    )
                  : const Text(
                      'Adding friends is a premium feature.\nSubscribe now to unlock this and more!',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, color: Colors.black87),
                    ),

              const SizedBox(height: 16),

              // Feature Highlights
              const Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Icon(Icons.person_add_alt_1_rounded,
                          color: Colors.orange, size: 22),
                      SizedBox(width: 8),
                      Text('Send Friend Requests'),
                    ],
                  ),
                  SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Icon(Icons.group_add_sharp,
                          color: Colors.orange, size: 22),
                      SizedBox(width: 8),
                      Text('Create Groups with your friends'),
                    ],
                  ),
                  SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Icon(Icons.star_rounded, color: Colors.orange, size: 22),
                      SizedBox(width: 8),
                      Text('Post & Promote Listings'),
                    ],
                  ),
                  SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Icon(Icons.stars_sharp, color: Colors.orange, size: 22),
                      SizedBox(width: 8),
                      Text('And More...'),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Maybe Later'),
                  ),
                  // const SizedBox(width: 8),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.workspace_premium, size: 20),
                    label: const Text('Subscribe Now'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange.shade100,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                    ),
                    onPressed: () {
                      Navigator.of(context).pop();
                      Get.to(() => const SubscriptionScreen());
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
