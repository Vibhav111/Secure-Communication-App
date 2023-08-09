import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:cyber_chat/screens/otp_verification_screen.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Secret Chat',
      home: AuthenticationScreen(),
      theme: ThemeData(primarySwatch: Colors.red),
      debugShowCheckedModeBanner: false,  
    );
  }
}

class AuthenticationScreen extends StatefulWidget {
  @override
  _AuthenticationScreenState createState() => _AuthenticationScreenState();
}

class _AuthenticationScreenState extends State<AuthenticationScreen> {
  TextEditingController usernameController = TextEditingController();
  TextEditingController emailController = TextEditingController();

  Future<void> verifyEmail() async {
    final String username = usernameController.text;
    final String email = emailController.text;

    if (username.isNotEmpty && email.isNotEmpty) {
      // Send email and username to the backend for verification
      final response = await http.post(
        Uri.parse('http://127.0.0.1:5000/verify_user'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'username': username, 'email': email}),
      );

      if (response.statusCode == 200) {
        // User is authenticated, navigate to OTP verification screen
        // ignore: use_build_context_synchronously
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OTPVerificationScreen(username: username, email: email),
          ),
        );
      } else {
        // Show error message
        // ignore: use_build_context_synchronously
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Error'),
            content: const Text('You are not an authenticated user.'),
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
      // Show error message if fields are empty
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Error'),
          content: const Text('Please enter both username and email.'),
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
    body:  Center(
        child: Stack(
          children: [
            // Background Image
            Container(
              decoration: const BoxDecoration(
                image: DecorationImage(
                  
                  colorFilter: ColorFilter.mode(Colors.black26, BlendMode.srcOver),
                  image: AssetImage('lib/assets/wood.jpg'),
                   // Replace with the path to your image
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.only(left: 25),
                    decoration: BoxDecoration(
                      
                      color: Colors.white, // White background for the TextField
                      borderRadius: BorderRadius.circular(8.0),),
                    child: TextField(
                      controller: usernameController,
                      cursorColor: Colors.red,
                      decoration: const InputDecoration(labelText: 'Enter Your Classified Username',  labelStyle: TextStyle(color: Colors.red)),
  
                  
                    ),
                  ),
                  const SizedBox(height: 16),

                  Container(
                     padding: const EdgeInsets.only(left: 25),
                    decoration: BoxDecoration(
                      
                      
                      color: Colors.white, // White background for the TextField
                      borderRadius: BorderRadius.circular(8.0),),
                    child: TextField(
                      controller: emailController,
                      cursorColor: Colors.red,
                      
                      decoration: const InputDecoration(

                        labelText: 'Provide Your Secure Email Address',labelStyle: TextStyle(color: Colors.red),                         
                        
                            
                            // Remove the default border

                            
                    ),
                  ),),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    
                    onPressed: verifyEmail,
                    child: const Text(' Authenticate'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(20),
                      primary: Colors.white, // White background for the button
                      onPrimary: Colors.red, // Black text color for the button
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
    
  }



