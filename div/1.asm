; Listing generated by Microsoft (R) Optimizing Compiler Version 19.27.29111.0 

include listing.inc

INCLUDELIB MSVCRT
INCLUDELIB OLDNAMES

PUBLIC	f
PUBLIC	f1
PUBLIC	f2
; Function compile flags: /Ogtpy
_TEXT	SEGMENT
a$ = 8
f2	PROC
; File C:\Users\82595\Documents\GitHub\Disassembly\div\main.c
; Line 8
	mov	eax, ecx
	cdq
	and	edx, 15
	add	eax, edx
	sar	eax, 4
	ret	0
f2	ENDP
_TEXT	ENDS
; Function compile flags: /Ogtpy
_TEXT	SEGMENT
a$ = 8
f1	PROC
; File C:\Users\82595\Documents\GitHub\Disassembly\div\main.c
; Line 5
	mov	eax, ecx
	cdq
	and	edx, 3
	add	eax, edx
	sar	eax, 2
	ret	0
f1	ENDP
_TEXT	ENDS
; Function compile flags: /Ogtpy
_TEXT	SEGMENT
a$ = 8
f	PROC
; File C:\Users\82595\Documents\GitHub\Disassembly\div\main.c
; Line 2
	mov	eax, 1431655766				; 55555556H
	imul	ecx
	mov	eax, edx
	shr	eax, 31
	add	eax, edx
	ret	0
f	ENDP
_TEXT	ENDS
END
