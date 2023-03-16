decodefen macro
local verticala, orizontala, piece, exit_if, w_no_kingside, w_no_queensideside
local b_no_kingside, b_no_queensided, fara_rocadem, no_enpassant, skip_enp
local XX, skip_XX
	;;init tabla
	mov ECX, 63
init_table:
	mov table[ECX], ' '
	loop init_table
	mov table+0, ' '
	mov table+64, 0
	;afis offset table, format
	;;pune piese in table
	mov EBX, 0
	mov ECX, 0
	mov i, 7
	
verticala:
	mov EDX, 0
orizontala:

	cmp fen[ECX], '9' ;;verificam daca pe pozitia curenta din fen e o piesa
	jg piece
	;;daca nu e piesa sarim peste fen[ECX] campuri
	mov EBX, 0
	mov BL, fen[ECX]
	inc ECX
	sub EBX, '0'
	add EDX, EBX
	jmp exit_if
piece:	
	;;table[i][j] = x // table [i*8+j] = x
	mov EAX, nr_of_squares
	push EDX
	mul i
	pop EDX
	add EAX, EDX
	mov EBX, 0
	mov BL, fen[ECX]
	mov table[EAX], BL
	inc EDX
	inc ECX
exit_if:

	cmp EDX, 8
	jl orizontala
	
	inc ECX
	
	dec i
	cmp i, 0
	jge verticala
	
	;;cine muta
	mov EAX, 0
	mov AL, fen[ECX]
	mov tomove, AL
	inc ECX
	;;posibilitate de rocada
	mov WK, 0
	mov WQ, 0
	mov BK, 0
	mov BQ, 0
	inc ECX
	mov AL, fen[ECX]
	cmp AL, '-'
	je fara_rocade
	cmp AL, 'K'
	jne w_no_kingside
	mov WK, 1
	inc ECX
	mov AL, fen[ECX]
w_no_kingside:
	cmp AL, 'Q'
	jne w_no_queenside
	mov WQ, 1
	inc ECX
	mov AL, fen[ECX]
w_no_queenside:
	cmp AL, 'k'
	jne w_no_kingside
	mov BK, 1
	inc ECX
	mov AL, fen[ECX]
b_no_kingside:
	cmp AL, 'q'
	jne b_no_queenside
	mov BQ, 1
	inc ECX
	mov AL, fen[ECX]
b_no_queenside:
	
fara_rocade:
	inc ECX
	mov AL, fen[ECX]
	;;en passant
	cmp AL, '-'
	je no_enpassant
	sub AL, 'a'
	mov en_j, AL	
	inc ECX
	mov AL, fen[ECX]
	sub EAX, '0'
	mov en_i, AL
	jmp skip_enp
no_enpassant:	
	mov en_i, '9'
	mov en_j, '9'
skip_enp:
inc ECX
	;;halfmove clock (numar de la 0 la 50)
	inc ECX
	mov AL, fen[ECX]
	inc ECX
	mov BL, fen[ECX]

	cmp BL, ' '
	jne XX
	;;else 0X
	mov hmc_zeci, 0
	sub EAX, '0'
	mov hmc_uni, AL
	jmp skip_XX
XX:
	sub AL, '0'
	sub BL, '0'
	mov hmc_uni, BL
	mov hmc_zeci, AL
skip_XX:
	;;fullmove clock
endm