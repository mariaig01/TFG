import 'package:flutter/material.dart';

class ArmarioNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const ArmarioNavBar({
    Key? key,
    required this.currentIndex,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: onTap,
      selectedItemColor: Color(0xFFFFB5B2),
      unselectedItemColor: Colors.grey,
      showUnselectedLabels: false,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.auto_awesome), label: 'IA'),
        BottomNavigationBarItem(
          icon: Icon(Icons.bar_chart_rounded),
          label: 'Gráficos',
        ),
        BottomNavigationBarItem(icon: Icon(Icons.checkroom), label: 'Armario'),
        BottomNavigationBarItem(
          icon: Icon(Icons.face_retouching_natural),
          label: 'Asistente',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.local_offer),
          label: 'Comparador',
        ),
      ],
    );
  }
}
