`timescale 1ns / 1ps
module tb_compute_v1_0;
    reg clk, rst, tick, final;
    reg [511:0] block;
    wire [255:0] digest;
    wire done;

    compute_v1_0 uut (
        .clk(clk), .rst(rst), .tick(tick), .final(final), .block(block),
        .digest(digest), .done(done)
    );

    initial begin
        clk = 0;
        forever #5 clk = ~clk; // 100 MHz clock
    end
    
    initial begin
        rst = 0;
        tick = 0;
        final = 0;
        #30;
        block = 512'h61626380000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000018;
        #20 rst = 1; // Release reset
        #10 tick = 1; // Start computation
        #10 tick = 0;
        #1000 if (done) $display("Digest: %h", digest);
        #10 $finish;
    end
    
    initial begin
        $monitor("Time=%0t | digest=%h | done=%b", $time, digest, done);
    end
endmodule