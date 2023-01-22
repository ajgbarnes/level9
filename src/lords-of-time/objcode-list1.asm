; Initial object locations
; Reference is $1DB0 + $50 + nth object
; Maximum object is + $EB (< $EB)
; There are 156 game objects / NPCs
; 1ea5

;1E00
        ; Game object / NPC initial locations
        EQUB  $FE, $99, $FE, $FE, $FE, $FE, $FE, $53
        EQUB  $3B, $4C, $56, $20, $C6, $36, $77, $7C
        EQUB  $0B, $4A, $53, $14, $55, $75, $01, $23
        EQUB  $B7, $0D, $80, $02, $0D, $48, $36, $3C
        EQUB  $FE, $08, $75, $0F, $46, $FF, $15, $77
        EQUB  $FE, $27, $02, $FE, $D2, $40, $FE, $FE
        EQUB  $FE, $FE, $B1, $FF, $42, $FE, $FE, $A6
        EQUB  $FE, $FE, $FE, $FE, $FE, $B0, $92, $FE
        EQUB  $FE, $3D, $B9, $05, $05, $B0, $0A, $BC
        EQUB  $0A, $FE, $15, $A9, $FE, $92, $FF, $FE
        EQUB  $FF, $02, $03, $03, $DB, $0A, $0C, $16
        EQUB  $19, $26, $2A, $F4, $2C, $5E, $63, $70
        EQUB  $71, $7D, $85, $9D, $9C, $C0, $FE, $BE
        EQUB  $C8, $C9, $18, $1D, $01, $FE, $FF, $FF
        EQUB  $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
        EQUB  $FF, $FE, $1D, $21, $35, $33, $36, $3A
        EQUB  $43, $41, $4A, $4C, $4D, $51, $59, $F4
        EQUB  $FE, $FE, $5E, $FF, $8B, $9A, $9A, $A6
        EQUB  $BD, $13, $25, $7D, $FE, $FE, $FE, $FE
        EQUB  $FE, $FE, $FE, $FE
;1E9C
        ; 479 Junk bytes
        ; First $00 is probably intended as a terminator
        ; for the list but it's never read
        EQUB  $00, $A6, $22, $7C, $08, $4F, $32, $A2
        EQUB  $30, $00, $AF, $22, $7D, $08, $4F, $33
        EQUB  $A2, $30, $00, $C9, $22, $7E, $08, $4F
        EQUB  $34, $A2, $43, $34, $3A, $3B, $43, $41
        EQUB  $52, $52, $59, $20, $43, $41, $50, $41
        EQUB  $43, $49, $54, $59, $00, $D2, $22, $7F
        EQUB  $08, $4F, $35, $A2, $30, $00, $DB, $22
        EQUB  $80, $08, $4F, $36, $A2, $30, $00, $E4
        EQUB  $22, $81, $08, $4F, $37, $A2, $30, $00
        EQUB  $ED, $22, $82, $08, $4F, $38, $A2, $30
        EQUB  $00, $F6, $22, $83, $08, $4F, $39, $A2
        EQUB  $30, $00, $FF, $22, $85, $08, $50, $31
        EQUB  $A2, $30, $00, $08, $23, $86, $08, $50
        EQUB  $32, $A2, $30, $00, $11, $23, $87, $08
        EQUB  $50, $33, $A2, $30, $00, $1A, $23, $88
        EQUB  $08, $50, $34, $A2, $30, $00, $23, $23
        EQUB  $89, $08, $50, $35, $A2, $30, $00, $39
        EQUB  $23, $99, $08, $52, $31, $A2, $43, $31
        EQUB  $3A, $3B, $46, $49, $52, $53, $54, $20
        EQUB  $52, $4F, $4F, $4D, $00, $43, $23, $9A
        EQUB  $08, $52, $32, $A2
;1F40        