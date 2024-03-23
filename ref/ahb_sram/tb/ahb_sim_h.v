//
//
// APB simulator header file
//
//

`define AHBS_WRITE 4'h1 // write data
`define AHBS_READI 4'h2 // read & ignore data
`define AHBS_READV 4'h3 // read verify data
`define AHBS_READR 4'h4 // read return data

`define AHBS_S08 2'b00  // Byte access
`define AHBS_S16 2'b01  // Half-word access
`define AHBS_S32 2'b10  // Word access


// forward task q;
// input   [7:0] pre_wait; // cycles to wait before command
// input   [3:0] mode;     // APB mode to run
// input  [15:0] address;  // APB address
// input  [31:0] data;     // write data or read verify data
// output [31:0] rdata;    // read return data

