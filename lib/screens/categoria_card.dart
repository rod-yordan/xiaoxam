// widgets/categoria_card_vertical.dart
import 'package:flutter/material.dart';

class CategoriaCard extends StatelessWidget {
  final String titulo;
  final String? imagenPath; // 👈 ahora puede ser null
  final VoidCallback onTap;

  const CategoriaCard({
    super.key,
    required this.titulo,
    this.imagenPath, // 👈 ya no required
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withAlpha(25),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Imagen de fondo (red o placeholder)
              if (imagenPath != null && imagenPath!.isNotEmpty)
                Image.network(
                  imagenPath!,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      color: Colors.grey.shade200,
                      child: const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFFED1C24),
                          strokeWidth: 2,
                        ),
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey.shade200,
                      child: const Center(
                        child: Icon(
                          Icons.broken_image,
                          color: Colors.grey,
                          size: 40,
                        ),
                      ),
                    );
                  },
                )
              else
                // Placeholder mientras carga la URL del primer producto
                Container(
                  color: Colors.grey.shade200,
                  child: const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFFED1C24),
                      strokeWidth: 2,
                    ),
                  ),
                ),

              // Franja semitransparente en la parte inferior
              Positioned(
                bottom: 12,
                left: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(217), // 0.85 opacidad
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    titulo,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
