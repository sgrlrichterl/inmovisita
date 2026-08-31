import 'package:flutter/material.dart';

/// Contenedor con borde suave usado en listas y paneles.
///
/// Se define como widget propio en lugar de un `CardTheme` global para no
/// depender de APIs de tema que cambian entre versiones de Flutter.
class Tarjeta extends StatelessWidget {
  const Tarjeta({
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(16),
    super.key,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Material(
        color: esquema.surface,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: esquema.outlineVariant),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
