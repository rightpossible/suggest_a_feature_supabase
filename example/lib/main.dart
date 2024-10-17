import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:suggest_a_feature/suggest_a_feature.dart';
import 'package:suggest_a_feature_supabase/suggest_a_feature_supabase.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://your-supabase-url.supabase.co',
    anonKey: 'your anon key',
  );
  initializeDateFormatting();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Suggest a Feature supabase example',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const SuggestAFeaturePage(),
    );
  }
}

class SuggestAFeaturePage extends StatelessWidget {
  const SuggestAFeaturePage({
    super.key,
  });

  static Route<void> route() {
    return MaterialPageRoute<void>(
      builder: (context) => const SuggestAFeaturePage(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;

    final theme = Theme.of(context);

    return SuggestionsPage(
      userId: user!.id,
      suggestionsDataSource: SupabaseSuggestionsDatasource(
        userId: user.id,
        supabaseClient: Supabase.instance.client,
        // isAdmin: true,
      ),
      theme: SuggestionsTheme(
        backgroundColor: theme.colorScheme.surface,
        actionColor: theme.colorScheme.primaryContainer,
        actionPressedColor: theme.colorScheme.primary,
        actionBackgroundColor: theme.colorScheme.primary,
        disabledTextColor: theme.colorScheme.onSurfaceVariant,
        upvoteArrowColor: theme.colorScheme.tertiary,
        requestsTabColor: theme.colorScheme.secondary,
        inProgressTabColor: theme.colorScheme.secondaryContainer,
        completedTabColor: theme.colorScheme.tertiaryContainer,
        declinedTabColor: theme.colorScheme.error,
        duplicatedTabColor: theme.colorScheme.errorContainer,
        featureLabelColor: theme.colorScheme.tertiary,
        bugLabelColor: theme.colorScheme.error,
        fabColor: theme.colorScheme.primary,
        fade: theme.colorScheme.surface,
      ),
      // onUploadMultiplePhotos: _handlePhotoUpload,
      // onSaveToGallery: ,
      onGetUserById: (id) async {
        return SuggestionAuthor(id: id, username: user.email ?? 'user');
      },
      locale: 'en',
    );
  }

  Future<List<String>> _handlePhotoUpload(List<String> localPaths) async {
    // Implement photo upload logic here
    // Return a list of uploaded photo URLs
    return [];
  }

  Future<void> _handleSaveToGallery(String url) async {
    // Implement save to gallery logic here
  }

  Future<Map<String, dynamic>> _getUserById(String userId) async {
    // Implement user fetching logic here
    return {};
  }
}
