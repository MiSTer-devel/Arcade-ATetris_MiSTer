//============================================================================
//  fpga-control module: diagonal
//  Verion 1.0
//
//  Control input improvements for FPGA 
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
//  diagonal_prediction
//
//  parameters:
//  
//  PDIP_FAVOR_DIRECTION: Favored direction on pure diagonal inputs 
//                        (not used for prediction). Check out [PDIP] below 
//                        to see what this does exactly.
//    0 DIR_HORIZONTAL
//    1 DIR_VERTICAL
// ---------------------------------------------------------------------------
module diagonal_prediction #(parameter 
	PDIP_FAVOR_DIRECTION = DIR_HORIZONTAL)
(
	// [dir/3:0] = {up, down, left, right}
	input  [3:0] dirinput,     // [dir/3:0] User dirctions
	input  [3:0] oldpInput,    // [dir/3:0] Last processed user directions 

	output [3:0] diroutput,    // [dir/3:0] Processed user directions

	// User setting: "Diagonal" How diagonal input should be handled
	// This is 4bit to reserve for future to cover a few more exceptional cases.
	// For more information on this, check [UIPD] below.
	// [uom/3:0] = 4bit int: MODE_DISABLED, MODE_PREDCTION, MODE_CORRECTION, MODE_VERTICAL, MODE_HORIZONTAL, MODE_CLEAR
	input  [3:0] m_mode        // [uom/3:0] User Options 
);

    // [Wiring]
    // dirinput -> pInput([UIPD]) -> pfix  -> diroutput
    wire [3:0] pInput;
	perfect_diagonal_fix #(PDIP_FAVOR_DIRECTION) pfix
	( pInput, diroutput );

	// MODE_DISABLED means no predictions - Games designed for without diagonal inputs = unpredictable.
	// As it results undesirable outcomes, when mode is not disabled, we predict user's intention:
	assign pInput = (m_mode != MODE_DISABLED && (dirinput & (DIR_UP | DIR_DOWN)) && (dirinput & (DIR_LEFT | DIR_RIGHT))) ?
		// [UIPD] User intent prediction for diagonal inputs
		// Based on current and past input, we attempt to predict the intention of the user on diagonal inputs.

		// 1. PREDICTION method. User label: "Change Direction"
		// By favoring the player's new direction change, we can predict which direction
		// the player intends to go on diagonal inputs.
		// This is the RECOMMENDED way to handle it.
		(m_mode == MODE_PREDCTION)  ? dirinput ^ (dirinput & oldpInput) :

		// 2. CORRECTION method. User label: "Keep Direction"
		// Respects the older direction that the player was holding/pressing force,
		// and assumes the diagonal input is an error and corrects it by
		// zeroing the newer input only.
		(m_mode == MODE_CORRECTION) ? oldpInput :

		// 3. FORCE (vertical) method. User label: "Vertical"
		// Forces 
		(m_mode == MODE_VERTICAL)   ? dirinput & ~(DIR_LEFT | DIR_RIGHT) : 

		// 4. FORCE (horizontal) method. User label: "Horizontal"
		// Forces 
		(m_mode == MODE_HORIZONTAL) ? dirinput & ~(DIR_UP | DIR_DOWN) : 

		// 5. CLEAR method. User label: "Stop"
		// Zeros all directions on the diagonal. Good for high-precision games like Tetris.
		(m_mode == MODE_CLEAR)      ? 0 : 

		dirinput
		:
		// Not diagonal input
		dirinput;
endmodule


// ---------------------------------------------------------------------------
//  perfect_diagonal_fix
//  This is meant to be used after diagonals are predicted.
//  If the input still has diagonal input, it means the directions formed
//  diagonal at the exact same time. It's incredibly rare, but it can happen.
//  In this case, we make an educational guess and force a direction.
//
//  parameters:
//  
//  PDIP_FAVOR_DIRECTION: Favored direction on pure diagonal inputs 
//                        (not used for prediction). Check out [PDIP] below 
//                        to see what this does exactly.
//    0 DIR_HORIZONTAL
//    1 DIR_VERTICAL
// ---------------------------------------------------------------------------
module perfect_diagonal_fix #(parameter 
	PDIP_FAVOR_DIRECTION = DIR_HORIZONTAL)
(
	// [dir/3:0] = {up, down, left, right}
	input  [3:0] dirinput,  // [dir/3:0] Input 
	output [3:0] diroutput  // [dir/3:0] Processed output
);
	// [PDIP] What to do with perfect diagonals
	// Although incredibly rare, diagonal input can happen with two adjacent inputs being pressed at the exact same tim.
	// Because we can no longer predict their intention, we simply favor one direction. Most games an educational guess would be horizontal, but it can be set to vertical for the rest.
	assign diroutput = ((dirinput & (DIR_UP | DIR_DOWN)) && (dirinput & (DIR_LEFT | DIR_RIGHT))) ?
		// Get rid of horizontal/veritcal directional inputs
		dirinput & ~(PDIP_FAVOR_DIRECTION ? (DIR_UP | DIR_DOWN) : (DIR_LEFT | DIR_RIGHT))
		:
		dirinput;
endmodule