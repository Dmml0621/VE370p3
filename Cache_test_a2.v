`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2020/07/21 20:21:05
// Design Name: 
// Module Name: Cache_test_a2
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


module Cache_test_a2;
endmodule
`timescale 1ns / 1ps

module Cache_test_a2;
   // Inputs
   reg read_write;
   reg [9:0]address;
   reg [31:0]write_data;
   wire [31:0]RD;
   wire Hit;
   Cache_Direct_WB cache ( read_write, address, write_data, RD, Hit);
    
    integer i=0;
    initial begin
        $dumpfile("Cache_2way_WB.dump");
        $dumpvars(1, cache);
        $display("Textual result of pipeline:");
        $display("==========================================================");
       #0 read_write = 0; address = 10'b0000000100;i=1; //should miss
       #10 read_write = 1; address = 10'b0000000000;i=2; write_data = 8'b11111111; //should hit
       #10 read_write = 0; address = 10'b0000000000;i=3; //should hit and read out 0xff
       #10 read_write = 0; address = 10'b1000000000;i=4; //should miss
       #10 read_write = 0; address = 10'b0000000000;i=5; //should hit for 2-way associative, should miss for directly mapped
       #10 read_write = 0; address = 10'b1100000000;i=6; //should miss
       #10 read_write = 0; address = 10'b1000000000;i=7; //should miss both for directly mapped and for 2-way associative (Least-Recently-Used policy)
       #80;
       $stop;
    end
    
   always #10 begin
       $display("Instruction [%d], Hit:%d, Read Data: %B",i, cache.hit_miss, cache.ReadData);
       $display("Word[0]:  %B, Word[1] = %B, Word[2] = %B, Word[3] = %B", cache.cache[00][127:96],cache.cache[00][95:64],cache.cache[00][63:32],cache.cache[00][31:0]);
       $display("Memory[0]: %B", cache.memory.Memory[0]);      
       $display("----------------------------------------------------------");
       
   end


endmodule
