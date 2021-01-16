//============================================================================
//  fpga-control module: socd_cleaners
//  Verion 1.0
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
//  vertical_socd_cleaner
//  parameters:
//
//  ON_SOCD: What to do when Up & Down switch is on:
//    0 FAVOR_ZERO        - Zero both input. Although not industry standard,
//                          this makes more sense for most 4way games.
//    1 FAVOR_UP          - Let left through, zero right. Industry standard.
//    2 FAVOR_DOWN        - Let rigth through, zero left
// ---------------------------------------------------------------------------
module vertical_socd_cleaner #(parameter 
	[1:0] ON_SOCD = FAVOR_ZERO)
(
	input  [3:0] dirinput,  // {up, down, left, right}
	output [3:0] diroutput  // {up, down, left, right}
);

	// [SOCD] Simultaneous Opposite Cardinal Direction (SOCD) cleaning
	// This only applies to non-dpads/joystics like keyboards & hitboxes where both opposing direction signals are alive.
	// In cases like this, we simply favor one direction or zero both input (+ - = 0), which will respect the direction still being held.
	assign diroutput = (dirinput & (DIR_UP | DIR_DOWN)) == (DIR_UP | DIR_DOWN) ? 
		// SOCD
		(ON_SOCD == FAVOR_ZERO) ? dirinput & ~(DIR_UP | DIR_DOWN) : 
		(ON_SOCD == FAVOR_UP)   ? dirinput & ~DIR_DOWN : 
		(ON_SOCD == FAVOR_DOWN) ? dirinput & ~DIR_UP :
		dirinput
		:
		// NO SOCD
		dirinput;

endmodule

// ---------------------------------------------------------------------------
//  horizontal_socd_cleaner
//  parameters:
//
//  SOCD_RL: What to do when Right & Left switch is on:
//    0 FAVOR_ZERO        - Zero both input. Most  game controllers use this 
//                          in their hardware/firmware (industry standard).
//    1 FAVOR_LEFT        - Let left through, zero right
//    1 FAVOR_RIGHT       - Let rigth through, zero left
// --------------------------------------------------------------------------
module horizontal_socd_cleaner #(parameter 
	[1:0] ON_SOCD = FAVOR_ZERO)
(
	input  [3:0] dirinput,  // {up, down, left, right}
	output [3:0] diroutput  // {up, down, left, right}
);
	// [SOCD] Simultaneous Opposite Cardinal Direction (SOCD) cleaning
	// This only applies to non-dpads/joystics like keyboards & hitboxes where both opposing direction signals are alive.
	// In cases like this, we simply favor one direction or zero both input (+ - = 0), which will respect the direction still being held.
	assign diroutput = ((dirinput & (DIR_LEFT | DIR_RIGHT)) == (DIR_LEFT | DIR_RIGHT)) ?
		// SOCD
		(ON_SOCD == FAVOR_ZERO)  ? dirinput & ~(DIR_LEFT | DIR_RIGHT) :
		(ON_SOCD == FAVOR_LEFT)  ? dirinput & ~DIR_RIGHT :
		(ON_SOCD == FAVOR_RIGHT) ? dirinput & ~DIR_LEFT :
		dirinput
		:
		// NO SOCD
		dirinput;

endmodule