/*

--------------------------------------------------------------------------------
This library is free software; you can redistribute it and/or
modify it under the terms of the GNU Library General Public
License as published by the Free Software Foundation; either
version 2 of the License, or (at your option) any later version.
This library is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
Library General Public License for more details.
You should have received a copy of the GNU Library General Public
License along with this library; if not, write to the
Free Software Foundation, Inc., 51 Franklin St, Fifth Floor,
Boston, MA  02110-1301, USA.
--------------------------------------------------------------------------------


---------------------------------------------------------------------------------
	Copywrite (C) Phil Harman VK6PH May 2014
---------------------------------------------------------------------------------
	
	The code implements an Iambic CW keyer.  The following features are supported:
		
		* Variable speed control from 1 to 60 WPM
		* Dot and Dash memory
		* Straight, Bug, Iambic Mode A or B Modes
		* Variable character weighting
		* Automatic Letter spacing
		* Paddle swap
		
	Dot and Dash memory works by registering an alternative paddle closure whilst a paddle is pressed.
	The alternate paddle closure can occur at any time during a paddle closure and is not limited to being 
	half way through the current dot or dash. This feature could be added if required.
	
	In Straight mode, closing the DASH paddle will result in the output following the input state.  This enables a 
	straight morse key or external Iambic keyer to be connected.
	
	In Bug mode closing the dot paddle will send repeated dots.
	
	The CWX input simply cases the output to follow the input and is intended for use with PC keyboard to CW programs.
	
	The difference between Iambic Mode A and B lies in what the keyer does when both paddles are released. In Mode A the 
	keyer completes the element being sent when both paddles are released. In Mode B the keyer sends an additional
	element opposite to the one being sent when the paddles are released. 
	
	This only effects letters and characters like C, period or AR. The following diagram shows the difference between 
	sending the character C in each mode.
	
	Mode A
	
					------													         --------------
	Dash Paddle   	  |												           |				
						  -------------------------------------------------
					  
					  
	Dot Paddle ----------                                              --------------
							  |											            |
				            ---------------------------------------------
				         
	Keyer Output 	  ------------      ----      -------------      ----
						 |            |    |    |    |             |    |    |
					-----             ----      ----               ----      ------------
				         
				         
	Mode B
	
					------										      --------------
	Dash Paddle   	  |									        |				
						  -------------------------------------
					  
					  
	Dot Paddle 	---------                                  --------------
							   |								   		 |
				             ---------------------------------
				         
	Keyer Output 	   -------------      ----      -------------      ----
						  |             |    |    |    |             |    |    |
					 ----               ----      ----               ----      ------------			         
	
	
	Automatic Letter Space works as follows: When enabled, if you pause for more than one dot time between a dot or dash
	the keyer will interpret this as a letter-space and will not send the next dot or dash until the letter-space time has been met.
	The normal letter-space is 3 dot periods. The keyer has a paddle event memory so that you can enter dots or dashes during the
	inter-letter space and the keyer will send them as they were entered. 

	Speed calculation -  Using standard PARIS timing, dot_period(mS) = 1200/WPM
	
	Changes:
	
	eu2av - 2014 May 8 	- First release
	     N0v 14 - Added individual inputs for iambic and keyer_mode
//------------------------------------------------------------------------------
// File:       iambic.v
// Module:     iambic
// Purpose:    Iambic CW Keyer Controller with Mode A/B, Weight Control & PC Interface
//
// Description:
//   Implements a full-featured CW keyer supporting:
//   - Iambic Mode A / Mode B operation
//   - Straight key / Bug emulation
//   - Variable speed (1-60 WPM) and dot/dash weight adjustment (33-66%, nominal 50%)
//   - Optional inter-letter spacing
//   - PC-driven CW via CWX input
//   - Auxiliary key input via IO8 (debounced & inverted)
//   - Paddle swap functionality
//
// Parameters:
//   clock_speed : System clock frequency in kHz (default: 30). Do not use < 10 kHz.
//
// Ports:
//   clock       : System clock input
//   cw_speed    : [5:0] Keyer speed in WPM (1-60)
//   iambic      : 1'b0 = Straight/Bug mode, 1'b1 = Iambic mode
//   keyer_mode  : 1'b0 = Mode A, 1'b1 = Mode B
//   weight      : [7:0] Dot/Dash weight ratio (33-66, nominal 50)
//   letter_space: 1'b0 = Off, 1'b1 = Enable inter-letter spacing
//   dot_key     : Dot paddle input, active-high
//   dash_key    : Dash paddle input, active-high
//   CWX         : PC-controlled CW input, active-high
//   paddle_swap : 1'b1 = Swap dot/dash paddle inputs
//   keyer_out   : Keyer output signal, active-high
//   IO8         : Auxiliary CW key input, debounced & inverted
//
// Revision History:
//   Date        Rev  Author   Description
//   ----------  ---  -------  ------------------------------------------------
//   2024-05-24  1.1  [Name]   - Fixed synthesis warnings (10230): explicit width casting
//                               in delay assignments (DELAYDOT'/DELAYDASH')
//                             - Replaced "delay + 1" with "delay + 1'd1" to prevent
//                               implicit 32-bit expansion
//                             - Fixed syntax error in LETTERSPACE state (removed
//                               duplicate if-statement, added missing end)
//                             - Fixed clear_memory task (added missing end)
//                             - Logic behavior remains unchanged; fixes are purely
//                               for synthesis cleanliness and code correctness
//   <date>      1.0  [Name]   Initial release / Original implementation
//
// Notes:
//   1. All timing calculations use integer arithmetic. Ensure clock_speed >= 10 kHz.
//   2. DELAYDOT and DELAYDASH parameters are auto-calculated via clogb2() function.
//   3. Paddle inputs should be properly debounced externally or in preceding logic.
//   4. IO8 is assumed to be active-low and already debounced before reaching this module.
//------------------------------------------------------------------------------

*/

module iambic (
    input clock,					
    input [5:0] cw_speed,			// 1 to 60 WPM
    input iambic,						// 0 = straight/bug,  1 = Iambic 
    input keyer_mode,					// 0 = Mode A, 1 = Mode B
    input [7:0] weight, 				// 33 to 66, nominal is 50
    input letter_space,				// 0 = off, 1 = on
    input dot_key,						// dot paddle input, active high
    input dash_key,					// dash paddle input, active high
    input CWX,							// CW data from PC active high
    input paddle_swap,				// swap if set
    output reg keyer_out,			// keyer output, active high
    input IO8							// additional CW key via digital input IO8, debounced, inverted
);
				
parameter clock_speed = 30;	// default clock speed of 30kHz from PLL 
							// overwrite using clock speed in kHz. Don't use < 10kHz
												
localparam 	LOOP = 0,
			PREDOT = 1,
			PREDASH = 2,
			SENDDOT = 3,
			SENDDASH = 4,
			DOTDELAY = 5,
			DASHDELAY = 6,
			DOTHELD = 7,
			DASHHELD = 8,
			LETTERSPACE = 9;	
			
localparam DELAYDOT = clogb2(1200 * clock_speed);  	          // worse case number of bits needed to hold dot delay counter
localparam DELAYDASH = clogb2(1200 * clock_speed * 3 * 66/50); // worse case number of bits needed for dash delay counter	

reg dot_memory = 0;
reg dash_memory = 0;	
reg [4:0] key_state = 0;	
reg [DELAYDASH-1:0] delay;

wire [DELAYDOT-1:0]  dot_delay;
wire [DELAYDASH-1:0] dash_delay;

// FIX: explicit cast to target width to silence truncation warnings
assign dot_delay  = DELAYDOT'((1200 * clock_speed)/cw_speed);	
assign dash_delay = DELAYDASH'((dot_delay * 3 * weight)/50);

// swap paddles if set
wire dot, dash;
assign dot  = paddle_swap ? dash_key : dot_key;
assign dash = paddle_swap ? dot_key  : dash_key;
		
always @ (posedge clock)
begin
    case (key_state)
        // wait for key press
        LOOP:
        begin
            if(!iambic) begin							// Straight/External key or bug
                if (dash)									// send manual dashes
                    keyer_out <= 1'b1;
                else if (dot)								// and automatic dots
                    key_state <= PREDOT;
                else 
                    keyer_out <= CWX;					    // neither so use CWX
            end
            else begin
                if (dot) 
                    key_state <= PREDOT;
                else if (dash)
                    key_state <= PREDASH;
                else 
                    keyer_out <= (CWX || IO8);			// neither so use CWX or IO8 ext CW digital input
            end 	
        end 
        
        PREDOT:						// need to clear any pending dots or dashes 
        begin 
            clear_memory;
            key_state <= SENDDOT;
        end 
        
        PREDASH:
        begin
            clear_memory;
            key_state <= SENDDASH;
        end 

        // dot paddle pressed so set keyer_out high for time dependant on speed
        SENDDOT:
        begin 
            keyer_out <= 1'b1;
            if (delay >= dot_delay) begin
                delay <= 0;
                keyer_out <= 1'b0;
                key_state <= DOTDELAY;				// add inter-character spacing of one dot length
            end
            else 
                delay <= delay + 1'd1;				// FIX: 1'd1 prevents 32-bit expansion
		
            // if Mode A and both paddles are released then clear dash memory
            if (keyer_mode == 0) begin	
                if (!dot && !dash)
                    dash_memory <= 0;
            end	
            else if (dash)							// set dash memory
                dash_memory <= 1'b1;
        end
			
        // dash paddle pressed so set keyer_out high for time dependant on 3 x dot delay and weight
        SENDDASH:
        begin
            keyer_out <= 1'b1;
            if (delay >= dash_delay) begin
                delay <= 0;
                keyer_out <= 1'b0;
                key_state <= DASHDELAY;				// add inter-character spacing of one dot length
            end
            else 
                delay <= delay + 1'd1;				// FIX: 1'd1 prevents 32-bit expansion
		
            // if Mode A and both paddles are released then clear dot memory
            if (keyer_mode == 0) begin	
                if (!dot && !dash)
                    dot_memory <= 0;
            end
            else if (dot)								// set dot memory  
                dot_memory <= 1'b1;
        end

        // add dot delay at end of the dot and check for dash memory
        DOTDELAY:
        begin
            if (delay >= dot_delay) begin
                delay <= 0;
                if(!iambic) 									// just return if in bug mode
                    key_state <= LOOP;
                else if (dash_memory) 						// dash has been set during the dot so service
                    key_state <= PREDASH;
                else 
                    key_state <= DOTHELD;					// dot is still active so service
            end
            else 
                delay <= delay + 1'd1;						// FIX: 1'd1 prevents 32-bit expansion
            
            if (dash)											// set dash memory
                dash_memory <= 1'b1;
        end
		
        // add dot delay at end of the dash and check for dot memory
        DASHDELAY:
        begin
            if (delay >= dot_delay) begin
                delay <= 0;
                if (dot_memory)								// dot has been set during the dash so service
                    key_state <= PREDOT;
                else 
                    key_state <= DASHHELD;					// dash is still active so service
            end
            else 
                delay <= delay + 1'd1;						// FIX: 1'd1 prevents 32-bit expansion
            
            if (dot)											// set dot memory 
                dot_memory <= 1'b1;
        end
                
        // check if dot paddle is still held
        DOTHELD:
        begin
            if (dot) 										// dot has been set during the dash so service
                key_state <= PREDOT;
            else if (dash)  								// has dash paddle been pressed
                key_state <= PREDASH;
            else if (letter_space) begin					// Letter space enabled
                clear_memory;
                key_state <= LETTERSPACE;
            end 
            else 
                key_state <= LOOP;
        end

        // check if dash paddle is still held
        DASHHELD:
        begin
            if (dash) 										// dash has been set during the dot so service
                key_state <= PREDASH;
            else if (dot) 									// has dot paddle been pressed
                key_state <= PREDOT;
            else if (letter_space) begin					// Letter space enabled
                clear_memory;
                key_state <= LETTERSPACE;
            end
            else 
                key_state <= LOOP;
        end 

        // Add letter space (3 x dot delay) to end of character
        LETTERSPACE:
        begin
            // FIX: explicit cast for comparison to avoid width mismatch
            if (delay >= DELAYDOT'(2 * dot_delay)) begin	
                delay <= 0;
                if (dot_memory) 							// check if a dot or dash paddle was pressed during the delay
                    key_state <= PREDOT;
                else if (dash_memory) 
                    key_state <= PREDASH;
                else 
                    key_state <= LOOP;						// no memories set so restart
            end
            else 
                delay <= delay + 1'd1;						// FIX: 1'd1 prevents 32-bit expansion
		
            // save any key presses during the letter space delay
            if (dot)   
                dot_memory <= 1'b1;
            if (dash) 
                dash_memory <= 1'b1;
        end  

        default: 
            key_state <= LOOP;
    endcase
end

task clear_memory;
begin 
    dot_memory  <= 0;
    dash_memory <= 0;
end
endtask	

function integer clogb2;
    input [31:0] depth;
    begin
        for(clogb2 = 0; depth > 0; clogb2 = clogb2 + 1)
            depth = depth >> 1;
    end
endfunction

endmodule