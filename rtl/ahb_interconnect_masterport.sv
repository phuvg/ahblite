////////////////////////////////////////////////////////////////////////////////
// Filename    : ahb_interconnect_masterport.sv
// Description : 
//
// Author      : Phu Vuong
// History     : Mar 26, 2024 : Initial     
//
////////////////////////////////////////////////////////////////////////////////
module ahb_interconnect_masterport #(
    parameter       SLAVE                           = 1,
    parameter       HADDR_WIDTH                     = 32,
    parameter       HDATA_WIDTH                     = 32
)(
    //#--> Global signal
    input                                           HCLK,
    input                                           HRESETn,

    //#--> connect with slaveport
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
	
    //#--> connect with ahb master
    output logic    [HDATA_WIDTH-1:0]               mst_HRDATA_o,
    output logic                                    mst_HREADYOUT_o,
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

    //#--> internal connect
    output logic    [SLAVE-1:0]                     mst_HSEL_o,
    output logic    [SLAVE-1:0]                     mst_switch_o,
    input           [SLAVE-1:0][HADDR_WIDTH-1:0]    slv_HADDR_base_i,
    input           [SLAVE-1:0][HADDR_WIDTH-1:0]    slv_HADDR_mask_i,
    input           [SLAVE-1:0]                     mst_grant_i
);
    ////////////////////////////////////////////////////////////////////////////
    //parameter declaration
    ////////////////////////////////////////////////////////////////////////////
    //#--> HTRANS config
    parameter       IDLE                            = 2'b00;
    parameter       BUSY                            = 2'b01;
    parameter       NONSEQ                          = 2'b10;
    parameter       SEQ                             = 2'b11;
    
    ////#--> FSM
    //localparam      NO_ACCESS                       = 2'b00;
    //localparam      ACCESS_CHECK                    = 2'b01;
    //localparam      ACCESS_PENDING                  = 2'b10;
    //localparam      ACCESS_GRANTED                  = 2'b11;

    //#--> slave selection
    localparam      SLAVE_WIDTH                     = SLAVE==1 ? 1 : $clog2(SLAVE);

	
    
    ////////////////////////////////////////////////////////////////////////////
    //logic - wire - reg declaration
    ////////////////////////////////////////////////////////////////////////////
    //#--> genvar
    genvar                                          slv_sel; //slave select for loop

    ////#--> FSM
    //logic   [1:0]                                   cr_state;
    //logic   [1:0]                                   nx_state;

    //#--> htrans detect
    logic                                           htrans_idle;
    logic                                           htrans_nonseq;

    //#--> latch master's command
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

    //logic   [1:0]                                   nx_HTRANS;
    //logic   [HADDR_WIDTH-1:0]                       nx_HADDR;

    //#--> address decode: generate HSEL
    logic   [SLAVE-1:0][HADDR_WIDTH-1:0]            mst_addr_valid;
    logic   [SLAVE-1:0][HADDR_WIDTH-1:0]            slv_addr_valid;
    logic   [SLAVE-1:0]                             hsel;
    logic   [SLAVE-1:0]                             mst_HSEL_lat;

    //#--> slave selection
    logic   [SLAVE-1:0][SLAVE_WIDTH-1:0]            slv_decode;
    logic   [SLAVE_WIDTH-1:0]                       slv_decode_lat;
    logic   [SLAVE_WIDTH-1:0]                       cr_slave;
    logic                                           no_connect;

    ////#--> burst decoder
    //logic                                           burst_single;
    //logic                                           burst_incr_undefined_length;
    //logic                                           burst_incr;
    //logic                                           burst_wrap;

    ////#--> burst counter
    //logic   [3:0]                                   burst_cnt;
    //logic   [3:0]                                   nx_burst_cnt;
    //logic   [3:0]                                   burst_cnt_upd;
    //logic   [3:0]                                   init_burst_cnt;

    ////#--> from slave to master
    //logic                                           wr_en;


    ////////////////////////////////////////////////////////////////////////////
    //design description
    ////////////////////////////////////////////////////////////////////////////
    //#--> htrans detect
    assign htrans_idle = mst_HTRANS_i == IDLE;
    assign htrans_nonseq = mst_HTRANS_i == NONSEQ ? 1'b1 : 1'b0;

    //#--> latch master's command
    //assign nx_HTRANS =  htrans_nonseq ? mst_HTRANS_i : mst_HTRANS_lat;
    always_ff @(posedge HCLK or negedge HRESETn) begin
        if(~HRESETn) begin
            mst_HTRANS_lat <= 2'h0;
        end else begin
            mst_HTRANS_lat <= (htrans_nonseq ? mst_HTRANS_i : mst_HTRANS_lat);
        end
    end 

    always_ff @(posedge HCLK or negedge HRESETn) begin
        if(~HRESETn) begin
            mst_HBURST_lat <= 3'h0;
        end else begin
            mst_HBURST_lat <= (htrans_nonseq ? mst_HBURST_i : mst_HBURST_lat);
        end
    end 

    always_ff @(posedge HCLK or negedge HRESETn) begin
        if(~HRESETn) begin
            mst_HSIZE_lat <= 3'h0;
        end else begin
            mst_HSIZE_lat <= (htrans_nonseq ? mst_HSIZE_i : mst_HSIZE_lat);
        end
    end 

    always_ff @(posedge HCLK or negedge HRESETn) begin
        if(~HRESETn) begin
            mst_HWRITE_lat <= 1'h0;
        end else begin
            mst_HWRITE_lat <= (htrans_nonseq ? mst_HWRITE_i : mst_HWRITE_lat);
        end
    end 
    
    //assign nx_HADDR = htrans_nonseq ? mst_HADDR_i : mst_HADDR_lat;
    always_ff @(posedge HCLK or negedge HRESETn) begin
        if(~HRESETn) begin
            mst_HADDR_lat <= {(HADDR_WIDTH){1'b0}};
        end else begin
            mst_HADDR_lat <= (htrans_nonseq ? mst_HADDR_i : mst_HADDR_lat);
        end
    end 

    always_ff @(posedge HCLK or negedge HRESETn) begin
        if(~HRESETn) begin
            mst_HWDATA_lat <= {(HDATA_WIDTH){1'b0}};
        end else begin
            mst_HWDATA_lat <= (htrans_nonseq ? mst_HWDATA_i : mst_HWDATA_lat);
        end
    end 

    always_ff @(posedge HCLK or negedge HRESETn) begin
        if(~HRESETn) begin
            mst_HMASTLOCK_lat <= 1'h0;
        end else begin
            mst_HMASTLOCK_lat <= (htrans_nonseq ? mst_HMASTLOCK_i : mst_HMASTLOCK_lat);
        end
    end 

    always_ff @(posedge HCLK or negedge HRESETn) begin
        if(~HRESETn) begin
            mst_HPROT_lat <= 7'h0;
        end else begin
            mst_HPROT_lat <= (htrans_nonseq ? mst_HPROT_i : mst_HPROT_lat);
        end
    end 

    always_ff @(posedge HCLK or negedge HRESETn) begin
        if(~HRESETn) begin
            mst_HNONSEC_lat <= 1'h0;
        end else begin
            mst_HNONSEC_lat <= (htrans_nonseq ? mst_HNONSEC_i : mst_HNONSEC_lat);
        end
    end 

    always_ff @(posedge HCLK or negedge HRESETn) begin
        if(~HRESETn) begin
            mst_HEXCL_lat <= 1'h0;
        end else begin
            mst_HEXCL_lat <= (htrans_nonseq ? mst_HEXCL_i : mst_HEXCL_lat);
        end
    end 

    always_ff @(posedge HCLK or negedge HRESETn) begin
        if(~HRESETn) begin
            mst_HMASTER_lat <= 4'h0;
        end else begin
            mst_HMASTER_lat <= (htrans_nonseq ? mst_HMASTER_i : mst_HMASTER_lat);
        end
    end 

    //#--> address decode: generate HSEL
    generate
        for(slv_sel=0; slv_sel<SLAVE; slv_sel++) begin : HSEL__GEN
            assign mst_addr_valid[slv_sel] = mst_HADDR_i & slv_HADDR_mask_i[slv_sel];
            assign slv_addr_valid[slv_sel] = slv_HADDR_base_i[slv_sel] & slv_HADDR_mask_i[slv_sel];
            assign hsel[slv_sel] = &(mst_addr_valid[slv_sel] ~^ slv_addr_valid[slv_sel]);
            assign mst_HSEL_o[slv_sel] = mst_grant_i[slv_sel] ? (
                                            slv_HREADY_i[cr_slave] ? hsel[slv_sel] : mst_HSEL_lat[slv_sel]
                                         ) : hsel[slv_sel];
            always_ff @(posedge HCLK or HRESETn) begin
                if(~HRESETn) begin
                    mst_HSEL_lat[slv_sel] <= 1'b1;
                end else begin
                    mst_HSEL_lat[slv_sel] <= mst_HSEL_o[slv_sel];
                end
            end
        end
    endgenerate

    //#--> slave selection
    generate
        assign slv_decode[0] = mst_grant_i[0] ? 'h0 : slv_decode_lat;
        for(slv_sel=1; slv_sel<SLAVE; slv_sel++) begin
            assign slv_decode[slv_sel] = mst_grant_i[slv_sel] ? slv_sel : slv_decode[slv_sel-1];
        end
    endgenerate
    assign cr_slave = slv_decode[SLAVE-1];
    
    always_ff @(posedge HCLK or HRESETn) begin
        if(~HRESETn) begin
            slv_decode_lat <= {(SLAVE_WIDTH){1'b0}};
        end else begin
            slv_decode_lat <= slv_decode[SLAVE-1];
        end
    end

    //assign no_connect = ~(|mst_HSEL_o) ? 1'b1 :
    //                    mst_grant_i[slv_decode] ? 1'b1 : 1'b0;

    ////#--> burst decoder
    //assign burst_single = (~mst_HBURST_i[2]) & (~mst_HBURST_i[1]) & (~mst_HBURST_i[0]);
    //assign burst_incr_undefined_length = (~mst_HBURST_i[2]) & (~mst_HBURST_i[1]) & mst_HBURST_i[0];
    //assign burst_incr = (mst_HBURST_i[2] & mst_HBURST_i[0]) | (mst_HBURST_i[1] & mst_HBURST_i[0]);
    //assign burst_wrap = (~mst_HBURST_i[0]) & (mst_HBURST_i[1] | mst_HBURST_i[2]);

    ////#--> burst counter
    //assign init_burst_cnt[3] = mst_HBURST_i[2] & mst_HBURST_i[1];
    //assign init_burst_cnt[2] = mst_HBURST_i[2];
    //assign init_burst_cnt[1] = mst_HBURST_i[2] | mst_HBURST_i[1];
    //assign init_burst_cnt[0] = mst_HBURST_i[2] | mst_HBURST_i[1] | mst_HBURST_i[0];

    //assign burst_cnt_upd = (burst_incr_undefined_length) ? burst_cnt : burst_cnt - 4'b0001;

    //assign nx_burst_cnt = ~slv_HREADY_i[cr_slave] ? burst_cnt :
    //                      mst_HTRANS_i == NONSEQ  ? init_burst_cnt :
    //                      mst_HTRANS_i == SEQ     ? burst_cnt_upd : burst_cnt;
    //always_ff @(posedge HCLK or negedge HRESETn) begin
    //    if(~HRESETn) begin
    //        burst_cnt <= 4'h0;
    //    end else begin
    //        burst_cnt <= nx_burst_cnt;
    //    end
    //end

    //#--> switch
    generate
        for(slv_sel=0; slv_sel<SLAVE; slv_sel++) begin
            assign mst_switch_o[slv_sel] = slv_HREADY_i[cr_slave] & mst_grant_i[slv_sel] & (htrans_idle | htrans_nonseq);
        end
    endgenerate

    //#--> HREADY loop
    assign mst_HREADYOUT_o = slv_HREADY_i[cr_slave];
    assign slv_HREADYOUT_o = {(SLAVE){mst_HREADY_i}};

    //#--> from master to slave
    generate
        for(slv_sel=0; slv_sel<SLAVE; slv_sel++) begin
            assign slv_HTRANS_o[slv_sel] = slv_HREADY_i[slv_sel] ? mst_HTRANS_i : mst_HTRANS_lat;
            assign slv_HBURST_o[slv_sel] = slv_HREADY_i[slv_sel] ? mst_HBURST_i : mst_HBURST_lat;
            assign slv_HSIZE_o[slv_sel] = slv_HREADY_i[slv_sel] ? mst_HSIZE_i : mst_HSIZE_lat;
            assign slv_HWRITE_o[slv_sel] = slv_HREADY_i[slv_sel] ? mst_HWRITE_i : mst_HWRITE_lat;
            assign slv_HADDR_o[slv_sel] = slv_HREADY_i[slv_sel] ? mst_HADDR_i : mst_HADDR_lat;
            assign slv_HWDATA_o[slv_sel] = slv_HREADY_i[slv_sel] ? mst_HWDATA_i : mst_HWDATA_lat;
            assign slv_HMASTLOCK_o[slv_sel] = slv_HREADY_i[slv_sel] ? mst_HMASTLOCK_i : mst_HMASTLOCK_lat;
            assign slv_HPROT_o[slv_sel] = slv_HREADY_i[slv_sel] ? mst_HPROT_i : mst_HPROT_lat;
            assign slv_HNONSEC_o[slv_sel] = slv_HREADY_i[slv_sel] ? mst_HNONSEC_i : mst_HNONSEC_lat;
            assign slv_HEXCL_o[slv_sel] = slv_HREADY_i[slv_sel] ? mst_HEXCL_i : mst_HEXCL_lat;
            assign slv_HMASTER_o[slv_sel] = slv_HREADY_i[slv_sel] ? mst_HMASTER_i : mst_HMASTER_lat;
        end
    endgenerate

    ////#--> from slave to master
    //always_ff @(posedge HCLK or negedge HRESETn) begin
    //    if(~HRESETn) begin
    //        wr_en <= 1'b0;
    //    end else begin
    //        wr_en <= mst_HWRITE_i;
    //    end
    //end
    //assign mst_HRDATA_o = (~wr_en) & slv_HRDATA_i[cr_slave];
    assign mst_HRDATA_o = slv_HRDATA_i[cr_slave];
endmodule