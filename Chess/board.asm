;;creeaza un patrat de culoare color la x, y
make_square macro x, y, color
local verticala, orizontala
	mov EAX, y
	mov EBX, area_width
	mul EBX
	add EAX, x 
	shl EAX, 2
	add EAX, area
	
	mov ECX, board_square_l
verticala:
	
	push ECX
	
	mov ECX, board_square_l	
orizontala:
	mov EDX, color
	mov dword ptr [EAX], EDX
	add EAX, 4
	loop orizontala
	sub EAX, board_square_l * 4
	
	pop ECX
	add EAX, area_width * 4
	loop verticala
endm

;;pune o rama de culoare color la x, y
make_highlight macro x, y, color
local verticala, orizontala, coloreaza, nu_colora
	push x
	push y
	mov EAX, y
	mov EBX, area_width
	mul EBX
	add EAX, x 
	shl EAX, 2
	add EAX, area
	
	mov EDI, board_square_l
	sub EDI, 1
	mov ECX, board_square_l
verticala:
	
	push ECX
	
	mov EBX, ECX
	mov ECX, board_square_l	
orizontala:
	mov EDX, color
	
	cmp ECX, 2
	jle coloreaza
	cmp EBX, 2
	jle coloreaza
	cmp ECX, EDI
	jge coloreaza
	cmp EBX, EDI
	jge coloreaza
	jmp nu_colora
coloreaza:
	mov dword ptr [EAX], EDX
nu_colora:	
	add EAX, 4
	loop orizontala
	
	sub EAX, board_square_l * 4
	pop ECX
	add EAX, area_width * 4
	loop verticala
	pop y
	pop x
endm

;;schimba culoarea alb->negru || negru->alb
swap_color macro
local urmeaza_negru, skip
	cmp dword ptr [EBP-16], 4
	je urmeaza_negru
	mov dword ptr [EBP-16], 4
	mov EAX, dword ptr [EBP-16]
	mov EDX, board_color
	mov dword ptr [EBP-12], EDX
	jmp skip
urmeaza_negru:
	mov dword ptr [EBP-16], 0
	mov EAX, dword ptr [EBP-16]
	mov EDX, [board_color+4]
	mov dword ptr [EBP-12], EDX
skip:
endm

;;creeaza o tabla la coordonatele x, y
make_table macro x, y, culoare_init, indicator_culoare
local verticala, orizontala
	push EBP
	mov EBP, ESP
    sub ESP, 16

	;;[EBP-4] == x
	;;[EBP-8] == y
	;;[EBP-12] == culoare
	;;[EBP-16] == 4 daca ultimul patrat a fost alb, 0 daca negru
	;;[EBP-12] += [EBP-16] * 4 determina urmatoarea culoare
	
	mov dword ptr [EBP-8], y
	mov EAX, culoare_init
	mov dword ptr [EBP-12], EAX
	mov dword ptr [EBP-16], indicator_culoare
	;add dword ptr [EBP-12], -4
	
	mov ECX, nr_of_squares
verticala: 
	push ECX
	mov ECX, nr_of_squares
	mov dword ptr [EBP-4], x
orizontala:
	push ECX
	make_square dword ptr [EBP-4], dword ptr[EBP-8], dword ptr [EBP-12]
	pop ECX
	
	swap_color
	
	add dword ptr [EBP-4], board_square_l
	loop orizontala
	pop ECX
	
	swap_color
	
	add dword ptr[EBP-8], board_square_l
	dec ECX
	jnz verticala
	
	mov ESP, EBP
	pop EBP
endm


;;afiseaza pe marginea tablei A-H, 1-8
make_table_text macro x, y
local orizontala, verticala
	mov EDX, 0
	mov EBX, 2
	mov EAX, board_square_l
	sub EAX, symbol_width
	div EBX
	add EAX, x
	
	mov ECX, EAX
	mov EAX, board_square_l
	mov EBX, nr_of_squares
	mul EBX
	mov EBX, EAX
	add EBX, y
	mov EAX, ECX
	
	mov EDX, 'a'
	
	mov ECX, nr_of_squares
verticala:	
	make_text_macro EDX, area, EAX, EBX
	;add EBX, area_width
	;make_text_macro EDX, area, EAX, EBX
	;sub EBX, area_width
	add EAX, board_square_l
	inc EDX
	loop verticala
	
	mov EDX, 0
	mov EBX, 2
	mov EAX, board_square_l
	sub EAX, symbol_height
	div EBX
	mov EBX, EAX
	add EBX, y
	
	mov EAX, board_square_l
	mov EDX, nr_of_squares
	mul EDX
	add EAX, x
	add EAX, 2
	
	mov EDX, '8'
	
	mov ECX, nr_of_squares
orizontala:
	make_text_macro EDX, area, EAX, EBX
	add EBX, board_square_l
	dec EDX
	loop orizontala
endm

readfen macro
	push offset mode_read 
	push offset file_name
	call fopen
	add ESP, 8
	push ESI
	mov ESI, EAX
	
	push EAX
	push offset 99
	push offset fen
	call fgets
	add ESP, 12
	
	push ESI
	call fclose
	pop ESI
	add ESP, 4
endm

printpieces macro
local verticala, orizontala
mov x, table_start_x
	add x, 15
	mov y, table_start_y
	add y, 10

	mov i, 7
verticala:	
	mov j, 0

	mov ECX, x
orizontala:
	mov EAX, nr_of_squares
	mul i
	add EAX, j
	mov EBX, 0
	mov BL, table[EAX]
	; pusha
	; afis EBX, format_c
	; popa
	make_text_macro EBX, area, x, y
	add x, board_square_l
	
	inc j
	cmp j, 8
	jl orizontala
	mov x, ECX
	add y, board_square_l	
	
	dec i
	cmp i, 0
	jge verticala
endm