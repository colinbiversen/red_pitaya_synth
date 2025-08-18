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
    input wire clk_in, // 30 MHz
    output reg start,
    output reg rstn,
    output reg clk_out
    );
    
reg [10:0] clk_cntr;
reg [1:0] state;
reg [1:0] state_next;

localparam [1:0]
    startup = 2'b00,
    idle = 2'b01,
    com = 2'b10;
    
always @(posedge clk_in)
begin
    state <= state_next;
end
    
// default in startup:
// signals in startup: rstn == 0 , start == 0, clk_out == 0
//
// enter idle if locked == 1:
// signals in idle: rstn = 0, start == 0, clk_out == clk_in
//
// enter com if cntr == 1024:
// signals in com: rstn = 1, start is pulsed for 1 clock cyle (clk_cntr == 1024), clk_out == clk_in

always @(posedge clk_in)
begin
    case (state)
        default: clk_cntr <= 0;
        startup:
        begin
            rstn <= 0;
            start <= 0;
            clk_out <= 0;
        end
        idle:
        begin
            rstn <= 0;
            clk_out <= clk_in;
            start <= 0;
        end
        com:
        begin
            rstn <= 1;
            clk_out <= clk_in;
            
        
    endcase
end

always @(*) 
begin
    case (state)
        default: state_next = startup;
        startup:
        begin
            if(locked) begin
                state_next = idle;
            end
            else begin
                state_next = state;
            end
        end
        idle:
        begin
            if (clk_cntr < 1024) begin
                state_next = state;
            end
            else if (clk_cntr == 1024) begin
                state_next = com;
            end
        end
        com:
        begin
            if (clk_cntr < 2047) begin
                state_next = state;
            end
            else if (clk_cntr == 2047) begin
                state_next = idle;
            end
        end
    endcase 
end

        

end
    


endmodule
