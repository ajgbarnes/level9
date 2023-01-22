; Generate Source File:
;    .\beebasm -i .\main.asm 
; Generate bootable disk image:
;    .\beebasm -i .\main.asm -di .\template.ssd -do .\LordsOfTime.ssd

config_load_address=$1200
config_checksum_page_loops=$73
config_list_0_start_address=$BD2B ; not used during game execution
; Ths is list1_object_initial_locations_start - 80
; as the first object starts at $50 / 80
config_list_1_start_address=$1DB0
config_list_2_start_address=$0500
; Ths is list3_object_score_values_start - 80
; as the first object starts at $50 / 80
config_list_3_start_address=$1EF0
config_list_4_start_address=$1F80
config_list_5_start_address=$0600
config_savefile="TIMEDAT"

; Configuration table
; ~~~~~~~~~~~~~~~~~~~
; Bytes from $7320
; $7320 JMP $7357  - main entry point to game
; $7323 JMP $7B1C  - generate game checksum byte
; $7326 $12        - game load address MSB
; $7327 $73        - number of pages from load address to loop over generating checksum byte
; $7328 $EA        - default value for checksum byte - replaced with checksum
; $7329 $5C20      - a-code start address
; $732B $0000      - not used
; $732D $0400      - variables start address
; $732F $1B00      - exits start address
; $7331 $2083      - messages start address
; $7333 $5A0B      - common word fragments start address
; $7335 .....      - inverse direction lookup table
; $7345 .....      - Junk Bytes
; $7349 $BD2B      - List 0 start address
; $734B $1DB0      - List 1 start address (add $50 so it actually starts at $1AF0)
; $734D $0500      - List 2 start address (add $50 so it actually starts at $1AD0)
; $734F $1F40      - List 3 start address (add $50 so it actually starts at $1B90)
; $7351 $1F80      - Unused
; $7353 $0600      - Unused
; $7357 $0000      - Configuration terminator

; High Level Memory Map 
; ~~~~~~~~~~~~~~~~~~~~~
; $1100 $117F      - Junk bytes
; $1220 $1AF7      - Dictionary
; $1AF7 $1AFF      - Dictionary Junk bytes (after teminator)
; $1B00 $1DB0      - Exits
; $1DB1 $1DFF      - Exits Junk bytes (after terminator)
; $1E00 $1E9C      - List 1 - object default locations 
; $1E9D $1F3F      - List 1 - junk bytes
; $1F40 $1FB8      - List 3 - object score values
; $1FB9 $2082      - List 3 - junk bytes
; $2083 $5A0A      - Messages
; $5A0B $5C1F      - Common word fragments
; $5C20 $731F      - A-code
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


org config_load_address
.start
;1200
        ; 32 junk bytes
        EQUB $00, $00, $00, $00, $00, $00, $00, $00
        EQUB $00, $00, $00, $00, $00, $00, $00, $00
        EQUB $00, $00, $00, $00, $00, $00, $00, $00
        EQUB $00, $00, $00, $00, $00, $00, $00, $00

;1220
.data_dictionary_start
INCLUDE "objcode-dictionary.asm"

;1B00
.data_exits_start
INCLUDE "objcode-exits.asm"

;1E00
.data_list1_start
INCLUDE "objcode-list1.asm"

;1F40
.data_list3_start
INCLUDE "objcode-list3.asm"

;1FDC
.data_list4_start
INCLUDE "objcode-list4.asm"

;2083
.data_messages_start
INCLUDE "objcode-messages.asm"

;5A0B
.data_common_word_fragments_start
INCLUDE "objcode-common-word-fragments.asm"

;5C20 (4A20)
.data_a_code_start
INCLUDE "objcode-a-code.asm"

.main_common_source_code
INCLUDE "..\level9-v1-engine\level9-v1-engine.asm"

; Junk bytes (never used)
INCLUDE "objcode-junk-end-of-file.asm"

.end

SAVE "LORDSOF", start, end, fn_game_entry_point