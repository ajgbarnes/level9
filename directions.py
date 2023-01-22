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
from string import hexdigits

import networkx as nx
import matplotlib.pyplot as plt

from dash import Dash, html
import dash_cytoscape as cyto

app = Dash(__name__)


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
exitsAddr            = int(gameData[args.game]['exitsAddr'],16) - loadAddress
filename             = gameData[args.game]['filename']

directions       = ["North", "North-east", "East", "South", "South-east", "South-west", "West", "North-west", "Up", "Down", "In", "Out", "Cross", "Climb", "Jump"]
reverseDirections = [4,6,7,1,8,2,3,5,10,9,12,11,255,255,15]

edges      = []
edgeLabels = {} 
elements = []


with open(filename,'rb') as fr:
    data=bytearray(fr.read())
    print("Data length:",len(data))

    exitsPointer = exitsAddr

    counter = 1
    currentLocation = 1

    elements.append({'data':{'id':str(255), 'label':str(255)}})
    elements.append({'data':{'id':str(currentLocation), 'label':str(currentLocation)}})

    # Explicit from loc1 to loc2 definitions
    while(data[exitsPointer] != 0 and counter):
        exit            = data[exitsPointer]
        direction       = exit & 0b00001111
        exitLocation    = data[exitsPointer+1]

        # Direction, from, to
        #print(directions[direction-1],hex(currentLocation),hex(exitLocation))
        edges.append([currentLocation, exitLocation])
        edgeLabels.update({(str(currentLocation), str(exitLocation)) : directions[direction-1]})
        elements.append({'data':{'source':str(currentLocation), 'target':str(exitLocation)}})

        # Check to see if this exit can be used for reverse direction lookup
        # If so, then can go from exit to current location the opposite way
        # e.g. if N current to exit location then we can go S 
        # from exit location to current
        if(exit & 0b00010000):
            reverseDirection = reverseDirections[direction-1]
            if(reverseDirection != 255):
                #print(directions[reverseDirection-1],hex(exitLocation),hex(currentLocation))
                edges.append([exitLocation, currentLocation])
                edgeLabels.update({(str(exitLocation), str(currentLocation)) : directions[reverseDirection-1]})
                elements.append({'data':{'source':str(exitLocation), 'target':str(currentLocation)}})


        # Is this the last exit defined for the current location?
        if(exit & 0b10000000):
            currentLocation += 1
            elements.append({'data':{'id':str(currentLocation), 'label':str(currentLocation)}})
        exitsPointer += 2

    graph = nx.DiGraph()
    graph.add_edges_from(edges)

    #pos = nx.spring_layout(graph)
    pos = nx.kamada_kawai_layout(graph)
    nx.draw_networkx(graph,pos=pos)
    #print(edgeLabels)
    #nx.draw_networkx_edge_labels(graph, pos, edge_labels = edgeLabels, font_color='blue')
    #plt.show()

app.layout = html.Div([
   html.P("Dash Locations:"),
   cyto.Cytoscape(
       id='locations',
       elements=elements,
       layout={'name': 'breadthfirst'},
       style={'width': '1500px', 'height': '1500px'}
   )
])


app.run_server(debug=True)    
