`timescale 1ns / 1ps
///////////////////////////////////////////////////////////////////////////////////////////
// audio_PWM.v -  This module will generate the audio PWM signals based on the 8-bit 
//                digital data
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
// The 8-bit digital data is fed to 'music_data' input signal
// PWM output of the digital sample is sent on 'PWM_out' 
//
//////////////////////////////////////////////////////////////////////////////////////////


//`timescale 1ns / 1ps
// Audio PWM module.

module audio_PWM
(
    input clk, 			          // 100MHz clock.
    input reset,		          // Reset assertion.
    input [7:0] music_data,	      // 8-bit music sample
    output reg PWM_out		      // PWM output. Connect this to ampPWM.
);
    
    
    reg [7:0] pwm_counter = 8'd0;           // counts up to 255 clock cycles per pwm period
       
 
// Sequential block to generate the PWM signal         
always @(posedge clk) 
begin
    if(reset)                   // Reset condition
    begin
        pwm_counter <= 0;
        PWM_out <= 0;
    end
    else 
    begin
        pwm_counter <= pwm_counter + 1;     // Increment the PWM counter
        
        if(pwm_counter >= music_data)       // Compare the PWM counter value to 8-bit digital data
            PWM_out <= 0;                   // Duty cycle of the PWM is varied depending on the input magnitude
        else
            PWM_out <= 1;
    end
end
    
    
endmodule
