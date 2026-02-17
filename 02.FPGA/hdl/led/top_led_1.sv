module top_led (
    input  wire clk,          // 25 MHz
    input  wire rst,          // Botão (Inicia a sequência)
    output reg  servo_pin,    
    output reg  led_verde,    
    output reg  led_verm      
);

    // Estados
    localparam IDLE     = 2'd0;
    localparam SEQUENCE = 2'd1;
    localparam DONE     = 2'd2;

    reg [1:0] state = IDLE;

    // Contadores
    reg [24:0] counter_1s = 0;   
    reg [3:0]  toggle_count = 0; 

    initial begin
        state = IDLE;
        led_verde = 1;
        led_verm  = 1;
    end

    always @(posedge clk) begin
        case (state)

            // --- ESTADO 0: ESPERA O BOTÃO ---
            IDLE: begin
                led_verde <= 1; // Estado de repouso (ex: apagados ou acesos fixos)
                led_verm  <= 1;
                
                if (rst) begin
                    // PREPARAÇÃO PARA O PRÓXIMO ESTADO
                    counter_1s   <= 0;
                    toggle_count <= 0;
                    
                    // Define como a sequência começa
                    led_verde <= 1; 
                    led_verm  <= 0; 
                    
                    state <= SEQUENCE; // Pula para a sequência
                end
            end

            // --- ESTADO 1: PISCA-PISCA ---
            SEQUENCE: begin
                // Apenas conta. Não force valores nos LEDs aqui fora do IF!
                counter_1s <= counter_1s + 1;

                // Passou 1 segundo?
                if (counter_1s >= 25_000_000) begin
                    counter_1s <= 0;

                    // AGORA SIM, inverte
                    led_verde <= ~led_verde;
                    led_verm  <= ~led_verm;

                    toggle_count <= toggle_count + 1;

                    // Terminou as 10 trocas? (0 a 9)
                    if (toggle_count == 4'd9) begin
                        state <= DONE;
                    end
                end
            end

            // --- ESTADO 2: ACABOU ---
            DONE: begin
                // Define como ficam os LEDs no final
                led_verde <= 0; 
                led_verm  <= 0;

                // Trava aqui ou espera o botão soltar para reiniciar
                // Se quiser reiniciar automático ao soltar o botão:
                if (!rst) begin
                    state <= IDLE;
                end
            end

            default: state <= IDLE;
        endcase
    end

endmodule