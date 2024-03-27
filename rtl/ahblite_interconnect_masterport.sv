////////////////////////////////////////////////////////////////////////////////
// Filename    : ahblite_interconnect_masterport.sv
// Description : 
//
// Author      : Phu Vuong
// History     : Mar 26, 2024 : Initial     
//
////////////////////////////////////////////////////////////////////////////////
module ahblite_interconnect_masterport #(
    parameter       SLAVE                           = 1,
    parameter       HADDR_WIDTH                     = 32,
    parameter       HDATA_WIDTH                     = 32
)(
    //-----------------------
    //Global signal
    input                                           HCLK,
    input                                           HRESETn,

    //-----------------------
    //connect with slaveport
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
    input           [HDATA_WIDTH-1:0]               slv_HRDATA_i,
    input                                           slv_HREADYOUT_i,
    input                                           slv_HRESP_i,
    input                                           slv_HEXOKAY_i,
    input           [SLAVE-1:0][HADDR_WIDTH-1:0]    slv_HADDR_base_i,
    input           [SLAVE-1:0][HADDR_WIDTH-1:0]    slv_HADDR_mask_i,
	
    //-----------------------
    //connect with ahb master
    output logic    [HDATA_WIDTH-1:0]               mst_HRDATA_o,
    input           [1:0]                           mst_HTRANS_i,
    input           [2:0]                           mst_HBURST_i,
    input           [2:0]                           mst_HSIZE_i,
    input                                           mst_HWRITE_i,
    input           [HADDR_WIDTH-1:0]               mst_HADDR_i,
    input           [HDATA_WIDTH-1:0]               mst_HWDATA_i,
    input                                           mst_HMASTLOCK_i,
    input           [6:0]                           mst_HPROT_i,
    input                                           mst_HNONSEC_i,
    input                                           mst_HEXCL_i,
    input           [3:0]                           mst_HMASTER_i,
    input                                           mst_HREADY_i,

    //-----------------------
    //internal connect
    output logic                                    slv_HSEL_o,
);
    ////////////////////////////////////////////////////////////////////////////
    //parameter declaration
    ////////////////////////////////////////////////////////////////////////////
    localparam      NO_ACCESS                       = 2'b00;
    localparam      ACCESS_CHECK                    = 2'b01;
    localparam      ACCESS_PENDING                  = 2'b10;
    localparam      ACCESS_GRANTED                  = 2'b11;
	
    
    ////////////////////////////////////////////////////////////////////////////
    //logic - wire - reg declaration
    ////////////////////////////////////////////////////////////////////////////
    //-----------------------
    //genvar
    genvar                                          slv_sel;

    //-----------------------
    //FSM
    logic   [1:0]                                   cr_state;
    logic   [1:0]                                   nx_state;

    //-----------------------
    //latch master's command
    logic   [1:0]                                   mst_HTRANS_lat;
    logic   [2:0]                                   mst_HBURST_lat;
    logic   [2:0]                                   mst_HSIZE_lat;
    logic                                           mst_HWRITE_lat;
    logic   [HADDR_WIDTH-1:0]                       mst_HADDR_lat;
    logic   [HDATA_WIDTH-1:0]                       mst_HWDATA_lat;
    logic                                           mst_HMASTLOCK_lat;
    logic   [6:0]                                   mst_HPROT_lat;
    logic                                           mst_HNONSEC_lat;
    logic                                           mst_HEXCL_lat;
    logic   [3:0]                                   mst_HMASTER_lat;
    logic                                           mst_HREADY_lat;

    logic   [1:0]                                   nx_HTRANS;

    //-----------------------
    //address decode -> generate HSEL
    logic   [SLAVE-1:0][HADDR_WIDTH-1:0]            mst_addr_valid;
    logic   [SLAVE-1:0][HADDR_WIDTH-1:0]            slv_addr_valid;
    logic                                           htrans_idle_det;

    //-----------------------
    //burst decoder
    logic                                               burst_single;
    logic                                               burst_incr_undefined_length;
    logic                                               burst_incr;
    logic                                               burst_wrap;

    //-----------------------
    //burst counter
    logic       [3:0]                                   burst_cnt;
    logic       [3:0]                                   nx_burst_cnt;
    logic       [3:0]                                   burst_cnt_upd;
    logic       [3:0]                                   init_burst_cnt;

    ////////////////////////////////////////////////////////////////////////////
    //design description
    ////////////////////////////////////////////////////////////////////////////
    //--------------------------------------------------------------------------
    //latch master's command
    assign nx_HTRANS =  mst_HREADY_i ? mst_HTRANS_i : mst_HTRANS_lat;
    always_ff @(posedge HCLK or negedge HRESETn) begin
        if(~HRESETn) begin
            mst_HTRANS_lat <= 2'h0;
        end else begin
            mst_HTRANS_lat <= mst_HTRANS_i;
        end
    end 

    always_ff @(posedge HCLK or negedge HRESETn) begin
        if(~HRESETn) begin
            mst_HBURST_lat <= 3'h0;
        end else begin
            mst_HBURST_lat <= mst_HBURST_i;
        end
    end 

    always_ff @(posedge HCLK or negedge HRESETn) begin
        if(~HRESETn) begin
            mst_HSIZE_lat <= 3'h0;
        end else begin
            mst_HSIZE_lat <= mst_HSIZE_i;
        end
    end 

    always_ff @(posedge HCLK or negedge HRESETn) begin
        if(~HRESETn) begin
            mst_HWRITE_lat <= 1'h0;
        end else begin
            mst_HWRITE_lat <= mst_HWRITE_i;
        end
    end 
    
    always_ff @(posedge HCLK or negedge HRESETn) begin
        if(~HRESETn) begin
            mst_HADDR_lat <= {(HADDR_WIDTH){1'b0}};
        end else begin
            mst_HADDR_lat <= mst_HADDR_i;
        end
    end 

    always_ff @(posedge HCLK or negedge HRESETn) begin
        if(~HRESETn) begin
            mst_HWDATA_lat <= {(HDATA_WIDTH){1'b0}};
        end else begin
            mst_HWDATA_lat <= mst_HWDATA_i;
        end
    end 

    always_ff @(posedge HCLK or negedge HRESETn) begin
        if(~HRESETn) begin
            mst_HMASTLOCK_lat <= 1'h0;
        end else begin
            mst_HMASTLOCK_lat <= mst_HMASTLOCK_i;
        end
    end 

    always_ff @(posedge HCLK or negedge HRESETn) begin
        if(~HRESETn) begin
            mst_HPROT_lat <= 7'h0;
        end else begin
            mst_HPROT_lat <= mst_HPROT_i;
        end
    end 

    always_ff @(posedge HCLK or negedge HRESETn) begin
        if(~HRESETn) begin
            mst_HNONSEC_lat <= 1'h0;
        end else begin
            mst_HNONSEC_lat <= mst_HNONSEC_i;
        end
    end 

    always_ff @(posedge HCLK or negedge HRESETn) begin
        if(~HRESETn) begin
            mst_HEXCL_lat <= 1'h0;
        end else begin
            mst_HEXCL_lat <= mst_HEXCL_i;
        end
    end 

    always_ff @(posedge HCLK or negedge HRESETn) begin
        if(~HRESETn) begin
            mst_HMASTER_lat <= 4'h0;
        end else begin
            mst_HMASTER_lat <= mst_HMASTER_i;
        end
    end 

    //--------------------------------------------------------------------------
    //address decode -> generate HSEL
    assign htrans_idle_det = ~mst_HTRANS_i[0] & ~mst_HTRANS_i[1];
    generate
        for(slv_sel=0; slv_sel<SLAVE; slave_sel++) begin : HSEL__GEN
            assign mst_addr_valid[slv_sel] = mst_HADDR_i & slv_HADDR_mask_i[slv_sel];
            assign slv_addr_valid[slv_sel] = slv_HADDR_base_i[slv_sel] & slv_HADDR_mask_i[slv_sel];
            assign slv_HSEL_o[slv_sel] = htrans_idle_det ? &(mst_addr_valid[slv_sel] ~^ slv_addr_valid[slv_sel]) : 1'b0;
        end
    endgenerate

    //--------------------------------------------------------------------------
    //burst decoder
    assign burst_single = (~mst_HBURST_i[2]) & (~mst_HBURST_i[1]) & (~mst_HBURST_i[0]);
    assign burst_incr_undefined_length = (~mst_HBURST_i[2]) & (~mst_HBURST_i[1]) & mst_HBURST_i[0];
    assign burst_incr = (mst_HBURST_i[2] & mst_HBURST_i[0]) | (mst_HBURST_i[1] & mst_HBURST_i[0]);
    assign burst_wrap = (~mst_HBURST_i[0]) & (mst_HBURST_i[1] | mst_HBURST_i[2]);

    //--------------------------------------------------------------------------
    //burst counter
    assign init_burst_cnt[3] = mst_HBURST_i[2] & mst_HBURST_i[1];
    assign init_burst_cnt[2] = mst_HBURST_i[2];
    assign init_burst_cnt[1] = mst_HBURST_i[2] | mst_HBURST_i[1];
    assign init_burst_cnt[0] = mst_HBURST_i[2] | mst_HBURST_i[1] | mst_HBURST_i[0];

    assign burst_cnt_upd = (burst_incr_undefined_length) ? burst_cnt : burst_cnt - 4'b0001;

    assign nx_burst_cnt = (~mst_HREADYOUT_o)        ? burst_cnt :
                          (mst_HTRANS_i == NONSEQ)  ? init_burst_cnt :
                          (mst_HTRANS_i == SEQ)     ? burst_cnt_upd : burst_cnt;
    always_ff @(posedge HCLK or negedge HRESETn) begin
        if(~HRESETn) begin
            burst_cnt <= 4'h0;
        end else begin
            burst_cnt <= nx_burst_cnt;
        end
    end

    //--------------------------------------------------------------------------
    //FSM - identify next state
endmodule
