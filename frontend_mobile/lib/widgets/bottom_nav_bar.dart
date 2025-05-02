import 'package:flutter/material.dart';

class BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final void Function(BuildContext, int) onNavigate;

  const BottomNavBar({
    Key? key,
    required this.currentIndex,
    required this.onNavigate,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: (index) => onNavigate(context, index),
      selectedItemColor: const Color(0xFFFFB5B2),
      unselectedItemColor: Colors.grey,
      showUnselectedLabels: false,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Inicio'),
        BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Buscar'),
        BottomNavigationBarItem(icon: Icon(Icons.add), label: 'Publicar'),
        BottomNavigationBarItem(icon: Icon(Icons.checkroom), label: 'Armario'),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Perfil'),
      ],
    );
  }
}
