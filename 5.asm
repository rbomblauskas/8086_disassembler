.model small
.stack 100h

vardoBufDydis EQU 20
skBufDydis    EQU 20; konstanta skBufDydis (lygi 20) - skaitymo buferio dydis
raBufDydis    EQU skBufDydis*3; konstanta raBufDydis (lygi 60) - rašymo buferio dydis

.data
	duom      db vardoBufDydis dup (0); duomenų failo pavadinimas, pasibaigiantis nuliniu simboliu (C sintakse - '\0')
	rez       db vardoBufDydis dup (0); rezultatų failo pavadinimas, pasibaigiantis nuliniu simboliu
	skBuf     db skBufDydis dup (?); skaitymo buferis
	raBuf     db raBufDydis dup (?); rašymo buferis
	nuskBaitu dw 0; kiek nuskaityta baitų
	dFail     dw ?; vieta, skirta saugoti duomenų failo deskriptoriaus numerį ("handle")
	rFail     dw ?; vieta, skirta saugoti rezultato failo deskriptoriaus numerį
	newLine   db 0Dh, 0Ah, '$'
	pagZin    db "Programos naudojimas: 5.EXE <duomenu_failas> <rezultatu_failas>", 10, 13, "$"
	dfZin     db "Klaida atidarant faila", 10, 13, "$"
	rfZin     db "Klaida rasant i faila", 10, 13, "$"

.code
	Pradzia:
	MOV ax, @data; reikalinga kiekvienos programos pradzioj
	MOV ds, ax; reikalinga kiekvienos programos pradzioj

	MOV ch, 0
	MOV cl, [es:0080h]; programos paleidimo parametrų simbolių skaičius rašomas ES 128-ame (80h) baite
	CMP cx, 0; jei paleidimo parametrų nėra
	JE  Pagalba; einame į pagalbą
	MOV bx, 0081h; programos paleidimo parametrai rašomi segmente es pradedant 129 (arba 81h) baitu

	KlaustukoPaieska:
	CMP  [es:bx], '?/'
	JE   Pagalba
	INC  bx
	loop KlaustukoPaieska

	ArgumentuSkaitymas:
	MOV  bx, 0081h
	MOV  cl, [es:0080h]
	CALL PraleistiTarpus
	MOV  di, offset duom
	CALL NuskaitytiVarda
	CMP  cx, 0
	JE   Pagalba; Per mažai argumentų
	CALL PraleistiTarpus
	MOV  di, offset rez
	CALL NuskaitytiVarda
	CMP  cx, 0
	JNE  Pagalba; Per daug argumentų
	JMP  Skaitymas

	Pagalba:
	MOV ah, 09h; buferio spausdinimo dosinės funkcijos numeris
	MOV dx, offset pagZin; į dx įrašome pagalbos žinutės buferio adresą
	INT 21h; spausdiname
	JMP Pabaiga

;*****************************************************
; Duomenų failo atidarymas skaitymui
;*****************************************************
	Skaitymas:
	MOV ah, 3Dh; 21h pertraukimo failo atidarymo funkcijos numeris
	MOV al, 00; 00 - failas atidaromas skaitymui
	MOV dx, offset duom; vieta, kur nurodomas failo pavadinimas, pasibaigiantis nuliniu simboliu
	INT 21h; failas atidaromas skaitymui
	JC  KlaidaAtidarantSkaitymui; jei atidarant failą skaitymui įvyksta klaida, nustatomas carry flag
	MOV dFail, ax; atmintyje išsisaugom duomenų failo deskriptoriaus numerį

;*****************************************************
; Rezultato failo sukūrimas ir atidarymas rašymui
;*****************************************************
	MOV ah, 3Ch; 21h pertraukimo failo sukūrimo funkcijos numeris
	MOV cx, 0; kuriamo failo atributai
	MOV dx, offset rez; vieta, kur nurodomas failo pavadinimas, pasibaigiantis nuliniu simboliu
	INT 21h; sukuriamas failas; jei failas jau egzistuoja, visa jo informacija ištrinama
	JC  KlaidaAtidarantRasymui; jei kuriant failą skaitymui įvyksta klaida, nustatomas carry flag
	MOV rFail, ax; atmintyje išsisaugom rezultato failo deskriptoriaus numerį

;*****************************************************
; Duomenų nuskaitymas iš failo
;*****************************************************

	skaityk:
	MOV  bx, dFail; į bx įrašom duomenų failo deskriptoriaus numerį
	CALL SkaitykBuf; iškviečiame skaitymo iš failo procedūrą
	CMP  ax, 0; ax įrašoma, kiek baitų buvo nuskaityta, jeigu 0 - pasiekta failo pabaiga
	JE   uzdarytiRasymui

;*****************************************************
; Darbas su nuskaityta informacija
;*****************************************************
	MOV  nuskBaitu, ax
	MOV  cx, ax
	MOV  dx, 0
	MOV  si, offset skBuf
	MOV  di, offset raBuf

	Dirbk:
	MOV  ah, 0
	MOV  al, byte ptr [si]
	CALL Skaiciuok
	MOV  byte ptr[di], al
	INC  di
	MOV  byte ptr[di], ah
	INC  di
	MOV  byte ptr[di], ' '
	INC  di
	ADD  dx, 3
	INC  si
	LOOP Dirbk

;*****************************************************
;Rezultato įrašymas į failą
;*****************************************************
	MOV  cx, dx
	MOV  bx, rFail; į bx įrašom rezultato failo deskriptoriaus numerį
	CALL RasykBuf; iškviečiame rašymo į failą procedūrą
	CMP  nuskBaitu, skBufDydis; jeigu vyko darbas su pilnu buferiu -> iš duomenų failo buvo nuskaitytas pilnas buferis ->
	JE   Skaityk; -> reikia skaityti toliau

;*****************************************************
;Rezultato failo uždarymas
;*****************************************************

	UzdarytiRasymui:
	MOV ah, 3Eh; 21h pertraukimo failo uždarymo funkcijos numeris
	MOV bx, rFail; į bx įrašom rezultato failo deskriptoriaus numerį
	INT 21h; failo uždarymas
	JC  klaidaUzdarantRasymui; jei uždarant failą įvyksta klaida, nustatomas carry flag

;*****************************************************
;Duomenų failo uždarymas
;*****************************************************

	UzdarytiSkaitymui:
	MOV ah, 3Eh; 21h pertraukimo failo uždarymo funkcijos numeris
	MOV bx, dFail; į bx įrašom duomenų failo deskriptoriaus numerį
	INT 21h; failo uždarymas
	JC  KlaidaUzdarantSkaitymui; jei uždarant failą įvyksta klaida, nustatomas carry flag

	Pabaiga:
	MOV ah, 4Ch; reikalinga kiekvienos programos pabaigoj
	MOV al, 0; reikalinga kiekvienos programos pabaigoj
	INT 21h
	
;*****************************************************
;Žinutės
;*****************************************************

	KlaidaAtidarantSkaitymui:
	MOV ah, 09h
	MOV dx, offset dfZin
	INT 21h
	JMP Pabaiga

	KlaidaAtidarantRasymui:
	MOV ah, 09h
	MOV dx, offset rfZin
	INT 21h
	JMP Pabaiga

	KlaidaUzdarantSkaitymui:
	MOV ah, 09h
	MOV dx, offset dfZin
	INT 21h
	JMP Pabaiga

	KlaidaUzdarantRasymui:
	MOV ah, 09h
	MOV dx, offset rfZin
	INT 21h
	JMP Pabaiga

;*****************************************************
;Procedūros
;*****************************************************
PraleistiTarpus PROC
	PraleistiTarpa:
	CMP  byte ptr [es:bx], ' '
	JNE  PraleistiTarpusPabaiga
	INC  bx
	LOOP PraleistiTarpa
	PraleistiTarpusPabaiga:
	RET
PraleistiTarpus ENDP

NuskaitytiVarda PROC
	VardoSkaitymas:
	MOV al, [es:bx]
	MOV [di], al
	INC di
	INC bx
	DEC cx
	JZ  NuskaitytiVardaPabaiga
	CMP byte ptr [es:bx], ' '
	JNE VardoSkaitymas
	NuskaitytiVardaPabaiga:
	MOV byte ptr[di], 0
	RET
NuskaitytiVarda ENDP

Skaiciuok PROC
;į AX paduodamas skaičius
;į AH ir AL bus grąžintas šešioliktainis skaičius ASCII formatu (2 simboliai)
	SkaiciuokPradzia:
	PUSH cx

	MOV cl, 16; šešioliktainė
	DIV cl; {AX}:16 = AL(liek AH)

	CMP al, 9
	JA  DaugiauNei9_1
	ADD al, '0'
	JMP AntrasSkaitmuo

	DaugiauNei9_1:
	ADD al, 'a'-10

	AntrasSkaitmuo:
	CMP ah, 9
	JA  DaugiauNei9_2
	ADD ah, '0'
	JMP SkaiciuokPabaiga

	DaugiauNei9_2:
	ADD ah, 'a'-10

	SkaiciuokPabaiga:
	;Turime atstatyti išsaugotų registrų reikšmes
	POP     cx
	RET
Skaiciuok ENDP

;*****************************************************
;Procedūra nuskaitanti informaciją iš failo
;*****************************************************
PROC SkaitykBuf
;į BX paduodamas failo deskriptoriaus numeris
;į AX bus grąžinta, kiek simbolių nuskaityta
	PUSH	cx
	PUSH	dx
	
	MOV	ah, 3Fh			;21h pertraukimo duomenų nuskaitymo funkcijos numeris
	MOV	cx, skBufDydis		;cx - kiek baitų reikia nuskaityti iš failo
	MOV	dx, offset skBuf	;vieta, į kurią įrašoma nuskaityta informacija
	INT	21h			;skaitymas iš failo
	JC	klaidaSkaitant		;jei skaitant iš failo įvyksta klaida, nustatomas carry flag

  SkaitykBufPabaiga:
	POP	dx
	POP	cx
	RET

  klaidaSkaitant:
	;<klaidos pranešimo išvedimo kodas>
	MOV ax, 0			;Pažymime registre ax, kad nebuvo nuskaityta nė vieno simbolio
	JMP	SkaitykBufPabaiga
SkaitykBuf ENDP

;*****************************************************
;Procedūra, įrašanti buferį į failą
;*****************************************************
PROC RasykBuf
;į BX paduodamas failo deskriptoriaus numeris
;į CX - kiek baitų įrašyti
;į AX bus grąžinta, kiek baitų buvo įrašyta
	PUSH	dx
	
	MOV	ah, 40h			;21h pertraukimo duomenų įrašymo funkcijos numeris
	MOV	dx, offset raBuf	;vieta, iš kurios rašom į failą
	INT	21h			;rašymas į failą
	JC	klaidaRasant		;jei rašant į failą įvyksta klaida, nustatomas carry flag
	CMP	cx, ax			;jei cx nelygus ax, vadinasi buvo įrašyta tik dalis informacijos
	JNE	dalinisIrasymas

  RasykBufPabaiga:
	POP	dx
	RET

  dalinisIrasymas:
	;<klaidos pranešimo išvedimo kodas>
	JMP	RasykBufPabaiga
  klaidaRasant:
	;<klaidos pranešimo išvedimo kodas>
	MOV	ax, 0			;Pažymime registre ax, kad nebuvo įrašytas nė vienas simbolis
	JMP	RasykBufPabaiga
RasykBuf ENDP
END Pradzia