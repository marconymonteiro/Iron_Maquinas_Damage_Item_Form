// DESENVOLVIDO POR BETA EYES
// @COPYRIGHT TODOS OS DIREITOS RESERVADOS
// O USO INDEVIDO, CÓPIA OU DISTRIBUIÇÃO SEM CONSULTA PRÉVIA É PASSÍVEL DE SANÇÕES LEGAIS 

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart'; // Suporte à localização
import 'home_screen.dart'; // Importa a tela inicial

void main() {
  runApp(InspectionApp());
}

class InspectionApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false, // Desativa o banner de debug
      home: HomeScreen(), // Tela inicial
      supportedLocales: const [
        Locale('pt', 'BR'), // Apenas Português do Brasil
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate, // Suporte para widgets Material
        GlobalWidgetsLocalizations.delegate, // Suporte para widgets
        GlobalCupertinoLocalizations.delegate, // Suporte para widgets Cupertino
      ],
    );
  }
}
