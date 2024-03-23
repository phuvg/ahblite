////////////////////////////////////////////////////////////////////////////////
// Filename    : ahblite_decoder_2to4.sv
// Description : 
//
// Author      : Phu Vuong
// History     : Aug 15, 2023 : Initial     
//
////////////////////////////////////////////////////////////////////////////////
module ahblite_decoder_2to4(
    //-----------------------
    //output
    output logic    [3:0]               out_o,
    //-----------------------
    //input
    input                               en_i,
    input           [1:0]               in_i
);
    ////////////////////////////////////////////////////////////////////////////
    //design description
    ////////////////////////////////////////////////////////////////////////////
    assign out_o[3] = en_i & in_i[1] & in_i[0];
    assign out_o[2] = en_i & in_i[1] & (~in_i[0]);
    assign out_o[1] = en_i & (~in_i[1]) & in_i[0];
    assign out_o[0] = en_i & (~in_i[1]) & (~in_i[0]);
endmodule
