module blink (
    input wire clk, //Clock de 25MHz
    output wire led //Saida para o LED
);

    //Criar um contador de 25bits
    //25MHz = 25.000.000 ciclos por segundo 
    //2^24 é aprox 16 milhoes. O bit mais alto vai alterar a cada ~0.6 segundos
    reg [24:0] counter = 0;

    always @(posedge clk) begin
        counter <= counter +1;
    end

    //Liga o LED ao bit mais significativo do contados
    //O operador ~inverte porque os LEDs da Colorlight acendem com 0 (Low)
    assign led = ~counter[24];
    
endmodule