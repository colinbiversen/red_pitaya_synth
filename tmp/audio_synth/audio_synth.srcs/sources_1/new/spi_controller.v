`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08/14/2025 07:11:31 PM
// Design Name: 
// Module Name: spi_controller
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: This controller will control the spi_master RTL module.
// It will wait for a clk_wiz IP block to be unlocked (locked == 1), where it will ingest signals
// from the SPI master in order to start the next spi frame.
// inputs: busy, done, 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module spi_controller(
    input wire locked,
    input wire busy,
    input wire clk,
    output reg start,
    output reg rstn
    );

// three states
// locked - clk_wiz has not stabilized, locked = 0
// idle - clock is stabilized but not in a SPI frame
// communicating - clock is stabilized and within a spi frame
endmodule
