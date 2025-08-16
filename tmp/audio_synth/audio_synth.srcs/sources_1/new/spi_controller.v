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
    
localparam [1:0]
    startup = 2'b00,
    idle = 2'b01,
    com = 2'b10;
    
reg [1:0] state;
reg [1:0] state_next;
    
always @(*)
begin
    case (state)
    
        default: state_next = startup;
        
        startup:
        begin
            if (locked)
            begin
                state_next = idle;
            end
            else
            begin
                state_next = startup;
            end
        end
            
        idle:
        begin
            if (busy)
            begin
                state_next = com;
            end
            else
            begin
                state_next = state;
            end
        end
        
        com:
        begin
            if (!busy)
            begin
                state_next = idle;
            end
            else
                state_next = state;
            
        end
    endcase
end
    

// three states
// locked - clk_wiz has not stabilized, locked = 0
// idle - clock is stabilized but not in a SPI frame
// communicating - clock is stabilized and within a spi frame
endmodule
