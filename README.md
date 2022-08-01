# Level 9 Python Tools

These are absolutely iconic adventure games for the BBC Micro - always been fascinated by them and how they crammed so much beautiful and eloquent English into so little memory. 

I do not hold the copyright to the original games, only the python programs that inspect and read them. The original game Copyright remains with Level 9.

Thank you to David Kinder and Glen Summers for their work on the C Level 9 interpreter.

Feedback and comments are always appreciated to help preserve and understand the internals of this classic.

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

The test scripts used to generate the above walkthroughs were sourced from [David Kinder's Github Level 9 repository](https://github.com/DavidKinder/Level9) and tweaked slightly to work with my parser:

## Extracted Full Game Walkthroughs and Text
* [Adventure Quest Test Script](https://github.com/ajgbarnes/level9/blob/main/full-game-text/adventure-quest-v1.txt)
* [Colossal Aventure Test Script](https://github.com/ajgbarnes/level9/blob/main/full-game-text/colossal-adventure-v1.txt)
* [Dungeon Adventure Test Script](https://github.com/ajgbarnes/level9/blob/main/full-game-text/dungeon-adventure.txt)
* [Lords of Time Test Script](https://github.com/ajgbarnes/level9/blob/main/full-game-text/lords-of-time-v1.txt)
* [Snowball Test Script](https://github.com/ajgbarnes/level9/blob/main/full-game-text/snowball-v1.txt)


# Pre-requisities

[Download this package as a zip file](https://github.com/ajgbarnes/level9/archive/refs/heads/main.zip) and extract somewhere or clone via git.

This should run on any platform that supports Python 3 - I have tried it so far on Windows 10 and MacOS Monterrey. Install the Python 3 interpreter and make sure it's in your PATH for your operating system.

Check you have the right version by typing the following from the command line

```
python --version
```

On some systems, you may have to access the Python 3 by including the version as below - if so all examples later in this note will need to be changed from *python* to *python3*

```
python3 --version
```

# Dictionary Extractor

A Python program to extract the dictionary of commands and objects from the game - this is everything that the game understands. 

Each line output will have an object code (in hex), the address in runtime memory where it would be found and the keyword.  There may be more than one keyword for a particular object code as sometimes synonyms are defined. 

If you want to derive the file offset instead of the runtime memory address, look in the level9-games.json file and subtract the loadAddress for that game.

The supported games can be seen by typing the following on the command line:

```
python dictionary.py --game
```

To run the dictionary extractor on a particular game, replace "\<game-name\>" with the name of one listed in the output from the previous command:

```
python dictionary.py --game <game-name>
```

# Descriptions Extractor

A Python program to extract all available game descriptions - including rooms, exits, objects, different object states. 

Each line output will have an description code (in hex), the address in runtime memory where it would be found and the description itself.  Given the way the game engine works, most description are fragments brought together with game engine constants and variable values for lookup.

If you want to derive the file offset instead of the runtime memory address, look in the level9-games.json file and subtract the loadAddress for that game.

The supported games can be seen by typing the following on the command line:

```
python descriptions.py --game 
```

To run the descriptions extractor on a particular game, replace "\<game-name\>" with the name of one listed in the output from the previous command:

```
python descriptions.py --game <game-name>
```

# Level 9 v1 Parser / Interpreter

To be released imminently for running all v1 BBC Micro games including:

* Adventure Quest
* Colossal Aventure
* Dungeon Adventure
* Lords of Time
* Snowball Test

Needs a code tidy now I understand how it should all work and want to comment as much as possible.

Here is a recording of it running through a scripted input game showing [Level 9's Lords of Time](https://www.youtube.com/watch?v=epD8R3tzTPk).  It currently works with ALL v1 Level 9 games for the BBC Micro.

The supported games can be seen by typing the following on the command line:

```
python parser.py --game
```

This will respond with:

```
PS C:\Users\ajgba\Desktop\lords\level9> python parser.py
usage: parser.py [-h] [--script SCRIPT] [--logging {info,debug}] --game {lords,snowball,colossal,dungeon,dungeon-old,adventure}
parser.py: error: the following arguments are required: --game
```

To run the a particular adventure game, replace "\<game-name\>" with the name of one listed in the output from the previous command:

```
python parser.py --game <game-name>
```

To test a game or see it played out in full, use the **--script** switch as below:

```
python parser.py --game lords --script test-scripts\lords-of-time-v1.txt
```
