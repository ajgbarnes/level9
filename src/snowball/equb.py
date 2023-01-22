


with open('equb.txt', 'r') as file:
    data = file.read()

    charsToRead = 24
    currentPos  = 0

    while(True):
        length = len(data)
        if(currentPos + charsToRead > length):
            eightBytes = data[currentPos:]
        else:
            eightBytes = data[currentPos:currentPos + charsToRead]
        eightBytes = eightBytes.strip()
        eightBytes = eightBytes.replace(" ", ", $")
        eightBytes = "        EQUB  $" + eightBytes
        print(eightBytes)
        currentPos = currentPos + charsToRead
        if(currentPos > length):
            break
