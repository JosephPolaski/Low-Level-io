; Title: Low level I/O Procedures
; Author: Joseph Polaski
; Description:This program will read in 10 decimal signed 32-bit integers as strings. It then converts them to a their signed numeric form
;	      and then caluculates their sum and average rounded to the nearest whole number. These numbers are then converted back to 
;	      string and displayed to the user. Macros are used to display output to users. All variables both integer and string are
;	      processed on the stack.

INCLUDE Irvine32.inc

; CONSTANTS
;***********************************
NUM_AMOUNT = 10

; MACROS
;***********************************

;****************************************************
;	getString	MACRO
;
;	Reads in a user string
;****************************************************
getString MACRO user_num, user_prompt, num_size
	
	; Preserve registers that will be altered by macro
	push	ecx
	push	edx

	; print user prompt to console
	mov		edx, user_prompt
	call	WriteString

	; read in user provided number
	mov		edx, user_num
	mov		ecx, num_size
	call	ReadString

	; restore registers
	pop		edx
	pop		ecx

ENDM

;****************************************************
;	displayString	MACRO
;
;	displays a prompt and user number
;****************************************************
displayString MACRO num_to_string, num_prompt
	
			; Preserve registers that will be altered by macro
			push	eax
			push	ecx
			push	edx

			; print user prompt to console
			mov		edx, num_prompt
			call	WriteString
			mov		al, " "
			call	WriteChar

			; read in user provided number
			mov		edx, num_to_string
			call	WriteString		
			mov		al, " "
			call	WriteChar

			; restore registers
			pop		edx
			pop		ecx
			pop		eax

ENDM

.data

;STRINGS
;************************************
intro_1				BYTE "Low Level I/O procedures", 0																; intro message 1
intro_2				BYTE "Written by: Joe Polaski", 0																; intro message 2
intro_3				BYTE "Please enter 10 signed integers that will fit within a 32 bit register.", 0				; intro message 3
intro_4				BYTE "In return, I will display a list of the integers along with thier sum and average!", 0
userNumString		BYTE 11	DUP(0)																					; Holds 32-bit signed integer
finalString			BYTE 11 DUP(0)																					; used in converting back to string accounts for 10 possible integers bytes and one sign character.
getStringPrompt		BYTE "Please enter a signed decimal Number: ", 0												; prompt for getString
invalidMsg			BYTE "Your number was too big or it wasn't signed. Try Again!", 0								; invalid number message
testMessage			BYTE "The current user number array is: ", 0													; test procedure prompt
finalNums			BYTE "The numbers you entered are: ", 0															; final number list caption
avgMsg				BYTE "The Rounded Average is:", 0																; rounded average caption
blnkMsg				BYTE " ",0																						; blank placeholder message
sumMsg				BYTE "The Sum of these numbers is:", 0															; sum message


;INTEGERS
;***********************************
userNumArray		SDWORD 10 DUP(0)																				; array to hold 10 user numbers
numSum				SDWORD	?																						; holds the sum of the numbers
roundedAvg			SDWORD	?																						; holds the rounded integer average


.code
main PROC

;***********************************
;		Introduction			
;***********************************
; push arguments to stack
push	OFFSET intro_1
push	OFFSET intro_2
push	OFFSET intro_3
push	OFFSET intro_4

call	Introduction

;***********************************
;		Get User Numbers
;		and Convert to Signed int
;***********************************
; push arguments to stack
push	OFFSET invalidMsg
push	SIZEOF userNumString
push	OFFSET getStringPrompt
push	OFFSET userNumArray
push	OFFSET userNumString
push	NUM_AMOUNT

call	readVal

;***********************************
;		Convert Numbers Back to
;		String and Display Values.
;***********************************
; push arguments to stack
push	OFFSET blnkMsg
push	OFFSET finalString
push	OFFSET userNumArray
push	NUM_AMOUNT
push	OFFSET userNumString	
push	OFFSET avgMsg
push	OFFSET sumMsg
push	OFFSET finalNums

call	WriteVal

	exit	; exit to operating system
main ENDP

;**********************************************************************************************************
;	Introduction Procedure
;
;	recieves: OFFSETS of intro_1, intro_2, intro_3,
;			  intro_1
;	returns: None
;	preconditions: OFFSETs must be pushed to stack
;	registers changed: edx
;	description: prints introduction to user
;**********************************************************************************************************
Introduction	PROC
		enter 0,0						; setup stack frame and base pointer

		
		mov		edx, [ebp + 20]				; print introduction				
		call	WriteString
		call	CrLf
		call	CrLf
		mov		edx, [ebp + 16]
		call	WriteString
		call	CrLf
		call	CrLf
		mov		edx, [ebp + 12]
		call	WriteString
		call	CrLf
		mov		edx, [ebp + 8]
		call	WriteString
		call	CrLf
		call	CrLf

		leave							; terminate stack frame
		ret 16							; clean up stack
Introduction	ENDP

;**********************************************************************************************************
;	readVal Procedure
;  
;	recieves: OFFSET getStringPrompt, OFFSET userNumArray,
;			  SIZEOF userNumString, OFFSET userNumString, 
;			  NUM_AMOUNT
;	returns: userNumArray
;	preconditions: parameters listed must be recieved
;	registers changed: esi, edi, ecx, edx
;	description: retrieves 10 numbers from the user.
;				 uses getString macro. Stores numbers
;				 in array.
;**********************************************************************************************************
readVal	PROC
		pushad							; store general purpose registers
		mov		ebp, esp

		xor		edi, edi				; clear registers to avoid data corruption
		xor		ecx, ecx
		xor		edx, edx

		; parameters
		mov		eax, [ebp + 52]				; SIZEOF userNumString
		mov		ebx, [ebp + 48]				; OFFSET getStringPrompt

		; set array pointers
		mov		esi, [ebp + 40]				; set esi to OFFSET userNumString
		mov		edi, [ebp + 44]				; set edi to OFFSET userNumArray

		mov		ecx, [ebp + 36]				; set loop counter to 10 (NUM_AMOUNT)

		; declare and initialize local variables
		sub		esp, 8									
		mov		DWORD PTR [ebp - 4], 0			; (Invalid Flag) initialize local variable to 0
		mov		SDWORD PTR [ebp - 8], 0			; (Converted number) initialize local variable to 0


GET:									; get numbers top of loop		
		getString	esi, ebx, eax				; invoke macro
		call		CrLf
		
		; convert string to decimal
		push	esi						; string entered by user
		push	eax						; number of characters typed by user

		call	convertStringToDec

		; Check if number was invalid
		mov		eax, DWORD PTR [ebp - 4]		; Invalid Flag (returned from convertStringToDec)
		cmp		eax, 1
		je		NV					; True: jump too not valid

		; False: Store number to array
		mov		eax, SDWORD PTR [ebp - 8]
		mov		[edi], eax				; insert number into index
		add		edi, 4					; point edi to next index
		jmp		NEXT					; jump to loop

NV:		; number not valid
		mov		edx, [ebp + 56]				; fetch and print invalid number message
		call	WriteString
		call	CrLf
		call	CrLf
		inc		ecx					; increment ecx so try is not counted

NEXT:													
		mov		eax, 0
		mov		[esi], eax				; reset userNumString
		mov		eax, [ebp + 52]				; reset eax to SIZEOF userNumString
	
		loop	GET

		mov		esp, ebp				; remove local variables
		popad							; restore general purpose registers
		ret 24							; clean up stack
readVal	ENDP

;**********************************************************************************************************
;	convertStringToDec Sub - Procedure
;  
;	recieves: OFFSET userNumString, count of chars
;			  in userNumString
;			  
;	returns: returns converted number and valid flag
;			 to local variables in readVal PROC
;	preconditions: parameters listed must be recieved
;	registers changed: esi, edx, eax, edi, ebx, ecx 
;	description: validates user numbers before they
;				 are allowed to be cast into the 
;				 userNumArray. Converts String to Int
;***********************************************************************************************************
convertStringToDec	PROC
		pushad
		mov		ebp, esp

		mov		esi, [ebp + 40]				; OFFSET userNumString 
		mov		ecx, [ebp + 36]				; count of characters in userNumString

		mov		ebx, 0					; secondary index counter

		; declare and initialize local variables
		sub		esp, 12									
		mov		DWORD PTR [ebp - 4], 0			; CUSTOM SIGN FLAG: negative = 1, positive = 0, used to determine if original number was negative
		mov		SDWORD PTR [ebp - 8], 0			; Power of Ten returned from calcPowerOfTen
		mov		SDWORD PTR [ebp - 12], 0		; ACCUMULATOR: used to add all place values together, initialize local variable to 0

		cld							; clear direction flag
string:									; iterate through string
		xor		eax, eax
		lodsb							; load contents contents of esi to eax

		; IF ebx == 0 (first iteration)
		cmp		ebx, 0
		jne		NFI					; FALSE: jump to not first index		
									; TRUE: check for sign character or number

		; IF eax  == '-'					; check for negative symbol
		cmp		eax, 2Dh
		jne		PCH					; FALSE: check for positive sign		
									; TRUE: set custom sign flag = 1
		mov		DWORD PTR [ebp - 4], 1
		jmp		next					; jump to next

PCH:	; IF eax  == '+'
		cmp		eax, 2Bh
		jne		INVLD					; FALSE: jump to Invalid
									; TRUE: set custom sign flag = 0
		mov		DWORD PTR [ebp - 4], 0
		jmp		next					; jump to next

NFI:									; not first index

		; IF 30h <= eax (ascii hex value for digit 0)
		cmp		eax, 30h
		jl		INVLD					; FALSE number is not a numerical digit, jump to invalid flag

		; ELSE IF eax <= 39h (ascii hex value for digit 9)
		cmp		eax, 39h
		jg		INVLD					; FALSE: number is not a numerical digit, jump to invalid
		
		; TRUE: character is valid convert and accumulate
		sub		eax, 30h				; subtract 30h to produce decimal digit
		
		; caluculate power of 10 to multiply by.
		; this will be used to established the proper
		; place for the digit.
		mov		edx, ecx				; copy index (number place)
		sub		edx, 2					; subtract 2 to adjust number of multiplications of 10 by itself		
		push	edx

		call	calcPowerOfTen					; return value stored in [ebp - 8]

		mov		edx, [ebp - 8]				; fetch power of 10
		imul	edx						; multiply by digit to get place value		
		
		add		DWORD PTR [ebp - 12], eax		; add to total in [ebp - 12]		
		jmp		next					; jump to process next number

INVLD:									; INVALID entry
		mov		SDWORD PTR [ebp + 44], 0		; return 0 to parent procedure local variable
		mov		DWORD PTR [ebp + 48], 1			; return invalid flag = 1 to parent procedure local variable
		jmp		FIN					; jump out of loop to finish

next:									; loop to next number
		inc		ebx
		loop	string
		jmp		DN					; jump to done protocol

NG:									; negate number if sign flag is set
		mov		eax, SDWORD PTR [ebp-12]		; retrieve total number		
		neg		eax
		mov		SDWORD PTR [ebp + 44], eax		; return to local variable of parent procedure
		mov		DWORD PTR [ebp + 48], 0			; return invalid flag = 0 to parent procedure local variable
		jmp		FIN

DN:									; done, store to array
		;check custom sign flag
		mov		eax, [ebp - 4]
		cmp		eax, 1
		je		NG					; jump to negate number number

		mov		eax, SDWORD PTR [ebp-12]
		mov		SDWORD PTR [ebp + 44], eax		; return to local variable of parent procedure		
		mov		DWORD PTR [ebp + 48], 0			; return invalid flag = 0 to parent procedure local variable
FIN:									; Finish

		mov		esp, ebp				; remove local variables
		popad
		ret	8
convertStringToDec	ENDP

;**********************************************************************************************************
;	calcPowerOfTen Sub - Procedure
;  
;	recieves: desired exponent
;			  
;			  
;	returns: returns desired power of ten to
;			 local variable in convertStringToDec
;			 [ebp + 48]
;	preconditions: parameters listed must be recieved
;	registers changed: esi, edx, eax, edi 
;	description: calculates a power of ten to 
;				 multiply with the user number in
;				 order to calculate its proper place.
;**********************************************************************************************************
calcPowerOfTen	PROC
		pushad							; preserve registers
		mov		ebp, esp				; set base pointer

		mov		ecx, [ebp + 36]				; exponent number
		mov		eax, 10
		mov		ebx, 10

		cmp		ecx, -1					; check for power of 0
		je		PZ					; jump to power of zero
		cmp		ecx, 0					; check for power of 1
		je		PW					; jump to power of 1

xloop:									; exponent loop
		imul	ebx
		loop	xloop
		mov		SDWORD PTR [ebp+44], eax		; return to local variable in convertStringToDec
		jmp		DNC					; done calculating power of ten		

PW:		; 1 exponent case
		mov		SDWORD PTR [ebp+44], 10			; pass a value of 10 as return
		jmp		DNC

PZ:		; zero exponent case
		mov		SDWORD PTR [ebp+44], 1			; pass a value of 1 as return

DNC:	; Done Calculating
		popad							; restore registers
		ret 4							; clean up stack
calcPowerOfTen	ENDP

;**********************************************************************************************************
;	writeVal Procedure
;  
;	recieves: OFFSET userNumArray, OFFSET NUM_AMOUNT
;					OFFSET userNumString, OFFSET avgMsg
;                   OFFSET sumMsg, OFFSET finalNums
;	returns: None
;	preconditions: parameters listed must be recieved
;	registers changed: esi, edi, ecx, edx, eax, ebx
;	description: converts numbers back to string
;				 calculates and prints sum, average and 
;				 numbers.
;**********************************************************************************************************
writeVal	PROC
		pushad							; preserve registers
		mov		ebp, esp				; set stack frame and base pointer

		; declare and initialize local variables
		sub		esp, 16					; create two 32-bit local variables
		mov		SDWORD PTR [ebp - 4], 0			; initialize average
		mov		SDWORD PTR [ebp - 8], 0			; initialize sum
		mov		SDWORD PTR [ebp - 12], 0		; initialize sum count
		mov		SDWORD PTR [ebp - 16], 0		; initialize string length counter

		; set pointers
		mov		esi, [ebp + 56]				; set source pointer to offset of userNumArray	

		mov		ecx, [ebp + 52]				; set counter to length of userNumArray

		cld							; clear directional loop

CONL:	; Conversion Loop		
		
		mov		eax, [esi]				; fetch first number
		add		SDWORD PTR [ebp - 8], eax		; add to local sum variable
		add		SDWORD PTR [ebp - 12], 1		; increment sum count


		push	[esi]						; pass number to convert
		push	[ebp + 48]					; push string address

		call	numToString					; call conversion helper

		; reverse backwards string

		push	[ebp + 60]					; OFFSET of finalString
		push	[ebp + 48]					; OFFSET of userNumString
		push	[ebp - 16]					; LENGTHOF of userNumString

		call	reverseString					; call helper procedure to reverse string

		cmp		ecx, 10					; check for first iteration
		jne		NF

FI:		; Invoke macro to print number (first iteration)

		displayString	[ebp + 60], [ebp + 36]
		jmp		DN

DN:		; Done printing

		add		esi, 4					; increment array pointer
		mov		SDWORD PTR [ebp - 16], 0		; clear string length counter
		loop	CONL
		jmp		CALC

NF:		; Invoke macro to print number (not first iteration)

		displayString	[ebp + 60], [ebp + 64]
		jmp		DN

CALC:	; calculate and display average

		push	[ebp - 8]					; push sum
		push	[ebp - 12]					; push sum count

		call	calcAvg

		push	[ebp - 4]					; sum of user numbers
		push	[ebp + 48]					; OFFSET userNumString

		call	numToString					; call conversion helper

		push	[ebp + 60]					; OFFSET of finalString
		push	[ebp + 48]					; OFFSET of userNumString
		push	[ebp - 16]					; LENGTHOF of userNumString

		call	reverseString					; call helper procedure to reverse string

		call	CrLf
		displayString	[ebp + 60], [ebp + 44]			; print

		; convert and display sum

		push	[ebp - 8]					; sum of user numbers
		push	[ebp + 48]					; OFFSET userNumString

		call	numToString					; call conversion helper

		push	[ebp + 60]					; OFFSET of finalString
		push	[ebp + 48]					; OFFSET of userNumString
		push	[ebp - 16]					; LENGTHOF of userNumString

		call	reverseString					; call helper procedure to reverse string

		call	CrLf
		displayString	[ebp + 60], [ebp + 40]			; print
		call	CrLf
		call	CrLf

		mov		esp, ebp				; remove local variables
		popad							; restore registers
		ret	28
writeVal	ENDP

;**********************************************************************************************************
;	numToString	 Procedure
;  
;	recieves: user number to be converted, OFFSET userNumString
;                   
;	returns: None
;	preconditions: parameters listed must be recieved
;	registers changed: esi, edi, eax, ebx
;	description: Converts a signed integer back to string.
;				 
;**********************************************************************************************************
numToString	PROC
		pushad							; preserve registers
		mov		ebp, esp				; set stack frame and base pointer

		sub		esp, 8					; create local variables
		mov		SDWORD PTR [ebp - 4], 0			; initialize to 0 negative flag NF = 1 (negative)
		mov		SDWORD PTR [ebp - 8], 0			; initialize counter to 0 (counts length of string)
		mov		edi, [ebp + 36]				; point edi to destination string
		mov		ebx, 0
		mov		[edi], ebx				; clear destination string

		CLD							; clear direction flag for stosb

		mov		eax, SDWORD PTR [ebp + 40]		; current number to be converted
		cmp		eax, 0					; check if the number is negative
		jg		CONV					; jump to not negative

		mov		SDWORD PTR [ebp - 4], 1			; set custom negative flag
		neg		eax					; negate to positive for ease of working with
		

CONV:	; Conversion Loop
		xor		edx, edx				; clear edx for division
		add		SDWORD PTR [ebp - 8], 1			; increment length counter
		
		mov		ebx, 10					; divide number by 10 until remainder is zero
		div		ebx
		
		; add 30h to remainder to make ascii char
		push	eax						; store eax current val
		mov		eax, edx				; fetch remainder
		add		eax, 30h
		stosb							; store contents of eax to edi		
		pop		eax					; restore
		
		; if quotient is zero we have reached the end
		cmp		eax, 0					; If edx is 0 break loop
		je		DN
		jmp		CONV					; loop

DN:		; Add sign symbol to string
		mov		ebx, SDWORD PTR [ebp - 4]		; retrieve custom sign flag
		cmp		ebx, 0					; IF not negative
		je		POSI					; True: jump to positive
		
		mov		eax, 0					; clear eax
		mov		al, 2Dh					; move '-' to eax
		jmp		EN					; jump to end

POSI:	; positive number
		
		mov		eax, 0					; clear eax
		mov		al, 2Bh					; move '+' to eax

EN:		; end
		stosb							; store sign in string
		;add		SDWORD PTR [ebp - 8], 1			; increment length counter
		mov		eax, 0									
		stosb							; store null terminator	
		
		; return length of string to local variable of writeVal
		xor		eax, eax
		mov		eax, [ebp - 8]
		mov		SDWORD PTR [ebp + 44], eax

		mov		esp, ebp				; remove local variables
		popad							; restore registers
		ret	8
numToString	ENDP

;**********************************************************************************************************
;	reverseString	 Procedure
;  
;	recieves: OFFSET userNumString, length of userNumString
;                   
;	returns: None
;	registers changed: eax, ebx, esi, edi
;	preconditions: parameters listed must be recieved
;	descriptions: reverses the number converted to string
;				   that was written backwards during conversion
;***********************************************************************************************************
reverseString	PROC
		pushad							; preserve registers
		mov		ebp, esp				; set base pointer
		
		xor		ebx, ebx				; clear ebx

		; set source and destination to userNumString
		mov		esi, [ebp + 40]				; OFFSET userNumString
		mov		edi, [ebp + 44]				; OFFSET finalString
		mov		ebx, [ebp + 36]				; Length of userNumString

		;dec		ebx					; decrement ebx to adjust offset of string
		add		esi, ebx				; add length to source pointer

		STD							; set direction flag to read backward

readStr:								; read string loop
		xor		eax, eax				; clear eax

		lodsb							; fetch first character

		; Store in destination finalString
		CLD							; clear direction flag to write forwards
		stosb
		STD							; set direction flag to change back to backwards reading

		dec		ebx					; decrement length counter

		cmp		ebx, 0
		jl		DN					; if done jump out
		jmp		readStr					; else loop

DN:		
mov		esi, [ebp + 44]						; OFFSET finalString
		CLD							; clear direction flag to write forwards
		mov		eax, 0					; add null terminator
		stosb

		popad							; restore registers
		ret 12							; clean up stack
reverseString	ENDP

;**********************************************************************************************************
;	calcAvg Procedure
;  
;	calculates average of numbers entereed
;
;	recieves: Sum, Count of numbers, 
;	returns: rounded integer average
;	preconditions: parameters listed must be recieved
;	registers changed: ebx, edx, eax
;	description: calculates the rounded average of an integer
;**********************************************************************************************************
calcAvg	PROC
		pushad							; store general purpose registers
		mov		ebp, esp				; set stack frame base pointer
		
		; declare and initialize local variables
		sub		esp, 4					; create 2 SDWORD local variables
		mov		SDWORD PTR [ebp - 4], 0			; Average 

		; calculate whole number part of average
		xor		edx, edx
		mov		eax, [ebp + 40]				; fetch sum
		mov		ebx, [ebp + 36]				; fetch number count

		idiv	ebx
		mov		SDWORD PTR [ebp - 4], eax

		; Assess need for rounding
		imul	edx, 2

		; IF (remainder * 2) >= number count, round up
		cmp		edx, ebx
		jge		RU					; TRUE: jump to Round Up
		jmp		DN					; FALSE: leave average as is and jump to Display Numbers

RU:		add		SDWORD PTR [ebp - 4], 1			; Round to nearest whole number

DN:		; done calculating return to local variable in write val
		mov		eax, [ebp - 4]
		mov		[ebp + 56], eax

		mov		esp, ebp				; remove local variables
		popad							; restore general purpose registers
		ret	8						; clean up stack
calcAvg	ENDP


END main
