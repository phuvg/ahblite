//
////////////////////////////////////////////////////////////////////////////////
// Filename    : tb_ahb_interconnect_2m3s.sv
// Description : 
//
// Author      : Phu Vuong
// History     : Mar 29, 2024 : Initial 	
//
////////////////////////////////////////////////////////////////////////////////
`timescale 1ns/10ps
module tb_ahb_interconnect_2m3s();
	////////////////////////////////////////////////////////////////////////////
    //param declaration
    ////////////////////////////////////////////////////////////////////////////
    parameter       CYCLE                           = 10; //ns -> 100MHz
    
    //#--> interconnect config
    parameter       MASTER                          = 2;
    parameter       SLAVE                           = 3;
    parameter       HADDR_WIDTH                     = 32;
    parameter       HDATA_WIDTH                     = 32;

    //#--> HTRANS config
    parameter       IDLE                            = 2'b00;
    parameter       BUSY                            = 2'b01;
    parameter       NONSEQ                          = 2'b10;
    parameter       SEQ                             = 2'b11;

    //BURST config
    parameter       SINGLE                          = 3'b000;
    parameter       INCR                            = 3'b001;
    parameter       WRAP4                           = 3'b010;
    parameter       INCR4                           = 3'b011;

    //SIZE config
    parameter       BYTE                            = 3'b000;
    parameter       HALFWORD                        = 3'b001;
    parameter       WORD                            = 3'b010;

    //WRITE/READ config
    parameter       WRITE                           = 1'h1;
    parameter       READ                            = 1'h0;

	////////////////////////////////////////////////////////////////////////////
    //port declaration
    ////////////////////////////////////////////////////////////////////////////
    //#--> Global signal
    logic                                           HCLK;
    logic                                           HRESETn;

    //#--> connect with ahb master
    logic           [MASTER-1:0][HDATA_WIDTH-1:0]   mst_HRDATA;
    logic           [MASTER-1:0]                    mst_HREADYOUT;
    logic           [MASTER-1:0][1:0]               mst_HTRANS;
    logic           [MASTER-1:0][2:0]               mst_HBURST;
    logic           [MASTER-1:0][2:0]               mst_HSIZE;
    logic           [MASTER-1:0]                    mst_HWRITE;
    logic           [MASTER-1:0][HADDR_WIDTH-1:0]   mst_HADDR;
    logic           [MASTER-1:0][HDATA_WIDTH-1:0]   mst_HWDATA;
    logic           [MASTER-1:0]                    mst_HMASTLOCK;
    logic           [MASTER-1:0][6:0]               mst_HPROT;
    logic           [MASTER-1:0]                    mst_HNONSEC;
    logic           [MASTER-1:0]                    mst_HEXCL;
    logic           [MASTER-1:0][3:0]               mst_HMASTER;
    logic           [MASTER-1:0]                    mst_HREADY;

    //#--> connect with ahb slave
    logic           [SLAVE-1:0][1:0]                slv_HTRANS;
    logic           [SLAVE-1:0][2:0]                slv_HBURST;
    logic           [SLAVE-1:0][2:0]                slv_HSIZE;
    logic           [SLAVE-1:0]                     slv_HWRITE;
    logic           [SLAVE-1:0][HDATA_WIDTH-1:0]    slv_HADDR;
    logic           [SLAVE-1:0][HDATA_WIDTH-1:0]    slv_HWDATA;
    logic           [SLAVE-1:0]                     slv_HMASTLOCK;
    logic           [SLAVE-1:0][6:0]                slv_HPROT;
    logic           [SLAVE-1:0]                     slv_HNONSEC;
    logic           [SLAVE-1:0]                     slv_HEXCL;
    logic           [SLAVE-1:0][3:0]                slv_HMASTER;
    logic           [SLAVE-1:0]                     slv_HREADYOUT;
    logic           [SLAVE-1:0][HDATA_WIDTH-1:0]    slv_HRDATA;
    logic           [SLAVE-1:0]                     slv_HREADY;
    logic           [SLAVE-1:0]                     slv_HRESP;
    logic           [SLAVE-1:0]                     slv_HEXOKAY;
    logic           [SLAVE-1:0][HADDR_WIDTH-1:0]    slv_HADDR_base;
    logic           [SLAVE-1:0][HADDR_WIDTH-1:0]    slv_HADDR_mask;


	////////////////////////////////////////////////////////////////////////////
    //testbench reg - wire declaration
    ////////////////////////////////////////////////////////////////////////////
    genvar                                          mst_sel;
    genvar                                          slv_sel;

	////////////////////////////////////////////////////////////////////////////
    //instance
    ////////////////////////////////////////////////////////////////////////////
    ahb_interconnect #(
        .MASTER(MASTER),
        .SLAVE(SLAVE),
        .HADDR_WIDTH(HADDR_WIDTH),
        .HDATA_WIDTH(HDATA_WIDTH)
    ) inst_interconnect (
        //#--> Global signal
        .HCLK(HCLK),
        .HRESETn(HRESETn),
    
        //#--> connect with ahb master
        .mst_HRDATA_o(mst_HRDATA),
        .mst_HREADYOUT_o(mst_HREADYOUT),
        .mst_HTRANS_i(mst_HTRANS),
        .mst_HBURST_i(mst_HBURST),
        .mst_HSIZE_i(mst_HSIZE),
        .mst_HWRITE_i(mst_HWRITE),
        .mst_HADDR_i(mst_HADDR),
        .mst_HWDATA_i(mst_HWDATA),
        .mst_HMASTLOCK_i(mst_HMASTLOCK),
        .mst_HPROT_i(mst_HPROT),
        .mst_HNONSEC_i(mst_HNONSEC),
        .mst_HEXCL_i(mst_HEXCL),
        .mst_HMASTER_i(mst_HMASTER),
        .mst_HREADY_i(mst_HREADY),
    
        //#--> connect with ahb slave
        .slv_HTRANS_o(slv_HTRANS),
        .slv_HBURST_o(slv_HBURST),
        .slv_HSIZE_o(slv_HSIZE),
        .slv_HWRITE_o(slv_HWRITE),
        .slv_HADDR_o(slv_HADDR),
        .slv_HWDATA_o(slv_HWDATA),
        .slv_HMASTLOCK_o(slv_HMASTLOCK),
        .slv_HPROT_o(slv_HPROT),
        .slv_HNONSEC_o(slv_HNONSEC),
        .slv_HEXCL_o(slv_HEXCL),
        .slv_HMASTER_o(slv_HMASTER),
        .slv_HREADYOUT_o(slv_HREADYOUT),
        .slv_HRDATA_i(slv_HRDATA),
        .slv_HREADY_i(slv_HREADY),
        .slv_HRESP_i(slv_HRESP),
        .slv_HEXOKAY_i(slv_HEXOKAY),
        .slv_HADDR_base_i(slv_HADDR_base),
        .slv_HADDR_mask_i(slv_HADDR_mask)
    );

	////////////////////////////////////////////////////////////////////////////
    //internal connection
    ////////////////////////////////////////////////////////////////////////////
    //#--> slave address
    assign slv_HADDR_base[0] = 'h1000_0000;
    assign slv_HADDR_mask[0] = 'hf000_0000;

    assign slv_HADDR_base[1] = 'h2000_0000;
    assign slv_HADDR_mask[1] = 'hf000_0000;

    assign slv_HADDR_base[2] = 'h3000_0000;
    assign slv_HADDR_mask[2] = 'hf000_0000;

	////////////////////////////////////////////////////////////////////////////
    //testbench
    ////////////////////////////////////////////////////////////////////////////
    initial begin
        //#--> init clock and reset
        HCLK = 1'h1;
        HRESETn = 1'h1;

        //#--> init
        init_mst();
        init_slv();

        //#--> reset
        #(3*CYCLE) HRESETn = 1'h0;
        #(2*CYCLE) HRESETn = 1'h1;

        //#--> transfer
        #(5*CYCLE) @(posedge HCLK);
        mst(0, NONSEQ, INCR4, WORD, WRITE, 'h1000_6000, 'habcd); // req slv0 #1
        mst(1, NONSEQ, INCR4, WORD, READ, 'h2000_8000, 'h0); // req slv1 #1
        slv(0, 'h0, 1'b1, 1'b0); // resp mst0 req
        slv(1, 'h0, 1'b1, 1'b0); // resp mst1 req
        #(1*CYCLE) @(posedge HCLK);
        mst(0, SEQ, INCR4, WORD, WRITE, 'h1000_6004, 'h1111); // continue slv0 #2
        mst(1, SEQ, INCR4, WORD, READ, 'h2000_8004, 'h0); // continue slv1 #2
        slv(0, 'h0, 1'b1, 1'b0); // resp mst0 #1
        slv(1, 'h333, 1'b1, 1'b0); // resp mst1 #1
        #(1*CYCLE) @(posedge HCLK);
        mst(0, SEQ, INCR4, WORD, WRITE, 'h1000_6008, 'h2); // continue slv0 #3
        mst(1, SEQ, INCR4, WORD, READ, 'h2000_8008, 'h0); // continue slv1 #3
        slv(0, 'h0, 1'b1, 1'b0); // resp mst0 #2
        slv(1, 'h555, 1'b1, 1'b0); // resp mst1 #2
        #(1*CYCLE) @(posedge HCLK);
        mst(0, SEQ, INCR4, WORD, WRITE, 'h1000_600c, 'h88); //continue slv0 #4 (last)
        mst(1, SEQ, INCR4, WORD, READ, 'h2000_800c, 'h0); // continue slv1 #4 (last)
        slv(0, 'h0, 1'b1, 1'b0); // resp mst0 #3
        slv(1, 'h777, 1'b1, 1'b0); // resp mst1 #3
        #(1*CYCLE) @(posedge HCLK);
        mst(0, IDLE, INCR4, WORD, WRITE, 'h0, 'h0); // idle
        mst(1, IDLE, INCR4, WORD, READ, 'h0, 'h0); // idle
        slv(0, 'h0, 1'b1, 1'b0); // resp mst0 #4
        slv(1, 'h999, 1'b1, 1'b0); // resp mst1 #4

        #(5*CYCLE) @(posedge HCLK);
        mst(0, NONSEQ, INCR4, WORD, READ, 'h1000_00a0, 'h0); // req slv0 #1
        mst(1, NONSEQ, INCR4, WORD, WRITE, 'h1000_0100, 'hfefe); // req slv0 #1
        slv(0, 'h0, 1'b1, 1'b0); // resp mst1 req
        #(1*CYCLE) @(posedge HCLK);
        mst(0, SEQ, INCR4, WORD, READ, 'h1000_00a4, 'h0); // continue slv0 #2
        mst(1, SEQ, INCR4, WORD, WRITE, 'h1000_0104, 'hacac); // continue slv0 #2
        slv(0, 'h0, 1'b1, 1'b0); // resp mst1 #1
        #(1*CYCLE) @(posedge HCLK);
        mst(0, SEQ, INCR4, WORD, READ, 'h1000_00a4, 'h0); // not change
        mst(1, SEQ, INCR4, WORD, WRITE, 'h1000_0108, 'h7676); // continue slv0 #3
        slv(0, 'h0, 1'b1, 1'b0); // resp mst1 #2
        #(1*CYCLE) @(posedge HCLK);
        mst(0, SEQ, INCR4, WORD, READ, 'h1000_00a4, 'h0); // not change
        mst(1, SEQ, INCR4, WORD, WRITE, 'h1000_010c, 'h9b9b); // continue slv0 #4
        slv(0, 'h0, 1'b1, 1'b0); // resp mst1 #3
        #(1*CYCLE) @(posedge HCLK);
        mst(0, SEQ, INCR4, WORD, READ, 'h1000_00a4, 'h0); // not change
        mst(1, NONSEQ, INCR, WORD, WRITE, 'h1005_0008, 'h1100); // req slv0 #1
        slv(0, 'h0, 1'b1, 1'b0); // resp mst1 #4
        #(1*CYCLE) @(posedge HCLK);
        mst(0, SEQ, INCR4, WORD, READ, 'h1000_00a4, 'h0); // not change
        mst(1, SEQ, INCR, WORD, WRITE, 'h1005_000c, 'h2200); // continue slv0 #2
        slv(0, 'h0, 1'b1, 1'b0); 
        #(1*CYCLE) @(posedge HCLK);
        mst(0, SEQ, INCR4, WORD, READ, 'h1000_00a4, 'h0); // not change
        mst(1, SEQ, INCR, WORD, WRITE, 'h1005_000c, 'h2200); // not change
        slv(0, 'h2134, 1'b1, 1'b0); // resp mst0 #1
        #(1*CYCLE) @(posedge HCLK);
        mst(0, SEQ, INCR4, WORD, READ, 'h1000_00a8, 'h0); // continue slv0 #3
        mst(1, SEQ, INCR, WORD, WRITE, 'h1005_000c, 'h2200); // not change
        slv(0, 'h3aacc, 1'b1, 1'b0); // resp mst0 #2
        #(1*CYCLE) @(posedge HCLK);
        mst(0, SEQ, INCR4, WORD, READ, 'h1000_00ac, 'h0); // continue slv0 #4
        mst(1, SEQ, INCR, WORD, WRITE, 'h1005_000c, 'h2200); // not change
        slv(0, 'h401, 1'b1, 1'b0); // resp mst0 #3
        #(1*CYCLE) @(posedge HCLK);
        mst(0, NONSEQ, SINGLE, WORD, WRITE, 'h3000_0000, 'hafafbfbf); // req slv2 #1
        mst(1, SEQ, INCR, WORD, WRITE, 'h1005_000c, 'h2200); // not change
        slv(0, 'h5552f, 1'b1, 1'b0); // resp mst0 #4
        #(1*CYCLE) @(posedge HCLK);
        mst(0, IDLE, SINGLE, WORD, WRITE, 'h0, 'h0); // idle
        mst(1, SEQ, INCR, WORD, WRITE, 'h1005_000c, 'h2200); // not change
        slv(0, 'h0, 1'b1, 1'b0); // resp mst1 #1
        slv(2, 'h0, 1'b1, 1'b0); // resp mst0 #1
        #(1*CYCLE) @(posedge HCLK);
        mst(1, SEQ, INCR, WORD, WRITE, 'h1005_0010, 'h2200); // continue slv0 #3
        slv(0, 'h0, 1'b1, 1'b0); // resp mst1 #2
        #(1*CYCLE) @(posedge HCLK);
        mst(1, IDLE, INCR, WORD, WRITE, 'h1005_0010, 'h2200); // idle
        slv(0, 'h0, 1'b1, 1'b0); // resp mst1 #3

        //#--> finish
        #(20*CYCLE) $finish;
    end
    
    //#--> clock gen
    always begin
        #(0.5 * CYCLE) HCLK <= ~HCLK;
    end
    
	////////////////////////////////////////////////////////////////////////////
    //task
    ////////////////////////////////////////////////////////////////////////////
    task init_mst;
        begin
            for(int m=0; m<MASTER; m++) begin
                mst_HTRANS[m] = IDLE;
                mst_HBURST[m] = SINGLE;
                mst_HSIZE[m] = BYTE;
                mst_HWRITE[m] = READ;
                mst_HADDR[m] = 'h0;
                mst_HWDATA[m] = 'h0;
                mst_HMASTLOCK[m] = 'h0;
                mst_HPROT[m] = 'h0;
                mst_HNONSEC[m] = 'h0;
                mst_HEXCL[m] = 'h0;
                mst_HMASTER[m] = 'h0;
                mst_HREADY[m] = 'h1;
            end
        end
    endtask

    task init_slv;
        begin
            for(int s=0; s<SLAVE; s++) begin
                slv_HRDATA[s] = 'h0;
                slv_HREADY[s] = 'h1;
                slv_HRESP[s] = 'h0;
                slv_HEXOKAY[s] = 'h0;
            end
        end
    endtask

    task mst;
        input integer m;
        input [1:0]htrans;
        input [2:0]hburst;
        input [2:0]hsize;
        input hwrite;
        input [HADDR_WIDTH-1:0]addr;
        input [HDATA_WIDTH-1:0]wrdata;
        begin
            mst_HTRANS[m] = htrans;
            mst_HBURST[m] = hburst;
            mst_HSIZE[m] = hsize;
            mst_HWRITE[m] = hwrite;
            mst_HADDR[m] = addr;
            mst_HWDATA[m] = wrdata;
        end
    endtask

    task slv_mst;
        input integer m;
        input integer s;
        input [1:0]htrans;
        input [2:0]hburst;
        input [2:0]hsize;
        input hwrite;
        input [HADDR_WIDTH-1:0]addr;
        input [HDATA_WIDTH-1:0]wrdata;
        input [HDATA_WIDTH-1:0]rddata;
        input hready;
        input hresp;
        begin
            mst_HTRANS[m] = htrans;
            mst_HBURST[m] = hburst;
            mst_HSIZE[m] = hsize;
            mst_HWRITE[m] = hwrite;
            mst_HADDR[m] = addr;
            mst_HWDATA[m] = wrdata;
            slv_HRDATA[s] = rddata;
            slv_HREADY[s] = hready;
            slv_HRESP[s] = hresp;
        end
    endtask

    task slv;
        input integer s;
        input [HDATA_WIDTH-1:0]rddata;
        input hready;
        input hresp;
        begin
            slv_HRDATA[s] = rddata;
            slv_HREADY[s] = hready;
            slv_HRESP[s] = hresp;
        end
    endtask
	
	////////////////////////////////////////////////////////////////////////////
    //dump waveform
    ////////////////////////////////////////////////////////////////////////////
    initial begin
        $dumpfile("wf_ahb_interconnect_2m3s.vcd");
        $dumpvars(0, tb_ahb_interconnect_2m3s);
    end
endmodule