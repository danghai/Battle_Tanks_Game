`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Hai Dang HOang
// 
// Create Date: 
// Design Name: 
// Module Name: keyboard
// Project Name: 
// Target Devices: Nexys4DDR
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments: This module takes input from keys of keyboard ( PS2_CLK, PS2_DATA)
// 						and outputs the designated function. It also has algorithm to detect
//						hold keys and press and then release the key.
//////////////////////////////////////////////////////////////////////////////////


module keyboard(
    input clk,
    input kclk,
    input kdata,
    output reg no, yes,
    output reg up1, down1, left1, right1, fire1,        // Keyboard for 1st player
    output reg up2, down2, left2, right2, fire2         // Keyboard for 2nd player
    );
    
    wire kclkf, kdataf;
    reg [10:0]datacur;
    reg [7:0]dataprev;
    reg [3:0]cnt;
    reg keycode;
    reg flag;
    reg isBreak;
    
    parameter              // Parameter keyboard button for both player 
        UP1   = 8'h1D,     // W button 
        DOWN1 = 8'h1B,     // S button
        LEFT1 = 8'h1C,     // A button
        RIGHT1= 8'h23,     // D button
        FIRE1 = 8'h29,     // Space button
        
        UP2   = 8'h43,     // I button
        DOWN2 = 8'h42,     // K button
        LEFT2 = 8'h3B,     // J button
        RIGHT2= 8'h4B,     // L button
        FIRE2 = 8'h5A,     // Enter button
        
        NO = 8'h31,        // N button
        YES = 8'h35;       // Y button
    initial begin
        cnt<=4'b0000;
        flag<=1'b0;
        isBreak <=1'b0;
    end
    
debouncer debounce(
    .clk(clk),
    .I0(kclk),
    .I1(kdata),
    .O0(kclkf),
    .O1(kdataf)
);
    
always@(negedge(kclkf))begin
     if(isBreak == 1'b1) begin
        datacur [cnt] = kdataf;
        cnt = cnt + 1;
        if (cnt == 11) cnt = 0;
        // 1st player
        if (datacur[8:1] == UP1 && cnt == 0) begin up1 = 0; isBreak = 0; end
        if (datacur[8:1] == DOWN1 && cnt == 0) begin down1 = 0; isBreak = 0; end
        if (datacur[8:1] == LEFT1 && cnt == 0) begin left1 = 0; isBreak = 0; end
        if (datacur[8:1] == RIGHT1 && cnt == 0) begin right1 = 0; isBreak = 0; end
        if (datacur[8:1] == FIRE1 && cnt == 0) begin fire1 = 0; isBreak = 0; end
        // 2nd player
        if (datacur[8:1] == UP2 && cnt == 0) begin up2 = 0; isBreak = 0; end
        if (datacur[8:1] == DOWN2 && cnt == 0) begin down2 = 0; isBreak = 0; end
        if (datacur[8:1] == LEFT2 && cnt == 0) begin left2 = 0; isBreak = 0; end
        if (datacur[8:1] == RIGHT2 && cnt == 0) begin right2 = 0; isBreak = 0; end
        if (datacur[8:1] == FIRE2 && cnt == 0) begin fire2 = 0; isBreak = 0; end
        // Yes/No button
        if (datacur[8:1] == YES && cnt == 0) begin yes = 0; isBreak = 0; end
        if (datacur[8:1] == NO && cnt == 0) begin no = 0; isBreak = 0; end
     end
     else begin
        datacur[cnt] = kdataf; cnt = cnt + 1; if(cnt ==11) cnt = 0;
        // 1st player
        if (datacur[8:1] == UP1 && cnt == 0) up1 = 1; 
        if (datacur[8:1] == DOWN1 && cnt == 0) down1 = 1;
        if (datacur[8:1] == LEFT1 && cnt == 0) left1 = 1;
        if (datacur[8:1] == RIGHT1 && cnt == 0) right1 = 1;
        if (datacur[8:1] == FIRE1 && cnt == 0) fire1 = 1;
        // 2nd player
        if (datacur[8:1] == UP2 && cnt == 0) up2 = 1; 
        if (datacur[8:1] == DOWN2 && cnt == 0) down2 = 1;
        if (datacur[8:1] == LEFT2 && cnt == 0) left2 = 1;
        if (datacur[8:1] == RIGHT2 && cnt == 0) right2 = 1;
        if (datacur[8:1] == FIRE2 && cnt == 0) fire2 = 1;  
        // YES/NO button
        if (datacur[8:1] == YES && cnt == 0) yes = 1; 
        if (datacur[8:1] == NO && cnt == 0) no = 1; 
        if (datacur[8:1] == 8'hF0) isBreak = 1;
     end
end
    
    
endmodule
