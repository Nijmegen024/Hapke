import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../app_config.dart';

const String apiBase = AppConfig.apiBaseUrl;
const FlutterSecureStorage secureStorage = FlutterSecureStorage();
const String sessionStorageKey = 'hapke_session';
const String lastOrderStorageKey = 'hapke_last_order';
const String authTokenKey = 'hapke_access_token';
const String authUserKey = 'hapke_auth_user';

final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();
