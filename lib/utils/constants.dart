import 'package:flutter/material.dart';

// Colores de la aplicación
class AppColors {
  static const Color primary = Color(0xFF2196F3);
  static const Color background = Color(0xFF121212);
  static const Color card = Color(0xFF1E1E1E);
  static const Color text = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFAAAAAA);
  static const Color error = Color(0xFFCF6679);
}

// Textos comunes
class AppStrings {
  static const String appName = 'IPTV Player';
  static const String login = 'Iniciar Sesión';
  static const String register = 'Registrarse';
  static const String email = 'Correo Electrónico';
  static const String password = 'Contraseña';
  static const String username = 'Nombre de Usuario';
  static const String m3uUrl = 'URL de lista M3U';
  static const String channels = 'Canales';
}

// Estilos de texto
class AppTextStyles {
  static const TextStyle heading = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: AppColors.text,
  );

  static const TextStyle body = TextStyle(
    fontSize: 16,
    color: AppColors.text,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 14,
    color: AppColors.textSecondary,
  );
}