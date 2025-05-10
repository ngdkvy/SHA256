`timescale 1ns / 1ps

module Message_scheduler(
    input wire clk,
    input wire rst,
    
    input wire [511:0] block,
    input wire init,
    input wire final,
    
    output reg mi,
    output reg ml,
    output reg [31:0] w
);

    // Define states
    localparam IDLE   = 2'b00;
    localparam INIT   = 2'b01;
    localparam UPDATE = 2'b10;

    reg [1:0] state, next_state;
    reg [5:0] w_ctr;
    reg [31:0] w_mem [0:15];
    reg [31:0] wnew;
    integer i;

    // Function for sigma0
    function [31:0] sigma0;
        input [31:0] x;
        begin
            sigma0 = {x[6:0], x[31:7]} ^ {x[17:0], x[31:18]} ^ (x >> 3);
        end
    endfunction

    // Function for sigma1
    function [31:0] sigma1;
        input [31:0] x;
        begin
            sigma1 = {x[16:0], x[31:17]} ^ {x[18:0], x[31:19]} ^ (x >> 10);
        end
    endfunction

    // Sequential logic for state and memory updates
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            w_ctr <= 6'd0;
            state <= IDLE;
            for (i = 0; i < 16; i = i + 1)
                w_mem[i] <= 32'd0;
        end else begin
            state <= next_state;
            case (next_state)
                INIT: begin
                    w_mem[w_ctr] <= block[511 - w_ctr*32 -: 32];
                    if (w_ctr < 6'd15) begin
                        w_ctr <= w_ctr + 1;
                    end else begin
                        w_ctr <= w_ctr + 1;
                    end
                end
                UPDATE: begin
                    for (i = 0; i < 15; i = i + 1)
                        w_mem[i] <= w_mem[i+1];
                    w_mem[15] <= wnew;
                    if (w_ctr == 6'd63) begin
                        w_ctr <= 6'd0;
                    end else begin
                        w_ctr <= w_ctr + 1;
                    end
                end
                default: begin
                    w_ctr <= 6'd0;
                end
            endcase
        end
    end

    // Combinatorial logic for next state and outputs
    always @(*) begin
        // Default assignments
        next_state = state;
        mi = 1'b0;
        ml = 1'b0;
        wnew = w_mem[0] + sigma0(w_mem[1]) + w_mem[9] + sigma1(w_mem[14]);
        w = 32'd0;

        case (state)
            IDLE: begin
                if (init) begin
                    next_state = INIT;
                    mi = 1'b1;
                    w = block[511:480]; // Immediately assign w for w_ctr = 0
                end
            end
            INIT: begin
                mi = 1'b1;
                w = block[511 - w_ctr*32 -: 32]; // Assign w combinatorially
                if (w_ctr == 6'd15) begin
                    next_state = UPDATE;
                end
            end
            UPDATE: begin
                mi = 1'b1;
                w = wnew; // Assign w combinatorially
                if (w_ctr == 6'd63) begin
                    ml = 1'b1;
                    next_state = IDLE;
                end
            end
        endcase
    end
endmodule