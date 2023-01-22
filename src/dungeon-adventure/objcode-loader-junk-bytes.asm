        ; Junk filler bytes to allow the actual data that 
        ; follows to be stored in $0900+
        EQUB  $00, $00, $00, $00, $00, $00, $00, $00
        EQUB  $00, $00, $00, $00, $00, $00, $00, $00
        EQUB  $00, $00, $00, $00, $00, $00, $00, $00
        EQUB  $00, $00, $00, $00, $00, $00, $00, $00

        EQUB  $00, $00, $00, $00, $00, $00, $00, $00
        EQUB  $00, $00, $00, $00, $00, $00, $00, $00
        EQUB  $00, $00, $00, $00, $00, $00, $00, $00
        EQUB  $00, $00, $00, $00, $00, $00, $00, $00

        EQUB  $00, $00, $00, $00, $00, $00, $00, $00
        EQUB  $00, $00, $00, $00, $00, $00, $00, $00

        ; Junk bytes
        ; Some remanants of a BBC Basic program that would
        ; CALL &7420
        EQUB  $0D, $00, $0A, $0A, $D6, $26, $37, $34
        EQUB  $32, $30, $0D, $FF

        ; Junk bytes
        ; Some old file system values maybe from a testing suite
        ; e.g. $CINT $QTEST5
        EQUB  $00, $45, $20, $24, $43, $49, $4E, $54
        EQUB  $20, $20, $20, $24, $51, $54, $45, $53
        EQUB  $54, $35, $20, $24     