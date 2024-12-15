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
  masKodas  db 81h, 0BFh, 05h, 01h, 04h, 08h, 8Ah, 0CFh, 0Eh, 24h, 24h, 80h, 06h, 10h, 02h, 30h, 8ch, 0c8h, 0b4h, 09h, 0bah, 0deh, 01h, 0cdh, 21h, 0b4h, 0ah, 0bah, 63h, 01h, 0cdh, 21h, 0b4h, 09h, 0bah, 11h, 02h
  
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
  jmpTableOff dw 0

  modf dw 0
  regf dw 0
  rmf  dw 0
  
  arDekModRM db 0
  ;dekInstruk db 255

  dekBaitai    db 10 dup(?)
  dekBaituSkc  db 0 
  dekBaitaiHex db 20 dup(?)

  nuskBaituSkc db skBufDydis
  instrukRod   dw 0100h

  rmLent    db "BX+SI$BX+DI$BP+SI$BP+DI$SI$$$$DI$$$$BP$$$$BX$"
  regLent0  db "AL$CL$DL$BL$AH$CH$DH$BH$"
  regLent1  db "AX$CX$DX$BX$SP$BP$SI$DI$"
  regLent2  db "ES$CS$SS$DS$"
  
  tarpas    db 20 dup(" "), "$"
  klZin     db "Klaida", 10, 13, "$"
  naujaEil  db 10, "$"
  pagZin    db "Sveiki, cia pagalbos pranesimas", 10, 13, "$"
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
  JC  KLAIDA
  MOV lFail, ax
  
  MOV bx, lFail
  MOV	ah, 3Fh			
  MOV	cx, opLentDydis
  MOV	dx, offset opLent
  INT	21h
  JC	KLAIDA

  MOV ah, 3Eh
  MOV bx, lFail
  INT 21h
  JC  KLAIDA

  DUOMENU_FAILO_ATIDARYMAS:
  MOV ah, 3Dh
  MOV al, 00
  MOV dx, offset dVard
  INT 21h
  JC  KLAIDA
  MOV dFail, ax

  ;JMP INSTRUKCIJU_DEKODAVIMAS
  
  REZULTATU_FAILO_SUKURIMAS:
  MOV ah, 3Ch
  MOV cx, 0
  MOV dx, offset rVard
  INT 21h
  JC  KLAIDA
  MOV rFail, ax
  JMP INSTRUKCIJU_DEKODAVIMAS

  PAGALBA:
  MOV dx, offset pagZin
  CALL spausdintiEilute
  JMP PABAIGA
  
  INSTRUKCIJU_DEKODAVIMAS:
  ;INT 3h
  MOV dekBaituSkc, 0
  MOV arDekModRM, 0
  MOV di, offset rBuf
  CALL dekoduotiInstrukcija

  CALL spausdintiDekoduotusBaitus
  CALL rasytiInstrukcija

  ;CALL spausdintiDekoduotusBaitus
  ;MOV dx, offset rBuf
  ;CALL spausdintiEilute

  XOR ah, ah
  MOV al, dekBaituSkc
  ADD instrukRod, ax

  JMP INSTRUKCIJU_DEKODAVIMAS
  
  ;DEC dekInstruk
  ;CMP dekInstruk, 0
  ;JNE INSTRUKCIJU_DEKODAVIMAS

  PABAIGA:
  MOV ah, 4Ch
  MOV al, 0
  INT 21h

  KLAIDA:
  MOV ah, 09h
  MOV dx, offset klZin
  INT 21h
  JMP PABAIGA

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
  MOV dx, 0
  MOV dl, dekBaituSkc
  ADD bx, dx
  MOV byte ptr[bx], al
  INC dekBaituSkc
  INC nuskBaituSkc
  POP bx
  RET
  FAILO_PABAIGA:
  JMP PABAIGA
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
  CALL dekoduotiModRM
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
  JE PRASIDEDA_I_J
  CMP byte ptr[bx], "J"
  JE PRASIDEDA_I_J
  JMP NEPRASIDEDA_I_J
  PRASIDEDA_I_J:
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

  NEPRASIDEDA_I_J:
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

spausdintiDekoduotusBaitus PROC
  PUSH cx
  PUSH si
  PUSH di
  ;INT 3h

  MOV ch, 0
  MOV cl, dekBaituSkc
  MOV si, offset dekBaitai
  MOV di, offset dekBaitaiHex
  BAITU_KODAVIMO_CIKLAS:
  LODSB
  CALL rasytiAL
  LOOP BAITU_KODAVIMO_CIKLAS
  MOV byte ptr[di], "$"

  POP di
  POP si
  POP cx

  RET
spausdintiDekoduotusBaitus ENDP

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
  MOV dx, offset dekBaitaiHex
  CALL rasytiIFaila
  MOV dx, offset tarpas
  ADD dx, cx
  CALL rasytiIFaila
  MOV dx, offset rBuf
  CALL rasytiIFaila
  RET
rasytiInstrukcija ENDP

END PRADZIA