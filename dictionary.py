# Python tool to extract the dictionary from all v1 Level 9 games
#
# Python 3 required - tested with 3.9.1
#
# (c) Copyright 2021 Andy Barnes
#
# Twitter @ajgbarnes
#
# TODO
# - Add comments
# - doesn't cleanly detect the end of the dictionary for Dungeon Adventure
#   (runs on past it)
# - Adapt to v2 and beyond

import argparse
import json


############################################################
# MAIN HERE
############################################################
f=open('level9-games.json')
gameData=json.load(f)


# Set up the command line arguments so the game
# to analyse can be specified on a switch
parser = argparse.ArgumentParser()
parser.add_argument('--game', type=str, choices=gameData.keys(),required=True)
args = parser.parse_args()

loadAddress          = int(gameData[args.game]['loadAddress'],16)
dictionaryAddr       = int(gameData[args.game]['dictionaryAddr'],16) - loadAddress
filename             = gameData[args.game]['filename']


with open(filename,'rb') as fr:
    data=bytearray(fr.read())
    print("Data length:",len(data))

    codeNext = False

    word=""

    startAddress=dictionaryAddr
    address=startAddress

    byte = data[address]
    wordStart=address
    
    while byte:
        if codeNext:
            print(hex(byte), " / ",hex(wordStart+loadAddress),word)
            codeNext=False
            word=""
            wordStart=address+1
        elif byte>=127:
            byte = byte & 127
            codeNext=True
            word = word + chr(byte)
            #print(chr(byte),end='')
        else:
            word = word + chr(byte)
            #print(chr(byte),end='')

        address=address+1
        byte = data[address]

    print("\nDictionary length :",hex(address-startAddress), " / ",address-startAddress)




