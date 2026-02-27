module system_complete (
    input  wire clk,        // 25 MHz
    input  wire rst,    // Botão Vermelho da Protoboard (Se quiser usar)
    // Interface SPI RP2040
    input  wire spi_sck, spi_mosi, spi_cs,
    // Saídas
    output wire spi_miso,
    output reg  led_verde,
    output reg  led_verm,
    output reg  servo_pin   // Pino do Servo Motor (ex: L4)
);

    // Miso não faz nada nesta versão, mantemos em 0
    assign spi_miso = 1'b0;

    // --- 1. COMUNICAÇÃO SPI (Ouvindo o RP2040) ---
    wire [7:0] rx_byte;
    wire       rx_valid;
    
    // Variável de MODO:
    // 0 = Menu (Pisca Junto)
    // 1 = App LED (Pisca Alternado)
    // 2 = App Botão (Espera Botão Físico)
    reg [1:0] modo_led   = 0; // 0=Menu, 1=Auto, 2=Manual
    reg       modo_servo = 0; // 0=Parado, 1=Varredura

    spi_slave u_spi (
        .clk(clk), .sck(spi_sck), .mosi(spi_mosi), .cs(spi_cs),
        .rx_data(rx_byte), .rx_valid(rx_valid)
    );

    // Atualiza o modo baseado no que o RP2040 mandou
    always @(posedge clk) begin
        if (rx_valid) begin
            if (rx_byte == 8'h00) modo_led <= 0; // Comando 0x00 -> Menu
            if (rx_byte == 8'hA1) modo_led <= 1; // Comando 0xA1 -> LED Auto
            if (rx_byte == 8'hB2) modo_led <= 2; // Comando 0xB2 -> LED Botão

            // Comandos do Botão B (Servo)
            if (rx_byte == 8'hC3) modo_servo <= 0; // Parado
            if (rx_byte == 8'hD4) modo_servo <= 1; // Movendo
        end
    end

    // --- 2. LÓGICAS DOS SISTEMAS (Tudo rodando junto) ---
    
    reg [24:0] cnt;
    always @(posedge clk) cnt <= cnt + 1;

    // --- 3. LÓGICA DOS LEDS ---
    // Lógica A: MENU (Pisca Rápido e Junto)
    // Bit 22 do contador muda a cada ~0.3s
    wire led_g_menu = cnt[22]; 
    wire led_r_menu = cnt[22];

    // Lógica B: APP 1 (Pisca Lento e Alternado - Automático)
    // Bit 24 muda a cada ~1.3s
    wire led_g_app1 = cnt[24];
    wire led_r_app1 = ~cnt[24];

    // Lógica C: APP 2 (Controlado pelo Botão Vermelho da Protoboard)
    // Se apertar rst, acende. Senão apaga.
    wire led_g_app2 = rst; // Botão pressionado (assumindo Pull-Down ou Up conforme sua placa)
    wire led_r_app2 = !rst;

    // --- 3. O SELETOR (MULTIPLEXADOR) ---
    // Aqui acontece a mágica. Decidimos quem controla o pino físico.
    always @(*) begin
        case (modo_led)
            0: begin // Menu
                led_verde = led_g_menu;
                led_verm  = led_r_menu;
            end
            1: begin // App 1
                led_verde = led_g_app1;
                led_verm  = led_r_app1;
            end
            2: begin // App 2
                led_verde = led_g_app2;
                led_verm  = led_r_app2;
            end
            default: begin
                led_verde = 0;
                led_verm  = 0;
            end
        endcase
    end

    // --- 4. LÓGICA DO SERVO (Gerador PWM 50Hz) ---
    // 25MHz / 50Hz = 500.000 ciclos (Período de 20ms)
    reg [18:0] pwm_counter = 0;
    reg [18:0] pwm_duty    = 37500; // Começa no meio (1.5ms)
    reg [24:0] sweep_timer = 0;
    reg dir_up = 1;

    always @(posedge clk) begin
        // Contador PWM
        if (pwm_counter < 500_000 - 1) begin
            pwm_counter <= pwm_counter + 1;
        end else begin
            pwm_counter <= 0;
        end

        // Controle do Pino do Servo
        servo_pin <= (pwm_counter < pwm_duty) ? 1'b1 : 1'b0;

        // Lógica de Varredura (Só funciona se modo_servo == 1)
        if (modo_servo == 1) begin
            sweep_timer <= sweep_timer + 1;
            // A cada ~10ms, atualiza a posição
            if (sweep_timer >= 250_000) begin
                sweep_timer <= 0;
                
                if (dir_up) begin
                    pwm_duty <= pwm_duty + 100;
                    if (pwm_duty >= 62500) dir_up <= 0; // 2.5ms (Máximo)
                end else begin
                    pwm_duty <= pwm_duty - 100;
                    if (pwm_duty <= 12500) dir_up <= 1; // 0.5ms (Mínimo)
                end
            end
        end else begin
            // Se modo_servo == 0, fica parado no meio
            pwm_duty <= 37500; 
        end
    end

endmodule