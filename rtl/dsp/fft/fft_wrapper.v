module fft_wrapper(
    input  wire clk,
    input  wire reset_n,
    input  wire ce,

	// Input data stream
    input  wire [15:0] tdata_s,
    input  wire        tuser_s,
    input  wire        tlast_s,
    input  wire        tvalid_s,
    output wire        tready_s,

	// Output data stream
    output wire [31:0] tdata_m,
    output reg         tuser_m,
    output reg         tlast_m,
    output wire        tvalid_m,
    input  wire        tready_m
);

	// Input FIFO
	wire fifo_full_in;
    reg  fifo_input_ien;

    wire [15:0] fft_din;
    wire        fft_input_proc;		// Input in process

    always @(posedge clk, negedge reset_n) begin
		if(!reset_n)
        	fifo_input_ien <= 1'b0;
        else begin
			if(tuser_s)
            	fifo_input_ien <= 1'b1;
            else if(tlast_s)
            	fifo_input_ien <= 1'b0;
        end
    end

    fifo_ip_sync_fftbuff_in fifo_input(
        .Clk(clk),
        .Reset(~reset_n),
        
        // Data I/O
        .Data(tdata_s),
        .WrEn(tvalid_s && (fifo_input_ien || tuser_s)),
        .Q(fft_din),
        .RdEn(fft_input_proc),

		// Flags
        .Full(fifo_full_in),
		.Empty( ),

        .Wnum( )
    );

    // Input flow control
    assign tready_s = ~fifo_full_in;

	// FFT
    // [Grinning face with sweat]
    wire [15:0] fft_dout_re;
    wire [15:0] fft_dout_im;
    wire        fft_output_proc;	// Output in process
    wire        fft_output_start, fft_output_end;

	fft_ip fft(
        .clk (clk),
        .rst (reset_n),

        // Data I/O
        .xn_re (fft_din),
        .xn_im (0),
        .xk_re (fft_dout_re),
        .xk_im (fft_dout_im),

		// Start
        .start (fifo_full_in),

        // Status signals
        .sod ( ),
        .ipd (fft_input_proc),
        .eod ( ),

        .soud (fft_output_start),
        .opd  (fft_output_proc),
        .eoud (fft_output_end)
    );

    // Output
    wire fifo_empty_out;

	fifo_ip_sync_fftbuff_out fifo_output(
		.Clk   (clk),
        .Reset (~reset_n),

        // Data I/O
        .Data ({fft_dout_im, fft_dout_re}),
        .WrEn (fft_output_proc),
        .Q    (tdata_m),
        .RdEn (tready_m),

        // Flags
		.Empty  (fifo_empty_out),
        .Full ( )
    );
    
    always @(posedge clk, negedge reset_n) begin
		if(reset_n) begin
			tuser_m <= 1'b0;
            tlast_m <= 1'b0;
        end
        else begin
			tuser_m <= fft_output_start;
            tlast_m <= fft_output_end;
        end
    end

    assign tvalid_m = ~fifo_empty_out;
endmodule