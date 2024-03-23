////////////////////////////////////////////////////////////////////////////////
// Filename    : ahblite_master.v
// Description : 
//
// Author      : Phu Vuong
// History     : Jul 31, 2022 : Initial     
//
////////////////////////////////////////////////////////////////////////////////
module ahblite_master(
    //-----------------------
    //Global signal
    HCLK,
    HRESETn,
    //-----------------------
    //connect with interconnect
    HADDR_o,
    HBURST_o,
    HMASTLOCK_o,
    HPROT_o,
    HSIZE_o,
    HNONSEC_o,
    HEXCL_o,
    HMASTER_o,
    HTRANS_o,
    HWDATA_o,
    HWRITE_o,
    HRDATA_i,
    HREADYOUT_i,
    HRESP_i,
    HEXOKAY_i,
	
    //-----------------------
    //connect with controller
    HRDATA_o,
    HADDR_i,
    HBURST_i,
    HMASTLOCK_i,
    HPROT_i,
    HSIZE_i,
    HNONSEC_i,
    HEXCL_i,
    HMASTER_i,
    HTRANS_i,
    HWDATA_i,
    HWRITE_i,
    HENABLE_i
);
    ////////////////////////////////////////////////////////////////////////////
    //module param declaration
    ////////////////////////////////////////////////////////////////////////////
    parameter           HADDR_SIZE                      = 32;
    parameter           HDATA_SIZE                      = 32;
	
	
    ////////////////////////////////////////////////////////////////////////////
    //pin - port declaration
    ////////////////////////////////////////////////////////////////////////////
    //-----------------------
    //Global signal
    input HCLK;
    input HRESETn;
    
    //connect with interconnect
    output      [HADDR_SIZE-1:0]                        HADDR_o;
    output      [2:0]                                   HBURST_o;
    output                                              HMASTLOCK_o;
    output      [6:0]                                   HPROT_o;
    output      [2:0]                                   HSIZE_o;
    output                                              HNONSEC_o;
    output                                              HEXCL_o;
    output      [3:0]                                   HMASTER_o;
    output      [1:0]                                   HTRANS_o;
    output      [HDATA_SIZE-1:0]                        HWDATA_o;
    output                                              HWRITE_o;
    input       [HDATA_SIZE-1:0]                        HRDATA_i;
    input                                               HREADYOUT_i;
    input                                               HRESP_i;
    input                                               HEXOKAY_i;

    //-----------------------
    //connect with controller
    output      [HDATA_SIZE-1:0]                        HRDATA_o;
    input       [HADDR_SIZE-1:0]                        HADDR_i;
    input       [2:0]                                   HBURST_i;
    input                                               HMASTLOCK_i;
    input       [6:0]                                   HPROT_i;
    input       [3:0]                                   HSIZE_i;
    input                                               HNONSEC_i;
    input                                               HEXCL_i;
    input                                               HMASTER_i;
    input       [1:0]                                   HTRANS_i;
    input       [HDATA_SIZE-1:0]                        HWDATA_i;
    input                                               HWRITE_i;
    input                                               HENABLE_i;

    
    ////////////////////////////////////////////////////////////////////////////
    //param - localparam - wire - reg declaration
    ////////////////////////////////////////////////////////////////////////////
    //HTRANS config
    parameter           IDLE                            = 2'b00;
    parameter           BUSY                            = 2'b01;
    parameter           NONSEQ                          = 2'b10;
    parameter           SEQ                             = 2'b11;
    
    //FSM-state
    localparam          ST_IDLE                         = 4'h0;
    localparam          ST_OP                           = 4'h1;
    localparam          ST_WR                           = 4'h2;
    localparam          ST_RD                           = 4'h3;
    localparam          ST_WAIT                         = 4'h4;
    localparam          ST_INCR_BUSY                    = 4'h5;
    localparam          ST_LENGTH_BUSY                  = 4'h6;
    localparam          ST_1ST_ERROR                    = 4'h7;
    localparam          ST_LAST_ERROR                   = 4'h8;
    localparam          ST_MST_ERROR                    = 4'h9;
    //FSM-bit
    localparam          BIT_IDLE                        = 10'h1;
    localparam          BIT_OP                          = 10'h1 << 1;
    localparam          BIT_WR                          = 10'h1 << 2;
    localparam          BIT_RD                          = 10'h1 << 3;
    localparam          BIT_WAIT                        = 10'h1 << 4;
    localparam          BIT_INCR_BUSY                   = 10'h1 << 5;
    localparam          BIT_LENGTH_BUSY                 = 10'h1 << 6;
    localparam          BIT_1ST_ERROR                   = 10'h1 << 7;
    localparam          BIT_LAST_ERROR                  = 10'h1 << 8;
    localparam          BIT_MST_ERROR                   = 10'h1 << 9;
    //FSM-signal
    reg         [3:0]                                   cur_state;
    reg         [3:0]                                   nxt_state;
    reg         [9:0]                                   bit_state;

    //burst_decoder
    wire                                                burst_incr;
    wire                                                burst_single;
    wire                                                burst_wrap;

    //burst counter
    reg         [3:0]                                   burst_cnt;
    wire        [3:0]                                   nxt_burst_cnt;
    wire        [3:0]                                   init_burst_cnt;



    ////////////////////////////////////////////////////////////////////////////
    //design description
    ////////////////////////////////////////////////////////////////////////////
    //--------------------------------------------------------------------------
    //FSM - identify next state
    always @(*) begin
        bit_state = BIT_IDLE;

        case(cur_state)
            ST_IDLE: begin
                if(HENABLE_i) begin
                    bit_state = BIT_OP;
                    nxt_state = ST_OP;
                end else begin
                    bit_state = BIT_IDLE;
                    nxt_state = ST_IDLE;
                end
            end

            ST_OP: begin
                if(HENABLE_i) begin
                    if(HTRANS_i == IDLE) begin
                        bit_state = BIT_OP
                        nxt_state = ST_OP;
                    end else if(HTRANS_i == NONSEQ) begin
                        if(HWRITE_i) begin
                            bit_state = BIT_WR;
                            nxt_state = ST_WR;
                        end else begin
                            bit_state = BIT_RD;
                            nxt_state = ST_RD;
                        end
                    end else begin
                        bit_state = BIT_MST_ERROR;
                        nxt_state = ST_MST_ERROR;
                    end
                end else begin
                    bit_state = BIT_IDLE;
                    nxt_state = ST_IDLE;
                end
            end

            ST_WR: begin
                if(HENABLE_i) begin
                    if(HRESP_i) begin
                        bit_state = BIT_1ST_ERROR;
                        nxt_state = ST_1ST_ERROR;
                    end else if(HREADY_i) begin
                        bit_state = BIT_ERROR;
                        nxt_state = ST_WAIT;
                    end else if(burst_single) begin
                        if(HTRANS_i == BUSY || HTRANS_i == SEQ) begin
                            bit_state = BIT_MST_ERROR;
                            nxt_state = ST_MST_ERROR;
                        end else begin
                            bit_state = BIT_OP;
                            nxt_state = ST_OP;
                        end
                    end else if(burst_incr) begin
                        if(HTRANS_i == BUSY) begin
                            bit_state = BIT_INCR_BUSY;
                            nxt_state = ST_INCR_BUSY;
                        end else if(HTRANS_i == IDLE) begin
                            bit_state = BIT_OP;
                            nxt_state = ST_OP;
                        end else begin
                            if(HWRITE_i) begin
                                bit_state = BIT_WR;
                                nxt_state = ST_WR;
                            end else begin
                                bit_state = BIT_RD;
                                nxt_state = ST_RD;
                            end
                        end
                    end else if(burst_cnt == 'h0) begin
                        if(HTRANS_i == BUSY) begin
                            bit_state = BIT_ERROR;
                            nxt_state = ST_MST_ERROR;
                        end else if(HTRANS_i == IDLE) begin
                            bit_state = BIT_OP;
                            nxt_state = ST_OP;
                        end else if(HTRANS_i == NONSEQ) begin
                            if(HWRITE_i) begin
                                bit_state = BIT_WR;
                                nxt_state = ST_WR;
                            end else begin
                                bit_state = BIT_RD;
                                nxt_state = ST_RD;
                            end
                        end else begin
                            bit_state = BIT_MST_ERROR;
                            nxt_state = ST_MST_ERROR;
                        end
                    end else if(HTRANS_i == BUSY) begin
                        bit_state = BIT_LENGTH_BUSY;
                        nxt_state = ST_LENGTH_BUSY;
                    end else begin
                        if(HWRITE_i) begin
                            bit_state = BIT_WR;
                            nxt_state = ST_WR;
                        end else begin
                            bit_state = BIT_RD;
                            nxt_state = ST_RD;
                        end
                    end
                end else begin
                    bit_state = BIT_IDLE;
                    nxt_state = ST_IDLE;
                end
            end

            ST_RD: begin
                if(HENABLE_i) begin
                    if(HRESP_i) begin
                        bit_state = BIT_1ST_ERROR;
                        nxt_state = ST_1ST_ERROR;
                    end else if(HREADY_i) begin
                        bit_state = BIT_WAIT;
                        nxt_state = ST_WAIT;
                    end else if(burst_single) begin
                        if(HTRANS_i == BUSY || HTRANS_i == SEQ) begin
                            bit_state = BIT_MST_ERROR;
                            nxt_state = ST_MST_ERROR;
                        end else begin
                            bit_state = BIT_OP;
                            nxt_state = ST_OP;
                        end
                    end else if(burst_incr) begin
                        if(HTRANS_i == BUSY) begin
                            bit_state = BIT_INCR_BUSY;
                            nxt_state = ST_INCR_BUSY;
                        end else if(HTRANS_i == IDLE) begin
                            bit_state = BIT_OP;
                            nxt_state = ST_OP;
                        end else begin
                            if(HWRITE_i) begin
                                bit_state = BIT_WR;
                                nxt_state = ST_WR;
                            end else begin
                                bit_state = BIT_RD;
                                nxt_state = ST_RD;
                            end
                        end
                    end else if(burst_cnt == 'h0) begin
                        if(HTRANS_i == BUSY) begin
                            bit_state = BIT_MST_ERROR;
                            nxt_state = ST_MST_ERROR;
                        end else if(HTRANS_i == IDLE) begin
                            bit_state = BIT_OP;
                            nxt_state = ST_OP;
                        end else if(HTRANS_i == NONSEQ) begin
                            if(HWRITE_i) begin
                                bit_state = BIT_WR;
                                nxt_state = ST_WR;
                            end else begin
                                bit_state = BIT_RD;
                                nxt_state = ST_RD;
                            end
                        end else begin
                            bit_state = BIT_MST_ERROR;
                            nxt_state = ST_MST_ERROR;
                        end
                    end else if(HTRANS_i == BUSY) begin
                        bit_state = BIT_LENGTH_BUSY;
                        nxt_state = ST_LENGTH_BUSY;
                    end else begin
                        if(HWRITE_i) begin
                            bit_state = BIT_WR;
                            nxt_state = ST_WR;
                        end else begin
                            bit_state = BIT_RD;
                            nxt_state = ST_RD;
                        end
                    end
                end else begin
                    bit_state = BIT_IDLE;
                    nxt_state = ST_IDLE;
                end
            end

            ST_WAIT: begin
                if(HENABLE_i) begin
                    if(HREADY_i) begin
                        bit_state = BIT_WAIT;
                        nxt_state = ST_WAIT;
                    end else if(burst_single) begin
                        if(HTRANS_i == BUSY || HTRANS_i == SEQ) begin
                            bit_state = BIT_MST_ERROR;
                            nxt_state = ST_MST_ERROR;
                        end else begin
                            bit_state = BIT_OP;
                            nxt_state = ST_OP;
                        end
                    end else if(burst_incr) begin
                        if(HTRANS_i == BUSY) begin
                            bit_state = BIT_INCR_BUSY;
                            nxt_state = ST_INCR_BUSY;
                        end else if(HTRANS_i == IDLE) begin
                            bit_state = BIT_OP;
                            nxt_state = ST_OP;
                        end else begin
                            if(HWRITE_i) begin
                                bit_state = BIT_WR;
                                nxt_state = ST_WR;
                            end else begin
                                bit_state = BIT_RD;
                                nxt_state = ST_RD;
                            end
                        end
                    end else if(burst_cnt == 'h0) begin
                        if(HTRANS_i == BUSY) begin
                            bit_state = BIT_MST_ERROR;
                            nxt_state = ST_MST_ERROR;
                        end else if(HTRANS_i == IDLE) begin
                            bit_state = BIT_OP;
                            nxt_state = ST_OP;
                        end else if(HTRANS_i == NONSEQ) begin
                            if(HWRITE_i) begin
                                bit_state = BIT_WR;
                                nxt_state = ST_WR;
                            end else begin
                                bit_state = BIT_RD;
                                nxt_state = ST_RD;
                            end
                        end else begin
                            bit_state = BIT_MST_ERROR;
                            nxt_state = ST_MST_ERROR;
                        end
                    end else if(HTRANS_i == BUSY) begin
                        bit_state = BIT_LENGTH_BUSY;
                        nxt_state = ST_LENGTH_BUSY;
                    end else begin
                        if(HWRITE_i) begin
                            bit_state = BIT_WR;
                            nxt_state = ST_WR;
                        end else begin
                            bit_state = BIT_RD;
                            nxt_state = ST_RD;
                        end
                    end
                end else begin
                    bit_state = BIT_IDLE;
                    nxt_state = ST_IDLE;
                end
            end

            ST_INCR_BUSY: begin
                if(HENABLE_i) begin
                    if(HTRANS_i == BUSY) begin
                        bit_state = BIT_INCR_BUSY;
                        nxt_state = ST_INCR_BUSY;
                    end else if(HTRANS == IDLE) begin
                        bit_state = BIT_OP;
                        nxt_state = ST_OP;
                    end else begin
                        if(HWRITE_i) begin
                            bit_state = BIT_WR;
                            nxt_state = ST_WR;
                        end else begin
                            bit_state = BIT_RD;
                            nxt_state = ST_RD;
                        end
                    end
                end else begin
                    bit_state = BIT_IDLE;
                    nxt_state = ST_IDLE;
                end
            end

            ST_LENGTH_BUSY: begin
                if(HENABLE_i) begin
                    if(HTRANS_i == BUSY) begin
                        bit_state = BIT_LENGTH_BUSY;
                        nxt_state = ST_LENGTH_BUSY;
                    end else begin
                        if(HWRITE_i) begin
                            bit_state = BIT_WR;
                            nxt_state = ST_WR;
                        end else begin
                            bit_state = BIT_RD;
                            nxt_state = ST_RD;
                        end
                    end
                end else begin
                    bit_state = BIT_IDLE;
                    nxt_state = ST_IDLE;
                end
            end

            ST_1ST_ERROR: begin
                if(HENABLE_i) begin
                    bit_state = BIT_LAST_ERROR;
                    nxt_state = ST_LAST_ERROR;
                end else begin
                    bit_state = BIT_IDLE;
                    nxt_state = ST_IDLE;
                end
            end

            ST_LAST_ERROR: begin
                if(HENABLE_i) begin
                    if(HTRANS_i == IDLE) begin
                        bit_state = BIT_OP;
                        nxt_state = ST_OP;
                    end else if(HTRANS_i == NONSEQ) begin
                        if(HWRITE_i) begin
                            bit_state = BIT_WR;
                            nxt_state = ST_WR;
                        end else begin
                            bit_state = BIT_RD;
                            nxt_state = ST_RD;
                        end
                    end else begin
                        bit_state = BIT_MST_ERROR;
                        nxt_state = ST_MST_ERROR;
                    end
                end else begin
                    bit_state = BIT_IDLE;
                    nxt_state = ST_IDLE;
                end
            end

            ST_MST_ERROR: begin
                if(HENABLE_i) begin
                    if(HTRANS_i == IDLE) begin
                        bit_state = BIT_OP;
                        nxt_state = ST_OP;
                    end else if(HTRANS_i == NONSEQ) begin
                        if(HWRITE_i) begin
                            bit_state = BIT_WR;
                            nxt_state = ST_WR;
                        end else begin
                            bit_state = BIT_RD;
                            nxt_state = ST_RD;
                        end
                    end else begin
                        bit_state = BIT_MST_ERROR;
                        nxt_state = ST_MST_ERROR;
                    end
                end else begin
                    bit_state = BIT_IDLE;
                    nxt_state = ST_IDLE;
                end
            end

            default: begin
                bit_state = BIT_IDLE;
                nxt_state = BIT_IDLE;
            end
        endcase
    end

    //FSM - update current state
    always @(posedge HCLK or negedge HRESETn) begin
        if(~HRESETn) begin
            cur_state <= ST_IDLE;
        end else begin
            cur_state <= nxt_state;
        end
    end


    //--------------------------------------------------------------------------
    //burst decoder
    assign burst_single = (~HBURST_i[2]) & (~HBURST_i[1]) & (~HBURST_i[0]);
    assign burst_incr = (~HBURST_i[1]) & HBURST_i[0];
    assign burst_wrap = (~HBURST_i[0]) & (HBURST_i[1] | HBURST_i[2]);


    //--------------------------------------------------------------------------
    //burst counter
    assign init_burst_cnt[3] = HBURST_i[2] & HBURST_i[1];
    assign init_burst_cnt[2] = HBURST_i[2];
    assign init_burst_cnt[1] = HBURST_i[2] | HBURST_i[1];
    assign init_burst_cnt[0] = init_burst_cnt[1];

    assign nxt_burst_cnt = (HTRANS_i == NONSEQ) ? init_burst_cnt : (
                            (HTRANS_i == SEQ) ? (burst_cnt - 4'b0001) : burst_cnt);

    always @(posedge HCLK or negedge HRESETn) begin
        if(~HRESETn) begin
            burst_cnt <= 4'h0;
        end else begin
            burst_cnt <= nxt_burst_cnt;
        end
    end


    //--------------------------------------------------------------------------
    //output - ahb static config buffer
    assign HBURST_o = HBURST_i;
    assign HMASTLOCK_o = HMASTLOCK_i;
    assign HPROT_o = HPROT_i;
    assign HSIZE_o = HSIZE_i;
    assign HNONSEC_o = HNONSEC_i;
    assign HEXCL_o = HEXCL_i;
    assign HMASTER_o = HMASTER_i;
    assign HTRANS_o = HTRANS_i;
    assign HWRITE_o = HWRITE_i;
endmodule
