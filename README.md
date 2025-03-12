## UoM G9 Capstone Project

## Design and Implementation of IoT Lake/River Real-Time Depth Monitoring, Hazard Detection and Path Mapping System.

### aims to enable boaters to conduct bathymetric surveys of lakes or rivers and leverage the survey data to enhance their boating experience and safety. Boaters can integrate our device onto their boats to monitor real-time depth and location data via our phone app and upload this data to our database. The app utilizes the database to visualize surveyed areas, provide navigational services for safe routing, and perform hazard differentiation.

## Team Members:
    1. Sukhmeet Singh Hora (7884859) 
    2. Sudipta Dip (7900493) 
    3. Gunjan Modi (7859501) 
    4. Matt Fryatt (7743214) 
    5. Het Patel (7868309) 
    6. Justine Ugalde (7789023) 

##### Department Supervisor: Dr. Ken Ferens 

### Note for the App:
This repository is read-only and is intended for reference purposes only. While you can explore the code and structure of the application, it cannot be cloned and run directly due to its dependencies on AWS services and configurations tied to a specific AWS account.

Why Can't This App Be Cloned and Run?
This application is built on Amazon Web Services (AWS) and integrates various AWS-managed services and Google Cloud Services, including: AWS Amplify, AWS IoT Core – For real-time communication and device management, Amazon S3 – For cloud storage and asset management and GraphQL APIs (AWS AppSync) – For data queries and mutations, Google Cloud for maps integration, geolocation and location access.

Since these AWS services are configured within a private AWS account, any cloned version of this repository will not function as expected unless properly set up with new AWS credentials and configurations.

#### App Configuration Steps Done on AWS Server for Reference Only: 
1. Run **flutter pub get** to install dependencies
2. Setup the app with AWS Amplify
    2.1 Setup Amplify CLI and configure Amplify using the instructions https://docs.amplify.aws/gen1/flutter/tools/cli/start/set-up-cli/
    2.2 used the command **amplify configure**
    2.3 Initialize amplify running the command **amplify init** and select yes for existing environment
    2.4 Then Run **amplify pull**
3. Create certs, provisioning template on AWS IoT Core
    2.1 Acces AWS IoT Core to create a thing, certs, policy and attach the certs folder in assets folder in app. Steps example here: https://docs.aws.amazon.com/iot/latest/developerguide/iot-moisture-create-thing.html
    2.2 Create a fleet provisioning template by claim (used in this app): steps here: https://docs.aws.amazon.com/iot/latest/developerguide/provision-wo-cert.html#claim-based


