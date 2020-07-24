`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2020/07/21 21:45:01
// Design Name: 
// Module Name: DWBCache
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


module Cache_Direct_WB(
    input read_write,
    input [9:0] Address,
    input [31:0] WriteData,
    output [31:0] ReadData,
    output hit_miss
);
  //4 words, 4 bits for tag, 1 bit for dirty, 1 bit for valid
  reg [133:0] cache [0:3];

  //cache block temp variables 
  wire hit;
  wire valid;
  wire dirty;
  wire [3:0] Tag;
  wire [1:0] BlockAddress;
  wire [1:0] WordOffset, ByteOffset;
  reg [31:0] CacheReadData; //data return to cpu

  //for memory I/O
  wire [127:0] MemReadData; //4 words data from mem
  reg [127:0] MemWriteData;
  reg [9:0] MemAddress;
  reg Memread_write;

  initial begin
    //Memread_write = 1'b0; //by default read memory
    //MemWriteData = 128'b0; 
    cache[0] = 134'b0;
    cache[1] = 134'b0;
    cache[2] = 134'b0;
    cache[3] = 134'b0;
  end


  //main memory to read data from, arguments in order
  Main_Memory_WB memory(.Address(MemAddress),.WT( MemWriteData), .write(Memread_write), .RD(MemReadData));
  //output
  assign ReadData = CacheReadData;
  assign hit_miss = hit;
  //decomposing input address
  assign Tag = Address[9:6];
  assign BlockAddress = Address[5:4];
  assign WordOffset = Address[3:2];
  assign ByteOffset = Address[1:0];
  
  //check V,D in cache
  assign valid = cache[BlockAddress][133];
  assign dirty = cache[BlockAddress][132];
  
  //check hit or miss
  assign hit = cache[BlockAddress][133] && (cache[BlockAddress][131:128] == Tag);


  always @(MemReadData)begin
    if (hit == 1'b0)
        cache[BlockAddress][133] = 1'b1; //set valid
  end

  always @ (hit, Address,WriteData, read_write, MemReadData) begin
    //if not hit
    if (~hit) begin
      //write back if not hit and dirty
      if (dirty) begin
        MemAddress = {cache[BlockAddress][131:128], Address[5:0]};
        MemWriteData = cache[BlockAddress][127:0];
        Memread_write = 1'b1;
      end
      else begin
        MemAddress = Address;
        Memread_write = 1'b0;
      end
      //dirty words has written back to memory, then read words into cache
      cache[BlockAddress][127:0] = MemReadData;
      cache[BlockAddress][131:128] = Tag;
      cache[BlockAddress][132] = 1'b0; //set not dirty
      //write word in cache

      if (read_write) begin
        cache[BlockAddress][132] = 1'b1; //set dirty
        case (WordOffset)
          2'b00:
            cache[BlockAddress][127:96] = WriteData;
          2'b01:
            cache[BlockAddress][95:64] = WriteData;
          2'b10:
            cache[BlockAddress][63:32] = WriteData;
          2'b11:
            cache[BlockAddress][31:0] = WriteData;
        endcase
      end
      //read word in cache
      else begin
        case (WordOffset)
          2'b00: 
            CacheReadData = cache[BlockAddress][127:96];
          2'b01:
            CacheReadData = cache[BlockAddress][95:64];
          2'b10:
            CacheReadData = cache[BlockAddress][63:32];
          2'b11:
            CacheReadData = cache[BlockAddress][31:0];
        endcase
      end
    end
    
    //if hit
    if (hit) begin
      //read word from cache
      MemAddress = Address;
      if (~read_write) begin
        case (WordOffset)
          2'b00: 
            CacheReadData = cache[BlockAddress][127:96];
          2'b01:
            CacheReadData = cache[BlockAddress][95:64];
          2'b10:
            CacheReadData = cache[BlockAddress][63:32];
          2'b11:
            CacheReadData = cache[BlockAddress][31:0];
        endcase 
      end
      //write word in cache
      else begin
        cache[BlockAddress][132] = 1'b1; //set dirty
        case (WordOffset)
          2'b00:
            cache[BlockAddress][127:96] = WriteData;
          2'b01:
            cache[BlockAddress][95:64] = WriteData;
          2'b10:
            cache[BlockAddress][63:32] = WriteData;
          2'b11:
            cache[BlockAddress][31:0] = WriteData;
        endcase
      end
    end
  end

  always @(hit or hit_miss) begin
      $display("Hit: %B, Hit_out: %B", hit, hit_miss);
  end
endmodule
