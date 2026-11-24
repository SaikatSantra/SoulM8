import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'routes.dart';
import 'theme.dart';

class Soulm8App extends ConsumerWidget {
  const Soulm8App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Soulm8',
      debugShowCheckedModeBanner: false,
      theme: Soulm8Theme.darkTheme,
      routerConfig: router,
    );
  }
}
