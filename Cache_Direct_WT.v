`timescale 1ns / 1ps


module Cache_Direct_WT(
    input               Write,
    input       [9:0]   Addr,
    input       [31:0]  WD,
    output reg [31:0] RD,
    output reg         Hit_out
    );
    
    wire [1:0]      block_index;
    wire [1:0]      word_index;
    wire [3:0]      tag;
    
    reg  [132:0]    Cache_Mem[0:3];
    wire [132:0]    block;
    wire            valid;
    wire [3:0]      block_tag;
    wire            Hit;
    
    // Initialize Cache memory to all 0
    initial begin
        Cache_Mem[0] = 133'b0;
        Cache_Mem[1] = 133'b0;
        Cache_Mem[2] = 133'b0;
        Cache_Mem[3] = 133'b0;
    end
    
    // Decompose the input address
    assign block_index = Addr[5:4];
    assign word_index = Addr[3:2];
    assign tag = Addr[9:6];
    
    // Determin Hit
    assign block = Cache_Mem[block_index];
    assign valid = block[132];
    assign block_tag = block[131:128];
    assign Hit = ((valid == 1'b1) && (tag == block_tag));
  
    // Write Through
    wire [127:0] RDM;
    wire [127:0]Main_WD;
    
    assign Main_WD = Cache_Mem[block_index][127:0];
    
    Main_Memory_WB mainRW(.write(Write), .Address(Addr), .WT(Main_WD), .RD(RDM));    

    always @(Hit,Write,WD,Addr,RDM) begin
        if (Hit == 1'b1) begin
        case (Write)
        1'b0:  // Hit && read
            case(word_index) 
                2'b00: RD = block[127:96];
                2'b01: RD = block[95:64];
                2'b10: RD = block[63:32];
                2'b11: RD = block[31:0];
            endcase
        1'b1:  // Hit && write
            case(word_index) 
                2'b00: Cache_Mem[block_index] = {1'b1,block_tag[3:0],WD[31:0],block[95:0]};
                2'b01: Cache_Mem[block_index] = {1'b1,block_tag[3:0],block[127:96],WD[31:0],block[63:0]};
                2'b10: Cache_Mem[block_index] = {1'b1,block_tag[3:0],block[127:64],WD[31:0],block[31:0]};
                2'b11: Cache_Mem[block_index] = {1'b1,block_tag[3:0],block[127:32],WD[31:0]};
            endcase
        endcase
        end
        else begin
            $display("Miss!!");
            Cache_Mem[block_index] = {1'b1,tag[3:0],RDM[127:0]};
            if (Write == 1'b0) begin
            case(word_index) 
                2'b00: RD = block[127:96];
                2'b01: RD = block[95:64];
                2'b10: RD = block[63:32];
                2'b11: RD = block[31:0];
            endcase      
            end
        end
    end
    
    // Match
    // Hit_out need to wait for the main memory to complete the write operation.
    always @(Hit,Write, RDM) begin
        if (Write == 1'b0)begin  // Read
            Hit_out = Hit;
        end
        else begin          // Write
            case (word_index)
                2'b00: Hit_out = Hit && (RDM[127:96] == WD[31:0]);
                2'b01: Hit_out = Hit && (RDM[95:64] == WD[31:0]);
                2'b10: Hit_out = Hit && (RDM[63:32] == WD[31:0]);
                2'b11: Hit_out = Hit && (RDM[31:0] == WD[31:0]);
            endcase
        end
    end
    
    // Simulation Part
    always @(Hit, Hit_out)begin
        $display("Hit: %B, Hit_out: %B", Hit, Hit_out);
    end
    
endmodule