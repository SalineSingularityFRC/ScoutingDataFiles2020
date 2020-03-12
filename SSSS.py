#!/usr/bin/env python3

from bluetooth import *
from gpiozero import LED
from time import sleep
import json

ROOT = "/var/SSSS"
uuid = "4f63aea8-be86-4f54-b8c8-2f0c9d37b56b"
name = "Super Singularity Scouting Server"

# Get LED pins for GPIO stuff
led = LED(17)
err_led = LED(27)

def main():
    # Setup a socket for RFCOMM (serial over bluetooth)
    server_sock = BluetoothSocket(RFCOMM)
    server_sock.bind(("",PORT_ANY))

    # Listen on serial port 1
    server_sock.listen(1)
    port = server_sock.getsockname()[1]

    # Advertise the RFCOMM signal
    advertise_service(server_sock, name,
        service_id = uuid,
        service_classes = [ uuid, SERIAL_PORT_CLASS ],
        profiles = [ SERIAL_PORT_PROFILE ]
    )

    # Run the client
    # Keep JSON in memory!
    try:
        while True:
            print("\nWaiting for connection on RFCOMM port {}".format(port))

            client_sock, client_info = server_sock.accept()
            print("Accepted connection from {}".format(client_info[0]))

            # Wait for one data packet
            try:
                data = client_sock.recv(1024)
                led.on()
                sleep(0.2)
                led.off()
                print("Data recieved: {}".format(data))
            except:
                print("Failed to recieve data over connection")
                continue

            #
            # MATCH DATA
            #

            # Open current JSON file for reading and load to current_data
            data_file = open("{}/matchData.json".format(ROOT), "r").read().rstrip()
            try:
                current_data = json.loads(data_file)
            except:
                print("Failed to load JSON. Is your JSON actually valid?")
                raise

            # Load JSON from bluetooth
            dataJSON = json.loads(data.decode("utf-8"))
            if len(dataJSON["matchData"]) < 1 and len(dataJSON["teamData"]) < 1:
                print("Got empty list")
                send_team_data(client_sock)
                print("Disconnecting...", end="")
                client_sock.close()
                print("OK")
                continue

            current_data.append(dataJSON["matchData"][0])

            # Write file
            if len(dataJSON["matchData"]) > 1:
                print("Writing to {}/matchData.json...".format(ROOT), end="")
                try:
                    match_data = open("{}/matchData.json".format(ROOT), "w")
                    match_data.write(json.dumps(current_data))
                    match_data.close()
                except:
                    clean_exit()
                    continue
                print("OK")
            
            #
            # TEAM DATA
            #

            # Read team data
            team_data = open("{}/teamData.json".format(ROOT), "r").read().rstrip()
            try:
                current_data = json.loads(team_data)
            except:
                print("Failed to load JSON. Is your JSON actually valid?")
                raise

            current_data.append(dataJSON["teamData"])

            # Write team data
            if len(dataJSON["teamData"]) > 1:
                print("Writing to {}/teamData.json...".format(ROOT), end="")
                try:
                    team_data_file = open("{}/teamData.json".format(ROOT), "w")
                    team_data_file.write(json.dumps(current_data))
                    team_data_file.close()
                except:
                    clean_exit()
                    continue
                print("OK")

            print("Sending data...", end="")
            try:
                send_team_data(client_sock)
            except:
                print("FAILED!")
            print("OK")

            print("Disconnecting...", end="")
            client_sock.close()
            print("OK")

    except KeyboardInterrupt:
        server_sock.close()
        print("\nClosed connection")
    except:
        server_sock.close()
        print("An error occurred!")
        raise

    print("Finished")

def send_team_data(client_sock):
    team_data = open("{}/teamData.json".format(ROOT), "r")
    client_sock.send(team_data.read())
    team_data.close()

def clean_exit():
    err_led.on()
    print("FAILED")
    print("Disconnecting...", end="")
    client_sock.close()
    print("OK")

if __name__ == "__main__":
    main()
