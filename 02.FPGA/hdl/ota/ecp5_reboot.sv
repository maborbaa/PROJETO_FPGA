module ecp5_reboot (
    input wire clk,
    input wire trigger,        // Pulso para iniciar o reboot
    input wire [31:0] address  // Endereço para onde pular (ex: 0x100000)
);
    // --- Comandos JTAG da Lattice ECP5 ---
    localparam CMD_LSC_WRITE_COMP_DIC = 8'h70; // Write Composition Index
    localparam CMD_LSC_PROG_SPI       = 8'h79; // Refresh (Reboot)

    reg [5:0]  state = 0;
    reg [31:0] shift_reg;
    reg [7:0]  cmd_reg;
    reg        jtag_ce = 0; // Clock Enable
    reg        jtag_si = 0; // Data In
    
    // Primitiva JTAGG (Acesso ao JTAG interno via Fabric)
    JTAGG u_jtag (
        .JTDO1(1'b0), // Não usado
        .JTDO2(1'b0), // Não usado
        .JTDI (jtag_si),
        .JTCK (clk),
        .JRTI2(1'b0),
        .JRTI1(jtag_ce),
        .JSHIFT(jtag_ce),
        .JUPDATE(1'b0),
        .JRSTN(1'b1),
        .JCE2(1'b0),
        .JCE1(1'b0)
    );

    always @(posedge clk) begin
        if (trigger) state <= 1;

        case (state)
            // 0: Idle
            0: begin jtag_ce <= 0; end

            // --- FASE 1: Escrever o Endereço (WBSTAR) ---
            // Infelizmente, via JTAGG é complexo setar WBSTAR diretamente sem softcore.
            // SIMPLIFICAÇÃO FUNCIONAL: 
            // O comando REFRESH padrão recarrega do 0x00.
            // Para pular para 0x100000 via hardware puro, precisamos do módulo bitstream burst.
            
            // 🛑 AJUSTE DE ROTA:
            // Escrever esse driver JTAG bit-banged em Verilog puro agora pode travar seu projeto.
            // VAMOS USAR A RP2040 COMO "MÃO DE DEUS".
            
        endcase
    end
endmodule