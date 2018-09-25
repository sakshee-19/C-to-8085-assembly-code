	MOV A, #3
	CMP A, #7
	JC btrue1
	JNZ bfalse1

	btrue1:
	LD #10
	ST $110

	JMP if1

	bfalse1:
	LD #10
	ST $111

if1	NOP

return	.end
