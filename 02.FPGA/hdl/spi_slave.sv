module spi_slave(
    //Interface controle
    input logic clk,    //clock interno FPGA (25MHz)
    input logic rst,    //reset nivel baixo

    //Interface SPI (Recebe da RP2040)
    input logic sck,    //SCK pulso externo - clock SPI mestre
    input logic mosi,   //dados (master out slave in)
    input logic cs,     //chip select (ativo em 0)

    //Interface RISC-V
    output logic [7:0] data_out,    //byte de dados RP2040
    output logic       data_valid,   //aviso de dados
    output logic sck_rise   //pulso interno - borda de subida do SCK

);
    logic sck_atual;   //valor estado atual - FF A
    logic sck_antigo;   //valor estado antigo - FF B


    //logic sck_register;     //shift_register 
    //localparam MAX = 25000000;  //25 MHz

    /* Construir a sequencia para receber os dados da RP2040
     ****     Iniciar com a Detecção da Borda    ****
     * Armazenar os sinais de Clock (25MHz) - sinais do sck - SPI
     * 1. Guardar o valor no estado agora
     * 2. Guardar o valor no estado anterior
     * 3. Comparar -- Se no estado anterior o sck era 0 e no agora é 1 - verificar a borda de subida
     * Objetivo: Sincronização transforma um sinal externo em um pulso interno - alinhamento com o chip
     */


    //sincronizar o SCK externo - RP2040
    always_ff @(posedge clk or negedge rst) begin
        if(!rst) begin
            sck_atual <= 1'b0;
            sck_antigo <= 1'b0;
        end else begin
            sck_atual <= sck;  //captura o externo
            sck_antigo <= sck_atual;   //guarda o passado
        end
    end

    assign sck_rise = sck_atual & ~sck_antigo; //detectar a borda de subida | inverte sck_antigo

    //Ler sck_rise para obter o byte - FSM
    //1. Defir os estados serão 3
    typedef enum logic [1:0] { 
        IDLE,       //cs = 1 -> esperando
        RECEIVE,    //cs = 0 -> recebendo
        DONE        // final byte completo
    } state_t;

    state_t estado_atual;

    //2. Logica para armazenar os dados
    logic [2:0] bit_count;   //contador
    logic [7:0] shift_reg;   //byte transmitido

    //3. Logica sequencial
    always_ff @( posedge clk or negedge rst ) begin
        if(!rst) begin
            //IDLE -> reset
            estado_atual <= IDLE;
            bit_count <= 0;
            shift_reg <= 0;
            //saidas
            data_out <= 0;
            data_valid <= 0;
        end else begin
            case (estado_atual)
                IDLE: begin
                    bit_count <= 0;      // Prepara contador
                    data_valid <= 0;     // Desliga aviso anterior
                    
                    // Se o CS baixar (0)
                    if (cs == 1'b0) begin
                        estado_atual <= RECEIVE; 
                    end
                end

                RECEIVE: begin
                    // Segurança: Se o CS subir (1), cancela tudo
                    if (cs == 1'b1) begin
                        estado_atual <= IDLE; // Reset se CS subir
                    end else begin
                        // Só fazemos algo se o Detector de Borda avisar (sck_rise)
                        if (sck_rise) begin
                            // 1. Pega o bit do fio MOSI e empurra na fila
                            shift_reg <= {shift_reg[6:0], mosi}; 
                            
                            // 2. Incrementa o contador de bits
                            bit_count <= bit_count + 1;

                            // 3. Verifica se completou 8 bits (O ou 7)
                            // Como bit_count tem 3 bits, ao somar 1 em 7 (111), ele vira 0 (000).
                            // Então se bit_count chegou em 7, este é o último bit
                            if (bit_count == 3'd7) begin
                                estado_atual <= DONE;
                            end
                        end
                    end
                end

                DONE: begin
                    data_out <= shift_reg; // Publica o byte
                    data_valid <= 1;       // valida para o RISC-V
                    
                    // Volta a dormir e esperar o próximo pacote
                    estado_atual <= IDLE;
                end
            endcase
        end        
    end

endmodule