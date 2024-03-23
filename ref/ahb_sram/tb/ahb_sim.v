//
//
// AHB bus cycle generator
// Copyright (c) 2014 Fen Logic Ltd.
// 23-Dec-2014 G.J. van Loo
//
//


//
//
// Simplified AHB cycle generator
//
// This module generates ABH bus cycles.
// This model only generates IDLE and BUSY cycles
// To qeueue up cycles use:
// q(<cycle_size>,<cycle_type>,<address>,<write_data>,<read_data>);
// cycle_size is one off:
//   `define AHBS_S08 2'b00  // Byte access
//   `define AHBS_S16 2'b01  // Half-word access
//   `define AHBS_S32 2'b10  // Word access      
//
// cycle_type is one off:
//   `define AHBS_WRITE 4'h1 // write data
//   `define AHBS_READI 4'h2 // read & ignore data read
//   `define AHBS_READV 4'h3 // read & verify data read
//   `define AHBS_READR 4'h4 // read & wait for data to return 
// 
// address and write_data are standard
//
// read_data is used for optional verification
//   If verification takes place depends on cycle_type
//   AHBS_WRITE No read thus no verification
//   AHBS_READI read but ignore data read
//   AHBS_READV read and verify data read against given read_data
//   AHBS_READR read return data into  read_data
//       This command returns only after the read has been performed
//       and thus implies a command buffer flush as well.
//   
// Beware: command are queued up in zero time.
// Thus if the q(...) call retuns the bus cycles may not
// yet have been executed/run yet. 
//
// Examples:
// ahb_sim ahb_bus_0(....
//    ahb_bus_0.q(`AHBS_S08,`AHBS_WRITE,32'h00001003,32'h11223344,dummy);
//    ahb_bus_0.q(`AHBS_S16,`AHBS_READI,32'h00001002,32'hxxxxxxxx,dummy);
//    ahb_bus_0.q(`AHBS_S32,`AHBS_READV,32'h00001000,32'h11223344,dummy);
//    ahb_bus_0.q(`AHBS_S32,`AHBS_READR,32'h00001000,0,data_back);
//

`include "ahb_sim_h.v"

module ahb_sim 
#(parameter ERROR_STOP = 1)
(
   input             clk,
   input             reset_n,

   output     [31:0] ahb_addr,
   output     [ 1:0] ahb_trans,
   output            ahb_write,
   output     [31:0] ahb_wdata,
   output     [ 2:0] ahb_size,
   input      [31:0] ahb_rdata,
   input             ahb_ready
);


localparam  TRANS_IDLE = 2'b00,
            TRANS_BUSY = 2'b01,
            TRANS_NSEQ = 2'b10,
            TRANS_SEQ  = 2'b11;


reg  [69:0]  cmnd_buffer [0:1023];
reg  [ 9:0]  cmnd_write,cmnd_read;
reg  [ 9:0]  wait_count; // Not yet used 

wire [ 1:0]  cmnd_size;
wire [ 3:0]  cmnd_mode;
wire [31:0]  cmnd_adrs;
wire [31:0]  cmnd_data;

reg  [ 1:0]  curr_size;
reg  [ 3:0]  curr_mode,curr_mode_p1;
reg  [15:0]  curr_adrs;
reg  [ 1:0]  curr_trans;
reg  [31:0]  curr_data;

reg  [31:0]  data_read;
reg          write_p1;
reg  [31:0]  data_p1,adrs_p1;
reg          second;

   assign {cmnd_size,cmnd_mode,cmnd_adrs,cmnd_data} = cmnd_buffer[cmnd_read];

   always @(posedge clk or negedge reset_n)
   begin
      if (!reset_n)
      begin
         second     <= 1'b0;
         cmnd_write <= 10'b0;
         cmnd_read  <= 10'b0;
         wait_count <= 10'b0;
         data_read  <= 32'h0;
         write_p1   <= 1'b0;
         curr_size  <= `AHBS_S32; 
         curr_mode  <= `AHBS_READI;
         curr_mode_p1 <= `AHBS_READI;
         curr_adrs  <= 32'h0;
         curr_data  <= 32'h0;
         curr_trans <= TRANS_IDLE;
      end
      else
      begin // clocked

         if (ahb_ready)
         begin

            write_p1 <= ahb_write;
            data_p1  <= curr_data;
            adrs_p1  <= curr_adrs;
            curr_mode_p1 <= curr_mode;

            if (cmnd_write!=cmnd_read)
            begin
               // Process next command from buffer
               curr_size  <= cmnd_size;
               curr_mode  <= cmnd_mode;
               curr_trans <= TRANS_NSEQ;
               curr_adrs  <= cmnd_adrs;
               curr_data  <= cmnd_data;

               cmnd_read  <= cmnd_read + 1;
            end // Start command
            else
            begin
               // AHB IDLE transfer
               // Doing a word read of address 0
               curr_size  <= `AHBS_S32; 
               curr_mode  <= `AHBS_READI;
               curr_trans <= TRANS_IDLE;
               curr_adrs  <= 32'h0;
               curr_data  <= 32'h0;
            end

            if (!write_p1)
            begin
               data_read = ahb_rdata;
               // If is is a read verify do so
               if (curr_mode_p1==`AHBS_READV)
               begin
                 if (ahb_rdata!==data_p1)
                 begin
                   $display("%m,@%0t AHB read verify error at address 0x%08X",$time,adrs_p1);
                   $display("    Have 0x%08X, expected 0x%08X",ahb_rdata,data_p1);
                   if (ERROR_STOP)
                     #10 $stop;
                 end
//                 else
//                   $display("0x%08X==0x%08X",ahb_rdata,data_p1);
                 
               end
            end // process read data

         end // if ahb_ready
      end // clocked
   end // always

   assign ahb_size   = {1'b0,curr_size};
   assign ahb_write  = (curr_mode==`AHBS_WRITE);
   assign ahb_wdata  = write_p1 ? data_p1 : 32'hx;
   assign ahb_addr   = curr_adrs;
   assign ahb_trans  = curr_trans;

//
// Behavioural write to AHB command buffer
//
task q;
input   [1:0] size;     // AHB size 0,1 or 2 
input   [3:0] mode;     // AHB mode to run
input  [31:0] address;  // AHB address
input  [31:0] data;     // write data or read verify data
output [31:0] rdata;    // read return data

reg           busy_wait;
reg   [ 9:0]  next_write;
begin

   // size vs address checks
   if (size==2'b10 && address[1:0]!=2'b00)
   begin
      $display("%m @%0t Illegal AHB bus request: Word on wrong boundary\n",$time);
      #5 $stop;
   end
   if (size==2'b01 && address[0]!=1'b0)
   begin
      $display("%m @%0t Illegal AHB bus request: Half-word on odd boundary\n",$time);
      #5 $stop;
   end

  // before writing check if queue is full
  // if so wait clock cycle
   next_write = cmnd_write + 1;
   while (next_write==cmnd_read)
      @(negedge clk);

   
  // Altough these two BLOCKING! commands are in this order
  // without the #0's simulators do NOT honor the order!!!
   cmnd_buffer[cmnd_write] = {size,mode,address,data};
   #0;
   cmnd_write = cmnd_write + 1;
   #0;
//   #5; // DEBUG ONLY!!!!

   // If user wants the return data
   // Wait till this command has been executed
   // Todo: make this run in parallel!
   if (mode==`AHBS_READR)
   begin
      busy_wait = 1;
      while (busy_wait)
      begin
         @(posedge clk) // neg edge??
         if (cmnd_read==cmnd_write && ahb_ready)
         begin
            rdata <= ahb_rdata;
            busy_wait <= 1'b0;
         end
      end
   end

end
endtask

//
// Flush: return when all commands have been excuted
//
task flush;
begin
	while (!(cmnd_read==cmnd_write && ahb_ready))
	  @(negedge clk);

end
endtask

endmodule // ahb_sim

