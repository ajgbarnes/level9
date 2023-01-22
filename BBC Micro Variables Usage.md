# Level 9's BBC Micro A-Code Version 1 Engine Zero Page Usage

The table below contains details of how Level 9's BBC Micro Version 1 A-Code Engine uses zero page to process the game. Some zero page locations are used for multiple purposes as demonstrated in the table. 

When debugging the following are the most important to track:
- zp_a_code_ptr_lsb/msb - the pointer into the A-Code
- zp_dictionary_start_lsb/msb - the pointer into the dictionary
- zp_variable_ptr_lsb/msb - the pointer to the current variable's value
- zp_exits_ptr_lsb/msb - the pointer into the exits list

| From  | To    | Assembler Name                    | Description              |
| :---: | :---: | -------------                     | -----------              |
| $0000 | $0038 | zp_general_string_buffer          | (Variable) Used to collect the 39 (max) characters of player input |
| $0000 | $0004 | n/a                               | (Variable) The player's input above is overwritten with the matched dictionary command ids or object ids (up to a max of 3) and then terminated with a $00.  Referenced by the zp_cmd_and_obj_pointer_lsb/msb pointer  |
| ..... | ..... |                                   | |
| $0037 | $0038 | zp_digit_pos_lookup_table_lsb/msb | (Variable) Used to store the memory address of the "power of ten" lookup table. This is used to determine which digits of a number to print |
| $0037 | $0041 | zp_input_parameter_block          | (Variable) Contains the buffer parameter block configuration to capture the player's input using OSWORD: |
|       |       |                                   | - $0037/38 - Starting memory address of where to write the player's input, the string buffer location. Always set to $0000 |
|       |       |                                   | - $0038    - Maximum input line length. Always set to ($27) 39  |
|       |       |                                   | - $0039    - Minimum acceptable ASCII value ($20) space         |
|       |       |                                   | - $004A    - Maximum acceptable ASCII value ($7F) delete        |
| $0037 | $0048 | zp_file_parameter_block           | (Variable) Contains the LOAD or SAVE file parameters for the call to OSFILE  |
|       |       |                                   | - $0037/38 - Address of the memory location that contains the filename to load or save terminated by a $0D e.g. ($746D) for Lords of Time: |
|       |       |                                   | - $0039/3C - Load address of the file ($FFFF0400)             |
|       |       |                                   | - $003D/40 - Undefined - execution address is not required    |
|       |       |                                   | - $0041/44 - Start address of data for save ($FFFF0400)       |
|       |       |                                   | - $0045/48 - End address of data for load (either $FFFF06FF for Snowball and Lords of Time or $FFFF05FF for all others )  |
| $0039 | $0039 | zp_digit_found_flag               | (Variable) Set when a digit is found to be printed in in the "power of ten" table. All subsequent digits printed. |
| $003A | $003A | zp_number_ascii_code              | (Variable) When printing digits, the derived ASCII code for the number in the current digit position |
| $003B | $003B | zp_digit_pos_lookup_table_offset  | (Variable) Index into the "power of ten" lookup table |
| ..... | ..... |                                   | |
| $0060 | $0061 | zp_encoded_string_ptr_lsb/msb     | (Variable) Pointer to an encoded string in the messages or common word fragments table |
| $0062 | $0063 | zp_current_input_char_lsb/msb     | (Variable) Pointer to the current input string character during procsesing of the player's input.  Points to $0000+ |
| $0064 | $0064 | zp_chars_on_current_line          | (Variable) Count of number of characters written to the current screen row. Used in output formatting to prevent writing a carriage return if less than two characters have been written and not writing a space at the beginning of a line (first two positions). |
| $0068 | $0069 | zp_random_seed_lsb/msb            | (Variable) Holds the random seed that can be used for game events  |
| $006A | $006B | zp_number_lsb/msb                 | (Variable) Initially holds the number to print during a print number command.  And when determining digits, it holds the remainder as it subtracts powers of ten, printing digits from here as it goes|
| $006A | $006A | zp_temp_cache_1                   | (Variable) Used to hold transient values or cache values in calculations |
| $006B | $006B | zp_temp_cache_2                   | (Variable) Used to hold transient values or cache values in calculations |
| $006C | $006C | zp_temp_cache_3                   | (Variable) Used to hold transient values or cache values in calculations |
| $006D | $006D | zp_temp_cache_4                   | (Variable) Used to hold transient values or cache values in calculations |
| $006E | $006E | zp_opcode_7th_bit                 | (Variable) Indicates if there are one or two bytes / operands for the constant in the A-code in any command that uses one e.g. messagec, varcon, ifeqct, ifnect, ifltct and ifgtct. 0x01 means only only one byte/operand and 0x00 means two bytes/operands |
| $006F | $006F | zp_opcode_6th_bit                 | (Variable) Indicates if there are one or two bytes / operands for the goto / gosub address in the A-code. Double bytes are always positive and relative from start of the A-code, single bytes are positive/negative from the current position.  |
| $0070 | $0071 | zp_variable_ptr_lsb/msb           | (Variable) Points to the 16-bit variable's memory location (always in $0400+) unless a routine is using a constant, in which case it'll be set to $0072 where the constant's value will be held.|
|       |       | zp_constant_lsb/msb               | (Variable) [see above] |
|       |       | zp_variable1_value_lsb/msb        | (Variable) When a variable is read, it's value is stored here |
|       |       | zp_random_seed_calc_area_lsb/msb  | (Variable) Used to hold transient values when calculating a new random seed. |
|       |       | zp_jump_table_offset_lsb/msb      | (Variable) Used to hold the calcuation for the absolute memory address for the nth entry in the desired jump table.    |
|       |       | zp_encoded_string_counter_lsb/msb | (Variable) When looping though common word fragments, it contains the countdown value until the nth fragment is found.   it is used to hold the current memory address |
|       |       | zp_variable_value_msb             | (Variable) When more than one variable is read, the code will store the value of one here rather than in $74/$75 as this will be needed for the second variable value |
|       |       | zp_1st/2nd_operand                | (Variable) When code is general and it doesn't know if an operand is a variable or constant, this symbol is used.  |
| $0074 | $0075 | zp_list_ptr_lsb                   | (Variable) When the list handler is processing a list, it uses this to move through the list. |
|       |       | zp_jump_table_entry_offset_lsb    | (Variable) Used to calculate the nth entry offset from the start of the jump table - these are 16-bit values so it takes the number and multiplies by 2 to get the byte that starts the nth entry.  This is subsequently added onto the jump table start address. |
|       |       | zp_cached_ptr_lsb/msb             | (Variable) Used to cache the memory address of one of the variables being manipulated e.g. during a ifgtvt operation |
| $0076 | $0077 | zp_input_string_buffer_ptr_lsb/msb| (Variable) Pointer used to process the player input held in $0000 |
| $0078 | $0078 | zp_input_words_count              | (Variable) Count of number of words that the player entered and currently held in $0000+ |
| ..... | ..... |                                   | |
| $007A | $007B | zp_current_word_ptr_lsb/msb       | (Variable) Used to cache the start of the word being parsed. This is case it's only a partial match against a dictionary word, the code can rewind to the start of the input word and check the next dictionary entry against it. |
| $007C | $007D | zp_dictionary_ptr_lsb/msb         | (Variable) When parsing the player's input, this location is used to hold the pointer into the dictionary. |
|       |       | zp_exits_ptr_lsb/msb              | (Variable) When checking to see if the player's requested direction is possible, it is used as the pointer in the exits data. |
| ..... | ..... |                                   | |
| $0080 | $0081 | zp_a_code_ptr_lsb/msb             | (Variable) The A-Code program counter - where in the A-code the execution has reached. |
| $0082 | $0083 | zp_dictionary_start_lsb/msb       | (Constant) Holds the start memory address of the dictionary (does not change) |
| $0084 | $0085 | zp_cmd_and_obj_pointer_lsb/msb    | (Variable) Used to store the command and object ids from the dictionary in the first three bytes of $0000+ as the words are parsed and matched against dictionary items. |
| $0086 | $0086 | zp_from_location                  | (Variable) When requesting to move in a direction, this holds the player's current location (where they are moving from) |
|       |       | zp_temp_cache_5                   | (Variable) Used to hold transient values or cache values in calculations |
|       |       | zp_curr_input_char_cache          | (Variable) Used to cache the currently being compared player's input character |
| $0087 | $0087 | zp_temp_cache_6                   | (Variable) Used to hold transient values or cache values in calculations |
|       |       | zp_move_direction                 | (Variable) When requesting to move in a direction, this holds the player's requested direction code e.g. 0x01 for North |
| $0088 | $0088 | zp_to_location                    | (Variable) When requesting to move in a direction, if the move is allowed, then this will be set to the location to where the player wll move. |
|       |       | zp_inverse_direction_counter      | (Variable) Used to index the inverse direction lookup table during exits processing |

