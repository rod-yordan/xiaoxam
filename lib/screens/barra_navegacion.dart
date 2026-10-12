import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

class BarraNavegacion extends StatelessWidget {
  final int currentIndex;
  final Function(int)? onTap;

  const BarraNavegacion({super.key, required this.currentIndex, this.onTap});

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      type: BottomNavigationBarType.fixed,
      onTap: onTap,
      elevation: 8,
      backgroundColor: Colors.white,
      // 👇 Ambos en negro (antes seleccionado negro y no seleccionado gris)
      selectedItemColor: Colors.black,
      unselectedItemColor: Colors.black,
      selectedLabelStyle: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color: Colors.black,
      ),
      unselectedLabelStyle: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.normal,
        color: Colors.black,
      ),
      items: [
        BottomNavigationBarItem(
          icon: Icon(Symbols.home, fill: currentIndex == 0 ? 1 : 0),
          label: 'Inicio',
        ),
        BottomNavigationBarItem(
          icon: Icon(Symbols.grid_view, fill: currentIndex == 1 ? 1 : 0),
          label: 'Catálogo',
        ),
        BottomNavigationBarItem(
          icon: Icon(Symbols.local_offer, fill: currentIndex == 2 ? 1 : 0),
          label: 'Cupones',
        ),
        BottomNavigationBarItem(
          icon: Icon(Symbols.favorite, fill: currentIndex == 3 ? 1 : 0),
          label: 'Favoritos',
        ),
        BottomNavigationBarItem(
          icon: Icon(Symbols.person, fill: currentIndex == 4 ? 1 : 0),
          label: 'Mi cuenta',
        ),
      ],
    );
  }
}
