module soc_memory (
    input clk,
    input valid,
    output reg ready,
    input [9:0] addr, 
    input [31:0] wdata,
    input [3:0] wstrb,
    output reg [31:0] rdata
);
    reg [31:0] mem [0:1023]; // RAM de 4KB

    // Carrega o firmware compilado do seu arquivo .hex
    initial $readmemh("hdl/firmware.hex", mem);

    always @(posedge clk) begin
        ready <= 1'b0;
        if (valid) begin
            ready <= 1'b1;
            rdata <= mem[addr];
            if (wstrb[0]) mem[addr][7:0]   <= wdata[7:0];
            if (wstrb[1]) mem[addr][15:8]  <= wdata[15:8];
            if (wstrb[2]) mem[addr][23:16] <= wdata[23:16];
            if (wstrb[3]) mem[addr][31:24] <= wdata[31:24];
        end
    end
endmodule