import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'chat_screen.dart';
import 'package:pin_code_fields/pin_code_fields.dart';


class OTPVerificationScreen extends StatefulWidget {
  final String username;
  final String email;

  const OTPVerificationScreen({super.key, required this.username, required this.email});

  @override
  _OTPVerificationScreenState createState() => _OTPVerificationScreenState();
}

class _OTPVerificationScreenState extends State<OTPVerificationScreen> {
  TextEditingController otpController = TextEditingController();

  Future<void> verifyOTP() async {
    final String otp = otpController.text;

    if (otp.isNotEmpty) {
      // Send OTP, username, and email to the backend for verification
      final response = await http.post(
        Uri.parse('http://127.0.0.1:5000/verify_otp'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'username': widget.username, 'email': widget.email, 'otp': otp}),
      );

      if (response.statusCode == 200) {
        // User is verified, navigate to the ChatScreen
        // ignore: use_build_context_synchronously
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatScreen(username: widget.username),
          ),
        );
      } else {
        // Show error message
        // ignore: use_build_context_synchronously
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Error'),
            content: const Text('Invalid OTP. Please try again.'),
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } else {
      // Show error message if OTP field is empty
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Error'),
          content: const Text('Please enter the OTP.'),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Verify Email')),
      body:  Center(
        child: Stack(
          children:[
             Container(
              decoration: const BoxDecoration(
                image: DecorationImage(
                  
                  colorFilter: ColorFilter.mode(Colors.black26, BlendMode.srcOver),
                  image: AssetImage('lib/assets/key_image.jpg'),
                  fit: BoxFit.cover,
                ),
              ),
            
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('An OTP has been sent to your email.', style: TextStyle( color: Colors.white ,fontSize: 20,fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                PinCodeTextField(
                  textStyle: const TextStyle(color: Colors.white),
                  controller: otpController,
                  length: 6,
                  cursorColor: Colors.white,
                  onChanged: (value) {}, appContext: context,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: verifyOTP,
                  child: const Text('Verify OTP'),
                ),
              ],
            ),
          ),
        ),
     ] ),
    ));
  }
}
