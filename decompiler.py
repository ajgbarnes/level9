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

    while fragmentNumber:
        if(data[address]==1):
            fragmentNumber = fragmentNumber - 1
        address=address+1

    return address

def _getAddrForMessageN(data, nthMessage):

    messagesAddress = messagesStartAddr

    # Do I subtract 1...
    
    # Keeping looping until the nth message is found
    while nthMessage:
        byte = data[messagesAddress]

        if(byte == 0):
            print("ERROR didn't find nth string")
            break
        elif(byte == 1):
            nthMessage = nthMessage - 1
        
        messagesAddress = messagesAddress + 1
        
    return messagesAddress 

def _getMessage(data, msgAddress):

    message=''

    byte = data[msgAddress]
    while byte:
        if(byte >= int("5E",16)):
            fragmentNumber = byte - int("5E",16)
            fragmentAddr = _getAddrForFragment(data,fragmentNumber)
            newMessage = _getMessage(data, fragmentAddr)
            message = message + newMessage

        elif(byte == int("2",16)):
            # Doesn't appear to be used
            pass
        elif(byte == int("1",16)):
            # End of fragment or string
            break
        else:
            message = message + str(chr(byte+0x1D))
            #_getCharacter(byte)

        msgAddress = msgAddress + 1
        byte = data[msgAddress]

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
        if(word[-1]!="\n"):
            print(" ",end='')


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
            vm_dictionary[word]=byte
            codeNext=False
            word=""
            wordStart=address+1
            count=count+1
            if(game == 'colossal' and count > 0x99):
                break
        else:
            if byte>=127:
                codeNext=True
            word = word + chr(byte & int("01111111",2))

        address=address+1
        byte = data[address]

    logging.debug(vm_dictionary.keys())

def vm_listhandler(data,opCode,pc):

    cmdAddress =pc
    listNumber = opCode & 0b00011111
    
    if(opCode & 0b00011111 > 0x05):
        print(f'Version 1 games only supported 5 lists and this is accessing list {opCode & 0b00011111}')
        sys.exit()

    listOffset = v1Configuration[game]['lists'][listNumber-1]    

    if(opCode >= 0b11100000): # 0xE0
        # list#x[ variable[ <operand1> ]] = variable[ <operand2>  ]

        pc=pc+1        
        variable1=data[pc]

        pc=pc+1        
        variable2=data[pc]

        if(listOffset < 0):
            print('Error: Update to reference list attempted ', hex(opCode), hex(pc))
            sys.exit()

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
            sys.exit()

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
        gotoTable.append(pc+offset-aCodeStartAddr)
        gotoTable = sorted(gotoTable)

    else:

        # Double (it's not set)
        pc=pc+1    
        operand2=data[pc]
        offset=(256 * operand2) + operand1
        msg = label + f" {offset:#0{6}x}"
        gotoTable.append(offset)
        gotoTable = sorted(gotoTable)

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
    print("/ Print message  \"",end='')
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
    else:
        print('Unhandled fn code '+hex(operand1))
        sys.exit()

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

    msg=f"Set var[{variable2:#0{4}x}] -= var[{variable1:#0{4}x}]."
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
 
    msg=f"Jump table at {constant:#0{6}x} ({aCodeStartAddr + constant:#0{6}x}) - nth entry in var[{hex(variable)}]"
    _print_code(opCode,cmdAddress,msg)

    jumpTables.append(aCodeStartAddr + constant)

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

def printJumpTable(data,pc):
    # nextGoto = 0
    # for i in gotoTable:
    #     if ( pc < i):
    #         nextGoto = i
    #         break
    #     if (pc >= i):
    #         continue

    counter = 0

    print("Jump Table       (Idx) ")
    print('**************************************************************************')

    while(True):
        if(counter == 0):
            dictionaryWord = "n/a"
        else:
            dictionaryWord = {i for i in vm_dictionary if vm_dictionary[i]==counter}
        print(f"{pc-aCodeStartAddr:#0{6}x} ({pc:#0{6}x}): ({counter:#0{4}x}) If player cmd in {dictionaryWord} Goto {data[pc+1] * 256 +data[pc]:#0{6}x}")
        
        pc = pc+2
        counter = counter + 1

        if(game == 'colossal' and counter == 0x5f):
            break
        elif(game == 'adventure' and counter == 0x2c):
            break

    print('**************************************************************************')
    
    return pc

############################################################
# MAIN HERE
############################################################

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

print('**************************************************************************')
print('Level 9 A-Code game dissassembly for')
print('**************************************************************************')

pc = aCodeStartAddr

with open(filename,'rb') as fr:
    data=bytearray(fr.read())

    vm_fn_load_dictionary(data)

    cmds = set()

    print(hex(pc))
    
    while(True):
        # Get the next instruction / opCode
        opCode = data[pc]
        opCodeClean = opCode & int("1F",16)

        if((data[pc] == 0x0 and data[pc+1] == 0x0) or (pc < aCodeStartAddr)):
            print('**************************************************************************')
            print('Level 9 A-Code game dissassembly complete')
            print('**************************************************************************')
            break

        if(pc in jumpTables):
            pc = printJumpTable(data,pc)
            continue

        if(opCode & (int("10000000",2))):
            pc=vm_listhandler(data,opCode,pc)        
        elif(opCodeClean == 0):
            pc = vm_fn_goto(data, opCode, pc)        
        elif(opCodeClean == 1):            
            pc = vm_fn_intgosub(data,opCode,pc)
        elif(opCodeClean == 2):
            pc = vm_fn_intreturn(data,opCode,pc)
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
        elif(opCodeClean == 24):
            pc=vm_fn_ifeqct(data,opCode,pc)
        elif(opCodeClean == 25):            
            pc=vm_fn_ifnect(data,opCode,pc)
        elif(opCodeClean == 26):
            pc = vm_fn_ifltct(data,opCode,pc)      
        elif(opCodeClean == 27):
            pc = vm_fn_ifgtct(data,opCode,pc)            
        else:
            logging.critical("Breaking on opCode "+str(opCode))
            break
    
        pc=pc+1

    logging.debug("pc"+hex(pc))
