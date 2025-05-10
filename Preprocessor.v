`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Preprocessor module for SHA-256 padding
//////////////////////////////////////////////////////////////////////////////////

module Preprocessor(
    input wire clk, rst,
    input wire [7:0] din,
    input wire dvalid,
    input wire dlast,
    input wire done,

    output reg tick,
    output reg final_block,
    output reg [511:0] msg_padded,
    output reg ready
);

    localparam IDLE = 3'd0;
    localparam RUN  = 3'd1;
    localparam ADD1 = 3'd2;
    localparam ADD0 = 3'd3;
    localparam LEN  = 3'd4;
    
    reg [2:0]  state;
    reg [7:0]  buff [0:63];
    reg [63:0] bitlen;
    reg [5:0]  tcount;
    reg [63:0] count;
    reg input_done;

    integer i;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            tcount       <= 0;
            count        <= 0;
            tick         <= 0;
            final_block  <= 0;
            msg_padded   <= 0;
            state        <= IDLE;
            for (i = 0; i < 64; i = i + 1)
                buff[i] <= 8'd0;
        end else begin
            tick         <= 0;
            final_block  <= 0;
            if (dvalid && dlast)
                input_done <= 1;
            case (state)
                IDLE: begin
                        if (dvalid) begin
                            buff[0] <= din;
                            count   <= 1;
                            tcount  <= 1;
                        end
                        input_done <= 0;
                        state   <= dlast ? ADD1 : RUN;
                end
                RUN: begin
                        if (dvalid)
                        begin
                            buff[tcount] <= din;
                            count <= count + 1;
                            tcount <= tcount + 1;;
                        end
                        if (tcount == 6'd63) 
                        begin
                            tick <= 1;
                            for (i = 0; i < 64; i = i + 1)
                                msg_padded[(63 - i)*8 +: 8] <= buff[i];
                            tcount <= 0;
                            state <= IDLE;
                        end
                        state <= dlast ? ADD1 : RUN;
                    end
                ADD1: begin
                        buff[tcount] <= 8'h80;
//                        count <= count + 1;
                        tcount <= tcount + 1;
                        if (tcount == 6'd63) begin
                            tick <= 1;
                            for (i = 0; i < 64; i = i + 1)
                                msg_padded[(63 - i)*8 +: 8] <= buff[i];
                            tcount <= 0;
                            state <= IDLE;
                        end
                        state <= (tcount == 6'd55) ? LEN : ADD0;
                end

                ADD0: begin
                    buff[tcount] <= 8'h00;
//                    count <= count + 1;
                    tcount <= tcount + 1;

                    if (tcount == 6'd63) 
                    begin
                        tick <= 1;
                        for (i = 0; i < 64; i = i + 1)
                            msg_padded[(63 - i)*8 +: 8] <= buff[i];
                        tcount <= 0;
                        state <= IDLE;
                    end
                        state <= (tcount == 6'd55) ? LEN : ADD0;
                end

                LEN: begin
                        bitlen <= count * 8;
                        tcount <= tcount + 1;
                        for (i = 0; i < 8; i = i + 1)
                            buff[56 + i] <= (bitlen) >> (8 * (7 - i));
 // V?i tcount t? 56 ??n 63
                        if (tcount == 6'd63) begin
                            final_block <= 1;
                            for (i = 0; i < 64; i = i + 1)
                                msg_padded[(63 - i)*8 +: 8] <= buff[i];
                            tcount <= 0;
                            state <= IDLE;
                        end else
                            state <= LEN;
                        if (done) state<=IDLE;
                    end
                default: state <= IDLE;
            endcase

        end
    end

    // Delay 1 cycle for ready
    always @(posedge clk or posedge rst) begin
        if (rst)
            ready <= 1;
        else
            ready <= (state == IDLE || !input_done);
    end

endmodule
