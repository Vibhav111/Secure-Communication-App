
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'dart:typed_data';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:socket_io_client/socket_io_client.dart' as io; // Import the socket_io_client package

class ChatScreen extends StatefulWidget {
  final String username;

  ChatScreen({super.key, required this.username});

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  // WebSocketChannel? channel; // Declare a WebSocketChannel
  TextEditingController messageController = TextEditingController();
  List<Map<String, String>> messages = [];
  io.Socket? socket;

  final String serverUrl = 'http://127.0.0.1:5000';

  // fixed encryption key
  final key = encrypt.Key(Uint8List.fromList(base64Url.decode('3Qf4t5w2QhHQq1rHAa/qqgL0XjVX0RjniZ4otR8tU1I=')));

  @override
  void initState() {
    super.initState();
    // Call getMessages when the screen is loaded to fetch existing messages from the server
    getMessages();
    
    // Establish WebSocket connection
    socket = io.io('http://127.0.0.1:5000', <String, dynamic>{
      'transports': ['websocket'], // Use WebSocket transport
    });
        // Establish WebSocket connection
    // channel = WebSocketChannel.connect(Uri.parse('ws://127.0.0.1:5000/socket.io/'));

        // Listen for incoming messages from the server
    socket!.on('message', (data) {
      // Handle the incoming message (e.g., add it to the messages list)
      setState(() {
        // Assuming your incoming message format is JSON
        final Map<String, dynamic> decodedMessage = jsonDecode(data);
        final String decryptedMessage = decryptMessage(decodedMessage['encrypted_message']);
        messages.add({
          'username': decodedMessage['username'],
          'encrypted_message': decodedMessage['encrypted_message'],
        });
      });
    });

    // Connect to the WebSocket server
    socket!.connect();
    // // Listen for incoming messages from the server
    // channel!.stream.listen((message) {
    //   // Handle the incoming message (e.g., add it to the messages list)
    //   setState(() {
    //     // Assuming your incoming message format is JSON
    //     final Map<String, dynamic> decodedMessage = jsonDecode(message);
    //     final String decryptedMessage = decryptMessage(decodedMessage['encrypted_message']);
    //     messages.add({
    //       'username': decodedMessage['username'],
    //       'encrypted_message': decodedMessage['encrypted_message'],
    //     });
    //   });
    // });
  }

     @override
  void dispose() {
    // Close the WebSocket connection when the widget is disposed
    socket!.disconnect();
    super.dispose();
  }
  Future<void> sendMessage() async {
    final String originalMessage = messageController.text;
    final String encryptedMessage = await encryptMessage(originalMessage);

    final url = '$serverUrl/send_message';
    final response = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'username': widget.username, 'encrypted_message': encryptedMessage}),
    );

if (response.statusCode == 200) {
    // Add the message to the local messages list and clear the message input field
    setState(() {
      messages.add({'username': widget.username, 'encrypted_message': encryptedMessage});
      messageController.clear();
    });

    // Send the encrypted message over the WebSocket
    socket!.emit('send_message', jsonEncode({
      'username': widget.username,
      'encrypted_message': encryptedMessage,
    }));
        
    // Send the encrypted message over the WebSocket
    // channel!.sink.add(jsonEncode({
    //   'username': widget.username,
    //   'encrypted_message': encryptedMessage,
    // }));
     }
    else {
      print('Failed to send message. Status Code: ${response.statusCode}');
    }
  }

  Future<String> encryptMessage(String message) async {
    final iv = encrypt.IV.fromSecureRandom(16); // Generate a random IV
    final encrypter = encrypt.Encrypter(encrypt.AES(key, mode: encrypt.AESMode.cbc, padding: 'PKCS7'));
    final encrypted = encrypter.encrypt(message, iv: iv);

    final ivString = iv.base64.replaceAll('/', '_').replaceAll('+', '-'); // Replace URL-unsafe characters
    final encryptedString = encrypted.base64.replaceAll('/', '_').replaceAll('+', '-'); // Replace URL-unsafe characters

    return '$ivString:$encryptedString'; // Combine IV and encrypted data as a single string
  }
  

 

  Future<void> getMessages() async {
    final url = '$serverUrl/get_messages';
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      if (data is List) {
        final List<Map<String, String>> decryptedMessages = data.map((message) {
          return {
            'username': message['username'].toString(),
            'encrypted_message': message['encrypted_message'].toString(),
          };
        }).toList();

        setState(() {
          messages = decryptedMessages;
        });
      } else {
        print('Invalid response data format');
      }
    } else if (response.statusCode == 204) {
      // If the response code is 204 (No Content), it means the database is empty
      setState(() {
        messages = [];
      });
    } else {
      print('Failed to get messages. Status Code: ${response.statusCode}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Secret Chats')),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          
          children: [
            Expanded(
            
              child: ListView.builder(
              
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  final message = messages[index];
                  final String decryptedMessage = decryptMessage(message['encrypted_message']!);
                  final isCurrentUser = message['username'] == widget.username;
      
       return   Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Column(
        crossAxisAlignment:
            isCurrentUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Container(
            decoration: BoxDecoration(
              color: isCurrentUser ? Colors.grey[300] : Colors.red[300],
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(12),
                topRight: const Radius.circular(12),
                bottomLeft: isCurrentUser ? Radius.circular(12) : Radius.circular(0),
                bottomRight: isCurrentUser ? Radius.circular(0) : Radius.circular(12),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Column(
              crossAxisAlignment:
                  isCurrentUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Text(
                   '${message['username']}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isCurrentUser ? Colors.black : Colors.white, 
                  ),
                ),
                const  SizedBox(height: 4),
                Text(
                  decryptedMessage,
                  style: TextStyle(
                    color: isCurrentUser ? Colors.black : Colors.white,
                  ),
                ),


              ],
            ),
          ),
        ],
      ),
    );

                },
              ),
            ),
            Container(
              padding: EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: messageController,
                      decoration:const  InputDecoration(hintText: 'Type a message...'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: sendMessage,
                    child: Text('Send'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }


String decryptMessage(String encryptedMessage) {
  // Spliting the combined IV and encrypted data
  final parts = encryptedMessage.split(':');
  if (parts.length != 2) {
    // Invalid encrypted message format
    return 'Error: Invalid encrypted message';
  }
  final ivString = parts[0];
  final encryptedDataString = parts[1];

  // Replacing URL-safe characters in IV and encrypted data
  final iv = encrypt.IV.fromBase64(ivString.replaceAll('_', '/').replaceAll('-', '+'));
  final encryptedData = encrypt.Encrypted.fromBase64(encryptedDataString.replaceAll('_', '/').replaceAll('-', '+'));

  // Decrypt the data
  final encrypter = encrypt.Encrypter(encrypt.AES(key, mode: encrypt.AESMode.cbc, padding: 'PKCS7'));
  final decrypted = encrypter.decrypt(encryptedData, iv: iv);

  return decrypted;
}

}