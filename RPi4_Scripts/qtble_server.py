import sys
import signal
import socket
import json
import os
import time
from subprocess import call
from PySide6.QtBluetooth import (QBluetoothUuid, QLowEnergyAdvertisingData,
                                 QLowEnergyAdvertisingParameters,
                                 QLowEnergyCharacteristic,
                                 QLowEnergyCharacteristicData,
                                 QLowEnergyController,
                                 QLowEnergyDescriptorData,
                                 QLowEnergyService,
                                 QLowEnergyServiceData)
from PySide6.QtCore import      (QUuid, 
                                 QByteArray, 
                                 QLoggingCategory, 
                                 QCoreApplication, 
                                 QTimer,
                                 QSocketNotifier)

DEVICE_CTRL_SERV =      QBluetoothUuid(QUuid("37dd28eb-b0e5-4714-b874-0fa1f50f88bf"))
DEVICE_STATE_CHAR =     QBluetoothUuid(QUuid("9232ed36-2122-4773-b1c8-31c2d5114e96"))
DEPTH_MONITOR_SERV =    QBluetoothUuid(QUuid("cbc3bb98-e29b-4b8d-8a1b-3e90aa65a790"))
DEPTH_DATA_CHAR =       QBluetoothUuid(QUuid("6943ec7e-cb2e-4b44-9adc-7f5d12837bd1"))
ACC_INFO_SERV =         QBluetoothUuid(QUuid("f50fd87e-a637-40b7-8688-2c19543e32b9"))
ACC_LOGIN_CHAR =        QBluetoothUuid(QUuid("0409c619-7985-4d33-b999-b03680392af1"))
ACC_PASS_CHAR =         QBluetoothUuid(QUuid("1f302110-00c4-4cff-b61b-164da324fe04"))

SOC_PATH = "/tmp/qtble_server_comm"

app = None
main_prog = None
advertising_data = None
le_controller = None
ctrl_service = None
monitor_service = None
info_service = None
ctrl_service_data = None
monitor_service_data = None
info_service_data = None

def depth_provider():
    global app, main_prog, monitor_service
    
    try:
        msgIn = main_prog.recv(1024)
        if msgIn:            
            print(msgIn)
            msgIn = msgIn.split(b'\n')
            if msgIn[-1] == b'':
                msgIn = msgIn[0]
            else:
                msgIn = msgIn[-1] 
            print(msgIn)
            msgIn = json.loads(msgIn.decode('utf-8'))
            if msgIn['program'] == "STOP":
                app.quit()
            else:
                value = QByteArray(json.dumps(msgIn['depth']))
                # print(int.from_bytes(value.data()))
                characteristic = monitor_service.characteristic(DEPTH_DATA_CHAR)
                assert characteristic.isValid()
                # Potentially causes notification.
                monitor_service.writeCharacteristic(characteristic, value)
    except OSError:
        pass

def changeState(info, newValue):
    global main_prog

    msgOut = {'device_state': newValue.toUpper().toStdString(), 'username': None, 'password': None}
    print("NEW STATE:\t", msgOut['device_state'])
    msgOut = json.dumps(msgOut)
    main_prog.sendall(msgOut.encode('utf-8'))
        
def retrievedAccInfo(info, newValue):
    global main_prog
    msgOut = ""
    if info.uuid() == ACC_LOGIN_CHAR:
        msgOut = {'device_state': None, 'username': newValue.toStdString(), 'password': None}
        print("Username:", msgOut['username'])
    elif info.uuid() == ACC_PASS_CHAR:
        msgOut = {'device_state': None, 'username': None, 'password': newValue.toStdString()}
        print("Password:", msgOut['password'])
    msgOut = json.dumps(msgOut)
    main_prog.sendall(msgOut.encode('utf-8'))
    info_service.writeCharacteristic(info, bytes(1))

def reconnect():
    errMsg = "NO DEVICES ARE CURRENTLY CONNECTED CONNECTED TO BLE SERVER"
    border = "\n" + "=" * len(errMsg) + "\n"
    errMsg += "\n\tRestarting the BLE Server"
    print(border + errMsg + border)
    ble_server()

def ble_server():
    global advertising_data, le_controller, ctrl_service, monitor_service, info_service

    le_controller = QLowEnergyController.createPeripheral()

    #! [Advertising Data]
    advertising_data = QLowEnergyAdvertisingData()
    advertising_data.setDiscoverability(QLowEnergyAdvertisingData.DiscoverabilityGeneral)
    advertising_data.setIncludePowerLevel(True)
    advertising_data.setLocalName("Depth Monitoring Device")
    advertising_data.setServices([DEVICE_CTRL_SERV])
    #! [Advertising Data]

    #! [Device Control Service Data]
    state_char_data = QLowEnergyCharacteristicData()
    state_char_data.setUuid(DEVICE_STATE_CHAR)
    state_char_data.setValue(QByteArray(1, 0))
    state_char_data.setValueLength(1,32)
    state_char_data.setProperties(QLowEnergyCharacteristic.Write | QLowEnergyCharacteristic.Read)

    description = "Switch between states on connected device; start = b'start', stop = b'stop', upload = b'upload"
    user_des = QLowEnergyDescriptorData(QBluetoothUuid.DescriptorType.CharacteristicUserDescription, QByteArray(description))
    state_char_data.addDescriptor(user_des)

    ctrl_service_data = QLowEnergyServiceData()
    ctrl_service_data.setType(QLowEnergyServiceData.ServiceTypePrimary)
    ctrl_service_data.setUuid(DEVICE_CTRL_SERV)
    ctrl_service_data.addCharacteristic(state_char_data)

    ctrl_service = le_controller.addService(ctrl_service_data)
    #! [Device Control Service Data]

    #! [Depth Monitor Service Data]
    dvalue_char_data = QLowEnergyCharacteristicData()
    dvalue_char_data.setUuid(DEPTH_DATA_CHAR)
    dvalue_char_data.setValue(QByteArray(1, 0))
    dvalue_char_data.setProperties(QLowEnergyCharacteristic.Notify)
    client_config = QLowEnergyDescriptorData(QBluetoothUuid.DescriptorType.ClientCharacteristicConfiguration, QByteArray(2, 0))
    dvalue_char_data.addDescriptor(client_config)

    description = "Get notified with the most recent depth data measured in json"
    user_des = QLowEnergyDescriptorData(QBluetoothUuid.DescriptorType.CharacteristicUserDescription, QByteArray(description))
    dvalue_char_data.addDescriptor(user_des)

    monitor_service_data = QLowEnergyServiceData()
    monitor_service_data.setType(QLowEnergyServiceData.ServiceTypePrimary)
    monitor_service_data.setUuid(DEPTH_MONITOR_SERV)
    monitor_service_data.addCharacteristic(dvalue_char_data)
    monitor_service = le_controller.addService(monitor_service_data)
    #! [Depth Monitor Service Data]

    #! [Account Info Service Data]
    login_char_data = QLowEnergyCharacteristicData()
    login_char_data.setUuid(ACC_LOGIN_CHAR)
    login_char_data.setValue(QByteArray(1, 0))
    login_char_data.setProperties(QLowEnergyCharacteristic.Write)

    pass_char_data = QLowEnergyCharacteristicData()
    pass_char_data.setUuid(ACC_PASS_CHAR)
    pass_char_data.setValue(QByteArray(1, 0))
    pass_char_data.setProperties(QLowEnergyCharacteristic.Write)

    info_service_data = QLowEnergyServiceData()
    info_service_data.setType(QLowEnergyServiceData.ServiceTypePrimary)
    info_service_data.setUuid(ACC_INFO_SERV)
    info_service_data.addCharacteristic(login_char_data)
    info_service_data.addCharacteristic(pass_char_data)

    info_service = le_controller.addService(info_service_data)
    #! [Account Info Service Data]

    #! [Start Advertising]
    le_controller.startAdvertising(QLowEnergyAdvertisingParameters(), advertising_data, advertising_data)
    #! [Start Advertising]

    ctrl_service.characteristicChanged.connect(changeState)
    info_service.characteristicChanged.connect(retrievedAccInfo)
    le_controller.disconnected.connect(reconnect)



if __name__ == '__main__':
    signal.signal(signal.SIGINT, signal.SIG_DFL)
    # Set the bluetooth I/O capbility to NoInputNoOutput for pairing
    call("sudo btmgmt io-cap 3", shell=True)
    # Create PySide6 application object
    app = QCoreApplication(sys.argv)
    QLoggingCategory.setFilterRules("qt.bluetooth* = true")
    # Create the Unix socket client
    main_prog = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
    # Continuously attempt to connect to main program
    print("Waiting for main program to start...")
    found = False
    while found == False:
        try:
            main_prog.connect(SOC_PATH)
            found = True
        except:
            time.sleep(2)
    
    msgIn = main_prog.recv(1024)
    msgIn = json.loads(msgIn.decode('utf-8'))
    
    if msgIn['program'] == "START":
        main_prog.setblocking(False)
        socNotifier = QSocketNotifier(main_prog.fileno(), QSocketNotifier.Read)
        socNotifier.setEnabled(True)
        socNotifier.activated.connect(depth_provider)
        ble_server()
        app.exec() # this line blocks until pside6 application is quit
        # close the connection
        main_prog.close()
        # remove the socket file
        os.unlink(SOC_PATH)
        # Reset the bluetooth I/O capbility to DisplayYesNo for pairing
        call("sudo btmgmt io-cap 1", shell=True)




