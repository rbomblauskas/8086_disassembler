;Disasemblerio autorius: Rokas Bomblauskas, PS 1 k. 1 gr.
;Kodo stilius:
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
  ;masKodas  db 81h, 0BFh, 05h, 01h, 04h, 08h, 8Ah, 0CFh, 0Eh, 24h, 24h, 80h, 06h, 10h, 02h, 30h, 8ch, 0c8h, 0b4h, 09h, 0bah, 0deh, 01h, 0cdh, 21h, 0b4h, 0ah, 0bah, 63h, 01h, 0cdh, 21h, 0b4h, 09h, 0bah, 11h, 02h
  
  skBuf     db skBufDydis dup ('$')
  rBuf      db rBufDydis dup ('$')
  opLent    db opLentDydis dup (?)

  lFail     dw ?
  dFail     dw ?
  rFail     dw ?

  lVard     db "op.bin", 0
  dVard     db vardoBufDydis dup(0)
  rVard     db vardoBufDydis dup(0)

  instruk   dw ?

  modJmpTable dw offset OP_ATM_0, offset OP_ATM_1, offset OP_ATM_2, offset OP_REG

  modf dw 0
  regf dw 0
  rmf  dw 0
  
  arDekModRM db 0
  ;dekInstruk db 255

  dekBaitai     db 10 dup(?)
  dekBaituSkc   dw 0 
  
  rezEil        db 100 dup(?)

  nuskBaituSkc db skBufDydis
  instrukRod   dw 0100h

  rmLent    db "BX+SI$BX+DI$BP+SI$BP+DI$SI$$$$DI$$$$BP$$$$BX$"
  regLent0  db "AL$CL$DL$BL$AH$CH$DH$BH$"
  regLent1  db "AX$CX$DX$BX$SP$BP$SI$DI$"
  regLent2  db "ES$CS$SS$DS$"
  bytePtr   db "BYTE PTR $"
  wordPtr   db "WORD PTR $"
  
  tarpas    db 20 dup(" "), "$"
  klAtZin     db "Klaida atidarant faila", 10, 13, "$"
  klUzdZin  db "Klaida uzdarant faila", 10, 13, "$"
  naujaEil  db 10, "$"
  pagZin    db "8086/8088 disasemblerio autorius: Rokas Bomblauskas, PS 1 k. 1 gr.", 10, 13
            db "Programa perskaito vykdomaji (.COM) faila ir isveda asemblerio instrukcijas", 10, 13
            db "Programos naudojimas: DASM.EXE <vykdomasis_failas> <rezultatu_failas>", 10, 13, "$"
  neatpaz   db "NEATPAZINTA$"
  

.code
  PRADZIA:
  MOV ax, @data
  MOV ds, ax

  MOV ch, 0
  MOV cl, [es:0080h]
  CMP cx, 0
  JE PAGALBA
  MOV bx, 0081h

  KLAUSTUKO_PAIESKA:
  CMP  [es:bx], '?/'
  JE   PAGALBA
  INC  bx
  LOOP KLAUSTUKO_PAIESKA

  ARGUMENTU_SKAITYMAS:
  MOV  bx, 0081h
  MOV  cl, [es:0080h]
  CALL praleistiTarpusKomEil
  MOV  di, offset dVard
  CALL skaitytiVardaKomEil
  CMP  cx, 0
  JE   PAGALBA
  CALL praleistiTarpusKomEil
  MOV  di, offset rVard
  CALL skaitytiVardaKomEil
  CMP  cx, 0
  JNE  PAGALBA

  OPKODU_LENTELES_SKAITYMAS:
  MOV ah, 3Dh
  MOV al, 00
  MOV dx, offset lVard
  INT 21h
  JC  KLAIDA_ATIDARANT
  MOV lFail, ax
  
  MOV bx, lFail
  MOV	ah, 3Fh			
  MOV	cx, opLentDydis
  MOV	dx, offset opLent
  INT	21h
  JC	KLAIDA_ATIDARANT

  CALL uzdarytiFaila

  DUOMENU_FAILO_ATIDARYMAS:
  MOV ah, 3Dh
  MOV al, 00
  MOV dx, offset dVard
  INT 21h
  JC  KLAIDA_ATIDARANT
  MOV dFail, ax
  
  REZULTATU_FAILO_SUKURIMAS:
  MOV ah, 3Ch
  MOV cx, 0
  MOV dx, offset rVard
  INT 21h
  JC  KLAIDA_ATIDARANT
  MOV rFail, ax
  JMP INSTRUKCIJU_DEKODAVIMAS

  PAGALBA:
  MOV dx, offset pagZin
  CALL spausdintiEilute
  JMP PABAIGA

  KLAIDA_ATIDARANT:
  MOV ah, 09h
  MOV dx, offset klAtZin
  INT 21h
  JMP PABAIGA
  
  INSTRUKCIJU_DEKODAVIMAS:
  MOV dekBaituSkc, 0
  MOV arDekModRM, 0
  MOV di, offset rBuf
  CALL dekoduotiInstrukcija

  MOV di, offset rezEil
  MOV ax, instrukRod
  CALL rasytiAX
  MOV [di], " :"
  ADD di, 2
  CALL rasytiDekoduotusBaitus
  CALL rasytiInstrukcija

  MOV ax, dekBaituSkc
  ADD instrukRod, ax

  JMP INSTRUKCIJU_DEKODAVIMAS

  FAILU_UZDARYMAS:
  MOV bx, dFail
  CALL uzdarytiFaila
  MOV bx, rFail
  CALL uzdarytiFaila
  
  PABAIGA:
  MOV ah, 4Ch
  MOV al, 0
  INT 21h

PROC skaitytiIsFailo
  PUSH bx
  PUSH cx
  PUSH dx
  MOV bx, dFail
  MOV ah, 3Fh
  MOV cx, skBufDydis
  MOV dx, offset skBuf
  INT 21h
  JC KLAIDA_SKAITANT
  SKAITYTI_IS_FAILO_PABAIGA:
  POP	dx
  POP	cx
  POP bx
  RET
  KLAIDA_SKAITANT:
  MOV ax, 0
  JMP SKAITYTI_IS_FAILO_PABAIGA
skaitytiIsFailo ENDP
  
PROC skaitytiBaita
  PUSH bx
  ;I AL IDEDAMAS SEKANTIS BAITAS
  CMP nuskBaituSkc, skBufDydis
  JB PRALEISTI_BUFERIO_NUSKAITYMA
  CALL skaitytiIsFailo
  CMP ax, 0
  JE FAILO_PABAIGA
  MOV nuskBaituSkc, 0
  MOV si, offset skBuf
  PRALEISTI_BUFERIO_NUSKAITYMA:
  LODSB
  MOV bx, offset dekBaitai
  MOV dx, dekBaituSkc
  ADD bx, dx
  MOV byte ptr[bx], al
  INC dekBaituSkc
  INC nuskBaituSkc
  POP bx
  RET
  FAILO_PABAIGA:
  JMP FAILU_UZDARYMAS
ENDP skaitytiBaita

PROC skaitytiZodi
  ;I AX IDEDAMI SEKANTYS DU BAITAI
  PUSH bx
  call skaitytiBaita
  MOV bl, al
  call skaitytiBaita
  MOV ah, al
  MOV al, bl
  POP bx
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
  
  CMP byte ptr[bx], "-"
  JE NEATPAZINTA_INSTRUKCIJA
  CMP byte ptr[bx], "9"
  JA NERA_GRUPEJE
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
  CMP byte ptr[bx], "-"
  JE NEATPAZINTA_INSTRUKCIJA
  NERA_GRUPEJE:
  CALL rasytiIkiTarpo
  CMP byte ptr[bx], " "
  JNE ARGUMENTU_DEKODAVIMAS
  MOV bx, instruk
  CALL praleistiArgumenta
  ARGUMENTU_DEKODAVIMAS:
  CMP byte ptr[bx], " "
  JE INSTRUKCIJOS_DEKODAVIMO_PABAIGA
  CALL rasytiTarpa
  CALL dekoduotiArgumenta
  CALL praleistiArgumenta
  CMP byte ptr[bx], " "
  JE INSTRUKCIJOS_DEKODAVIMO_PABAIGA
  MOV dx, ","
  CALL rasytiSimboli
  CALL rasytiTarpa
  CALL dekoduotiArgumenta

  INSTRUKCIJOS_DEKODAVIMO_PABAIGA:
  MOV byte ptr[di], 10
  MOV byte ptr [di+1], "$"
  POP cx
  POP bx
  POP ax
  RET

  NEATPAZINTA_INSTRUKCIJA:
  MOV dx, offset neatpaz
  CALL rasytiIkiDolerio
  JMP INSTRUKCIJOS_DEKODAVIMO_PABAIGA
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

  ;JUMP TABLE
  PUSH bx
  MOV bx, modf
  SHL bx, 1
  ADD bx, offset modJmpTable
  MOV ax, [bx]
  POP bx
  JMP ax

  OP_ATM_0:
  CALL rasytiPriesdeli
  MOV dl, "["
  CALL rasytiSimboli
  CMP rmf, 6
  JNE NETIESIOGINIS_ADRESAS
  CALL skaitytiZodi
  CALL rasytiAX
  JMP OP_ATM_0_PABAIGA
  NETIESIOGINIS_ADRESAS:
  MOV ax, rmf
  MOV dl, 6
  MUL dl
  MOV dx, offset rmLent
  ADD dx, ax
  CALL rasytiIkiDolerio
  OP_ATM_0_PABAIGA:
  MOV dl, "]"
  CALL rasytiSimboli
  JMP ARGUMENTO_DEKODAVIMO_PABAIGA

  OP_ATM_1:
  CALL rasytiPriesdeli
  MOV dl, "["
  CALL rasytiSimboli
  MOV ax, rmf
  MOV dl, 6
  MUL dl
  MOV dx, offset rmLent
  ADD dx, ax
  CALL rasytiIkiDolerio
  MOV dl, "+"
  CALL rasytiSimboli
  CALL skaitytiBaita
  CALL rasytiAL
  MOV dl, "]"
  CALL rasytiSimboli
  JMP ARGUMENTO_DEKODAVIMO_PABAIGA

  OP_ATM_2:
  CALL rasytiPriesdeli
  MOV dl, "["
  CALL rasytiSimboli
  MOV ax, rmf
  MOV dl, 6
  MUL dl
  MOV dx, offset rmLent
  ADD dx, ax
  CALL rasytiIkiDolerio
  MOV dl, "+"
  CALL rasytiSimboli
  CALL skaitytiZodi
  CALL rasytiAX
  MOV dl, "]"
  CALL rasytiSimboli
  JMP ARGUMENTO_DEKODAVIMO_PABAIGA

  OP_REG:
  MOV ax, rmf
  MOV dl, 3
  MUL dl
  MOV dx, offset regLent0
  CMP byte ptr[bx+1], "b"
  JE REGISTRO_ARGUMENTO_IRASYMAS
  MOV dx, offset regLent1
  REGISTRO_ARGUMENTO_IRASYMAS:
  ADD dx, ax
  CALL rasytiIkiDolerio
  JMP ARGUMENTO_DEKODAVIMO_PABAIGA

  NEPRASIDEDA_E_DIDZIAJA:
  CMP byte ptr[bx], "G"
  JNE NEPRASIDEDA_G
  CALL dekoduotiModRM
  MOV ax, regf
  MOV dl, 3
  MUL dl
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
  JNE NEPRASIDEDA_I
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

  NEPRASIDEDA_I:
  CMP byte ptr[bx], "J"
  CMP byte ptr[bx+1], "v"
  JE ZODZIO_POSLINKIS

  BAITO_POSLINKIS:
  CALL skaitytiBaita
  CBW
  ADD ax, instrukRod
  ADD ax, dekBaituSkc
  CALL rasytiAX
  JMP ARGUMENTO_DEKODAVIMO_PABAIGA

  ZODZIO_POSLINKIS:
  CALL skaitytiZodi
  ADD ax, instrukRod
  ADD ax, dekBaituSkc
  CALL rasytiAX
  JMP ARGUMENTO_DEKODAVIMO_PABAIGA

  NEPRASIDEDA_J:
  CMP byte ptr[bx], "O"
  JNE NEPRASIDEDA_O
  MOV dl, "["
  CALL rasytiSimboli
  CALL skaitytiZodi
  CALL rasytiAX
  MOV dl, "]"
  CALL rasytiSimboli
  JMP ARGUMENTO_DEKODAVIMO_PABAIGA
  
  NEPRASIDEDA_O:
  CMP byte ptr[bx], "S"
  JNE NEPRASIDEDA_S
  CALL dekoduotiModRM
  MOV ax, regf
  MOV dl, 3
  MUL dl
  MOV dx, offset regLent2
  ADD dx, ax
  CALL rasytiIkiDolerio
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

PROC rasytiPriesdeli
  CMP byte ptr [bx+1], "v"
  JE ZODZIO_PRIESDELIS
  BAITO_PRIESDELIS:
  MOV dx, offset bytePtr
  JMP PRIESDELIO_RASYMO_PABAIGA 
  ZODZIO_PRIESDELIS:
  MOV dx, offset wordPtr
  PRIESDELIO_RASYMO_PABAIGA:
  CALL rasytiIkiDolerio
  RET
ENDP rasytiPriesdeli

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
  PUSH ax
  PUSH dx
  
  AND al, 0Fh ;nunulinam vyresniji pusbaiti AND al, 00001111b
  CMP al, 9
  JBE PRINT_HEX_SKAITMUO_0_9
  JMP PRINT_HEX_SKAITMUO_A_F
  
  PRINT_HEX_SKAITMUO_A_F: 
  SUB al, 10 ;10-15 ===> 0-5
  ADD al, 41h
  MOV [di], al
  INC di
  JMP PRINT_HEX_SKAITMUO_GRIZTI
  
  PRINT_HEX_SKAITMUO_0_9: ;0-9
  ADD al, 30h
  MOV [di], al
  INC di
  JMP PRINT_HEX_SKAITMUO_GRIZTI
  
  PRINT_HEX_SKAITMUO_GRIZTI:
  POP dx
  POP ax
  RET
ENDP rasytiHex

praleistiTarpusKomEil PROC
  PRALEISTI_TARPA:
  CMP  byte ptr [es:bx], ' '
  JNE  PRALEISTI_TARPUS_PABAIGA
  INC  bx
  LOOP PRALEISTI_TARPA
  PRALEISTI_TARPUS_PABAIGA:
  RET
praleistiTarpusKomEil ENDP

skaitytiVardaKomEil PROC
  VARDO_SKAITYMAS:
  MOV al, [es:bx]
  MOV [di], al
  INC di
  INC bx
  DEC cx
  JZ  VARDO_SKAITYMO_PABAIGA
  CMP byte ptr [es:bx], ' '
  JNE VARDO_SKAITYMAS
  VARDO_SKAITYMO_PABAIGA:
  MOV byte ptr[di], 0
  RET
skaitytiVardaKomEil ENDP

rasytiDekoduotusBaitus PROC
  PUSH cx
  PUSH si
  ;INT 3h

  MOV cx, dekBaituSkc
  MOV si, offset dekBaitai
  BAITU_KODAVIMO_CIKLAS:
  LODSB
  CALL rasytiAL
  LOOP BAITU_KODAVIMO_CIKLAS

  POP si
  POP cx

  RET
rasytiDekoduotusBaitus ENDP

skaiciuotiEilutesIlgi PROC
;DX laikoma rodykle i eilute
;CX grazinamas eilutes ilgis
  PUSH bx
  MOV bx, dx
  MOV cx, 0
  EILUTES_ILGIO_SKAICIAVIMAS:
  INC cx
  INC bx
  CMP byte ptr[bx], "$"
  JNE EILUTES_ILGIO_SKAICIAVIMAS
  POP bx
  RET
skaiciuotiEilutesIlgi ENDP

uzdarytiFaila PROC
  PUSH ax
  MOV ah, 3Eh
  INT 21h
  JC  KLAIDA_UZDARANT
  POP ax
  RET
  KLAIDA_UZDARANT:
  MOV ah, 09h
  MOV dx, offset klUzdZin
  INT 21h
  JMP PABAIGA
uzdarytiFaila ENDP

rasytiIFaila PROC
  PUSH ax
  PUSH bx
  MOV bx, rFail
  MOV	ah, 40h
  CALL skaiciuotiEilutesIlgi
  INT	21h
  JC	klaidaRasant
  CMP	cx, ax
  JNE	DALINIS_IRASYMAS
  RasykBufPabaiga:
  POP bx
  POP ax
  RET
  DALINIS_IRASYMAS:
  JMP	RasykBufPabaiga
  klaidaRasant:
  MOV	ax, 0
  JMP	RasykBufPabaiga
  RET
ENDP rasytiIFaila

rasytiInstrukcija PROC
  MOV ax, dekBaituSkc
  SHL ax, 1
  MOV dx, offset tarpas
  ADD dx, ax
  CALL rasytiIkiDolerio
  MOV dx, offset rBuf
  CALL rasytiIkiDolerio
  MOV dx, offset rezEil
  MOV byte ptr[di], "$"
  CALL rasytiIFaila
  RET
rasytiInstrukcija ENDP

END PRADZIA