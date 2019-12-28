//============================================================================
//  fpga-control modules: enhanced4wayjoy, enhanced2wayjoy
//  Verion 0.8
// 
//  Copyright (C) 2019 Eniva
//
//  This program is free software; you can redistribute it and/or modify it
//  under the terms of the GNU General Public License as published by the Free
//  Software Foundation; either version 2 of the License, or (at your option)
//  any later version.
//
//  This program is distributed in the hope that it will be useful, but WITHOUT
//  ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
//  FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
//  more details.
//
//  You should have received a copy of the GNU General Public License along
//  with this program; if not, write to the Free Software Foundation, Inc.,
//  51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
//============================================================================

// ---------------------------------------------------------------------------
//  For module parameters, check out "./header.sv".
// ---------------------------------------------------------------------------
`include "header.sv"
`include "socd.sv"
`include "diagonal.sv"

// ---------------------------------------------------------------------------
//  enhanced4wayjoy
//
//  FOR 4-WAY-INPUT SYSTEMS ONLY!
//  Unlike 4-way joysticks, keyboards & most modern controllers can easily do
//  multi-direction presses at once (i.e. diagonals).
//  This causes a problem for systems never wrote codes for them.
//  This is a fix to the modern problem to provide responsive controls.
//
//  parameters:
//  
//  SOCD_UD: What to do when both Up & Down switches are on:
//    0 FAVOR_ZERO        - Zero both input. Although not industry standard,
//                          this makes more sense for most 4way games.
//    1 FAVOR_UP          - Let left through, zero right. Industry standard.
//    2 FAVOR_DOWN        - Let rigth through, zero left
//  
//  SOCD_LR: What to do when both Left & Right switches are on:
//    0 FAVOR_ZERO        - Zero both input. Most  game controllers use this 
//                          in their hardware/firmware (industry standard).
//    1 FAVOR_LEFT        - Let left through, zero right
//    1 FAVOR_RIGHT       - Let rigth through, zero left
//  
//  PDIP_FAVOR_DIRECTION: Favored direction on pure diagonal inputs 
//                        (not used for prediction). Check out [PDIP] below 
//                        to see what this does exactly.
//    0 DIR_HORIZONTAL
//    1 DIR_VERTICAL
// ---------------------------------------------------------------------------
module enhanced4wayjoy #(parameter 
	[1:0] SOCD_UD              = FAVOR_ZERO,
	[1:0] SOCD_LR              = FAVOR_ZERO, 
	      PDIP_FAVOR_DIRECTION = DIR_HORIZONTAL)
(
	input        clock,

	// [dir/3:0] = {up, down, left, right}
	input  [3:0] dirinput,  // [dir/3:0] User dirctional inputs
	output [3:0] diroutput, // [dir/3:0] [PAYLOAD]. What you want to use

	// [uom/3:0] = 4bit int: MODE_DISABLED, MODE_PREDCTION, MODE_CORRECTION, 
	//                       MODE_VERTICAL, MODE_HORIZONTAL, MODE_CLEAR
	input  [3:0] m_mode     // [uom/3:0] User option
);
	// [Wiring]
	// dirinput -> [PCLK]:newInput -> rawInput -> wire_vh (v_socdc -> h_socdc)
	// -> wire_hpd (h_socdc -> pdiagonal) -> pInput -> diroutput
	wire [3:0] wire_vh;
	wire [3:0] wire_hpd;

	reg [3:0] oldInput = 0; // last RAW direcitonal input signals
	reg [3:0] newInput = 0; // latest RAW directional input signals
	reg [3:0] rawInput = 0; // latest input reg to create payload
	reg [3:0] pInput   = 0; // PROCESSED directional input signals
	reg [3:0] lpInput  = 0; // last PROCESSED directional input signals

	reg [3:0] userMode = 0; // m_mode. Avoids comb logic trigger outside clk+

	assign diroutput = pInput;

	// [PCLK]
	always @(posedge clock)
	begin
		newInput <= dirinput;
		oldInput <= newInput;

		if (oldInput != newInput)
		begin
			lpInput <= pInput;
			rawInput <= newInput;
			userMode <= m_mode;
		end
	end

	// Clear SOCD -> Predict/process diagonals -> Payload
	vertical_socd_cleaner #(SOCD_UD) v_socdc
	( rawInput, wire_vh );

	horizontal_socd_cleaner #(SOCD_LR) h_socdc
	( wire_vh, wire_hpd );

	diagonal_prediction #(PDIP_FAVOR_DIRECTION) pdiagonal
	( wire_hpd, lpInput, pInput, userMode );

endmodule

// ---------------------------------------------------------------------------
//  enhanced2wayjoy
//
//  FOR 2-WAY-INPUT SYSTEMS ONLY!
//  
//
//  parameters:
//  
//  ORIENTATION:          Orientation of the 2-way
//    0 DIR_HORIZONTAL
//    1 DIR_VERTICAL
// ---------------------------------------------------------------------------
module enhanced2wayjoy #(parameter
	ORIENTATION = DIR_HORIZONTAL)
(
	input        clock,

	// [dir/3:0] = {up, down, left, right}
	input  [3:0] dirinput,  // [dir/3:0] User dirctions
	output [3:0] diroutput  // [dir/3:0] [PAYLOAD]. What you want to use
);

	// [Wiring]
	// dirinput -> [PCLK]:pInput ->  diroutput
	reg [3:0] oldInput = 0; // last RAW direcitonal input signals
	reg [3:0] newInput = 0; // latest RAW directional input signals
	reg [3:0] pInput   = 0; // PROCESSED directional input signals

	assign diroutput = pInput;

	// [PCLK]
	always @(posedge clock)
	begin
		newInput <= dirinput;
		oldInput <= newInput;

		if (oldInput != newInput)
		begin
			pInput <= (ORIENTATION == DIR_HORIZONTAL) ? 
				// HORIZONTAL 2-WAY: Remove up and down directions
				newInput & ~(DIR_UP | DIR_DOWN) :

				// VERTICAL 2-WAY: Remove left and right directions
				newInput & ~(DIR_LEFT | DIR_RIGHT);
		end
	end


endmodule