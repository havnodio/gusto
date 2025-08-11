import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'pages/home/home_page.dart';
import 'pages/home/login_page.dart';
import 'pages/home/AccountRequestsPage.dart';
import 'pages/home/forget_password.dart';
import 'pages/inside_admin/orderpage.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(textTheme: GoogleFonts.arimoTextTheme()),
      initialRoute: '/',
      routes: {
        '/': (context) => const HomePage(),
        '/login': (context) => const LoginPage(),
        '/request': (context) => const RegisterPage(),
        '/forgot': (context) => const ForgetPassword(),
        '/orders': (context) => const OrderPage(),
      },
    );
  }
}
