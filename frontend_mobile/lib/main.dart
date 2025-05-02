import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'viewmodels/login_viewmodel.dart';
import 'viewmodels/register_viewmodel.dart';
import 'viewmodels/create_post_viewmodel.dart';
import 'viewmodels/feed_viewmodel.dart';
import 'viewmodels/comments_viewmodel.dart';
import 'viewmodels/likes_viewmodel.dart';
import 'viewmodels/forgotpassword_viewmodel.dart';
import 'viewmodels/resetpassword_viewmodel.dart';
import 'views/login_screen.dart';
import 'viewmodels/group_viewmodel.dart';
import 'viewmodels/messages_viewmodel.dart';
import 'viewmodels/search_viewmodel.dart';
import 'viewmodels/group_messages_viewmodel.dart';
import 'viewmodels/notifications_viewmodel.dart';
import 'viewmodels/profile_viewmodel.dart';
import 'viewmodels/favorites_viewmodel.dart';
import 'viewmodels/create_prenda_viewmodel.dart';
import 'viewmodels/miarmario_viewmodel.dart';
import 'viewmodels/edit_prenda_viewmodel.dart';
import 'viewmodels/perfil_usuario_viewmodel.dart';
import 'viewmodels/prenda_detail_viewmodel.dart';
import 'viewmodels/post_viewmodel.dart';
import 'services/likes_notifier.dart';
import 'services/favorites_notifier.dart';
import 'viewmodels/direct_messages_viewmodel.dart';
import 'viewmodels/configuracion_viewmodel.dart';

final RouteObserver<PageRoute> routeObserver = RouteObserver<PageRoute>();

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LoginViewModel()),
        ChangeNotifierProvider(create: (_) => RegisterViewModel()),
        ChangeNotifierProvider(create: (_) => CreatePostViewModel()),
        ChangeNotifierProvider(create: (_) => CommentViewModel()),
        ChangeNotifierProvider(create: (_) => LikeViewModel()),
        ChangeNotifierProvider(create: (_) => ForgotPasswordViewModel()),
        ChangeNotifierProvider(create: (_) => ResetPasswordViewModel()),
        ChangeNotifierProvider(create: (_) => GroupViewModel()),
        ChangeNotifierProvider(create: (_) => MessagesViewModel()),
        ChangeNotifierProvider(create: (_) => DirectMessagesViewModel()),
        ChangeNotifierProvider(create: (_) => GroupMessagesViewModel()),
        ChangeNotifierProvider(create: (_) => SearchViewModel()),
        ChangeNotifierProvider(create: (_) => GroupMessagesViewModel()),
        ChangeNotifierProvider(create: (_) => NotificationsViewModel()),
        ChangeNotifierProvider(create: (_) => ProfileViewModel()),
        ChangeNotifierProvider(create: (_) => FeedViewModel()),
        ChangeNotifierProvider(create: (_) => FavoritesViewModel()),
        ChangeNotifierProvider(create: (_) => CreatePrendaViewModel()),
        ChangeNotifierProvider(create: (_) => MiArmarioViewModel()),
        ChangeNotifierProvider(create: (_) => EditPrendaViewModel()),
        ChangeNotifierProvider(create: (_) => PerfilUsuarioViewModel()),
        ChangeNotifierProvider(create: (_) => PrendaDetailViewModel()),
        ChangeNotifierProvider(create: (_) => PostViewModel()),
        ChangeNotifierProvider(create: (_) => LikesNotifier()),
        ChangeNotifierProvider(create: (_) => FavoritesNotifier()),
        ChangeNotifierProvider(create: (_) => SettingsViewModel()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Looksy',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Quicksand',
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFFFB5B2)),
        useMaterial3: true,
      ),
      home: LoginScreen(), // Cambia a FeedScreen si quieres probar directamente
    );
  }
}
