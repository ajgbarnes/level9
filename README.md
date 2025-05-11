# Level 9 Python Tools

These are absolutely iconic adventure games for the BBC Micro - always been fascinated by them and how they crammed so much beautiful and eloquent English into so little memory. 

I do not hold the copyright to the original games, only the python programs that inspect and read them. The original game Copyright remains with Level 9.

Thank you to David Kinder and Glen Summers for their work on the C Level 9 interpreter.

Feedback and comments are always appreciated to help preserve and understand the internals of this classic.

# Level 9 Version 1 Specification

I have written a [specification for Version 1 games](https://github.com/ajgbarnes/level9/blob/main/A-Code%20Version%201%20Specification.md) which I will extended to include later version over time.  It hopefully gives a pretty good introduction into how the Level 9 game engines should work, if you wish to write your own or just want to understand it academically.  

It's not perfect, but I will proof read it again and improve over time. Any feedback is welcome. 

# Game Dictionaries and Descriptions

For all the supported Level 9 a-code version 1 games, the descriptions and dictionaries have been pre-extracted below:

## Extracted Dictionaries
* [Adventure Quest Dictionary](https://github.com/ajgbarnes/level9/blob/main/game-text/adventure-quest-v1-dict.txt)
* [Colossal Aventure Dictionary](https://github.com/ajgbarnes/level9/blob/main/game-text/colossal-adventure-v1-dict.txt)
* [Dungeon Adventure Dictionary](https://github.com/ajgbarnes/level9/blob/main/game-text/dungeon-adventure-dict.txt)
* [Lords of Time Dictionary](https://github.com/ajgbarnes/level9/blob/main/game-text/lords-of-time-v1-dict.txt)
* [Snowball Dictionary](https://github.com/ajgbarnes/level9/blob/main/game-text/snowball-v1-dict.txt)

## Extracted Descriptions
* [Adventure Quest Descriptions](https://github.com/ajgbarnes/level9/blob/main/game-text/adventure-quest-v1-descs.txt)
* [Colossal Aventure Descriptions](https://github.com/ajgbarnes/level9/blob/main/game-text/colossal-adventure-v1-descs.txt)
* [Dungeon Adventure Descriptions](https://github.com/ajgbarnes/level9/blob/main/game-text/dungeon-adventure-descs.txt)
* [Lords of Time Descriptions](https://github.com/ajgbarnes/level9/blob/main/game-text/lords-of-time-v1-descs.txt)
* [Snowball Descriptions](https://github.com/ajgbarnes/level9/blob/main/game-text/snowball-v1-descs.txt)

SPOILERS: The full game walkthroughs and response text can be found here:

## Extracted Full Game Walkthroughs and Text
* [Adventure Quest Walkthrough](https://github.com/ajgbarnes/level9/blob/main/full-game-text/adventure-quest-v1.txt)
* [Colossal Aventure Walkthrough](https://github.com/ajgbarnes/level9/blob/main/full-game-text/colossal-adventure-v1.txt)
* [Dungeon Adventure Walkthrough](https://github.com/ajgbarnes/level9/blob/main/full-game-text/dungeon-adventure.txt)
* [Lords of Time Walkthrough](https://github.com/ajgbarnes/level9/blob/main/full-game-text/lords-of-time-v1.txt)
* [Snowball Walkthrough](https://github.com/ajgbarnes/level9/blob/main/full-game-text/snowball-v1.txt)

The test scripts used to generate the above walkthroughs were sourced from [David Kinder's Github Level 9 repository](https://github.com/DavidKinder/Level9) and tweaked slightly to work with my parser.


# Pre-requisities

[Download this package as a zip file](https://github.com/ajgbarnes/level9/archive/refs/heads/main.zip) and extract somewhere or clone via git.

This should run on any platform that supports Python 3.10+ - I have tried it so far on Windows 10 and MacOS Monterrey and later. Install the Python 3 interpreter and make sure it's in your PATH for your operating system.

Check you have the right version by typing the following from the command line

```
python --version
```

On some systems, you may have to access the Python 3 by including the version as below - if so all examples later in this note will need to be changed from *python* to *python3*

```
python3 --version
```

# Dictionary Extractor

Extract the dictionary of commands and objects from the game - this is everything that the game understands from user input. 

Each line output will have an object code (in hex), the address in runtime memory where it would be found and the keyword.  There may be more than one keyword for a particular object code as sometimes synonyms are defined. 

If you want to derive the file offset instead of the runtime memory address, look in the level9-games.json file and subtract the loadAddress for that game.

The supported games can be seen by typing the following on the command line:

```
python level9.py --game 
or
python level9.py -g 
```

To run the dictionary extractor on a particular game, replace "\<game-name\>" with the name of one listed in the output from the previous command:

```
python level9.py --game <game-name> --dictionary
or
python level9.py -g <game-name> -d
```

In game at any point, \#dictionary and \#dict will print the dictionary.

# Descriptions Extractor

Extract all available game descriptions - including rooms, exits, objects, different object states. 

Each line output will have an description code (in hex), the address in runtime memory where it would be found and the description itself.  Given the way the game engine works, most description are fragments brought together with game engine constants and variable values for lookup.

If you want to derive the file offset instead of the runtime memory address, look in the level9-games.json file and subtract the loadAddress for that game.

The supported games can be seen by typing the following on the command line:

```
python level9.py --game 
or
python level9.py -g 
```

To run the descriptions extractor on a particular game, replace "\<game-name\>" with the name of one listed in the output from the previous command:

```
python level9.py --game <game-name> --messages
or
python level9.py -g <game-name> -m
```
# Exit Definitions Extractor

Extract all available exit definitions.

Each line output will have:

* File offset for the exit definition
* From location id
* To location id
* Direction that the player has to move
* Bit 0 Inverse direction indicator e.g. if a player can go East from location 1 to location 2, they can also go West
* Bit 1 definition (see produced file for definition as it varies by game)
* BIt 2 definition (see produced file for definition as it varies by game)
* From location message id
* From location description

The supported games can be seen by typing the following on the command line:

```
python exits.py --game 
or
python exits.py -g 
```

To run the Exit Definitions extractor on a particular game, replace "\<game-name\>" with the name of one listed in the output from the previous command:

```
python level9.py --game <game-name> --exits
or
python level9.py -g <game-name> -e
```

# Level 9 v1 Parser / Interpreter

Now released and should work with games from the BBC Micro, Oric, ZX Spectrum etc including:

* Adventure Quest
* Colossal Aventure
* Dungeon Adventure
* Lords of Time
* Snowball Test

It was intended to be ultra portable so rus on the command line for now (that will change to support graphics but allow a user to choose).  

Here is a recording of it running through a scripted input game showing [Level 9's Lords of Time](https://www.youtube.com/watch?v=epD8R3tzTPk).  It currently works with ALL v1 Level 9 games for the BBC Micro and tested with a few from the Oric (.tap) and ZX Spectrum (.tzx). Others may work - I have not tried any C64 versions yet partly because I don't understand the D64 format yet (doesn't appear to preserve the binary in "raw" that can be read and interpreted)

The supported games can be seen by typing the following on the command line:

``` 
python level9.py --game 
or
python level9.py -g
```

This will respond with:

```
usage: level9.py [-h] [-d | -m] (-g {adventure,colossal,dungeon,lords,snowball} | -f FILE) [-s SCRIPT | -a]
                 [--logging {info,debug}]
level9.py: error: one of the arguments -g/--game -f/--file is required
```

To run the a particular adventure game, replace "\<game-name\>" with the name of one listed in the output from the previous command:

```
python level9.py --game <game-name>
```

To test a game or see it played out in full, use the **--autoGame** switch as below:

```
python level9.py --game lords --autoGame
or
python level9.py --game lords --a
```

To test a game and use your own script use the **--script** switch as below:

```
python level9.py --game lords --script test-scripts\lords-of-time-v1.txt
or
python level9.py -g lords --s test-scripts\lords-of-time-v1.txt
```

To see all command line options,, use the command below:

```
python level9.py -h
```

Which will respond with:

```
usage: level9.py [-h] [-d | -m] (-g {adventure,colossal,dungeon,lords,snowball} | -f FILE) [-s SCRIPT | -a]
                 [--logging {info,debug}]
level9.py: error: one of the arguments -g/--game -f/--file is required
PS C:\Users\ajgba\Desktop\lords\level9> python level9.py -h
usage: level9.py [-h] [-d | -m] (-g {adventure,colossal,dungeon,lords,snowball} | -f FILE) [-s SCRIPT | -a]
                 [--logging {info,debug}]

options:
  -h, --help            show this help message and exit
  -d, --dictionary
  -m, --messages
  -g {adventure,colossal,dungeon,lords,snowball}, --game {adventure,colossal,dungeon,lords,snowball}
  -f FILE, --file FILE
  -s SCRIPT, --script SCRIPT
  -a, --autoGame
  --logging {info,debug}
```

## TODO

1. Write up how the compression algorithm seems to work for common word fragments / messages
2. Add a Python UI so it's prepared for the graphics (as an option)

## Level 9 Additional Commands

The interpreter has been extended to include the following commands, mostly for my aid in debugging (these can also be included in script files):

|Command|Description|
| --- | --- | 
|#vars|lists all game variable values|
|#var \<number\>|displays a single game variable value|
|#seed \<number\>|sets the random seed to the value - useful for debugging when a game contains random events|
|#setvar \<number\> \<value\> |Sets variable to the value. Can be decimal or hexadecimal values (0xNN)|
|#setlist \<number\> \<value\> | Set item <number> to <value>. Can be decimal or hexadecimal values (0xNN)|
|#list |lists all the values in the listarea (these can be manipulated with #setlist to e.g. put objects in your current location or inventory)|
|#message \<number\> |print message number|
|#dict / #dictionary  | print the dictionary for the game|

# Level 9 v1 Decompiler

It's not perfect and needs some tidying up and so far the following are available:

* [Adventure Quest](https://github.com/ajgbarnes/level9/blob/main/decompilation/adventure-quest-v1.txt)
* [Colossal Aventure](https://github.com/ajgbarnes/level9/blob/main/decompilation/colossal-adventure-v1.txt)
* [Dungeon Adventure](https://github.com/ajgbarnes/level9/blob/main/decompilation/dungeon-adventure-v1.txt)
* [Lords of Time](https://github.com/ajgbarnes/level9/blob/main/decompilation/lords-of-time-v1.txt)
* [Snowball](https://github.com/ajgbarnes/level9/blob/main/decompilation/snowball-v1.txt)

NOTE - I do have annotated versions of these which are nearing completion.

The supported games can be seen by typing the following on the command line:

```
python decompiler.py --game 
or
python decompiler.py -g
```

And to run a decompilation:

```
python decompiler.py --game <game-name>
or
python decompiler.py -g <game-name>
```

Note that some games will end in error as it runs past the end of the A-Code. Will fix that soon but all of the A-Code is there beforehand.

No compiler yet and the source for compilation would NOT look like this.  This is purely informational which you can use alongside the dictionary and message extraction files to understand the game mechanics.

# BBC Micro Game Common Game Engine 

The engine for the BBC Micro games is more or less common across the 5 supported games - there are a few differences as below. It appears that Lords of Time and Snowball are later manifestations however they are not perfect and introduce some bugs/features.

- For Lords of Time and Snowball, there is a memory checksum generation routine which is not present in my copies of the other games
- For Lords of Time and Snowball, the break handler location is set at the start of fn_init_game and at the end for the rest
- Dungeon Adventure is too big to fit into one file on disk and be loaded - it is split across two with the exits going into the first with some relocation code.  All other data is in the second file and loaded into $1100 onwards by the loader.
- Name of the save file
- Values of some of the junk bytes
- Game code header information - BBC Micro does embed locations of lists, a-code etc.  Pretty much everything but the dictionary which is a hard coded address in the engine.  Shame, it was almost a header but this changes in v2 onwards.
- The Break Handler for Snowball and Lords of Time only prints "Err" whereas it prints "Error" for all the others
- The end memory locations in the save game files for Snowball and Lords of Time are reduced from $0400-$06FF to $0400-$05FF
- Only Colossal Adventure and Adventure Quest use jump tables - the code is latently there however for Snowball / Lords of Time the pushing of A to the stack and pulling it back afterwards was removed.  Looks like a page boundary addition fix
- The clear variables routine (fn_clear_variables) doesn't do anything for Snowball and Lords of Time - it pointlessly loops - it runs into the clear stack routine for these two games
- I don't truly understand the clear stack routine (why it sets the stack pointer to $01E0 or $0180) - will play with that at some point i.e. why not back to higher?

## Common Version 1 Engine & Other TODO

- Tidy up the comments in level9-v1-engine.asm and make them less Lords of Time specific
- Remove the memory locations in the comments for the level9-v1-engine.asm (they are specific to the Lords of Time as that's where I started)
- Proof read the comments and improve in level9-v1-engine.asm   
- Update the memory location tables in the main.asm files as they all reflect Lords of Time right now

## Building the games

Enter the directory for any of the games e.g.

```
cd src\dungeon-adventure
```

To generate the source file(s) outside of a disk image (can be used with the leve9.py interpreter):

```
.\beebasm -i .\main.asm
```

Note for Dungeon Adventure, to use the file, you'll need to use a hex editor and cut and paste the Dungeo1 contents to before the Dungeo2 content and save it. BBC micro had to split these across 2 files for disk access.

To generate a bootable disk image to use with e.g. beebjit or BeebEm.  For all but Dungeon Adventure this should work with the level9.py interpreter.

```
.\beebasm -i .\main.asm -di template.ssd -do Adventure.ssd
.\beebasm -i .\main.asm -di template.ssd -do Colossal.ssd
.\beebasm -i .\main.asm -di template.ssd -do Dungeon.ssd
.\beebasm -i .\main.asm -di template.ssd -do LordsOfTime.ssd
.\beebasm -i .\main.asm -di template.ssd -do Snowball.ssd
```

## Useful References

The following may be useful references when understand the BBC Micro Version code:

1. [BBC Micro Zero Page Variable Usage](https://github.com/ajgbarnes/level9/blob/main/BBC%20Micro%20Variables%20Usage.md)
2. [BBC Micro Level 9 Common Engine](https://github.com/ajgbarnes/level9/tree/main/src/level9-v1-engine)
3. [Level 9 Version 1 A-Code Specifition](https://github.com/ajgbarnes/level9/blob/main/A-Code%20Version%201%20Specification.md)
4. [BBC Micro Compiler Memory Locations](https://github.com/ajgbarnes/level9/blob/main/BBC%20Micro%20Memory%20Locations.md)

A useful reference when understand the BBC Micro code is the BBC Micro Version 1 Compiled Memory Maps alongside the 

Enjoy!

Andy

