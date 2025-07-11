import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'app/app.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'features/auth/auth_cubit.dart';
import 'package:syncfusion_flutter_core/core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  setUrlStrategy(PathUrlStrategy());
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  SyncfusionLicense.registerLicense("Ngo9BigBOggjHTQxAR8/V1JEaF5cXmRCeUx3Qnxbf1x1ZFBMYl9bQHJPMyBoS35Rc0VkWH9edXZWQmRbV0N2VEFd");

  runApp(
    BlocProvider(
      create: (_) => AuthCubit(),
      child: const SmartSchedulerApp(),
    ),
  );
}
