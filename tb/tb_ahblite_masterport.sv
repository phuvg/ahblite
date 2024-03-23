//
////////////////////////////////////////////////////////////////////////////////
// Filename    : tb_ahblite_masterport.sv
// Description : 
//
// Author      : Phu Vuong
// History     : Aug 01, 2022 : Initial 	
//
////////////////////////////////////////////////////////////////////////////////
`timescale 1ns/1ps
module tb_ahblite_masterport();
	////////////////////////////////////////////////////////////////////////////
    //param declaration
    ////////////////////////////////////////////////////////////////////////////
    parameter           HADDR_SIZE          = 32;
    parameter           HDATA_SIZE          = 32;
    parameter           MASTER              = 2;
    parameter           SLAVE               = 4;

	parameter           CLK_PERIOD          = 1; //T=1ns => F=1GHz
    
    //HTRANS config
    parameter           IDLE                = 2'b00;
    parameter           BUSY                = 2'b01;
    parameter           NONSEQ              = 2'b10;
    parameter           SEQ                 = 2'b11;

    //BURST config
    parameter           SINGLE              = 3'b000;
    parameter           INCR                = 3'b001;
    parameter           WRAP4               = 3'b010;
    parameter           INCR4               = 3'b011;

    //SIZE config
    parameter           BYTE                = 3'b000;
    parameter           HALFWORD            = 3'b001;
    parameter           WORD                = 3'b010;

    //WRITE/READ config
    parameter           WRITE               = 1'h1;
    parameter           READ                = 1'h0;
	
	////////////////////////////////////////////////////////////////////////////
    //port declaration
    ////////////////////////////////////////////////////////////////////////////
    //-----------------------
    //Global signal
    logic                                   HCLK;
    logic                                   HRESETn;

    //-----------------------
    //connect with controller - ahb master
    logic   [HDATA_SIZE-1:0]                mst_HRDATA_o;
    logic                                   mst_HREADYOUT_o;
    logic                                   mst_HRESP_o;
    logic                                   mst_HEXOKAY_o;
    logic   [HADDR_SIZE-1:0]                mst_HADDR_i;
    logic   [2:0]                           mst_HBURST_i;
    logic                                   mst_HMASTLOCK_i;
    logic   [6:0]                           mst_HPROT_i;
    logic   [2:0]                           mst_HSIZE_i;
    logic                                   mst_HNONSEC_i;
    logic                                   mst_HEXCL_i;
    logic                                   mst_HMASTER_i;
    logic   [1:0]                           mst_HTRANS_i;
    logic   [HDATA_SIZE-1:0]                mst_HWDATA_i;
    logic                                   mst_HWRITE_i;
    
    //connect with slaveport
    logic                                   slv_HSEL_o[SLAVE-1:0];
    logic   [HADDR_SIZE-1:0]                slv_HADDR_o[SLAVE-1:0];
    logic   [2:0]                           slv_HBURST_o[SLAVE-1:0];
    logic                                   slv_HMASTLOCK_o[SLAVE-1:0];
    logic   [6:0]                           slv_HPROT_o[SLAVE-1:0];
    logic   [2:0]                           slv_HSIZE_o[SLAVE-1:0];
    logic                                   slv_HNONSEC_o[SLAVE-1:0];
    logic                                   slv_HEXCL_o[SLAVE-1:0];
    logic   [3:0]                           slv_HMASTER_o[SLAVE-1:0];
    logic   [1:0]                           slv_HTRANS_o[SLAVE-1:0];
    logic   [HDATA_SIZE-1:0]                slv_HWDATA_o[SLAVE-1:0];
    logic                                   slv_HWRITE_o[SLAVE-1:0];
    logic   [HADDR_SIZE-1:0]                slv_HADDR_mask_i[SLAVE-1:0];
    logic   [HADDR_SIZE-1:0]                slv_HADDR_base_i[SLAVE-1:0];
    logic   [HDATA_SIZE-1:0]                slv_HRDATA_i[SLAVE-1:0];
    logic                                   slv_HREADYOUT_i[SLAVE-1:0];
    logic                                   slv_HRESP_i[SLAVE-1:0];
    logic                                   slv_HEXOKAY_i[SLAVE-1:0];
	
	////////////////////////////////////////////////////////////////////////////
    //testbench reg - wire declaration
    ////////////////////////////////////////////////////////////////////////////
    //-----------------------
    //genvar
    int                                     slv_sel;
    genvar                                  i, j;

    //-----------------------
    //for review
    //HSEL generate
    logic   [SLAVE-1:0]                     view_slv_HSEL_o;
    logic   [HADDR_SIZE-1:0]                view_mst_addr_valid_0;
    logic   [HADDR_SIZE-1:0]                view_slv_addr_valid_0;
    //write path
    logic   [HDATA_SIZE-1:0]                view_slv_HWDATA_o_0;
    logic   [HDATA_SIZE-1:0]                view_slv_HWDATA_o_1;
    logic   [HDATA_SIZE-1:0]                view_slv_HWDATA_o_2;
    logic   [HDATA_SIZE-1:0]                view_slv_HWDATA_o_3;
    logic   [HADDR_SIZE-1:0]                view_slv_HADDR_o_0;
    logic   [HADDR_SIZE-1:0]                view_slv_HADDR_o_1;
    logic   [HADDR_SIZE-1:0]                view_slv_HADDR_o_2;
    logic   [HADDR_SIZE-1:0]                view_slv_HADDR_o_3;
	
	////////////////////////////////////////////////////////////////////////////
    //instance
    ////////////////////////////////////////////////////////////////////////////
    ahblite_masterport #(
        .HADDR_SIZE(HADDR_SIZE),
        .HDATA_SIZE(HDATA_SIZE),
        .MASTER(MASTER),
        .SLAVE(SLAVE)
    ) i_ahblite_masterport (
        //-----------------------
        //Global signal
        .HCLK(HCLK),
        .HRESETn(HRESETn),
        
        //-----------------------
        //connect with controller - ahb master
        .mst_HRDATA_o(mst_HRDATA_o),
        .mst_HREADYOUT_o(mst_HREADYOUT_o),
        .mst_HRESP_o(mst_HRESP_o),
        .mst_HEXOKAY_o(mst_HEXOKAY_o),
        .mst_HADDR_i(mst_HADDR_i),
        .mst_HBURST_i(mst_HBURST_i),
        .mst_HMASTLOCK_i(mst_HMASTLOCK_i),
        .mst_HPROT_i(mst_HPROT_i),
        .mst_HSIZE_i(mst_HSIZE_i),
        .mst_HNONSEC_i(mst_HNONSEC_i),
        .mst_HEXCL_i(mst_HEXCL_i),
        .mst_HMASTER_i(mst_HMASTER_i),
        .mst_HTRANS_i(mst_HTRANS_i),
        .mst_HWDATA_i(mst_HWDATA_i),
        .mst_HWRITE_i(mst_HWRITE_i),
        
        //connect with slaveport
        .slv_HSEL_o(slv_HSEL_o),
        .slv_HADDR_o(slv_HADDR_o),
        .slv_HBURST_o(slv_HBURST_o),
        .slv_HMASTLOCK_o(slv_HMASTLOCK_o),
        .slv_HPROT_o(slv_HPROT_o),
        .slv_HSIZE_o(slv_HSIZE_o),
        .slv_HNONSEC_o(slv_HNONSEC_o),
        .slv_HEXCL_o(slv_HEXCL_o),
        .slv_HMASTER_o(slv_HMASTER_o),
        .slv_HTRANS_o(slv_HTRANS_o),
        .slv_HWDATA_o(slv_HWDATA_o),
        .slv_HWRITE_o(slv_HWRITE_o),
        .slv_HADDR_mask_i(slv_HADDR_mask_i),
        .slv_HADDR_base_i(slv_HADDR_base_i),
        .slv_HRDATA_i(slv_HRDATA_i),
        .slv_HREADYOUT_i(slv_HREADYOUT_i),
        .slv_HRESP_i(slv_HRESP_i),
        .slv_HEXOKAY_i(slv_HEXOKAY_i)
    );

	
	////////////////////////////////////////////////////////////////////////////
    //testbench logic connection
    ////////////////////////////////////////////////////////////////////////////
    //for review
    generate
        for(i=0; i<SLAVE; i++) begin
            assign view_slv_HSEL_o[i] = slv_HSEL_o[i];
        end
    endgenerate

    model_get_signal #(
        .WIDTH(HADDR_SIZE),
        .HEIGHT(SLAVE),
        .SEL(0)
    ) get_mst_addr_valid__0 (
        .in(i_ahblite_masterport.mst_addr_valid),
        .out(view_mst_addr_valid_0)
    );

    model_get_signal #(
        .WIDTH(HADDR_SIZE),
        .HEIGHT(SLAVE),
        .SEL(0)
    ) get_slv_addr_valid__0 (
        .in(i_ahblite_masterport.slv_addr_valid),
        .out(view_slv_addr_valid_0)
    );

    model_get_signal #(
        .WIDTH(HDATA_SIZE),
        .HEIGHT(SLAVE),
        .SEL(0)
    ) get_slv_HWDATA_o__0 (
        .in(slv_HWDATA_o),
        .out(view_slv_HWDATA_o_0)
    );

    model_get_signal #(
        .WIDTH(HDATA_SIZE),
        .HEIGHT(SLAVE),
        .SEL(1)
    ) get_slv_HWDATA_o__1 (
        .in(slv_HWDATA_o),
        .out(view_slv_HWDATA_o_1)
    );

    model_get_signal #(
        .WIDTH(HDATA_SIZE),
        .HEIGHT(SLAVE),
        .SEL(2)
    ) get_slv_HWDATA_o__2 (
        .in(slv_HWDATA_o),
        .out(view_slv_HWDATA_o_2)
    );

    model_get_signal #(
        .WIDTH(HDATA_SIZE),
        .HEIGHT(SLAVE),
        .SEL(3)
    ) get_slv_HWDATA_o__3 (
        .in(slv_HWDATA_o),
        .out(view_slv_HWDATA_o_3)
    );

    model_get_signal #(
        .WIDTH(HDATA_SIZE),
        .HEIGHT(SLAVE),
        .SEL(0)
    ) get_slv_HADDR_o__0 (
        .in(slv_HADDR_o),
        .out(view_slv_HADDR_o_0)
    );

    model_get_signal #(
        .WIDTH(HDATA_SIZE),
        .HEIGHT(SLAVE),
        .SEL(1)
    ) get_slv_HADDR_o__1 (
        .in(slv_HADDR_o),
        .out(view_slv_HADDR_o_1)
    );

    model_get_signal #(
        .WIDTH(HDATA_SIZE),
        .HEIGHT(SLAVE),
        .SEL(2)
    ) get_slv_HADDR_o__2 (
        .in(slv_HADDR_o),
        .out(view_slv_HADDR_o_2)
    );

    model_get_signal #(
        .WIDTH(HDATA_SIZE),
        .HEIGHT(SLAVE),
        .SEL(3)
    ) get_slv_HADDR_o__3 (
        .in(slv_HADDR_o),
        .out(view_slv_HADDR_o_3)
    );
	
	////////////////////////////////////////////////////////////////////////////
    //testbench
    ////////////////////////////////////////////////////////////////////////////
    initial begin
        //init
        HCLK = 1'b1;
        HRESETn = 1'b1;
        cmd_init_mst();
        cmd_init_slv();
        
        //reset
        #(4.001*CLK_PERIOD) HRESETn = 1'b0;
        #(2.001*CLK_PERIOD) HRESETn = 1'b1;

        //sequence
        #(6.001*CLK_PERIOD);
        cmd_wr_length4(INCR4, WORD, 32'h1000_0028);

        #(10.001*CLK_PERIOD);
        cmd_wr_length4(WRAP4, WORD, 32'h1000_0028);

        #(10.001*CLK_PERIOD);
        $finish();
    end

	//-----------------------
    //#--> clock gen
    always begin
        #(0.5 * CLK_PERIOD) HCLK <= ~HCLK;
    end
    
	////////////////////////////////////////////////////////////////////////////
    //task
    ////////////////////////////////////////////////////////////////////////////
    task cmd_init_mst;
        begin
            mst_HADDR_i = 32'h0;
            mst_HBURST_i = SINGLE;
            mst_HMASTLOCK_i = 1'h0;
            mst_HPROT_i = 7'h0;
            mst_HSIZE_i = WORD;
            mst_HNONSEC_i = 1'h0;
            mst_HEXCL_i = 1'h0;
            mst_HMASTER_i = 1'h0;
            mst_HTRANS_i = IDLE;
            mst_HWDATA_i = 32'h0;
            mst_HWRITE_i = WRITE;
        end
    endtask

    task cmd_init_slv;
        begin
            for(slv_sel=0; slv_sel<SLAVE; slv_sel++) begin
                slv_HREADYOUT_i[slv_sel] = 1'h1;
                slv_HRESP_i[slv_sel] = 1'h1;
                slv_HEXOKAY_i[slv_sel] = 1'h0;
                slv_HRDATA_i[slv_sel] = 32'h0;
            end
            //addr slv0
            slv_HADDR_base_i[0] = 32'h1000_0000;
            slv_HADDR_mask_i[0] = 32'hf000_0000;
            //addr slv1
            slv_HADDR_base_i[1] = 32'h4000_0000;
            slv_HADDR_mask_i[1] = 32'he000_0000;
            //addr slv2
            slv_HADDR_base_i[2] = 32'h8000_0000;
            slv_HADDR_mask_i[2] = 32'he000_0000;
            //addr slv3
            slv_HADDR_base_i[3] = 32'ha000_0000;
            slv_HADDR_mask_i[3] = 32'hf000_0000;
        end
    endtask

    task cmd_wr_length4;
        input [2:0] burst;
        input [2:0] size;
        input [HADDR_SIZE-1:0] addr;
        begin
            mst_HBURST_i = burst;
            mst_HSIZE_i = size;
            mst_HADDR_i = addr;
            mst_HTRANS_i = NONSEQ;
            mst_HWDATA_i = $random;
            #(1.001*CLK_PERIOD) mst_HTRANS_i = SEQ; mst_HWDATA_i = $random;
            #(1.001*CLK_PERIOD) mst_HTRANS_i = SEQ; mst_HWDATA_i = $random;
            #(1.001*CLK_PERIOD) mst_HTRANS_i = SEQ; mst_HWDATA_i = $random;
            #(1.001*CLK_PERIOD);
            mst_HADDR_i = 32'h0;
            mst_HTRANS_i = IDLE;
            mst_HWDATA_i = 32'h0;
        end
    endtask
	
	////////////////////////////////////////////////////////////////////////////
    //dump waveform
    ////////////////////////////////////////////////////////////////////////////
    initial begin
        $dumpfile("wf_ahblite_masterport.vcd");
        $dumpvars(tb_ahblite_masterport);
    end
endmodule
