////////////////////////////////////////////////////////////////////////////////
// Filename    : ahb_interconnect.sv
// Description : 
//
// Author      : Phu Vuong
// History     : Mar 28, 2024 : Initial     
//
////////////////////////////////////////////////////////////////////////////////
module ahb_interconnect #(
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
    //genvar
    genvar                                          mst_sel;
    genvar                                          slv_sel;

    //from masterport to slaveport
    logic   [MASTER-1:0][SLAVE-1:0][1:0]            from_mst_HTRANS;
    logic   [MASTER-1:0][SLAVE-1:0][2:0]            from_mst_HBURST;
    logic   [MASTER-1:0][SLAVE-1:0][2:0]            from_mst_HSIZE;
    logic   [MASTER-1:0][SLAVE-1:0]                 from_mst_HWRITE;
    logic   [MASTER-1:0][SLAVE-1:0][HDATA_WIDTH-1:0]from_mst_HADDR;
    logic   [MASTER-1:0][SLAVE-1:0][HDATA_WIDTH-1:0]from_mst_HWDATA;
    logic   [MASTER-1:0][SLAVE-1:0]                 from_mst_HMASTLOCK;
    logic   [MASTER-1:0][SLAVE-1:0][6:0]            from_mst_HPROT;
    logic   [MASTER-1:0][SLAVE-1:0]                 from_mst_HNONSEC;
    logic   [MASTER-1:0][SLAVE-1:0]                 from_mst_HEXCL;
    logic   [MASTER-1:0][SLAVE-1:0][3:0]            from_mst_HMASTER;
    logic   [MASTER-1:0][SLAVE-1:0]                 from_mst_HREADYOUT;
    
    logic   [SLAVE-1:0][MASTER-1:0][1:0]            to_slv_HTRANS;
    logic   [SLAVE-1:0][MASTER-1:0][2:0]            to_slv_HBURST;
    logic   [SLAVE-1:0][MASTER-1:0][2:0]            to_slv_HSIZE;
    logic   [SLAVE-1:0][MASTER-1:0]                 to_slv_HWRITE;
    logic   [SLAVE-1:0][MASTER-1:0][HDATA_WIDTH-1:0]to_slv_HADDR;
    logic   [SLAVE-1:0][MASTER-1:0][HDATA_WIDTH-1:0]to_slv_HWDATA;
    logic   [SLAVE-1:0][MASTER-1:0]                 to_slv_HMASTLOCK;
    logic   [SLAVE-1:0][MASTER-1:0][6:0]            to_slv_HPROT;
    logic   [SLAVE-1:0][MASTER-1:0]                 to_slv_HNONSEC;
    logic   [SLAVE-1:0][MASTER-1:0]                 to_slv_HEXCL;
    logic   [SLAVE-1:0][MASTER-1:0][3:0]            to_slv_HMASTER;
    logic   [SLAVE-1:0][MASTER-1:0]                 to_slv_HREADY;

    //from slaveport to masterport
    logic   [SLAVE-1:0][MASTER-1:0][HDATA_WIDTH-1:0]from_slv_HRDATA;
    logic   [SLAVE-1:0][MASTER-1:0]                 from_slv_HREADYOUT;
    logic   [SLAVE-1:0][MASTER-1:0]                 from_slv_HRESP;
    logic   [SLAVE-1:0][MASTER-1:0]                 from_slv_HEXOKAY;

    logic   [MASTER-1:0][SLAVE-1:0][HDATA_WIDTH-1:0]to_mst_HRDATA;
    logic   [MASTER-1:0][SLAVE-1:0]                 to_mst_HREADY;
    logic   [MASTER-1:0][SLAVE-1:0]                 to_mst_HRESP;
    logic   [MASTER-1:0][SLAVE-1:0]                 to_mst_HEXOKAY;

    //internal
    logic   [SLAVE-1:0][MASTER-1:0]                 from_slv_mst_grant;
    logic   [SLAVE-1:0][MASTER-1:0][HADDR_WIDTH-1:0]from_slv_slv_HADDR_base;
    logic   [SLAVE-1:0][MASTER-1:0][HADDR_WIDTH-1:0]from_slv_slv_HADDR_mask;

    logic   [MASTER-1:0][SLAVE-1:0][HADDR_WIDTH-1:0]to_mst_slv_HADDR_base;
    logic   [MASTER-1:0][SLAVE-1:0][HADDR_WIDTH-1:0]to_mst_slv_HADDR_mask;
    logic   [MASTER-1:0][SLAVE-1:0]                 to_mst_mst_grant;

    logic   [MASTER-1:0][SLAVE-1:0]                 from_mst_mst_HSEL;
    logic   [MASTER-1:0][SLAVE-1:0]                 from_mst_mst_switch;

    logic   [SLAVE-1:0][MASTER-1:0]                 to_slv_mst_switch;
    logic   [SLAVE-1:0][MASTER-1:0]                 to_slv_mst_HSEL;
    
    ////////////////////////////////////////////////////////////////////////////
    //design description
    ////////////////////////////////////////////////////////////////////////////
    //#--> from masterprot to slaveport
    generate
        for(slv_sel=0; slv_sel<SLAVE; slv_sel++) begin
            for(mst_sel=0; mst_sel<MASTER; mst_sel++) begin
                assign to_slv_HTRANS[slv_sel][mst_sel] = from_mst_HTRANS[mst_sel][slv_sel];
                assign to_slv_HBURST[slv_sel][mst_sel] = from_mst_HBURST[mst_sel][slv_sel];
                assign to_slv_HSIZE[slv_sel][mst_sel] = from_mst_HSIZE[mst_sel][slv_sel];
                assign to_slv_HWRITE[slv_sel][mst_sel] = from_mst_HWRITE[mst_sel][slv_sel];
                assign to_slv_HADDR[slv_sel][mst_sel] = from_mst_HADDR[mst_sel][slv_sel];
                assign to_slv_HWDATA[slv_sel][mst_sel] = from_mst_HWDATA[mst_sel][slv_sel];
                assign to_slv_HMASTLOCK[slv_sel][mst_sel] = from_mst_HMASTLOCK[mst_sel][slv_sel];
                assign to_slv_HPROT[slv_sel][mst_sel] = from_mst_HPROT[mst_sel][slv_sel];
                assign to_slv_HNONSEC[slv_sel][mst_sel] = from_mst_HNONSEC[mst_sel][slv_sel];
                assign to_slv_HEXCL[slv_sel][mst_sel] = from_mst_HEXCL[mst_sel][slv_sel];
                assign to_slv_HMASTER[slv_sel][mst_sel] = from_mst_HMASTER[mst_sel][slv_sel];
                assign to_slv_HREADY[slv_sel][mst_sel] = from_mst_HREADYOUT[mst_sel][slv_sel];

                //#--> internal
                assign to_slv_mst_switch[slv_sel][mst_sel] = from_mst_mst_switch[mst_sel][slv_sel];
                assign to_slv_mst_HSEL[slv_sel][mst_sel] = from_mst_mst_HSEL[mst_sel][slv_sel];
            end
        end
    endgenerate

    //#--> from slaveport to masterport
    generate
        for(mst_sel=0; mst_sel<MASTER; mst_sel++) begin
            for(slv_sel=0; slv_sel<SLAVE; slv_sel++) begin
                assign to_mst_HRDATA[mst_sel][slv_sel] = from_slv_HRDATA[slv_sel][mst_sel];
                assign to_mst_HREADY[mst_sel][slv_sel] = from_slv_HREADYOUT[slv_sel][mst_sel];
                assign to_mst_HRESP[mst_sel][slv_sel] = from_slv_HRESP[slv_sel][mst_sel];
                assign to_mst_HEXOKAY[mst_sel][slv_sel] = from_slv_HEXOKAY[slv_sel][mst_sel];

                //#--> internal
                assign to_mst_slv_HADDR_base[mst_sel][slv_sel] = from_slv_slv_HADDR_base[slv_sel][mst_sel];
                assign to_mst_slv_HADDR_mask[mst_sel][slv_sel] = from_slv_slv_HADDR_mask[slv_sel][mst_sel];
                assign to_mst_mst_grant[mst_sel][slv_sel] = from_slv_mst_grant[slv_sel][mst_sel];
            end
        end
    endgenerate
    
    //#--> masterport
    generate
        for(mst_sel=0; mst_sel<MASTER; mst_sel++) begin : masterport__GEN
            ahb_interconnect_masterport #(
                .SLAVE(SLAVE),
                .HADDR_WIDTH(HADDR_WIDTH),
                .HDATA_WIDTH(HDATA_WIDTH)
            ) masterport (
                //#--> Global signal
                .HCLK(HCLK),
                .HRESETn(HRESETn),
                
                //#--> connect with slaveport
                .slv_HTRANS_o(from_mst_HTRANS[mst_sel]),
                .slv_HBURST_o(from_mst_HBURST[mst_sel]),
                .slv_HSIZE_o(from_mst_HSIZE[mst_sel]),
                .slv_HWRITE_o(from_mst_HWRITE[mst_sel]),
                .slv_HADDR_o(from_mst_HADDR[mst_sel]),
                .slv_HWDATA_o(from_mst_HWDATA[mst_sel]),
                .slv_HMASTLOCK_o(from_mst_HMASTLOCK[mst_sel]),
                .slv_HPROT_o(from_mst_HPROT[mst_sel]),
                .slv_HNONSEC_o(from_mst_HNONSEC[mst_sel]),
                .slv_HEXCL_o(from_mst_HEXCL[mst_sel]),
                .slv_HMASTER_o(from_mst_HMASTER[mst_sel]),
                .slv_HREADYOUT_o(from_mst_HREADYOUT[mst_sel]),
                .slv_HRDATA_i(to_mst_HRDATA[mst_sel]),
                .slv_HREADY_i(to_mst_HREADY[mst_sel]),
                .slv_HRESP_i(to_mst_HRESP[mst_sel]),
                .slv_HEXOKAY_i(to_mst_HEXOKAY[mst_sel]),
                	
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
                .mst_HSEL_o(from_mst_mst_HSEL[mst_sel]),
                .mst_switch_o(from_mst_mst_switch[mst_sel]),
                .slv_HADDR_base_i(to_mst_slv_HADDR_base[mst_sel]),
                .slv_HADDR_mask_i(to_mst_slv_HADDR_mask[mst_sel]),
                .mst_grant_i(to_mst_mst_grant[mst_sel])
            );
        end
    endgenerate

    //#--> slaveport
    generate
        for(slv_sel=0; slv_sel<SLAVE; slv_sel++) begin : slaveport__GEN
            ahb_interconnect_slaveport #(
                .MASTER(MASTER),
                .HADDR_WIDTH(HADDR_WIDTH),
                .HDATA_WIDTH(HDATA_WIDTH)
            ) slaveport (
                //#--> Global signal
                .HCLK(HCLK),
                .HRESETn(HRESETn),
                
                //#--> connect with masterport
                .mst_HRDATA_o(from_slv_HRDATA[slv_sel]),
                .mst_HREADYOUT_o(from_slv_HREADYOUT[slv_sel]),
                .mst_HRESP_o(from_slv_HRESP[slv_sel]),
                .mst_HEXOKAY_o(from_slv_HEXOKAY[slv_sel]),
                .mst_HTRANS_i(to_slv_HTRANS[slv_sel]),
                .mst_HBURST_i(to_slv_HBURST[slv_sel]),
                .mst_HSIZE_i(to_slv_HSIZE[slv_sel]),
                .mst_HWRITE_i(to_slv_HWRITE[slv_sel]),
                .mst_HADDR_i(to_slv_HADDR[slv_sel]),
                .mst_HWDATA_i(to_slv_HWDATA[slv_sel]),
                .mst_HMASTLOCK_i(to_slv_HMASTLOCK[slv_sel]),
                .mst_HPROT_i(to_slv_HPROT[slv_sel]),
                .mst_HNONSEC_i(to_slv_HNONSEC[slv_sel]),
                .mst_HEXCL_i(to_slv_HEXCL[slv_sel]),
                .mst_HMASTER_i(to_slv_HMASTER[slv_sel]),
                .mst_HREADY_i(to_slv_HREADY[slv_sel]),
                	
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
                .mst_grant_o(from_slv_mst_grant[slv_sel]),
                .slv_HADDR_base_o(from_slv_slv_HADDR_base[slv_sel]),
                .slv_HADDR_mask_o(from_slv_slv_HADDR_mask[slv_sel]),
                .mst_switch_i(to_slv_mst_switch[slv_sel]),
                .mst_HSEL_i(to_slv_mst_HSEL[slv_sel])
            );
        end
    endgenerate
endmodule