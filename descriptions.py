# Python tool to extract the descriptions from all v1 Level 9 games
#
# Python 3 required - tested with 3.9.1
#
# (c) Copyright 2021 Andy Barnes
#
# Twitter @ajgbarnes
#
# TODO
# - Add comments
# - Adapt to v2 and beyond

import argparse
import json


def printCharacter(byte):
    char = chr(byte+int("0x1D",16))
    if(char == "%"):
        print("\n")
    elif(char == "_"):
        print(" ")
    else:
        print(chr(byte+29),end='')

def findAndPrintLetters(iterations, bytearray):

    startAddress=commonFragmentsAddr
    currentPos=startAddress
    loopsLeft=iterations - 0x5E

    while loopsLeft:
        if(bytearray[currentPos]==1):
            loopsLeft = loopsLeft-1
        currentPos=currentPos+1

    while(bytearray[currentPos]>2):
        if(bytearray[currentPos]>=94):
            findAndPrintLetters(bytearray[currentPos], bytearray)
        else:
            printCharacter(bytearray[currentPos])
        currentPos=currentPos+1

############################################################
# MAIN HERE
############################################################
# Note - adding a section where the messagesStartAddr is set 
# to the commonFragmentsAddr will decode the common fragments   
f=open('level9-games.json')
gameData=json.load(f)


# Set up the command line arguments so the game
# to analyse can be specified on a switch
parser = argparse.ArgumentParser()
parser.add_argument('--game', type=str, choices=gameData.keys(),required=True)
args = parser.parse_args()

loadAddress          = int(gameData[args.game]['loadAddress'],16)
commonFragmentsAddr  = int(gameData[args.game]['commonFragmentsAddr'],16) - loadAddress
messagesStartAddr    = int(gameData[args.game]['messagesStartAddr'],16) - loadAddress
filename             = gameData[args.game]['filename']

with open(filename,'rb') as fr:
    data=bytearray(fr.read())
    print("Data length:",len(data))

    counter = 0

    startAddress=messagesStartAddr
    address=startAddress

    print(hex(counter)," / ",hex(address+loadAddress)," : ",end='')

    byte = data[address]

    while(byte):
        #94 = $5E
        if(byte>=94):
            findAndPrintLetters(byte, data)
            #print("_",end='')
            pass
        elif(byte < 94 and byte > 2):
            printCharacter(byte)
        elif(byte == 2):
            break
        else:
            print("")
            counter=counter+1
            print(hex(counter)," / ",hex(address+1+loadAddress)," : ",end='')

        address=address+1
        byte = data[address]

    print("\n")
    print(hex(address+loadAddress))

