import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_application/pages/inside_admin/ProductsManagementPage.dart';
import 'package:flutter_application/pages/inside_admin/ClientsPage.dart';
import 'package:flutter_application/pages/inside_admin/orderpage.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage>
    with TickerProviderStateMixin {
  AnimationController? _fadeController;
  Animation<double>? _fadeAnimation;
  AnimationController? _slideController;
  Animation<Offset>? _slideAnimation;

  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isRefreshing = false;
  String _searchQuery = '';
  List<String> _recentSearches = ['Products', 'Orders', 'Analytics'];
  List<String> _searchSuggestions = [];

  // Mock dashboard stats
  final Map<String, dynamic> _dashboardStats = {
    'totalProducts': 0,
    'pendingOrders': 0,
    'totalClients': 0,
    'todayRevenue': 0,
  };

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController!,
      curve: Curves.easeOut,
    );

    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _slideController!,
            curve: Curves.easeOutCubic,
          ),
        );

    _fadeController!.forward();
    _slideController!.forward();

    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _fadeController?.dispose();
    _slideController?.dispose();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text;
      _searchSuggestions = _getSearchSuggestions(_searchQuery);
    });
  }

  List<String> _getSearchSuggestions(String query) {
    if (query.isEmpty) return [];
    const allSuggestions = [
      'Products',
      'Add Product',
      'Inventory',
      'Orders',
      'Pending Orders',
      'Order History',
      'Clients',
      'Customer Data',
      'Client Reports',
      'Analytics',
      'Sales Report',
      'Revenue Analytics',
    ];
    return allSuggestions
        .where((item) => item.toLowerCase().contains(query.toLowerCase()))
        .take(4)
        .toList();
  }

  Future<void> _onRefresh() async {
    setState(() => _isRefreshing = true);
    // Simulate API call
    await Future.delayed(const Duration(seconds: 2));
    setState(() => _isRefreshing = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Dashboard refreshed'),
          backgroundColor: const Color(0xFF34C759),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  void _navigateTo(BuildContext context, Widget page) {
    HapticFeedback.lightImpact();
    Navigator.of(context).push(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 400),
        pageBuilder: (_, __, ___) => page,
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position:
                  Tween<Offset>(
                    begin: const Offset(0, 0.02),
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOutCubic,
                    ),
                  ),
              child: child,
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF999999),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
    required Color accentColor,
    bool isEnabled = true,
    bool isBeta = false,
  }) {
    return GestureDetector(
      onTap: isEnabled ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isEnabled ? const Color(0xFFF8F8F8) : const Color(0xFFF0F0F0),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isEnabled
                ? accentColor.withOpacity(0.1)
                : Colors.transparent,
          ),
          boxShadow: [
            BoxShadow(
              color: accentColor.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [accentColor, accentColor.withOpacity(0.8)],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 18, color: Colors.white),
                ),
                if (isBeta)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF9500),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'BETA',
                      style: TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
            const Spacer(),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isEnabled
                    ? const Color(0xFF1A1A1A)
                    : const Color(0xFF999999),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: isEnabled
                    ? const Color(0xFF666666)
                    : const Color(0xFF999999),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchSuggestions() {
    if (_searchSuggestions.isEmpty && _searchQuery.isEmpty)
      return const SizedBox();

    final suggestions = _searchQuery.isEmpty
        ? _recentSearches
        : _searchSuggestions;
    final title = _searchQuery.isEmpty ? 'Recent searches' : 'Suggestions';

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF999999),
            ),
          ),
          const SizedBox(height: 8),
          ...suggestions.map(
            (suggestion) => GestureDetector(
              onTap: () {
                _searchController.text = suggestion;
                if (!_recentSearches.contains(suggestion)) {
                  setState(() {
                    _recentSearches.insert(0, suggestion);
                    if (_recentSearches.length > 5)
                      _recentSearches.removeLast();
                  });
                }
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Icon(
                      _searchQuery.isEmpty ? Icons.history : Icons.search,
                      size: 16,
                      color: const Color(0xFF999999),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      suggestion,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_fadeAnimation == null || _slideAnimation == null) {
      return const SizedBox.shrink();
    }

    return Scaffold(
      backgroundColor: const Color(0xFFE5E5E5),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation!,
          child: SlideTransition(
            position: _slideAnimation!,
            child: RefreshIndicator(
              onRefresh: _onRefresh,
              color: const Color(0xFF007AFF),
              child: Container(
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Top bar
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          GestureDetector(
                            onTap: () => HapticFeedback.lightImpact(),
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    const Color(0xFF007AFF).withOpacity(0.1),
                                    const Color(0xFF007AFF).withOpacity(0.05),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: const Color(
                                    0xFF007AFF,
                                  ).withOpacity(0.2),
                                ),
                              ),
                              child: const Icon(
                                Icons.help_outline,
                                size: 18,
                                color: Color(0xFF007AFF),
                              ),
                            ),
                          ),
                          Stack(
                            children: [
                              GestureDetector(
                                onTap: () => HapticFeedback.lightImpact(),
                                child: Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        const Color(
                                          0xFFFF9500,
                                        ).withOpacity(0.1),
                                        const Color(
                                          0xFFFF9500,
                                        ).withOpacity(0.05),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(18),
                                    border: Border.all(
                                      color: const Color(
                                        0xFFFF9500,
                                      ).withOpacity(0.2),
                                    ),
                                  ),
                                  child: IconButton(
                                    onPressed: () {
                                      HapticFeedback.mediumImpact();
                                      showDialog(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
                                          ),
                                          title: const Text(
                                            'Sign Out',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          content: const Text(
                                            'Are you sure you want to sign out?',
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(context),
                                              child: const Text(
                                                'Cancel',
                                                style: TextStyle(
                                                  color: Color(0xFF999999),
                                                ),
                                              ),
                                            ),
                                            TextButton(
                                              onPressed: () {
                                                Navigator.pop(context);
                                                Navigator.pushReplacementNamed(
                                                  context,
                                                  '/login',
                                                );
                                              },
                                              child: const Text(
                                                'Sign Out',
                                                style: TextStyle(
                                                  color: Color(0xFFFF3B30),
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                    icon: const Icon(
                                      Icons.notifications_none,
                                      size: 18,
                                      color: Color(0xFFFF9500),
                                    ),
                                    padding: EdgeInsets.zero,
                                  ),
                                ),
                              ),
                              Positioned(
                                right: 2,
                                top: 2,
                                child: Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0xFFFF9500),
                                        Color(0xFFFF6B00),
                                      ],
                                    ),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 2,
                                    ),
                                  ),
                                  child: const Center(
                                    child: Text(
                                      '3',
                                      style: TextStyle(
                                        fontSize: 8,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Main content
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Greeting with time-based message
                            Text(
                              "Hi Admin,",
                              style: TextStyle(
                                fontSize: 16,
                                color: const Color(0xFF999999),
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              "How can I help\nyou today?",
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF1A1A1A),
                                height: 1.1,
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Quick stats
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [
                                  _buildStatCard(
                                    'Products',
                                    '${_dashboardStats['totalProducts']}',
                                    Icons.inventory_2_outlined,
                                    const Color(0xFF34C759),
                                  ),
                                  const SizedBox(width: 12),
                                  _buildStatCard(
                                    'Pending Orders',
                                    '${_dashboardStats['pendingOrders']}',
                                    Icons.pending_actions,
                                    const Color(0xFFFF9500),
                                  ),
                                  const SizedBox(width: 12),
                                  _buildStatCard(
                                    'Clients',
                                    '${_dashboardStats['totalClients']}',
                                    Icons.people_outline,
                                    const Color(0xFF007AFF),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Features grid
                            Expanded(
                              child: GridView.count(
                                controller: _scrollController,
                                crossAxisCount: 2,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                                childAspectRatio: 1.1,
                                physics: const BouncingScrollPhysics(),
                                children: [
                                  _buildFeatureCard(
                                    title: "Products",
                                    subtitle: "Manage inventory, add items...",
                                    icon: Icons.inventory_2_outlined,
                                    accentColor: const Color(0xFF34C759),
                                    onTap: () => _navigateTo(
                                      context,
                                      const ProductsPage(),
                                    ),
                                  ),
                                  _buildFeatureCard(
                                    title: "Orders",
                                    subtitle: "Track, process orders...",
                                    icon: Icons.receipt_long_outlined,
                                    accentColor: const Color(0xFFFF9500),
                                    onTap: () =>
                                        _navigateTo(context, const OrderPage()),
                                  ),
                                  _buildFeatureCard(
                                    title: "Clients",
                                    subtitle: "View customer data...",
                                    icon: Icons.people_outline,
                                    accentColor: const Color(0xFF007AFF),
                                    onTap: () => _navigateTo(
                                      context,
                                      const ClientsPage(),
                                    ),
                                  ),
                                  _buildFeatureCard(
                                    title: "Analytics",
                                    subtitle: "Insights, reports...",
                                    icon: Icons.analytics_outlined,
                                    accentColor: const Color(0xFF5856D6),
                                    isBeta: true,
                                    onTap: () {
                                      HapticFeedback.mediumImpact();
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: const Text(
                                            'Analytics coming soon!',
                                          ),
                                          backgroundColor: const Color(
                                            0xFF5856D6,
                                          ),
                                          behavior: SnackBarBehavior.floating,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 16),

                            // Enhanced search bar with suggestions
                            Column(
                              children: [
                                Container(
                                  height: 48,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        const Color(0xFFF8F8F8),
                                        const Color(0xFFF0F0F0),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(24),
                                    border: Border.all(
                                      color: const Color(
                                        0xFF007AFF,
                                      ).withOpacity(0.1),
                                    ),
                                  ),
                                  child: TextField(
                                    controller: _searchController,
                                    decoration: const InputDecoration(
                                      hintText: "Search anything...",
                                      hintStyle: TextStyle(
                                        color: Color(0xFF999999),
                                        fontSize: 16,
                                      ),
                                      prefixIcon: Icon(
                                        Icons.search,
                                        color: Color(0xFF007AFF),
                                        size: 20,
                                      ),
                                      suffixIcon: Icon(
                                        Icons.mic_none,
                                        color: Color(0xFF999999),
                                        size: 20,
                                      ),
                                      border: InputBorder.none,
                                      contentPadding: EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 12,
                                      ),
                                    ),
                                    onTap: () =>
                                        HapticFeedback.selectionClick(),
                                  ),
                                ),
                                if (_searchQuery.isNotEmpty ||
                                    _searchController.text.isEmpty)
                                  _buildSearchSuggestions(),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Enhanced bottom navigation
                    Container(
                      margin: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                      height: 68,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF1A1A1A), Color(0xFF2C2C2E)],
                        ),
                        borderRadius: BorderRadius.circular(34),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(18),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.1),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.dashboard_outlined,
                                    size: 18,
                                    color: Color(0xFF1A1A1A),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF333333),
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                  child: const Icon(
                                    Icons.person_outline,
                                    size: 18,
                                    color: Color(0xFF999999),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              HapticFeedback.mediumImpact();
                              // Add quick action functionality
                            },
                            child: Container(
                              width: 52,
                              height: 52,
                              margin: const EdgeInsets.only(right: 8),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Colors.white, Color(0xFFF8F8F8)],
                                ),
                                borderRadius: BorderRadius.circular(26),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.add,
                                size: 24,
                                color: Color(0xFF1A1A1A),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
