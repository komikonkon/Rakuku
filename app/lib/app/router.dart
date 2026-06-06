import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/add/add_item_screen.dart';
import '../features/detail/item_detail_screen.dart';
import '../features/home/home_screen.dart';
import '../features/review/review_config_screen.dart';
import '../features/review/review_result_screen.dart';
import '../features/review/review_session_screen.dart';
import '../features/settings/settings_screen.dart';

/// アプリのルーター（画面一覧 docs/screen-list.md に対応）。
final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        name: 'home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/items/:id',
        name: 'itemDetail',
        builder: (context, state) =>
            ItemDetailScreen(itemId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/add',
        name: 'add',
        builder: (context, state) => const AddItemScreen(),
      ),
      GoRoute(
        path: '/review',
        name: 'reviewConfig',
        builder: (context, state) => const ReviewConfigScreen(),
      ),
      GoRoute(
        path: '/review/session',
        name: 'reviewSession',
        builder: (context, state) => const ReviewSessionScreen(),
      ),
      GoRoute(
        path: '/review/result',
        name: 'reviewResult',
        builder: (context, state) => const ReviewResultScreen(),
      ),
      GoRoute(
        path: '/settings',
        name: 'settings',
        builder: (context, state) => const SettingsScreen(),
      ),
    ],
  );
});
