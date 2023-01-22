; Generate Source File:
;    .\beebasm -i .\main.asm 
; Generate bootable disk image:
;    .\beebasm -i .\main.asm -di template.ssd -do Adventure.ssd


; TODO 
config_load_address=$1900
config_checksum_page_loops=$73
config_list_0_start_address=$1504 ; not used during game execution
config_list_1_start_address=$1B9D
config_list_2_start_address=$0500
config_list_3_start_address=$1C18
config_list_4_start_address=$1C40
config_list_5_start_address=$0000
config_savefile="QDAT"

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
        ; Junk bytes (actually BBC Basic to CALL &7300)
        EQUB  $0D, $00, $0A, $0A, $D6, $26, $37, $33
        EQUB  $30, $30, $0D, $FF, $00, $00, $00, $00
        EQUB  $00, $00, $00, $00, $00, $00, $00, $00
        EQUB  $00, $00, $00, $00, $00, $00, $00, $00

.data_exits_start
INCLUDE "objcode-exits.asm"

.data_list1_start
INCLUDE "objcode-list1.asm"

.data_list3_start
INCLUDE "objcode-list3.asm"

.data_list4_start
INCLUDE "objcode-list4.asm"

.data_dictionary_start
INCLUDE "objcode-dictionary.asm"

.data_a_code_start
INCLUDE "objcode-a-code.asm"

.data_messages_start
INCLUDE "objcode-messages.asm"

.data_common_word_fragments_start
INCLUDE "objcode-common-word-fragments.asm"

        ; MODE 7
        ; Send the select screen mode command
        LDA     #$16
        JSR     &FFEE   ; OSWRCH

        ; Send the required screen i.e. MODE 7
        LDA     #$07
        JSR     &FFEE   ; OSWRCH

        LDA     #$0F 
        JSR     $FFF4   ; OSBYTE

        ; Jump to game entry point
        JMP     $7420

        ; Junk bytes - 14       
        EQUB    $00, $00, $00, $00, $00, $00, $00, $00
        EQUB    $00, $00, $00, $00, $00, $00

.main_common_source_code
INCLUDE "..\level9-v1-engine\level9-v1-engine.asm"

INCLUDE "objcode-junk-end-of-file.asm"

.end

SAVE "ADQUEST", start, end, fn_other_entry_point