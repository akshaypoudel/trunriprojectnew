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
import 'package:trunriproject/settings/string_extension.dart';
import 'package:trunriproject/subscription/subscription_data.dart';
import 'package:trunriproject/subscription/subscription_screen.dart';
import 'package:trunriproject/widgets/helper.dart';

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
  List<Map<String, dynamic>> homeTownFriendsList =
      []; // New list for hometown friends
  String? currentEmail;
  bool isLoading = false;
  List<String> friends = [];
  List<String> sentRequests = [];
  List<String> receivedRequests = [];

  static int friendRequestsCount = 2;

  String currentCity = '';
  String homeTownCity = '';

  @override
  void initState() {
    super.initState();
    isLoading = true;
    _loadChats();
  }

  Future<void> _loadChats() async {
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      final meDoc =
          await FirebaseFirestore.instance.collection('User').doc(uid).get();
      currentEmail = meDoc.get('email');
      currentCity = meDoc.get('city');
      homeTownCity = meDoc.get('hometown')['city'];

      final currentCityLower = currentCity.toString().toLowerCase();
      final homeTownCityLower = homeTownCity.toString().toLowerCase();

      friendRequestsCount = meDoc.data()?['friendRequestLimit'] as int? ?? 0;

      final myFriends = meDoc.data()?['friends'] ?? [];
      final myRequests = meDoc.data()?['friendRequests'] ?? {};

      friends = List<String>.from(myFriends);
      sentRequests = List<String>.from(myRequests['sent'] ?? []);
      receivedRequests = List<String>.from(myRequests['received'] ?? []);

      final allUsers =
          await FirebaseFirestore.instance.collection('User').get();

      List<Map<String, dynamic>> tempFriends = [];
      List<Map<String, dynamic>> tempOthers = []; // Add Friends - Same City
      List<Map<String, dynamic>> tempReceived = [];
      List<Map<String, dynamic>> tempHomeTownFriends =
          []; // HomeTown Friends - Same HomeTown

      if (allUsers.docs.isEmpty) {
        return;
      }

      for (var doc in allUsers.docs) {
        final email = doc['email'];
        final name = doc['name'];
        final profession = doc['profession'];
        final userHomeTownCity = doc['hometown']['city'];
        final userCity = doc['city'];

        final userCityLower = userCity.toString().toLowerCase();
        final userHomeTownCityLower = userHomeTownCity.toString().toLowerCase();

        if (email == currentEmail) continue;

        final userMap = {
          'email': email,
          'name': name,
          'profile': doc['profile'] ?? '',
          'profession': profession,
          'homeTownCity': userHomeTownCity,
          'userCity': userCity,
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
            'timestamp': timestamp,
          });
        } else if (sentRequests.contains(email)) {
          // Add to Add Friends if same city
          if (currentCityLower == userCityLower) {
            tempOthers.add({...userMap, 'relation': 'sent'});
          }
          // Add to HomeTown Friends if same hometown
          if (homeTownCityLower == userHomeTownCityLower) {
            tempHomeTownFriends.add({...userMap, 'relation': 'sent'});
          }
        } else if (receivedRequests.contains(email)) {
          tempReceived.add({...userMap, 'relation': 'received'});
        } else {
          // Add to Add Friends if same city (regardless of hometown)
          if (currentCityLower == userCityLower) {
            tempOthers.add({...userMap, 'relation': 'none'});
          }
          // Add to HomeTown Friends if same hometown (regardless of city)
          if (homeTownCityLower == userHomeTownCityLower) {
            tempHomeTownFriends.add({...userMap, 'relation': 'none'});
          }
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
        homeTownFriendsList = tempHomeTownFriends;
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
    if (!provider.isUserSubscribed && friendRequestsCount == 0) {
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

        if (!provider.isUserSubscribed) {
          friendRequestsCount--;
          tx.update(meRef, {
            'friendRequestLimit': friendRequestsCount,
          });
        }
      });

      setState(() {
        addFriendsList = addFriendsList.map((user) {
          if (user['email'] == receiverEmail) {
            return {...user, 'relation': 'sent'};
          }
          return user;
        }).toList();

        // Also update hometown friends list
        homeTownFriendsList = homeTownFriendsList.map((user) {
          if (user['email'] == receiverEmail) {
            return {...user, 'relation': 'sent'};
          }
          return user;
        }).toList();
      });
      sentRequests.add(receiverEmail);
    } catch (e) {
      log('sendFriendRequest error: $e');
      showSnackBar(context, 'Can\'t send friend request');
    } finally {
      _hideLoadingDialog();
      if (!provider.isUserSubscribed) {
        _showFreeRequestsWarningDialog(friendRequestsCount);
      }
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
      final senderProfession = senderDoc['profession'];
      final senderHomeTownCity = senderDoc['hometown']['city'];
      final senderCity = senderDoc['city'];
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

      setState(() {
        friendsList.insert(0, {
          'email': senderEmail,
          'name': senderName,
          'profession': senderProfession,
          'city': senderCity,
          'homeTownCity': senderHomeTownCity,
          'profile': senderProfile,
          'relation': 'friend',
          'lastMessage': '',
          'lastMessageTime': '',
        });

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
      });
    } catch (e) {
      log('error === $e');
    } finally {
      _hideLoadingDialog();
    }
  }

  Future<void> _unfriendUser(String userEmail) async {
    _showLoadingDialog();

    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      final meRef = FirebaseFirestore.instance.collection('User').doc(uid);

      final userSnap = await FirebaseFirestore.instance
          .collection('User')
          .where('email', isEqualTo: userEmail)
          .limit(1)
          .get();

      if (userSnap.docs.isEmpty) {
        _hideLoadingDialog();
        return;
      }

      final userDoc = userSnap.docs.first;
      final userRef = userDoc.reference;

      await FirebaseFirestore.instance.runTransaction((tx) async {
        final meSnapshot = await tx.get(meRef);
        final userSnapshot = await tx.get(userRef);

        List<String> myFriends =
            List<String>.from(meSnapshot.get('friends') ?? []);
        List<String> userFriends =
            List<String>.from(userSnapshot.get('friends') ?? []);

        myFriends.remove(userEmail);
        userFriends.remove(currentEmail);

        tx.update(meRef, {'friends': myFriends});
        tx.update(userRef, {'friends': userFriends});
      });

      setState(() {
        final unfriendedUser = friendsList.firstWhere(
          (user) => user['email'] == userEmail,
          orElse: () => {},
        );

        friendsList.removeWhere((user) => user['email'] == userEmail);
        friends.remove(userEmail);

        if (unfriendedUser.isNotEmpty) {
          addFriendsList.add({
            ...unfriendedUser,
            'relation': 'none',
          });
        }
      });

      _hideLoadingDialog();
      showSnackBar(context, 'User unfriended successfully');
    } catch (e) {
      _hideLoadingDialog();
      log('error unfriending user: $e');
      showSnackBar(context, 'Failed to unfriend user');
    }
  }

  Future<void> _blockUser(String userEmail) async {
    _showLoadingDialog();

    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      final meRef = FirebaseFirestore.instance.collection('User').doc(uid);

      final userSnap = await FirebaseFirestore.instance
          .collection('User')
          .where('email', isEqualTo: userEmail)
          .limit(1)
          .get();

      if (userSnap.docs.isEmpty) {
        _hideLoadingDialog();
        return;
      }

      final userDoc = userSnap.docs.first;
      final userRef = userDoc.reference;

      await FirebaseFirestore.instance.runTransaction((tx) async {
        final meSnapshot = await tx.get(meRef);
        final userSnapshot = await tx.get(userRef);

        List<String> blockedUsers =
            List<String>.from(meSnapshot.data()?['blockedUsers'] ?? []);
        List<String> myFriends =
            List<String>.from(meSnapshot.get('friends') ?? []);
        Map<String, dynamic> myRequests =
            meSnapshot.get('friendRequests') ?? {'sent': [], 'received': []};

        List<String> theirFriends =
            List<String>.from(userSnapshot.get('friends') ?? []);
        Map<String, dynamic> theirRequests =
            userSnapshot.get('friendRequests') ?? {'sent': [], 'received': []};

        if (!blockedUsers.contains(userEmail)) {
          blockedUsers.add(userEmail);
        }

        myFriends.remove(userEmail);
        theirFriends.remove(currentEmail);

        List<String> mySent = List<String>.from(myRequests['sent'] ?? []);
        List<String> myReceived =
            List<String>.from(myRequests['received'] ?? []);
        List<String> theirSent = List<String>.from(theirRequests['sent'] ?? []);
        List<String> theirReceived =
            List<String>.from(theirRequests['received'] ?? []);

        mySent.remove(userEmail);
        myReceived.remove(userEmail);
        theirSent.remove(currentEmail);
        theirReceived.remove(currentEmail);

        tx.update(meRef, {
          'blockedUsers': blockedUsers,
          'friends': myFriends,
          'friendRequests': {
            'sent': mySent,
            'received': myReceived,
          },
        });

        tx.update(userRef, {
          'friends': theirFriends,
          'friendRequests': {
            'sent': theirSent,
            'received': theirReceived,
          },
        });
      });

      setState(() {
        friendsList.removeWhere((user) => user['email'] == userEmail);
        addFriendsList.removeWhere((user) => user['email'] == userEmail);
        receivedRequestsList.removeWhere((user) => user['email'] == userEmail);
        homeTownFriendsList.removeWhere((user) => user['email'] == userEmail);

        friends.remove(userEmail);
        sentRequests.remove(userEmail);
        receivedRequests.remove(userEmail);
      });

      _hideLoadingDialog();
      showSnackBar(context, 'User blocked successfully');
    } catch (e) {
      _hideLoadingDialog();
      log('error blocking user: $e');
      showSnackBar(context, 'Failed to block user');
    }
  }

  Future<void> _cancelFriendRequest(String receiverEmail) async {
    _showLoadingDialog();

    try {
      final provider = Provider.of<SubscriptionData>(context, listen: false);

      final uid = FirebaseAuth.instance.currentUser!.uid;
      final meRef = FirebaseFirestore.instance.collection('User').doc(uid);

      final receiverSnap = await FirebaseFirestore.instance
          .collection('User')
          .where('email', isEqualTo: receiverEmail)
          .limit(1)
          .get();

      if (receiverSnap.docs.isEmpty) {
        _hideLoadingDialog();
        return;
      }

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

        mySent.remove(receiverEmail);
        receiverReceived.remove(currentEmail);

        tx.update(meRef, {'friendRequests.sent': mySent});
        tx.update(receiverRef, {'friendRequests.received': receiverReceived});

        if (!provider.isUserSubscribed) {
          friendRequestsCount++;
          tx.update(meRef, {
            'friendRequestLimit': friendRequestsCount,
          });
        }
      });

      setState(() {
        addFriendsList = addFriendsList.map((user) {
          if (user['email'] == receiverEmail) {
            return {...user, 'relation': 'none'};
          }
          return user;
        }).toList();

        // Also update hometown friends list
        homeTownFriendsList = homeTownFriendsList.map((user) {
          if (user['email'] == receiverEmail) {
            return {...user, 'relation': 'none'};
          }
          return user;
        }).toList();

        sentRequests.remove(receiverEmail);
      });

      _hideLoadingDialog();
      showSnackBar(context, 'Friend request cancelled');
    } catch (e) {
      _hideLoadingDialog();
      log('error cancelling request: $e');
      showSnackBar(context, 'Failed to cancel request');
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final provider = Provider.of<SubscriptionData>(context);

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
                      addFriendsList.isEmpty &&
                      homeTownFriendsList.isEmpty
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        const SizedBox(height: 120),
                        Column(
                          children: [
                            Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                color: Colors.orange.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.person_2_outlined,
                                size: 50,
                                color: Colors.orange,
                              ),
                            ),
                            const SizedBox(height: 24),
                            const Text(
                              'No People Found',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 40),
                              child: Text(
                                'No people found in your hometown. Try refreshing or check back later.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton.icon(
                              onPressed: () => _loadChats(),
                              icon: const Icon(Icons.refresh),
                              label: const Text('Refresh'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 24, vertical: 12),
                              ),
                            ),
                          ],
                        ),
                      ],
                    )
                  : ListView(
                      padding: const EdgeInsets.all(0),
                      children: [
                        Container(
                          margin: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Colors.orange[400]!,
                                Colors.orange[600]!,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.orange.withValues(alpha: 0.3),
                                blurRadius: 15,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(25),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.location_on,
                                        color: Colors.white, size: 20),
                                    const SizedBox(width: 6),
                                    Text(
                                      "You are in $currentCity, Australia",
                                      style: const TextStyle(
                                          color: Colors.white, fontSize: 14),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  "${homeTownCity.capitalizeFirst()} NRIs in Australia",
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
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
                                    color: Colors.red,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.orange,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    '${receivedRequestsList.length}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
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
                            shortBio:
                                '${(user['profession'] ?? '').toString().capitalizeFirst()} in \n${(user['userCity'] ?? '').toString().capitalizeFirst()} from ${(user['homeTownCity'] ?? '').toString().capitalizeFirst()}',
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
                                    color: Colors.green,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.green,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    '${friendsList.length}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
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
                            shortBio:
                                '${(user['profession'] ?? '').toString().capitalizeFirst()} in \n${(user['userCity'] ?? '').toString().capitalizeFirst()} from ${(user['homeTownCity'] ?? '').toString().capitalizeFirst()}',
                            lastMessageTime: user['lastMessageTime'],
                            imageUrl: user['profile'],
                            status: 'friend',
                            onUnfriend: () =>
                                _unfriendUser(user['email'] ?? ''),
                            onBlock: () => _blockUser(user['email'] ?? ''),
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
                            child: Text(
                              'People Near You',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.orange,
                              ),
                            ),
                          ),
                        ...addFriendsList.map(
                          (user) => UserTiles(
                            chatType: 'user',
                            userName: user['name'],
                            lastMessage: '',
                            lastMessageTime: '',
                            imageUrl: user['profile'],
                            status: user['relation'],
                            shortBio:
                                '${(user['profession'] ?? '').toString().capitalizeFirst()} in \n${(user['userCity'] ?? '').toString().capitalizeFirst()} from ${(user['homeTownCity'] ?? '').toString().capitalizeFirst()}',
                            onSendFriendRequest: () {
                              if (user['relation'] == 'none') {
                                _sendFriendRequest(user['email']);
                              }
                            },
                            onCancelRequest: () =>
                                _cancelFriendRequest(user['email']),
                            onBlock: () => _blockUser(user['email']),
                          ),
                        ),

                        // New Hometown Friends Section
                        if (!provider.isUserSubscribed &&
                            homeTownFriendsList.isNotEmpty)
                          Container(
                            margin: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Colors.grey[100]!,
                                  Colors.grey[200]!,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                  color: Colors.orange.withValues(alpha: 0.3)),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.orange
                                              .withValues(alpha: 0.1),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: const Icon(
                                          Icons.lock,
                                          color: Colors.orange,
                                          size: 24,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                const Text(
                                                  'Hometown Friends',
                                                  style: TextStyle(
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.black87,
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Container(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 8,
                                                      vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: Colors.deepPurple,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            12),
                                                  ),
                                                  child: Text(
                                                    '${homeTownFriendsList.length}',
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 14,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              'Connect with people from ${homeTownCity.capitalizeFirst()}',
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: Colors.grey[600],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  const Text(
                                    '🔓 Unlock this feature to connect with people from your hometown who are now living across Australia!',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.black87,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 16),
                                  ElevatedButton.icon(
                                    onPressed: () => Get.to(
                                        () => const SubscriptionScreen()),
                                    icon: const Icon(Icons.workspace_premium,
                                        size: 20),
                                    label: const Text('Unlock Premium'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.orange,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 24, vertical: 12),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                        // Show actual hometown friends for subscribed users
                        if (provider.isUserSubscribed &&
                            homeTownFriendsList.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Row(
                              children: [
                                const Icon(Icons.home_outlined,
                                    color: Colors.deepPurple, size: 22),
                                const SizedBox(width: 8),
                                const Text(
                                  'Hometown Friends',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.deepPurple,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.deepPurple,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    '${homeTownFriendsList.length}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        if (provider.isUserSubscribed)
                          ...homeTownFriendsList.map(
                            (user) => UserTiles(
                              chatType: 'user',
                              userName: user['name'],
                              lastMessage: '',
                              lastMessageTime: '',
                              imageUrl: user['profile'],
                              status: user['relation'],
                              shortBio:
                                  '${(user['profession'] ?? '').toString().capitalizeFirst()} in \n${(user['userCity'] ?? '').toString().capitalizeFirst()} from ${(user['homeTownCity'] ?? '').toString().capitalizeFirst()}',
                              onSendFriendRequest: () {
                                if (user['relation'] == 'none') {
                                  _sendFriendRequest(user['email']);
                                }
                              },
                              onCancelRequest: () =>
                                  _cancelFriendRequest(user['email']),
                              onBlock: () => _blockUser(user['email']),
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
              const Icon(Icons.lock_outline_rounded,
                  size: 48, color: Colors.deepOrange),
              const SizedBox(height: 12),
              const Text(
                'Premium Feature',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              (isGroup)
                  ? const Text(
                      'Creating Group is a premium feature.\nSubscribe now to unlock this and more!',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, color: Colors.black87),
                    )
                  : const Text(
                      'Your free friend requests limit is reached.\nSubscribe now to get unlimited requests and more!',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, color: Colors.black87),
                    ),
              const SizedBox(height: 16),
              const Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Icon(Icons.person_add_alt_1_rounded,
                          color: Colors.orange, size: 22),
                      SizedBox(width: 8),
                      Text('Send Unlimited Friend Requests'),
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
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Maybe Later'),
                  ),
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

  void _showFreeRequestsWarningDialog(int remainingRequests) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.warning_amber_rounded,
                  size: 32,
                  color: Colors.orange,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Friend Request Sent!',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: const TextStyle(fontSize: 16, color: Colors.black87),
                  children: [
                    (remainingRequests == 0)
                        ? const TextSpan(text: 'You have ')
                        : const TextSpan(text: 'You have only '),
                    TextSpan(
                      text: '$remainingRequests',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                      ),
                    ),
                    const TextSpan(text: ' free friend request'),
                    TextSpan(text: remainingRequests == 1 ? '' : 's'),
                    const TextSpan(text: ' remaining.\n\n'),
                    const TextSpan(
                      text: 'Subscribe now to get unlimited requests!',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Maybe Later'),
                  ),
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
