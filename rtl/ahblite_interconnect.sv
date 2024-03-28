////////////////////////////////////////////////////////////////////////////////
// Filename    : ahblite_interconnect.sv
// Description : 
//
// Author      : Phu Vuong
// History     : Mar 28, 2024 : Initial     
//
////////////////////////////////////////////////////////////////////////////////
module ahblite_interconnect #(
    parameter       MASTER                          = 1,
    parameter       SLAVE                           = 1,
    parameter       HADDR_WIDTH                     = 32,
    parameter       HDATA_WIDTH                     = 32
)(
    //#--> Global signal
    input                                           HCLK,
    input                                           HRESETn,

    //#--> connect with ahb master
    output logic    [MASTER-1:0][HDATA_WIDTH-1:0]   mst_HRDATA_o,
    output logic    [MASTER-1:0]                    mst_HREADYOUT_o,
    input           [MASTER-1:0][1:0]               mst_HTRANS_i,
    input           [MASTER-1:0][2:0]               mst_HBURST_i,
    input           [MASTER-1:0][2:0]               mst_HSIZE_i,
    input           [MASTER-1:0]                    mst_HWRITE_i,
    input           [MASTER-1:0][HADDR_WIDTH-1:0]   mst_HADDR_i,
    input           [MASTER-1:0][HDATA_WIDTH-1:0]   mst_HWDATA_i,
    input           [MASTER-1:0]                    mst_HMASTLOCK_i,
    input           [MASTER-1:0][6:0]               mst_HPROT_i,
    input           [MASTER-1:0]                    mst_HNONSEC_i,
    input           [MASTER-1:0]                    mst_HEXCL_i,
    input           [MASTER-1:0][3:0]               mst_HMASTER_i,
    input           [MASTER-1:0]                    mst_HREADY_i,

    //#--> connect with ahb slave
    output logic    [SLAVE-1:0][1:0]                slv_HTRANS_o,
    output logic    [SLAVE-1:0][2:0]                slv_HBURST_o,
    output logic    [SLAVE-1:0][2:0]                slv_HSIZE_o,
    output logic    [SLAVE-1:0]                     slv_HWRITE_o,
    output logic    [SLAVE-1:0][HDATA_WIDTH-1:0]    slv_HADDR_o,
    output logic    [SLAVE-1:0][HDATA_WIDTH-1:0]    slv_HWDATA_o,
    output logic    [SLAVE-1:0]                     slv_HMASTLOCK_o,
    output logic    [SLAVE-1:0][6:0]                slv_HPROT_o,
    output logic    [SLAVE-1:0]                     slv_HNONSEC_o,
    output logic    [SLAVE-1:0]                     slv_HEXCL_o,
    output logic    [SLAVE-1:0][3:0]                slv_HMASTER_o,
    output logic    [SLAVE-1:0]                     slv_HREADYOUT_o,
    input           [SLAVE-1:0][HDATA_WIDTH-1:0]    slv_HRDATA_i,
    input           [SLAVE-1:0]                     slv_HREADY_i,
    input           [SLAVE-1:0]                     slv_HRESP_i,
    input           [SLAVE-1:0]                     slv_HEXOKAY_i,
    input           [SLAVE-1:0][HADDR_WIDTH-1:0]    slv_HADDR_base_i,
    input           [SLAVE-1:0][HADDR_WIDTH-1:0]    slv_HADDR_mask_i
);
    ////////////////////////////////////////////////////////////////////////////
    //parameter declaration
    ////////////////////////////////////////////////////////////////////////////

	
    ////////////////////////////////////////////////////////////////////////////
    //logic - wire - reg declaration
    ////////////////////////////////////////////////////////////////////////////
    
    
    ////////////////////////////////////////////////////////////////////////////
    //design description
    ////////////////////////////////////////////////////////////////////////////
    //#--> masterport
    generate
        for(mst_sel=0; mst_sel<MASTER; mst_sel++) begin : masterport__GEN
            ahblite_interconnect_masterport #(
                .SLAVE(SLAVE),
                .HADDR_WIDTH(HADDR_WIDTH),
                .HDATA_WIDTH(HDATA_WIDTH)
            ) masterport (
                //#--> Global signal
                .HCLK(HCLK),
                .HRESETn(HRESETn),
                
                //#--> connect with slaveport
                .slv_HTRANS_o(),
                .slv_HBURST_o(),
                .slv_HSIZE_o(),
                .slv_HWRITE_o(),
                .slv_HADDR_o(),
                .slv_HWDATA_o(),
                .slv_HMASTLOCK_o(),
                .slv_HPROT_o(),
                .slv_HNONSEC_o(),
                .slv_HEXCL_o(),
                .slv_HMASTER_o(),
                .slv_HREADYOUT_o(),
                .slv_HRDATA_i(),
                .slv_HREADY_i(),
                .slv_HRESP_i(),
                .slv_HEXOKAY_i(),
                	
                //#--> connect with ahb master
                .mst_HRDATA_o(mst_HRDATA_o[mst_sel]),
                .mst_HREADYOUT_o(mst_HREADYOUT_o[mst_sel]),
                .mst_HTRANS_i(mst_HTRANS_i[mst_sel]),
                .mst_HBURST_i(mst_HBURST_i[mst_sel]),
                .mst_HSIZE_i(mst_HSIZE_i[mst_sel]),
                .mst_HWRITE_i(mst_HWRITE_i[mst_sel]),
                .mst_HADDR_i(mst_HADDR_i[mst_sel]),
                .mst_HWDATA_i(mst_HWDATA_i[mst_sel]),
                .mst_HMASTLOCK_i(mst_HMASTLOCK_i[mst_sel]),
                .mst_HPROT_i(mst_HPROT_i[mst_sel]),
                .mst_HNONSEC_i(mst_HNONSEC_i[mst_sel]),
                .mst_HEXCL_i(mst_HEXCL_i[mst_sel]),
                .mst_HMASTER_i(mst_HMASTER_i[mst_sel]),
                .mst_HREADY_i(mst_HREADY_i[mst_sel]),
                
                //#--> internal connect
                .mst_HSEL_o(),
                .mst_switch_o(),
                .slv_HADDR_base_i(),
                .slv_HADDR_mask_i(),
                .mst_grant_i()
            );
        end
    endgenerate

    //#--> slaveport
    generate
        for(slv_sel=0; slv_sel<SLAVE; slv_sel++) begin : slaveport__GEN
            ahblite_interconnect_masterport #(
                .MASTER(MASTER),
                .HADDR_WIDTH(HADDR_WIDTH),
                .HDATA_WIDTH(HDATA_WIDTH)
            ) slaveport (
                //#--> Global signal
                .HCLK(HCLK),
                .HRESETn(HRESETn),
                
                //#--> connect with masterport
                .mst_HRDATA_o(),
                .mst_HREADYOUT_o(),
                .mst_HRESP_o(),
                .mst_HEXOKAY_o(),
                .mst_HTRANS_i(),
                .mst_HBURST_i(),
                .mst_HSIZE_i(),
                .mst_HWRITE_i(),
                .mst_HADDR_i(),
                .mst_HWDATA_i(),
                .mst_HMASTLOCK_i(),
                .mst_HPROT_i(),
                .mst_HNONSEC_i(),
                .mst_HEXCL_i(),
                .mst_HMASTER_i(),
                .mst_HREADY_i(),
                	
                //#--> connect with ahb slave
                .slv_HTRANS_o(slv_HTRANS_o[slv_sel]),
                .slv_HBURST_o(slv_HBURST_o[slv_sel]),
                .slv_HSIZE_o(slv_HSIZE_o[slv_sel]),
                .slv_HWRITE_o(slv_HWRITE_o[slv_sel]),
                .slv_HADDR_o(slv_HADDR_o[slv_sel]),
                .slv_HWDATA_o(slv_HWDATA_o[slv_sel]),
                .slv_HMASTLOCK_o(slv_HMASTLOCK_o[slv_sel]),
                .slv_HPROT_o(slv_HPROT_o[slv_sel]),
                .slv_HNONSEC_o(slv_HNONSEC_o[slv_sel]),
                .slv_HEXCL_o(slv_HEXCL_o[slv_sel]),
                .slv_HMASTER_o(slv_HMASTER_o[slv_sel]),
                .slv_HREADYOUT_o(slv_HREADYOUT_o[slv_sel]),
                .slv_HRDATA_i(slv_HRDATA_i[slv_sel]),
                .slv_HREADY_i(slv_HREADY_i[slv_sel]),
                .slv_HRESP_i(slv_HRESP_i[slv_sel]),
                .slv_HEXOKAY_i(slv_HEXOKAY_i[slv_sel]),
                .slv_HADDR_base_i(slv_HADDR_base_i[slv_sel]),
                .slv_HADDR_mask_i(slv_HADDR_mask_i[slv_sel]),
                
                //#--> internal connect
                .mst_grant_o(),
                .slv_HADDR_base_o(),
                .slv_HADDR_mask_o(),
                .mst_switch_i(),
                .mst_HSEL_i()
            );
        end
    endgenerate
endmodule
