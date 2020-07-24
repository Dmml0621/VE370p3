`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2020/07/20 10:02:06
// Design Name: 
// Module Name: Cache_2way
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module Cache_2way_WT(
    input               Write,
    input       [9:0]   Addr,
    input       [31:0]  WD,
    output reg [31:0] RD,
    output reg         Hit_out
    );
    
    reg  [132:0] Cache_Mem[0:3];
    reg          LRU [0:1];
    reg  [1:0]   block_index;
    
    wire set_index;
    wire [1:0]word_index;
    wire [3:0]tag;
    wire         valid;
    wire [3:0]   block_tag;
    wire [132:0] block;
    wire         Hit;
    
    wire          Valid [0:1];
    wire  [3:0]   Block_tag[0:1];
    
    initial begin
        Cache_Mem[0] = 133'b0;
        Cache_Mem[1] = 133'b0;
        Cache_Mem[2] = 133'b0;
        Cache_Mem[3] = 133'b0;
        LRU[0]=1'b0;LRU[1]=1'b0;
    end
    
    // Hit / Miss
    assign set_index = Addr[4];
    assign word_index = Addr[3:2];
    assign tag = Addr[9:6];
    
    assign Valid[0] = Cache_Mem[{1'b0,set_index}][132];
    assign Valid[1] = Cache_Mem[{1'b1,set_index}][132];
    assign Block_tag[0] = Cache_Mem[{1'b0,set_index}][131:128];
    assign Block_tag[1] = Cache_Mem[{1'b1,set_index}][131:128];
    assign Hit = ((Valid[0] == 1'b1) && (tag == Block_tag[0])) || ((Valid[1] == 1'b1) && (tag == Block_tag[1]));
    assign block = Cache_Mem[block_index];
    assign valid = block[132];
    assign block_tag = block[131:128];
    
    // block_index[], LRU[]
    always @(tag, Valid[0],Valid[1], Block_tag[0], Block_tag[1], set_index) begin
        if (Hit == 1'b0) begin  // Miss, the block is the LUB block 
            block_index = {LRU[set_index], set_index};
        end
        else begin  // Hit, the block is the hit block.
            block_index = {((Valid[1] == 1'b1) && (tag == Block_tag[1])), set_index};   // block 1 hit, block_index[1] =1, otherwise, block_index[1] = 0
            LRU[set_index] = ((Valid[0] == 1'b1) && (tag == Block_tag[0]));      // LRU = !block[1]
        end
    end
  
    // Write Through
    wire [127:0] RDM;
    wire [127:0]Main_WD;
    assign Main_WD = Cache_Mem[block_index][127:0];
    
    Main_Memory_WB mainRW(.write(Write), .Address(Addr), .WT(Main_WD), .RD(RDM));    // Main_Write. Write until block_index is fixed

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
    always @(Hit,Write, RDM) begin
        if (Write == 1'b0)begin  // Read
            Hit_out = Hit;
        end
        else begin          // Write
            case (word_index)
                2'b00: Hit_out =  Hit && (RDM[127:96] == WD[31:0]);
                2'b01: Hit_out =  Hit &&  (RDM[95:64] == WD[31:0]);
                2'b10: Hit_out =  Hit &&  (RDM[63:32] == WD[31:0]);
                2'b11: Hit_out =  Hit &&  (RDM[31:0] == WD[31:0]);
            endcase
        end
        //$display("block_index: %B, LRU[%B]: %B",block_index, set_index, LRU[set_index]);
    end
    
    // Simulation Part
    always @(Hit, Hit_out)begin
        $display("Hit: %B, Hit_out: %B", Hit, Hit_out);
    end
    
    
endmodule
