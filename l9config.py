###############################################################################
# Level 9 Version 1 Configuration Table
# -------------------------------------
#
# Later versions of Level 9 games have a configuration table at the start 
# however version 1 games do not have this. The BBC Micro version 1 games
# DO however have a configuration table for each game. I don't know if this is
# consistently implemented yet (need to learn some Z80 and memory addressing
# to understand the Spectrum ones). 
#
# A note on the configuration attributes:
#
# filename       - BBC Micro filename by run by default if you chooose
#                  game via a command line switched
# script         - Script to execute to test the game or get to a certain 
#                  point
# signatureBytes - First 5 bytes of the A-Code - allows a game file from
#                  any platform to be scanned and the game to be identified.
#                  Also used to find the offset from the start of the game file
#                  for the start of the A-Code (used below for the offsets)
# offsets        - Where each of the major game file components are relative
#                  to the start of the A-Code in the file
# lists          - For reference lists, location in the game file (reference
#                  list is e.g. starting location of each object). These will
#                  always be negative and are before the A-Code for version 1 
#                  games.
#                  
#                  For dynamic lists e.g. an objects current location, these will
#                  be 0 or greater (positive). This represents the starting
#                  offset on where to store them in the listarea e.g. 
#                  object location might start at 50 in the list area.
#
#                  Note that version 1 games can have a maximum  of 5 lists 
#                  per game (reference and dynamic).
###############################################################################
v1Configuration = {
    "adventure" : {
        "version"           : 1,
        "filename"          : "ADQUEST",
        "script"            : "test-scripts/adventure-quest-v1.txt",
        "signatureBytes"    : b'\x00\x06\x00\x00\x46',
        "offsets" : {
            "dictionaryOffset"  : -0x04c8,
            "messagesOffset"    :  0x1000,
            "fragmentsOffset"   :  0x49d1,
            "exitsOffset"       : -0x0800            
        },
        "lists" : [
            -0x0583,
            0x0000,
            -0x0508,
            -0x04e0, 
            None        
        ],
    },    
    "colossal" : {
        "version"           : 1,
        "filename"          : "COLOSS2",
        "script"            : "test-scripts/colossal-adventure-v1.txt",
        "signatureBytes"    : b'\x20\x04\x00\x49\x00',
        "offsets" : {
            "dictionaryOffset"  : -0x0760,
            "messagesOffset"    :  0x0f80,
            "fragmentsOffset"   :  0x57d7,
            "exitsOffset"       : -0x03b0
        },
        "lists" : [
            0x0000,
            -0x004b,
            0x0080,
            -0x002b, 
            0x00d0                
        ],
    },    
    "dungeon" : {
        "version"           : 1,
        "filename"          : "Dungeo2",
        "script"            : "test-scripts/dungeon-adventure-v1.txt",
        "signatureBytes"    : b'\x00\x06\x00\x00\x44',
        "offsets" : {
            "dictionaryOffset"  : -0x0740,
            "messagesOffset"    :  0x16bf,
            "fragmentsOffset"   :  0x58cc,
            "exitsOffset"       :  0x63e0
        },
        "lists" : [
            -0x00d6,
            0x0000,
            None,
            None,
            None
        ]
    },    
    "lords" : {
        "version"           : 1,
        "filename"          : "LORDSOF",
        "script"            : "test-scripts/lords-of-time-v1.txt",
        #"filename"          : "lot.tzx",
        "signatureBytes"    : b'\x00\x06\x00\x00\x65',
        "offsets" : {
            "dictionaryOffset"  : -0x4a00,
            "messagesOffset"    : -0x3b9d,
            "fragmentsOffset"   : -0x0215,
            "exitsOffset"       : -0x4120
        },
        "lists" : [
            -0x3e70,
            0x0000,
            -0x3d30,
            0x0080,
            0x0100
        ]
    },
    "snowball" : {
        "version"           : 1,
        "filename"          : "SNOWBAL",
        "script"            : "test-scripts/snowball-v1.txt",
        "signatureBytes"    : b'\x00\x06\x00\x00\xd4',
        "offsets" : {
            "dictionaryOffset"  : -0x0a10,
            "messagesOffset"    :  0x1930,
            "fragmentsOffset"   :  0x5547,
            "exitsOffset"       : -0x0300
        },
        "lists" : [
            -0x00f0,
            0x0000,
            -0x0050,
            None, 
            None            
        ],
    }
}
