import 'dart:convert';
import 'package:http/http.dart' as http;

class CallService {
  final String baseUrl = 'http://10.0.2.2:3000/api';

  Future<List<Map<String, dynamic>>> getCallLogsByUserId(String userId) async {
    try {
      final int? numericUserId = int.tryParse(userId);
      if (numericUserId == null) {
        throw Exception('Invalid user ID format');
      }

      final response = await http.get(
        Uri.parse('$baseUrl/call/logs/$numericUserId'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);
        final List<dynamic> calls = jsonResponse['data'] ?? [];
        
        return calls.map((call) {
          final dynamic rawId = call['Call ID'];
          final String id = rawId?.toString() ?? '';

          return {
            'id': id,
            'Call Status': call['Call Status'] ?? '',
            'Call Direction': call['Call Direction'] ?? '',
            'Call Type': call['Call Type'] ?? '',
            'Call Timestamp': call['Call Timestamp'] ?? '',
            'Contact Name': call['Contact Name'] ?? 'Unknown',
            'Contact Id': call['Contact Id'] ?? 0,
            'Profile Picture': call['Profile Picture'] ?? '',
          };
        }).toList();
      } else {
        throw Exception('Failed to load call logs');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> deleteCallLog(String callId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/call/logs/$callId'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<Map<String, bool>> deleteMultipleCallLogs(List<String> callIds) async {
    final Map<String, bool> results = {};
    
    try {
      for (String id in callIds) {
        if (id.isEmpty) continue;

        final response = await http.delete(
          Uri.parse('$baseUrl/call/logs/$id'),
          headers: {'Content-Type': 'application/json'},
        );

        results[id] = response.statusCode == 200;
      }
    } catch (e) {
      rethrow;
    }

    return results;
  }
}
