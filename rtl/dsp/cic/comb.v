/*
    comb.v
    CIC comb
*/
module comb #(
    parameter DW = 16,
    parameter M  = 1
)(
    input  wire clk,
    input  wire reset_n,
    input  wire ce,

    input  wire signed [DW-1:0] din,
    output reg  signed [DW-1:0] dout
);

    reg signed [DW-1:0] din_0[0:M-1];
    integer i;
    always @(posedge clk, negedge reset_n) begin
        if(!reset_n) begin
            dout  <= 0;

            for(i = 0;i < M;i = i + 1)
                din_0[i] <= 0;
        end
        else begin
        if(ce) begin
            dout  <= din - din_0[M-1];

            din_0[0] <= din;

            if(M > 1) begin
                for(i = 1;i < M;i = i + 1)
                    din_0[i] <= din_0[i-1];
            end
        end
        end
    end
endmodule