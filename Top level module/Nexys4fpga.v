`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Hai Dang Hoang
// Engineer: Mark Chernishoff
// Engineer: Aditya Pawar
// Email: danghai@pdx.edu
// Create Date: 11/26/2016 04:12:03 AM
// Design Name: 
// Module Name: Nexys4fpga
// Project Name: Battle tank game
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments: The top module consist the instantiations of all the modules
//						used in the project. 
// 


//////////////////////////////////////////////////////////////////////////////////


module Nexys4fpga(
    ///////////////////////////////////////////////////////////////////////////
	// Port Declarations
	///////////////////////////////////////////////////////////////////////////
	// System Connections
	input			clk,           // 100 MHz clock from on-board oscillator
	output	[7:0]	JA,			   // JA Header
	input			btnCpuReset,   // Red pushbutton
	
	// On-Board Display Connections
	output			dp,           
	output	[6:0]	seg,           // Seven segment dis
	output	[7:0]	an,            // Seven segment display anode pins
	output	[15:0]	led,           // LED outputs
	
	// Buttons & Switches
	input			btnL, btnU,
					btnR, btnD,
					btnC, 
	input	[15:0]	sw,
	input              PS2_CLK,
    input              PS2_DATA,
    output AUD_PWM,         // Audion PWM output
    output AUD_SD,           // Audio Shutdowm control output 
	// VGA Display Connections
	output	[3:0]	vga_red,
	output	[3:0]	vga_green,
	output	[3:0]	vga_blue,
	output			vga_vsync,
	output			vga_hsync
);
	// System Level connections
	wire			sysreset;
	
	wire            explosion_act;                 // wire to connect active explosion to sound
	
	// parameter
	parameter SIMULATE = 0;
	parameter integer CLK_FREQUENCY_HZ = 100000000;
	parameter integer UPDATE_FREQUENCY_45 = 44900000;
	parameter integer UPDATE_FREQUENCY_8KHZ  = 8000;        // 8KHZ clock for sampling the audio
	parameter integer CNTR_WIDTH = 32;
	
	///// KEYBOARD //////
	reg clk_50 = 0;
	wire    up1,down1,left1,right1,fire1;
    wire    up2,down2,left2,right2,fire2; 
	wire    no,yes;    // no --> 'N buttons'
	                   // yes --> "Y buttons'
        always @(posedge clk) begin
           clk_50 <= ~clk_50;
        end
        keyboard key1 (.clk(clk_50),
                       .kclk (PS2_CLK),
                       .kdata (PS2_DATA),
                       .yes(yes), .no(no),
                       .up1(up1), .down1(down1), .left1(left1), .right1(right1), .fire1(fire1),
                       .up2(up2), .down2(down2), .left2(left2), .right2(right2), .fire2(fire2));
     
	/////END KEYBOARD//////
	
	///// AUDIO PWM/////////

    
    // Count value generation for 32kHz clock frequency 
     reg            [CNTR_WIDTH-1:0]    clk_cnt_8Khz; 
     wire           [CNTR_WIDTH-1:0]    top_cnt_8Khz = ((CLK_FREQUENCY_HZ / UPDATE_FREQUENCY_8KHZ) - 1); // Count value for 8Khz clock 
     reg            tick8Khz;                // update 8Khz clock enable    
    
         
     
     always @(posedge clk) begin
         if (sysreset) begin
             clk_cnt_8Khz <= {CNTR_WIDTH{1'b0}};
         end
         
         else if (clk_cnt_8Khz == top_cnt_8Khz) begin
             tick8Khz     <= 1'b1;
             clk_cnt_8Khz <= {CNTR_WIDTH{1'b0}};
         end
         
         else begin
             tick8Khz     <= 1'b0;
             clk_cnt_8Khz <= clk_cnt_8Khz + 1'b1;
         end
     end // update clock enable
    wire [7:0]  rDout_Audio;
    assign AUD_SD = 1'b1;
    // Intial Audio part
    audio_PWM audio_PWM_module
    (
        .clk(clk), 
        .reset(sysreset),
        .music_data(rDout_Audio), 
        .PWM_out(AUD_PWM)
    );
   
	
	///// END AUDIO PWM ///////
	reg [CNTR_WIDTH-1:0] clk_cnt_25;
	wire [CNTR_WIDTH-1:0] top_cnt_25 = ((CLK_FREQUENCY_HZ / UPDATE_FREQUENCY_45) -1);
	reg tick;
	wire [1:0] player_screen;
	wire [1:0] red_score;
	wire [1:0] green_score;
	wire reset_plyrScrn;
	always @(posedge clk) begin
	   if (sysreset) begin
	       clk_cnt_25 <= {CNTR_WIDTH{1'b0}};
	   end
	   
	   else if (clk_cnt_25 == top_cnt_25) begin
	       tick <= 1'b1;
	       clk_cnt_25 <= {CNTR_WIDTH{1'b0}};
	   end
	   
	   else begin
	       tick <= 1'b0;
	       clk_cnt_25 <= clk_cnt_25 + 1'b1;
	   end
	end
					
	///////////////////////////////////////////////////////////////////////////
	// Internal Signals
	///////////////////////////////////////////////////////////////////////////
	// IO <-> RojoBot connections
	wire	[7:0]	motctl;         // Motor Control
	wire	[7:0]	locx;           // Bot location X (column) coordinate
	wire	[7:0]	locy;           // Bot location Y (row) coordinate
	wire	[7:0]	botinfo;        // Bot orientation and movement (action)
	wire	[7:0]	sensors;        // Bot sensor values
	wire	[7:0]	lmdist;         // Left motor distance counter
	wire	[7:0]	rmdist;         // Right motor distance counter
	wire			upd_sysregs;    // Sysgnal toogles roughly every 50ms whether
	                                // the Bot output registers are updated or not
	
	// IO Interface <-> processor KCPSM6
	wire	[7:0]	port_id;
	wire	[7:0]	out_port;
	wire	[7:0]	in_port;
	wire			k_write_strobe;
	wire			write_strobe;
	wire			read_strobe;
	wire			interrupt;
	wire			interrupt_ack;
					
	// IO <-> Debounce connections
	wire	[5:0]	db_btns;
	wire	[15:0]	db_sw;
			
	// IO <-> 7-seg Connections
	wire	[4:0]	Dig[7:0];
	wire	[3:0]	DPHigh;
	wire	[3:0]	DPLow;
	
	// RoboCop <-> Code Store connections
	wire	[17:0]	instruction;
	wire	[11:0]	address;
	wire			bram_enable;
	
	// RoboCop <-> System connections
	wire			rdl;
	wire			kcpsm6_sleep;

	// Display related connections
	wire			clk_25MHz;
	wire			vidOn;	
	wire	[10:0]	pixCol;
	wire	[10:0]	pixRow;
	wire	[11:0]	botIcon;
	wire	[1:0]	worldPix;

	// System Level connections
	//wire			sysreset;
	//wire			sysclk;

	wire [11:0] color_out;     // 12-bit RGB data for displaying the first screen
	wire [11:0] first_screen_out;
	wire [11:0] game_screen_out;
	wire [11:0] player1wins_out;
	wire [11:0] player2wins_out;
	wire [1:0] mode;
	
	///////////////////////////////////////////////////////////////////////////
	// Global Assigns
	///////////////////////////////////////////////////////////////////////////

	assign sysreset = !db_btns[0];			// Reset is active low!
	assign kcpsm6_reset	= sysreset | rdl;
	assign kcpsm6_sleep = 1'b0;	
	assign JA[7:0] 	= {clk,sysreset, 6'b000000};
    
    
    assign led[12]=	explosion_act;

       AudioInterface AI(
           .sw(mode),
           .explosion_act(explosion_act),
           .fire({fire1,fire2}),
           .score({red_score,green_score}),
           .tick8Khz(tick8Khz),
           .reset(sysreset),
           .audio_out(rDout_Audio),
           .clk(clk));
	
	///////////////////////////////////////////////////////////////////////////
	// Instantiate the debounce module
	///////////////////////////////////////////////////////////////////////////
	debounce #(
		.RESET_POLARITY_LOW(0),
		.SIMULATE(SIMULATE))
	DB (
		.clk(clk),	
		.pbtn_in({btnC, btnL, btnU, btnR, btnD, btnCpuReset}),
		.switch_in(sw),
		.pbtn_db(db_btns),
		.swtch_db(db_sw)
	);	
		
	///////////////////////////////////////////////////////////////////////////	
	// Instantiate the 7-segment, 8-digit display
	///////////////////////////////////////////////////////////////////////////
	sevensegment #(
		.RESET_POLARITY_LOW(0),
		.SIMULATE(SIMULATE))
		
	SSD (
		// inputs for control signals
		.d0({3'b000,red_score}),
		.d1(5'd13),
 		.d2(5'd14),
		.d3(5'd26),
		.d4({3'b000,green_score}),
		.d5(5'd29),
		.d6(5'd28),
		.d7(5'd27),
		.dp({DPHigh, DPLow}),
		.seg({dp,seg}),			
		.an(an),
		.clk(clk),
		.reset(sysreset),
		.digits_out() 
	);
	
																	
	///////////////////////////////////////////////////////////////////////////
	// Instantiate RoboCop Line Follower
	///////////////////////////////////////////////////////////////////////////

	kcpsm6 #(
		.interrupt_vector		(12'h3FF),
		.scratch_pad_memory_size(64),
		.hwbuild				(8'h00))
	RoboCop_CPU (
		.address 		(address),
		.instruction 	(instruction),
		.bram_enable 	(bram_enable),
		.port_id 		(port_id),
		.write_strobe 	(write_strobe),
		.k_write_strobe (k_write_strobe),
		.out_port 		(out_port),
		.read_strobe 	(read_strobe),
		.in_port 		(in_port),
		.interrupt 		(interrupt),
		.interrupt_ack 	(interrupt_ack),
		.reset 			(kcpsm6_reset),
		.sleep			(kcpsm6_sleep),
		.clk 			(clk)); 
	
	 switch switch1(
             .address(address), 
             .instruction(instruction), 
             .enable(bram_enable), 
             .rdl(rdl), 
             .clk(clk)
             );	

	
	Colorizer colorizer (
	   .pRed_VGA(vga_red),
	   .pGreen_VGA(vga_green),
	   .pBlue_VGA(vga_blue),
	   .pIcon(color_out),
	   .pVideo_on(vidOn),
	   .pClk(tick),
	   .pReset(sysreset)
	);
	///////////////////////////////////////////////////////////////////////////	
	// Instantiate DTG
	///////////////////////////////////////////////////////////////////////////
	dtg #(/* Keeping parameter Defaults */)
	dtg1 (
		.clock			(tick),
		.rst			(sysreset),
		.horiz_sync		(vga_hsync),
		.vert_sync		(vga_vsync),
		.video_on		(vidOn),
		.pixel_row		(pixRow), 
		.pixel_column	(pixCol));


    //////////////////////////////////////////////////
    // Background screen
    //////////////////////////////////////////////////
  
    first_screen first(
    .first_screen_out(first_screen_out),
    .pPixel_row(pixRow),
    .pPixel_column(pixCol),
    .pClk(clk),
    .pClk2(tick),
    .pReset(sysreset)  
    ); 
   
   
     game_screen game_screen1(
     .first_screen_out(game_screen_out),
     .pPixel_row(pixRow),
     .pPixel_column(pixCol),
     .pClk(clk),
     .pClk2(tick),
     .pReset(sysreset),
     .btns({fire1,left1,up1,right1,down1}),       // keyboard
     .sw({fire2,left2,up2,right2,down2}),
     /*.btns(db_btns[5:1]),                       // btns and swithces
     .sw(db_sw[15:11]),   */                      // input
     .player_screen(player_screen),             // output to switch interface: outputs 2'd2 if red player wins and 2'd1 if green wins
     .red_score(red_score),                     // output to 7 seg red score
     .green_score(green_score),                 // output to 7 seg green score
     .reset_plyrScrn(reset_plyrScrn),
     .explosion_act(explosion_act)              // output to sound, explosion is active: 1'd1 is active explosion, 1'd0 is no explosion
     ); 
     
     
  
      player1_screen player1(
         .first_screen_out(player1wins_out),
         .pPixel_row(pixRow),
         .pPixel_column(pixCol),
         .pClk(clk),
         .pClk2(tick),
         .pReset(sysreset)  
         ); 
    
    
      player2_screen player2(
           .first_screen_out(player2wins_out),
           .pPixel_row(pixRow),
           .pPixel_column(pixCol),
           .pClk(clk),
           .pClk2(tick),
           .pReset(sysreset)  
       ); 
 
    ///////////////
    SwitchInterface SI(
    .clk(clk),
    .port_id(port_id),
    .write_strobe(write_strobe),
    .out_port(out_port),
    .in_port(in_port),
    .interrupt(interrupt),
    .interrupt_ack(interrupt_ack),
    .player_screen(player_screen),      // input from gamescreen, selects player 1 or 2 winner screen
    .reset(sysreset),
    .FirstScreen(first_screen_out),
    .GameScreen(game_screen_out),
    .Player1Wins(player1wins_out),
    .Player2Wins(player2wins_out),
    .sw({no,yes}),                    // switches to control which screen to display
    .color(color_out),
    .led(led[7:0]),
    .mode(mode),
    .reset_plyrScrn(reset_plyrScrn)     // reset player_screen signal
    ); 
endmodule