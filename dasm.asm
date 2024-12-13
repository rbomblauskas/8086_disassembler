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

.data
  masKodas  db 0b4h, 09h, 0bah, 0deh, 01h, 0cdh, 21h, 0b4h, 0ah, 0bah, 63h, 01h, 0cdh, 21h, 0b4h, 09h, 0bah, 11h, 02h
  skBuf     db skBufDydis dup ('$')
  rBuf      db rBufDydis dup ('$')

  lentVard  db "op.bin", 0
  opLent    db opLentDydis dup (?)
  lFail     dw ?

  instr     dw ?

  modf db 0
  regf db 0
  rmf  db 0

  rmLent    db "BX+SI$BX+DI$BP+SI$BP+DI$SI$$$$DI$$$$BP$$$$BX$"
	regLent0  db "AL$CL$DL$BL$AH$CH$DH$BH$"
  regLent1  db "AX$CX$DX$BX$SP$BP$SI$DI$"
  

  klZin     db "Klaida", 10, 13, "$"
  

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
  MOV di, offset rBuf
  
  CALL dekoduotiInstrukcija
  
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
  
  CALL skaitytiBaita

  MOV bl, 16
  MUL bl
  MOV bx, offset oplent
  ADD bx, ax
  MOV instr, bx
  
  CALL spausdinti16Baitu


  POP bx
  POP ax
  RET
ENDP dekoduotiInstrukcija

PROC dekoduotiModRM
  PUSH ax

  CALL skaitytiBaita

  MOV modf, al
	SHR modf, 6h
	MOV regf, al
	SHR regf, 3h
	AND regf, 7h
	MOV rmf, al
	AND rmf, 7h

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
	MOV ah, 09
	INT 21h
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
  INC BX
  POP ax
  RET
ENDP rasytiIkiTarpo

PROC praleistiIkiTarpo
  ;PRALEIDZIA BUFERI IS BX IKI TARPO SIMBOLIO
  PRALEISTI_IKI_TARPO_CIKLAS:
  INC BX
  CMP byte ptr[bx], " "
  JNE PRALEISTI_IKI_TARPO_CIKLAS
  INC BX
  RET
ENDP rasytiIkiTarpo


END PRADZIA