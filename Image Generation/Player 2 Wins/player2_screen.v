///////////////////////////////////////////////////////////////////////////////////////////
// player2_screen.v -  module for the player2_screen display logic
//
// Copyright Hai Dang, Mark Chernishoff, Aditya Pawar
//
// Date: 7th December 2016
//
// ECE 540 SoC with FPGA
//
// Final Project: Battle Tank
//
// Description:
// ------------
// This Module contains logic for displaying the player2_screen (2nd player wins)
//
//////////////////////////////////////////////////////////////////////////////////////////
module player2_screen (first_screen_out,pPixel_row,pPixel_column,pClk,pClk2,pReset);

input  pClk; //100Mhz
input pClk2; //44.9 Mhzinput  pReset; 
input [10:0] pPixel_row; //from DTG
input [10:0] pPixel_column; //From DTG
input pReset;

output reg [11:0]  first_screen_out = 12'd0;

wire [10:0] pixel_row_B,pixel_column_B;

//Zooming for background from 128x96 to 1024x768
assign pixel_row_B =  {3'b000,pPixel_row [9:3]};
assign pixel_column_B =  {3'b000,pPixel_column [9:3]};

//Address to be passed to the Block RAM
reg [13:0] rAddr_first = 14'd0;

//Out from the Block RAM
wire [11:0] rDout_first;

// Block ROM to store the image information of background
blk_mem_gen_3 first_page (
  .clka(pClk),    // input wire clka
  .addra(rAddr_first),  // input wire [13 : 0] addra
  .douta(rDout_first)  // output wire [11 : 0] douta
);



always @(posedge pClk2)begin
    if (pReset)
        first_screen_out <= 12'd0;
    else
        begin
            //Where ever is the pixel pointer, take the rgb value from the BRAM and print it.
            rAddr_first   <= {pixel_row_B[6:0],pixel_column_B[6:0]};
            first_screen_out  <= rDout_first;
        end  
end

endmodule