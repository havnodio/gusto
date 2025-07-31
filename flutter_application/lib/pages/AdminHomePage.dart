import 'package:flutter/material.dart';
import 'package:flutter_application/pages/Clients_Page.dart';
import 'package:flutter_application/pages/OrdersPage.dart';
import 'package:flutter_application/pages/home_page.dart';
import 'package:flutter_application/pages/stock_Page.dart';
import 'package:flutter_application/pages/AccountRequestsPage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_application/pages/DashboardPage.dart';
import 'package:google_fonts/google_fonts.dart';

class AdminHomePage extends StatefulWidget {
  const AdminHomePage({super.key});

  @override
  State<AdminHomePage> createState() => _AdminHomePageState();
}

class _AdminHomePageState extends State<AdminHomePage>
    with SingleTickerProviderStateMixin {
  String? userRole;
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    loadUserRole();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> loadUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      userRole = prefs.getString('role'); // "admin" or "user"
    });
  }

  Future<void> _logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt_token');
    await prefs.remove('role');
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const HomePage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Set to white as requested
      appBar: AppBar(
        title: Text(
          userRole == 'admin' ? 'Admin Dashboard' : 'Dashboard',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.teal,
        elevation: 4, // Added for depth
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white, size: 28),
            onPressed: () async {
              final shouldLogout = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text('Confirm Logout', style: GoogleFonts.poppins()),
                  content: Text(
                    'Are you sure you want to logout?',
                    style: GoogleFonts.poppins(),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: Text(
                        'Cancel',
                        style: GoogleFonts.poppins(color: Colors.grey),
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: Text(
                        'Logout',
                        style: GoogleFonts.poppins(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              );
              if (shouldLogout == true) {
                _logout(context);
              }
            },
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(color: Colors.teal),
              child: Text(
                'Menu',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(
                Icons.dashboard,
                color: Colors.teal,
                size: 28,
              ),
              title: Text(
                'Dashboard',
                style: GoogleFonts.poppins(fontSize: 16),
              ),
              onTap: () {
                Navigator.pop(context); // Close drawer, stay on Dashboard
              },
            ),
            ListTile(
              leading: const Icon(Icons.people, color: Colors.teal, size: 28),
              title: Text('Clients', style: GoogleFonts.poppins(fontSize: 16)),
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const ClientsPage()),
                );
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.inventory,
                color: Colors.teal,
                size: 28,
              ),
              title: Text('Products', style: GoogleFonts.poppins(fontSize: 16)),
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const ProductsPage()),
                );
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.shopping_cart,
                color: Colors.teal,
                size: 28,
              ),
              title: Text('Orders', style: GoogleFonts.poppins(fontSize: 16)),
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const OrdersPage()),
                );
              },
            ),
            if (userRole == 'admin')
              ListTile(
                leading: const Icon(
                  Icons.person_add,
                  color: Colors.teal,
                  size: 28,
                ),
                title: Text(
                  'Account Requests',
                  style: GoogleFonts.poppins(fontSize: 16),
                ),
                onTap: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AccountRequestsPage(),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: const Center(child: DashboardPage()),
        ),
      ),
    );
  }
}
