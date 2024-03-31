////////////////////////////////////////////////////////////////////////////////
// Filename    : ahblite_interconnect_slaveport.sv
// Description : 
//
// Author      : Phu Vuong
// History     : Mar 26, 2024 : Initial     
//
////////////////////////////////////////////////////////////////////////////////
module ahblite_interconnect_slaveport #(
    parameter       MASTER                          = 1,
    parameter       HADDR_WIDTH                     = 32,
    parameter       HDATA_WIDTH                     = 32
)(
    //#--> Global signal
    input                                           HCLK,
    input                                           HRESETn,

    //#--> connect with masterport
    output logic    [MASTER-1:0][HDATA_WIDTH-1:0]   mst_HRDATA_o,
    output logic    [MASTER-1:0]                    mst_HREADYOUT_o,
    output logic    [MASTER-1:0]                    mst_HRESP_o,
    output logic    [MASTER-1:0]                    mst_HEXOKAY_o,
    input           [MASTER-1:0][1:0]               mst_HTRANS_i,
    input           [MASTER-1:0][2:0]               mst_HBURST_i,
    input           [MASTER-1:0][2:0]               mst_HSIZE_i,
    input           [MASTER-1:0]                    mst_HWRITE_i,
    input           [MASTER-1:0][HDATA_WIDTH-1:0]   mst_HADDR_i,
    input           [MASTER-1:0][HDATA_WIDTH-1:0]   mst_HWDATA_i,
    input           [MASTER-1:0]                    mst_HMASTLOCK_i,
    input           [MASTER-1:0][6:0]               mst_HPROT_i,
    input           [MASTER-1:0]                    mst_HNONSEC_i,
    input           [MASTER-1:0]                    mst_HEXCL_i,
    input           [MASTER-1:0][3:0]               mst_HMASTER_i,
    input           [MASTER-1:0]                    mst_HREADY_i,
	
    //#--> connect with ahb slave
    output logic    [1:0]                           slv_HTRANS_o,
    output logic    [2:0]                           slv_HBURST_o,
    output logic    [2:0]                           slv_HSIZE_o,
    output logic                                    slv_HWRITE_o,
    output logic    [HDATA_WIDTH-1:0]               slv_HADDR_o,
    output logic    [HDATA_WIDTH-1:0]               slv_HWDATA_o,
    output logic                                    slv_HMASTLOCK_o,
    output logic    [6:0]                           slv_HPROT_o,
    output logic                                    slv_HNONSEC_o,
    output logic                                    slv_HEXCL_o,
    output logic    [3:0]                           slv_HMASTER_o,
    output logic                                    slv_HREADYOUT_o,
    input           [HDATA_WIDTH-1:0]               slv_HRDATA_i,
    input                                           slv_HREADY_i,
    input                                           slv_HRESP_i,
    input                                           slv_HEXOKAY_i,
    input           [HADDR_WIDTH-1:0]               slv_HADDR_base_i,
    input           [HADDR_WIDTH-1:0]               slv_HADDR_mask_i,

    //#--> internal connect
    output logic    [MASTER-1:0]                    mst_grant_o,
    output logic    [MASTER-1:0][HADDR_WIDTH-1:0]   slv_HADDR_base_o,
    output logic    [MASTER-1:0][HADDR_WIDTH-1:0]   slv_HADDR_mask_o,
    input           [MASTER-1:0]                    mst_switch_i,
    input           [MASTER-1:0]                    mst_HSEL_i
);
    ////////////////////////////////////////////////////////////////////////////
    //parameter declaration
    ////////////////////////////////////////////////////////////////////////////
    localparam      PRIORITY_WIDTH                  = MASTER==1 ? 1 : $clog2(MASTER);
    localparam      PRIORITY_LEVEL                  = MASTER;
	
    
    ////////////////////////////////////////////////////////////////////////////
    //logic - wire - reg declaration
    ////////////////////////////////////////////////////////////////////////////
    //#--> genvar
    genvar                                          mst_sel;
    genvar                                          level_sel;
    genvar                                          temp;

    //#--> arbiter - priority level register
    logic                                           upd_priority;
    logic           [MASTER-1:0][PRIORITY_WIDTH-1:0]priority_lat;
    logic           [MASTER-1:0][PRIORITY_WIDTH-1:0]nx_priority;

    logic           [MASTER-1:0][PRIORITY_WIDTH-1:0]cr_priority;
    logic           [MASTER-1:0]                    flag_larger_equal;

    //#--> arbiter - priority selection
    logic           [MASTER-1:0][PRIORITY_LEVEL-1:0]req_level;

    //#--> arbiter - asserted request check
    logic           [PRIORITY_LEVEL-1:0][MASTER-1:0]or_asserted_req_mapped;
    logic           [PRIORITY_LEVEL-1:0]            or_asserted_req;

    //#--> arbiter - request enable
    logic   [PRIORITY_LEVEL-1:0][PRIORITY_LEVEL-1:0]req_en_gating_in;
    logic           [PRIORITY_LEVEL-1:0]            req_en;
    
    //#--> arbiter - request mask
    logic           [MASTER-1:0][PRIORITY_LEVEL-1:0]req_mask;

    //#--> arbiter - next grant and output
    logic           [MASTER-1:0]                    set_grant;
    logic           [MASTER-1:0]                    nx_grant;
    logic                                           no_grant;

    //#--> control mst_HREADY_o to masterport
    logic           [MASTER-1:0]                    nx_HREADY;

    //#--> HREADY loop
    logic           [MASTER-1:0]                    int_HREADY;
    logic                                           int_HREADY_lat;

    //#--> from master to slave
    logic           [MASTER-1:0][1:0]               mst_HTRANS_mx;
    logic           [MASTER-1:0][2:0]               mst_HBURST_mx;
    logic           [MASTER-1:0][2:0]               mst_HSIZE_mx;
    logic           [MASTER-1:0]                    mst_HWRITE_mx;
    logic           [MASTER-1:0][HDATA_WIDTH-1:0]   mst_HADDR_mx;
    logic           [MASTER-1:0][HDATA_WIDTH-1:0]   mst_HWDATA_mx;
    logic           [MASTER-1:0]                    mst_HMASTLOCK_mx;
    logic           [MASTER-1:0][6:0]               mst_HPROT_mx;
    logic           [MASTER-1:0]                    mst_HNONSEC_mx;
    logic           [MASTER-1:0]                    mst_HEXCL_mx;
    logic           [MASTER-1:0][3:0]               mst_HMASTER_mx;

    ////////////////////////////////////////////////////////////////////////////
    //design description
    ////////////////////////////////////////////////////////////////////////////
    //#--> arbiter - priority level register
    generate
        assign cr_priority[0] = nx_grant[0] ? priority_lat[0] : {(PRIORITY_WIDTH){1'b0}};
        for(mst_sel=1; mst_sel<MASTER; mst_sel++) begin : cr_priority__GEN
            assign cr_priority[mst_sel] = nx_grant[mst_sel] ? priority_lat[mst_sel] : cr_priority[mst_sel-1];
        end
    endgenerate

    assign upd_priority = no_grant & |(mst_HSEL_i);

    generate
        for(mst_sel=0; mst_sel<MASTER; mst_sel++) begin : nx_priority__GEN
            ahblite_interconnect_compare_nbit #(
                .WIDTH(MASTER)
            ) comp_00 (
                .comp_o(flag_larger_equal[mst_sel]),
                .a(priority_lat[0]),
                .b(cr_priority[MASTER-1])
            );
            assign nx_priority[mst_sel] =   nx_grant[mst_sel] ? {(PRIORITY_WIDTH){1'b1}} :
                                            flag_larger_equal[mst_sel] ? priority_lat[0] :
                                            priority_lat[0] - {{(PRIORITY_WIDTH-1){1'b0}}, 1'b1};
            
            always_ff @(posedge HCLK or negedge HRESETn) begin
                if(~HRESETn) begin
                    priority_lat[mst_sel] <= mst_sel;
                end else begin
                    priority_lat[mst_sel] <= nx_priority[mst_sel];
                end
            end
        end
    endgenerate

    //#--> arbiter - priority selection
    generate
        for(mst_sel=0; mst_sel<MASTER; mst_sel++) begin : req_level__GEN
            for(level_sel=0; level_sel<PRIORITY_LEVEL; level_sel++) begin : req_level_bit__GEN
                assign req_level[mst_sel][level_sel] = priority_lat[mst_sel] == mst_sel ? mst_HSEL_i[mst_sel] : 1'b0;
            end
        end
    endgenerate
    
    //#--> arbiter - asserted request check
    generate
        for(level_sel=0; level_sel<PRIORITY_LEVEL; level_sel++) begin : or_asserted_req_mapped__GEN
            for(mst_sel=0; mst_sel<MASTER; mst_sel++) begin : or_priority_asserted_mapped_bit__GEN
                assign or_asserted_req_mapped[level_sel][mst_sel] = req_level[mst_sel][level_sel];
            end
        end
    endgenerate

    generate
        for(level_sel=0; level_sel<PRIORITY_LEVEL; level_sel++) begin : or_asserted_req__GEN
            assign or_asserted_req[level_sel] = |or_asserted_req_mapped[level_sel];
        end
    endgenerate

    //#--> arbiter - request enable
    generate
        assign req_en_gating_in[0] = {(PRIORITY_LEVEL){1'b0}};
        if(PRIORITY_LEVEL == 2) begin
            assign req_en_gating_in[1] = {(PRIORITY_LEVEL){1'b0}};
        end else if(PRIORITY_LEVEL > 2) begin
            for(level_sel=2; level_sel<PRIORITY_LEVEL; level_sel++) begin
                for(temp=0; temp<level_sel; temp++) begin
                    assign req_en_gating_in[level_sel][temp] = or_asserted_req[temp];
                end
                for(temp=level_sel; temp<PRIORITY_LEVEL; temp++) begin
                    assign req_en_gating_in[level_sel][temp] = 1'b0;
                end
            end
        end
    endgenerate
   
    generate
        assign req_en[0] = or_asserted_req[0];
        if(PRIORITY_LEVEL == 2) begin
            assign req_en[1] = ~or_asserted_req[0] & or_asserted_req[1];
        end else if(PRIORITY_LEVEL > 2) begin
            assign req_en[1] = ~or_asserted_req[0] & or_asserted_req[1];
            for(level_sel=2; level_sel<PRIORITY_LEVEL; level_sel++) begin
                assign req_en[level_sel] = or_asserted_req[level_sel] & ~(|req_en_gating_in[level_sel]);
            end
        end
    endgenerate

    //#--> arbiter - request mask
    generate
        for(mst_sel=0; mst_sel<MASTER; mst_sel++) begin : req_mask__GEN
            for(level_sel=0; level_sel<PRIORITY_LEVEL; level_sel++) begin : req_mask_bit__GEN
                assign req_mask[mst_sel][level_sel] = req_en[level_sel] & req_level[mst_sel][level_sel];
            end
        end
    endgenerate

    //#--> arbiter - next grant and output
    generate
        for(mst_sel=0; mst_sel<MASTER; mst_sel++) begin : mst_grant__GEN
            assign set_grant[mst_sel] = |req_mask[mst_sel];
            assign nx_grant[mst_sel] = (no_grant | mst_switch_i[mst_sel]) ? set_grant[mst_sel] : (mst_grant_o[mst_sel] & mst_HSEL_i[mst_sel]);

            always_ff @(posedge HCLK or negedge HRESETn) begin
                if(~HRESETn) begin
                    mst_grant_o[mst_sel] <= 1'b0;
                end else begin
                    mst_grant_o[mst_sel] <= nx_grant[mst_sel];
                end
            end
        end
    endgenerate
    assign no_grant = ~(|mst_grant_o);

    //#--> address of slave to masterport
    generate
        for(mst_sel=0; mst_sel<MASTER; mst_sel++) begin : addr_to_masterport__GEN
            assign slv_HADDR_base_o[mst_sel] = slv_HADDR_base_i;
            assign slv_HADDR_mask_o[mst_sel] = slv_HADDR_mask_i;
        end
    endgenerate

    //#--> control mst_HREADY_o to masterport
    generate
        for(mst_sel=0; mst_sel<MASTER; mst_sel++) begin : mst_HREADYOUT__GEN
            assign nx_HREADY[mst_sel] = ~(|mst_HSEL_i) ? slv_HREADY_i :
                                        mst_HSEL_i[mst_sel] & nx_grant[mst_sel] ? slv_HREADY_i :
                                        1'b0;

            always_ff @(posedge HCLK or negedge HRESETn) begin
                if(~HRESETn) begin
                    mst_HREADYOUT_o[mst_sel] <= slv_HREADY_i;
                end else begin
                    mst_HREADYOUT_o[mst_sel] <= nx_HREADY[mst_sel];
                end
            end
        end
    endgenerate

    //#--> HREADY loop
    generate
        assign int_HREADY[0] = nx_grant[0] ? mst_HREADY_i[0] : int_HREADY_lat;
        for(mst_sel=1; mst_sel<MASTER; mst_sel++) begin : int_HREADY__GEN
            assign int_HREADY[mst_sel] = nx_grant[mst_sel] ? mst_HREADY_i[mst_sel] : int_HREADY[mst_sel-1];
        end
    endgenerate

    assign slv_HREADYOUT_o = int_HREADY[MASTER-1];

    always_ff @(posedge HCLK or negedge HRESETn) begin
        if(~HRESETn) begin
            int_HREADY_lat <= 1'b1;
        end else begin
            int_HREADY_lat <= int_HREADY[MASTER-1];
        end
    end

    //#--> from master to slave
    generate
        assign mst_HTRANS_mx[0] = (nx_grant[0] | mst_grant_o[0]) ? mst_HTRANS_i[0] : 'h0;
        assign mst_HBURST_mx[0] = (nx_grant[0] | mst_grant_o[0]) ? mst_HBURST_i[0] : 'h0;
        assign mst_HSIZE_mx[0] = (nx_grant[0] | mst_grant_o[0]) ? mst_HSIZE_i[0] : 'h0;
        assign mst_HWRITE_mx[0] = (nx_grant[0] | mst_grant_o[0]) ? mst_HWRITE_i[0] : 'h0;
        assign mst_HADDR_mx[0] = (nx_grant[0] | mst_grant_o[0]) ? mst_HADDR_i[0] : 'h0;
        assign mst_HWDATA_mx[0] = (nx_grant[0] | mst_grant_o[0]) ? mst_HWDATA_i[0] : 'h0;
        assign mst_HMASTLOCK_mx[0] = (nx_grant[0] | mst_grant_o[0]) ? mst_HMASTLOCK_i[0] : 'h0;
        assign mst_HPROT_mx[0] = (nx_grant[0] | mst_grant_o[0]) ? mst_HPROT_i[0] : 'h0;
        assign mst_HNONSEC_mx[0] = (nx_grant[0] | mst_grant_o[0]) ? mst_HNONSEC_i[0] : 'h0;
        assign mst_HEXCL_mx[0] = (nx_grant[0] | mst_grant_o[0]) ? mst_HEXCL_i[0] : 'h0;
        assign mst_HMASTER_mx[0] = (nx_grant[0] | mst_grant_o[0]) ? mst_HMASTER_i[0] : 'h0;
        for(mst_sel=1; mst_sel<MASTER; mst_sel++) begin : mst2slv__GEN
            assign mst_HTRANS_mx[mst_sel] = (nx_grant[mst_sel] | mst_grant_o[mst_sel]) ? mst_HTRANS_i[mst_sel] : mst_HTRANS_mx[mst_sel-1];
            assign mst_HBURST_mx[mst_sel] = (nx_grant[mst_sel] | mst_grant_o[mst_sel]) ? mst_HBURST_i[mst_sel] : mst_HBURST_mx[mst_sel-1];
            assign mst_HSIZE_mx[mst_sel] = (nx_grant[mst_sel] | mst_grant_o[mst_sel]) ? mst_HSIZE_i[mst_sel] : mst_HSIZE_mx[mst_sel-1];
            assign mst_HWRITE_mx[mst_sel] = (nx_grant[mst_sel] | mst_grant_o[mst_sel]) ? mst_HWRITE_i[mst_sel] : mst_HWRITE_mx[mst_sel-1];
            assign mst_HADDR_mx[mst_sel] = (nx_grant[mst_sel] | mst_grant_o[mst_sel]) ? mst_HADDR_i[mst_sel] : mst_HADDR_mx[mst_sel-1];
            assign mst_HWDATA_mx[mst_sel] = (nx_grant[mst_sel] | mst_grant_o[mst_sel]) ? mst_HWDATA_i[mst_sel] : mst_HWDATA_mx[mst_sel-1];
            assign mst_HMASTLOCK_mx[mst_sel] = (nx_grant[mst_sel] | mst_grant_o[mst_sel]) ? mst_HMASTLOCK_i[mst_sel] : mst_HMASTLOCK_mx[mst_sel-1];
            assign mst_HPROT_mx[mst_sel] = (nx_grant[mst_sel] | mst_grant_o[mst_sel]) ? mst_HPROT_i[mst_sel] : mst_HPROT_mx[mst_sel-1];
            assign mst_HNONSEC_mx[mst_sel] = (nx_grant[mst_sel] | mst_grant_o[mst_sel]) ? mst_HNONSEC_i[mst_sel] : mst_HNONSEC_mx[mst_sel-1];
            assign mst_HEXCL_mx[mst_sel] = (nx_grant[mst_sel] | mst_grant_o[mst_sel]) ? mst_HEXCL_i[mst_sel] : mst_HEXCL_mx[mst_sel-1];
            assign mst_HMASTER_mx[mst_sel] = (nx_grant[mst_sel] | mst_grant_o[mst_sel]) ? mst_HMASTER_i[mst_sel] : mst_HMASTER_mx[mst_sel-1];
        end
    endgenerate

    assign slv_HTRANS_o = mst_HTRANS_mx[MASTER-1];
    assign slv_HBURST_o = mst_HBURST_mx[MASTER-1];
    assign slv_HSIZE_o = mst_HSIZE_mx[MASTER-1];
    assign slv_HWRITE_o = mst_HWRITE_mx[MASTER-1];
    assign slv_HADDR_o = mst_HADDR_mx[MASTER-1];
    assign slv_HWDATA_o = mst_HWDATA_mx[MASTER-1];
    assign slv_HMASTLOCK_o = mst_HMASTLOCK_mx[MASTER-1];
    assign slv_HPROT_o = mst_HPROT_mx[MASTER-1];
    assign slv_HNONSEC_o = mst_HNONSEC_mx[MASTER-1];
    assign slv_HEXCL_o = mst_HEXCL_mx[MASTER-1];
    assign slv_HMASTER_o = mst_HMASTER_mx[MASTER-1];

    //#--> from slave to master
    generate
        for(mst_sel=0; mst_sel<MASTER; mst_sel++) begin
            assign mst_HRDATA_o[mst_sel] = mst_grant_o[mst_sel] ? slv_HRDATA_i : 'h0;
            assign mst_HRESP_o[mst_sel] = slv_HRESP_i;
            assign mst_HEXOKAY_o[mst_sel] = slv_HEXOKAY_i;
        end
    endgenerate
endmodule
