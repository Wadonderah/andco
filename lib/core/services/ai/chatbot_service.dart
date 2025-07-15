import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../shared/models/user_model.dart';
import 'base_ai_service.dart';

/// Intelligent Customer Support Chatbot using Hugging Face free models
class ChatbotService extends BaseAIService
    with RateLimitMixin, CacheMixin<ChatResponse> {
  static const String _huggingFaceApiUrl =
      'https://api-inference.huggingface.co/models';
  static const String _defaultModel = 'microsoft/DialoGPT-medium';
  static const String _apiKey =
      'YOUR_HUGGING_FACE_API_KEY'; // Replace with actual key

  AIServiceStatus _status = AIServiceStatus.uninitialized;
  bool _isEnabled = true;
  bool _isInitialized = false;
  ChatbotConfig _config = const ChatbotConfig();

  final Map<String, List<ChatMessage>> _conversationHistory = {};
  final Map<String, String> _userContexts = {};
  late KnowledgeBase _knowledgeBase;

  @override
  String get serviceName => 'Customer Support Chatbot';

  @override
  bool get isEnabled => _isEnabled;

  @override
  bool get isInitialized => _isInitialized;

  @override
  AIServiceStatus get status => _status;

  @override
  Future<void> initialize({Map<String, dynamic>? config}) async {
    try {
      _status = AIServiceStatus.initializing;

      if (config != null) {
        _config = ChatbotConfig.fromJson(config);
      }

      // Set up rate limiting (Hugging Face free tier: 1,000 requests/month)
      setRateLimitConfig(const RateLimitConfig(
        maxRequestsPerMinute: 2,
        maxRequestsPerHour: 30,
        maxRequestsPerDay: 100,
      ));

      // Set up caching
      setCacheConfig(const CacheConfig(
        enabled: true,
        cacheDuration: Duration(minutes: 10),
        maxCacheSize: 100,
        persistCache: true,
      ));

      // Initialize knowledge base
      _knowledgeBase = KnowledgeBase();
      await _knowledgeBase.initialize();

      // Load conversation history
      await _loadConversationHistory();

      _isInitialized = true;
      _status = AIServiceStatus.ready;

      debugPrint('✅ Chatbot Service initialized');
    } catch (e) {
      _status = AIServiceStatus.error;
      debugPrint('❌ Failed to initialize Chatbot Service: $e');
      rethrow;
    }
  }

  @override
  Future<void> dispose() async {
    await _saveConversationHistory();
    _conversationHistory.clear();
    _userContexts.clear();
    clearCache();
    _isInitialized = false;
    _status = AIServiceStatus.uninitialized;
  }

  @override
  Future<void> enable() async {
    _isEnabled = true;
    if (_isInitialized) {
      _status = AIServiceStatus.ready;
    }
  }

  @override
  Future<void> disable() async {
    _isEnabled = false;
    _status = AIServiceStatus.disabled;
  }

  @override
  Future<AIServiceHealth> getHealthStatus() async {
    final isHealthy =
        _isEnabled && _isInitialized && _status != AIServiceStatus.error;

    return AIServiceHealth(
      serviceName: serviceName,
      status: _status,
      isHealthy: isHealthy,
      lastCheck: DateTime.now(),
      metrics: {
        'activeConversations': _conversationHistory.length,
        'knowledgeBaseEntries': _knowledgeBase.entryCount,
        'isEnabled': _isEnabled,
        'isInitialized': _isInitialized,
      },
    );
  }

  @override
  Map<String, dynamic> getConfiguration() {
    return _config.toJson();
  }

  @override
  Future<void> updateConfiguration(Map<String, dynamic> config) async {
    _config = ChatbotConfig.fromJson(config);
  }

  @override
  Future<void> reset() async {
    _conversationHistory.clear();
    _userContexts.clear();
    clearCache();
    _status = AIServiceStatus.ready;
  }

  /// Send a message to the chatbot and get a response
  Future<AIServiceResult<ChatResponse>> sendMessage({
    required String userId,
    required String message,
    UserRole? userRole,
    Map<String, dynamic>? context,
  }) async {
    try {
      if (!_isEnabled || !_isInitialized) {
        return AIServiceResult.failure('Chatbot service not available');
      }

      _status = AIServiceStatus.running;

      // Check rate limits
      if (!await checkRateLimit('chat_message')) {
        return AIServiceResult.failure(
            'Rate limit exceeded. Please try again later.');
      }

      // Create user message
      final userMessage = ChatMessage(
        id: _generateMessageId(),
        content: message,
        sender: MessageSender.user,
        timestamp: DateTime.now(),
        userId: userId,
      );

      // Add to conversation history
      _addMessageToHistory(userId, userMessage);

      // Update user context
      if (context != null) {
        _userContexts[userId] = json.encode(context);
      }

      // Check cache for similar messages
      final cacheKey = _generateCacheKey(message, userRole);
      final cached = getCached(cacheKey);
      if (cached != null) {
        debugPrint('📦 Using cached chatbot response');
        _addMessageToHistory(userId, cached.botMessage);
        return AIServiceResult.success(cached);
      }

      // Try to answer from knowledge base first
      final knowledgeResponse =
          await _tryKnowledgeBaseResponse(message, userRole);
      if (knowledgeResponse != null) {
        final response = ChatResponse(
          userMessage: userMessage,
          botMessage: knowledgeResponse,
          responseTime: DateTime.now().difference(userMessage.timestamp),
          confidence: 0.9,
          source: ResponseSource.knowledgeBase,
        );

        _addMessageToHistory(userId, knowledgeResponse);
        setCached(cacheKey, response);

        _status = AIServiceStatus.ready;
        return AIServiceResult.success(response);
      }

      // Use AI model for complex queries
      final aiResponse = await _getAIResponse(userId, message, userRole);
      if (aiResponse != null) {
        final response = ChatResponse(
          userMessage: userMessage,
          botMessage: aiResponse,
          responseTime: DateTime.now().difference(userMessage.timestamp),
          confidence: 0.7,
          source: ResponseSource.aiModel,
        );

        _addMessageToHistory(userId, aiResponse);
        setCached(cacheKey, response);

        _status = AIServiceStatus.ready;
        return AIServiceResult.success(response);
      }

      // Fallback response
      final fallbackResponse = _getFallbackResponse(userRole);
      final response = ChatResponse(
        userMessage: userMessage,
        botMessage: fallbackResponse,
        responseTime: DateTime.now().difference(userMessage.timestamp),
        confidence: 0.3,
        source: ResponseSource.fallback,
      );

      _addMessageToHistory(userId, fallbackResponse);

      _status = AIServiceStatus.ready;
      return AIServiceResult.success(response);
    } catch (e) {
      _status = AIServiceStatus.error;
      debugPrint('❌ Chatbot message failed: $e');
      return AIServiceResult.failure(e.toString());
    }
  }

  /// Try to get response from knowledge base
  Future<ChatMessage?> _tryKnowledgeBaseResponse(
      String message, UserRole? userRole) async {
    final response = await _knowledgeBase.findResponse(message, userRole);

    if (response != null) {
      return ChatMessage(
        id: _generateMessageId(),
        content: response,
        sender: MessageSender.bot,
        timestamp: DateTime.now(),
        userId: 'system',
      );
    }

    return null;
  }

  /// Get AI response from Hugging Face model
  Future<ChatMessage?> _getAIResponse(
      String userId, String message, UserRole? userRole) async {
    try {
      // Prepare conversation context
      final conversationHistory = _conversationHistory[userId] ?? [];
      final context = _buildConversationContext(conversationHistory, userRole);

      // Prepare request
      final requestBody = {
        'inputs': {
          'past_user_inputs': conversationHistory
              .where((m) => m.sender == MessageSender.user)
              .map((m) => m.content)
              .toList(),
          'generated_responses': conversationHistory
              .where((m) => m.sender == MessageSender.bot)
              .map((m) => m.content)
              .toList(),
          'text': message,
        },
        'parameters': {
          'max_length': _config.maxResponseLength,
          'temperature': _config.temperature,
          'do_sample': true,
          'top_p': 0.9,
        },
      };

      final response = await http.post(
        Uri.parse('$_huggingFaceApiUrl/$_defaultModel'),
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
        },
        body: json.encode(requestBody),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        String botResponse = '';

        if (data is Map && data.containsKey('generated_text')) {
          botResponse = data['generated_text'];
        } else if (data is List && data.isNotEmpty) {
          botResponse = data[0]['generated_text'] ?? '';
        }

        if (botResponse.isNotEmpty) {
          // Clean and format response
          botResponse = _cleanAIResponse(botResponse);

          return ChatMessage(
            id: _generateMessageId(),
            content: botResponse,
            sender: MessageSender.bot,
            timestamp: DateTime.now(),
            userId: 'system',
          );
        }
      } else if (response.statusCode == 503) {
        // Model is loading, return a loading message
        return ChatMessage(
          id: _generateMessageId(),
          content:
              'I\'m currently loading my knowledge. Please try again in a moment.',
          sender: MessageSender.bot,
          timestamp: DateTime.now(),
          userId: 'system',
        );
      } else {
        debugPrint('⚠️ Hugging Face API error: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('⚠️ Failed to get AI response: $e');
    }

    return null;
  }

  /// Build conversation context for AI model
  String _buildConversationContext(
      List<ChatMessage> history, UserRole? userRole) {
    final roleContext = _getRoleContext(userRole);
    final recentHistory = history.take(10).map((m) {
      final sender = m.sender == MessageSender.user ? 'User' : 'Assistant';
      return '$sender: ${m.content}';
    }).join('\n');

    return '$roleContext\n\nConversation:\n$recentHistory';
  }

  /// Get role-specific context
  String _getRoleContext(UserRole? userRole) {
    switch (userRole) {
      case UserRole.parent:
        return 'You are a helpful assistant for parents using a school transport app. '
            'Help with questions about bus schedules, payments, student safety, and tracking.';
      case UserRole.driver:
        return 'You are a helpful assistant for bus drivers using a school transport app. '
            'Help with questions about routes, student manifests, safety protocols, and reporting.';
      case UserRole.schoolAdmin:
        return 'You are a helpful assistant for school administrators using a school transport app. '
            'Help with questions about route management, driver oversight, reports, and system administration.';
      case UserRole.superAdmin:
        return 'You are a helpful assistant for system administrators using a school transport app. '
            'Help with questions about system management, analytics, user administration, and technical support.';
      default:
        return 'You are a helpful assistant for a school transport app. '
            'Provide helpful and accurate information about the app\'s features.';
    }
  }

  /// Clean AI response
  String _cleanAIResponse(String response) {
    // Remove unwanted prefixes and suffixes
    response = response.trim();

    // Remove common AI artifacts
    response = response.replaceAll(RegExp(r'^(Assistant:|Bot:|AI:)\s*'), '');
    response = response.replaceAll(RegExp(r'\s*(Human:|User:).*$'), '');

    // Limit length
    if (response.length > _config.maxResponseLength) {
      response = response.substring(0, _config.maxResponseLength);
      // Try to end at a sentence
      final lastPeriod = response.lastIndexOf('.');
      if (lastPeriod > response.length * 0.8) {
        response = response.substring(0, lastPeriod + 1);
      }
    }

    return response.trim();
  }

  /// Get fallback response based on user role
  ChatMessage _getFallbackResponse(UserRole? userRole) {
    final responses =
        _config.fallbackResponses[userRole] ?? _config.defaultFallbackResponses;
    final response = responses.isNotEmpty
        ? responses.first
        : 'I\'m sorry, I couldn\'t understand your question. Please try rephrasing it or contact support.';

    return ChatMessage(
      id: _generateMessageId(),
      content: response,
      sender: MessageSender.bot,
      timestamp: DateTime.now(),
      userId: 'system',
    );
  }

  /// Add message to conversation history
  void _addMessageToHistory(String userId, ChatMessage message) {
    if (!_conversationHistory.containsKey(userId)) {
      _conversationHistory[userId] = [];
    }

    _conversationHistory[userId]!.add(message);

    // Keep only recent messages (last 50)
    if (_conversationHistory[userId]!.length > 50) {
      _conversationHistory[userId] =
          _conversationHistory[userId]!.skip(25).toList();
    }
  }

  /// Generate cache key
  String _generateCacheKey(String message, UserRole? userRole) {
    final roleKey = userRole?.name ?? 'general';
    final messageHash = message.toLowerCase().replaceAll(RegExp(r'\s+'), '_');
    return '${roleKey}_${messageHash.length > 50 ? messageHash.substring(0, 50) : messageHash}';
  }

  /// Generate unique message ID
  String _generateMessageId() {
    return '${DateTime.now().millisecondsSinceEpoch}_${DateTime.now().microsecond}';
  }

  /// Load conversation history from storage
  Future<void> _loadConversationHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = prefs.getString('chat_history');

      if (historyJson != null) {
        final historyData = json.decode(historyJson) as Map<String, dynamic>;

        for (final entry in historyData.entries) {
          final userId = entry.key;
          final messages = (entry.value as List)
              .map((m) => ChatMessage.fromJson(m))
              .toList();
          _conversationHistory[userId] = messages;
        }
      }
    } catch (e) {
      debugPrint('⚠️ Failed to load conversation history: $e');
    }
  }

  /// Save conversation history to storage
  Future<void> _saveConversationHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyData = <String, dynamic>{};

      for (final entry in _conversationHistory.entries) {
        historyData[entry.key] = entry.value.map((m) => m.toJson()).toList();
      }

      await prefs.setString('chat_history', json.encode(historyData));
    } catch (e) {
      debugPrint('⚠️ Failed to save conversation history: $e');
    }
  }

  /// Get conversation history for a user
  List<ChatMessage> getConversationHistory(String userId) {
    return _conversationHistory[userId] ?? [];
  }

  /// Clear conversation history for a user
  Future<void> clearConversationHistory(String userId) async {
    _conversationHistory.remove(userId);
    _userContexts.remove(userId);
    await _saveConversationHistory();
  }

  /// Get chat statistics
  Map<String, dynamic> getChatStatistics() {
    final totalMessages = _conversationHistory.values
        .map((messages) => messages.length)
        .fold(0, (sum, count) => sum + count);

    final activeUsers = _conversationHistory.keys.length;

    return {
      'totalMessages': totalMessages,
      'activeUsers': activeUsers,
      'knowledgeBaseEntries': _knowledgeBase.entryCount,
      'averageMessagesPerUser':
          activeUsers > 0 ? totalMessages / activeUsers : 0,
    };
  }
}

/// Configuration for Chatbot Service
class ChatbotConfig extends AIServiceConfig {
  final String model;
  final int maxResponseLength;
  final double temperature;
  final bool enableKnowledgeBase;
  final Map<UserRole, List<String>> fallbackResponses;
  final List<String> defaultFallbackResponses;
  final Duration responseTimeout;

  const ChatbotConfig({
    super.enabled = true,
    this.model = 'microsoft/DialoGPT-medium',
    this.maxResponseLength = 200,
    this.temperature = 0.7,
    this.enableKnowledgeBase = true,
    this.fallbackResponses = const {},
    this.defaultFallbackResponses = const [
      'I\'m sorry, I couldn\'t understand your question. Could you please rephrase it?',
      'I\'m here to help! Could you provide more details about what you need assistance with?',
      'Let me connect you with a human agent who can better assist you.',
    ],
    this.responseTimeout = const Duration(seconds: 30),
    super.rateLimitConfig,
    super.cacheConfig,
    super.customConfig = const {},
  });

  @override
  Map<String, dynamic> toJson() {
    return {
      'enabled': enabled,
      'model': model,
      'maxResponseLength': maxResponseLength,
      'temperature': temperature,
      'enableKnowledgeBase': enableKnowledgeBase,
      'fallbackResponses': fallbackResponses.map((k, v) => MapEntry(k.name, v)),
      'defaultFallbackResponses': defaultFallbackResponses,
      'responseTimeoutMs': responseTimeout.inMilliseconds,
      'rateLimitConfig': rateLimitConfig?.toJson(),
      'cacheConfig': cacheConfig?.toJson(),
      'customConfig': customConfig,
    };
  }

  factory ChatbotConfig.fromJson(Map<String, dynamic> json) {
    final fallbackMap = <UserRole, List<String>>{};
    if (json['fallbackResponses'] != null) {
      final responses = json['fallbackResponses'] as Map<String, dynamic>;
      for (final entry in responses.entries) {
        final role = UserRole.values.firstWhere((r) => r.name == entry.key);
        fallbackMap[role] = List<String>.from(entry.value);
      }
    }

    return ChatbotConfig(
      enabled: json['enabled'] ?? true,
      model: json['model'] ?? 'microsoft/DialoGPT-medium',
      maxResponseLength: json['maxResponseLength'] ?? 200,
      temperature: json['temperature']?.toDouble() ?? 0.7,
      enableKnowledgeBase: json['enableKnowledgeBase'] ?? true,
      fallbackResponses: fallbackMap,
      defaultFallbackResponses:
          List<String>.from(json['defaultFallbackResponses'] ?? []),
      responseTimeout:
          Duration(milliseconds: json['responseTimeoutMs'] ?? 30000),
      rateLimitConfig: json['rateLimitConfig'] != null
          ? RateLimitConfig.fromJson(json['rateLimitConfig'])
          : null,
      cacheConfig: json['cacheConfig'] != null
          ? CacheConfig.fromJson(json['cacheConfig'])
          : null,
      customConfig: Map<String, dynamic>.from(json['customConfig'] ?? {}),
    );
  }
}

/// Chat message data
class ChatMessage {
  final String id;
  final String content;
  final MessageSender sender;
  final DateTime timestamp;
  final String userId;
  final Map<String, dynamic>? metadata;

  const ChatMessage({
    required this.id,
    required this.content,
    required this.sender,
    required this.timestamp,
    required this.userId,
    this.metadata,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content': content,
      'sender': sender.name,
      'timestamp': timestamp.toIso8601String(),
      'userId': userId,
      'metadata': metadata,
    };
  }

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] ?? '',
      content: json['content'] ?? '',
      sender: MessageSender.values.firstWhere((s) => s.name == json['sender']),
      timestamp: DateTime.parse(json['timestamp']),
      userId: json['userId'] ?? '',
      metadata: json['metadata'],
    );
  }
}

/// Message sender types
enum MessageSender {
  user,
  bot,
  system,
}

/// Chat response data
class ChatResponse {
  final ChatMessage userMessage;
  final ChatMessage botMessage;
  final Duration responseTime;
  final double confidence;
  final ResponseSource source;

  const ChatResponse({
    required this.userMessage,
    required this.botMessage,
    required this.responseTime,
    required this.confidence,
    required this.source,
  });

  Map<String, dynamic> toJson() {
    return {
      'userMessage': userMessage.toJson(),
      'botMessage': botMessage.toJson(),
      'responseTimeMs': responseTime.inMilliseconds,
      'confidence': confidence,
      'source': source.name,
    };
  }
}

/// Response source types
enum ResponseSource {
  knowledgeBase,
  aiModel,
  fallback,
  humanAgent,
}

/// Knowledge base for FAQ and common responses
class KnowledgeBase {
  final Map<String, KnowledgeEntry> _entries = {};

  int get entryCount => _entries.length;

  Future<void> initialize() async {
    // Initialize with common FAQ entries
    await _loadDefaultEntries();
  }

  /// Load default knowledge base entries
  Future<void> _loadDefaultEntries() async {
    final defaultEntries = [
      // General App Questions
      KnowledgeEntry(
        id: 'app_features',
        keywords: ['features', 'what can', 'app do', 'capabilities'],
        response:
            'AndCo School Transport app helps you track your child\'s bus, make payments, communicate with drivers, and ensure safe transportation. You can view real-time bus locations, receive notifications, and access trip history.',
        category: 'general',
        userRoles: UserRole.values,
      ),

      // Parent-specific
      KnowledgeEntry(
        id: 'track_bus',
        keywords: ['track', 'bus location', 'where is bus', 'real time'],
        response:
            'To track your child\'s bus, go to the Home screen and tap on "Track Bus". You\'ll see the real-time location of the bus and estimated arrival time.',
        category: 'tracking',
        userRoles: [UserRole.parent],
      ),

      KnowledgeEntry(
        id: 'make_payment',
        keywords: ['payment', 'pay', 'fees', 'billing', 'cost'],
        response:
            'You can make payments through the Payments section. We accept credit cards, mobile money (M-Pesa), and bank transfers. Your payment history is also available there.',
        category: 'payments',
        userRoles: [UserRole.parent],
      ),

      // Driver-specific
      KnowledgeEntry(
        id: 'student_manifest',
        keywords: ['manifest', 'student list', 'pickup list', 'students'],
        response:
            'Your student manifest is available in the Routes section. It shows all students to pick up/drop off with their photos and addresses. Swipe to mark attendance.',
        category: 'routes',
        userRoles: [UserRole.driver],
      ),

      KnowledgeEntry(
        id: 'emergency_contact',
        keywords: ['emergency', 'sos', 'help', 'urgent', 'accident'],
        response:
            'In case of emergency, use the SOS button on your dashboard. This will immediately alert school administrators and emergency contacts. You can also call emergency services directly.',
        category: 'safety',
        userRoles: [UserRole.driver],
      ),

      // School Admin-specific
      KnowledgeEntry(
        id: 'manage_routes',
        keywords: ['routes', 'manage routes', 'assign', 'route planning'],
        response:
            'You can manage routes in the Route Management section. Create new routes, assign drivers, add/remove students, and optimize routes for efficiency.',
        category: 'management',
        userRoles: [UserRole.schoolAdmin],
      ),

      KnowledgeEntry(
        id: 'view_reports',
        keywords: ['reports', 'analytics', 'statistics', 'data'],
        response:
            'Reports are available in the Reports section. You can generate daily, weekly, and monthly reports on attendance, routes, payments, and safety incidents.',
        category: 'reports',
        userRoles: [UserRole.schoolAdmin, UserRole.superAdmin],
      ),

      // Technical Support
      KnowledgeEntry(
        id: 'app_not_working',
        keywords: ['not working', 'broken', 'error', 'crash', 'bug'],
        response:
            'If you\'re experiencing issues, try restarting the app first. If the problem persists, check your internet connection and ensure you have the latest app version. Contact support if issues continue.',
        category: 'technical',
        userRoles: UserRole.values,
      ),

      KnowledgeEntry(
        id: 'forgot_password',
        keywords: [
          'forgot password',
          'reset password',
          'login',
          'can\'t login'
        ],
        response:
            'To reset your password, tap "Forgot Password" on the login screen and enter your email. You\'ll receive a reset link. If you don\'t receive it, check your spam folder.',
        category: 'account',
        userRoles: UserRole.values,
      ),
    ];

    for (final entry in defaultEntries) {
      _entries[entry.id] = entry;
    }
  }

  /// Find response for a user query
  Future<String?> findResponse(String query, UserRole? userRole) async {
    final queryLower = query.toLowerCase();

    // Find matching entries
    final matches = <KnowledgeEntry>[];

    for (final entry in _entries.values) {
      // Check if user role matches
      if (userRole != null && !entry.userRoles.contains(userRole)) {
        continue;
      }

      // Check keyword matches
      for (final keyword in entry.keywords) {
        if (queryLower.contains(keyword.toLowerCase())) {
          matches.add(entry);
          break;
        }
      }
    }

    // Return best match
    if (matches.isNotEmpty) {
      // Sort by relevance (number of keyword matches)
      matches.sort((a, b) {
        final aMatches = a.keywords
            .where((k) => queryLower.contains(k.toLowerCase()))
            .length;
        final bMatches = b.keywords
            .where((k) => queryLower.contains(k.toLowerCase()))
            .length;
        return bMatches.compareTo(aMatches);
      });

      return matches.first.response;
    }

    return null;
  }

  /// Add new knowledge entry
  void addEntry(KnowledgeEntry entry) {
    _entries[entry.id] = entry;
  }

  /// Remove knowledge entry
  void removeEntry(String id) {
    _entries.remove(id);
  }

  /// Get all entries for a category
  List<KnowledgeEntry> getEntriesByCategory(String category) {
    return _entries.values.where((e) => e.category == category).toList();
  }
}

/// Knowledge base entry
class KnowledgeEntry {
  final String id;
  final List<String> keywords;
  final String response;
  final String category;
  final List<UserRole> userRoles;

  const KnowledgeEntry({
    required this.id,
    required this.keywords,
    required this.response,
    required this.category,
    required this.userRoles,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'keywords': keywords,
      'response': response,
      'category': category,
      'userRoles': userRoles.map((r) => r.name).toList(),
    };
  }

  factory KnowledgeEntry.fromJson(Map<String, dynamic> json) {
    return KnowledgeEntry(
      id: json['id'] ?? '',
      keywords: List<String>.from(json['keywords'] ?? []),
      response: json['response'] ?? '',
      category: json['category'] ?? '',
      userRoles: (json['userRoles'] as List?)
              ?.map((r) => UserRole.values.firstWhere((role) => role.name == r))
              .toList() ??
          [],
    );
  }
}
