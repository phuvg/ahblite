//
// Synchronous memory interface for 32-bit wide AHB bus
//
// A synchronous memory connected to the AHB bus incurs
// a wait cycle if we have a write followed by a read
//
// To prevent this a single entry write buffer is added.
// The very first write goes into the write buffer
// (PLus address and write strobes are stored)
// If a read comes in for that address, the data is read
// out of the write buffer, not the memory.
//
// When a next write request arrives we flush the buffer to
// memory and the new write goes into the write buffer.
// The flush to memory can be done in a single cycle because
// we have the write address, strobes AND the write data.
// The write buffer is also flushed if no access is made.
//
// This module also converts the AHB bus cycle type and address to 
// byte write strobes for the memory.
//
// 
// Design by G.J. van Loo, FenLogic Ltd, 28-February-2017.
//
// This program is free software. It comes without any guarantees or
// warranty to the extent permitted by applicable law. Although the
// author has attempted to find and correct any bugs in this free software
// program, the author is not responsible for any damage or losses of any
// kind caused by the use or misuse of the program. You can redistribute
// the program and or modify it in any form without obligations, but the
// author would appreciated if the credits stays in.
// 


//
// General signal information note:
// ..._p1 means 1 pipeline stage (clock) delayed
//


//`include "timescale.h"

module ahb_sram
#(parameter L2MD = 16) // Log 2 memory depth. 16 = 64K deep
(  input           clk,       // System clock
   input           reset_n,   // System reset
   input           clken,     // Clock enable
   
   // AHB-light Slave side
   // No prot, burst or resp
   input  [L2MD-1:0] ahbl_addr,
   input       [1:0] ahbl_trans,
   input             ahbl_write,
   input       [2:0] ahbl_size,
   input      [31:0] ahbl_wdata,
   output reg [31:0] ahbl_rdata,
   output            ahbl_ready,


   // Standard synchronous memory interface
   output [L2MD-3:0] m_address,
   output            m_write,
   output reg [31:0] m_wdata,
   output     [ 3:0] m_wstrobe,
   output            m_read,
   input      [31:0] m_rdata

);

// ahbl_trans[0] is never used as this module does
// not care if accesses are sequential or not

wire            read_req; 
reg             read_req_p1;


// write strobe generation
wire      [3:0] w_info;
reg       [3:0] w_strobe;

// Single entry write buffer
reg  [L2MD-1:2] wbuf_adrs;   // Write address
reg             wbuf_valid;  // If buffer is filled
reg      [31:0] wbuf_data;   // Write data
reg      [ 3:0] wbuf_strobe; // The write strobes

wire            wbuf_write;
wire            write_req;
reg             wbuf_write_p1;
wire            wbuf_hit;  // Bus 1 write hit
reg             wbuf_hit_p1;

   // always ready (Which is the main purpose of this module)
   assign ahbl_ready  = 1'b1; 

   // Memory interface
   // writes have priority
   assign m_write   = write_req;
   assign m_read    = read_req & ~m_write;

   assign m_address = m_write ? wbuf_adrs :
                      m_read  ? ahbl_addr[L2MD-1:2] :
                      {(L2MD-2){1'b0}}; // keep bus silent

   assign m_wstrobe = wbuf_strobe;

   // For a back-to-back write or a write followed by idle have to use
   // the AHB wdata as it is not yet in wbuf_data register
   always @( *)
   begin
      if ((wbuf_write & wbuf_write_p1) || (write_req & wbuf_write_p1))
         m_wdata = ahbl_wdata;
      else
         m_wdata = wbuf_data;
   end

   // Need to do a read from memory if there is a read request 
   // (Could save tiny bit of power to suppress read
   // on 'cache' hit and all write buffer strobes set.)
   assign read_req = ahbl_trans[1] & ~ahbl_write;

   // Write to buffer each time a write from bus comes in 
   assign wbuf_write = ahbl_trans[1] & ahbl_write;

   // determine read from write buffer address
   // in which case we have to return the write buffer data
   assign wbuf_hit = read_req & wbuf_valid  & (ahbl_addr[L2MD-1:2]==wbuf_adrs);

   // Write to memory if the write buffer is full and
   // 1/ An bus write comes in 
   // Or  
   // 2/ No active cycle comes in
   // The latter (2) could be omitted but will give rise to errors
   // if memory rention is implemented as the contents of the write buffer is lost
   assign write_req  = wbuf_valid & ((ahbl_trans[1] & ahbl_write) | ~ahbl_trans[1]);
   
   // write strobe generation using
   // access ahbl_size[1:0] and LS address bits
   assign w_info = {ahbl_size[1:0],ahbl_addr[1:0]} ;

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
      4'b01_01 : // HW, address 1 illegal!!
         w_strobe = 4'b0011;
      4'b01_10 : // HW, address 2
         w_strobe = 4'b1100;
      4'b01_11 : // HW, address 3 illegal!!
         w_strobe = 4'b1100;
      4'b10_00 : // word, address 0
         w_strobe = 4'b1111;
      4'b10_01 : // word, address 1 illegal!!
         w_strobe = 4'b1111;
      4'b10_10 : // word, address 2 illegal!!
         w_strobe = 4'b1111;
      4'b10_11 : // word, address 3 illegal!!
         w_strobe = 4'b1111;
      default :  // 64-bit: Not supported
         w_strobe = 4'b0000;
      endcase
   end

   //
   // register part
   //
   always @(posedge clk or negedge reset_n)
   begin
      if (!reset_n)
      begin

         read_req_p1 <= 1'b0;

         // write buffer
         wbuf_adrs      <= {L2MD{1'b0}};
         wbuf_valid     <= 1'b0;
         wbuf_hit_p1    <= 1'b0;
         wbuf_write_p1  <= 1'b0;

         // These don't really need a reset
         wbuf_data      <= 32'h0;
         wbuf_strobe    <= 4'b0;

      end
      else if (clken)
      begin

         // Did we do an actual read?
         read_req_p1 <= read_req;

         //
         // Write buffer operations
         //

         // Hit against write buffer
         wbuf_hit_p1 <= wbuf_hit;

         // write buffer update
         // Note that write strobes are derived from ahbl_size[1:0] & address
         // this come in the address cycle, not! the data cycle

         // Pretend buffer is valid when the address arrives
         // (Even though the data buffer is not correct yet.)
         // An immediate following read to the same address
         // wil give a write buffer address match
         // The data is not needed until the cycle after by which time
         // the write data buffer WILL be valid
         //
         // If we have two conseq writes to the same address
         // the first data written to the memory will be wrong.
         // But then it will never be used:
         // A read will return the write buffer data (which WILL be correct)
         // A follow-up write will at some time overwrite the wrong data

         if (wbuf_write)
         begin
            wbuf_adrs   <= ahbl_addr[L2MD-1:2];
            wbuf_strobe <= w_strobe;
            wbuf_valid  <= 1'b1;
         end
         else
            if (write_req)
               wbuf_valid  <= 1'b0; // Mem write but no bus write

         // need to pick up the write data one cycle
         // after the write address
         wbuf_write_p1 <= wbuf_write;

         if (wbuf_write_p1)
            wbuf_data <=  ahbl_wdata;

      end
   end // always


   // data on bus comes from write buffer or memory
   // On address hit write buffer has priority!
   always @( * )
   begin
      if (wbuf_hit_p1)
      begin
         // From write buffer only if write strobe was set 
         ahbl_rdata[ 7: 0] = wbuf_strobe[0] ? wbuf_data[ 7: 0] : m_rdata[ 7: 0];
         ahbl_rdata[15: 8] = wbuf_strobe[1] ? wbuf_data[15: 8] : m_rdata[15: 8];
         ahbl_rdata[23:16] = wbuf_strobe[2] ? wbuf_data[23:16] : m_rdata[23:16];
         ahbl_rdata[31:24] = wbuf_strobe[3] ? wbuf_data[31:24] : m_rdata[31:24];
      end
      else
        ahbl_rdata = m_rdata;
   end


endmodule // ahb_sram