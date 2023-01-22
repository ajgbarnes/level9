import json

fSnowball    = open("..\\src\\snowball\\memory-locations.json")
fLords       = open("..\\src\\lords-of-time\\memory-locations.json")
fColossal    = open("..\\src\\colossal-adventure\\memory-locations.json")
fDungeon     = open("..\\src\\dungeon-adventure\\memory-locations.json")
fAdventure   = open("..\\src\\adventure-quest\\memory-locations.json")

snowballDict  = json.load(fSnowball)[0]
lordsDict     = json.load(fLords)[0]
colossalDict  = json.load(fColossal)[0]
dungeonDict   = json.load(fDungeon)[0]
adventureDict = json.load(fAdventure)[0]

fSnowball.close()
fLords.close()
fColossal.close()
fDungeon.close()
fAdventure.close()

keys = snowballDict.keys()

print('|Label|Adventure Quest|Colossal Adventure|Dungeon Adventure|Lords of Time|Snowball|')
print('|:---|:---:|:---:|:---:|:---:|:---:|')

def getValue(gameDict, key):
    value = gameDict.get(key, "")
    if(value == ""):
        value = "n/a".format(":4^")
    else:
        value = hex(value).format(":04x").replace("0x","")
    return value


for key in keys:
    label = key.replace('.','')
    print(f"|{label}|{getValue(adventureDict,key)}|{getValue(colossalDict,key)}|{getValue(dungeonDict,key)}|{getValue(lordsDict,key)}|{getValue(snowballDict,key)}|")