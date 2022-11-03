/*
    stream_2_vout_tb.v
    Testbench of stream to video out module
*/
`timescale 1ns/100ps

module stream_2_vout_tb ();
    // Parameters
    localparam CLK_PERIOD = 10;

    // Signals
    reg  clk, reset_n;

    // DUT
    reg  [4:0]  vin_r, vin_b;
    reg  [5:0]  vin_g;
    wire [15:0] sdata = {vin_r, vin_b, vin_g};
    wire        sfetch;
    reg         svalid;

    stream_2_video_out dut (
      .clk     (clk ),
      .reset_n (reset_n ),

      .sdata      (sdata ),
      .snextframe ( ),
      .sfetch     (sfetch ),
      .svalid     (svalid ),

      .video_r      ( ),
      .video_b      ( ),
      .video_g      ( ),
      .hsync        ( ),
      .vsync        ( ),
      .hblank       ( ),
      .vblank       ( ),
      .active_video ( )
    );

    
    // Process
    reg  sfetch_1;

    always @(posedge clk, negedge reset_n) begin
        if(!reset_n) begin
            vin_r    <= 0;
            vin_b    <= 0;
            vin_g    <= 0;

            svalid   <= 1'b0;

            sfetch_1 <= 0;
        end
        else begin
            sfetch_1 <= sfetch;

            if(sfetch_1) begin
                vin_r  <= {$random} % 32;
                vin_b  <= {$random} % 32;
                vin_g  <= {$random} % 64;

                svalid <= 1'b1;
            end
            else begin
                vin_r  <= 0;
                vin_b  <= 0;
                vin_g  <= 0;

                svalid <= 1'b0;
            end
        end
    end

    initial begin
        clk     = 1'b0;
        reset_n = 1'b0;

        repeat(10) @(posedge clk);
        reset_n = 1'b1;
    end

    always #(CLK_PERIOD / 2) clk = ~clk;

    always begin
        repeat(10000000) @(posedge clk);
        $stop();
    end
endmodule