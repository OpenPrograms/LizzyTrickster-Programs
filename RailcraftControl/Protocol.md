Stuff
============


Should probably put this into a Markdown Document
Cmd/MessageID index, sorta
0: Client2Server-B - Generic 'hello' meessage, used to notify the server it exists
- Parameters: Empty String
1: Server2Client-U - Aspect update message, used in general and also to get an mcu up to speed after it's added
- Parameters: String in the format "[AT][1-4]": A/T = Away/Towards, 1-4 = aspect. 
2: Server2Client-U - "I am master", used to tell MCUs of which address to listen to for aspect updates
- Parameters: String UUID of the Network card connected to the MCUs
3: Client2Server-B - "Where master?", used for MCUs that have lost the master server, server should respond with 2
- Parameters: String UUID of the MCU's netowrk card address
4: Server2Clients-B - Update available notification, MCUs should wait a short period before sending a 5
- Parameters: Checksum of the update, should match what it can get from EEPROM.getChecksum()
5: Client2Server-U - Can haz update?
- Parameters: Checksum of the EEPROM: used server side to tell the MCU if it needs the update or not
6: Server2Client-U - here (may or may not) be the update!, EEPROMs are 4096 bytes in size, default max net messages are 8192 bytes
- Parameters: the update string, MCUs should then set() this to their EEPROMs and reboot.
7: Client2Server-U - Update Complete -- Remove? not really needed because the server will send out updates regardless of whether an MCU is connected or not
8: Any2Any-U - PING! sent from either mcu to server or visaversa, never from mcu to mcu
9: Same2AsAbove-U PONG! the response to 8



