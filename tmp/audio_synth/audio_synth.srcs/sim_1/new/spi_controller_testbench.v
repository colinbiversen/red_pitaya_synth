`timescale 1ns / 1ps

module spi_controller_tb();

// Testbench signals
reg locked;
reg clk_in;
wire start;
wire rstn;
wire clk_out;

// Test control variables
integer test_count;
integer error_count;

// Clock generation (30 MHz = 33.33ns period)
initial begin
    clk_in = 0;
    forever #16.67 clk_in = ~clk_in;  // 30 MHz clock
end

// Instantiate the DUT (Device Under Test)
spi_controller dut (
    .locked(locked),
    .clk_in(clk_in),
    .start(start),
    .rstn(rstn),
    .clk_out(clk_out)
);

// Main test sequence
initial begin
    $display("=== SPI Controller Testbench Starting ===");
    
    // Initialize signals
    locked = 0;
    test_count = 0;
    error_count = 0;
    
    // Wait for a few clock cycles
    #200;
    
    // Test 1: Verify startup state
    test_count = test_count + 1;
    $display("Time %0t: Test %0d - Startup state", $time, test_count);
    if (dut.state != 2'b00 || rstn != 0 || start != 0 || clk_out != 0) begin
        $display("ERROR: Startup state incorrect!");
        error_count = error_count + 1;
    end else begin
        $display("PASS: Startup state correct");
    end
    
    // Test 2: Assert locked and verify transition to IDLE
    test_count = test_count + 1;
    $display("Time %0t: Test %0d - Transition to IDLE", $time, test_count);
    locked = 1;
    repeat(5) @(posedge clk_in);
    if (dut.state != 2'b01 || rstn != 0 || start != 0 || clk_out != clk_in) begin
        $display("ERROR: Idle state incorrect!");
        error_count = error_count + 1;
    end else begin
        $display("PASS: Idle state correct");
    end
    
    // Test 3: Wait for first IDLE->COM transition and check start pulse
    test_count = test_count + 1;
    $display("Time %0t: Test %0d - First COM transition and start pulse", $time, test_count);
    
    // Fast forward to near the transition
    while (dut.clk_cntr < 1020) begin
        @(posedge clk_in);
    end
    
    // Watch for the transition and start pulse
    while (dut.clk_cntr != 1024) begin
        @(posedge clk_in);
    end
    @(posedge clk_in);
    
    if (dut.state != 2'b10 || rstn != 1) begin
        $display("ERROR: COM state setup incorrect!");
        error_count = error_count + 1;
    end
    if (start != 1) begin
        $display("ERROR: Start pulse missing!");
        error_count = error_count + 1;
    end else begin
        $display("PASS: COM state and start pulse correct");
    end
    
    // Test 4: Check locked going low
    test_count = test_count + 1;
    $display("Time %0t: Test %0d - Test locked signal loss", $time, test_count);
    repeat(10) @(posedge clk_in);
    locked = 0;
    @(posedge clk_in);
    
    if (dut.state != 2'b00) begin
        $display("ERROR: Should return to startup when locked goes low!");
        error_count = error_count + 1;
    end else begin
        $display("PASS: Correctly returned to startup");
    end
    
    // Final results
    $display("\n=== TEST SUMMARY ===");
    $display("Total tests: %0d", test_count);
    $display("Errors: %0d", error_count);
    if (error_count == 0) begin
        $display("ALL TESTS PASSED!");
    end else begin
        $display("SOME TESTS FAILED!");
    end
    
    $finish;
end

// Optional monitor for debugging (comment out for cleaner output)
/*
always @(posedge clk_in) begin
    $display("Time %0t: state=%s, counter=%d, locked=%b, rstn=%b, start=%b", 
             $time, 
             (dut.state == 2'b00) ? "STARTUP" : 
             (dut.state == 2'b01) ? "IDLE" : 
             (dut.state == 2'b10) ? "COM" : "UNKNOWN",
             dut.clk_cntr, locked, rstn, start);
end
*/

// Timeout safety
initial begin
    #100000; // 100us timeout
    $display("ERROR: Testbench timeout!");
    $finish;
end

endmodule