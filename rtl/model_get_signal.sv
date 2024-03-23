////////////////////////////////////////////////////////////////////////////////
// Filename    : model_get_signal.sv
// Description : 
//
// Author      : Phu Vuong
// History     : Feb 22, 2024 : Initial     
//
////////////////////////////////////////////////////////////////////////////////
module model_get_signal #(
    parameter       WIDTH           = 32,
    parameter       HEIGHT          = 32,
    parameter       SEL             = 0
) (
    //-----------------------
    //input
    input           [WIDTH-1:0]     in[HEIGHT-1:0],
	
    //-----------------------
    //output
    output logic    [WIDTH-1:0]     out
);
    ////////////////////////////////////////////////////////////////////////////
    //design description
    ////////////////////////////////////////////////////////////////////////////
    assign out = in[SEL];


endmodule
