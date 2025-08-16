`timescale 1ns / 1ps

// Note that this module works on a 15.625 MHz clock. can be scaled up based on subnode max freq

module tb_spi_master;

  // Inputs
  reg clk;
  reg rstn;
  reg start;
  wire sclk;
  wire csn;
  wire done;
  wire busy;
  wire [5:0] cntr_out;
  reg miso;
  wire [31:0] data_out;

  // Instantiate the SPI master
  spi_master uut (
    .clk(clk),
    .rstn(rstn),
    .start(start),
    .sclk(sclk),
    .csn(csn),
    .done(done),
    .busy(busy),
    .miso(miso),
    .cntr_out(cntr_out),
    .data_out(data_out)
  );

  // Clock generation
  always #32 clk = ~clk;  // 15.625 MHz system clock

  // SPI slave model — shift out dummy data
  reg [31:0] slave_data = 32'hA5A5_5A5A;  // Example data
  reg [5:0] bit_index = 31;

  always @(posedge sclk) begin
    if (!csn) begin
      miso <= slave_data[bit_index];
    end
  end
  
  always @(posedge sclk) begin
    if ((bit_index > 0) & (!csn)) begin
        bit_index <= bit_index - 1;
    end
  end

  // Test sequence
  initial begin
    // Initial state
    clk   = 0;
    rstn  = 0;
    start = 0;
    miso  = 0;
    #300;

    // Release reset
    rstn = 1;
    #64;

    // Pulse start for one clock
    @(posedge clk);
    start = 1;
    @(posedge clk);
    start = 0;

    // Wait for done
    wait (done == 1);
    @(posedge clk);  // Wait one extra cycle
    
    // Display result
    $display("SPI Output Data = %h", data_out);
    #200;
    
    rstn = 0;
    slave_data <= 32'hFF88FF99;
    bit_index <= 31;
    #100;
    
    rstn = 1;
    #64
    
    @(posedge clk);
    start = 1;
    @(posedge clk);
    start = 0;
    
    wait (done == 1);
    @(posedge clk);  // Wait one extra cycle
    
    // Display result
    $display("SPI Output Data = %h", data_out);
    #200;
    
    rstn = 0;
    slave_data <= 32'h00000000;
    bit_index <= 31;
    #100;
    
    rstn = 1;
    #64
    
    @(posedge clk);
    start = 1;
    @(posedge clk);
    start = 0;
    
    wait (done == 1);
    @(posedge clk);  // Wait one extra cycle
    
    // Display result
    $display("SPI Output Data = %h", data_out);
    #200;
    
    rstn = 0;
    slave_data <= 32'hE5F10DBD;
    bit_index <= 31;
    #100;
    
    rstn = 1;
    #64
    
    @(posedge clk);
    start = 1;
    @(posedge clk);
    start = 0;
    
    wait (done == 1);
    @(posedge clk);  // Wait one extra cycle
    
    // Display result
    $display("SPI Output Data = %h", data_out);

    // End simulation
    #200;
    
    
    
    $finish;
  end

endmodule
