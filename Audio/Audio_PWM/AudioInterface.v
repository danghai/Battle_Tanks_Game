///////////////////////////////////////////////////////////////////////////////////////////
// AudioInterface.v 
//
// Copyright Hai Dang, Mark Chernishoff, Aditya Pawar
//
// Date: 7th December 2016
//
// ECE 540 SoC with FPGA
//
// Final Project: Battle Tank
// Description:
// ------------
// This module acts a multiplexer which takes input from the 
// output of games screen and keyboard to select appropriate sound for
// animation
//////////////////////////////////////////////////////////////////////////////////////////
module AudioInterface(sw,tick8Khz,clk,reset,audio_out,fire,score,explosion_act);  
input [1:0]sw;
input [1:0] fire;
input [3:0] score;
input tick8Khz;
input clk;
input explosion_act;
input reset;
output reg [7:0]audio_out;

reg [1:0]state,nextstate;
reg rAddr_Audio [15:0];
reg rAudio_out [7:0];

// music for first screen
reg [15:0] rAddr_Audio_battleTank;
wire [7:0]  rDout_Audio_battleTank;
blk_mem_gen_battleTank battle_tank (
  .clka(tick8Khz),    // input wire clka
  .addra(rAddr_Audio_battleTank),  // input wire [15 : 0] addra
  .douta(rDout_Audio_battleTank)  // output wire [7 : 0] douta
);
// music for game screen
reg [14:0] rAddr_Audio_cheersound;
wire [7:0]  rDout_Audio_cheersound;
blk_mem_gen_cheer cheer_sound (
  .clka(clk),    // input wire clka
  .addra(rAddr_Audio_cheersound),  // input wire [14 : 0] addra
  .douta(rDout_Audio_cheersound)  // output wire [7 : 0] douta
);

// // music for player 1 wins
reg [13:0] rAddr_Audio_winsound;
wire [7:0]  rDout_Audio_winsound;
blk_mem_gen_winsound win_sound (
  .clka(clk),    // input wire clka
  .addra(rAddr_Audio_winsound),  // input wire [13 : 0] addra
  .douta(rDout_Audio_winsound)  // output wire [7 : 0] douta
);
// music for player 2 wins
reg [14:0] rAddr_Audio_ambulancesound;
wire [7:0]  rDout_Audio_ambulancesound;
blk_mem_gen_ambulance ambulancce_sound (
  .clka(clk),    // input wire clka
  .addra(rAddr_Audio_ambulancesound),  // input wire [14 : 0] addra
  .douta(rDout_Audio_ambulancesound)  // output wire [7 : 0] douta
);
// // music for tank firing
reg [13:0]rAddr_Audio_tank_firing;
wire [7:0]rDout_Audio_tank_firing;
blk_mem_gen_tank_firing tank_firing (
  .clka(clk),    // input wire clka
  .addra(rAddr_Audio_tank_firing),  // input wire [13 : 0] addra
  .douta(rDout_Audio_tank_firing)  // output wire [7 : 0] douta
);
// music for tank explosion
reg [12:0]rAddr_Audio_tank_explosion;
wire [7:0]rDout_Audio_tank_explosion;
blk_mem_gen_tankexplosion tank_explosion (
  .clka(clk),    // input wire clka
  .addra(rAddr_Audio_tank_explosion),  // input wire [12 : 0] addra
  .douta(rDout_Audio_tank_explosion)  // output wire [7 : 0] douta
);

reg fire_reg;
reg explosion_reg;
// Set variable to detect fire and explosion
always @(posedge tick8Khz) begin
   if ((fire[0] == 1'b1) || (fire[1] == 1'b1))      // If tank fire
        fire_reg <= 1'b1;
  else if(rAddr_Audio_tank_firing == 16200)
        fire_reg <= 1'b0;							
  else if (explosion_act == 1'b1) begin				// If explosion happens
        fire_reg <= 1'b0;
        explosion_reg <= 1'b1;
    end
  else if(rAddr_Audio_tank_explosion == 13697) 
        explosion_reg <= 1'b0;
   else begin
        explosion_reg <= explosion_reg;
        fire_reg <= fire_reg;
   end
end  


//sequential block to generate the sound 
always @ (posedge tick8Khz)
begin
   if(reset) begin
        rAddr_Audio_battleTank <= 16'd0;
        rAddr_Audio_cheersound <= 15'd0;
        rAddr_Audio_winsound <= 14'd0;
        rAddr_Audio_ambulancesound <= 15'd0;
   end 
   else begin
            case(sw)
                2'b00:			// Music for first screen
                    begin
                        if(rAddr_Audio_battleTank == 59400) 
                            rAddr_Audio_battleTank <= 16'b0;
                  
                        else begin
                              rAddr_Audio_battleTank <= rAddr_Audio_battleTank + 1'b1;
                              audio_out <= rDout_Audio_battleTank;
                             end
                    end
				// Music for game screen
                2'b01: begin 
                 if(fire_reg == 1'b1) begin         // Tank fire
                    rAddr_Audio_cheersound <= 15'd0;
                         if(rAddr_Audio_tank_firing == 16200) begin
                            rAddr_Audio_tank_firing <= 15'b0;
                         end
                           // explotion <= 1'b0;
                         else begin
                              rAddr_Audio_tank_firing <= rAddr_Audio_tank_firing + 1'b1;
                              audio_out <= rDout_Audio_tank_firing;
                         end
                 end   
                 else if (explosion_act == 1'b1) begin   // Explosion sound
                        if(rAddr_Audio_tank_explosion == 13697) 
                              rAddr_Audio_tank_explosion <= 13'b0;
                                                   
                         else begin
                              rAddr_Audio_tank_explosion <= rAddr_Audio_tank_explosion + 1'b1;
                              audio_out <=  rDout_Audio_tank_explosion;
                         end
                                                    
                 end
                 else begin  // Tank moving
                         if(rAddr_Audio_cheersound == 179400) 
                                 rAddr_Audio_cheersound <= 16'b0;
                                  
                         else begin
                                 rAddr_Audio_cheersound <= rAddr_Audio_cheersound + 1'b1;
                                 audio_out <= rDout_Audio_cheersound;
                         end                              
                 end 
				 // Music for player 1 wins
                end // if
                2'b10: begin
                   
                          if(rAddr_Audio_winsound == 50000)
                            rAddr_Audio_winsound <= 14'b0;
                          else begin
                              rAddr_Audio_winsound <= rAddr_Audio_winsound + 1'b1;
                              audio_out <= rDout_Audio_winsound;
                          end
                end
				  // Music for player 2 wins
                 2'b11:
                      begin
                        if(rAddr_Audio_ambulancesound == 50000)
                            rAddr_Audio_ambulancesound <= 15'b0;
                        else begin
                             rAddr_Audio_ambulancesound <= rAddr_Audio_ambulancesound + 1'b1;
                             audio_out <= rDout_Audio_ambulancesound;
                        end
                      end
            endcase 
     end  
end


endmodule		