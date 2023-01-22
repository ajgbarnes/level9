
# Data Locations

These are the memory location for BBC Micro debugging of each of the labels in the assembly code.  Useful for setting breakpoints and looking at memory locations. Will also work for the datafile however the load address for each will have to be subtracted

|Label|Adventure Quest|Colossal Adventure|Dungeon Adventure|Lords of Time|Snowball|
|:---|:---:|:---:|:---:|:---:|:---:|
|data_dictionary_start|1c58|1180|1100|1220|1180|
|data_exits_start|1920|1530|e20|1b00|1890|
|data_list1_start|1bd0|n/a|17b0|1e00|1af0|
|data_list2_start|n/a|1896|n/a|n/a|n/a|
|data_list3_start|1c18|n/a|n/a|1f40|1b40|
|data_list4_start|1c40|18b6|n/a|1fb9|n/a|
|data_a_code_start|2120|18e0|1840|5c20|1b90|
|data_messages_start|3120|2860|2eff|2083|34c0|
|data_common_word_fragments_start|6af1|70b7|710c|5a0b|70d7|
|data_checksum_start_page_msb|n/a|n/a|n/a|7326|7326|
|data_checksum_loop_counter_max|n/a|n/a|n/a|7327|7327|
|data_calculated_checksum|n/a|n/a|n/a|7328|7328|
|data_a_code_address_lsb|7323|7323|7323|7329|7329|
|data_a_code_address_msb|7324|7324|7324|732a|732a|
|data_variables_start_address_lsb|7327|7327|7327|732d|732d|
|data_variables_start_address_msb|7328|7328|7328|732e|732e|
|data_location_exits_address_lsb|7329|7329|7329|732f|732f|
|data_location_exits_address_msb|732a|732a|732a|7330|7330|
|data_messages_address_lsb|732b|732b|732b|7331|7331|
|data_messages_address_msb|732c|732c|732c|7332|7332|
|data_common_word_fragments_address_lsb|732d|732d|732d|7333|7333|
|data_common_word_fragments_address_msb|732e|732e|732e|7334|7334|
|data_inverse_directions_table|732f|732f|732f|7335|7335|
|data_list_location_lookup_table|7343|7343|7343|7349|7349|
|data_save_game_file_name|7468|7468|7468|746d|746d|
|data_power_of_ten_table|7b84|7b84|7b84|7bac|7baa|
|data_cmd_lookup_table|7b90|7b90|7b90|7bb8|7bb6|
    
# Command Handlers

The table below contains the memory address for the Command Handlers.

|Label|Adventure Quest|Colossal Adventure|Dungeon Adventure|Lords of Time|Snowball|
|:---|:---:|:---:|:---:|:---:|:---:|
|fn_cmd_printnumber|7472|7472|7472|7477|7477|
|fn_cmd_messagev|758e|758e|758e|7593|7593|
|fn_cmd_messagec|759f|759f|759f|75a4|75a4|
|fn_cmd_add_var1_to_var2|75a9|75a9|75a9|75ae|75ae|
|fn_cmd_subtract_var2_from_var1|75c3|75c3|75c3|75c8|75c8|
|fn_cmd_jump|75db|75db|75db|75e0|75e0|
|fn_cmd_intgosub|76a0|76a0|76a0|76a5|76a5|
|fn_cmd_intreturn|76c5|76c5|76c5|76ca|76ca|
|fn_cmd_set_variable_to_constant|772b|772b|772b|7738|7738|
|fn_cmd_copy_from_var1_to_var2|7746|7746|7746|7753|7753|
|fn_cmd_get_player_input|775b|775b|775b|7768|7768|
|fn_cmd_goto|78fb|78fb|78fb|790a|790a|
|fn_cmd_if_var1_equals_var2_then_goto|793a|793a|793a|7949|7949|
|fn_cmd_if_var1_does_not_equal_var2_then_goto|794b|794b|794b|795a|795a|
|fn_cmd_if_var1_less_than_var2_then_goto|7953|7953|7953|7962|7962|
|fn_cmd_if_var1_greater_than_var2_then_goto|795d|795d|795d|796c|796c|
|fn_cmd_if_var1_equals_constant_then_goto|7965|7965|7965|7974|7974|
|fn_cmd_if_var1_does_not_equal_constant_then_goto|796d|796d|796d|797c|797c|
|fn_cmd_if_var1_is_less_than_constant_then_goto|7975|7975|7975|7984|7984|
|fn_cmd_if_var1_is_greater_than_constant_then_goto|797f|797f|797f|798e|798e|
|fn_cmd_exit|79af|79af|79af|79be|79be|
|fn_cmd_function|7a67|7a67|7a67|7a76|7a76|

# List Handlers

The table below contains the memory address for the List Handlers.

Note that listcv1 is defaulted to in fn_list_handler so doeesn't have it's own label

|Label|Adventure Quest|Colossal Adventure|Dungeon Adventure|Lords of Time|Snowball|
|:---|:---:|:---:|:---:|:---:|:---:|
|fn_list_handler|7629|7629|7629|762e|762e|
|fn_list_handler_listvv|7641|7641|7641|7646|7646|
|fn_list_handler_listv1c|7655|7655|7655|765a|765a|
|fn_list_handler_listv1v|7661|7661|7661|7666|7666|

# Supporting Functions

The table below contains all the functions that support Command and List Handlers, including the game entry points of *fn_game_entry_point* and *fn_other_entry_point*.

|Label|Adventure Quest|Colossal Adventure|Dungeon Adventure|Lords of Time|Snowball|
|:---|:---:|:---:|:---:|:---:|:---:|
|start|1900|1100|1100|1200|1100|
|data_dictionary_start|1c58|1180|1100|1220|1180|
|data_exits_start|1920|1530|e20|1b00|1890|
|data_list1_start|1bd0|n/a|17b0|1e00|1af0|
|data_list2_start|n/a|1896|n/a|n/a|n/a|
|data_list3_start|1c18|n/a|n/a|1f40|1b40|
|data_list4_start|1c40|18b6|n/a|1fb9|n/a|
|data_a_code_start|2120|18e0|1840|5c20|1b90|
|data_messages_start|3120|2860|2eff|2083|34c0|
|data_common_word_fragments_start|6af1|70b7|710c|5a0b|70d7|
|main_common_source_code|7320|7320|7320|7320|7320|
|fn_game_entry_point|7320|7320|7320|7320|7320|
|fn_calc_checksum_byte|n/a|n/a|n/a|7323|7323|
|data_checksum_start_page_msb|n/a|n/a|n/a|7326|7326|
|data_checksum_loop_counter_max|n/a|n/a|n/a|7327|7327|
|data_calculated_checksum|n/a|n/a|n/a|7328|7328|
|data_a_code_address_lsb|7323|7323|7323|7329|7329|
|data_a_code_address_msb|7324|7324|7324|732a|732a|
|data_variables_start_address_lsb|7327|7327|7327|732d|732d|
|data_variables_start_address_msb|7328|7328|7328|732e|732e|
|data_location_exits_address_lsb|7329|7329|7329|732f|732f|
|data_location_exits_address_msb|732a|732a|732a|7330|7330|
|data_messages_address_lsb|732b|732b|732b|7331|7331|
|data_messages_address_msb|732c|732c|732c|7332|7332|
|data_common_word_fragments_address_lsb|732d|732d|732d|7333|7333|
|data_common_word_fragments_address_msb|732e|732e|732e|7334|7334|
|data_inverse_directions_table|732f|732f|732f|7335|7335|
|data_list_location_lookup_table|7343|7343|7343|7349|7349|
|fn_init_game|7351|7351|7351|7357|7357|
|jump_to_a_code_virtual_machine|7379|7379|7379|737f|737f|
|loop_a_code_virtual_machine|737c|737c|737c|7382|7382|
|fn_process_general_opcode|739d|739d|739d|73a3|73a3|
|fn_write_char_to_screen|73ac|73ac|73ac|73b2|73b2|
|no_carriage_return|73bc|73bc|73bc|73c2|73c2|
|print_char_or_space|73c8|73c8|73c8|73ce|73ce|
|end_write_char_to_screen|73cb|73cb|73cb|73d1|73d1|
|fn_generate_random_seed|73cc|73cc|73cc|73d2|73d2|
|fn_other_entry_point|7420|7420|7420|7425|7425|
|fn_save_game|7423|7423|7423|7428|7428|
|fn_load_game|742c|742c|742c|7431|7431|
|set_param_block_lsb_and_call_osfile|7433|7433|7433|7438|7438|
|fn_create_file_parameter_block|7439|7439|7439|743e|743e|
|data_save_game_file_name|7468|7468|7468|746d|746d|
|fn_cmd_printnumber|7472|7472|7472|7477|7477|
|fn_decode_encoded_string|7484|7484|7484|7489|7489|
|loop_check_and_add_char_to_string_buffer|748d|748d|748d|7492|7492|
|continue_with_encoded_string|749f|749f|749f|74a4|74a4|
|fn_process_embedded_encoded_string|74b4|74b4|74b4|74b9|74b9|
|fn_find_nth_game_description|74d0|74d0|74d0|74d5|74d5|
|fn_find_nth_common_word_fragment|74da|74da|74da|74df|74df|
|loop_find_nth_encoded_string|74da|74da|74da|74df|74df|
|check_current_encoded_string_byte|74e1|74e1|74e1|74e6|74e6|
|fn_check_char_and_add_to_string_buffer|7508|7508|7508|750d|750d|
|check_if_underscore|750e|750e|750e|7513|7513|
|check_if_carriage_return|7514|7514|7514|7519|7519|
|fn_write_char_to_string_and_move_to_next_char|751e|751e|751e|7523|7523|
|fn_move_to_next_char_memory_address|7522|7522|7522|7527|7527|
|fn_write_string_and_then_start_new_line|7530|7530|7530|7535|7535|
|fn_reset_next_char_pointer|7545|7545|7545|754a|754a|
|fn_check_string_fits_on_current_line|754e|754e|754e|7553|7553|
|reset_next_char_pointer_to_start|7568|7568|7568|756d|756d|
|fn_print_next_char|756b|756b|756b|7570|7570|
|fn_reset_next_char_ptr_and_write_space|757e|757e|757e|7583|7583|
|fn_cmd_messagev|758e|758e|758e|7593|7593|
|fn_cmd_messagec|759f|759f|759f|75a4|75a4|
|fn_cmd_add_var1_to_var2|75a9|75a9|75a9|75ae|75ae|
|fn_cmd_subtract_var2_from_var1|75c3|75c3|75c3|75c8|75c8|
|fn_cmd_jump|75db|75db|75db|75e0|75e0|
|set_jump_table_offset|75ec|75ec|75ec|75f1|75f1|
|fn_list_handler|7629|7629|7629|762e|762e|
|fn_list_handler_listvv|7641|7641|7641|7646|7646|
|fn_list_set_nth_list_entry_to_variable_value|764a|764a|764a|764f|764f|
|fn_list_handler_listv1c|7655|7655|7655|765a|765a|
|fn_list_handler_listv1v|7661|7661|7661|7666|7666|
|fn_list_get_nth_list_entry_and_set_variable|766a|766a|766a|766f|766f|
|fn_get_operand_variable_value|767a|767a|767a|767f|767f|
|fn_list_get_start_address|7685|7685|7685|768a|768a|
|fn_list_add_offset_to_list_start_address|7692|7692|7692|7697|7697|
|fn_cmd_intgosub|76a0|76a0|76a0|76a5|76a5|
|calc_a_code_return_address|76af|76af|76af|76b4|76b4|
|fn_cmd_intreturn|76c5|76c5|76c5|76ca|76ca|
|fn_get_next_a_code_byte|76d8|76d8|76d8|76dd|76dd|
|fn_get_jump_table_offset|76f0|76f0|76f0|76f5|76f5|
|fn_get_a_code_variable_number|76f0|76f0|76f0|76f5|76f5|
|get_variable_value|770b|770b|770b|7718|7718|
|fn_get_a_code_opcode_operands|7710|7710|7710|771d|771d|
|fn_get_a_code_opcode_operand_single_byte|7721|7721|7721|772e|772e|
|fn_cmd_set_variable_to_constant|772b|772b|772b|7738|7738|
|fn_set_constant_address_location|7734|7734|7734|7741|7741|
|fn_copy_memory_address_ptr|773d|773d|773d|774a|774a|
|fn_cmd_copy_from_var1_to_var2|7746|7746|7746|7753|7753|
|fn_copy_from_memory_to_memory|7749|7749|7749|7756|7756|
|fn_cmd_get_player_input|775b|775b|775b|7768|7768|
|fn_store_matched_cmds_and_objects|775e|775e|775e|776b|776b|
|fn_set_variable_value|7775|7775|7775|7784|7784|
|fn_get_and_parse_player_input|7784|7784|7784|7793|7793|
|count_next_word|77b4|77b4|77b4|77c3|77c3|
|loop_find_end_of_word|77bc|77bc|77bc|77cb|77cb|
|input_words_counted|77cd|77cd|77cd|77dc|77dc|
|compare_current_input_word|77d9|77d9|77d9|77e8|77e8|
|compare_next_dict_char_against_input_char|77e7|77e7|77e7|77f6|77f6|
|loop_until_end_of_dict_word|7818|7818|7818|7827|7827|
|fn_player_input_string_parsed|7830|7830|7830|783f|783f|
|fn_check_word_against_next_dict_entry|7833|7833|7833|7842|7842|
|fn_reset_dict_and_compare_next_word|7844|7844|7844|7853|7853|
|fn_find_next_dict_entry_and_compare|784a|784a|784a|7859|7859|
|loop_get_next_dict_chr|784b|784b|784b|785a|785a|
|fn_loop_to_end_of_current_input_word|786a|786a|786a|7879|7879|
|fn_end_cmd_or_obj_seq_and_process|7889|7889|7889|7898|7898|
|fn_cache_cmd_or_obj|7891|7891|7891|78a0|78a0|
|fn_find_next_non_space_in_input_string|78a3|78a3|78a3|78b2|78b2|
|loop_check_next_input_character|78a3|78a3|78a3|78b2|78b2|
|fn_inc_input_string_buffer_pointer|78b0|78b0|78b0|78bf|78bf|
|fn_inc_dictionary_or_exits_ptr|78be|78be|78be|78cd|78cd|
|fn_dec_input_string_buffer_pointer|78cc|78cc|78cc|78db|78db|
|fn_dec_exit_or_dictionary_pointer|78da|78da|78da|78e9|78e9|
|fn_get_input_character|78e8|78e8|78e8|78f7|78f7|
|fn_get_exits_or_dictionary_byte|78ed|78ed|78ed|78fc|78fc|
|fn_init_dictionary_pointer|78f2|78f2|78f2|7901|7901|
|fn_cmd_goto|78fb|78fb|78fb|790a|790a|
|single_byte_offset|7917|7917|7917|7926|7926|
|perform_goto_calc|792b|792b|792b|793a|793a|
|fn_cmd_if_var1_equals_var2_then_goto|793a|793a|793a|7949|7949|
|skip_over_operands|793f|793f|793f|794e|794e|
|only_one_operand|7948|7948|7948|7957|7957|
|fn_cmd_if_var1_does_not_equal_var2_then_goto|794b|794b|794b|795a|795a|
|fn_cmd_if_var1_less_than_var2_then_goto|7953|7953|7953|7962|7962|
|fn_cmd_if_var1_greater_than_var2_then_goto|795d|795d|795d|796c|796c|
|fn_cmd_if_var1_equals_constant_then_goto|7965|7965|7965|7974|7974|
|fn_cmd_if_var1_does_not_equal_constant_then_goto|796d|796d|796d|797c|797c|
|fn_cmd_if_var1_is_less_than_constant_then_goto|7975|7975|7975|7984|7984|
|fn_cmd_if_var1_is_greater_than_constant_then_goto|797f|797f|797f|798e|798e|
|fn_get_var1_and_var2_and_check_if_equal|7987|7987|7987|7996|7996|
|fn_get_var_and_constant_and_check_if_equal|7993|7993|7993|79a2|79a2|
|fn_check_if_equal|799f|799f|799f|79ae|79ae|
|return_check_if_equal|79ae|79ae|79ae|79bd|79bd|
|fn_cmd_exit|79af|79af|79af|79be|79be|
|fn_check_if_move_direction_allowed|79ca|79ca|79ca|79d9|79d9|
|loop_find_nth_location_exits_start|79d2|79d2|79d2|79e1|79e1|
|loop_check_location_exits_for_match|79e4|79e4|79e4|79f3|79f3|
|direction_did_not_match_player_direction|79fb|79fb|79fb|7a0a|7a0a|
|check_locations_for_inverse_direction|7a0b|7a0b|7a0b|7a1a|7a1a|
|loop_check_next_location_for_inverse_direction|7a19|7a19|7a19|7a28|7a28|
|exit_cannot_be_used_for_reverse_lookup|7a3e|7a3e|7a3e|7a4d|7a4d|
|to_location_did_not_match|7a3e|7a3e|7a3e|7a4d|7a4d|
|skip_inc_location_number|7a4a|7a4a|7a4a|7a59|7a59|
|fn_reset_exits_ptr|7a5c|7a5c|7a5c|7a6b|7a6b|
|fn_cmd_function|7a67|7a67|7a67|7a76|7a76|
|check_if_save_game|7a71|7a71|7a71|7a80|7a80|
|check_if_load_game|7a78|7a78|7a78|7a87|7a87|
|check_if_clear_variables|7a7f|7a7f|7a7f|7a8e|7a8e|
|fn_clear_variables|7a8a|7a8a|7a8a|7a99|7a99|
|loop_clear_var_memory|7a90|7a90|7a90|7a9d|7a9d|
|fn_clear_stack|7a97|7a97|7a97|7aa0|7aa0|
|fn_brkv_handler|7aa1|7aa1|7aa1|7aaa|7aaa|
|escape_pressed|7acd|7acd|7acd|7ac9|7ac9|
|end_brkv_handler|7af0|7af0|7af0|7aec|7aec|
|fn_read_player_input|7af3|7af3|7af3|7aef|7aef|
|end_read_player_input|7b1f|7b1f|7b1f|7b1b|7b1b|
|fn_get_data_checksum|n/a|n/a|n/a|7b1c|7b1c|
|loop_checksum_calc|n/a|n/a|n/a|7b2c|7b2a|
|fn_actually_printnumber|7b20|7b20|7b20|7b48|7b46|
|move_to_next_digit_pos_outer_loop|7b3c|7b3c|7b3c|7b64|7b62|
|subtraction_inner_loop|7b56|7b56|7b56|7b7e|7b7c|
|check_if_digit_found|7b70|7b70|7b70|7b98|7b96|
|print_zero|7b7e|7b7e|7b7e|7ba6|7ba4|
|print_number_complete|7b83|7b83|7b83|7bab|7ba9|
|data_power_of_ten_table|7b84|7b84|7b84|7bac|7baa|
|data_cmd_lookup_table|7b90|7b90|7b90|7bb8|7bb6|
|end|7c00|7c00|7c00|7bff|7bff|