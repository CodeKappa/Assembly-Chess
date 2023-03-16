.386
.model flat, stdcall
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;includem biblioteci, si declaram ce functii vrem sa importam
includelib msvcrt.lib
extern exit: proc
extern malloc: proc
extern memset: proc
extern fopen: proc
extern fclose: proc
extern fgets: proc
extern printf: proc

includelib canvas.lib
extern BeginDrawing: proc
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;declaram simbolul start ca public - de acolo incepe executia
public start
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;sectiunile programului, date, respectiv cod
.data
;aici declaram date
window_title DB "Proiect PLA | Kovacs Paul-Adrian | Sah", 0
area_width EQU 400
area_height EQU 500
area DD 0

counter DD 0 ; numara evenimentele de tip timer

;;fen file
mode_read DB "r", 0
format DB "%s", 10, 0
format_c DB "%c", 10, 0
format_d DB "%d", 10, 0
file_name DB "fen.txt", 0
fen DB 100 DUP (0)
debug_msg DB "I was here", 10, 0

;;game
tomove DB 0
WK DB 0
WQ DB 0
BK DB 0
BQ DB 0
en_i DB 0
en_j DB 0
hmc_zeci DB 0
hmc_uni DB 0
move_stage DB 0
stage0x DD 0
stage0y DD 0
stage1x DD 0
stage1y DD 0
valid DB 0
update DB 0

;;table
table DB 65 DUP (0)
i DD 0
j DD 0
k DD 0
cont DD 0
cc DD 0
x DD 0
y DD 0
w DD 0
t DD 0

;;board constants
nr_of_squares EQU 8
board_square_l EQU 40
board_color DD 0ffe3bah, 0d9975dh
white_square EQU 0fff3e8h
black_square EQU 0cf884ah
table_start_x EQU 30
table_start_y EQU 100

arg1 EQU 8
arg2 EQU 12
arg3 EQU 16
arg4 EQU 20

symbol_width EQU 10
symbol_height EQU 20
include digits.inc
include letters.inc
include Wpieces.inc
include Bpieces.inc

include board.asm
include fen.asm
include game.asm

.code
	
; procedura make_text afiseaza o piesa de sah sau o cifra la coordonatele date
; arg1 - simbolul de afisat (litera sau cifra)
; arg2 - pointer la vectorul de pixeli
; arg3 - pos_x
; arg4 - pos_y
make_text proc
	push ebp
	mov ebp, esp
	pusha
	
	mov eax, [ebp+arg1] ; citim simbolul de afisat
	
	;;se afiseaza highlight pe campul selectat
	cmp eax, 'H'
	jne no_highlight
	jmp leave_print_on_table
no_highlight:
	
	;;verificam daca simbolul este o cifra
	cmp eax, '0'
	jl not_a_digit
	cmp eax, '9'
	jg not_a_digit
	sub eax, '0'
	lea esi, digits
	jmp draw_text
not_a_digit:
	;;verificam daca simbolul este o piesa alba
	cmp eax, 'A'
	jl not_white
	cmp eax, 'Z'
	jg not_white
	sub eax, 'A'
	lea esi, Wpieces
	jmp draw_text
not_white:
	;;verificam daca simbolul este o piesa neagra
	cmp eax, 'a'
	jl not_black
	cmp eax, 'z'
	jg not_black
	sub eax, 'a'
	lea esi, Bpieces
	jmp draw_text
not_black:	
	;;atuci afiseaza spatiu
	mov eax, 26 ; de la 0 pana la 25 sunt litere, 26 e space
	lea esi, letters
	
draw_text:
	mov ebx, symbol_width
	mul ebx
	mov ebx, symbol_height
	mul ebx
	add esi, eax
	mov ecx, symbol_height
bucla_simbol_linii:
	mov edi, [ebp+arg2] ; pointer la matricea de pixeli
	mov eax, [ebp+arg4] ; pointer la coord y
	add eax, symbol_height
	sub eax, ecx
	mov ebx, area_width
	mul ebx
	add eax, [ebp+arg3] ; pointer la coord x
	shl eax, 2 ; inmultim cu 4, avem un DWORD per pixel
	add edi, eax
	push ecx
	mov ecx, symbol_width
bucla_simbol_coloane:
	;;daca e 0 nu afiasa
	cmp byte ptr [esi], 0
	je simbol_pixel_next
	;;daca e 2 afiseaza alb
	cmp byte ptr [esi], 2
	je simbol_pixel_alb
	;;altfel afiseaza negru
	mov dword ptr [edi], 0
	jmp simbol_pixel_next
simbol_pixel_alb:
	mov dword ptr [edi], 0FFFFFFh
simbol_pixel_next:
	inc esi
	add edi, 4
	loop bucla_simbol_coloane
	pop ecx
    loop bucla_simbol_linii
leave_print_on_table:
	popa
	mov esp, ebp
	pop ebp
	ret
make_text endp


; un macro ca sa apelam mai usor desenarea simbolului
make_text_macro macro symbol, drawArea, x, y
	push y
	push x
	push drawArea
	push symbol
	call make_text
	add esp, 16
endm

; functia de desenare - se apeleaza la fiecare click
; sau la fiecare interval de 200ms in care nu s-a dat click
; arg1 - evt (0 - initializare, 1 - click, 2 - s-a scurs intervalul fara click)
; arg2 - x
; arg3 - y

afis macro x, f ;;printf("%s", x)
	push x
	push offset f
	call printf
	add ESP, 8
endm

bpawnvalid macro
local twoahead, captura, wright, invalid, wvalid, pawnend
	pusha
	mov EAX, stage1x
	mov EBX, stage1y
	
	mov ECX, 0
	mov CL, table[EAX+EBX]
	cmp ECX, ' '
	jne captura
	mov ECX, stage0x
	mov EDI, stage0y
	
	sub ECX, 8
	;;una in fata
	cmp ECX, EAX
	jne twoahead
	cmp EBX, EDI
	jne twoahead
	jmp wvalid
twoahead:
	cmp stage0x, 48

	jne invalid
	mov DL, table[ECX+EDI]
	cmp EDX, ' '
	jne invalid
	sub ECX, 8
	cmp ECX, EAX
	jne invalid
	cmp EBX, EDI
	jne invalid
	jmp wvalid
captura:
	mov ECX, stage0x
	mov EDI, stage0y	
	;;pe stanga
	sub ECX, 8
	dec EDI
	cmp ECX, EAX
	jne wright
	cmp EBX, EDI
	jne wright
	jmp wvalid
	;;pe dreapta
wright:
	inc EDI
	inc EDI
	cmp ECX, EAX
	jne invalid
	cmp EBX, EDI
	jne invalid
	jmp wvalid
	
invalid:
	mov valid,0
	jmp pawnend
wvalid:
	mov hmc_uni, 0
	mov hmc_zeci, 0
	mov valid, 1
	mov ECX, stage0x
	mov EDI, stage0y 
	cmp stage1x, 0
	jne pawnend
	mov table[ECX+EDI], 'q'
pawnend:	
	popa
endm

wpawnvalid macro
local twoahead, captura, wright, invalid, wvalid, pawnend
	pusha
	mov EAX, stage1x
	mov EBX, stage1y
	
	mov ECX, 0
	mov CL, table[EAX+EBX]
	cmp ECX, ' '
	jne captura
	mov ECX, stage0x
	mov EDI, stage0y
	
	add ECX, 8
	;;una in fata
	cmp ECX, EAX
	jne twoahead
	cmp EBX, EDI
	jne twoahead
	jmp wvalid
twoahead:
	cmp stage0x, 8

	jne invalid
	mov DL, table[ECX+EDI]
	cmp EDX, ' '
	jne invalid
	add ECX, 8
	cmp ECX, EAX
	jne invalid
	cmp EBX, EDI
	jne invalid
	jmp wvalid
captura:
	mov ECX, stage0x
	mov EDI, stage0y	
	;;pe stanga
	add ECX, 8
	dec EDI
	cmp ECX, EAX
	jne wright
	cmp EBX, EDI
	jne wright
	jmp wvalid
	;;pe dreapta
wright:
	inc EDI
	inc EDI
	cmp ECX, EAX
	jne invalid
	cmp EBX, EDI
	jne invalid
	jmp wvalid
	
invalid:
	mov valid,0
	jmp pawnend
wvalid:
	mov hmc_uni, 0
	mov hmc_zeci, 0
	mov valid, 1
	mov ECX, stage0x
	mov EDI, stage0y 
	cmp stage1x, 56
	jne pawnend
	mov table[ECX+EDI], 'Q'
pawnend:	
	popa
endm


draw proc
	push ebp
	mov ebp, esp
	pusha
	
	mov eax, [ebp+arg1]
	cmp eax, 1
	jz evt_click
	cmp eax, 2
	jz evt_timer ; nu s-a efectuat click pe nimic
	;mai jos e codul care intializeaza fereastra cu pixeli albi
	mov eax, area_width
	mov ebx, area_height
	mul ebx
	shl eax, 2
	push eax
	push 255
	push area
	call memset
	add esp, 12
	
	;;creeaza tabla de joc
	
	;make_square 10, 100, white_square
	;;campuri
	make_table table_start_x, table_start_y, board_color, 4
	;;litere pe marginea tablei
	make_table_text table_start_x, table_start_y
	;;citeste fen.txt in fen
	readfen
	afis offset fen, format
	;;decodeaza fen si pune piesele in table
	decodefen

	; mov EAX, 0
	; mov AL, tomove
	; afis EAX, format_c
	; mov AL, WK
	; afis EAX, format_d
	; mov AL, WQ
	; afis EAX, format_d
	; mov AL, BK
	; afis EAX, format_d
	; mov AL, BQ
	; afis EAX, format_d
	; mov AL, en_i
	; afis EAX, format_d
	; mov AL, en_j
	; afis EAX, format_d
	; mov AL, hmc_zeci
	; afis EAX, format_d
	; mov AL, hmc_uni
	; afis EAX, format_d

	;afis offset table, format
	
	;;afiseaza piese din table pe ecran
	printpieces
	
	mov move_stage, 0
	
	jmp afisare_litere
	
evt_click:

	mov EAX, nr_of_squares
	mov ECX, board_square_l
	mul ECX
	mov ECX, EAX
	mov EAX, [EBP+arg2]
	mov EBX, [EBP+arg3]
	sub EAX, table_start_x
	sub EBX, table_start_y
	cmp EAX, 0
	jl deselect
	cmp EAX, ECX
	jg deselect
	cmp EBX, 0
	jl deselect
	cmp EBX, ECX
	jg deselect
	
	mov EDX, 0
	mov ECX, board_square_l
	div ECX
	mov j, EAX
	
	mov EDX, 0
	mov EAX, EBX
	mov ECX, board_square_l
	div ECX
	mov i, EAX
	
	mov EAX, board_square_l
	mul i
	mov y, table_start_y
	add y, EAX
	
	mov EAX, board_square_l
	mul j
	mov x, table_start_x
	add x, EAX

	mov eax, x
	mov ebx, y
	mov w, ebx
	mov t, eax
	
	mov EAX, 7
	sub EAX, i
	mov i, EAX
	mov EAX, j
	
	mov EAX, nr_of_squares
	mul i
	mov EBX, j
	mov ECX, 0
	mov CL, table[EAX+EBX]
	cmp tomove, 'w'
	jne negru_la_mutare
	
	;;move_stage == 0 // se selecteaza o piesa a jucatorului tomove
	cmp move_stage, 1
	je camp_sau_piesa_inamica
	cmp ECX, 'A'
	jl deselect
	cmp ECX, 'Z'
	jg deselect
	mov stage0x, EAX
	mov stage0y, EBX
	mov move_stage, 1
	jmp skip_if
	;; se selecteza campul catre care se va deplasa piesa
camp_sau_piesa_inamica:

	cmp ECX, 'A'
	jl skipif
	cmp ECX, 'Z'
	jg skipif
	jmp deselect
skipif:	
	mov valid, 1
	mov stage1x, EAX
	mov stage1y, EBX
	
	mov EAX, stage0x
	mov EBX, stage0y

	mov ECX, 0
	mov CL, table[EAX+EBX]

	cmp ECX, 'P'
	jne not_wpawn
	wpawnvalid
	;mov valid, 1
	jmp validareW
not_wpawn:
	cmp ECX, 'N'
	jne not_wknight
	mov valid, 1
	
	jmp validareW
not_wknight:
	cmp ECX, 'B'
	jne not_wbishop
	mov valid, 1
	
	jmp validareW
not_wbishop:
	cmp ECX, 'Q'
	jne not_wqueen
	mov valid, 1
	
	jmp validareW
not_wqueen:
	cmp ECX, 'K'
	jne not_wking
	wkingvalid
	;mov valid, 1
	
	jmp validareW
not_wking:
validareW:
	cmp valid, 0
	je deselect
	mov EAX, stage1x
	mov EBX, stage1y
	mov ECX, stage0x
	mov EDI, stage0y 
	mov DL, table[ECX+EDI]
	mov table[EAX+EBX], DL
	mov DL, ' '
	mov table[ECX+EDI], DL
	mov tomove, 'b'
	mov move_stage, 0
	mov update, 1
	jmp deselect
negru_la_mutare:

	;;move_stage == 0 // se selecteaza o piesa a jucatorului tomove
	cmp move_stage, 1
	je camp_sau_piesa_inamica2
	cmp ECX, 'a'
	jl deselect
	cmp ECX, 'z'
	jg deselect
	mov stage0x, EAX
	mov stage0y, EBX
	mov move_stage, 1
	jmp skip_if
camp_sau_piesa_inamica2:
	
	cmp ECX, 'a'
	jl skipif2
	cmp ECX, 'z'
	jg skipif2
	jmp deselect
skipif2:
	mov valid, 1
	mov stage1x, EAX
	mov stage1y, EBX
	
	mov EAX, stage0x
	mov EBX, stage0y

	mov ECX, 0
	mov CL, table[EAX+EBX]

	
	
	cmp ECX, 'p'
	jne not_bpawn
	bpawnvalid
	;mov valid, 1
	jmp validareB
not_bpawn:
	cmp ECX, 'n'
	jne not_bknight
	mov valid, 1
	
	jmp validareB
not_bknight:
	cmp ECX, 'b'
	jne not_bbishop
	mov valid, 1
	
	jmp validareB
not_bbishop:
	cmp ECX, 'q'
	jne not_bqueen
	mov valid, 1
	
	jmp validareB
not_bqueen:
	cmp ECX, 'k'
	jne not_bking
	;afis offset debug_msg, format
	bkingvalid
	;mov valid, 1
	
	jmp validareB
not_bking:
validareB:	
	cmp valid, 0
	je deselect
	mov EAX, stage1x
	mov EBX, stage1y
	mov ECX, stage0x
	mov EDI, stage0y 
	mov DL, table[ECX+EDI]
	mov table[EAX+EBX], DL
	mov DL, ' '
	mov table[ECX+EDI], DL
	mov tomove, 'w'
	mov move_stage, 0
	mov update, 1
	jmp deselect
skip_if:

	;afis offset table, format
	make_highlight x, y, 0bd454h
	jmp dont_deselect
deselect:
	make_table table_start_x, table_start_y, board_color, 4
	push x
	push y
	printpieces
	pop y
	pop x
	mov move_stage, 0
	cmp update, 0
	je dont_deselect
	make_highlight x, y, 0bd454h
	mov update, 0
dont_deselect:
	
	jmp afisare_litere
evt_timer:
	inc counter

	
afisare_litere:
	;afisam valoarea counter-ului curent (sute, zeci si unitati)
	mov ebx, 10
	mov eax, counter
	;cifra unitatilor
	mov edx, 0
	div ebx
	add edx, '0'
	make_text_macro edx, area, 30, 30
	;cifra zecilor
	mov edx, 0
	div ebx
	add edx, '0'
	make_text_macro edx, area, 20, 30
	;cifra sutelor
	mov edx, 0
	div ebx
	add edx, '0'
	make_text_macro edx, area, 10, 30
	
	;scriem un mesaj
	make_text_macro 'p', area, 10, 10
	make_text_macro 'r', area, 20, 10
	make_text_macro 'o', area, 30, 10
	make_text_macro 'i', area, 40, 10
	make_text_macro 'e', area, 50, 10
	make_text_macro 'c', area, 60, 10
	make_text_macro 't', area, 70, 10
	make_text_macro 'p', area, 90, 10
	make_text_macro 'l', area, 100, 10
	make_text_macro 'a', area, 110, 10
	

final_draw:
	popa
	mov esp, ebp
	pop ebp
	ret
draw endp

start:
	;alocam memorie pentru zona de desenat
	mov eax, area_width
	mov ebx, area_height
	mul ebx
	shl eax, 2
	push eax
	call malloc
	add esp, 4
	mov area, eax
	;apelam functia de desenare a ferestrei
	; typedef void (*DrawFunc)(int evt, int x, int y);
	; void __cdecl BeginDrawing(const char *title, int width, int height, unsigned int *area, DrawFunc draw);
	push offset draw
	push area
	push area_height
	push area_width
	push offset window_title
	call BeginDrawing
	add esp, 20
	
	;terminarea programului
	push 0
	call exit
end start
