import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'pages/seed_user_page.dart';

void main() {
  runApp(const TeamBuilderApp());
}

class TeamBuilderApp extends StatelessWidget {
  const TeamBuilderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Team Builder',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.blue,
        scaffoldBackgroundColor: Colors.grey[100],
      ),
      home: const SeedMemberPage(), // ✅ ใช้หน้า seed สมาชิก
    );
  }
}
