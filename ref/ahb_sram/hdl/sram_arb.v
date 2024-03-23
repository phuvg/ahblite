//
//
// Uncached SRAM Arbiter
//
// Two port arbiter and write buffer**
//
//============================================================================
// COPYRIGHT (c) 2015 Xsilon Ltd
//
// PROJECT        : Wizard
// AUTHOR         : G.J. van Loo
// DESCRIPTION    : Dual AHB port front end for synchronous memory
//
// History        : 13-Mar-2015 Initial revision.
//
//============================================================================
// Copyright (c) 2015 by Xsilon Ltd. This model, and any intellectual property
// or knowhow upon which it relies, is the confidential and proprietary
// property of Xsilon Ltd.  The possession or use of this file or any part of
// its content requires a written licence from Xsilon Ltd.
//============================================================================
//

//
// Connects two busses N bits wide
// to a synchronous memory 2N bits wide
// Same as sramcarb but with the cache removed as it take a lot og registers
// Also brings back the SRAN width to 32 bits
//
// ** A synchronous memory connected to the AHB bus
// always has a single entry write buffer to prevent
// the bus from stalling on each read-after-write
//
// The very first write goes into the write buffer
// (Address, data and write strobes)
// From then on it is part of the 'cache'.
// When a next write request arrives we flush the buffer to
// memory and the new write goes into the write buffer.
// The flush to memory can be done in a single cycle because
// we have the write address, strobes AND the write data.
// This may cause a stall on the other port. So be it!
//
//
//
// Not done:
// I COULD look at the bus1 cache to return data to bus2
// and vice versa

//
// General signal information note:
// ..._p1 means 1 pipeline stage (clock) delayed
//


//`include "timescale_h.v"

module sram_arb
#(parameter L2MD = 16) // Log 2 memory depth. 16 = 64K deep
(  input           clk,       // System clock
   input           reset_n,   // System reset
   input           clken,     // Clock enable

   input    [1:0]  arb,       //  arbitration scheme
   // arb[0] = 1 is round robin
   //          arb[1] is not used
   //        = 0 is priority
   //          arb[1]=0 bus 1 highest priority
   //          arb[1]=1 bus 2 highest priority

   // Bus-1
   // AHB-light Slave side
   // No prot, burst or resp
   input [L2MD-1:0] ahbl1_addr,
   input      [1:0] ahbl1_trans,
   input            ahbl1_write,
   input      [2:0] ahbl1_size,
   input     [31:0] ahbl1_wdata,
   output    [31:0] ahbl1_rdata,
   output           ahbl1_ready,


   // Bus-2
   // AHB-light Slave side
   // No prot, burst or resp
   input [L2MD-1:0] ahbl2_addr,
   input      [1:0] ahbl2_trans,
   input            ahbl2_write,
   input      [2:0] ahbl2_size,
   input     [31:0] ahbl2_wdata,
   output    [31:0] ahbl2_rdata,
   output           ahbl2_ready,

   // Standard synchronous memory interface
   output [L2MD-3:0] m_address,
   output            m_write,
   output reg [31:0] m_wdata,
   output     [ 3:0] m_wstrobe,
   output            m_read,
   input      [31:0] m_rdata

);


   //
   // standard AHB bus-1 handling
   // (reduced signals)
   //

reg  [L2MD-1:0] hold1_addr;
reg         hold1_trans; // MS bit only
reg         hold1_write;
reg   [1:0] hold1_size;  // drop MS bit


wire [L2MD-1:0] addr_1;
wire        trans1; // MS bit only
wire        write1;
wire  [1:0] size_1; // drop MS bit

   // If the port is not ready we have to use the hold information
   // as the current address is for the next cycle
   assign  addr_1 = ahbl1_ready ? ahbl1_addr     : hold1_addr ;
   assign  trans1 = ahbl1_ready ? ahbl1_trans[1] : hold1_trans;
   assign  write1 = ahbl1_ready ? ahbl1_write    : hold1_write;
   assign  size_1 = ahbl1_ready ? ahbl1_size[1:0]: hold1_size ;

   always @(posedge clk or negedge reset_n)
   begin
   	if (!reset_n)
   	begin
   	   hold1_addr  <= {L2MD{1'b0}};
         hold1_trans <= 1'b0;
         hold1_write <= 1'b0;
         hold1_size  <= 2'b0;
      end
      else if (clken)
      begin
        if (ahbl1_ready)
        begin
   	     hold1_addr <= ahbl1_addr ;
           hold1_trans<= ahbl1_trans[1];
           hold1_write<= ahbl1_write;
           hold1_size <= ahbl1_size[1:0] ;
        end
      end // clocked
   end // always

   //
   // standard AHB bus-2 handling
   // (reduced signals)
   //

reg  [L2MD-1:0] hold2_addr;
reg         hold2_trans; // MS bit only
reg         hold2_write;
reg   [1:0] hold2_size;  // drop MS bit


wire [L2MD-1:0] addr_2;
wire        trans2; // MS bit only
wire        write2; // MS bit only
wire  [1:0] size_2; // drop MS bit


   // If the port is not ready we have to use the hold information
   // as the current address is for the next cycle
   assign  addr_2 = ahbl2_ready ? ahbl2_addr     : hold2_addr ;
   assign  write2 = ahbl2_ready ? ahbl2_write    : hold2_write;
   assign  trans2 = ahbl2_ready ? ahbl2_trans[1] : hold2_trans;
   assign  size_2 = ahbl2_ready ? ahbl2_size[1:0]: hold2_size ;

   always @(posedge clk or negedge reset_n)
   begin
   	if (!reset_n)
   	begin
   	   hold2_addr <= {L2MD{1'b0}};
         hold2_trans<= 1'b0;
         hold2_write<= 1'b0;
         hold2_size <= 2'b0;
      end
      else if (clken)
      begin
        if (ahbl2_ready)
        begin
   	     hold2_addr <= ahbl2_addr ;
           hold2_trans<= ahbl2_trans[1];
           hold2_write<= ahbl2_write;
           hold2_size <= ahbl2_size[1:0] ;
        end
      end // clocked
   end // always


//
// Channel 1
//

wire            b1_read_req; // bus 1 read request
wire            b1_mem_read; // bus 1 read happening
reg             b1_mem_read_p1;

//
// Channel 2
//

wire            b2_read_req; // bus 1 read request
wire            b2_mem_read; // bus 1 read happening
reg             b2_mem_read_p1;

// write strobe generation
wire      [3:0] w_info;
reg       [3:0] w_strobe;

// Single write buffer
reg  [L2MD-1:2] ws_adrs;
reg             ws_valid;
reg      [31:0] ws_data;
reg      [ 3:0] ws_strobe;
reg             ws_write;
reg             ws_sel;
wire            ws_flush_to_mem;
wire            b1_write_req;
wire            b2_write_req;
wire            b1_mem_write;
wire            b2_mem_write;
reg             buf1_write_p1;
reg             buf2_write_p1;
wire            b1_wthit;  // Bus 1 write hit
wire            b2_wthit;  // Bus 2 write hit
reg             b1_wthit_p1;
reg             b2_wthit_p1;

// Memory interface and RR
reg            m_addr_2_p1; //
reg            chan_sel;
reg            chan_sel_p1;



   // Memory interface
   // writes have priority
   assign m_write   = ws_flush_to_mem;
   assign m_read    = (b1_mem_read  | b2_mem_read) & ~m_write;

   assign m_address = m_write ? ws_adrs :
                      m_read  ? (chan_sel ? addr_2[L2MD-1:2] : addr_1[L2MD-1:2]) :
                      {(L2MD-2){1'b0}}; // keep bus silent

   assign m_wstrobe = ws_strobe;
   // For a back-to-back write have to use the AHB wdata
   // as it is not yet in ws_data register
   always @( *)
   begin
      if (ws_write & buf1_write_p1)
         m_wdata = ahbl1_wdata;
      else
      if (ws_write & buf2_write_p1)
         m_wdata = ahbl2_wdata;
      else
         m_wdata   = ws_data;
   end


   // determine write cache hits
   assign b1_wthit = trans1 & ~write1 & ws_valid  & (addr_1[L2MD-1:2]==ws_adrs);
   assign b2_wthit = trans2 & ~write2 & ws_valid  & (addr_2[L2MD-1:2]==ws_adrs);


   // Need to do a read from memory if
   // there is a read request and we have no write cache hit
   assign b1_read_req = trans1 & ~write1 & ~b1_wthit;
   assign b2_read_req = trans2 & ~write2 & ~b2_wthit;

   // Write to memory if a bus write comes in and the write buffer is full
   assign b1_write_req = trans1 & write1 & ws_valid;
   assign b2_write_req = trans2 & write2 & ws_valid;

   // write strobe generation using
   // access size and LS address bits
   assign w_info = chan_sel ? {size_2[1:0],addr_2[1:0]} : {size_1[1:0],addr_1[1:0]} ;

   always @( w_info )
   begin
      case (w_info)
      4'b00_00 : // byte, address 0
         w_strobe = 4'b0001;
      4'b00_01 : // byte, address 1
         w_strobe = 4'b0010;
      4'b00_10 : // byte, address 2
         w_strobe = 4'b0100;
      4'b00_11 : // byte, address 3
         w_strobe = 4'b1000;
      4'b01_00 : // HW, address 0
         w_strobe = 4'b0011;
      4'b01_01 : // HW, address 1 illegal??
         w_strobe = 4'b0011;
      4'b01_10 : // HW, address 2
         w_strobe = 4'b1100;
      4'b01_11 : // HW, address 3 illegal??
         w_strobe = 4'b1100;
      4'b10_00 : // word, address 0
         w_strobe = 4'b1111;
      4'b10_01 : // word, address 1 illegal??
         w_strobe = 4'b1111;
      4'b10_10 : // word, address 2 illegal??
         w_strobe = 4'b1111;
      4'b10_11 : // word, address 3 illegal??
         w_strobe = 4'b1111;
      default :  // 64-bit: should not happen
         w_strobe = 4'b0000;
      endcase
   end


   //
   // Memory access arbiter
   //
   // Writes go before reads
   // The rest is 'programmable'
   //
   // arb[0] = 1 is round robin
   //          arb[1] is not used
   //        = 0 is priority
   //          arb[1]=0 bus 1 highest priority
   //          arb[1]=1 bus 2 highest priority
   always @( * )
   begin
      if (arb[0])
      begin // round robin
         if (chan_sel_p1)
         begin // Previous was bus 2
               // Priority for bus 1
            // writes go first!
            if (b1_write_req)
               chan_sel = 1'b0;
            else
            if (b2_write_req)
               chan_sel = 1'b1;
            else
            if (b1_read_req)
               chan_sel = 1'b0;
            else
               chan_sel = 1'b1;
         end
         else
         begin // Previous was bus 1
               // Priority for bus 2
            // writes go first!
            if (b2_write_req)
               chan_sel = 1'b1;
            else
            if (b1_write_req)
               chan_sel = 1'b0;
            else
            if (b2_read_req)
               chan_sel = 1'b1;
            else
               chan_sel = 1'b0;
         end
      end
      else
      begin
         // hard priority
         if (arb[1])
         begin // Priority for bus 2
            if (b2_write_req)
               chan_sel = 1'b1;
            else
            if (b1_write_req)
               chan_sel = 1'b0;
            else
            if (b2_read_req)
               chan_sel = 1'b1;
            else
               chan_sel = 1'b0;
         end
         else
         begin // Priority for bus 1
            if (b1_write_req)
               chan_sel = 1'b0;
            else
            if (b2_write_req)
               chan_sel = 1'b1;
            else
            if (b1_read_req)
               chan_sel = 1'b0;
            else
               chan_sel = 1'b1;
         end
      end
   end


   // All signals below are mutual exclusive
   assign b1_mem_read  = (chan_sel==1'b0) & b1_read_req;
   assign b2_mem_read  = (chan_sel==1'b1) & b2_read_req;
   assign b1_mem_write = (chan_sel==1'b0) & b1_write_req;
   assign b2_mem_write = (chan_sel==1'b1) & b2_write_req;
   // Write write_buffer to memory
   assign ws_flush_to_mem = b1_mem_write | b2_mem_write;

   // Control access to write buffer
   always @( * )
   begin
      if (ws_valid==1'b0)
      begin
         // write buffer is empty
         if (trans2 & write2)
         begin
            ws_write = 1'b1;
            ws_sel   = 1'b1;
         end
         else
         if (trans1 & write1)
         begin
            ws_write = 1'b1;
            ws_sel   = 1'b0;
         end
         else
         begin
            ws_write = 1'b0;
            ws_sel   = 1'b0;
         end

      end
      else
      begin
         ws_write = ws_flush_to_mem;
         ws_sel   = chan_sel;
      end
   end

   //
   // register part
   //
   always @(posedge clk or negedge reset_n)
   begin
      if (!reset_n)
      begin

         b1_mem_read_p1 <= 1'b0;
         b2_mem_read_p1 <= 1'b0;

         // write buffer
         ws_adrs        <= {L2MD{1'b0}};
         ws_valid       <= 1'b0;
         b1_wthit_p1    <= 1'b0;
         b2_wthit_p1    <= 1'b0;
         buf1_write_p1  <= 1'b0;
         buf2_write_p1  <= 1'b0;

         // Memory access & RR
         m_addr_2_p1    <= 1'b0;
         chan_sel_p1    <= 1'b0;

         // These don't really need a reset
         ws_data        <= 32'h0;
         ws_strobe      <= 4'b0;

      end
      else if (clken)
      begin

         //
         // cache operations
         //

         // Hit against write buffer
         b1_wthit_p1 <= b1_wthit;
         b2_wthit_p1 <= b2_wthit;

         // Did we do an actual read?
         b1_mem_read_p1 <= b1_mem_read;
         b2_mem_read_p1 <= b2_mem_read;

          // store selected channal for round-robin
         // but only if a real access happens
         if (b1_mem_read | b2_mem_read | ws_flush_to_mem)
            chan_sel_p1 <= chan_sel;

         // write buffer update
         // note that write strobes are derived from size & address
         // thus come in the address cycle, not the data cycle

         // Pretend buffer is valid when the address arrives
         // (Even though the data buffer is not correct yet.)
         // An immediate following read to the same address
         // wil give a write buffer address match
         // The data is not needed until the cycle after by which time
         // the write data buffer WILL be valid
         //
         // If we have two conseq writes to the same address
         // the first data written to the memory will be wrong.
         // But then it wil never be used:
         // A read will return the write buffer data (which WILL be correct)
         // The follow-up write will at some time overwrite the wrong data
         //

         if (ws_write)
         begin
            ws_adrs   <= ws_sel ? addr_2[L2MD-1:2] : addr_1[L2MD-1:2];
            ws_strobe <= w_strobe;
            ws_valid  <= 1'b1;
         end

         // need to pick up the write data after the write address
         // also used for the write ready
         buf1_write_p1 <= (ws_write & ~ws_sel);
         buf2_write_p1 <= (ws_write &  ws_sel);

         if (buf1_write_p1)
            ws_data <=  ahbl1_wdata;
         else
            if (buf2_write_p1)
               ws_data <= ahbl2_wdata;

      end
   end // always


   // data on bus comes from write buffer or memory
   // Write buffer has highest priority!
   assign ahbl1_rdata  = b1_wthit_p1 ? ws_data : m_rdata;
   assign ahbl2_rdata  = b2_wthit_p1 ? ws_data : m_rdata;

   // ready if hit
   // Else ready if other side is NOT using the memory
   // There is a single not-ready too many for the very first write to the buffer
   // But this way the code depth is much smaller
   assign ahbl1_ready  = b1_wthit_p1 ? 1'b1 : ~(b2_mem_read_p1 | buf2_write_p1);
   assign ahbl2_ready  = b2_wthit_p1 ? 1'b1 : ~(b1_mem_read_p1 | buf1_write_p1);


endmodule