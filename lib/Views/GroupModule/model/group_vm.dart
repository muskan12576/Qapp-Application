import 'dart:convert';
import 'package:qapp/Model/base_view_model.dart';
import 'package:qapp/Services/api_service.dart';
import 'package:qapp/Utills/app_constants.dart';

class GroupViewModel extends BaseViewModel {
  GroupViewModel._();
  static final GroupViewModel instance = GroupViewModel._();

  final ApiBaseService _api = ApiBaseService();

  Future<Map<String, dynamic>?> createGroup({
    required String title,
    String? photoUrl,
    List<String> memberIds = const [],
  }) async {
    final payload = <String, dynamic>{'title': title, 'memberIds': memberIds};
    if (photoUrl != null) payload['photoUrl'] = photoUrl;
    final res = await _api.postRequest(AppConstants.groupApi, payload);
    if (res != null && (res.statusCode == 200 || res.statusCode == 201)) {
      final json = jsonDecode(res.body);
      return Map<String, dynamic>.from(json['data']?['group'] ?? {});
    }
    return null;
  }

  Future<List<Map<String, dynamic>>> getUserGroups() async {
    final res = await _api.getRequest(AppConstants.groupApi);
    if (res != null && res.statusCode == 200) {
      final json = jsonDecode(res.body);
      final list = json['data']?['groups'] as List? ?? [];
      return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    }
    return [];
  }

  Future<Map<String, dynamic>?> getGroupDetails(String groupId) async {
    final res = await _api.getRequest(AppConstants.groupDetailsApi(groupId));
    if (res != null && res.statusCode == 200) {
      final json = jsonDecode(res.body);
      return Map<String, dynamic>.from(json['data']?['group'] ?? {});
    }
    return null;
  }

  Future<bool> addMembers(String groupId, List<String> memberIds) async {
    final res = await _api.postRequest(AppConstants.groupMembersApi(groupId), {'memberIds': memberIds});
    return res != null && res.statusCode == 200;
  }

  Future<bool> removeMember(String groupId, String userId) async {
    final res = await _api.deleteRequest('${AppConstants.groupMembersApi(groupId)}/$userId');
    return res != null && res.statusCode == 200;
  }

  Future<bool> setMemberRole(String groupId, String userId, String role) async {
    final res = await _api.putRequest(AppConstants.groupAdminApi(groupId), {
      'userId': userId,
      'role': role,
    });
    return res != null && res.statusCode == 200;
  }

  Future<bool> leaveGroup(String groupId) async {
    final res = await _api.postRequest(AppConstants.groupLeaveApi(groupId), {});
    return res != null && res.statusCode == 200;
  }
}
