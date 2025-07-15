import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Real-time chat service for parent-driver and parent-school communication
class ChatService {
  static ChatService? _instance;
  static ChatService get instance => _instance ??= ChatService._();

  ChatService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Get chat contacts for the current user
  Stream<List<ChatContact>> getChatContactsStream() {
    final user = _auth.currentUser;
    if (user == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection('chat_contacts')
        .where('userId', isEqualTo: user.uid)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return ChatContact(
          id: doc.id,
          name: data['name'] ?? 'Unknown',
          type: data['type'] ?? 'driver',
          lastMessage: data['lastMessage'] ?? '',
          lastMessageTime: data['lastMessageTime'] != null
              ? (data['lastMessageTime'] as Timestamp).toDate()
              : DateTime.now(),
          unreadCount: data['unreadCount'] ?? 0,
          isOnline: data['isOnline'] ?? false,
        );
      }).toList();
    });
  }

  /// Get messages for a specific chat
  Stream<List<ChatMessage>> getMessagesStream(String chatId) {
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .limit(100)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return ChatMessage(
          id: doc.id,
          senderId: data['senderId'] ?? '',
          senderName: data['senderName'] ?? 'Unknown',
          message: data['message'] ?? '',
          timestamp: data['timestamp'] != null
              ? (data['timestamp'] as Timestamp).toDate()
              : DateTime.now(),
          isFromMe: data['senderId'] == _auth.currentUser?.uid,
          messageType: _parseMessageType(data['messageType']),
          locationData: data['locationData'],
        );
      }).toList();
    });
  }

  /// Send a text message
  Future<void> sendMessage({
    required String chatId,
    required String message,
    required String recipientId,
    required String recipientName,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    try {
      // Add message to chat
      await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .add({
        'senderId': user.uid,
        'senderName': user.displayName ?? 'Unknown',
        'message': message,
        'timestamp': FieldValue.serverTimestamp(),
        'messageType': 'text',
        'isRead': false,
      });

      // Update chat contact for sender
      await _updateChatContact(
        userId: user.uid,
        contactId: recipientId,
        contactName: recipientName,
        lastMessage: message,
        isFromMe: true,
      );

      // Update chat contact for recipient
      await _updateChatContact(
        userId: recipientId,
        contactId: user.uid,
        contactName: user.displayName ?? 'Unknown',
        lastMessage: message,
        isFromMe: false,
      );

      debugPrint('✅ Message sent successfully');
    } catch (e) {
      debugPrint('❌ Failed to send message: $e');
      rethrow;
    }
  }

  /// Send location message
  Future<void> sendLocationMessage({
    required String chatId,
    required String recipientId,
    required String recipientName,
    required Map<String, dynamic> locationData,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    try {
      await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .add({
        'senderId': user.uid,
        'senderName': user.displayName ?? 'Unknown',
        'message': 'Location shared',
        'timestamp': FieldValue.serverTimestamp(),
        'messageType': 'location',
        'locationData': locationData,
        'isRead': false,
      });

      // Update chat contacts
      await _updateChatContact(
        userId: user.uid,
        contactId: recipientId,
        contactName: recipientName,
        lastMessage: 'Location shared',
        isFromMe: true,
      );

      await _updateChatContact(
        userId: recipientId,
        contactId: user.uid,
        contactName: user.displayName ?? 'Unknown',
        lastMessage: 'Location shared',
        isFromMe: false,
      );

      debugPrint('✅ Location message sent successfully');
    } catch (e) {
      debugPrint('❌ Failed to send location message: $e');
      rethrow;
    }
  }

  /// Mark messages as read
  Future<void> markMessagesAsRead(String chatId, String senderId) async {
    try {
      final batch = _firestore.batch();

      final unreadMessages = await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .where('senderId', isEqualTo: senderId)
          .where('isRead', isEqualTo: false)
          .get();

      for (final doc in unreadMessages.docs) {
        batch.update(doc.reference, {'isRead': true});
      }

      await batch.commit();
      debugPrint('✅ Messages marked as read');
    } catch (e) {
      debugPrint('❌ Failed to mark messages as read: $e');
    }
  }

  /// Update chat contact information
  Future<void> _updateChatContact({
    required String userId,
    required String contactId,
    required String contactName,
    required String lastMessage,
    required bool isFromMe,
  }) async {
    try {
      await _firestore
          .collection('chat_contacts')
          .doc('${userId}_$contactId')
          .set({
        'userId': userId,
        'contactId': contactId,
        'name': contactName,
        'lastMessage': lastMessage,
        'lastMessageTime': FieldValue.serverTimestamp(),
        'unreadCount': isFromMe ? 0 : FieldValue.increment(1),
        'isOnline': false, // Will be updated by presence system
        'type': 'driver', // Default type, should be determined by user role
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('❌ Failed to update chat contact: $e');
    }
  }

  MessageType _parseMessageType(String? type) {
    switch (type) {
      case 'text':
        return MessageType.text;
      case 'location':
        return MessageType.location;
      case 'image':
        return MessageType.image;
      case 'document':
        return MessageType.document;
      default:
        return MessageType.text;
    }
  }
}

/// Chat contact model
class ChatContact {
  final String id;
  final String name;
  final String type;
  final String lastMessage;
  final DateTime lastMessageTime;
  final int unreadCount;
  final bool isOnline;

  ChatContact({
    required this.id,
    required this.name,
    required this.type,
    required this.lastMessage,
    required this.lastMessageTime,
    required this.unreadCount,
    required this.isOnline,
  });
}

/// Chat message model
class ChatMessage {
  final String id;
  final String senderId;
  final String senderName;
  final String message;
  final DateTime timestamp;
  final bool isFromMe;
  final MessageType messageType;
  final Map<String, dynamic>? locationData;

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.message,
    required this.timestamp,
    required this.isFromMe,
    required this.messageType,
    this.locationData,
  });
}

/// Message types
enum MessageType {
  text,
  location,
  image,
  document,
}
