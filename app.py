from flask import Flask, request, jsonify
import pymysql
# from mysql.connector import Error
# from Crypto.Random import get_random_bytes
import random
import string
from flask_cors import CORS
from flask_socketio import SocketIO, emit
from flask_mail import Mail,Message



app = Flask(__name__)
CORS(app) 
socketio = SocketIO(app)

# MySQL credentials and database name
db_config = {
    'host': 'localhost',
    'user': 'admin',
    'password': '*********',
    'database': 'chat_app_db',
}

# mail configuration

app.config['MAIL_SERVER'] = 'smtp.office365.com'
app.config['MAIL_PORT'] = 587
app.config['MAIL_USE_TLS'] = True
app.config['MAIL_USERNAME'] = 'sampleid@outlook.com'
app.config['MAIL_PASSWORD'] = '******'

mail = Mail(app)
# Establish the connection to MySQL
connection = None
try:
    connection = pymysql.connect(**db_config)
    cursor = connection.cursor()

except Exception as e:
    print(f"Error connecting to MySQL{e}")
    exit(1)

@socketio.on('connect')
def handle_connect():
    print('Client connected')

@socketio.on('disconnect')
def handle_disconnect():
    print('Client disconnected')

def send_message_to_clients(username, encrypted_message):
    emit('message', {'username': username, 'encrypted_message': encrypted_message}, broadcast=True)    

@app.route('/send_message', methods=['POST'])
def send_message():
    try:
        data = request.get_json()
        username = data.get('username')
        encrypted_message = data.get('encrypted_message')

        if username and encrypted_message:
            insert_query = "INSERT INTO messages (username, encrypted_message) VALUES (%s, %s)"
            cursor.execute(insert_query, (username, encrypted_message))
            connection.commit()
            # send_message_to_clients(username, encrypted_message)

            return jsonify({"message": "Message received and stored successfully."}), 200
            send_message_to_clients(username=widget_username, encrypted_message=encrypted_message)
        else:
            return jsonify({"error": "Invalid request data."}), 400
    except Exception as e:
        print("Error:", str(e))
        return jsonify({"error": str(e)}), 500

# def send_message_to_clients(username, encrypted_message):
#     # This function will emit the 'message' event to all connected clients
#     emit('message', {'username': username, 'encrypted_message': encrypted_message}, broadcast=True)


@app.route('/get_messages', methods=['GET'])
def get_messages():
    try:
        # Retrieve all messages from the database
        select_query = "SELECT username, encrypted_message FROM messages"
        cursor.execute(select_query)
        messages = [{'username': username, 'encrypted_message': encrypted_message} for username, encrypted_message in cursor]

        return jsonify(messages), 200
    except Exception as e:
        print("Error:", str(e))
        return jsonify({"error": str(e)}), 500

@app.route('/verify_user', methods=['POST'])
def verify_user():
    try:
        data = request.get_json()
        username = data.get('username')
        email = data.get('email')

        #  list of valid emails
        valid_emails = ['thevibhav9@gmail.com', 'vibhavs0007@gmail.com', 'test@test']

        if username and email and email in valid_emails:
            # If the username and email are valid, generate and store an OTP for verification
            otp = generate_otp()
            store_otp(username, otp)  # Store the OTP in the backend
            send_otp_email(email, otp)  # Send the OTP via email
            return jsonify({"message": "User is verified. Check your email for OTP."}), 200
        else:
            return jsonify({"error": "You are not an authenticated user."}), 401
    except Exception as e:
        print("Error:", str(e))
        return jsonify({"error": str(e)}), 500

@app.route('/verify_otp', methods=['POST'])
def verify_otp():
    try:
        data = request.get_json()
        username = data.get('username')
        email = data.get('email')
        otp = data.get('otp')

        # Replace this with your logic to check if the OTP is valid
        if username and email and otp and check_valid_otp(username, otp):
            return jsonify({"message": "OTP verified. User is authenticated."}), 200
        else:
            return jsonify({"error": "Invalid OTP. Please try again."}), 401
    except Exception as e:
        print("Error:", str(e))
        return jsonify({"error": str(e)}), 500

# Helper function to generate a random 6-digit OTP
def generate_otp():
    return ''.join(random.choices(string.digits, k=6))

# Helper function to store the OTP in the backend (you can use a database or caching system for this)
def store_otp(username, otp):
    try:
        # Check if the username already exists in the database
        select_query = "SELECT * FROM otp_table WHERE username = %s"
        cursor.execute(select_query, (username))
        existing_user = cursor.fetchone()

        if existing_user:
            # If the username exists, update the OTP column for that user
            update_query = "UPDATE otp_table SET otp = %s WHERE username = %s"
            cursor.execute(update_query, (otp, username))
        else:
            # If the username is not present, insert a new row with the username and OTP
            insert_query = "INSERT INTO otp_table (username, otp) VALUES (%s, %s)"
            cursor.execute(insert_query, (username, otp))

        connection.commit()
    except Exception as e:
        print("Error storing OTP:", str(e))
        raise

# Helper function to send the OTP via email
def send_otp_email(email, otp):
    try:
 
        sender_email = 'vibhavs0007@outlook.com'
        message = f'Your OTP is: {otp}'
        msg = Message(subject="OTP Verification",
                  sender="sampledbsproject@outlook.com",
                  recipients= [email])
        msg.body = f"Hi, {message}"
        mail.send(msg)

    except Exception as e:
        print("Error sending OTP email:", str(e))
        raise

# Helper function to check if the provided OTP is valid
def check_valid_otp(username, otp):
    try:
        # Replace 'otp_table' where username-OTP pairs are stored
        select_query = "SELECT otp FROM otp_table WHERE username = %s"
        cursor.execute(select_query, (username,))
        stored_otp = cursor.fetchone()

        if stored_otp and stored_otp[0] == otp:
            # Delete the used OTP from the database for security
            delete_query = "DELETE FROM otp_table WHERE username = %s"
            cursor.execute(delete_query, (username,))
            connection.commit()
            return True
        else:
            return False
    except Exception as e:
        print("Error checking OTP:", str(e))
        raise


if __name__ == '__main__':
  socketio.run(app, host='127.0.0.1', port=5000)

  
