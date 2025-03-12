import threading
import queue
import time
import json
import random
import uuid
import serial
from brping import Ping1D
import subprocess
import requests
from datetime import datetime
from awscrt import mqtt
from awsiot import mqtt_connection_builder
import boto3
from botocore.exceptions import NoCredentialsError
import os
import signal
import socket
import logging

# Replace with your Wi-Fi credentials
WIFI_SSID = "you wifi username"
WIFI_PASSWORD = "you wifi password"
# Constants
SOC_PATH = "/tmp/qtble_server_comm"
API_KEY = "please enter your API key # api_key created in google cloud console
DEVICE = "/dev/ttyUSB0" # usb port where ping2 sensor connected is via USB-UART
BAUDRATE = 115200 # baud rate for reading value 
local_file_path = "/home/g9pi/Downloads/readyToUpload/" # path where file to upload is stored
s3_bucket_name = "g9capstoneiotapp-storage-uniqueusercertsa9559-dev" # AWS S3 Bucket Name
s3_storage_path = "public/MappedRoutes/" # AWS S3 Storage file path
wifi_connected = False
connected_to_aws = False
mqtt_connection = None
# Add Threading Events for State Control
state_machine_event = threading.Event()  # Event to control the state machine thread
sync_thread_event = threading.Event()   # Event to control the synchronizer thread

# Thread)-safe data structure
data_store = {"depth": None, "gps": None}
json_list = []   # List to store the JSON output
sync_queue = queue.Queue()  # Queue to send data to the synchronizer thread

# Geolocation base URL
GEOLOCATION_BASE_URL = "https://www.googleapis.com"

def connect_to_wifi(ssid, password):
    # Connect to a Wi-Fi network using the provided SSID and password.
    print(f"Attempting to connect to Wi-Fi network '{ssid}'...")
    result = subprocess.run(
        ['sudo', 'nmcli', 'dev', 'wifi', 'connect', ssid, 'password', password],
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE
    )
    if result.returncode == 0:
        print(f"Successfully connected to Wi-Fi network '{ssid}'.")
        return True
    else:
        print(f"Failed to connect to Wi-Fi network '{ssid}'.")
        print("Error:", result.stderr.decode())
        return False

def wifi_connect(wifi_ssid, wifi_password):
    global wifi_connected, connected_to_aws, mqtt_connection
    # Main function to handle Wi-Fi connection logic.
    try:
        # Check if Wi-Fi is blocked by RF-kill
        print("Checking if Wi-Fi is blocked by RF-kill...")
        result = subprocess.run(['rfkill', 'list'], stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        if 'Wireless LAN: blocked' in result.stdout.decode():
            print("Wi-Fi is blocked by RF-kill. Unblocking...")
            os.system("sudo rfkill unblock wifi")
        # Bring up the Wi-Fi interface
        print("Turning on Wi-Fi interface...")
        os.system("sudo nmcli radio wifi on")
        # Wait a few seconds for the Wi-Fi interface to initialize
        time.sleep(4)
        # Attempt to connect until successful
        while True:
            if connect_to_wifi(wifi_ssid, wifi_password):
                wifi_connected = True
                if not connected_to_aws:
                    print("connecting to AWS:")
                    # If not connected to AWS, establish the connection and subscribe to topics
                    mqtt_connection = connect_and_subscribe()  # Reuse the connection function
                    connected_to_aws = True
                    # Start a new thread to send heartbeat messages to AWS IoT Core
                    heartbeat_thread = threading.Thread(target=publish_heartbeat, args=(mqtt_connection,))
                    heartbeat_thread.daemon = True  # Make the thread exit when the main program exits
                    heartbeat_thread.start()
                    break
            else:
                wifi_connected = False
                connected_to_aws = False
                print("Retrying connection in 5 seconds...")
                time.sleep(5)  # Wait 5 seconds before retrying
    except KeyboardInterrupt:
        print("Script terminated by user.")
    except Exception as e:
        print(f"An error occurred: {e}")
        
# Update the State Machine's `run` Method
class StateMachine:
    def __init__(self, myPing):
        self.state = "READ_DEPTH"
        self.myPing = myPing  # Store myPing for use in the state machine
    def transition(self, new_state):
        print(f"Transitioning to {new_state}")
        self.state = new_state
    def run(self):
        global wifi_connected, mqtt_connection
    # This method implements the main loop of the state machine continuously transitions between states to perform specific tasks:
    # - READ_DEPTH: Reads depth data from the Ping sensor.
    # - READ_GPS: Fetches GPS location data using Wi-Fi geolocation.
    # - SYNC: Synchronizes the collected data and prepares it for further processing or transmission.
        while state_machine_event.is_set():  # Run while the event is set
            if self.state == "READ_DEPTH":
                # Call the function to read depth data from the Ping sensor The sensor data is stored in a shared data structure (`data_store`).
                read_ping2_sensor_depth(self.myPing)  # Pass the Ping sensor object to the function.
                # Transition to the next state, READ_GPS, after reading the depth.
                self.transition("READ_GPS")
            elif self.state == "READ_GPS":
                # read_serial_port() this is function to be used when GPS and system is tested in real outdoors environment
                if wifi_connected:
                    print("Geolocating........")
                    # Call the function to perform geolocation using available Wi-Fi access points.The resulting GPS coordinates (latitude, longitude, and accuracy) are saved in `data_store`.
                    gps_wifi_geolocate()
                else:
                    # if wifi is not available, just simulate - this is only for testing indoors (outdoors - will use actual gps device)
                    simulate_gps()
                # Transition to the next state, SYNC, after obtaining GPS data.
                self.transition("SYNC")
            elif self.state == "SYNC":
                # Call the function to synchronize the collected depth and GPS data. The data is typically added to a queue for further processing, such as saving to a log file or publishing to a cloud service.
                sync_data()
                # Transition back to the READ_DEPTH state to start the cycle again.
                self.transition("READ_DEPTH")
            # A delay of 0.1 seconds allows the state machine to run 10 times per second, balancing - Responsiveness - Efficiency
            time.sleep(1)
            
# Initialize the Ping2 sensor library
def init_ping2(device, baudrate):
    # Create a Ping1D object and establish a serial connection to the device
    myPing = Ping1D()
    myPing.connect_serial(device, baudrate)  # Connect to the specified device at the given baud rate
    myPing.set_ping_interval(29)
    myPing.set_speed_of_sound(1500)
    myPing.set_gain_setting(2)
    return myPing  # Return the initialized Ping1D object
    
def read_ping2_sensor_depth(myPing):
    # Read distance data from the Ping sensor
    data = myPing.get_distance()  # Fetch distance and confidence data from the sensor
    if data:
        # Extract and print the distance (in mm) and confidence (in percentage)
        depth = data["distance"]
        confidence = data["confidence"]
        print("Distance: %s mm\tConfidence: %s%%" % (depth, confidence))
        # Store the depth and confidence data in the shared data structure
        data_store["depth"] = {"distance": depth, "confidence": confidence}
    else:
        # Handle the case where data retrieval fails
        print("Failed to get distance data")

def read_serial_port():
    # Reads a single GNGLL line from the serial port and returns the parsed GPS data. 
    # Returns: dict: A dictionary with 'latitude', 'longitude', and 'status' if successful, or None if no valid data is found.
    port = "/dev/ttyACM1"
    baud_rate = 115200
    try:
        with serial.Serial(port, baud_rate, timeout=1) as ser:
            while True:
                if ser.in_waiting > 0:
                    line = ser.readline().decode('utf-8').strip()
                    if "GNGLL" in line:
                        parsed = parse_gngll_line(line)
                        if parsed:
                            lat, lon, status = parsed['latitude'], parsed['longitude'], parsed['status']
                            acc = 100 if status == 'A' else 0
                            data_store["gps"] = {"latitude": lat, "longitude": lon, "accuracy": acc}
                            print(f"Latitude: {lat}, Longitude: {lon}, Accuracy: {acc} meters")
    except serial.SerialException as e:
        print(f"Error opening or reading from serial port: {e}")
    return None

def parse_gngll_line(line):
    try:
        parts = line.split(',')
        if len(parts) < 7:
            return None
        # Extract latitude
        raw_lat = parts[1]
        lat_hemisphere = parts[2]
        latitude = convert_to_decimal(raw_lat, lat_hemisphere)
        # Extract longitude
        raw_lon = parts[3]
        lon_hemisphere = parts[4]
        longitude = convert_to_decimal(raw_lon, lon_hemisphere)
        # Extract status
        status = parts[6]
        return {"latitude": latitude, "longitude": longitude, "status": status}
    except (ValueError, IndexError):
        return None

def convert_to_decimal(raw_value, hemisphere):
    try:
        # Split into degrees and minutes
        degrees = int(raw_value[:2 if hemisphere in ['N', 'S'] else 3])
        minutes = float(raw_value[2 if hemisphere in ['N', 'S'] else 3:])
        decimal = degrees + minutes / 60
        # Apply hemisphere direction
        if hemisphere in ['S', 'W']:
            decimal = -decimal
        return decimal
    except (ValueError, IndexError):
        return None

def simulate_gps():
    latitude = 49.824
    longitude = -97.1545
    speed = 0.01
    # Simulate GPS movement by incrementing the latitude and longitude
    latitude += random.uniform(-speed, speed)  
    longitude += random.uniform(-speed, speed)
    accuracy = 0
    # Store the simulated data in the shared data_store
    if latitude and longitude:
        data_store["gps"] = {"latitude": latitude, "longitude": longitude, "accuracy": accuracy}
        print(f"Latitude: {latitude}, Longitude: {longitude}, Accuracy: {accuracy} meters")

def scan_wifi():
    try:
        # Run the command sudo iwlist wlan0 scan to get list of wifi access points
        result = subprocess.run(["sudo", "iwlist", "wlan0", "scan"], stdout=subprocess.PIPE)
        command_output = result.stdout.decode("utf-8")
        wifi_accesspoints_list = []
        mac_address, sig_strength = None, None
        # from the result get the Address and the Signal Level strength
        for line in command_output.split("\n"):
            line = line.strip()
            if "Address:" in line:
                mac_address = line.split("Address:")[1].strip()
            elif "Signal level=" in line:
                sig_strength = int(line.split("Signal level=")[1].split()[0])
                if mac_address is not None:
                    wifi_accesspoints_list.append({"macAddress": mac_address, "signalStrength": sig_strength})
                    mac_address, sig_strength = None, None
        return wifi_accesspoints_list
    except Exception as e:
        print(f"Error {e}")
        return []

def geolocate(wifi_access_points=None):
    params = {}
    if wifi_access_points is not None:
        params["wifiAccessPoints"] = wifi_access_points

    request_url = f"{GEOLOCATION_BASE_URL}/geolocation/v1/geolocate?key={API_KEY}"
    try:
        response = requests.post(request_url, json=params, timeout=10)
        response.raise_for_status()  # Raise exception for HTTP error responses
        location_data = response.json()
        if response.status_code == 200:
            return location_data
    except (requests.exceptions.RequestException, ValueError) as e:
        print(f"Geolocation error: {e}")
    return None  # Return None in case of failure

def gps_wifi_geolocate():
    wifi_access_points = scan_wifi()
    location_data = geolocate(wifi_access_points)
    if location_data:
        location = location_data.get("location", {})
        latitude = location.get('lat')
        longitude = location.get('lng')
        accuracy = location_data.get("accuracy", {})
        # Store and print the GPS data
        data_store["gps"] = {"latitude": latitude, "longitude": longitude, "accuracy": accuracy}
        print(f"Latitude: {latitude}, Longitude: {longitude}, Accuracy: {accuracy} meters")
    else:
        print("Geolocation failed. Using simulated GPS data.")
        simulate_gps()

# Synchronize Data
def sync_data():
    try:
        # Ensure both depth and GPS data are available
        if data_store["depth"] and data_store["gps"]:
            # Generate a timestamp for the synchronized data
            timestamp = time.strftime("%Y-%m-%d %H:%M:%S", time.gmtime())
            # Combine depth and GPS data into a single dictionary
            combined_data = {
                "distance": data_store["depth"]["distance"],  # Depth value in mm
                "confidence": data_store["depth"]["confidence"],  # Sensor confidence level
                "latitude": data_store["gps"]["latitude"],  # GPS latitude
                "longitude": data_store["gps"]["longitude"],  # GPS longitude
                "accuracy": data_store["gps"]["accuracy"],  # GPS accuracy in meters
                "timestamp": timestamp,  # Current timestamp in UTC
            }
            # Add the combined data to the synchronizer queue
            sync_queue.put(combined_data)
    except Exception as e:
        # Handle and log any errors during the synchronization process
        print(f"Error syncing data: {e}")
    
# Function to publish a message to an MQTT topic
def publish_message(mqtt_connection, topic, message, qos=mqtt.QoS.AT_LEAST_ONCE):
    # Print the message being published for logging purposes
    print(f"Publishing message to topic '{topic}': {message}")
    # Publish the message to the given topic wiTime messag esent by BLE is: 1738968541631.339th specified QoS
    mqtt_connection.publish(topic=topic, payload=message, qos=qos)

# Function to publish heartbeat messages at regular intervals
def publish_heartbeat(mqtt_connection):
    # Define the topic for heartbeat messages
    topic = "g9capstone/piHeartbeat"
    counter = 1
    # Loop to send heartbeat messages every 60 seconds
    while True:
        # Create a heartbeat message with a counter and timestamp
        heartbeat_message = json.dumps({"heartbeat": counter})
        # Publish the heartbeat message to the topic
        publish_message(mqtt_connection, topic, heartbeat_message)
        # Increment the counter for the next heartbeat
        counter += 1
        # Sleep for 60 seconds before sending the next heartbeat message
        time.sleep(60)  # Publish every 60 seconds

# Function to establish a connection to AWS IoT Core and subscribe to topics
def connect_and_subscribe():
    # Set up the AWS IoT endpoint and file paths for the certificates
    endpoint = "a265o0aqbr1bnh-ats.iot.ca-central-1.amazonaws.com"
    cert_filepath = "/home/g9pi/certs/device.pem.crt"
    pri_key_filepath = "/home/g9pi/certs/private.pem.key"
    ca_filepath = "/home/g9pi/certs/Amazon-root-CA-1.pem"
    client_id = "g9capstone_RPiDevice"
    # Create an MQTT connection object using mutual TLS authentication
    mqtt_connection = mqtt_connection_builder.mtls_from_path(
        endpoint=endpoint,
        cert_filepath=cert_filepath,
        pri_key_filepath=pri_key_filepath,
        ca_filepath=ca_filepath,
        client_id=client_id,
        clean_session=False,  # Persistent session
        keep_alive_secs=30  # Keep the connection alive with a 30-second interval
    )
    # Log the connection attempt to AWS IoT Core
    print(f"Connecting to {endpoint}...")
    # Establish the MQTT connection
    connect_future = mqtt_connection.connect()
    # Wait for the connection to be established
    connect_future.result()  
    # Log successful connection
    print("Connected to AWS IoT Core!")
    # Return the established MQTT connection
    return mqtt_connection

# Function to handle synchronization of data and manage MQTT connection
def synchronizer(sync_queue, ble_server):
    global wifi_connected, connected_to_aws, mqtt_connection, json_list
    # Initialize MQTT connection and AWS connection state
    connected_to_aws = False  # Track if the connection to AWS IoT Core is established
    while sync_thread_event.is_set():  # Run while the event is set
        try:
            # Block until data is available in the queue
            data = sync_queue.get()  
            if data is None:
                break  # Exit the loop if a None value is received (signal to stop)
            # Log the data in a formatted JSON structure
            print(json.dumps(data, indent=4))
            # Check Wi-Fi connectivity
            if wifi_connected and connected_to_aws:
                print(f"Time messag esent by Wifi is: {time.time() * 1000}")
                # Publish the data to AWS IoT Core if Wi-Fi is connected
                topic = "g9capstone/readValues"  # Define the topic for data
                message = json.dumps(data)  # Convert the data to JSON format
                publish_message(mqtt_connection, topic, message)  # Publish the message
            else:
                print(f"Time messag esent by BLE is: {time.time() * 1000}")
                msgOut = json.dumps({'depth': data, 'program': None}) + '\n'
                ble_server.sendall(msgOut.encode('utf-8'))
                print("sending by bluetooth:", data)
            # Append to the list for storage or future use
            json_list.append(data)
        except queue.Empty:  # Handle empty queue without blocking indefinitely
            continue
        except Exception as e:
            # Catch and log any exceptions that occur during processing
            print(f"Error in synchronizer: {e}")
            
# Function to upload a file to AWS S3
def upload_to_s3(file_path, bucket_name, object_name):
    # AWS credentials for S3 access
    aws_access_key_id = "please insert the aws access key here.."
    aws_secret_access_key = "please insert secret access key here.."
    # Initialize S3 client with provided credentials
    s3 = boto3.client(
        's3',
        aws_access_key_id=aws_access_key_id,
        aws_secret_access_key=aws_secret_access_key
    )
    try:
        # Attempt to upload the file to S3 with the specified bucket and object name
        s3.upload_file(file_path, bucket_name, object_name)
        print(f"File uploaded to S3: s3://{bucket_name}/{object_name}")
    except FileNotFoundError:
        # If the file is not found locally, print an error message
        print("The file was not found.")
    except NoCredentialsError:
        # If AWS credentials are not available or are incorrect, print an error message
        print("Credentials not available or incorrect.")

# Function to reverse geocode (get address) from latitude and longitude
def reverse_geocode(lat, long):
    # API key for Google Maps Geocoding API
    api_key = "AIzaSyCCVcP5u7dUEEDZepuFu4XrKl0NrNZK9rA"
    # Construct the URL for the geocoding API request
    url = f"https://maps.googleapis.com/maps/api/geocode/json?latlng={lat},{long}&key={api_key}"
    # Send a request to the geocoding API
    response = requests.get(url)
    if response.status_code == 200:
        # If the request is successful, parse the JSON response
        data = response.json()
        if data['results']:
            # Return the formatted address from the response
            return data['results'][0]['formatted_address']
        else:
            # If no address is found, return a message
            return "No address found"
    else:
        # If the API request fails, return an error message
        return f"Error: {response.status_code}"

# Function to process and upload files in a folder, then delete them after successful upload
def process_and_upload(file_path, bucket_name, s3_path):
    global wifi_connected
    if wifi_connected:
        # Iterate over all files in the directory
        for filename in os.listdir(file_path):
            local_file = os.path.join(file_path, filename)
            # Only process JSON files
            if os.path.isfile(local_file):
                try:
                    # Read the JSON data from the file
                    with open(local_file, 'r') as file:
                        data = json.load(file)
                    if data:
                        # Extract latitude and longitude from the first record in the data
                        first_lat = data[0].get('latitude')
                        first_long = data[0].get('longitude')
                        # If latitude and longitude are available, proceed with further steps
                        if first_lat and first_long:
                            # Perform reverse geocoding to get the address of the first coordinate
                            first_location = reverse_geocode(first_lat, first_long)
                            # Generate a file path for S3 based on the geocoded address
                            current_utc_time = datetime.now().strftime('%Y-%m-%d_%H-%M-%S')
                            s3_file_pathname = f"{s3_path}{first_location}_{current_utc_time}.txt"
                            print(f"Generated S3 filename: {s3_file_pathname}")
                            # Upload the file to S3 using the generated filename
                            upload_to_s3(local_file, bucket_name, s3_file_pathname)
                            print(f"File (Mapped Route for Session): {s3_file_pathname} uploaded to AWS S3 Storage Server")
                            # Delete the local file after successful upload
                            os.remove(local_file)
                            print(f"Deleted local file: {local_file}")
                except Exception as e:
                    print(f"Failed to process file {local_file}: {e}")
                
def savelocalFile(file_path):
    global json_list
    if not json_list:  # Check if json_list is empty
        print("No data to save. json_list is empty.")
        return  # Exit the function early
    # Generate a unique filename using UUID and current date/time
    unique_filename = f"{uuid.uuid4()}_{datetime.now().strftime('%Y%m%d_%H%M%S')}.txt"
    full_file_path = os.path.join(file_path, unique_filename)
    # Write to the generated file
    with open(full_file_path, 'w+') as file:
        json.dump(json_list, file, indent=4)
    print(f"Saved the session (START-STOP) data to a local file: {full_file_path}")
    json_list = []  # Clear json_list after saving

if __name__ == "__main__":
    command = ""
    initialized = False
    # Initialize the Ping2 device
    while not initialized:
        myPing = init_ping2(DEVICE, BAUDRATE)
        if not myPing.initialize():
            print("Failed to initialize Ping!")
        else:
            initialized = True
     # remove the socket file if it already exists
    try:
        os.unlink(SOC_PATH)
    except OSError:
        if os.path.exists(SOC_PATH):
            raise
    # Create the Unix socket server
    server = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
    # Bind the socket to the path
    server.bind(SOC_PATH)
    # Listen for incoming connections
    server.listen(1)
    # accept connections
    print('Waiting for bluetooth server connection...')
    ble_server, addr = server.accept()
    # Start state machine with myPing
    state_machine = StateMachine(myPing)
    # try to connect to WiFi
    wifi_thread = threading.Thread(target=wifi_connect, args=(WIFI_SSID, WIFI_PASSWORD))
    wifi_thread.start()
    state_machine_thread = None
    sync_thread_event.set()
    sync_thread = threading.Thread(target=synchronizer, args=(sync_queue, ble_server))
    sync_thread.start()
    try:
        ble_server.setblocking(False)
        msgOut = json.dumps({'depth': None, 'program': "START"})
        ble_server.sendall(msgOut.encode('utf-8')) 
        while True:
            try:
                msgIn = ble_server.recv(1024)
                if not msgIn:
                    break
                msgIn = json.loads(msgIn.decode('utf-8'))
                if msgIn['device_state'] != None:
                    command = msgIn['device_state']
            except OSError:
                pass 
            if command == "START":
                if not state_machine_event.is_set():
                   print("Starting state machine...")
                   state_machine_event.set()
                   state_machine_thread = threading.Thread(target=state_machine.run)
                   state_machine_thread.start()
                   sync_thread_event.set()
            elif command == "STOP":
                if state_machine_event.is_set():
                    print("Stopping state machine and synchronizer...")
                state_machine_event.clear()
                sync_thread_event.clear()
                savelocalFile(local_file_path)
                command = None
            elif command == "UPLOAD":
                if wifi_connected:
                    # Upload the file to S3
                    print(f"Uploading {local_file_path} to S3...")
                    process_and_upload(local_file_path, s3_bucket_name, s3_storage_path)
                command = None
    except KeyboardInterrupt:
        print("Current time on RPi Machine (ms): ", time.time() *1000)  
        print("Stopping state machine due to keyboard interrupt...")
        sync_queue.put(None)  # Send exit siTime messag esent by BLE is: 1738968541631.339gnal to synchronizer
        sync_thread.join()  # Ensure the synchronizer thread finishes
        sync_thread.join()  # Ensure the synchronizer thread finishes
        msgOut = json.dumps({'depth': None, 'program': "STOP"}) + '\n'
        ble_server.sendall(msgOut.encode('utf-8'))
        # close the connection
        ble_server.close()
