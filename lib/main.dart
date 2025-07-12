import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'features/dashboard/calendar_widgets/calendar_cubit.dart';
import 'features/dashboard/calendar_widgets/calendar_repository.dart';
import 'firebase_options.dart';
import 'app/app.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'features/auth/auth_cubit.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  setUrlStrategy(PathUrlStrategy());
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final calendarRepository = CalendarRepository();

  runApp(
    MultiRepositoryProvider(
      providers: [
        RepositoryProvider<CalendarRepository>.value(value: calendarRepository),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<AuthCubit>(
            create: (_) => AuthCubit(),
          ),
          BlocProvider<CalendarCubit>(
            create: (context) => CalendarCubit(calendarRepository)..loadEvents(),
          ),
        ],
        child: const SmartSchedulerApp(),
      ),
    ),
  );
}
