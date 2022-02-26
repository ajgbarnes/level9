# Level 9 Python Tools

These are absolutely iconic adventure games for the BBC Micro - always been fascinated by them and how they crammed so much beautiful and eloquent English into so little memory. 

I do not hold the copyright to the original games, only the python programs that inspect and read them. The original game Copyright remains with Level 9.

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
python dictionary.py --game <game-name>
```

To run the dictionary extractor on a particular game, replace "<game-name>" with the name of one listed in the output from the previous command:

```
python dictionary.py --game <game-name>
```

# Descriptions Extractor

A Python program to extract all available game descriptions - including rooms, exits, objects, different object states. 

Each line output will have an description code (in hex), the address in runtime memory where it would be found and the description itself.  Given the way the game engine works, most description are fragments brought together with game engine constants and variable values for lookup.

If you want to derive the file offset instead of the runtime memory address, look in the level9-games.json file and subtract the loadAddress for that game.

The supported games can be seen by typing the following on the command line:

```
python descriptions.py --game <game-name>
```

To run the descriptions extractor on a particular game, replace "<game-name>" with the name of one listed in the output from the previous command:

```
python descriptions.py --game <game-name>
```

# Level 9 v1 Parser / Interpreter

To be released imminently for running Lords of Time in the first instance - needs a little work to run the others - recording of it running through a scripted input game can be found on Youtube showing [Level 9's Lords of Time](https://www.youtube.com/watch?v=epD8R3tzTPk).