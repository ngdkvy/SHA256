`timescale 1ns / 1ps

module compute_v1_0(
    input wire            clk,
    input wire            rst,
    input wire            tick,
    input wire            final,
    input wire [511:0]    block,
    output wire [255:0]   digest,
    output wire           done
);

    //----------------------------------------------------------------
    // Internal constant and parameter definitions.
    //----------------------------------------------------------------
    localparam SHA256_H0_0 = 32'h6a09e667;
    localparam SHA256_H0_1 = 32'hbb67ae85;
    localparam SHA256_H0_2 = 32'h3c6ef372;
    localparam SHA256_H0_3 = 32'ha54ff53a;
    localparam SHA256_H0_4 = 32'h510e527f;
    localparam SHA256_H0_5 = 32'h9b05688c;
    localparam SHA256_H0_6 = 32'h1f83d9ab;
    localparam SHA256_H0_7 = 32'h5be0cd19;
    
    localparam SHA256_ROUNDS = 63;
    
    localparam IDLE   = 0;
    localparam ROUNDS = 1;
    localparam DONE   = 2;

    //----------------------------------------------------------------
    // Registers including update variables and write enable.
    //----------------------------------------------------------------
    reg [31:0] a_reg, a_new;
    reg [31:0] b_reg, b_new;
    reg [31:0] c_reg, c_new;
    reg [31:0] d_reg, d_new;
    reg [31:0] e_reg, e_new;
    reg [31:0] f_reg, f_new;
    reg [31:0] g_reg, g_new;
    reg [31:0] h_reg, h_new;
    reg        a_h_we;
    
    reg [31:0] H0_reg, H0_new;
    reg [31:0] H1_reg, H1_new;
    reg [31:0] H2_reg, H2_new;
    reg [31:0] H3_reg, H3_new;
    reg [31:0] H4_reg, H4_new;
    reg [31:0] H5_reg, H5_new;
    reg [31:0] H6_reg, H6_new;
    reg [31:0] H7_reg, H7_new;
    reg        H_we;
    
    reg [5:0] t_ctr_reg, t_ctr_new;
    reg       t_ctr_we;
    reg       t_ctr_inc;
    reg       t_ctr_rst;
    
    reg digest_valid_reg, digest_valid_new;
    reg digest_valid_we;
    reg done_reg;
    
    reg [1:0] sha256_ctrl_reg, sha256_ctrl_new;
    reg       sha256_ctrl_we;

    //----------------------------------------------------------------
    // Local variables for combinatorial logic.
    //----------------------------------------------------------------
    reg [31:0] sum1;
    reg [31:0] ch;
    reg [31:0] sum0;
    reg [31:0] maj;

    //----------------------------------------------------------------
    // Wires.
    //----------------------------------------------------------------
    reg digest_init;
    reg digest_update;
    
    reg state_init;
    reg state_update;
    
    reg first_block;
    
    reg [31:0] t1;
    reg [31:0] t2;
    
    wire [31:0] k_data;
    
    reg w_init;
    reg w_final;
    wire w_mi;
    wire w_ml;
    reg [5:0] w_round;
    wire [31:0] w_data;

    //----------------------------------------------------------------
    // Module instantiations.
    //----------------------------------------------------------------
    k_constants k_constants_inst (.w_ctr(t_ctr_reg), .K(k_data));
    
    Message_scheduler Message_scheduler_inst(
        .clk(clk),
        .rst(rst),
        .block(block),
        .init(w_init),
        .final(w_final),
        .mi(w_mi),
        .ml(w_ml),
        .w(w_data)
    );

    //----------------------------------------------------------------
    // Concurrent connectivity for ports etc.
    //----------------------------------------------------------------
    assign digest = {H0_reg, H1_reg, H2_reg, H3_reg, H4_reg, H5_reg, H6_reg, H7_reg};
    assign digest_valid = digest_valid_reg;
    assign done = done_reg;

    //----------------------------------------------------------------
    // reg_update
    // Update functionality for all registers.
    //----------------------------------------------------------------
    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            a_reg <= 32'h0;
            b_reg <= 32'h0;
            c_reg <= 32'h0;
            d_reg <= 32'h0;
            e_reg <= 32'h0;
            f_reg <= 32'h0;
            g_reg <= 32'h0;
            h_reg <= 32'h0;
            H0_reg <= 32'h0;
            H1_reg <= 32'h0;
            H2_reg <= 32'h0;
            H3_reg <= 32'h0;
            H4_reg <= 32'h0;
            H5_reg <= 32'h0;
            H6_reg <= 32'h0;
            H7_reg <= 32'h0;
            digest_valid_reg <= 0;
            t_ctr_reg <= 6'h0;
            sha256_ctrl_reg <= IDLE;
        end else begin
            if (a_h_we) begin
                a_reg <= a_new;
                b_reg <= b_new;
                c_reg <= c_new;
                d_reg <= d_new;
                e_reg <= e_new;
                f_reg <= f_new;
                g_reg <= g_new;
                h_reg <= h_new;
            end
            if (H_we) begin
                H0_reg <= H0_new;
                H1_reg <= H1_new;
                H2_reg <= H2_new;
                H3_reg <= H3_new;
                H4_reg <= H4_new;
                H5_reg <= H5_new;
                H6_reg <= H6_new;
                H7_reg <= H7_new;
            end
            if (t_ctr_we) t_ctr_reg <= t_ctr_new;
            if (digest_valid_we) digest_valid_reg <= digest_valid_new;
            if (sha256_ctrl_we) sha256_ctrl_reg <= sha256_ctrl_new;
        end
    end

    //----------------------------------------------------------------
    // digest_logic
    // Logic to init and update the digest.
    //----------------------------------------------------------------
    always @* begin
        H0_new = 32'h0;
        H1_new = 32'h0;
        H2_new = 32'h0;
        H3_new = 32'h0;
        H4_new = 32'h0;
        H5_new = 32'h0;
        H6_new = 32'h0;
        H7_new = 32'h0;
        H_we = 0;

        if (digest_init) begin
            H_we = 1;
            H0_new = SHA256_H0_0;
            H1_new = SHA256_H0_1;
            H2_new = SHA256_H0_2;
            H3_new = SHA256_H0_3;
            H4_new = SHA256_H0_4;
            H5_new = SHA256_H0_5;
            H6_new = SHA256_H0_6;
            H7_new = SHA256_H0_7;
        end
        if (digest_update) begin
            H_we = 1;
            H0_new = H0_reg + a_reg;
            H1_new = H1_reg + b_reg;
            H2_new = H2_reg + c_reg;
            H3_new = H3_reg + d_reg;
            H4_new = H4_reg + e_reg;
            H5_new = H5_reg + f_reg;
            H6_new = H6_reg + g_reg;
            H7_new = H7_reg + h_reg;
        end
    end

    //----------------------------------------------------------------
    // t1_logic
    // Logic for the T1 function.
    //----------------------------------------------------------------
    always @* begin
        sum1 = ({e_reg[5:0], e_reg[31:6]} ^ {e_reg[10:0], e_reg[31:11]} ^ {e_reg[24:0], e_reg[31:25]});
        ch = (e_reg & f_reg) ^ ((~e_reg) & g_reg);
        t1 = h_reg + sum1 + ch + w_data + k_data;
    end

    //----------------------------------------------------------------
    // t2_logic
    // Logic for the T2 function.
    //----------------------------------------------------------------
    always @* begin
        sum0 =  ( {a_reg[1:0], a_reg[31:2]}^{a_reg[12:0], a_reg[31:13]} ^{a_reg[21:0], a_reg[31:22]}) ;
        maj =  (a_reg & b_reg) ^ (a_reg & c_reg)  ^(b_reg & c_reg);
        t2 = sum0 + maj;
    end

    //----------------------------------------------------------------
    // state_logic
    // Logic to init and update the state during round processing.
    //----------------------------------------------------------------
    always @* begin
        a_new = 32'h0;
        b_new = 32'h0;
        c_new = 32'h0;
        d_new = 32'h0;
        e_new = 32'h0;
        f_new = 32'h0;
        g_new = 32'h0;
        h_new = 32'h0;
        a_h_we = 0;

        if (state_init) begin
            a_h_we = 1;
            if (first_block) begin
                a_new = SHA256_H0_0;
                b_new = SHA256_H0_1;
                c_new = SHA256_H0_2;
                d_new = SHA256_H0_3;
                e_new = SHA256_H0_4;
                f_new = SHA256_H0_5;
                g_new = SHA256_H0_6;
                h_new = SHA256_H0_7;
            end else begin
                a_new = H0_reg;
                b_new = H1_reg;
                c_new = H2_reg;
                d_new = H3_reg;
                e_new = H4_reg;
                f_new = H5_reg;
                g_new = H6_reg;
                h_new = H7_reg;
            end
        end

        if (state_update) begin
            a_h_we = 1;
            a_new = t1 + t2;
            b_new = a_reg;
            c_new = b_reg;
            d_new = c_reg;
            e_new = d_reg + t1;
            f_new = e_reg;
            g_new = f_reg;
            h_new = g_reg;
        end
    end

    //----------------------------------------------------------------
    // t_ctr
    // Update logic for the round counter.
    //----------------------------------------------------------------
    always @* begin
        t_ctr_new = 0;
        t_ctr_we = 0;

        if (t_ctr_rst) begin
            t_ctr_new = 0;
            t_ctr_we = 1;
        end
        if (t_ctr_inc) begin
            t_ctr_new = t_ctr_reg + 1'b1;
            t_ctr_we = 1;
        end
    end

    //----------------------------------------------------------------
    // sha256_ctrl_fsm
    // Logic for the state machine controlling the core behaviour.
    //----------------------------------------------------------------
    always @* begin
        digest_init = 0;
        digest_update = 0;
        state_init = 0;
        state_update = 0;
        first_block = 0;
        w_init = 0;
        w_final = 0;
        t_ctr_inc = 0;
        t_ctr_rst = 0;
        digest_valid_new = 0;
        digest_valid_we = 0;
        sha256_ctrl_new = sha256_ctrl_reg;
        sha256_ctrl_we = 0;
        done_reg = 0;

        case (sha256_ctrl_reg)
            IDLE: begin
                if (tick || final) begin
                    digest_init = 1;
                    w_init = 1;
                    state_init = 1;
                    first_block = 1; // Assume single block for "abc"
                    t_ctr_rst = 1;
                    digest_valid_new = 0;
                    digest_valid_we = 1;
                    sha256_ctrl_new = ROUNDS;
                    sha256_ctrl_we = 1;
                end
            end
            ROUNDS: begin
                w_final = 1;
                state_update = 1;
                t_ctr_inc = 1;

                if (t_ctr_reg == SHA256_ROUNDS) begin
                    sha256_ctrl_new = DONE;
                    sha256_ctrl_we = 1;
                end
            end
            DONE: begin
                digest_update = 1;
                digest_valid_new = 1;
                digest_valid_we = 1;
                done_reg = 1;
                sha256_ctrl_new = IDLE;
                sha256_ctrl_we = 1;
            end
        endcase
    end

endmodule