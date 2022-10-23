/*
${header_comment}
*/
module axi_regif_template(
    /* Signal I/O */
    ${reg_field_define}

    /* Configure interface, AXI-4 Lite */
    // Global
    input  wire        aclk_s,         //! Slave interface clock
    input  wire        aresetn_s,      //! Slave interface reset, active low
    input  wire        ce,             //! Slave interface clock enable
    // Write address channel
    input  wire [31:0] awaddr_s,       //! Write address channel address
    input  wire [2:0]  awprot_s,       //! Write address channel protection bits, no sense
    input  wire        awvalid_s,      //! Write address channel valid
    output reg         awready_s,      //! Write address channel ready
    // Write data channel
    input  wire [31:0] wdata_s,        //! Write data channel data
    input  wire [3:0]  wstrb_s,        //! Write data channel byte strobes
    input  wire        wvalid_s,       //! Write data channel valid
    output reg         wready_s,       //! Write data channel ready
    // Read address channel
    input  wire [31:0] araddr_s,       //! Read address channel address
    input  wire [1:0]  arprot_s,       //! Read address channel protection bits, no sense
    input  wire        arvalid_s,      //! Read address channel valid
    output reg         arready_s,      //! Read address channel ready
    // Read data channel
    output reg  [31:0] rdata_s,        //! Read data channel data
    output reg  [1:0]  rresp_s,        //! Read data channel response
    output reg         rvalid_s,       //! Read data channel valid
    input  wire        rready_s,       //! Read data channel ready
    // Write response channel
    output reg  [1:0]  bresp_s,        //! Write response channel response code, always OKAY
    output reg         bvalid_s,       //! Write response channel valid
    input  wire        bready_s        //! Write response channel ready
);

    /* AXI4 FSM */
    reg  [1:0]  conf_if_state;
    reg  [31:0] conf_if_addr;

    localparam STAT_IDLE  = 2'h0;
    localparam STAT_RDATA = 2'h1;
    localparam STAT_WDATA = 2'h2;
    localparam STAT_WRESP = 2'h3;

    always @(posedge aclk_s, negedge aresetn_s) begin
        if(!aresetn_s) begin
            // State machine reset
            conf_if_state  <= STAT_IDLE;
            conf_if_addr   <= 32'h0;
        end
        else begin
        if(ce) begin
            case(conf_if_state)
                STAT_IDLE:begin
                    if(awvalid_s && awready_s) begin
                        // Write data
                        conf_if_state <= STAT_WDATA;
                        conf_if_addr  <= awaddr_s;
                    end
                    else if(arvalid_s && arready_s) begin
                        // Read data
                        conf_if_state <= STAT_RDATA;
                        conf_if_addr  <= araddr_s;
                    end
                end
                STAT_RDATA:begin
                    if(rvalid_s && rready_s)
                        conf_if_state <= STAT_IDLE;
                end
                STAT_WDATA:begin
                    if(wvalid_s && wready_s)
                        conf_if_state <= STAT_WRESP;
                end
                STAT_WRESP:begin
                    if(bvalid_s && bready_s)
                        conf_if_state <= STAT_IDLE;
                end
            endcase
        end
        end
    end

    always @(*) begin
        case(conf_if_state)
            STAT_RDATA:begin
                // Write address
                awready_s = 1'b0;
                // Read address
                arready_s = 1'b0;
                // Write data
                wready_s  = 1'b0;
                // Read data
                rdata_s   = read_reg(conf_if_addr);
                rresp_s   = 2'b0;      // Always OKAY
                rvalid_s  = 1'b1;
                // Write response
                bresp_s   = 2'b00;
                bvalid_s  = 1'b0;
            end
            STAT_WDATA:begin
                // Write address
                awready_s = 1'b0;
                // Read address
                arready_s = 1'b0;
                // Write data
                wready_s  = 1'b1;
                // Read data
                rdata_s   = 32'h0;
                rresp_s   = 2'b0;
                rvalid_s  = 1'b0;
                // Write response
                bresp_s   = 2'b00;
                bvalid_s  = 1'b0;
            end
            STAT_WRESP:begin
                // Write address
                awready_s = 1'b0;
                // Read address
                arready_s = 1'b0;
                // Write data
                wready_s  = 1'b0;
                // Read data
                rdata_s   = 32'h0;
                rresp_s   = 2'b0;
                rvalid_s  = 1'b0;
                // Write response
                bresp_s   = 2'b00;
                bvalid_s  = 1'b1;
            end
            default:begin       // IDLE, default
                // Write address
                awready_s = 1'b1;
                // Read address
                arready_s = 1'b1;
                // Write data
                wready_s  = 1'b0;
                // Read data
                rdata_s   = 32'h0;
                rresp_s   = 2'b0;
                rvalid_s  = 1'b0;
                // Write response
                bresp_s   = 2'b00;
                bvalid_s  = 1'b0;
            end
        endcase
    end

    /* Register access */
    // Registers
    ${reg_define}

    // Register read
    function [31:0] read_reg;
        input  [31:0] addr;
    begin
        case(addr[31:2])
            ${reg_read}
        endcase
    end
    endfunction

    // Register write
    always @(posedge aclk_s, negedge aresetn_s) begin
        if(!aresetn_s) begin
            ${reg_reset}
        end
        else begin
        if(ce) begin
            if((conf_if_state == STAT_WDATA) && (wvalid_s && wready_s)) begin
                case(conf_if_addr[31:2])
                    ${reg_write}
                endcase
            end
            else begin
                ${reg_field_update}
            end
        end
        end
    end

    /* Register fields output */
    ${reg_field_assign}
endmodule