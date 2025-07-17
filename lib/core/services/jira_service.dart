import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../services/firebase_service.dart';

/// Jira API service for issue tracking and support tickets
/// Allows parents to submit support requests and track their status
class JiraService {
  static JiraService? _instance;
  static JiraService get instance => _instance ??= JiraService._();

  JiraService._();

  // Jira configuration (should be loaded from environment variables)
  String? _jiraBaseUrl;
  String? _jiraUsername;
  String? _jiraApiToken;
  String? _projectKey;

  // Default configuration for development
  static const String _defaultJiraBaseUrl = 'https://your-domain.atlassian.net';
  static const String _defaultProjectKey = 'ANDCO';
  static const String _defaultUsername = 'your-email@domain.com';
  static const String _defaultApiToken = 'your-jira-api-token';

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  /// Initialize Jira service with credentials
  Future<void> initialize({
    String? jiraBaseUrl,
    String? username,
    String? apiToken,
    String? projectKey,
  }) async {
    try {
      _jiraBaseUrl = jiraBaseUrl ?? _defaultJiraBaseUrl;
      _jiraUsername = username ?? _defaultUsername;
      _jiraApiToken = apiToken ?? _defaultApiToken;
      _projectKey = projectKey ?? _defaultProjectKey;

      // Validate credentials
      if (_jiraBaseUrl!.contains('your-domain') ||
          _jiraUsername!.contains('your-email') ||
          _jiraApiToken!.contains('your-jira')) {
        debugPrint(
            '⚠️ Using default Jira credentials. Please configure proper credentials for production.');
      }

      // Test connection
      await _testConnection();

      _isInitialized = true;
      debugPrint('✅ Jira service initialized successfully');

      await FirebaseService.instance.logEvent('jira_service_initialized', {
        'project_key': _projectKey ?? 'unknown',
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('❌ Jira initialization failed: $e');
      await FirebaseService.instance.logError(e, StackTrace.current,
          reason: 'Jira service initialization failed');
      rethrow;
    }
  }

  /// Test Jira connection
  Future<void> _testConnection() async {
    try {
      final response = await _makeRequest('GET', '/rest/api/3/myself');
      if (response.statusCode == 200) {
        debugPrint('✅ Jira connection test successful');
      } else {
        throw JiraException('Connection test failed: ${response.statusCode}');
      }
    } catch (e) {
      throw JiraException('Failed to connect to Jira: $e');
    }
  }

  /// Submit a support ticket from parent
  Future<Map<String, dynamic>> submitSupportTicket({
    required String parentId,
    required String parentName,
    required String parentEmail,
    required String subject,
    required String description,
    required String priority, // 'Low', 'Medium', 'High', 'Critical'
    required String
        category, // 'Technical', 'Billing', 'General', 'Feature Request'
    List<String>? attachmentUrls,
    Map<String, dynamic>? additionalData,
  }) async {
    if (!_isInitialized) {
      throw JiraException('Jira service not initialized');
    }

    try {
      // Create issue payload
      final issueData = {
        'fields': {
          'project': {'key': _projectKey},
          'summary': '[$category] $subject',
          'description': {
            'type': 'doc',
            'version': 1,
            'content': [
              {
                'type': 'paragraph',
                'content': [
                  {'type': 'text', 'text': description}
                ]
              },
              {
                'type': 'paragraph',
                'content': [
                  {'type': 'text', 'text': '\n--- Parent Information ---'}
                ]
              },
              {
                'type': 'paragraph',
                'content': [
                  {'type': 'text', 'text': 'Parent ID: $parentId'}
                ]
              },
              {
                'type': 'paragraph',
                'content': [
                  {'type': 'text', 'text': 'Parent Name: $parentName'}
                ]
              },
              {
                'type': 'paragraph',
                'content': [
                  {'type': 'text', 'text': 'Parent Email: $parentEmail'}
                ]
              },
              if (additionalData != null) ...[
                {
                  'type': 'paragraph',
                  'content': [
                    {'type': 'text', 'text': '\n--- Additional Data ---'}
                  ]
                },
                {
                  'type': 'paragraph',
                  'content': [
                    {'type': 'text', 'text': jsonEncode(additionalData)}
                  ]
                }
              ]
            ]
          },
          'issuetype': {'name': 'Task'},
          'priority': {'name': priority},
          'labels': ['parent-support', 'andco-app', category.toLowerCase()],
          'customfield_10000': parentId, // Custom field for parent ID
        }
      };

      final response =
          await _makeRequest('POST', '/rest/api/3/issue', body: issueData);

      if (response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        final issueKey = responseData['key'];
        final issueId = responseData['id'];

        // Store ticket reference in Firestore
        await _storeTicketReference(
          parentId: parentId,
          issueKey: issueKey,
          issueId: issueId,
          subject: subject,
          category: category,
          priority: priority,
        );

        // Send confirmation notification
        await _sendTicketConfirmation(parentId, issueKey, subject);

        await FirebaseService.instance.logEvent('support_ticket_created', {
          'parent_id': parentId,
          'issue_key': issueKey,
          'category': category,
          'priority': priority,
        });

        return {
          'success': true,
          'issueKey': issueKey,
          'issueId': issueId,
          'message': 'Support ticket created successfully',
        };
      } else {
        throw JiraException('Failed to create issue: ${response.body}');
      }
    } catch (e) {
      debugPrint('❌ Failed to submit support ticket: $e');
      await FirebaseService.instance.logError(e, StackTrace.current,
          reason: 'Failed to submit support ticket');
      rethrow;
    }
  }

  /// Get support tickets for a parent
  Future<List<Map<String, dynamic>>> getParentTickets({
    required String parentId,
    int maxResults = 50,
  }) async {
    if (!_isInitialized) {
      throw JiraException('Jira service not initialized');
    }

    try {
      // Get tickets from Firestore first (for quick access)
      final firestoreTickets = await _getTicketsFromFirestore(parentId);

      // Get latest status from Jira for each ticket
      final updatedTickets = <Map<String, dynamic>>[];

      for (final ticket in firestoreTickets) {
        try {
          final jiraTicket = await _getJiraTicketDetails(ticket['issueKey']);
          updatedTickets.add({
            ...ticket,
            'currentStatus': jiraTicket['status'],
            'lastUpdated': jiraTicket['updated'],
            'assignee': jiraTicket['assignee'],
            'resolution': jiraTicket['resolution'],
            'comments': jiraTicket['comments'],
          });
        } catch (e) {
          // If we can't get Jira details, use Firestore data
          updatedTickets.add(ticket);
        }
      }

      return updatedTickets;
    } catch (e) {
      debugPrint('❌ Failed to get parent tickets: $e');
      await FirebaseService.instance.logError(e, StackTrace.current,
          reason: 'Failed to get parent tickets');
      return [];
    }
  }

  /// Get detailed ticket information
  Future<Map<String, dynamic>?> getTicketDetails({
    required String issueKey,
  }) async {
    if (!_isInitialized) {
      throw JiraException('Jira service not initialized');
    }

    try {
      return await _getJiraTicketDetails(issueKey);
    } catch (e) {
      debugPrint('❌ Failed to get ticket details: $e');
      await FirebaseService.instance.logError(e, StackTrace.current,
          reason: 'Failed to get ticket details');
      return null;
    }
  }

  /// Add comment to a ticket
  Future<bool> addTicketComment({
    required String issueKey,
    required String parentId,
    required String comment,
  }) async {
    if (!_isInitialized) {
      throw JiraException('Jira service not initialized');
    }

    try {
      final commentData = {
        'body': {
          'type': 'doc',
          'version': 1,
          'content': [
            {
              'type': 'paragraph',
              'content': [
                {'type': 'text', 'text': comment}
              ]
            },
            {
              'type': 'paragraph',
              'content': [
                {
                  'type': 'text',
                  'text': '\n--- Comment from Parent (ID: $parentId) ---'
                }
              ]
            }
          ]
        }
      };

      final response = await _makeRequest(
        'POST',
        '/rest/api/3/issue/$issueKey/comment',
        body: commentData,
      );

      if (response.statusCode == 201) {
        await FirebaseService.instance
            .logEvent('support_ticket_comment_added', {
          'parent_id': parentId,
          'issue_key': issueKey,
        });
        return true;
      } else {
        throw JiraException('Failed to add comment: ${response.body}');
      }
    } catch (e) {
      debugPrint('❌ Failed to add ticket comment: $e');
      await FirebaseService.instance.logError(e, StackTrace.current,
          reason: 'Failed to add ticket comment');
      return false;
    }
  }

  /// Make HTTP request to Jira API
  Future<http.Response> _makeRequest(
    String method,
    String endpoint, {
    Map<String, dynamic>? body,
  }) async {
    final url = Uri.parse('$_jiraBaseUrl$endpoint');
    final headers = {
      'Authorization':
          'Basic ${base64Encode(utf8.encode('$_jiraUsername:$_jiraApiToken'))}',
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    switch (method.toUpperCase()) {
      case 'GET':
        return await http.get(url, headers: headers);
      case 'POST':
        return await http.post(url, headers: headers, body: jsonEncode(body));
      case 'PUT':
        return await http.put(url, headers: headers, body: jsonEncode(body));
      case 'DELETE':
        return await http.delete(url, headers: headers);
      default:
        throw JiraException('Unsupported HTTP method: $method');
    }
  }

  /// Store ticket reference in Firestore
  Future<void> _storeTicketReference({
    required String parentId,
    required String issueKey,
    required String issueId,
    required String subject,
    required String category,
    required String priority,
  }) async {
    try {
      await FirebaseService.instance.firestore
          .collection('support_tickets')
          .doc(issueKey)
          .set({
        'parentId': parentId,
        'issueKey': issueKey,
        'issueId': issueId,
        'subject': subject,
        'category': category,
        'priority': priority,
        'status': 'Open',
        'createdAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('❌ Failed to store ticket reference: $e');
    }
  }

  /// Get tickets from Firestore
  Future<List<Map<String, dynamic>>> _getTicketsFromFirestore(
      String parentId) async {
    try {
      final snapshot = await FirebaseService.instance.firestore
          .collection('support_tickets')
          .where('parentId', isEqualTo: parentId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => {
                'id': doc.id,
                ...doc.data(),
              })
          .toList();
    } catch (e) {
      debugPrint('❌ Failed to get tickets from Firestore: $e');
      return [];
    }
  }

  /// Get Jira ticket details
  Future<Map<String, dynamic>> _getJiraTicketDetails(String issueKey) async {
    final response = await _makeRequest(
        'GET', '/rest/api/3/issue/$issueKey?expand=comments');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return {
        'key': data['key'],
        'status': data['fields']['status']['name'],
        'updated': data['fields']['updated'],
        'assignee': data['fields']['assignee']?['displayName'],
        'resolution': data['fields']['resolution']?['name'],
        'comments': (data['fields']['comment']['comments'] as List)
            .map((comment) => {
                  'author': comment['author']['displayName'],
                  'body': _extractTextFromADF(comment['body']),
                  'created': comment['created'],
                })
            .toList(),
      };
    } else {
      throw JiraException('Failed to get ticket details: ${response.body}');
    }
  }

  /// Send ticket confirmation notification
  Future<void> _sendTicketConfirmation(
      String parentId, String issueKey, String subject) async {
    try {
      await FirebaseService.instance.firestore.collection('notifications').add({
        'userId': parentId,
        'type': 'support_ticket_created',
        'title': 'Support Ticket Created',
        'message':
            'Your support ticket "$subject" has been created. Ticket ID: $issueKey',
        'data': {
          'issueKey': issueKey,
          'subject': subject,
        },
        'createdAt': DateTime.now().toIso8601String(),
        'read': false,
      });
    } catch (e) {
      debugPrint('❌ Failed to send ticket confirmation: $e');
    }
  }

  /// Extract text from Atlassian Document Format (ADF)
  String _extractTextFromADF(Map<String, dynamic> adf) {
    try {
      final content = adf['content'] as List?;
      if (content == null) return '';

      final buffer = StringBuffer();
      for (final item in content) {
        if (item['type'] == 'paragraph') {
          final paragraphContent = item['content'] as List?;
          if (paragraphContent != null) {
            for (final textItem in paragraphContent) {
              if (textItem['type'] == 'text') {
                buffer.write(textItem['text']);
              }
            }
          }
          buffer.write('\n');
        }
      }
      return buffer.toString().trim();
    } catch (e) {
      return 'Unable to parse comment';
    }
  }
}

/// Jira specific exception class
class JiraException implements Exception {
  final String message;
  final String? code;

  JiraException(this.message, [this.code]);

  @override
  String toString() =>
      'JiraException: $message${code != null ? ' (Code: $code)' : ''}';
}
