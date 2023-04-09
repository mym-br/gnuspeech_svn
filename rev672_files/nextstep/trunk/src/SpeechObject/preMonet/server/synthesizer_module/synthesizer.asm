;; REVISION INFORMATION  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; $Author: rao $
;; $Date: 2002-03-21 16:49:54 $
;; $Revision: 1.1 $
;; $Source: /Users/dalmazio/cvsroot/gnuspeech/trillium/src/SpeechObject/preMonet/server/synthesizer_module/synthesizer.asm,v $
;; $State: Exp $
;;
;;
;; $Log: not supported by cvs2svn $
;; Revision 1.3  1993/11/30  22:30:35  len
;; Fixed a bug in DSP code.  Created the scaled_volume()
;; function, which checks volume ranges before scaling
;; them to a fractional number.
;;
;; Revision 1.2  1993/11/29  18:43:18  len
;; Moved calculatation of amplitudes and resonator coefficients to the
;; DSP from the host.
;;
;; Revision 1.1.1.1  1993/11/25  23:00:46  len
;; Initial archive of production code for the 1.0 TTS_Server (tag v5).
;;
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;   PROGRAM:	synthesizer.asm (DMA version)
;;
;;   AUTHOR:	Leonard Manzara
;;
;;   DATE:	
;;
;;   SUMMARY:	Revamped voice synthesis program.  Uses DSP-initiated streamed DMA
;;		input and output.
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;  DEBUGGING FLAG

DEBUG_56 set 0			; set to 1 for use with Bug56


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;  FORMATTING FOR LISTING FILE

	page 120,48,0,1,0	; Width, height, topmar, botmar, lmar

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;  ASSEMBLY OPTIONS
	opt rc,mu,mex

	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;  INCLUDE FILE

	NOLIST
	include	'ioequlc.asm'
	LIST


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;  INTERNAL SCALING CONSTANTS (MUST MATCH 68040)

SCALE_ASP		set     -35.0	; in dB
SCALE_FRIC		set     -54.0	; in dB
PRECASCADE_SCALE	set	-38.0	; in dB
OSC_PER_SCALE		set	0.75	; % of precascade applied to osc
					; (r.c get 1.0 - value)
SINE_OFFSET		set	0.25	; converts sine function to cosine (adds pi/2)


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;  ORIGINS FOR PROGRAM MEMORY

	IF !DEBUG_56
ON_CHIP_PROGRAM_START	equ	$40
	ELSE
ON_CHIP_PROGRAM_START	equ	$A0
	ENDIF

OFF_CHIP_PROGRAM_START	equ	$2000


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;  MACROS

writeHost macro source
_one	
	jclr	#m_htde,x:m_hsr,_one	
	movep	source,x:m_htx
	endm
	

readHost macro	dest
_two
	jclr	#m_hrdf,x:m_hsr,_two	
	movep	x:m_hrx,dest
	endm


shiftLeft macro s,m,n,acc		; four input variables
	move	#>@cvi(@pow(2,n-1)),m	; load the mult. reg.
	mpy	s,m,acc			; shift left n bits
	endm				; result in 0 part of accumulator
	
;; 	s   = source register (x0,x1,y0,or y1)
;; 	m   = the multiplier register (x0,x1,y0,or y1)
;;	n   = the number of bits to be shifted
;;	acc = the destination accumulator (a or b)


dbToAmpTable	macro	origin
;; This macro creates a table of max+1 points in each of x and y memory.  X memory
;; is filled with the values to convert from dB to amplitude, for the range 0 to
;; max dB.  Y memory is filled with the delta between the x+1 value and the x value.
;; This allows efficient interpolation between x table values.  Note that the dB
;; values are actually made to range from -max to 0 dB (to permit correct calculation
;; using the power function), and that -max dB is set to 0.0, so that 0 dB actually
;; corresponds to an amplitude of 0 (and not some very small number).

; The table has max+1 entries
max	set	60

;; Create the dbToAmp conversion value for 0 to max dB
	org	x:origin
	dc	0.0
count	set	1
	dup 	max
value	set	@min(@pow(10.0,@cvf(count-max)/20.0),0.9999998)
	dc	value
count	set	count+1
	endm

;; Create the delta values between adjacent x table values.
	org	y:origin
value	set	@min(@pow(10.0,@cvf(-max+1)/20.0),0.9999998)
	dc	value
count	set	1
	dup	max-1
value	set	@min(@pow(10.0,@cvf(count-max)/20.0),0.9999998)
nvalue	set	@min(@pow(10.0,@cvf(count-max+1)/20.0),0.9999998)
delta	set	nvalue-value
	dc	delta
count	set	count+1
	endm
	dc	0.0

	endm



rTable	macro	origin
;; This macro creates a table of max points in each of x and y memory.  X memory
;; is filled with the values to 
;; Y memory is filled with the delta between the x+1 value and the x value.
;; This allows efficient interpolation between x table values.

; The table has max entries
rTableSize	equ	64
pi		equ	3.141592654

;; Create the rTable value for 0 to rTableSize
	org	x:origin
count	set	0
	dup 	rTableSize
value	set	@min(@xpn(-(@cvf(count)*pi)/(@cvf(rTableSize-1)*2.0)),0.9999998)
	dc	value
count	set	count+1
	endm

;; Create the delta values between adjacent x table values.
	org	y:origin
count	set	0
	dup	rTableSize-1
value	set	@min(@xpn(-(@cvf(count)*pi)/(@cvf(rTableSize-1)*2.0)),0.9999998)
nvalue	set	@min(@xpn(-(@cvf(count+1)*pi)/(@cvf(rTableSize-1)*2.0)),0.9999998)
delta	set	nvalue-value
	dc	delta
count	set	count+1
	endm
	dc	0.0

	endm



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;  INTERRUPT AND HOST COMMAND VECTORS

VEC_RESET		equ	$00	; reset vector
VEC_HOST_RECEIVE_DATA	equ	$20	; non-dma data from host to dsp
VEC_DMA_OUT_DONE	equ	$24	; host command: dma-out complete
VEC_DMA_IN_DONE		equ	$28	; host command: dma-in complete
VEC_DMA_IN_ACCEPTED	equ	$2C	; host command: dma-in request accepted
VEC_LOAD_WAVEFORM	equ	$30	; host command: load in waveform
VEC_START               equ	$32	; host command: start synthesizing
VEC_STOP                equ	$34	; host command: stop synthesizing
VEC_LOAD_FNR		equ	$36	; host command: load fnr c,b,a coefficients



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;  ON CHIP X, Y, AND LONG MEMORY STORAGE

;;  X MEMORY
x_tableMod		equ	$ff
x_seed			equ	$fe
x_signal2		equ	$fd
x_radiation		equ	$fc
x_index1		equ	$fb
x_index2		equ	$fa
x_curAmpl		equ	$f9
x_tableCount		equ	$f8
x_temp			equ	$f7
x_temp3			equ	$f6

x_temp2			equ	$01
x_STATUS_flags		equ	$00	; status flags (use $00 for use with jset)

;;  STATUS FLAG BITS
DMA_OUT_DONE		equ	0	; indicates dma-out is complete
DMA_IN_DONE		equ	1	; indicates dma-in is complete
DMA_IN_ACCEPTED 	equ	2	; indicates dma-in accepted by host
RUN_STATUS		equ	3	; indicates if synth to run


;;  Y MEMORY
y_factor		equ	$ff
y_signal		equ	$fe
y_deltaAmpl		equ	$fd
y_bufferOutCount	equ	$fc	; accumulated size of output dma buffer
y_am_signal             equ	$fb
y_divisor		equ	$fa

DATA_TABLE		equ	$00	; this is where data from the 68040 is stored
PHASE_INC_INT		equ	$00	; coefficients for filters are loaded directly
PHASE_INC_FRAC		equ	$01	; to x filter memory
RC_SCALE_INT		equ	$02
RC_SCALE_FRAC		equ	$03
OSC_VOL			equ	$04
MASTER_VOL		equ	$05
ASP_VOL			equ	$06
FRIC_VOL		equ	$07
BYPASS_REG		equ	$08
BALANCE                 equ     $09
NASAL_BYPASS            equ	$0a

DATA_TABLE_SIZE		equ	11	; make sure this (number+14) is matched in
					; the 68040 (25)

;;  LONG MEMORY
l_currentPhase		equ	$ef	; long memory occupies both x and y memory,
l_phaseInc		equ	$ed	; therefore it cannot use the same address space
l_dbToAmpTable		equ	$40	; $40 - $7F (64) x and y space for dbToAmp table
l_rTable		equ	$80	; $80 - $BF (64) x and y space for rTable
					; 		 (Exp(-x))

;;  FILL DB TO AMPLITUDE CONVERSION TABLE
	dbToAmpTable	l_dbToAmpTable
;;  FILE R FUNCTION TABLE
	rTable		l_rTable



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;  OFF-CHIP X, Y AND PROGRAM MEMORY (CANNOT BE OVERLAID)
;;
;;  total offchip memory	$2000 - $3FFF	(8192)
;;  reserved program memory	$2000 - $21FF	(512)
;;  waveform table memory	$2200 - $22FF	(256)
;;  free memory			$2300 - $23FF   (256)
;;  resonator 1 X memory	$2400 - $2403	(4)
;;  resonator 1 Y memory	$2404 - $2407	(4)
;;  resonator 2 X memory	$2408 - $240B	(4)
;;  resonator 2 Y memory	$240C - $240F	(4)
;;  resonator 3 X memory	$2410 - $2413	(4)
;;  resonator 3 Y memory	$2414 - $2417	(4)
;;  resonator 4 X memory	$2418 - $241B	(4)
;;  resonator 4 Y memory	$241C - $241F   (4)
;;  resonator fr X memory	$2420 - $2423	(4)
;;  resonator fr Y memory	$2424 - $2427	(4)
;;  resonator fnr X memory      $2428 - $242B   (4)
;;  resonator fnr Y memory      $242C - $242F   (4)
;;  notch filter X memory   	$2430 - $2437   (8)
;;  notch filter Y(X) memory	$2438 - $243B	(4)
;;  notch filter Y(Y) memory	$243C - $243F	(4)
;;  free memory			$2440 - $33FF	(4032)
;;  DMA output buffer           $3400 - $37FF   (1024)
;;  DMA input buffer            $3800 - $3FFF   (2048)


WAVE_TABLE	equ	$2200		; base address of wavetable
WAVE_TABLE_SIZE	equ	256		; can be set as high as 512
					; (must match 68040)

R_FILTERSIZE	equ	3		; all resonator filters use 3 words in memory
NNF_FSIZE_X	equ	5		; notch filters have 5 coefficients
NNF_FSIZE_Y	equ	2		; notch filters Y(X) and Y(Y) memory

XC1MEMC		equ	$2400		; resonator 1 memory
XC1MEMB		equ	$2401
XC1MEMA		equ	$2402
C1_COEF_R0	equ	$2403
YC1MEM		equ	$2404
C1_FMEM_R4	equ	$2407

XC2MEMC		equ	$2408		; resonator 2 memory
XC2MEMB		equ	$2409
XC2MEMA		equ	$240a
C2_COEF_R0	equ	$240b
YC2MEM		equ	$240c
C2_FMEM_R4	equ	$240f

XC3MEMC		equ	$2410		; resonator 3 memory
XC3MEMB		equ	$2411
XC3MEMA		equ	$2412
C3_COEF_R0	equ	$2413
YC3MEM		equ	$2414
C3_FMEM_R4	equ	$2417

XC4MEMC		equ	$2418		; resonator 4 memory
XC4MEMB		equ	$2419
XC4MEMA		equ	$241a
C4_COEF_R0	equ	$241b
YC4MEM		equ	$241c
C4_FMEM_R4	equ	$241f

XFRMEMC		equ	$2420		; frication resonator memory
XFRMEMB		equ	$2421
XFRMEMA		equ	$2422
FR_COEF_R0	equ	$2423
YFRMEM		equ	$2424
FR_FMEM_R4	equ	$2427

XFNRMEMC	equ	$2428		; fixed nasal resonator memory
XFNRMEMB	equ	$2429
XFNRMEMA	equ	$242a
FNR_COEF_R0	equ	$242b
YFNRMEM		equ	$242c
FNR_FMEM_R4	equ	$242f

XNNFMEMA	equ	$2430		; nasal notch filter memory
XNNFMEMB	equ	$2431
XNNFMEMA2	equ	$2432
XNNFMEMC	equ	$2433
XNNFMEMD	equ	$2434
NNF_COEF_R0	equ	$2435
YNNFMEMX	equ	$2438
NNF_FMEMX_R4    equ	$243b
YNNFMEMY        equ	$243c
NNF_FMEMY_R6    equ	$243f

DMA_OUT_BUFFER	equ	$3400		; dma output buffer
DMA_OUT_SIZE    equ     1024   		; size of output buffer (must match 040)
DMA_IN_BUFFER	equ	$3800		; dma input buffer
DMA_IN_SIZE	equ     2048		; size of input buffer (must match 040)



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;  REGISTER USE
;;	r0	m0		filter memory - for y(n-2), y(n-1), x(n)
;;	r1	m1	n1	waveform table pointers
;;	r2	m2	n2	"
;;	r3	m3		update_datatable registers
;;	r4	m4		filter coefficient memory
;;	r5	m5	n5	pointer for DMA input buffer
;;	r6	m6		load_waveform registers
;;	r7	m7		pointer for DMA output buffer



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;  MISC. CONSTANTS

SEED		equ	.7892347	; constants for noise generator
FACTOR		equ	377

;;  BYPASS SWITCHES USED IN BYPASS_REG
RC_BYPASS	equ	0
FNR_BYPASS      equ	1
NNF_BYPASS      equ	2
F1_BYPASS       equ	3
F2_BYPASS       equ	4
F3_BYPASS       equ	5
F4_BYPASS       equ	6
AM_BYPASS       equ	7
FR_BYPASS       equ	8


INCREMENT1	equ	44		; load data table every 44th sample
INCREMENT2	equ	10		; on every 10 load, inc1+=1  (or 45)
					; yields effective load every 44.1 samples
					; or every .002 of a second (assuming
					; sample rate of 22.05 kHz)

TABLES_PER_DMA	equ	64		; number of tables per dma-in buffer
JUNK_SKIP	equ	7		; table size (32) - actual data (25) = 7



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;  DMA MESSAGES

DMA_OUT_REQ	equ	$050001		; message to host to request dma-OUT
DMA_IN_REQ	equ	$040002		; message to host to request dma-IN 



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;  INTERRUPT VECTORS

	IF !DEBUG_56

	org	p:VEC_RESET
	jmp	reset

;	org	p:VEC_HOST_RECEIVE_DATA	; currently not being used
;	movep	x:m_hrx,y:(r2)+
;	nop

	org	p:VEC_DMA_OUT_DONE	; DMA-OUT completed.
	bset	#DMA_OUT_DONE,x:x_STATUS_flags
	nop

	org	p:VEC_DMA_IN_DONE	; DMA-IN completed.
	bset	#DMA_IN_DONE,x:x_STATUS_flags
	nop
		
	org	p:VEC_DMA_IN_ACCEPTED	; DMA-IN accepted: start reading.
	jsr	dma_in_accepted		

	org	p:VEC_LOAD_WAVEFORM
	jsr	load_waveform		; load in waveform from host

	org	p:VEC_START		; signal to start synthesizing
	bset	#RUN_STATUS,x:x_STATUS_flags
	nop

	org	p:VEC_STOP		; signal to stop synthesizing
	bclr	#RUN_STATUS,x:x_STATUS_flags
	nop

	org	p:VEC_LOAD_FNR
	jsr	load_fnr		; load in fnr coefficients from host

	ENDIF



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;  RESET SUBROUTINE

	org	p:ON_CHIP_PROGRAM_START
reset

;; SET UP CHIP
	bclr	#m_hcie,x:m_hcr		; disable host command interrupts

	movec	#6,omr			; chip set to mode 2; ROM enabled
	bset	#0,x:m_pbc		; set port B to be host interface
	bset	#3,x:m_pcddr		; set pin 3 (pc3) of port C to be output
	bclr	#3,x:m_pcd		; zero to enable the external ram
	movep	#>$000000,x:m_bcr	; set 0 wait states for all external RAM
	movep	#>$00b400,x:m_ipr	; set interrupt priority register to
					; SSI=0, SCI=1, HOST=0

;; SET UP VARIABLES
	clr	a
	move	a10,l:l_currentPhase	; set current phase angle to 0
	move	a,x:x_radiation		; clear r.c. memory
	move	a,y:OSC_VOL		; set oscil ampl to 0 (ready for interpolation)
	move	a,x:x_STATUS_flags	; clear status flags
	move	a,y:y_bufferOutCount	; clear buffer counts
	move	a,x:x_tableCount	; clear table count

;; SET UP REGISTERS
	move	#>WAVE_TABLE,r1		; set register to base of waveform table
	move	#>WAVE_TABLE,r2		; set register to base of waveform table
	move	#>WAVE_TABLE_SIZE-1,x0
	move	x0,x:x_tableMod		; set mask to tablesize - 1
	move	x:x_tableMod,m1		; set modulus for waveform table
	move	x:x_tableMod,m2		; set modulus for waveform table

	move	#>DATA_TABLE,r3		; set register to base of datatable
	move	#>DATA_TABLE_SIZE-1,m3	; set modulus for datatable

	move	#>DMA_IN_BUFFER,r5	; set register to base of dma input buffer
	move	#>DMA_IN_SIZE-1,m5	; set modulus for dma input buffer
	move	#>JUNK_SKIP,n5		; used to skip junk data at end of tables

	move	#>WAVE_TABLE,r6		; set register to base of wavetable
	move	#>WAVE_TABLE_SIZE-1,m6	; set modulus for wavetable

	move	#>DMA_OUT_BUFFER,r7	; set register to base of dma output buffer
	move	#>DMA_OUT_SIZE-1,m7	; set modulus for dma output buffer


;; SET UP FILTER MEMORY
	move	#>XNNFMEMA,r0		; initialize pointers to nasal notch filter
	move	#>YNNFMEMX,r4
	move	#>YNNFMEMY,r6
	move	r0,x:NNF_COEF_R0
	move	r4,y:NNF_FMEMX_R4
	move	r6,y:NNF_FMEMY_R6
	move	#>NNF_FSIZE_Y-1,m4
	move	#>NNF_FSIZE_Y-1,m6
	rep	#NNF_FSIZE_Y		; clear y: filter memory to 0
	  move	a,y:(r4)+
	rep	#NNF_FSIZE_Y
	  move	a,y:(r6)+

	move	#>WAVE_TABLE,r6		; reset register to base of wavetable
	move	#>WAVE_TABLE_SIZE-1,m6	; reset modulus for wavetable

	move	#>R_FILTERSIZE-1,m0	; set modulus for resonator filters
	move	#>R_FILTERSIZE-1,m4

	move	#>XC1MEMC,r0		; initialize pointers to first formant
	move	#>YC1MEM,r4		; filter coefficients and filter memory
	move	r0,x:C1_COEF_R0
	move	r4,y:C1_FMEM_R4
	rep	#R_FILTERSIZE		; set y: filter memory to 0
	  move  a,y:(r4)+

	move	#>XC2MEMC,r0		; initialize pointers to second formant
	move	#>YC2MEM,r4		; filter coefficients and filter memory
	move	r0,x:C2_COEF_R0
	move	r4,y:C2_FMEM_R4
	rep	#R_FILTERSIZE		; set y: filter memory to 0
	  move  a,y:(r4)+

	move	#>XC3MEMC,r0		; initialize pointers to third formant
	move	#>YC3MEM,r4		; filter coefficients and filter memory
	move	r0,x:C3_COEF_R0
	move	r4,y:C3_FMEM_R4
	rep	#R_FILTERSIZE		; set y: filter memory to 0
	  move  a,y:(r4)+

	move	#>XC4MEMC,r0		; initialize pointers to fourth formant
	move	#>YC4MEM,r4		; filter coefficients and filter memory
	move	r0,x:C4_COEF_R0
	move	r4,y:C4_FMEM_R4
	rep	#R_FILTERSIZE		; set y: filter memory to 0
	  move  a,y:(r4)+

	move	#>XFRMEMC,r0		; initialize pointers to fric res
	move	#>YFRMEM,r4		; filter coefficients and memory
	move	r0,x:FR_COEF_R0
	move	r4,y:FR_FMEM_R4
	rep	#R_FILTERSIZE		; set y: filter memory to 0
	  move	a,y:(r4)+

	move	#>XFNRMEMC,r0		; initialize pointers to fixed nasal res
	move	#>YFNRMEM,r4		; filter coefficients and memory
	move	r0,x:FNR_COEF_R0
	move	r4,y:FNR_FMEM_R4
	rep	#R_FILTERSIZE		; set y: filter memory to 0
	  move	a,y:(r4)+

;; SET UP RANDOM NUMBER (NOISE) GENERATOR
	move	#>FACTOR,a
	move	a,y:y_factor		; prime factor
seed	dc	SEED
	move	p:seed,a
	move	a,x:x_seed		; prime seed

;; SET UP INITIAL INDEX VALUES FOR UPDATE_DATATABLE
	move	#>1,a1
	move	a1,x:x_index1
	move	a1,x:x_index2

;; UNMASK INTERRUPTS
	bset    #m_hcie,x:m_hcr		; host command interrupts
	move	#0,sr			; unmask interrupts

;; WAIT UNTIL SIGNALED TO START
_wait	jclr	#RUN_STATUS,x:x_STATUS_flags,_wait



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;  START ROUTINE - MAIN ROUTINE WHERE SAMPLES ARE CREATED
start

_toploop

	move	x:x_index1,a		; if index1 == 0, then update datatable
	move	#>1,y1
	sub	y1,a
	move	a,x:x_index1		; index1 -= 1
	jseq	update_datatable

	
_osc
	move	l:l_currentPhase,a	; get current phase angle in table
	move	l:l_phaseInc,b		; get phase angle increment
	add	b,a	x:x_tableMod,x1	; calc new current phase angle
					; uses 48 bit addition (int.frac)
					; wrap integer part of current phase
	and	x1,a			; to keep within table boundaries

	clr	b    a,l:l_currentPhase ; store new current phase angle
	move	a1,n1			; put int part of CPA into register n1
	move	#>1,b1			; put table f(n+1) position into n2
	add	a,b
	and	x1,b			; wrap integer part of phase
	clr	b	b1,n2
	move	y:(r1+n1),y1		; get value of f(n)

	move	y:(r2+n2),b		; get value of f(n+1)

	sub	y1,b	#0,a1		; diff = f(n+1) - f(n)

	asr	a	b1,x0		; shift frac right since no sign bit
					; put diff in x0 register
	move	a0,y0			; put frac. of CPA into y0
	move	y1,a			; put f(n) in a
	macr	x0,y0,a	x:x_curAmpl,y0	; a = f(n) + (diff * CPA(frac)), get current ampl
	move	a,x0	a,y:y_am_signal	; save unscaled waveform value

	mpy	x0,y0,a	y:y_deltaAmpl,b	; multiply output by amplitude factor
					; get delta for AX
	add	y0,b			; current amplitude += deltaAmpl
	move	b,x:x_curAmpl

	move	a,x0 	#@CVF(@POW(10.0,((PRECASCADE_SCALE*OSC_PER_SCALE)/20.0))),y1
	mpyr	x0,y1,a			; scale oscillator down (internal scaling)
	move	a,y:y_signal		; store signal


_radiation
	jset	#RC_BYPASS,y:BYPASS_REG,_noise
	move	x:x_radiation,b		; radiation characteristic is a zero
	sub	b,a	y:y_signal,y0	; at the origin
	rnd	a	y0,x:x_radiation

					     ; scale output from r.c.
	move	y:RC_SCALE_INT,y1  a,x0	     ; put signal in x0; put scale (int) in y1
	mpy	x0,y1,b	 y:RC_SCALE_FRAC,y0  ; do int mult; put scale (frac) in y0
	jmi	_neg_scale		; if result is neg then add - sign
	lsl	b			; else clear sign bit
	asr	b
	move	b0,a			; put result into a
	jmp	_rc_scale		; go to frac. multiply
_neg_scale
	abs	b			; add - sign bit
	lsl	b
	asr	b
	move	b0,a
	neg	a
_rc_scale
	macr	x0,y0,a			; do fraction multiply; is added to
					; previous integer multiply
	move	a,y:y_signal		; store signal

_noise
	clr	a	x:x_seed,x0	; x0 = seed
	move	y:y_factor,y0		; y0 = factor
	mpy	x0,y0,b			; b = seed * factor
	asr	b			; b0 = unsigned product (lsp)
	move	b0,x:x_seed		; store new random number (seed)
	move	b0,a1			; put signal in a1

_amplitude_modulation
	jset	#AM_BYPASS,y:BYPASS_REG,_store_noise
	move	a,x1	y:y_am_signal,y1	; noise signal in x1; get signal from osc
	mpyr	x1,y1,a	#@cvf(0.9999998),b	; scale noise with osc signal; put 1.0 in b
	move	a1,y1				; store modulated noise signal in y1

	move	y:OSC_VOL,y0		; y0 contains scaling for modulated noise
	sub	y0,b			; calculate cross fade (1.0 - x0)
	move	b,x0			; x0 contains scaling for straight noise

	mpyr	x1,x0,a			; sum straight noise
	macr	y0,y1,a			; + modulated noise

_store_noise
	move	a,x:x_signal2		; store scaled noise signal

_asp_vol
	move	a,x0	 y:ASP_VOL,y0	; multiply by amplitude factor
	mpyr	x0,y0,a	 		; scale aspiration

	move	#@CVF(@POW(10.0,(SCALE_ASP/20.0))),x1 a,y1 
	mpyr	x1,y1,a	 y:y_signal,b	; scale volume down by SCALE_ASP dB (internal)


_sum_voice_noise
	add	b,a		; add voiced and asp. signal together
	move	a,y:y_signal	; store summed signal

_fixed_nasal_resonator
	jset	#FNR_BYPASS,y:BYPASS_REG,_nasal_notch_filter
	move	x:FNR_COEF_R0,r0	; set pointer to filter memory
	move	y:FNR_FMEM_R4,r4	; set pointer to coefficients

	jsr	resonator		; put signal in a through resonator

	move	r0,x:FNR_COEF_R0	; save filter memory pointer
	move	r4,y:FNR_FMEM_R4	; save coefficient pointer

_nasal_notch_filter
	jset	#NNF_BYPASS,y:BYPASS_REG,_bypass_switch
	move	x:NNF_COEF_R0,r0	; set pointer to coefficients
	move	y:NNF_FMEMX_R4,r4	; set pointer to Y(X) filter memory
	move	y:NNF_FMEMY_R6,r6	; set pointer to Y(Y) filter memory
	move	#>NNF_FSIZE_X-1,m0	; set modulus for coefficient memory
	move	#>NNF_FSIZE_Y-1,m4	; set modulus for Y(X) filter memory
	move	#>NNF_FSIZE_Y-1,m6	; set modulus for Y(Y) filter memory

	jsr	notch_filter		; put signal in A through notch filter

	move	r0,x:NNF_COEF_R0	; save coefficient pointer
	move	r4,y:NNF_FMEMX_R4	; save pointer to Y(X) filter memory
	move	r6,y:NNF_FMEMY_R6	; save pointer to Y(Y) filter memory
	move	#>R_FILTERSIZE-1,m0	; restore m0 modulus
	move	#>R_FILTERSIZE-1,m4	; restore m0 modulus
	move	#>WAVE_TABLE_SIZE-1,m6	; restore m6 modulus
	move	#>WAVE_TABLE,r6		; restore r6

_bypass_switch
	move	#@cvf(0.9999998),b a,y1 ; put 1.0 in b, y1 is nasal signal
	move	y:NASAL_BYPASS,x0	; x0 is non-nasal scaling
	sub	x0,b	 y:y_signal,y0  ; nasal scaling = (1.0 - x0), y0 is non-nasal signal

	mpy	x0,y0,a	 b,x1		; do non-nasal scaling, x1 is nasal scaling
	macr	x1,y1,a			; + nasal scaling

_cascade1
	jset	#F1_BYPASS,y:BYPASS_REG,_cascade2
	move	x:C1_COEF_R0,r0		; set pointer to filter memory
	move	y:C1_FMEM_R4,r4		; set pointer to coefficients

	jsr	resonator		; put signal in a through resonator

	move	r0,x:C1_COEF_R0		; save filter memory pointer
	move	r4,y:C1_FMEM_R4		; save coefficient pointer

_cascade2
	jset	#F2_BYPASS,y:BYPASS_REG,_store
	move	x:C2_COEF_R0,r0		; set pointer to filter memory
	move	y:C2_FMEM_R4,r4		; set pointer to coefficients

	jsr	resonator		; put signal in a through resonator

	move	r0,x:C2_COEF_R0		; save filter memory pointer
	move	r4,y:C2_FMEM_R4		; save coefficient pointer

_store
	move	a,y:y_signal		; store signal from f1 and f2

_frication
	move	x:x_signal2,x1		; get noise signal
	move	y:FRIC_VOL,y1		; get amplitude factor for fric vol
	mpyr	x1,y1,a	 		;scale by fric vol

	move	#@CVF(@POW(10.0,(SCALE_FRIC/20.0))),x1	a,y1
	mpyr	x1,y1,a			; scale volume down by SCALE_FRIC dB (internal)

_fricres
	jset	#FR_BYPASS,y:BYPASS_REG,_sum_cascade_frication
	move	x:FR_COEF_R0,r0		; set pointer to filter memory
	move	y:FR_FMEM_R4,r4		; set pointer to coefficients

	jsr	resonator		; put signal in a through resonator

	move	r0,x:FR_COEF_R0		; save filter memory pointer
	move	r4,y:FR_FMEM_R4		; save coefficient pointer

_sum_cascade_frication
	move	y:y_signal,b
	add	b,a			; add two signals together

_cascade3
	jset	#F3_BYPASS,y:BYPASS_REG,_cascade4
	move	x:C3_COEF_R0,r0		; set pointer to filter memory
	move	y:C3_FMEM_R4,r4		; set pointer to coefficients

	jsr	resonator		; put signal in a through resonator

	move	r0,x:C3_COEF_R0		; save filter memory pointer
	move	r4,y:C3_FMEM_R4		; save coefficient pointer

_cascade4
	jset	#F4_BYPASS,y:BYPASS_REG,_mastervol
	move	x:C4_COEF_R0,r0		; set pointer to filter memory
	move	y:C4_FMEM_R4,r4		; set pointer to coefficients

	jsr	resonator		; put signal in a through resonator

	move	r0,x:C4_COEF_R0		; save filter memory pointer
	move	r4,y:C4_FMEM_R4		; save coefficient pointer


_mastervol
	move	y:MASTER_VOL,y0   a,x0	; get amplitude factor for master vol
	mpyr	x0,y0,a			; scale output signal
	
_output
	move	a,x1	#@pow(2,-4.65),y1  ; shift value r to avoid clipping 
					   ; (internal shift: ~+20dB)
	mpyr	x1,y1,a			   ; multiply X by factor

	jsr	write_sample_stereo_bal	; put sample to DMA buffer

	jmp	_toploop		; loop forever



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;  WRITE_SAMPLE_STEREO_BAL SUBROUTINE

write_sample_stereo_bal
        move    #@cvf(0.9999998),b      ; put a 1.0 in reg b
        move    y:BALANCE,x1            ; x1 contains R scaling
        sub     x1,b     a,y0           ; R scaling = 1.0 - L scaling,  y0 contains signal
        move    b,x0                    ; x0 contains L scaling
        mpy     x0,y0,a                 ; scale L channel,
        mpy     x1,y0,a  a,x:(r7)+      ; scale R channel, put L value in dma-out buffer
        move    a,x:(r7)+               ; put R output value into dma-out buffer

	move	y:y_bufferOutCount,b
	move	#>2,y0
	add	y0,b	#>DMA_OUT_SIZE,a
	move	b,y:y_bufferOutCount	; increment buffer count by 2

	cmp	b,a			; if Buffer count < DMA size, exit
	jgt	_exit			; (only send DMA buffer when it is full)

	  jsr	write_DMA_buffer		; write DMA buffer to host
	  clr	a	#>DMA_OUT_BUFFER,r7	; reset DMA buffer pointer to beginning
	  move	a,y:y_bufferOutCount		; reset buffer count

_exit	rts


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;  WRITE_DMA_BUFFER SUBROUTINE:  writes one complete DMA to
;;  the host, reading from the dma output buffer.

write_DMA_buffer
	bclr	#DMA_OUT_DONE,x:x_STATUS_flags	; clear dma-out done flag
	writeHost #DMA_OUT_REQ			; request host for dma-out

_ackBeg	jclr	#m_hf1,x:m_hsr,_ackBeg 	; loop until host acknowledges (HF1=1)

	move	#>DMA_OUT_BUFFER,r7	; point to beginning of DMA buffer
	move	#>DMA_OUT_SIZE,b
	do	b,_send_loop	; top of DMA buffer send loop
_send	jclr	#m_htde,x:m_hsr,_send	; loop until htde bit of HSR is set
	movep	x:(r7)+,x:m_htx		; send buffer element to host
_send_loop
	jset	#DMA_OUT_DONE,x:x_STATUS_flags,_endDMA ; if interrupt has set flags,
	jclr	#m_htde,x:m_hsr,_send_loop	; then go to end;  else keep
	movep	#0,x:m_htx		; sending 0s until interrupt sets flags
	jmp	_send_loop
_endDMA

_ackEnd	jset	#m_hf1,x:m_hsr,_ackEnd	; loop until host ack. has ended (HF1=0)

	rts



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;  LOAD_WAVEFORM SUBROUTINE

	org	p:OFF_CHIP_PROGRAM_START

load_waveform
	move	#>WAVE_TABLE,r6		; reset pointer to beginning of table

	do	#WAVE_TABLE_SIZE,_tableloop
_loop2	jclr	#m_hrdf,x:m_hsr,_loop2	; loop until hrdf bit of HSR becomes set
	movep	x:m_hrx,y:(r6)+		; move data into y memory; increment pointer
_tableloop

	rti


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;  LOAD_FNR SUBROUTINE

load_fnr

_loop3	jclr	#m_hrdf,x:m_hsr,_loop3	; loop until hrdf bit of HSR becomes set
	movep	x:m_hrx,x:XFNRMEMC	; move coefficient into x memory
_loop4	jclr	#m_hrdf,x:m_hsr,_loop4	; loop until hrdf bit of HSR becomes set
	movep	x:m_hrx,x:XFNRMEMB	; move coefficient into x memory
_loop5	jclr	#m_hrdf,x:m_hsr,_loop5	; loop until hrdf bit of HSR becomes set
	movep	x:m_hrx,x:XFNRMEMA	; move coefficient into x memory

	rti



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;  UPDATE_DATATABLE SUBROUTINE


update_datatable
	move	y:OSC_VOL,x1
	move	x1,x:x_curAmpl		; end of interpolation
	move	#@cvf(1.0/44.0),y0	; put 1/44 into y memory (interpolation factor)
	move	y0,y:y_divisor

	move	x:x_index2,a
	move	#>1,y1
	sub	y1,a	#>INCREMENT1,b	; index2--
	jne	_continue
	  add	y1,b	#>INCREMENT2,a
	  move	#@cvf(1.0/45.0),y0	; put 1/45 into y memory when using larger
	  move	y0,y:y_divisor		; increment

_continue
	move	b,x:x_index1	; if (index2 != 0) index1=inc1, else index1=inc1+1
	move	a,x:x_index2	; if (index2 != 0) index2 -= 1, else index2=inc2

;; CHECK TABLE COUNT, AND READ NEW DMA BUFFER IF NEEDED
	move	x:x_tableCount,a
	move	#>0,x1
	cmp	x1,a			; if table_count != 0
	jne	_continue2		; then, continue
	  jsr	read_DMA_buffer		; else, read in new DMA buffer
	  move	#>TABLES_PER_DMA,x1
	  move	x1,x:x_tableCount	; and reset table count to maximum
	  move	#>DMA_IN_BUFFER,r5	; and set pointer to start of buffer

;; READ AND CONVERT DATA FROM DMA INPUT TABLE
_continue2
	move	#>DATA_TABLE,r3		; reset pointer to beginning of datatable

	do	#DATA_TABLE_SIZE,_tableloop	; loop until table filled
	move	y:(r5)+,y1
	move	y1,y:(r3)+		; move data into y mem; increment pointer
_tableloop

;; CONVERT DB VALUES TO AMPLITUDE
	move	y:OSC_VOL,y0		; oscillator (voicing) volume
	jsr	convert_to_amp
	move	b,y:OSC_VOL

	move	y:MASTER_VOL,y0		; master volume
	jsr	convert_to_amp
	move	b,y:MASTER_VOL

	move	y:ASP_VOL,y0		; aspiration volume
	jsr	convert_to_amp
	move	b,y:ASP_VOL

	move	y:FRIC_VOL,y0		; frication volume
	jsr	convert_to_amp
	move	b,y:FRIC_VOL

;; LOAD FILTER COEFFICIENTS DIRECTLY INTO X FILTER MEMORY
	move	#>XC1MEMC,r0		; calculate R1 coefficients
	jsr	calc_res_coef

	move	#>XC2MEMC,r0		; calculate R2 coefficients
	jsr	calc_res_coef

	move	#>XC3MEMC,r0		; calculate R3 coefficients
	jsr	calc_res_coef

	move	#>XC4MEMC,r0		; calculate R4 coefficients
	jsr	calc_res_coef

	move	#>XFRMEMC,r0		; calculate frication coefficients
	jsr	calc_res_coef

	move	y:(r5)+,x1		; nasal notch filter
	move	x1,x:XNNFMEMA		; move A coefficient into x memory
	move	x1,x:XNNFMEMA2		; move A coefficient into x memory
	move	y:(r5)+,x1
	move	x1,x:XNNFMEMB		; move B coefficient into x memory
	move	y:(r5)+,x1
	move	x1,x:XNNFMEMC		; move C coefficient into x memory
	move	y:(r5)+,x1
	move	x1,x:XNNFMEMD		; move D coefficient into x memory

;; INCREMENT POINTER AND DECREMENT TABLE COUNT
	move	#>1,x1			; table_count -= 1
	move	x:x_tableCount,a
	sub	x1,a	y:(r5)+n5,y1	; skip to start of next table (y1 not used)
	move	a,x:x_tableCount

;; CALCULATE PHASE INCREMENT FROM INT AND FRAC PARTS
	clr	a
	move	y:PHASE_INC_FRAC,a0	; get frac. part of inc. from input table
	asl	a			; get rid of sign bit, left justify
	move	y:PHASE_INC_INT,a1	; get integer part of increment
	move	a10,l:l_phaseInc	; store phase angle increment

;; CALCULATE DELTA VALUE FOR LINEAR AMPLITUDE INTERPOLATION
	clr	b	x:x_curAmpl,x1
	move	y:OSC_VOL,b
	sub	x1,b			; x = OSC_VOL - currentAmpl
	move	b,x0	y:y_divisor,y0	; put divisor into y0
	mpyr	x0,y0,b
	move	b,y:y_deltaAmpl		; deltaAmpl = x * 1/44 (or 1/45)

	rts



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;  READ_DMA_BUFFER SUBROUTINE:  reads one complete DMA from
;;  the host, and puts it in the dma input buffer.

read_DMA_buffer
	bclr	#m_hrie,x:m_hcr		; Disable the host receive interrupt.
					; since the following values are samples...

	move	#>DMA_IN_BUFFER,r5		; set pointer to dma input buffer
	bclr	#DMA_IN_ACCEPTED,x:x_STATUS_flags	; clear accepted flag
	bclr	#DMA_IN_DONE,x:x_STATUS_flags	; clear dma-in done flag

	writeHost #DMA_IN_REQ			; send dma-in request to host

_ready	jclr	#DMA_IN_ACCEPTED,x:x_STATUS_flags,_ready	; loop until host ready


	move	#>DMA_IN_SIZE,b
	do	b,_end_DMA_loop			; loop until buffer filled
_high	 jclr	#m_hrdf,x:m_hsr,_high		; wait until we can read
	 movep	x:m_hrx,x1			; get high order 16 bits
	
	 shiftLeft x1,y1,16,a			; shift left two bytes
	 move	a0,x1				; result of shift is in a0

_low	 jclr	#m_hrdf,x:m_hsr,_low		; get low order 16 bits
	 movep	x:m_hrx,a			; and put in A1 (A2 and A0 clear)
	 or	x1,a				; add the high order 8 bits into A1

	 move	x1,x:x_temp2
	 jclr   #23,x:x_temp2,_no_correct 	; if necessary, do sign extension
	   move	#>$FF,a2
_no_correct
	 move	a,y:(r5)+		; put data into dma input buffer
_end_DMA_loop


	jclr	#m_hrdf,x:m_hsr,_then	; Continue reading incoming (junk) data...
	move	x:m_hrx,x0		; until dma-in complete signalled by host
_then
	jclr	#DMA_IN_DONE,x:x_STATUS_flags,_end_DMA_loop

	bset	#m_hrie,x:m_hcr		; Enable the host receive interrupt.
	rts




;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;  DMA_IN_ACCEPTED INTERRUPT SERVICE ROUTINE:  called when the host is 
;;  ready to send the samples.  It reads an integer.

dma_in_accepted
	readHost x:x_temp			; The host sends a integer.
	bset	#DMA_IN_ACCEPTED,x:x_STATUS_flags	; But we don't really need it.
	rti




;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;  RESONATOR SUBROUTINE

resonator
	clr	b	x:(r0)+,x0  y:(r4)+,y0	;                C -> x0, y(n-2) -> y0
	mpy	x0,y0,b x:(r0)+,x0  y:(r4)+,y0	; b = C*y(n-2),  B -> x0, y(n-1) -> y0
	mac	x0,y0,b	x:(r0)+,x0  a,y0	; b += B*y(n-1), A -> x0, x(n) -> y0
	mac	x0,y0,b				; b += A*x(n)
	asl	b				; b *= 2
	rnd	b				; round b to 24 bit result
	move	b,a				; put result to output
	move	b,y:(r4)-			; put result to y(n)
	rts


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;  NOTCH_FILTER SUBROUTINE

notch_filter
	move	a,y1	  x:(r0)+,x0			; y1 = x(n) (input), x0 = a
	mpy	x0,y1,a	  x:(r0)+,x0	y:(r4)+,y0	; A = a*x(n)
	mac	x0,y0,a	  x:(r0)+,x0	y:(r4),y0	; A = A + b*x(n-1)
	mac	x0,y0,a	  x:(r0)+,x0	y:(r6)+,y0	; A = A + a*x(n-2)
	mac	x0,y0,a	  x:(r0)+,x0	y:(r6),y0	; A = A + c*y(n-1)
	mac	x0,y0,a	  x:(r0),x0	y1,y:(r4)	; A = A + d*y(n-2)
	asl	a					; A = 2A
	rnd	a					; round A
	move		  		a,y:(r6)	; store y(n)
	rts


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;  CONVERT_TO_AMP SUBROUTINE

convert_to_amp
	move	#>64,x1		; move scaling factor into x1
	mpy	y0,x1,a		; mult. input by scaling factor
	lsl	a				; put sign bit into a0 and
	asr	a	#>l_dbToAmpTable,b	; get conversion table base

	move	a1,y0		; get the table offset
	add	y0,b		; and add it to the table base
	move	b,r4		; and put the result into r4

	move	a0,x1		; get the fractional part of the scaled input
	move	x:(r4),b	; get the ampl value of the int part of the input
	move	y:(r4),y1	; get the corresponding delta value
	macr	x1,y1,b		; add frac * delta to b

	rts


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;  SUBROUTINE TO GET R FUNCTION (INPUT IN Y0, OUTPUT IN B)

rfunction
	move	#>rTableSize-1,x1	; move scaling factor into x1
	mpy	y0,x1,a			; mult. input by scaling factor
	asl	a			; multiply by 2
	lsl	a			; put sign bit into a0 and
	asr	a	#>l_rTable,b	; get conversion table base

	move	a1,y0		; get the table offset
	add	y0,b		; and add it to the table base
	move	b,r4		; and put the result into r4

	move	a0,x1		; get the fractional part of the scaled input
	move	x:(r4),b	; get the ampl value of the int part of the input
	move	y:(r4),y1	; get the corresponding delta value
	macr	x1,y1,b		; add frac * delta to b

	rts


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;  SUBROUTINE TO CALCULATE SIN FUNCTION (INPUT IN Y0, OUTPUT IN B)

sinTableSize	equ	256
sinTableBase	equ	$100

sin
	move	#$FFFF,m4	; set linear modulus

	move	#>sinTableSize,x1		; move scaling factor into x1
	mpy	y0,x1,a				; mult. input by scaling factor
	lsl	a				; put sign bit into a0 and
	asr	a	#>sinTableBase,b	; get conversion table base

	move	a1,y0		; get the table offset
	add	y0,b		; and add it to the table base
	move	b,r4		; and put the result into r4

	move	a0,x1		; get the fractional part of the scaled input
	move	y:(r4)+,b	; get the ampl value from the sine table
	move	y:(r4),a	; get the next value in the table
	sub	b,a		; calculate the table delta (a = a - b)
	move	a,y1		; move the delta into y1
	macr	x1,y1,b		; add frac * delta to base amplitude value

	move	#>R_FILTERSIZE-1,m4	; restore m4 modulus
	rts


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;  SUBROUTINE TO CALCULATE RESONATOR COEFFICIENTS
;;
;;  scaled frequency in y:(r5)		; frequency/sample_rate
;;  scaled bandwidth in y:(r5)+1	; bandwidth/nyquist_rate
;;
;;  coefficient C put in x:(r0)
;;  coefficient B put in x:(r0)+1
;;  coefficient A put in x:(r0)+2

calc_res_coef
	move	y:(r5)+,y0		; get scaled frequency
	move	#SINE_OFFSET,a		; add pi/2, so that cosine(freq) is
	add	y0,a			; calculated with the sine function
	move	a,y0

	jsr	sin			; calculate sine of frequency
	move	b,x:x_temp3		; store sine value

	move	y:(r5)+,y0		; get scaled bandwidth
	jsr	rfunction		; calculate r function of bandwidth

	move	b,y0			; move r to y0
	mpyr	-y0,y0,b		; b = -r*r
	asr	b	x:x_temp3,x0	; C = -(r*r)/2;  put sine(freq) into x0
	move	b,x:(r0)+		; store coefficient C

	mpyr	y0,x0,a			; B = r * sine(freq)
	move	a,x:(r0)+		; store coefficient B

	neg	a			; B *= (-1)
	sub	b,a	#@cvf(0.5),y1	; B -= C
	add	y1,a			; A = 0.5 - B - C
	move	a,x:(r0)+		; store coefficient A

	rts
