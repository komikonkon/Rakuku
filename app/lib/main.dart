import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/app.dart';
import 'core/env.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (Env.isSupabaseConfigured) {
    await Supabase.initialize(
      url: Env.supabaseUrl,
      anonKey: Env.supabaseAnonKey,
    );

    // 匿名スタート（要件 §5.6）: セッションが無ければ匿名サインイン。
    // オフライン等で失敗してもアプリは起動する（同期は後続で）。
    final auth = Supabase.instance.client.auth;
    if (auth.currentSession == null) {
      try {
        await auth.signInAnonymously();
      } catch (_) {
        // ネットワーク不通など。後続の同期処理でリトライする想定。
      }
    }
  }

  runApp(const ProviderScope(child: RakukuApp()));
}
