`timescale 1ns / 1ps

module Cache_test_b1;
   // Inputs
   reg read_write;
   reg [9:0]address;
   reg [31:0]write_data;
   wire [127:0]RD;
   wire Hit;
   Cache_2way_WT cache ( read_write, address, write_data, RD, Hit);
    
    integer i=0;
    initial begin
        $dumpfile("Cache_2way_WT.dump");
        $dumpvars(1, cache);
        $display("Textual result of pipeline:");
        $display("==========================================================");
       #0 read_write = 0; address = 10'b0000000000;i=1; //should miss
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
           $display("Instruction [%d], Hit:%d, Read Data: %B",i, cache.Hit_out, cache.RD);
           $display("set_index: %B, LRU[%B] = %B",cache.set_index, cache.set_index, cache.LRU[cache.set_index]);
           $display("Block[00]:  %B, Block[10] = %B, Block[01] = %B, Block[11] = %B", 
                    cache.Cache_Mem[0][132:128],cache.Cache_Mem[2][132:128],cache.Cache_Mem[1][132:128],cache.Cache_Mem[3][132:128]);
           $display("Memory[0]: %B", cache.mainRW.Memory[0]);
           $display("----------------------------------------------------------");
           
       end



endmodule
