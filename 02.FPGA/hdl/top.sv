module top (
    input logic clk_in,
    input logic rst_in, 

    //LED verificar
    output logic [7:0] led,

    //SPI
    input logic spi_sck,
    input logic spi_mosi,
    input logic spi_cs
);

// Ligar - conexao
// 1. Processador
// 2. Memoria
// 3. SPI Slave

// 1. Instancia SPI Slave: conexão SPI
logic [7:0] spi_data_out;
logic       spi_valid;
logic       spi_sck_rise; //debug pode acionar led

spi_slave u_spi (
    .clk        (clk_in),
    .rst        (rst_in),
    .sck        (spi_sck),
    .mosi       (spi_mosi),
    .cs         (spi_cs),
    .data_out   (spi_data_out),
    .data_valid (spi_valid),
    .sck_rise   (spi_sck_rise)
);

// 2. Barramento: fios - processador
logic           mem_valid_in;  //instrucao
logic           mem_ready_in;  //leitura
logic [31:0]    mem_addr_in;   //endereco
logic [31:0]    mem_wdata_in;  //escrever dado
logic [31:0]    mem_rdata_in;  //ler dado
logic [3:0]     mem_wstrb_in;  //4 bit (0000 - leitura 1111 - escrita)

// 2. Instanciar o processador
picorv32 #(
    .PROGADDR_RESET(32'h0000_0000), //Memoria RAM
    .STACKADDR(32'h0000_0200)       //Stack Pointer
) cpu (
    .clk        (clk_in),
    .resetn     (rst_in), //ativo baixo
    .mem_valid  (mem_valid_in),
    .mem_ready  (mem_ready_in),
    .mem_addr   (mem_addr_in),
    .mem_wdata  (mem_wdata_in),
    .mem_rdata  (mem_rdata_in),
    .mem_wstrb  (mem_wstrb_in)
);


// 3. Memoria RAM - escrita
// Cria uma memória de 1KB (256 palavras de 32 bits)
logic [31:0] memoria [0:255]; 
logic [31:0] ram_rdata; // Variavel temporaria para RAM

logic [15:0] addr_prefixo;
assign addr_prefixo = mem_addr_in[31:16];

// Leitura da RAM (Conecta a matriz à variável temporária)
// O processador endereça Bytes (0,4,8..), a memória endereça Palavras (0,1,2..).
// Por isso usamos [9:2] (dividir por 4).
assign ram_rdata = memoria[mem_addr_in[9:2]];

// Bloco de ESCRITA Síncrona (LEDs e RAM)
always_ff @(posedge clk_in) begin
    // Se mem_valid_in é 1 e wstrb não é zero, o processador quer ESCREVER
    if (mem_valid_in && |mem_wstrb_in) begin
        
        // A. Escrita na RAM (Endereços 0x0000....)
        if (addr_prefixo == 16'h0000) begin  // <--- MUDOU AQUI
                 memoria[mem_addr_in[9:2]] <= mem_wdata_in;
        end

        /*   if (mem_addr_in[31:16] == 16'h0000) begin  //não finciona erro no icarus
                memoria[mem_addr_in[9:2]] <= mem_wdata_in;
        end */

        // B. Escrita nos LEDs (Endereço 0x00020000)
        if (mem_addr_in == 32'h00020000) begin
            led <= mem_wdata_in[7:0]; // Atualiza os LEDs físicos
        end
    end
end

//3. Multiplexador Combinacional - Decodificador (Always Comb)
// Mapa de memoria
// 0x0000_xxxx -> fala memoria RAM
// 0x0001_xxxx -> fala SPI Slave

always_comb begin
    mem_rdata_in = 32'h00000000;

    //verificar bit a bit
    //if(mem_addr_in[31:16] == 16'h0001) begin // não funciona erro no icarus
    if(addr_prefixo == 16'h0001) begin
        // O processador le o SPI
        // Entregar o byte que veio do spi_slave, preenchendo o resto com zeros.
        mem_rdata_in = {23'd0, spi_valid, spi_data_out}; 
            
    end else begin
        // Se não for SPI, assumimos que é Memória RAM (0x0000...)
        mem_rdata_in = ram_rdata;
    end
end

assign mem_ready_in = mem_valid_in;

/* SoC
* O always_comb monitora o mem_addr.
* Se o endereço começa com 0x0001 (ex: 0x00010000), ele conecta o fio mem_rdata aos dados do SPI.
* Caso contrário, ele conecta à memória RAM.
* Na linha mem_rdata = {..., spi_valid, spi_data_out}, foi empacotado 
* Quando o processador ler esse endereço, ele vai receber o byte E o status de validade de uma vez só
*/

endmodule
