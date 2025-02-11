import 'dart:convert';
import 'package:http/http.dart' as http;

// Models
class Community {
  final int communityId;
  final String communityName;
  final String communityDescription;
  final String? communityImageUrl;
  final int createdBy;
  final String createdAt;
  final int communityUserId;
  final String memberRole;
  final String memberJoinedAt;
  final int totalMembers;
  final List<Group> groups;

  Community({
    required this.communityId,
    required this.communityName,
    required this.communityDescription,
    this.communityImageUrl,
    required this.createdBy,
    required this.createdAt,
    required this.communityUserId,
    required this.memberRole,
    required this.memberJoinedAt,
    required this.totalMembers,
    required this.groups,
  });

  factory Community.fromJson(Map<String, dynamic> json) {
    return Community(
      communityId: json['community_id'],
      communityName: json['community_name'],
      communityDescription: json['community_description'],
      communityImageUrl: json['community_image_url'],
      createdBy: json['created_by'],
      createdAt: json['created_at'],
      communityUserId: json['community_user_id'],
      memberRole: json['member_role'],
      memberJoinedAt: json['member_joined_at'],
      totalMembers: json['total_members'],
      groups: (json['groups'] as List)
          .map((group) => Group.fromJson(group))
          .toList(),
    );
  }
}

class Group {
  final int groupId;
  final String groupName;
  final String? groupImageUrl;
  final String createdAt;

  Group({
    required this.groupId,
    required this.groupName,
    this.groupImageUrl,
    required this.createdAt,
  });

  factory Group.fromJson(Map<String, dynamic> json) {
    return Group(
      groupId: json['group_id'],
      groupName: json['group_name'],
      groupImageUrl: json['group_image_url'],
      createdAt: json['created_at'],
    );
  }
}

// Service
class CommunityService {
  final String baseUrl;
  CommunityService({this.baseUrl = 'http://10.0.2.2:3000/api'});

  Future<List<Community>> getUserCommunities(int userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/communities/user/$userId'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        
        if (responseData.containsKey('data')) {
          final List<dynamic> data = responseData['data']['data'] ?? [];
          return data.map((json) => Community.fromJson(json)).toList();
        } else {
          return [];
        }
      } else if (response.statusCode == 404) {
        print('API endpoint not found: ${response.body}');
        return [];
      } else {
        print('API error response: ${response.body}');
        throw Exception('Failed to load communities: ${response.statusCode}');
      }
    } catch (e) {
      print('Exception during API call: $e');
      throw Exception('Failed to load communities: $e');
    }
  }
}
