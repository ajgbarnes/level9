from ast import Pass
from fileinput import filename
import os
import sys
import re
import time
import logging
import argparse
import json

###############################################################################
# Load the version1 file configuration information
###############################################################################
from l9config import v1Configuration


vm_variables  = [0]*256
vm_stack      = []
vm_listarea   = [0]*512
vm_dictionary = {}

jumpTables = []
gotoTable = []

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

def _print_code(opCode,cmdAddress, msg):
    if(opCode > 0x80):
        print(f"{cmdAddress-aCodeStartAddr:#0{6}x} ({cmdAddress:#0{6}x}): ({opCode:#0{4}x}) "+msg)
    else: 
        print(f"{cmdAddress-aCodeStartAddr:#0{6}x} ({cmdAddress:#0{6}x}): ({opCode&0x1f:#0{4}x}) "+msg)

def _getSignedNumber(byte):
    if(byte>127):
        signedNumber=(256-byte) * -1
    else:
        signedNumber=byte
    return signedNumber

def _getAddrForFragment(data, fragmentNumber):

    address=commonFragmentsAddr

    if mversion == 1:
        while fragmentNumber:
            if(data[address]==1):
                fragmentNumber = fragmentNumber - 1
            address=address+1
    elif mversion == 2:
        # The common fragments address is one out for some reason!
        # BBC Micro code subtracts 1 from it too
        address = address - 1
        while fragmentNumber:
            messageLength = data[address]
            address= address + messageLength
            #print(hex(fragmentNumber),hex(data[address]), hex(address))
            fragmentNumber = fragmentNumber - 1
        #print(hex(fragmentNumber),hex(data[address]), hex(address))

    return address

def _getAddrForMessageN(data, messageNumber):

    messagesAddress = messagesStartAddr

    if mversion == 1:
        # Keeping looping until the nth message is found
        while messageNumber:
            byte = data[messagesAddress]

            if(byte == 0 or byte == 2):
                print("Error: Didn't find nth string")
                break
            elif(byte == 1):
                messageNumber = messageNumber - 1
        
            messagesAddress = messagesAddress + 1
    elif mversion == 2:
        # Subtract 1 from the message number as they are zero
        # based indexed in the game file
        messageNumber = messageNumber - 1
        while messageNumber:
            #print(hex(messagesAddress), hex(data[messagesAddress]))
            messageLength = data[messagesAddress]
            while not data[messagesAddress]:
                messagesAddress = messagesAddress + 1
                messageLength = messageLength + 255 + data[messagesAddress]

            if messagesAddress >= commonFragmentsAddr:
                print("Error: Didn't find nth string")
                break

            messagesAddress = messagesAddress + messageLength

            messageNumber = messageNumber - 1
        #print(hex(messagesAddress), hex(data[messagesAddress]))
        #print("with eoo", hex(messagesAddress + 0xe00))
        
    return messagesAddress 

def _getMessage(data, msgAddress):

    message=''

    if mversion == 1:
        byte = data[msgAddress]
        while byte:
            if(byte >= int("5E",16)):
                fragmentNumber = byte - int("5E",16)
                fragmentAddr = _getAddrForFragment(data,fragmentNumber)
                newMessage = _getMessage(data, fragmentAddr)
                message = message + newMessage

            elif(byte == int("2",16)):
                # Used to denote end of some fragments?
                break
            elif(byte == int("1",16)):
                # End of fragment or string
                break
            else:
                message = message + str(chr(byte+0x1D))
                #_getCharacter(byte)

            msgAddress = msgAddress + 1
            byte = data[msgAddress]
    elif mversion == 2:
        # BBC Micro only allows 1 byte length for strings
        # in v2 at least for return to eden
        # Other platforms allow multiple 255 extensions
        msgLength = data[msgAddress]
        while not data[msgAddress]:
            msgAddress = msgAddress + 1
            msgLength = msgLength + 255 + data[msgAddress]

        msgLength = msgLength - 1

        msgAddress = msgAddress + 1

        while msgLength:
            byte = data[msgAddress]
            if(byte >= 0x5E):
                fragmentNumber = byte - 0x5E
                fragmentAddr = _getAddrForFragment(data,fragmentNumber)

                newMessage = _getMessage(data, fragmentAddr)
                message = message + newMessage
                pass

            elif(byte < 0x03):
                # End of fragment or string
                break
            else:
                message = message + str(chr(byte+0x1D))

            msgAddress = msgAddress + 1
            msgLength = msgLength - 1
    elif mversion >= 3:
        message = '<Not Implemented>\\n'

    return message

def _printMessage(data, msgAddress):

    message=_getMessage(data,msgAddress)
    message=message.replace("_"," ")
    messageLength = len(message)

    words=message.split()
    for word in words:

        if(word.find('%') >= 0):
            if(messageLength>-1):
                word = word.replace('%','\\n')
            else:
                word = word.replace('%','')
            pass
        
        print(word,end='')
        if(word[-2:]!='\\n'):
            print(' ',end='')


# STIL NEEDED?
def _getCharacter(byte,byteCount):
    char = chr(byte+0x1D)
    if(char == "%"):
        print("\n",end='')
    elif(char == "_"):
        print(" ",end='')
    else:
        print(char,end='')   

def vm_fn_load_dictionary(data):
    codeNext = False

    word=""

    if version >= 3:
        return

    address=dictionaryAddr

    byte = data[address]
        
    # Dictionary consists of n bytes of a word
    # followed by a that last character with the 8th bit set
    # 
    # # It's then followed by a code that indicates the object
    # or command

    count = 1

    while byte:
        if codeNext:
            if word in vm_dictionary.keys():
                if vm_dictionary[word] != byte:
                    word=word+'('+hex(byte)+')'
            vm_dictionary[word]=byte
            codeNext=False
            word=""
            wordStart=address+1
            count=count+1
        else:
            if byte>=127:
                codeNext=True
            c = chr(byte & 0x7F)
            if c in ['?','-','\\','/','!','.',','] or c.isalnum():
                word = word + c
            else:
                break

        address=address+1
        byte = data[address]

def vm_listhandler(data,opCode,pc):

    cmdAddress =pc
    listNumber = opCode & 0b00011111
    
    if(version == 1 and listNumber > 5):
        print(f'Error: Version 1 games only supported 5 lists and this is accessing list {opCode & 0b00011111}')
    elif(version == 2 and listNumber > 10):
        print(f'Error: Version 2 games only supported 9 lists and this is accessing list {opCode & 0b00011111}')
    elif(version >= 3 and listNumber > 10):
        print(f'Error: Version 3-4 games only supported 10 lists (0-9) and this is accessing list {opCode & 0b00011111}')

    if(version == 1):
        # Get the list offset - if it is negative then it is
        # a reference (static) list in the game code, otherwise
        # it's a working dynamic list in vm_listarea
        if listNumber <= 5:
            listOffset = v1Configuration[game]['lists'][listNumber-1]
            if listOffset is None:
                print(f'Error: This version 1 game does not use list {listNumber}')
                listOffset = 0
        else:
            listOffset = 0
    elif version == 2:
        # In v2
        offsetInTable = listNumber * 2
        listOffset    = data[0x06 + offsetInTable] + data[0x07 + offsetInTable] * 256
    elif version >= 3:
        offsetInTable = listNumber * 2
        listOffset    = data[0x14 + offsetInTable] + data[0x15 + offsetInTable] * 256

    if(opCode >= 0b11100000): # 0xE0
        # list#x[ variable[ <operand1> ]] = variable[ <operand2>  ]

        pc=pc+1        
        variable1=data[pc]

        pc=pc+1        
        variable2=data[pc]

        if(listOffset < 0):
            print('Error: Update to reference list attempted ', hex(opCode), hex(pc))

        msg = f"Set list#{opCode&0x1f}[var[{variable1:#0{4}x}]] = var[{variable2:#0{4}x}] (list address {aCodeStartAddr+listOffset:#0{6}x})"
        _print_code(opCode,cmdAddress,msg)

    elif(opCode >= 0b11000000): # 0xC0
        # variable[ <operand2> ] = list#x[ <operand1> ]

        pc=pc+1
        constant = data[pc]

        pc=pc+1
        variable = data[pc]

        if(listOffset < 0):
            print('Error: Update to reference list attempted ', hex(opCode), hex(pc))

        msg=f"Set var[{variable:#0{4}x}] = list#{opCode&0x1f}[{constant:#0{4}x}]"
        _print_code(opCode,cmdAddress,msg)

    elif(opCode >= 0b10100000): # 0xA0
        # variable[ <operand2> ] = list#x[ variable[ <operand1> ]]

        pc=pc+1
        variable1 = data[pc]

        pc=pc+1
        variable2 = data[pc]

        msg=f"Set var[{variable2:#0{4}x}] = list#{opCode&0x1f}[var[{variable1:#0{4}x}]] (list address {aCodeStartAddr+listOffset:#0{6}x})"
        _print_code(opCode,cmdAddress,msg)
    else:
        pc=pc+1
        constant = data[pc]

        pc=pc+1
        variable = data[pc]

        msg=f"Set list#{opCode&0x1f}[{constant:#0{2}x}] = var[{variable:#0{2}x}]"
        _print_code(opCode,cmdAddress,msg)

    return pc

def vm_fn_goto(data, opCode, pc, text=None):

    global gotoTable

    cmdAddress = pc
    # Get the first operand
    pc=pc+1
    operand1 = data[pc]
    operand2 = None

    if(text is None):
        label='Goto'
    else:
        label=text

    # The 6th bit indicates if the   command has one 
    # or two operands
    if (opCode & 0b00100000):
        # Single (it's set)
        if(operand1> 127):
            offset=_getSignedNumber(operand1)
        else:
            offset=operand1

        msg = label + f" {pc+offset-aCodeStartAddr:#0{6}x}"
        if pc+offset < len(data) or pc+offset < aCodeStartAddr:
            gotoTable.append(pc+offset-aCodeStartAddr)
            gotoTable = sorted(gotoTable)
        else:
            print('Error: '+label+' out of range')

    else:

        # Double (it's not set)
        pc=pc+1    
        operand2=data[pc]
        offset=(256 * operand2) + operand1
        msg = label + f" {offset:#0{6}x}"
        if aCodeStartAddr+offset < len(data):
            gotoTable.append(offset)
            gotoTable = sorted(gotoTable)
        else:
            print('Error: '+label+' out of range')

    _print_code(opCode,cmdAddress,msg)

    if(text is None):
        print('**************************************************************************')

    return pc

def vm_fn_intgosub(data, opCode, pc):

    pc=vm_fn_goto(data,opCode,pc,text="Gosub")

    return pc

def vm_fn_intreturn(data, opCode, pc):
    
    msg = f"Return"
    _print_code(opCode,pc,msg)
    print('**************************************************************************')
    return pc

def vm_fn_printnumber(data, opCode, pc):

    cmdAddress=pc
    # Get the first operand
    pc=pc+1
    variable1 = data[pc]

    msg = f"Print Number var[{variable1:#0{4}x}]"
    _print_code(opCode,cmdAddress,msg)

    return pc    

def vm_fn_messagev(data, opCode, pc):

    cmdAddress=pc
    # Get the first operand
    pc=pc+1
    operand1 = data[pc]

    msg = f"Print message var[{operand1:#0{4}x}]"
    _print_code(opCode,cmdAddress,msg)

    return pc


def vm_fn_messagec(data, opCode, pc):

    cmdAddress=pc
    # Get the first operand
    pc=pc+1
    operand1 = data[pc]
    operand2 = None
    nthMessage = 0
    


    # If the 7th bit is set in the opCode
    # then there is only one operand, otherwise
    # there are two
    if not (opCode & int("01000000",2)):
        pc=pc+1
        operand2=data[pc]

    # Calculate the nthMessage that should be 
    # printed
    if(operand2 is not None):
        nthMessage = (operand2 * 256 ) + operand1
    else:
        nthMessage = operand1  

    address = _getAddrForMessageN(data, nthMessage)
    print("/ Print message \"",end='')
    _printMessage(data, address)
    print("\"")
    msg =  f"Print message (constant) {nthMessage:#0{4}x}"

    _print_code(opCode,cmdAddress,msg)    
    
    return pc


def vm_fn_function(data,opCode,pc):
    
    cmdAddress=pc

    pc=pc+1
    operand1 = data[pc]

    if(operand1 == 1):
        msg = f"Function - Quit ({operand1:#0{4}x})"
    elif(operand1 == 2):
        pc=pc+1
        operand2=data[pc]
        msg = f"Function - Random - Set var[{operand2:#0{4}x}]=<random number>"
    elif(operand1 == 3):
        msg = f"Function - Save ({operand1:#0{4}x})"
    elif(operand1 == 4):
        msg = f"Function - Restore ({operand1:#0{4}x})"
    elif(operand1 == 5):
        msg = f"Function - Clear Workspace ({operand1:#0{4}x})"
    elif(operand1 == 6):
        msg = f"Function - Clear Stack ({operand1:#0{4}x})"
    elif(operand1 == 250 and version >= 3):
        pc=pc+1
        operand2=''
        while pc < len(data) and data[pc]:
            operand2=operand2+chr(data[pc])
            pc=pc+1
        msg = f"Function - Print String ({operand1:#0{4}x}) \"{operand2}\""
    else:
        msg = f"Function - Invalid fn code "+hex(operand1)

    _print_code(opCode,cmdAddress,msg)

    return pc


def vm_fn_input(data,opCode,pc):

    cmdAddress=pc
    # <command> <byte1> <byte2> <byte3> <byte4>
    # <byte1> where to store the first cmd/obj
    # <byte2> where to store the second cmd/obj
    # <byte3> where to store the third cmd/obj
    # <byte4> where to store the word count
    #
    # Don't need those bytes as we can just store
    # in python variables
    pc=pc+1
    variable1=data[pc]
    
    pc=pc+1
    variable2=data[pc]

    pc=pc+1
    variable3=data[pc]    

    pc=pc+1
    variable4=data[pc]

    msg =  f"Input - results in word1 var[{variable1:#0{4}x}], word2 var[{variable2:#0{4}x}], word3 var[{variable3:#0{4}x}], count var[{variable4:#0{4}x}]"

    _print_code(opCode,cmdAddress,msg)    
    
    return pc


def vm_fn_varcon(data,opCode,pc):

    cmdAddress = pc

    pc=pc+1
    operand1 = data[pc]
    pc=pc+1
    operand2 = data[pc]

    # The 7th bit indicates if the constant is
    # single or double byte
    if (opCode & 0b01000000):
        # Single (it's set)
        constant=operand1
        variable=operand2
        msg = f"Set var[{variable:#0{4}x}] = (constant) {constant:#0{4}x}"
    else:
        # Double (it's not set)
        constant=operand1 + (256 * operand2)
        pc=pc+1
        variable=data[pc]
    
        msg = f"Set var[{variable:#0{4}x}] = (constant) {constant:#0{4}x}"
    _print_code(opCode,cmdAddress,msg)

    return pc

def vm_fn_varvar(data,opCode,pc):

    cmdAddress = pc

    pc=pc+1
    variable1 = data[pc]
    pc=pc+1
    variable2 = data[pc]

    msg = f"Set var[{variable2:#0{4}x}] = var[{variable1:#0{4}x}]"
    _print_code(opCode,cmdAddress,msg)

    return pc

def vm_fn_add(data, opCode, pc):

    cmdAddress = pc

    pc=pc+1
    variable1 = data[pc]
    pc=pc+1
    variable2 = data[pc]

    msg=f"Set var[{variable2:#0{4}x}] += var[{variable1:#0{4}x}]"
    _print_code(opCode,cmdAddress,msg)    

    return pc   

def vm_fn_sub(data, opCode, pc):
    
    cmdAddress=pc

    pc=pc+1
    variable1 = data[pc]
    pc=pc+1
    variable2 = data[pc]

    msg=f"Set var[{variable2:#0{4}x}] -= var[{variable1:#0{4}x}]"
    _print_code(opCode,cmdAddress,msg)    

    
    return pc

def vm_fn_jump(data, opCode, pc):
    cmdAddress = pc

    pc=pc+1
    constant1 = data[pc]

    pc=pc+1
    constant2 = data[pc]

    pc=pc+1
    variable = data[pc]

    constant = (constant2 * 256) + constant1
 
    if aCodeStartAddr + constant < len(data):
        jumpTables.append(aCodeStartAddr + constant)
    else:
        print("Error: Jump Table at invalid address")

    msg=f"Jump table at {constant:#0{6}x} ({aCodeStartAddr + constant:#0{6}x}) - nth entry in var[{hex(variable)}]"
    _print_code(opCode,cmdAddress,msg)

    print('**************************************************************************')

    return pc

def vm_fn_screen(data, opCode, pc):

    cmdAddress = pc

    # Get the indicator for text (0x00) or graphics (0x01)
    # to show
    pc=pc+1
    constant1 = data[pc]

    # If switching to graphics mode (0x01) then there will be a second
    # operand that indicates which mode to switch to - although not used
    # by the BBC as it uses a small Mode 5 window
    if(constant1 > 0x00):
        pc=pc+1
        constant2 = data[pc]
        msg=f"Screen Graphmode ({constant2:#0{4}x})"
    else:
        msg=f"Screen Textmode"

    _print_code(opCode, cmdAddress, msg)

    return pc

def vm_fn_picture(data, opCode, pc):

    cmdAddress = pc

    pc=pc+1
    variable1 = data[pc]

    msg=f"Picture var[{variable1:#0{4}x}]"
    _print_code(opCode, cmdAddress, msg)

    return pc

def vm_fn_cleartg(data, opCode, pc):

    cmdAddress = pc

    pc=pc+1
    constant1 = data[pc]

    msg=f"Cleartg Graphmode ({constant1:#0{4}x})"
    _print_code(opCode, cmdAddress, msg)

    return pc

def vm_fn_get_next_object(data, opCode, pc):

    cmdAddress = pc

    # <cmd> <variable1> <variable2> <variable3> <variable4> <variable5> <variable6>
    pc=pc+1
    # max object?
    variable1 = data[pc]

    pc=pc+1
    # high search pos
    variable2 = data[pc]

    pc=pc+1
    # search pos
    variable3 = data[pc]

    pc=pc+1
    # object
    variable4 = data[pc]

    pc=pc+1
    # num objects
    variable5 = data[pc]

    pc=pc+1
    # search depth
    variable6 = data[pc]

    msg=f"Get Next Object var[{variable1:#0{4}x}] var[{variable2:#0{4}x}] var[{variable3:#0{4}x}] var[{variable4:#0{4}x}] var[{variable5:#0{4}x}] var[{variable6:#0{4}x}]"
    _print_code(opCode, cmdAddress, msg)

    return pc

def vm_fn_print_input(data, opCode, pc):

    cmdAddress = pc

    msg=f"Print Input"
    _print_code(opCode, cmdAddress, msg)

    return pc

def vm_fn_exit(data, opCode, pc):

    cmdAddress = pc

    # <cmd> <variable1> <variable2> <variable3> <variable4>
    pc=pc+1
    # 0490 - current location (moving from)
    variable1 = data[pc]

    pc=pc+1
    # 0448 first cmd / object
    variable2 = data[pc]

    pc=pc+1
    # 049C - door bump?!? don't know...
    variable3 = data[pc]

    pc=pc+1
    # 0492 - location to move to
    variable4 = data[pc]

    msg=f"Exits - check location var[{variable1:#0{4}x}] can move var[{variable2:#0{4}x}] - exit flags in var[{variable3:#0{4}x}] and target location (or 0x00) in var[{variable4:#0{4}x}]"
    _print_code(opCode,cmdAddress,msg)      


    return pc

def vm_fn_ifxxvt(data,opCode,pc,operation):
    offset=0

    cmdAddress = pc

    pc=pc+1
    operand1=data[pc]

    pc=pc+1
    operand2=data[pc]    

    pc=pc+1
    operand3=data[pc]

    variable1 = operand1
    variable2 = operand2

    if(opCode & 0b00100000):
        if(operand3> 127):
            offset = _getSignedNumber(operand3)
            msg=f"If var[{variable1:#0{4}x}] "+ operation + f" var[{variable2:#0{4}x}] then Goto {pc+offset-aCodeStartAddr:#0{6}x}"
        else:
            offset=operand3
            msg=f"If var[{variable1:#0{4}x}] "+ operation + f" var[{variable2:#0{4}x}] then Goto {pc+offset-aCodeStartAddr:#0{6}x}"
    else:
        pc=pc+1
        operand4=data[pc]
        offset=(256 * operand4) + operand3
        msg=f"If var[{variable1:#0{4}x}] "+ operation + f" var[{variable2:#0{4}x}] then Goto {offset:#0{6}x}"

    _print_code(opCode,cmdAddress,msg)  
    return pc    

def vm_fn_ifxxct(data,opCode,pc,operation):

    cmdAddress = pc

    # Bit 7 not set on opCode - double byte constant
    # Bit 6 not set on opCode - double byte offset
    offset=0
    constant=0

    # <cmd x11xxxxx> <variable> <constant> <offset>
    # <cmd x10xxxxx> <variable> <constant> <offset lsb> <offset msb>
    # <cmd x01xxxxx> <variable> <constant lsb> <constant msb> <offset>
    # <cmd x00xxxxx> <variable> <constant lsb> <constant msb> <offset lsb> <offset msb>
    
    pc=pc+1
    variable=data[pc]

    pc=pc+1
    if (opCode & 0b01000000):
        constant = data[pc]
    else: 
        constantLower  = data[pc]

        pc=pc+1
        constantHigher = data[pc]

        constant = 256 * constantHigher + constantLower

    pc=pc+1
    if (opCode & 0b00100000):
        offset = data[pc]
        if(offset> 127):
            offset=_getSignedNumber(offset)
        msg=f"If var[{variable:#0{4}x}] "+ operation + f" (constant) {constant:#0{4}x} then Goto {pc+offset-aCodeStartAddr:#0{6}x}"
    else: 
        offsetLower  = data[pc]

        pc=pc+1
        offsetHigher = data[pc]

        offset = (256 * offsetHigher + offsetLower)
        msg=f"If var[{variable:#0{4}x}] "+ operation + f" (constant) {constant:#0{4}x} then Goto {offset:#0{6}x}"
    _print_code(opCode,cmdAddress,msg)

    return pc

def vm_fn_ifeqvt(data,opCode,pc):
    pc=vm_fn_ifxxvt(data,opCode,pc,"==")
    return pc

def vm_fn_ifnevt(data,opCode,pc):   
    return vm_fn_ifxxvt(data,opCode,pc,"!=")

def vm_fn_ifltvt(data,opCode,pc):
    return vm_fn_ifxxvt(data,opCode,pc,"<")

def vm_fn_ifgtvt(data,opCode,pc):
    return vm_fn_ifxxvt(data,opCode,pc,">")

def vm_fn_ifeqct(data,opCode,pc):
    return vm_fn_ifxxct(data,opCode,pc,"==")

def vm_fn_ifnect(data,opCode,pc):
    return vm_fn_ifxxct(data,opCode,pc,"!=")

def vm_fn_ifltct(data,opCode,pc):
    return vm_fn_ifxxct(data,opCode,pc,"<")

def vm_fn_ifgtct(data,opCode,pc):
    return vm_fn_ifxxct(data,opCode,pc,">")


###############################################################################
# _autodetect_game()
#
# Autodetect v2-3-4 games and if not found then:
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
def _autodetect_game(data, version):
    game = 'unknown'
    startAddress = -1

    if version < 2:
        length = data[0x1c] + data [0x1d] * 256
        if length > 0 and length + 1 <= len(data):
            checksum = 0
            for j in range(0x20, length + 1):
                checksum = checksum + data[j];
            if checksum & 0xff == data[0x1e]:
                version = 2

    if version < 3:
        length = data[0x00] + data [0x01] * 256
        if length > 0 and length + 1 <= len(data):
            checksum = 0
            for j in range(length + 1):
                checksum = checksum + data[j];
            if checksum & 0xff == 0:
                if length >= 0x8500:
                    version = 4
                else:
                    version = 3

    # Either it's a v1 file or unknown so scan the file
    if(version < 2):
        for gameKey in v1Configuration:
            # Skip if the configuration is for a non-v1 file
            # we'll test it later to see if it's v2
            if('signatureBytes' not in v1Configuration[gameKey]):
                continue
            signatureBytes = v1Configuration[gameKey]['signatureBytes']
            startAddress  = data.find(signatureBytes)
            if startAddress != -1:
                name = v1Configuration[gameKey]['name']
                game = gameKey
                if version != 1:
                    print('[Identified v1 game: "'+name+'" --game '+game+']')
                    version = 1
                break

    if version == 2:
        startAddress = data[0x1a] + data [0x1b] *256
    elif version >= 3:
        startAddress = data[0x28] + data [0x29] *256

    return startAddress, game, version

###############################################################################
# _identify_game()
#
# Identify v2-3-4 games (already autodetected) based on the "Welcome to" part
# in some well-known key descriptions.
#
#
# Parameters:
# none
#
# Returns:
#   game indicator
###############################################################################
def _identify_game(version):
    for msg in [0x01, 0xa0, 0xe6, 0xff]:
        address = _getAddrForMessageN(data, msg)
        desc=_getMessage(data, address)
        if "Welcome to" in desc:
            for gameKey in v1Configuration:
                if v1Configuration[gameKey]['version'] == version:
                    name = v1Configuration[gameKey]['name']
                    if name in desc:
                        game = gameKey
                        print('[Identified v'+str(version)+' game: "'+name+'" --game '+game+']')
                        break

    # Remove this placeholder when v3-4 messages are implemented
    if version >= 3:
        game = 'unknownv3-4'
        print('[Could not identify v'+str(version)+' game: n/i!]')

    if game == 'unknown':
        print("[Could not identify v"+str(version)+" game!]")

    return game

def printJumpTable(data,pc):

    global gotoTable

    counter = 0

    print("Jump Table       (Idx) ")
    print('**************************************************************************')

    while(True):
        if version >= 3:
            dictionaryWord = "n/i"
        elif counter == 0:
            dictionaryWord = "n/a"
        else:
            dictionaryWord = {i for i in vm_dictionary if vm_dictionary[i]==counter}

        if pc+1 >= len(data):
            break
        goto = data[pc+1] * 256 + data[pc]
        if goto + aCodeStartAddr >= len(data):
            break
        gotoTable.append(goto)
        gotoTable = sorted(gotoTable)

        print(f"{pc-aCodeStartAddr:#0{6}x} ({pc:#0{6}x}): ({counter:#0{4}x}) If player cmd in {dictionaryWord} Goto {goto:#0{6}x}")
        
        pc = pc+2
        counter = counter + 1

        if pc - aCodeStartAddr in gotoTable:
            break

    print('**************************************************************************')
    
    return pc

############################################################
# MAIN HERE
############################################################

# Set up the command line arguments so the game
# to analyse can be specified on a switch
parser = argparse.ArgumentParser()
parserGroup = parser.add_mutually_exclusive_group(required=True)
parserGroup.add_argument('-g','--game', type=str, choices=v1Configuration.keys())
parserGroup.add_argument('-f','--file', type=str)
args = parser.parse_args()

# Check to see if they specified a game or a file
if(args.game):
    game     = args.game
    filename = v1Configuration[game]['filename']
    version  = v1Configuration[game]['version']
else:
    game     = None
    filename = args.file
    version  = -1

with open(filename,'rb') as dataFile:
    data = bytearray(dataFile.read())
    dataFile.close()

# Identify the game (do this anyway for preconfigured ones)
aCodeStartAddr, foundGame, version = _autodetect_game(data, version)

# If game was not given, maybe we can detect it
if(not game):
    game = foundGame

# The message database of some v2 games is still on v1
# Initialize it first to be the same as the game version
mversion = version
if(version == 1):
    # Derive the location of the major game partsffunction based on offsets in the v1 configuration
    dictionaryAddr       = aCodeStartAddr + v1Configuration[game]['offsets']['dictionaryOffset']
    exitsAddr            = aCodeStartAddr + v1Configuration[game]['offsets']['exitsOffset']
    messagesStartAddr    = aCodeStartAddr + v1Configuration[game]['offsets']['messagesOffset']
    commonFragmentsAddr  = aCodeStartAddr + v1Configuration[game]['offsets']['fragmentsOffset']
elif(version == 2):
    dictionaryAddr       = data[0x06] + data [0x07] *256
    messagesStartAddr    = data[0x00] + data [0x01] *256
    exitsAddr            = data[0x04] + data [0x05] *256
    commonFragmentsAddr  = data[0x02] + data [0x03] *256
    # v1 msg db starts with an empty one
    if data[messagesStartAddr] == 1:
        mversion = 1
elif(version >= 3):
    messagesStartAddr    = data[0x02] + data [0x03] *256
    messagesLen          = data[0x04] + data [0x05] *256
    dictionaryAddr       = data[0x06] + data [0x07] *256
    dictionaryLen        = data[0x08] + data [0x09] *256
    dictionaryDataAddr   = data[0x0a] + data [0x0b] *256
    dictionaryDataLen    = data[0x0c] + data [0x0d] *256
    wordTableAddr        = data[0x0e] + data [0x0f] *256
    unknownAddr          = data[0x10] + data [0x11] *256
    exitsAddr            = data[0x12] + data [0x13] *256

# Identify autodetected v2-3-4 game
if version > 1 and game == 'unknown':
    game = _identify_game(version)

# If it couldn't be identified then quit
if(aCodeStartAddr < 0 or game == 'unknown'):
    print('Error: Unable to detect a Level 9 game in ' + filename)
    sys.exit()

print('**************************************************************************')
print('Level 9 A-Code game dissassembly for "'+game+'" (v'+str(version)+')')
print('**************************************************************************')

pc = aCodeStartAddr

with open(filename,'rb') as fr:
    data=bytearray(fr.read())
    length=len(data)
    # Pad data to avoid instructions going out of boundary in mid-action
    data=data+b'????????????????'

    vm_fn_load_dictionary(data)

    jump = False

    while(True):
        if pc in jumpTables:
            newpc = printJumpTable(data,pc)
            if newpc == pc:
                jumpTables.remove(pc)
                print("Error: Jump Table has no valid entries")
            elif jump:
                pc = newpc
            else:
                jumpTables.remove(pc)
                print("Error: Jump Table is executable - also interpreting as such")
            continue

        if pc >= length or (jump and gotoTable and pc - aCodeStartAddr > gotoTable[-1]):
            print('**************************************************************************')
            print('Level 9 A-Code game dissassembly complete for "'+game+'" (v'+str(version)+')')
            print('**************************************************************************')
            break
        else:
            jump = False

        # Get the next instruction / opCode
        opCode = data[pc]
        opCodeClean = opCode & int("1F",16)

        if(opCode & (int("10000000",2))):
            pc=vm_listhandler(data,opCode,pc)        
        elif(opCodeClean == 0):
            pc = vm_fn_goto(data, opCode, pc)        
            jump = True
        elif(opCodeClean == 1):            
            pc = vm_fn_intgosub(data,opCode,pc)
        elif(opCodeClean == 2):
            pc = vm_fn_intreturn(data,opCode,pc)
            jump = True
        elif(opCodeClean == 3):
            pc = vm_fn_printnumber(data,opCode,pc)
        elif(opCodeClean == 4):
            pc = vm_fn_messagev(data, opCode, pc)
        elif(opCodeClean == 5):
            pc = vm_fn_messagec(data, opCode, pc)
        elif(opCodeClean == 6):
            pc = vm_fn_function(data, opCode, pc)
        elif(opCodeClean == 7):
            pc = vm_fn_input(data, opCode, pc)
        elif(opCodeClean == 8):
            pc = vm_fn_varcon(data, opCode, pc)
        elif(opCodeClean == 9):
            pc = vm_fn_varvar(data, opCode, pc)
        elif(opCodeClean == 10):
            pc = vm_fn_add(data, opCode, pc)
        elif(opCodeClean == 11):
            pc = vm_fn_sub(data, opCode, pc)
        elif(opCodeClean == 14):
            pc = vm_fn_jump(data,opCode,pc)
            jump = True
        elif(opCodeClean == 15):
            pc = vm_fn_exit(data,opCode,pc)
        elif(opCodeClean == 16):
            pc = vm_fn_ifeqvt(data,opCode,pc)
        elif(opCodeClean == 17):
            pc = vm_fn_ifnevt(data,opCode,pc)
        elif(opCodeClean == 18):
            pc = vm_fn_ifltvt(data,opCode,pc)
        elif(opCodeClean == 19):
            pc = vm_fn_ifgtvt(data,opCode,pc)     
        elif(opCodeClean == 20):
            pc = vm_fn_screen(data,opCode,pc)
        elif(opCodeClean == 21):
            pc = vm_fn_cleartg(data,opCode,pc)
        elif(opCodeClean == 22):
            pc = vm_fn_picture(data,opCode,pc)
        elif(opCodeClean == 23):
            pc = vm_fn_get_next_object(data,opCode,pc)
        elif(opCodeClean == 24):
            pc=vm_fn_ifeqct(data,opCode,pc)
        elif(opCodeClean == 25):            
            pc=vm_fn_ifnect(data,opCode,pc)
        elif(opCodeClean == 26):
            pc = vm_fn_ifltct(data,opCode,pc)      
        elif(opCodeClean == 27):
            pc = vm_fn_ifgtct(data,opCode,pc)            
        elif(opCodeClean == 28):
            pc = vm_fn_print_input(data,opCode,pc)
        else:
            _print_code(opCodeClean, pc, 'Invalid opCode')
    
        pc=pc+1
