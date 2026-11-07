import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models/product.dart';
import '../providers/product_list_provider.dart';
import '../widgets/offline_banner.dart';
import '../widgets/product_card.dart';
import '../widgets/product_grid.dart';
import '../widgets/product_search_field.dart';
import '../widgets/state_views.dart';
import 'product_detail_screen.dart';

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key});

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  static const _searchDebounce = Duration(milliseconds: 450);
  static const _loadMoreThreshold = 600.0;
  static const _toolbarHeight = 76.0;
  static const _searchBarHeight = 68.0;

  final _scrollController = ScrollController();
  final _searchController = TextEditingController();
  Timer? _debounce;

  ProductListProvider get _provider => context.read<ProductListProvider>();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_maybeLoadMore);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  /// Loads the next page when the user nears the bottom, or when the first
  /// page doesn't fill the screen (e.g. on tablets).
  void _maybeLoadMore() {
    if (!mounted || !_scrollController.hasClients) return;
    final provider = _provider;
    if (!provider.canLoadMore) return;
    final position = _scrollController.position;
    if (position.maxScrollExtent - position.pixels <= _loadMoreThreshold) {
      provider.loadMore();
    }
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(_searchDebounce, () {
      if (mounted) _runSearch(value);
    });
  }

  void _onSearchSubmitted(String value) {
    _debounce?.cancel();
    _runSearch(value);
  }

  /// Runs the search and, once it has finished, drops focus from the search
  /// field (closing the keyboard and hiding the cursor). Focus is kept if the
  /// user has typed something new in the meantime.
  Future<void> _runSearch(String value) async {
    await _provider.search(value);
    if (!mounted || _searchController.text != value) return;
    FocusManager.instance.primaryFocus?.unfocus();
  }

  void _clearSearch() {
    _searchController.clear();
    _onSearchSubmitted('');
  }

  Future<void> _onRefresh() async {
    final hadProducts = _provider.products.isNotEmpty;
    final refreshed = await _provider.refresh();
    if (!refreshed && hadProducts && mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('Couldn’t refresh. Showing the products already loaded.')),
        );
    }
  }

  void _openProduct(Product product) {
    FocusScope.of(context).unfocus();
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => ProductDetailScreen(product: product)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProductListProvider>();
    if (provider.status == ProductListStatus.loaded) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _maybeLoadMore());
    }

    final topInset = MediaQuery.paddingOf(context).top;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        edgeOffset: topInset + _toolbarHeight + _searchBarHeight,
        child: CustomScrollView(
          controller: _scrollController,
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            _buildAppBar(context),
            if (provider.isOffline && provider.status == ProductListStatus.loaded)
              const SliverToBoxAdapter(
                child: OfflineBanner(
                  key: Key('offline_banner'),
                  message: 'You’re offline. Showing products saved from your last visit.',
                  margin: EdgeInsets.fromLTRB(16, 4, 16, 8),
                ),
              ),
            ..._buildContent(context, provider),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    final theme = Theme.of(context);
    return SliverAppBar(
      pinned: true,
      toolbarHeight: _toolbarHeight,
      titleSpacing: 20,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Product Explorer',
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Find something good',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.headlineSmall,
          ),
        ],
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(_searchBarHeight),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: ProductSearchField(
            controller: _searchController,
            onChanged: _onSearchChanged,
            onSubmitted: _onSearchSubmitted,
            onClear: _clearSearch,
          ),
        ),
      ),
    );
  }

  List<Widget> _buildContent(BuildContext context, ProductListProvider provider) {
    switch (provider.status) {
      case ProductListStatus.initial:
      case ProductListStatus.loading:
        return const [ProductGridSkeleton(key: Key('loading_view'))];

      case ProductListStatus.error:
        return [
          SliverFillRemaining(
            hasScrollBody: false,
            child: ErrorStateView(
              key: const Key('error_view'),
              error: provider.error!,
              onRetry: provider.retry,
            ),
          ),
        ];

      case ProductListStatus.empty:
        return [
          SliverFillRemaining(
            hasScrollBody: false,
            child: provider.isSearching
                ? MessageStateView(
                    key: const Key('empty_view'),
                    icon: Icons.search_off_rounded,
                    title: 'No matches',
                    message: 'Nothing matches “${provider.query}”. '
                        'Try a shorter or different word.',
                    actionLabel: 'Clear search',
                    actionIcon: Icons.close_rounded,
                    onAction: _clearSearch,
                  )
                : MessageStateView(
                    key: const Key('empty_view'),
                    icon: Icons.inventory_2_outlined,
                    title: 'No products yet',
                    message: 'The catalogue is empty right now. Check back later.',
                    actionLabel: 'Reload',
                    onAction: provider.retry,
                  ),
          ),
        ];

      case ProductListStatus.loaded:
        return [
          SliverToBoxAdapter(child: _ResultsHeader(provider: provider)),
          SliverPadding(
            padding: productGridPadding,
            sliver: SliverGrid(
              gridDelegate: productGridDelegate,
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final product = provider.products[index];
                  return ProductCard(
                    key: ValueKey('product_card_${product.id}'),
                    product: product,
                    onTap: () => _openProduct(product),
                  );
                },
                childCount: provider.products.length,
              ),
            ),
          ),
          SliverToBoxAdapter(child: _ListFooter(provider: provider)),
        ];
    }
  }
}

class _ResultsHeader extends StatelessWidget {
  const _ResultsHeader({required this.provider});

  final ProductListProvider provider;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title = provider.isSearching ? 'Results for “${provider.query}”' : 'All products';
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '${provider.products.length} of ${provider.total}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _ListFooter extends StatelessWidget {
  const _ListFooter({required this.provider});

  final ProductListProvider provider;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    final Widget child;
    if (provider.isLoadingMore) {
      child = const SizedBox.square(
        key: Key('load_more_indicator'),
        dimension: 28,
        child: CircularProgressIndicator(strokeWidth: 2.5),
      );
    } else if (provider.loadMoreError != null) {
      child = Column(
        children: [
          Text(
            'More products didn’t load.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            key: const Key('load_more_retry'),
            onPressed: provider.loadMore,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Load more'),
          ),
        ],
      );
    } else if (!provider.hasMore) {
      child = Text(
        'That’s everything. ${provider.products.length} products shown.',
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      );
    } else {
      child = const SizedBox.shrink();
    }

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 24 + bottomInset),
      child: Center(child: child),
    );
  }
}
