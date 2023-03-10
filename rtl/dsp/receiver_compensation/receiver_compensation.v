/*
    receiver_compensation.v
    Receiver compensation
*/

module receiver_compensation #(
    parameter DW       = 16,
    parameter MEM_FILE = "test.mem",
    parameter DATA_CNT = 1024
) (
    input  wire clk,
    input  wire reset_n,

    // Input AXI-Stream
    input  wire [DW-1:0] tdata_s,
    input  wire          tvalid_s,
    input  wire          tlast_s,
    input  wire          tuser_s,
    output wire          tready_s,

    // Output AXI-Stream
    output reg  [DW-1:0] tdata_m,
    output reg           tlast_m,
    output reg           tuser_m,
    output reg           tvalid_m,
    input  wire          tready_m,

    // AHB Control Interface
    // HCLK, HRESETn are combined into global signals.
    input  wire [31:0]     haddr_s,
    input  wire [2:0]      hburst_s,
    // Locked sequence (HMASTLOCK) is not used.
    // Protection option (HPROT[6:0]) is not used.
    input  wire [2:0]      hsize_s,
    // Secure transfer (HNONSEC) is not used.
    // Exclusive transfer (HEXCL) is not used.
    // Master identifier (HMASTER[3:0]) is not used.
    input  wire [1:0]      htrans_s,
    input  wire [31:0]     hwdata_s,
    input  wire            hwrite_s,

    output reg  [31:0]     hrdata_s,
    output reg  [31:0]     hreadyout_s,
    output reg             hresp_s,
    // Exlusive transfer is not available, thus HEXOKAY signal is not used.

    input  wire            hsel_s
);


    // Data input
    reg  signed [DW-1:0] data;
    reg         [DW-1:0] data_0;
    reg         [9:0]    idx;

    reg                  valid_0, valid_1;
    reg                  last_0;
    reg                  user_0, user_1;

    always @(posedge clk, negedge reset_n) begin
        if(!reset_n) begin
            data    <= 0;
            data_0  <= 0;
            idx     <= 0;

            valid_0 <= 1'b0;
            valid_1 <= 1'b0;
            last_0  <= 1'b0;
            user_0  <= 1'b0;
            user_1  <= 1'b0;
        end
        else begin
            if(tvalid_s && tready_s) begin
                if(tlast_s)
                    idx <= 0;
                else
                    idx <= idx + 1;

                data_0 <= tdata_s;
                data   <= data_0;

                last_0 <= tlast_s;
            end

            valid_0 <= tvalid_s;
            valid_1 <= valid_0;
            user_0  <= tuser_s;
            user_1  <= user_0;
        end
    end

    // AHB Interface
    reg  [31:0] haddr_last;

    // Window coefficients
    reg  signed [DW-1:0] coeff_r;
    reg         [DW-1:0] coeff_r1_ahb;
    reg                  coeff_we;

    reg  [DW-1:0] coeffs [0:1023];
    initial begin
        $readmemh(MEM_FILE, coeffs);    
    end

    always @(posedge clk, negedge reset_n) begin
        if(!reset_n) begin
            coeff_r      <= 0;
            coeff_r1_ahb <= 0;
        end
        else begin
            if(coeff_we)
                coeffs[haddr_last[9:1]] <= hwdata_s[15:0];

            coeff_r      <= coeffs[idx];
            coeff_r1_ahb <= coeffs[haddr_s[9:1]];
        end
    end

    // Windowing
    wire signed [DW-1:0] result;
    assign result = data - coeff_r;

    // Output
    always @(posedge clk, negedge reset_n) begin
        if(!reset_n) begin
            tdata_m  <= 0;
            tvalid_m <= 1'b0;
            tlast_m  <= 1'b0;
            tuser_m  <= 1'b0;
        end
        else begin
            if(tvalid_m && tready_m) begin
                tdata_m <= result;
            end

            tvalid_m <= valid_1;
            tlast_m  <= last_0;
            tuser_m  <= user_0;
        end
    end

    assign tready_s = tready_m;

    `include "ahb_intf_receiver_compensation.v"
endmodule