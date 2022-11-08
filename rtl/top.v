/*
    top.v
    Top module
*/
module top(
    input  wire clk_sys,
    input  wire reset_n,

    // ADC Input
    input  wire [9:0]  adc_in,
    output wire        adc_sel,
    output wire        adc_clk,

    // UART
    output wire        uart_tx,
    input  wire        uart_rx,

    // GPIO
    inout  wire [31:0] gpio,
    output wire        test,

    // SPI Master
    output wire        spi_sck,
    input  wire        spi_miso,
    output wire        spi_mosi,
    output wire  [1:0] spi_ss_n,

    // MSI001
    output wire        dem_ref_clk,
    output wire        dem_sdi,
    output wire        dem_sck,
    output wire        dem_sen,

    // Flash
    inout  wire        flash_clk,
    inout  wire        flash_miso,
    inout  wire        flash_mosi,
    inout  wire        flash_csn
);

    wire  hclk;

    pll_sys pll0(
        .clkin(clk_sys),
        .clkout(hclk)
    );

    // MSI001 driver
    assign dem_ref_clk = clk_sys;
    assign dem_sdi     = spi_mosi;
    assign dem_sck     = spi_sck;
    assign dem_sen     = ~spi_ss_n[0];

    assign test        = 1'b0;

    // Modules
    wire [15:0] tdata;
    wire        tvalid;
    wire        tready;

    adc_input_ad9201 adc_input (
        .clk       (hclk ),
        .reset_n   (reset_n ),

        .adc_input  (adc_in ),
        .adc_iq_sel (adc_sel ),
        .adc_clk    (adc_clk ),

        .tdata_m  (tdata ),
        .tvalid_m (tvalid ),
        .tready_m (tready )
    );
  

    wire [31:0] haddr;
    wire [2:0]  hburst;
    wire [2:0]  hsize;
    wire [1:0]  htrans;
    wire [31:0] hwdata;
    wire        hwrite;
    wire [31:0] hrdata;
    wire        hreadyout;
    wire        hresp;
    wire        hsel;

    wire [31:0] interrupts;

    dsp_subsystem dsp0(
        .hclk (hclk ),
        .hresetn (reset_n ),
        .ce(1'b1),

        .tdata_s   (tdata ),
        .tvalid_s  (tvalid ),
        .tready_s  (tready),

        .haddr_s     (haddr ),
        .hburst_s    (hburst ),
        .hsize_s     (hsize ),
        .htrans_s    (htrans ),
        .hwdata_s    (hwdata ),
        .hwrite_s    (hwrite ),
        .hrdata_s    (hrdata ),
        .hreadyout_s (hreadyout ),
        .hresp_s     (hresp ),
        .hsel_s      (hsel ),

        .interrupts (interrupts)
    );

    Gowin_PicoRV32_Top core(
        .clk_in   (hclk), //input clk_in
		.resetn_in(reset_n), //input resetn_in

		.ser_tx (uart_tx), //output ser_tx
		.ser_rx (uart_rx), //input ser_rx

		.gpio_io(gpio), //inout [31:0] gpio_io

		.wbspi_master_miso (spi_miso), //input wbspi_master_miso
		.wbspi_master_mosi (spi_mosi), //output wbspi_master_mosi
		.wbspi_master_ssn  (spi_ss_n), //output [1:0] wbspi_master_ssn
		.wbspi_master_sclk (spi_sck), //output wbspi_master_sclk

		.io_spi_clk  (flash_clk), //inout io_spi_clk
		.io_spi_csn  (flash_csn), //inout io_spi_csn
		.io_spi_mosi (flash_mosi), //inout io_spi_mosi
		.io_spi_miso (flash_miso), //inout io_spi_miso

		.hrdata (hrdata), //input [31:0] hrdata
		.hresp  (hresp), //input [1:0] hresp
		.hready (hreadyout), //input hready
		.haddr  (haddr), //output [31:0] haddr
		.hwrite (hwrite), //output hwrite
		.hsize  (hsize), //output [2:0] hsize
		.hburst (hburst), //output [2:0] hburst
		.hwdata (hwdata), //output [31:0] hwdata
		.hsel   (hsel), //output hsel
		.htrans (htrans), //output [1:0] htrans

		.irq_in( ), //input [31:20] irq_in

		.jtag_TDI( ), //input jtag_TDI
		.jtag_TDO( ), //output jtag_TDO
		.jtag_TCK( ), //input jtag_TCK
		.jtag_TMS( )  //input jtag_TMS
	);

endmodule