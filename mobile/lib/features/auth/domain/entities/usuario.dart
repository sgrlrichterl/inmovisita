/// Roles soportados por el sistema. Se materializan como *custom claims* del
/// token de Firebase Auth y se validan tambien en las reglas de Firestore.
enum RolUsuario {
  asesor,
  coordinador,
  admin;

  static RolUsuario fromString(String? value) {
    return RolUsuario.values.firstWhere(
      (r) => r.name == value,
      orElse: () => RolUsuario.asesor,
    );
  }

  bool get puedeVerTodasLasVisitas =>
      this == RolUsuario.coordinador || this == RolUsuario.admin;
}

/// Usuario autenticado de la aplicacion.
class Usuario {
  const Usuario({
    required this.uid,
    required this.nombre,
    required this.email,
    required this.rol,
  });

  factory Usuario.fromMap(Map<String, Object?> map) {
    return Usuario(
      uid: map['uid']! as String,
      nombre: (map['nombre'] ?? '') as String,
      email: (map['email'] ?? '') as String,
      rol: RolUsuario.fromString(map['rol'] as String?),
    );
  }

  final String uid;
  final String nombre;
  final String email;
  final RolUsuario rol;

  Map<String, Object?> toMap() => <String, Object?>{
        'uid': uid,
        'nombre': nombre,
        'email': email,
        'rol': rol.name,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      };

  String get iniciales {
    final partes = nombre.trim().split(RegExp(r'\s+'));
    if (partes.isEmpty || partes.first.isEmpty) {
      return '?';
    }
    if (partes.length == 1) {
      return partes.first.substring(0, 1).toUpperCase();
    }
    return (partes.first.substring(0, 1) + partes[1].substring(0, 1))
        .toUpperCase();
  }
}
