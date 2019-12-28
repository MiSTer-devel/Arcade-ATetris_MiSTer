localparam DIR_UP           = 4'b1000;
localparam DIR_DOWN         = 4'b0100;
localparam DIR_LEFT         = 4'b0010;
localparam DIR_RIGHT        = 4'b0001;

localparam FAVOR_ZERO       = 2'b00;
localparam FAVOR_UP         = 2'b01;
localparam FAVOR_DOWN       = 2'b10;
localparam FAVOR_LEFT       = 2'b01;
localparam FAVOR_RIGHT      = 2'b10;

localparam DIR_HORIZONTAL   = 1'b0;
localparam DIR_VERTICAL     = 1'b1;

localparam MODE_DISABLED    = 4'b0000;
localparam MODE_PREDCTION   = 4'b0001;
localparam MODE_CORRECTION  = 4'b0010;
localparam MODE_VERTICAL    = 4'b0011;
localparam MODE_HORIZONTAL  = 4'b0100;
localparam MODE_CLEAR       = 4'b0101;
