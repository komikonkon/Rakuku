/// 環境変数（ビルド時 --dart-define / --dart-define-from-file で注入）。
///
/// 実行例:
///   flutter run --dart-define-from-file=env.json
///
/// env.json（gitignore 済み）:
///   { "SUPABASE_URL": "https://xxxx.supabase.co", "SUPABASE_ANON_KEY": "..." }
class Env {
  const Env._();

  static const String supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const String supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  /// Supabase 接続情報が揃っているか。未設定でもアプリは起動できる
  /// （ローカルでUI確認するため）。揃っていない場合は接続系を初期化しない。
  static bool get isSupabaseConfigured =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;
}
