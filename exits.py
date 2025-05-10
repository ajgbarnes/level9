###############################################################################
# Python Level 9 Exit Definiton extractor for Version 1 Games
###############################################################################
#
# Written after reverse engineering the BBC Micro game.
#
# Implementation in Python of the Level 9 BBC Micro Version 1 A-Code engine
# used in the following games:
#
# - Adventure Quest (1982)
# - Colossal Adventure (1982)
# - Dungeon Adventure (1982)
# - Snowball (1983)
# - Lords of Time (1983)
#
# Will extend this at some point to v2, v3 and v4.
#
# Game files are written by Level 9 Computing (c) Copyright 1982, 1983
#
# Code and comments by Andy Barnes (c) Copyright 2022 (for now)
#
# Twitter @ajgbarnes
#
# This was used a reference to functions only as I struggled understanding 
# the code - nearly all my understanding came from decompiling the BBC Micro's 
# game code.
###############################################################################
import sys
import argparse
from l9config import v1Configuration
import logging

loadAddress          = int("1200",16)
dictionaryAddr       = 128
# Stored at 732F
exitsAddr            = 1072
messagesStartAddr    = 5984
commonFragmentsAddr  = 24503

directions = [
    "  -  ",
    "North",
    "NEast",
    "East",
    "South",
    "SEast",
    "SWest",
    "West",
    "NWest",
    "Up",
    "Down",
    "Enter",
    "Leave",
    "Cross",
    "Climb",
    "Jump"
]

###############################################################################
# _getAddrForFragment
#
# Gets the address in the game file of the nth common word fragment. Each
# common fragment is seperated by a 0x01.
# 
#
# Parameters: 
#    data           - the game file byte array
#    fragmentNumber - nth fragment to find address of
#
# Returns:
#   Address of the nth fragment
###############################################################################
def _getAddrForFragment(data, fragmentNumber):
  
    address=commonFragmentsAddr

    while fragmentNumber:
        if(data[address]==1):
            fragmentNumber = fragmentNumber - 1
        address=address+1

    return address


###############################################################################
# _getMessage
#
# Decode the message at the passed address. Does NOT print it to the screen.
# Loop through each byte:
# - If a byte is > 0x5E then it's a common fragment (go decode)
# - If a byte is 0x01 then it's the end of the message
# - If a byte is 0x01 then it's the end of the messages area of memory
# 
#
# Parameters: 
#    data           - the game file byte array
#    msgAddress     - start address in the game file of the address
#
# Returns:
#   Decoded plain text message
###############################################################################
def _getMessage(data, msgAddress):

    message=''

    byte = data[msgAddress]
    while byte:
        if(byte >= 0x5E):
            fragmentNumber = byte - 0x5E
            fragmentAddr = _getAddrForFragment(data,fragmentNumber)

            newMessage = _getMessage(data, fragmentAddr)
            message = message + newMessage

        elif(byte == 0x02):
            # Used to denote end of some fragments?
            break
        elif(byte == 0x01):
            # End of fragment or string
            break
        else:
            message = message + str(chr(byte+0x1D))
            #_getCharacter(byte)

        msgAddress = msgAddress + 1
        byte = data[msgAddress]

    return message

###############################################################################
# _getAddrForMessageN
#
# Gets the address in the game file of the nth message. Each
# message is seperated by a 0x01.
# 
#
# Parameters: 
#    data           - the game file byte array
#    messageNumber  - nth message to find address of
#
# Returns:
#   Address of the nth message
###############################################################################
def _getAddrForMessageN(data, messageNumber):

    messagesAddress = messagesStartAddr
 
    # Keeping looping until the nth message is found
    while messageNumber:
        byte = data[messagesAddress]

        if(byte == 0):
            logging.error("ERROR couldn't find nth string")
            sys.exit(1)
        elif(byte == 1):
            messageNumber = messageNumber - 1
        
        messagesAddress = messagesAddress + 1
        
    return messagesAddress 

###############################################################################
# _find_v1_a_code_start()
#
# Loop through the v1 game configurations and look for the byte signature for
# each - stop on the first signature that matches and return the start address
# where the signature was found.
# 
# 
# Parameters: 
#    data           - the game file byte array
#
# Returns:
#   Start address of the A-Code and game indicator
###############################################################################
def _find_v1_a_code_start(data):
    game = 'unknown'
    startAddress = -1

    for gameKey in v1Configuration:
        signatureBytes = v1Configuration[gameKey]['signatureBytes']
        startAddress  = data.find(signatureBytes)
        if startAddress != -1:
            game = gameKey
            break
    
    return startAddress, game

# Set up the command line arguments so the game
# to analyse can be specified on a switch
parser = argparse.ArgumentParser()
parser.add_argument('-g','--game', type=str, choices= v1Configuration.keys(),required=True)
args = parser.parse_args()

game = args.game

filename = v1Configuration[game]['filename']

with open(filename,'rb') as dataFile:
    data = bytearray(dataFile.read())
    dataFile.close()

# Identify the game (do this anyway for preconfigured ones)
aCodeStartAddr, game = _find_v1_a_code_start(data)

# Derive the location of the major game parts based on offsets in the v1 configuration
dictionaryAddr       = aCodeStartAddr + v1Configuration[game]['offsets']['dictionaryOffset']
exitsAddr            = aCodeStartAddr + v1Configuration[game]['offsets']['exitsOffset'] 
messagesStartAddr    = aCodeStartAddr + v1Configuration[game]['offsets']['messagesOffset']
commonFragmentsAddr  = aCodeStartAddr + v1Configuration[game]['offsets']['fragmentsOffset']
locationsStartMsgId  =                  v1Configuration[game]['locationsStartMsgId']

match game:
    case "snowball":
        print("Snowball Adventure - Location Exit Definition")
        print("---------------------------------------------\n")
        print("Bit configuration:\n")
        print("Bit 0 - where the direction can be used inversely")
        print("Bit 1 - whether this direction should be hidden")
        print("Bit 2 - if there is a door in this direction")
        print("\n")
    case "lords":
        print("Lords of Time - Location Exit Definitions")
        print("-----------------------------------------\n")
        print("Bit configuration:\n")
        print("Bit 0 - where the direction can be used inversely")
        print("Bit 1 - whether this direction should be hidden")
        print("Bit 2 - if there is a door in this direction")
        print("\n")
    case "adventure":
        print("Adventure Quest- Location Exit Definitions")
        print("---------------------------------------------\n")
        print("Bit configuration:\n")
        print("Bit 0 - where the direction can be used inversely")
        print("Bit 1 - if player cannot move in that direction but print the location's description as a message")
        print("Bit 2 - not used, always set to 0x00 but printed here as 'No'")
        print("\n")
    case "dungeon":
        print("Dungeon Adventure - Location Exit Definitions")
        print("---------------------------------------------\n")
        print("Bit configuration:\n")
        print("Bit 0 - where the direction can be used inversely")
        print("Bit 1 - If set this a teleporation between a black and white dot and prints 'There is a sensation of rapid movement..'")
        print("Bit 2 - not used, always set to 0x00 but printed here as 'No'")
        print("\n")
    case "colossal":
        print("Colossal Adventure - Location Exit Definitions")
        print("----------------------------------------------\n")
        print("Bit configuration:\n")
        print("Bit 0 - where the direction can be used inversely")
        print("Bit 1 - if there is a 'door' in this direction between locations")
        print("Bit 2 - not used, always set to 0x00 but printed here as 'No'")
        print("\n")



print(f'                        (Inv.)')
print(f'Address From  To  Dir   Bit 0 Bit 1 Bit 2 MsgId Location Text')
print(f'------- ---- ---- ----- ----- ----- ----- ----- -------------')

fromLocation = 0
exitPointer = exitsAddr
hideNulls = False

# Print the right way first

while(data[exitPointer]):
    fromLocation = fromLocation + 1

    lastExit = False

    while(not lastExit):
        exitFlags      = data[exitPointer]
        targetLocation = data[exitPointer+1]

        exitDirection = exitFlags & 0xf
        exitAttrs     = (exitFlags & 0x70) >> 4

        # Bit 2 and Bit 1 vary on purpose by game (see decompilations)
        bit2 = "Yes" if exitAttrs & 0x04 else "No"
        bit1 = "Yes" if exitAttrs & 0x02 else "No"
        
        # Bit 0 always specifies if a direction can be used inversely
        # i.e. if you can go East from location 1 to location 2, if this is 
        # set then you can go West from location 2 to location 1
        reverseValid  = "Yes" if exitAttrs & 0x01 else "No"

        messageId = fromLocation + locationsStartMsgId

        address = _getAddrForMessageN(data, messageId)
        message = _getMessage(data, address)
        if(not (hideNulls and exitDirection == 0)):
            print(f'0x{exitPointer:04x}  0x{fromLocation:02x} 0x{targetLocation:02x} {directions[exitDirection]:<5}  {reverseValid:<5} {bit1:<5} {bit2:<5} 0x{messageId:03x} {message}')
        if(targetLocation == 0xfe):
            print('uh oh')
            sys.exit()

        # Check the 8th bit - if it's set it's the last exit
        # for this location
        if(exitFlags & 0x80):
            lastExit = True

        exitPointer += 2
