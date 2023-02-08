; JACKSBOY para la Flashjacks.
;
; Ultima version: 11-05-2020
;
;
;-----------------------------------------------------------------------------


;-----------------------------------------------------------------------------
;Constantes del entorno.

; IDE registers:

IDE_BANK	equ	#4104
IDE_DATA	equ	#7C00
IDE_STATUS	equ	#7E07
IDE_CMD		equ	#7E07
IDE_ERROR	equ	#7E01
IDE_FEAT	equ	#7E01
IDE_SECCNT	equ	#7E02
IDE_LBALOW	equ	#7E03
IDE_LBAMID	equ	#7E04
IDE_LBAHIGH	equ	#7E05
IDE_HEAD	equ	#7E06
IDE_DEVCTRL	equ	#7E0E	;Device control register. Reset IDE por bit 2.
FJ_TIMER1	equ	#7E0D	;Temporizador de 100khz(100uSeg.) por registro. Decrece de 1 en 1 hasta llegar a 00h.

FJ_VDP_INST	equ	#7E20	;Petición instrucción al VDP desde la Flashjacks. 
FJ_VDP_R36	equ	#7E21	;Registro 36 del VDP.Destino eje X."DX7..0"
FJ_VDP_R37	equ	#7E22	;Registro 37 del VDP.Destino eje X."0,0,0,0,0,0,0,DX8"
FJ_VDP_R38	equ	#7E23	;Registro 38 del VDP.Destino eje Y."DY7..0"
FJ_VDP_NBLOQ	equ	#7E24	;Número de bloques de 512bytes a transferir al VDP.
FJ_VDP_R40	equ	#7E25	;Registro 40 del VDP.Número píxeles eje X."NX7..0"
FJ_VDP_R41	equ	#7E26	;Registro 41 del VDP.Número píxeles eje X."0,0,0,0,0,0,0,NX8"
FJ_VDP_R42	equ	#7E27	;Registro 42 del VDP.Número píxeles eje Y."NY7..0"
FJ_VDP_R43	equ	#7E28	;Registro 43 del VDP.Número píxeles eje Y."0,0,0,0,0,0,0,NY8"
FJ_VDP_R32	equ	#7E29	;Registro 32 del VDP.Origen eje X."SX7..0"
FJ_VDP_R34	equ	#7E2A	;Registro 34 del VDP.Origen eje Y."SY7..0"
FJ_VDP_R35	equ	#7E2B	;Registro 35 del VDP.Origen eje Y."0,0,0,0,0,0,SY9,SY8"
FJ_VDP_R39	equ	#7E2C	;Registro 39 del VDP.Destino eje Y."0,0,0,0,0,0,DY9,DY8"
FJ_CLUSH_FB	equ	#7E2D	;Byte alto cluster archivo Flashboy.
FJ_CLUSL_FB	equ	#7E2E	;Byte bajo cluster archivo Flashboy
FLAGS_FB	equ	#7E2F	;Flags info Flashboy. (0,0,0,0,0,0,0,AccessRAM). "7..0"
FJ_TAM3_FB	equ	#7E30	;Byte alto3 tamaño archivo Flashboy.
FJ_TAM2_FB	equ	#7E31	;Byte alto2 tamaño archivo Flashboy.
FJ_TAM1_FB	equ	#7E32	;Byte alto1 tamaño archivo Flashboy.
FJ_TAM0_FB	equ	#7E33	;Byte bajo tamaño archivo Flashboy.
FJ_JOY_1	equ	#7E34	;Registro de salida Joy_Status1
FJ_JOY_2	equ	#7E35	;Registro de salida Joy_Status2
FJ_JOY_3	equ	#7E36	;Registro de salida Joy_Status3
FJ_JOY_4	equ	#7E37	;Registro de salida Joy_Status4

; Bits in the status register

BSY	equ	7	;Busy
DRDY	equ	6	;Device ready
DF	equ	5	;Device fault
DRQ	equ	3	;Data request
ERR	equ	0	;Error

M_BSY	equ	(1 SHL BSY)
M_DRDY	equ	(1 SHL DRDY)
M_DF	equ	(1 SHL DF)
M_DRQ	equ	(1 SHL DRQ)
M_ERR	equ	(1 SHL ERR)

; Bits in the device control register register

SRST	equ	2	;Software reset
M_SRST	equ	(1 SHL SRST)

; Standard BIOS and work area entries
CLS	equ	000C3h
CHSNS	equ	0009Ch
KILBUF	equ	00156h
VDP	equ	0F3DFh

; Varios
CALSLT  equ     0001Ch
BDOS	equ	00005h
RDSLT	equ	0000Ch
WRSLT	equ	00014h
ENASLT	equ	00024h
FCB	equ	0005ch
DMA	equ	00080h
RSLREG	equ	00138h
SNSMAT	equ	00141h
RAMAD1	equ	0f342h
RAMAD2	equ	0f343h
LOCATE	equ	0f3DCh
CHGET	equ	0009fh
POSIT	equ	000C6h
MNROM	equ	0FCC1h	; Main-ROM Slot number & Secondary slot flags table
DRVINV	equ	0FB22H	; Installed Disk-ROM

;Fin de las constantes del entorno.
;-----------------------------------------------------------------------------

;-----------------------------------------------------------------------------
; Macros:

;-----------------------------------------------------------------------------
;
; Enable or disable the IDE registers

;Note that bank 7 (the driver code bank) must be kept switched
;Cuidado. Cuando se cambia de IDE ON a OFF y viceversa, el mapper permanece inalterado.
;Cuando está en IDE_OFF, la siguiente vez permite cambiar de mapper.
;Así que no hacer dos IDE_OFF seguidos ya que el segundo IDE_OFF atacará a la página del mapper con valor cero en este caso.


macro	IDE_ON
	ld	a,1
	ld	(IDE_BANK),a
endmacro

macro	IDE_OFF
	ld	a,0
	ld	(IDE_BANK),a
endmacro

;-----------------------------------------------------------------------------
;
; Comprobación de que la unidad y los datos SD están disponibles.
macro ideready

.iderready:	
	ld	a,(IDE_STATUS)
	bit	BSY,a
	jp	nz,.iderready ; Hace una comprobación al inicio y deja paso cuando la FLASHJACKS informa que puede continuar.
	ld	hl, IDE_DATA
endmacro

;-----------------------------------------------------------------------------
;
; Envía al puerto de salida HL e incrementa su puntero.
macro outi_1
	;ld	a,(hl)
	;ld	a,30
	;out	(c),a
	;inc	hl
	outi
endmacro

macro outi_2
	outi_1
	outi_1
endmacro

macro outi_3
	outi_1
	outi_1
	outi_1
endmacro

macro outi_4
	outi_1
	outi_1
	outi_1
	outi_1
endmacro

macro outi_7
	outi_1
	outi_1
	outi_1
	outi_1
	outi_1
	outi_1
	outi_1
endmacro

macro outi_8
	outi_1
	outi_1
	outi_1
	outi_1
	outi_1
	outi_1
	outi_1
	outi_1
endmacro

macro outi_10
	outi_1
	outi_1
	outi_1
	outi_1
	outi_1
	outi_1
	outi_1
	outi_1
	outi_1
	outi_1
endmacro

macro outi_11
	outi_1
	outi_1
	outi_1
	outi_1
	outi_1
	outi_1
	outi_1
	outi_1
	outi_1
	outi_1
	outi_1
endmacro

macro outi_100
	outi_10
	outi_10
	outi_10
	outi_10
	outi_10
	outi_10
	outi_10
	outi_10
	outi_10
	outi_10
endmacro

macro outi_511
	outi_100
	outi_100
	outi_100
	outi_100
	outi_100
	outi_10
	outi_1
endmacro

macro outi_512
	outi_100
	outi_100
	outi_100
	outi_100
	outi_100
	outi_10
	outi_1
	outi_1
endmacro




;-----------------------------------------------------------------------------
;
; Fin de las macros.
;
;------------------------------------------------------------------------------
	

;------------------------------------------------------------------------------
;
; bytes de opciones:
;
;  options:                            options2:
;
;      bit0 -> no usado		           bit0 -> loop mode ON
;      bit1 -> no usado                    bit1 -> reproduccion abortada
;      bit2 -> no usado			   bit2 -> Test VDP<->FJ
;      bit3 -> no usado		  	   bit3 -> PassVideo VDP<->FJ
;      bit4 -> no usado			   bit4 -> Background
;      bit5 -> no usado	                   bit5 -> Jacksboy
;      bit6 -> no usado	                   bit6 -> no usado
;      bit7 -> no usado	                   bit7 -> no usado
;
;------------------------------------------------------------------------------


;-----------------------------------------------------------------------------
;-----------------------------------------------------------------------------
; Programa principal:

	org	0100h

	jp	inicio

textointro:
	db	"                     JacksBoy para Flashjacks ver 1.00", 13, 10
	db	"           Sintesis de un sistema de 8bits dentro de otro de 8bits", 13, 10
	db	13,10,"$"

txtROM:	
	db	"Cargando ROM....",13,10,"$"

txtRAM:	
	db	"Cargando SRAM....",13,10,"$"

txtBootROM:
	db	"Cargando BootROM....",13,10,"$"

txtSRAM:	
	db	"Salvando SRAM....",13,10,"$"

txtEnter:
	db	13,10,"$"



textonot:
	db	"                     JacksBoy para Flashjacks ver 1.00", 13,10
	db	"           Sintesis de un sistema de 8bits dentro de otro de 8bits", 13,10
	db	13,10
	db	"Notas del autor:",13,10
	db	13,10
	db	" JACKSBOY es un sistema sintetizado para cargar software homebrew y libre.",13,10
	db	"No contiene marcas propietarias de ningun tipo. Parte de una idea libre.",13,10
	db	"Proyectado como demostracion de la potencia de la FJ. Dos CPUs trabajando en ",13,10
	db	"paralelo, compartiendo recursos como el VDP, RAM, teclado, audio, etc...",13,10
	db	13,10
	db	"Este sistema utiliza la CPU del Z80 para gestion y control del MSX, contando",13,10
	db	"con una segunda CPU variable hasta 8Mhz para el core de la JACKSBOY.",13,10
	db	"Compatible con sistemas monocromo y color.",13,10
	db	13,10
	db	"Espero que lo disfruteis tanto como yo en las largas horas proyectando tan ",13,10
	db	"singular sistema.",13,10
	db	13,10
	db	"                                                            AQUIJACKS",13,10
	db	#1A,"$"

textoini:
	db	"                     JacksBoy para Flashjacks ver 1.00", 13,10
	db	"           Sintesis de un sistema de 8bits dentro de otro de 8bits", 13,10
fintextoini:	db	13,10
	db	"Modo de uso: JACKSBOY [path] boyfile.gb* [opciones]",13,10
	db	13,10
	db	"Opciones:",13,10
	db	" /T -> Test VDP                         /V -> Test virtual VRAM FJ",13,10
	db	" /G -> Jacksboy                         /H -> Notas del autor   ",13,10
	db	" /B archivo -> Carga un archivo imagen de fondo (.SCC)",13,10
	db	13,10
	db	"Teclas configuradas:",13,10
	db	"Arriba   --> Joy/Cursor Arriba  Tecla Q | Abajo   --> Joy/Cursor Abajo  Tecla A",13,10
	db	"Izquierda--> Joy/Cursor Izq     Tecla O | Derecha --> Joy/Cursor Der    Tecla P",13,10
	db	"Boton A  --> Tecla Espacio,C    Joy A/C | Boton B --> Tecla RET,GRPH,V    Joy B",13,10
	db	"Select   --> Tecla F1,Z         Joy X   | Start   --> Tecla F2,X    Joy Y/START",13,10
	db	"NormalCPU--> Tecla F3                   | MidCPU  --> Tecla F4",13,10
	db	"FastCPU  --> Tecla F5                   ",13,10
	db	13,10
	db	"Optimizado para Joymega en el puerto 1 del Joystick. ",13,10
	db	"Carga y salva partidas autodetectable en archivos .RAM",13,10
	db	"Es necesario el BOY_BIOS.BIN en el directorio raiz.",13,10
	db	"RAM compartida. Con 128k internos, desactiva de la FJ para mayor velocidad.",13,10
	db	#1A,"$"

inicio:
	ld	sp, (#0006)
	ld	a, (DMA)	
	or	a	
	jp	nz, readline	;Si encuentra parámetros continua.

muestratexto:			;Sin parámetros muestra el texto explicativo y sale.
	; Hace un clear Screen o CLS.
	xor    a		; Pone a cero el flag Z.
	ld     ix, CLS          ; Petición de la rutina BIOS. En este caso CLS (Clear Screen).
	ld     iy,(MNROM)       ; BIOS slot
        call   CALSLT           ; Llamada al interslot. Es necesario hacerlo así en MSXDOS para llamadas a BIOS.
	; Averigua si es MSX-DOS2.
	XOR	A
	LD	DE,#0402
	CALL	#FFCA
	OR	A
	JP	Z,error11	;Para comprobar si realmente tienes las tablas.

	; Si es MSX-DOS2 activa las subrutinas de MSX-DOS2.
	;call Enable_MSX22

	; Saca el texto de ayuda.
	ld	de, textoini	;Fija el puntero en el texto de ayuda.
	ld	c, 9
	call	BDOS		;Imprime por pantalla el texto.
	rst	0		;Salida al MSXDOS.

notastexto:			; Muestra el texto de notas del autor.
	; Hace un clear Screen o CLS.
	xor    a		; Pone a cero el flag Z.
	ld     ix, CLS          ; Petición de la rutina BIOS. En este caso CLS (Clear Screen).
	ld     iy,(MNROM)       ; BIOS slot
        call   CALSLT           ; Llamada al interslot. Es necesario hacerlo así en MSXDOS para llamadas a BIOS.
	; Averigua si es MSX-DOS2.
	XOR	A
	LD	DE,#0402
	CALL	#FFCA
	OR	A
	JP	Z,error11	;Para comprobar si realmente tienes las tablas.

	; Si es MSX-DOS2 activa las subrutinas de MSX-DOS2.
	;call Enable_MSX22

	; Saca el texto de ayuda.
	ld	de, textonot	;Fija el puntero en el texto de notas.
	ld	c, 9
	call	BDOS		;Imprime por pantalla el texto.
	rst	0		;Salida al MSXDOS.

readline:
	xor	a		;Comprueba si es un Turbo-R.
	ld	hl, #002D	;Pide de la BIOS MSXVER
	rst	#30
	db	0
	dw	#000C
	di
	cp	0
	jp	z, error10	;Si es un MSX1 te echa fuera del programa.
	ei
	ld	hl, #0082	;Extrae parametros de la linea de comandos.
	ld	de, filename
	call	saltaspacio	;Salta todos los espacios encontrados.
	jp	c, muestratexto ;Si no hay nombre de archivo ejecuta salir al MSXDOS.
	cp	"/"
	jp	z, leeoptions2  ;Si hay barra y no nombre de archivo ejecuta las opciones .

leefilename:	
	ldi
	ld	a, (hl)
	cp	" "
	jp	z, leeoptions	;Lee las opciones si encuentra la barra espacio.
	jp	c, abre		;Va a operación de abrir archivo si no encuentra opciones. Programa secundario.
	jp	leefilename	;Bucle lectura nombre de archivo.

leeoptions:
	call	saltaspacio	;Salta todos los espacios encontrados.
	ld	a, (hl)
	cp	"/"
	jp	nz, abre	;Si no encuentra una barra abre archivo. Programa secundario.
	inc	hl
	ld	a, (hl)
	cp	" "
	jp	z, muestratexto
	jp	c, muestratexto ;Si es una barra con un espacio muestra el texto de opciones y fin.
	or	#20		;Pasa de si es mayusculas o minusculas.
	ld	b, %100		;Selecciona la marca del bit a guardar.
	cp	"t"		
	jp	z, setoption2	;Si es una t guarda el valor en variale options
	ld	b, %1000	;Selecciona la marca del bit a guardar.
	cp	"v"		
	jp	z, setoption2	;Si es una v guarda el valor en variale options
	ld	b, %100000	;Selecciona la marca del bit a guardar.
	cp	"g"		
	jp	z, setoption2	;Si es una v guarda el valor en variale options
	cp	"h"		
	jp	z, notastexto	;Si es una h saca las notas y el acerca de.
	cp	"b"
	jp	z, setback	;Si es una b va al bucle de lectura nombre archivo .SCC . Llamada a subproceso.

	jp	muestratexto	;Si es cualquier otra opción muestra el texto de opciones y fin.

leeoptions2:
	call	saltaspacio	;Salta todos los espacios encontrados.
	ld	a, (hl)
	cp	"/"
	jp	nz, muestratexto;Si no encuentra una barra muestra el texto de opciones y fin.
	inc	hl
	ld	a, (hl)
	cp	" "
	jp	z, muestratexto
	jp	c, muestratexto ;Si es una barra con un espacio muestra el texto de opciones y fin.
	or	#20		;Pasa de si es mayusculas o minusculas.
	cp	"h"		
	jp	z, notastexto	;Si es una h saca las notas y el acerca de.
	
	jp	muestratexto	;Si es cualquier otra opción muestra el texto de opciones y fin.

;Fin del programa principal.
;-----------------------------------------------------------------------------

;-----------------------------------------------------------------------------	
;Subprocesos del programa principal:

;Almacena variable en options.
setoption:			
	ld	a, (options)
	or	b
	ld	(options), a
	inc	hl
	jp	leeoptions	;Vuelve al bucle principal.

;Almacena variable en options2.
setoption2:
	ld	a, (options2)	
	or	b
	ld	(options2), a
	inc	hl
	jp	leeoptions	;Vuelve al programa principal.

;Bucle de lectura nombre archivo .SCC
setback:			
	inc	hl
	ld	a, (hl)
	cp	" "
	jp	nz, muestratexto;Si encuentra un espacio en lugar del nombre archivo va a muestra el texto de opciones y fin.
	call	saltaspacio	;Salta todos los espacios encontrados.
	cp	"/"
	jp	z, muestratexto	;Si encuentra una barra de opciones en lugar del nombre archivo va a muestra el texto de opciones y fin.
	ld	de, backfile	;Carga variable nombre del archivo .SCC
leefile2:	
	ldi
	ld	a, (hl)
	cp	" "
	jp	nz, leefile2	;hace la lectura hasta encontrar barra de espacio.

	ld	a, (options2)
	or	%10000
	ld	(options2), a	;Guarda una marca de Background en options2.

	xor	a
	ld	(de), a		;Pone un cero al final de la variable nombre del archivo .SCC

	jp	leeoptions	;Vuelve al programa principal.

;Fin de los subprocesos del programa principal.
;-----------------------------------------------------------------------------


; Fin del programa principal.
;
;-----------------------------------------------------------------------------
;-----------------------------------------------------------------------------


;-----------------------------------------------------------------------------
;
; Programa secundario. Fase de apertura del archivo ya con todas la opciones definidas.
; 

abre:	
	; Cargar archivo en FIB
	ld	de, filename	;Obtiene el File Info Block del
	ld	b, 0		;fichero.
	ld	hl, 0
	ld	ix, FIB
	ld	c, #40
	call	BDOS
	or	a
	jp	nz, error2	;Salta si error del archivo no se puede abrir.	

	ld	a, (options2)	;Salta a passvideo Test VDP <-> FJ si es la opción seleccionada .
	and	%1000
	jp	nz, searchslot	;No es necesario abrir el archivo.

	ld	a, (options2)	;Salta a en modo VDP pruebas si es la opción seleccionada .
	and	%100
	jp	nz, searchslot	;No es necesario abrir el archivo.


; Transfiere filename a fileram cambiandole la extensión a .RAM
TransfileRAM:			
	ld	c, 9
	ld	hl, filename	;Nombre archivo ROM inicial
	ld	de, fileram	;Nombre archivo con extensión RAM.
	ld	a,(hl)
	ld	(de),a
Trfil_0:
	inc	hl
	inc	de
	dec	c
	ld	a,(hl)
	cp	02Eh		; Mira si hay un punto para tratarlo como extensión.
	jp	z, Trfil_2
	cp	" "
	jp	z, Trfil_1
	ld	(de),a
	ld	a,c
	cp	0
	jp	z, Trfil_1
	jp	Trfil_0
Trfil_1:			; Si ha acabado los 8 carácteres del nombre o es un espacio va a insertar el punto + extensión
	ld	a,02Eh
Trfil_2:			; Si encuentra el punto inserta la extensión. 
	ld	(de),a
	inc	de
	ld	a,"R"
	ld	(de),a
	inc	de
	ld	a,"A"
	ld	(de),a
	inc	de
	ld	a,"M"
	ld	(de),a
Trfil_3:			; Rellena el resto con espacios.
	inc	de
	dec	c
	xor	a		; Lo que queda despues debe valer cero.
	ld	(de),a
	ld	a,c
	cp	0
	jp	nz, Trfil_3


; Busca la unidad Flashjacks en el sistema
searchslot:
	ld	a, (FIB+25)	;Averigua la unidad lógica actual.
	ld	b, a		
	ld	d, #FF		
	ld	c, #6A		
	call	BDOS
	
	ld	a, d
	dec	a		;Le resta 1 ya que el cero cuenta.
	ld	(unidad), a	;Guarda el número de unidad lógica de acceso.
		
	ld	hl, #FB21	;Mira el número de unidades conectado en la interfaz de disco 1.	
	cp	(hl)		
	jp	c, tipodisp	;Si coincide selecciona esta unidad y va a tipo de dispositivo.
	sub	a, (hl)
	inc	hl
	inc	hl		;Mira el número de unidades conectado en la interfaz de disco 2.
	cp	(hl)
	jp	c, tipodisp	;Si coincide selecciona esta unidad y va a tipo de dispositivo.
	sub	a, (hl)
	inc	hl
	inc	hl		;Mira el número de unidades conectado en la interfaz de disco 3.
	cp	(hl)
	jp	c, tipodisp	;Si coincide selecciona esta unidad y va a tipo de dispositivo.
	sub	a, (hl)
	inc	hl
	inc	hl		;Mira el número de unidades conectado en la interfaz de disco 4.
tipodisp:
	inc	hl		;Va al slot address disk de la unidad seleccionada.
	ld	(unidad), a	;Guarda el número de unidad lógica de acceso.
	ld	a, (hl)
	ld	(slotide), a	;Guarda en slotide la dirección de esa unidad.
	
	di
	ld	hl,4000h
	call	ENASLT

;Detección de la Flashjacks

	;ld	a,(slotide)	
	;ld	hl,5FFEh
	;ld	e,019h
	;call	WRSLT
	
	ld	a,019h		; Carga en un posible FMPAC el modo recepción instrucciones EPROM.
	ld	(5FFEh),a
	
	ld	a,076h
	ld	(5FFFh),a

	ld	a,(4000h)	; Hace una lectura para tirar cualquier intento pasado de petición.
	
	ld	a,0aah
	ld	(4340h),a	; Petición acceso comandos FlashJacks. 
	ld	a,055h
	ld	(43FFh),a	; Autoselect acceso comandos FlashJacks. 
	ld	a,020h
	ld	(4340h),a	; Petición código de verificación de FlashJacks

	ld	b,16
	ld	hl,4100h	; Se ubica en la dirección 4100h (Es donde se encuentra la marca de 4bytes de FlashJacks)
RDID_BCL:
	ld	a,(hl)		; (HL) = Primer byte info FlashJacks
	cp	057h		; El primer byte debe ser 57h.
	jp	z,ID_2
	ld	a,000h		; Descarga en un posible FMPAC el modo recepción instrucciones EPROM.
	ld	(5FFEh),a
	ld	a,000h
	ld	(5FFFh),a
	ei			; Activa interrupciones.
	jp	error1		; Salta a error1 sin cierre de fichero(no lo ha abierto) si no es una Flashjacks.

ID_2:	inc	hl
	ld	a,(hl)		; (HL) = Segundo byte info FlashJacks
	cp	071h		; El segundo byte debe ser 71h.
	jp	z,ID_3
	ld	a,000h		; Descarga en un posible FMPAC el modo recepción instrucciones EPROM.
	ld	(5FFEh),a
	ld	a,000h
	ld	(5FFFh),a
	ei			; Activa interrupciones.
	jp	error1		; Salta a error1 sin cierre de fichero(no lo ha abierto) si no es una Flashjacks.

ID_3:	inc	hl
	ld	a,(hl)		; (HL) = Tercer byte info FlashJacks
	cp	098h		; El tercer byte debe ser 98h.
	jp	z,ID_4
	ld	a,000h		; Descarga en un posible FMPAC el modo recepción instrucciones EPROM.
	ld	(5FFEh),a
	ld	a,000h
	ld	(5FFFh),a
	ei			; Activa interrupciones.
	jp	error1		; Salta a error1 sin cierre de fichero(no lo ha abierto) si no es una Flashjacks.

ID_4:	inc	hl
	ld	a,(hl)		; (HL) = Cuarto byte info FlashJacks
	cp	022h		; El cuarto byte debe ser 22h.

	jp	z,ID_OK		; Salta si da todo OK.
	
	ld	a,000h		; Descarga en un posible FMPAC el modo recepción instrucciones EPROM.
	ld	(5FFEh),a
	ld	a,000h
	ld	(5FFFh),a
	ei			; Activa interrupciones.
	jp	error1		; Salta a error1 sin cierre de fichero(no lo ha abierto) si no es una Flashjacks.

ID_OK:	inc	hl
	ld	a,(hl)		; Al incrementar a 104h sale del modo info FlashJacks
	ld	a,000h		; Descarga en un posible FMPAC el modo recepción instrucciones EPROM.
	ld	(5FFEh),a
	ld	a,000h
	ld	(5FFFh),a
	ei
	
	; Hace un clear Screen o CLS.
	xor    a		; Pone a cero el flag Z.
	ld     ix, CLS          ; Petición de la rutina BIOS. En este caso CLS (Clear Screen).
	ld     iy,(MNROM)       ; BIOS slot
        call   CALSLT           ; Llamada al interslot. Es necesario hacerlo así en MSXDOS para llamadas a BIOS.	

	ld	a, (options2)	;Salta a passvideo Test VDP <-> FJ si es la opción seleccionada .
	and	%1000
	jp	nz, VideoIn	;No es necesario abrir archivos.

	ld	a, (options2)	;Salta a en modo VDP pruebas si es la opción seleccionada .
	and	%100
	jp	nz, VideoIn	;No es necesario abrir archivos.
	
	
	ld	de, textointro	;Fija el puntero en el texto de intro.
	ld	c, 9
	call	BDOS
	
	ld	de, txtROM	;Fija el puntero en el texto de cargar ROM.
	ld	c, 9
	call	BDOS
		
	di
	IDE_ON
	ideready

	ld	a,050h		;Resetea estados de variables en FJ.
	ld	(IDE_CMD),a

	ideready

	; Cargar ROM en Flashjacks.	
	ld	a, (FIB+19)	;Top Cluster archivo abierto. Alto.
	ld	(FJ_CLUSH_FB),a	;Ingresa la dirección cluster el archivo. Alto. 
	ld	a, (FIB+20)	;Top Cluster archivo abierto. Bajo.
	ld	(FJ_CLUSL_FB),a	;Ingresa la dirección cluster el archivo. Bajo. 
	ld	a, (FIB+21)	;Tamaño archivo abierto. Alto3.
	ld	(FJ_TAM3_FB),a	;Ingresa el tamaño del archivo. Alto3. 
	ld	a, (FIB+22)	;Tamaño archivo abierto. Alto2.
	ld	(FJ_TAM2_FB),a	;Ingresa el tamaño del archivo. Alto2. 
	ld	a, (FIB+23)	;Tamaño archivo abierto. Alto1.
	ld	(FJ_TAM1_FB),a	;Ingresa el tamaño del archivo. Alto1. 
	ld	a, (FIB+24)	;Tamaño archivo abierto. Bajo.
	ld	(FJ_TAM0_FB),a	;Ingresa el tamaño del archivo. Bajo. 

	ld	a,043h		;Carga ROM.
	ld	(IDE_CMD),a

	ideready		; Hasta que no termina la carga no avanza.
	
	IDE_OFF
	ei

	; Cargar archivo RAM en FIB
	ld	de, fileram	;Obtiene el File Info Block del
	ld	b, 0		;fichero.
	ld	hl, 0
	ld	ix, FIB
	ld	c, #40
	call	BDOS
	or	a
	jp	nz, AlBootROM	;Salta si error del archivo no se puede abrir.	

	ld	de, txtRAM	;Fija el puntero en el texto de cargar RAM.
	ld	c, 9
	call	BDOS

	di
	IDE_ON
	ideready

	; Cargar RAM en Flashjacks.	
	ld	a, (FIB+19)	;Top Cluster archivo abierto. Alto.
	ld	(FJ_CLUSH_FB),a	;Ingresa la dirección cluster el archivo. Alto. 
	ld	a, (FIB+20)	;Top Cluster archivo abierto. Bajo.
	ld	(FJ_CLUSL_FB),a	;Ingresa la dirección cluster el archivo. Bajo. 
	ld	a, (FIB+21)	;Tamaño archivo abierto. Alto3.
	ld	(FJ_TAM3_FB),a	;Ingresa el tamaño del archivo. Alto3. 
	ld	a, (FIB+22)	;Tamaño archivo abierto. Alto2.
	ld	(FJ_TAM2_FB),a	;Ingresa el tamaño del archivo. Alto2. 
	ld	a, (FIB+23)	;Tamaño archivo abierto. Alto1.
	ld	(FJ_TAM1_FB),a	;Ingresa el tamaño del archivo. Alto1. 
	ld	a, (FIB+24)	;Tamaño archivo abierto. Bajo.
	ld	(FJ_TAM0_FB),a	;Ingresa el tamaño del archivo. Bajo. 

	ld	a,044h		;Carga RAM.
	ld	(IDE_CMD),a

	ideready		; Hasta que no termina la carga no avanza.

AlBootROM:

	IDE_OFF
	ei

	; Cargar archivo BootROM en FIB
	ld	de, fileboot	;Obtiene el File Info Block del
	ld	b, 0		;fichero.
	ld	hl, 0
	ld	ix, FIB
	ld	c, #40
	call	BDOS
	or	a
	jp	nz, error8	;Salta si error del archivo no se puede abrir.	

	ld	de, txtBootROM	;Fija el puntero en el texto de cargar BootROM.
	ld	c, 9
	call	BDOS

	di
	IDE_ON
	ideready

	; Cargar BootROM en Flashjacks.	
	ld	a, (FIB+19)	;Top Cluster archivo abierto. Alto.
	ld	(FJ_CLUSH_FB),a	;Ingresa la dirección cluster el archivo. Alto. 
	ld	a, (FIB+20)	;Top Cluster archivo abierto. Bajo.
	ld	(FJ_CLUSL_FB),a	;Ingresa la dirección cluster el archivo. Bajo. 
	ld	a, (FIB+21)	;Tamaño archivo abierto. Alto3.
	ld	(FJ_TAM3_FB),a	;Ingresa el tamaño del archivo. Alto3. 
	ld	a, (FIB+22)	;Tamaño archivo abierto. Alto2.
	ld	(FJ_TAM2_FB),a	;Ingresa el tamaño del archivo. Alto2. 
	ld	a, (FIB+23)	;Tamaño archivo abierto. Alto1.
	ld	(FJ_TAM1_FB),a	;Ingresa el tamaño del archivo. Alto1. 
	ld	a, (FIB+24)	;Tamaño archivo abierto. Bajo.
	ld	(FJ_TAM0_FB),a	;Ingresa el tamaño del archivo. Bajo. 

	ld	a,046h		;Carga BootROM.
	ld	(IDE_CMD),a

	ideready		; Hasta que no termina la carga no avanza.

	IDE_OFF
	ei

	
	;Fin de la detección de la Flashjacks. Si sigue por aquí es que ha detectado una Flashjacks

;---------------------------------------------------------------------------
; Subprograma Formato VideoIn desde la Flashjacks

VideoIn:
	
	xor	a		;Comprueba si es un Turbo-R.
	ld	hl, #002D	;Pide de la BIOS MSXVER
	rst	#30
	db	0
	dw	#000C
	di
	cp	0
	jp	z, error10	;Si es un MSX1 te echa fuera del programa.
	cp	3		;Un 3 es un MSX Turbo R.
	jp	z, msxturbor2	;si es un TurboR salta a msxturbor.
	
	;Configuración del MSX2Plus.

	ld	a, #FF
	ld	(modor800), a	;La variable modor800 la deja todo a 1. Fuera de servicio.
	
	ld	a, 8		;Vuelca a la variable Z80B una posible configuración de un turbo A1-WX's.
	out	(#40), a
	in	a, (#41)
	ld	(Z80B), a	

	ld	a, 8
	out	(#40), a
	ld	a, 1		;Set Z80-B 3,57Mhz. En todos los casos.
	out	(#41), a

	jp	VideoInVDP	;Va al retorno del programa principal.
	
	;Fin configuración del MSX2Plus.
		
	;Configuración del MSX TurboR.  
	
msxturbor2:	
	rst	#30		;Guarda en modor800 como viene configurado para restaurarlo a posterior.
	db	0
	dw	#183		;GETCPU mismo config que CHGCPU.
	ld	(modor800),a	;Lo guarda en la variable.
		
	ld	a, #80		;Cambia a modo Z80. Fuerza el sistema en Z80. (R800 incompatible).
	rst	#30
	db	0
	dw	#180		;CHGCPU mismo config que GETCPU. 

	;Fin configuración del MSX TurboR.

	;Configuración de la pantalla.
	
VideoInVDP:	
	ld	a, 8		;Pasa a Screen 8
	rst	#30
	db	0
	dw	005FH

	di			
	in	a, (#99)	;Color bordes=0.
	ld	a, 0
	out	(#99), a
	ld	a, 128+7
	out	(#99), a

	ld	a, (#F3E0)	;Desactiva la pantalla.
	and	%10111111	;Screen OFF.
	out	(#99), a
	ld	a, 128+1
	out	(#99), a

	ld	a, 00001010b	;Sprites OFF. 
	out	(#99), a
	ld	a, 8+128
	out	(#99), a

	ld	a, (options2)	;Si hay carga de fondo de pantalla ejecuta subproceso loadback.
	and	%10000
	jp	nz, loadback

	ld	a, 36		;Si no borra la pantalla entera mediante un CLS.
	out	(#99), a
	ld	a, 17+80H
	out	(#99), a
	ld	hl, HMMV
	ld	b, 11
	ld	c, #9b
	otir
waitvdp2:
	ld	a, 2		;Espera a que el comando CLS acabe.
	out	(#99), a
	ld	a, 128+15
	out	(#99), a
	in	a, (#99)
	and	1
	jp	nz, waitvdp2	;Bucle de espera hasta que la función CLS finalice.
	xor	a
	out	(#99), a
	ld	a, 128+15
	out	(#99), a
retloadb:
	ld	a, (#FFE8)	; 60 Hz
	and	%01110101
	or	%00000000	; Non interlaced. Vertical 192.
	out	(#99), a
	ld	a, 128+9
	out	(#99), a

	ld	a, (#F3DF)	;
	or	%00000000	;
	and	%10001111	;Disable all interrupt.
	out	(#99), a
	ld	a, 128+0
	out	(#99), a
	
	
	ld	a, (#F3E0)	;Activa la pantalla.
	or	%01000000	;Screen ON.
	and	%11011100	;Disable interrupt vertical retrace. Sprite 8x8. Normal sprite.
	out	(#99), a
	ld	a, 128+1
	out	(#99), a

	; Prepara los registros HMMC comunes con los valores perpetuos.
	xor	a		; Valor cero.
	out	(#99), a	
	ld	a, 33+80H	;Registro R#33 SX8. Siempre a cero.	
	out	(#99), a
	
	xor	a		; Valor cero.
	out	(#99), a	
	ld	a, 37+80H	;Registro R#37 DX8. Siempre a cero.	
	out	(#99), a

	;ld	a,(FJ_VDP_R39)
	ld	a, 1		;La primera vez empieza por el registro 1 ya que se va a visualizar el 0.
	ld	(pagvram2),a	;Envia el comando al VDP. Registro R#39 del VDP.
	out	(#99), a	
	ld	a, 39+80H	;Registro R#39 NY8-9. Cambio de página.	
	out	(#99), a

	ld	a,20H		;Envia el comando al VDP. Registro R#40 del VDP. 32 Píxeles.
	out	(#99), a	
	ld	a, 40+80H	;Registro R#40. Número píxeles eje X.
	out	(#99), a

	xor	a		; Valor cero.
	out	(#99), a	
	ld	a, 41+80H	;Registro R#41 NX-8. Siempre a cero.	
	out	(#99), a

	ld	a,10H		;Envia el comando al VDP. Registro R#42 del VDP. 16 Píxeles.
	out	(#99), a	
	ld	a, 42+80H	;Registro R#42. Número píxeles eje Y.
	out	(#99), a
	
	xor	a		; Valor cero.
	out	(#99), a	
	ld	a, 43+80H	;Registro R#43 NY8-9. Siempre a cero.	
	out	(#99), a

	ld	a,00h		;Envia el comando al VDP. Registro R#45 del VDP.
	out	(#99), a	
	ld	a, 45+80H	;Registro R#45 NY8-9. Siempre a cero. Configura sentido derecha inferior en VRAM.	
	out	(#99), a

	ld	a, 44+80H	;Carga el contador 44 al registro 17. (Empezará en acceso indirecto por R44)
	out	(#99), a	; El 80 anterior hace que el bit 7 esté a 1 desactivando el autoincremental.
	ld	a, 17+80H	;Registro R#17 del VDP.Bit 7 siempre a 1 =80 + R	
	out	(#99), a

reload_Video:

	di
	IDE_ON			;Activa la unidad IDE.
	ideready		;Espera a que la FJ esté disponible.

	ld	c, #9B		;Carga el puerto 9b para el envío indirecto.

	ld	a,0
	ld	(MultiVDP),a

	xor	a
	ld	(FJ_VDP_INST),a	;Borra petición instrucción al VDP desde la Flashjacks. 

	ld	a, (options2)	;Salta a passvideo Test VDP <-> FJ si es la opción seleccionada .
	and	%1000
	jp	nz, VideoInA

	ld	a, (options2)	;Salta a en modo VDP pruebas si es la opción seleccionada .
	and	%100
	jp	nz, VideoInP
	
VideoInC:	
	ld	a,042h		;Poner la FJ-SD en modo VDP PassVideo Gameboy.
	ld	(IDE_CMD),a
	jp	VideoInB

VideoInP:	
	ld	a,040h		;Poner la FJ-SD en modo VDP pruebas.
	ld	(IDE_CMD),a
	jp	VideoInB

VideoInA:	
	ld	a,041h		;Poner la FJ-SD en modo VDP PassVideo Test.
	ld	(IDE_CMD),a	

VideoInB:
	ideready		;Espera a que la FJ esté disponible.

	ld	a, #F7		;Establece la fila 7 de la matriz del teclado en el PPI.
	out	(#AA), a

	;---
	; Bucle en espera de instrucciones de la Flashjacks.

VideoIn2:
	ld	a,(FJ_VDP_INST)	;Petición instrucción al VDP desde la Flashjacks. 
	cp	0FFh		;Si hay un reset en curso, pausa la aplicación.
	jp	z,VideoIn3
	
	ld	a,(MultiVDP)	;Si hay petición en curso HMMM salta a posible escritura directa de datos.
	cp	01h
	jp	z,VideoIn2a

	ld	a,(FJ_VDP_INST)	;Petición instrucción al VDP desde la Flashjacks. 
	cp	01h		;Si es petición de gestión de cuadros 512bytes va a VideoHMMC.
	jp	z,VideoHMMC
	jp	VideoIn2b

VideoIn2a:
	ld	a,(FJ_VDP_INST)	;Petición instrucción al VDP desde la Flashjacks. 
	cp	01h		;Si es petición de gestión de cuadros 512bytes va a VideoDirect.
	jp	z,VideoDirect

VideoIn2b:
	cp	03h		;Si es petición de copia de cuadros 512bytes entre VRAM va a VideoHMMM.	
	jp	z,VideoHMMM	

	cp	02h
	jp	z,XpageVDP	;Si es petición de cambio de página va a XpageVDP.

	jp	VideoIn2

VideoIn3:	
	IDE_ON			;Activa la unidad IDE.
	xor	a
	ld	(FJ_VDP_INST),a	;Borra petición instrucción al VDP desde la Flashjacks. 
	ld	a,(FJ_VDP_INST)	;Petición instrucción al VDP desde la Flashjacks. 
	cp	0FFh		;Si ya no hay un reset en curso, reinicia la aplicación.
	jp	nz,reload_Video
	jp	VideoIn3	;Bucle hasta que inserte de nuevo tarjeta.


	; Fin bucle en espera de instrucciones de la Flashjacks.
	;---

	;---
	;Gestión de la petición de recepción de cuadros de 512Bytes al VDP en escritura directa.
VideoDirect:
	;Envia posicionamiento al VDP junto al primer punto.    

	ld	a,(pagvram2)	;Envía el cámbio de página al A16 del registro 14. 
	or	a
	sla	a
	sla	a
	ld	b,a
	ld	a,(FJ_VDP_R38)	;Equivale al registro R#38 del VDP. Inicio del eje de las Y
	sra	a
	sra	a
	sra	a
	sra	a
	sra	a
	sra	a
	and	%00000011
	add	a,b
	out	(#99), a	
	ld	a, 14+80H	;Registro R#14 A16-15-14. Página destino(en A16). Es para la escritura directa.
	out	(#99), a
	
	ld	a,(FJ_VDP_R36)	;Envia el primer registro al puerto 1. Equivale al Registro R#36 del VDP. Inicio del eje de las X
	out	(#99), a	
	
	ld	a,(FJ_VDP_R38)	;Equivale al registro R#38 del VDP. Inicio del eje de las Y
	and	%00111111	;Filtra solo A13-A8 correspondiente a Y5..0
	or	%01000000	;Pone bit de escritura. Data Write.
	out	(#99), a
	
	ld	a,(FJ_VDP_R38)	;Guarda el registro R#38 del VDP. Incrementa en 1 su posición para el siguiente nivel.
	inc	a
	ld	(TempejeY),a	;Lo guarda en TempejeY.
	
	ld	c, #98		;Carga el puerto 98 para el envío directo.
	ld	hl, IDE_DATA	;Envía el primer valor del IDE-SD al VDP. al Registro R#44.

	outi_10
	outi_10
	outi_10
	outi_1
	outi_1			;Envío de 32 Bytes. 

	ld	a,15		;Inicia a 15 veces el ciclo de las Y.
	ld	d,a		;Lo guarda en d.

CicloDirect:	
	ld	a,(TempejeY)	;Equivale al registro R#38 del VDP. Inicio del eje de las Y con variable incremental guardada.
	sra	a
	sra	a
	sra	a
	sra	a
	sra	a
	sra	a
	and	%00000011
	add	a,b
	out	(#99), a	
	ld	a, 14+80H	;Registro R#14 A16-15-14. Página destino(en A16). Es para la escritura directa.
	out	(#99), a
	
	ld	a,(FJ_VDP_R36)	;Envia el registro de las X al puerto 1. Equivale al Registro R#36 del VDP. Inicio del eje de las X
	out	(#99), a

	ld	a,(TempejeY)	;Equivale al registro R#38 del VDP. Inicio del eje de las Y con variable incremental guardada.
	and	%00111111	;Filtra solo A13-A8 correspondiente a Y5..0
	or	%01000000	;Pone bit de escritura. Data Write.
	out	(#99), a
	
	ld	a,(TempejeY)	;Guarda la variable TempejeY del VDP. Incrementa en 1 su posición para el siguiente nivel.
	inc	a
	ld	(TempejeY),a	;Lo guarda en TempejeY.

	outi_10
	outi_10
	outi_10
	outi_1
	outi_1			;Envío de 32 Bytes.
	
	ld	a,d		;Recupera el ciclo de las Y	
	dec	a		;Decrementa en 1.
	cp	0		;Si ha llegado a cero finaliza la escritura.
	jp	z,CicloDirect2	;Salta a fin de escritura.
	ld	d,a		;Si no guarda el nuevo valor.
	jp	CicloDirect	;Bucle escritura.

CicloDirect2:	
	ld	a,0
	ld	(MultiVDP),a	;Tira la variable de espera por HMMM ya que el VideoDirect ha consumido la espera.
	
	ld	c, #9B		;Carga el puerto 9b para el envío indirecto.(Lo deja preparado para una escritura indirecta por comandos.
	xor	a
	ld	(FJ_VDP_INST),a	;Borra petición instrucción al VDP desde la Flashjacks. 
	jp	VideoIn2	;Va a la siguiente instrucción.

	;---
	;Gestión de la petición de recepción de cuadros de 512Bytes al VDP por instrucción HMMC.
VideoHMMC:
	;Envia comando HMMC al VDP junto al primer punto.    
	ld	a,(FJ_VDP_R36)	;Envia el comando al VDP. Registro R#36 del VDP.
	out	(#99), a	
	ld	a, 36+80H	;Registro R#36 Inicio eje X.
	out	(#99), a

	ld	a,(FJ_VDP_R38)	;Envia el comando al VDP. Registro R#38 del VDP.
	out	(#99), a	
	ld	a, 38+80H	;Registro R#38 Inicio eje Y.
	out	(#99), a
	
	ld	a,10H		;Envia el comando al VDP. Registro R#42 del VDP. 16 pixeles.
	out	(#99), a	
	ld	a, 42+80H	;Registro R#42. Número píxeles eje Y.
	out	(#99), a

	ld	hl, IDE_DATA	;Envía el primer valor del IDE-SD al VDP. al Registro R#44.
	outi
	
	ld	a,0F0h		;Envia el comando al VDP. Registro R#46 del VDP.
	out	(#99), a
	ld	a, 46+80H	;Registro R#46 del VDP. Siempre 0F0h. Ejecuta HMMC.
	out	(#99), a

	outi_511		;Envía los 511bytes restantes.

FinVideoIn2:	
	ld	a,0
	ld	(MultiVDP),a	;Tira la marca de espera VDP por ejecución de HMMM.
	xor	a
	ld	(FJ_VDP_INST),a	;Borra petición instrucción al VDP desde la Flashjacks. 
	jp	VideoIn2	;Va a la siguiente instrucción.
	

	;---
	;Gestión cambio página del VDP.
XpageVDP:
	ld	a,(MultiVDP)	;Comprueba si está activo el HMMM en el VDP.
	cp	00h
	jp	z,XpageVDP_con	;Si no, pasa de comprobar el estado del VDP.
	
	ld	a,02h		;Solicita el R#2 para ver el CE status
	out	(#99), a
	ld	a, 15+80H	
	out	(#99), a
	in	a,(#99)
	and	1
	jp	nz, XpageVDP	;Bucle de espera hasta que la función en curso finalice.
	xor	a
	out	(#99), a
	ld	a, 15+80H
	out	(#99), a

XpageVDP_con:	
	call	chgpage2	;Cambia la página de video a mostrar. 0 por 1 y viceversa.
	jp	FinVideoIn2	;Va al cierre de la instrucción.

	
	;---
	;Gestión de la petición de copia de cuadros de 512Bytes al VDP por instrucción HMMM.
VideoHMMM:
	;Envia comando HMMM al VDP junto al primer punto. 
	
	ld	a,(MultiVDP)	;Comprueba si está activo el HMMM en el VDP.
	cp	00h
	jp	z,VideoHMMM_cont;Si no, pasa de comprobar el estado del VDP.

	ld	a,02h		;Solicita el R#2 para ver el CE status
	out	(#99), a
	ld	a, 15+80H	
	out	(#99), a
	in	a,(#99)
	and	1
	jp	nz, VideoHMMM	;Bucle de espera hasta que la función en curso finalice.
	xor	a
	out	(#99), a
	ld	a, 15+80H
	out	(#99), a

VideoHMMM_cont:	
	ld	a,(FJ_VDP_R32)	;Envia el comando al VDP. Registro R#32 de la Flashjacks.
	out	(#99), a	
	ld	a, 32+80H	;Registro R#32 del VDP. Inicio eje X.
	out	(#99), a
	
	ld	a,(FJ_VDP_R34)	;Envia el comando al VDP. Registro R#34 de la Flashjacks.
	out	(#99), a	
	ld	a, 34+80H	;Registro R#34 Inicio eje Y.
	out	(#99), a

	ld	a,(FJ_VDP_R35)	;Envia el comando al VDP. Registro R#35 de la Flashjacks.
	out	(#99), a	
	ld	a, 35+80H	;Registro R#35 NY8-9. Cambio de página origen.
	out	(#99), a

	ld	a,(FJ_VDP_R36)	;Envia el comando al VDP. Registro R#36 de la Flashjacks.
	out	(#99), a	
	ld	a, 36+80H	;Registro R#36 del VDP. Inicio eje X.
	out	(#99), a

	ld	a,(FJ_VDP_R38)	;Envia el comando al VDP. Registro R#38 de la Flashjacks.
	out	(#99), a	
	ld	a, 38+80H	;Registro R#38 Destino eje Y.
	out	(#99), a

	ld	a,10H		;Envia el comando al VDP. Registro R#42 del VDP. 16 pixeles.
	out	(#99), a	
	ld	a, 42+80H	;Registro R#42. Número píxeles eje Y.
	out	(#99), a

	ld	a,0D0h		;Envia el comando al VDP. Registro R#46 del VDP.
	out	(#99), a
	ld	a, 46+80H	;Registro R#46 del VDP. Siempre 0E0h. Ejecuta HMMM.
	out	(#99), a

VideoHMMM1:

	ld	a,1
	ld	(MultiVDP),a	;Activa la marca de que el VDP está trabajando en un comando y que hay que respetar como mínimo los NOP anteriores antes de volver a trabajar por comandos.

	xor	a
	ld	(FJ_VDP_INST),a	;Borra petición instrucción al VDP desde la Flashjacks. 
	jp	VideoIn2	;Va a la siguiente instrucción.

	;Ventana screen 12, 128x106 = 13.568 bytes
	;Completo screen 12, 256x212 = 54.272 bytes
	;Screen 12 a 104 cuadros: 256x208 = 8x13 cuadros de 512bytes cada uno (32x16).
	;Screen 12 a 96 cuadros: 256x192 = 8x12 cuadros de 512bytes cada uno (32x16).
	;Completo damero de 106 piezas de 512bytes. (32x16 o 16x32)

; Fin subprograma Formato VideoIn desde la Flashjacks
;---------------------------------------------------------------------------

;---------------------------------------------------------------------------
; Subprograma finalización del programa y salida estable al sistema


finvideo2:

	IDE_OFF
	ei
	
	ld	a, (modor800)		; Si es un Turbo-R reestablece el modo del procesador.
	cp	#FF	
	jp	z, notr			; Si lee FF no es un TurboR y pasa de reestablecer nada.
	or	#80
	rst	#30
	db	0
	dw	#180
	jp	resrefr			; Salta a restaurar refrescos del VDP.

notr:					; si es un 2+ de Panasonic a 6Mhz lo vuelve a poner a 6Mhz.
	ld	a, (Z80B)
	cp	#FA
	jp	z, tresMhz		; Si no lo es fuerza a frecuencia de un Z80 normal.

	ld	a, 8			; Fuerza a 6 Mhz si la variable z80B de inicio así lo tenía. 
	out	(#40), a
	ld	a, 0
	out	(#41), a
	jp	resrefr			; Salta a restaurar refrescos del VDP.
tresMhz:
	ld	a, 8			; Si no habían turbos definidos, por si acaso fuerza a frecuencia normal del MSX.
	out	(#40), a
	ld	a, 1
	out	(#41), a

resrefr:
	
	ld	a, (#FFE8)		; Recupera los refrescos normales del VDP.
	out	(#99), a
	ld	a, 128+9
	out	(#99), a

	xor	a			; Vuelve a Screen 0.
	rst	#30
	db	0
	dw	#005F

	ld	a, "$"
	ld	(fintextoini), a	; Marca el final del texto a mostrar. (las dos primeras líneas).	
	ld	c, 9			; Escribe solo las dos primeras líneas del texto de presentación.
	ld	de, textoini
	call	BDOS

	
	ld	a, (options2)	;Salta a passvideo Test VDP <-> FJ si es la opción seleccionada .
	and	%1000
	jp	nz, SalidaDos	;No es necesario salvar archivos.

	ld	a, (options2)	;Salta a en modo VDP pruebas si es la opción seleccionada .
	and	%100
	jp	nz, SalidaDos	;No es necesario salvar archivos.

	di
	IDE_ON			;Activa la unidad IDE.
	ideready		;Espera a que la FJ esté disponible.

	ld	a,(FLAGS_FB)	;Mira si ha grabado algo en la SRAM externa de la Jacksboy.
	and	%1
	jp	z,SalidaDos	;salta grabado si no se ha grabado nada.
	
	IDE_OFF
	ei
	
	ld	de, txtEnter	;Fija el puntero en el texto de enter
	ld	c, 9
	call	BDOS
	
	ld	de, txtSRAM	;Fija el puntero en el texto de salvar RAM.
	ld	c, 9
	call	BDOS

	
	; Lectura del posible archivo RAM a FIB
	ld	de, fileram	;Obtiene el File Info Block del
	ld	b, 0		;posible fichero RAM.
	ld	hl, 0
	ld	ix, FIB
	ld	c, #40
	call	BDOS
	or	a
	jp	z, saveRAM	;Salta si no hay error del archivo y se puede abrir.	

	
	; Salva un archivo de 0 bytes si en el anterior apartado no lo ha encontrado.
	ld	de, fileram	;Obtiene el File Info Block del
	ld	b, 0		;posible fichero RAM.
	ld	hl, 0
	ld	a,0
	ld	c, #44		;Create file handle.
	call	BDOS
	or	a
	jp	nz, SalidaDos	;Salta si hay error del archivo y no se puede salvar.	
	ld	a, b
	ld	(filehandle), a	;Guarda en filehandle en su variable.

	; Mueve el filehandle al final del archivo (131071 byte).
	ld	a,(filehandle)
	ld	b, a		;dirección del FileHandle.
	ld	de, 0001h	;Offset H
	ld	hl, 0FFFFh	;Offset L
	ld	a,0		;Relative to the begin of the file.
	ld	c, #4A		;Save al filehandle.
	call	BDOS
	or	a
	jp	nz, cierrefile	;Salta si hay error del archivo y no se puede salvar.	

	; Guarda datos archivo del filehandle. 1byte, el último.
	ld	de, 0000h	;Inicio de datos a grabar. (Da igual. La Flashjacks luego lo machacará.)
	ld	a,(filehandle)
	ld	b, a		;dirección del FileHandle.
	ld	hl, 0001h	;Número de bytes a grabar. 1byte
	ld	a,0
	ld	c, #49		;Save al filehandle.
	call	BDOS

cierrefile:
	; Cierra el fichero creado.
	ld	a, (filehandle)		
	ld	b, a
	ld	c, #45
	call	BDOS

	; Lectura del posible archivo RAM a FIB
	ld	de, fileram	;Obtiene el File Info Block del
	ld	b, 0		;posible fichero RAM.
	ld	hl, 0
	ld	ix, FIB
	ld	c, #40
	call	BDOS
	or	a
	jp	nz, SalidaDos	;Salta si hay error del archivo y no se puede abrir.	


saveRAM:
	di
	IDE_ON
	ideready

	; Salva RAM volatil de archivo a RAM
	ld	a, (FIB+19)	;Top Cluster archivo abierto. Alto.
	ld	(FJ_CLUSH_FB),a	;Ingresa la dirección cluster el archivo. Alto. 
	ld	a, (FIB+20)	;Top Cluster archivo abierto. Bajo.
	ld	(FJ_CLUSL_FB),a	;Ingresa la dirección cluster el archivo. Bajo. 
	ld	a, (FIB+21)	;Tamaño archivo abierto. Alto3.
	ld	(FJ_TAM3_FB),a	;Ingresa el tamaño del archivo. Alto3. 
	ld	a, (FIB+22)	;Tamaño archivo abierto. Alto2.
	ld	(FJ_TAM2_FB),a	;Ingresa el tamaño del archivo. Alto2. 
	ld	a, (FIB+23)	;Tamaño archivo abierto. Alto1.
	ld	(FJ_TAM1_FB),a	;Ingresa el tamaño del archivo. Alto1. 
	ld	a, (FIB+24)	;Tamaño archivo abierto. Bajo.
	ld	(FJ_TAM0_FB),a	;Ingresa el tamaño del archivo. Bajo. 
	ld	a,045h		;Salva RAM.
	ld	(IDE_CMD),a

SalidaDos:

	di
	IDE_ON
	ideready
	
	ld	a,050h		;Resetea estados de variables en FJ.
	ld	(IDE_CMD),a

	di
	IDE_ON			;Activa la unidad IDE.
	ideready

	IDE_OFF
	
	ld	a,(RAMAD1)		;Esto devuelve los mappers del MSX en un estado lógico y estable.
	ld	hl,4000h
	call	ENASLT			;Select Main-RAM at bank 4000h~7FFFh

	ei				; Activa interrupciones.

printexin2:
	ld	de, texin2		;Imprime por pantalla Jacksboy finalizado.
	ld	c, 9
	call	BDOS
	
	rst	0			;Salida al MSXDOS.

; Textos de la finalización del programa.
texin2:	db	13,10,"JacksBoy finalizado.",13,10,"$"


; Fin subprograma finalización del programa y salida estable al sistema
;---------------------------------------------------------------------------

;-----------------------------------------------------------------------------	
;Subproceso de carga de una imagen de fondo pantalla:

loadback:
	ld	de, backfile	;Abre el fichero del puntero backfile. Acordarse de cerrar el archivo.
	xor	a
	ld	c, #43
	call	BDOS
	or	a
	jp	nz, error2_	;Si hay un error de no se puede abrir lo indica por pantalla y fin del programa.

	ld	a, b
	ld	(filehandle2), a;Pasa el resultado del inicio del puntero del archivo a filehandle2.
	ld	de, #8000
	ld	hl, #3507	;Cantidad de bytes a transferir a la dirección 8000h.
	ld	c, #48		;Lee el contenido del puntero filehandle2
	call	BDOS
	or	a
	jp	nz, error3_	;Si hay error de lectura lo indica por pantalla y fin del programa.

	ld	a, (#8007)
	ld	(transback+8), a;Pasa la marca de 8007 a la variable transback +8.

	di
	in	a, (#99)
	ld	a, 36
	out	(#99), a
	ld	a, 17+128
	out	(#99), a
	ld	hl, transback	;Envía los datos de transback al primer punto de pantalla cantidad 0bh.
	ld	bc, #0b9b
	otir			;Repite 0bh veces.

	ld	a, 44+128
	out	(#99), a
	ld	a, 17+128
	out	(#99), a
	ld	hl, #8008
	ld	a, 53
	ld	bc, #FF9b	;Envía el byte 8008 en adelante a pantalla . Se programa contador 0FFh veces.
pptransfer:	
	otir			;Ejecuta el envio del datos al VDP 0FFh veces.
	dec	a		
	jp	nz, pptransfer	;Bucle de lo anterior 53 veces. (Total transferidos 13.515 bytes).

	call	read2vram	;Lee del filehandle2 3500bytes y lo envía al VDP.
	call	read2vram	;Lee del filehandle2 3500bytes y lo envía al VDP.
	call	read2vram	;Lee del filehandle2 3500bytes y lo envía al VDP.

	ld	a, (filehandle2);Cierra el fichero abierto.
	ld	b, a
	ld	c, #45
	call	BDOS

	di
	in	a, (#99)
	ld	a, 32
	out	(#99), a
	ld	a, 17+128
	out	(#99), a
	ld	hl, transback2	;Envía los datos de transback2 al primer punto de pantalla cantidad 0bh.
	ld	bc, #0f9b
	otir			;Repite 0Fh veces.

InCopy:
	ld	a,02h		;Solicita el R#2 para ver el CE status
	out	(#99), a
	ld	a, 15+80H	
	out	(#99), a
	in	a,(#99)
	and	1
	jp	nz, InCopy	;Bucle de espera hasta que la función en curso finalice.

	jp	retloadb	;Devuelve el control al proceso principal.

;Fin subproceso de carga de una imagen de fondo pantalla.
;-----------------------------------------------------------------------------	


;-----------------------------------------------------------------------------	
;Subproceso de salida del programa con mensaje de error:

txterror:	db	"Error: $"

error:	;Salida normal con mensaje de error.
	push	de		;Guarda el mensaje de error a mostrar.
	
		
	ld	a,(RAMAD1)	;Esto devuelve los mappers del MSX en un estado lógico y estable.
	ld	hl,4000h
	call	ENASLT		;Select Main-RAM at bank 4000h~7FFFh

	ld	de, txterror	;Imprime por pantalla la palabrar Error.
	ld	c, #09
	call	BDOS

	pop	de		;Recupera e imprime por pantalla el mensaje del error.
	ld	c, #09
	call	BDOS

	ld	a, (#FFE8)	;Acceso al VDP para devolver los refrescos.	
	out	(#99), a
	ld	a, 128+9
	out	(#99), a
	
	ei			;Activa interrupciones. Por si acaso se han quedado desactivadas.
	rst	0		;Salida al MSXDOS.

error9: ;Salida cerrando archivo con mensaje de error:
	push	de

	ld	a, (filehandle)	;Cierra el archivo
	ld	b, a
	ld	c, #45
	call	BDOS

	ei
	ld	a, (#FFE8)	;Acceso al VDP para devolver los refrescos.
	out	(#99), a
	ld	a, 128+9
	out	(#99), a

	xor	a		;Screen 0.
	rst	#30
	db	0
	dw	#005F

	ld	a,(RAMAD1)	;Esto devuelve los mappers del MSX en un estado lógico y estable.
	ld	hl,4000h
	call	ENASLT		;Select Main-RAM at bank 4000h~7FFFh

	ld	c, 9
	ld	de, txterror	;Imprime por pantalla la palabrar Error.
	call	BDOS

	pop	de		;Recupera e imprime por pantalla el mensaje del error.
	ld	c, #09
	call	BDOS
	
	ei			;Activa interrupciones. Por si acaso se han quedado desactivadas.
	rst	0		;Salida al MSXDOS.


;Mensajes de error:
txterror1:	db	"FLASHJACKS no detectada!!",13,10,"$"
error1:
	ld	de, txterror1	;Error de Flashjacks no detectada.
	jp	error

txterror2:	db	"El archivo no se puede abrir!!",13,10,"$"
error2:
	ld	de, txterror2	;Error del archivo que no se puede abrir.
	jp	error

error2_:
	ld	de, txterror2	;Error del archivo que no se puede abrir cerrando archivo.
	jp	error9

txterror3:	db	"El archivo no se puede leer!!",13,10,"$"
error3:
	ld	de, txterror3	;Error del archivo que no se puede leer.
	jp	error

error3_:
	ld	de, txterror3	;Error del archivo que no se puede leer cerrando archivo.
	jp	error9

txterror4:	db	"La Flashjacks no está preparada!!",13,10,"$"
error4:
	xor	a		;Screen 0.
	rst	#30		
	db	0
	dw	#005F
	ld	de, txterror4	;Error de la Flashjacks no está preparada.
	jp	error

txterror5:	db	"no es un archivo EVA!!",13,10,"$"
error5:				;Error de no es un archivo EVA.
	ld	de, txterror5
	jp	error

txterror6:	db	"IDE BIOS 1.92 or greater needed!!",13,10,"$"
error6:				;Error de BIOS 1.92 o superior necesaria.
	ld	de, txterror6
	jp	error

txterror7:	db	"error de la unidad!!",13,10,"$"
error7:				;Error en la unidad.
	ld	de, txterror7
	jp	error

txterror8:	db	"No se encuentra el BootROM (BOY_BIOS.BIN) en el raiz...",13,10,"$"
error8:
	ld	de, txterror8	;Error de no encuentro BootROM
	jp	error

txterror10:	db	"Detectado MSX1.Jacksboy no funciona en un VDP inferior al V9938.",13,10,"$"
error10:
	ld	de, txterror10	;Error en MSX1.
	jp	error9

txterror11:	db	"Esto no es MSX-DOS2.Carga los drivers originales.",13,10,"$"
error11:
	ld	de, txterror11	;Error no es MSX-DOS2
	jp	error

;Fin del subproceso de salida del programa con mensaje de error.
;-----------------------------------------------------------------------------	


;-----------------------------------------------------------------------------
;
; Subrutinas (vienen de un CALL):

;-----------------------------------------------------------------------------
;
; Espera al ideready de la tarjeta SD.
_ideready:
	ideready
	ret

;-----------------------------------------------------------------------------
;
; Saltar espacios de una cadena de carácteres

saltaspacio:			;Salta todos los espacios en la lectura de cadena de carácteres.
	ld	a, (hl)
	cp	" "
	ret	nz		;Si hay otra cosa que no sea espacios fin de la subrutina.
	inc	hl
	jp	saltaspacio	;Bucle saltar espacios.

;-----------------------------------------------------------------------------
;
; Convierte una cadena numérica de decimal a hexadecimal.
; El resultado lo pone en bc y de

dec2hex:
	ld	bc, 0
	ld	de, 0
dec2hex2:
	inc	hl		;lee la cadena numérica en texto.
	ld	a, (hl)
	cp	" "
	ret	z		;Si hay un espacio fin de la lectura. Sale de la subrutina
	ret	c		;Si no hay nada fin de la lectura. Sale de la subrutina.
	sub	#30		;Lo pasa a número de variable.(30 a 39 ASCII).
	cp	10
	jp	nc, dec2hex3	;Si no es un número muestra texto y fin.
	push	af
	call	mulbcdx10	;Multiplica por 10 el número.
	pop	af
	add	a, d
	ld	d, a
	ld	a, c
	adc	a, 0
	ld	c, a
	ld	a, b
	adc	a, 0
	ld	b, a
	jp	dec2hex2	;Va haciendo bucle hasta tener el número en HEX.
dec2hex3:
	pop	hl		;Mata el RET del stack pointer. (Extrae del SP la llamada del CALL y lo pone en HL por ejemplo).
	jp	muestratexto	;Salto incondicional de muestra texto y fin.

;-----------------------------------------------------------------------------
;
; Multiplica un valor BCD x10

mulbcdx10:
	or	a
	rl	d
	rl	c
	rl	b
	ld	ixh, b
	ld	ixl, c
	ld	iyh, d
	or	a
	rl	d
	rl	c
	rl	b
	or	a
	rl	d
	rl	c
	rl	b
	ld	a, d
	add	a, iyh
	ld	d, a
	ld	a, c
	adc	a, ixl
	ld	c, a
	ld	a, b
	adc	a, ixh
	ld	b, a
	ret

;-----------------------------------------------------------------------------
;
; Multiplica un valor BCD x3

mulbcdx3:
	ld	ixh, b
	ld	ixl, c
	ld	iyh, d
	or	a
	rl	d
	rl	c
	rl	b
	ld	a, d
	add	a, iyh
	ld	d, a
	ld	a, c
	adc	a, ixl
	ld	c, a
	ld	a, b
	adc	a, ixh
	ld	b, a
	ret

;-----------------------------------------------------------------------------
;Lee de filehandle2 3500bytes y los pone en la memoria 8000h

read2vram:
	ld	a, (filehandle2);Lee de filehandle2 3500bytes y los pone en la memoria 8000h.
	ld	b, a
	ld	de, #8000	;Read 53 lines.
	ld	hl, #3500
	ld	c, #48
	call	#5

	di
	ld	hl, #8000
	ld	a, 53
	ld	bc, #009b
pptransfer2:	
	otir			
	dec	a
	jp	nz, pptransfer2;Envía los datos de 8000h al puerto del VDP 53bytes.
	ret

;-----------------------------------------------------------------------------
;Detecta la pulsacion de la tecla ESC o TAB y sale o pausa respectivamente
;A posterior, coge la tecla pulsada y la almacena en FJ_KEYB_MSX.
;La configuración del teclado es editable y se puede asignar y desasignar teclas

readkeyb:	
	in	a, (#A9)	;Detecta la pulsacion de la tecla ESC o TAB y sale o pausa respectivamente.
	bit	2, a		
	jp	z, readkeybfin	;Si es ESC salta para finalizar video.
	bit	3, a
	jp	z, readkeyb	;Si es TAB bucle de lectura tecla hasta dejar de pulsar la tecla.(Pausa del video).
	
	; Rutina mapeo puertos teclados para que la FJ lo recoga por el puerto A9h.
	ld	a,#F0
	out	(#AA),a
	in	a,(#A9)
	ld	a,#F1
	out	(#AA),a
	in	a,(#A9)
	ld	a,#F2
	out	(#AA),a
	in	a,(#A9)
	ld	a,#F3
	out	(#AA),a
	in	a,(#A9)
	ld	a,#F4
	out	(#AA),a
	in	a,(#A9)
	ld	a,#F5
	out	(#AA),a
	in	a,(#A9)
	ld	a,#F6
	out	(#AA),a
	in	a,(#A9)
	ld	a,#F7
	out	(#AA),a
	in	a,(#A9)
	ld	a,#F8
	out	(#AA),a
	in	a,(#A9)
	ld	a,#F9
	out	(#AA),a
	in	a,(#A9)
	ld	a,#FA
	out	(#AA),a
	in	a,(#A9)
	ld	a,#FB	; Esta es para que actualice la variable de teclado ASCII en la FJ. (FB no existe como fila).
	out	(#AA),a
	in	a,(#A9)

	ld	a,#F7 ; Recupera el F7 para la próxima lectura.
	out (#AA),a

	; Mapeo puertos Joystick JOYMEGA

	ld	a, 15	; Lee el puerto de joystick y almacena
	out	(#A0), a	; los estados en las variables.
	in	a, (#A2)
	and	10101111b
	push	af
	out	(#A1), a
	ld	a, 14
	out	(#A0), a
	in	a, (#A2)
	ld	(FJ_JOY_1), a
	ld	a, 15
	out	(#A0), a
	pop	af
	push	af
	or	00010000b
	out	(#A1), a
	ld	a, 14
	out	(#A0), a
	in	a, (#A2)
	ld	(FJ_JOY_2), a
	ld	a, 15
	out	(#A0), a
	pop	af
	push	af
	out	(#A1), a
	or	00010000b
	out	(#A1), a
	and	11101111b
	out	(#A1), a
	or	00010000b
	out	(#A1), a
	ld	a, 14
	out	(#A0), a
	in	a, (#A2)
	ld	(FJ_JOY_3), a
	ld	a, 15
	out	(#A0), a
	pop	af
	push	af
	and	11101111b
	out	(#A1), a
	ld	a, 14
	out	(#A0), a
	in	a, (#A2)
	ld	(FJ_JOY_4), a
	ld	a, 15
	out	(#A0), a
	pop	af
	or	00010000b
	out	(#A1), a
	and	11101111b
	out	(#A1), a
	ret

readkeybfin:
	ld	a,0FFh
	ld	(IDE_DEVCTRL),a ;Envía un reset a la unidad IDE.
	pop	hl		;Mata el RET del stack pointer. (Extrae del SP la llamada del CALL y lo pone en HL por ejemplo).
	jp	finvideo2	;Salta a finvideo2.

;-----------------------------------------------------------------------------
;Cambia la pagina de video a mostrar en videoin. 0 por 1 y viceversa.

chgpage2:	                ;Cambia la pagina de video a mostrar.
	ld	a,(FJ_VDP_R39)	;Le solicita la nueva página a la Flashjacks.
	or	a
	jp	nz, page1b	;Si está en la página 0 va a la 1.
	xor	a
	ld	(pagvram2), a	;Cambia a página 0.
	ld	a, (#F3E1)
	or	%00100000
	out	(#99), a
	ld	a, #82
	out	(#99), a
	jp	page2fin
page1b:
	ld	a, 1
	ld	(pagvram2), a	;Cambia a página 1.
	ld	a, (#F3E1)
	and	%11011111
	out	(#99), a
	ld	a, #82
	out	(#99), a

page2fin: ; Actualiza registro pagína en HMMM y hace lectura de teclado en cada cámbio de página.	
	ld	a,(pagvram2)	;Envia el comando al VDP. Registro R#39 del VDP.
	out	(#99), a	
	ld	a, 39+80H	;Registro R#39 NY8-9. Cambio de página destino.	Es para el HMMC.
	out	(#99), a
	
	call	readkeyb	;Llama lectura del teclado para pausa TAB o salida ESC. Si es salida va a gestion fin del video.
				;También hace la lectura de la tecla pulsada y lo envía a la Flashjacks

	ret

;-----------------------------------------------------------------------------
;Averigua y almacena las subrutinas de MSX-DOS2

Enable_MSX22:
	XOR	A
	LD	DE,#0402
	CALL	#FFCA

	LD	DE,ALL_SEG
	LD	BC,48
	LDIR
	RET

ALL_SEG:	DS	3
FRE_SEG:	DS	3
RD_SEG:		DS	3
WR_SEG:		DS	3
CAL_SEG:	DS	3
CALLS:		DS	3
PUT_PH:		DS	3
GET_PH:		DS	3
PUT_P0:		DS	3
GET_P0:		DS	3
PUT_P1:		DS	3
GET_P1:		DS	3
PUT_P2:		DS	3
GET_P2:		DS	3
PUT_P3:		DS	3
GET_P3:		DS	3


;-----------------------------------------------------------------------------
;Variables del entorno.

oldstack:	dw	0
PCMport:	db	0
tamanyoPCM:	dw	0
options:	db	%0
options2:	db	%0
pcmsize:	dw	0
tamanyo:	db	0,0,0,0
tamanyoc:	db	0,0,0,0
unidad:		db	0
slotide:	db	0
cabezas:	db	0
sectores:	db	0
devicetype:	db	0
atapic:		ds	18
start:		db	0,0,0,0
start_:		db	0,0,0,0
final:		db	0,0,0,0
final_:		db	0,0,0,0
frmxint:	db	2
HMMV:		db	0,0,0,0,0,0,212,1,0,0,#C0
HMMC1:		db	64,0,53
pagvram:	db	0
		db	128,0,106,0,0,#F0

HMMC2:		db	0,0,0
pagvram2:	db	0
		db	0,1,212,0,0,#F0

transback:	db	0,0,0,0,0,1,212,0,0,0,#F0
transback2:	db	0,0,0,0,0,0,0,1,0,1,212,0,0,0,#D0

datovideo:	db	0
TempejeY:	db	0
MultiVDP:	db	0
regside1:	db	0
regside2:	db	0
regside3:	db	0
regside4:	db	0
regside1c:	db	0
regside2c:	db	0
regside3c:	db	0
regside4c:	db	0
atapiread:	db	#A8,0,0,0,0,0,0,0,0,0,0,0
modor800:	db	0
Z80B:		db	0
filehandle:	db	0
filehandle2:	db	0
filename:	ds	64
fileram:	ds	20
fileboot:	db	5Ch,"BOY_BIOS.BIN",0 ; el 5Ch es contrabarra para ir a directorio raiz.
backfile:	ds	64
safe38:		ds	5
buffer:		ds	2
FIB:		ds	64
sonido:		dw	0
sonido2:	dw	0
idevice:	dw	0

;Fin de las variables del entorno.
;-----------------------------------------------------------------------------

;Fin del programa completo.
;-----------------------------------------------------------------------------
end