/* Arquivo: bootloader.s */
/* Objetivo: Inicializar a Pilha (Stack) e pular para o C */

.section .init      /* insere no inicio */
.global _start      /* inicio do programa */

_start:
    /* 1. Configurar o Stack Pointer (Pilha) */
    /* Nossa RAM começa em 0x00000000 e tem 1024 bytes (0x400) */
    /* A pilha cresce de cima para baixo. Colocar no meio (512 ou 0x200) */
    /* deixar espaço para o código em cima e dados em baixo. */
    li sp, 0x00000200

    /* 2. Salta para a função main() (que estará no arquivo .c) */
    call main

    /* 3. Trava de Segurança (Loop Infinito) */
    /* Se o main() retornar (o que não deve acontecer), travamos aqui */
loop:
    j loop