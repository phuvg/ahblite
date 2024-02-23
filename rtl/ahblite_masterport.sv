//
////////////////////////////////////////////////////////////////////////////////
// Filename    : ahblite_masterport.sv
// Description : 
//
// Author      : Phu Vuong
// History     : Jul 31, 2022 : Initial     
//
////////////////////////////////////////////////////////////////////////////////
module ahblite_masterport #(
    parameter                   HADDR_SIZE              = 32,
    parameter                   HDATA_SIZE              = 32,
    parameter                   MASTER                  = 2,
    parameter                   SLAVE                   = 6
) (
    //-----------------------
    //Global signal
    input                                               HCLK,
    input                                               HRESETn,

    //-----------------------
    //connect with controller - ahb master
    output logic    [HDATA_SIZE-1:0]                    mst_HRDATA_o,
    output logic                                        mst_HREADYOUT_o,
    output logic                                        mst_HRESP_o,
    output logic                                        mst_HEXOKAY_o,
    input           [HADDR_SIZE-1:0]                    mst_HADDR_i,
    input           [2:0]                               mst_HBURST_i,
    input                                               mst_HMASTLOCK_i,
    input           [6:0]                               mst_HPROT_i,
    input           [2:0]                               mst_HSIZE_i,
    input                                               mst_HNONSEC_i,
    input                                               mst_HEXCL_i,
    input                                               mst_HMASTER_i,
    input           [1:0]                               mst_HTRANS_i,
    input           [HDATA_SIZE-1:0]                    mst_HWDATA_i,
    input                                               mst_HWRITE_i,
    
    //connect with slaveport
    output logic                                        slv_HSEL_o[SLAVE-1:0],
    output logic    [HADDR_SIZE-1:0]                    slv_HADDR_o[SLAVE-1:0],
    output logic    [2:0]                               slv_HBURST_o[SLAVE-1:0],
    output logic                                        slv_HMASTLOCK_o[SLAVE-1:0],
    output logic    [6:0]                               slv_HPROT_o[SLAVE-1:0],
    output logic    [2:0]                               slv_HSIZE_o[SLAVE-1:0],
    output logic                                        slv_HNONSEC_o[SLAVE-1:0],
    output logic                                        slv_HEXCL_o[SLAVE-1:0],
    output logic    [3:0]                               slv_HMASTER_o[SLAVE-1:0],
    output logic    [1:0]                               slv_HTRANS_o[SLAVE-1:0],
    output logic    [HDATA_SIZE-1:0]                    slv_HWDATA_o[SLAVE-1:0],
    output logic                                        slv_HWRITE_o[SLAVE-1:0],
    input           [HADDR_SIZE-1:0]                    slv_HADDR_mask_i[SLAVE-1:0],
    input           [HADDR_SIZE-1:0]                    slv_HADDR_base_i[SLAVE-1:0],
    input           [HDATA_SIZE-1:0]                    slv_HRDATA_i[SLAVE-1:0],
    input                                               slv_HREADYOUT_i[SLAVE-1:0],
    input                                               slv_HRESP_i[SLAVE-1:0],
    input                                               slv_HEXOKAY_i[SLAVE-1:0]
);
    ////////////////////////////////////////////////////////////////////////////
    //param - localparam - wire - reg declaration
    ////////////////////////////////////////////////////////////////////////////
    //HTRANS config
    parameter           IDLE                            = 2'b00;
    parameter           BUSY                            = 2'b01;
    parameter           NONSEQ                          = 2'b10;
    parameter           SEQ                             = 2'b11;
    
    //genvar
    genvar                                              slv_sel, bit_sel;

    //addr decoder
    logic       [HADDR_SIZE-1:0]                        mst_addr_valid[SLAVE-1:0];
    logic       [HADDR_SIZE-1:0]                        slv_addr_valid[SLAVE-1:0];
    
    //burst decoder
    logic                                               burst_single;
    logic                                               burst_incr_undefined_length;
    logic                                               burst_incr;
    logic                                               burst_wrap;

    //burst counter
    logic       [3:0]                                   burst_cnt;
    logic       [3:0]                                   nx_burst_cnt;
    logic       [3:0]                                   burst_cnt_upd;
    logic       [3:0]                                   init_burst_cnt;

    //size decoder
    logic                                               size_byte;
    logic                                               size_halfword;
    logic                                               size_word;
    logic                                               size_doubleword;
    logic                                               size_quadrupleword;
    logic                                               size_octupleword;
    logic                                               size_sexdecupleword;
    logic                                               size_duotrigintupleword;

    //next address generate
    logic       [HADDR_SIZE-1:0]                        upd_addr;
    logic       [HADDR_SIZE-1:0]                        nx_upd_addr;
    logic       [HADDR_SIZE-1:0]                        upd_addr_incr;
    logic       [HADDR_SIZE-1:0]                        upd_addr_wrap;
    logic       [HADDR_SIZE-1:0]                        addr_incr_value;
    logic                                               nx_burst_cnt_zerodet;
    logic       [11:0]                                  boundary;
    logic       [HADDR_SIZE-1:0]                        addr_boundary;
    logic       [HADDR_SIZE-1:0]                        boundary_check_lat;
    logic       [HADDR_SIZE-1:0]                        nx_boundary_check;

    //write - read data
    logic       [HDATA_SIZE-1:0]                        wdata;
    logic       [HDATA_SIZE-1:0]                        wdata_lat;
    logic       [HDATA_SIZE-1:0]                        nx_wdata;
    logic                                               hwrite_lat;

    //common output of slave's output
    logic       [HADDR_SIZE-1:0]                        slv_HADDR_comm;
    logic       [HDATA_SIZE-1:0]                        slv_HWDATA_comm;

    //gating logic of master's output
    logic       [SLAVE-1:0]                             mst_HREADYOUT_gating;
    logic       [SLAVE-1:0]                             mst_HRESP_gating;
    logic       [SLAVE-1:0]                             mst_HEXOKAY_gating;
    logic       [HDATA_SIZE*SLAVE-1:0]                  mst_HRDATA_gating;
    logic       [HDATA_SIZE-1:0]                        mst_HRDATA_or;



    ////////////////////////////////////////////////////////////////////////////
    //design description
    ////////////////////////////////////////////////////////////////////////////
    //--------------------------------------------------------------------------
    //address decoder -> generate HSEL
    generate
        for(slv_sel=0; slv_sel<SLAVE; slv_sel++) begin : HSEL__GEN
            assign mst_addr_valid[slv_sel][HADDR_SIZE-1:0] = mst_HADDR_i[HADDR_SIZE-1:0] & slv_HADDR_mask_i[slv_sel][HADDR_SIZE-1:0];
            assign slv_addr_valid[slv_sel][HADDR_SIZE-1:0] = slv_HADDR_base_i[slv_sel][HADDR_SIZE-1:0] & slv_HADDR_mask_i[slv_sel][HADDR_SIZE-1:0];
            assign slv_HSEL_o[slv_sel] = &(mst_addr_valid[slv_sel][HADDR_SIZE-1:0] ~^ slv_addr_valid[slv_sel][HADDR_SIZE-1:0]);
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
    //size decoder
    ahblite_size_decoder i_size_decoder(
        .size_byte(size_byte),
        .size_halfword(size_halfword),
        .size_word(size_word),
        .size_doubleword(size_doubleword),
        .size_quadrupleword(size_quadrupleword),
        .size_octupleword(size_octupleword),
        .size_sexdecupleword(size_sexdecupleword),
        .size_duotrigintupleword(size_duotrigintupleword),
        .HSIZE(mst_HSIZE_i)
    );


    //--------------------------------------------------------------------------
    //next address generate
    assign addr_incr_value = size_byte                  ? 'd1     :
                             size_halfword              ? 'd2     :
                             size_word                  ? 'd4     :
                             size_doubleword            ? 'd8     :
                             size_quadrupleword         ? 'd16    :
                             size_octupleword           ? 'd32    :
                             size_sexdecupleword        ? 'd64    :
                             size_duotrigintupleword    ? 'd128   : 'd0;

    assign boundary[11] =   mst_HSIZE_i[2] &  mst_HSIZE_i[1] &  mst_HSIZE_i[0] &  mst_HBURST_i[2] &  mst_HBURST_i[1];
    assign boundary[10] = ( mst_HSIZE_i[2] &  mst_HSIZE_i[1] &  mst_HSIZE_i[0] &  mst_HBURST_i[2] & ~mst_HBURST_i[1])
                        | ( mst_HSIZE_i[2] &  mst_HSIZE_i[1] &  mst_HSIZE_i[0] &  mst_HBURST_i[2] &  mst_HBURST_i[1]);
    assign boundary[9]  = ( mst_HSIZE_i[2] &  mst_HSIZE_i[1] &  mst_HSIZE_i[0] & ~mst_HBURST_i[2] &  mst_HBURST_i[1])
                        | ( mst_HSIZE_i[2] &  mst_HSIZE_i[1] & ~mst_HSIZE_i[0] &  mst_HBURST_i[2] & ~mst_HBURST_i[1])
                        | ( mst_HSIZE_i[2] & ~mst_HSIZE_i[1] &  mst_HSIZE_i[0] &  mst_HBURST_i[2] &  mst_HBURST_i[1]);
    assign boundary[8]  = ( mst_HSIZE_i[2] &  mst_HSIZE_i[1] & ~mst_HSIZE_i[0] & ~mst_HBURST_i[2] &  mst_HBURST_i[1])
                        | ( mst_HSIZE_i[2] & ~mst_HSIZE_i[1] &  mst_HSIZE_i[0] &  mst_HBURST_i[2] & ~mst_HBURST_i[1])
                        | ( mst_HSIZE_i[2] & ~mst_HSIZE_i[1] & ~mst_HSIZE_i[0] &  mst_HBURST_i[2] &  mst_HBURST_i[1]);
    assign boundary[7]  = ( mst_HSIZE_i[2] & ~mst_HSIZE_i[1] &  mst_HSIZE_i[0] & ~mst_HBURST_i[2] &  mst_HBURST_i[1])
                        | ( mst_HSIZE_i[2] & ~mst_HSIZE_i[1] & ~mst_HSIZE_i[0] &  mst_HBURST_i[2] & ~mst_HBURST_i[1])
                        | (~mst_HSIZE_i[2] &  mst_HSIZE_i[1] &  mst_HSIZE_i[0] &  mst_HBURST_i[2] &  mst_HBURST_i[1]);
    assign boundary[6]  = ( mst_HSIZE_i[2] & ~mst_HSIZE_i[1] & ~mst_HSIZE_i[0] & ~mst_HBURST_i[2] &  mst_HBURST_i[1])
                        | (~mst_HSIZE_i[2] &  mst_HSIZE_i[1] &  mst_HSIZE_i[0] &  mst_HBURST_i[2] & ~mst_HBURST_i[1])
                        | (~mst_HSIZE_i[2] &  mst_HSIZE_i[1] & ~mst_HSIZE_i[0] &  mst_HBURST_i[2] &  mst_HBURST_i[1]);
    assign boundary[5]  = (~mst_HSIZE_i[2] &  mst_HSIZE_i[1] &  mst_HSIZE_i[0] & ~mst_HBURST_i[2] &  mst_HBURST_i[1])
                        | (~mst_HSIZE_i[2] &  mst_HSIZE_i[1] & ~mst_HSIZE_i[0] &  mst_HBURST_i[2] & ~mst_HBURST_i[1])
                        | (~mst_HSIZE_i[2] & ~mst_HSIZE_i[1] &  mst_HSIZE_i[0] &  mst_HBURST_i[2] &  mst_HBURST_i[1]);
    assign boundary[4]  = (~mst_HSIZE_i[2] &  mst_HSIZE_i[1] & ~mst_HSIZE_i[0] & ~mst_HBURST_i[2] &  mst_HBURST_i[1])
                        | (~mst_HSIZE_i[2] & ~mst_HSIZE_i[1] &  mst_HSIZE_i[0] &  mst_HBURST_i[2] & ~mst_HBURST_i[1])
                        | (~mst_HSIZE_i[2] & ~mst_HSIZE_i[1] & ~mst_HSIZE_i[0] &  mst_HBURST_i[2] &  mst_HBURST_i[1]);
    assign boundary[3]  = (~mst_HSIZE_i[2] & ~mst_HSIZE_i[1] &  mst_HSIZE_i[0] & ~mst_HBURST_i[2] &  mst_HBURST_i[1])
                        | (~mst_HSIZE_i[2] & ~mst_HSIZE_i[1] & ~mst_HSIZE_i[0] &  mst_HBURST_i[2] & ~mst_HBURST_i[1]);
    assign boundary[2]  = (~mst_HSIZE_i[2] & ~mst_HSIZE_i[1] & ~mst_HSIZE_i[0] & ~mst_HBURST_i[2] &  mst_HBURST_i[1]);
    assign boundary[1]  = 1'b0;
    assign boundary[0]  = 1'b0;
    assign addr_boundary = {{(HADDR_SIZE-12){1'b0}}, boundary[11:0]};

    assign nx_boundary_check = (mst_HTRANS_i == NONSEQ) ? (mst_HADDR_i & addr_boundary) : boundary_check_lat;
    always_ff @(posedge HCLK or negedge HRESETn) begin
        if(~HRESETn) begin
            boundary_check_lat <= mst_HADDR_i;
        end else begin
            boundary_check_lat <= nx_boundary_check;
        end
    end

    assign nx_burst_cnt_zerodet = ~(|(nx_burst_cnt));
    assign upd_addr_incr = slv_HADDR_comm + addr_incr_value;
    assign upd_addr_wrap = ((upd_addr_incr & addr_boundary) == boundary_check_lat) ? upd_addr_incr : upd_addr_incr - addr_boundary;

    assign nx_upd_addr = nx_burst_cnt_zerodet   ? mst_HADDR_i   :
                         burst_single           ? mst_HADDR_i   :
                         burst_incr             ? upd_addr_incr :
                         burst_wrap             ? upd_addr_wrap : mst_HADDR_i;
    always_ff @(posedge HCLK or negedge HRESETn) begin
        if(~HRESETn) begin
            upd_addr <= mst_HADDR_i;
        end else begin
            upd_addr <= nx_upd_addr;
        end
    end

    assign slv_HADDR_comm = ~mst_HREADYOUT_o ? upd_addr :
                            ((mst_HTRANS_i == NONSEQ) || (mst_HTRANS_i == IDLE)) ? mst_HADDR_i : upd_addr;
    

    //--------------------------------------------------------------------------
    //write data
    assign wdata = (mst_HWRITE_i) ? mst_HWDATA_i : 32'h0;
    assign nx_wdata = (mst_HTRANS_i == NONSEQ)  ? wdata :
                      (mst_HTRANS_i == SEQ)     ? wdata : wdata_lat;
    always_ff @(posedge HCLK or negedge HRESETn) begin
        if(~HRESETn) begin
            wdata_lat <= 32'h0;
        end else begin
            wdata_lat <= nx_wdata;
        end
    end
    assign slv_HWDATA_comm = mst_HREADYOUT_o ? wdata_lat : 32'h0;


    //--------------------------------------------------------------------------
    //output - read data
    always_ff @(posedge HCLK or negedge HRESETn) begin
        if(~HRESETn) begin
            hwrite_lat <= 1'h0;
        end else begin
            hwrite_lat <= ~mst_HWRITE_i;
        end
    end
    assign mst_HRDATA_o = {(HDATA_SIZE){mst_HREADYOUT_o}} & {(HDATA_SIZE){hwrite_lat}} & mst_HRDATA_or;


    //--------------------------------------------------------------------------
    //output - slave interface
    generate
        for(slv_sel=0; slv_sel<SLAVE; slv_sel++) begin : SLV_INTF__GEN
            assign slv_HADDR_o[slv_sel]         = slv_HSEL_o[slv_sel] ? slv_HADDR_comm  : {(HADDR_SIZE){1'b0}};
            assign slv_HBURST_o[slv_sel]        = slv_HSEL_o[slv_sel] ? mst_HBURST_i    : 3'h0;
            assign slv_HMASTLOCK_o[slv_sel]     = slv_HSEL_o[slv_sel] ? mst_HMASTLOCK_i : 1'h0;
            assign slv_HPROT_o[slv_sel]         = slv_HSEL_o[slv_sel] ? mst_HPROT_i     : 7'h0;
            assign slv_HSIZE_o[slv_sel]         = slv_HSEL_o[slv_sel] ? mst_HSIZE_i     : 2'h0;
            assign slv_HNONSEC_o[slv_sel]       = slv_HSEL_o[slv_sel] ? mst_HNONSEC_i   : 1'h0;
            assign slv_HEXCL_o[slv_sel]         = slv_HSEL_o[slv_sel] ? mst_HEXCL_i     : 1'h0;
            assign slv_HMASTER_o[slv_sel]       = slv_HSEL_o[slv_sel] ? mst_HMASTER_i   : 3'h0;
            assign slv_HTRANS_o[slv_sel]        = slv_HSEL_o[slv_sel] ? mst_HTRANS_i    : 2'h0;
            assign slv_HWDATA_o[slv_sel]        = slv_HSEL_o[slv_sel] ? slv_HWDATA_comm : {(HDATA_SIZE){1'b0}};
            assign slv_HWRITE_o[slv_sel]        = slv_HSEL_o[slv_sel] ? mst_HWRITE_i    : 1'h0;
        end
    endgenerate


    //--------------------------------------------------------------------------
    //output - response, master interface
    generate
        if(SLAVE==1) begin : RESP_1SLV__GEN
            assign mst_HREADYOUT_o = slv_HREADYOUT_i[0];
            assign mst_HRESP_o = slv_HRESP_i[0];
            assign mst_HEXOKAY_o = slv_HEXOKAY_i[0];
        end else begin : RESP_nSLV__GEN
            for(slv_sel=0; slv_sel<SLAVE; slv_sel++) begin : RESP__GEN
                assign mst_HREADYOUT_gating[slv_sel] = slv_HSEL_o[slv_sel] & slv_HREADYOUT_i[slv_sel];
                assign mst_HRESP_gating[slv_sel] = slv_HSEL_o[slv_sel] & slv_HRESP_i[slv_sel];
                assign mst_HEXOKAY_gating[slv_sel] = slv_HSEL_o[slv_sel] & slv_HEXOKAY_i[slv_sel];
            end
            assign mst_HREADYOUT_o = |mst_HREADYOUT_gating;
            assign mst_HRESP_o = |mst_HRESP_gating;
            assign mst_HEXOKAY_o = |mst_HEXOKAY_gating;

            for(bit_sel=0; bit_sel<HDATA_SIZE; bit_sel++) begin : RDATA_GATING_BIT_MAP__GEN
                for(slv_sel=0; slv_sel<SLAVE; slv_sel++) begin : RDATA_GATING_SLV_MAP__GEN
                    assign mst_HRDATA_gating[bit_sel*SLAVE+slv_sel] = slv_HSEL_o[slv_sel] & slv_HRDATA_i[slv_sel];
                end
            end
            for(bit_sel=0; bit_sel<HDATA_SIZE; bit_sel++) begin : RDATA_SUM__GEN
                assign mst_HRDATA_or[bit_sel] = |mst_HRDATA_gating[bit_sel*SLAVE +: SLAVE];
            end
        end
    endgenerate
endmodule
