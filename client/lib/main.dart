import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import './screens/login_screen.dart';
import './screens/register_screen.dart';
import './screens/subscription_screen.dart';
import './providers/auth_provider.dart';
import './providers/subscription_provider.dart'; 

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthProvider(),
        ),
        ChangeNotifierProvider(  
          create: (_) => SubscriptionProvider(),
        ),
      ],
      child: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          return MaterialApp(
            title: 'Subscription App',
            theme: ThemeData(
              primarySwatch: Colors.blue,
            ),
            home: _buildHomeScreen(authProvider),
            debugShowCheckedModeBanner: false,
            routes: {
              '/login': (context) => LoginScreen(),
              '/register': (context) => RegisterScreen(),
              '/subscriptions': (context) => SubscriptionsScreen(),
            },
          );
        },
      ),
    );
  }

  Widget _buildHomeScreen(AuthProvider authProvider) {
    if (authProvider.isAuthenticated) {
      return SubscriptionsScreen(); 
    }
    return LoginScreen();
  }
}