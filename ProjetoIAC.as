;=================================================================
; CONSTANTS
;-----------------------------------------------------------------
; Text window
TERM_READ       EQU     FFFFh
TERM_WRITE      EQU     FFFEh
TERM_STATUS     EQU     FFFDh
TERM_CURSOR     EQU     FFFCh
TERM_COLOR      EQU     FFFBh
TERM_COL_MAX    EQU     50h
TERM_LINE_MAX   EQU     2D
ULT_POS_TERM    EQU     2C4Fh
LINHA1          EQU     100h
LINHA2          EQU     200h
LINHA3          EQU     300h
LINHA4          EQU     400h
LINHA5          EQU     500h
LINHA6          EQU     600h
LINHA7          EQU     700h
LINHA8          EQU     700h
BLOCO           EQU     178

; Stack
SP_INIT         EQU     7000h

; timer
TIMER_CONTROL   EQU     FFF7h
TIMER_COUNTER   EQU     FFF6h
TIMER_SETSTART  EQU     1
TIMER_SETSTOP   EQU     0
TIMERCOUNT_MAX  EQU     20
TIMERCOUNT_MIN  EQU     1
TIMERCOUNT_INIT EQU     1

; DISPLAY
DISP7_D0        EQU     FFF0h
DISP7_D1        EQU     FFF1h
DISP7_D2        EQU     FFF2h
DISP7_D3        EQU     FFF3h
DISP7_D4        EQU     FFEEh
DISP7_D5        EQU     FFEFh
DIGITO1         EQU     10
DIGITO2         EQU     100
DIGITO3         EQU     1000
DIGITO4         EQU     10000

; interruptions
INT_MASK        EQU     FFFAh
INT_MASK_VAL    EQU     8009h ; 1000 0000 0000 1001 b

; geração de terreno
POTENCIA        EQU     b400h
TERRENO_TAMANHO EQU     80

; dinossauro
SALTO_UPDATE    EQU     100h

; geração dos cactos
NUM_GERADOR     EQU     F332h

; terreno de jogo
LINHA_TERRENO   EQU     1600h
ULTIMA_COLUNA   EQU     1650h
FIM_TABELA      EQU     1550h
ALTURA_ESPACOS  EQU     10
MUDAR_LINHA     EQU     100h
ULT_POS_TAB     EQU     1550h
CACTO           EQU     '#'
ESPACO          EQU     ' '
UNDERSCORE      EQU     '_'

; colisões
COLUNAS         EQU     00FFh

; salto
ALT_SALTO_MAX   EQU     700h

; cores
COR_DINO_CONS   EQU     001Ch
COR_TERRENO_CONS        EQU 00FCh
COR_CACTO_CONS  EQU     001Ch
COR_GAME_OVER_CONS      EQU 00E0h
COR_DEFAULT_CONS        EQU 00FFh
;=================================================================
; VARIAVEIS
;-----------------------------------------------------------------
; Geração de terreno
                ORIG    0000h
; Geracacto
altura          WORD    4        ;altura
seed            WORD    4        ;semente

;Timer
TIMER_COUNTVAL  WORD    TIMERCOUNT_INIT ; indica o atual período de contagem
TIMER_TICK      WORD    0

; Dino                                  ; interrupções do timer              
SALTAR          WORD    0
POS_DINO        WORD    0
ALTURA_DINO     WORD    1
CURSOR_DINO     WORD    1500h
COLUNA_DINO     WORD    0000h

; Jogo
GAME_RESTART    WORD    0
PONTUACAO       WORD    0
GAME_OVER_VAR   WORD    1012h
TEXTO_GAME_OVER WORD    1812h
STRING_GM       STR     'PRESSIONE O BOTAO 0 PARA JOGAR DE NOVO',0
START_DINO      WORD    0220h
TEXTO_DINO      WORD    0A1Ah
STRING_DINO     STR     'PRESSIONE O BOTAO 0 PARA JOGAR',0
APAGAR_TXT_DINO STR     '                              ',0


                ORIG    1500h ; IMPORTANTE NAO MUDAR
terrenojogo     TAB     80


;=================================================================
; PROGRAMA PRINCIPAL
;-----------------------------------------------------------------
                ORIG    0000h
MAIN:           

; Esta função não recebe nem retorna nada. É a função principal do programa e o 
; seu propósito é habilitar as interrupções, iniciar o temporizador e verificar 
; se o mesmo já chegou a zero (através do TIMER_TICK).

                

                MVI     R6,SP_INIT
                
                ; Configura as rotinas de interrupção
                ; Máscara de interrupções
                MVI     R1,INT_MASK
                MVI     R2,INT_MASK_VAL
                STOR    M[R1],R2
                ; habilita interrupções
                ENI
                
                MVI     R1, START_DINO ; posição inicial do texto
                MVI     R2, BLOCO ; caracter utilizado para escrever
                JAL     WRITE_DINO
                
                MVI     R1, TEXTO_DINO ; endereço do cursor
                MVI     R2, STRING_DINO ; texto que vai ser escrito no terminal
                JAL     DINO_TXT_INSERIR
                
.loop_texto:    MVI     R1, GAME_RESTART
                LOAD    R2, M[R1]
                CMP     R2, R0 ; não começa enquanto o jogador não clicar em '0' 
                BR.Z    .loop_texto
                
                MVI     R1, TEXTO_DINO
                MVI     R2, APAGAR_TXT_DINO
                JAL     DINO_TXT_APAGAR
restart:        

                ; Inicia o Timer
                ; código retirado e adaptado do exercício 3 da prep Lab 4
                MVI     R2,TIMERCOUNT_INIT
                MVI     R1,TIMER_COUNTER
                STOR    M[R1],R2          
                MVI     R1,TIMER_TICK
                STOR    M[R1],R0          ; limpa os timer tick
                MVI     R1,TIMER_CONTROL
                MVI     R2,TIMER_SETSTART
                STOR    M[R1],R2          ; começa timer
                
                MVI     R5,TIMER_TICK
.loop:          LOAD    R1,M[R5]
                CMP     R1,R0
                BR.Z    .loop
                ; Decrementar o Timer Tcik
                MVI     R2,TIMER_TICK
                DSI     ; região: crítica, se uma interrupção acontecer, pode gera um valor errado
                LOAD    R1,M[R2]
                DEC     R1
                STOR    M[R2],R1
                ENI
                ; FUNÇÕES
                
                MVI     R1, terrenojogo
                MVI     R2, TERRENO_TAMANHO 
                JAL     ATUALIZAJOGO
                
                MVI     R1, terrenojogo
                JAL     ATUALIZATERRENO
                
                MVI     R1, SALTAR
                JAL     DINO
                
                MVI     R1, terrenojogo
                MVI     R2, PONTUACAO
                JAL     ATUALIZAPONTUACAO
.final:         BR      .loop
                
fim:            BR      fim
                



;=================================================================
; FUNÇÕES
;-----------------------------------------------------------------
                ORIG    1000h
;------------------------------------------------------------------------------

WRITE_DINO:     

; Esta função recebe dois argumentos: a variável 'START_DINO' e a variável
; 'BLOCO'. Não retorna nada. Esta função irá escrever "DINO" no terminal 
; utilizando blocos (pixels)

                ; GUARDAR CONTEXTO
                DEC     R6
                STOR    M[R6], R4
                DEC     R6
                STOR    M[R6],R5
                DEC     R6
                STOR    M[R6], R7
                ;FUNÇÃ0
                LOAD    R4, M[R1]
                
                ;em cada coluna vamos inserir os blocos de cima para baixo
                ;depois incrementamos o R4, que será o primeiro endereço
                ;de cada coluna
                
                ; LETRA D
                JAL     COLUNA1
                JAL     COLUNA2
                JAL     COLUNA2
                JAL     COLUNA2
                JAL     COLUNA13
                ; ESPAÇO
                INC     R4
                ; LETRA I
                JAL     COLUNA1
                ; ESPAÇO
                INC     R4
                ;LETRA N
                JAL     COLUNA1
                JAL     COLUNA7
                JAL     COLUNA14
                JAL     COLUNA15
                JAL     COLUNA1
                ; ESPAÇO
                INC     R4
                ; LETRA O
                JAL     COLUNA1
                JAL     COLUNA2
                JAL     COLUNA2
                JAL     COLUNA1
                ;REPOR CONTEXTO
                LOAD    R7, M[R6]
                INC     R6
                LOAD    R5, M[R6]
                INC     R6
                LOAD    R4, M[R6]
                INC     R6
                ;RETORNAR
                JMP     R7

DINO_TXT_INSERIR:

; Esta funcao recebe dois argumentos: a variável 'TEXTO_DINO' e a variável
; 'STRING_DINO'. Não retorna nenhum valor. Esta função insere o texto inicial 
; debaixo das letras "DINO"

                DEC     R6
                STOR    M[R6], R7
                
                ;FUNÇÃO
                LOAD    R1, M[R1]
                JAL     TEXTO
                
                ;RETORNAR
                LOAD    R7, M[R6]
                INC     R6
                
                JMP     R7
                
                


DINO_TXT_APAGAR:

; Esta função recebe dois argumentos: o endereço do cursor da frase que queremos
; apagar e uma cadeia de caracteres composta de espaços. Esta função não retorna
; nada. A sua função é apagar o texto debaixo das letras "DINO".
                
                DEC     R6
                STOR    M[R6], R7
                
                ;FUNÇÃO
                LOAD    R1, M[R1]
                JAL     TEXTO
                
                ;RETORNAR
                LOAD    R7, M[R6]
                INC     R6
                
                
                JMP     R7


WRITE_GAMEOVER: 

; Esta função recebe duas variáveis: a posição inicial do texto e o caractér
; utilizado para escrever (bloco). Esta função não retorna nada.
; A sua função é escrever "GAME OVER" no terminal utilizando blocos.

                ; GUARDAR CONTEXTO
                DEC     R6
                STOR    M[R6], R4
                DEC     R6
                STOR    M[R6],R5
                DEC     R6
                STOR    M[R6], R7
                
                ;FUNÇÃO
                LOAD    R4, M[R1]
                
                ;em cada coluna vamos inserir os blocos de cima para baixo
                ;depois incrementamos o R4, que será o primeiro endereço
                ;de cada coluna
                
                ; LETRA G
                JAL     COLUNA1
                JAL     COLUNA2
                JAL     COLUNA2
                JAL     COLUNA3
                JAL     COLUNA4
                ; ESPAÇO
                INC     R4
                ; LETRA A
                JAL     COLUNA1
                JAL     COLUNA5
                JAL     COLUNA5
                JAL     COLUNA1
                ; ESPAÇO
                INC     R4
                ; LETRA M
                JAL     COLUNA1
                JAL     COLUNA6
                JAL     COLUNA7
                JAL     COLUNA7
                JAL     COLUNA6
                JAL     COLUNA1
                ; ESPAÇO
                INC     R4
                ; LETRA E
                JAL     COLUNA1
                JAL     COLUNA3
                JAL     COLUNA3
                JAL     COLUNA2
                ;ESPAÇO
                INC     R4
                INC     R4
                INC     R4
                ; LETRA O
                JAL     COLUNA1
                JAL     COLUNA2
                JAL     COLUNA2
                JAL     COLUNA1
                ;ESPAÇO
                INC     R4
                ; LETRA V
                JAL     COLUNA8
                JAL     COLUNA9
                JAL     COLUNA10
                JAL     COLUNA9
                JAL     COLUNA8
                ; ESPAÇO
                INC     R4
                ; LETRA E
                JAL     COLUNA1
                JAL     COLUNA3
                JAL     COLUNA3
                JAL     COLUNA2
                ; ESPAÇO
                INC     R4
                ; LETRA R
                JAL     COLUNA1
                JAL     COLUNA11
                JAL     COLUNA11
                JAL     COLUNA11
                JAL     COLUNA12
                
                ; TEXTO COM A INSTRUÇÃO PARA REINICIAR O JOGO
                MVI     R1, TEXTO_GAME_OVER
                LOAD    R1, M[R1]
                MVI     R2, STRING_GM
                JAL     TEXTO
                
                ;REPOR CONTEXTO
                LOAD    R7, M[R6]
                INC     R6
                LOAD    R5, M[R6]
                INC     R6
                LOAD    R4, M[R6]
                INC     R6
                ;RETORNAR
                JMP     R7
                
                
TEXTO:          

; Esta função recebe dois argumentos: a posição do cursor e a string que vai ser
; escrita no terminal. Não retorna nada. A sua função é inserir os elementos da
; string no terminal, na posição desejada. A função sabe que tem que acabar 
; quando o valor hexadecimal do caracter na string é 0.

                DEC     R6
                STOR    M[R6], R4
                DEC     R6
                STOR    M[R6], R5
                DEC     R6
                STOR    M[R6], R7
                
.loop:          MOV     R5, R1
                LOAD    R4, M[R2]
                CMP     R4, R0
                BR.Z    .sair ; se o caracter a inserir for 0, sai da função
                MVI     R1, TERM_CURSOR
                STOR    M[R1], R5
                MVI     R1, TERM_WRITE
                STOR    M[R1], R4
                INC     R5
                INC     R2
                BR      .loop
                
.sair:          LOAD    R7, M[R6]
                INC     R6
                LOAD    R5, M[R6]
                INC     R6
                LOAD    R4, M[R6]
                INC     R6

                JMP     R7

;--COLUNAS----------------------------------------------------------------

; Está representando em baixo de cada função a disposição dos blocos
; que cada função insere. 1 = Posição com bloco; 0 = Posição sem bloco.

COLUNA1:        MVI     R5, 7
                DEC     R6
                STOR    M[R6], R4
.loop:          MVI     R1, TERM_CURSOR
                STOR    M[R1], R4
                MVI     R1, TERM_WRITE
                STOR    M[R1], R2
                MVI     R1, LINHA1
                ADD     R4, R4, R1
                DEC     R5
                CMP     R5, R0
                BR.P    .loop
                LOAD    R4, M[R6]
                INC     R6
                INC     R4
                JMP     R7
                
                ;1
                ;1
                ;1
                ;1
                ;1
                ;1
                ;1
                
COLUNA2:        MVI     R5, 2
                DEC     R6
                STOR    M[R6], R4            
.loop:          MVI     R1, TERM_CURSOR
                STOR    M[R1], R4
                MVI     R1, TERM_WRITE
                STOR    M[R1], R2
                MVI     R1, LINHA6
                ADD     R4, R4, R1
                DEC     R5
                CMP     R5, R0
                BR.P    .loop
                LOAD    R4, M[R6]
                INC     R6
                INC     R4
                JMP     R7
                
                ;1
                ;0
                ;0
                ;0
                ;0
                ;0
                ;1
                
COLUNA3:        MVI     R5, 3
                DEC     R6
                STOR    M[R6], R4
.loop:          MVI     R1, TERM_CURSOR
                STOR    M[R1], R4
                MVI     R1, TERM_WRITE
                STOR    M[R1], R2
                MVI     R1, LINHA3
                ADD     R4, R4, R1
                DEC     R5
                CMP     R5, R0
                BR.P    .loop
                LOAD    R4, M[R6]
                INC     R6
                INC     R4
                JMP     R7
                
                ;1
                ;0
                ;0
                ;1
                ;0
                ;0
                ;1
                
COLUNA4:        DEC     R6
                STOR    M[R6], R4
                
                MVI     R1, TERM_CURSOR
                STOR    M[R1], R4
                MVI     R1, TERM_WRITE
                STOR    M[R1], R2
                MVI     R1, LINHA3
                ADD     R4, R4, R1

                MVI     R5, 4
.loop:          MVI     R1, TERM_CURSOR
                STOR    M[R1], R4
                MVI     R1, TERM_WRITE
                STOR    M[R1], R2
                MVI     R1, LINHA1
                ADD     R4, R4, R1
                DEC     R5
                CMP     R5, R0
                BR.P    .loop
                LOAD    R4, M[R6]
                INC     R6
                INC     R4
                JMP     R7
                
                ;1
                ;0
                ;0
                ;1
                ;1
                ;1
                ;1
                
COLUNA5:        DEC     R6
                STOR    M[R6], R4
                MVI     R5, 2
.loop:          MVI     R1, TERM_CURSOR
                STOR    M[R1], R4
                MVI     R1, TERM_WRITE
                STOR    M[R1], R2
                MVI     R1, LINHA3
                ADD     R4, R4, R1
                DEC     R5
                CMP     R5, R0
                BR.P    .loop
                LOAD    R4, M[R6]
                INC     R6
                INC     R4
                JMP     R7
                
                ;1
                ;0
                ;0
                ;1
                ;0
                ;0
                ;0
                
COLUNA6:        MVI     R1, TERM_CURSOR
                STOR    M[R1], R4
                MVI     R1, TERM_WRITE
                STOR    M[R1], R2
                INC     R4
                JMP     R7
                
                ;1
                ;0
                ;0
                ;0
                ;0
                ;0
                ;0

COLUNA7:        DEC     R6
                STOR    M[R6], R4
                MVI     R1, LINHA1
                ADD     R4, R4, R1
                MVI     R1, TERM_CURSOR
                STOR    M[R1], R4
                MVI     R1, TERM_WRITE
                STOR    M[R1], R2
                LOAD    R4, M[R6]
                INC     R6
                INC     R4
                JMP     R7
                
                ;0
                ;1
                ;0
                ;0
                ;0
                ;0
                ;0
                
COLUNA8:        MVI     R5, 5
                DEC     R6
                STOR    M[R6], R4
.loop:          MVI     R1, TERM_CURSOR
                STOR    M[R1], R4
                MVI     R1, TERM_WRITE
                STOR    M[R1], R2
                MVI     R1, LINHA1
                ADD     R4, R4, R1
                DEC     R5
                CMP     R5, R0
                BR.P    .loop
                LOAD    R4, M[R6]
                INC     R6
                INC     R4
                JMP     R7
                
                ;1
                ;1
                ;1
                ;1
                ;1
                ;0
                ;0
                
COLUNA9:        DEC     R6
                STOR    M[R6], R4
                MVI     R1, LINHA5
                ADD     R4, R4, R1
                MVI     R1, TERM_CURSOR
                STOR    M[R1], R4
                MVI     R1, TERM_WRITE
                STOR    M[R1], R2
                LOAD    R4, M[R6]
                INC     R6
                INC     R4
                JMP     R7
                
                ;0
                ;0
                ;0
                ;0
                ;0
                ;1
                ;0
                
COLUNA10:       DEC     R6
                STOR    M[R6], R4
                MVI     R1, LINHA6
                ADD     R4, R4, R1
                MVI     R1, TERM_CURSOR
                STOR    M[R1], R4
                MVI     R1, TERM_WRITE
                STOR    M[R1], R2
                LOAD    R4, M[R6]
                INC     R6
                INC     R4
                JMP     R7
                
                ;0
                ;0
                ;0
                ;0
                ;0
                ;0
                ;10
                
COLUNA11:       DEC     R6
                STOR    M[R6], R4
                MVI     R5, 2
.loop:          MVI     R1, TERM_CURSOR
                STOR    M[R1], R4
                MVI     R1, TERM_WRITE
                STOR    M[R1], R2
                MVI     R1, LINHA2
                ADD     R4, R4, R1
                DEC     R5
                CMP     R5, R0
                BR.P    .loop
                LOAD    R4, M[R6]
                INC     R6
                INC     R4
                JMP     R7
                
                ;1
                ;0
                ;1
                ;0
                ;0
                ;0
                ;0
                
COLUNA12:       DEC     R6
                STOR    M[R6], R4
                
                MVI     R1, LINHA1
                ADD     R4, R4, R1
                
                MVI     R1, TERM_CURSOR
                STOR    M[R1], R4
                MVI     R1, TERM_WRITE
                STOR    M[R1], R2
                MVI     R1, LINHA2
                ADD     R4, R4, R1
                
                ;0
                ;1
                ;0
                ;1
                ;1
                ;1
                ;1

                MVI     R5, 4
.loop:          MVI     R1, TERM_CURSOR
                STOR    M[R1], R4
                MVI     R1, TERM_WRITE
                STOR    M[R1], R2
                MVI     R1, LINHA1
                ADD     R4, R4, R1
                DEC     R5
                CMP     R5, R0
                BR.P    .loop
                LOAD    R4, M[R6]
                INC     R6
                INC     R4
                JMP     R7
                
COLUNA13:       DEC     R6
                STOR    M[R6], R4
                MVI     R1, LINHA1
                ADD     R4, R4, R1
                MVI     R5, 5
.loop:          MVI     R1, TERM_CURSOR
                STOR    M[R1], R4
                MVI     R1, TERM_WRITE
                STOR    M[R1], R2
                MVI     R1, LINHA1
                ADD     R4, R4, R1
                DEC     R5
                CMP     R5, R0
                BR.P    .loop
                LOAD    R4, M[R6]
                INC     R6
                INC     R4
                JMP     R7
                
                ;0
                ;1
                ;1
                ;1
                ;1
                ;1
                ;0
                
COLUNA14:       DEC     R6
                STOR    M[R6], R4
                MVI     R1, LINHA2
                ADD     R4, R4, R1
                MVI     R1, TERM_CURSOR
                STOR    M[R1], R4
                MVI     R1, TERM_WRITE
                STOR    M[R1], R2
                LOAD    R4, M[R6]
                INC     R6
                INC     R4
                JMP     R7
                
                ;0
                ;0
                ;1
                ;0
                ;0
                ;0
                ;0
                
COLUNA15:       DEC     R6
                STOR    M[R6], R4
                MVI     R1, LINHA3
                ADD     R4, R4, R1
                MVI     R1, TERM_CURSOR
                STOR    M[R1], R4
                MVI     R1, TERM_WRITE
                STOR    M[R1], R2
                LOAD    R4, M[R6]
                INC     R6
                INC     R4
                JMP     R7
                
                ;0
                ;0
                ;0
                ;1
                ;0
                ;0
                ;0

                
;------------------------------------------------------------------------------

DINO:           

; Esta função recebe como argumneto a variável 'Saltar'. Não retorna nada. A sua
; função é escrever o Dinossauro no Terminal.

                ; GUARDAR CONTEXTO
                DEC     R6
                STOR    M[R6], R4
                DEC     R6
                STOR    M[R6],R5
                DEC     R6
                STOR    M[R6], R7
                ; FUNÇÃO
                ; PROCESSAR SALTO
                LOAD    R2, M[R1]
                CMP     R2, R0 ; se salto for 1, então vai para a rotina de salto
                BR.Z    .inserir_dino

                JAL     ATUALIZAR_SALTO ; rotina de salto

.inserir_dino:  ; escreve o Dino no terminal
                MVI     R1, CURSOR_DINO ; linha
                LOAD    R2, M[R1]
                MVI     R1, POS_DINO ; coluna
                LOAD    R4, M[R1]
                SUB     R2, R2, R4
                MVI     R1, TERM_CURSOR
                STOR    M[R1], R2 ; coloca o cursor do terminal na posição desejada
                
                MVI     R1, TERM_COLOR
                JAL     COR_DINO ; alterar a cor do Dino
                
                MVI     R1, TERM_WRITE
                MVI     R2, 324 ; valor da tecla 'D' em ASCII
                STOR    M[R1], R2 ; escreve o dinossauro no terminal
                
                MVI     R1, TERM_COLOR
                JAL     COR_DEFAULT ; alterar a cor para default
                ;REPOR CONTEXTO
                LOAD    R7, M[R6]
                INC     R6
                LOAD    R5, M[R6]
                INC     R6
                LOAD    R4, M[R6]
                INC     R6
                ;RETORNAR
                JMP     R7

ATUALIZAR_SALTO:

; Esta função recebe como argumento a variável 'Saltar'. Não retorna nada.
; A sua função é atualizar a posição do Dino e escrever o mesmo no terminal caso
; o utilizador tenha premido o botão para saltar.

                ; GUARDAR CONTEXTO
                DEC     R6
                STOR    M[R6], R4
                DEC     R6
                STOR    M[R6],R5
                DEC     R6
                STOR    M[R6],R7
                ;FUNÇÃO
                LOAD    R2, M[R1]
                CMP     R2, R0 ; se for 0, não salta, se for 1 é ascendente, se for -1 é descendente
                BR.Z    .reporsair
                BR.P    .cima
                BR.N    .baixo

.cima:          MVI     R1, POS_DINO ; coluna
                LOAD    R2, M[R1]
                
                MVI     R4, MUDAR_LINHA 
                ADD     R2, R2, R4 ; linha acima da atual
                STOR    M[R1], R2
                
                MVI     R1, ALTURA_DINO
                JAL     AUMENTA_ALT_DINO ; rotina para guardar altura
                MVI     R1, ALT_SALTO_MAX
                CMP     R1, R2 ; compara se chegou à altura máxima de salto
                BR.P    .reporsair
                
                MVI     R2, -1
                MVI     R1, SALTAR ; indica que o próximo salto será descendente
                STOR    M[R1], R2
                
                
                
.baixo:         MVI     R1, POS_DINO ; coluna
                LOAD    R2, M[R1]
                MVI     R4, MUDAR_LINHA ; linha abaixo da atual
                SUB     R2, R2, R4
                STOR    M[R1], R2
                MVI     R1, ALTURA_DINO
                JAL     DIMINUI_ALT_DINO ; rotina para guardar altura
                MVI     R1, 0
                CMP     R2, R1 ; compara se chegou à altura mínima
                BR.P    .reporsair
                MVI     R2, 0
                MVI     R1, SALTAR ; indica que o salto terminou
                STOR    M[R1], R2
                
.reporsair:     ;REPOR CONTEXTO
                LOAD    R7, M[R6]
                INC     R6
                LOAD    R5, M[R6]
                INC     R6
                LOAD    R4, M[R6]
                INC     R6
                ;RETORNAR
                JMP     R7
                
AUMENTA_ALT_DINO:

; Esta função recebe como argumento a variável 'ALTURA_DINO'. Não retorna nada.
; A sua função é incrementar o valor da variável para que esta corresponda à 
; altura em que o Dino se encontra.

                ; GUARDAR CONTEXTO
                DEC     R6
                STOR    M[R6], R7
                DEC     R6
                STOR    M[R6], R2
                
                ; Incrementa o valor da variável
                LOAD    R2, M[R1]
                INC     R2
                STOR    M[R1], R2
                
                ; REPOR CONTEXTO
                LOAD    R2, M[R6]
                INC     R6
                LOAD    R7, M[R6]
                INC     R6
                
                JMP     R7
                
DIMINUI_ALT_DINO:

; Esta função recebe como argumento a variável 'ALTURA_DINO'. Não retorna nada.
; A sua função é decrementar o valor da variável para que esta corresponda à 
; altura em que o Dino se encontra.

                ; GUARDAR CONTEXTO
                DEC     R6
                STOR    M[R6], R7
                DEC     R6
                STOR    M[R6], R2
                
                ; Decrementa o valor da variável
                LOAD    R2, M[R1]
                DEC     R2
                STOR    M[R1], R2
                
                ; REPOR CONTEXTO
                LOAD    R2, M[R6]
                INC     R6
                LOAD    R7, M[R6]
                INC     R6
                
                JMP     R7
                
COR_DINO:      

; Esta função recebe como argumento o porto de controlo de cor do terminal.
; Não devolve nada. A sua função é alterar a cor do terminal, para que o Dino
; seja escrito em verde

                DEC     R6
                STOR    M[R6], R7
                DEC     R6
                STOR    M[R6], R5
                
                MVI     R5, COR_DINO_CONS ; 0000 0000 0001 1100b , verde
                STOR    M[R1], R5
                
                LOAD    R5, M[R6]
                INC     R6
                LOAD    R7, M[R6]
                INC     R6
                
                JMP     R7
;------------------------------------------------------------------

                ;TERRENO DE JOGO
TERRENO_JOGO:   

; Esta função recebe um argumento: o endereço da linha em que será colocado o 
; terreno, no terminal. Não retorna nada. O seu propósito é escrever no terminal
; o Terreno de jogo.

                ; GUARDAR CONTEXTO
                DEC     R6
                STOR    M[R6], R1
                DEC     R6
                STOR    M[R6], R4
                DEC     R6
                STOR    M[R6],R5
                DEC     R6
                STOR    M[R6],R7
                
                ;FUNÇÃO
                MVI     R4, BLOCO

.loop:          MVI     R1, TERM_CURSOR
                STOR    M[R1], R2
                
                MVI     R1, TERM_COLOR
                JAL     COR_TERRENO ; altera a cor do terreno
                
                MVI     R1, TERM_WRITE
                STOR    M[R1], R4 ; escreve '-' numa coluna da linha
                
                MVI     R1, TERM_COLOR
                JAL     COR_DEFAULT ; alterar a cor para default
                
                MVI     R1, ULTIMA_COLUNA     ;linha 16h, coluna 50h
                INC     R2
                CMP     R1, R2 ; verifica se já chegou ao fim da linha
                BR.P    .loop
                
                ;REPOR CONTEXTO
                LOAD    R7, M[R6]
                INC     R6
                LOAD    R5, M[R6]
                INC     R6
                LOAD    R4, M[R6]
                INC     R6
                LOAD    R1, M[R6]
                INC     R6
                ;RETORNAR
                JMP     R7
                

COR_TERRENO:      

; Esta função recebe como argumento o porto de controlo de cor do terminal.
; Não devolve nada. A sua função é alterar a cor do terminal, para que o Terreno
; seja escrito a amarelo.

                DEC     R6
                STOR    M[R6], R7
                DEC     R6
                STOR    M[R6], R5
                
                MVI     R5, COR_TERRENO_CONS ; 0000 0000 1111 1100b , amarelo
                STOR    M[R1], R5
                
                LOAD    R5, M[R6]
                INC     R6
                LOAD    R7, M[R6]
                INC     R6
                
                JMP     R7
                
;-----------------------------------------------------------------
ATUALIZATERRENO:

; Esta função recebe como argumento a tabela que representa o terreno de jogo.
; Não retorna nada. A sua função é atualizar o terreno do jogo no terminal, de
; forma a que corresponda à tabela que o representa.

                ; GUARDAR CONTEXTO
                DEC     R6
                STOR    M[R6], R4
                DEC     R6
                STOR    M[R6],R5
                DEC     R6
                STOR    M[R6],R7
                ;FUNÇÃO
                
                ; INSERIR TERRENO
                MVI     R2, LINHA_TERRENO        ;linha 16h, coluna 0h
                JAL     TERRENO_JOGO
                
                MOV     R4, R1
.loop:          LOAD    R1, M[R4] ; valor do endereço na tabela e do endereço a inserir no cursor
                
                ;INSERIR CACTO SE HOUVER ELEMENTO NA TABELA
                DEC     R6
                STOR    M[R6],R7
                CMP     R1, R0
                
                LOAD    R2, M[R4]        ;R2 - tamanho do cacto
                JAL.NZ  INSERIR_CACTO
                
                MVI     R2, ALTURA_ESPACOS
                JAL.Z   INSERIR_SPACE
                LOAD    R7, M[R6]
                INC     R6
                
                ;VERIFICAR SE JÁ CHEGAMOS AO FINAL DA TABELA
                INC     R4
                MVI     R1, FIM_TABELA 
                CMP     R1, R4
                BR.P    .loop
.reporsair:     ;REPOR CONTEXTO
                LOAD    R7, M[R6]
                INC     R6
                LOAD    R5, M[R6]
                INC     R6
                LOAD    R4, M[R6]
                INC     R6
                ;SAIR
                JMP     R7

INSERIR_SPACE:  

; Esta função recebe como argumento a 'altura' (número de linhas) em que tem 
; que colocar espaços. Não retorna nada. A sua função é escrever espaços nas 
; colunas onde não deve haver cactos, 'apagando' os cactos que lá estavam.

                ;GUARDAR CONTEXTO
                DEC     R6
                STOR    M[R6], R4        ;R4 - cursor
                DEC     R6
                STOR    M[R6], R5
                DEC     R6
                STOR    M[R6],R7
                

                MVI     R5, ESPACO
                
.loop:          ;ESCREVER NO ECRÃ
                MVI     R1, TERM_CURSOR
                STOR    M[R1], R4
                MVI     R1, TERM_WRITE
                STOR    M[R1], R5
                ;TROCAR PARA LINHA ACIMA CURSOR
                MVI     R1, MUDAR_LINHA           ;R1 - 1 linha no cursor
                SUB     R4, R4, R1
                DEC     R2
                CMP     R2, R0
                BR.P    .loop
                ;REPOR CONTEXTO
                LOAD    R7, M[R6]
                INC     R6
                LOAD    R5, M[R6]
                INC     R6
                LOAD    R4, M[R6]
                INC     R6
                ;SAIR
                JMP     R7


INSERIR_CACTO:  

; Esta função recebe como argumento o tamanho do cacto que é suposto ser 
; inserido. Não retorna nada. A sua função é inserir um cacto no terminal com a
; mesma altura que o cato correspondente na tabela. Não escreve cacto caso isso
; provoque uma colisão

                ;GUARDAR CONTEXTO
                DEC     R6
                STOR    M[R6], R4        ;R4 - cursor
                DEC     R6
                STOR    M[R6], R5
                DEC     R6
                STOR    M[R6], R7
                
                MOV     R1, R4
                JAL     COLISAO
                
                MVI     R5, CACTO
                
.loop:          MVI     R1, TERM_COLOR
                JAL     COR_CACTO ; alterar a cor do cacto

                ;ESCREVER NO ECRÃ
                MVI     R1, TERM_CURSOR
                STOR    M[R1], R4
                
                MVI     R1, TERM_WRITE
                STOR    M[R1], R5
                
                MVI     R1, TERM_COLOR
                JAL     COR_DEFAULT ; alterar a cor para default
                ;TROCAR PARA LINHA ACIMA CURSOR
                MVI     R1, MUDAR_LINHA           ;R1 - 1 linha no cursor
                SUB     R4, R4, R1
                DEC     R2
                CMP     R2, R0
                BR.P    .loop
                
                ;REPOR CONTEXTO
                LOAD    R7, M[R6]
                INC     R6
                LOAD    R5, M[R6]
                INC     R6
                LOAD    R4, M[R6]
                INC     R6
                ;SAIR
                JMP     R7
                
COR_CACTO:      

; Esta função recebe como argumento o porto de controlo de cor do terminal.
; Não devolve nada. A sua função é alterar a cor do terminal, para que os cactos
; sejam escritos a verde.

                DEC     R6
                STOR    M[R6], R7
                DEC     R6
                STOR    M[R6], R5
                
                MVI     R5, COR_CACTO_CONS ; 0000 0000 0001 1100b , verde
                STOR    M[R1], R5
                
                LOAD    R5, M[R6]
                INC     R6
                LOAD    R7, M[R6]
                INC     R6
                
                JMP     R7
;-----------------------------------------------------------------           
ATUALIZAJOGO:   

; Esta função recebe como argumento a tabela que representa o terreno de jogos e
; o número de colunas da mesma. Não devolve nada. A sua função é atualizar a 
; tabela com as alterações que o jogo vai sofrendo (movimento dos cactos).

                ;GUARDAR CONTEXTO
                DEC     R6
                STOR    M[R6], R4 ; Guarda o valor original de R4
                DEC     R6
                STOR    M[R6], R5 ; Guarda o valor original de R5
                DEC     R6
                STOR    M[R6], R7
                
                ;FUNÇÃO
                MVI     R4, 80
                ADD     R5, R1, R4 ; R5 = endereço da coluna n
.loop:          MOV     R5, R1
                
                INC     R1 ; endereço da coluna n + 1
                
                LOAD    R4, M[R1] ; valor contido na coluna n + 1
                
                STOR    M[R5], R4 ; guarda o valor da coluna n + 1 na coluna n
                DEC     R2
                CMP     R2, R0
                BR.NZ   .loop
                
                ;INVOCAR FUNÇÃO GERACACTO
                DEC     R6
                STOR    M[R6], R1 ; Guarda endereço coluna mais à direita
                
                ; Definição dos argumentos de geracacto  
                MVI     R4, altura         
                LOAD    R1, M[R4] ; r1 = altura
                MVI     R4, seed 
                LOAD    R2, M[R4] ; r2 = seed  

                JAL     GERACACTO
                
                LOAD    R1, M[R6] ; Recupera endereço coluna mais à direita
                INC     R6
                STOR    M[R1], R3; Guarda na coluna mais à direita o valor do cacto gerado aleatoriamente
                
                ; REPOR CONTEXTO
                LOAD    R7, M[R6]
                INC     R6
                LOAD    R5, M[R6] ; Retomar valor original de R5
                INC     R6
                LOAD    R4, M[R6] ; Retomar valor original de R4
                INC     R6
                ; SAIR
                JMP     R7


GERACACTO:      

; Esta função recebe dois argumentos: a altura e a seed. Retorna um cacto cuja
; altura máxima é a definida pelo argumento. A sua função é gerar cactos de 
; forma 'aleatória'.

                ;GUARDAR CONTEXTO
                DEC     R6
                STOR    M[R6], R4 ; Guarda o valor original de R4
                DEC     R6
                STOR    M[R6], R5 ; Guarda o valor original de R5
                DEC     R6
                STOR    M[R6], R7; Guardar o valor original de R7
                
                ;FUNÇÃO
                MVI     R4, 1        
                AND     R4, R2, R4 ; r4 irá ser o bit, bit = x & 1
                SHR     R2 ; x = x >> 1
                CMP     R4, R0 ;if bit: (se bit for o, logo False            
                BR.Z    .pont ;          salta para pont)
                MVI     R4, POTENCIA        
                XOR     R2, R2, R4 ; x = XOR(x, b400h)
                
.pont:          MVI     R4, NUM_GERADOR ; if x < 62258
                CMP     R2, R4
                BR.NC   .return                
                MVI     R3, 0 ;return é 0
                MVI     R4, seed ; x é global
                STOR    M[R4], R2
                BR      .reporsair
                
.return:        ; so ocorre se o return for diferente de 0
                DEC     R1 ; return (x & (altura - 1)) + 1
                AND     R3, R1, R2
                INC     R3
                MVI     R4, seed ; x é global
                STOR    M[R4], R2
                
.reporsair:     ; REPOR CONTEXTO
                LOAD    R7, M[R6] ; Retomar valor original de R7
                INC     R6
                LOAD    R5, M[R6] ; Retomar valor original de R5
                INC     R6
                LOAD    R4, M[R6] ; Retomar valor original de R4
                INC     R6
                ;SAIR
                JMP     R7 

COLISAO:        

; Esta função recebe como argumento a posição em que o próximo cacto será 
; escrito e a altura do mesmo. Não retorna nada. A sua função é verificar se 
; existe alguma colisão entre o cacto e o Dinossauro.

                ;GUARDAR CONTEXTO
                DEC     R6
                STOR    M[R6], R7 ; Guarda o valor original de R7
                DEC     R6
                STOR    M[R6], R4
                DEC     R6
                STOR    M[R6], R2
                DEC     R6
                STOR    M[R6], R1
                
                MVI     R4, COLUNAS
                
                AND     R1, R1, R4 ; em R1 fica a coluna (ignora a linha)
                
                MVI     R4, COLUNA_DINO
                LOAD    R4, M[R4]
                
                CMP     R1, R4 ; compara se a coluna do cato é a mesma do Dino
                BR.NZ   .REPORSAIR
                
                MVI     R1, ALTURA_DINO
                LOAD    R4, M[R1]
                CMP     R4, R2 ; há colisão se a altura do cacto for igual ou
                               ; superior à altura da posição do Dino
                JAL.NP  GAME_OVER
                

.REPORSAIR:     ; REPOR CONTEXTO
                LOAD    R1, M[R6] ; Retomar valor original de R7
                INC     R6
                LOAD    R2, M[R6]
                INC     R6
                LOAD    R4, M[R6]
                INC     R6
                LOAD    R7, M[R6]
                INC     R6
                
                JMP     R7
                
;------------------------------------------------------------------------------

ATUALIZAPONTUACAO:

; Esta função recebe como argumento as variáveis 'terrenojogo' e 'PONTUACAO'.
; Não retorna nada. A sua função é atualizar a pontuação do jogador.

                ; GUARDAR CONTEXTO
                DEC     R6
                STOR    M[R6], R4
                DEC     R6
                STOR    M[R6],R5
                DEC     R6
                STOR    M[R6], R7
                ;FUNÇÃO
                LOAD    R4, M[R1]
                CMP     R4, R0 ; verifica se na posição do terreno há um cacto
                BR.Z    .reporsair
                
                ; Incrementa pontuação quando o Dino salta por cima de um cacto
                LOAD    R5, M[R2]
                INC     R5
                STOR    M[R2], R5
                
                MVI     R1, PONTUACAO
                JAL     ESCREVERDISPLAY 

                ;REPOR CONTEXTO
.reporsair:     LOAD    R7, M[R6]
                INC     R6
                LOAD    R5, M[R6]
                INC     R6
                LOAD    R4, M[R6]
                INC     R6
                ;RETORNAR
                JMP     R7

ESCREVERDISPLAY:

; Esta dunção recebe como argumento a variável 'pontuação'. Não devolve nada.
; A sua função é escrever no Display de 7 segmentos a pontuação do jogador.

                ; GUARDAR CONTEXTO
                DEC     R6
                STOR    M[R6], R4
                DEC     R6
                STOR    M[R6],R5
                DEC     R6
                STOR    M[R6], R7
                MVI     R4, 0
                ;FUNÇÃO
                LOAD    R2, M[R1]
                
                ;DISPLAY 4
                MVI     R4, 0
                MVI     R1, DIGITO4
.loopdisplay4:  CMP     R2, R1
                BR.N    .escreverdisplay4
                SUB     R2, R2, R1
                INC     R4
                BR      .loopdisplay4

.escreverdisplay4:
                MVI     R1, DISP7_D4
                STOR    M[R1],R4
                
                ;DISPLAY 3
                MVI     R4, 0
                MVI     R1, DIGITO3
.loopdisplay3:  CMP     R2, R1
                BR.N    .escreverdisplay3
                SUB     R2, R2, R1
                INC     R4
                BR      .loopdisplay3

.escreverdisplay3:
                MVI     R1, DISP7_D3
                STOR    M[R1],R4
                
                ;DISPLAY 2
                MVI     R4, 0
                MVI     R1, DIGITO2
.loopdisplay2:  CMP     R2, R1
                BR.N    .escreverdisplay2
                SUB     R2, R2, R1
                INC     R4
                BR      .loopdisplay2

.escreverdisplay2:
                MVI     R1, DISP7_D2
                STOR    M[R1],R4
                
                ;DISPLAY 1
                MVI     R4, 0
                MVI     R1, DIGITO1
.loopdisplay1:  CMP     R2, R1
                BR.N    .escreverdisplay1
                SUB     R2, R2, R1
                INC     R4
                BR      .loopdisplay1

.escreverdisplay1:
                MVI     R1, DISP7_D1
                STOR    M[R1], R4
                
                ;DISPLAY0
.escreverdisplay0:
                MVI     R1, DISP7_D0
                STOR    M[R1], R2

                
                ;REPOR CONTEXTO
.reporsair:     LOAD    R7, M[R6]
                INC     R6
                LOAD    R5, M[R6]
                INC     R6
                LOAD    R4, M[R6]
                INC     R6
                ;RETORNAR
                JMP     R7

;------------------------------------------------------------------------------
                
GAME_OVER:      

; Esta função não recebe nem retorna nada. A sua função é aguardar que o jogador
; clique no botão '0' para dar restart ao jogo após perder.
                
                ;GUARDAR CONTEXTO
                DEC     R6
                STOR    M[R6], R7 ; Guarda o valor original de R7
                
                MVI     R1, GAME_RESTART
                MVI     R2, 0
                STOR    M[R1], R2
                
                JAL     LIMPAR_TERM ; limpar o terminal
                
                MVI     R1, TERM_COLOR
                JAL     COR_GAME_OVER ; alterar a cor do 'GAME OVER'
                
                MVI     R1, GAME_OVER_VAR ; posição inicial do texto
                MVI     R2, BLOCO ; caracter utilizado para escrever
                JAL     WRITE_GAMEOVER
                
                MVI     R1, TERM_COLOR
                JAL     COR_DEFAULT ; alterar a cor para default
                
.loop:          MVI     R1, GAME_RESTART
                LOAD    R1, M[R1]
                
                CMP     R1, R0 ; Verifica se o botao '0' foi pressionado
                BR.Z   .loop
                
                JAL     LIMPAR_TERM ; limpar o terminal
                
                MVI     R1, terrenojogo
                JAL     RESET_TERRENO ; dar reset da tabela
                
                JAL     RESET_VARIAVEIS ; dá reset nas variáveis
                
                JAL     ESCREVERDISPLAY ; dá reset na pontuação do Display
                
                MVI     R1, START_DINO ; posição inicial do texto
                MVI     R2, BLOCO ; caracter utilizado para escrever
                JAL     WRITE_DINO ; escrever Dino
                
                ; REPOR CONTEXTO
                LOAD    R7, M[R6] ; Retomar valor original de R7
                INC     R6
                
                JAL     restart

LIMPAR_TERM:    

; Esta função não recebe argumentos nem devolve nada. O seu objetivo é 'limpar'
; o terminal, escrevendo em todas as posições um espaço ' ' .
                
                ;GUARDAR CONTEXTO
                DEC     R6
                STOR    M[R6], R7 ; Guarda o valor original de R7
                DEC     R6
                STOR    M[R6], R4
                DEC     R6
                STOR    M[R6], R5
                
                
                MVI     R2, 0 ; contador
                MVI     R4, ' '
.loop:          
                MVI     R1, TERM_WRITE
                STOR    M[R1], R4 ; print ' ' para 'limpar' a posição do cursor
                INC     R2
                MVI     R5, ULT_POS_TERM
                CMP     R2, R5
                BR.N    .loop
                
                JMP     R7
                
                ; REPOR CONTEXTO
                LOAD    R5, M[R6]
                INC     R6
                LOAD    R4, M[R6]
                INC     R6
                LOAD    R7, M[R6] ; Retomar valor original de R7
                INC     R6
                
RESET_TERRENO:  

; Esta função recebe como argumento a tabela que representa o Terreno de jogo.
; Não devolve nada. A sua função é limpar o terreno de jogo (eleminando todos 
; os cactos).
                
                ;GUARDAR CONTEXTO
                DEC     R6
                STOR    M[R6], R7 ; Guarda o valor original de R7
                DEC     R6
                STOR    M[R6], R4
                DEC     R6
                STOR    M[R6], R5


.loop:          MVI     R2, 0
                STOR    M[R1], R2 ; coloca 0 em todas as posicoes da tabela
                INC     R1
                MVI     R2, ULT_POS_TAB
                CMP     R1, R2
                BR.NP   .loop
                
                ; REPOR CONTEXTO
                LOAD    R5, M[R6]
                INC     R6
                LOAD    R4, M[R6]
                INC     R6
                LOAD    R7, M[R6] ; Retomar valor original de R7
                INC     R6
                
                JMP     R7
                
RESET_VARIAVEIS:

; Função não recebe argumentos nem devolve nada. A sua função é colocar todas 
; as variáveis com o seu valor inicial

                ; GUARDAER CONTEXTO
                DEC     R6
                STOR    M[R6], R7
                
                ; Reset dos valores
                MVI     R1, TIMER_TICK
                MVI     R2, 0
                STOR    M[R1], R2
                
                MVI     R1, SALTAR
                MVI     R2, 0
                STOR    M[R1], R2
                
                MVI     R1, POS_DINO
                MVI     R2, 0
                STOR    M[R1], R2
                
                MVI     R1, ALTURA_DINO
                MVI     R2, 1
                STOR    M[R1], R2
                
                MVI     R1, PONTUACAO
                MVI     R2, 0
                STOR    M[R1], R2
                
                LOAD    R7, M[R6]
                INC     R6
                
                JMP     R7
                
COR_GAME_OVER:      

; Esta função recebe como argumento o porto de controlo de cor do terminal.
; Não devolve nada. A sua função é alterar a cor do terminal, para que o texto
; 'GAME OVER' seja escrito a vermelho.

                DEC     R6
                STOR    M[R6], R7
                DEC     R6
                STOR    M[R6], R5
                
                MVI     R5, COR_GAME_OVER_CONS ; 0000 0000 1110 0000b , vermelho
                STOR    M[R1], R5
                
                LOAD    R5, M[R6]
                INC     R6
                LOAD    R7, M[R6]
                INC     R6
                
                JMP     R7
                
COR_DEFAULT:      

; Esta função recebe como argumento o porto de controlo de cor do terminal.
; Não devolve nada. A sua função é alterar a cor do terminal para branco que 
; foi a cor que escolhemos como default.

                DEC     R6
                STOR    M[R6], R7
                DEC     R6
                STOR    M[R6], R5
                
                MVI     R5, COR_DEFAULT_CONS ; 0000 0000 1111 1111b , branco
                STOR    M[R1], R5
                
                LOAD    R5, M[R6]
                INC     R6
                LOAD    R7, M[R6]
                INC     R6
                
                JMP     R7
;-------------------------------------------------------------------------------            

;*****************************************************************
; AUXILIARES INTERRUPÇÕES
;*****************************************************************
AUX_TIMER_ISR:  

; Esta função não recebe nem retorna nada. A sua utilidade é reiniciar o Timer
; e incrementar a variável TIMER_TICK, identificando que houve uma interrupção.

                ; Guardar contexto
                DEC     R6
                STOR    M[R6],R1
                DEC     R6
                STOR    M[R6],R2
                ; Reiniciar o Timer
                MVI     R1,TIMER_COUNTVAL
                LOAD    R2,M[R1]
                MVI     R1,TIMER_COUNTER
                STOR    M[R1],R2
                MVI     R1,TIMER_CONTROL
                MVI     R2,TIMER_SETSTART
                STOR    M[R1],R2
                ; Incrementar a FLAG do timer
                MVI     R2,TIMER_TICK
                LOAD    R1,M[R2]
                INC     R1
                STOR    M[R2],R1
                ; Repor contexto
                LOAD    R2,M[R6]
                INC     R6
                LOAD    R1,M[R6]
                INC     R6
                JMP     R7

;*****************************************************************
; INTERRUPÇÕES
;*****************************************************************
                ORIG    7FF0h
TIMER_ISR:      ; Guardar contexto
                DEC     R6
                STOR    M[R6],R7
                ; Chamar função auxiliar
                JAL     AUX_TIMER_ISR
                ; Repor contexto
                LOAD    R7,M[R6]
                INC     R6
                RTI
                
                ORIG    7F30h
SALTO_DINO:     ; Guardar contexto
                DEC     R6
                STOR    M[R6],R2
                DEC     R6
                STOR    M[R6], R1
                MVI     R1, SALTAR
                LOAD    R1, M[R1]
                MVI     R2, 1
                CMP     R1, R0
                BR.NZ   .reporsair
                MVI     R1, SALTAR
                STOR    M[R1], R2
                ; Repor contexto
.reporsair:     LOAD    R1, M[R6]
                INC     R6
                LOAD    R2,M[R6]
                INC     R6
                RTI

                ORIG    7F00h
                
RESTART_GAME:   ; Guardar contexto
                DEC     R6
                STOR    M[R6],R2
                DEC     R6
                STOR    M[R6],R1
                
                MVI     R1, GAME_RESTART
                MVI     R2, 1
                STOR    M[R1], R2

                ; Repor contexto
                LOAD    R1,M[R6]
                INC     R6
                LOAD    R2,M[R6]
                INC     R6
                RTI
