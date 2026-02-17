module top_servo_pwm (
    input  wire clk,
    input  wire rst,          // Botão (ativo alto)
    output reg  servo_pin,
    output reg  led_verde,
    output reg  led_verm
);

    // Estados
    typedef enum logic [1:0] {
        IDLE         = 2'd0,
        MOVE         = 2'd1,
        WAIT_RELEASE = 2'd2
    } state_t;

    state_t state = IDLE;

    // PWM
    reg [18:0] pwm_counter = 0;
    reg [18:0] duty = 0;

    // Tempo 2s
    reg [25:0] time_counter = 0;

    // Direção
    reg next_dir = 0;

    localparam POS_A = 19'd31_000; // ~45 graus
    localparam POS_B = 19'd44_000; // ~135 graus

    // PWM 20ms
    always @(posedge clk) begin
        if (pwm_counter >= 19'd499_999)
            pwm_counter <= 0;
        else
            pwm_counter <= pwm_counter + 1;

        servo_pin <= (pwm_counter < duty);
    end

    // FSM
    always @(posedge clk) begin
        case (state)

            // -------------------------
            IDLE: begin
                led_verde <= 1;
                led_verm  <= 1;
                duty <= 0;
                time_counter <= 0;

                if (rst) begin
                    duty <= (next_dir == 0) ? POS_A : POS_B;
                    state <= MOVE;
                end
            end

            // -------------------------
            MOVE: begin
                time_counter <= time_counter + 1;

                if (next_dir == 0) begin
                    led_verde <= 1; led_verm <= 0;
                end else begin
                    led_verde <= 0; led_verm <= 1;
                end

                if (time_counter >= 26'd50_000_000) begin
                    time_counter <= 0;
                    next_dir <= ~next_dir;
                    state <= WAIT_RELEASE;
                end
            end

            // -------------------------
            WAIT_RELEASE: begin
                duty <= 0;
                led_verde <= 1;
                led_verm  <= 1;

                if (!rst)
                    state <= IDLE;
            end

        endcase
    end

endmodule
