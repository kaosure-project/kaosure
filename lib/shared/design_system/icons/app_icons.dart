library;

import 'package:flutter/material.dart';

/// Icons used throughout the application.
abstract final class AppIcons {
  const AppIcons._();

  // Authentication
  static const IconData login = Icons.login_rounded;
  static const IconData logout = Icons.logout_rounded;
  static const IconData register = Icons.person_add_rounded;

  // User
  static const IconData profile = Icons.person_rounded;
  static const IconData account = Icons.account_circle_rounded;
  static const IconData settings = Icons.settings_rounded;

  // Security
  static const IconData security = Icons.security_rounded;
  static const IconData password = Icons.lock_rounded;
  static const IconData shield = Icons.shield_rounded;
  static const IconData verified = Icons.verified_user_rounded;

  // Device
  static const IconData devices = Icons.devices_rounded;
  static const IconData smartphone = Icons.smartphone_rounded;
  static const IconData computer = Icons.computer_rounded;

  // Marketplace
  static const IconData marketplace = Icons.storefront_rounded;
  static const IconData favorite = Icons.favorite_rounded;
  static const IconData shoppingCart = Icons.shopping_cart_rounded;

  // Common
  static const IconData home = Icons.home_rounded;
  static const IconData search = Icons.search_rounded;
  static const IconData notification = Icons.notifications_rounded;
  static const IconData language = Icons.language_rounded;
  static const IconData email = Icons.email_rounded;
  static const IconData phone = Icons.phone_rounded;
}