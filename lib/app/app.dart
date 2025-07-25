import 'package:calendarit/features/auth/auth_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
// import 'l10n/l10n.dart';

import '../features/dashboard/calendar_widgets/calendar_cubit.dart';
import '../features/onboarding/onboarding_screen.dart';
import '../features/auth/sign_in_screen.dart';
import '../features/auth/sign_up_screen.dart';
import '../features/auth/forgot_password_screen.dart';
import '../features/dashboard/dashboard_screen.dart';
import '../features/event_details/event_details_screen.dart';
import '../features/connections/connections_screen.dart';
import '../features/settings/settings_screen.dart';
import '../screens/gmail_web_redirect_screen.dart';

import 'package:go_router/go_router.dart';

import 'custom_theme.dart';

class SmartSchedulerApp extends StatelessWidget {
  const SmartSchedulerApp({super.key});

  @override
  Widget build(BuildContext context) {
    final GoRouter router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) {
            //dashboard if authenticated, otherwise onboarding
            final authCubit = context.read<AuthCubit>();
            final isAuthenticated = authCubit.isAuthenticated;
            print('AuthCubit in / route: $authCubit');
            print('Is authenticated: $isAuthenticated');
            if (isAuthenticated) {
              return DashboardScreen();
            } else {
              return const OnboardingScreen();
            }
          },
        ),
        GoRoute(
          path: '/onboarding',
          builder: (context, state) => const OnboardingScreen(),
        ),
        GoRoute(
          path: '/sign-in',
          builder: (context, state) => const SignInScreen(),
        ),
        GoRoute(
          path: '/sign-up',
          builder: (context, state) => const SignUpScreen(),
        ),
        GoRoute(
          path: '/forgot-password',
          builder: (context, state) => const ForgotPasswordScreen(),
        ),
        GoRoute(
          path: '/dashboard',
          builder: (context, state) {
            final cubit = context.read<CalendarCubit?>();
            print('CalendarCubit in /dashboard route: $cubit');
            return DashboardScreen();
          },
        ),
        GoRoute(
          path: '/event/:id',
          builder: (context, state) {
            final eventId = state.pathParameters['id']!;
            return EventDetailsScreen(eventId: eventId);
          },
        ),
        GoRoute(
          path: '/connections',
          builder: (context, state) => const ConnectionsScreen(),
        ),
        GoRoute(
          path: '/settings',
          builder: (context, state) => const SettingsScreen(),
        ),
        GoRoute(
          path: '/oauth2redirect',
          builder: (context, state) => const GmailWebRedirectScreen(),
        ),
      ],
    );

    return MaterialApp.router(
      title: 'Calendar IT',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      routerConfig: router,
      localizationsDelegates: const [
        // AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      // supportedLocales: AppLocalizations.supportedLocales,
    );
  }
}
