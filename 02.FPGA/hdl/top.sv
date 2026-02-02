module top (
    input  logic clk_in,    // 25MHz
    input  logic rst,       // Agora é Active High (1 = Reset)
    
    // SPI (Ignorado)
    input  logic spi_cs,
    input  logic spi_sck,
    input  logic spi_mosi,
    output logic spi_miso,

    // Teclado (Declarado para não dar erro, mas sem lógica ativa por enquanto)
    output logic [3:0] row,
    input  logic [3:0] col,

    // LEDs
    output logic [1:0] led
);

    // 1. "Heartbeat" (Sinal de vida no LED Vermelho)
    logic [24:0] counter;
    always_ff @(posedge clk_in) counter <= counter + 1;
    assign led[0] = counter[24]; // LED Vermelho pisca sozinho

    // 2. Lógica SPI Escravo (Slave)
    logic [7:0] shift_reg;
    logic [2:0] bit_count;
    logic       data_ready;
    logic       led_state_spi; // Estado controlado pelo RP2040

    // Sincronizador de Clock SPI (para evitar glitch)
    logic sck_r, sck_rr;
    always_ff @(posedge clk_in) begin
        sck_r  <= spi_sck;
        sck_rr <= sck_r;
    end
    logic sck_rising_edge;
    assign sck_rising_edge = (sck_r && !sck_rr); // Detecta subida do SCK

    // Recebimento de Dados SPI
    always_ff @(posedge clk_in) begin
        if (rst) begin
            bit_count <= 0;
            data_ready <= 0;
        end else if (spi_cs) begin
            // CS em Alto = Reset da transmissão SPI
            bit_count <= 0;
        end else if (sck_rising_edge) begin
            // Desloca o bit recebido no MOSI para dentro
            shift_reg <= {shift_reg[6:0], spi_mosi};
            bit_count <= bit_count + 1;
        end
    end

    // Processamento do Comando (Ao fim de 8 bits ou na subida do CS)
    always_ff @(posedge clk_in) begin
        if (rst) begin
            led_state_spi <= 1; // Começa apagado (Active Low: 1=OFF)
        end else begin
            // Se o chip select subir (fim de transmissão)
            if (spi_cs) begin
                // Comando 0xA1 -> Ligar LED (Active Low = 0)
                if (shift_reg == 8'hA1) 
                    led_state_spi <= 0;
                
                // Comando 0xB0 -> Desligar LED (Active Low = 1)
                else if (shift_reg == 8'hB0) 
                    led_state_spi <= 1;
            end
        end
    end

    // Atribui o estado ao LED Verde
    assign led[1] = led_state_spi;

    // Teclado e MISO desativados por enquanto
    assign row = 4'b0000;
    assign spi_miso = 1'bZ;    

endmodule