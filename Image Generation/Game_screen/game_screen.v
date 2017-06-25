///////////////////////////////////////////////////////////////////////////////////////////
// game_screen.v -  module for the game screen display logic
//
// Copyright - Mark Chernishoff, Hai Dang, Aditya Pawar
//
// Date: Nov, 2016
//
// ECE 540 SoC with FPGA
//
// Final Project: Battle Tanks
//
// Description:
// ------------
// This Module contains logic for displaying the Game screen, both red and green tanks, and bullets. 
// This also keeps track of tank and bullet orientation and location. 
//
// output background, red tank, green tank, red bullet, green bullet, explosion
// 
// ouputs player_screen = 01 -> output 1st player wins
// outputs player_screen = 10 -> output 2nd player wins
// output explosion_act to AudioInterface
// outputs red_score and green_score to SSD
//////////////////////////////////////////////////////////////////////////////////////////
module game_screen (first_screen_out,pPixel_row,pPixel_column,pClk,pClk2,pReset,btns,sw,player_screen,
                    red_score,green_score,reset_plyrScrn,explosion_act);

input               pClk; //100Mhz
input               pClk2; //44.9 Mhzinput  pReset; 
input       [10:0]  pPixel_row; //from DTG
input       [10:0]  pPixel_column; //From DTG
input               pReset;

output  reg [11:0]  first_screen_out = 12'd0;       // output data to colorizer
input       [4:0]   btns;                           // input to control red tank
input       [4:0]   sw;                             // input to control green tank
output  reg [1:0]   player_screen;                  // output to switch interface: outputs 2'd2 if red player wins and 2'd1 if green wins
output  reg [1:0]   red_score;                      // outputs red score to 7 SD
output  reg [1:0]   green_score;                    // outputs green score to 7 SD
input               reset_plyrScrn;                 // input from Switch interface that screen has changed, reset player_screen to 0
output  reg         explosion_act;                  // output to sound, explosion is active: 1'd1 is active explosion, 1'd0 is no explosion
wire        [10:0]  pixel_row_B,pixel_column_B;     // scalar for input from dtg
reg                 aReset;                         // reset synchronizer
reg                 bReset;                         // reset synchronizer


//Zooming for background from 128x96 to 1024x768
assign pixel_row_B =  pPixel_row [10:1];
assign pixel_column_B =  pPixel_column [10:1];

// starting locations
reg         [9:0]   tank_start_locX;                          // red tank locations
reg         [9:0]   tank_start_locY;

reg         [9:0]   green_tank_locX;                          // green tank locations
reg         [9:0]   green_tank_locY;

parameter integer   FLAG_CNT = 500000;                      // speed for tank. Less is faster
reg	        [20:0]  flag_count;                             // counter for tank movement
reg			        flag;                                   // tank can only move if flag is set high

reg         [20:0]  explosion_cnt;
reg                 explosion_flag;
reg         [20:0]  green_explosion_cnt;
reg                 red_explosion_ack;
reg                 green_explosion_ack;



parameter integer   BULLET_CNT = 100000;                    // speed for bullet. Less is faster
reg	        [19:0]  bullet_count;                           // counter for bullet movement
reg			        bullet_flag;                            // only changes bullet location if flag is high
reg         [1:0]	red_bullet_orient;                      // save bullet orientation when fired from tank
reg         [9:0]	red_bullet_locX;                        // red tanks bullet location
reg         [9:0]	red_bullet_locY;                
reg                 red_bullet_act;                         // active until it hits wall or opposing player


reg         [1:0]	green_bullet_orient;
reg         [9:0]	green_bullet_locX;
reg         [9:0]	green_bullet_locY;
reg                 green_bullet_act;


/////////////////////// address and data registers for green tank bullets and red tank bullets///////////////////////////
reg         [6:0]   greenbullet_up_addr;
reg         [6:0]   bullet_up_addr;
wire        [11:0]  bullet_up_dataOut;

reg         [6:0]   greenbullet_down_addr;
reg         [6:0]   bullet_down_addr;
wire        [11:0]  bullet_down_dataOut;

reg         [6:0]   greenbullet_left_addr;
reg         [6:0]   bullet_left_addr;
wire        [11:0]  bullet_left_dataOut;

reg         [6:0]   greenbullet_right_addr;
reg         [6:0]   bullet_right_addr;
wire        [11:0]  bullet_right_dataOut;

reg         [1:0]   redtank_orient;
reg         [1:0]   greentank_orient;

reg                 green_stop;
reg                 red_stop;



//Address to be passed to the Block RAM
reg         [17:0] rAddr_first = 18'd0;
wire        [11:0] rDout_first;

// addr and data for up
reg         [9:0]   up_addr = 10'd0;
wire        [11:0]  up_dataOut;

// addr and data for down

reg         [9:0]   greenup_addr = 10'd0;
wire        [11:0]  greenup_dataOut;

// addr and data for left

reg         [9:0]   left_addr = 10'd0;
wire        [11:0]  left_dataOut;

// addr and data for down

reg         [9:0]   greenleft_addr = 10'd0;
wire        [11:0]  greenleft_dataOut;

// wires for keyboard button presses
wire        [4:0]   UP, DOWN, LEFT, RIGHT, CENTER;
wire        [1:0]   ICON_UP, ICON_DOWN, ICON_LEFT, ICON_RIGHT;

// address and data for red tank explosion icon
reg         [9:0]   explosion_addr = 10'd0;
wire        [11:0]  explosion_dataOut;

// address and data for tank explosion icon
reg         [9:0]   green_explosion_addr = 10'd0;
wire        [11:0]  green_explosion_dataOut;


// Block ROM to store the image information of background
blk_mem_gen_1 first_page (
  .clka(pClk2),    // input wire clka
  .addra(rAddr_first),  // input wire [13 : 0] addra
  .douta(rDout_first)
);


// Block Rom for tank up position

blk_mem_gen_4 redup1(
  .clka(pClk2),    // input wire clka
  .addra(up_addr),  // input wire [9 : 0] addra
  .douta(up_dataOut)  // output wire [11 : 0] douta
);

// tank down position
blk_mem_gen_5 greenup(
  .clka(pClk2),    // input wire clka
  .addra(greenup_addr),  // input wire [9 : 0] addra
  .douta(greenup_dataOut)  // output wire [11 : 0] douta
);

// tank left position
blk_mem_gen_6 redleft1(
  .clka(pClk2),    // input wire clka
  .addra(left_addr),  // input wire [9 : 0] addra
  .douta(left_dataOut)  // output wire [11 : 0] douta
);

// tank right position
blk_mem_gen_7 greenleft(
  .clka(pClk2),    // input wire clka
  .addra(greenleft_addr),  // input wire [9 : 0] addra
  .douta(greenleft_dataOut)  // output wire [11 : 0] douta
);

blk_mem_gen_8 red_bullet_up(
  .clka(pClk2),    // input wire clka
  .addra( bullet_up_addr),  // input wire [9 : 0] addra
  .douta( bullet_up_dataOut)  // output wire [11 : 0] douta
);

blk_mem_gen_9 red_bullet_down(
  .clka(pClk2),    // input wire clka
  .addra( greenbullet_down_addr),  // input wire [9 : 0] addra
  .douta( bullet_down_dataOut)  // output wire [11 : 0] douta
);

blk_mem_gen_10 red_bullet_left(
  .clka(pClk2),    // input wire clka
  .addra( bullet_left_addr),  // input wire [9 : 0] addra
  .douta( bullet_left_dataOut)  // output wire [11 : 0] douta
);

blk_mem_gen_11 red_bullet_right(
  .clka(pClk2),    // input wire clka
  .addra( bullet_right_addr),  // input wire [9 : 0] addra
  .douta( bullet_right_dataOut)  // output wire [11 : 0] douta
);

blk_mem_gen_12 explosion(
  .clka(pClk2),    // input wire clka
  .addra( explosion_addr),  // input wire [9 : 0] addra
  .douta( explosion_dataOut)  // output wire [11 : 0] douta
);

blk_mem_gen_12 greenexplosion(
  .clka(pClk2),    // input wire clka
  .addra( green_explosion_addr),  // input wire [9 : 0] addra
  .douta( green_explosion_dataOut)  // output wire [11 : 0] douta
);

////////////////// used to assign bullet and tank orientations////////////////////////
assign  DOWN    = 5'b00001;                 
assign  RIGHT   = 5'b00010;
assign  UP      = 5'b00100;
assign  LEFT    = 5'b01000;
assign  CENTER  = 5'b10000;

assign  ICON_UP     = 2'b00;                
assign  ICON_DOWN   = 2'b01;
assign  ICON_LEFT   = 2'b10;
assign  ICON_RIGHT  = 2'b11;

///////////////////////// reset synchronizer /////////////////////////////////////////

always @ (posedge pClk2)            
    begin
        aReset <= pReset;
        bReset <= aReset;
    end

///////////////////////// setting tank and bullet orientations///////////////////////

always @ (posedge pClk2)
begin
if (bReset) redtank_orient <= UP;

else if 	(red_bullet_act && btns[4] == 1'd1)
    begin
        case (redtank_orient) 
            ICON_DOWN:	red_bullet_orient <= ICON_DOWN;	
            ICON_UP:		red_bullet_orient <= ICON_UP;
            ICON_LEFT:	red_bullet_orient <= ICON_LEFT;
            ICON_RIGHT:	red_bullet_orient <= ICON_RIGHT;
            default:red_bullet_orient <= red_bullet_orient;
        endcase
    end
else
    begin
        case (btns)
        DOWN: redtank_orient <= ICON_DOWN;
        RIGHT:  redtank_orient <= ICON_RIGHT;
        UP:     redtank_orient <= ICON_UP;
        LEFT:   redtank_orient <= ICON_LEFT;
        default: redtank_orient <= redtank_orient;
        endcase
   
    end
    
if (bReset) greentank_orient <= UP;
    
    else if     (green_bullet_act && sw[4] == 1'd1)
        begin
            case (greentank_orient) 
                ICON_DOWN:    green_bullet_orient <= ICON_DOWN;    
                ICON_UP:        green_bullet_orient <= ICON_UP;
                ICON_LEFT:    green_bullet_orient <= ICON_LEFT;
                ICON_RIGHT:    green_bullet_orient <= ICON_RIGHT;
                default:green_bullet_orient <= green_bullet_orient;
            endcase
        end
    else
        begin
            case (sw)
            DOWN: greentank_orient <= ICON_DOWN;
            RIGHT:  greentank_orient <= ICON_RIGHT;
            UP:     greentank_orient <= ICON_UP;
            LEFT:   greentank_orient <= ICON_LEFT;
            default: greentank_orient <= greentank_orient;
            endcase
       
        end
end
/////////////////////////////////////////////////////////////////////////////////////
//////////////////////this outputs either tank or background data///////////////////

always @(posedge pClk2)begin
    if (bReset) begin
            first_screen_out <= 12'd0;
            rAddr_first <= 18'd0;       
        end
    
    else
        begin
            //Where ever is the pixel pointer, print the background to screen.
            rAddr_first   <= {pixel_row_B[8:0],pixel_column_B[8:0]};;
            first_screen_out  <= rDout_first;
        end 
        
  if (bReset) begin
                up_addr <=  10'd0;
                left_addr <= 10'd0;
                end
                
//////////////// If green bullet hits red tank output explosion///////////////////////////////////////                
           else if ((green_bullet_locX >= tank_start_locX) && ( green_bullet_locX <= (tank_start_locX+ 10'd31)) && 
                (green_bullet_locY >= tank_start_locY) && ( green_bullet_locY <= (tank_start_locY+ 10'd31)) &&
                (pPixel_row >= tank_start_locX ) && ( pPixel_row <= (tank_start_locX + 10'd31)) && 
                (pPixel_column >= tank_start_locY ) && ( pPixel_column <= (tank_start_locY + 10'd31)))
                    begin
                               explosion_addr <= explosion_addr + 1'd1;             // address for explosion BROM
                               first_screen_out <= explosion_dataOut;               // data in explosion BROM
                               green_explosion_cnt <= green_explosion_cnt + 1'd1;   // counter length of time to display explosion
                               explosion_act <= 1'd1;                               // explosion active, used to produce sound
                    end
            
/////////////// when counter reaches 60000, increment score            
           else if (green_explosion_cnt >= 19'd60000)
                begin
                    green_score <= green_score + 1'd1;
                    green_explosion_cnt <= 19'd0;
                    explosion_flag <= 1'd1;                                         // flag used to reset player locations
                    explosion_act <= 1'd0;                                          // stop outputting explosion sound
                end
///////////// when green tank reaches 3 hits, output player 1 wins//////////////
           else if (green_score == 2'd3)
                begin
                    player_screen <= 2'b01;
                    green_score <= 1'd0;
                end
        
////////// reset flag when tank locations reset/////////////////////////////////        
            else if (red_explosion_ack >= 1'd1) explosion_flag <= 1'd0;
   
//////////// reset player screen and score when screens change/////////////////   
            else if (reset_plyrScrn >= 1'd1) begin
                                        player_screen <= 2'b00;
                                        green_score <= 1'd0;
                                    end
   
   else begin
           
/////////// this displays red tank orientation ///////////////////////////////
           case (redtank_orient)
           
            ICON_UP:  if ((pPixel_row == tank_start_locX) && (pPixel_column == tank_start_locY)) 
                        begin
                         up_addr <=10'd0;                       // reset addresses
                         explosion_addr <= 10'd0;
                         end
                       else if ((pPixel_row >= tank_start_locX ) && ( pPixel_row <= (tank_start_locX + 10'd31)) && 
                          (pPixel_column >= tank_start_locY ) && ( pPixel_column <= (tank_start_locY + 10'd31)))
                       begin            
                               first_screen_out <= up_dataOut;   // output red tank up orientation
                               up_addr <= up_addr + 1'd1;        // increase address
                       end
            
                else begin
                        up_addr <= up_addr + 10'd0;             // if pixel location is not over tank, do nothing
                        explosion_addr <= explosion_addr;       // if not over explosion, do nothing
                    end
            ICON_DOWN: if ((pPixel_row == tank_start_locX) && (pPixel_column == tank_start_locY))
                        begin
                         up_addr <=10'd1023;                    // reset addresses                
                        explosion_addr <= 10'd0;                
                         end
             else if ((pPixel_row >= tank_start_locX ) && ( pPixel_row <= (tank_start_locX + 10'd31)) && 
                    (pPixel_column >= tank_start_locY ) && ( pPixel_column <= (tank_start_locY + 10'd31)))
                       begin 
                                first_screen_out <= up_dataOut;  // output red tank down orientation
                                up_addr <= up_addr - 1'd1;      // decrease address
                               
                       end
             
                else begin
                           up_addr <= up_addr + 10'd0;          // do nothing
                           explosion_addr <= explosion_addr;    // do nothing
                       end
            ICON_LEFT:   
                 if ((pPixel_row == tank_start_locX) && (pPixel_column == tank_start_locY)) 
                            begin
                                left_addr <=10'd0;                  // reset addresses 
                                explosion_addr <= 10'd0;
                            end
             else if ((pPixel_row >= tank_start_locX ) && ( pPixel_row <= (tank_start_locX + 10'd31)) && 
                    (pPixel_column >= tank_start_locY ) && ( pPixel_column <= (tank_start_locY + 10'd31)))
                       begin            
                               first_screen_out <= left_dataOut;    // output red tank left orientation
                               left_addr <= left_addr + 1'd1;       // increase address
                       end
            
            else begin
                            left_addr <= left_addr + 10'd0;         // do nothing
                            explosion_addr <= explosion_addr;
                    end    
            ICON_RIGHT:  
             if ((pPixel_row == tank_start_locX) && (pPixel_column == tank_start_locY)) 
                        begin
                            left_addr <=10'd1023;                   // reset addresses                  
                            explosion_addr <= 10'd0;
                        end               
             else if ((pPixel_row >= tank_start_locY ) && ( pPixel_row <= (tank_start_locY + 10'd31)) && 
                    (pPixel_column >= tank_start_locX ) && ( pPixel_column <= (tank_start_locX + 10'd31)))
                       begin 
                               first_screen_out <= left_dataOut;    // output red tank right orientation
                               left_addr <= left_addr - 1'd1;       // decrease address
                       end
            
            else begin
                    left_addr <= left_addr + 10'd0;                 // do nothing
                    explosion_addr <= explosion_addr;
                end            
            
            endcase
    
end

//////////////// start of green tank explosion output to screen /////////////////////////////////
    if (bReset) begin
            greenup_addr <= 10'd0;
            greenleft_addr <= 10'd0;
        end
//////////////// If red bullet hits green tank output explosion///////////////////////////////////////          
    else if ((red_bullet_locX >= green_tank_locX) && ( red_bullet_locX <= (green_tank_locX+ 10'd31)) && 
        (red_bullet_locY >= green_tank_locY) && ( red_bullet_locY <= (green_tank_locY+ 10'd31)) &&
        (pPixel_row >= green_tank_locX ) && ( pPixel_row <= (green_tank_locX + 10'd31)) && 
        (pPixel_column >= green_tank_locY ) && ( pPixel_column <= (green_tank_locY + 10'd31)))
            begin
                green_explosion_addr <= green_explosion_addr + 1'd1;
                first_screen_out <= green_explosion_dataOut;
                explosion_cnt <= explosion_cnt + 1'd1;                  // count to display explosion for an amount of time
                explosion_act <= 1'd1;                                  // used to output sound when exploding
            end
            
////////////////when count reaches 600000 stop displaying explosion////////////////////////////////////            
    else if (explosion_cnt >= 19'd60000)
             begin
                 red_score <= red_score + 1'd1;                         // increment red score
                 explosion_cnt <= 19'd0;
                 explosion_flag <= 1'd1;                                // flag used to reset player location
                 explosion_act <= 1'd0;                                 // stop outputting explosion sound
             end
             
/////////////// when red score reaches change screens ///////////////////////////////////////////////////
    else if (red_score == 2'd3)
             begin
                 player_screen <= 2'b10;                                // output to switch interface to display player 1 wins
                 red_score <= 1'd0;                                     // reset score
             end 
              
/////////////// this displays green tank orientation ////////////////////////////////////////////////////////   
    else if (green_explosion_ack >= 1'd1) explosion_flag <= 1'd0;
     else if (reset_plyrScrn >= 1'd1) begin                             
                player_screen <= 2'b0;                                  // reset to 0 when starting over
                red_score <= 1'd0;                                      // when reset high, reset score
              end
    else  begin
                
   
            case (greentank_orient)
           
            ICON_UP:   
            if ((pPixel_row == green_tank_locX) && (pPixel_column == green_tank_locY)) 
                    begin
                        greenup_addr <=10'd0;                           // reset address
                        green_explosion_addr <= 10'd0;
                    end
             else if ((pPixel_row >= green_tank_locX ) && ( pPixel_row <= (green_tank_locX + 10'd31)) && 
                    (pPixel_column >= green_tank_locY ) && ( pPixel_column <= (green_tank_locY + 10'd31)))
                       begin            
                               first_screen_out <= greenup_dataOut;    // output green tank up data
                               greenup_addr <= greenup_addr + 1'd1;     // increment address
                       end
            
            else begin 
                    greenup_addr <= greenup_addr + 10'd0;               // do nothing, when pixel is not over tank
                    green_explosion_addr <= green_explosion_addr;
                 end
            ICON_DOWN:
              if ((pPixel_row == green_tank_locX) && (pPixel_column == green_tank_locY))
                    begin
                     greenup_addr <=10'd1023;                           // reset address
                    green_explosion_addr <= 10'd0;
                    end                
             else if ((pPixel_row >= green_tank_locX ) && ( pPixel_row <= (green_tank_locX + 10'd31)) && 
                    (pPixel_column >= green_tank_locY ) && ( pPixel_column <= (green_tank_locY + 10'd31)))
                       begin 
                                first_screen_out <= greenup_dataOut;        // output green tank down data
                                greenup_addr <= greenup_addr - 1'd1;        // deccrement address
                               
                       end
             
            else begin 
                   greenup_addr <= greenup_addr + 10'd0;                    // do nothing
                   green_explosion_addr <= green_explosion_addr;
                end
            ICON_LEFT:   
             if ((pPixel_row == green_tank_locX) && (pPixel_column == green_tank_locY)) 
                    begin
                        greenleft_addr <=10'd0;                             // reset address       
                        green_explosion_addr <= 10'd0;
                        end                  
             
             else if ((pPixel_row >= green_tank_locX ) && ( pPixel_row <= (green_tank_locX + 10'd31)) && 
                    (pPixel_column >= green_tank_locY ) && ( pPixel_column <= (green_tank_locY + 10'd31)))
                       begin            
                               first_screen_out <= greenleft_dataOut;           // output green tank left data         
                               greenleft_addr <= greenleft_addr + 1'd1;
                       end
            
            else 
                begin
                    greenleft_addr <= greenleft_addr + 10'd0;                    // do nothing
                   green_explosion_addr <= green_explosion_addr;
                 end            
            ICON_RIGHT:
             if ((pPixel_row == green_tank_locX) && (pPixel_column == green_tank_locY))
                begin
                    greenleft_addr <=10'd1023;                                  // reset address 
                    green_explosion_addr <= 10'd0;
                end              
             else if ((pPixel_row >= green_tank_locX ) && ( pPixel_row <= (green_tank_locX + 10'd31)) && 
                    (pPixel_column >= green_tank_locY ) && ( pPixel_column <= (green_tank_locY + 10'd31)))
                       begin   
                               first_screen_out <= greenleft_dataOut;           // output green tank right data
                               greenleft_addr <= greenleft_addr - 1'd1;
                       end
                    
            else begin
                   greenleft_addr <= greenleft_addr + 10'd0;                    // do nothing
                  green_explosion_addr <= green_explosion_addr;
                end
            endcase    
    end
    
//////////////// outputs red bullet info ///////////////////////////////////////////////////////////////////////////    
if (red_bullet_act == 1'd1)
        begin
            case (red_bullet_orient)
           
                ICON_UP:   
                    if ((pPixel_row == green_tank_locX) && (pPixel_column == green_tank_locY)) bullet_up_addr <= 7'd120;    // reset bullet address
                    else if ((pPixel_row >= red_bullet_locX ) && ( pPixel_row <= (red_bullet_locX + 10'd14)) && 
                    (pPixel_column >= red_bullet_locY ) && ( pPixel_column <= (red_bullet_locY + 10'd7)))
                       begin            
                           first_screen_out <= bullet_up_dataOut;                       // output bullet up data
                           bullet_up_addr <= bullet_up_addr - 1'd1;
                       end
                    else bullet_up_addr <= bullet_up_addr + 10'd0;                      // do nothing
                
                ICON_DOWN:   
                    if ((pPixel_row == green_tank_locX) && (pPixel_column == green_tank_locY)) bullet_up_addr <= 7'd0;     // reset bullet address     
                    else if ((pPixel_row >= red_bullet_locX ) && ( pPixel_row <= (red_bullet_locX + 10'd14)) && 
                        (pPixel_column >= red_bullet_locY ) && ( pPixel_column <= (red_bullet_locY + 10'd7)))
                           begin            
                               first_screen_out <= bullet_up_dataOut;                   // output bullet down data
                               bullet_up_addr <= bullet_up_addr + 1'd1;
                           end
                    else bullet_up_addr <= bullet_up_addr + 10'd0;                       // do nothing
                
                ICON_LEFT:   
                 if ((pPixel_row == green_tank_locX) && (pPixel_column == green_tank_locY)) bullet_left_addr <= 7'd120;     // reset bullet address
                 else if ((pPixel_row >= red_bullet_locX ) && ( pPixel_row <= (red_bullet_locX + 10'd7)) && 
                    (pPixel_column >= red_bullet_locY ) && ( pPixel_column <= (red_bullet_locY + 10'd14)))
                       begin            
                           first_screen_out <= bullet_left_dataOut;                     // output bullet left data
                           bullet_left_addr <= bullet_left_addr - 1'd1;
                       end
                else bullet_left_addr <= bullet_left_addr + 10'd0;                      // do nothing
                
                ICON_RIGHT:   
                 if ((pPixel_row == green_tank_locX) && (pPixel_column == green_tank_locY)) bullet_left_addr <= 7'd0;       // reset bullet address
                 else if ((pPixel_row >= red_bullet_locX ) && ( pPixel_row <= (red_bullet_locX + 10'd7)) && 
                    (pPixel_column >= red_bullet_locY ) && ( pPixel_column <= (red_bullet_locY + 10'd14)))
                       begin            
                           first_screen_out <= bullet_left_dataOut;                     // output bullet right data
                           bullet_left_addr <= bullet_left_addr + 1'd1;
                       end
                else bullet_left_addr <= bullet_left_addr + 10'd0;                      // do nothing
            endcase
        end
    else begin
            bullet_left_addr <= bullet_left_addr;                                       // do nothing
            bullet_up_addr <= bullet_up_addr ;
        end   

//////////////// outputs green bullet info ///////////////////////////////////////////////////////////////////////////           
    if (green_bullet_act == 1'd1)
                begin
                    case (green_bullet_orient)
                   
                        ICON_UP:   
                         if ((pPixel_row == green_tank_locX) && (pPixel_column == green_tank_locY)) greenbullet_down_addr <= 7'd120;    // reset bullet address
                         else if ((pPixel_row >= green_bullet_locX ) && ( pPixel_row <= (green_bullet_locX + 10'd14)) && 
                            (pPixel_column >= green_bullet_locY ) && ( pPixel_column <= (green_bullet_locY + 10'd7)))
                               begin            
                                   first_screen_out <= bullet_down_dataOut;                                 // output bullet up data
                                   greenbullet_down_addr <= greenbullet_down_addr - 1'd1;
                               end
                        else greenbullet_down_addr <= greenbullet_down_addr + 10'd0;                        // do nothing
                        
                        ICON_DOWN:   
                         if ((pPixel_row == green_tank_locX) && (pPixel_column == green_tank_locY)) greenbullet_down_addr <= 7'd0;      // reset bullet address
                         else if ((pPixel_row >= green_bullet_locX ) && ( pPixel_row <= (green_bullet_locX + 10'd14)) && 
                            (pPixel_column >= green_bullet_locY ) && ( pPixel_column <= (green_bullet_locY + 10'd7)))
                               begin            
                                   first_screen_out <= bullet_down_dataOut;
                                   greenbullet_down_addr <= greenbullet_down_addr + 1'd1;                   // output bullet down data
                               end
                        else greenbullet_down_addr <= greenbullet_down_addr + 10'd0;                        // do nothing
                        
                        ICON_LEFT:   
                         if ((pPixel_row == green_tank_locX) && (pPixel_column == green_tank_locY)) bullet_right_addr <= 7'd120;        // reset bullet address
                         else if ((pPixel_row >= green_bullet_locX ) && ( pPixel_row <= (green_bullet_locX + 10'd7)) && 
                            (pPixel_column >= green_bullet_locY ) && ( pPixel_column <= (green_bullet_locY + 10'd14)))
                               begin            
                                   first_screen_out <= bullet_right_dataOut;                                // output bullet left data
                                   bullet_right_addr <= bullet_right_addr - 1'd1;
                               end
                        else bullet_right_addr <= bullet_right_addr;                                        // do nothing
                        
                        ICON_RIGHT:   
                         if ((pPixel_row == green_tank_locX) && (pPixel_column == green_tank_locY)) bullet_right_addr <= 7'd0;          // reset bullet address
                         else if ((pPixel_row >= green_bullet_locX ) && ( pPixel_row <= (green_bullet_locX + 10'd7)) && 
                            (pPixel_column >= green_bullet_locY ) && ( pPixel_column <= (green_bullet_locY + 10'd14)))
                               begin            
                                   first_screen_out <= bullet_right_dataOut;                                // output bullet right data
                                   bullet_right_addr <= bullet_right_addr + 1'd1;
                               end
                        else bullet_right_addr <= bullet_right_addr + 10'd0;                            
    // do nothing
                    endcase
                end
            else begin
                    bullet_right_addr <= bullet_right_addr;                                                 // do nothing
                    greenbullet_down_addr <=greenbullet_down_addr ;
                end  
end

//////////////////////////// red tank and bullet location ///////////////////////////////////////////////////////////////
always@(posedge pClk2) begin
	if (bReset)
		begin
			tank_start_locX <= 10'd60;                   // reset red tank location  
			tank_start_locY <= 10'd60;

		end
	
	else if ( explosion_flag >= 1'd1)                  // if explosion set, reset red tank location
	   begin
	       red_explosion_ack <= 1'd1;                  // used to reset explosion flag
	       tank_start_locX <= 10'd60;                  // reset red tank location  
           tank_start_locY <= 10'd60;
           
	   end
	else if ( rDout_first != 12'd4095 && (pPixel_row >= tank_start_locX ) && ( pPixel_row <= (tank_start_locX + 10'd31)) && 
                                          (pPixel_column >= tank_start_locY ) && ( pPixel_column <= (tank_start_locY + 10'd31)))
                     begin
                          red_stop <= 1'd1;             // if at wall stop the movement of tank
                      end
	else if ((flag > 0) )          // changing red tank location when button pushed and flag is set high
		begin
			if (red_stop == 1'd0)                    
                begin
                    case (btns)         // change tank location if buttons pressed
                        UP:		tank_start_locX <= tank_start_locX - 1'd1;             
                        DOWN:	tank_start_locX <= tank_start_locX + 1'd1;
                        LEFT:	tank_start_locY <= tank_start_locY - 1'd1;
                        RIGHT:	tank_start_locY <= tank_start_locY + 1'd1;
                        default:	begin
                                        tank_start_locY <= tank_start_locY;
                                        tank_start_locX <= tank_start_locX;
                                    end
			         endcase
			    end
			else if (red_stop >= 1'd1)       // stop is set high, reverse 1 location and clear the stop
			     begin
			     red_stop <= 1'd0;           // clear the stop flag
			         case (btns)
                         UP:        tank_start_locX <= tank_start_locX + 1'd1;             
                         DOWN:      tank_start_locX <= tank_start_locX - 1'd1;
                         LEFT:      tank_start_locY <= tank_start_locY + 1'd1;
                         RIGHT:     tank_start_locY <= tank_start_locY - 1'd1;
                         default:    begin
                                         tank_start_locY <= tank_start_locY;
                                         tank_start_locX <= tank_start_locX;
                                     end
                      endcase
			     end
			else begin
			         tank_start_locX <= tank_start_locX;
                     tank_start_locY <= tank_start_locY;
                     red_stop <= 1'd0;
			     end
		
	   end
	                    
	else
		begin
			tank_start_locX <= tank_start_locX;
			tank_start_locY <= tank_start_locY;
			red_explosion_ack <= 1'd0;                   // clear acknowledge flag
		end
////////////////////// changes red bullet location ////////////////////////////////////////////////	
	if (bReset)
		begin
			red_bullet_act <= 0;
			red_bullet_locY <= 10'd0;                    // reset bullet location
			red_bullet_locX <= 10'd0;
		end
    else if (explosion_flag >= 1'd1)                    // if hit opposing player, reset bullet location
        begin 
           red_explosion_ack <= 1'd1;                    
           red_bullet_locY <= 10'd0;
           red_bullet_locX <= 10'd0;
        end 	
	else if (btns[4] == 1'd1)                          // fire button hit
		begin
			red_bullet_act <= 1'd1;                          //  activate bullet
			red_bullet_locY <= tank_start_locY + 4'd15;      //  assign starting bullet location
			red_bullet_locX <= tank_start_locX + 4'd15;
		end
	else if ((red_bullet_act == 1'd1) && (bullet_flag > 0))    // only increment bullet location if flag is high and is active
		begin
			case (red_bullet_orient)         // increment X Y location based on orientation 
				ICON_UP:			red_bullet_locX <= red_bullet_locX - 1'd1;	
				ICON_DOWN:		    red_bullet_locX <= red_bullet_locX + 1'd1;
				ICON_LEFT:		    red_bullet_locY <= red_bullet_locY - 1'd1;
				ICON_RIGHT:		   red_bullet_locY <= red_bullet_locY + 1'd1;
				default:	begin
								    red_bullet_locY <= red_bullet_locY;
								    red_bullet_locX <= red_bullet_locX;
							end
			endcase
		end
	else if ((rDout_first != 12'd4095) && ( pPixel_row == (red_bullet_locX + 10'd4)) && // if bullet hits wall
				 ( pPixel_column == (red_bullet_locY + 10'd7)))
			begin
				red_bullet_act <= 1'd0;                     // deactivate bullet and reset location
				red_bullet_locY <= 10'd0;
                red_bullet_locX <= 10'd0;
			end
	else if ((red_bullet_locX >= green_tank_locX) && ( red_bullet_locX <= (green_tank_locX+ 10'd31)) &&    // if bullet hits opposing player
            (red_bullet_locY >= green_tank_locY) && ( red_bullet_locY <= (green_tank_locY+ 10'd31)))
                 red_bullet_act <= 1'd0;   		           // deactivate bullet
	else begin
			red_bullet_locY <= red_bullet_locY;
			red_bullet_locX <= red_bullet_locX;
			red_explosion_ack <= 1'd0;
		end
end


//////////////////////////////////// green tank and bullet location //////////////////////////////////////////
always @ (posedge pClk2)
    begin		
	if (bReset)
                begin
                    green_tank_locX <= 10'd560;             // reset green tank starting location
                    green_tank_locY <= 10'd560;         
                end
            else if (explosion_flag >= 1'd1)                // if tank hit reset starting location
               begin 
                    green_explosion_ack <= 1'd1;                  
                   green_tank_locX <= 10'd560;
                   green_tank_locY <= 10'd560;
                   
               end 
               
///////////////////// if at wall move back to tank back to original position ///////////////////////////////
            else if (rDout_first != 12'd4095 &&  (pPixel_row >= green_tank_locX ) && ( pPixel_row <= (green_tank_locX + 10'd31)) && 
                           (pPixel_column >= green_tank_locY ) && ( pPixel_column <= (green_tank_locY + 10'd31)))
                     begin
                        green_stop <= 1'd1;             // stop tank from moving if at wall
                     end  
            else if (flag > 0)              // changing green tank location when button pushed
                begin
                    if (green_stop == 1'd0)
                        begin
                            case (sw)
                                UP:         green_tank_locX <= green_tank_locX - 1'd1;
                                DOWN:       green_tank_locX <= green_tank_locX + 1'd1;
                                LEFT:       green_tank_locY <= green_tank_locY - 1'd1;
                                RIGHT:      green_tank_locY <= green_tank_locY + 1'd1;
                                default:    begin
                                                green_tank_locY <= green_tank_locY;
                                                green_tank_locX <= green_tank_locX;
                                            end
                            endcase
                        end
                        
                    else if (green_stop >= 1'd1) // if at wall
                        begin
                            green_stop <= 1'd0;
                            case (sw)           // decrease 1 location 
                                UP:         green_tank_locX <= green_tank_locX + 1'd1;
                                DOWN:       green_tank_locX <= green_tank_locX - 1'd1;
                                LEFT:       green_tank_locY <= green_tank_locY + 1'd1;
                                RIGHT:      green_tank_locY <= green_tank_locY - 1'd1;
                                default:    begin
                                                green_tank_locY <= green_tank_locY;
                                                green_tank_locX <= green_tank_locX;
                                            end
                            endcase
                        end
                    else begin
                            green_tank_locY <= green_tank_locY;
                            green_tank_locX <= green_tank_locX;
                            green_stop <= 1'd0;
                         end
                end
             
            else
                begin
                    green_tank_locX <= green_tank_locX;
                    green_tank_locY <= green_tank_locY;
                    green_explosion_ack <= 1'd0;                    // reset explosion acknowledge
                    
                end

///////////////////////////////// green tank bullet update ///////////////////////////////////////////           
            if (bReset)
                begin
                    green_bullet_act <= 0;                          // reset bullet if reset button pressed
                    green_bullet_locY <= 10'd0;
                    green_bullet_locX <= 10'd0;
                end
            else if (explosion_flag >= 1'd1)                        // if tank hit, reset bullet location
                begin   
                   green_explosion_ack <= 1'd1;                  
                   green_bullet_locY <= 10'd0;
                   green_bullet_locX <= 10'd0;
                end   
            else if (sw[4] == 1'd1)   // fire bullet button pressed
                begin
                    green_bullet_act <= 1'd1;                       // activate green bullet
                    green_bullet_locY <= green_tank_locY + 4'd15;   // assign bullet starting location
                    green_bullet_locX <= green_tank_locX + 4'd15;
                end
            else if ((green_bullet_act == 1'd1) && (bullet_flag > 0)) // if bullet active and flag is set, change green bullet location
                begin
                    case (green_bullet_orient)
                        ICON_UP:            green_bullet_locX <= green_bullet_locX - 1'd1;    
                        ICON_DOWN:          green_bullet_locX <= green_bullet_locX + 1'd1;
                        ICON_LEFT:          green_bullet_locY <= green_bullet_locY - 1'd1;
                        ICON_RIGHT:         green_bullet_locY <= green_bullet_locY + 1'd1;
                        default:    begin
                                        green_bullet_locY <= green_bullet_locY;
                                        green_bullet_locX <= green_bullet_locX;
                                    end
                    endcase
                end
            else if ((rDout_first != 12'd4095) && ( pPixel_row == (green_bullet_locX + 10'd4)) && // bullet hits wall
                        ( pPixel_column == (green_bullet_locY + 10'd7)))
                    begin
                        green_bullet_act <= 1'd0;                       // deactivate bullet
                        green_bullet_locY <= 10'd0;                     // reset bullet location
                        green_bullet_locX <= 10'd0;
                    end
           else if ((green_bullet_locX >= tank_start_locX) && ( green_bullet_locX <= (tank_start_locX+ 10'd31)) && 
                    (green_bullet_locY >= tank_start_locY) && ( green_bullet_locY <= (tank_start_locY+ 10'd31)))
                         green_bullet_act <= 1'd0;                      // deactivat bullet if bullet hits opposing player        
            else begin
                    green_bullet_locY <= green_bullet_locY;
                    green_bullet_locX <= green_bullet_locX;
                    green_explosion_ack <= 1'd0;
                end
end	


/////////////////// Flags are used to control the speed of incrementing tanks and bullet movement ////////////////////////////////
always@(posedge pClk2) begin
	if (bReset)
		begin
			flag_count <= 0;
			flag <= 1'd0;
		end

//////////////////////////// counter for tank movement ////////////////////////	
	else if (flag_count == FLAG_CNT)
		begin
			flag <= 1'd1;
			flag_count <= 0;
		end
	else 
		begin
			flag_count <= flag_count + 1;
			flag <= 1'd0;
		end

//////////////////////////// counter for bullet movement ////////////////////////			
	if (bReset)
		begin
			bullet_count <= 0;
			bullet_flag <= 1'd0;
		end
	else if (bullet_count == BULLET_CNT)
		begin
			bullet_flag <= 1'd1;
			bullet_count <= 0;
		end
	else 
		begin
			bullet_count <= bullet_count + 1;
			bullet_flag <= 1'd0;
		end
		
   
end
endmodule