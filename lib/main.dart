import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'data/datasources/product_local_data_source.dart';
import 'data/datasources/product_remote_data_source.dart';
import 'data/repositories/product_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final preferences = await SharedPreferences.getInstance();

  final repository = ProductRepository(
    remote: ProductRemoteDataSource(client: http.Client()),
    local: SharedPreferencesProductCache(preferences),
  );

  runApp(ProductExplorerApp(repository: repository));
}
