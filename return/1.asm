; Listing generated by Microsoft (R) Optimizing Compiler Version 16.00.30319.01 

	TITLE	C:\Disassembly\return\struct.c
	.686P
	.XMM
	include listing.inc
	.model	flat

INCLUDELIB LIBCMT
INCLUDELIB OLDNAMES

PUBLIC	__$ArrayPad$
PUBLIC	_get_some_values
EXTRN	___security_cookie:DWORD
EXTRN	@__security_check_cookie@4:PROC
; Function compile flags: /Odtp
_TEXT	SEGMENT
_rt$ = -16						; size = 12
__$ArrayPad$ = -4					; size = 4
$T3895 = 8						; size = 4
_a$ = 12						; size = 4
_get_some_values PROC
; File c:\disassembly\return\struct.c
; Line 12
	push	ebp
	mov	ebp, esp
	sub	esp, 16					; 00000010H
	mov	eax, DWORD PTR ___security_cookie
	xor	eax, ebp
	mov	DWORD PTR __$ArrayPad$[ebp], eax
; Line 14
	mov	eax, DWORD PTR _a$[ebp]
	add	eax, 1
	mov	DWORD PTR _rt$[ebp], eax
; Line 15
	mov	ecx, DWORD PTR _a$[ebp]
	add	ecx, 2
	mov	DWORD PTR _rt$[ebp+4], ecx
; Line 16
	mov	edx, DWORD PTR _a$[ebp]
	add	edx, 3
	mov	DWORD PTR _rt$[ebp+8], edx
; Line 17
	mov	eax, DWORD PTR $T3895[ebp]
	mov	ecx, DWORD PTR _rt$[ebp]
	mov	DWORD PTR [eax], ecx
	mov	edx, DWORD PTR _rt$[ebp+4]
	mov	DWORD PTR [eax+4], edx
	mov	ecx, DWORD PTR _rt$[ebp+8]
	mov	DWORD PTR [eax+8], ecx
	mov	eax, DWORD PTR $T3895[ebp]
; Line 18
	mov	ecx, DWORD PTR __$ArrayPad$[ebp]
	xor	ecx, ebp
	call	@__security_check_cookie@4
	mov	esp, ebp
	pop	ebp
	ret	0
_get_some_values ENDP
_TEXT	ENDS
END
