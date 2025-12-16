/* Arquivo: sections.lds */
/* Objetivo: Mapear o código para dentro da nossa pequena RAM de 1KB */

MEMORY {
    /* Definimos uma região chamada 'mem' */
    /* ORIGIN: Endereço inicial (0x00000000) */
    /* LENGTH: Tamanho total (0x400 = 1024 bytes = 1KB) */
    mem : ORIGIN = 0x00000000, LENGTH = 0x00000400
}

SECTIONS {
    /* A saída será gravada sequencialmente na região 'mem' */
    .memory : {
        . = 0x000000; /* O contador de posição começa no zero */
        
        /* 1. Primeiro: A seção .init (Vem do bootloader.s) */
        /* Isso garante que a primeira instrução da RAM seja o salto inicial */
        *(.init);
        
        /* 2. Segundo: A seção .text (O código do programa C) */
        *(.text);
        
        /* 3. Terceiro: As seções de dados (Variáveis globais e constantes) */
        *(.data);
        *(.rodata);
        *(.bss);
        
        /* O resto da memória fica livre para a Pilha (Stack) que cresce do fim para o começo */
    } > mem
}