// feed_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/feed_viewmodel.dart';
import '../widgets/bottom_nav_bar.dart';
import '../widgets/post_card.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/likes_notifier.dart';
import '../services/favorites_notifier.dart';
import 'login_screen.dart';
import 'group_screen.dart';
import 'search_screen.dart';
import 'notifications_screen.dart';
import 'profile_screen.dart';
import 'miarmario_screen.dart';
import 'create_post_screen.dart';
import 'post_detail_screen.dart';
import '../models/post.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  int _selectedIndex = 0;

  final List<Widget> _pantallas = [
    const FeedContent(),
    const SearchScreen(),
    Container(),
    Container(),
    const ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final vm = Provider.of<FeedViewModel>(context, listen: false);
      final likesNotifier = Provider.of<LikesNotifier>(context, listen: false);
      final favoritesNotifier = Provider.of<FavoritesNotifier>(
        context,
        listen: false,
      );

      await vm.cargarFeed();

      likesNotifier.setLikes(
        {for (var p in vm.publicaciones) p.id: p.haDadoLike},
        {for (var p in vm.publicaciones) p.id: p.likesCount},
      );

      favoritesNotifier.setGuardados({
        for (var p in vm.publicaciones)
          if (p.guardado) p.id,
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pantallas[_selectedIndex],
      bottomNavigationBar: BottomNavBar(
        currentIndex: 0,
        onNavigate: (context, index) {
          switch (index) {
            case 0:
              break;
            case 1:
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const SearchScreen()),
              );
              break;
            case 2:
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const CreatePostScreen()),
              );
              break;
            case 3:
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const MiArmarioScreen()),
              );
              break;
            case 4:
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              );
              break;
          }
        },
      ),
    );
  }
}

class FeedContent extends StatelessWidget {
  const FeedContent({super.key});

  void _logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt_token');

    if (!context.mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = Provider.of<FeedViewModel>(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFF0F0),
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Icons.logout),
          color: const Color(0xFFFFB5B2),
          onPressed: () => _logout(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none),
            color: const Color(0xFFFFB5B2),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NotificationsScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.send),
            color: const Color(0xFFFFB5B2),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const GroupScreen()),
              );
            },
          ),
        ],
      ),
      body:
          vm.isLoading
              ? const Center(child: CircularProgressIndicator())
              : vm.publicaciones.isEmpty
              ? const Center(
                child: Text(
                  "No hay publicaciones aún",
                  style: TextStyle(color: Colors.grey),
                ),
              )
              : ListView.builder(
                itemCount: vm.publicaciones.length,
                itemBuilder: (context, index) {
                  final post = vm.publicaciones[index];
                  return Consumer2<LikesNotifier, FavoritesNotifier>(
                    builder: (context, likesNotifier, favoritesNotifier, _) {
                      final isLiked = likesNotifier.isLiked(post.id);
                      final isSaved = favoritesNotifier.isSaved(post.id);

                      return GestureDetector(
                        onTap: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => PostDetailScreen(post: post),
                            ),
                          );

                          if (result != null && result is PostModel) {
                            vm.actualizarPost(result);
                            likesNotifier.toggleLike(
                              result.id,
                              result.haDadoLike,
                              result.likesCount,
                            );
                            favoritesNotifier.toggleSave(
                              result.id,
                              result.guardado,
                            );
                          }
                        },
                        child: PostCard(
                          post: post.copyWith(
                            haDadoLike: isLiked,
                            guardado: isSaved,
                          ),
                          onLikeToggled: (updated) {
                            vm.actualizarPost(updated);
                            likesNotifier.toggleLike(
                              updated.id,
                              updated.haDadoLike,
                              updated.likesCount,
                            );
                          },
                          onSaveToggled: (updated) {
                            vm.actualizarPost(updated);
                            favoritesNotifier.toggleSave(
                              updated.id,
                              updated.guardado,
                            );
                          },
                        ),
                      );
                    },
                  );
                },
              ),
    );
  }
}
