`timescale 1ns / 1ps
module tb_message_scheduler;
    reg clk, rst, init, final;
    reg [511:0] block;
    wire [31:0] w;
    wire mi, ml;

    Message_scheduler uut (
        .clk(clk), .rst(rst), .block(block), .init(init), .final(final),
        .w(w), .mi(mi), .ml(ml)
    );

    initial begin
        clk = 0;
        forever #5 clk = ~clk; // 100 MHz clock
    end
    
    initial begin
        rst = 1;
        init = 0;
        final = 0;
        block = 512'h61626380000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000018;
        #20 rst = 0;
        #15 init = 1;
        #10 init = 0;
        #1000 $finish;
    end
    
    initial begin
        $monitor("Time=%0t | w=%h | mi=%b | ml=%b | w_ctr=%0d | state=%b",
                 $time, w, mi, ml, uut.w_ctr, uut.state);
    end
endmodule