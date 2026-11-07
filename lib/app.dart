import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_theme.dart';
import 'data/repositories/product_repository.dart';
import 'presentation/providers/product_list_provider.dart';
import 'presentation/screens/product_list_screen.dart';

/// Root widget. The repository is injected so tests can supply a fake API.
class ProductExplorerApp extends StatelessWidget {
  const ProductExplorerApp({super.key, required this.repository});

  final ProductRepository repository;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<ProductRepository>.value(value: repository),
        ChangeNotifierProvider<ProductListProvider>(
          create: (_) => ProductListProvider(repository: repository)..loadInitial(),
        ),
      ],
      child: MaterialApp(
        title: 'Product Explorer',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        home: const ProductListScreen(),
      ),
    );
  }
}
