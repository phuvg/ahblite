//
//
// AHB sram Testbench
//
//

`include "timescale.h"
`include "ahb_sim_h.v"

module ahb_sram_test;

localparam CLK_PERIOD=100;

localparam L2MD= 10; // 2^16 is 64K bytes memory 

reg             clk; // System clock
reg             reset_n; // System reset
reg             clken; // Clock enable

reg     [  1:0] arb; //  arbitration scheme

   // AHB-light Slave side
   // No prot, burst or resp
wire     [31:0] ahbl_addr;
wire    [  1:0] ahbl_trans;
wire            ahbl_write;
wire    [  2:0] ahbl_size;
wire    [ 31:0] ahbl_wdata;
wire    [ 31:0] ahbl_rdata;
wire            ahbl_ready;

   // Standard synchronous memory interface
wire [L2MD-3:0] m_address;
wire            m_write;
wire    [ 31:0] m_wdata;
wire    [  3:0] m_wstrobe;
wire            m_read;
wire    [ 31:0] m_rdata;

integer loop1,r,adr,data,size,wrt,exp;
reg [31:0] dummy;

reg [31:0] mirror_mem [0:255];

   initial
   begin
      clk           = 1'b0;
      reset_n       = 1'b0;
      clken         = 1'b1;

      arb           = 2'b0;
      #(CLK_PERIOD*10) reset_n = 1'b1;
      #(CLK_PERIOD*5)  ;
      // Fill memory with pattern word_data===word_address
      sync_byte_mem_0.set(32'h00000000,32'h00000004);
      #(CLK_PERIOD*5)  ;

      // 8 conseq reads
      for (loop1=0; loop1<32; loop1=loop1+4)
        ahb_sim.q(`AHBS_S32,`AHBS_READV,32'h0,32'h0,dummy);
      ahb_sim.flush;
      #(CLK_PERIOD*5)  ;


      // Write followed by delayed read of same location
      ahb_sim.q(`AHBS_S32,`AHBS_WRITE,32'h8,32'h88888888,dummy);
      ahb_sim.flush;
      #(CLK_PERIOD*2)  ;
      ahb_sim.q(`AHBS_S32,`AHBS_READV,32'h8,32'h88888888,dummy);
      ahb_sim.flush;
      #(CLK_PERIOD*5)  ;

      // Write followed by direct read of same location
      // This will flush the previous write to memory
      ahb_sim.q(`AHBS_S32,`AHBS_WRITE,32'h10,32'h10101010,dummy);
      ahb_sim.q(`AHBS_S32,`AHBS_READV,32'h10,32'h10101010,dummy);
      ahb_sim.flush;
      #(CLK_PERIOD*5)  ;

      // Three back-to-back writes to same location 
      // This will trigger write-by-pass-data-fetch
      ahb_sim.q(`AHBS_S32,`AHBS_WRITE,32'h14,32'h12121212,dummy);
      ahb_sim.q(`AHBS_S32,`AHBS_WRITE,32'h14,32'h13131313,dummy);
      ahb_sim.q(`AHBS_S32,`AHBS_WRITE,32'h14,32'h14141414,dummy);
      ahb_sim.q(`AHBS_S32,`AHBS_READV,32'h14,32'h14141414,dummy);
      ahb_sim.flush;
      #(CLK_PERIOD*5)  ;
      
      // Byte writes 
      ahb_sim.q(`AHBS_S08,`AHBS_WRITE,32'h40,32'hFFFFFF44,dummy);
      ahb_sim.q(`AHBS_S32,`AHBS_READV,32'h40,32'h00000044,dummy);
      ahb_sim.q(`AHBS_S08,`AHBS_WRITE,32'h41,32'hFFFF43FF,dummy);
      ahb_sim.q(`AHBS_S32,`AHBS_READV,32'h40,32'h00004344,dummy);
      ahb_sim.q(`AHBS_S08,`AHBS_WRITE,32'h42,32'hFF42FFFF,dummy);
      ahb_sim.q(`AHBS_S32,`AHBS_READV,32'h40,32'h00424344,dummy);
      ahb_sim.q(`AHBS_S08,`AHBS_WRITE,32'h43,32'h41FFFFFF,dummy);
      ahb_sim.q(`AHBS_S32,`AHBS_READV,32'h40,32'h41424344,dummy);
      ahb_sim.flush;
      #(CLK_PERIOD*5)  ;

      // Half word writes 
      ahb_sim.q(`AHBS_S16,`AHBS_WRITE,32'h40,32'h51525354,dummy);
      ahb_sim.q(`AHBS_S32,`AHBS_READV,32'h40,32'h41425354,dummy);
      ahb_sim.q(`AHBS_S16,`AHBS_WRITE,32'h42,32'h51525354,dummy);
      ahb_sim.q(`AHBS_S32,`AHBS_READV,32'h40,32'h51525354,dummy);
      ahb_sim.q(`AHBS_S16,`AHBS_WRITE,32'h42,32'h6162FFFF,dummy);
      ahb_sim.q(`AHBS_S16,`AHBS_WRITE,32'h40,32'hFFFF6364,dummy);
      ahb_sim.q(`AHBS_S32,`AHBS_READV,32'h40,32'h61626364,dummy);
      ahb_sim.flush;
      #(CLK_PERIOD*15)  ;

      //
      // Random test
      // Using 1Kbyte mirror memory
      //
      
      // Fill memories with pattern again 
      sync_byte_mem_0.set(32'h00000000,32'h00000004);
      for (loop1=0; loop1<256; loop1=loop1+1)
         mirror_mem[loop1]=loop1<<2;
         
     for (loop1=0; loop1<1000000; loop1=loop1+1)
     begin
        adr = $random & 32'h03FF;
        data = $random;        
        size = ($random>>8) & 3;
        while (size==3)
          size = ($random>>8) & 3;      
        wrt = ($random>>9) & 1;
        if (size==1)
          adr = adr & 32'hFFFFFFFE;
        if (size==2)
          adr = adr & 32'hFFFFFFFC;
        if (wrt)
        begin        
          ahb_sim.q(size,`AHBS_WRITE,adr,data,dummy);
          mirror_write(size[1:0],adr,data);
//          $display("@%0t W %2d 0x%08x 0x%08x",$time,size,adr,data);
        end // do write 
        else
        begin
           exp = mirror_mem[adr>>2];
           adr = adr & 32'hFFFFFFFC;
           ahb_sim.q(`AHBS_S32,`AHBS_READV,adr,exp,dummy);
//           $display("@%0t R %2d 0x%08x 0x%08x?",$time,size,adr,exp);
           ahb_sim.flush;
        end // do verify read
        
     end // test loop
     ahb_sim.flush;
     #(CLK_PERIOD*15)  ;
     
      $stop;

   end
   
ahb_sim
ahb_sim (
      .clk      (clk),
      .reset_n  (reset_n),

      .ahb_size (ahbl_size),
      .ahb_addr (ahbl_addr),
      .ahb_trans(ahbl_trans),
      .ahb_write(ahbl_write),
      .ahb_wdata(ahbl_wdata),
      .ahb_rdata(ahbl_rdata),
      .ahb_ready(ahbl_ready)
   );

ahb_sram
   #(
      .L2MD (L2MD) 
   ) // parameters
ahb_sram_0 (
      .clk         (clk),          // System clock
      .reset_n     (reset_n),      // System reset
      .clken       (clken),        // Clock enable

   // Bus-1
   // AHB-light Slave side
   // No prot, burst or resp
      .ahbl_addr (ahbl_addr[15:0]),
      .ahbl_trans(ahbl_trans),
      .ahbl_write(ahbl_write),
      .ahbl_size (ahbl_size),
      .ahbl_wdata(ahbl_wdata),
      .ahbl_rdata(ahbl_rdata),
      .ahbl_ready(ahbl_ready),

   // Standard synchronous memory interface
      .m_address   (m_address),    // do NOT use LS bit!
      .m_write     (m_write),
      .m_wdata     (m_wdata),
      .m_wstrobe   (m_wstrobe),
      .m_read      (m_read),
      .m_rdata     (m_rdata)
   );


sync_byte_mem
   #(
      .CLEAR  (1) ,    // clear on start
      .LOAD   (0)  ,   // load after clearing
      .L2DEP  (L2MD-2),  // Log 2 memory depth in <width> units
      .BY     (4)      // Width in bytes
   ) // parameters
sync_byte_mem_0 (
      .clk    (clk),
      .reset_n(reset_n),
      .read   (m_read),
      .write  (m_write),
      .address(m_address),
      .wstrobe(m_wstrobe),
      .wdata  (m_wdata),
      .rdata  (m_rdata)
   );

task mirror_write;
input [1:0] size;
input [31:0] address;
input [31:0] data;
begin
   case (size)
   0 : 
      case (address[1:0])
         0 : mirror_mem[address>>2][ 7: 0] = data[ 7: 0];
         1 : mirror_mem[address>>2][15: 8] = data[15: 8];
         2 : mirror_mem[address>>2][23:16] = data[23:16];
         3 : mirror_mem[address>>2][31:24] = data[31:24];         
      endcase
   1 : 
      case (address[1])
         0 : mirror_mem[address>>2][15: 0] = data[15: 0];
         1 : mirror_mem[address>>2][31:16] = data[31:16];
      endcase
   2:
      mirror_mem[address>>2] = data;      
   endcase
end
endtask

   // Generate arbitrary clock. 
   initial
   begin
      clk = 1'b0;
      forever
         #(CLK_PERIOD/2) clk = ~clk;
   end

endmodule
