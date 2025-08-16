`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Engineer: Colin Iversen
// 
// Create Date: 07/20/2025 01:11:43 PM
// Design Name: RP-TM4C SPI Interface
// Module Name: spi_master
// Project Name: synth_engine_v01_rp
// Target Devices: Zynq 7000 SoC
// Tool Versions: 2025.1
//
// This SPI main module is built to operate CPOL/CPHA 00. It is built with a single chip select signal,
// which is meant to be used with the TM4C microcontroller or any microcontroller that uses the SSI protocol.
// Function: SPI controller following SSI protocol for 16-bit communication, concatenating 2 sequential SPI frames
// Use: 
// input a divided clock (up to 45 MHz) as 'clk'
// input a active low reset signal. 'rstn' must be pulsed low before any communication 32-bit frame.
//          'rstn' does not need to be pulsed between 16-bit spi frames of the same 32-bit word.
// input a start signal. 'start' needs to be pulsed high in order to start communication
// 
// order of operation: 'rstn' pulse low, 'start' pulse high, MISO data is clocked into reg, then released
// when communication stops into 'data_out'. Data must be recieved by other modules before rstn is pulled low.
// 'data_out' reg will be reset and data lost if rstn is pulled low before data is retrieved.
//  
//
//
// output 'busy' is pulled high = !csn during whole 32 bit word transfer.
// output 'done' is pulsed high when commuication per 32 bit word transfer is done.
//
// Dependencies: -
// 
// Revision: v01
// Additional Comments: -
// 
//////////////////////////////////////////////////////////////////////////////////

module spi_master(
    input  wire        locked,
    input  wire        clk,         // System clock, divided to 3.9 MHz
    input  wire        rstn,         // Synchronous reset
    input  wire        start,       // Start capture
    output reg         busy,        // Active while receiving
    output reg         done,        // Pulse high for one cycle at end

    output reg         sclk,        // SPI clock (output to slave)
    output reg         csn,        // Active-low chip select (output to slave)
    input  wire        miso,        // Data from slave
    //output reg         mosi,

    output reg [31:0]  data_out,    // Final received data
    output reg [5:0]   cntr_out
);
// FSM with 5 states, one-hot encoding
// S0 = Idle : CSN high, no data
// S1 = Start_0 : CSN low, CLK low, MISO configured to receive as input. start transfer of 16 MSB's
// S2 = Receive_0 : CSN low, CLK high, MISO reads input bit
// S3 = Shift_0 : CSN low, CLK low, MISO shifts input bit
// S4 = Pause: CSN high for a few clock cyles
// S5 = Start_1 : CSN low, CLK low, MISO configured to receive as input. start transfer of 16 LSB's
// S6 = Receive_1 : CSN low, CLK high, MISO reads input bit
// S7 = Shift_1 : CSN low, CLK low, MISO shifts input bit
// S8 = Done: CSN high, done

localparam [4:0] 
  spi_idle          = 5'b00000,
  data_start_0      = 5'b00010,
  data_receive_0    = 5'b00100,
  data_shift_0      = 5'b01000,
  spi_pause         = 5'b00001,
  data_start_1      = 5'b00011,
  data_receive_1    = 5'b00101,
  data_shift_1      = 5'b01001,
  spi_done          = 5'b10000;

parameter data_length_d = 32; // length that will be concatenated, will zero-pad to MSB
parameter max_data_transfer_d = 16; // max data transfer per SPI frame (tm4c supports 16 max)

reg [4:0] state;
reg [4:0] state_next;
reg [$clog2(data_length_d) - 1:0] cntr;
reg [data_length_d - 1:0] shift_reg;
reg buffer;

// combinational next state logic for FSM (do not worry about asynch reset)
always @(*)
begin
    case (state)
        default: state_next = spi_idle;
        
        spi_idle:
        begin
            if (start)
            begin
                state_next = data_start_0;
            end
            else
            begin
                state_next = spi_idle;
            end
        end
        data_start_0:
        begin
            state_next = data_receive_0;
        end
        data_receive_0:
        begin
            state_next = data_shift_0;
        end
        data_shift_0:
        begin
            if (cntr < (max_data_transfer_d - 1))
            begin
                state_next = data_receive_0;
            end
            else if (cntr == (max_data_transfer_d - 1))
            begin
                state_next = spi_pause;
            end
            else
            begin
                state_next = spi_idle;
            end
        end
        spi_pause:
        begin
            state_next = data_start_1;
        end
        data_start_1:
        begin
            state_next = data_receive_1;
        end
        data_receive_1:
        begin   
            state_next = data_shift_1;
        end
        data_shift_1:
        begin
            if (cntr < data_length_d - 1)
            begin
                state_next = data_receive_1;
            end
            else if (cntr == data_length_d - 1)
            begin
                state_next = spi_done;
            end
            else
            begin 
                state_next = spi_idle;
            end
        end
        spi_done:
        begin
            state_next = spi_idle;
        end
    endcase
end

always @(posedge clk)
begin
    cntr_out <= cntr;
end

// synchronous reset output and state assignment
always @(posedge clk) 
begin
    if (!rstn)
    begin
        state    <= spi_idle;
        csn      <= 1'b1;
        busy     <= 1'b0;
        done     <= 1'b0;
        sclk     <= 1'b0;
        cntr     <= 0;
        shift_reg <= 0;
    end 
    else
    begin
        state <= state_next; // do not need to change states in any other sequential block
    end
end

// Shift register for sampling MISO and shifting data out
always @(posedge clk) begin
    if (!rstn) begin
        shift_reg <= 0;
        cntr <= 0;
    end else begin
        case (state)
            data_receive_0, data_receive_1: begin
                // give an extra clk cycle for miso to latch
            end
            
            data_shift_0, data_shift_1: begin
                shift_reg <= {shift_reg[data_length_d-2:0], miso};
                cntr <= cntr + 1;
            end

            data_start_0: begin
                cntr <= 0;
            end

            default: begin
                // No change to shift_reg
                cntr <= cntr;
            end
        endcase
    end
end

// sclk and csn output for subnode control
always @(posedge clk) begin
    if (!rstn) begin
        sclk <= 0;
        csn <= 1;
    end else begin
        case (state)
            spi_idle, spi_done, spi_pause: begin
                csn <= 1;
                sclk <= 0;
            end
            data_start_0, data_start_1, data_shift_0, data_shift_1: begin
                csn <= 0;
                sclk <= 0;
            end
            data_receive_0, data_receive_1: begin
                csn <= 0;
                sclk <= 1;
            end
        endcase
    end
end    

// busy and done signals
always @(posedge clk) begin
    if (!rstn) begin
        busy <= 0;
        done <= 0;
    end else begin
        busy <= (state != spi_idle && state != spi_done);
        done <= (state == spi_done);
    end
end

// Output captured data
always @(posedge clk) begin
    if (!rstn) begin
        data_out <= 32'b0;
    end else if (state == spi_done) begin
        data_out <= shift_reg;
    end
end


endmodule
