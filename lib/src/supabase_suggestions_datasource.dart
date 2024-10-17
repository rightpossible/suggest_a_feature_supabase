import 'package:suggest_a_feature/suggest_a_feature.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

enum _Entity { suggestion, comment }

class SupabaseSuggestionsDatasource implements SuggestionsDataSource {
  static const String _suggestionIdFieldName = 'suggestion_id';
  static const String _authorIdFieldName = 'author_id';
  static const String _commentIdFieldName = 'comment_id';
  static const String _votedUsersArrayName = 'voted_user_ids';
  static const String _notificationsUsersArrayName = 'notify_user_ids';

  final String suggestionsTableName;
  final String commentsTableName;

  final SupabaseClient supabaseClient;

  @override
  final String userId;
  final bool isAdmin;

  SupabaseSuggestionsDatasource({
    required this.userId,
    required this.supabaseClient,
    this.isAdmin = false,
    this.suggestionsTableName = 'suggest_a_feature_suggestions',
    this.commentsTableName = 'suggest_a_feature_comments',
  });

  @override
  Future<Suggestion> getSuggestionById(String suggestionId) async {
    print('Attempting to fetch suggestion with ID: $suggestionId');
    final response = await supabaseClient
        .from(suggestionsTableName)
        .select()
        .eq(_suggestionIdFieldName, suggestionId)
        .single();

    print('Fetched suggestion with ID: $suggestionId');
    return Suggestion.fromJson(json: response);
  }

  @override
  Future<List<Suggestion>> getAllSuggestions() async {
    print('Fetching all suggestions');
    final response = await supabaseClient.from(suggestionsTableName).select();

    print('Fetched ${response.toList()} suggestions');
    return response.isNotEmpty
        ? response.map((json) => Suggestion.fromJson(json: json)).toList()
        : [];
  }

  @override
  Future<Suggestion> createSuggestion(CreateSuggestionModel suggestion) async {
    print('Attempting to create a new suggestion');
    final response = await supabaseClient
        .from(suggestionsTableName)
        .insert(suggestion.toJson())
        .select()
        .single();

    print('Created a new suggestion');
    return Suggestion.fromJson(json: response);
  }

  @override
  Future<Suggestion> updateSuggestion(Suggestion suggestion) async {
    print('Attempting to update suggestion with ID: ${suggestion.id}');
    if (!await _isUserAuthor(_Entity.suggestion, suggestion.id) && !isAdmin) {
      throw Exception(
        'Failed to update the suggestion. User has no author rights',
      );
    }

    final response = await supabaseClient
        .from(suggestionsTableName)
        .update(suggestion.toUpdatingJson())
        .eq(_suggestionIdFieldName, suggestion.id)
        .select()
        .single();

    print('Updated suggestion with ID: ${suggestion.id}');
    return Suggestion.fromJson(json: response);
  }

  @override
  Future<void> deleteSuggestionById(String suggestionId) async {
    print('Attempting to delete suggestion with ID: $suggestionId');
    if (!await _isUserAuthor(_Entity.suggestion, suggestionId) && !isAdmin) {
      throw Exception(
        'Failed to delete the suggestion. User has no author rights',
      );
    }

    await supabaseClient
        .from(suggestionsTableName)
        .delete()
        .eq(_suggestionIdFieldName, suggestionId);

    print('Deleted suggestion with ID: $suggestionId');
    await _commentsBatchDelete(suggestionId);
  }

  @override
  Future<List<Comment>> getAllComments(String suggestionId) async {
    print('Fetching comments for suggestion with ID: $suggestionId');
    final response = await supabaseClient
        .from(commentsTableName)
        .select()
        .eq(_suggestionIdFieldName, suggestionId);

    print(
      'Fetched ${response.length} comments for suggestion with ID: $suggestionId',
    );
    return response.isNotEmpty
        ? response.map((json) => Comment.fromJson(json: json)).toList()
        : [];
  }

  @override
  Future<Comment> createComment(CreateCommentModel comment) async {
    print(
      'Attempting to create a new comment for suggestion with ID: ${comment.suggestionId}',
    );
    final response = await supabaseClient
        .from(commentsTableName)
        .insert(comment.toJson())
        .select()
        .single();

    print(
      'Created a new comment for suggestion with ID: ${comment.suggestionId}',
    );
    return Comment.fromJson(json: response);
  }

  @override
  Future<void> deleteCommentById(String commentId) async {
    print('Attempting to delete comment with ID: $commentId');
    if (!await _isUserAuthor(_Entity.comment, commentId) && !isAdmin) {
      throw Exception(
        'Failed to delete the comment. User has no author rights',
      );
    }

    await supabaseClient
        .from(commentsTableName)
        .delete()
        .eq(_commentIdFieldName, commentId);

    print('Deleted comment with ID: $commentId');
  }

  Future<void> _commentsBatchDelete(String suggestionId) async {
    print('Deleting all comments for suggestion with ID: $suggestionId');
    await supabaseClient
        .from(commentsTableName)
        .delete()
        .eq(_suggestionIdFieldName, suggestionId);

    print('Deleted all comments for suggestion with ID: $suggestionId');
  }

  @override
  Future<void> addNotifyToUpdateUser(String suggestionId) async {
    print(
      'Attempting to add notification for user with ID: $userId to suggestion with ID: $suggestionId',
    );
    final userIdsToNotify = await _getSuggestionNotifications(suggestionId);
    if (userIdsToNotify.contains(userId)) {
      throw Exception(
        'Failed to add notification. User is already in notify list',
      );
    }

    await supabaseClient.from(suggestionsTableName).update({
      _notificationsUsersArrayName: [...userIdsToNotify, userId],
    }).eq(_suggestionIdFieldName, suggestionId);

    print(
      'Added notification for user with ID: $userId to suggestion with ID: $suggestionId',
    );
  }

  @override
  Future<void> deleteNotifyToUpdateUser(String suggestionId) async {
    print(
      'Attempting to remove notification for user with ID: $userId from suggestion with ID: $suggestionId',
    );
    final userIdsToNotify = await _getSuggestionNotifications(suggestionId);
    if (!userIdsToNotify.contains(userId)) {
      throw Exception(
        'Failed to remove notification. User is not in notify list',
      );
    }
    userIdsToNotify.remove(userId);

    await supabaseClient
        .from(suggestionsTableName)
        .update({_notificationsUsersArrayName: userIdsToNotify}).eq(
      _suggestionIdFieldName,
      suggestionId,
    );

    print(
      'Removed notification for user with ID: $userId from suggestion with ID: $suggestionId',
    );
  }

  @override
  Future<void> upvote(String suggestionId) async {
    print('Attempting to upvote suggestion with ID: $suggestionId');
    final votedUserIds = await _getSuggestionVotes(suggestionId);
    if (votedUserIds.contains(userId)) {
      throw Exception(
        'Failed to vote for the suggestion. User has already voted',
      );
    }

    await supabaseClient.from(suggestionsTableName).update({
      _votedUsersArrayName: [...votedUserIds, userId],
    }).eq(_suggestionIdFieldName, suggestionId);

    print('Upvoted suggestion with ID: $suggestionId');
  }

  @override
  Future<void> downvote(String suggestionId) async {
    print('Attempting to downvote suggestion with ID: $suggestionId');
    final votedUserIds = await _getSuggestionVotes(suggestionId);
    if (!votedUserIds.contains(userId)) {
      throw Exception(
        'Failed to remove the vote for the suggestion. '
        'User has not voted earlier',
      );
    }
    votedUserIds.remove(userId);

    await supabaseClient
        .from(suggestionsTableName)
        .update({_votedUsersArrayName: votedUserIds}).eq(
      _suggestionIdFieldName,
      suggestionId,
    );

    print('Downvoted suggestion with ID: $suggestionId');
  }

  Future<List<String>> _getSuggestionVotes(String suggestionId) async {
    print('Fetching votes for suggestion with ID: $suggestionId');
    final suggestion = await supabaseClient
        .from(suggestionsTableName)
        .select(_votedUsersArrayName)
        .eq(_suggestionIdFieldName, suggestionId)
        .single();

    print('Fetched votes for suggestion with ID: $suggestionId');
    final votes = suggestion[_votedUsersArrayName] as List<dynamic>?;
    return votes == null ? [] : votes.cast<String>();
  }

  Future<List<String>> _getSuggestionNotifications(String suggestionId) async {
    print('Fetching notifications for suggestion with ID: $suggestionId');
    final suggestion = await supabaseClient
        .from(suggestionsTableName)
        .select(_notificationsUsersArrayName)
        .eq(_suggestionIdFieldName, suggestionId)
        .single();

    print('Fetched notifications for suggestion with ID: $suggestionId');
    final notifications =
        suggestion[_notificationsUsersArrayName] as List<dynamic>?;
    return notifications == null ? [] : notifications.cast<String>();
  }

  Future<bool> _isUserAuthor(_Entity entity, String entityId) async {
    print(
      'Checking if user with ID: $userId is the author of $entity with ID: $entityId',
    );
    final response = await supabaseClient
        .from(
          entity == _Entity.suggestion
              ? suggestionsTableName
              : commentsTableName,
        )
        .select()
        .eq(_authorIdFieldName, userId)
        .eq(
          entity == _Entity.suggestion
              ? _suggestionIdFieldName
              : _commentIdFieldName,
          entityId,
        );

    print(
      'Checked if user with ID: $userId is the author of $entity with ID: $entityId',
    );
    return response.length == 1;
  }
}
