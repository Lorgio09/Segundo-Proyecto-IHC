import 'package:flutter/material.dart';

/// Tema visual para UniSport con estilo de bordes definidos y estética deportiva moderna (IHC)
class TemaApp {
  // Paleta de colores principales
  static const Color fondo = Color(0xFFF8FAFC);
  static const Color superficie = Color(0xFFFFFFFF);
  static const Color textoPrincipal = Color(0xFF0F172A);
  static const Color textoSecundario = Color(0xFF64748B);
  static const Color borde = Color(0xFF0F172A);
  
  // Colores de acento deportivo
  static const Color verdeDeportivo = Color(0xFF10B981);
  static const Color azulDeportivo = Color(0xFF6366F1);
  static const Color rojoAlerta = Color(0xFFEF4444);
  static const Color amarilloInsignia = Color(0xFFFEF08A);

  // Grosor de bordes para el estilo con bordes definidos
  static const double grosorBorde = 2.5;
  static const double grosorBordeAncho = 3.5;

  static ThemeData get tema {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: fondo,
      fontFamily: 'sans-serif',
      colorScheme: ColorScheme.fromSeed(
        seedColor: azulDeportivo,
        primary: textoPrincipal,
        secondary: verdeDeportivo,
        surface: superficie,
        error: rojoAlerta,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: superficie,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: textoPrincipal,
          fontSize: 20,
          fontWeight: FontWeight.w900,
          letterSpacing: -0.5,
        ),
        iconTheme: IconThemeData(color: textoPrincipal),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: superficie,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        labelStyle: const TextStyle(
          color: textoSecundario,
          fontWeight: FontWeight.w600,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: borde, width: grosorBorde),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: borde, width: grosorBorde),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: azulDeportivo, width: grosorBordeAncho),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: rojoAlerta, width: grosorBorde),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: rojoAlerta, width: grosorBordeAncho),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: textoPrincipal,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 54),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: borde, width: grosorBorde),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.3,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: textoPrincipal,
          backgroundColor: superficie,
          minimumSize: const Size(double.infinity, 52),
          side: const BorderSide(color: borde, width: grosorBorde),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}
