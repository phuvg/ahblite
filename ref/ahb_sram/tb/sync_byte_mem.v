//
// Author: G.J. van Loo
// Behavioural model of a 
//   synchronous byte writable memory
// Can be cleared and loaded from file
// 

`include "timescale.h"

module sync_byte_mem
#( parameter L2DEP     = 12, // Log 2 memory depth in units
             BY        =  4, // Width in bytes
             CLEAR     =  1, // clear on start
             FILE      = ""  // Load from file if not empty name
 )
(
   input                  clk,
   input                  reset_n,

   input                  read,
   input                  write,
   input      [L2DEP-1:0] address, // unit address !
   input         [BY-1:0] wstrobe,
   input       [BY*8-1:0] wdata,
   output reg  [BY*8-1:0] rdata
);

localparam BITS = BY*8,
           WORDS = 1<<L2DEP;

reg [BITS-1:0] memory [0:WORDS-1];
reg [BITS-1:0] temp;

   always @(posedge reset_n)
   begin
     if (CLEAR)
        set(0,0);
      // If the filename is not zero use it to load from
      if (FILE[7:0]!=0)
         $readmemh(FILE,memory);
   end


   always @(posedge clk)
   begin : b
      integer b;
      if (read)
         rdata  <= memory[address];
      else
      begin
         if (write)
         begin
            temp = memory[address];
            for (b=0; b<BY; b=b+1)
         	   if (wstrobe[b])
                  temp[ b*8 +: 8] = wdata[ b*8 +: 8];
            memory[address] <= temp;
         end
      end
   end

//
// Fill the memory with an incrementing pattern
// using start=0 and increment=0 clears the memory
//
task set;
input reg[BITS-1:0] start,increment;
integer m;
begin
   for (m=0; m<WORDS; m=m+1)
   begin
      memory[m] = start;
      start = start + increment;
   end
end
endtask // set

endmodule


