// Arquivo: hdl/top_servo_test.sv
// Este é o "Chefe" que controla o motor usando o seu driver novo

module top_servo_test (
    input  logic clk,        // 25MHz
    output logic servo_pin,  // Pino L4
    output logic led_verde,  // Debug
    output logic led_verm    // Debug
);

    // Sinais internos (Fios que ligam o Chefe ao Motorista)
    logic [19:0] fio_duty;   // O valor da posição
    logic rst_interno = 0;   // Vamos deixar o reset desligado por enquanto

    // ---------------------------------------------------------
    // 1. INSTÂNCIA DO SEU DRIVER NOVO (O Componente)
    // ---------------------------------------------------------
    servo motorista_pwm (
        .clk(clk),
        .rst(rst_interno),
        .duty(fio_duty),     // O Chefe manda o valor aqui
        .pwm_out(servo_pin)  // O sinal sai para o pino físico
    );

    // ---------------------------------------------------------
    // 2. LÓGICA DO CHEFE (Gerar o movimento de varredura)
    // ---------------------------------------------------------
    // Parâmetros para 25MHz
    localparam MIN_0G   = 25000;  // 1ms
    localparam MAX_180G = 50000;  // 2ms
    
    logic [19:0] contador_tempo = 0;
    logic direcao = 0;
    logic [15:0] divisor_velocidade = 0;
    
    // Inicializa no centro
    initial fio_duty = 37500; 

    always_ff @(posedge clk) begin
        // Conta 20ms (500.000 ticks) para sincronizar a atualização
        if (contador_tempo >= 500000) 
            contador_tempo <= 0;
        else 
            contador_tempo <= contador_tempo + 1;

        // Atualiza a posição a cada ciclo completo (para não gerar glitch)
        if (contador_tempo == 0) begin
            
            // Controle de Velocidade
            if (divisor_velocidade >= 100) begin // Ajuste aqui a velocidade
                divisor_velocidade <= 0;

                if (direcao == 0) begin // Indo
                    fio_duty <= fio_duty + 250;
                    if (fio_duty >= MAX_180G) direcao <= 1;
                end else begin // Voltando
                    fio_duty <= fio_duty - 250;
                    if (fio_duty <= MIN_0G) direcao <= 0;
                end
            end else begin
                divisor_velocidade <= divisor_velocidade + 1;
            end
        end
    end

    // Feedback Visual
    assign led_verde = (direcao == 0);
    assign led_verm  = (direcao == 1);

endmodule