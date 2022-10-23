/*
    integrator.v
    CIC integrator
*/
module integrator #(
    parameter DW = 16
)(
    input  wire clk,
    input  wire reset_n,
    input  wire ce,

    input  wire signed [DW-1:0] din,
    output reg  signed [DW-1:0] dout
);

    always @(posedge clk, negedge reset_n) begin
        if(!reset_n)
            dout <= {DW{1'b0}};
        else begin
        if(ce)
            dout <= din + dout;
        end
    end
endmodule