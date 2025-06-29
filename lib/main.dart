// lib/main.dart - UPDATED: Direct to MainScreen without login
import 'package:nashama_fc/services/refresh_state_manager.dart';
import 'package:nashama_fc/themes/dynamic_theme.dart';
import 'package:nashama_fc/widgets/connection_status_widget.dart';
import 'package:nashama_fc/widgets/screenshot_wrapper.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:nashama_fc/services/config_service.dart';
import 'package:nashama_fc/services/theme_service.dart';
import 'package:nashama_fc/services/auth_service.dart';
import 'package:nashama_fc/pages/main_screen.dart';
import 'package:nashama_fc/pages/no_internet_page.dart';
import 'package:nashama_fc/services/internet_connection_service.dart';

void main() async {
  // Preserve the native splash screen
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  // Initialize services
  final configService = ConfigService();
  final themeService = ThemeService();
  final authService = AuthService();  
  final internetService = InternetConnectionService(); 

  // Load configuration
  debugPrint('🚀 ERPForever App Starting...');
  debugPrint('📡 Loading configuration from remote source...');

  await configService.loadConfig();

  // 🔥 CRITICAL: Initialize internet connection monitoring FIRST
  await internetService.initialize();
  debugPrint('🌐 Internet connection service initialized');

  // Log configuration status
  final cacheStatus = await configService.getCacheStatus();
  debugPrint('💾 Cache Status: $cacheStatus');

  if (configService.config != null) {
    debugPrint('✅ Configuration loaded successfully');
    debugPrint('🔗 Main Icons: ${configService.config!.mainIcons.length}');
    debugPrint('📋 Sheet Icons: ${configService.config!.sheetIcons.length}');
    debugPrint('🌍 Language: ${configService.config!.lang}');
    debugPrint('🌍 Direction: ${configService.config!.theme.direction}');
  } else {
    debugPrint('⚠️ Using fallback configuration');
  }

  // Load saved theme
  final savedTheme = await themeService.getSavedThemeMode();

  // 🆕 REMOVED: Authentication check - no longer needed
  // final isLoggedIn = await authService.checkAuthState();

  // 🌐 Log initial internet status
  debugPrint('🌐 Initial internet status: ${internetService.isConnected}');

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: configService),
        ChangeNotifierProvider(create: (_) => themeService),
        ChangeNotifierProvider.value(value: authService),
        ChangeNotifierProvider(create: (_) => RefreshStateManager()),
        ChangeNotifierProvider(create: (_) => SplashStateManager()),
        ChangeNotifierProvider.value(value: internetService), 
      ],
      child: MyApp(
        initialThemeMode: savedTheme, 
        hasInternet: internetService.isConnected,
      ),
    ),
  );
}

class SplashStateManager extends ChangeNotifier {
  bool _isWebViewReady = false;
  bool _isMinTimeElapsed = false;
  bool _isSplashRemoved = false;
  bool _hasInternet = true;  // 🆕 Track internet status
  late DateTime _startTime;

  SplashStateManager() {
    _startTime = DateTime.now();
    _startMinTimeTimer();
  }

  bool get isSplashRemoved => _isSplashRemoved;

  // 🆕 NEW: Method to update internet status
  void setInternetStatus(bool hasInternet) {
    _hasInternet = hasInternet;
    debugPrint('🌐 Splash Manager - Internet status: ${hasInternet ? "CONNECTED" : "DISCONNECTED"}');
    
    if (!hasInternet) {
      // If no internet, remove splash immediately after minimum time to show no internet page
      debugPrint('🚫 No internet detected - will remove splash after minimum time');
      _checkSplashRemoval();
    } else {
      // If internet is back, check if we should remove splash
      debugPrint('✅ Internet connected - checking splash removal conditions');
      _checkSplashRemoval();
    }
  }

  void _startMinTimeTimer() {
    Future.delayed(const Duration(seconds: 2), () {
      _isMinTimeElapsed = true;
      debugPrint('⏱️ Minimum 2 seconds elapsed');
      _checkSplashRemoval();
    });
  }

  void setWebViewReady() {
    if (!_isWebViewReady) {
      _isWebViewReady = true;
      debugPrint('🌐 First WebView is ready');
      _checkSplashRemoval();
    }
  }

  void _checkSplashRemoval() {

    bool shouldRemove = _isMinTimeElapsed && 
                       (_isWebViewReady || !_hasInternet) && 
                       !_isSplashRemoved;
    
    debugPrint('🔍 Splash removal check:');
    debugPrint('   - Min time elapsed: $_isMinTimeElapsed');
    debugPrint('   - WebView ready: $_isWebViewReady');
    debugPrint('   - Has internet: $_hasInternet');
    debugPrint('   - Should remove: $shouldRemove');
    
    if (shouldRemove) {
      _removeSplash();
    }
  }

  void _removeSplash() {
    if (_isSplashRemoved) return; // Prevent multiple calls
    
    _isSplashRemoved = true;

    try {
      FlutterNativeSplash.remove();
      debugPrint('✅ Splash screen removed successfully!');
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Error removing splash screen: $e');
    }
  }
}

class MyApp extends StatelessWidget {
  final String initialThemeMode;
  final bool hasInternet;

  const MyApp({
    super.key, 
    required this.initialThemeMode, 
    required this.hasInternet,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer4<ConfigService, ThemeService, AuthService, InternetConnectionService>(
      builder: (context, configService, themeService, authService, internetService, child) {
        // 🔧 CRITICAL: Monitor internet connection changes for splash management
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (context.mounted) {
            try {
              final splashManager = Provider.of<SplashStateManager>(context, listen: false);
              splashManager.setInternetStatus(internetService.isConnected);
            } catch (e) {
              debugPrint('❌ Error updating splash manager with internet status: $e');
            }
          }
        });

        // 🆕 SIMPLIFIED: Always go to MainScreen, no auth check needed
        final textDirection = configService.getTextDirection();

        // 🆕 Enhanced config loading with context after app is built
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (context.mounted) {
            _enhanceConfigWithContext(context, configService);
          }
        });

        return Directionality(
          textDirection: textDirection,
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'ERPForever',
            themeMode: themeService.themeMode,
            theme: DynamicTheme.buildLightTheme(configService.config),
            darkTheme: DynamicTheme.buildDarkTheme(configService.config),
            home: ScreenshotWrapper(
              child: ConnectionStatusWidget(
                child: _buildHomePage(internetService),
              ),
            ),
            builder: (context, widget) {
              return Directionality(
                textDirection: textDirection,
                child: widget ?? Container(),
              );
            },
          ),
        );
      },
    );
  }

  // 🆕 SIMPLIFIED: Build home page based on internet status only
  Widget _buildHomePage(InternetConnectionService internetService) {
    return Consumer<InternetConnectionService>(
      builder: (context, connectionService, _) {
        debugPrint('🏠 Building home page - Internet: ${connectionService.isConnected}');
        
        // 🔧 PRIORITY: If no internet, always show no internet page
        if (!connectionService.isConnected) {
          debugPrint('🚫 No internet - showing NoInternetPage');
          return const NoInternetPage();
        }
        
        // 🔧 SIMPLIFIED: If internet is available, always show MainScreen
        debugPrint('✅ Internet available - showing MainScreen');
        return const MainScreen();
      },
    );
  }

  /// 🆕 Enhanced configuration loading with context for better app data
  void _enhanceConfigWithContext(
    BuildContext context,
    ConfigService configService,
  ) async {
    try {
      debugPrint('🔧 Enhancing configuration with context for better app data...');

      // Check if we need to reload with enhanced context
      final cacheStatus = await configService.getCacheStatus();
      final cacheAgeMinutes = (cacheStatus['cacheAge'] as int? ?? 0) / (1000 * 60);

      // Only reload if cache is older than 1 minute or if we haven't loaded with context yet
      if (cacheAgeMinutes > 1 || !configService.isLoaded) {
        debugPrint('🔄 Reloading configuration with enhanced app data...');
        await configService.loadConfig(context);
        debugPrint('✅ Configuration enhanced with context-aware app data');
      } else {
        debugPrint('⏩ Recent config available, skipping context enhancement');
      }
    } catch (e) {
      debugPrint('❌ Error enhancing config with context: $e');
    }
  }
}