;Kodo stilius
;Žymės: SCREAMING_SNAKE_CASE
;Procedūros: camelCase
;Kintamieji: camelCase

.model small
.stack 100h

vardoBufDydis EQU 20
skBufDydis    EQU 20
rBufDydis     EQU 30
opLentDydis   EQU 5000
grpPoslinkis  EQU 4096

.data
  masKodas  db 24h, 24h, 80h, 06h, 10h, 02h, 30h, 8ch, 0c8h, 0b4h, 09h, 0bah, 0deh, 01h, 0cdh, 21h, 0b4h, 0ah, 0bah, 63h, 01h, 0cdh, 21h, 0b4h, 09h, 0bah, 11h, 02h
  skBuf     db skBufDydis dup ('$')
  rBuf      db rBufDydis dup ('$')

  lentVard  db "op.bin", 0
  opLent    db opLentDydis dup (?)
  lFail     dw ?

  instruk   dw ?

  modJmpTable dw offset OP_ATM_0, offset OP_ATM_1, offset OP_ATM_2, offset OP_REG
  jmpTableOff dw 0

  modf dw 0
  regf dw 0
  rmf  dw 0
  
  arDekModRM db 0
  dekInstruk db 5

  rmLent    db "BX+SI$BX+DI$BP+SI$BP+DI$SI$$$$DI$$$$BP$$$$BX$"
	regLent0  db "AL$CL$DL$BL$AH$CH$DH$BH$"
  regLent1  db "AX$CX$DX$BX$SP$BP$SI$DI$"
  regLent2  db "ES$CS$SS$DS$"
  

  klZin     db "Klaida", 10, 13, "$"
  naujaEil  db 10, 13, "$"
  

.code
  PRADZIA:
  MOV ax, @data
  MOV ds, ax
  
  SKAITYMAS:
  MOV ah, 3Dh
  MOV al, 00
  MOV dx, offset lentVard
  INT 21h
  JC  klaida
  MOV lFail, ax
  
  MOV bx, lFail
  MOV	ah, 3Fh			
  MOV	cx, opLentDydis
  MOV	dx, offset opLent
  INT	21h
  JC	KLAIDA

  MOV si, offset masKodas
  
  INSTRUKCIJU_DEKODAVIMAS:
  MOV di, offset rBuf
  MOV arDekModRM, 0
  CALL dekoduotiInstrukcija
  MOV dx, offset rBuf
  CALL spausdintiEilute
  
  DEC dekInstruk
  CMP dekInstruk, 0
  JNE INSTRUKCIJU_DEKODAVIMAS


  
  PABAIGA:
  MOV ah, 4Ch
  MOV al, 0
  INT 21h

  KLAIDA:
  MOV ah, 09h
  MOV dx, offset klZin
  INT 21h
  JMP PABAIGA
  
PROC skaitytiBaita
  ;I AL IDEDAMAS SEKANTIS BAITAS
  LODSB ;; TODO: po to padaryti labiau advanced.
  RET
ENDP skaitytiBaita

PROC skaitytiZodi
  ;I AX IDEDAMI SEKANTYS DU BAITAI
  LODSW
  RET
ENDP skaitytiZodi

PROC dekoduotiInstrukcija
  PUSH ax
  PUSH bx
  PUSH cx
  
  CALL skaitytiBaita

  MOV ah, 0
  SHL ax, 4 ; Dauginame is 16
  MOV bx, offset oplent
  ADD bx, ax
  MOV instruk, bx
  
  CMP byte ptr[bx], "9"
  ja NERA_GRUPEJE
  CALL dekoduotiModRM
  MOV ah, 0
  MOV al, byte ptr[bx]
  SUB al, "0"
  SHL ax, 3 ; Dauginame is 8
  ;Galbut naudoti 1 baito modrm laukus?
  ADD ax, regf
  SHL ax, 4 ; Dauginame is 16
  
  MOV bx, offset opLent
  ADD bx, grpPoslinkis
  ADD bx, ax

  NERA_GRUPEJE:
  CALL rasytiIkiTarpo
  CMP byte ptr[bx], " "
  JNE ARGUMENTU_DEKODAVIMAS
  MOV bx, instruk
  CALL praleistiArgumenta
  ARGUMENTU_DEKODAVIMAS:

  CALL rasytiTarpa
  CALL dekoduotiArgumenta
  CALL praleistiArgumenta
  CMP byte ptr[bx], " "
  JE PRALEISTI_ANTRA_ARGUMENTA
  MOV dx, ","
  CALL rasytiSimboli
  CALL rasytiTarpa
  CALL dekoduotiArgumenta
  PRALEISTI_ANTRA_ARGUMENTA:
  MOV byte ptr [di], "$"


  POP cx
  POP bx
  POP ax
  RET
ENDP dekoduotiInstrukcija

PROC dekoduotiArgumenta
  ;ADRESAS I ARGUMENTO BUFERI LAIKOMAS BX REGISTRE
  PUSH ax
  PUSH bx

  CMP byte ptr[bx], "e"
  JNE NEPRASIDEDA_E_MAZAJA
  INC bx
  CALL rasytiIkiTarpo
  JMP ARGUMENTO_DEKODAVIMO_PABAIGA

  NEPRASIDEDA_E_MAZAJA:
  CMP byte ptr[bx], "1"
  JB NEPRASIDEDA_1_3
  CMP byte ptr[bx], "3"
  JA NEPRASIDEDA_1_3
  MOV dl, [bx]
  CALL rasytiSimboli
  JMP ARGUMENTO_DEKODAVIMO_PABAIGA
  
  NEPRASIDEDA_1_3:
  CMP byte ptr[bx], "M"
  JNE NEPRASIDEDA_M
  CALL dekoduotiModRM
  CALL skaitytiZodi
  CALL rasytiAX
  JMP ARGUMENTO_DEKODAVIMO_PABAIGA

  NEPRASIDEDA_M:
  CMP byte ptr[bx], "E"
  JE PRASIDEDA_E_DIDZIAJA
  JMP NEPRASIDEDA_E_DIDZIAJA
  PRASIDEDA_E_DIDZIAJA:
  CALL dekoduotiModRM
  ;INT 3h
  ;TODO: PADARYTI JUMP TABLE
  CMP modf, 0
  JE OP_ATM_0_T
  CMP modf, 1
  JE OP_ATM_1_T
  CMP modf, 2
  JE OP_ATM_2_T
  CMP modf, 3
  JE OP_REG_T
  
  OP_ATM_0_T: JMP OP_ATM_0
  OP_ATM_1_T: JMP OP_ATM_1
  OP_ATM_2_T: JMP OP_ATM_2
  OP_REG_T: JMP OP_REG

  OP_ATM_0:
  mov dl, "["
  call rasytiSimboli
  cmp rmf, 6
  jne NETIESIOGINIS_ADRESAS
  call skaitytiZodi
  call rasytiAX
  mov dl, "h"
  call rasytiSimboli
  jmp OP_ATM_0_PABAIGA
  NETIESIOGINIS_ADRESAS:
  mov ax, rmf
  mov dl, 6
  mul dl
  mov dx, offset rmLent
  add dx, ax
  call rasytiIkiDolerio
  OP_ATM_0_PABAIGA:
  mov dl, "]"
  call rasytiSimboli
  jmp ARGUMENTO_DEKODAVIMO_PABAIGA

  OP_ATM_1:
  mov dl, "["
  call rasytiSimboli
  mov ax, rmf
  mov dl, 6
  mul dl
  mov dx, offset rmLent
  add dx, ax
  call rasytiIkiDolerio
  mov dl, "+"
  call rasytiSimboli
  call skaitytiBaita
  call rasytiAL
  mov dl, "h"
  call rasytiSimboli
  mov dl, "]"
  call rasytiSimboli
  jmp ARGUMENTO_DEKODAVIMO_PABAIGA

  OP_ATM_2:
  mov dl, "["
  call rasytiSimboli
  mov ax, rmf
  mov dl, 6
  mul dl
  mov dx, offset rmLent
  add dx, ax
  call rasytiIkiDolerio
  mov dl, "+"
  call rasytiSimboli
  call skaitytiZodi
  call rasytiAX
  mov dl, "h"
  call rasytiSimboli
  mov dl, "]"
  call rasytiSimboli
  jmp ARGUMENTO_DEKODAVIMO_PABAIGA

  OP_REG:
  mov ax, rmf
  mov dl, 3
  mul dl
  mov dx, offset regLent0
  CMP byte ptr[bx+1], "b"
  JE REGISTRO_ARGUMENTO_IRASYMAS
  MOV dx, offset regLent1
  REGISTRO_ARGUMENTO_IRASYMAS:
  add dx, ax
  call rasytiIkiDolerio
  jmp ARGUMENTO_DEKODAVIMO_PABAIGA

  NEPRASIDEDA_E_DIDZIAJA:
  CMP byte ptr[bx], "G"
  JNE NEPRASIDEDA_G
  mov ax, regf
  mov dl, 3
  mul dl
  MOV dx, offset regLent0
  CMP byte ptr[bx+1], "b"
  JE REGISTRO_ARGUMENTO_IRASYMAS_2
  MOV dx, offset regLent1
  REGISTRO_ARGUMENTO_IRASYMAS_2:
  ADD dx, ax
  CALL rasytiIkiDolerio
  JMP ARGUMENTO_DEKODAVIMO_PABAIGA
  
  NEPRASIDEDA_G:
  CMP byte ptr[bx], "I"
  JE PRASIDEDA_I_J_O
  CMP byte ptr[bx], "J"
  JE PRASIDEDA_I_J_O
  CMP byte ptr[bx], "O"
  JE PRASIDEDA_I_J_O
  JMP NEPRASIDEDA_I_J_O
  PRASIDEDA_I_J_O:
  CMP byte ptr[bx+1], "v"
  JE BETARPISKAS_ZODIS
  BETARPISKAS_BAITAS:
  CALL skaitytiBaita
  CALL rasytiAL
  JMP ARGUMENTO_DEKODAVIMO_PABAIGA
  BETARPISKAS_ZODIS:
  CALL skaitytiZodi
  CALL rasytiAX
  JMP ARGUMENTO_DEKODAVIMO_PABAIGA

  NEPRASIDEDA_I_J_O:
  CMP byte ptr[bx], "S"
  JNE NEPRASIDEDA_S
  CALL dekoduotiModRM
  mov ax, regf
  mov dl, 3
  mul dl
  mov dx, offset regLent2
  add dx, ax
  call rasytiIkiDolerio
  JMP ARGUMENTO_DEKODAVIMO_PABAIGA

  NEPRASIDEDA_S:

  ARGUMENTO_DEKODAVIMO_PABAIGA:
  POP bx
  POP ax
  RET
ENDP dekoduotiArgumenta

PROC dekoduotiModRM
  PUSH ax

  CMP arDekModRM, 1
  JE MODRM_DEKODAVIMO_PABAIGA

  CALL skaitytiBaita
  mov ah, 0
  MOV modf, ax
	SHR modf, 6h
	MOV regf, ax
	SHR regf, 3h
	AND regf, 7h
	MOV rmf, ax
	AND rmf, 7h

  MOV arDekModRM, 1

  MODRM_DEKODAVIMO_PABAIGA:

  POP ax
  RET
ENDP dekoduotiModRM

PROC spausdinti16Baitu
  PUSH ax
  PUSH bx
  PUSH cx
  PUSH dx

  MOV cx, 16
  MOV ah, 02h

  SPAUSDINTI_16_BAITU_CIKLAS:
  MOV dl, byte ptr[bx]
  INT 21h
  INC bx
  LOOP SPAUSDINTI_16_BAITU_CIKLAS
  
  POP dx
  POP cx
  POP bx
  POP ax
  RET
ENDP spausdinti16Baitu

PROC spausdintiEilute
	PUSH ax
  PUSH dx
	MOV ah, 09
	INT 21h
  MOV dx, offset naujaEil
  INT 21h
  POP dx
	POP ax
  RET
ENDP spausdintiEilute

PROC rasytiIkiTarpo
  ;RASO BUFERI IS BX I DI IKI TARPO SIMBOLIO
  PUSH ax
  RASYTI_IKI_TARPO_CIKLAS:
  MOV al, [bx]
  MOV [di], al
  INC di
  INC bx
  CMP byte ptr[bx], " "
  JNE RASYTI_IKI_TARPO_CIKLAS
  INC bx
  POP ax
  RET
ENDP rasytiIkiTarpo
  PUSH ax

PROC rasytiIkiDolerio
  ;RASO BUFERI IS DX I DI IKI DOLERIO SIMBOLIO
  PUSH ax
  PUSH bx
  PUSH dx
  MOV bx, dx
  RASYTI_IKI_DOLERIO_CIKLAS:
  MOV al, [bx]
  MOV [di], al
  INC di
  INC bx
  CMP byte ptr[bx], "$"
  JNE RASYTI_IKI_DOLERIO_CIKLAS
  POP dx
  POP bx
  POP ax
  RET
ENDP rasytiIkiDolerio

PROC rasytiTarpa
  MOV byte ptr[di], " "
  INC di
  RET
ENDP rasytiTarpa

PROC rasytiSimboli
  MOV byte ptr[di], dl
  INC di
  RET
ENDP rasytiSimboli

PROC praleistiArgumenta
  ;PRALEIDZIA BUFERI IS BX IKI TARPO SIMBOLIO
  PRALEISTI_IKI_TARPO_CIKLAS:
  INC BX
  CMP byte ptr[bx], " "
  JNE PRALEISTI_IKI_TARPO_CIKLAS
  INC BX
  RET
ENDP praleistiArgumenta

PROC rasytiAX
	push ax
	mov al, ah
	call rasytiAL
	pop ax
	call rasytiAL
  RET
ENDP rasytiAX


PROC rasytiAL
	push ax
	push cx
	push ax
	mov cl, 4
	shr al, cl
	call rasytiHex
	pop ax
	call rasytiHex
	pop cx
	pop ax
  RET
ENDP rasytiAL

PROC rasytiHex
	push ax
	push dx
	
	and al, 0Fh ;nunulinam vyresniji pusbaiti AND al, 00001111b
	cmp al, 9
	jbe PrintHexSkaitmuo_0_9
	jmp PrintHexSkaitmuo_A_F
	
	PrintHexSkaitmuo_A_F: 
	sub al, 10 ;10-15 ===> 0-5
	add al, 41h
  mov [di], al
  inc di
	jmp PrintHexSkaitmuo_grizti
	
	
	PrintHexSkaitmuo_0_9: ;0-9
	add al, 30h
	mov [di], al
  inc di
	jmp printHexSkaitmuo_grizti
	
	printHexSkaitmuo_grizti:
	pop dx
	pop ax
  RET
ENDP rasytiHex


END PRADZIA