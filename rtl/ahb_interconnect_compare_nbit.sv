////////////////////////////////////////////////////////////////////////////////
// Filename    : ahb_interconnect_compare_nbit.sv
// Description : 
//
// Author      : Phu Vuong
// History     : Mar 26, 2024 : Initial     
//
////////////////////////////////////////////////////////////////////////////////
module ahb_interconnect_compare_nbit #(
    parameter WIDTH = 2
)(
    output logic                ol,
    output logic                oe,
    input           [WIDTH-1:0] a,
    input           [WIDTH-1:0] b
);
    ////////////////////////////////////////////////////////////////////////////
    //logic - wire - reg declaration
    ////////////////////////////////////////////////////////////////////////////
    genvar                      i;
    logic           [WIDTH-1:0] cl;
    logic           [WIDTH-1:0] ce;

    ////////////////////////////////////////////////////////////////////////////
    //design description
    ////////////////////////////////////////////////////////////////////////////
    generate
        if(WIDTH > 1) begin : compare_nbit
            ahb_interconnect_compare_1bit compare_msb(
                .ol(cl[WIDTH-1]),
                .oe(ce[WIDTH-1]),
                .fl(1'b0),
                .fe(1'b0),
                .a(a[WIDTH-1]),
                .b(a[WIDTH-1])
            );
            for(i=WIDTH-2; i>=0; i--) begin : compare_lsb__GEN
                ahb_interconnect_compare_1bit compare(
                    .ol(cl[i]),
                    .oe(ce[i]),
                    .fl(cl[i+1]),
                    .fe(ce[i+1]),
                    .a(a[i]),
                    .b(a[i])
                );
            end
            assign ol = cl[0];
            assign oe = ce[0];
        end else begin : compare_1bit
            ahb_interconnect_compare_1bit compare_00(
                .ol(ol),
                .oe(oe),
                .fl(1'b0),
                .fe(1'b0),
                .a(a[0]),
                .b(a[0])
            );
        end
    endgenerate
endmodule