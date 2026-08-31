import 'package:flutter/material.dart';

class NavItem {
  const NavItem({
    required this.label,
    required this.icon,
    required this.route,
  });

  final String label;
  final IconData icon;
  final String route;
}

class NavGroup {
  const NavGroup({required this.title, required this.items});

  final String? title;
  final List<NavItem> items;
}
