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
    output wire [15:0] tdata_m,
    output wire        tuser_m,
    output wire        tlast_m,
    output wire        tvalid_m,
    input  wire        tready_m
);

    // Parameters
    localparam DATA_COUNT = 1023;
	// Input FIFO
	wire fifo_full_in, fifo_full_out;
    reg  fifo_input_ien;

    wire [15:0] fft_din;
    reg         fft_read, fft_start;

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

    fifo_fft_in fifo_input(
        .Clk(clk),
        .Reset(~reset_n),
        
        // Data I/O
        .Data (tdata_s),
        .WrEn (tvalid_s && (fifo_input_ien || tuser_s)),
        .Q    (fft_din),
        .RdEn (fft_read),

		// Flags
        .Full(fifo_full_in),
		.Empty( )
    );

    // Input flow control
    assign tready_s = (~fifo_full_in) && (~fifo_full_out);

	// FFT
    // [Grinning face with sweat]
    wire [15:0] fft_dout_re;
    wire [15:0] fft_dout_im;
    wire        fft_input_end, fft_input_proc;
    wire        fft_output_proc;	// Output in process
    wire        fft_output_start, fft_output_end;
    wire        fft_busy;

    // FFT control FSM
    reg  [1:0] fft_stat;

    localparam FFT_IDLE  = 2'b00;
    localparam FFT_WAIT  = 2'b01;
    localparam FFT_BEGIN = 2'b10;
    localparam FFT_READ  = 2'b11;

    always @(posedge clk, negedge reset_n) begin
		if(!reset_n)
        	fft_stat <= FFT_IDLE;
        else begin
			case(fft_stat)
            FFT_IDLE:begin
                if(fifo_full_in && (~fft_busy))
                    fft_stat <= FFT_WAIT;
            end
            FFT_WAIT:begin
                if(~fft_output_proc)
                    fft_stat <= FFT_BEGIN;
            end
            FFT_BEGIN:fft_stat <= FFT_READ;
            FFT_READ:begin
                if(fft_input_end || (~fft_input_proc)) begin
                    if(fifo_full_in)
                        fft_stat <= FFT_BEGIN;
                    else
                        fft_stat <= FFT_IDLE;
                end
            end
            endcase
        end
    end

    always @(*) begin
        case(fft_stat)
        FFT_IDLE, FFT_WAIT:begin
            fft_read  = 1'b0;
            fft_start = 1'b0;
        end
        FFT_BEGIN:begin
            fft_read  = 1'b0;
            fft_start = 1'b1;
        end
        FFT_READ:begin
            fft_read  = 1'b1;
            fft_start = 1'b0;
        end
        default:begin
            fft_read  = 1'b0;
            fft_start = 1'b0;
        end
        endcase
    end

	fft_ip fft(
        .clk (clk),
        .rst (~reset_n),

        // Data I/O
        .xn_re (fft_din),
        .xn_im (0),
        .xk_re (fft_dout_re),
        .xk_im (fft_dout_im),

		// Start
        .start (fft_start),

        // Status signals
        .sod ( ),
        .ipd (fft_input_proc),
        .eod (fft_input_end),

        .soud (fft_output_start),
        .opd  (fft_output_proc),
        .eoud (fft_output_end),

        .busy (fft_busy)
    );

    wire [15:0] modulus;
    wire        modulus_start, modulus_last;
    wire        modulus_valid;

    modulus #(
      .DW(16 )
    )modulus_dut (
        .clk     (clk ),
        .reset_n (reset_n ),
        .ce      (ce ),

        .tdata_s  ({fft_dout_im, fft_dout_re}),
        .tuser_s  (fft_output_start),
        .tlast_s  (fft_output_end ),
        .tvalid_s (fft_output_proc ),
        .tready_s ( ),

        .tdata_m  (modulus ),
        .tuser_m  (modulus_start ),
        .tlast_m  (modulus_last ),
        .tvalid_m (modulus_valid ),
        .tready_m (1'b1 )
    );

    // Output
    wire fifo_empty_out;

	fifo_fft_out fifo_output(
		.Clk   (clk),
        .Reset (~reset_n),

        // Data I/O
        .Data (modulus),
        .WrEn (modulus_valid),
        .Q    (tdata_m),
        .RdEn (tready_m),

        // Flags
		.Empty (fifo_empty_out),
        .Full  (fifo_full_out)
    );

    // Data counter
    reg  [15:0] cnt;
    
    always @(posedge clk, negedge reset_n) begin
		if(!reset_n)
            cnt <= DATA_COUNT;
        else begin
            if(tvalid_m && tready_m) begin
                if(cnt == 0) begin
                    if(~fifo_empty_out)
                        cnt <= DATA_COUNT;
                end
                else
                    cnt <= cnt - 1;
            end
        end
    end

    assign tlast_m  = (cnt == 0);
    assign tuser_m  = (cnt == DATA_COUNT);
    assign tvalid_m = ~fifo_empty_out;
endmodule