//
////////////////////////////////////////////////////////////////////////////////
// Filename    : tb_ahblite_interconnect_1m1s.sv
// Description : 
//
// Author      : Phu Vuong
// History     : Mar 29, 2024 : Initial 	
//
////////////////////////////////////////////////////////////////////////////////
`timescale 1ns/10ps
module tb_ahblite_interconnect_1m1s();
	////////////////////////////////////////////////////////////////////////////
    //param declaration
    ////////////////////////////////////////////////////////////////////////////
    parameter       CYCLE                           = 10; //ns -> 100MHz
    
    //#--> interconnect config
    parameter       MASTER                          = 1;
    parameter       SLAVE                           = 1;
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
    ahblite_interconnect #(
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
    //testbench
    ////////////////////////////////////////////////////////////////////////////
    initial begin
        //#--> init clock and reset
        HCLK = 1'h0;
        HRESETn = 1'h1;

        //#--> init
        init_mst();
        init_slv();

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
                slv_HADDR_base[s] = 'h0;
                slv_HADDR_mask[s] = 'h0;
            end
        end
    endtask
	
	////////////////////////////////////////////////////////////////////////////
    //dump waveform
    ////////////////////////////////////////////////////////////////////////////
    initial begin
        $dumpfile("wf_ahblite_interconnect_1m1s.vcd");
        $dumpvars(tb_ahblite_interconnect_1m1s);
    end
endmodule
