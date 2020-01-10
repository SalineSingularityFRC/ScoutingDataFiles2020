from bluetooth import *
import json

server_sock=BluetoothSocket(RFCOMM)
server_sock.bind(("",PORT_ANY))
server_sock.listen(1)

port=server_sock.getsockname()[1]

uuid="4f63aea8-be86-4f54-b8c8-2f0c9d37b56b"
name="Super Singularity Scouting Server"

advertise_service(server_sock, name,
	service_id = uuid,
	service_classes = [ uuid, SERIAL_PORT_CLASS ],
	profiles = [ SERIAL_PORT_PROFILE ]
)

def doClient():
	print("Waiting for connection on RFCOMM channel %d" % port)

	client_sock, client_info = server_sock.accept()
	print("Accepted connection from "+client_info[0])


	try:
		data = client_sock.recv(1024)
		print("Data recieved.")
		print(data)
		str=open("/var/www/html/matchData.json","r").read()
		matchDataFile=open("/var/www/html/matchData.json","w")
		dataJSON = json.loads(data.rstrip())
		matchDataString=json.dumps(dataJSON["matchData"])[1:-1]
		targetLength=len(matchDataString)
		if len(matchDataString)>5:
			str=str[:-1]
			str=str.strip("]")
			matchDataFile.write(str+","+matchDataString+"]")
		else:
			matchDataFile.write(str)
		matchDataFile.close()
		teamDataFile = open("/var/www/html/teamData.json","a")
		teamDataString=","+json.dumps(dataJSON["teamData"])[1:-1]
		if len(teamDataString)>1:
			teamDataFile.write(teamDataString)
		teamDataFile.close()
		teamDataFile = open("/var/www/html/teamData.json","r")
		
		client_sock.send(""+teamDataFile.read()+"]\n")
		teamDataFile.close()
		print("Data sent.")
	except IOError:
		print("An IOError occurred")
		pass

	print("Disconnected.\n")

	client_sock.close()

try:
	while True:
		doClient()
except KeyboardInterrupt:
	server_sock.close()
	print("\nAll done.")
except:
	server_sock.close()
	print("An error occurred.")
	raise
print("End of Program")
