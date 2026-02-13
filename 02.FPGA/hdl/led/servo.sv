module servo (
    input  wire clk,          // 25 MHz (P3)
    output reg  servo_pin,     // L4
    output reg  led_verde,     // N4
    output reg  led_verm       // P16
);

    // Contador para gerar atraso visível
    // 25 MHz → 25.000.000 ciclos ≈ 1 segundo
    reg [24:0] counter;

    always @(posedge clk) begin
        counter <= counter + 1;

        if (counter == 25_000_000) begin
            counter   <= 0;
            servo_pin <= ~servo_pin;   // alterna o pino do servo
            led_verde <= ~led_verde;   // alterna LED verde
            led_verm  <= ~led_verm;    // alterna LED vermelho
        end
    end

endmodule
