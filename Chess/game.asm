wkingvalid macro
local noKc, nocastle, rocada, kingend
	pusha
	cmp stage1x, 0
	jne nocastle
	cmp stage1y, 6
	jne noKc
	cmp WK, 1
	jne noKc
	cmp table[5], ' '
	jne noKc
	cmp table[5], ' '
	jne noKc
	mov table[6], 'K'
	mov table[5], 'R'
	mov table[7], ' '
	jmp rocada
noKc:
	cmp stage1y, 2
	jne nocastle
	cmp WQ, 1
	jne nocastle
	cmp table[1], ' '
	jne noKc
	cmp table[2], ' '
	jne noKc
	cmp table[3], ' '
	jne noKc
	mov table[2], 'K'
	mov table[3], 'R'
	mov table[0], ' '
	jmp rocada
nocastle:
	mov valid, 1
	jmp kingend
rocada:
	mov valid, 1
kingend:
	mov WK, 0
	mov WQ, 0
	popa
endm

bkingvalid macro
local noKc, nocastle, rocada, kingend
	pusha
	cmp stage1x, 56
	jne nocastle
	cmp stage1y, 6
	jne noKc
	cmp BK, 1
	jne noKc

	cmp table[61], ' '
	jne noKc
	cmp table[62], ' '
	jne noKc
	mov table[62], 'k'
	mov table[61], 'r'
	mov table[63], ' '
	jmp rocada
noKc:
	cmp stage1y, 2
	jne nocastle
	cmp BQ, 1
	jne nocastle
	cmp table[57], ' '
	jne noKc
	cmp table[58], ' '
	jne noKc
	cmp table[59], ' '
	jne noKc
	mov table[58], 'k'
	mov table[59], 'r'
	mov table[56], ' '
	jmp rocada
nocastle:
	mov valid, 1
	jmp kingend
rocada:
	mov valid, 1
kingend:
	mov BK, 0
	mov BQ, 0
	popa
endm