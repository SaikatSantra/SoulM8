import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../features/auth/presentation/auth_controller.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/auth/presentation/register_screen.dart';
import '../features/profile/presentation/profile_screen.dart';
import '../features/human_chat/presentation/human_chat_screen.dart';
import '../features/ai_companion/presentation/ai_chat_screen.dart';
import '../features/ai_companion/presentation/memories_screen.dart';
import '../features/ai_companion/presentation/gallery_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authControllerProvider);

  return GoRouter(
    initialLocation: '/profile',
    redirect: (context, state) {
      if (authState.isLoading) return null;

      final isAuth = authState.isAuthenticated;
      final isAuthRoute = state.matchedLocation == '/login' || state.matchedLocation == '/register';

      if (!isAuth && !isAuthRoute) {
        return '/login';
      }
      if (isAuth && isAuthRoute) {
        return '/profile';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: '/chat/:friendId',
        builder: (context, state) {
          final friendId = state.pathParameters['friendId']!;
          final friendData = state.extra as Map<String, dynamic>?;
          return HumanChatScreen(friendId: friendId, friendData: friendData);
        },
      ),
      GoRoute(
        path: '/ai-chat',
        builder: (context, state) => const AIChatScreen(),
      ),
      GoRoute(
        path: '/memories',
        builder: (context, state) => const MemoriesScreen(),
      ),
      GoRoute(
        path: '/gallery',
        builder: (context, state) => const GalleryScreen(),
      ),
    ],
  );
});
