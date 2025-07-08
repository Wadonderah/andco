import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class WhatsAppService {
  static final WhatsAppService _instance = WhatsAppService._internal();
  factory WhatsAppService() => _instance;
  WhatsAppService._internal();

  // WhatsApp Cloud API configuration
  static const String _baseUrl = 'https://graph.facebook.com/v18.0';
  static const String _phoneNumberId = 'YOUR_PHONE_NUMBER_ID';
  static const String _accessToken = 'YOUR_ACCESS_TOKEN';
  
  final Map<String, BotConversation> _activeConversations = {};

  // Send text message
  Future<bool> sendTextMessage(String to, String message) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/$_phoneNumberId/messages'),
        headers: {
          'Authorization': 'Bearer $_accessToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'messaging_product': 'whatsapp',
          'to': to,
          'type': 'text',
          'text': {'body': message},
        }),
      );

      if (response.statusCode == 200) {
        debugPrint('WhatsApp message sent successfully to $to');
        return true;
      } else {
        debugPrint('Failed to send WhatsApp message: ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('Error sending WhatsApp message: $e');
      return false;
    }
  }

  // Send template message
  Future<bool> sendTemplateMessage(String to, String templateName, Map<String, String> parameters) async {
    try {
      final components = parameters.entries.map((entry) => {
        'type': 'text',
        'text': entry.value,
      }).toList();

      final response = await http.post(
        Uri.parse('$_baseUrl/$_phoneNumberId/messages'),
        headers: {
          'Authorization': 'Bearer $_accessToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'messaging_product': 'whatsapp',
          'to': to,
          'type': 'template',
          'template': {
            'name': templateName,
            'language': {'code': 'en'},
            'components': [
              {
                'type': 'body',
                'parameters': components,
              }
            ],
          },
        }),
      );

      if (response.statusCode == 200) {
        debugPrint('WhatsApp template sent successfully to $to');
        return true;
      } else {
        debugPrint('Failed to send WhatsApp template: ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('Error sending WhatsApp template: $e');
      return false;
    }
  }

  // Send interactive message with buttons
  Future<bool> sendInteractiveMessage(String to, String bodyText, List<WhatsAppButton> buttons) async {
    try {
      final buttonComponents = buttons.map((button) => {
        'type': 'reply',
        'reply': {
          'id': button.id,
          'title': button.title,
        },
      }).toList();

      final response = await http.post(
        Uri.parse('$_baseUrl/$_phoneNumberId/messages'),
        headers: {
          'Authorization': 'Bearer $_accessToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'messaging_product': 'whatsapp',
          'to': to,
          'type': 'interactive',
          'interactive': {
            'type': 'button',
            'body': {'text': bodyText},
            'action': {
              'buttons': buttonComponents,
            },
          },
        }),
      );

      if (response.statusCode == 200) {
        debugPrint('WhatsApp interactive message sent successfully to $to');
        return true;
      } else {
        debugPrint('Failed to send WhatsApp interactive message: ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('Error sending WhatsApp interactive message: $e');
      return false;
    }
  }

  // Send location message
  Future<bool> sendLocationMessage(String to, double latitude, double longitude, String name, String address) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/$_phoneNumberId/messages'),
        headers: {
          'Authorization': 'Bearer $_accessToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'messaging_product': 'whatsapp',
          'to': to,
          'type': 'location',
          'location': {
            'latitude': latitude,
            'longitude': longitude,
            'name': name,
            'address': address,
          },
        }),
      );

      if (response.statusCode == 200) {
        debugPrint('WhatsApp location sent successfully to $to');
        return true;
      } else {
        debugPrint('Failed to send WhatsApp location: ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('Error sending WhatsApp location: $e');
      return false;
    }
  }

  // Handle incoming webhook
  Future<WhatsAppResponse> handleWebhook(Map<String, dynamic> webhookData) async {
    try {
      final entry = webhookData['entry']?[0];
      final changes = entry?['changes']?[0];
      final value = changes?['value'];
      
      if (value?['messages'] != null) {
        final message = value['messages'][0];
        final from = message['from'];
        final messageType = message['type'];
        
        final contact = value['contacts']?[0];
        final profileName = contact?['profile']?['name'] ?? 'Unknown';
        
        switch (messageType) {
          case 'text':
            final text = message['text']['body'];
            return await _handleTextMessage(from, text, profileName);
          
          case 'interactive':
            final buttonReply = message['interactive']['button_reply'];
            final buttonId = buttonReply['id'];
            return await _handleButtonReply(from, buttonId, profileName);
          
          case 'location':
            final location = message['location'];
            return await _handleLocationMessage(from, location, profileName);
          
          default:
            return WhatsAppResponse(
              success: true,
              reply: 'Sorry, I can only process text messages, buttons, and locations.',
            );
        }
      }
      
      return WhatsAppResponse(success: true);
    } catch (e) {
      debugPrint('Error handling WhatsApp webhook: $e');
      return WhatsAppResponse(success: false, error: e.toString());
    }
  }

  // Handle text message with bot logic
  Future<WhatsAppResponse> _handleTextMessage(String from, String text, String profileName) async {
    final conversation = _getOrCreateConversation(from, profileName);
    final lowerText = text.toLowerCase().trim();
    
    // Bot command processing
    if (lowerText.startsWith('/')) {
      return await _handleBotCommand(from, lowerText, conversation);
    }
    
    // Context-aware responses based on conversation state
    switch (conversation.state) {
      case ConversationState.initial:
        return await _handleInitialMessage(from, lowerText, conversation);
      
      case ConversationState.trackingBus:
        return await _handleBusTracking(from, lowerText, conversation);
      
      case ConversationState.reportIssue:
        return await _handleIssueReport(from, lowerText, conversation);
      
      case ConversationState.checkSchedule:
        return await _handleScheduleCheck(from, lowerText, conversation);
      
      default:
        return await _handleGeneralQuery(from, lowerText, conversation);
    }
  }

  Future<WhatsAppResponse> _handleBotCommand(String from, String command, BotConversation conversation) async {
    switch (command) {
      case '/start':
        conversation.state = ConversationState.initial;
        await sendInteractiveMessage(from, 
          'Welcome to School Bus Tracker! 🚌\n\nHow can I help you today?',
          [
            WhatsAppButton(id: 'track_bus', title: '🚌 Track Bus'),
            WhatsAppButton(id: 'schedule', title: '📅 Check Schedule'),
            WhatsAppButton(id: 'report_issue', title: '⚠️ Report Issue'),
          ]
        );
        break;
      
      case '/track':
        conversation.state = ConversationState.trackingBus;
        await sendTextMessage(from, 'Please provide your child\'s name or student ID to track their bus.');
        break;
      
      case '/schedule':
        conversation.state = ConversationState.checkSchedule;
        await sendTextMessage(from, 'Please provide your child\'s name or route number to check the schedule.');
        break;
      
      case '/help':
        await sendTextMessage(from, 
          'Available commands:\n'
          '/start - Main menu\n'
          '/track - Track bus location\n'
          '/schedule - Check bus schedule\n'
          '/report - Report an issue\n'
          '/help - Show this help\n'
          '/stop - End conversation'
        );
        break;
      
      case '/stop':
        conversation.state = ConversationState.ended;
        await sendTextMessage(from, 'Thank you for using School Bus Tracker! Have a great day! 👋');
        _activeConversations.remove(from);
        break;
      
      default:
        await sendTextMessage(from, 'Unknown command. Type /help for available commands.');
    }
    
    return WhatsAppResponse(success: true);
  }

  Future<WhatsAppResponse> _handleInitialMessage(String from, String text, BotConversation conversation) async {
    if (text.contains('track') || text.contains('bus') || text.contains('location')) {
      conversation.state = ConversationState.trackingBus;
      await sendTextMessage(from, 'I\'ll help you track the bus! Please provide your child\'s name or student ID.');
    } else if (text.contains('schedule') || text.contains('time')) {
      conversation.state = ConversationState.checkSchedule;
      await sendTextMessage(from, 'I\'ll check the schedule for you! Please provide your child\'s name or route number.');
    } else if (text.contains('problem') || text.contains('issue') || text.contains('report')) {
      conversation.state = ConversationState.reportIssue;
      await sendTextMessage(from, 'I\'m sorry to hear about the issue. Please describe what happened.');
    } else {
      await sendInteractiveMessage(from,
        'Hello ${conversation.userName}! 👋\n\nI\'m your School Bus Assistant. How can I help you today?',
        [
          WhatsAppButton(id: 'track_bus', title: '🚌 Track Bus'),
          WhatsAppButton(id: 'schedule', title: '📅 Check Schedule'),
          WhatsAppButton(id: 'report_issue', title: '⚠️ Report Issue'),
        ]
      );
    }
    
    return WhatsAppResponse(success: true);
  }

  Future<WhatsAppResponse> _handleBusTracking(String from, String text, BotConversation conversation) async {
    // Simulate bus tracking logic
    await sendTextMessage(from, 'Looking up bus information for "$text"...');
    
    // Simulate API call delay
    await Future.delayed(const Duration(seconds: 2));
    
    // Mock bus data
    await sendLocationMessage(from, -1.2921, 36.8219, 'School Bus Location', 'Nairobi, Kenya');
    await sendTextMessage(from, 
      '🚌 Bus Status Update:\n'
      '• Route: Route A\n'
      '• Current Location: Westlands\n'
      '• ETA to next stop: 5 minutes\n'
      '• Driver: John Doe\n'
      '• Speed: 25 km/h\n\n'
      'Your child is safe on board! 👍'
    );
    
    conversation.state = ConversationState.completed;
    await sendInteractiveMessage(from,
      'Is there anything else I can help you with?',
      [
        WhatsAppButton(id: 'track_again', title: '🔄 Track Again'),
        WhatsAppButton(id: 'main_menu', title: '🏠 Main Menu'),
        WhatsAppButton(id: 'end_chat', title: '👋 End Chat'),
      ]
    );
    
    return WhatsAppResponse(success: true);
  }

  Future<WhatsAppResponse> _handleScheduleCheck(String from, String text, BotConversation conversation) async {
    await sendTextMessage(from, 'Checking schedule for "$text"...');
    
    await Future.delayed(const Duration(seconds: 1));
    
    await sendTextMessage(from,
      '📅 Bus Schedule for Today:\n\n'
      '🌅 Morning Pickup:\n'
      '• 7:00 AM - Home pickup\n'
      '• 7:30 AM - Arrive at school\n\n'
      '🌆 Afternoon Drop-off:\n'
      '• 3:00 PM - Leave school\n'
      '• 3:30 PM - Arrive at home\n\n'
      '📍 Route: A-12\n'
      '🚌 Bus: KCA 123A\n'
      '👨‍✈️ Driver: John Doe'
    );
    
    conversation.state = ConversationState.completed;
    return WhatsAppResponse(success: true);
  }

  Future<WhatsAppResponse> _handleIssueReport(String from, String text, BotConversation conversation) async {
    conversation.issueDescription = text;
    
    await sendTextMessage(from, 
      'Thank you for reporting this issue. I\'ve recorded the following:\n\n'
      '"$text"\n\n'
      'Your report has been forwarded to our support team. '
      'You should receive a response within 2 hours.\n\n'
      'Reference ID: #${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}'
    );
    
    conversation.state = ConversationState.completed;
    return WhatsAppResponse(success: true);
  }

  Future<WhatsAppResponse> _handleGeneralQuery(String from, String text, BotConversation conversation) async {
    // Simple keyword-based responses
    if (text.contains('hello') || text.contains('hi')) {
      await sendTextMessage(from, 'Hello! How can I assist you with the school bus service today?');
    } else if (text.contains('thank')) {
      await sendTextMessage(from, 'You\'re welcome! Is there anything else I can help you with?');
    } else {
      await sendTextMessage(from, 
        'I\'m not sure I understand. You can:\n'
        '• Type /track to track a bus\n'
        '• Type /schedule to check schedules\n'
        '• Type /report to report an issue\n'
        '• Type /help for more options'
      );
    }
    
    return WhatsAppResponse(success: true);
  }

  Future<WhatsAppResponse> _handleButtonReply(String from, String buttonId, String profileName) async {
    final conversation = _getOrCreateConversation(from, profileName);
    
    switch (buttonId) {
      case 'track_bus':
        conversation.state = ConversationState.trackingBus;
        await sendTextMessage(from, 'Please provide your child\'s name or student ID to track their bus.');
        break;
      
      case 'schedule':
        conversation.state = ConversationState.checkSchedule;
        await sendTextMessage(from, 'Please provide your child\'s name or route number to check the schedule.');
        break;
      
      case 'report_issue':
        conversation.state = ConversationState.reportIssue;
        await sendTextMessage(from, 'Please describe the issue you\'d like to report.');
        break;
      
      case 'main_menu':
        conversation.state = ConversationState.initial;
        await sendInteractiveMessage(from,
          'How can I help you today?',
          [
            WhatsAppButton(id: 'track_bus', title: '🚌 Track Bus'),
            WhatsAppButton(id: 'schedule', title: '📅 Check Schedule'),
            WhatsAppButton(id: 'report_issue', title: '⚠️ Report Issue'),
          ]
        );
        break;
      
      case 'end_chat':
        conversation.state = ConversationState.ended;
        await sendTextMessage(from, 'Thank you for using School Bus Tracker! Have a great day! 👋');
        _activeConversations.remove(from);
        break;
    }
    
    return WhatsAppResponse(success: true);
  }

  Future<WhatsAppResponse> _handleLocationMessage(String from, Map<String, dynamic> location, String profileName) async {
    final latitude = location['latitude'];
    final longitude = location['longitude'];
    
    await sendTextMessage(from, 
      'Thank you for sharing your location! 📍\n\n'
      'I can see you\'re at coordinates: $latitude, $longitude\n\n'
      'Let me find the nearest bus stop and provide you with relevant information.'
    );
    
    return WhatsAppResponse(success: true);
  }

  BotConversation _getOrCreateConversation(String phoneNumber, String userName) {
    if (!_activeConversations.containsKey(phoneNumber)) {
      _activeConversations[phoneNumber] = BotConversation(
        phoneNumber: phoneNumber,
        userName: userName,
        state: ConversationState.initial,
        startTime: DateTime.now(),
      );
    }
    return _activeConversations[phoneNumber]!;
  }

  // Notification methods
  Future<void> sendBusArrivalNotification(String phoneNumber, String childName, String stopName, int minutesAway) async {
    await sendTemplateMessage(phoneNumber, 'bus_arrival_alert', {
      'child_name': childName,
      'stop_name': stopName,
      'minutes': minutesAway.toString(),
    });
  }

  Future<void> sendEmergencyAlert(String phoneNumber, String message, double? latitude, double? longitude) async {
    await sendTextMessage(phoneNumber, '🚨 EMERGENCY ALERT 🚨\n\n$message');
    
    if (latitude != null && longitude != null) {
      await sendLocationMessage(phoneNumber, latitude, longitude, 'Emergency Location', 'Current bus location');
    }
  }

  Future<void> sendRouteDelayNotification(String phoneNumber, String routeName, int delayMinutes, String reason) async {
    await sendTemplateMessage(phoneNumber, 'route_delay_notice', {
      'route_name': routeName,
      'delay_minutes': delayMinutes.toString(),
      'reason': reason,
    });
  }
}

// Data Models
class WhatsAppButton {
  final String id;
  final String title;

  WhatsAppButton({required this.id, required this.title});
}

class WhatsAppResponse {
  final bool success;
  final String? reply;
  final String? error;

  WhatsAppResponse({required this.success, this.reply, this.error});
}

class BotConversation {
  final String phoneNumber;
  final String userName;
  ConversationState state;
  final DateTime startTime;
  String? issueDescription;
  Map<String, dynamic> context = {};

  BotConversation({
    required this.phoneNumber,
    required this.userName,
    required this.state,
    required this.startTime,
    this.issueDescription,
  });
}

enum ConversationState {
  initial,
  trackingBus,
  checkSchedule,
  reportIssue,
  completed,
  ended,
}
