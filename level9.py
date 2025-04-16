###############################################################################
# Python Level 9 Interpreter for Version 1 Games
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
# This is actually the second iteration as the first looked quite similar to the
# assembly code when I was working out what it all did. 
#  
# Game files are written by Level 9 Computing (c) Copyright 1982, 1983
#
# Code and comments by Andy Barnes (c) Copyright 2022 (for now)
#
# Twitter @ajgbarnes
#
# This implementation uses the same function and list handler 
# names as the [Level 9 interpeter by Glenn Summers and others](https://github.com/DavidKinder/Level9/blob/master/level9.c) 
# for consistency and familiarity.  
#
# This was used a reference to functions only as I struggled understanding 
# the code - nearly all my understanding came from decompiling the BBC Micro's 
# game code.
###############################################################################
from fileinput import filename
import sys
import signal
import re
import time
import logging
import argparse

###############################################################################
# Load the version1 file configuration information
###############################################################################
from l9config import v1Configuration

###############################################################################
# This table is used by the vm_fn_exit command handler in its second scan
# of the exit data to see if it's possible to go from another location 
# to the current location using the inverse direction to the way the player wants 
# to move e.g. if the player is moving E from location 1 to 2, then is it possible
# to move W from location to 2 and 1 and can do the exit flags allow it to be 
# used for reverse location lookup.
#
# Note Lords of Time requires this to have 19 entries when OPEN DOOR is 
# used (bug in the A-Code?). So extending with four 0xff bytes
###############################################################################
inverseDirectionTable = [0x00, 0x04, 0x06, 0x07, 0x01, 0x08, 0x02, 0x03, 
    0x05, 0x0a, 0x09, 0x0c, 0x0b, 0xff, 0xff, 0x0f, 0xff, 0xff, 0xff, 0xff]

vm_variables_previous  = [0]*256
vm_variables           = [0]*256
vm_stack               = []
vm_listarea            = [0]*512
vm_listarea_previous   = [0]*512
vm_dictionary          = {}

charsWrittenToLine = 0

###############################################################################
# Default randomseed for game events - can be set at any time with
# #randomseed <value>
# either manually or from a script
###############################################################################
randomseed=int(time.time()) & 0xff

###############################################################################
# File that contains the automated script to execute (if any).
# Holds the file handle.
###############################################################################
scriptFile = None

##############################################################################
# Not used but a reference index of the commands that the A-Code supports
# (I used it for logging at some early point). Zero based index so goto = 0.
##############################################################################
opCodes=[
	"goto",
	"intgosub",
	"intreturn",
	"printnumber",
	"messagev",
	"messagec",
	"function",
	"input",
	"varcon",
	"varvar",
	"_add",
	"_sub",
	"ilins",
	"ilins",
	"jump",
	"exit",
	"ifeqvt",
	"ifnevt",
	"ifltvt",
	"ifgtvt",
	"nop",
	"nop",
	"nop",
	"nop",
	"ifeqct",
	"ifnect",
    "ifltct",
    "ifgtct",
	"printinput",
	"ilins",
	"ilins",
	"ilins",
]

###############################################################################
# isValidHex()
#
# Validates a string is in 0xNN format
#
# Parameters: 
#    string - holds the string to be validate as hex
#
        # Returns:
        #    True  - string is in 0xNN format
#    False - invalid format
###############################################################################
def isValidHex(string):
    return re.search("^0x[0-9a-fA-F]{2}$", string) is not None
    
###############################################################################
# signal_handler()
#
# Signal handler for SIGINT (when someone pressses CTRL+C)
# just exits cleanly without an error / stack trace
#
# Parameters: 
#    signum - the signal that was invoked
#    frame  - the frame object
#
# Returns:
#    n/a
###############################################################################
def signal_handler(signum, frame):
    sys.exit(0)


###############################################################################
# _process_hash_commands()
#
# If a player enters a # command, match it and process here. These are 
# not part of the original Level 9 game engine - just a few tools for 
# helping to understand what is going on.
#
# Supports:
# #vars          - lists all game variable values
# #var <number>  - displays a single game variable value
# #seed <number> - sets the random seed to the value - useful for 
#                  debugging when a game contains random events
# #setvar <number> <value> - Sets variable to the value. Can be decimal
#                  or hexadecimal values (0xNN)
# #setlist <number> <value> - Set item <number> to <value>. Can be decimal
#                  or hexadecimal values (0xNN)
# #list          - lists all the values in the listarea
# #dict          - print the dictionary for the game
# 
# 
#
# Parameters: 
#    data      - the game file byte array
#    pc        - the virtual machine program counter
#    userInput - the text string typed by the player
#    signum - the signal that was invoked
#    frame  - the frame object
#
# Returns:
#   n/a
###############################################################################
def _process_hash_commands(data, pc, userInput):
    global randomseed

    buffer=""

    strippedInput = userInput.strip().lower()

    # Give yourself all the items
    #for x in range(80,159):
    #    vm_listarea[x]=0xff

    match strippedInput.split():

        # Prints the dictionary
        case ['#dict' | '#dictionary']:
            for word in vm_dictionary.keys():
                print(word.replace("'", "") + " ", end='')
                if word == '9':
                    break
            print("")

        # Sets the random seed which can be used by the A-Code
        # for random game events
        case ["#seed", seed]:
            if(seed.isdigit()):
                randomseed = int(seed)
                print("Seed set to "+seed)
            if(isValidHex(seed)):
                randomseed = int(seed,16)
                print("Seed set to "+hex(seed))

        # Prints the value of just one variable
        case ['#var', variable]:
            if(variable.isdigit()):
                intvariable = int(variable)
                if(vm_variables[intvariable] == vm_variables_previous[intvariable]):
                    print(f"\033[0m{vm_variables[intvariable]:04x} (hex)")
                else:
                    print(f"\033[92m{vm_variables[intvariable]:04x}\033[0m (hex)")
            elif(isValidHex(variable)):                
                intvariable = int(variable,16)
                if(vm_variables[intvariable] == vm_variables_previous[intvariable]):
                    print(f"\033[0m{vm_variables[intvariable]:04x} (hex)")
                else:
                    print(f"\033[92m{vm_variables[intvariable]:04x}\033[0m (hex)")

        # Prints the value of ALL variables
        case ['#vars', *_]:
            print("        x0   x1   x2   x3   x4   x5   x6   x7   x8   x9   xa   xb   xc   xd   xe   xf")
            print("      ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ----")
            for idx, variable in enumerate(vm_variables):
                #buffer = "" + str(idx - idx % 10)
                if(idx > 0 and (idx % 16 == 0 or idx == len(vm_variables))):
                    startIdx = (idx - 16) - (idx % 16)
                    print(f"\033[0m{startIdx:03x}"+" |"+buffer)
                    buffer = ""
                if(vm_variables[idx] == vm_variables_previous[idx]):
                    buffer += f" \033[0m{variable:04x}"
                else:
                    buffer += f" \033[92m{variable:04x}"
            print("")

        # Set the value of a variable
        case ["#setvar", variable, value]:
            if(variable.isdigit() and value.isdigit()):
                vm_variables_previous[int(variable)]=vm_variables[int(variable)]
                vm_variables[int(variable)]=int(value)
                print('Variable '+variable+' changed to '+value)
            elif(isValidHex(variable) and isValidHex(value)):
                vm_variables_previous[int(variable,16)]=vm_variables[int(variable,16)]
                vm_variables[int(variable,16)]=int(value,16)
                print('Variable '+variable+' changed to '+value)

        # Set the value in the list area (all dynamic lists are stored there)
        case["#setlist", item, value]:
            if(item.isdigit() and value.isdigit()):
                vm_listarea[int(item)]=int(value)
                print(vm_listarea[int(item)])
                print('List area item '+item+' changed to '+value)
            elif(isValidHex(item) and isValidHex(value)):
                vm_listarea[int(item,16)]=int(value,16)
                print(hex(vm_listarea[int(item,16)]))
                print('List area item '+item+' changed to '+value)

        # Print all values in the dynamic list area
        case ['#list', *_]:
            print("      x0 x1 x2 x3 x4 x5 x6 x7 x8 x9 xa xb xc xd xe xf")
            print("      -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --")
            for idx, variable in enumerate(vm_listarea):
                if(idx > 0 and (idx % 16 == 0 or idx == len(vm_listarea))):
                    startIdx = (idx - 16) - (idx % 16)
                    print(f"\033[0m{startIdx:03x}"+" |"+buffer)
                    buffer = ""
                if(vm_listarea[idx] == vm_listarea_previous[idx]):
                    buffer += f" \033[0m{variable:02x}"
                else:
                    buffer += f" \033[92m{variable:02x}"
            print("")

        # Print all values in the dynamic list area
        case ['#message' | '#msg', number]:
            if(number.isdigit()):
                address = _getAddrForMessageN(data, int(number))
                _printMessage(data, address)
                print("")                
            elif(isValidHex(number)):
                address = _getAddrForMessageN(data, int(number, 16))
                _printMessage(data, address)                
                print("")

        case other:
            print('Invalid command')

###############################################################################
# _getSignedNumber
#
# Converts a twos complement value of a byte to a positive or negative
# integer.
#
# Parameters: 
#    byte      - value to convert
#
# Returns:
#   Integer in range of +127 to -127
###############################################################################
def _getSignedNumber(byte):
    if(byte>127):
        signedNumber=(256-byte) * -1
    else:
        signedNumber=byte
    return signedNumber

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
# _getAddrForMessageN
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
# _printMessage
#
# Calls the routine to decode the message at msgAddress and then prints
# the character to the screen with the following character rules:
# '%' - replace with a carriage return but only print it if more than 2
#       characters have been written to the line
# '_' - replace with a space
# 
# Anything else is just printed
# 
# Parameters: 
#    data           - the game file byte array
#    msgAddress     - start address in the game file of the message to print
#
# Returns:
#   n/a
###############################################################################
def _printMessage(data, msgAddress):

    global charsWrittenToLine

    message=_getMessage(data,msgAddress)

    for character in message:
        if(character == '%' and charsWrittenToLine>2):
            print('\n',end='')
            charsWrittenToLine = 0
        elif(character == '_'):
            print(' ',end='')
            charsWrittenToLine += 1
        elif(character != '%'):
            print(character,end='')
            charsWrittenToLine += 1

###############################################################################
# _printCharacter()
#
# Used when printing all the messages
# 
# 
# Parameters: 
#    byte           - byte to print
#
# Returns:
#   n/a
###############################################################################
def _printCharacter(byte):
    char = chr(byte+int("0x1D",16))
    if(char == "%"):
        print("\n")
    elif(char == "_"):
        print(" ")
    else:
        print(chr(byte+29),end='')
###############################################################################
# _findAndPrintLetters
#
# Recursive function for finding the nth common word fragment and printing
# it - if the nth common word fragment contains another common word fragment
# it wlil call itself to decode and print that
# 
# Parameters: 
#    iteratiions    - the nth common word fragment to find
#    bytearray      - data to loop over
#
# Returns:
#   n/a
###############################################################################
def _findAndPrintLetters(iterations, bytearray):

    startAddress=commonFragmentsAddr
    currentPos=startAddress
    loopsLeft=iterations - 0x5E

    while loopsLeft:
        if(bytearray[currentPos]==1):
            loopsLeft = loopsLeft-1
        currentPos=currentPos+1

    while(bytearray[currentPos]>2):
        if(bytearray[currentPos]>=94):
            _findAndPrintLetters(bytearray[currentPos], bytearray)
        else:
            _printCharacter(bytearray[currentPos])
        currentPos=currentPos+1

###############################################################################
# _printAllMessage
#
# Prints all the messages for the game
# 
# Anything else is just printed
# 
# Parameters: 
#    data           - the game file byte array
#    msgAddress     - start address in the game file of the message to print
#
# Returns:
#   n/a
###############################################################################
def _printAllMessages(data,messagesStartAddr):

    counter=0
    startAddress=messagesStartAddr
    address=startAddress

    print(hex(counter)," / ",hex(address)," : ",end='')

    byte = data[address]

    while(byte):
        if(byte>=0x5E):
            _findAndPrintLetters(byte, data)
            pass
        elif(byte < 0x5E and byte > 0x02):
            _printCharacter(byte)
        elif(byte == 2):
            break
        else:
            print("")
            counter=counter+1
            print(hex(counter)," / ",hex(address+1)," : ",end='')

        address=address+1
        byte = data[address]            

###############################################################################
# vm_fn_load_dictionary
#
# Finds the dictionary in the code starting at dictionaryAddr 
# and decodes the words.  Puts each word in a python dictionary
# with the word as the key and the command/object value as the value
#
# The last byte of the word has the 8th bit set - this byte is 
# followed by the command/object value.
# 
# Parameters: 
#    data           - the game file byte array
#    dictionaryddr  - start address in the game file of the dictionary
#
# Returns:
#   n/a
###############################################################################
def vm_fn_load_dictionary(data,dictionaryAddr,printDict):
    codeNext = False

    word=""

    address=dictionaryAddr

    byte = data[address]
    wordStart=address

    while byte:
        if codeNext:
            if(printDict):
                print(hex(byte), " / ",hex(wordStart),word)
            vm_dictionary[word]=byte
            codeNext=False
            word=""
        else:
            if byte>=127:
                codeNext=True
            word = word + chr(byte & 0x7F)

        address=address+1
        byte = data[address]
    

###############################################################################
# vm_fn_listhandler()
#
# Implements the four list handlers for processing the game lists. Up to
# 5 lists can be defined (technically 6 but the 0 position is never used
# by the v1 games). 
# 
# The list could be a reference (in the game code) or dynamic 
# (outside the game code) list. The list number to look up is 
# contained in the bottom 5 bits of the opCode.  
#
# 0xE0 - 0xE5
#      list#x[ variable[ <operand1> ]] = variable[ <operand2> 
# 0xC0 - 0xC5
#      variable[ <operand2> ] = list#x[ <operand1> ]
# 0xA0 - 0xA5
#      variable[ <operand2> ] = list#x[ variable[ <operand1> ]]
# 0x80 - 0x85
#      list#x[ <operand1> ] = variable[ <operand2> ]
# 
# Parameters: 
#    data           - the game file byte array
#    opCode         - list handler code
#    pc             - the program counter
#
# Returns:
#   Updated program counter
###############################################################################
def vm_fn_listhandler(data,opCode,pc):

    listNumber = opCode & 0b00011111
    
    if(opCode & 0b00011111 > 0x05):
        print(f'Version 1 games only supported 5 lists and this is accessing list {opCode & 0b00011111}')
        sys.exit()

    # Get the list offset - if it is negative then it is 
    # a reference (static) list in the game code, otherwise
    # it's a working dynamic list in vm_listarea
    listOffset = v1Configuration[game]['lists'][listNumber-1]

    if(opCode >= 0b11100000): # 0xE0
        # list#x[ variable[ <operand1> ]] = variable[ <operand2> ]
        pc=pc+1        
        variable1=data[pc]

        pc=pc+1        
        variable2=data[pc]

        if(listOffset < 0):
            print('Error: Update to reference list attempted ', hex(opCode), hex(pc))
            sys.exit()

        offset = listOffset + vm_variables[variable1]
        vm_listarea[offset] = vm_variables[variable2]
    elif(opCode >= 0b11000000): # 0xC0
        # variable[ <operand2> ] = list#x[ <operand1> ]

        pc=pc+1
        constant = data[pc]

        pc=pc+1
        variable = data[pc]

        if(listOffset < 0):
            print('Error: Update to reference list attempted ', hex(opCode), hex(pc))
            sys.exit()

        vm_variables[variable] = vm_listarea[listOffset+constant]

    elif(opCode >= 0b10100000): # 0xA0
        # variable[ <operand2> ] = list#x[ variable[ <operand1> ]]

        pc=pc+1
        variable1 = data[pc]

        pc=pc+1
        variable2 = data[pc]

        if(listOffset >= 0):
            vm_variables[variable2] = vm_listarea[listOffset+vm_variables[variable1]]
        else:
            listItemAddress=aCodeStartAddr+listOffset+vm_variables[variable1]
            vm_variables[variable2] = data[listItemAddress]
            
    else: # > 0b1000000 / 0x80
        # list#x[ <operand1> ] = variable[ <operand2> ]

        pc=pc+1
        variable1 = data[pc]

        pc=pc+1
        variable2 = data[pc]

        if(listOffset<0):
            print('Error: Update to reference list attempted ', hex(opCode), hex(pc))
            sys.exit()

        offset = listOffset + variable1
        vm_listarea[offset] = vm_variables[variable2]

    return pc

###############################################################################
# vm_fn_goto()
#
# Performs a relative or absolute goto
# 
# Parameters: 
#    data           - the game file byte array
#    opCode         - list handler code
#    pc             - the program counter
#
# Returns:
#   Updated program counter
###############################################################################
def vm_fn_goto(data, opCode, pc):

    # Get the first operand
    pc=pc+1
    operand1 = data[pc]
    operand2 = None

    # The 6th bit indicates if the command has one 
    # or two operands
    if (opCode & 0b00100000):
        # Single (it's set)
        offset=_getSignedNumber(operand1)
        pc=pc+offset-1
    else:
        # Double (it's not set)
        pc=pc+1    
        operand2=data[pc]
        offset=(256 * operand2) + operand1
        pc=aCodeStartAddr+offset-1

    return pc

###############################################################################
# vm_fn_intgosub()
#
# Places the current program counter on the stack (so it can be
# returned to) and performs a relative or absolute goto 
# 
# Parameters: 
#    data           - the game file byte array
#    opCode         - list handler code
#    pc             - the program counter
#
# Returns:
#   Updated program counter
###############################################################################
def vm_fn_intgosub(data, opCode, pc):
    # If the 6th bit is set then there's only one
    # operand for the offset so the return address is pc+1
    # otherwise there are two so it's pc+2
    if(opCode & 0b00100000):
        vm_stack.append(pc+1)
    else:
        vm_stack.append(pc+2)

    pc=vm_fn_goto(data,opCode,pc)

    return pc

###############################################################################
# vm_fn_intreturn()
#
# Returns to the A-Code location at the top of the stack 
# (sets the program counter)
# 
# Parameters: 
#    data           - the game file byte array
#    opCode         - list handler code
#    pc             - the program counter
#
# Returns:
#   Updated program counter
###############################################################################
def vm_fn_intreturn(data, opCode, pc):
    
    pc=vm_stack.pop()

    return pc

###############################################################################
# vm_fn_printnumber()
#
# Prints the number held in the variable1 to the screen
# 
# Parameters: 
#    data           - the game file byte array
#    opCode         - list handler code
#    pc             - the program counter
#
# Returns:
#   Updated program counter
###############################################################################
def vm_fn_printnumber(data, opCode, pc):

    # Get the first operand
    pc=pc+1
    variable1 = data[pc]
    
    print(str(vm_variables[variable1]),end='')

    return pc    

###############################################################################
# vm_fn_messagev()
#
# Prints the message with the id held in variable indicated by operand1
# 
# Parameters: 
#    data           - the game file byte array
#    opCode         - list handler code
#    pc             - the program counter
#
# Returns:
#   Updated program counter
###############################################################################
def vm_fn_messagev(data, opCode, pc):

    # Get the first operand
    pc=pc+1
    operand1 = data[pc]

    nthMessage = vm_variables[operand1]
    address = _getAddrForMessageN(data, nthMessage)
    _printMessage(data, address)

    return pc

###############################################################################
# vm_fn_messagec()
#
# Prints the message with the id held in operands 1 and 2
# 
# Parameters: 
#    data           - the game file byte array
#    opCode         - list handler code
#    pc             - the program counter
#
# Returns:
#   Updated program counter
###############################################################################
def vm_fn_messagec(data, opCode, pc):

    # Get the first operand
    pc=pc+1
    operand1 = data[pc]
    operand2 = None
    nthMessage = 0;

    # If the 7th bit is set in the opCode
    # then there is only one operand, otherwise
    # there are two
    if (opCode & 0b01000000):
        nthMessage = operand1  
    else:
        pc=pc+1
        operand2=data[pc]
        nthMessage = (operand2 * 256 ) + operand1
    
    address = _getAddrForMessageN(data, nthMessage)
    _printMessage(data, address)

    return pc

###############################################################################
# vm_fn_function()
#
# Performs one of the following functions based on the operand:
# 1 - exit
# 2 - generate new random seed
# 3 - save game
# 4 - load game
# 5 - Reset all the variables to zero
# 6 - Clear the stack
# 
# Parameters: 
#    data           - the game file byte array
#    opCode         - list handler code
#    pc             - the program counter
#
# Returns:
#   Updated program counter
###############################################################################
def vm_fn_function(data,opCode,pc):
    global randomseed
    pc=pc+1
    requiredFunction = data[pc]
    match requiredFunction:
        case 1:
            sys.exit(0)
        case 2:
            pc=pc+1
            variableToSet=data[pc]

            randomseed=(((((randomseed<<8) + 0x0a - randomseed) <<2) + randomseed) + 1) & 0xffff
            vm_variables[variableToSet]=randomseed & 0xff            
        case 3:
            with open(game+".sav", "wb") as save_file:
                for var in (vm_variables):
                    save_file.write(var.to_bytes(2,'big'))
                for li in (vm_listarea):
                    save_file.write(li.to_bytes(1,'big'))   
        case 4:
            with open(game+".sav", "rb") as load_file:
                for i in range(0, len(vm_variables)):
                    bytes=load_file.read(2)
                    print(i)
                    vm_variables[i] = int.from_bytes(bytes, 'big')
                for i in range(0, len(vm_listarea)-1):
                    bytes=load_file.read(1)
                    vm_listarea[i] = int.from_bytes(bytes, 'big')
        case 5: 
            # Reset all the variables to zero
            for i in range(0,len(vm_variables)):
                vm_variables[i]=0
        case 6:
            # Clear the stack
            vm_stack.clear()
        case other:
            print(f'Unknown function {requiredFunction:02x}')
            sys.exit()

    return pc

###############################################################################
# vm_fn_input()
#
# Wait for player input and parse the result by looking up each word in the
# dictionary and finding the command/object id with the match (or ignoring)
# a word if it doesn't match.
#
# The ids are placed in the variables identified by the first three operands
# and the word count in the fourth.  
#
# Note that if it's prefixed with a hash then it'll be passed to the hash
# command handler - these are extensions I put in for debugging / understanding
# 
# Parameters: 
#    data           - the game file byte array
#    opCode         - list handler code
#    pc             - the program counter
#
# Returns:
#   Updated program counter
###############################################################################
def vm_fn_input(data,opCode,pc):
    global vm_variables_previous
    global vm_listarea_previous

    # <command> <byte1> <byte2> <byte3> <byte4>
    # <byte1> where to store the first cmd/obj
    # <byte2> where to store the second cmd/obj
    # <byte3> where to store the third cmd/obj
    # <byte4> where to store the word count
    pc=pc+1
    firstWordVar=data[pc]
    
    pc=pc+1
    secondWordVar=data[pc]

    pc=pc+1
    thirdWordVar=data[pc]    

    pc=pc+1
    wordCountVar=data[pc]

    wordCount=0

    while(True):
        userInput = ''
        hashCommand = False	    
          
        if(scriptFile):
            #time.sleep(1)
            while(True):
                userInput = scriptFile.readline()
                if(userInput == ""):
                    userInput = input().upper()
                    break
                userInput = userInput.replace("*","")                
                userInput = userInput.split('[')[0]
                userInput = userInput.split(';')[0]
                userInput = userInput.rstrip()
                if(userInput != ''):
                    break
            print(userInput)
            #time.sleep(0.8)
            userInput=userInput.upper()
        else:
            # Get user input
            userInput = input().upper()

        if(len(userInput) > 0 and userInput[0] =="#"):
            _process_hash_commands(data, pc, userInput)
            hashCommand = True
        else:
            vm_variables_previous = vm_variables.copy()

	# Restrict to the first 39 characters only
        if(len(userInput) > 39):
            userInput=userInput[0:39]

        words=list(filter(None,userInput.split(' ')))

        vm_variables[firstWordVar]  = 0x00
        vm_variables[secondWordVar] = 0x00
        vm_variables[thirdWordVar]  = 0x00
        vm_variables[wordCountVar]  = len(words)

        wordVarPointer = 0x00
	    
        for word in words:
            code = None
            for dictWord in vm_dictionary.keys():
                if(dictWord.startswith(word)):
                    code = vm_dictionary[dictWord]
                    break
            
            if(code is not None):
                match wordVarPointer:
                    case 0:
                        vm_variables[firstWordVar]=code
                    case 1:
                        vm_variables[secondWordVar]=code
                    case 2:
                        vm_variables[thirdWordVar]=code
                    case other:
                        break

                wordVarPointer=wordVarPointer+1

        if(vm_variables[wordCountVar]>0 and not hashCommand):
            vm_listarea_previous  = vm_listarea.copy()
            break

    return pc

###############################################################################
# vm_fn_varcon()
#
# Set the variable value to a constant (either 8 or 16-bit)
#
# Variable[operand2] = operand1 or
# Variable[operand3] = operand2 * 256 + operand1
# 
# Parameters: 
#    data           - the game file byte array
#    opCode         - list handler code
#    pc             - the program counter
#
# Returns:
#   Updated program counter
###############################################################################
def vm_fn_varcon(data,opCode,pc):

    constant = 0
    variable = 0

    pc=pc+1
    operand1 = data[pc]

    pc=pc+1
    operand2 = data[pc]

    # Bit 7 indicates if there are one or two operands for the constant
    # that the variable will be set to
    if (opCode & 0b01000000):
        # Bit 7 is set so there will be only one operand for the constant
        constant=operand1
        variable=operand2
    else:
        # Bit 7 is NOT set so there will be two operands for the constant used
        # in the comparison
        constant=operand1 + (256 * operand2)

        pc=pc+1
        variable=data[pc]

    # Set the variable value to the constant 
    vm_variables[variable] = constant

    return pc

###############################################################################
# vm_fn_varvar()
#
# Set the variable2's value to variable1's value
#
# Variable[operand2] = variable[operand1]
# 
# Parameters: 
#    data           - the game file byte array
#    opCode         - list handler code
#    pc             - the program counter
#
# Returns:
#   Updated program counter
###############################################################################
def vm_fn_varvar(data,opCode,pc):

    pc=pc+1
    sourceVar = data[pc]

    pc=pc+1
    targetVar = data[pc]

    vm_variables[targetVar] = vm_variables[sourceVar]

    return pc

###############################################################################
# vm_fn_add()
#
# Set the variable2's value to variable1's value plus variable2's value
#
# Variable[operand2] = variable[operand1] + variable[operand2]
# 
# Parameters: 
#    data           - the game file byte array
#    opCode         - list handler code
#    pc             - the program counter
#
# Returns:
#   Updated program counter
###############################################################################
def vm_fn_add(data, opCode, pc):
    
    pc=pc+1
    firstVar = data[pc]

    pc=pc+1
    secondVar = data[pc]

    vm_variables[secondVar] = vm_variables[firstVar] + vm_variables[secondVar]

    return pc   

###############################################################################
# vm_fn_sub()
#
# Set the variable2's value to variable2's value minus variable1's value
#
# Variable[operand2] = variable[operand1] + variable[operand2]
# 
# Parameters: 
#    data           - the game file byte array
#    opCode         - list handler code
#    pc             - the program counter
#
# Returns:
#   Updated program counter
###############################################################################
def vm_fn_sub(data, opCode, pc):
    pc=pc+1
    firstVar = data[pc]

    pc=pc+1
    secondVar = data[pc]

    vm_variables[secondVar] = vm_variables[secondVar] - vm_variables[firstVar]

    return pc

###############################################################################
# _find_next_location()
#
# Find the start address of the exists for the nth location. The first byte of the
# last exit byte pair for a location will have the 8th-bit set. The next byte pair
# is the exit data for the next location.
# 
# Parameters: 
#    exitPointer    - points to the start of the exits data
#    data           - the game file byte array
#    location       - nth location to find 
#
# Returns:
#   Updated exitPointer, pointing to the start of the exits for the nth location
###############################################################################
def _find_next_location(exitPointer, data, location):

    fromLocation = location - 1

    # Keep looping until we are at the start of the exits for the nth
    # location
    while(fromLocation):
        byte=0
        # Loop until the last exit for the nth location is found 
        # (it will have bit 8 set)
        while(not byte & 0b10000000):
            byte = data[exitPointer]
            exitPointer += 2

        # Found the last exit for the location so about to start
        # the n+1th location
        fromLocation -= 1    

    # Return the address of the start of the exits for the nth location
    return exitPointer    

###############################################################################
# vm_fn_jump()
#
# Look up the location in the A-Code to jump to in the jump table. The
# jump table's location in the A-Code is given by operand1 and operand2. 
# This is added to the start address offset for the A-Code.  The nth entry 
# is then looked up which is located at 2 x n (each address is 2 bytes).  N
# is in operand3.
# 
# Parameters: 
#    data           - the game file byte array
#    opCode         - list handler code
#    pc             - the program counter
#
# Returns:
#   Updated program counter
###############################################################################
def vm_fn_jump(data, opCode, pc):

    pc=pc+1
    constant1 = data[pc]

    pc=pc+1
    constant2 = data[pc]

    pc=pc+1
    offsetVar = data[pc]

    aCodeOffset     = (constant2 * 256) + constant1
    tableOffset   = vm_variables[offsetVar] * 2
    jumpTableAddress = aCodeStartAddr + aCodeOffset + tableOffset

    #print(hex(aCodeOffset), hex(offsetVar), hex(vm_variables[offsetVar]), hex(data[jumpTableAddress] + (data[jumpTableAddress+1] * 256)))

    pc = aCodeStartAddr + data[jumpTableAddress] + (data[jumpTableAddress+1] * 256) - 1

    return pc    

###############################################################################
# vm_fn_exit()
#
# Determine if the player can move from their current location (operand1)
# in a certain direction (operand2) and put the exit flags in operand3
# and the target location in operand4 if they can.
#
# First tries to see if it's possible to use one of the exits defined 
# for the from location - "is there an exit definition from location X
# that allows me to move in direction Y"
#
# If not, it will do inverse direciton lookup - e.g. get the opposite of
# North i.e. South and try "is there an exit TO location X from any other location 
# in the inverse direction to Y (and can I use this exit for reverse lookup)"
# 
# Parameters: 
#    data           - the game file byte array
#    opCode         - list handler code
#    pc             - the program counter
#
# Returns:
#   Updated program counter
###############################################################################
def vm_fn_exit(data, opCode, pc):

    exitPointer = exitsAddr
    exitFound   = False

    pc=pc+1
    currentLocationVar = data[pc]
    fromLocation = vm_variables[currentLocationVar]

    pc=pc+1
    moveDirectionVar = data[pc]
    moveDirection = vm_variables[moveDirectionVar]    

    pc=pc+1
    exitFlagsVar = data[pc]
    vm_variables[exitFlagsVar] = 0x00

    pc=pc+1
    targetLocationVar = data[pc]
    vm_variables[targetLocationVar] = 0x00

    # Point the exit pointer at the start of the nth location's exits
    if(fromLocation - 1 > 0):
        exitPointer=_find_next_location(exitPointer, data, fromLocation)

    # Loop through the nth location's exits to see if it's possible
    # to move in the player's chosen movement direction - if it is set the
    # 
    while(data[exitPointer]):
        if(moveDirection == data[exitPointer] & 0b00001111):
            vm_variables[exitFlagsVar]      = (data[exitPointer] & 0b01110000) >> 4 
            vm_variables[targetLocationVar] = data[exitPointer+1]
            break

        if(data[exitPointer] & 0b10000000):
            break

        exitPointer += 2

    # If an exit hasn't been found and say the player was trying to
    # go East from location 12, check to see if it's possible 
    # to go (the inverse) West from any location and end up in location 12
    if(vm_variables[targetLocationVar] == 0x00):
        exitPointer = exitsAddr
        locationNumber = 1
        
        # Get the inverse direction e.g. for N it's S, for E it's W
        inverseMoveDirection = inverseDirectionTable[moveDirection]

        # Loop through ALL the exits to see if it's possible to go
        # the inverse direction to the player's current location
        while(data[exitPointer]):

            # Can this exit be used for reverse lookup? Bit 5 must be set to 1
            if(data[exitPointer] & 0b00010000):

                # Does the inverse direction match the exit direction
                if(inverseMoveDirection == (data[exitPointer] & 0b00001111)):

                    # Is the player's current location the where the inverse
                    # direction would take you
                    if(fromLocation == data[exitPointer+1]):

                        # Set the exit flags and the location that they will move to
                        vm_variables[exitFlagsVar]      = (data[exitPointer] & 0b01110000) >> 4 
                        vm_variables[targetLocationVar] = locationNumber
                        break
            
            # Is this the last exit for the location?  If so bit 8 
            # will be set so increment the location number
            if(data[exitPointer] & 0b10000000):
                locationNumber += 1

            # Move to the next exit
            exitPointer += 2

    return pc

###############################################################################
# vm_fn_ifxxvt()
#
# Comparison handler for all variable value to variable value checks. The 
# comparator operation is passed in as a parameter.  If the test is true
# then goto will be called either with a relative (one operand) or absolute goto 
# (two operands)
# 
# Parameters: 
#    data           - the game file byte array
#    opCode         - list handler code
#    pc             - the program counter
#
# Returns:
#   Updated program counter
###############################################################################
def vm_fn_ifxxvt(data,opCode,pc,operation):
    offset=0

    pc=pc+1
    variable1=data[pc]

    pc=pc+1
    variable2=data[pc]    

    pc=pc+1
    operand3=data[pc]

    # Bit 6 indicates if there are one or two operands for the goto offset
    if(opCode & 0b00100000):
        # Bit 6 is set so there will be one operand for the offset
        # and it will be relative to the current program counter (and signed)
        # i.e. can go forwards or backwards        
        operand4=None

        offset = _getSignedNumber(operand3)
        targetAddress = pc + offset -1 
    else:
        # If bit 6 is NOT set then there will be two operands and it will be 
        # relative to the start of the A-code 
        pc=pc+1
        operand4=data[pc]
        offset=(256 * operand4) + operand3

        targetAddress=aCodeStartAddr+offset-1

    if(eval("vm_variables[variable1] "+operation+" vm_variables[variable2]")):
        pc = targetAddress

    return pc    

###############################################################################
# vm_fn_ifxxct()
#
# Comparison handler for all variable value against constant checks. The 
# comparator operation is passed in as a parameter.  If the test is true
# then goto will be called either with a relative (one operand) or absolute goto 
# (two operands)
# 
# Parameters: 
#    data           - the game file byte array
#    opCode         - list handler code
#    pc             - the program counter
#
# Returns:
#   Updated program counter
###############################################################################
def vm_fn_ifxxct(data,opCode,pc,operation):

    pc=pc+1
    variable=data[pc]

    # Bit 7 indicates if there are one or two operands for the constant
    # used in the comparison
    if (opCode & 0b01000000):
        # Bit 7 is set so there will be only one operand for the constant used
        # in the comparison
        pc=pc+1
        constant = data[pc]
    else: 
        # Bit 7 is NOT set so there will be two operands for the constant used
        # in the comparison
        pc=pc+1
        constantLower  = data[pc]

        pc=pc+1
        constantHigher = data[pc]

        constant = 256 * constantHigher + constantLower

    # Bit 6 indicates if there are one or two operands for the goto offset
    if (opCode & 0b00100000):
        # Bit 6 is set so there will be one operand for the offset
        # and it will be relative to the current program counter (and signed)
        # i.e. can go forwards or backwards              
        pc=pc+1
        offset = _getSignedNumber(data[pc])
        targetAddress = pc + offset - 1
    else: 
        pc=pc+1
        offsetLower  = data[pc]

        pc=pc+1
        offsetHigher = data[pc]

        targetAddress = (256 * offsetHigher + offsetLower) + aCodeStartAddr - 1

    if(eval("vm_variables[variable] "+operation+" constant")):
        pc = targetAddress

    return pc

###############################################################################
# vm_fn_ifeqvt()
#
# Comparison handler entry point for if variable1's value equals variable2's value
# If the test is true then goto will be called either with a relative (one operand) 
# or absolute goto (two operands)
# 
# Parameters: 
#    data           - the game file byte array
#    opCode         - list handler code
#    pc             - the program counter
#
# Returns:
#   Updated program counter
###############################################################################
def vm_fn_ifeqvt(data,opCode,pc):
    return vm_fn_ifxxvt(data,opCode,pc,"==")

###############################################################################
# vm_fn_ifnevt()
#
# Comparison handler entry point for if variable1's value does not equal variable2's value
# If the test is true then goto will be called either with a relative (one operand) 
# or absolute goto (two operands)
# 
# Parameters: 
#    data           - the game file byte array
#    opCode         - list handler code
#    pc             - the program counter
#
# Returns:
#   Updated program counter
###############################################################################
def vm_fn_ifnevt(data,opCode,pc):   
    return vm_fn_ifxxvt(data,opCode,pc,"!=")

###############################################################################
# vm_fn_ifltvt()
#
# Comparison handler entry point for if variable1's value is less than variable2's value
# If the test is true then goto will be called either with a relative (one operand) 
# or absolute goto (two operands)
# 
# Parameters: 
#    data           - the game file byte array
#    opCode         - list handler code
#    pc             - the program counter
#
# Returns:
#   Updated program counter
###############################################################################
def vm_fn_ifltvt(data,opCode,pc):
    return vm_fn_ifxxvt(data,opCode,pc,"<")

###############################################################################
# vm_fn_ifgtvt()
#
# Comparison handler entry point for if variable1's value is greater than variable2's value
# If the test is true then goto will be called either with a relative (one operand) 
# or absolute goto (two operands)
# 
# Parameters: 
#    data           - the game file byte array
#    opCode         - list handler code
#    pc             - the program counter
#
# Returns:
#   Updated program counter
###############################################################################
def vm_fn_ifgtvt(data,opCode,pc):
    return vm_fn_ifxxvt(data,opCode,pc,">")

###############################################################################
# vm_fn_ifeqct()
#
# Comparison handler entry point for if variable1's value equals a constant
# If the test is true then goto will be called either with a relative (one operand) 
# or absolute goto (two operands)
# 
# Parameters: 
#    data           - the game file byte array
#    opCode         - list handler code
#    pc             - the program \
#
# Returns:
#   Updated program counter
###############################################################################
def vm_fn_ifeqct(data,opCode,pc):
    return vm_fn_ifxxct(data,opCode,pc,"==")

###############################################################################
# vm_fn_ifnect()
#
# Comparison handler entry point for if variable1's value does not equal a constant
# If the test is true then goto will be called either with a relative (one operand) 
# or absolute goto (two operands)
# 
# Parameters: 
#    data           - the game file byte array
#    opCode         - list handler code
#    pc             - the program counter
#
# Returns:
#   Updated program counter
###############################################################################
def vm_fn_ifnect(data,opCode,pc):
    return vm_fn_ifxxct(data,opCode,pc,"!=")

###############################################################################
# vm_fn_ifltct()
#
# Comparison handler entry point for if variable1's value is less than a constant
# If the test is true then goto will be called either with a relative (one operand) 
# or absolute goto (two operands)
# 
# Parameters: 
#    data           - the game file byte array
#    opCode         - list handler code
#    pc             - the program counter
#
# Returns:
#   Updated program counter
###############################################################################
def vm_fn_ifltct(data,opCode,pc):
    return vm_fn_ifxxct(data,opCode,pc,"<")

###############################################################################
# vm_fn_ifgtct()
#
# Comparison handler entry point for if variable1's value is greater than a constant
# If the test is true then goto will be called either with a relative (one operand) 
# or absolute goto (two operands)
# 
# Parameters: 
#    data           - the game file byte array
#    opCode         - list handler code
#    pc             - the program counter
#
# Returns:
#   Updated program counter
###############################################################################
def vm_fn_ifgtct(data,opCode,pc):
    return vm_fn_ifxxct(data,opCode,pc,">")

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


############################################################
# MAIN HERE
############################################################
cmds = set()

# Handle CTRL+C gracefully
signal.signal(signal.SIGINT, signal_handler)

# Set up the command line argument parser
parser = argparse.ArgumentParser()

# Switch to print the dictionary or messages
parserGroup1 = parser.add_mutually_exclusive_group(required=False)
parserGroup1.add_argument('-d', '--dictionary',required=False, action='store_true')
parserGroup1.add_argument('-m', '--messages',required=False, action='store_true')

# Set up the first parser group - either a file or game name
parserGroup2 = parser.add_mutually_exclusive_group(required=True)
parserGroup2.add_argument('-g', '--game', type=str, choices=v1Configuration.keys())
parserGroup2.add_argument('-f', '--file', type=str)

# Set up the second parser group - either a script file or the default one (auto)
parserGroup3 = parser.add_mutually_exclusive_group(required=False)
parserGroup3.add_argument('-s', '--script', type=str, required=False)
parserGroup3.add_argument('-a', '--autoGame', required=False, action='store_true')

# Not used so much any more but was during development of this
parser.add_argument('--logging', type=str, choices=['info','debug'],required=False)

# Parse the arguments
args = parser.parse_args()  

# Check to see what logging level is required
if(args.logging and args.logging == 'debug'):
    debugLevel=logging.DEBUG
else:
    debugLevel=logging.INFO
    
logging.basicConfig(filename='parser.log', encoding='utf-8', level=debugLevel)

# Check to see if they specified a game or a file
if(args.game):
    filename = v1Configuration[args.game]['filename']
else:
    filename = args.file

# Load the game file
with open(filename,'rb') as dataFile:
    data = bytearray(dataFile.read())
    dataFile.close()

# Identify the game (do this anyway for preconfigured ones)
aCodeStartAddr, game = _find_v1_a_code_start(data)

# If it couldn't be identified then quit
if(aCodeStartAddr < 0):
    print('Unable to identify the Level 9 Version 1 game in ' + filename)
    sys.exit()

# If a script file was specified, open it
if(args.script):
    scriptFile = open(args.script,'r')

# If autoGame was specified, use the default script file
if(args.autoGame):
    scriptFile = open(v1Configuration[game]['script'],'r')    

# Derive the location of the major game partsffunction based on offsets in the v1 configuration
dictionaryAddr       = aCodeStartAddr + v1Configuration[game]['offsets']['dictionaryOffset']
exitsAddr            = aCodeStartAddr + v1Configuration[game]['offsets']['exitsOffset'] 
messagesStartAddr    = aCodeStartAddr + v1Configuration[game]['offsets']['messagesOffset']
commonFragmentsAddr  = aCodeStartAddr + v1Configuration[game]['offsets']['fragmentsOffset']

# print(hex(dictionaryAddr))
# print(hex(exitsAddr))
# print(hex(messagesStartAddr))
# print(hex(commonFragmentsAddr))

# Set the program counter to the start of the A-Code
pc = aCodeStartAddr
maxpc = pc

# Load and decode the dictionary 
vm_fn_load_dictionary(data,dictionaryAddr, args.dictionary)
if(args.dictionary):
    sys.exit()

if(args.messages):
    _printAllMessages(data, messagesStartAddr)
    sys.exit()


# Main virtual machine loop - find the next operator in the A-Code and
# despatch it to a command or the list handler
while(True):

    # Get the next instruction / opCode
    opCode = data[pc]
    opCodeClean = opCode & 0x1F

    if(opCode & 0x80):
        cmds.add(opCode)
        pc = vm_fn_listhandler(data,opCode,pc)        
    else:
        cmds.add(opCodeClean)
        match opCodeClean:
            case 0x00:
                pc = vm_fn_goto(data, opCode, pc)
            case 0x01:
                pc = vm_fn_intgosub(data, opCode, pc)
            case 0x02:
                pc = vm_fn_intreturn(data, opCode, pc)
            case 0x03:
                pc = vm_fn_printnumber(data, opCode, pc)
            case 0x04:
                pc = vm_fn_messagev(data, opCode, pc)
            case 0x05:
                pc = vm_fn_messagec(data, opCode, pc)
            case 0x06:
                pc = vm_fn_function(data, opCode, pc)
            case 0x07:
                pc = vm_fn_input(data, opCode, pc)
            case 0x08:
                pc = vm_fn_varcon(data, opCode, pc)
            case 0x09:
                pc = vm_fn_varvar(data, opCode, pc)
            case 0x0a:
                pc = vm_fn_add(data, opCode, pc)
            case 0x0b:
                pc = vm_fn_sub(data, opCode, pc)
            case 0x0e:
                pc = vm_fn_jump(data, opCode, pc)
            case 0x0f:                
                pc = vm_fn_exit(data, opCode, pc)
            case 0x10:                
                pc = vm_fn_ifeqvt(data, opCode, pc)
            case 0x11:
                pc = vm_fn_ifnevt(data, opCode, pc)
            case 0x12:
                pc = vm_fn_ifltvt(data, opCode, pc)
            case 0x13:
                pc = vm_fn_ifgtvt(data, opCode, pc)
            case 0x18:
                pc = vm_fn_ifeqct(data, opCode, pc)
            case 0x19:
                pc = vm_fn_ifnect(data, opCode, pc)                
            case 0x1a:
                pc = vm_fn_ifltct(data, opCode, pc)                                
            case 0x1b:
                pc = vm_fn_ifgtct(data, opCode, pc)                                                
            case other:
                print(f'Illegal opCode {opCodeClean:02x} at {pc:04x}')
                break

    pc=pc+1

