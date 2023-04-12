import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:pet_app/constants/constants.dart';
import 'package:pet_app/drawer/hidden_drawer.dart';
import 'package:pet_app/models/homeless_pet.dart';
import 'package:pet_app/screens/splash_screen.dart';
import 'package:pet_app/utils/helpers/shared_pref_helper.dart';
import 'package:pet_app/utils/services/database.dart';
import 'package:provider/provider.dart';

Future main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  runApp(
    MaterialApp(
      home: MyApp(),
      debugShowCheckedModeBanner: false,
    ),
  );
}

class MyApp extends StatefulWidget {
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final Stream<List<HomelessPet>> getHomelessPets =
      DatabaseMethods().getHomelessPets();
  bool isLoggedIn;
  @override
  void initState() {
    setState(() {
      getLoggedInState();
    });
    super.initState();
  }

  getLoggedInState() async {
    await SharedPrefHelper().getUserLoggedInSharedPref().then((val) {
      setState(() {
        isLoggedIn = val;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        StreamProvider<List<HomelessPet>>(
          create: (context) => getHomelessPets,
          initialData: [],
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          appBarTheme: AppBarTheme(
            backgroundColor: Constants.kPrimaryColor,
            foregroundColor: Colors.white,
            shadowColor: Colors.transparent,
          ),
        ),
        home: isLoggedIn != null
            ? isLoggedIn
                ? HiddenDrawer()
                : SplashScreen()
            : SplashScreen(),
      ),
    );
  }
}
