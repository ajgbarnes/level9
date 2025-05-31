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

command      = ""
output       = ""
argumentName = ""

# See 
try:
    subprocess.run(pythonInterpreter + " -V", 
                    stdout=subprocess.DEVNULL,
                    stderr=subprocess.DEVNULL)
except:
    pythonInterpreter = "python"

l9Command = pythonInterpreter + " level9.py"
try:
    output = subprocess.run(l9Command, 
                            capture_output=True,
                            text = True)
except Exception as e:
    print("Unable to find the python interpreter or level9.py.")
    print(f"Exception : {e}")
    print(f"Command   : {l9Command}")
    sys.exit(1)

if("usage" not in output.stderr.lower()):
    print(f"Unable to find the python interpreter or level9.py. Return code {e.returncode}")
    sys.exit(1)

outputLines = output.stderr.lower().split("\n")

gamesListIndex = -1
for index, line in enumerate(outputLines):
    if("(-g" in line):
        gamesListIndex = index
        break

if(gamesListIndex == -1 or gamesListIndex > len(outputLines)):
    print("Unable to find games list when running level9.py")
    sys.exit(1)

gamesList = re.sub("{|}", "", outputLines[gamesListIndex]).split()[1].split(",")

for argumentName, wasPassed in vars(args).items():
    if(wasPassed):
        argument = argumentName
        break

if(argument == ""):
    # Should never ever happen but...
    print("No passed argument")
    sys.exit(1)


for game in gamesList:

    command = f"{l9Command} --game {game:12s} --{argument}"
    print("-----------------------------------------------------------------")
    print(f"{command}")
    print("-----------------------------------------------------------------")
    try:
        output = subprocess.run(command, 
                                capture_output=True,
                                text = True)
    except Exception as e:
        print("Error excuting level9.py")
        print(f"Exception : {e}")
        print(f"Command   : {command}")
        sys.exit(1)    
    if(output.returncode !=0):
        print("Error excuting level9.py")
        print(f"Command   : {command}")
        print(output.stderr)
        sys.exit(1)            
    print(output.stdout)
