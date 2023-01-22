load $1100 LORDSOF$

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

zp_load_file_parameter_block = $0037

zp_input_parameter_block_buffer_lsb=$0037
zp_digit_pos_lookup_table_lsb=$0037
zp_digit_pos_lookup_table_msb=$0038
zp_input_parameter_block_buffer_msb=$0038
zp_digit_in_position_flag=$0039
zp_input_parameter_block_max_length=$0039
zp_number_ascii_code=$003A
zp_input_parameter_block_min_char_value=$003A
zp_digit_pos_lookup_tale_offset=$003B
zp_input_parameter_block_max_char_value=$003B

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
zp_variable1_value_lsb=$0072
zp_1st_operand=$0072
zp_jump_table_offset_lsb=$0072
zp_encoded_string_counter_lsb=$0072
zp_random_seed_calc_area_lsb=$072
zp_constant_lsb=$0072
zp_variable1_value_msb=$0073
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

zp_current_word_ptr_lsb=$7A
zp_current_word_ptr_msb=$7B


zp_dictionary_ptr_lsb=$007C
zp_dictionary_ptr_msb=$007D
zp_exits_ptr_lsb=$007C
zp_exits_ptr_msb=$007D

; Zero Page
zp_a_code_ptr_lsb=$0080
zp_a_code_ptr_msb-$0081

zp_dictionary_start_lsb=$0082
zp_dictionary_start_msb=$0083

zp_cmd_and_obj_pointer_lsb=$84
zp_cmd_and_obj_pointer_msb=$85

zp_temp_cache_6=$0086
zp_from_location=$0006
zp_curr_input_char_cache=$86
zp_temp_cache_7=$0087
zp_move_direction=$0087

zp_to_location=$0088
zp_inverse_direction_location_counter=$088

data_dictionary_start=1220

data_a_code_start = $5C20

fn_game_entry_point = $7320

data_a_code_lsb = $7329
data_a_code_msb = $732A

fn_init_game = $7357

fn_process_general_opcode=$73A3

fn_write_char_to_screen = $73B2
no_carriage_return=$73C2

fn_load_game=$7431
fn_create_file_parameter_block=$743E

data_save_game_file_name=$746D
fn_find_nth_encoded_string=$74DF

fn_find_nth_game_description=$74D5

fn_reset_next_char_pointer=$754A

fn_cmd_messagev=$7593

calc_a_code_return_address=$76B4

fn_get_next_a_code_opcode = $76DD
fn_cmd_get_player_input=$7768

perform_goto_calc=$793A

fn_brkv_handler = $7AAA

data_cmd_lookup_table=$7BB8


save lordsoftime.asm