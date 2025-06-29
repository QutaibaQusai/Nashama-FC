import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nashama_fc/services/config_service.dart';

class AuthService extends ChangeNotifier {
  static const String _isLoggedInKey = 'isLoggedIn';
  
  // 🆕 SIMPLIFIED: Always consider user as "logged in" since no login is required
  bool _isLoggedIn = true;
  bool _isLoading = false;
  
  bool get isLoggedIn => _isLoggedIn;
  bool get isLoading => _isLoading;

  AuthService() {
    _loadAuthState();
  }

  Future<void> _loadAuthState() async {
    try {
      _isLoading = true;
      notifyListeners();
      
      // 🆕 SIMPLIFIED: Always set as logged in, no need to check stored state
      _isLoggedIn = true;
      
      debugPrint('📱 Auth state loaded: isLoggedIn = $_isLoggedIn (always true - no login required)');
      
      // 🆕 OPTIONAL: Still validate stored config if available
      await _validateStoredConfig();
    } catch (e) {
      debugPrint('❌ Error loading auth state: $e');
      _isLoggedIn = true; // Still set to true even on error
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 🆕 OPTIONAL: Validate that stored config is still valid (if any)
  Future<void> _validateStoredConfig() async {
    try {
      final configService = ConfigService();
      
      // Check if we have a stored dynamic config URL and role
      final prefs = await SharedPreferences.getInstance();
      final storedConfigUrl = prefs.getString('dynamic_config_url');
      final storedRole = prefs.getString('user_role');
      
      if (storedConfigUrl != null) {
        debugPrint('✅ Found stored config URL: $storedConfigUrl');
        debugPrint('👤 Found stored role: ${storedRole ?? 'none'}');
        
        // Force reload config with stored role to ensure URLs are processed
        if (storedRole != null && storedRole.isNotEmpty) {
          debugPrint('🔄 Reprocessing config with stored role...');
          await configService.loadConfig();
        }
      } else {
        debugPrint('ℹ️ No stored config URL found, using default configuration');
      }
    } catch (e) {
      debugPrint('❌ Error validating stored config: $e');
    }
  }

  /// 🆕 OPTIONAL: Method to handle config URL updates (if needed for dynamic configs)
  Future<void> updateConfig({String? configUrl, BuildContext? context}) async {
    try {
      debugPrint('🔄 Processing config update...');
      if (configUrl != null) {
        debugPrint('🔗 Config update includes URL: $configUrl');
        await _handleConfigUrlUpdate(configUrl, context);
      }
      
      notifyListeners();
      
      debugPrint('✅ Config update completed');
    } catch (e) {
      debugPrint('❌ Error during config update: $e');
      notifyListeners();
    }
  }

  Future<void> _handleConfigUrlUpdate(String configUrl, [BuildContext? context]) async {
    try {
      debugPrint('🔗 Processing config URL update: $configUrl');
      
      final parsedData = ConfigService.parseLoginConfigUrl(configUrl);
      
      if (parsedData.isNotEmpty && parsedData.containsKey('configUrl')) {
        final fullConfigUrl = parsedData['configUrl']!;
        final userRole = parsedData['role'];
        
        debugPrint('✅ Extracted config URL: $fullConfigUrl');
        debugPrint('👤 Extracted user role: ${userRole ?? 'not specified'}');
        
        await ConfigService().setDynamicConfigUrl(
          fullConfigUrl,
          role: userRole?.trim(),
        );
        
        if (context != null) {
          debugPrint('🔄 Immediately reloading configuration...');
          await ConfigService().loadConfig(context);
          debugPrint('✅ Configuration reloaded with role processing');
        }
        
        debugPrint('🎉 Config update completed successfully');
      } else {
        debugPrint('⚠️ Failed to parse config URL, using default configuration');
      }
    } catch (e) {
      debugPrint('❌ Error handling config URL update: $e');
    }
  }

  /// 🆕 OPTIONAL: Method to clear dynamic config (if needed)
  Future<void> clearDynamicConfig() async {
    try {
      debugPrint('🔄 Clearing dynamic configuration...');
      await ConfigService().clearDynamicConfigUrl();
      debugPrint('✅ Dynamic configuration cleared');
    } catch (e) {
      debugPrint('❌ Error clearing dynamic config: $e');
    }
  }

  /// 🆕 SIMPLIFIED: Check auth state (always returns true now)
  Future<bool> checkAuthState() async {
    await _loadAuthState();
    return _isLoggedIn; // Always true
  }

  /// 🆕 OPTIONAL: Method to set user config URL manually (if needed)
  Future<void> setUserConfigUrl(String configUrl, {String? role}) async {
    try {
      debugPrint('🔗 Manually setting user config URL with role: $configUrl');
      debugPrint('👤 Role: ${role ?? 'not specified'}');
      
      await ConfigService().setDynamicConfigUrl(configUrl, role: role?.trim());
      
      debugPrint('✅ User config URL and role set successfully');
    } catch (e) {
      debugPrint('❌ Error setting user config URL: $e');
    }
  }

  /// 🆕 Get current config information
  Map<String, String?> getUserConfigInfo() {
    final configService = ConfigService();
    final info = {
      'configUrl': configService.currentConfigUrl,
      'role': configService.userRole,
    };
    
    debugPrint('📋 Current user config info:');
    debugPrint('   Config URL: ${info['configUrl']}');
    debugPrint('   User Role: ${info['role'] ?? 'none'}');
    
    return info;
  }

  /// 🆕 OPTIONAL: Refresh config with stored role
  Future<void> refreshConfigWithStoredRole([BuildContext? context]) async {
    try {
      debugPrint('🔄 Refreshing config with stored role...');
      
      final configService = ConfigService();
      final currentRole = configService.userRole;
      
      if (currentRole != null && currentRole.isNotEmpty) {
        debugPrint('👤 Using stored role: $currentRole');
        await configService.loadConfig(context);
        debugPrint('✅ Config refreshed with stored role applied');
      } else {
        debugPrint('ℹ️ No stored role found, loading config without role processing');
        await configService.loadConfig(context);
      }
      
    } catch (e) {
      debugPrint('❌ Error refreshing config with stored role: $e');
    }
  }

  /// 🆕 Check if we have valid role configuration
  bool hasValidRoleConfiguration() {
    final configService = ConfigService();
    final hasRole = configService.userRole != null && configService.userRole!.isNotEmpty;
    final hasConfig = configService.config != null;
    
    debugPrint('🔍 Role configuration status:');
    debugPrint('   Has role: $hasRole (${configService.userRole ?? 'none'})');
    debugPrint('   Has config: $hasConfig');
    
    return hasConfig; // Only check config, not role since login is not required
  }

  /// 🆕 OPTIONAL: Reset method (if needed for debugging or special cases)
  Future<void> reset() async {
    try {
      debugPrint('🔄 Resetting auth service...');
      
      _isLoggedIn = true; // Always keep as true
      await clearDynamicConfig();
      
      notifyListeners();
      
      debugPrint('✅ Auth service reset completed');
    } catch (e) {
      debugPrint('❌ Error resetting auth service: $e');
    }
  }
}