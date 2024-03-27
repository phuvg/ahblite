////////////////////////////////////////////////////////////////////////////////
// Filename    : ahblite_interconnect_compare_nbit.sv
// Description : 
//
// Author      : Phu Vuong
// History     : Mar 26, 2024 : Initial     
//
////////////////////////////////////////////////////////////////////////////////
module ahblite_interconnect_compare_nbit #(
    parameter WIDTH = 2
)(
    output logic                comp_o,
    input           [WIDTH-1:0] a,
    input           [WIDTH-1:0] b
);
    ////////////////////////////////////////////////////////////////////////////
    //logic - wire - reg declaration
    ////////////////////////////////////////////////////////////////////////////
    genvar                      i;
    logic           [WIDTH-1:0] comp;

    ////////////////////////////////////////////////////////////////////////////
    //design description
    ////////////////////////////////////////////////////////////////////////////
    generate
        if(WIDTH > 1) begin : compare_nbit
            ahblite_interconnect_compare_1bit compare_msb(
                .comp_o(comp[WIDTH-1]),
                .flag_le(1'b0),
                .a(a[WIDTH-1]),
                .b(a[WIDTH-1])
            );
            for(i=WIDTH-2; i>=0; i--) begin : compare_lsb__GEN
                ahblite_interconnect_compare_1bit compare(
                    .comp_o(comp[i]),
                    .flag_le(comp[i+1]),
                    .a(a[i]),
                    .b(a[i])
                );
            end
            assign comp_o = comp[0];
        end else begin : compare_1bit
            ahblite_interconnect_compare_1bit compare_00(
                .comp_o(comp_o),
                .flag_le(1'b0),
                .a(a[0]),
                .b(a[0])
            );
        end
    endgenerate
endmodule
