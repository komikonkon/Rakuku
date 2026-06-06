import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'router.dart';
import 'theme.dart';

class RakukuApp extends ConsumerWidget {
  const RakukuApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: 'Rakuku',
      debugShowCheckedModeBanner: false,
      theme: buildLightTheme(),
      routerConfig: router,
    );
  }
}
