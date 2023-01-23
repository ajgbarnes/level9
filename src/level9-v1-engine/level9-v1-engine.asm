; Disassembly and annotation of the Level 9 BBC Micro Version 1 A-Code engine
; used in the following games:
;
; - Adventure Quest (1982)
; - Colossal Adventure (1982)
; - Dungeon Adventure (1982)
; - Snowball (1983)
; - Lords of Time (1983)
; 
; Originally written by Level 9 Computing (c) Copyright 1982, 1983
;
; Disassembly labels and comments by Andy Barnes (c) Copyright 2022
;
; Twitter @ajgbarnes

; .\beebdis lords.ctl
; beebasm       
; .\beebjit -debug -0 .\LordsOfTime.ssd
; b <memory>
; blist
; d <memory>
; m <memory>
; bmr <lo> <hi> 

; Input string is read into $0000 onwards
; Then matched dictionray item verb or object code is place in $0000
;
; List Handler opcodes
; --------------------
; Bits 1-4 
; Bit 5
; Bit 6
; Bit 7
; Bit 8 - set
;
; General opcodes
; ---------------
; Bits 1-5 - the opcode function
; Bit 6
; Bit 7
; Bit 8 - not set
; Open or close a file
OSFIND = $FFCE
; Load or save a block of memory to a file 	
OSGBPB = $FFD1
; Save a single byte to file from A
OSBPUT = $FFD4 
; Load a single byte to A from file
OSBGET = $FFD7
; Load or save data about a file
OSARGS = $FFDA
; Load or save a complete file
OSFILE = $FFDD
; Read character (from keyboard) to A
OSRDCH = $FFE0 
; Write a character (to screen) from A plus LF if (A)=&0D
OSASCI = $FFE3
; Write LF,CR (&0A,&0D) to screen 
OSNEWL = $FFE7
; Write character (to screen) from A
OSWRCH = $FFEE
; Perfrom miscellaneous OS operation using control block to pass parameters
OSWORD = $FFF1
; Perfrom miscellaneous OS operation using registers to pass parameters
OSBYTE = $FFF4
; Interpret the command line given 
OSCLI = $FFF7
RESET = $FFFC
SHEILA_6845_address=$FE00
SHEILA_6845_data=$FE01
SHEILA_SYS_VIA_REG_B_CTL=$FE40

OS_ERROR_MSG_PTR=$00FD

BRKV_LSB=$0202
BRKV_MSB=$0203
WRCHV_LSB = $020E
WRCHV_MSB = $020F
IND1V_LSB =$0230
IND1V_MSB =$0231
FSCV_LSB = $021E

zp_general_string_buffer=$0000

zp_file_parameter_block = $0037

zp_input_parameter_block=$0037
zp_digit_pos_lookup_table_lsb=$0037
zp_digit_pos_lookup_table_msb=$0038

zp_digit_found_flag=$0039

zp_number_ascii_code=$003A

zp_digit_pos_lookup_table_offset=$003B


zp_encoded_string_ptr_lsb=$0060
zp_encoded_string_ptr_msb=$0061

zp_current_input_char_lsb=$0062
zp_current_input_char_msb=$0063
zp_chars_on_current_line=$0064

zp_random_seed_lsb=$0068
zp_random_seed_msb=$0069

zp_temp_cache_1=$006A

zp_number_lsb=$006A
zp_temp_cache_2=$006B
zp_number_msb=$006B
zp_temp_cache_3=$006C
zp_temp_cache_4=$006D

zp_opcode_7th_bit=$006E
zp_opcode_6th_bit=$006F

zp_variable_ptr_lsb=$0070
zp_variable_ptr_msb=$0071

; These need to be set to the same locations
; or the code will break
zp_variable_value_lsb=$0072
zp_1st_operand=$0072
zp_jump_table_offset_lsb=$0072
zp_encoded_string_counter_lsb=$0072
zp_random_seed_calc_area_lsb=$072
zp_constant_lsb=$0072

; These need to be set to the same locations
; or the code will break
zp_variable_value_msb=$0073
zp_2nd_operand=$0073
zp_jump_table_offset_msb=$0073
zp_random_seed_calc_area_msb=$073
zp_constant_msb=$0073
zp_encoded_string_counter_msb=$0073

zp_list_ptr_lsb=$0074
zp_cached_ptr_lsb=$0074
zp_list_ptr_msb=$0075
zp_cached_ptr_msb=$0075
zp_jump_table_entry_offset_lsb=$0074
zp_jump_table_entry_offset_msb=$0075

zp_input_string_buffer_ptr_lsb=$0076
zp_input_string_buffer_ptr_msb=$0077

zp_input_words_count=$0078

zp_current_word_ptr_lsb=$7A
zp_current_word_ptr_msb=$7B


zp_dictionary_ptr_lsb=$007C
zp_dictionary_ptr_msb=$007D
zp_exits_ptr_lsb=$007C
zp_exits_ptr_msb=$007D

; Zero Page
zp_a_code_ptr_lsb=$0080
zp_a_code_ptr_msb=$0081

zp_dictionary_start_lsb=$0082
zp_dictionary_start_msb=$0083

zp_cmd_and_obj_pointer_lsb=$84
zp_cmd_and_obj_pointer_msb=$85

zp_temp_cache_5=$0086
zp_from_location=$0086
zp_curr_input_char_cache=$86
zp_temp_cache_6=$0087
zp_move_direction=$0087

zp_to_location=$0088
zp_inverse_direction_counter=$0088

; *******************************************************
; NOTE: Comments and memory locations before labels
;       are specific to Lords of Time
; *******************************************************


;7320
.fn_game_entry_point
        ; -----------------------------------------------
        ; Game entry point - called after load
        ; Just jumps to the initialisation routine
        ; -----------------------------------------------
        JMP     fn_init_game

IF config_savefile = "TIMEDAT" OR config_savefile = "SNOWDAT"
;7323
.fn_calc_checksum_byte
        ; This does not have a known caller 

        ; This appears to be some maybe protection mechanism
        ; as it takes a checksum into $7328 of an addition
        ; of all the bytes between $1200 and $72FF inclusive.
        ; Maybe the protection code was in $1200 originally?
        JMP     fn_get_data_checksum

;7326
        ; Start page MSB for fn_get_data_checksum
        ; LSB is initially set to $00 
.data_checksum_start_page_msb             
        EQUB    HI(config_load_address)

;7327
.data_checksum_loop_counter_max
        ; Number of pages of memory to loop around starting
        ; at the page MSB above (config_load_address)
        EQUB    config_checksum_page_loops

;7328
.data_calculated_checksum
        ; Data Checksum value 
        ; (dictionary, lists, a-code, common word fragments
        ; and the 6502 code)
        EQUB    $EA
ENDIF

;7329
.data_a_code_address_lsb
        ; Set to $5C20, the start of the virtual machine
        ; commands
        EQUB    LO(data_a_code_start)
.data_a_code_address_msb
        EQUB    HI(data_a_code_start)

;732B
        EQUB    $00, $00
        ; Variables memory address
;732D
.data_variables_start_address_lsb
        EQUB    $00
;732E
.data_variables_start_address_msb   
        EQUB    $04

        ; Exits memory address
        ; Set to $1B00
;732F
.data_location_exits_address_lsb
        EQUB    LO(data_exits_start)
;7330
.data_location_exits_address_msb
        EQUB    HI(data_exits_start)

        ; Encoded/compressed descriptions start address
        ; Set to $2083
;7331
.data_messages_address_lsb
        EQUB    LO(data_messages_start)
.data_messages_address_msb
        EQUB    HI(data_messages_start)      

        ; Common word fragments start address
        ; Set to $5A0B
;7333
.data_common_word_fragments_address_lsb
        EQUB    LO(data_common_word_fragments_start)
.data_common_word_fragments_address_msb
        EQUB    HI(data_common_word_fragments_start)

;7335
.data_inverse_directions_table
        ; Byte not used
        EQUB     $00
        ; South - opposite of North ($01)
        EQUB     $04
        ; South West - opposite of North East ($02)
        EQUB     $06
        ; West - opposite of East ($03)
        EQUB     $07
        ; North - opposite of South ($04)
        EQUB     $01
        ; North West - opposite of South East ($05)
        EQUB     $08
        ; South West - opposite of North East ($06)
        EQUB     $02
        ; East - opposite of West ($07)
        EQUB     $03
        ; South East - opposite of North West ($08)
        EQUB     $05
        ; Down - opposite of Up ($09)
        EQUB     $0A
        ; Up - opposite of Down ($0A)
        EQUB     $09
        ; Out - opposite of In ($0B)
        EQUB     $0C
        ; In - opposite of Out ($0C)
        EQUB     $0B
        ; No opposite for Cross ($0D)
        EQUB     $FF
        ; No opposite for Climb ($0E)
        EQUB     $FF
        ; Jump - opposite for Jump ($0F) 
        EQUB     $0F

;7345
IF config_savefile = "TIMEDAT"
        ;Junk bytes
        EQUB    $49
        EQUB    $4C
        EQUB    $45
        EQUB    $24
ELIF config_savefile = "QDAT"
        ;Junk bytes
        EQUB    $F0
        EQUB    $14
        EQUB    $FA
        EQUB    $15
ELIF config_savefile = "DUNDAT"
        ;Junk bytes
        EQUB    $00
        EQUB    $00
        EQUB    $C0
        EQUB    $00        
ELSE
        ;Junk bytes
        EQUB    $00
        EQUB    $00
        EQUB    $00
        EQUB    $00
ENDIF

; 7349
.data_list_location_lookup_table
        EQUB    LO(config_list_0_start_address)
        EQUB    HI(config_list_0_start_address)

;734B
        ; List 1 - Lords of Time - Current object location
        ;
        ; Bug/feature
        ; ~~~~~~~~~~~
        ; Feature: An object's current location is actually stored 
        ; between $0550 + object offset as the game A-code adds
        ; $50 onto the address
        EQUB    LO(config_list_1_start_address)
        EQUB    HI(config_list_1_start_address)          

;734D             
        ; List 2 - Lords of Time - Initial object location
        ;  
        ; Bug/feature
        ; ~~~~~~~~~~~
        ; Feature: The actual list starts at $1E00 and
        ; as the game A-code adds $50 + object number offset
        ; onto the address
        EQUB    LO(config_list_2_start_address)
        EQUB    HI(config_list_2_start_address)

;734F
        ; List 3 - Lords of Time -  
        ; Value of object. Either $00, $01, or $03
        ; If less than $02, not counted in the "score" command
        ; and nor does "It's a valuable treasure" get added 
        ; to its description when examined. Values actually
        ; start at $1Ef0 + object id (min value $50) so
        ; from $1F40 onwards to $1FDB
        EQUB    LO(config_list_3_start_address)
        EQUB    HI(config_list_3_start_address)     

;7351
        ; Unknown / unused list 4
        EQUB    LO(config_list_4_start_address)
        EQUB    HI(config_list_4_start_address)

;7353
        ; Unknown / unused list 5
        EQUB    LO(config_list_5_start_address)
        EQUB    HI(config_list_5_start_address)


;7355
        ; End of lists
        EQUB    $00, $00

;7357
.fn_init_game

IF config_savefile = "TIMEDAT" OR config_savefile = "SNOWDAT"
        ; Set the BRKV handler
        ; for when a BRK instruction is 
        ; executed - handler is at $7AAA
        LDA     #LO(fn_brkv_handler)
        STA     BRKV_LSB
        LDA     #HI(fn_brkv_handler)
        STA     BRKV_MSB
ENDIF

        ; Reset the A-code pointer ($80/$81) to the start
        ; of the A-code ($5C20)
        LDA     data_a_code_address_lsb
        STA     zp_a_code_ptr_lsb 
        LDA     data_a_code_address_msb
        STA     zp_a_code_ptr_msb

        ; Store the (encoded) dictionary location
        ; $1120 in $82/$83 - these variables never
        ; change during the game
        LDA     #LO(data_dictionary_start)
        STA     zp_dictionary_start_lsb
        LDA     #HI(data_dictionary_start)
        STA     zp_dictionary_start_msb

        ; Switch paged mode off ($0F)
        LDA     #$0F
        JSR     fn_write_char_to_screen

        ; Reset the input string buffer pointer 
        ; to $0000, the start of the buffer
        JSR     fn_reset_next_char_pointer

        ; Reset the number of characters written to the
        ; current line to zero
        LDA     #$00
        STA     zp_chars_on_current_line

        ; Colossal cave puts the setting of the break handler here 
        ; whilst the others have and the start of this fn
IF config_savefile != "TIMEDAT" AND config_savefile != "SNOWDAT"
        ; Set the BRKV handler
        ; for when a BRK instruction is 
        ; executed - handler is at $7AAA
        LDA     #LO(fn_brkv_handler)
        STA     BRKV_LSB
        LDA     #HI(fn_brkv_handler)
        STA     BRKV_MSB
ENDIF        

;737F
.jump_to_a_code_virtual_machine 
        JSR     loop_a_code_virtual_machine

;7382
.loop_a_code_virtual_machine
        ; -----------------------------------------------
        ; Main A-code virtual machine
        ; -----------------------------------------------

        ; Set the carry flag
        SEC

        ; This is clever - once the current opcode command or 
        ; list handler has been called, the virtual machine 
        ; wants to call itself again to process the next opcode
        ; command or list handler. So it subtracts 3 from
        ; the return address (which is normally after the JSR xxyy)
        ; to make it the say JSR xxyy.  So this will set the RTS
        ; address back to 737F (.jump_to_a_code_virtual_machine)
        ; above.  The return address is on the stack so it reads it
        ; from there (LSB/MSB) and subtracts 3 and then writes it back
        PLA
        SBC     #$03
        TAX
        PLA
        SBC     #$00
        PHA
        TXA
        PHA

        ; Get the next A-code opcode
        JSR     fn_get_next_a_code_byte

        ; Push the A-code opcode onto the stack to 
        ; preserve it whilst it's manipulated below
        PHA

        ; Get the 7th bit of the opcode
        ; $40 = 64 = 0100 0000
        AND     #$40

        ; Store the A-code opcode's 7th bit
        ; TODO - why
        STA     zp_opcode_7th_bit

        ; Restore the A-code opcode
        PLA

        ; Push the A-code opcode onto the stack to 
        ; preserve it whilst it's manipulated again
        PHA        

        ; Get the 6th bit of the opcode
        ; $20 = 32 = 0010 0000
        AND     #$20

        ; TODO
        ; Store the A-code opcode's 6th bit 
        ; This is used to indicate how many operands
        ; a command has:
        ;
        ; 0 - two operands
        ; 1 - single operand
        STA     zp_opcode_6th_bit

        ; Restore the A-code opcode (again)
        PLA

        ; Check if the 8th bit is set on the A-code opcode
        ; If it is, then it's a list handler opcode
        ; otherwise it's a general opcode
        CMP     #$7F

        ; Branch to the opcode handler if it's not set
        BCC     fn_process_general_opcode

        ; It's set

        ; Branch to the list handler
        JMP     fn_list_handler

;73A3
.fn_process_general_opcode
        ; ---------------------------------------
        ; General opcode handler - look up the
        ; function to call based on the command
        ; lookup table and call it by returning
        ; from this function
        ; (the Stack will hold the function address
        ; so returning will "return" to the command)
        ; ---------------------------------------

        ; Bottom five bits are the command to execute
        ; Keep the bottom 5-bits by ANDing with $1F / 0001 1111 
        AND     #$1F

        ; Multiple by 2
        ; Lookup table is two byte for each routine 
        ; so times by 2 to correctly aligned to the 
        ; right lookup table entry
        ASL     A

        ; Store the index into the lookup table in Y
        TAY

        ; Add 1 - as the MSB will be retrieved first
        ; then the LSB - easier to put the address on the
        ; stack in that order.  Address will be 
        ; "returned to" when the RTS executes
        INY

        ; Lookup the address of a routine in a lookup table
        ; based on the value 
        LDA     data_cmd_lookup_table,Y
        PHA

        ; Get the LSB 
        DEY
        LDA     data_cmd_lookup_table,Y
        PHA

        ; Looked up routine will be called when the return (RTS)
        ; is executed - goes to the <address>+1 when it returns
        ; e.g. address might be $7909 but continues execution
        ; at $790A
        RTS             
        
;73B2
.fn_write_char_to_screen
        ; ---------------------------------------
        ; Writes the passed character to the screen 
        ; if it is a character.  
        ;
        ; If it's a carriage return ($0D) then it will only
        ; be output if there are 2 or more characters
        ; already written to the current screen row
        ;
        ; If it's a space ($20) the it will only be output
        ; if a non-space character has already been 
        ; written to the screen. This stops unnecessary
        ; spaces appearing at the start of a line.
        ; ---------------------------------------
        
        ; Check to see if a carriage return
        ; has been sent
        CMP     #$0D
        BNE     no_carriage_return

        ; Display a CR

        ; Check to see if less than 2 characters have 
        ; been written to the current line of text - if
        ; so don't write the carriage return
        LDA     zp_chars_on_current_line
        CMP     #$02
        BCC     end_write_char_to_screen

        ; Write LF and CR (ASCII $OD) to the screen
        ; Send $OD to OSASCI causes both a LF and CR
        ; to be sent to the screen
        LDA     #$0D
        JSR     OSASCI

        ; Return - CR/LF written to screen
        RTS
        
;73C2
.no_carriage_return
        ; Check to see if a space was passed in 
        ; ASCII $20
        CMP     #$20
        BNE     print_char_or_space

        ; Space was passed

        ; If no characters have been written to the current
        ; line do NOT write a space
        LDA     zp_chars_on_current_line
        CMP     #$00
        BEQ     end_write_char_to_screen

        ; Not at the start of the line

        ; Write a space (ASCII $20) to the screen
        LDA     #$20
;73CE
.print_char_or_space
        ; Write the space or character to the current line
        JSR     OSASCI

;73D1
.end_write_char_to_screen
        ; Return having written a character
        ; or skipped
        RTS      


;73D2
.fn_generate_random_seed
        ; -------------------------------------------
        ; Generates a new random seed for game events
        ; using a complicated algorithm
        ;
        ; Javascript of python equivalent would be:
        ;
        ; ((((((oldSeed << 8) + 0x0A) - oldSeed) << 2) + oldSeed) + 1) & 0xFFFF
        ; -------------------------------------------


        ; Load the old random seed's previous LSB (ignore the MSB) from $68
        ; newSeed = oldSeed << 8
        LDA     zp_random_seed_lsb

        ; Put the previous random seed LSB into the new randomm seed MSB
        STA     zp_random_seed_calc_area_msb

        ; Set the new random seed LSB to $0A
        ; Note this gets replaced with the right calc after this
        ; newSeed = newSeed + 0x0A
        LDA     #$0A
        STA     zp_random_seed_calc_area_lsb

        ; The next five 6 intructions basically perform:
        ; newSeed = newSeed - oldSeed

        ; Subtract the old random seed LSB from the new seed LSB
        SEC
        SBC     zp_random_seed_lsb
        STA     zp_random_seed_calc_area_lsb

        ; Subtract the old seed MSB from the new seed MSB
        ; newSeed = newSeed + ((oldSeed & 0xFF) - 0x0A)
        LDA     zp_random_seed_calc_area_msb
        SBC     zp_random_seed_msb
        STA     zp_random_seed_calc_area_msb

        ; Next 14 instructions peform the equivalent of 
        ; CLC
        ; ROL   zp_random_seed_calc_area_lsb
        ; ROL   zp_random_seed_calc_area_msb
        ; CLC
        ; ROL   zp_random_seed_calc_area_lsb
        ; ROL   zp_random_seed_calc_area_msb
        ;
        ; newSeed = newSeed << 2
        
        ; First half of the instructions
        ; CLC
        ; ROR   zp_random_seed_calc_area_lsb
        ; ROR   zp_random_seed_calc_area_msb
        ; newSeed = newSeed << 1
        LDA     zp_random_seed_calc_area_lsb
        CLC
        ADC     zp_random_seed_calc_area_lsb
        STA     zp_random_seed_calc_area_lsb
        LDA     zp_random_seed_calc_area_msb
        ADC     zp_random_seed_calc_area_msb
        STA     zp_random_seed_calc_area_msb

        ; Second half of the instructions
        ; CLC
        ; ROR   zp_random_seed_calc_area_lsb
        ; ROR   zp_random_seed_calc_area_msb
        ; newSeed = newSeed << 1
        ; (so now each byte rotated left twice)
        LDA     zp_random_seed_calc_area_lsb
        CLC
        ADC     zp_random_seed_calc_area_lsb
        STA     zp_random_seed_calc_area_lsb
        LDA     zp_random_seed_calc_area_msb
        ADC     zp_random_seed_calc_area_msb
        STA     zp_random_seed_calc_area_msb

        ; Add the old seed onto the new seed
        ; newSeed = newSeed + oldSeed
        LDA     zp_random_seed_calc_area_lsb
        CLC
        ADC     zp_random_seed_lsb
        STA     zp_random_seed_calc_area_lsb
        LDA     zp_random_seed_calc_area_msb
        ADC     zp_random_seed_msb
        STA     zp_random_seed_calc_area_msb

        ; Add one to the new seeed
        ; newSeed = newSeed + 1

        ; Add one to the old seed LSB first
        LDA     zp_random_seed_calc_area_lsb
        CLC
        ADC     #$01
        STA     zp_random_seed_calc_area_lsb

        ; Add any carry to the new seed MSB
        LDA     zp_random_seed_calc_area_msb
        ADC     #$00
        STA     zp_random_seed_calc_area_msb

        ; Move the values from the new seed
        ; working area and overwrite the old seed 
        ; with them
        LDA     zp_random_seed_calc_area_msb
        STA     zp_random_seed_msb
        LDA     zp_random_seed_calc_area_lsb
        STA     zp_random_seed_lsb

        ; Set the value of the variable to this value
        JSR     fn_set_variable_value

        RTS          

IF config_savefile="COLDAT" OR config_savefile = "DUNDAT"
        ; For some reason it has this junk byte defined
        EQUB    $00
ELIF config_savefile="QDAT"        
        ; For some reason it has this junk byte defined
        EQUB    $50
ENDIF
.fn_other_entry_point
; 7425
        ; Not used ! Never called! 
        JMP     fn_game_entry_point

;7428
.fn_save_game
        ; Create the file parameter block (filename, save from/toaddress etc)
        ; in memory
        JSR     fn_create_file_parameter_block

        ; OSFILE A=0/$00
        ; Save named file 
        ; XY contain the address of the 
        ; file block, in this case at $0037
        ; (see function abovefor details of block)

        ; Set the OSFILE operation to "save block of memory"
        LDA     #$00

        ; Set the file parameter block location to $00
        TAY

        JMP     set_param_block_lsb_and_call_osfile

;7431
.fn_load_game
        JSR     fn_create_file_parameter_block

        ; OSFILE A=255/$FF
        ; Load named file 
        ; XY contain the address of the 
        ; file block, in this case at $0037
        ; (see function abovefor details of block)
        LDA     #$FF

        ; Sets Y to $00
        LDY     #HI(zp_file_parameter_block)

.set_param_block_lsb_and_call_osfile
        LDX     #LO(zp_file_parameter_block)
        JSR     OSFILE

        ; Return once file loaded
        RTS

;743E
.fn_create_file_parameter_block
        ; ---------------------------------------
        ; Creates the OSFILE parameter block
        ; for loading the save game file into 
        ; memory. 
        ;
        ; The OSFILE parameter block is set up
        ; at $0037 though to $0048 (17)
        ; ---------------------------------------

        ; Set the address of the save game file 
        ; name which is held at $746D
        ; $0037 = $6D
        ; $0038 = $74
        LDA     #LO(data_save_game_file_name)
        STA     zp_file_parameter_block

        LDA     #HI(data_save_game_file_name)
        STA     zp_file_parameter_block+1
        
        ; Set the file load address to $0400
        ; (well $FFFF0400)
        ; Sets $0039 and $003C
        ; $0039 = $00
        ; $003A = $04
        ; $003B = $FF
        ; $003C = $FF
        LDA     #$00
        STA     zp_file_parameter_block+2


        LDA     #$04
        STA     zp_file_parameter_block+3

        LDX     #$FF
        STX     zp_file_parameter_block+4
        STX     zp_file_parameter_block+5

        ; Don't set the file execution address
        ; as it doesn't get executed so 
        ; $003D - $0040 are undefined here

        ; Set the file length to $0400 TODO CHECK
        ; (and pad the other two variables $43/$44 with $FF)
        ; $0041 = $00
        ; $0042 = $04
        ; $0043 = $FF
        ; $0044 = $FF
        LDA     #$00
        STA    zp_file_parameter_block+10

        LDA     #$04
        STA     zp_file_parameter_block+11
        STX     zp_file_parameter_block+12
        STX     zp_file_parameter_block+13
        
        ; Set the end address to $06FF or $05FF
        ; (and pad the other two
        ; variables $47/$48 with $FF)        
        ; $0045 = $00
        ; $0046 = $04
        ; $0047 = $04
        ; $0048 = $04
        LDA     #$FF
        STA     zp_file_parameter_block+14

IF config_savefile = "TIMEDAT" OR config_savefile = "SNOWDAT"
        LDA     #$06
ELSE
        LDA     #$05        
ENDIF        
        STA     zp_file_parameter_block+15
        STX     zp_file_parameter_block+16
        STX     zp_file_parameter_block+17

        ; OSFILE parameter block set up
        RTS        

;746D
.data_save_game_file_name
        EQUS    config_savefile
        EQUB    $0D
        EQUB    $0D
        EQUB    $00

IF config_savefile = "COLDAT" OR config_savefile = "DUNDAT"
        ; Add a byte because COLDAT is shorter than
        ; SNOWDAT or TIMEDAT.  QDAT also only needs
        ; an extra byte
        EQUB    $00
ELIF config_savefile = "QDAT"
        EQUB    $00
        EQUB    $00
        EQUB    $00
ENDIF

;7477
.fn_cmd_printnumber
        ; -----------------------------------------------
        ; Virtual Machine A-code operator 3 ($03) - printnumber
        ;
        ; This has the following A-code format:
        ;     <operator> <operand> 
        ; 
        ; <operator> (bits 1-5) = $03 / 00011
        ; <operator> (bit  6  ) = not used
        ; <operator> (bit  7  ) = not used
        ; <operator> (bit  8  ) = 0 (to indicate a command)
        ;
        ; <operand> - variable containing the number to print
        ; 
        ; Bug/feature
        ; ~~~~~~~~~~~
        ; After calling fn_get_a_code_variable_number A contains the 
        ; lower 8-bit value of the variable and 
        ; the code unnecessarily retrieves it again
        ; 
        ; 1. Get the 16-bit value of the variable in the <operand>
        ; 2. MSB goes into X 
        ; 3. LSB goes into Y 
        ; 4. Print routine called
        ; -----------------------------------------------
        JSR     fn_get_a_code_variable_number

        ; At this point, A contains the lower 8-bit value of the variable 
        ; (not the full 16-bit value) and $70/$71 contain the address 
        ; of the 16-bit variable

        ; Load the lower 8-bits (unnecessary as A holds this already)
        LDY     #$00
        LDA     (zp_variable_ptr_lsb),Y

        ; Store it on the stack 
        PHA

        ; Get the top 8-bits of the variable
        INY
        LDA     (zp_variable_ptr_lsb),Y

        ; MSB of the variable value goes into X
        TAX

        ; Restore the lower 8-bits into A
        PLA

        ; LSB of the variable value goes into Y
        TAY

        ; Call the routine to actually print the 
        ; number
        JSR     fn_actually_printnumber

        ; Number printed
        RTS

;7489
.fn_decode_encoded_string
        ; -------------------------------------
        ; Takes the index to the current encoded string
        ; and processes each byte one at a time
        ; adding to the string buffer at $0000
        ;
        ; 1. If the byte is less than $03 it's 
        ;    assumed to be the encoded string terminator,
        ;    decoding stops and processing ends
        ; 2. If the byte is >= $5E it's assumed 
        ;    to be an embedded common word
        ;    fragment and that is similarly 
        ;    recursively processed before completing
        ;    the current word - the common word lookup index
        ;    is worked out by subtracting $5E from the
        ;    value when processing it
        ; 3. If it's between $02 and $5D then it
        ;    has $1D added to it so it's in the 
        ;    ASCII printable range and adds to the buffer
        ; 4. If it's a % it will add a CR to the buffer
        ;    If it's a _ it will add a space to the buffer
        ; -------------------------------------

        ; Get the current encoded string byte
        LDY     #$00
        LDA     (zp_encoded_string_ptr_lsb),Y

        ; Check it's greater than 2 otherwise treat
        ; as a valid encoded byte not a terminator
        CMP     #$03

        ; If it's >2 then process it, it's not a terminator
        BCS     loop_check_and_add_char_to_string_buffer

        ; Terminator reached
        RTS

;7492
.loop_check_and_add_char_to_string_buffer
        ; Cache on the stack the current index position of where
        ; the encoded string is being processed
        ;
        ; This is important because if the current byte is 
        ; a reference to another encoded string
        ; then that one needs to be processed before the rest
        ; of this one
        LDA     zp_encoded_string_ptr_lsb
        PHA
        LDA     zp_encoded_string_ptr_msb
        PHA

        ; Is it a reference to another encoded string (>=$5E)
        ; If so, process the referenced encoded string before
        ; continuing with this one
        LDA     (zp_encoded_string_ptr_lsb),Y
        CMP     #$5E
        BCS     fn_process_embedded_encoded_string

        ; Printable character, not another encoded string
        
        ; Add $1D to align it to the printable ASCII range
        CLC
        ADC     #$1D

        ; Check the current character, transform it if it's
        ; a "%" into a CR or "_" into a space, and add
        ; to the string buffer at $0000+.  Also checks
        ; line width has not been exceeded and adds a CR
        ; if it has.
        ;
        ; It does NOT write it to the screen
        JSR     fn_check_char_and_add_to_string_buffer

;74A4
.continue_with_encoded_string

        ; Restore the memory address index of 
        ; the encoded string
        PLA
        STA     zp_encoded_string_ptr_msb
        PLA
        STA     zp_encoded_string_ptr_lsb

        ; Increment to the next encoded string
        ; byte by adding 1 to the LSB
        LDA     zp_encoded_string_ptr_lsb
        ADC     #$01
        STA     zp_encoded_string_ptr_lsb

        ; If there was a carry add it onto the MSB
        LDA     zp_encoded_string_ptr_msb
        ADC     #$00
        STA     zp_encoded_string_ptr_msb
        JMP     fn_decode_encoded_string

;74B9
.fn_process_embedded_encoded_string
        ; A value >= $5E means that the current
        ; byte refers to another encoded string

        ; To determine which nth common word fragment encoded
        ; string is required, subtract $5E () to get to n
        SEC
        SBC     #$5E
        STA     zp_encoded_string_counter_lsb

        ; Reset the msb to zero 
        LDA     #$00
        STA     zp_encoded_string_counter_msb

        ; Put the address of the common word fragments
        ; encoded string lookup into $60/$61 - 
        ; this starts at $5A0B

        ; Reset the index to the start of the
        ; common word fragment encoded strings
        LDA     data_common_word_fragments_address_lsb
        STA     zp_encoded_string_ptr_lsb

        ; Reset the index to the start of the
        ; encoded string
        LDA     data_common_word_fragments_address_msb
        STA     zp_encoded_string_ptr_msb

        ; Find the nth common word fragment - "n" is
        ; defined in zp_encoded_string_counter_lsb/msb
        JSR     fn_find_nth_common_word_fragment

        ; Process the new common word fragment until it's
        ; complete
        JSR     fn_decode_encoded_string

        ; Revert back to the previous common word fragment
        ; now the newly referenced common word fragment
        ; has been processed 
        JMP     continue_with_encoded_string

;74D5
.fn_find_nth_game_description
        ; -------------------------------------
        ; Starts at the beginning of the encoded/compressed
        ; game descriptions area of memory and loops
        ; through until it finds the nth description.
        ; Each encoded game description is separated by 
        ; a $01 byte
        ;
        ; "n" is defined in the 
        ; zp_encoded_string_counter_lsb/msb
        ; -------------------------------------
        LDA     data_messages_address_lsb
        STA     zp_encoded_string_ptr_lsb
        LDA     data_messages_address_msb
        STA     zp_encoded_string_ptr_msb

        ; Continues below

;74DF
.fn_find_nth_common_word_fragment
.loop_find_nth_encoded_string
        ; -------------------------------------
        ; This piece of code has two entry points
        ; and will yield a different result depending
        ; on that:
        ; 
        ; fn_find_nth_game_description
        ; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        ; Loops through the game descriptions memory
        ; starting at $2083 which is held in 
        ; zp_encoded_string_ptr_lsb/msb ($60/$61)
        ; until it finds the nth description. 
        ; Each encoded game description is separated by 
        ; a $01 byte        
        ;
        ; fn_find_nth_common_word_fragment
        ; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        ; Loops through the game descriptions memory
        ; starting at $5A0B which is held in 
        ; zp_encoded_string_ptr_lsb/msb ($60/$61)
        ; until it finds the nth description. The
        ; memory location is set by the caller.
        ; Each encoded common word fragment is separated 
        ; by a $01 byte        

        ; Check to see if the encoded string counter 
        ; has reached zero or if the code still needs to loop
        ; looking for the next encoded string 
        LDA     zp_encoded_string_counter_lsb
        ORA     zp_encoded_string_counter_msb

        ; IF the counter is still greater than zero,
        ; branch ahead
        BNE     check_current_encoded_string_byte

        ; Counter zero

        ; At this point the zp_encoded_string_ptr_lsb/msb
        ; will point to the start of the encoded string
        ; that was requested - it can now be printed to the 
        ; screen (note it is still encoded)
        RTS

;74E6
.check_current_encoded_string_byte
        ; Loop through the encoded strings - each
        ; encoded string is separated by a $01.  This needs
        ; to happen n times where n is defined
        ; by the values held in $72/$73
        ;

        ; Load the next encoded string
        LDY     #$00
        LDA     (zp_encoded_string_ptr_lsb),Y

        ; Is it a separator ($01)
        CMP     #$01

        ; Push the result and processor status onto the stack
        ; (result is used after the index is incremented)
        PHP

        ; Move to the next encoded string byte
        ; by adding 1 to the LSB and any carry to to
        ; the MSB address

        ; Add one to the LSB
        LDA     zp_encoded_string_ptr_lsb
        CLC
        ADC     #$01
        STA     zp_encoded_string_ptr_lsb

        ; Add the carry to the MSB
        LDA     zp_encoded_string_ptr_msb
        ADC     #$00
        STA     zp_encoded_string_ptr_msb

        ; Restore the processor status so the comparison
        ; from earlier can be used
        PLP

        ; If the current byte is not a separator ($01)
        ; loop back to inspect the next byte
        BNE     loop_find_nth_encoded_string


        ; Current byte is a separator ($01)

        ; Found a separator so decrement the counter

        ; Subtract one from the counter LSB
        LDA     zp_encoded_string_counter_lsb
        SEC
        SBC     #$01
        STA     zp_encoded_string_counter_lsb

        ; Subtract any borrow from the MSB
        LDA     zp_encoded_string_counter_msb
        SBC     #$00
        STA     zp_encoded_string_counter_msb
        
        ; Start looking for the next separator
        JMP     loop_find_nth_encoded_string
        
;750D
.fn_check_char_and_add_to_string_buffer

        ; Check the current character, transform it if it's
        ; a "%" into a CR or "_" into a space, and add
        ; to the string buffer at $0000+.  Also checks
        ; line width has not been exceeded and adds a CR
        ; if it has.
        ;
        ; It does NOT write it to the screen


        ; Is it a percent (%) symbol (ASCII $25)
        ; if so add a CR/lF to the screen otherwise
        ; branch ahead
        CMP     #$25
        BNE     check_if_underscore

        ; It's a percent symbol

        ; This will add a newline to the screen
        ; instead of a percent symbol
        LDA     #$0D
;7513
.check_if_underscore
        ; Is it an underscore (_) character (ASCII $5F), 
        ; if so it'll be replaced with a space
        CMP     #$5F
        BNE     check_if_carriage_return

        ; It's an underscore

        ; Replace it with a space on screen
        LDA     #$20
;7519
.check_if_carriage_return
        ; Reset the Y index counter to zero
        LDY     #$00

        ; Add a CR/LF to the screen
        CMP     #$0D
        BEQ     fn_write_string_and_then_start_new_line

        ; If it's a space, check it fits on the current
        ; line otherwise put a CR/LF in
        CMP     #$20
        BEQ     fn_check_string_fits_on_current_line

        ; continues below

;7523
.fn_write_char_to_string_and_move_to_next_char
        ; Write the current value in the accumulator
        ; to the string buffer - this could be either
        ; a character or command 
        LDY     #$00
        STA     (zp_current_input_char_lsb),Y

        ; continues below

;7527
.fn_move_to_next_char_memory_address
        ; -------------------------------------
        ; Adds one to the current character's
        ; memory address (moves to the next
        ; character in the decoded string or where
        ; to write the next character)
        ; -------------------------------------

        ; Load the LSB for the current character
        LDA     zp_current_input_char_lsb
        
        ; Clear carry
        CLC

        ; Add one to the LSB 
        ADC     #$01
        STA     zp_current_input_char_lsb

        ; If it went across a page boundary
        ; increment the address's MSB
        LDA     zp_current_input_char_msb
        
        ; Add the carry if there was any from the LSB
        ADC     #$00

        ; Store the MSB again
        STA     zp_current_input_char_msb
        RTS

;7535
.fn_write_string_and_then_start_new_line

        ; Write the current string (held at $0000 onwards)
        ; to the screen (assuming it fits, otherwise start
        ; a new line)
        JSR     fn_check_string_fits_on_current_line

        ; String has been written - now start a new line
        LDA     #$0D
        JSR     fn_write_char_to_screen

        ; Reset the number of characters on the current
        ; line to zero
        LDA     #$00
        STA     zp_chars_on_current_line

        ; Reset the string character pointer to the start
        ; of the string buffer ($0000)
        JSR     fn_reset_next_char_pointer

        LDA     #$00
        TAY
        STA     (zp_current_input_char_lsb),Y
        RTS


;754A
.fn_reset_next_char_pointer
        ; ---------------------------------------
        ; Reset the input string buffer pointer 
        ; to $0000, the start of the buffer
        ; ---------------------------------------

        ; Set the LSB at $62 to $00
        LDA     #$00
        STA     zp_current_input_char_lsb

        ; Set the MSB at $63 to $00
        LDA     #$00
        STA     zp_current_input_char_msb

        ; All done...
        RTS

;7553
.fn_check_string_fits_on_current_line
        ; ---------------------------------------
        ; Gets the current string length, adds
        ; it to the number of characters already
        ; written to this line and sees if it will
        ; fit - if so it's written out, if not
        ; a CR/LF will be written, resets number
        ; of characters on this line and prints
        ; the string
        ; ---------------------------------------

        ; Add a string terminator ($00) to the string 
        ; buffer (which starts at $0000) and move to the 
        ; next character
        LDA     #$00
        JSR     fn_write_char_to_string_and_move_to_next_char

        ; Never seems to do anything? Setting
        ; carry and then subtracting zero
        ; from the string length (the LSB points
        ; to just after the string terminator for
        ; the current string so it acts as a string
        ; length + 1 for the space after the word
        ; given it starts at $0000)
        LDA     zp_current_input_char_lsb
        SEC
        SBC     #$00

        ; Clear the carry flag
        CLC

        ; Add the string length plus 1 for the following
        ; space to the number of characters already on the
        ; line 
        ADC     zp_chars_on_current_line

        ; Check to see if more less than 39 ($27) characters
        ; have written to the screen - branch ahead to
        ; write the characters if less than 39
        CMP     #$27
        BCC     reset_next_char_pointer_to_start

        ; 39 or more characters have been written to the screen
        
        ; Write a CR and LF to the screen to move to the next line
        LDA     #$0D
        JSR     fn_write_char_to_screen

        ; Reset the number of characters on the current line 
        ; to zero
        LDA     #$00
        STA     zp_chars_on_current_line
;756D
.reset_next_char_pointer_to_start
        ; Move the string character pointer to the start of
        ; the string so it can be written to the screen
        JSR     fn_reset_next_char_pointer

        ; Continues to print all string characters below

;7570
.fn_print_next_char
        ; ---------------------------------------------
        ; Prints the next string character to the 
        ; screen or, if a string terminator, resets
        ; the string character pointer to the start of 
        ; the buffer, writes a string terminator into the
        ; first position and writes a space to the screen
        ;
        ; Note calls itself until all the current string
        ; characters are printed to the screen - recursion!
        ; ---------------------------------------------

        ; Get the next string character - the memory
        ; location incremented to point to the next
        ; character
        LDY     #$00
        LDA     (zp_current_input_char_lsb),Y

        ; Check to see if the character is a NUL ($00)
        ; This indicates that it is the end of the
        ; current string - so branch away and get the 
        ; reset the character pointer and write a 
        ; space to the screen
        CMP     #$00
        BEQ     fn_reset_next_char_ptr_and_write_space

        ; Not a NUL ($00) string terminator

        ; Write the character to the screen
        JSR     fn_write_char_to_screen

        ; Increase the number of characters written
        ; to the current line on the screen
        INC     zp_chars_on_current_line
        
        ; Move to the next character in memory
        JSR     fn_move_to_next_char_memory_address

        ; Print the next string character (if any)
        JMP       fn_print_next_char

;7583
.fn_reset_next_char_ptr_and_write_space
        ; ---------------------------------------------
        ; Resets the string character pointer to $0000
        ; and puts a string terminator there ($00). 
        ; Also write a space to the screen
        ; ---------------------------------------------

        ; Finished processing the current string
        ; so reset the string character pointer
        ; to the start of the string buffer i.e. $0000
        JSR     fn_reset_next_char_pointer

        ; Write a string terminator ($00) to the start of
        ; the string buffer to indicate there isn't currently
        ; a decoded string in there
        LDA     #$00
        TAY
        STA     (zp_current_input_char_lsb),Y

        ; Write a space to the screen
        LDA     #$20
        JSR     fn_write_char_to_screen

        ; Increase the count of characters that have been
        ; written to the current line on the screen
        INC     zp_chars_on_current_line

        ; All done...
        RTS    

;7593
.fn_cmd_messagev
        ; -----------------------------------------------
        ; Virtual Machine A-code opcode 4 ($04) - messagev
        ;
        ; This has the following A-code format:
        ;     <operator> <operand> 
        ; 
        ; <operator> (bits 1-5) = $04 / 00100
        ; <operator> (bit  6  ) = not used
        ; <operator> (bit  7  ) = not used
        ; <operator> (bit  8  ) = 0 (to indicate a command)
        ;
        ; <operand>   - Variable number that contains message id
        ; 
        ; Prints a messge based on the value held in a variable.
        ; The variable number that holds the message id is held 
        ; in an operand
        ;
        ; Used to print things like room directions
        ; in (through a door), north, south etc based
        ; in your own living room
        ; You can see
        ; [a fine golden hourglass] [on the mantlepiece]
        ; a picture of a kindly old man
        ; -----------------------------------------------

        ; Reads the operand which contains the variable 
        ; number to check.  Each variable is 16-bit and its
        ; memory location is calcuated using:
        ; Address = 2 * value + $0400. 
        ;
        ; zp_variable_ptr_lsb/msb ($70/$71) contain the address of the
        ; variable's lower 8-bits
        ; 
        ; The lower 8-bits of the variable's value are
        ; returned in A
        JSR     fn_get_a_code_variable_number

        ; Store the LSB of the value in $72
        ; This is the lower 8-bits of the 16-bit message id
        STA     zp_encoded_string_counter_lsb

        ; Get the next value from the workspace
        ; and store in the second byte of the 
        ; message id - 73
        INY
        LDA     (zp_variable_ptr_lsb),Y
        STA     zp_encoded_string_counter_msb

        ; A is now used as the nth string to display
        ; when the string is printed - "n" is stored
        ; in zp_encoded_string_counter_lsb/msb ($72/$73)        

        ; Use those values to find the memory
        ; location of the nth string to display
        ; "n" is determined by the value in 
        ; zp_encoded_string_counter_lsb/msb ($72/$73)
        ;
        ; The encoded string address will be placed in 
        ; zp_encoded_string_ptr_lsb/msb ($60/$61)
        JSR     fn_find_nth_game_description

        ; Decode and add the nth game description to 
        ; the string buffer ($0000) and write it 
        ; to the screen
        JSR     fn_decode_encoded_string

        ; Variable's message id printed
        RTS

;messagec
;75A4
.fn_cmd_messagec
        ; -----------------------------------------------
        ; Virtual Machine A-code opcode 4 ($05) - messagec
        ;
        ; This has the following A-code format:
        ;     <operator> <operand1> [<operand2>]
        ;
        ; <operand2> is only present if the 7th bit is zero
        ; 
        ; <operator> (bits 1-5) = $05 / 00110
        ; <operator> (bit  6  ) = not used
        ; <operator> (bit  7  ) = 0 (two operands) or 1 (one operand)
        ; <operator> (bit  8  ) = 0 (to indicate a command)
        ;
        ; <operand1>   - single byte that contains the 8-bit message id 
        ;                OR
        ;                LSB of the 16-bit message id
        ; [<operand2>] - MSB of the 16-bit message id
        ;
        ; The 7th bit of the opcode indicates:
        ;     1 - single byte offset (relative plus or
        ;         minus from the current A-code execution
        ;         address)
        ;     0 - double byte offset (absolute offset 
        ;         from the start of the A-code)
        ; 
        ; Used to print a message

        ; Following the operator in the a-code, there
        ; will either be followed by one or two bytes to 
        ; denote the nth message that should be found 
        ; and written to the screen.  So either an 8-bit
        ; or 16-bit message id. If the command code has 
        ; its 7th bit set then it has one byte, if not set 
        ; then two
        ; 
        ; Bytes will be placed in 
        ; zp_encoded_string_counter_lsb/msb ($72/$73)
        JSR     fn_get_a_code_opcode_operands

        ; Find the start memory address of the nth
        ; game description
        ;
        ; Memmory adress will be placed in 
        ; zp_encoded_string_ptr_lsb/msb ($60/$61)
        ; when it returns
        JSR     fn_find_nth_game_description

        ; Decode and add the nth game description to 
        ; the string buffer ($0000) and write it 
        ; to the screen
        JSR     fn_decode_encoded_string

        ; Message printed
        RTS

;75AE
.fn_cmd_add_var1_to_var2
        ; -----------------------------------------------
        ; Virtual Machine A-code operator 10 ($0A) - _add
        ;
        ; This has the following A-code format:
        ;     <operator> <operand1> <operand2>
        ;
        ; <operator> (bits 1-5) = $0A / 01010
        ; <operator> (bit  6  ) = not used
        ; <operator> (bit  7  ) = not used
        ; <operator> (bit  8  ) = 0 (to indicate a command)
        ;
        ; <operand1> - First variable to be updated
        ; <operand2> - Second variable that will be added to the first variable
        ;
        ; Adds the second variable's value to the first and stores in the first
        ;
        ; variable1 = variable2 + variable1
        ; -----------------------------------------------

        ; Reads the operand which contains the first variable's number
        ; Each variable is 16-bit and its memory location is calcuated using:
        ;    Address = 2 * value + $0400. 
        ;
        ; zp_variable_ptr_lsb/msb ($70/$71) contain the address of the
        ; variable's lower 8-bits
        ; 
        ; The lower 8-bits of the variable's value are
        ; returned in A
        JSR     fn_get_a_code_variable_number

        ; Moves the variable's memory address in $70/$71 into $74/$75
        ; which is zp_cached_ptr_lsb/msb
        JSR     fn_copy_memory_address_ptr

        ; Reads the operand which contains the second variable's number
        ; Each variable is 16-bit and its memory location is calcuated using:
        ;     Address = 2 * value + $0400. 
        ;
        ; zp_variable_ptr_lsb/msb ($70/$71) contain the address of the
        ; variable's lower 8-bits
        ; 
        ; The lower 8-bits of the variable's value are
        ; returned in A
        JSR     fn_get_a_code_variable_number

        ; Add the LSB value of the second variable to the LSB
        ; value of the first variable and store in the first variable
        LDY     #$00
        LDA     (zp_cached_ptr_lsb),Y
        CLC
        ADC     (zp_variable_ptr_lsb),Y
        STA     (zp_variable_ptr_lsb),Y

        ; Add the MSB value of the second variable to the MSB
        ; value of the first variable and store in the first variable
        INY
        LDA     (zp_cached_ptr_lsb),Y
        ADC     (zp_variable_ptr_lsb),Y
        STA     (zp_variable_ptr_lsb),Y

        ; Addition complete - first variable updated
        RTS

;75CE
.fn_cmd_subtract_var2_from_var1
        ; -----------------------------------------------
        ; Virtual Machine A-code operator 11 ($0B) - _sub
        ;
        ; This has the following A-code format:
        ;     <operator> <operand1> <operand2>
        ;
        ; <operator> (bits 1-5) = $0B / 01011
        ; <operator> (bit  6  ) = not used
        ; <operator> (bit  7  ) = not used
        ; <operator> (bit  8  ) = 0 (to indicate a command)
        ;
        ; <operand1> - First variable to be updated
        ; <operand2> - Second variable that will be added to the first variable
        ;
        ; Subtract the first variable from the second variable and store in the
        ; second variable 
        ;
        ; variable2 = variable2 - variable1
        ; -----------------------------------------------

        ; Reads the operand which contains the first variable's number
        ; Each variable is 16-bit and its memory location is calcuated using:
        ;    Address = 2 * value + $0400. 
        ;
        ; zp_variable_ptr_lsb/msb ($70/$71) contain the address of the
        ; variable's lower 8-bits
        ; 
        ; The lower 8-bits of the variable's value are
        ; returned in A
        JSR     fn_get_a_code_variable_number

        ; Moves the variable's memory address in $70/$71 into $74/$75
        ; which is zp_cached_ptr_lsb/msb
        JSR     fn_copy_memory_address_ptr

        ; Reads the operand which contains the second variable's number
        ; Each variable is 16-bit and its memory location is calcuated using:
        ;     Address = 2 * value + $0400. 
        ;
        ; zp_variable_ptr_lsb/msb ($70/$71) contain the address of the
        ; variable's lower 8-bits
        ; 
        ; The lower 8-bits of the variable's value are
        ; returned in A
        JSR     fn_get_a_code_variable_number

        ; Subtract the LSB value of the first variable from the LSB
        ; value of the first variable and store in the first variable
        LDA     (zp_variable_ptr_lsb),Y
        SEC
        SBC     (zp_cached_ptr_lsb),Y
        STA     (zp_variable_ptr_lsb),Y

        ; Subtract the MSB value of the first variable from the MSB
        ; value of the first variable and store in the first variable
        INY
        LDA     (zp_variable_ptr_lsb),Y
        SBC     (zp_cached_ptr_lsb),Y
        STA     (zp_variable_ptr_lsb),Y

        ; Addition complete - first variable updated
        RTS

;75E0
.fn_cmd_jump
        ; -----------------------------------------------
         ; Virtual Machine A-code operator 14 ($0D) - jump
        ;
        ; This has the following A-code format:
        ;     <operator> <operand1> <operand2> <operand3>
        ; 
        ; <operand3> is only present if the 6th bit is zero
        ;
        ; <operator> (bits 1-5) = $0D / 01110
        ; <operator> (bit  6  ) = not used
        ; <operator> (bit  7  ) = not used
        ; <operator> (bit  8  ) = 0 (to indicate a command)
        ;
        ; <operand1> - LSB of the 16-bit offset in A-code to the jump table
        ; <operand2> - MSB of the 16-bit offset in A-code to the jump table
        ; <operand3> - nth entry in the jump table that is required
        ;
        ; Sets a variable to an 8-bit or 16-bit constant
        ; -----------------------------------------------
        ;
        ; Get the nth entry <operand3> from the specified
        ; jump table <operand1> and <operand2> and jump to that
        ; address

        ; Retrieve the 16-bit a-code offset for the jump
        ; table - this is specified in operand1 and operand2
        ; and the function stores this is in $72/$73
        ; This is the relative start position of the jump table
        ; from the start of the A-code
        JSR     fn_get_a_code_opcode_operands

        ; Get the jump table offset into the A-code
        ; This is the position in the jump table. A contains
        ; the variable's LSB value on return
        JSR     fn_get_jump_table_offset

        ; Multiply the nth jump table number by 2 
        ; to get the offset as each address is 2 bytes (LSB / MSB) 
        ASL     A

        ; Cache the processor status
        PHP

        ; Store the jump table offset LSB ($74)
        STA     zp_jump_table_entry_offset_lsb
        LDA     #$00

        ; Retrieve the processor status
        PLP

        ; Check to see if the carry flag was set
        ; so the jump table offset was greater than 128
        ; when multipled by 2 - so set the MSB to 1
        BCC     set_jump_table_offset

        ; Set the jump table offset MSB to 1
        LDA     #$01

.set_jump_table_offset
        ; Save the jump table MSB as either 0 or 1 into $75
        STA     zp_jump_table_entry_offset_msb

        ; Add the jump table offset to the a-code offset
        ; this gets a relative offset to the jump table
        ; entry from the start of the A-code

        ; Load the jump table LSB ($74)
        LDA     zp_jump_table_entry_offset_lsb

        ; Add the jump table offset LSB ($72) to the entry offset LSB ($74)
        ; and store in the jump table offset 
        CLC
        ADC     zp_jump_table_offset_lsb
        STA     zp_jump_table_offset_lsb

        ; Add the jump table offset MSB ($73) to the entry offset MSB ($75)
        ; and store in the jump table offset 
        LDA     zp_jump_table_entry_offset_msb
        ADC     zp_jump_table_offset_msb
        STA     zp_jump_table_offset_msb

        ; Add the A-code start address to the jump table offset - this
        ; gives the absolute memory address of the jump table entry

        ; Add the A-code absolute start address LSB to the 
        ; jump table relative entry 
        LDA     zp_jump_table_offset_lsb
        CLC
        ADC     data_a_code_address_lsb
        STA     zp_jump_table_offset_lsb

        ; Add the A-code absolute start address LSB to the 
        ; jump table relative entry 
        LDA     zp_jump_table_offset_msb
        ADC     data_a_code_address_msb
        STA     zp_jump_table_offset_msb

        ; Now read the the jump table entry - this tells us where to 
        ; jump to.  Get the LSB first.  It's relative to the start
        ; of the A-code
        LDA     (zp_jump_table_offset_lsb),Y

        ; Add the absolute A-code start address LSB and add it to the relative
        ; jump code LSB
        CLC
        ADC     data_a_code_address_lsb

        ; Preserve the registers
        PHP

        ; Update the A-code pointer LSB ($80) to the jump address LSB
        STA     zp_a_code_ptr_lsb

        ; Add one to the absolute address so the MSB of the jump address
        ; can be read (could have just done an INY...)
        LDA     zp_jump_table_offset_lsb
        CLC
        ADC     #$01
        STA     zp_jump_table_offset_lsb

        ; Add any carry from the LSB to the MSB
        LDA     zp_jump_table_offset_msb
        ADC     #$00
        STA     zp_jump_table_offset_msb

        ; Now read the the MSB of the jump table entry 
        ; It's relative to the start of the A-code
        LDA     (zp_jump_table_offset_lsb),Y

        ; Get the processor registers
        PLP

        ; Add the A-code start address to get the absolute address
        ; in memory of where to jump to
        ADC     data_a_code_address_msb

        ; Update the A-code pointer MSB to the jump address MSB
        STA     zp_a_code_ptr_msb

        ; Jump to that address
        RTS

;762E
.fn_list_handler
        ; -----------------------------------------------
        ; Virtual Machine A-code List Handler
        ;
        ; This has the following A-code format:
        ;     <operator> <operand1> <operand2>
        ; 
        ; <operator> (bits 1-5) = List number to handle (up to 32)
        ; <operator> (bit  6  ) = see below
        ; <operator> (bit  7  ) = see below
        ; <operator> (bit  8  ) = 1 (to indicate it's handling lists)
        ;
        ; Bit 7 Bit 6 List Handler Value
        ; ----- ----- ------------ -----
        ;   1     1    listvv       $Ex
        ;   1     0    listv1c      $Cx
        ;   0     1    listv1v      $Ax
        ;   0     0    listcv1      $8x
        ;
        ; If listvv:
        ;
        ;    <operand1> - variable number that indicates which list item to set 
        ;    <operand2> - variable number to get value of and
        ;                 to set list item to
        ;         
        ;    list[variable[<operand1>]] = variable[<operand2>]
        ;
        ; If listv1c:
        ;
        ;    <operand1> - indicates which list item value to get
        ;    <operand2> - variable to set to list item value
        ;      
        ;    variable[<operand2>] = list[<operand1>]
        ;
        ; If listv1v:
        ;
        ;    <operand1> - list item to set
        ;    <operand2> - variable value to get
        ;
        ;    variable[<operand2>] = list[variable[<operand1>]]
        ;
        ; If listcv1:
        ;
        ;    <operand1> - indicates which list item value to set
        ;    <operand2> - variable value to get value of and
        ;                 to set list item to
        ;    
        ;    list[<operand1>] = variable[<operand2>]
        ;
        ; Notes on lists:
        ; 1. A list is either reference data or runtime
        ;    variable data
        ; 2. A reference data list is e.g. starting location
        ;    of all game objects
        ; 3. A runtime variable data list is e.g. current
        ;    location of all game objects
        ;
        ; -----------------------------------------------

        ; Check to see if this needs the listvv handler
        ; Sets nth list item to a variable value
        CMP     #$E0
        BCS     fn_list_handler_listvv

        ; Check to see if this needs the listv1c handler
        CMP     #$C0
        BCS     fn_list_handler_listv1c

        ; Check to see if this needs the listv1v handler
        CMP     #$A0
        BCS     fn_list_handler_listv1v

        ; Defaults to listcv1 so this is really
        ; fn_list_handler_list_c1v

        ; Bits 1-5 indicate the list number so 
        ; remove the top 3 bits and leave the remianing 
        ; bits
        SEC
        SBC     #$80

        ; Get the list start address and hold it in $74/$75
        JSR     fn_list_get_start_address

        ; Get the constant and store in $72/$73
        ; Constant is a single byte so MSB will be set to $00
        JSR     fn_get_a_code_opcode_operand_single_byte

        ; Use the constant just retrieved as the offset into
        ; the list and set that entry to <operand2>'s variable's
        ; value
        JMP     fn_list_set_nth_list_entry_to_variable_value

;7646
.fn_list_handler_listvv
        ; -----------------------------------------------
        ; Sets the nth entry of the desired list to 
        ; the value of variable x
        ;
        ; list[nth entry]=variable[x]
        ; -----------------------------------------------

        ; Bits 1-5 indicate the list number so 
        ; remove the top 3 bits and leave the remianing 
        ; bits
        SEC
        SBC     #$E0

        ; Get the list start address and hold it in $74/$75
        JSR     fn_list_get_start_address

        ; Get the next operand which indicates which 
        ; nth entry in the list should be changed
        ; Read the variable value
        ; Set $70/$71 to the address of the variable
        ; Set $72/$73 to the variable value, which represents
        ; the nth entry in the list 
        JSR     fn_get_operand_variable_value

        ; Continues

;764F
.fn_list_set_nth_list_entry_to_variable_value

        ; Each entry in a list is 8-bits / 1 byte
        ; so to get the nth entry from the 
        ; start address just add the offset
        ; in $72/$73 to the start address 
        ; in $74/$75
        JSR    fn_list_add_offset_to_list_start_address

        ; Get the next operand which indicates which variable value
        ; to get.  This nth list entry will be set to this value.
        ; Read the variable value
        ; Set $70/$71 to the address of the variable
        ; Set $72/$73 to the variable value
        JSR     fn_get_a_code_variable_number

        ; Store the variable value in the nth
        ; list entry 
        LDY     #$00
        STA     (zp_list_ptr_lsb),Y

        ; nth list entry value set to variable value
        RTS

;765A
.fn_list_handler_listv1c
        ; -----------------------------------------------
        ; Sets the value of variable x to the value of the
        ; nth entry of the desired list
        ;
        ; variable[x] = list[nth entry]
        ; -----------------------------------------------

        ; Bits 1-5 indicate the list number so 
        ; remove the top 3 bits and leave the remianing 
        ; bits
        SEC
        SBC     #$C0

        ; Get the list start address and hold it in $74/$75
        JSR     fn_list_get_start_address

        ; Get the constant and store in $72/$73
        ; Constant is a single byte so MSB will be set to $00
        JSR     fn_get_a_code_opcode_operand_single_byte

        ; Get the nth list entry        
        JMP     fn_list_get_nth_list_entry_and_set_variable

;7666
.fn_list_handler_listv1v
        ; -----------------------------------------------
        ; Sets the value of variable y to the value of the
        ; nth entry of the desired list.  The nth entry
        ; of the list is held in variable[x].
        ;
        ;    variable[y] = list[variable[x]]
        ; -----------------------------------------------

        ; Bits 1-5 indicate the list number so 
        ; remove the top 3 bits and leave the remianing 
        ; bits
        SEC
        SBC     #$A0

        ; Get the list start address and hold it in $74/$75
        JSR     fn_list_get_start_address
        
        ; Get the next operand which indicates which variable value
        ; to get.  This will be used to index the list to get the nth
        ; entry.  This is variable[x] above.
        ; Read the variable value
        ; Set $70/$71 to the address of the variable
        ; Set $72/$73 to the variable value
        JSR     fn_get_operand_variable_value

        ; Continues below

;766F
.fn_list_get_nth_list_entry_and_set_variable

        ; Each entry in a list is 8-bits / 1 byte
        ; so to get the nth entry from the 
        ; start address just add the offset
        ; in $72/$73 to the start address 
        ; in $74/$75
        JSR     fn_list_add_offset_to_list_start_address

        ; Get the next operand which indicates which variable value
        ; to set.  This will be set to the value of the nth list entry 
        ; Read the variable value
        ; Set $70/$71 to the address of the variable
        ; Set $72/$73 to the variable value
        JSR     fn_get_a_code_variable_number

        ; Get the value of the nth list entry LSB
        LDA     (zp_list_ptr_lsb),Y

        ; Store the nth list entry LSB in the variable
        STA     (zp_variable_ptr_lsb),Y
        
        ; List values are 8-bit / single byte 
        ; so set the MSB of the variable to $00
        LDA     #$00
        INY
        STA     (zp_variable_ptr_lsb),Y
        RTS

;767F
.fn_get_operand_variable_value
        ; -------------------------------------------
        ; Performs the following:
        ; 1. Gets the next <operand>
        ; 2. Operand is the variable number value to retieve
        ; 3. Variable value address is in $70/$71
        ; 3. Gets variables value and stores in $72/$73
        ; -------------------------------------------

        ; Reads the operand which contains the variable 
        ; number who's value is the list item to update
        ; Each variable is 16-bit and its
        ; memory location is calcuated using:
        ; Address = 2 * value + $0400
        ;
        ; zp_variable_ptr_lsb/msb ($70/$71 will contain
        ; the address of the variable's lower 8-bits)
        ; 
        ; The lower 8-bits of the variable's value are
        ; returned in A   
        JSR     fn_get_a_code_variable_number 

        ; Store the LSB of the variable's value in $72
        STA     zp_variable_value_lsb

        ; Increment the idex to 1
        INY

        ; Read the MSB of the variable's value
        LDA     (zp_variable_ptr_lsb),Y

        ; Store the MSB of the variable's value in $73
        STA     zp_variable_value_msb

        RTS

;768A
.fn_list_get_start_address
        ; -----------------------------------------------
        ; Lookup the list start address
        ; The list addresses are held at $7349/A onwards
        ; and the list number * 2 is used to index the entry
        ; as each address is 2 bytes.
        ;
        ; List start address is held in $74/$75 on return
        ; -----------------------------------------------

        ; Multiply the list number by 2
        ; as the list location lookup table
        ; contains an LSB/MSB for each 
        ; list address
        ASL     A

        ; Use the multipled number as the 
        ; index into the lookup table to 
        ; get the nth list address
        TAX

        ; Get the list start address LSB ($7349)
        LDA     data_list_location_lookup_table,X

        ; Store the list start address LSB
        STA     zp_list_ptr_lsb

        ; Get the list start address MSB ($734A)
        LDA     data_list_location_lookup_table+1,X
        
        ; Store the list start address MSB
        STA     zp_list_ptr_msb
        RTS

;7697
.fn_list_add_offset_to_list_start_address
        ; -----------------------------------------------
        ; The offset is the nth entry in the list so it
        ; adds the offset to the list start address to 
        ; get the address of the nth entry.
        ;
        ; Each list entry is only 8-bits / 1 byte
        ;
        ; $75/$75 set to the address of the nth entry on 
        ; return
        ; -----------------------------------------------

        ; Get the list start address LSB ($74)
        LDA     zp_list_ptr_lsb
        CLC

        ; Add the value of the variable LSB that was read
        ; to get to the offset in the list
        ADC     zp_variable_value_lsb

        ; Store the result
        STA     zp_list_ptr_lsb

        ; Get the list start address msb
        LDA     zp_list_ptr_msb
 
        ; Add the value of the variable MSB that was read
        ; to get to the offset in the list
        ADC      zp_variable_value_msb

        ; Store the result
        STA     zp_list_ptr_msb

        ; Offset absolute address calculated
        RTS

;76A5
.fn_cmd_intgosub
        ; -----------------------------------------------
        ; Virtual Machine A-code opcode 1 ($01) - intgosub
        ;
        ; This has the following A-code format:
        ;     <operator> <operand1> [<operand2>]
        ;
        ; <operand2> is only present if the 6th bit is zero
        ; 
        ; <operator> (bits 1-5) = $01 / 00001
        ; <operator> (bit  6  ) = 0 (two operands) or 1 (one operand)
        ; <operator> (bit  7  ) = not used
        ; <operator> (bit  8  ) = 0 (to indicate a command)
        ;
        ; <operand1>   - single byte relative signed offset (-127 to +128) 
        ;                OR
        ;                LSB of the absolute offset to add to the A-code start address
        ; [<operand2>] - MSB of the absolute offset to add to the A-code start address
        ; 
        ; Puts the current A-code execution address on the stack
        ; +1 or +2 depending on whether this has a single or double
        ; operands - this is indicated by the 6th bit of the opcode.
        ; It puts this under the return address on the stack so it 
        ; can be read by the return instruction when it executes.
        ;
        ; The 6th bit of the opcode indicates:
        ;     1 - one operand - single byte offset (relative plus or
        ;         minus from the current A-code execution
        ;         address)
        ;     0 - two operands - double byte offset (absolute offset 
        ;         from the start of the A-code)
        ;
        ;
        ; On entry the stack contains the return address of the entry point
        ; back into the main virtual machine loop ($737E but will
        ; have one added to it when an RTS is executed so $737F
        ; or .jump_to_a_code_virtual_machine)
        ; -----------------------------------------------

        ; Gets the return address from the stack 
        ; and temporarily caches in $86/$87
        PLA
        STA     zp_temp_cache_5
        PLA
        STA     zp_temp_cache_6

        ; Assume two operands until we check
        LDX     #$02

        ; If the 6th bit is set, there is only one operand
        ; (single byte offset), it i's set to zero it's two
        ; operands.
        LDA     zp_opcode_6th_bit
        CMP     #$00
        BEQ     calc_a_code_return_address 

        ; Single operand so decrement X as only 1 needs to be
        ; added to the current A-code execution address to get the
        ; address of the next instruction - this is where a "return"
        ; instruction will execute from
        DEX
;76B4
.calc_a_code_return_address
        ; Store X in zero page ($6A)
        STX     zp_temp_cache_1

        ; Get the current A-code execution address LSB
        LDA     zp_a_code_ptr_lsb

        ; Clear the carry flag and add either 1 or 2 (depending on
        ; if this opcode has one or two operands) to get to the next
        ; valid opcode
        CLC
        ADC     zp_temp_cache_1

        ; Push the LSB onto the stack for a future "return" instruction
        ; to find
        PHA

        ; And any carry onto the MSB e.g. if the LSB went from $FF to $00
        ; when adding $01
        LDA     zp_a_code_ptr_msb
        ADC     #$00

        ; Push the MSB onto the stack for a future "return" instruction
        ; to find
        PHA

        ; Restore the return address from the stack, cached in $86/$87
        LDA     zp_temp_cache_6
        PHA
        LDA     zp_temp_cache_5
        PHA

        ; Perform the goto (basically the same as a goto but with 
        ; the next command's A-code execution address held on the stack
        ; for when there is a return.  When the return A-code instruction is
        ; found, the current A-code execution address will be set to the
        ; one calculated above on the stack)
        JMP     fn_cmd_goto

;76CA
.fn_cmd_intreturn
        ; -----------------------------------------------
        ; Virtual Machine A-code operator 2 ($02) - intreturn
        ; 
        ; This has the following A-code format:
        ;     <operator>
        ; 
        ; <operator> (bits 1-5) = $02 / 00010
        ; <operator> (bit  6  ) = not used
        ; <operator> (bit  7  ) = not used
        ; <operator> (bit  8  ) = 0 (to indicate a command)        
        ;
        ; Retrieves the A-code execution address of where
        ; to return to after a intgosub.  This is held under
        ; the 6502 JSR return address on the stack, so
        ; 1. get the JSR return address from the stack
        ; 2. cache it 
        ; 3. get the A-code execution
        ; 4. Put the JSR return address back on the stack
        ; 5. return
        ;
        ; The JSR return address is always set to 737E
        ; -----------------------------------------------

        ; Get the JSR return address LSB from the stack and
        ; store in $86
        PLA
        STA     zp_temp_cache_5
        
        ; Get the JSR return address MSB from the stack and
        ; store in $87
        PLA
        STA     zp_temp_cache_6

        ; Get the return A-code execution address MSB and
        ; set the current A-code execution address to it ($81)
        PLA
        STA     zp_a_code_ptr_msb

        ; Get the return A-code execution address LSB and
        ; set the current A-code execution address to it ($80)
        PLA
        STA     zp_a_code_ptr_lsb

        ; Put the JSR return address MSB back on the stack
        LDA     zp_temp_cache_6
        PHA

        ; Put the JSR return address LSB back on the stack
        LDA     zp_temp_cache_5
        PHA

        ; Returns
        RTS

;76DD
.fn_get_next_a_code_byte
        ; ---------------------------------------
        ; Read the next A-code byte from the
        ; A-code. This could be a opcode or an
        ; operand
        ; ---------------------------------------

        ; Preserve Y as the code needs to reset
        ; Y to zero and use it for lookup - this is 
        ; restored back into Y before this fn completes
        STY     zp_temp_cache_1

        ; Reset Y to zero
        LDY     #$00

        ; Get the next A-code byte
        LDA     (zp_a_code_ptr_lsb),Y

        ; Stick the A-code byte on the stack
        ; temporarily
        PHA

        ; Restore Y for the return
        LDY     zp_temp_cache_1

        ; Increment the pointer into the A-code to 
        ; the next A-code byte

        ; Add one to the LSB
        LDA     zp_a_code_ptr_lsb
        CLC
        ADC     #$01
        STA     zp_a_code_ptr_lsb

        ; If it crossed a page boundary, add 1 to the MSB
        LDA     zp_a_code_ptr_msb
        ADC     #$00
        STA     zp_a_code_ptr_msb

        ; Get the cached A-code byte from the stack
        PLA

        ; All done - A contains the A-code byte
        ; This could be an opcode or operand
        RTS

;76F5
.fn_get_jump_table_offset
.fn_get_a_code_variable_number
        ; ---------------------------------------------
        ; Gets the value of the game variable number - 
        ; the variable number is in the next operand
        ;
        ; 1. Variables are 16-bit values held from $0400 onwards
        ; 2. The next A-code operand gives the variable number
        ;    e.g. 32 ($20).
        ; 3. To get the address though, this has to be multiplied
        ;    by two (as each variable is 16-bit and uses two bytes)
        ; 4. And then added to $0400
        ; 5. Hence variable 32 is at $20 x 2 + $0400 = $0440
        ;
        ; Bug/feature 
        ; ~~~~~~~~~~~~~
        ; The two times multiplication is performed before 
        ; the base address is set up ($0400) so the carry flag from ASL A
        ; is thrown away. The code therefore later on needs to check
        ; if a page boundary was crossed e.g. $0400 + 2 * $80 should
        ; equal $0500 but the carry was thrown away so it does this manual
        ; check (unnecessary):
        ;
        ; If bit 7 of the variable is not set (<128) 
        ;     Calculated  address = $0400 + 2 * variable
        ; If bit 7 of the variable is set (>127)
        ;     Calculated  address = $0400 + 2 * variable (throw away carry) + $0100
        ;
        ; So variables are theoretically stored from $0400 to $05FF
        ; however for Lords of Time, one of hte lists start at $0550
        ;
        ; Returns the value that the game variable holds
        ; ---------------------------------------------
        
        ; Get the operand from the A-code as this indicates
        ; which variable to lookup
        JSR     fn_get_next_a_code_byte

IF config_savefile = "TIMEDAT" OR config_savefile = "SNOWDAT"

        ; Cache the operand value
        PHA
ENDIF

        ; Multiple it by 2 (2 * operand value)
        ASL     A

        ; Transfer the result to Y
        TAY

        ; Write $0400 to $70/$71 - this is the start address
        ; of where the game variables are held - reads from $732D/3
        ; Bug/feature - if this was before the ASL A above, then the 
        ; carry flag from ASL A could be added to the MSB here after a 
        ; LDA #$00
        LDA     data_variables_start_address_msb
        STA     zp_variable_ptr_msb
        LDA     data_variables_start_address_lsb
        STA     zp_variable_ptr_lsb

        ; Y contains the variable number double (as each
        ; variable is 16-bit and therefore uses two bytes)
        ; Add Y onto the LSB to get the variable's memory
        ; location
        TYA
        CLC
        ADC     zp_variable_ptr_lsb
        STA     zp_variable_ptr_lsb

        ; Add any carry to the MSB
        LDA     zp_variable_ptr_msb
        ADC     #$00
        STA     zp_variable_ptr_msb

IF config_savefile = "TIMEDAT" OR config_savefile = "SNOWDAT"
        ; Restore the operand value
        PLA 

        ; Check to see if the top bit is set
        ; The carry flag from the ASL A is throw away above
        ; so the MSB hasn't been incremeted correctly to $05xx
        ; if the variable is > 127 i.e. $0400 + 2 * $80 should 
        ; equal $0500 but at this point the memory address held
        ; in zp_variable_ptr_msb/lsb will be $0400
        AND     #$80

        ; If it's not set branch ahead
        BEQ     get_variable_value

        ; It's set, add one to the MSB address
        ; so page $05xx rather than $04xx
        INC     zp_variable_ptr_msb
ENDIF

;7718
.get_variable_value
        ; Load the variable value from the vm
        ; workspace 
        LDY     #$00
        LDA     (zp_variable_ptr_lsb),Y

        ; Return with A containing the vm workspace
        ; variable value
        RTS

;771D
.fn_get_a_code_opcode_operands
        ; --------------------------------------------
        ; In the A-code, operators have one or two operands.
        ; Gets one or two byte values that follow the the 
        ; opcode.  These are stored in $72/$73. If a single
        ; byte only, then $73 is set to the value $00.
        ; 
        ; This function is used by:
        ; messagec - either an 8-bit or 16-bit message id
        ; varcon   - first byte is the constant, second the variable number
        ; 
        ; 
        ; If the 7th bit of the command is set, it reads
        ; only one byte otherwise if not set, two.
        ; ---------------------------------------------

        ; Check to see if the 7th bit of the command is
        ; set - only load one byte not two
        LDA     zp_opcode_7th_bit
        CMP     #$00
        BNE     fn_get_a_code_opcode_operand_single_byte

        ; 7th bit not set so there are two operands (it's
        ; a 16-bit message id)

        ; Get the next operand from the a-code 
        ; that follows the operator and store it in $72
        JSR     fn_get_next_a_code_byte
        STA     zp_1st_operand

        ; Get the next operand from the a-code
        ; that follows the first operand and store it in $73
        JSR     fn_get_next_a_code_byte
        STA     zp_2nd_operand

        ; Operands retrieved (two bytes)
        RTS

;772E
.fn_get_a_code_opcode_operand_single_byte
        ; Get the next operand from the a-code 
        ; that follows the operator and store it in $72
        JSR     fn_get_next_a_code_byte
        STA     zp_1st_operand

        ; There is no second byte so
        ; set the second operand $73 to the value $00 
        LDA     #$00
        STA     zp_2nd_operand

        ; Operands retrieved (one byte)
        RTS        

;7738
;varcon
.fn_cmd_set_variable_to_constant
        ; -----------------------------------------------
        ; Virtual Machine A-code operator 0 ($08) - varcon
        ;
        ; This has the following A-code format:
        ;     <operator> <operand1> <operand2> [<operand3>]
        ; 
        ; <operand3> is only present if the 6th bit is zero
        ;
        ; <operator> (bits 1-5) = $08 / 01001
        ; <operator> (bit  6  ) = not used
        ; <operator> (bit  7  ) = indicates if there are one or two operands
        ; <operator> (bit  8  ) = 0 (to indicate a command)
        ;
        ; 
        ; If bit 7 is set:
        ;     
        ; <operand1> - 8-bit constant to set the variable value to
        ; <operand2> - Variable number to set to the constant
        ;
        ; If bit 7 is NOT set:
        ;     
        ; <operand1> - LSB of the 16-bit constant to set the variable value to
        ; <operand2> - MSB of the 16-bit constant to set the variable value to
        ; <operand3> - Variable number to set to the constant
        ; 
        ;
        ; Sets a variable to an 8-bit or 16-bit constant
        ; -----------------------------------------------

        ; Read one or two operands based on bit 7
        ; Bytes will be placed in zp_1st_operand/zp_2nd_operand($72/$73)
        ; and those locations used as a source address
        JSR     fn_get_a_code_opcode_operands

        ; Set the "copy from" pointer $70/&71 to point
        ; at $72/$73 where the constant above
        ; was placed
        JSR     fn_set_constant_address_location

        ; Copy the value held at $72/$73 into the
        ; variable number indicated by the next 
        ; a-code operand.
        JMP     fn_copy_from_memory_to_memory

;7741
.fn_set_constant_address_location
        ; ------------------------------------
        ; Set the variable address $70/$71 to be 
        ; $0072 which is where the constant
        ; is held 
        ; ------------------------------------
        LDA     #LO(zp_constant_lsb)
        STA     zp_variable_ptr_lsb
        LDA     #HI(zp_constant_lsb)
        STA     zp_variable_ptr_msb

        ; VM Workspace pointer set
        RTS

;774A
.fn_copy_memory_address_ptr
        ; -----------------------------------------------
        ; Moves the memory address reference in $70/$71
        ; into $73/$74.  This allows $70/$71 to be set
        ; to a variable address and a copy or add or 
        ; subtract etc to happen
        ; -----------------------------------------------
        
        ; Copy the LSB
        LDA     zp_variable_ptr_lsb
        STA     zp_cached_ptr_lsb

        ; Copy the MSB
        LDA     zp_variable_ptr_msb
        STA     zp_cached_ptr_msb
        RTS

;7753
.fn_cmd_copy_from_var1_to_var2
        ; -----------------------------------------------
        ; Virtual Machine A-code operator 9 ($09) - varvar
        ;
        ; This has the following A-code format:
        ;     <operator> <operand1> <operand2>
        ;
        ; <operator> (bits 1-5) = $09 / 01001
        ; <operator> (bit  6  ) = not used
        ; <operator> (bit  7  ) = not used
        ; <operator> (bit  8  ) = 0 (to indicate a command)
        ;
        ; <operand1> - variable number to copy value from
        ; <operand2> - variable number to copy value to
        ;
        ; Copies the value of variable 1 to variable 2 - 
        ; both variables have address in the ($0400 - $05FF)
        ; range
        ; -----------------------------------------------

        ; Reads the operand which contains the variable 
        ; number to read from.  Each variable is 16-bit and its
        ; memory location is calcuated using:
        ; Address = 2 * value + $0400. 
        ;
        ; zp_variable_ptr_lsb/msb ($70/$71) contain the address of the
        ; variable's lower 8-bits
        ; 
        ; The lower 8-bits of the variable's value are
        ; returned in A
        JSR     fn_get_a_code_variable_number

        ; Coninues below

;7756
.fn_copy_from_memory_to_memory
        ; -----------------------------------------------
        ; Sets a variable to an 8-bit or 16-bit value held
        ; in memory
        ; 
        ; On entry ():
        ;    $70/$71 - set to location of memory to copy
        ;
        ; Performs the following:
        ; 1. Moves the memory address in $70/$71 into $74/$75
        ;    - this is the copy from address
        ; 2. Gets the next operand from the a-code. This is the
        ;    variable number
        ; 3. Calculates the memory address of the variable
        ;    and places this in this in $70/$71.
        ; 4. Sets the value of the memory address referenced
        ;    in $70/$71 to the value held in the memory 
        ;    address referenced in $74/$75
        ;
        ; Notes for varcon:
        ; ~~~~~~~~~~~~~~~~
        ; On entry:
        ; $70/$71 - always contains the memory address $0072
        ; $71/$72 - always contains the constant value
        ; 
        ; Notes for varvar:
        ; ~~~~~~~~~~~~~~~~
        ; $70/$71 - always contains the copy from variable's 
        ;           starting memory address (LSB)
        ; -----------------------------------------------

        ; Moves the memory address in $70/$71 into $74/$75
        ; - this is the copy from address
        JSR     fn_copy_memory_address_ptr

        ; Reads the operand which contains the variable 
        ; number to update.  Each variable is 16-bit and its
        ; memory location is calcuated using:
        ; Address = 2 * value + $0400
        ;
        ; zp_variable_ptr_lsb/msb ($70/$71 will contain
        ; the address of the variable's lower 8-bits)
        ; 
        ; The lower 8-bits of the variable's value are
        ; returned in A        
        JSR     fn_get_a_code_variable_number

        ; Copies the first byte at the "copy from"
        ; address to the first byte at the "copy to"
        ; address (either both in $0400 - $05FF or
        ; from zero page to $0400 - $05FF)
        LDY     #$00
        LDA     (zp_cached_ptr_lsb),Y
        STA     (zp_variable_ptr_lsb),Y

        ; Copies the second byte at the "copy from"
        ; address to the second byte at the "copy to"
        ; address (either both in $0400 - $05FF or
        ; from zero page to $0400 - $05FF)
        INY
        LDA     (zp_cached_ptr_lsb),Y
        STA     (zp_variable_ptr_lsb),Y

        ; Two bytes copied in the workspace
        RTS

;7768
.fn_cmd_get_player_input
        ; ---------------------------------------------
        ; 1. Get the player's input, parse it to find
        ; dictionary matches of commands or objects
        ; and store the codes in the virtual machine
        ; memory
        ; ---------------------------------------------
        ; <command> <byte1> <byte2> <byte3> <byte3>
        ;
        ; <command> is always $07
        ; <byte1> where to store the first cmd/obj
        ; <byte2> where to store the second cmd/obj
        ; <byte3> where to store the third cmd/obj
        ; <byte4> where to store the word count
        ;
        ; Note there are no bytes following it that
        ; the command uses
        
        ; Get the player's input and store
        ; the command(s) and/or object(s) 
        ; in a buffer starting at $0000
        JSR     fn_get_and_parse_player_input

        ; Continues

;776B
.fn_store_matched_cmds_and_objects

IF config_savefile = "TIMEDAT" OR config_savefile = "SNOWDAT"
        ; Clean up the stack, values are not used
        ; Remove the cached memory location of the
        ; first word the player inputted (MSB then LSB)
        ; The values were placed there initally at $77BA/D
        ; and pulled off and on after that e.g. in
        ; input_words_counted
        PLA
        PLA

        ; Remove the return address from the stack
        ; for the call to fn_get_and_parse_player_input
        ; - once player input is parsed, $783F
        ; calls fn_end_cmd_or_obj_seq_and_process
        ; which in turn JMPs to 776B above, making
        ; the RTS address redundant and unused
        PLA
        PLA
ENDIF

        ; Load the first derived command or object code 
        ; from the string buffer into A and write
        ; to the vm variable specified in <operand1>
        ; for the input <operator>
        LDA     zp_general_string_buffer
        JSR     fn_set_variable_value

        ; Load the second derived command or object code 
        ; from the string buffer into A and write
        ; to the vm variable specified in <operand2>
        ; for the input <operator>
        LDA     zp_general_string_buffer+1
        JSR     fn_set_variable_value

        ; Load the second derived command or object code 
        ; from the string buffer into A and write
        ; to the vm variable specified in <operand3>
        ; for the input <operator>
        LDA     zp_general_string_buffer+2
        JSR     fn_set_variable_value

        ; Load the input words count and write
        ; into the vm workspace
        LDA     zp_input_words_count
        JSR     fn_set_variable_value

IF config_savefile = "TIMEDAT" OR config_savefile = "SNOWDAT"
        ; Finished capturing input 
        RTS
ELSE
        JMP     jump_to_a_code_virtual_machine 
ENDIF        

;################################################ 
;7784
.fn_set_variable_value
        ; ---------------------------------------------
        ; Updates the vm variable value to the value 
        ; passed in A
        ;
        ; Each variable is 16-bit
        ; and held in memory between ($0400-$05FF)
        ;
        ; The address of the 16-bit variable is calculated using
        ; Memory addrres = $0400 + (2 * variable number)
        ;
        ; The variable number is the next <operand> read
        ; from the next byte in the a-code
        ; ---------------------------------------------

        ; Cache on the stack the new variable value to write
        PHA

        ; Get the variable number from the a-code and 
        ; calculate the start address where its 16-bit
        ; value resides in memory 
        ; zp_variable_ptr_lsb/msb will point to the address
        ; of the variable's contents
        JSR     fn_get_a_code_variable_number

        ; Y is used to index the 16-bit variable's value
        ; so reset it to zero
        LDY     #$00

        ; Restore the value to set the variable to
        PLA

        ; Write the value to the variable LSB
        STA     (zp_variable_ptr_lsb),Y
        INY

        ; Set the variable MSB to zero
        LDA     #$00
        STA     (zp_variable_ptr_lsb),Y

        ; Variable updated
        RTS

;7793
.fn_get_and_parse_player_input
        ; ---------------------------------------------
        ; 1. Get a new line of input from the player
        ;    and add a space and a terminator to the 
        ;    end of the string buffer
        ; ---------------------------------------------
        ; Get a new line of text input from the player
        ; up to a maximum of 39 characters.  Stores this
        ; in $0000+ as a raw string
        LDY     #$27
        JSR     fn_read_player_input

        ; Y now contains the number of characters input
        ; by the player at this point - move it to X
        ; to use as an index
        TYA
        TAX

        ; Put a space at the end of the input string
        LDA     #$20
        STA     zp_general_string_buffer,X

        ; Terminate the string with a $00 string terminator
        ; after the space
        LDA     #$00
        INX
        STA     zp_general_string_buffer,X

        ; ---------------------------------------------
        ; 2. Reset the working variables and the pointer
        ;    to the player's input and initialise 
        ;    the pointer to the dictionary
        ; ---------------------------------------------
        
        ; Reset the string buffer and the instruction buffer
        ; memory pointers (they both use the same memory 
        ; starting in zeropage at $0000)
        LDA     #$00
        STA     zp_cmd_and_obj_pointer_lsb
        STA     zp_input_string_buffer_ptr_lsb
        LDA     #$00
        STA     zp_cmd_and_obj_pointer_msb
        STA     zp_input_string_buffer_ptr_msb

        ; Initialise the dictionary pointer to the
        ; start of the dictionary
        JSR     fn_init_dictionary_pointer


        ; ---------------------------------------------
        ; 3. Find the start of the first word in the 
        ;    player's input (skip spaces) and cache
        ;    the position
        ; ---------------------------------------------

        ; Subtract 1 from the player's input string
        ; buffer pointer as the next function
        ; call adds one
        JSR     fn_dec_input_string_buffer_pointer

        ; Find the first non-space character in the 
        ; player's input string and load into A and 
        ; zp_input_buffer_lsb/msb will point to 
        ; memory location
        JSR     fn_find_next_non_space_in_input_string

        ; Cache on the stack the position of the start
        ; of the first word that the player entered
        LDA     zp_input_string_buffer_ptr_lsb
        PHA
        LDA     zp_input_string_buffer_ptr_msb
        PHA

        ; ---------------------------------------------
        ; 4. Reset the word count
        ; ---------------------------------------------

        ; Reset X to zero - X is used to count words here
        LDX     #$00

        ; ---------------------------------------------
        ; 5. Move back a character in the player's input
        ;    to just before the first word - main loop
        ;    loops around each word found to count them
        ; ---------------------------------------------

        ; Subtract 1 from the player's input string
        ; buffer pointer as the next function
        ; call adds one
        JSR     fn_dec_input_string_buffer_pointer

;77C3
.count_next_word

        ; ---------------------------------------------
        ; 6. Counts all the words in the input
        ;    string by finding the start of the 
        ;    next word, looping through word
        ;    to find the next space or string 
        ;    terminator and then looping to find
        ;    the start of the next word or terminator
        ;
        ;    Finding a string terminator at any point
        ;    will break out of this routine
        ;
        ; ---------------------------------------------

        ; Get the next non-space character in the 
        ; player's input string
        JSR     fn_find_next_non_space_in_input_string

        ; Is the current character the input terminator?
        ; If so branch as all input words have been counted
        CMP     #$00
        BEQ     input_words_counted

        ; Still more input to process

        ; X is used to count the number of input words
        INX
;77CB
.loop_find_end_of_word
        ; Loop looks for the end of the current word 
        ; by checking for an input termination 
        ; character of $00 or a space $20

        ; Move to the next character that the player
        ; entered
        JSR     fn_inc_input_string_buffer_pointer

        ; Get the current character from the string buffer
        ; the the player entered
        JSR     fn_get_input_character

        ; Is the current character the input terminator?
        ; If so branch as all input words have been counted
        CMP     #$00
        BEQ     input_words_counted

        ; Is it a space? Loop to the next character if not
        CMP     #$20
        BNE     loop_find_end_of_word

        ; It's a space
        
        ; Find the start of the next word 
        ; by looping through all spaces until a non
        ; space or terminator is found
        JMP     count_next_word

;77DC
.input_words_counted
        ; ---------------------------------------------
        ; 7. ALl input words are counted, reset the 
        ;    input string buffer to point to the start
        ;    of the first input word and cache the location
        ;    back on the stack
        ; ---------------------------------------------

        ; Store the number of input words counted 
        STX     zp_input_words_count

        ; Restore the string buffer pointer
        ; to point back to the start of the 
        ; player input string

        ; Pull the cached start string address MSB
        ; from the Stack
        PLA     

        ; Restore it to the string buffer pointer MSB
        STA     zp_input_string_buffer_ptr_msb

        ; Pull the cached start string address MSB
        ; from the Stack
        PLA

        ; Restore it to the string buffer pointer LSB
        STA     zp_input_string_buffer_ptr_lsb

        ; Cache the string buffer pointer LSB again on the stack
        PHA

        ; Reload the string buffer pointer MSB
        LDA     zp_input_string_buffer_ptr_msb

        ; Cache the string buffer pointer LSB again
        PHA

;77E8
.compare_current_input_word
        ; ---------------------------------------------
        ; 8. Cache the start of the current input word 
        ;    being parsed.  
        ; ---------------------------------------------

        ; Cache the start of the current input word
        LDA     zp_input_string_buffer_ptr_msb
        STA     zp_current_word_ptr_msb
        LDA     zp_input_string_buffer_ptr_lsb
        STA     zp_current_word_ptr_lsb

        ; Decrement the string buffer pointer (required
        ; because the next fn call moves to the next
        ; character in the string before doing anything
        ; else)
        JSR     fn_dec_input_string_buffer_pointer

        ; Find the start of the next word by skipping 
        ; over spaces to find the first non-space
        ; or string terminator
        JSR     fn_find_next_non_space_in_input_string

;77F6
.compare_next_dict_char_against_input_char

        ; ---------------------------------------------
        ; 9. Load the next character of the current 
        ;    input word and check it isn't the end 
        ;    of the string ($00) or a space ($20). 
        ;    Cache the character in X and load the
        ;    next current dictionary word character
        ;    and check it isn't the end of the 
        ;    dictionary ($00)
        ; ---------------------------------------------

        ; Load the next character of the word into
        ; A (the accumulator)
        JSR     fn_get_input_character

        ; Is the input character a space (ASCII $20)
        ; If so, branch ahead as we have a partial
        ; match against a full dictionary word e.g.
        ; the player typed "NORT" and it was 
        ; matched against "NORT(H)" in the 
        ; dictionary. Remember that
        ; the code above in (1) replaces the
        ; end CR with a space in the player 
        ; input so even the last word has a 
        ; space after it
        CMP     #$20
        BEQ     loop_until_end_of_dict_word

        ; Have all the words been matched to 
        ; commands or objects?
        ; 
        ; Is the character in the input string
        ; terminator? If so, branch ahead as 
        ; we have parsed the player input string
        CMP     #$00
        BEQ     fn_player_input_string_parsed

        ; Not space or a string terminator - valid
        ; ascii input value

        ; Cache the current input string value
        TAX
        JSR     fn_get_exits_or_dictionary_byte

        ; Has the end of the dictionary been reached?
        ; Terminated with a $00 - if so branch
        CMP     #$00
        BEQ     fn_loop_to_end_of_current_input_word

;7809
        ; ---------------------------------------------
        ; 10. Masks out the 8th bit of the current 
        ;     dictionary word character (8th bit
        ;     just indiciates if it's the last character
        ;     of the current dictionary word).  The compares
        ;     this character with the current input 
        ;     character.  If they are the same,
        ;     moves the pointers forward for 
        ;     dictionary and input string to the next
        ;     character in each.
        ; ---------------------------------------------

        ; At this point A contains the current dictionary
        ; word character and X the current input character
        ; for comparison

        ; Cache the current dictionary word character
        ; on the stack 
        PHA

        ; Throw away the top bit (keep the bottom 7 bits)
        ; AND $7F = AND 0111 1111
        AND     #$7F

        ; Store the player's current input string value
        ; in $86
        STX     zp_curr_input_char_cache

        ; Compare the current dictionary word character
        ; against the player's current input string character
        CMP     zp_curr_input_char_cache

        ; If it isn't the same then branch ahead
        ; and find the next dictionary entry
        BNE     fn_find_next_dict_entry_and_compare

        ; The player's current input string character
        ; matches the current dictionary word character

        ; Move the pointer to the next dictionary character
        JSR     fn_inc_dictionary_or_exits_ptr

        ; Move the pointer to the next player input character
        JSR     fn_inc_input_string_buffer_pointer

        ; ---------------------------------------------
        ; 11. Checks to see if it's the last letter
        ;     of the current dictionary word (last
        ;     letter has the 8th bit set).  If it is,
        ;     then check the next input string character
        ;     is a space (so is it a 100% match?)
        ; ---------------------------------------------

        ; Restore the current dictionary word character with
        ; the top bit restored - note that the dictionary
        ; word pointer is at this point, pointing at the
        ; character after this where this one was retrieved
        PLA

        ; Is this the last character of the dictionary
        ; word (last character has it's 8th bit set
        ; so value will be >= $7F)
        CMP     #$7F

        ; Branch to the next dictionary word character
        ; for comparison against user input 
        ; if it wasn't the last dictionary word character
        BCC     compare_next_dict_char_against_input_char

        ; Last dictionary word character

        ; Get the player's next input character
        JSR     fn_get_input_character

        ; Did the player input a space as the next character?
        ; If so, then player's current word 100% matches 
        ; the dictionary word
        CMP     #$20

        ; Branch if it isn't a space so it doesn't 100% match
        ; - e.g. if the player input "GETT" instead of "GET"
        ; (it will reset to the start of the current word
        ; to see if it can be matched against another dictionary
        ; word)
        BNE     fn_check_word_against_next_dict_entry

        ; Dictionary word 100% matches player input
        ; word

        ; ---------------------------------------------
        ; 12. The character after the dictionary word
        ;     is the command or object code.  Get
        ;     this (because the player input word 100% 
        ;     matched). Store this code in the 
        ;     player input string buffer (each word
        ;     code is stored sequentially from the
        ;     start)
        ; ---------------------------------------------

        ; Move the dictionary pointer back to the
        ; last matched letter (end of dictionary word)
        JSR     fn_dec_exit_or_dictionary_pointer

;7827
.loop_until_end_of_dict_word
        ; ---------------------------------------------
        ; 13. Loop until the last character of the 
        ;     dictionary word is found - for a 100%
        ;     match it's already there, for a partial
        ;     match it has to loop to find it. This 
        ;     is performed because the command or
        ;     object code is after the last character
        ;     of the dictionary word
        ; ---------------------------------------------

        ; Get the last matched letter
        JSR     fn_get_exits_or_dictionary_byte

        ; Add the last letter to the stack
        PHA

        ; Move to beyond the last matched dictionary
        ; character to get to the 
        JSR     fn_inc_dictionary_or_exits_ptr

        ; Restore the last letter from the stack
        PLA

        ; Check to see if this is the last letter
        ; of the dictionary word to check - this is 
        ; indicated by bit 7 being set
        CMP     #$7F

        ; Branch if not the last character of the 
        ; dictionary word process the next character
        BCC     loop_until_end_of_dict_word

        ; Character has bit 7 set so it WAS the last
        ; character to match for that dictionary word

        ; Get the next dictionary character - the next
        ; character after the last character to match
        ; contains the command or object id derived
        ; from the word
        JSR     fn_get_exits_or_dictionary_byte


        ; Write the command or object code to the zero page
        ; memory cache
        JSR     fn_cache_cmd_or_obj

        ; Move the input string buffer pointer to the start
        ; of the next input word
        JSR     fn_find_next_non_space_in_input_string

        ; Reset the dictionary pointer to the beginning
        ; of the dictonary and compare the next input word
        ; against it by looping through the dictionary
        JMP     fn_reset_dict_and_compare_next_word

;783F
.fn_player_input_string_parsed
        ; Add a sequence terminator ($00) to the string
        ; and process to commands or objets
        JMP     fn_end_cmd_or_obj_seq_and_process


;7842
.fn_check_word_against_next_dict_entry
        ; ---------------------------------------------
        ; Resets the input string pointer to point
        ; back to the start of the current word so it 
        ; can try and map it against another dictionry 
        ; word
        ; 
        ; Called when a player input word has additional
        ; letters after the dictionary word match e.g.
        ; "GETT" when matched with "GET"
        ; ---------------------------------------------

        ; Reset the LSB to the start of the current word
        LDA     zp_current_word_ptr_lsb ; 7A
        STA     zp_input_string_buffer_ptr_lsb  ; 76

        ; Reset the MSB to the start of the current word
        LDA     zp_current_word_ptr_msb
        STA     zp_input_string_buffer_ptr_msb

        ; Move the dictionary point on to the start
        ; of the next dictionary word
        JSR     fn_inc_dictionary_or_exits_ptr
        JSR     fn_inc_dictionary_or_exits_ptr

        ; Check the current word against the next
        ; dictionary item 
        JMP     compare_current_input_word


;7853
.fn_reset_dict_and_compare_next_word
        ; ---------------------------------------------
        ; Rest the dictionary pointer and compare
        ; the next word againt the dictionary
        ; ---------------------------------------------

        ; Reset the dictionary pointer to the start
        ; of the dictionary
        JSR     fn_init_dictionary_pointer

        ; Compare the next input word against 
        ; the dictionary
        JMP     compare_current_input_word

;7859
.fn_find_next_dict_entry_and_compare
        ; Pull the current input word character from the
        ; stack (clean up, not used)
        PLA
;785A
.loop_get_next_dict_chr
        ; Move the dictionary pointer forward
        JSR     fn_inc_dictionary_or_exits_ptr

        ; Get the character at the dictionary pointer
        JSR     fn_get_exits_or_dictionary_byte

        ; Has the end of the dictionary been reached?
        CMP     #$00

        ; Branch if at the end of the dictionary
        BEQ     fn_loop_to_end_of_current_input_word

        ; Not at the end of the dictionary

        ; Is it the last character of the dictionary 
        ; word? Last character of each word has the 8th
        ; bit set so will be >=$7Fs
        CMP     #$7F

        ; If not the last character, loop until it's
        ; found (when it's value >=$7F)
        BCC     loop_get_next_dict_chr

        ; At the last character of the dictionary word

        ; The last character is followed by a command or
        ; object code, so increment the dictionary pointer
        ; twice to get to the start of the next word
        JSR     fn_inc_dictionary_or_exits_ptr
        JSR     fn_inc_dictionary_or_exits_ptr

        ; Reset the input string buffer pointer back to the
        ; start of the current word as it needs to be compared
        ; against hte next dictionary entry
        LDA     zp_current_word_ptr_lsb
        STA     zp_input_string_buffer_ptr_lsb
        LDA     zp_current_word_ptr_msb
        STA     zp_input_string_buffer_ptr_msb

        ; Compare the next dictionary entry against the 
        ; current input word
        JMP     compare_next_dict_char_against_input_char       

;7879
.fn_loop_to_end_of_current_input_word
        ; ------------------------------------------
        ; End of the dictionary has been reached but
        ; input string has not been matched at all
        ;
        ; 1. Loop until input terminator ($00) is found
        ;    or a space is found
        ; 2. End processing if a terminator
        ; 3. If a space is found, loop until the start
        ;    of the next word or the input terminator 
        ;    is found
        ; 4. Point the current word pointer at the start
        ;    of the word and the reset the dictionary
        ;    pointer back to the start 
        ; 5. Jump back and try an match the next word
        ; ------------------------------------------


        ; Move to the next byte in the string input buffer
        ; at $0000+
        JSR     fn_inc_input_string_buffer_pointer

        ; Get the character at this new position in the
        ; input buffer
        JSR     fn_get_input_character

        ; Was this the end of the user's input?
        CMP     #$00

        BEQ     fn_end_cmd_or_obj_seq_and_process

        ; It was not the end of the user's input

        ; Was the user input followed by a space ($20 / 32)
        ; branch if it is not a space (loop until a terminator
        ; or a space is found to get to the end of this word)
        CMP     #$20
        BNE     fn_loop_to_end_of_current_input_word

        ; It was a space

        ; Move to the start of the next input word or 
        ; the input terminator 
        JSR     fn_find_next_non_space_in_input_string

        ; Reset the dictionary pointer back to the 
        ; start of the dictionary - so the next input 
        ; word can be compared against it
        JSR     fn_init_dictionary_pointer

        ; Cached the memory address of the start of
        ; the new word (used in case of partial matches)
        ; to reset back to the start of the word for 
        ; comparison against the next dictionary item
        LDA     zp_input_string_buffer_ptr_lsb
        STA     zp_current_word_ptr_lsb
        LDA     zp_input_string_buffer_ptr_msb
        STA     zp_current_word_ptr_msb
        JMP     compare_next_dict_char_against_input_char

;7898
.fn_end_cmd_or_obj_seq_and_process
        ; Terminate the sequence of commands and/or
        ; objects in zero page by writing $00
        ; after the last command or object
        LDA     #$00
        JSR     fn_cache_cmd_or_obj


        ; Commands / objects so far have been written
        ; into $0000+ over the input words. Callt this
        ; function to move them into vm variables
        ; in the 0400-05FF range.  The variables
        ; are specified after the <operator> for 
        ; the input command as operands
        JMP     fn_store_matched_cmds_and_objects

;78A0
.fn_cache_cmd_or_obj
        ; ----------------------------------------------
        ; Write the command or object code for the
        ; current input word into zero page memory - 
        ; commands and objects are written sequentially
        ; starting from $0000
        ; ----------------------------------------------
        
        ; Write the derived command or object code
        ; to the current zero page location
        LDY     #$00
        STA     (zp_cmd_and_obj_pointer_lsb),Y

        ; Get the pointer address
        LDA     zp_cmd_and_obj_pointer_lsb

        ; Clear the carry flag
        CLC

        ; Increment the pointer address
        ADC     #$01

        ; Save it back over the current value
        STA     zp_cmd_and_obj_pointer_lsb

        ; Load the pointer MSB
        LDA     zp_cmd_and_obj_pointer_msb

        ; Add any carry to the MSB
        ADC     #$00

        ; Store it back over the current value
        STA     zp_cmd_and_obj_pointer_msb

        ; All done
        RTS        

;78B2
.fn_find_next_non_space_in_input_string
.loop_check_next_input_character
        ; Move to the next character in the input string buffer
        JSR     fn_inc_input_string_buffer_pointer

        ; Get the character at that position
        ; Note does not increment the pointer into the buffer
        JSR     fn_get_input_character

        ; Check to to see if the character is a space ($20)
        CMP     #$20

        ; Check if it's a space and, if so, loop back to this function
        BEQ     loop_check_next_input_character

        ; Set the status flags to see if this was the string terminator
        ; TODO not sure this is used
        CMP     #$00

        ; Return the next non-space character
        RTS

;78BF
.fn_inc_input_string_buffer_pointer
        ; ----------------------------------------------
        ; Increments the pointer to the input string
        ; buffer - to point at the next input character
        ; ----------------------------------------------

        ; Get the LSB of the string buffer pointer
        LDA     zp_input_string_buffer_ptr_lsb

        ; Clear the carry flag
        CLC

        ; Add 1 to the LSB pointer address
        ADC     #$01

        ; Store the new value over the old value
        STA     zp_input_string_buffer_ptr_lsb

        ; Load the MSB of the string buffer pointer
        LDA     zp_input_string_buffer_ptr_msb

        ; Add the carry if there was any (LSB > 255)
        ADC     #$00

        ; Store the new value over the old value
        STA     zp_input_string_buffer_ptr_msb

        ; All done
        RTS

;78CD
.fn_inc_dictionary_or_exits_ptr
        ; ----------------------------------------------
        ; Increments the pointer to the dictionary
        ; or location exit information
        ; to point at the next byte
        ;
        ; Note:
        ;    zp_dictionary_ptr_lsb/msb points to the 
        ;    same location as 
        ;    zp_exits_ptr_lsb/msb 
        ;
        ; The former is used here but this function is
        ; for both the dictionary and the exits.  I defined
        ; two different variables to make other parts
        ; of the code easier to read...
        ; ----------------------------------------------

        ; Get the LSB of the dictionary pointer
        LDA     zp_dictionary_ptr_lsb

        ; Clear the carry flag
        CLC

        ; Add 1 to the LSB pointer address
        ADC     #$01

        ; Store the new value over the old value
        STA     zp_dictionary_ptr_lsb

        ; Get the MSB of the dictionary pointer
        LDA     zp_dictionary_ptr_msb

        ; Add the carry if there was any (LSB > 255)
        ADC     #$00

        ; Store the new value over the old value
        STA     zp_dictionary_ptr_msb
        RTS

;78D8
.fn_dec_input_string_buffer_pointer
        ; ----------------------------------------------
        ; Decrements the pointer to the input string
        ; buffer - to point at the previous input character
        ; ----------------------------------------------

        ; Set the carry flag
        SEC

        ; Get the LSB of the string buffer pointer
        LDA     zp_input_string_buffer_ptr_lsb

        ; Subtract one (using the carry if a borrow is required)
        SBC     #$01

        ; Store the new value over the old value
        STA     zp_input_string_buffer_ptr_lsb

        ; Load the MSB of the string buffer pointer
        LDA     zp_input_string_buffer_ptr_msb

        ; Subtract the 1 if a borrow occured
        SBC     #$00

        ; Store the new value over the old value
        STA     zp_input_string_buffer_ptr_msb

        ; All done
        RTS

;78E9
.fn_dec_exit_or_dictionary_pointer
        ; ----------------------------------------------
        ; Decrements (moves back) the pointer to the 
        ; dictionary or location exit information
        ; to point at the next byte
        ;
        ; Note:
        ;    zp_dictionary_ptr_lsb/msb points to the 
        ;    same location as 
        ;    zp_exits_ptr_lsb/msb 
        ;
        ; The former is used here but this function is
        ; for both the dictionary and the exits.  I defined
        ; two different variables to make other parts
        ; of the code easier to read...
        ; ----------------------------------------------
        SEC
        LDA     zp_dictionary_ptr_lsb
        SBC     #$01
        STA     zp_dictionary_ptr_lsb
        LDA     zp_dictionary_ptr_msb
        SBC     #$00
        STA     zp_dictionary_ptr_msb
        RTS


;78F7
.fn_get_input_character
        ; Get the next character from the input string buffer
        ; which contains the text the user entered.  This is 
        ; in zero page from $0000+
        LDY     #$00
        LDA     (zp_input_string_buffer_ptr_lsb),Y
        RTS

;78FC
.fn_get_exits_or_dictionary_byte
        ; ----------------------------------------------
        ; Returns the byte pointed at by the dictionary
        ; or location exits pointer
        ;
        ; Note:
        ;    zp_dictionary_ptr_lsb/msb points to the 
        ;    same location as 
        ;    zp_exits_ptr_lsb/msb 
        ;
        ; The former is used here but this function is
        ; for both the dictionary and the exits.  I defined
        ; two different variables to make other parts
        ; of the code easier to read...
        ; ----------------------------------------------

        ; Get the byte and return it
        LDY     #$00
        LDA     (zp_dictionary_ptr_lsb),Y
        RTS

;7901
.fn_init_dictionary_pointer
        ; ------------------------------------------
        ; Resets the dictionary pointer back to the start
        ; ------------------------------------------

        ; Reset the LSB back to the start of the dictionary
        LDA     zp_dictionary_start_lsb
        STA     zp_dictionary_ptr_lsb

        ; Reset the MSB back to the start of the dictionary
        LDA     zp_dictionary_start_msb
        STA     zp_dictionary_ptr_msb

        ; Reset complete
        RTS

;790A
.fn_cmd_goto
        ; -----------------------------------------------
        ; Virtual Machine A-code operator 0 ($00) - goto
        ;
        ; This has the following A-code format:
        ;     <operator> <operand1> [<operand2>]
        ;
        ; <operand2> is only present if the 6th bit is zero
        ; 
        ; <operator> (bits 1-5) = $00 / 00000
        ; <operator> (bit  6  ) = 0 (two operands) or 1 (one operand)
        ; <operator> (bit  7  ) = not used
        ; <operator> (bit  8  ) = 0 (to indicate a command)
        ;
        ; <operand1>   - single byte relative signed offset (-127 to +128) 
        ;                OR
        ;                LSB of the absolute offset to add to the A-code start address
        ; [<operand2>] - MSB of the absolute offset to add to the A-code start address
        ;
        ; The 6th bit of the opcode indicates:
        ;     1 - single byte offset (relative plus or
        ;         minus from the current A-code execution
        ;         address)
        ;     0 - double byte offset (absolute offset 
        ;         from the start of the A-code)
        ; 
        ; Double byte offset
        ; ~~~~~~~~~~~~~~~~~~
        ; A-code execution address = A-code start address + operand1 + (256 + operand2)
        ; 
        ; Single byte offset
        ; ~~~~~~~~~~~~~~~~~~
        ; If the single byte offset is positive:
        ;    A-code execution address = A-code execution address + single byte offset
        ;
        ; If the single byte offset is negative:
        ;    A-code execution address = A-code execution address + single byte offset - 1
        ; Note that the single byte offset is negative so it's a subtraction in reality
        ;
        ; -----------------------------------------------

        ; Get the cached 6th bit of the command        
        LDA     zp_opcode_6th_bit

        ; If the 6th bit is set then branch ahead to the single
        ; byte offset processing
        CMP     #$00
        BNE     single_byte_offset

        ; 6th bit not set - so it's a double byte offset
        ; which is an absolute offset from the start of the
        ; A-code

        ; Sets the current a-code execution address to:
        ;    $5C20 + opcode1 + opcode2 * 256

        ; Get the LSB increment
        JSR     fn_get_next_a_code_byte

        ; Add the increment onto the virtual machine start
        ; address ($5C20) and push it onto the stack
        CLC
        ADC     data_a_code_address_lsb
        PHA

        ; Preserve the CPU registers (most interested in preserving
        ; the carry flag from the addition above to add to the MSB
        ; later)
        PHP

        ; Get the MSB increment 
        JSR     fn_get_next_a_code_byte

        ; Pull the processor status from the stack (most interested
        ; in the carry flag status here to add any carry)
        PLP

        ; Add the MSB increment and store it
        ADC     data_a_code_address_msb
        STA     zp_a_code_ptr_msb

        ; Get the LSB calculated earlier and store it
        PLA
        STA     zp_a_code_ptr_lsb

        ; Double byte offset added
        RTS

;7926
.single_byte_offset

        ; The single byte offset is between -128 and +127 
        ; (in 2's complement binary). This piece of code
        ; performs a relative offset to where the a-code
        ; execution address currently is.
        ;
        ; If the single byte offset is positive:
        ;    a-code execution address = a-code execution address + single byte offset
        ;
        ; If the single byte offset is negative:
        ;    a-code execution address = a-code execution address + single byte offset - 1
        ; Note that the single byte offset is negative so it's a subtraction in reality
        ;
        ; The X register is used to hold either 0 $00) or -1 ($FF)
        ; 

        ; Initialise X to $00 - nothing to add if the single byte offset
        ; is zero but if it is negative then this will be set later to -1 ($FF)
        LDX     #$00

        ; Cache the current a-code execution address 
        ; and cache for the time being
        LDA     zp_a_code_ptr_lsb
        STA     zp_temp_cache_2
        LDA     zp_a_code_ptr_msb
        STA     zp_temp_cache_3

        ; Get the next byte which is the address to offset
        ; either plus or minus (if it's < 127 then it's plus
        ; if it's >=127 it's minus)
        JSR     fn_get_next_a_code_byte

        ; Cache the single byte offset value
        PHA
        
        ; Check to see if the 8th bit is set
        ; ($80 = 1000 0000), if it isn't then 
        ; branch (don't need to subtract one from the 
        ; calculation when it's a positive offset)
        AND     #$80
        BEQ     perform_goto_calc

        ; 8th bit set - so the value is < 0 in 2's complement binary

        ; Change the X value from $00 to $FF (-1) so the calculation will be 
        ; a-code execution address = a-code execution address + single byte offset - 1
        ; Note that the single byte offset is negative so it's a subtraction in reality
        LDX     #$FF

;793A
.perform_goto_calc
        ; Retrieve the offset value
        PLA

        ; Add the offset value onto the 
        CLC
        ADC     zp_temp_cache_2
        STA     zp_a_code_ptr_lsb

        ; Store either $00 or $FF depending on bit 8
        STX     zp_temp_cache_1

        ; Add any carry to the MSB
        LDA     zp_temp_cache_3
        ADC     zp_temp_cache_1
        STA     zp_a_code_ptr_msb

        ; Single byte offset added
        RTS        

.fn_cmd_if_var1_equals_var2_then_goto
        ; -----------------------------------------------
        ; Virtual Machine A-code opcode 16 ($10) - ifeqvt
        ;
        ; This has the following A-code format:
        ;     <operator> <operand1> <operand2> <operand3> [<operand4>]
        ; 
        ; <operator> (bits 1-5) = $10 / 10000
        ; <operator> (bit  6  ) = 0 (two offset operands) or 1 (one offset operand)
        ; <operator> (bit  7  ) = not used
        ; <operator> (bit  8  ) = 0 (to indicate a command)
        ;
        ; If bit 6 is set to 1:
        ;
        ; <operand1>   - Variable 1 to compare with variable 2
        ; <operand2>   - Variable 2 to compare with variable 1
        ; <operand3>   - single byte relative signed offset (-127 to +128)
        ;
        ; If bit 6 is set to 0:
        ;
        ; <operand1>   - Variable 1 to compare with variable 2
        ; <operand2>   - Variable 2 to compare with variable 1
        ; <operand3>   - LSB of the absolute offset to add to the A-code start address
        ; <operand4>   - MSB of the absolute offset to add to the A-code start address
        ; 

        ; Get variable number 1 and variable number 2 operands
        ; from the a-code and calculate their memory addresses
        ; Then retrieve their values and subtract variable 1
        ; from variable 2. It will then return the 6502 
        ; processor flags to allow this code to check it
        JSR     fn_get_var1_and_var2_and_check_if_equal

        ; If they are the same, the zero flag wil be set
        ; so branch if it is set and perform the goto
        BEQ     fn_cmd_goto

        ; They are not the same so do not perform the goto

;794E
.skip_over_operands
        ; Check the 6th bit of the operator to see if the
        ; goto had one or two operands.  This code just
        ; moves the a-code pointer to the next operator
        ; beyond this operator's operands
        LDA     zp_opcode_6th_bit

        ; If the 6th bit is set to zero then there are 
        ; two operands.  Skip ahead if there's only one
        CMP     #$00
        BNE     only_one_operand

        ; Skip over the first operand
        JSR     fn_get_next_a_code_byte

;7957
.only_one_operand
        ; Skip over the first or second operand and return
        JMP     fn_get_next_a_code_byte

;795A
.fn_cmd_if_var1_does_not_equal_var2_then_goto
        ; -----------------------------------------------
        ; Virtual Machine A-code opcode 17 ($11) - ifneqvt
        ;
        ; This has the following A-code format:
        ;     <operator> <operand1> <operand2> <operand3> [<operand4>]
        ; 
        ; <operator> (bits 1-5) = $11 / 10001
        ; <operator> (bit  6  ) = 0 (two offset operands) or 1 (one offset operand)
        ; <operator> (bit  7  ) = not used
        ; <operator> (bit  8  ) = 0 (to indicate a command)
        ;
        ; If bit 6 is set to 1:
        ;
        ; <operand1>   - Variable 1 to compare with variable 2
        ; <operand2>   - Variable 2 to compare with variable 1
        ; <operand3>   - single byte relative signed offset (-127 to +128)
        ;
        ; If bit 6 is set to 0:
        ;
        ; <operand1>   - Variable 1 to compare with variable 2
        ; <operand2>   - Variable 2 to compare with variable 1
        ; <operand3>   - LSB of the absolute offset to add to the A-code start address
        ; <operand4>   - MSB of the absolute offset to add to the A-code start address
        ; 
        ; Check to see if variable 1 does not equal variable 2
        ; If they do not equal each other, perform a goto command
        ; Otherwise move the a-code pointer to after the operands

        ; Get variable number 1 and variable number 2 operands
        ; from the a-code and calculate their memory addresses
        ; Then retrieve their values and subtract variable 1
        ; from variable 2. It will then return the 6502 
        ; processor flags to allow this code to check it
        JSR     fn_get_var1_and_var2_and_check_if_equal

        ; If they are the different, the zero flag wil NOT be set
        ; so branch if it is set and perform the goto
        BNE     fn_cmd_goto

        ; They are equal so jump to the common piece
        ; of code that most the a-code pointer to after
        ; the operands for this operator and points at the
        ; start of the next operator
        JMP     skip_over_operands

;7962
.fn_cmd_if_var1_less_than_var2_then_goto
        ; -----------------------------------------------
        ; Virtual Machine A-code opcode 18 ($12) - ifltvt
        ;
        ; This has the following A-code format:
        ;     <operator> <operand1> <operand2> <operand3> [<operand4>]
        ; 
        ; <operator> (bits 1-5) = $12 / 10010
        ; <operator> (bit  6  ) = 0 (two offset operands) or 1 (one offset operand)
        ; <operator> (bit  7  ) = not used
        ; <operator> (bit  8  ) = 0 (to indicate a command)
        ;
        ; If bit 6 is set to 1:
        ;
        ; <operand1>   - Variable 1 to compare with variable 2
        ; <operand2>   - Variable 2 to compare with variable 1
        ; <operand3>   - single byte relative signed offset (-127 to +128)
        ;
        ; If bit 6 is set to 0:
        ;
        ; <operand1>   - Variable 1 to compare with variable 2
        ; <operand2>   - Variable 2 to compare with variable 1
        ; <operand3>   - LSB of the absolute offset to add to the A-code start address
        ; <operand4>   - MSB of the absolute offset to add to the A-code start address
        ; 
        ; Check to see if variable 1 < variable 2
        ; If variable 1 < variable 2, perform a goto command
        ; Otherwise move the a-code pointer to after the operands

        ; Get variable number 1 and variable number 2 operands
        ; from the a-code and calculate their memory addresses
        ; Then retrieve their values and subtract variable 1
        ; from variable 2. It will then return the 6502 
        ; processor flags to allow this code to check it
        JSR     fn_get_var1_and_var2_and_check_if_equal

        ; Check to see if the carry is clear
        ; Is variable 1 <= variable 2 if not then branch
        BCC     skip_over_operands

        ; This means that variable1 <= variable2 as no borrow occured
        ; that would have set the carry flag (routine above performs a 
        ; variable 2 - variable 1 and returns the flags)
        ; had to occur

        ; Check to see if the zero flag is set
        ; Is variable 1 < variable 2 if not then branch (they are equal)
        BEQ     skip_over_operands

        ; Variable 1 is less than variable 2 so 
        ; perform the goto
        JMP     fn_cmd_goto

;796C
.fn_cmd_if_var1_greater_than_var2_then_goto
        ; -----------------------------------------------
        ; Virtual Machine A-code opcode 19 ($13) - ifltvt
        ;
        ; This has the following A-code format:
        ;     <operator> <operand1> <operand2> <operand3> [<operand4>]
        ; 
        ; <operator> (bits 1-5) = $13 / 01101
        ; <operator> (bit  6  ) = 0 (two offset operands) or 1 (one offset operand)
        ; <operator> (bit  7  ) = not used
        ; <operator> (bit  8  ) = 0 (to indicate a command)
        ;
        ; If bit 6 is set to 1:
        ;
        ; <operand1>   - Variable 1 to compare with variable 2
        ; <operand2>   - Variable 2 to compare with variable 1
        ; <operand3>   - single byte relative signed offset (-127 to +128)
        ;
        ; If bit 6 is set to 0:
        ;
        ; <operand1>   - Variable 1 to compare with variable 2
        ; <operand2>   - Variable 2 to compare with variable 1
        ; <operand3>   - LSB of the absolute offset to add to the A-code start address
        ; <operand4>   - MSB of the absolute offset to add to the A-code start address
        ; 
        ; Check to see if variable 1 > variable 2
        ; If variable 1 > variable 2, perform a goto command
        ; Otherwise move the a-code pointer to after the operands

        ; Get variable number 1 and variable number 2 operands
        ; from the a-code and calculate their memory addresses
        ; Then retrieve their values and subtract variable 1
        ; from variable 2. It will then return the 6502 
        ; processor flags to allow this code to check it
        JSR     fn_get_var1_and_var2_and_check_if_equal

        ; Check to see if the carry is set
        ; Is variable 1 > variable 2 if not then branch

        ; The carry flag is set if a borrow occurred 
        ; (routine above performs a variable 2 - variable 1
        ; and returns the flags) 
        BCS     skip_over_operands

        ; Variable 1 is greater than variable 2 so 
        ; perform the goto
        JMP     fn_cmd_goto

;7973
.fn_cmd_if_var1_equals_constant_then_goto
        ; -----------------------------------------------
        ; Virtual Machine A-code opcode 24 ($18) - ifeqct
        ;
        ; This has the following A-code format:
        ;     <operator> <operand1> <operand2> <operand3> [<operand4>]
        ; 
        ; <operator> (bits 1-5) = $18 / 11000
        ; <operator> (bit  6  ) = 0 (two offset operands) or 1 (one offset operand)
        ; <operator> (bit  7  ) = not used
        ; <operator> (bit  8  ) = 0 (to indicate a command)
        ;
        ; If bit 6 is set to 1:
        ;
        ; <operand1>   - Variable 1 to compare with variable 2
        ; <operand2>   - Variable 2 to compare with variable 1
        ; <operand3>   - single byte relative signed offset (-127 to +128)
        ;
        ; If bit 6 is set to 0:
        ;
        ; <operand1>   - Variable 1 to compare with variable 2
        ; <operand2>   - Variable 2 to compare with variable 1
        ; <operand3>   - LSB of the absolute offset to add to the A-code start address
        ; <operand4>   - MSB of the absolute offset to add to the A-code start address
        ; 

        ; Get variable number 1 and variable number 2 operands
        ; from the a-code and calculate their memory addresses
        ; Then retrieve their values and subtract variable 1
        ; from variable 2. It will then return the 6502 
        ; processor flags to allow this code to check it
        JSR     fn_get_var_and_constant_and_check_if_equal

        ; If the zero flag isn't set after the subtraction then they the variable
        ; does not equal the constant so br
        BNE     skip_over_operands

        ; Variable 1 is equals the constant so
        ; perform the goto
        JMP     fn_cmd_goto

;797B
.fn_cmd_if_var1_does_not_equal_constant_then_goto
        ; -----------------------------------------------
        ; Virtual Machine A-code opcode 25 ($19) - ifnect
        ;
        ; This has the following A-code format:
        ;     <operator> <operand1> <operand2> <operand3> [<operand4>]
        ; 
        ; <operator> (bits 1-5) = $19 / 11001
        ; <operator> (bit  6  ) = 0 (two offset operands) or 1 (one offset operand)
        ; <operator> (bit  7  ) = not used
        ; <operator> (bit  8  ) = 0 (to indicate a command)
        ;
        ; If bit 6 is set to 1:
        ;
        ; <operand1>   - Variable 1 to compare with variable 2
        ; <operand2>   - Variable 2 to compare with variable 1
        ; <operand3>   - single byte relative signed offset (-127 to +128)
        ;
        ; If bit 6 is set to 0:
        ;
        ; <operand1>   - Variable 1 to compare with variable 2
        ; <operand2>   - Variable 2 to compare with variable 1
        ; <operand3>   - LSB of the absolute offset to add to the A-code start address
        ; <operand4>   - MSB of the absolute offset to add to the A-code start address
        ; -----------------------------------------------

        ; Get variable number 1 and the constant operands
        ; from the a-code. Calculate the memory address 
        ; for the variable. Retrieve the value of the 
        ; variable and the constant. It will then subtract
        ; the constant from the variable value
        ; It will then return the 6502 
        ; processor flags to allow this code to check it   
        JSR     fn_get_var_and_constant_and_check_if_equal

        ; They are equal so jump to the common piece
        ; of code that most the a-code pointer to after
        ; the operands for this operator and points at the
        ; start of the next operator
        BEQ     skip_over_operands

        ; Variable 1 does not equal the constant so
        ; perform the goto
        JMP     fn_cmd_goto

;7983
.fn_cmd_if_var1_is_less_than_constant_then_goto
        ; -----------------------------------------------
        ; Virtual Machine A-code opcode 26 ($1A) - ifltct
        ;
        ; This has the following A-code format:
        ;     <operator> <operand1> <operand2> [<operand3>]
        ; 
        ; <operator> (bits 1-5) = $1A / 11010
        ; <operator> (bit  6  ) = 0 (two offset operands) or 1 (one offset operand)
        ; <operator> (bit  7  ) = not used
        ; <operator> (bit  8  ) = 0 (to indicate a command)
        ;
        ; If bit 6 is set to 1:
        ;
        ; <operand1>   - Variable 1 to compare with variable 2
        ; <operand2>   - single byte relative signed offset (-127 to +128)
        ;
        ; If bit 6 is set to 0:
        ;
        ; <operand1>   - Variable 1 to compare with variable 2
        ; <operand2>   - LSB of the absolute offset to add to the A-code start address
        ; <operand3>   - MSB of the absolute offset to add to the A-code start address
        ; -----------------------------------------------
        ;
        ; Check to see if the variable is less than the constant
        ; If it is perform the goto
        ; It not just move to the next instruction

        ; Get variable number 1 and the constant operands
        ; from the a-code. Calculate the memory address 
        ; for the variable. Retrieve the value of the 
        ; variable and the constant. It will then subtract
        ; the constant from the variable value
        ; It will then return the 6502 
        ; processor flags to allow this code to check it   
        JSR     fn_get_var_and_constant_and_check_if_equal

        ; If the variable value equals the constant then 
        ; jump to the common piece
        ; of code that most the a-code pointer to after
        ; the operands for this operator and points at the
        ; start of the next operator (don't perform the goto)
        BEQ     skip_over_operands

        ; If no borrow occured when the constant was subtracted
        ; from the variable then the variable is less than the constant
        ; The carry flag will be cleared if a borrow occured so in that 
        ; instance the variable is greater than the constant, so branch 
        ; away and don't perform the goto
        BCC     skip_over_operands

        ; Variable 1 is less than the constant so
        ; perform the goto
        JMP     fn_cmd_goto

;798D
.fn_cmd_if_var1_is_greater_than_constant_then_goto
        ; -----------------------------------------------
        ; Virtual Machine A-code opcode 27 ($1B) - ifgtct
        ;
        ; This has the following A-code format:
        ;     <operator> <operand1> <operand2> [<operand3>]
        ; 
        ; <operator> (bits 1-5) = $1B / 11010
        ; <operator> (bit  6  ) = 0 (two offset operands) or 1 (one offset operand)
        ; <operator> (bit  7  ) = not used
        ; <operator> (bit  8  ) = 0 (to indicate a command)
        ;
        ; If bit 6 is set to 1:
        ;
        ; <operand1>   - Variable 1 to compare with variable 2
        ; <operand2>   - single byte relative signed offset (-127 to +128)
        ;
        ; If bit 6 is set to 0:
        ;
        ; <operand1>   - Variable 1 to compare with variable 2
        ; <operand2>   - LSB of the absolute offset to add to the A-code start address
        ; <operand3>   - MSB of the absolute offset to add to the A-code start address
        ; -----------------------------------------------
        ;
        ; Check to see if the variable is greater than the constant
        ; If it is perform the goto
        ; It not just move to the next instruction

        ; Get variable number 1 and the constant operands
        ; from the a-code. Calculate the memory address 
        ; for the variable. Retrieve the value of the 
        ; variable and the constant. It will then subtract
        ; the constant from the variable value
        ; It will then return the 6502 
        ; processor flags to allow this code to check it  
        JSR     fn_get_var_and_constant_and_check_if_equal        

        ; If a borrow occured when the constant was subtracted
        ; from the variable then the variable is greater than the constant
        ; The carry flag will be cleared if a borrow occured so if it's
        ; set then the variable is less than or equal to than the constant, 
        ; so branch away and don't perform the goto
        BCS     skip_over_operands

        ; Variable 1 is greater than the constant so
        ; perform the goto
        JMP     fn_cmd_goto

;7996
.fn_get_var1_and_var2_and_check_if_equal
        ; ------------------------------------
        ; TODO
        ;  ------------------------------------
        ; Reads the operand which contains the first
        ; variable. Each variable is 16-bit and its
        ; memory location is calcuated using:
        ; Address = 2 * value + $0400. 
        ;
        ; zp_variable_ptr_lsb/msb ($70/$71) contain the address of the
        ; variable's lower 8-bits
        ; 
        ; The lower 8-bits of the variable's value are
        ; returned in A
        JSR     fn_get_a_code_variable_number

        ; Moves the memory address in $70/$71 into $74/$75
        ; - this is the copy from address
        JSR     fn_copy_memory_address_ptr

        ; Reads the operand which contains the second
        ; variable. Each variable is 16-bit and its
        ; memory location is calcuated using:
        ; Address = 2 * value + $0400. 
        ;
        ; zp_variable_ptr_lsb/msb ($70/$71) contain the address of the
        ; variable's lower 8-bits
        ; 
        ; The lower 8-bits of the variable's value are
        ; returned in A        
        JSR     fn_get_a_code_variable_number

        ; First  variable pointed at by $74/$75
        ; Second variable pointed at by $70/$71

        JMP     fn_check_if_equal

;79A2
.fn_get_var_and_constant_and_check_if_equal

        ; Reads the operand which contains the second variable's number
        ; Each variable is 16-bit and its memory location is calcuated using:
        ;     Address = 2 * value + $0400. 
        ;
        ; zp_variable_ptr_lsb/msb ($70/$71) contains the address of the
        ; variable's lower 8-bits
        ; 
        ; The lower 8-bits of the variable's value are
        ; returned in A
        JSR     fn_get_a_code_variable_number

        ; Moves the memory address in $70/$71 into $74/$75
        ; - this is the copy from address - this is the variable
        JSR      fn_copy_memory_address_ptr

        ; Retrieve the constant operand(s) and store in
        ; $72/$73
        JSR     fn_get_a_code_opcode_operands

        ; Set the constant address location in $70/$71 to point 
        ; at $72/$73 where the constant is held
        JSR     fn_set_constant_address_location

        ; At this point 
        ; $70/$71 points at the constant in $72/$73 (this is variale 1 below)
        ; $72/$73 contains the constant
        ; $74/$75 points at the LSB of the variable

        ; Continues

;79AE
.fn_check_if_equal
        ; ----------------------------------------------------
        ; Checks to see if the two numbers in variable1 and variable2
        ; are equal.  It does this by:
        ; 1. Subtracting variable 1's MSB from variable 2's MSB
        ; 2. If they are the same, then it will subtract 
        ;    variable 1's LSB from variable 2's LSB
        ; 3. Return the status flags for the caller to check
        ; ----------------------------------------------------
        ; Subtract the MSB of variable 1 from the MSB of variable 2
        SEC
        LDY     #$01
        LDA     (zp_variable_ptr_lsb),Y
        SBC     (zp_cached_ptr_lsb),Y

        BNE     return_check_if_equal

        ; Subtract the LSB of variable 1 from the LSB of variable 2
        DEY
        SEC
        LDA     (zp_variable_ptr_lsb),Y
        SBC     (zp_cached_ptr_lsb),Y
.return_check_if_equal
        RTS

;79BD
.fn_cmd_exit
        ; Virtual Machine A-code opcode 15 ($0F) - exit
        ;
        ; This has the following A-code format:
        ;     <operator> <operand1> <operand2> <operand3> <operand4>
        ; 
        ; <operator> (bits 1-5) = $0F / 01111
        ; <operator> (bit  6  ) = not used
        ; <operator> (bit  7  ) = not used
        ; <operator> (bit  8  ) = 0 (to indicate a command)
        ;
        ; <operand1>   - Player's current location
        ; <operand2>   - Move direction
        ; <operand3>   - Exit flags if move allowed in move direction
        ; <operand4>   - Target location if move allowed in move direction
        ; -----------------------------------------------
        ;
        ; Performs the following:
        ;
        ; 1. Loops through the exits information until it finds
        ;    the start of location n's exits
        ; 2. It then loops through the exits for location n
        ;    comparing the player's requested direction with the exit
        ;    direction
        ; 3. If it finds a match it returns with this 
        ; 4. If it doesn't find a match it performs "reverse direction"
        ;    lookup
        ; 5. So it starts looping through again and looks to see
        ;    if it's possible to get to the current location using the
        ;    inverse direction e.g. if the player wanted to N from location 1,
        ;    can they go S from another location to locaiton 1?
        ; 6. The inverse direction is only allowed if bit 5 is set e.g.
        ;    going West in a maze from one location may not allow going East
        ;    back to the same place.  Or it might be a one way only direction
        ; 6. If it finds a match it returns with this
        ; 7. Otherwise the move direction is not allowed

        ; Reads <operand1> which contains the variable 
        ; number that holds the "from location".  Each variable 
        ; is 16-bit and its memory location is calcuated using:
        ; Address = 2 * value + $0400. 
        ;
        ; zp_variable_ptr_lsb/msb ($70/$71) contain the address of the
        ; variable's lower 8-bits
        ; 
        ; The lower 8-bits of the variable's value are
        ; returned in A
        JSR     fn_get_a_code_variable_number

        ; Store the from location 
        STA     zp_from_location

        ; Reads <operand2> which contains the variable 
        ; number that holds the "move direction" e.g. 3 = east.
        ; Each variable is 16-bit and its memory location is calcuated using:
        ; Address = 2 * value + $0400. 
        ;
        ; zp_variable_ptr_lsb/msb ($70/$71) contain the address of the
        ; variable's lower 8-bits
        ; 
        ; The lower 8-bits of the variable's value are
        ; returned in A
        JSR     fn_get_a_code_variable_number

        ; Store the move direction 
        STA     zp_move_direction

        ; Check the exits information to see if the move is allowed
        JSR     fn_check_if_move_direction_allowed

        ; Get the top 3 bits by masking with 0x01110000
        ; These bits are the exit flags
        ; Bit 7 - Is there a door in the way in that direction
        ; Bit 6 - Should the exit be hidden (not shown in the room description)
        ; Bit 5 - Can this room be used for inverse direction lookup
        AND     #$70

        ; Shift bits 7-5 into bits 1-3 by rotating them right 4 times
        LSR     A
        LSR     A
        LSR     A
        LSR     A

        ; Get the exits variable number <operand3> and set it to the exit flags
        JSR     fn_set_variable_value

        ; Get the target location variable number <operand4>
        ; and set it to the target location.  And return (hence the JMP)
        LDA     zp_to_location
        JMP     fn_set_variable_value

;79D9
.fn_check_if_move_direction_allowed
        ; Set the exits pointer to $1B00
        JSR     fn_reset_exits_ptr

        ; Load the from location into X as an index
        LDX     zp_from_location        

        ; Subtract 1 to see if it is zero - it is then
        ; it's the first location and the zp_exits_pointer_lsb/msb
        ; are already pointing at the exits for this location
        DEX

        ; Branch ahead if already pointing at the first location
        BEQ     loop_check_location_exits_for_match

.loop_find_nth_location_exits_start
        ; Not at the first location so have to loop through 
        ; and find the start of the exits for location n

        ; Location exit definitions are 2 bytes (16-bits)
        ; The first byte is defined as:
        ; Bit 8    - Denotes that this is the last location exit
        ;            definition for location n
        ; Bit 7    - Is there a door in the way?
        ; Bit 6    - Should this exit be hidden (not showin the room description)
        ; Bit 5    - Whether it can be used for inverse location lookup
        ; Bits 1-4 - 
        ; Get the the byte that the exit pointer is pointing at
        JSR     fn_get_exits_or_dictionary_byte

        ; Preserve this on the stack
        PHA

        ; Each location exit definition is 16-bits / 2 bytes
        ; so move to the next location exit definition
        JSR     fn_inc_dictionary_or_exits_ptr
        JSR     fn_inc_dictionary_or_exits_ptr

        ; Retrieve the byte from the previous location exit
        ; definition
        PLA

        ; Check to see if the 8th bit is set ($80 / 1000 0000)
        AND     #$80

        ; Loop if it's not set to get to one where it is set
        BEQ     loop_find_nth_location_exits_start

        ; Byte is the last location exit definition for 
        ; a location (bit 8 is set)

        ; Decrement the location count to see if we have found
        ; the nth location 
        DEX

        ; If it's not zero, then we still have to loop through more
        ; location exits definitions
        BNE     loop_find_nth_location_exits_start

        ; At this point the zp_exits_ptr_lsb/msb will point to the
        ; start of the location exits definition for location n        

;79F3
.loop_check_location_exits_for_match
        ; Get the first byte of the location exit information pair
        JSR     fn_get_exits_or_dictionary_byte

        ; The bottom 4-bits of the first byte of 
        ; each location exit definition indicate the 
        ; exit direction e.g. south or west
        
        ; Mask to get the bottom four bits
        AND     #$0F

        ; Compare them with the direction the player requested to move 
        CMP     zp_move_direction

        ; Branch ahead if the location exit information direction does
        ; not match the direction that the player requested to move
        BNE     direction_did_not_match_player_direction

        ; Exit direction matches the player's required to move direction

        ; Re-read the first byte of the direction exit information pair
        JSR     fn_get_exits_or_dictionary_byte

        ; Preserve the exit direction
        PHA

        ; Move the exits pointer to the second byte of the 
        ; location exit information
        JSR     fn_inc_dictionary_or_exits_ptr

        ; Get the second byte of the location exit information
        ; This contains the "to location" if the move direction is
        ; taken
        JSR     fn_get_exits_or_dictionary_byte

        ; Set the "to location"
        STA     zp_to_location

        ; Restore the exit direction (calling code
        ; will extract bits 5-7 from it as they are exit
        ; information flags)
        PLA

        ; Return!
        RTS

;7A0A
.direction_did_not_match_player_direction

        ; Re-read the first byte of the direction exit information pair
        JSR     fn_get_exits_or_dictionary_byte

        ; Check to see if this was the last location exit informatin
        ; byte pair for this location (the 8th bit will be set)
        AND     #$80

        ; Branch ahead if it's set - all exits for this location
        ; have been processed
        BNE     check_locations_for_inverse_direction

        ; It's not the last exit for this location so move ahead
        ; 2 bytes to the next location exit information pair
        JSR     fn_inc_dictionary_or_exits_ptr
        JSR     fn_inc_dictionary_or_exits_ptr

        ; Loop back and check the next location exit information pair
        JMP     loop_check_location_exits_for_match

;7A1A
.check_locations_for_inverse_direction
        ; Load the player's requests move direction
        LDX     zp_move_direction

        ; Use it as an index into the inverse directions table
        ; e.g. West = East, North = South, NW = SE
        LDA     data_inverse_directions_table,X

        ; Store the inverse direction
        STA     zp_move_direction

        ; Reset the exits pointer
        JSR     fn_reset_exits_ptr

        ; Set the location counter to 1 - we're
        ; testing that first to see if it's possible
        ; to get from there back to the player's current
        ; location using the inverse direction
        LDA     #$01
        STA     zp_inverse_direction_counter

;7A48
.loop_check_next_location_for_inverse_direction
        JSR     fn_get_exits_or_dictionary_byte

        ; TODO
        STA     zp_temp_cache_1

        ; Check the 6th bit - if it's NOT set then this location exit
        ; cannot be used for reverse lookup
        AND     #$10
        CMP     #$00

        ; Branch if zero as this cannot be used for reverse lookup
        BEQ     exit_cannot_be_used_for_reverse_lookup

        ; Bit 6 is set so can be used

        ; The bottom 4-bits of the first byte of 
        ; each location exit definition indicate the 
        ; exit direction e.g. south or west - this code
        ; is checking if the it's possible to move in the inverse
        ; direction that the player requested to the player's current
        ; location
        
        ; Mask to get the bottom four bits
        LDA     zp_temp_cache_1
        AND     #$0F

        ; Compare this with the inverse direction
        CMP     zp_move_direction

        ; Branch away if it doesn't match 
        BNE     exit_cannot_be_used_for_reverse_lookup

        ; Direction matched inverse direction

        ; Move to the second byte of the location
        ; exit definition
        JSR     fn_inc_dictionary_or_exits_ptr

        ; Get the second byte of the location exit
        ; definition, it contains the "to location"
        JSR     fn_get_exits_or_dictionary_byte

        ; See if the "to location" matches the 
        ; current location of the player
        CMP     zp_from_location

        ; Preserve the comparison result
        PHP

        ; Move the exits pointer back to the first
        ; byte of the location exit definition as 
        ; that's the one we need to return to the caller
        JSR     fn_dec_exit_or_dictionary_pointer

        ; Restore$E0 the comparison result
        PLP

        ; Branch ahead if the "to location" did
        ; not match the player's current location
        BNE     to_location_did_not_match

        ; It matches

        ; Re-read the first byte and return it 
        ; in A
        JMP     fn_get_exits_or_dictionary_byte

;7A4D
.exit_cannot_be_used_for_reverse_lookup
.to_location_did_not_match
        ; Re-read the first byte of the location exit
        ; definition
        JSR     fn_get_exits_or_dictionary_byte

        ; Check the 8th bit to see if this is the last
        ; location exit definition for this location number
        AND     #$80

        ; If it's clear (zero) it isn't the last exit for this location number
        ; So branch ahead and process the next one for this location
        ; (Basically skips incrementing the inverse direciton location
        ; counter)
        BEQ     skip_inc_location_number

        ; Last location exit definition for the current location
        ; being checked

        ; Load the location number that we just tested
        LDX     zp_inverse_direction_counter

        ; Increment the location counter - we're going to 
        ; test the next one now to see if it's possible
        ; to get from there back to the player's current
        ; location using the inverse direction as th eprevious
        ; one didn't allow it
        INX
        STX     zp_inverse_direction_counter
.skip_inc_location_number

        ; Re-read the first byte for this location exit
        ; definition
        JSR     fn_get_exits_or_dictionary_byte

        ; Preserve the first byte of the current location exit
        ; definition
        PHA

        ; Move forward to the next location exit definition
        ; either for the same location or a the next one
        JSR     fn_inc_dictionary_or_exits_ptr
        JSR     fn_inc_dictionary_or_exits_ptr

        ; Get the first byte back for the (now) previous
        ; location exit definition
        PLA

        ; Check to see if the end of the exists list was
        ; reached - it is terminated with $00
        CMP     #$00

        ; If it's not the end of the exits list, loop around
        ; the next location's exits data
        BNE     loop_check_next_location_for_inverse_direction

        ; It is the end of the data so store the $00
        ; in the "to location" field to show it's not possible
        ; to move the way the player wanted
        STA     zp_to_location

        RTS

;7A6B
.fn_reset_exits_ptr
        ; Reset to the VM Workspace to the start
        ; of $1B00
        LDA     data_location_exits_address_lsb
        STA     zp_exits_ptr_lsb
        LDA     data_location_exits_address_msb
        STA     zp_exits_ptr_msb
        RTS

;7A76
.fn_cmd_function
        ; ----------------------------------------------------
        ; Virtual Machine A-code operator 3 ($06) - function
        ;
        ; This has the following A-code format:
        ;     <operator> <operand> 
        ; 
        ; <operator> (bits 1-5) = $06 / 00110
        ; <operator> (bit  6  ) = not used
        ; <operator> (bit  7  ) = not used
        ; <operator> (bit  8  ) = 0 (to indicate a command)
        ;
        ; <operand> - id of function to execute:
        ; $02 - Generate random seed
        ; $03 - Save game
        ; $04 - Load (restore) game
        ; $05 - Clear variables
        ; $06 - Clear stack

        ; Get the operand to find out which function needs
        ; to be called
        JSR     fn_get_next_a_code_byte

        ; Check to see if it's a request to generate 
        ; a new random seed - branch ahead if it's not
        CMP     #$02
        BNE     check_if_save_game

        ; Generate a new random seed
        JMP     fn_generate_random_seed

;7A80
.check_if_save_game
        ; Check to see if a "SAVE"  of the player's progress
        ; is required
        CMP     #$03
        BNE     check_if_load_game

        ; Save the current game
        JMP     fn_save_game

;7A87
.check_if_load_game
        ; Check to see if the player wants to restore a 
        ; previously saved game
        CMP     #$04
        BNE     check_if_clear_variables

        ; Load (restore) a saved game
        JMP     fn_load_game

.check_if_clear_variables
        ; Check to see if the game variables need to be reset
        CMP     #$05
        BEQ     fn_clear_variables

        ; Check to see if game stack needs to be reset
        CMP     #$06
        BEQ     fn_clear_stack

        ; Unknown command so invoke the reset and (perform a break)
        JMP     (RESET)


;7A99
.fn_clear_variables
        ; ----------------------------------------------------
        ; Clear the variables
        ; 
        ; Clear the variable memory between $046E and $0400
        ; for Colossal Adventure, Adventure Quest and
        ; Dungeon Adventure
        ;
        ; Bug/feature
        ; ~~~~~~~~~~~
        ; For Snowball and Lords of Time this does nothing.
        ; It randomly loops based on the value of A - to reach
        ; here the value of A will be $05 so it doubles it to
        ; $0A, transfers to X, resets A to zero and then loops
        ; $0A times before going to clear the stack.  BNE does
        ; not affect the stack.
        ; ----------------------------------------------------

IF config_savefile = "COLDAT" OR config_savefile = "QDAT" OR config_savefile = "DUNDAT"
        LDA     #$6E
ENDIF

        ; A is always $05 at this point unless 
        ; Double A to $0A
        ASL     A

        ; Set X to $0A so the code can pointlessly loop 10 times
        TAX

        ; Reset A to $00
        LDA     #$00

;7A9D
.loop_clear_var_memory
        ; Doesn't make sense why this is missing from Snowball or
        ; Lords of Time...
IF config_savefile = "COLDAT" OR config_savefile = "QDAT" OR config_savefile = "DUNDAT"
        STA     $0400,X
ENDIF

        ; Decrement X
        DEX
        
        ; Loop until X is zero
        BNE     loop_clear_var_memory

        ; Doesn't make sense why this is missing from Snowball or
        ; Lords of Time... means that for those two games it will
        ; run straight into clearing the stack too
IF config_savefile = "COLDAT" OR config_savefile = "QDAT" OR config_savefile = "DUNDAT"
        RTS
ENDIF

;7AA0  
.fn_clear_stack
        ; ----------------------------------------------------
        ; Clear the gosub stack on the stack
        ; 
        ; 1. Takes the current return address from the stack
        ; 2. Caches the return address in Y and A
        ; 3. Sets the stack pointer to $180 via X
        ; 4. Puts the return addres in A and Y back on the stack
        ; 5. Returns
        ;
        ; Bug/feature
        ; ~~~~~~~~~~~
        ; Why set the stack to $0180 or $01E0 and not $01FF?
        ; ----------------------------------------------------

        ; Get the return address and cache in Y and A
        PLA
        TAY
        PLA

IF config_savefile = "COLDAT" OR config_savefile = "QDAT" OR config_savefile = "DUNDAT"
        ; Set the stack pointer to $1E0 (why not $1FF?)
        LDX     #$E0
ELSE
        ; Set the stack pointer to $180 (why not $1FF?)
        LDX     #$80
ENDIF
        TXS

        ; Restore the return address from A and Y
        PHA
        TYA
        PHA

        ; Stack cleared
        RTS


;7AAA
.fn_brkv_handler
        ; -----------------------------------------------
        ; BRKV - Break handler 
        ; Intercepts a BRK instruction when executed - 
        ; if a BRK instruction then the address of the 
        ; byte following the BRK is held in $FD/$FE
        ; -----------------------------------------------
IF config_savefile = "COLDAT" OR config_savefile = "QDAT" OR config_savefile = "DUNDAT"
        ; Clear the stack
        JSR     fn_clear_stack
ENDIF

        ; Get the reason code for the break
        LDY     #$00
        LDA     (OS_ERROR_MSG_PTR),Y

        ; Check if break or escape caused the
        ; interrupt - branch if it wasn't break
        CMP     #$11
        BEQ     escape_pressed

        ; Write 'E' (ASCII $45) to the screen
        LDA     #$45
        JSR     OSASCI

        ; Write 'r' (ASCII $72) to the screen
        LDA     #$72
        JSR     OSASCI

        ; Write 'r' (ASCII $72) to the screen
        LDA     #$72
        JSR     OSASCI

IF config_savefile = "COLDAT" OR config_savefile = "QDAT" OR config_savefile = "DUNDAT"
        ; Write 'o' (ASCII $6F) to the screen
        LDA     #$6F
        JSR     OSASCI

        ; Write 'r' (ASCII $72) to the screen
        LDA     #$72
        JSR     OSASCI
ENDIF

        ; Write LF and CR (ASCII $OD) to the screen
        ; Send $OD to OSASCI causes both a LF and CR
        ; to be sent to the screen
        LDA     #$0D
        JSR     OSASCI

        JMP     end_brkv_handler

;7AC9
.escape_pressed
        ; Write 'E' (ASCII $45) to the screen
        LDA     #$45
        JSR     OSASCI

        ; Write 's' (ASCII $73) to the screen
        LDA     #$73
        JSR     OSASCI

        ; Write 'c' (ASCII $63) to the screen        
        LDA     #$63
        JSR     OSASCI

        ; Write 'a' (ASCII $61) to the screen
        LDA     #$61
        JSR     OSASCI

        ; Write 'p' (ASCII $61) to the screen
        LDA     #$70
        JSR     OSASCI

        ; Write 'e' (ASCII $61) to the screen
        LDA     #$65
        JSR     OSASCI

        ; Write LF and CR (ASCII $OD) to the screen
        ; Send $OD to OSASCI causes both a LF and CR
        ; to be sent to the screen
        LDA     #$0D
        JSR     OSASCI

;7AEC
.end_brkv_handler
        JMP     jump_to_a_code_virtual_machine

;7AEF
.fn_read_player_input
        ; -------------------------------------------------
        ; Read the player's next line of input
        ; On Entry:
        ;     Y - max characters to read
        ; On Exit:
        ; $0000 - string buffer containing user input 
        ; -------------------------------------------------

        ; String buffer parameter block defined at $0037
        ; XY?0..1 - string buffer location ($0000)
        ; XY?2    - maximum line length (buffer size minus 1) ($27 / 39 characters)
        ; XY?3    - minimum acceptable ascii value ($20) - space
        ; XY?4    - maximum acceptable ascii value ($7F) - delete

        ; Set up the string buffer parameter block

        ; Set the LSB for the string buffer location £xx00
        LDX     #$00
        STX     zp_input_parameter_block

        ; Set the MSB for the string buffer location £00xx
        LDX     #$00
        STX     zp_input_parameter_block+1

        ; Save the maximum line length based on the passed Y value
        STY     zp_input_parameter_block+2

        ; Set the minimum acceptable character value ($20 for space)
        LDX     #$20
        STX     zp_input_parameter_block+3

        ; Set the maxmimum acceptable character value ($7F for delete)
        LDX     #$7F
        STX     zp_input_parameter_block+4

        ; Set the MSB of the parameter block
        LDY     #HI(zp_input_parameter_block)

        ; Set the LSB of the parameter block
        LDX     #LO(zp_input_parameter_block)

        ; OSWORD $00 - Input Line
        ;
        ; Waits for the player to type a sentence
        ; up to 39 characters long terminated
        ; by a space or the escape key
        LDA     #$00
        JSR     OSWORD

        ; Check to see if the player pressed 
        ; return or escape to terminate the string
        ; Carry clear - return
        ; Carry set   - escape
        BCC     end_read_player_input

        ; Escape pressed - start a new line
        ; to and read again (discard the current read
        ; line)

        ; OSBYTE $7E
        ; Clear the escape condition
        LDA     #$7E
        JSR     OSBYTE

        ; Write a new line to the screen
        LDA     #$0D
        JSR     OSASCI

        ; Set the maximum lin length to $27 / 39
        LDY     #$27
        JMP     fn_read_player_input

;7B1B
.end_read_player_input
        ; Completed the read - process the player input
        RTS   

IF config_savefile = "TIMEDAT" OR config_savefile = "SNOWDAT"

; 7B1C
.fn_get_data_checksum
        ; ----------------------------------------------
        ; Takes a checksum of the first 114 bytes 
        ; of memory ($1200 to $1272). Uses a single byte
        ; (initially zero) and adds all the values at those
        ; memory locations to the same byte so presumably
        ; that checksum could be checked by something
        ; 
        ; This code does the following:
        ; 
        ; 1. Sets the start address to $1200
        ;    in $6A/$6B
        ; 2. Sets $7328 to $00
        ; 3. Loads the value from the address in $6A/$6B
        ; 4. Adds the value in $7328
        ; 5. Stores the value in $7328
        ; 6. Adds one to the address in $6A/$6B
        ; 7. Loops back around if $7328 is less than $73/115
        ; 8. Returns
        ; ----------------------------------------------
        
        ; Set the LSB of the address ($006A) to $00
        LDA     #$00
        STA     zp_temp_cache_1

; Only Lords of time needs this
IF config_savefile = "TIMEDAT"
        ; Set the start value of the checksum to $00      
        LDA     #$00
ENDIF    
        ;$7328
        STA     data_calculated_checksum ; contains $EA (NOP)by default

        ; Set the MSB ($006B) of the address to $12  
        LDA     data_checksum_start_page_msb
        STA     zp_temp_cache_2

        ; Start address in $6A/$6B is $1200

        ; Set the index counter to zero
        ; (Never changes as the actual address
        ;  is updated repeatedly)
        LDY     #$00

;7B2C
.loop_checksum_calc
        ; Get the byte at the address specified in $6A/$6B
        ; starting at $1200 and looping until $7300 is reached
        ; (last address used will be $72FF)
        LDA     (zp_temp_cache_1),Y   ; $00 first time around

        ; Add this to the checksum 
        CLC
        ADC     data_calculated_checksum  ; $00 first time around for LoT
        STA     data_calculated_checksum  

        ; $6A/$6B = $1200, the start address tje first time around
        ; Add one to 006A, the LSB 
        ; Add one to the memory location
        LDA     zp_temp_cache_1
        CLC
        ADC     #$01
        STA     zp_temp_cache_1

        ; Add any carry to 006B, the MSB
        LDA     zp_temp_cache_2
        ADC     #$00
        STA     zp_temp_cache_2

        ; Goes around this loop until $7300 is the
        ; next address and stops

        ; Check how many times around this loop
        CMP     data_checksum_loop_counter_max

        ; Loop back around if the address is < $7300
        BNE     loop_checksum_calc

        ; Return - checksum isin $7328
        RTS
ENDIF

;7B48
.fn_actually_printnumber
        ; On entry:
        ;    A is undefined
        ;    X contains the MSB of the number to print
        ;    Y contains the LSB of the number to print

        ; Cache the number's LSB in $6A
        STY     zp_number_lsb
        
        ; Cache the number's MSB in $6B
        STX     zp_number_msb

        ; Check to see if any bits are set in the MSB or LSB
        ; (simple check to see if the 16-bit value is zero)
        LDA     #$00
        ORA     zp_number_lsb
        ORA     zp_number_msb

IF config_savefile = "COLDAT" OR config_savefile = "QDAT"
        ; Bug/feature
        ; ~~~~~~~~~~~
        ; This looks to be a bug in the older engine
        ; as it doesn't print a zero just returns
        BEQ     print_number_complete
ELSE
        ; Branch if the 16-bit value is zero,
        ; to print a single zero
        BEQ     print_zero
ENDIF

        ; 16-bit value is not zero

        ; Indicates if a digit has been found in a 10^nth digit
        ; position.  If it has then this will be set to 1 and
        ; remain set to 1 until all the remaining digits to the 
        ; right have been printed too
        LDA     #$00
        STA     zp_digit_found_flag

        ; Set the address of the nth digit lookup table 
        ; Lookup table contains
        ; Hex      Dec
        ; ---      ---
        ; $2710 - 10,000
        ; $03E8 -  1,000
        ; $0064 -    100
        ; $000A -     10
        ; $0000 -      0
        ; 
        ; These are used to determine:
        ; 1. nth digit position that contains the first number digit
        ; 2. The digit to print (how many times can the lookup table number
        ;    be subtracted)
        ; 3. The value from (2) gets added to the ASCII code for 0 ($30) so if 
        ;    the lookup table value can be subtracted 5 times then $30+5 will be
        ;    printed

        ; Store the address of the power of ten lookup table
        ; $7BAC
        LDA     #LO(data_power_of_ten_table)
        STA     zp_digit_pos_lookup_table_lsb
        LDA     #HI(data_power_of_ten_table)
        STA     zp_digit_pos_lookup_table_msb

        ; Used to index the lookup table and pull out the value
        ; to determine if there are any digits in the nth position
        LDY     #$00
        STY     zp_digit_pos_lookup_table_offset

 ;7B64
.move_to_next_digit_pos_outer_loop
        ; Loop through the number to check if any digits should be 
        ; printed for ten thousands, thousands, hundreds, tens and digits
        ; 
        ; It uses a lookup table for the values and subtracts
        ; each from the 16-bit number - if there is 
        ; $2710 - 10,000
        ; $03E8 -  1,000
        ; $0064 -    100
        ; $000A -     10
        ; 
        ; Starts at 10,000 and iterates through to 10 - subtracting
        ; to see where the first digit is (inner_loop). First digit is 
        ; detected wheren there is a remainder from <number> - <10^n>.

        ; Read the next 10^n LSB value from the table (starts at 10,000)
        ; and cache the LSB in $6C
        LDY     zp_digit_pos_lookup_table_offset
        LDA     (zp_digit_pos_lookup_table_lsb),Y
        STA     zp_temp_cache_3

        ; Increment the offset to point at the MSB
        INY

        ; Read the next 10^n MSB value from the table (starts at 10,000)
        ; and cache the MSB in $6C
        LDA     (zp_digit_pos_lookup_table_lsb),Y
        STA     zp_temp_cache_4

        ; Increment the offset to point at the next 10^n value for the 
        ; next time around the loop
        INY
        STY     zp_digit_pos_lookup_table_offset


        ; If the LSB and MSB of the 10^n value are both zero, all digit
        ; positions have been checked - OR them together to check
        LDA     #$00
        ORA     zp_temp_cache_3
        ORA     zp_temp_cache_4

        ; If both values are zero then we have been through the list
        ; If it $6C OR'd with $6D is zero then branch ahead and return
        BEQ     print_number_complete

        ; Load the ASCII code for zero 
        LDA     #$30
        STA     zp_number_ascii_code
 
;7B7E
.subtraction_inner_loop
        ; This loop checks to see initially if there are 
        ; any digits in this 10^nth digit position.  It does this by
        ; subtracting the 10^nth from the 16-bit number and if 
        ; the carry flag is set then the 16-bit number is greater than
        ; the 10^nth number and has a digit in this position.  
        ; zp_digit_found_flag will then be set so all subsequent
        ; times around the outer loop, a digit will be printed.
        ;
        ; First digit position through loop 
        ; 1. ASCII value to print is set to $30 for 0
        ; 2. Assume number to print is 2,001
        ; 3. Subtract 10,000 from 16-bit number to print
        ; 4. If carry flag is clear than there are no digits in this position 
        ;    (number is less than 10,000) 
        ; 
        ; Second digit position through loop
        ; 1.  Subtract 1,000 from 16-bit number to print
        ; 2.  Number was bigger than 1,000 (it was 2,001)
        ; 3.  Set flag to indicate digits found in this position
        ; 4.  Increment the ascii number to print ($31 for 1)
        ; 5.  Update cached 16-bit number to subtract 1,000 so set to 1,001
        ; 6.  Loop back around the inner loop to subtract 1,000 again
        ; 7.  Number is still bigger than 1,000 at 1,001
        ; 8.  Set flag to indicate digits found in this position
        ; 9.  Update cached 16-bit number to subtract another 1,000 so set to 1
        ; 10. Increment the ascii number to print ($32 for 2)
        ; 11. Loop back around the inner loop to subtract 1,000 again
        ; 12. Number is now negative so jump ahead to print it
        ;
        ; Third digit position through loop
        ; 1.  Subtract 100 from 16-bit number to print
        ; 2.  Remainder (1) is smaller than 100
        ; 3.  Jump ahead to print a zero 


        ; The next 7 lines perform a subtraction of either
        ; 10,000 or 1,000 or 100 or 10 from the 16-bit number
        ; to print.  The 10,000 etc are held in zp_temp_cache_3/4

        ; Subtract 10^n's LSB from the remainder of the number's LSB
        ; if not the first time through the loop
        LDA     zp_number_lsb
        SEC
        SBC     zp_temp_cache_3
        TAX

        ; Subtract 10^n's MSB from the remainder of the number's MSB
        ; if not the first time through the loop
        LDA     zp_number_msb
        SBC     zp_temp_cache_4
        TAY

        ; if zp_temp_cache_2 < 6D then this number is present
        ; If the 16-bit number to print, is less than the 
        ; position 
        BCC     check_if_digit_found

        ; Successful subtraction - positive remainder

        ; Increment the ASCII code as the 10^n was subctracted
        ; at least this many times
        INC     zp_number_ascii_code

        ; Found a digit 
        LDA     #$01
        STA     zp_digit_found_flag

        ; Store the remainder from the subtraction in the 
        ; the number to print cache - will loop again and 
        ; see if it can subtract it again - if not, print it
        ; and move onto the next digit
        STX     zp_number_lsb
        STY     zp_number_msb

        ; See if another 10^n can be subtracted
        JMP     subtraction_inner_loop ;7b7e

;7B98
.check_if_digit_found
        ; Was a digit found in this position
        LDA     #$00
        CMP     zp_digit_found_flag

        ; Branch if a digit was not found
        BEQ     move_to_next_digit_pos_outer_loop

        ; Write the ascii code to the screen
        LDA     zp_number_ascii_code
        JSR     fn_write_char_to_screen

        ; Move to the next number to print
        JMP     move_to_next_digit_pos_outer_loop

;7BA6
.print_zero
        ; Set A to the ASCII value for 0 ($30/48)
        LDA     #$30

        ; Print the character on the screen
        JSR     fn_write_char_to_screen

;7BAB
.print_number_complete
        RTS

;7BAC
.data_power_of_ten_table
        ; List of the numbers to subtract from the 16-bit
        ; number to be printed (in LSB MSB order)

        ; 10,000 
        EQUB    $10, $27

        ; 1,000
        EQUB    $E8, $03

        ; 100
        EQUB    $64, $00

        ; 10
        EQUB    $0A, $00

        ; 1
        EQUB    $01, $00

        ; Table terminator
        EQUB    $00, $00

;7BB8
.data_cmd_lookup_table
        ; Routines to call when the virtual machine
        ; needs to execute an a-code general command -
        ; location of the routine is the address + 1
        ; They are all called after an RTS (put on stack
        ; so the processor adds the 1 back on automatically)

        ; goto - 0
        ; $7909
        EQUB    LO(fn_cmd_goto-1)
        EQUB    HI(fn_cmd_goto-1)

        ; intgosub - 1
        ; $76A4
        EQUB    LO(fn_cmd_intgosub-1)
        EQUB    HI(fn_cmd_intgosub-1)        
        
        ; intreturn - 2 
        ; $76C9
        EQUB    LO(fn_cmd_intreturn-1)
        EQUB    HI(fn_cmd_intreturn-1)                
        
        ; printnumber -3 
        ; $7476
        EQUB    LO(fn_cmd_printnumber-1)
        EQUB    HI(fn_cmd_printnumber-1)    
        
        ; messagev - 4
        ; $7592
        EQUB    LO(fn_cmd_messagev-1)
        EQUB    HI(fn_cmd_messagev-1)        

        ; messagec - 5
        ; $75A3
        EQUB    LO(fn_cmd_messagec-1)
        EQUB    HI(fn_cmd_messagec-1)

        ; function - 6
        ; $7A75
        EQUB    LO(fn_cmd_function-1)
        EQUB    HI(fn_cmd_function-1)

        ; input - 7
        ; 7767
        EQUB    LO(fn_cmd_get_player_input-1)
        EQUB    HI(fn_cmd_get_player_input-1)

        ; varcon - 8
        ; 7737
        EQUB    LO(fn_cmd_set_variable_to_constant-1)
        EQUB    HI(fn_cmd_set_variable_to_constant-1)

        ; varvar - 9
        ; $7752
        EQUB    LO(fn_cmd_copy_from_var1_to_var2-1)
        EQUB    HI(fn_cmd_copy_from_var1_to_var2-1)

        ; _add - 10
        ; $75AD
        EQUB    LO(fn_cmd_add_var1_to_var2-1)
        EQUB    HI(fn_cmd_add_var1_to_var2-1)

        ; _sub - 11
        ; $75C7
        EQUB    LO(fn_cmd_subtract_var2_from_var1-1)
        EQUB    HI(fn_cmd_subtract_var2_from_var1-1)

        ; nothing - 12
        EQUB    $00,$00

        ; nothing - 13
        EQUB    $00,$00

        ; jump - 14
        ; $75DF
        EQUB    LO(fn_cmd_jump-1)
        EQUB    HI(fn_cmd_jump-1)

        ; exit - 15
        ; $79BD
        EQUB    LO(fn_cmd_exit-1)
        EQUB    HI(fn_cmd_exit-1)

        ; ifeqvt - 16
        ; $7948
        EQUB    LO(fn_cmd_if_var1_equals_var2_then_goto-1)
        EQUB    HI(fn_cmd_if_var1_equals_var2_then_goto-1)

        ; ifnevt - 17
        ; $7959
        EQUB    LO(fn_cmd_if_var1_does_not_equal_var2_then_goto-1)
        EQUB    HI(fn_cmd_if_var1_does_not_equal_var2_then_goto-1)

        ; ifltvt - 18   
        ; $7961
        EQUB    LO(fn_cmd_if_var1_less_than_var2_then_goto-1)
        EQUB    HI(fn_cmd_if_var1_less_than_var2_then_goto-1)

        ; ifgtvt - 19
        ; $796B
        EQUB    LO(fn_cmd_if_var1_greater_than_var2_then_goto-1)
        EQUB    HI(fn_cmd_if_var1_greater_than_var2_then_goto-1)        

        ; nothing - 20
        EQUB    $00,$00

        ; nothing - 21
        EQUB    $00,$00        

        ; nothing - 22
        EQUB    $00,$00        

        ; nothing - 23
        EQUB    $00,$00        

        ; ifeqct - 24
        ; $7973
        EQUB    LO(fn_cmd_if_var1_equals_constant_then_goto-1)
        EQUB    HI(fn_cmd_if_var1_equals_constant_then_goto-1)

        ; ifnect - 25
        ; $797B
        EQUB    LO(fn_cmd_if_var1_does_not_equal_constant_then_goto-1)
        EQUB    HI(fn_cmd_if_var1_does_not_equal_constant_then_goto-1)

        ; ifltct - 26
        ; $7983
        EQUB    LO(fn_cmd_if_var1_is_less_than_constant_then_goto-1)
        EQUB    HI(fn_cmd_if_var1_is_less_than_constant_then_goto-1)        

        ; ifgtct - 27
        ; $798D
        EQUB    LO(fn_cmd_if_var1_is_greater_than_constant_then_goto-1)
        EQUB    HI(fn_cmd_if_var1_is_greater_than_constant_then_goto-1) 

        ; nothing - 28
        EQUB    $00,$00        

        ; nothing - 29
        EQUB    $00,$00 