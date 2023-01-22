; Summary Memory Map
; ------------------
; From  To      Bytes   Type            Description
; 0400                                  Workspace?
; 1200  121F    32      Unused          Zero bytes
; 1220  1AF4    2261    Data            Dictionary of commands and objects
; 1AF4  1AF7    3       Data            Dictionary termination zero bytes
; 1AF8  2082                            Not sure yet
; 2083  5A0A    2274    Data            Encoded words (response and objects and direction)
; 5A0B  5C17                            Common word fragments
; 5C20  731C                            Virtual machine?
; 731D
; 7329  732A    2       Data            Address of common word fragments lookup table
; 7BB8  7BFF            
; 7C00  7FFF    1024    Screen          Screen memory

;1200

; In the dictionary, the last letter to match has its top bit
; set which is why it gets AND'd with &7F before comparison with the
; input string

; The character AFTER the last letter is the control code, the action

;2083
.data_game_descriptions

;5A0B
.data_common_word_fragments

;5C20
.data_virtual_machine_cmds

;3700

        ; OSFILE parameter block
        ; Address of filename ($5231)
        EQUB    $31,$52

        ; File load address ($5A7F)
        EQUB    $7F,$5A

        ; File execution address ($8487)
        EQUB    $84,$87

        ;

;7320
.fn_game_start
        JMP     fn_init_game

;...
;7323

;7329
.data_virtual_machine_cmds_address_lsb
        ; Set to $5C20, the start of the virtual machine
        ; commands
        EQUB    LO(data_virtual_machine_cmds)
.data_virtual_machine_cmds_address_msb
        EQUB    HI(data_virtual_machine_cmds)

        EQUB    $00, $00

;732D
; TODO make low /high
.data_vm_workspace_lsb
        EQUB    $00
.data_vm_workspace_msb        
        EQUB    $04

        EQUB    $00
        EQUB    $1B
;...
; 7331
.data_game_descriptions_address_lsb
        ; Set to $2083, the start of the encoded/compressed
        ; game descriptions
        EQUB    LO(data_game_descriptions)
.data_game_descriptions_address_msb
        EQUB    HI(data_game_descriptions)

;7333
.data_common_word_fragments_address_lsb
        ; Set to $5A0B, the start of the common word
        ; fragments
        EQUB    LO(data_common_word_fragments)
.data_common_word_fragments_address_msb
        EQUB    HI(data_common_word_fragments)

;...
;7335
        EQUB    LO(data_virtual_machine_address)
        EQUB    HI(data_virtual_machine_address)



;...
;7357
.fn_init_game

; Does $5C20 contain text that needs to be decoded?
; Reads firt character which is a 00 then moves to the 
; next position and 


        ; Set the BRKV handler
        ; for when a BRK instruction is 
        ; executed
        LDA     #LO(fn_brkv_handler)
        STA     BRKV_LSB
        LDA     #HI(fn_brkv_handler)
        STA     BRKV_MSB

        ; Store the location of the virtual machine
        LDA     data_virtual_machine_cmds_address_lsb
        STA     zp_virtual_machine_lsb
        LDA     data_virtual_machine_cmds_address_msb
        STA     zp_virtual_machine_msb

        ; Store the parser dictionary location
        LDA     #$20
        STA     zp_dictionary_start_lsb

        LDA     #$12
        STA     zp_dictionary_start_msb

        ; Switch paged mode off ($0F)
        LDA     #$0F
        JSR     fn_write_character_to_screen

        ; Reset the input string buffer pointer 
        ; to $0000, the start of the buffer
        JSR     fn_reset_next_char_pointer

        ; Reset the number of characters written to the
        ; current line to zero
        LDA     #$00
        STA     zp_chars_on_current_line
.L737F
        JSR     L7382

.L7382
        ; -----------------------------------------------
        ; Main virtual machine loop
        ; -----------------------------------------------

        ; Set the carry flag
        SEC

        ; Get the return address LSB for this
        ; sub-routine from the stack,
        ; subtract 3 from it (and subtract
        ; 1 from the return address MSB if it 
        ; crosses a page boundary) and write
        ; the new address to the stack
        ; TODO WHY
        PLA
        SBC     #$03
        TAX
        PLA
        SBC     #$00
        PHA
        TXA
        PHA

        ; Get the next compressed character?
        JSR     fn_get_cmd_and_increment_cmd_pointer

        ; Push the compressed character to the stack
        PHA

        ; Get the 7th bit of the character
        ; $40 = 64 = 0100 0000
        AND     #$40

        ; Store it for some reason?!? TODO
        STA     zp_cmd_values_status

        ; Get the character again
        PLA

        ; Cache it again on the stack
        PHA

        ; Get the 6th bit of the character
        ; $20 = 32 = 0010 0000
        AND     #$20


        ; Store if ro some reason?!? TODO
        STA     L006F

        ; Get the character again
        PLA
.L739C

; NOTHING TO DO WIT CHARACTERS!!!
        ; Check if it is less than $7F / 127 / 1000 0000
        ; (Printable ASCII character range) - if it is < 127
        ; the branch ahead

        ; Check if the 8th bit is set
        CMP     #$7F
        ; Branch if < 127
        BCC     L73A3

        ; Character >= 127

        JMP     L762E

.L73A3
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
;...





;73B2
.fn_write_character_to_screen
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
        BCC     end_write_character_to_screen

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
        BNE     L73CE

        ; Space was passed

        ; TODO Check some state and don't write to screen
        ; if it's not set
        ; If no characters have been written to the current
        ; line do NOT write a space
        LDA     L0064
        CMP     #$00
        BEQ     end_write_character_to_screen

        ; Not at the start of the line

        ; Write a space (ASCII $20) to the screen
        LDA     #$20
;73CE
.print_character_or_space
        ; Write the space or character to the current line
        JSR     OSASCI

;73D1
.end_write_character_to_screen
        ; Return having written a character
        ; or skipped
        RTS        

;...


.L7425
        ; Restart a game
        JMP     fn_game_start

.L7428
        JSR     L743E

        LDA     #$00
        TAY
.L742E
        JMP     L7438

.L7431
        JSR     L743E

        ; OSFILE A=255/$FF
        ; Load named file 
        ; XY contain the address of the 
        ; file block, in this case at $3700
        ; (see memory location for details of block)
        LDA     #$FF
        LDY     #$00
        LDX     #$37
        JSR     OSFILE

        ; Return once file loaded
        RTS

.L743E
        LDA     #$6D
        STA     L0037

        LDA     #$74
        STA     L0038
        
        LDA     #$00
.L7448
        STA     L0039
.L744A
        LDA     #$04

        STA     L003A
.L744E
        LDX     #$FF

.L7450
        STX     L003B
        STX     L003C
        LDA     #$00
        STA     L0041
        LDA     #$04
.L745A
        STA     L0042
        STX     L0043
        STX     L0044
        LDA     #$FF
        STA     L0045
        LDA     #$06
        STA     L0046
        STX     L0047
        STX     L0048
        RTS
;...
;7489
.fn_print_encoded_string
        ; -------------------------------------
        ; Takes the index to the current encoded string
        ; and processes each byte one at a time
        ; adding to the string buffer at $0000
        ;
        ; 1. If the byte is less than $03 it's 
        ;    assumed to be a word terminator
        ;    and processing stops
        ; 2. If the byte is >= $5E it's assumed 
        ;    to be another embedded common word
        ;    fragment and that is similarly 
        ;    recursively processed before completing
        ;    the current word - the common word index
        ;    is worked out by subtracting $5E from the
        ;    value when processing it
        ; 3. If it's between $02 and $5D the it 
        ;    has $1F added to it so it's in the 
        ;    ASCII printable range
        ; -------------------------------------

        ; Get the current encoded string byte
        LDY     #$00
        LDA     (zp_encoded_string_index_lsb),Y

        ; Check it's greater than 2 otherwise treat
        ; as a valid encoded byte not a terminator
        CMP     #$03

        ; If it's >2 then process it, it's not a terminator
        BCS     loop_check_and_add_char_to_string

        ; Terminator reached
        RTS

;7492
.loop_check_and_add_char_to_string
        ; Cache the current index position of where
        ; the encoded is being processed
        ;
        ; This is important because if the current byte is 
        ; a reference to another encoded string
        ; then that one needs to be processed before the rest
        ; of this one
        LDA     zp_encoded_string_index_lsb
        PHA
        LDA     zp_encoded_string_index_msb
        PHA

        ; Is it a reference to another encoded string (>=$5E)
        ; If so, process the referenced encoded string before
        ; continuing with this one
        LDA     (zp_encoded_string_index_lsb),Y
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
        STA     zp_encoded_string_index_msb
        PLA
        STA     zp_encoded_string_index_lsb

        ; Increment to the next encoded string
        ; byte by adding 1 to the LSB
        LDA     zp_encoded_string_index_lsb
        ADC     #$01
        STA     zp_encoded_string_index_lsb

        ; If there was a carry add it onto the MSB
        LDA     zp_encoded_string_index_msb
        ADC     #$00
        STA     zp_encoded_string_index_msb
        JMP     get_next_encoded_string_byte

;7489
.get_next_encoded_string_byte
        LDY     #$00
        LDA     (zp_encoded_string_index_lsb),Y

        ; If the next encoded string byte is >= 3 
        ; then process it 
        CMP     #$03
        BCS     loop_check_and_add_char_to_string

        ; It was < 3 so return
        RTS
;...

;74B9
.fn_process_embedded_encoded_string
        ; A value >= $5E means that the current
        ; byte refers to another encoded string

        ; To determine which nth encoded
        ; string is required, subtract $5E
        ; to get to n
        SEC
        SBC     #$5E
        STA     zp_encoded_string_counter_lsb

        ; Reset the msb to zero 
        LDA     #$00
        STA     zp_encoded_string_counter_msb

        ; Put the address of the encoded
        ; string lookup into $60/$61 - 
        ; this starts at $5A0B

        ; Reset the index to the start of the
        ; encoded strings
        LDA     data_common_word_fragments_address_lsb
        STA     zp_encoded_string_index_lsb

        ; Reset the index to the start of the
        ; encoded string
        LDA     data_common_word_fragments_address_msb
        STA     zp_encoded_string_index_msb

        ; Find the nth common word fragment - "n" is
        ; defined in zp_encoded_string_counter_lsb/msb
        JSR     fn_find_nth_common_word_fragment

        ; Process the new common word fragment until it's
        ; complete
        JSR     fn_print_encoded_string

        ; Revert back to the previous common word fragment
        ; now the newly referenced common word fragment
        ; has been processed 
        JMP     continue_with_encoded_string
;...

;74D5
.fn_find_nth_game_description
        ; Look for the nth common game description
        ; "n" is defined in the 
        ; zp_encoded_string_counter_lsb/msb
        LDA     data_game_descriptions_address_lsb
        STA     zp_encoded_string_index_lsb
        LDA     data_game_descriptions_address_msb
        STA     zp_encoded_string_index_msb

;74DF
.fn_find_nth_encoded_string
.loop_find_nth_encoded_string
        ; If started above it'll find the nth game
        ; description not common word - if called
        ; direct it'll loop over the common words

        ; Check to see if the common word fragment counter
        ; has reached zero or if the code still needs to loop
        ; looking for the next common word fragment separator
        LDA     zp_encoded_string_counter_lsb
        ORA     zp_encoded_string_counter_msb

        ; Check the current byte for a separator ($01)
        ; if the counter is greater than zero
        BNE     check_current_encoded_string_byte

        ; Counter zero

        ; At this point the zp_encoded_string_index_lsb/msb
        ; will point to the start of the common word fragment
        ; that was requested - it can now be printed to the 
        ; screen (note it is still encoded)

        RTS

;74E6
.check_current_encoded_string_byte
        ; Loop through the common word fragments - each
        ; fragment is separated by a $01.  This needs
        ; to happen n times where n is defined
        ; by the values held in $72/$73
        ;
        ; Common word fragments are in $5A0B++

        ; Load the next common word fragment
        LDY     #$00
        LDA     (zp_encoded_string_index_lsb),Y

        ; Is it a separator ($01)
        CMP     #$01

        ; Push the result and processor status onto the stack
        ; (result is used after the index is incremented)
        PHP

        ; Move to the next common word fragment byte
        ; by adding 1 to the LSB and any carry to to
        ; the MSB address

        ; Add one to the LSB
        LDA     zp_encoded_string_index_lsb
        CLC
        ADC     #$01
        STA     zp_encoded_string_index_lsb

        ; Add the carry to the MSB
        LDA     zp_encoded_string_index_msb
        ADC     #$00
        STA     zp_encoded_string_index_msb

        ; Restore the processor status so the comparison
        ; from earlier can be used
        PLP

        ; If the current byte is not a separator ($01)
        ; loop back to inspect the next byte
        BNE     loop_find_nth_encoded_string


        ; Current byte is a separator ($01)

        ; Found a separator so decrement the number
        ; left to find so n = n - 1

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
        ; if the counter has not yet reached zero
        JMP     loop_find_nth_encoded_string
        
;...

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
        STA     (zp_current_char_lsb),Y

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
        LDA     zp_current_char_lsb
        
        ; Clear carry
        CLC

        ; Add one to the LSB 
        ADC     #$01
        STA     zp_current_char_lsb

        ; If it went across a page boundary
        ; increment the address's MSB
        LDA     zp_current_char_msb
        
        ; Add the carry if there was any from the LSB
        ADC     #$00

        ; Store the MSB again
        STA     zp_current_char_msb
        RTS

;7535
.fn_write_string_and_then_start_new_line

        ; Write the current string (held at $0000 onwards)
        ; to the screen (assuming it fits, otherwise start
        ; a new line)
        JSR     fn_check_string_fits_on_current_line

        ; String has been written - now start a new line
        LDA     #$0D
        JSR     fn_write_character_to_screen

        ; Reset the number of characters on the current
        ; line to zero
        LDA     #$00
        STA     zp_chars_on_current_line

        ; Reset the string character pointer to the start
        ; of the string buffer ($0000)
        JSR     fn_reset_next_char_pointer

        LDA     #$00
        TAY
        STA     (zp_current_char_lsb),Y
        RTS

;754A
.fn_reset_next_char_pointer
        ; ---------------------------------------
        ; Reset the pointer to the current string
        ; character to $0000
        ; ---------------------------------------

        ; Set the LSB to $00
        LDA     #$00
        STA     zp_current_char_lsb

        ; Set the MSB to $00
        LDA     #$00
        STA     zp_current_char_msb

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
        LDA     zp_current_char_lsb
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
        JSR     fn_write_character_to_screen

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
        ; locations increment to point to the next
        ; character
        LDY     #$00
        LDA     (zp_current_char_lsb),Y

        ; Check to see if the character is a NUL ($00)
        ; This indicates that it is the end of the
        ; current string - so branch away and get the 
        ; reset the character pointer and write a 
        ; space to the screen
        CMP     #$00
        BEQ     fn_reset_next_char_ptr_and_write_space

        ; Not a NUL ($00) string terminator

        ; Write the character to the screen
        JSR     fn_write_character_to_screen

        ; Increase the number of characters written
        ; to the current line on the screen
        INC     zp_chars_on_current_line
        JSR     L7527

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
        STA     (zp_current_char_lsb),Y

        ; Write a space to the screen
        LDA     #$20
        JSR     fn_write_character_to_screen

        ; Increase the count of characters that have been
        ; written to the current line on the screen
        INC     zp_chars_on_current_line

        ; All done...
        RTS    

;...
;messagev
.L7593
        ; ---------------------------------------------
        ; Prints a messge from a vm workspace variable
        ; - the variable holds the message number
        ; ---------------------------------------------
        ;
        ; <command> <byte1>
        ;
        ; <command> is always $04
        ; <byte1> variable to use for message

        ; Used to print things like room directions
        ; in (through a door), north, south etc based
        ; in your own living room
        ; You can see
        ; [a fine golden hourglass] [on the mantlepiece]
        ; a picture of a kindly old man
        ; 
        ; on variables held in $0400 to $05FF

        ; Looks up A in the vm workspace based on 
        ; the next vm value - next vm value is 
        ; 2 * value + $0400 to get address
        JSR     fn_get_a_code_variable_number

        ; A is now used as the nth string to display
        ; when the string is printed - "n" is stored
        ; in zp_encoded_string_counter_lsb/msb ($72/$73)

        ; Store A in the LSB of the counter - 72
        STA     zp_encoded_string_counter_lsb

        ; Get the next value from the workspace
        ; and store in the second byte of the 
        ; counter - 73
        INY
        LDA     (zp_vm_workspace_pointer_lsb),Y
        STA     zp_encoded_string_counter_msb

        ; Use those values to find the memory
        ; location of the nth string to display
        ; "n" is determined by the value in 
        ; zp_encoded_string_counter_lsb/msb ($72/$73)
        ;
        ; Address will be placed in 
        ; zp_encoded_string_index_lsb/msb ($60/$61)
        JSR     fn_find_nth_game_description

        ; Decode and add the nth game description to 
        ; the string buffer ($0000) and write it 
        ; to the screen
        JSR     fn_print_encoded_string

        RTS


;messagec
;75A4
.fn_cmd_print_message
        ; Used to print things that are constant and not
        ; driven by a variable e.g. in the vm stream

        ; After the command in the virtual machine, it
        ; will either be followed by one or two bytes to 
        ; denote the nth message that should be found 
        ; and written to the screen -
        ; if the command code had its 7th bit set then 
        ; it has one byte, if not set then two
        ; 
        ; Bytes will be placed in 
        ; zp_encoded_string_counter_lsb/msb ($72/$73)
        JSR     fn_get_cmd_values

        ; Find the start memory address of the nth
        ; game description
        ;
        ; Address will be placed in 
        ; zp_encoded_string_index_lsb/msb ($60/$61)
        JSR     fn_find_nth_game_description

        ; Decode and add the nth game description to 
        ; the string buffer ($0000) and write it 
        ; to the screen
        JSR     fn_print_encoded_string

        RTS

;75AE
;_add
.fn_add_var1_to_var2
        ; ---------------------------------------------
        ; Copies a value from the virtual machine into
        ; the virtual machine workspace.
        ; ---------------------------------------------
        ;
        ; <command> <byte1> <byte2>
        ;
        ; <command> is always $0A
        ; <byte1> used to calculate address of two bytes 
        ;         in $0400-$05FF to add to below
        ; <byte2> used to calculate address of two bytes
        ;         in $0400-$05FF that will be added to
        ; 

        ; Get <byte1> from the virtual machine and calculate
        ; the source address for the addition (in $0400-$05FF)
        JSR     fn_get_a_code_variable_number

        ; Cache the address in zp_vm_workspace_pointer_cache_lsb/msb
        JSR     fn_copy_memory_address_ptr

        ; Get <byte2> from the virtual machine and calculate
        ; the target address for the addition (in $0400-$05FF)
        ; Address will be held in zp_vm_workspace_pointer_lsb/msb
        JSR     fn_get_a_code_variable_number

        ; Load the first source byte and add to the first
        ; target byte and write back to the first
        ; target byte
        LDY     #$00
        LDA     (zp_vm_workspace_pointer_cache_lsb),Y
        CLC
        ADC     (zp_vm_workspace_pointer_lsb),Y
        STA     (zp_vm_workspace_pointer_lsb),Y

        ; Load the second source byte and add to the second
        ; target byte and write back to the second
        ; target byte
        INY
        LDA     (zp_vm_workspace_pointer_cache_lsb),Y
        ADC     (zp_vm_workspace_pointer_lsb),Y
        STA     (zp_vm_workspace_pointer_lsb),Y

        ; Addition complete
        RTS

;75C8
;_sub
.fn_subtract_var1_from_var2
        ; ---------------------------------------------
        ; Copies a value from the virtual machine into
        ; the virtual machine workspace.
        ; ---------------------------------------------
        ;
        ; <command> <byte1> <byte2>
        ;
        ; <command> is always $49
        ; <byte1> used to calculate address of two bytes 
        ;         in $0400-$05FF to subtract from below
        ; <byte2> used to calculate address of two bytes
        ;         in $0400-$05FF that will be have the values
        ;         above subtracted
        ; 
        ; target = target - source

        ; Get <byte1> from the virtual machine and calculate
        ; the source address for the subtraction (in $0400-$05FF)
        JSR     fn_get_a_code_variable_number

        ; Cache the address in zp_vm_workspace_pointer_cache_lsb/msb
        JSR     fn_copy_memory_address_ptr

        ; Get <byte2> from the virtual machine and calculate
        ; the target address for the subtraction (in $0400-$05FF)
        ; Address will be held in zp_vm_workspace_pointer_lsb/msb
        JSR     fn_get_a_code_variable_number

        ; Subtract the source lsb from the target lsb
        ; and store back in the target lsb
        LDA     (zp_vm_workspace_pointer_lsb),Y
        SEC
        SBC     (zp_vm_workspace_pointer_cache_lsb),Y
        STA     (zp_vm_workspace_pointer_lsb),Y

        ; Subtract the source msb from the target msb
        ; and store back in the target msb
        INY
        LDA     (zp_vm_workspace_pointer_lsb),Y
        SBC     (zp_vm_workspace_pointer_cache_lsb),Y
        STA     (zp_vm_workspace_pointer_lsb),Y

        ; Subtraction complete
        RTS

;...
;intgosub
        PLA
        STA     zp_curr_input_char_cache
        PLA
        STA     L0087
        LDX     #$02

        ; Check 6th bit?
        LDA     L006F
        CMP     #$00
        BEQ     L76B4

        DEX
.L76B4
        STX     zp_general_cache_1
        
        LDA     zp_virtual_machine_lsb
        CLC
        ADC     zp_general_cache_1
        PHA
        LDA     L0081
        ADC     #$00
        PHA


        LDA     L0087
        PHA
        LDA     zp_curr_input_char_cache
        PHA
        JMP     fn_cmd_goto

        PLA
        STA     zp_curr_input_char_cache
        PLA
        STA     L0087
        PLA
        STA     L0081
        PLA
        STA     zp_virtual_machine_lsb
        LDA     L0087
        PHA
        LDA     zp_curr_input_char_cache
        PHA
        RTS
;...

;76DD
.fn_get_cmd_and_increment_cmd_pointer
        ; TODO is it only used for that?
        ; Used to get common word fragments for descriptions and
        ; not sure yet for the other bit

        ; Preserve Y as the code will reset it to zero
        STY     zp_general_cache_1

        ; Reset Y to zero
        LDY     #$00

        ; Get soemthing
        LDA     (zp_virtual_machine_lsb),Y

        ; Stick it on the stack
        PHA

        ; Restore Y for the return
        LDY     zp_general_cache_1

        ; Move to the next memory address of the
        ; common word fragments
        LDA     zp_virtual_machine_lsb
        CLC
        ADC     #$01
        STA     zp_virtual_machine_lsb
        LDA     zp_virtual_machine_msb
        ADC     #$00
        STA     zp_virtual_machine_msb
        PLA
        RTS

;76F5
.fn_get_a_code_variable_number
        ; ---------------------------------------------
        ; Move the VM Workspace pointer
        ;
        ; Gets the value pointed at by the 
        ; virtual machine tape and uses it as
        ; the offset into the vm workspace - every
        ; variable entry in the vm workspace is two bytes 
        ; so memory is used from $0400 to $05FF
        ;
        ; Address = $0400 + (2 * <value>)
        ;
        ; If bit 7 is set to 0
        ;     Read address      
        ; If bit 7 is set to 1 
        ;     Read address + $0100
        ;
        ; Return the value in A
        ; ---------------------------------------------
        
        ; Get the next virtual machine byte and use it
        ; to calculate the variable address
        JSR     fn_get_cmd_and_increment_cmd_pointer

        ; Cache the value
        PHA

        ; Multiple it by 2 (2 * <value>)
        ASL     A

        ; Transfer the result to Y
        TAY

        ; Write $0400 to $70/$71
        LDA     data_vm_workspace_msb
        STA     zp_vm_workspace_pointer_msb
        LDA     data_vm_workspace_lsb
        STA     zp_vm_workspace_pointer_lsb

        ; Add Y onto the LSB so 
        TYA
        CLC
        ADC     zp_vm_workspace_pointer_lsb
        STA     zp_vm_workspace_pointer_lsb

        ; Add any carry 
        LDA     zp_vm_workspace_pointer_msb
        ADC     #$00
        STA     zp_vm_workspace_pointer_msb

        ; Get A back in its looked up form
        PLA 

        ; Check to see if the top bit is set
        AND     #$80

        ; If it's not set branch ahead
        BEQ     get_variable_value

        ; It's set, add one to the MSB address
        ; so page $05xx rather than $04xx
        INC     zp_vm_workspace_pointer_msb
;7718
.get_variable_value
        ; Load the variable value from the vm
        ; workspace 
        LDY     #$00
        LDA     (zp_vm_workspace_pointer_lsb),Y

        ; Return with A containing the vm workspace
        ; variable value
        RTS

;771D
.fn_get_cmd_values
        ; ---------------------------------------------
        ; Gets one or two byte values that follow the command
        ; If the 7th bit of the command is set, it needs 
        ; only one byte otherise two
        ; ---------------------------------------------

        ; Check to see if the 7th bit of the command is
        ; set - only load one byte not two
        LDA     zp_cmd_values_status
        CMP     #$00
        BNE     get_single_value_byte

        ; 7th bit not set <- correct

        ; Get the next value from the virtual machine
        ; that follows the command byte and use it 
        ; as the LSB for the counter
        JSR     fn_get_cmd_and_increment_cmd_pointer
        STA     zp_encoded_string_counter_lsb

        ; Get the next value from the virtual machine
        ; that follows the command byte and use it 
        ; as the MSB for the counter        
        JSR     fn_get_cmd_and_increment_cmd_pointer
        STA     zp_encoded_string_counter_msb

        ; Counter retrieved (two bytes)
        RTS

;772E
.get_single_value_byte
        ; Get the next value from the virtual machine
        ; that follows the command byte and use it 
        ; as the LSB for the counter
        JSR     fn_get_cmd_and_increment_cmd_pointer
        ;72
        STA     zp_encoded_string_counter_lsb

        ; There is no second byte for the counter so
        ; set the MSB to zero
        LDA     #$00
        ;73
        STA     zp_encoded_string_counter_msb

        ; Counter retreived (one byte)
        RTS

;7738
;varcon
.fn_cmd_copy_from_constant_to_var
        ; ---------------------------------------------
        ; Copies a value from the virtual machine into
        ; the virtual machine workspace.
        ; ---------------------------------------------
        ; <command> <byte1> <byte2>
        ;
        ; <command> is always $48
        ; <byte1> value to copy
        ; <byte2> used to calculate address of two bytes
        ;         in $0400-$05FF that will be added to        
        ;
        ; After this command in the virtual machine, it
        ; will be followed by two bytes.
        ;
        ; The first byte is the value that will be
        ; copied
        ;
        ; The second byte after the command
        ; is used to calculate the target
        ; in $0400-$05FF, the vm workspace
        ; 
        ; Byte will be placed in 
        ; zp_encoded_string_counter_lsb/msb ($72/$73)
        ; and those locations used as a source address
        JSR     fn_get_cmd_values

        ; Set the "copy from" pointer to point
        ; at $72/$73 where the value/byte above
        ; was placed
        JSR     fn_set_constant_address_location

        ; Copy the value held at $72/$73 
        ; to the vm workspace target 
        ; in $0400-$05FF, calculated from
        ; the next byte in the vm
        JMP     fn_copy_from_memory_to_memory

;7741
.fn_set_constant_address_location
        ; Point the VM workspace pointer at 
        ; $0072/73 as it contains the address
        ; to "copy from"
        LDA     #$72
        STA     zp_vm_workspace_pointer_lsb
        LDA     #$00
        STA     zp_vm_workspace_pointer_msb

        ; VM Workspace pointer set
        RTS


;774A
.fn_copy_memory_address_ptr
        LDA     zp_vm_workspace_pointer_lsb
        STA     zp_vm_workspace_pointer_cache_lsb
        LDA     zp_vm_workspace_pointer_msb
        STA     zp_vm_workspace_pointer_cache_msb
        RTS

;7753
;varvar
.fn_cmd_copy_from_var1_to_var2
        ; ---------------------------------------------
        ; Copies two bytes from the "copy from"
        ; address in the virtual machine workspace
        ; ($0400 - $05FF) to the "copy to" address
        ; in the virutal machine workspace
        ;
        ; The "copy from" address is calculated from the 
        ; first byte following the command in the virtual
        ; machine and the "copy to" address is calculated
        ; from the second byte following the command

        ; The next byte in the virtual machine
        ; is used to calcuate the "copy from" address 
        ; ---------------------------------------------
        ; <command> <byte1> <byte2>
        ;
        ; <command> is always $49
        ; <byte1> used to calculate the source address 
        ;         of two bytes in $0400-$05FF that 
        ;         be the "copy from"
        ; <byte2> used to calculate the target address 
        ;         of two bytes in $0400-$05FF that 
        ;         be the "copy from"
        ; 
        ; Calculates address in the vm workspace based on 
        ; the next vm value - next vm value is 
        ; (2 * byte) + $0400 to get address 
        ; Address set in zp_vm_workspace_pointer_lsb/msbs
        ; A is then set to the byte at that location
        JSR     fn_get_a_code_variable_number

        ; Coninues below

;7756
.fn_copy_from_memory_to_memory
        ; Cache the vm workspace pointer - this is the
        ; addresss of the two bytes that will be copied
        ; from in $0400 - $05FF or a zeropage address
        JSR     fn_copy_memory_address_ptr

        ; The next byte in the virtual machine
        ; is used to calcuate the "copy to" address 
        ; 
        ; Calculates address in the vm workspace based on 
        ; the next vm value - next vm value is 
        ; (2 * byte) + $0400 to get address 
        ; Address set in zp_vm_workspace_pointer_lsb/msbs
        ; A is then set to the byte at that location
        JSR     fn_get_a_code_variable_number

        ; Copies the first byte at the "copy from"
        ; address to the first byte at the "copy to"
        ; address (either both in $0400 - $05FF or
        ; from zero page to $0400 - $05FF)
        LDY     #$00
        LDA     (zp_vm_workspace_pointer_cache_lsb),Y
        STA     (zp_vm_workspace_pointer_lsb),Y

        ; Copies the second byte at the "copy from"
        ; address to the second byte at the "copy to"
        ; address (either both in $0400 - $05FF or
        ; from zero page to $0400 - $05FF)
        INY
        LDA     (zp_vm_workspace_pointer_cache_lsb),Y
        STA     (zp_vm_workspace_pointer_lsb),Y

        ; Two bytes copied in the workspace
        RTS


;input
;7768
.fn_cmd_get_player_input
        ; ---------------------------------------------
        ; Get the player's input, parse it to find
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

        ; Load the first derived command or object code 
        ; from the string buffer into A and write
        ; to the vm workspace
        LDA     zp_general_string_buffer
        JSR     fn_write_vm_workspace_variable

        ; Load the second derived command or object code 
        ; from the string buffer into A and write
        ; to the vm workspace
        LDA     zp_general_string_buffer+1
        JSR     fn_write_vm_workspace_variable

        ; Load the third derived command or object code 
        ; from the string buffer into A and write
        ; to the vm workspace
        LDA     zp_general_string_buffer+2
        JSR     fn_write_vm_workspace_variable

        ; Load the input words count and write
        ; into the vm workspace
        LDA     zp_input_words_count
        JSR     fn_write_vm_workspace_variable

        ; Finished capturing input 
        RTS
;...

;7784
.fn_write_vm_workspace_variable
        ; ---------------------------------------------
        ; Writes the value passed in A
        ; to the vm workspace ($0400-$05FF)
        ; based on 2 * <byte> where <byte> is the
        ; next byte in the virtual machine
        ; ---------------------------------------------

        ; Cache the value to write on the stack
        PHA

        ; Get the next byte value and calculate the vm workspace address
        ; where the value should be written
        JSR     fn_get_a_code_variable_number

        LDY     #$00

        ; Restore the value to write from the stack
        PLA

        ; Write the value to the variable LSB
        STA     (zp_vm_workspace_pointer_lsb),Y
        INY
        ; Set the variable MSB to zero
        LDA     #$00
        STA     (zp_vm_workspace_pointer_lsb),Y
        RTS

;7793
.fn_get_and_parse_player_input


        ; ---------------------------------------------
        ; 1. Get a new line of input from the player
        ;    and add a space and a terminator to the 
        ;    end of the string buffer
        ; ---------------------------------------------
        ; Get a new line of text input from the player
        ; up to a maximum of 39 characters
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

.L77A3
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
        STA     zp_input_string_buffer_pointer_lsb
        LDA     #$00
        STA     zp_cmd_and_obj_pointer_msb
        STA     zp_input_string_buffer_pointer_msb

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
        LDA     zp_input_string_buffer_pointer_lsb
        PHA
        LDA     zp_input_string_buffer_pointer_msb
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
        STA     zp_input_string_buffer_pointer_msb

        ; Pull the cached start string address MSB
        ; from the Stack
        PLA

        ; Restore it to the string buffer pointer LSB
        STA     zp_input_string_buffer_pointer_lsb

        ; Cache the string buffer pointer LSB again on the stack
        PHA

        ; Reload the string buffer pointer MSB
        LDA     zp_input_string_buffer_pointer_msb

        ; Cache the string buffer pointer LSB again
        PHA

;77E8
.compare_current_input_word
        ; ---------------------------------------------
        ; 8. Cache the start of the current input word 
        ;    being parsed.  
        ; ---------------------------------------------


        ; Cache the start of the current input word
        LDA     zp_input_string_buffer_pointer_msb
        STA     zp_current_word_pointer_msb
        LDA     zp_input_string_buffer_pointer_lsb
        STA     zp_current_word_pointer_lsb

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

        ; Is the character a space (ASCII $20)
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
        JSR     fn_get_dictionary_word_character

        ; Has the end of the dictionary been reached?
        ; Terminated with a $00 - if so branch
        CMP     #$00
        BEQ     L7879

;7809
        ; ---------------------------------------------
        ; 10. Masks out the 8th bit of the current 
        ;     dictionary word character (8th bit
        ;     just indiciates if it's the last character
        ;     of the dictionary word).  The compares
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
        ; in 86
        STX     zp_curr_input_char_cache

        ; Compare the current dictionary word character
        ; against the player's current input string character
        CMP     zp_curr_input_char_cache

        ; If it isn't the same then branch ahead
        BNE     L7859

        ; The player's current input string character
        ; matches the current dictionary word character

        ; Move the pointer to the next dictionary character
        JSR     fn_inc_dictionary_pointer

        ; Move the pointer to the next player input character
        JSR     fn_get_input_character

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
        JSR     fn_dec_dictionary_pointer

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
        JSR     fn_get_dictionary_word_character

        ; Add the last letter to the stack
        PHA

        ; Move to beyond the last matched dictionary
        ; character to get to the 
        JSR     fn_inc_dictionary_pointer

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
        JSR     fn_get_dictionary_word_character


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
        LDA     zp_current_word_pointer_lsb ; 7A
        STA     zp_input_string_buffer_pointer_lsb  ; 76

        ; Reset the MSB to the start of the current word
        LDA     zp_current_word_pointer_msb
        STA     zp_input_string_buffer_pointer_msb

        ; Move the dictionary point on to the start
        ; of the next dictionary word
        JSR     fn_inc_dictionary_pointer
        JSR     fn_inc_dictionary_pointer

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
        ; Pull the current input word character fromt he
        ; stack (clean up, not used)
        PLA
;785A
.loop_get_next_dict_chr
        ; Move the dictionary pointer forward
        JSR     fn_inc_dictionary_pointer

        ; Get the character at the dictionary pointer
        JSR     fn_get_dictionary_word_character

        ; Has the end of the dictionary been reached?
        CMP     #$00

        ; Branch if at the end of the dictionary
        BEQ     L7879

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
        JSR     fn_inc_dictionary_pointer
        JSR     fn_inc_dictionary_pointer

        ; Reset the input string buffer pointer back to the
        ; start of the current word as it needs to be compared
        ; against hte next dictionary entry
        LDA     zp_current_word_pointer_lsb
        STA     zp_input_string_buffer_pointer_lsb
        LDA     zp_current_word_pointer_msb
        STA     zp_input_string_buffer_pointer_msb

        ; Compare the next dictionary entry against the 
        ; current input word
        JMP     compare_next_dict_char_against_input_char


;...
.L7879
        ; Doesn't match?
        JSR     fn_inc_input_string_buffer_pointer

        JSR     fn_get_input_character

        ; Have 
        CMP     #$00
.L7881
        BEQ     end_cmd_or_obj_seq_and_process

        CMP     #$20
        BNE     L7879

        JSR     fn_find_next_non_space_in_input_string

        JSR     fn_init_dictionary_pointer

        LDA     zp_input_string_buffer_pointer_lsb
        STA     L007A
        LDA     zp_input_string_buffer_pointer_msb
        STA     L007B
        JMP     L77F6
;...

;7898
.fn_end_cmd_or_obj_seq_and_process
        ; Terminate the sequence of commands and/or
        ; objects in zero page by writing $00
        ; after the last command or object
        LDA     #$00
        JSR     fn_cache_cmd_or_obj

        JMP     L776B

;...
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
f
        ; Store it back over the current value
        STA     zp_cmd_and_obj_pointer_msb

        ; All done
        RTS
;...


;...
;78B2
.fn_find_first_non_space_in_input_string
        JSR     fn_inc_input_string_buffer_pointer

.L78B5
        JSR     fn_get_input_character

        CMP     #$20
        BEQ     fn_find_next_non_space_in_input_string

        CMP     #$00
        RTS
;...
.L78BF
.fn_inc_input_string_buffer_pointer
        ; ----------------------------------------------
        ; Increments the pointer to the input string
        ; buffer - to point at the next input character
        ; ----------------------------------------------

        ; Get the LSB of the string buffer pointer
        LDA     zp_input_string_buffer_pointer_lsb

        ; Clear the carry flag
        CLC

        ; Add 1 to the LSB pointer address
        ADC     #$01

        ; Store the new value over the old value
        STA     zp_input_string_buffer_pointer_lsb

        ; Load the MSB of the string buffer pointer
        LDA     zp_input_string_buffer_pointer_msb

        ; Add the carry if there was any (LSB > 255)
        ADC     #$00

        ; Store the new value over the old value
        STA     zp_input_string_buffer_pointer_msb

        ; All done
        RTS

;78CD
.fn_inc_dictionary_pointer
        ; ----------------------------------------------
        ; Increments the pointer to the dictionary
        ; to point at the next dictionary character
        ; ----------------------------------------------

        ; Get the LSB of the dictionary pointer
        LDA     zp_dictionary_pointer_lsb

        ; Clear the carry flag
        CLC

        ; Add 1 to the LSB pointer address
        ADC     #$01

        ; Store the new value over the old value
        STA     zp_dictionary_pointer_lsb

        ; Get the MSB of the dictionary pointer
        LDA     zp_dictionary_pointer_msb

        ; Add the carry if there was any (LSB > 255)
        ADC     #$00

        ; Store the new value over the old value
        STA     zp_dictionary_pointer_msb
        RTS

;78DB
.fn_dec_input_string_buffer_pointer
        ; ----------------------------------------------
        ; Decrements the pointer to the input string
        ; buffer - to point at the previous input character
        ; ----------------------------------------------

        ; Set the carry flag
        SEC

        ; Get the LSB of the string buffer pointer
        LDA     zp_input_string_buffer_pointer_lsb

        ; Subtract one (using the carry if a borrow is required)
        SBC     #$01

        ; Store the new value over the old value
        STA     zp_input_string_buffer_pointer_lsb

        ; Load the MSB of the string buffer pointer
        LDA     zp_input_string_buffer_pointer_msb

        ; Subtract the 1 if a borrow occured
        SBC     #$00

        ; Store the new value over the old value
        STA     zp_input_string_buffer_pointer_msb

        ; All done
        RTS

;78E9
.fn_dec_dictionary_pointer
        ; ----------------------------------------------
        ; Decrements the pointer to the dictionary 
        ; to point at the previous dictionary character
        ; ----------------------------------------------

        ; Set the carry flag
        SEC

        ; Get the LSB of the dictionary pointer
        LDA     zp_dictionary_pointer_lsb

        ; Subtract one (using the carry if a borrow is required)
        SBC     #$01

        ; Store the new value over the old value
        STA     zp_dictionary_pointer_lsb

        ; Get the MSB of the dictionary pointer
        LDA     zp_dictionary_pointer_msb

        ; Subtract the 1 if a borrow occured
        SBC     #$00

        ; Store the new value over the old value
        STA     zp_dictionary_pointer_msb

        ; All done
        RTS        
;...
;78F7
.fn_get_input_character
        ; Variable contains the location of the next
        ; input character that has been buffered 
        ; in zero page from $0000+
        LDY     #$00
        LDA     (zp_input_string_buffer_pointer_lsb),Y
        RTS

;78FC
.fn_get_dictionary_word_character
        ; Variable contains the location of the next
        ; dictionary word character 
        LDY     #$00
        LDA     (zp_dictionary_pointer_lsb),Y
        RTS

;...
;7901
.fn_init_dictionary_pointer
        ; Reset the LSB back to the start of the dictionary
        LDA     zp_dictionary_start_lsb
        STA     zp_dictionary_pointer_lsb

        ; Reset the MSB back to the start of the dictionary
        LDA     zp_dictionary_start_msb
        STA     zp_dictionary_pointer_msb

        ; Reset complete
        RTS
;...

;790A
.fn_cmd_goto
        ; -----------------------------------------------
        ; Virtual machine command - goto
        ;
        ; The 6th bit of the command byte indicates:
        ;     1 - single byte offset
        ;     0 - double byte offset
        ; 
        ; Sets the current virtual machine position to:
        ;    $5C20 + <value>
        ; where
        ;    <value> is stored in the one or two bytes 
        ;    after the goto command
        ; -----------------------------------------------

        ; TODO what does the 6th bit do....?
        ;
        ; Check the 6th bit of the command
        ; if it's set branch ahead as single byte <- correct
        LDA     L006F

        ; Z set if A=M
        CMP     #$00

        ; if 6f != 00
        ; Branch on result not zero
        BNE     single_byte_offset

        ; 6th bit not set - so it's a double byte offset

        ; Get the LSB increment
        JSR     fn_get_cmd_and_increment_cmd_pointer

        ; Add the increment onto the virtual machine start
        ; address ($5C20) and push it onto the stack
        CLC
        ADC     data_virtual_machine_cmds_address_lsb
        PHA

        ; Preserve the CPU registers (most interested in preserving
        ; the carry flag from the addition above to add to the MSB
        ; later)
        PHP

        ; Get the MSB increment 
        JSR     fn_get_cmd_and_increment_cmd_pointer

        ; Pull the processor status from the stack (most interested
        ; in the carry flag status here to add any carry)
        PLP

        ; Add the MSB increment and store it
        ADC     data_virtual_machine_cmds_address_msb
        STA     zp_virtual_machine_msb

        ; Get the LSB calculated earlier and store it
        PLA
        STA     zp_virtual_machine_lsb

        ; Double byte offset added
        RTS

;7926
.single_byte_offset
        LDX     #$00

        ; Cache the current memory address of the
        ; virtual machine (LSB and MSB)
        LDA     zp_virtual_machine_lsb
        STA     zp_general_cache_2
        LDA     zp_virtual_machine_lsb
        STA     zp_general_cache_3

        ; Get the next byte which is the address to offset
        JSR     fn_get_cmd_and_increment_cmd_pointer

        ; Cache the offset value
        PHA
        
        ; Check to see if the 8th bit is set
        ; ($80 = 1000 0000), if it isn't then 
        ; branch
        AND     #$80
        BEQ     L793A

        ; 8th bit set

        ; Change the X value from $00 to $FF
        ; TODO WHY
        LDX     #$FF
.L793A
        ; Retrieve the offset value
        PLA

        ; Add the offset value onto the 
        CLC
        ADC     zp_general_cache_2
        STA     zp_virtual_machine_lsb
g
        ; Store either $00 or $FF depending on bit 8
        STX     zp_general_cache_1

        ; Add any carry to the MSB
        LDA     zp_general_cache_3
        ADC     zp_general_cache_1
        STA     zp_virtual_machine_msb

        ; Single byte offset added
        RTS
;...
;ifgtct
;798E
fn_

        ; <cmd> <byte1> <byte2>
        ; <byte1> vm workspace addr value
        ; <byte2> constant
        ; 
        ; Check if variable (byte1) > constant (byte2)
        ;
        ; On return:
        ;     Carry set     - variable > constant
        ;     Carry not set - variable <= constant
        JSR     L79A2

        ; If variable > constant then move forward
        ; one or two bytes if the 6th bit of the 
        ; command is set
        BCS     L794E

        JMP     L790A

.L7996
        JSR     fn_get_a_code_variable_number

        JSR     fn_copy_memory_address_ptr

        JSR     fn_get_a_code_variable_number

        JMP     subtract_variable_from_constant

.L79A2

        ; Looks up A in the vm workspace based on 
        ; the next vm byte - next vm byte is 
        ; 2 * byte + $0400 to get address
        JSR     fn_get_a_code_variable_number

        ; Caches the workspace pointer that points to the
        ; virtual machine variable
        JSR     fn_copy_memory_address_ptr

        JSR     fn_get_cmd_values

        ; Set the "copy from" pointer to point
        ; at $72/$73 where the byte above
        ; was placed
        JSR     fn_set_constant_address_location

;79AE
.subtract_variable_from_constant
        ; Result msb = constant msb - variable msb
        SEC
        LDY     #$01
        ; ($70),1 <- contains 00 so becomes 73
        LDA     (zp_vm_workspace_pointer_lsb),Y

        ; ($73),1
        SBC     (zp_vm_workspace_pointer_cache_lsb),Y
I
        ; If Result msb  != 0
        ; If the variable msb != the constant msb then branch
        ; and return - carry flag will be set if 
        ; variable > constant, unset if variable < constant
        BNE     end_subtract_variable_from_constant

        ; The variable msb == the constant msb
        DEY
        
        ; Calculuate the 
        ; Result lsb = constant lsb - variable lsb
        SEC

        ; Subtact the variable from the constant
        LDA     (zp_vm_workspace_pointer_lsb),Y
        SBC     (zp_vm_workspace_pointer_cache_lsb),Y
;79BD
.end_subtract_variable_from_constant
        ; Carry flag will be set if variable > constant
        ; for either the MSB or LSB
        RTS
;...
;exit
;79BE
;commmand = 0F
        ; Get next two bytes and  put in 86/87
        
        ; 86
        JSR     fn_get_a_code_variable_number
        STA     zp_curr_input_char_cache
        ;87
        JSR     fn_get_a_code_variable_number
        STA     L0087

        ; $86 is the nth 8th bit set character
        ; in the new dictionary - $87 is the
        ; the thing to compare against that nth character
        ; (the bottom 4 bits)
        ;
        ; Set the dictionary address to 1B00 (new!)
        ; Get the character there if 0086 isn't 1
        ; and move the dictionary pointer on +2
        ; keep going until a byte with bit 8 set is found

        JSR     L79D9

        ; Get bits 7-5 by ANDing with
        ; 0111 0000 and rotate into the
        ; lowest bits e.g.
        ; 0111 0000 would become 0000 0111
        AND     #$70
        LSR     A
        LSR     A
        LSR     A
        LSR     A

        ; Write this to the vm workspace
        JSR     fn_write_vm_workspace_variable

        LDA     L0088
        JMP     fn_write_vm_workspace_variable

.L79D9
        ; Set the dictionary to $1B00
        JSR     L7A6B

        ; 86
        LDX     zp_curr_input_char_cache

        ; Load 86 (variable1 value), subtract 1 
        ; if it's zero goto 79f3
        DEX
.L79DF
        BEQ     L79F3

.L79E1
        JSR     fn_get_dictionary_word_character

        PHA
        JSR     fn_inc_dictionary_pointer

        JSR     fn_inc_dictionary_pointer

        PLA
        AND     #$80
        BEQ     L79E1

        DEX
        BNE     L79E1

.L79F3
        ; Does not increment the dictionary word
        ; pointer
        JSR     fn_get_dictionary_word_character

        ; Keep the bottom four bits only by ANDing
        ; with $0F (0000 1111)
        AND     #$0F
        CMP     L0087
        ; If any bit is set then branch
        ; Branch if A != M
        BNE     L7A0A

        ; no bits set

        JSR     fn_get_dictionary_word_character

        PHA
.L7A00
        JSR     fn_inc_dictionary_pointer

L7A01 = L7A00+1m        
        JSR     fn_get_dictionary_word_character

.L7A06
        STA     L0088
L7A07 = L7A06+1
        PLA
        RTS     

.L7A0A
        ; Does not increment the dictionary word
        ; pointer - gets the same value from before
        JSR     fn_get_dictionary_word_character

        ; Check if the 8th bit is set
        AND     #$80

        ; if it is then branch
        BNE     L7A1A


        ; 8th bit not set - move ahead 2 bytes

        JSR     fn_inc_dictionary_pointer
        JSR     fn_inc_dictionary_pointer

.L7A17
        JMP     L79F3

.L7A1A
        ; Get value from VM workspace?
        LDX     L0087
        LDA     L7335,X
        STA     L0087

        ; Reset to start of $1B00
        JSR     L7A6B

        LDA     #$01
        STA     L0088
.L7A28
        JSR     fn_get_dictionary_word_character

        ; Check bit 5
        STA     zp_general_cache_1
        AND     #$10
        ; Z set if A=M
        CMP     #$00
        ; Branch if zero (so 5th bit not set)
        BEQ     L7A4D

        ; Bit 5 set

        ; Get the bottom four bits by ANDing with $0F (0000 1111)
        LDA     zp_general_cache_1
        AND     #$0F
        CMP     L0087

        ; Compare the value to what's in 87 (loaded from $04xx)
        ; If A != M then branch
        BNE     L7A4D

        ; A=M

        JSR     fn_inc_dictionary_pointer

        JSR     fn_get_dictionary_word_character

        CMP     zp_curr_input_char_cache
        PHP
.L7A44
        JSR     fn_dec_dictionary_pointer

L7A45 = L7A44+1
L7A46 = L7A44+2
        PLP
.L7A48
        BNE     L7A4D

;...
.L7A6B
        ; Reset to the VM Workspace to the start
        ; of $1B00
        LDA     L732F
        STA     zp_dictionary_pointer_lsb
        LDA     L7330
        STA     zp_dictionary_pointer_msb
        RTS

;...

        JSR     fn_get_cmd_and_increment_cmd_pointer

        CMP     #$02
        BNE     L7A80

        JMP     L73D2
;...

;7AAA
.fn_brkv_handler
        ; -----------------------------------------------
        ; BRKV - Break handler 
        ; Intercepts a BRK instruction when executed - 
        ; if a BRK instruction then the address of the 
        ; byte following the BRK is held in $FD/$FE
        ; -----------------------------------------------
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

        ; Write LF and CR (ASCII $OD) to the screen
        ; Send $OD to OSASCI causes both a LF and CR
        ; to be sent to the screen
        LDA     #$0D
        JSR     OSASCI

        JMP     L7AEC

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
        JMP     L737F

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
        STX     zp_pb_input_string_buffer_lsb

        ; Set the MSB for the string buffer location £00xx
        LDX     #$00
        STX     zp_pb_input_string_buffer_lsb

        ; Save the maximum line length based on the passed Y value
        STY     zp_pb_max_input_length

        ; Set the minimum acceptable character value ($20 for space)
        LDX     #$20
        STX     zp_pb_min_character_value

        ; Set the maxmimum acceptable character value ($7F for delete)
        LDX     #$7F
        STX     zp_pb_max_character_value

        ; Set the MSB of the parameter block
        LDY     #$00

        ; Set the LSB of the parameter block
        LDX     #$37

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

;7BB8
.data_cmd_lookup_table
; TODO LOOKUP TABLE
        ; Routines to call when the virtual machine
        ; needs to execute an instruction - location 
        ; of the routine is the address + 1

        ; Goto - 0
        ;     Followed by 1 or 2 bytes of data to add
        ;     to $5C20 (number of bytes indicated by bit 7)
        ;     6th bit indicates if (1) double or (0) single byte
        EQUB    LO(fn_cmd_goto-1)
        EQUB    HI(fn_cmd_goto-1)

        ; intgosub - 1
        ; Uses a stack to put the return address on
        ; and goes to the address specified
        ; in byte1 and byte2
        EQUB    $A4,$76 
        
        ; intreturn - 2 
        ; Returns to the address on the stack
        EQUB    $C9,$76
        
        ; printnumber -3 
        ; prints the number that is held
        ; in the byte variable
        EQUB    $76,$74
        
        ; messagev - 4
        ; <command> <byte>
        ; <byte> address of variable that holds message
        ;
        ; VM Workspace variable message
        EQUB    $92,$75 
        
        ; messagec - 5
        ; <command> <LSB> [<MSB>]
        ;
        ; Print message
        ;     Followed by one or two bytes of data 
        ;     that indicate the nth message
        ;     
        ;     7th bit indicates if (1) double of (0) single byte
        ;
        ; Hardcoded message from the VM tape
        EQUB    LO(fn_cmd_print_message-1)
        EQUB    HI(fn_cmd_print_message-1)

        ; function - 6
        ; printstr and others in here
        EQUB    $75,$7A

        ; input - 7
        ; <command> <byte1> <byte2> <byte3> <byte4>
        ; <byte1> where to store the first cmd/obj
        ; <byte2> where to store the second cmd/obj
        ; <byte3> where to store the third cmd/obj
        ; <byte4> where to store the word count

        EQUB    LO(fn_cmd_get_player_input-1)
        EQUB    HI(fn_cmd_get_player_input-1)

        ; varcon - 8
        ; <command> <value> <target>
        EQUB    LO(fn_cmd_copy_from_constant_to_var-1)
        EQUB    HI(fn_cmd_copy_from_constant_to_var-1)

        ; varvar - 9
        ; <command> <source> <target>
        EQUB    LO(fn_cmd_copy_from_var1_to_var2-1)
        EQUB    HI(fn_cmd_copy_from_var1_to_var2-1)

        ; _add - 10
        ; target= target + source
        EQUB    LO(fn_add_var1_to_var2-1)
        EQUB    HI(fn_add_var1_to_var2-1)

        ; _sub - 11
        ; <command> <source> <target>
        ; target= target - source
        EQUB    LO(fn_subtract_var1_from_var2-1)
        EQUB    HI(fn_subtract_var1_from_var2-1)

        ; nothing - 12
        EQUB    $00,$00

        ; nothing - 13
        EQUB    $00,$00

        ; jump - 14
        EQUB    $DF,$75

        ; exit - 15
        EQUB    $BD,$79

        ; ifeqvt - 16
        ; checks two variables are the same
        ; and moves pointer to location if they are
        EQUB    $48,$79

        ; ifnevt - 17
        ; checks two variables are NOT the same
        ; and moves pointer to location if they are different
        EQUB    $59,$79

        ; ifltvt - 18   
        ; checks if variable 1 is less than variable
        ; 2 and im,f so moves pointer to location
        EQUB    $61,$79

        ; ifgtvt - 19
        ; checks if variable 1 is greater than variable
        ; 2 and if so moves pointer to location        
        EQUB    $6B,$79


        ; nothing - 20
        EQUB    $00,$00

        ; nothing - 21
        EQUB    $00,$00        

        ; nothing - 22
        EQUB    $00,$00        

        ; nothing - 23
        EQUB    $00,$00        

        ; ifeqct - 24
        ; Checks if variable 1 is equal to a constant
        ; value
        EQUB    $73,$79

        ; ifnect - 25
        ; Checks if variable 1 is NOT equal to a constant
        ; value
        EQUB    $7B,$79

        ; ifltct - 26
        ; Checks if variable 1 is less than a constant
        ; value
        EQUB    $83,$79

        ; ifgtct - 27
        ; Checks if variable 1 is greater than a constant
        ; value        
        ; <cmd> <byte1> <byte2>
        ; <byte1> vm workspace addr value
        ; <byte2> constant
        EQUB    $8D,$79

        ; nothing - 28
        EQUB    $00,$00        

        ; nothing - 29
        EQUB    $00,$00 

        ; nothing - 30  
        EQUB    $00,$00        


;TODO
        EQUS    "TIMEDAT" 
