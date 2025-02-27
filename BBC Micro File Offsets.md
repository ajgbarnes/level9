
# File Offset Locations

Below is a list for the BBC Micro files of the offsets where the major components are contained. The offsets are in hexadecimal. 

Each of the files has a different order of the major components and the only one that seems to matter is that read only (static) lists MUST be in the file before the A-Code.  And that's because if there is a positive offset for the list, it's treated like a dynamic list instead. 

## Snowball

|Component|File Offset|
|:---|:---:|
|Dictionary|0080|
|Exits|0790|
|list#1|09a0|
|list#3|0a40|
|A-code|0a90|
|Messages|23c0|
|Fragments|5fd7|
|6502 Code|6220|

## Lords of Time

|Component|File Offset|
|:---|:---:|
|Dictionary|0020|
|Messages|0e83|
|Exits|0900|
|list#1|0bb0|
|list#3|0cf0|
|Fragments|480B|
|A-code|4a20|
|6502 Code|6120|

## Colossal 

|Component|File Offset|
|:---|:---:|
|Dictionary|0080|
|Exits|0430|
|list#2|0795|
|list#4|07b5|
|Messages|1760|
|Fragments|5fb7|
|A-code|07e0|
|6502 Code|6220|

## Adventure Quest

|Component|File Offset|
|:---|:---:|
|Exits|0020|
|list#1|029d|
|list#3|0318|
|Dictionary|0358|
|A-code|0820|
|Messages|1820|
|Fragments|51f1|
|6502 Code|5a00|

## Dungeon Adventure

|Component|File Offset|
|:---|:---:|
|Messages|0000|
|list#1|066a|
|A-code|0740|
|Fragments|600c|
|6502 Code|6220|
|Exits|6ae0|
