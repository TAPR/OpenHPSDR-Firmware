ASMI	ASMI_inst (
	.addr ( addr_sig ),
	.bulk_erase ( bulk_erase_sig ),
	.clkin ( clkin_sig ),
	.datain ( datain_sig ),
	.rden ( rden_sig ),
	.read ( read_sig ),
	.sector_erase ( sector_erase_sig ),
	.sector_protect ( sector_protect_sig ),
	.shift_bytes ( shift_bytes_sig ),
	.wren ( wren_sig ),
	.write ( write_sig ),
	.busy ( busy_sig ),
	.data_valid ( data_valid_sig ),
	.dataout ( dataout_sig ),
	.illegal_erase ( illegal_erase_sig ),
	.illegal_write ( illegal_write_sig )
	);
