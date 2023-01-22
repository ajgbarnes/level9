; Generate Source File:
;    .\beebasm -i .\main.asm 
; Generate bootable disk image:
;    .\beebasm -i .\main.asm -di template.ssd -do Dungeon.ssd

config_load_address=$0e20
config_checksum_page_loops=$73
config_list_0_start_address=$0000
config_list_1_start_address=$176A
config_list_2_start_address=$0500
config_list_3_start_address=$0000
config_list_4_start_address=$0000
config_list_5_start_address=$0000
config_savefile="DUNDAT"

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

; -----------------------------------------------------------------------------
; Start of Dungeo1
; 
; Note that this game is too big to fit into a single load with a DFS
; as it requires memory from $0E00 to $7BFF so part of the game
; is held here (3 pages of memory) that when this loads to $0800+
; the main game is loaded to $1100+ and then pages from $0900 to $0BFF relocated
; over the DFS working area in $E00 to $10FF. Those pages contain the "exits"
; for the game
; -----------------------------------------------------------------------------
org $0880
.start_loader
        ; Set X and Y to point at the *L.Dungeo2 command
        LDX     #LO(data_oscli_load_dungeo2)
        LDY     #HI(data_oscli_load_dungeo2)

        ; Executive the *LOAD command
        JSR     OSCLI

        ; Counter to copy 3 pages of memory 
        LDY     #$03

        ; The following loop copies a page of memory
        ; from 09FF-0900 to 0EFF-0E00.  Then increments
        ; to 0A00 an 0F00 and copies 
        LDX     #$00
.loop_memory_relocate_page
.data_from_memory
        LDA     $0900,X
.data_to_memory        
        STA     $0E00,X
        DEX
        BNE     loop_memory_relocate_page

        ; Increment to the next "to" page of memory
        INC     data_to_memory+2

        ; Increment to the next "from" page of memory        
        INC     data_from_memory+2

        ; Decrement the loop counter - only want to copy
        ; 3 pages of memory
        DEY

        ; If not all the 3 pages have been copied, loop
        ; back and copy the next page
        BNE     loop_memory_relocate_page 

        ; Clear the text area of the screen
        ; VDU 12
        LDA     #$0C
        JSR     OSWRCH

        ; Main entry point to Dungeo2 - note that if you
        ; change the level9-v1-engine.asm source code you
        ; may have to change this label
        JMP     fn_other_entry_point

.data_oscli_load_dungeo2
        EQUS    "L.Dungeo2"
        EQUB    $0D, $00

INCLUDE "objcode-loader-junk-bytes.asm"

.data_exits_start_loader
INCLUDE "objcode-exits.asm"        

INCLUDE "objcode-loader-junk-end-of-file.asm"
        
.end_loader
SAVE "Dungeo1", start_loader, end_loader, start_loader

; -----------------------------------------------------------------------------
; End of Dungeo1
; -----------------------------------------------------------------------------


; -----------------------------------------------------------------------------
; Start of Dungeo2
; -----------------------------------------------------------------------------
org config_load_address
; This is where exits will get relocation to on load
.data_exits_start


org $1100
.start
        ; Note - no junk header bytes for Dungeon Adventure

.data_dictionary_start
INCLUDE "objcode-dictionary.asm"

.data_list1_start
INCLUDE "objcode-list1.asm"

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

SAVE "Dungeo2", start, end, fn_game_entry_point
; -----------------------------------------------------------------------------
; End of Dungeo2
; -----------------------------------------------------------------------------