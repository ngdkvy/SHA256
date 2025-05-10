`timescale 1ns / 1ps

module tb_preprocessor;

    // Inputs
    reg         clk;
    reg         rst;
    wire        ready;
    reg  [7:0]  din ;
    reg         dvalid;
    reg         dlast;

    wire        tick;
    wire        final_block;
    wire [511:0] msg_padded;
    reg        done;


    // Instantiate the Unit Under Test (UUT)
    Preprocessor uut (
        .clk(clk),
        .rst(rst),
        .dvalid(dvalid),
        .dlast(dlast),
        .din(din),
        .ready(ready),
        .tick(tick),
        .final_block(final_block),
        .done(done),
        .msg_padded(msg_padded)
    );

    initial begin
        clk = 0;
        forever #5 clk = ~clk; // 100 MHz
    end

    // Testbench 1 (example: "abc")
//    reg [7:0] test_data [0:15]; // 16 bytes for testing
//    integer i;

//    initial begin
//            // Initialize
//            rst = 0;
//            dvalid = 0;
//            dlast  = 0;
//            din = 0;
//            done = 0;
//            // Wait and release reset
//            #20;
//            rst = 1;
            
//            test_data[13] = 8'h61;
//            test_data[14] = 8'h62;
//            test_data[15] = 8'h63;
//            // Feed 16 bytes to preprocessor
//            for (i = 0; i < 16; i = i + 1) begin
//                @(posedge clk);
//                dlast  = (i == 15) ? 1 : 0;
//                if (i == 13)         dvalid = 1;
//                if (dvalid)
//                    din    = test_data[i];
//                else 
//                    din = 0;
//                if (i == 16) dvalid = 0;
//            end
//            @(posedge clk);
//            dlast  = 0;
//            din    = 8'h00;
//            dvalid = 0;
//            #700
//            done = 1;
//            #10;
//            done = 0;

///////////////////////////////////////////////////////////////////////////////////////
    // Testbench 2: 56 char 'a'
//    reg [7:0] test_data [0:55];
//    integer i;

//    initial begin
//        // Initialize
//        rst = 0;
//        dvalid = 0;
//        dlast  = 0;
//        din = 0;
//        done = 0;
//        // Wait and release reset
//        #20;
//        rst = 1;
        
//        // Fill test_data with 56 'a' (8'h61)
//        for (i = 0; i < 56; i = i + 1) begin
//            test_data[i] = 8'h61; // ASCII value for 'a'
//        end

//        // Feed 56 bytes to preprocessor
//        for (i = 0; i < 56; i = i + 1) begin
//            @(posedge clk);
//            dlast  = (i == 55) ? 1 : 0;  // Set dlast on the last byte
//            if (i == 0) dvalid = 1; // Start by asserting dvalid
//            if (dvalid)
//                din = test_data[i];   // Feed current byte to din
//            else 
//                din = 0;
//            if (i == 56) dvalid = 0; // End by deasserting dvalid
//        end
//            @(posedge clk);
//            dlast  = 0;
//            din    = 8'h00;
//            dvalid = 0;
//            #750
//            done = 1;
//            #10;
//            done = 0;

///////////////////////////////////////////////////////////////////////////////////////
    // Testbench 3: 65 char 'a'
//    reg [7:0] test_data [0:64];
//    integer i;

//    initial begin
//        // Initialize
//        rst = 0;
//        dvalid = 0;
//        dlast  = 0;
//        din = 0;
//        done = 0;
//        // Wait and release reset
//        #20;
//        rst = 1;
        
//        // Fill test_data with 56 'a' (8'h61)
//        for (i = 0; i < 65; i = i + 1) begin
//            test_data[i] = 8'h61; // ASCII value for 'a'
//        end

//        // Feed 56 bytes to preprocessor
//        for (i = 0; i < 65; i = i + 1) begin
//            @(posedge clk);
//            dlast  = (i == 64) ? 1 : 0;  // Set dlast on the last byte
//            if (i == 0) dvalid = 1; // Start by asserting dvalid
//            if (dvalid)
//                din = test_data[i];   // Feed current byte to din
//            else 
//                din = 0;
//            if (i == 65) dvalid = 0; // End by deasserting dvalid
//        end
//            @(posedge clk);
//            dlast  = 0;
//            din    = 8'h00;
//            dvalid = 0;
//            #750
//            done = 1;
//            #10;
//            done = 0;
          
///////////////////////////////////////////////////////////////////////////////////////            
     // Testbench 4 (example: "abc") voi du lieu ngat quang
    reg [7:0] test_data [0:15]; 
    integer i;

    initial begin
        // Reset
        rst = 0;
        dvalid = 0;
        dlast  = 0;
        din = 0;
        done = 0;

        #20;
        rst = 1;

        for (i = 0; i < 16; i = i + 1)
            test_data[i] = 8'h00;
        test_data[13] = 8'h61; // 'a'
        test_data[14] = 8'h62; // 'b'
        test_data[15] = 8'h63; // 'c'

        // G?i d? li?u ??n preprocessor
        for (i = 0; i < 16; i = i + 1) begin
            @(posedge clk);
            if (i >= 13) begin // ch? g?i d? li?u t? i=13 ? 15
                wait (ready);  // ch? ready tr??c khi g?i
                dvalid = 1;
                din    = test_data[i];
                dlast  = (i == 15);
                @(posedge clk);
                dvalid = 0;
                dlast  = 0;
            end
        end

 
        @(posedge clk);
        din    = 8'h00;
        dvalid = 0;
        dlast  = 0;

  
        #700;
        done = 1;
        #10;
        done = 0;
     
        // Wait for tick and final_block
        wait(tick);
        wait(final_block);
        
        $display("Final block asserted at time %t", $time);
        $display("Tick asserted at time %t", $time);
        $fdisplay(32'h80000002, "msg_padded = %h", msg_padded);
        // End simulation
        #50;
        $finish;
    end

endmodule

       