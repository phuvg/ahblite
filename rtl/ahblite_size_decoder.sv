////////////////////////////////////////////////////////////////////////////////
// Filename    : ahblite_size_decoder.sv
// Description : 
//
// Author      : Phu Vuong
// History     : Jul 31, 2022 : Initial     
//
////////////////////////////////////////////////////////////////////////////////
module ahblite_size_decoder(
    //-----------------------
    //output
    output logic                size_byte,
    output logic                size_halfword,
    output logic                size_word,
    output logic                size_doubleword,
    output logic                size_quadrupleword,
    output logic                size_octupleword,
    output logic                size_sexdecupleword,
    output logic                size_duotrigintupleword,
	
    //-----------------------
    //input
    input   [2:0]               HSIZE
);
    ////////////////////////////////////////////////////////////////////////////
    //design description
    ////////////////////////////////////////////////////////////////////////////
    ahblite_decoder_2to4 i_decoder_2to4_01(
        .out_o({size_duotrigintupleword, size_sexdecupleword, size_octupleword, size_quadrupleword}),
        .en_i(HSIZE[2]),
        .in_i(HSIZE[1:0])
    );

    ahblite_decoder_2to4 i_decoder_2to4_00(
        .out_o({size_doubleword, size_word, size_halfword, size_byte}),
        .en_i(~HSIZE[2]),
        .in_i(HSIZE[1:0])
    );

endmodule
