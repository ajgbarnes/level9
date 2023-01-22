; Generate Source File:
;    .\beebasm -i .\main.asm 
; Generate bootable disk image:
;    .\beebasm -i .\main.asm -di template.ssd -do Colossal.ssd

config_load_address=$1100
config_checksum_page_loops=$73
config_list_0_start_address=$0000
config_list_1_start_address=$0500
config_list_2_start_address=$1895
config_list_3_start_address=$0580
config_list_4_start_address=$18B5
config_list_5_start_address=$05D0
config_savefile="COLDAT"

; Configuration table
; ~~~~~~~~~~~~~~~~~~~
; Bytes from $7320
; $7320 JMP $7357  - main entry point to game
; $7323 JMP $7B1C  - generate game checksum byte
; $7326 $11        - game load address MSB
; $7327 $73        - number of pages from load address to loop over generating checksum byte
; $7328 $EA        - default value for checksum byte - replaced with checksum
; $7329 $1B90      - a-code start address
; $732B $0000      - not used
; $732D $0400      - variables start address
; $732F $1890      - exits start address
; $7331 $34C0      - messages start address
; $7333 $70D7      - common word fragments start address
; $7335 .....      - inverse direction lookup table
; $7345 .....      - Junk Bytes
; $7349 $0000      - List 0 start address
; $734B $1AA0      - List 1 start address (add $50 so it actually starts at $1AF0)
; $734D $0500      - List 2 start address (add $50 so it actually starts at $1AD0)
; $734F $1B40      - List 3 start address (add $50 so it actually starts at $1B90)
; $7351 $9000      - Unused
; $7353 $0A00      - Unused
; $7357 $0000      - Configuration terminator

; High Level Memory Map 
; ~~~~~~~~~~~~~~~~~~~~~
; $1100 $117F      - Junk bytes
; $1180 $1862      - Dictionary
; $1863 $187F      - Dictionary Junk bytes (after teminator)
; $1890 $1ADF      - Exits
; $1AE0 $1AEF      - Exits Junk bytes (after terminator)
; $1AF0 $1B3F      - List 1 - object default locations ($1AA0 + $50)
; $1B40 $1B8F      - List 3 - ???
; $1B90 $34BF      - A-code
; $34C0 $70D6      - Messages
; $70D7 $731F      - Common word fragments
; $7320 $7322      - Execution entry point
; $7323 $7326      - Checksum entry point
; $7327 $7334      - Game address configuration (see above)
; $7335 $7344      - Inverse direction lookup table
; $7345 $7348      - Junk bytes
; $7349 $734A      - List 0 start address
; $734B $734C      - List 1 start address
; $734D $734E      - List 2 start address
; $734F $7350      - List 3 start address
; $7351 $7354      - Don't appear to be used
; $7355 $7356      - Configuration terminator
; $7357 $7BA9      - Code
; $7BAA $7BB5      - Digits lookup table
; $7BB6 $7BF1      - Command address lookup table
; $7BF1 $7BFF      - Junk bytes (not used)

; $7320            - Jumps to $7351
; $7420            - Execution entry point when called by Coloss1
;                    Jumpes to $7320



org config_load_address
.start
        ; 148 junk bytes
        ; Actually part of a basic program that maybe
        ; Level 9 used to build the game.  Somethin' like:
        ; T%=&2120
        ; IF VER=3 THEN T=&1820
        ; PROGSTART=T
        ; IF VER=1 THEN T=&2860
        ; IF VER=2 THEN T=&3120
        ; IF VER=3 THEN T=&2EDF
        ; DESC_ADDRESS
        EQUB  $54, $3D, $26, $32, $31, $32, $30, $0D
        EQUB  $01, $54, $16, $20, $E7, $20, $56, $45
        EQUB  $52, $3D, $33, $20, $8C, $20, $54, $3D
        EQUB  $26, $31, $38, $32, $30, $0D, $01, $5E
        EQUB  $10, $20, $50, $52, $4F, $47, $53, $54
        EQUB  $41, $52, $54, $3D, $54, $0D, $01, $68
        EQUB  $16, $20, $E7, $20, $56, $45, $52, $3D
        EQUB  $31, $20, $8C, $20, $54, $3D, $26, $32
        EQUB  $38, $36, $30, $0D, $01, $72, $16, $20
        EQUB  $E7, $20, $56, $45, $52, $3D, $32, $20
        EQUB  $8C, $20, $54, $3D, $26, $33, $31, $32
        EQUB  $30, $0D, $01, $7C, $16, $20, $E7, $20
        EQUB  $56, $45, $52, $3D, $33, $20, $8C, $20
        EQUB  $54, $3D, $26, $32, $45, $44, $46, $0D
        EQUB  $01, $86, $13, $20, $44, $45, $53, $43
        EQUB  $5F, $41, $44, $44, $52, $45, $53, $53           

.data_dictionary_start
INCLUDE "objcode-dictionary.asm"

.data_exits_start
INCLUDE "objcode-exits.asm"

.data_list2_start
INCLUDE "objcode-list2.asm"

.data_list4_start
INCLUDE "objcode-list4.asm"

.data_a_code_start
INCLUDE "objcode-a-code.asm"

.data_messages_start
INCLUDE "objcode-messages.asm"

.data_common_word_fragments_start
INCLUDE "objcode-common-word-fragments.asm"

.main_common_source_code
INCLUDE "..\level9-v1-engine\level9-v1-engine.asm"

INCLUDE "objcode-junk-end-of-file.asm"

.end

SAVE "COLOSAL", start, end, fn_other_entry_point