`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/23/2016 02:03:40 AM
// Design Name: Hai Dang, Mark Chernishoff, Aditya Pawar
// Module Name: SwitchInterface
// Project Name: Battle tank game
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
// The switch interface is just used to control the communication with the Picoblaze switch.v 
// program. The SwitchInterface inputs are the FirstScreen, GameScreen, Player1Wins, and 
// Player2Wins data outputs to VGA. There is also inputs from the keyboard and player_screen 
// that are used to control which screen needs to be output to the display. 
//
//////////////////////////////////////////////////////////////////////////////////

module SwitchInterface(clk,reset,FirstScreen,GameScreen,Player1Wins,Player2Wins,sw,color,port_id,
                        write_strobe,out_port,in_port,interrupt,interrupt_ack,player_screen,led,reset_plyrScrn,mode);

//inputs

input               clk,reset;

input       [11:0]  FirstScreen;
input       [11:0]  GameScreen;
input       [11:0]  Player1Wins;
input       [11:0]  Player2Wins;

input       [1:0]   sw;                // keyboard input

output reg  [11:0]  color;
input       [7:0]   port_id;            // IO's for picoblaze
input               write_strobe;
input       [7:0]   out_port; 
output  reg [7:0]   in_port;
output  reg         interrupt;
input               interrupt_ack;
input       [1:0]   player_screen;      // selector for player 1 or 2 win screen
output reg  [7:0]   led;
output reg          reset_plyrScrn;     // resets player_screen signal
output      [1:0]   mode;

reg         [1:0]   screenout;          // screen selector

assign              mode = screenout;   // Which mode for screen

//////////////// Interrupt acknowledg handler ////////////////////////////
always @(posedge clk) begin
		if (interrupt_ack)
			interrupt <= 1'b0;
		else if (player_screen > 2'd0 || sw > 2'd0)   // player_screen changes or keyboard input changes, intiate interrupt
			interrupt <= 1'b1;
		else
			interrupt <= interrupt;
	end

///////////////// IO's to Picoblaze //////////////////////////////////////
	
always @ (posedge clk)
    begin
         if (reset)
            begin
                color <= FirstScreen;
            end
        else if (write_strobe) begin
           case (port_id)
               8'h02:  led[7:0] <= out_port;               //port address for lower 8 LED's
               8'h03:  if(out_port >= 1'd1) 
                            screenout <= 2'b01;            // game_screen selected 
                       else
                            color <= color;
               8'h04:  if(out_port >= 1'd1) 
                            screenout <= 2'b10;             // Player 1 wins selected
                       else
                             color <= color;
               8'h05:  if(out_port >= 1'd1) 
                            screenout <= 2'b11;             // player 2 wins selected
                        else
                            color <= color;
               8'h06: if(out_port >= 1'd1)
                            screenout <= 2'b00;             // First Screen selected
                        else
                           screenout <= screenout;
              default: color <= color;
           endcase
       end
       
       else begin
            case (port_id)   
              8'h00:  in_port <= sw;                        //port address for sw selected
              8'h01:  in_port <= player_screen;            //port address for player_screen selected
              
              default: ; 
           endcase
        end
        
       case (screenout)
            2'b00: begin
                        reset_plyrScrn <= 1'd0;            // first screen output
                        color <= FirstScreen;
                   end
            2'b01: begin
                        reset_plyrScrn <= 1'd0;           // game screen output
                        color <= GameScreen;
                   end
            2'b10: begin
                        color <= Player1Wins;               // Player 1 wins output
                        reset_plyrScrn <= 1'd1;
                   end
            2'b11: begin
                           color <= Player2Wins;            // Player 2 wins output 
                           reset_plyrScrn <= 1'd1;
                      end
       endcase
    end


endmodule 
