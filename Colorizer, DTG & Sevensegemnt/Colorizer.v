`timescale 1ns / 1ps
///////////////////////////////////////////////////////////////////////////////////////////
// Colorizer.v - Module for displaying the colours of the worldmap and icon.
//
// Copyright Hai Dang, Mark Chernishoff, Aditya Pawar
//
// Date: 7th December 2016
//
// ECE 540 SoC with FPGA
//
// Final Project: Battle Tank
//////////////////////////////////////////////////////////////////////////////////////////

module Colorizer(pRed_VGA,pGreen_VGA,pBlue_VGA,pIcon,pVideo_on,pClk,pReset);

//RGB colour outputs
output reg [3:0] pRed_VGA;
output reg[3:0] pGreen_VGA;
output reg [3:0] pBlue_VGA;

//Pixel value of color stream coming from switch interface
input  [11:0] pIcon;

//Video_on signal from DTG.
input  pVideo_on;

input pClk;
input pReset;


always@(posedge pClk)
begin
// At reset RGB values are set to 0 for black screen.
if(pReset)
begin
       pRed_VGA<=4'b0000;
       pGreen_VGA<=4'b0000;
       pBlue_VGA<=4'b0000;
end
    
else 
        if(pVideo_on)
        begin    
        // If the video_on signal is enabled then based on the pixel information from the switch interface
        //the RGB colours are set.
            {pRed_VGA,pGreen_VGA,pBlue_VGA} <=  pIcon;      
        end
     //else black screen
     else
         begin  
            pRed_VGA<=4'b0000;
            pGreen_VGA<=4'b0000;
            pBlue_VGA<=4'b0000;         
         end    
 end                    
endmodule