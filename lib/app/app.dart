import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/localization/app_strings.dart';
import '../features/auth/presentation/lock_screen.dart';
import '../features/documents/presentation/home_screen.dart';
import '../features/onboarding/presentation/onboarding_screen.dart';
import 'theme.dart';

class PathokApp extends StatefulWidget {
  const PathokApp({super.key});

  @override
  State<PathokApp> createState() => _PathokAppState();
}

class _PathokAppState extends State<PathokApp> {
  bool _isEnglish = true;
  bool _isDarkMode = false;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _loadInitialPreferences();
  }

  Future<void> _loadInitialPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _isEnglish = prefs.getBool('english_language') ?? true;
        _isDarkMode = prefs.getBool('dark_mode_enabled') ?? false;
        _initialized = true;
      });
    }
  }

  Future<void> _setEnglish(bool english) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('english_language', english);
    if (mounted) setState(() => _isEnglish = english);
  }

  Future<void> _setDarkMode(bool darkMode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('dark_mode_enabled', darkMode);
    if (mounted) setState(() => _isDarkMode = darkMode);
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      return const SizedBox.shrink();
    }

    return AppLocaleScope(
      isEnglish: _isEnglish,
      child: MaterialApp(
        title: 'পাঠক',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light,
        home: AppRoot(
          onLanguageChanged: _setEnglish,
          onThemeChanged: _setDarkMode,
          isDarkMode: _isDarkMode,
        ),
      ),
    );
  }
}

class AppRoot extends StatefulWidget {
  const AppRoot({
    required this.onLanguageChanged,
    required this.onThemeChanged,
    required this.isDarkMode,
    super.key,
  });

  final ValueChanged<bool> onLanguageChanged;
  final ValueChanged<bool> onThemeChanged;
  final bool isDarkMode;

  @override
  State<AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<AppRoot> with WidgetsBindingObserver {
  bool? _onboardingComplete;
  bool _locked = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkStatus();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _locked) {
      _checkStatus();
    }
  }

  Future<void> _checkStatus() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _onboardingComplete = prefs.getBool('onboarding_complete') ?? false;
        _locked = false;
      });
    }
  }

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_complete', true);
    if (mounted) {
      setState(() => _onboardingComplete = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);

    if (_onboardingComplete == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(strings.appName),
            ],
          ),
        ),
      );
    }

    if (_locked) {
      return LockScreen(onUnlock: _checkStatus);
    }

    if (!_onboardingComplete!) {
      return OnboardingScreen(
        onComplete: _completeOnboarding,
        onLanguageChanged: widget.onLanguageChanged,
      );
    }

    return HomeScreen(
      onLanguageChanged: widget.onLanguageChanged,
      onThemeChanged: widget.onThemeChanged,
      isDarkMode: widget.isDarkMode,
    );
  }
}
