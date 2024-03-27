////////////////////////////////////////////////////////////////////////////////
// Filename    : ahblite_interconnect_compare.sv
// Description : 
//
// Author      : Phu Vuong
// History     : Mar 26, 2024 : Initial     
//
////////////////////////////////////////////////////////////////////////////////
module ahblite_interconnect_compare_1bit (
    output logic    comp_o,
    input           flag_le, //flag larger or equal
    input           a,
    input           b
);
    ////////////////////////////////////////////////////////////////////////////
    //design description
    ////////////////////////////////////////////////////////////////////////////
    assign comp_o = flag_le | a | ~b;
endmodule