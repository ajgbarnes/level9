###############################################################################
# Python Level 9 Bulk Generator / Test Harness
###############################################################################
#
# Written in python for portability rather than say a .bat or .sh file
#
# Useful for testing purposes, it will bulk test all games defined 
# in L9Config.py against the passed switch:
#
# -d/--dictionary - generates all dictionaries for all games
# -m/--messages   - generates all game descriptions for all games
# -e/--exits      - generates all exit definitions for all games
# -a/--autoGame   - runs the tests scripts for all games
#
# Helpful to see if any updates have broken any of the games
#
# Code and comments by Andy Barnes (c) Copyright 2022 (for now)
#
# Twitter @ajgbarnes
#
###############################################################################
import subprocess
import sys
import signal
import argparse
import re

###############################################################################
# signal_handler()
#
# Signal handler for SIGINT (when someone pressses CTRL+C)
# just exits cleanly without an error / stack trace
#
# Parameters: 
#    signum - the signal that was invoked
#    frame  - the frame object
#
# Returns:
#    n/a
###############################################################################
def signal_handler(signum, frame):
    sys.exit(0)


# Handle CTRL+C gracefully
signal.signal(signal.SIGINT, signal_handler)

# Set up the command line argument parser
parser = argparse.ArgumentParser()

# Switch to print the dictionary or messages or exit definitions or run the test scripts
parserGroup = parser.add_mutually_exclusive_group(required=True)
parserGroup.add_argument('-d', '--dictionary', required=False, action='store_true')
parserGroup.add_argument('-m', '--messages'  , required=False, action='store_true')
parserGroup.add_argument('-e', '--exits'     , required=False, action='store_true')
parserGroup.add_argument('-a', '--autoGame'  , required=False, action='store_true')

# Parse the arguments
args = parser.parse_args()  

# Set the default interpreter to python3 (some systems may not have this 
# alias or executable)
pythonInterpreter = "python3"

# Initialise the variables outside of the blocks and set them to be empty strings
command      = ""
output       = ""
argumentName = ""

# Check to see if "python3" is available by running "python3 -v"
# if there's an error, switch to "python" instead
try:
    subprocess.run(pythonInterpreter + " -V", 
                    stdout=subprocess.DEVNULL,
                    stderr=subprocess.DEVNULL)
except:
    pythonInterpreter = "python"

# Prefix the chosen python interpreter to the level9.py script
l9Command = pythonInterpreter + " level9.py"

# Check to see if the level9.py file exists and it's executable without errors
try:
    output = subprocess.run(l9Command, 
                            capture_output=True,
                            text = True)
except Exception as e:
    # Something went wrong, print an error and exit
    print("Unable to find the python interpreter or level9.py.")
    print(f"Exception : {e}")
    print(f"Command   : {l9Command}")
    sys.exit(1)

# Exit if the usage information was not returned 
if("usage" not in output.stderr.lower()):
    print(f"Unable to find the python interpreter or level9.py. Return code {e.returncode}")
    sys.exit(1)

# Split the usage information by lines 
outputLines = output.stderr.lower().split("\n")

# Find the line with the {-g text as it'll have the list of games on it
gamesListIndex = -1
for index, line in enumerate(outputLines):
    if("(-g" in line):
        gamesListIndex = index
        break

# Line should always be found (unless I broke something in the usage information in level9.py)
# however, defensively exit if it wasn't found or the index is too high
if(gamesListIndex == -1 or gamesListIndex > len(outputLines)):
    print("Unable to find games list when running level9.py")
    sys.exit(1)

# 1. Split into multiple lines by spaces
# 2. Get the second line (it'll be the {snowball,lords} line as the first will be the {-g line})
# 3. Replace the {} wrapping brackets around the game list
# 4. Split the games into separate lines by , value
gamesList = re.sub("{|}", "", outputLines[gamesListIndex]).split()[1].split(",")

# Get the arguments / switches that this was started with (will be passed onto level9.py)
for argumentName, wasPassed in vars(args).items():
    if(wasPassed):
        argument = argumentName
        break

# Should never ever happen but... if no argument was found, exit
if(argument == ""):
    print("No passed argument")
    sys.exit(1)

# Iterate over each game
for game in gamesList:

    # Add the game switch and game and argument to the 'python3 leve9.py' command
    command = f"{l9Command} --game {game:12s} --{argument}"

    # Print the header
    print("-----------------------------------------------------------------")
    print(f"{command}")
    print("-----------------------------------------------------------------")

    # Execute the command
    try:
        output = subprocess.run(command, 
                                capture_output=True,
                                text = True)
    except Exception as e:
        # Something went wrong, error and exit
        print("Error excuting level9.py")
        print(f"Exception : {e}")
        print(f"Command   : {command}")
        sys.exit(1)    

    # Check the return code from level9.py was successful (0)
    if(output.returncode !=0):
        # Something went wrong, error and exit
        print("Error excuting level9.py")
        print(f"Command   : {command}")
        print(output.stderr)
        sys.exit(1)            
        
    # Print the output from the command
    print(output.stdout)
