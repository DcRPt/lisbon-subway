import 'dart:io' as io;
import 'package:cmproject/connectivity_module.dart';
import 'package:cmproject/data/http_metro_datasource.dart';
import 'package:cmproject/data/sqflite_metro_datasource.dart';
import 'package:cmproject/gps_location_service.dart';
import 'package:cmproject/http/http_client.dart';
import 'package:cmproject/screens/main_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'connectivity_service.dart';
import 'data/generic_data_source.dart';
import 'data/my_generic_data_source.dart';
import 'location_module.dart';

class _HttpOverrides extends io.HttpOverrides {
  @override
  io.HttpClient createHttpClient(io.SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (io.X509Certificate cert, String host, int port) => true;
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  io.HttpOverrides.global = _HttpOverrides();

  final sqfliteDataSource = SqfliteMetroDataSource();
  await sqfliteDataSource.init();

  final httpClient = HttpClient();

  runApp(
    MultiProvider(
      providers: [
        Provider<HttpMetroDataSource>(
          create: (_) => HttpMetroDataSource(client: httpClient),
        ),
        Provider<SqfliteMetroDataSource>(
          create: (_) => sqfliteDataSource,
        ),
        Provider<ConnectivityModule>(
          create: (_) => ConnectivityService(),
        ),
        Provider<LocationModule>(create: (_) => GpsLocationService()),
        Provider<GenericDataSource>(
          create: (_) => MyGenericDataSource(client: httpClient, db: sqfliteDataSource.db),
        ),
      ],
      child: const MyApp(),
    )
  );
}

class MyApp extends StatelessWidget {

  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: const MainScreen(),
    );
  }
}