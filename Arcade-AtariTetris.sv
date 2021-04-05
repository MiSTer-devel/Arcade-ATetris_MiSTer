//============================================================================
//  Arcade: Atari-Tetris for MiSTer
//
//						Written by MiSTer-X 2019
//============================================================================

`include "rtl/fourWay/controls_top.sv"

module emu
(
	//Master input clock
	input         CLK_50M,

	//Async reset from top-level module.
	//Can be used as initial reset.
	input         RESET,

	//Must be passed to hps_io module
	inout  [45:0] HPS_BUS,

	//Base video clock. Usually equals to CLK_SYS.
	output        CLK_VIDEO,

	//Multiple resolutions are supported using different CE_PIXEL rates.
	//Must be based on CLK_VIDEO
	output        CE_PIXEL,

	//Video aspect ratio for HDMI. Most retro systems have ratio 4:3.
	//if VIDEO_ARX[12] or VIDEO_ARY[12] is set then [11:0] contains scaled size instead of aspect ratio.
	output [12:0] VIDEO_ARX,
	output [12:0] VIDEO_ARY,

	output  [7:0] VGA_R,
	output  [7:0] VGA_G,
	output  [7:0] VGA_B,
	output        VGA_HS,
	output        VGA_VS,
	output        VGA_DE,    // = ~(VBlank | HBlank)
	output        VGA_F1,
	output [1:0]  VGA_SL,
	output        VGA_SCALER, // Force VGA scaler

	input  [11:0] HDMI_WIDTH,
	input  [11:0] HDMI_HEIGHT,

`ifdef MISTER_FB
	// Use framebuffer in DDRAM (USE_FB=1 in qsf)
	// FB_FORMAT:
	//    [2:0] : 011=8bpp(palette) 100=16bpp 101=24bpp 110=32bpp
	//    [3]   : 0=16bits 565 1=16bits 1555
	//    [4]   : 0=RGB  1=BGR (for 16/24/32 modes)
	//
	// FB_STRIDE either 0 (rounded to 256 bytes) or multiple of pixel size (in bytes)
	output        FB_EN,
	output  [4:0] FB_FORMAT,
	output [11:0] FB_WIDTH,
	output [11:0] FB_HEIGHT,
	output [31:0] FB_BASE,
	output [13:0] FB_STRIDE,
	input         FB_VBL,
	input         FB_LL,
	output        FB_FORCE_BLANK,

`ifdef MISTER_FB_PALETTE
	// Palette control for 8bit modes.
	// Ignored for other video modes.
	output        FB_PAL_CLK,
	output  [7:0] FB_PAL_ADDR,
	output [23:0] FB_PAL_DOUT,
	input  [23:0] FB_PAL_DIN,
	output        FB_PAL_WR,
`endif
`endif

	output        LED_USER,  // 1 - ON, 0 - OFF.

	// b[1]: 0 - LED status is system status OR'd with b[0]
	//       1 - LED status is controled solely by b[0]
	// hint: supply 2'b00 to let the system control the LED.
	output  [1:0] LED_POWER,
	output  [1:0] LED_DISK,

	// I/O board button press simulation (active high)
	// b[1]: user button
	// b[0]: osd button
	output  [1:0] BUTTONS,

	input         CLK_AUDIO, // 24.576 MHz
	output [15:0] AUDIO_L,
	output [15:0] AUDIO_R,
	output        AUDIO_S,   // 1 - signed audio samples, 0 - unsigned
	output  [1:0] AUDIO_MIX, // 0 - no mix, 1 - 25%, 2 - 50%, 3 - 100% (mono)

	//ADC
	inout   [3:0] ADC_BUS,

	//SD-SPI
	output        SD_SCK,
	output        SD_MOSI,
	input         SD_MISO,
	output        SD_CS,
	input         SD_CD,

	//High latency DDR3 RAM interface
	//Use for non-critical time purposes
	output        DDRAM_CLK,
	input         DDRAM_BUSY,
	output  [7:0] DDRAM_BURSTCNT,
	output [28:0] DDRAM_ADDR,
	input  [63:0] DDRAM_DOUT,
	input         DDRAM_DOUT_READY,
	output        DDRAM_RD,
	output [63:0] DDRAM_DIN,
	output  [7:0] DDRAM_BE,
	output        DDRAM_WE,

	//SDRAM interface with lower latency
	output        SDRAM_CLK,
	output        SDRAM_CKE,
	output [12:0] SDRAM_A,
	output  [1:0] SDRAM_BA,
	inout  [15:0] SDRAM_DQ,
	output        SDRAM_DQML,
	output        SDRAM_DQMH,
	output        SDRAM_nCS,
	output        SDRAM_nCAS,
	output        SDRAM_nRAS,
	output        SDRAM_nWE,

`ifdef MISTER_DUAL_SDRAM
	//Secondary SDRAM
	//Set all output SDRAM_* signals to Z ASAP if SDRAM2_EN is 0
	input         SDRAM2_EN,
	output        SDRAM2_CLK,
	output [12:0] SDRAM2_A,
	output  [1:0] SDRAM2_BA,
	inout  [15:0] SDRAM2_DQ,
	output        SDRAM2_nCS,
	output        SDRAM2_nCAS,
	output        SDRAM2_nRAS,
	output        SDRAM2_nWE,
`endif

	input         UART_CTS,
	output        UART_RTS,
	input         UART_RXD,
	output        UART_TXD,
	output        UART_DTR,
	input         UART_DSR,

	// Open-drain User port.
	// 0 - D+/RX
	// 1 - D-/TX
	// 2..6 - USR2..USR6
	// Set USER_OUT to 1 to read from USER_IN.
	input   [6:0] USER_IN,
	output  [6:0] USER_OUT,

	input         OSD_STATUS
);

assign {SD_SCK, SD_MOSI, SD_CS} = 'Z;
assign {UART_RTS, UART_TXD, UART_DTR} = 0;
assign {SDRAM_DQ, SDRAM_A, SDRAM_BA, SDRAM_CLK, SDRAM_CKE, SDRAM_DQML, SDRAM_DQMH, SDRAM_nWE, SDRAM_nCAS, SDRAM_nRAS, SDRAM_nCS} = 'Z;

assign VGA_F1    = 0;
assign VGA_SCALER= 0;
assign USER_OUT  = '1;
assign LED_USER  = ioctl_download;
assign LED_DISK  = 0;
assign LED_POWER = 0;
assign BUTTONS   = 0;
assign AUDIO_MIX = 0;
assign FB_FORCE_BLANK = '0;

wire [1:0] ar = status[20:19];

assign VIDEO_ARX = (!ar) ? ((status[2]|mod_tetris)  ? 8'd4 : 8'd3) : (ar - 1'd1);
assign VIDEO_ARY = (!ar) ? ((status[2]|mod_tetris)  ? 8'd3 : 8'd4) : 12'd0;


`include "build_id.v" 
localparam CONF_STR = {
	"A.ATetris;;",
	"-;",
	"H0OJK,Aspect ratio,Original,Full Screen,[ARC1],[ARC2];",
	"H1H0O2,Orientation,Vert,Horz;",
	"O35,Scandoubler Fx,None,HQ2x,CRT 25%,CRT 50%,CRT 75%;",
	"-;",
	"ODG,Diagonal,Default,Change Direction,Keep Direction,Vertical,Horizontal,Stop;",
	"OH,Self-Test,Off,On;",
	"-;",
	"O8C,Analog Video H-Pos,0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31;",
	"OIK,Analog Video V-Pos,0,1,2,3,4,5,6,7;",
	"O6,Pause when OSD is open,On,Off;",
	"-;",
	"R0,Reset;",
	"J1,Rotate,Start 1P,Start 2P,Coin,Pause;",
	"jn,A,Start,Select,R,L;",
	"V,v",`BUILD_DATE
};

wire [3:0] DG_MODE = status[16:13];

wire [4:0] HOFFS = status[12:8];
wire [2:0] VOFFS = status[20:18];

wire bSelfTest = status[17];


////////////////////   CLOCKS   ///////////////////
 
wire clk_hdmi;
wire clk_14M;
wire clk_sys = clk_hdmi;

pll pll
(
	.rst(0),
	.refclk(CLK_50M),
	.outclk_0(clk_14M),
	.outclk_1(clk_hdmi)
);

///////////////////////////////////////////////////

wire [31:0] status;
wire  [1:0] buttons;
wire        forced_scandoubler;
wire			direct_video;

wire				ioctl_download;
wire				ioctl_upload;
wire				ioctl_wr;
wire	[7:0]		ioctl_index;
wire	[24:0]	ioctl_addr;
wire	[7:0]		ioctl_din;
wire	[7:0]		ioctl_dout;

wire [15:0] joystk1, joystk2;

wire [21:0] gamma_bus;

hps_io #(.STRLEN($size(CONF_STR)>>3)) hps_io
(
	.clk_sys(clk_sys),
	.HPS_BUS(HPS_BUS),

	.conf_str(CONF_STR),

	.buttons(buttons),

	.status(status),
	.status_menumask({14'h0,mod_tetris,direct_video}),

	.forced_scandoubler(forced_scandoubler),
	.gamma_bus(gamma_bus),
	.direct_video(direct_video),

	.ioctl_download(ioctl_download),
	.ioctl_upload(ioctl_upload),
	.ioctl_wr(ioctl_wr),
	.ioctl_addr(ioctl_addr),
	.ioctl_dout(ioctl_dout),
	.ioctl_din(ioctl_din),
	.ioctl_index(ioctl_index),

	.joystick_0(joystk1),
	.joystick_1(joystk2)
);

wire m_up2     = joystk2[3];
wire m_down2   = joystk2[2];
wire m_left2   = joystk2[1];
wire m_right2  = joystk2[0];
wire m_trig21  = joystk2[4];

wire m_start1  = joystk1[5]|joystk2[5];
wire m_start2  = joystk1[6]|joystk2[6];

wire m_up1     = joystk1[3];
wire m_down1   = joystk1[2];
wire m_left1   = joystk1[1];
wire m_right1  = joystk1[0];
wire m_trig11  = joystk1[4];

wire m_coin1   = joystk1[7];
wire m_coin2   = joystk2[7];
wire m_pause   = joystk1[8] | joystk2[8];

// PAUSE SYSTEM
reg				pause;									// Pause signal (active-high)
reg				pause_toggle = 1'b0;					// User paused (active-high)
reg [31:0]		pause_timer;							// Time since pause
reg [31:0]		pause_timer_dim = 31'h1DCD6500;	// Time until screen dim (10 seconds @ 50Mhz)
reg 				dim_video = 1'b0;						// Dim video output (active-high)

// Pause when highscore module requires access, user has pressed pause, or OSD is open and option is set
assign pause = pause_toggle | (OSD_STATUS && ~status[6]);
assign dim_video = (pause_timer >= pause_timer_dim) ? 1'b1 : 1'b0;

always @(posedge clk_hdmi) begin
	reg old_pause;
	old_pause <= m_pause;
	if(~old_pause & m_pause) pause_toggle <= ~pause_toggle;
	if(pause_toggle)
	begin
		if(pause_timer<pause_timer_dim)
		begin
			pause_timer <= pause_timer + 1'b1;
		end
	end
	else
	begin
		pause_timer <= 1'b0;
	end
end


reg mod_tetris = 0;
reg mod_tetris_cocktail = 0;


always @(posedge clk_sys) begin
	reg [7:0] mod = 0;
	if (ioctl_wr & (ioctl_index==1)) mod <= ioctl_dout;
	
	mod_tetris <= (mod == 0);
	mod_tetris_cocktail <= (mod == 1);
end


wire no_rotate = status[2] | direct_video | mod_tetris;


///////////////////////////////////////////////////

wire hblank, vblank;
wire ce_vid;
wire hs, vs;
wire [2:0] r,g; wire [1:0] b;
wire [7:0] rgb_out = dim_video ? {r >> 1,g >> 1, b >> 1} : {r,g,b};

reg ce_pix;
always @(posedge clk_hdmi) begin
	reg old_clk;
	old_clk <= ce_vid;
	ce_pix  <= old_clk & ~ce_vid;
end

wire rotate_ccw = 1;
screen_rotate screen_rotate (.*);

arcade_video #(336,8) arcade_video
(
	.*,

	.clk_video(clk_hdmi),

	.RGB_in(rgb_out),
	.HBlank(hblank),
	.VBlank(vblank),
	.HSync(~hs),
	.VSync(~vs),

	.fx(status[5:3])
);

wire			PCLK;
wire  [8:0] HPOS,VPOS;
wire  [7:0] POUT;
HVGEN hvgen
(
	.HPOS(HPOS),.VPOS(VPOS),.PCLK(PCLK),.iRGB(POUT),
	.oRGB({r,g,b}),.HBLK(hblank),.VBLK(vblank),.HSYN(hs),.VSYN(vs),
	.HOFFS(HOFFS),.VOFFS(VOFFS)
);
assign ce_vid = PCLK;


wire [15:0] AOUT;
assign AUDIO_L = AOUT;
assign AUDIO_R = AUDIO_L;
assign AUDIO_S = 0;// unsigned PCM


///////////////////////////////////////////////////
wire rom_download = ioctl_download & !ioctl_index;
wire nvm_download = ioctl_download & (ioctl_index=='d4);
wire iRST = RESET | status[0] | buttons[1] | ioctl_download;


`define SELFT	bSelfTest

`define COIN1	m_coin1
`define COIN2	m_coin2

`define P1UP	m_up1
`define P1DW	m_down1
`define P1LF	m_left1
`define P1RG	m_right1
`define P1RO	m_trig11|m_start1

`define P2UP	m_up2
`define P2DW	m_down2
`define P2LF	m_left2
`define P2RG	m_right2
`define P2RO	m_trig21|m_start2


wire dum1,oP1DW,oP1LF,oP1RG;
wire dum2,oP2DW,oP2LF,oP2RG;

enhanced4wayjoy player1
(
    clk_sys,
    {
        `P1UP,
        `P1DW,
		  `P1LF,
        `P1RG
    },
    {dum1, oP1DW, oP1LF, oP1RG},
    DG_MODE
);

enhanced4wayjoy player2
(
    clk_sys,
    {
        `P2UP,
        `P2DW,
		  `P2LF,
        `P2RG
    },
    {dum2, oP2DW, oP2LF, oP2RG},
    DG_MODE
);

wire [10:0] INP = ~{`SELFT,`COIN2,`COIN1,oP2LF,oP2RG,oP2DW,`P2RO,oP1LF,oP1RG,oP1DW,`P1RO};

FPGA_ATETRIS GameCore
(
	.MCLK(clk_14M),.RESET(iRST),
	.INP(INP),
	.HPOS(HPOS),.VPOS(VPOS),.PCLK(PCLK),.POUT(POUT),
	.AOUT(AOUT),

	.ROMCL(clk_sys),
	.ROMAD(ioctl_addr),
	.ROMDT(ioctl_dout),
	.ROMEN(ioctl_wr & rom_download),

	.pause(pause),

	.hs_address(ioctl_addr),
	.hs_data_in(ioctl_dout),
	.hs_data_out(ioctl_din),
	.hs_write(ioctl_wr & nvm_download)
);

endmodule


module HVGEN
(
	output  [8:0]		HPOS,
	output  [8:0]		VPOS,
	input 				PCLK,
	input	  [7:0]		iRGB,

	output reg [7:0]	oRGB,
	output reg			HBLK = 1,
	output reg			VBLK = 1,
	output reg			HSYN = 1,
	output reg			VSYN = 1,
	
	input   [8:0]		HOFFS,
	input   [8:0]		VOFFS
);

reg [8:0] hcnt = 0;
reg [8:0] vcnt = 0;

assign HPOS = hcnt-1;
assign VPOS = vcnt;

wire [8:0] HS_B = 360+(HOFFS*2);
wire [8:0] HS_E =  24+(HS_B);
wire [8:0] HS_N = 511-(456-HS_E);

wire [8:0] VS_B = 240+(VOFFS*2);
wire [8:0] VS_E =   3+(VS_B);

always @(posedge PCLK) begin
	case (hcnt)
		  0: begin HBLK <= 0; hcnt <= hcnt+1; end
		337: begin HBLK <= 1; hcnt <= hcnt+1; end
		511: begin hcnt <= 0;
			case (vcnt)
				239: begin VBLK <= 1; vcnt <= vcnt+1; end
				261: begin VBLK <= 0; vcnt <= 0;      end
				default: vcnt <= vcnt+1;
			endcase
		end
		default: hcnt <= hcnt+1;
	endcase

	if (hcnt==HS_B) begin HSYN <= 0; end
	if (hcnt==HS_E) begin HSYN <= 1; hcnt <= HS_N; end

	if (vcnt==VS_B) begin VSYN <= 0; end
	if (vcnt==VS_E) begin VSYN <= 1; end
	
	oRGB <= (HBLK|VBLK) ? 8'h0 : iRGB;
end

endmodule

