import 'package:another_telephony/telephony.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:my_app/widgets/CustomCarousel.dart';
import 'package:my_app/widgets/custom_appBar.dart';
import 'package:my_app/widgets/emergencies/emergency_button.dart';
import 'package:my_app/widgets/live_safe.dart';
import 'package:my_app/widgets/sossheet/SafeHome.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shake/shake.dart';

import 'bottom_screens/fake_call_screen.dart';
import 'db/db_services.dart';
import 'model/contactsm.dart';

class UnifiedHomePage extends StatefulWidget {
  const UnifiedHomePage({super.key});

  @override
  State<UnifiedHomePage> createState() => _UnifiedHomePageState();
}

class _UnifiedHomePageState extends State<UnifiedHomePage> {
  Position? _curentPosition;
  String? _curentAddress;
  LocationPermission? permission;
  ShakeDetector? _detector;
  final user = FirebaseAuth.instance.currentUser;

  _isPermissionGranted() async => await Permission.sms.status.isGranted;

  sendSmsToContact(TContact contact, String messageBody) async {
    try {
      final telephony = Telephony.instance;
      await telephony.sendSms(
        to: contact.number,
        message: messageBody,
      );
      Fluttertoast.showToast(msg: "Alert sent to ${contact.number}");
    } catch (e) {
      Fluttertoast.showToast(msg: "Failed to send SMS: $e");
    }
  }

  _getCurrentLocation() async {
    final hasPermission = await _handleLocationPermission();
    if (!hasPermission) return;

    LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 100,
    );

    try {
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: locationSettings,
      );

      if (!mounted) return;
      setState(() {
        _curentPosition = position;
        print(_curentPosition!.latitude);
        _getAddressFromLatLon();
      });
    } catch (e) {
      Fluttertoast.showToast(msg: e.toString());
    }
  }

  _getAddressFromLatLon() async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        _curentPosition!.latitude, _curentPosition!.longitude,
      );

      Placemark place = placemarks[0];
      if (!mounted) return;
      setState(() {
        _curentAddress =
        "${place.locality},${place.postalCode},${place.street},";
      });
    } catch (e) {
      Fluttertoast.showToast(msg: e.toString());
    }
  }

  Future<bool> _handleLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text(
                'Location services are disabled. Please enable the services')));
      }
      return false;
    }
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Location permissions are denied')));
        }
        return false;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text(
                'Location permissions are permanently denied, we cannot request permissions.')));
      }
      return false;
    }
    return true;
  }

  getAndSendSms() async {
    List<TContact> contactList = await DatabaseHelper().getContactList();

    if (contactList.isEmpty) {
      Fluttertoast.showToast(msg: "Emergency contact list is empty");
    } else {
      String messageBody =
          "SOS Alert, I am here: https://www.google.com/maps/search/?api=1&query=${_curentPosition!.latitude}%2C${_curentPosition!.longitude}. $_curentAddress";

      if (await _isPermissionGranted()) {
        for (var element in contactList) {
          sendSmsToContact(element, messageBody);
        }
      } else {
        Fluttertoast.showToast(msg: "Permission not granted");
      }
    }
  }

  signout() async {
    await FirebaseAuth.instance.signOut();
  }

  void handleEmergency() {
    print("Emergency Activated!");
  }

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _startDetector();
  }

  void _startDetector() {
    _detector?.stopListening();
    _detector = ShakeDetector.autoStart(
      onPhoneShake: (ShakeEvent event) {
        getAndSendSms();
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const IncomingCallScreen(callerName: 'Home'),
            ),
          );
        }
      },
      minimumShakeCount: 1,
      shakeSlopTimeMS: 500,
      shakeCountResetTime: 3000,
      shakeThresholdGravity: 2.7,
      useFilter: false,
    );
  }

  @override
  void dispose() {
    _detector?.stopListening();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              CustomAppbar(),
              Expanded(
                child: ListView(
                  children: [
                    CustomCarousel(),
                    Padding(
                      padding: const EdgeInsets.only(top: 20.0),
                      child: EmergencyButton(),
                    ),
                    SizedBox(height: 20.0),
                    LiveSafe(),
                    SizedBox(height: 20.0),
                    SafeHome(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
