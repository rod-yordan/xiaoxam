class NavbarItem {
  final String tipo;
  final String nombre;
  final String valor;
  final List<NavbarSubitem> subitems;

  NavbarItem({
    required this.tipo,
    required this.nombre,
    required this.valor,
    this.subitems = const [],
  });

  factory NavbarItem.fromJson(Map<String, dynamic> json) {
    return NavbarItem(
      tipo: json['tipo'] ?? '',
      nombre: json['nombre'] ?? '',
      valor: json['valor'] ?? '',
      subitems:
          (json['subitems'] as List<dynamic>?)
              ?.map((e) => NavbarSubitem.fromJson(e))
              .toList() ??
          [],
    );
  }
}

class NavbarSubitem {
  final String nombre;
  final String valor;

  NavbarSubitem({required this.nombre, required this.valor});

  factory NavbarSubitem.fromJson(Map<String, dynamic> json) {
    return NavbarSubitem(
      nombre: json['nombre'] ?? '',
      valor: json['valor'] ?? '',
    );
  }
}
