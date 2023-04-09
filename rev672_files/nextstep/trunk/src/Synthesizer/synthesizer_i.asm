	NOLIST
;***************************************************************************************
;  FORMATTING FOR LISTING FILE
;***************************************************************************************

	page 144,70,0,0,0	; width, height, top margin, bottom margin, left margin
	opt cex,mex,mu,nocc	; dc expansions, macro expansions, (cross
				; reference,) memory usage, cycle usage reports
	lstcol 23,13,6,1,1	; label, opcode, operand, x, y field widths


	LIST	
;  REVISION INFORMATION ****************************************************************
;
;  $Author: rao $
;  $Date: 2002-03-21 16:49:54 $
;  $Revision: 1.1 $
;  $Source: /Users/dalmazio/cvsroot/gnuspeech/trillium/src/Synthesizer/synthesizer_i.asm,v $
;  $State: Exp $
;
;
;  $Log: not supported by cvs2svn $
;; Revision 1.8  1994/10/20  22:41:08  len
;; Adjusted the output volume upwards, and made 1 channel output the same as
;; stereo output with the balance at 0.0.
;;
;  Revision 1.7  1994/10/03  18:13:12  len
;  Altered some routines that use r3 and r4, so that they are now consistent
;  with the same routines in the tube_module.
;
;  Revision 1.6  1994/09/26  22:02:03  len
;  Optimized crossmix calculations.
;
;  Revision 1.5  1994/09/19  03:05:35  len
;  Resectioned the TRM to 10 sections in 8 regions.  Also
;  changed friction injection to be continous from sections
;  3 to 10.
; 
;  Revision 1.4  1994/09/13  21:42:43  len
;  Folded in optimizations made in synthesizer.asm.
;
;  Revision 1.3  1994/07/13  03:40:04  len
;  Added Mono/Stereo sound output option and changed file format.
;
;  Revision 1.2  1994/06/17  21:06:30  len
;  Fixed a bug which occasionally led to interrupted sound out.
;
;  Revision 1.1.1.1  1994/05/20  00:21:55  len
;  Initial archive of TRM interactive Synthesizer.
;
;
;***************************************************************************************
;
;  Program:	synthesizer_i.asm
;
;  Author:	Leonard Manzara
;
;  Date:	September 13th, 1994
;
;  Summary:	Added the optimizations done in synthesizer.asm.  This version
;               can now go down to tube lengths of about 12.8 cm.
;
;		Copyright (C) by Trillium Sound Research Inc. 1994
;		All Rights Reserved
;
;***************************************************************************************


;***************************************************************************************
;  COMPILATION FLAGS
;***************************************************************************************

;  THESE MUST MATCH THE FLAGS IN synthesizer_module.h
OVERSAMPLE_OSC	set	1	; 1 to use 2x oversampling oscillator
VARIABLE_GP	set	1	; 1 for variable shaped glottal pulse
FIXED_CROSSMIX	set	0	; 1 for fixed crossmix offset (60 dB)
SYNC_DMA	set	1	; 1 for synchronous dma output (instead of async)

;  THESE FLAGS ARE USED FOR LOCAL EXPERIMENTATION AND DEBUGGING
DEBUG_56	set	0	; 1 for use with Bug56


	NOLIST
;***************************************************************************************
;  INCLUDE FILES
;***************************************************************************************

	include	'ioequlc.asm'


	LIST
;***************************************************************************************
;  ORIGINS FOR PROGRAM MEMORY
;***************************************************************************************

	IF !DEBUG_56
ON_CHIP_PROGRAM_START	equ	$40
	ELSE
ON_CHIP_PROGRAM_START	equ	$A0
	ENDIF

OFF_CHIP_PROGRAM_START	equ	$2000



;***************************************************************************************
;  INTERRUPT AND HOST COMMAND VECTORS
;***************************************************************************************

VEC_RESET		equ	$00	; reset vector
VEC_TRANSMIT_DATA	equ	$22	; asynchronous dma-out vector
VEC_DMA_OUT_DONE	equ	$24	; host command: dma-out complete
VEC_DMA_IN_DONE		equ	$28	; host command: dma-in complete
VEC_DMA_IN_ACCEPTED	equ	$2C	; host command: dma-in request accepted
VEC_LOAD_DATATABLE	equ	$30	; host command: load in datatable
VEC_START               equ	$32	; host command: start synthesizing
VEC_STOP                equ	$34	; host command: stop synthesizing
VEC_LOAD_FIR_COEF       equ	$36	; host command: load in FIR coefficients
VEC_LOAD_SRC_COEF       equ	$38	; host command: load in SRC coefs. & deltas
VEC_LOAD_WAVETABLE	equ	$3A	; host command: load in wavetable
VEC_LOAD_UR_DATA        equ	$3C     ; host command: load in utterance-rate params.



;***************************************************************************************
;  MACRO:	writeHost
;
;  Writes one word from the 'source' register to the host.
;
;  Parameters:	source
;***************************************************************************************

writeHost macro source
_one	jclr	#m_htde,x:m_hsr,_one	
	movep	source,x:m_htx
	endm
	


;***************************************************************************************
;  MACRO:	readHost
;
;  Reads one word from the host and puts it into the 'dest' register.
;
;  Parameters:	dest
;***************************************************************************************

readHost macro	dest
_two	jclr	#m_hrdf,x:m_hsr,_two	
	movep	x:m_hrx,dest
	endm



;***************************************************************************************
;  MACRO:	shiftLeft
;
;  Simulates a bitwise shift left using multiplication, with the result in the lower
;  part of the accumulator.
;
;  Parameters:	s   = source register (x0,x1,y0,or y1)
; 		m   = the multiplier register (x0,x1,y0,or y1)
;		n   = the number of bits to be shifted
;		acc = the destination accumulator (a or b)
;***************************************************************************************

shiftLeft macro s,m,n,acc
	move	#>@cvi(@pow(2,n-1)),m
	mpy	s,m,acc
	endm

	

;***************************************************************************************
;  MACRO:	dbToAmpTable
;
;  This macro creates a table of size+1 points in each of x and y memory.  X memory
;  is filled with the values to convert from dB to amplitude, for the range 0 to
;  max dB.  Y memory is filled with the delta between the x+1 value and the x value.
;  This allows efficient interpolation between x table values.  Note that the dB
;  values are actually made to range from -max to 0 dB (to permit correct calculation
;  using the power function), and that -max dB is set to 0.0, so that 0 dB actually
;  corresponds to an amplitude of 0 (and not some very small number).
;
;  Parameters:	size
;***************************************************************************************

dbToAmpTable	macro	size

;  RECORD THE ORIGIN FROM THE CURRENT COUNTER VALUE
origin	set	@lcv(R)

;  THE TABLE HAS max+1 ENTRIES
max	set	size

;  CREATE THE dbToAmp CONVERSION VALUE FOR 0 TO max dB
	org	x:origin
	dc	0.0
count	set	1
	dup 	max
value	set	@min(@pow(10.0,@cvf(count-max)/20.0),0.9999998)
	dc	value
count	set	count+1
	endm

;  CREATE THE DELTA VALUES BETWEEN ADJACENT X TABLE VALUES
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



;***************************************************************************************
;  MACRO:	betaTable
;
;  This macro creates a table used to find the beta coefficient for a bandpass
;  filter.  The actual values for the function are put into Y memory.  The formula
;  for the beta function is:
;
;  	beta = (0.5) * (1 - tan(bw_value)) / (2 * (1 + tan(bw_value)))
;
;  where bw_value is a number between 0 and PI (nyquist).
;
;  Parameters:	size
;***************************************************************************************

betaTable	macro	size

;  RECORD THE ORIGIN FROM THE CURRENT COUNTER VALUE
origin		set	@lcv(R)

;  SET PI
PI		set	3.141592653589793

;  RECORD THE SIZE OF THE TABLE
betaTableSize	set	size

;  CALCULATE THE VALUES FOR THE TABLE FROM BEGINNING TO END
		org	y:origin
count		set	0
		dup	betaTableSize
tanVal		set	@tan(PI*@cvf(count)/(@cvf(betaTableSize-1)*2.0))
value		set	(1.0-tanVal)/(2.0*(1.0+tanVal))
		dc	value
count		set	count+1
		endm

		endm



;***************************************************************************************
;  MISC. CONSTANTS
;***************************************************************************************

SEED			equ	0.7892347	; constants for noise generator
FACTOR			equ	377
CROSSMIX_SCALE  	equ	5               ; 2^5 = 32
POSITION_SCALE		equ	8
VT_SCALE		equ	@pow(2,-5.0)
ONE			equ	1
UNITY			equ	0.9999998
MAX			equ	$00FFFF



;***************************************************************************************
;  DMA MESSAGES
;***************************************************************************************

DMA_OUT_REQ		equ	$050001		; message to host to request dma-OUT
DMA_IN_REQ		equ	$040002		; message to host to request dma-IN 



;***************************************************************************************
;  STATUS FLAG BITS
;***************************************************************************************

DMA_OUT_DONE		equ	0		; indicates dma-out is complete
DMA_IN_DONE		equ	1		; indicates dma-in is complete
DMA_IN_ACCEPTED 	equ	2		; indicates dma-in accepted by host
RUN_STATUS		equ	3		; indicates if synth to run
VT_BRANCH		equ	4		; indicates which VT branch to take
PARAM_UPDATE		equ	5		; indicates if parameters need updating



;***************************************************************************************
;  ON-CHIP LONG MEMORY
;  Long memory occupies both x and y memory, so no x or y variables
;  are allowed in this space.
;***************************************************************************************

	org		l:$001C
l_timeReg		ds		1
l_timeRegInc		ds		1
l_phaseInc		ds		1
l_currentPhase		ds		1

	org		l:$0080
l_dbToAmpTable		dbToAmpTable	60	; dB to amplitude conversion table

	org		l:$00BF
l_a_save		ds		1	;  fits at end of dbToAmpTable

	org		l:$00C0
l_FIR_base		dsm		64	; memory for the oscillator FIR filter
temp_betaTable		equ	l_FIR_base	; FIR memory is used temporarily to
						; store the betaTable when loading


;***************************************************************************************
;  ON-CHIP X MEMORY
;***************************************************************************************

	org		x:$0000
x_STATUS_flags		ds	1	; status flags (use $00 for use with jset)
x_ngs_signal		ds	1
x_lpn_signal		ds	1
x_fric_sig		equ	x_lpn_signal	; fric signal uses lpn to save space

x_FIR_mod		ds	1
FIR_x_ptr		ds	1
FIR_y_ptr		ds	1
x_tableMod		ds	1

ALPHA			ds	1
BETA			ds	1
GAMMA			ds	1

fa10			ds	1
fb11			ds	1
fa20			ds	1
fa21			ds	1
fb21			ds	1

x_temp2			ds	1

nfa10			ds	1
nfb11			ds	1
nfa20			ds	1
nfa21			ds	1
nfb21			ds	1

dma_fill_base		ds	1
mask_l			dc	L_MASK
base_diff		dc	BASE_DIFF
fbase_addr		dc	filter_base
vtScale			ds	1
coeff_mem		dc	OPC_1
tap_mem			dc	y_tap0


;  TUBE MEMORY
	org		x:$0020
S1_TA			ds	1
S1_BA			ds	1
S2_TA			ds	1
S2_BA			ds	1
S3_TA			ds	1
S3_BA			ds	1
S4_TA			ds	1
S4_BA			ds	1
S5_TA			ds	1
S5_BA			ds	1
S6_TA			ds	1
S6_BA			ds	1
S7_TA			ds	1
S7_BA			ds	1
S8_TA			ds	1
S8_BA			ds	1
S9_TA			ds	1
S9_BA			ds	1
S10_TA			ds	1
S10_BA			ds	1
N1_TA			ds	1
N1_BA			ds	1
N2_TA			ds	1
N2_BA			ds	1
N3_TA			ds	1
N3_BA			ds	1
N4_TA			ds	1
N4_BA			ds	1
N5_TA			ds	1
N5_BA			ds	1
N6_TA			ds	1
N6_BA			ds	1


	org		x:$0040
;  SCATTERING JUNCTION COEFFICIENTS:  MUST BE CONTIGUOUS MEMORY
OPC_1			ds	1	; control-rate scattering coefficients
OPC_2			ds	1
OPC_3			ds	1
ALPHA_L			ds	1
ALPHA_R			ds	1
ALPHA_T			ds	1
OPC_4			ds	1
OPC_5			ds	1
OPC_6			ds	1
OPC_7			ds	1
OPC_REFL		ds	1
OPC_RAD			ds	1
NC_1			ds	1

NC_2			ds	1	; utterance-rate scattering coefficients
NC_3			ds	1
NC_4			ds	1
NC_5			ds	1
NC_REFL			ds	1
NC_RAD			ds	1


;  MISC VARIABLES
dma_empty_base		ds	1
x_x0_save		ds	1
x_r4_save		ds	1
x_tnDelta		ds	1
x_div1			ds	1
x_div2			ds	1
x_newDiv2		ds	1
x_temp			ds	1
x_FIR_size		ds	1



;***************************************************************************************
;  ON-CHIP Y MEMORY
;***************************************************************************************

	org		y:$0000
BREATHINESS		ds	1
DAMPING			ds	1
PULSE_MODULATION	ds	1

OSC_AMP			ds	1
MASTER_AMP		ds	1
ANTI_BREATHINESS	ds	1

y_bp_xn1		ds	1
y_bp_xn2		ds	1
y_bp_yn1		ds	1
y_bp_yn2		ds	1

mRadiationX		ds	1
mRadiationY		ds	1
nRadiationX		ds	1
nRadiationY		ds	1

ta0			ds	1
tb1			ds	1
throatY			ds	1
throatGain		ds	1

y_seed			dc	SEED
y_factor		dc	FACTOR
y_one			dc	ONE
y_unity			dc	UNITY
y_max			dc	MAX

BALANCE_R               ds	1
BALANCE_L               ds	1

crossmix		ds	1
anti_crossmix		ds	1


;  TUBE MEMORY
	org		y:$0020
S1_TB			ds	1
S1_BB			ds	1
S2_TB			ds	1
S2_BB			ds	1
S3_TB			ds	1
S3_BB			ds	1
S4_TB			ds	1
S4_BB			ds	1
S5_TB			ds	1
S5_BB			ds	1
S6_TB			ds	1
S6_BB			ds	1
S7_TB			ds	1
S7_BB			ds	1
S8_TB			ds	1
S8_BB			ds	1
S9_TB			ds	1
S9_BB			ds	1
S10_TB			ds	1
S10_BB			ds	1
N1_TB			ds	1
N1_BB			ds	1
N2_TB			ds	1
N2_BB			ds	1
N3_TB			ds	1
N3_BB			ds	1
N4_TB			ds	1
N4_BB			ds	1
N5_TB			ds	1
N5_BB			ds	1
N6_TB			ds	1
N6_BB			ds	1


;  FRICATION TAP MEMORY
	org		y:$0040
y_tap0			ds	1
y_tap1			ds	1
y_tap2			ds	1
y_tap3			ds	1
y_tap4			ds	1
y_tap5			ds	1
y_tap6			ds	1
y_tap7			ds	1
y_tapGuard		ds	1
NUMBER_TAPS		equ	8


;  MISC. VARIABLES
TP			ds	1
TN_MIN			ds	1
TN_MAX			ds	1
endPtr			ds	1
CONTROL_PERIOD          ds	1
ASP_AMP			ds	1



;***************************************************************************************
;  OFF-CHIP X, Y AND PROGRAM MEMORY (CANNOT BE OVERLAID)
;
;  $2000 - $3FFF	(8192)		total offchip memory
;
;  $2000 - $22FF	(768)		reserved program memory
;
;  $2300 - $237F	(128)		free memory
;
;  $23C0 - 23FF		(64)		beta table (initialized in reset)
;
;  $2400 - $24FF	(256)		gp waveform table memory
;
;  $2500 - $2A7F	(1664)		SRC filter coefficients
;  $2B80 - $31FF	(1664)		SRC filter deltas
;  $3200 - $33FF	(512)		SRC buffer
;
;				      If synchronous dma out:
;  $3400 - $37FF	(1024)		DMA output buffer
;				      If asynchronous dma out:
;  $3400 - $35FF	(512)		DMA output buffer 1	
;  $3600 - $37FF	(512)		DMA output buffer 2	
;
;  $3800 - $3FFF	(2048)		DMA input buffer		
;
;***************************************************************************************

;  WAVETABLE MEMORY ALLOCATION (MUST AGREE WITH HOST)
SINE_TABLE_SIZE		equ	256
GP_TABLE_SIZE		equ	256

;  SAMPLE RATE CONVERSION BUFFER MEMORY ALLOCATION (MUST AGREE WITH HOST)
PADSIZE			equ	26
L_BITS			equ	6
L_RANGE			equ	@cvi(@pow(2,L_BITS))
L_MASK			equ	@cvi(L_RANGE-1)
N_SCALE			equ	@pow(2,-L_BITS)
FILTER_SIZE		equ	@cvi(PADSIZE*L_RANGE)
BASE_DIFF		equ	FILTER_SIZE
SRC_BUFFER_SIZE		equ	512

;  DMA OUTPUT BUFFERS MEMORY ALLOCATION (MUST AGREE WITH HOST)
	IF SYNC_DMA
DMA_OUT_SIZE    	equ     1024
	ELSE
DMA_OUT_SIZE    	equ     512
	ENDIF

;  DMA INPUT BUFFER MEMORY ALLOCATION (MUST AGREE WITH HOST)
DMA_IN_SIZE		equ	2048		; size of input buffer


;  ACTUAL MEMORY ALLOCATION
	org		y:$0100
sine_wave_table		dsm	SINE_TABLE_SIZE


;  BETA TABLE IS CREATED IN LOW MEMORY, AND LATER MOVED TO OFF-CHIP MEMORY
	org		y:temp_betaTable
			betaTable	64
	org		y:$23C0
l_betaTable		ds		64	; beta function table


gp_wave_table		dsm	GP_TABLE_SIZE

filter_base		ds	FILTER_SIZE
filter_d_base		ds	FILTER_SIZE
src_buffer_base		dsm	SRC_BUFFER_SIZE

	IF SYNC_DMA
dma_out_buffer		dsm	DMA_OUT_SIZE
	ELSE
dma_out_buffer1		dsm	DMA_OUT_SIZE		; dma output buffer 1
dma_out_buffer2		dsm	DMA_OUT_SIZE		; dma output buffer 2
	ENDIF

dma_in_buffer		dsm	DMA_IN_SIZE
DATA_TABLE		equ	dma_in_buffer
DATA_TABLE_SIZE		equ	44



;***************************************************************************************
;  REGISTER USE:
;
;	r0	m0	n0	waveform table pointers
;	r1	m1		SRC index for dataEmpty
;	r2	m2		DMA buffer empty pointer
;	r3	m3	n3	general (unprotected) use; m3 left at linear ($FFFF)
;	r4	m4	n4	general (unprotected) use; m4 left at linear ($FFFF)
;	r5	m5	n5	SRC fillPtr for dataFill and dataEmpty	
;	r6	m6		DMA buffer fill pointer
;	r7	m7	n7	SRC emptyPtr for dataFill and DataEmpty
;
;***************************************************************************************

	NOLIST
	lstcol
	lstcol	,,,14,14	; change lising format slightly
	opt cc			; enable cycle usage reports
	LIST

;***************************************************************************************
;  INTERRUPT VECTORS
;***************************************************************************************

	IF !DEBUG_56

	org	p:VEC_RESET
	jmp	reset

	IF SYNC_DMA
	org	p:VEC_TRANSMIT_DATA		; synchronous DMA-out
	nop
	nop

	org	p:VEC_DMA_OUT_DONE		; DMA-OUT completed.
	bset	#DMA_OUT_DONE,x:x_STATUS_flags
	nop

	ELSE
	org	p:VEC_TRANSMIT_DATA		; asynchronous DMA-out
	movep	y:(r2)+,x:m_htx
	nop

	org	p:VEC_DMA_OUT_DONE		; DMA-OUT completed.
	bclr	#m_htie,x:m_hcr
	nop
	ENDIF

	org	p:VEC_DMA_IN_DONE		; DMA-IN completed.
	bset	#DMA_IN_DONE,x:x_STATUS_flags
	nop
		
	org	p:VEC_DMA_IN_ACCEPTED		; DMA-IN accepted: start reading.
	jsr	dma_in_accepted

	org	p:VEC_LOAD_DATATABLE		; load in datatable from host
	jsr	load_datatable

	org	p:VEC_START			; signal to start synthesizing
	bset	#RUN_STATUS,x:x_STATUS_flags
	nop

	org	p:VEC_STOP			; signal to stop synthesizing
	bclr	#RUN_STATUS,x:x_STATUS_flags
	nop

	org	p:VEC_LOAD_FIR_COEF		; load in FIR coefficients from host
	jsr	load_fir_coefficients

	org	p:VEC_LOAD_SRC_COEF		; load in SRC coefficients from host
	jsr	load_src_coefficients

	org	p:VEC_LOAD_WAVETABLE		; load in glottal pulse wavetable
	jsr	load_wavetable

;;	org	p:VEC_LOAD_UR_DATA		; load in utterance-rate parameters
;;	jsr	load_ur_parameters

	ENDIF



	org	p:ON_CHIP_PROGRAM_START

;***************************************************************************************
;  MAIN LOOP
;
;  This is where samples are created.  The loop does not advance if the run status
;  bit is clear.  If a new table of parameters has been read in, its data is used
;  to update the synthesizer parameters.
;
;***************************************************************************************

main	jclr	#RUN_STATUS,x:x_STATUS_flags,main	; loop here if not running

;  UPDATE PARAMETERS, IF A TABLE HAS JUST BEEN LOADED
	jsset	#PARAM_UPDATE,x:x_STATUS_flags,update_parameters



;***************************************************************************************
;  ROUTINE:	lp_noise
;
;  Generates lowpass-filtered noise, using a linear-congruence pseudo-random number
;  generator, and a one-zero low pass filter (zero at PI).
;
;  Input: 	none
;  Output:	x:x_lpn_signal (and also in b)
;***************************************************************************************

	move	y:y_seed,x0		; seed -> x0
	move	y:y_factor,y0		; factor -> y0
	mpy	x0,y0,a  		; a = seed * factor
	asr	a			; a0 = randomly signed fraction from -1 to +1
	move	a0,b			; put new random number in b
	add	x0,b	a0,y:y_seed	; b = x[n] + x[n-1]	store new random number
	asr	b			; b /= 2
	move	b,x:x_lpn_signal	; store low pass noise signal



	IF OVERSAMPLE_OSC
;***************************************************************************************
;  ROUTINE:	oversampling_oscillator
;
;  A 2X oversampling oscillator, where decimation is performed with an FIR filter.
;
;  Input:	none
;  Output:	a
;***************************************************************************************

;  SET UP REGISTERS FOR FIR FILTER
	move	x:x_FIR_mod,m3
	move	x:x_FIR_mod,m4

;  GENERATE ONE SAMPLE USING LINEAR INTERPOLATING OSCILLATOR
	move	l:l_currentPhase,a	; current phase angle -> a
	move	l:l_phaseInc,b		; phase angle increment -> b
	add	b,a	x:x_tableMod,x1	; calc new current phase angle
					; uses 48 bit addition (int.frac)
	and	x1,a	y:y_one,y1	; wrap integer part of current phase
					; to keep within table boundaries
	move	a,n0			; put int part of CPA into register n0
	add	y1,a 	a,l:l_currentPhase	; store new current phase angle & add 1
	and	x1,a	y:(r0+n0),y1		; wrap integer part of phase & get f(n)
	move	a,n0			; put int part of incremented CPA into n0
	move	#0,a1			; zero upper part of a
	move	y:(r0+n0),b		; get value of f(n+1)
	sub	y1,b	x:FIR_x_ptr,r3	; diff = f(n+1) - f(n)   set r3 for FIR filter
	asr	a	b,x0		; shift frac right since no sign bit
					; put diff in x0 register
	tfr	y1,a	a0,x1		; put f(n) in a; put frac. of CPA into x1
	macr	x0,x1,a	l:l_phaseInc,b	; a = f(n) + (diff * CPA(frac))  phaseInc -> b

;  MOVE THIS SAMPLE INTO THE INPUT OF THE FIR FILTER
	move	a,x:(r3)-		; put sample into input of FIR filter

;  GENERATE SECOND SAMPLE USING LINEAR INTERPOLATING OSCILLATOR
	move	l:l_currentPhase,a	; current phase angle -> a
	add	b,a	x:x_tableMod,x1	; calc new current phase angle
					; uses 48 bit addition (int.frac)
	and	x1,a	y:y_one,y1	; wrap integer part of current phase
					; to keep within table boundaries
	move	a,n0			; put int part of CPA into register n0
	add	y1,a 	a,l:l_currentPhase	; store new current phase angle & add 1
	and	x1,a	y:(r0+n0),y1		; wrap integer part of phase & get f(n)
	move	a,n0			; put int part of incremented CPA into n0
	move	#0,a1			; zero upper part of a
	move	y:(r0+n0),b		; get value of f(n+1)
	sub	y1,b	x:FIR_y_ptr,r4	; diff = f(n+1) - f(n)   set r4 for FIR filter
	asr	a	b,x0		; shift frac right since no sign bit
					; put diff in x0 register
	tfr	y1,a	a0,x1		; put f(n) in a; put frac. of CPA into x1
	macr	x0,x1,a			; a = f(n) + (diff * CPA(frac)),

;  FILTER THE TWO SAMPLES USING THE FIR FILTER
	clr	a	a,x:(r3)+	y:(r4)+,y0
	do x:x_FIR_mod,_end_loop
	 mac	x0,y0,a	x:(r3)+,x0	y:(r4)+,y0
_end_loop
	macr	x0,y0,a	(r3)-

;  STORE REGISTERS FOR FIR FILTER
	move	r3,x:FIR_x_ptr
	move	r4,x:FIR_y_ptr
	move	y:y_max,m3
	move	y:y_max,m4		; output in a is decimated signal



	ELSE
;***************************************************************************************
;  ROUTINE:	oscillator  (non-oversampling)
;
;  Non-oversampling linear interpolating wavetable oscillator.
;
;  Input:	none
;  Output:	a
;***************************************************************************************

;  GENERATE ONE SAMPLE USING LINEAR INTERPOLATING OSCILLATOR
	move	l:l_currentPhase,a	; current phase angle -> a
	move	l:l_phaseInc,b		; phase angle increment -> b
	add	b,a	x:x_tableMod,x1	; calc new current phase angle
					; uses 48 bit addition (int.frac)
	and	x1,a	y:y_one,y1	; wrap integer part of current phase
					; to keep within table boundaries
	move	a,n0			; put int part of CPA into register n0
	add	y1,a 	a,l:l_currentPhase	; store new current phase angle & add 1
	and	x1,a	y:(r0+n0),y1		; wrap integer part of phase & get f(n)
	move	a,n0			; put int part of incremented CPA into n0
	move	#0,a1			; zero upper part of a
	move	y:(r0+n0),b		; get value of f(n+1)
	sub	y1,b	 		; diff = f(n+1) - f(n)
	asr	a	b,x0		; shift frac right since no sign bit
					; put diff in x0 register
	tfr	y1,a	a0,x1		; put f(n) in a; put frac. of CPA into x1
	macr	x0,x1,a			; a = f(n) + (diff * CPA(frac)),
					; output in a is decimated signal
	ENDIF



;***************************************************************************************
;  ROUTINE:	noisy_glottal_source
;
;  Calculates the noisy glottal source by adding pulsed noise to the glottal source
;  according to the breathiness parameter.
;
;  Input:	a (glottal source), x:x_lpn_signal (lp noise)
;  Output:	x:x_ngs_signal, b (x_lpn_signal), x0 (pulsed noise)
;***************************************************************************************

	move	a,y0	 x:x_lpn_signal,x0	; pulsed noise = lp_noise * gp
	mpyr	x0,y0,a	 a,x1			; glottal source -> x1

	move	a,x0	 y:BREATHINESS,y0	; store pulsed noise signal in x0
	mpy	x0,y0,a	 y:ANTI_BREATHINESS,y1	; a = pulsed noise * breathiness

	macr	x1,y1,a	 y:OSC_AMP,y0		; a += gp * (1.0 - breathiness)
	move	a,x1				; get amplitude factor

	mpyr	x1,y0,a	 x:x_lpn_signal,b	; a = signal * amplitude factor
	move	a,x:x_ngs_signal		; save noisy glottal source signal



;***************************************************************************************
;  ROUTINE:	modulation_switch
;
;  Skips the crossmix_noise routine, if not switched on.  Note that register b contains
;  crossmixed noise if switch on, or plain lp noise if switched off.
;
;***************************************************************************************

	jclr	#0,y:PULSE_MODULATION,_bpfilt	; crossmixed noise in b (preserve!)



;***************************************************************************************
;  ROUTINE:	crossmix_noise
;
;  Crossmixes pulsed noise and low-pass noise, according to the crossmix and
;  anti-crossmix factors (calculated from oscillator amplitude in outer loop).
;
;  Input:	x0 (pulsed noise signal), x:x_lpn_signal
;  Output:	b
;***************************************************************************************

	move	y:crossmix,y0			; ax -> y0
	move	y:anti_crossmix,y1		; (1.0 - ax) -> y1
	mpy	x0,y0,b	 x:x_lpn_signal,x1	; b = ax * pulsed_noise	  lp_noise -> x1
	macr	x1,y1,b				; b += (1.0 - ax) * lp_noise



;***************************************************************************************
;  ROUTINE:	bandpass_filter
;
;  Bandpass filters the input signal, with specified center frequency and bandwidth
;  converted the the filter coefficients ALPHA, BETA, and GAMMA.  Note that this
;  implementation does not use R registers, since using them means more instructions,
;  and fixed locations of filter memory
;
;  Input:	b (b is preserved)
;  Output:	a (and also in y:y_bp_yn1)
;***************************************************************************************

_bpfilt	move	b,y1	 x:ALPHA,x0
	mpy	x0,y1,a			y:y_bp_xn2,y0	; a = alpha * x(n)
	mac    -x0,y0,a	 x:BETA,x0			; a -= alpha * x(n-2)
	move				y:y_bp_yn2,y0	
	mac    -x0,y0,a	 x:GAMMA,x0			; a -= beta * y(n-2)
	move				y:y_bp_yn1,y0
	mac	x0,y0,a			y0,y:y_bp_yn2	; a += gamma * y(n-1)
	asl	a			y:y_bp_xn1,x0	; a *= 2
	rnd	a			x0,y:y_bp_xn2
	move	a,y:y_bp_yn1				; store output
	move	y1,y:y_bp_xn1				; store input
	move	a,x:x_fric_sig				; store frication signal



;***************************************************************************************
;  ROUTINE:	sum_asp_ngs
;
;  Scale the aspiration signal (crossmixed noise) and add it to the noisy
;  glottal source.
;
;  Input:	b (crossmixed noise), x:x_ngs_signal (noisy glottal source)
;  Output:	a (summed signal: also in y:y_bp_yn1), y1 (vtScale)
;***************************************************************************************

	move	b,x0	 y:ASP_AMP,y0		; crossmixed noise -> x0   asp_amp -> y0
	mpyr	x0,y0,a	 x:x_ngs_signal,x1	; a = crossmix_noise * asp_amp
	add	x1,a	 x:vtScale,y1		; a += noisy glottal source  vtScale->y1



;***************************************************************************************
;  ROUTINE:	vocalTract
;
;  Calculates the propagation of the input sample value (the glottis) through the vocal
;  tract, and sums the output from the nose and mouth.
;
;  Input:	a, x:x_fric_sig, y1 (vtScale)
;  Output:	a
;***************************************************************************************

;  SCALE INPUT SO THERE IS NO OVERFLOW
	move	a,x1
	mpy	x1,y1,b		x:coeff_mem,r3	; scaled input -> b	coeff ptr -> r3
	move	x:tap_mem,r4			; set up pointer to tap memory

;  BRANCH TEST
	bchg	#VT_BRANCH,x:x_STATUS_flags		; flip branch bit
	jclr	#VT_BRANCH,x:x_STATUS_flags,_branch	; branch every other time


;  FIRST BRANCH
;  CALCULATE PHARYNX SECTIONS
;  INITIALIZE TOP LEFT OF TUBE
	move	y:DAMPING,x1			; damping -> x1 (x1 not disturbed)
	move	y:S1_BB,y0			; BL_PREV -> y0
	macr	x1,y0,b		y:S1_TB,y0	; b += damping * BL_PREV
	move	x:(r3)+,x0			; coeff -> x0

;  JUNCTION S1 - S2 (R1 - R2)
	mpy	x0,y0,a		y:S2_BB,y1	; a = coeff * TL_PREV
	macr   -x0,y1,a		b,x:S1_TA	; a -= coeff * BR_PREV	  b -> TL_CURR
	mpy	y0,x1,a		a,x0		; a = damping * TL_PREV   x0 = delta
	macr	x0,x1,a		y:S2_TB,y0	; a += damping * delta
	mpy	y1,x1,b		a,x:S2_TA	; b = damping * BR_PREV   a -> TR_CURR
	macr	x0,x1,b		x:(r3)+,x0	; b += damping * delta

;  JUNCTION S2 - S3 (R2 - R3)
	mpy	x0,y0,a		y:S3_BB,y1	; a = coeff * TL_PREV
	macr   -x0,y1,a		b,x:S1_BA	; a -= coeff * BR_PREV    b -> BL_CURR
	mpy	y0,x1,a		a,x0		; a = damping * TL_PREV   x0 = delta
	mac	x0,x1,a		y:S3_TB,y0	; a += damping * delta
	mpy	y1,x1,b		y:(r4)+,y1	; b = damping * BR_PREV   fric_tap0-> y1
	macr	x0,x1,b		x:x_fric_sig,x0	; b += damping * delta    frication-> x0
	macr	y1,x0,a		x:(r3)+,x0	; a += tap0 * frication
	move	a,x:S3_TA			; a -> TR_CURR

;  JUNCTION S3 - S4 (R3 - R4)
	mpy	x0,y0,a		y:S4_BB,y1	; a = coeff * TL_PREV
	macr   -x0,y1,a		b,x:S2_BA	; a -= coeff * BR_PREV    b -> BL_CURR
	mpy	y0,x1,a		a,x0		; a = damping * TL_PREV   x0 = delta
	mac	x0,x1,a		y:N1_BB,y0	; a += damping * delta    n1 B prev-> y0
	mpy	y1,x1,b		y:(r4)+,y1	; b = damping * BR_PREV   fric_tap1-> y1
	macr	x0,x1,b		x:x_fric_sig,x0	; b += damping * delta    frication-> x0
	macr	y1,x0,a		y:S4_TB,x0	; a += tap1 * frication   s4 T prev-> x0
	move	b,x:S3_BA			; b -> BL_CURR
	move	a,x:S4_TA			; a -> TR_CURR

;  CALCULATE 3-WAY JUNCTION:  S4 - S5 - N1 (R4 - N1)
	move	y:S5_BB,x1			; s5 B prev -> x1

	tfr	x1,b		x:(r3)+,y1	; ALPHA_L -> y1
	mpy	x0,y1,a		x:(r3)+,y1	; ALPHA_R -> y1
	mac	x1,y1,a		x:(r3)+,y1	; ALPHA_T -> y1

	macr	y0,y1,a		y:DAMPING,y1
	move	a,x1
	mpy	x1,y1,a
	asl	a		b,x1

	macr   -x0,y1,a		a,b		; left output
	tfr	b,a		a,x:S4_BA	; left output -> s4 B curr

	macr   -y0,y1,b		x:x_fric_sig,y0	; top output

	mac    -x1,y1,a		b,x:N1_TA	; right output   TO -> s5 T curr
	move	x:(r3)+,x0	y:(r4)+,y1	; coeff -> x0    fric_tap2 -> y1
	macr	y1,y0,a		y:S5_TB,y0	; a += tap2 * frication
	move	a,x:S5_TA			; right output -> s5 T curr

;  JUNCTION S5 - S6 (R4 - R5)
	mpy	x0,y0,a		y:S6_BB,y1	; a = coeff * TL_PREV
	macr   -x0,y1,a		y:DAMPING,x1	; a -= coeff * BR_PREV
	mpy	y0,x1,a		a,x0		; a = damping * TL_PREV   x0 = delta
	mac	x0,x1,a		y:S6_TB,y0	; a += damping * delta
	mpy	y1,x1,b		y:(r4)+,y1	; b = damping * BR_PREV	  fric_tap3-> y1
	macr	x0,x1,b		x:x_fric_sig,x0 ; b += damping * delta	  frication-> x0
	macr	y1,x0,a		y:(r4)+,y1	; a += tap3 * frication
	move	a,x:S6_TA			; a -> TR_CURR

;  JUNCTION:  S6 - S7 (R5 internal)
	mpy	y0,x1,a		b,x:S5_BA	; a = TL_PREV * damping
	macr	y1,x0,a		y:S7_BB,y1	; a += tap4 * frication   BR_PREV -> y1
	mpyr	y1,x1,b		a,x:S7_TA	; b = BR_PREV * damping   a -> TR_CURR

;  JUNCTION S7 - S8 (R5 - R6)
	move	x:(r3)+,x0
	move	y:S7_TB,y0
	mpy	x0,y0,a		y:S8_BB,y1	; a = coeff * TL_PREV
	macr   -x0,y1,a		b,x:S6_BA	; a -= coeff * BR_PREV    b -> BL_CURR
	mpy	y0,x1,a		a,x0		; a = damping * TL_PREV   x0 = delta
	mac	x0,x1,a		y:S8_TB,y0	; a += damping * delta
	mpy	y1,x1,b		y:(r4)+,y1	; b = damping * BR_PREV	  fric_tap5-> y1
	macr	x0,x1,b		x:x_fric_sig,x0 ; b += damping * delta	  frication-> x0
	macr	y1,x0,a		x:(r3)+,x0	; a += tap5 * frication
	move	a,x:S8_TA			; a -> TR_CURR

;  JUNCTION S8 - S9 (R6 - R7)
	mpy	x0,y0,a		y:S9_BB,y1	; a = coeff * TL_PREV
	macr   -x0,y1,a		b,x:S7_BA	; a -= coeff * BR_PREV    b -> BL_CURR
	mpy	y0,x1,a		a,x0		; a = damping * TL_PREV   x0 = delta
	mac	x0,x1,a		y:S9_TB,y0	; a += damping * delta
	mpy	y1,x1,b		y:(r4)+,y1	; b = damping * BR_PREV	  fric_tap6-> y1
	macr	x0,x1,b		x:x_fric_sig,x0 ; b += damping * delta	  frication-> x0
	macr	y1,x0,a		x:(r3)+,x0	; a += tap6 * frication
	move	a,x:S9_TA			; a -> TR_CURR

;  JUNCTION S9 - S10 (R7 - R8)
	mpy	x0,y0,a		y:S10_BB,y1	; a = coeff * TL_PREV
	macr   -x0,y1,a		b,x:S8_BA	; a -= coeff * BR_PREV    b -> BL_CURR
	mpy	y0,x1,a		a,x0		; a = damping * TL_PREV   x0 = delta
	mac	x0,x1,a		y:S10_TB,y0	; a += damping * delta
	mpy	y1,x1,b		y:(r4)+,y1	; b = damping * BR_PREV	  fric_tap7-> y1
	macr	x0,x1,b		x:x_fric_sig,x0 ; b += damping * delta	  frication-> x0
	macr	y1,x0,a		x:(r3)+,x0	; a += tap7 * frication
	move	a,x:S10_TA			; a -> TR_CURR
	move	b,x:S9_BA			; b -> BL_CURR

;  MOUTH REFLECTION
	mpyr	y0,x0,b		x:fa10,x0	; b = TL_PREV * coeff	  fa10 -> x0
	move	b,y1		x:fb11,x1	; scaled input -> y1	  fb11 -> x1
	mpy	x0,y1,a		y:S10_BB,y1	; a = fa10 * input	  y[n-1] -> y1
	macr   -x1,y1,a		x:(r3)+,x0	; a -= fb11 * y[n-1]	  radCoeff -> x0
	move	a,x:S10_BA			; a -> BL_CURR

;  MOUTH RADIATION (INPUT IN y0, OUTPUT STORED IN y:mRadiationY)
	mpyr	x0,y0,a		x:fa20,x0	 ; a = TL_PREV * coeff	  fa20 -> x0
	move	a,y0	  	x:fa21,x1	 ; scaled input -> y0	  fa21 -> x1
	mpy	x0,y0,a		y:mRadiationX,y1 ; a = fa20 * input	  x[n-1] -> y1
	mac	x1,y1,a		x:fb21,x1	 ; a += fa21 * x[n-1]	  fb21 -> x1
	move	y:mRadiationY,y1		 ; y[n-1] -> y1
	macr   -x1,y1,a		y0,y:mRadiationX ; a -= fb21 * y[n-1]	  store x[n]
	move	a,y:mRadiationY			 ; store y[n]


;  CALCULATE NOSE SECTIONS
;  JUNCTION N1 - N2
	move	y:N1_TB,y0
	move	x:(r3)+,x0
	mpy	x0,y0,a		y:N2_BB,y1	; a = coeff * TL_PREV
	macr   -x0,y1,a		y:DAMPING,x1	; a -= coeff * BR_PREV
	mpy	y0,x1,a		a,x0		; a = damping * TL_PREV   x0 = delta
	macr	x0,x1,a		y:N2_TB,y0	; a += damping * delta
	mpy	y1,x1,b		a,x:N2_TA	; b = damping * BR_PREV   a -> TR_CURR
	macr	x0,x1,b		x:(r3)+,x0	; b += damping * delta

;  JUNCTION N2 - N3
	mpy	x0,y0,a		y:N3_BB,y1	; a = coeff * TL_PREV
	macr   -x0,y1,a		b,x:N1_BA	; a -= coeff * BR_PREV    b -> BL_CURR
	mpy	y0,x1,a		a,x0		; a = damping * TL_PREV   x0 = delta
	macr	x0,x1,a		y:N3_TB,y0	; a += damping * delta
	mpy	y1,x1,b		a,x:N3_TA	; b = damping * BR_PREV   a -> TR_CURR
	macr	x0,x1,b		x:(r3)+,x0	; b += damping * delta

;  JUNCTION N3 - N4
	mpy	x0,y0,a		y:N4_BB,y1	; a = coeff * TL_PREV
	macr   -x0,y1,a		b,x:N2_BA	; a -= coeff * BR_PREV    b -> BL_CURR
	mpy	y0,x1,a		a,x0		; a = damping * TL_PREV   x0 = delta
	macr	x0,x1,a		y:N4_TB,y0	; a += damping * delta
	mpy	y1,x1,b		a,x:N4_TA	; b = damping * BR_PREV   a -> TR_CURR
	macr	x0,x1,b		x:(r3)+,x0	; b += damping * delta

;  JUNCTION N4 - N5
	mpy	x0,y0,a		y:N5_BB,y1	; a = coeff * TL_PREV
	macr   -x0,y1,a		b,x:N3_BA	; a -= coeff * BR_PREV    b -> BL_CURR
	mpy	y0,x1,a		a,x0		; a = damping * TL_PREV   x0 = delta
	macr	x0,x1,a		y:N5_TB,y0	; a += damping * delta
	mpy	y1,x1,b		a,x:N5_TA	; b = damping * BR_PREV   a -> TR_CURR
	macr	x0,x1,b		x:(r3)+,x0	; b += damping * delta

;  JUNCTION N5 - N6
	mpy	x0,y0,a		y:N6_BB,y1	; a = coeff * TL_PREV
	macr   -x0,y1,a		b,x:N4_BA	; a -= coeff * BR_PREV    b -> BL_CURR
	mpy	y0,x1,a		a,x0		; a = damping * TL_PREV   x0 = delta
	macr	x0,x1,a		y:N6_TB,y0	; a += damping * delta
	mpy	y1,x1,b		a,x:N6_TA	; b = damping * BR_PREV   a -> TR_CURR
	macr	x0,x1,b		x:(r3)+,x0	; b += damping * delta
	move	b,x:N5_BA			; b -> BL_CURR

;  NOSE REFLECTION
	mpyr	y0,x0,b		x:nfa10,x0	; b = TL_PREV * coeff	  fa10 -> x0
	move	b,y1		x:nfb11,x1	; scaled input -> y1	  fb11 -> x1
	mpy	x0,y1,a		y:N6_BB,y1	; a = fa10 * input	  y[n-1] -> y1
	macr   -x1,y1,a		x:(r3)+,x0	; a -= fb11 * y[n-1]	  radCoeff -> x0
	move	a,x:N6_BA			; a -> BL_CURR

;  NOSE RADIATION (INPUT IN y0, OUTPUT STORED IN y:nRadiationY)
	mpyr	x0,y0,a		x:nfa20,x0	 ; a = TL_PREV * coeff	  fa20 -> x0
	move	a,y0	  	x:nfa21,x1	 ; scaled input -> y0	  fa21 -> x1
	mpy	x0,y0,a		y:nRadiationX,y1 ; a = fa20 * input	  x[n-1] -> y1
	mac	x1,y1,a		x:nfb21,x1	 ; a += fa21 * x[n-1]	  fb21 -> x1
	move	y:nRadiationY,y1		 ; y[n-1] -> y1
	macr   -x1,y1,a		y0,y:nRadiationX ; a -= fb21 * y[n-1]	  store x[n]
	move	a,y:nRadiationY			 ; store y[n]

;  GO TO END OF VOCAL TRACT SUBROUTINE
	jmp	_endVT



;  SECOND BRANCH
;  CALCULATE PHARYNX SECTIONS
;  INITIALIZE TOP LEFT OF TUBE
_branch	move	y:DAMPING,x1			; damping -> x1 (x1 not disturbed)
	move	x:S1_BA,y0			; BL_PREV -> y0
	macr	x1,y0,b		x:S1_TA,y0	; b += damping * BL_PREV
	move	x:(r3)+,x0			; coeff -> x0

;  JUNCTION S1 - S2 (R1 - R2)
	mpy	x0,y0,a		x:S2_BA,y1	; a = coeff * TL_PREV
	macr   -x0,y1,a		b,y:S1_TB	; a -= coeff * BR_PREV	  b -> TL_CURR
	mpy	y0,x1,a		a,x0		; a = damping * TL_PREV   x0 = delta
	macr	x0,x1,a		x:S2_TA,y0	; a += damping * delta
	mpy	y1,x1,b		a,y:S2_TB	; b = damping * BR_PREV   a -> TR_CURR
	macr	x0,x1,b		x:(r3)+,x0	; b += damping * delta

;  JUNCTION S2 - S3 (R2 - R3)
	mpy	x0,y0,a		x:S3_BA,y1	; a = coeff * TL_PREV
	macr   -x0,y1,a		b,y:S1_BB	; a -= coeff * BR_PREV    b -> BL_CURR
	mpy	y0,x1,a		a,x0		; a = damping * TL_PREV   x0 = delta
	mac	x0,x1,a		x:S3_TA,y0	; a += damping * delta
	mpy	y1,x1,b		y:(r4)+,y1	; b = damping * BR_PREV   fric_tap0-> y1
	macr	x0,x1,b		x:x_fric_sig,x0	; b += damping * delta    frication-> x0
	macr	y1,x0,a		x:(r3)+,x0	; a += tap0 * frication
	move	a,y:S3_TB			; a -> TR_CURR

;  JUNCTION S3 - S4 (R3 - R4)
	mpy	x0,y0,a		x:S4_BA,y1	; a = coeff * TL_PREV
	macr   -x0,y1,a		b,y:S2_BB	; a -= coeff * BR_PREV    b -> BL_CURR
	mpy	y0,x1,a		a,x0		; a = damping * TL_PREV   x0 = delta
	mac	x0,x1,a		x:N1_BA,y0	; a += damping * delta    n1 B prev-> y0
	mpy	y1,x1,b		y:(r4)+,y1	; b = damping * BR_PREV	  fric_tap1-> y1
	macr	x0,x1,b		x:x_fric_sig,x0	; b += damping * delta    frication-> x0
	macr	y1,x0,a		x:S4_TA,x0	; a += tap1 * frication   s4 T prev-> x0
	move	b,y:S3_BB			; b -> BL_CURR
	move	a,y:S4_TB			; a -> TR_CURR

;  CALCULATE 3-WAY JUNCTION:  S4 - S5 - N1 (R4 - N1)
	move	x:S5_BA,x1			; s5 B prev -> x1

	tfr	x1,b		x:(r3)+,y1	; ALPHA_L -> y1
	mpy	x0,y1,a		x:(r3)+,y1	; ALPHA_R -> y1
	mac	x1,y1,a		x:(r3)+,y1	; ALPHA_T -> y1

	macr	y0,y1,a		y:DAMPING,y1
	move	a,x1
	mpy	x1,y1,a
	asl	a		b,x1

	macr   -x0,y1,a		a,b		; left output
	tfr	b,a		a,y:S4_BB	; left output -> s4 B curr

	macr   -y0,y1,b		x:x_fric_sig,y0	; top output

	mac    -x1,y1,a		b,y:N1_TB	; right output   TO -> s5 T curr
	move	x:(r3)+,x0	y:(r4)+,y1	; coeff -> x0    fric_tap2 -> y1
	macr	y1,y0,a		x:S5_TA,y0	; a += tap2 * frication
	move	a,y:S5_TB			; right output -> s5 T curr


;  CALCULATE MOUTH SECTIONS
;  JUNCTION S5 - S6 (R4 - R5)
	mpy	x0,y0,a		x:S6_BA,y1	; a = coeff * TL_PREV
	macr   -x0,y1,a		y:DAMPING,x1	; a -= coeff * BR_PREV
	mpy	y0,x1,a		a,x0		; a = damping * TL_PREV   x0 = delta
	mac	x0,x1,a		x:S6_TA,y0	; a += damping * delta
	mpy	y1,x1,b		y:(r4)+,y1	; b = damping * BR_PREV	  fric_tap3-> y1
	macr	x0,x1,b		x:x_fric_sig,x0 ; b += damping * delta	  frication-> x0
	macr	y1,x0,a		y:(r4)+,y1	; a += tap3 * frication
	move	a,y:S6_TB			; a -> TR_CURR

;  JUNCTION:  S6 - S7 (R5 internal)
	mpy	y0,x1,a		b,y:S5_BB	; a = TL_PREV * damping
	macr	y1,x0,a		x:S7_BA,y1	; a += tap4 * frication   BR_PREV -> y1
	mpyr	y1,x1,b		a,y:S7_TB	; b = BR_PREV * damping   a -> TR_CURR

;  JUNCTION S7 - S8 (R5 - R6)
	move	x:(r3)+,x0
	move	x:S7_TA,y0
	mpy	x0,y0,a		x:S8_BA,y1	; a = coeff * TL_PREV
	macr   -x0,y1,a		b,y:S6_BB	; a -= coeff * BR_PREV    b -> BL_CURR
	mpy	y0,x1,a		a,x0		; a = damping * TL_PREV   x0 = delta
	mac	x0,x1,a		x:S8_TA,y0	; a += damping * delta
	mpy	y1,x1,b		y:(r4)+,y1	; b = damping * BR_PREV	  fric_tap5-> y1
	macr	x0,x1,b		x:x_fric_sig,x0 ; b += damping * delta	  frication-> x0
	macr	y1,x0,a		x:(r3)+,x0	; a += tap5 * frication
	move	a,y:S8_TB			; a -> TR_CURR

;  JUNCTION S8 - S9 (R6 - R7)
	mpy	x0,y0,a		x:S9_BA,y1	; a = coeff * TL_PREV
	macr   -x0,y1,a		b,y:S7_BB	; a -= coeff * BR_PREV    b -> BL_CURR
	mpy	y0,x1,a		a,x0		; a = damping * TL_PREV   x0 = delta
	mac	x0,x1,a		x:S9_TA,y0	; a += damping * delta
	mpy	y1,x1,b		y:(r4)+,y1	; b = damping * BR_PREV	  fric_tap6-> y1
	macr	x0,x1,b		x:x_fric_sig,x0 ; b += damping * delta	  frication-> x0
	macr	y1,x0,a		x:(r3)+,x0	; a += tap6 * frication
	move	a,y:S9_TB			; a -> TR_CURR

;  JUNCTION S9 - S10 (R7 - R8)
	mpy	x0,y0,a		x:S10_BA,y1	; a = coeff * TL_PREV
	macr   -x0,y1,a		b,y:S8_BB	; a -= coeff * BR_PREV    b -> BL_CURR
	mpy	y0,x1,a		a,x0		; a = damping * TL_PREV   x0 = delta
	mac	x0,x1,a		x:S10_TA,y0	; a += damping * delta
	mpy	y1,x1,b		y:(r4)+,y1	; b = damping * BR_PREV	  fric_tap7-> y1
	macr	x0,x1,b		x:x_fric_sig,x0 ; b += damping * delta	  frication-> x0
	macr	y1,x0,a		x:(r3)+,x0	; a += tap7 * frication
	move	a,y:S10_TB			; a -> TR_CURR
	move	b,y:S9_BB			; b -> BL_CURR

;  MOUTH REFLECTION
	mpyr	y0,x0,b		x:fa10,x0	; b = TL_PREV * coeff	  fa10 -> x0
	move	b,y1		x:fb11,x1	; scaled input -> y1	  fb11 -> x1
	mpy	x0,y1,a		x:S10_BA,y1	; a = fa10 * input	  y[n-1] -> y1
	macr   -x1,y1,a		x:(r3)+,x0	; a -= fb11 * y[n-1]	  radCoeff -> x0
	move	a,y:S10_BB			; a -> BL_CURR

;  MOUTH RADIATION (INPUT IN y0, OUTPUT STORED IN y:mRadiationY)
	mpyr	x0,y0,a		x:fa20,x0	 ; a = TL_PREV * coeff	  fa20 -> x0
	move	a,y0	  	x:fa21,x1	 ; scaled input -> y0	  fa21 -> x1
	mpy	x0,y0,a		y:mRadiationX,y1 ; a = fa20 * input	  x[n-1] -> y1
	mac	x1,y1,a		x:fb21,x1	 ; a += fa21 * x[n-1]	  fb21 -> x1
	move	y:mRadiationY,y1		 ; y[n-1] -> y1
	macr   -x1,y1,a		y0,y:mRadiationX ; a -= fb21 * y[n-1]	  store x[n]
	move	a,y:mRadiationY			 ; store y[n]


;  CALCULATE NOSE SECTIONS
;  JUNCTION N1 - N2
	move	x:N1_TA,y0
	move	x:(r3)+,x0
	mpy	x0,y0,a		x:N2_BA,y1	; a = coeff * TL_PREV
	macr   -x0,y1,a		y:DAMPING,x1	; a -= coeff * BR_PREV
	mpy	y0,x1,a		a,x0		; a = damping * TL_PREV   x0 = delta
	macr	x0,x1,a		x:N2_TA,y0	; a += damping * delta
	mpy	y1,x1,b		a,y:N2_TB	; b = damping * BR_PREV   a -> TR_CURR
	macr	x0,x1,b		x:(r3)+,x0	; b += damping * delta

;  JUNCTION N2 - N3
	mpy	x0,y0,a		x:N3_BA,y1	; a = coeff * TL_PREV
	macr   -x0,y1,a		b,y:N1_BB	; a -= coeff * BR_PREV    b -> BL_CURR
	mpy	y0,x1,a		a,x0		; a = damping * TL_PREV   x0 = delta
	macr	x0,x1,a		x:N3_TA,y0	; a += damping * delta
	mpy	y1,x1,b		a,y:N3_TB	; b = damping * BR_PREV   a -> TR_CURR
	macr	x0,x1,b		x:(r3)+,x0	; b += damping * delta

;  JUNCTION N3 - N4
	mpy	x0,y0,a		x:N4_BA,y1	; a = coeff * TL_PREV
	macr   -x0,y1,a		b,y:N2_BB	; a -= coeff * BR_PREV    b -> BL_CURR
	mpy	y0,x1,a		a,x0		; a = damping * TL_PREV   x0 = delta
	macr	x0,x1,a		x:N4_TA,y0	; a += damping * delta
	mpy	y1,x1,b		a,y:N4_TB	; b = damping * BR_PREV   a -> TR_CURR
	macr	x0,x1,b		x:(r3)+,x0	; b += damping * delta

;  JUNCTION N4 - N5
	mpy	x0,y0,a		x:N5_BA,y1	; a = coeff * TL_PREV
	macr   -x0,y1,a		b,y:N3_BB	; a -= coeff * BR_PREV    b -> BL_CURR
	mpy	y0,x1,a		a,x0		; a = damping * TL_PREV   x0 = delta
	macr	x0,x1,a		x:N5_TA,y0	; a += damping * delta
	mpy	y1,x1,b		a,y:N5_TB	; b = damping * BR_PREV   a -> TR_CURR
	macr	x0,x1,b		x:(r3)+,x0	; b += damping * delta

;  JUNCTION N5 - N6
	mpy	x0,y0,a		x:N6_BA,y1	; a = coeff * TL_PREV
	macr   -x0,y1,a		b,y:N4_BB	; a -= coeff * BR_PREV    b -> BL_CURR
	mpy	y0,x1,a		a,x0		; a = damping * TL_PREV   x0 = delta
	macr	x0,x1,a		x:N6_TA,y0	; a += damping * delta
	mpy	y1,x1,b		a,y:N6_TB	; b = damping * BR_PREV   a -> TR_CURR
	macr	x0,x1,b		x:(r3)+,x0	; b += damping * delta
	move	b,y:N5_BB			; b -> BL_CURR

;  NOSE REFLECTION
	mpyr	y0,x0,b		x:nfa10,x0	; b = TL_PREV * coeff	  fa10 -> x0
	move	b,y1		x:nfb11,x1	; scaled input -> y1	  fb11 -> x1
	mpy	x0,y1,a		x:N6_BA,y1	; a = fa10 * input	  y[n-1] -> y1
	macr   -x1,y1,a		x:(r3)+,x0	; a -= fb11 * y[n-1]	  radCoeff -> x0
	move	a,y:N6_BB			; a -> BL_CURR

;  NOSE RADIATION (INPUT IN y0, OUTPUT STORED IN y:nRadiationY)
	mpyr	x0,y0,a		x:nfa20,x0	 ; a = TL_PREV * coeff	  fa20 -> x0
	move	a,y0	  	x:nfa21,x1	 ; scaled input -> y0	  fa21 -> x1
	mpy	x0,y0,a		y:nRadiationX,y1 ; a = fa20 * input	  x[n-1] -> y1
	mac	x1,y1,a		x:nfb21,x1	 ; a += fa21 * x[n-1]	  fb21 -> x1
	move	y:nRadiationY,y1		 ; y[n-1] -> y1
	macr   -x1,y1,a		y0,y:nRadiationX ; a -= fb21 * y[n-1]	  store x[n]
	move	a,y:nRadiationY			 ; store y[n]


;  THE TWO BRANCHES JOIN HERE
;  ADD NOSE AND MOUTH OUTPUT TOGETHER (y:nRadiation in a)
_endVT	move	y:mRadiationY,x1
	add	x1,a	x:vtScale,y0		; output is about 8 bits softer



;***************************************************************************************
;  ROUTINE:	throat
;
;  Synthesizes the effect of transmission of the glottal pulse through the membranes
;  of the throat and mouth, using a low pass filter and gain control.
;
;  Input:	x:x_ngs_signal, y0 (vtScale)
;  Output:	b
;
;  a (vocalTract signal) not used
;***************************************************************************************

	move	x:x_ngs_signal,x0		; noisy glottal source -> x0
	mpy	x0,y0,b	 y:throatY,x1		; scaled input -> b 	y[n-1] -> x1
	move 	b,x0	 y:ta0,y0		; input -> x0		ta0 -> y0
	mpy	x0,y0,b	 y:tb1,y0		; b = input * ta0	tb1 -> y0
	macr	x1,y0,b	 y:throatGain,y0	; b += y[n-1] * tb1	gain -> y0
	move	b,x0				; b -> x0
	mpyr	x0,y0,b	 b,y:throatY		; b = output * gain	store y[n]



;***************************************************************************************
;  ROUTINE:	sum_throat_vt
;
;  Sums the signals from the throat and vocal tract, scales this by 4 to boost the
;  weak signal, and scales the resulting signal by the master volume.
;
;  Input:	a (vocal tract signal), b (throat signal)
;  Output:	a (summed & scaled signal), x0 (SRC emptyPtr)
;***************************************************************************************

;  SCALE OUTPUT ACCORDING TO MASTER VOLUME
	add	b,a	 y:MASTER_AMP,y0	; sum throat signal & vt signal, and
	asl	a				; get amplitude factor for master vol
	asl	a				; a *= 4 (scale amplitude since it is
	move	a,x0				;         too soft)
	mpyr	x0,y0,a	 r7,x0			; scale output signal  SRC emptyPtr->x0



;***************************************************************************************
;  ROUTINE:	dataFill
;
;  Fills the sample rate conversion (SRC) buffer with the input value.  The buffer is
;  emptied (and thus the samples converted to the new sample rate) when full.
;
;  Input:	a
;  Output:	x:(r5)
;***************************************************************************************
	move	a,x:(r5)+
	move	r5,b
	cmp	x0,b
	jseq	dataEmpty


	jmp	main				; loop forever






	org	p:OFF_CHIP_PROGRAM_START

;***************************************************************************************
;  SUBROUTINE:	reset
;
;  Resets the dsp chip, and initializes variables and registers.
;***************************************************************************************

;  DISABLE HOST COMMANDS AND INTERRUPTS
reset	bclr	#m_hcie,x:m_hcr		; disable host command interrupts
	bclr	#m_hrie,x:m_hcr		; disable host receive interrupt
					; (no interrupts while setting up)
;  SET UP CHIP
	movec	#6,omr			; chip set to mode 2; ROM enabled
	bset	#0,x:m_pbc		; set port B to be host interface
	bset	#3,x:m_pcddr		; set pin 3 (pc3) of port C to be output
	bclr	#3,x:m_pcd		; zero to enable the external ram
	movep	#>$000000,x:m_bcr	; set 0 wait states for all external RAM
	movep	#>$000c00,x:m_ipr	; set interrupt priority register to
					; SSI=0, SCI=0, HOST=2

;  MOVE BETA TABLE FROM LOW MEMORY (FILLED BY LOADER) TO HIGH MEMORY
	move	#>temp_betaTable,r3	; set register to base of temporary memory
	move	#>l_betaTable,r4	; set register to base of betaTable memory
	do #64,_move			; transfer the table
	 move	y:(r3)+,a
	 move	a,y:(r4)+
_move

;  SET UP VARIABLES
	clr	a
	move	a10,l:l_currentPhase	; set current phase angle to 1; fix this later
	move	a,y:OSC_AMP		; set oscil ampl to 0 (ready for interpolation)
	move	a,x:x_STATUS_flags	; clear status flags

;  CLEAR BANDPASS FILTER MEMORY
	move	a,y:y_bp_xn1		; clear bandpass filter x and y memory
	move	a,y:y_bp_xn2
	move	a,y:y_bp_yn1
	move	a,y:y_bp_yn2

;  CLEAR TUBE MEMORY
	move	#>$0020,r4
	do #32,_endloopb
	 move	a10,l:(r4)+
_endloopb

;  CLEAR MOUTH RADIATION FILTER MEMORY
	move	a,y:mRadiationX
	move	a,y:mRadiationY

;  CLEAR NOSE RADIATION FILTER MEMORY
	move	a,y:nRadiationX
	move	a,y:nRadiationY

;  CLEAR THROAT LP FILTER MEMORY
	move	a,y:throatY

;  CLEAR SAMPLE RATE CONVERSION BUFFER
	move	#>src_buffer_base,r4
	do #SRC_BUFFER_SIZE,_endloop2
	 move	a,x:(r4)+
_endloop2


;  SET UP REGISTERS
	move	#>sine_wave_table,r0	; set register to base of waveform table
	move	#>SINE_TABLE_SIZE-1,x0
	move	x0,x:x_tableMod		; set mask to tablesize - 1
	move	x0,m0			; set modulus for waveform table

	IF SYNC_DMA
	move	#>dma_out_buffer,a	; store base of dma buffer
	move	a,x:dma_fill_base
	move	a,r6
	move	#>DMA_OUT_SIZE-1,m6	; set modulus for dma buffer

	ELSE
	move	#>dma_out_buffer1,a	; store base of dma buffer
	move	a,x:dma_fill_base
	move	a,r6
	move	#>DMA_OUT_SIZE-1,m6	; set modulus for dma buffer

	move	#>dma_out_buffer2,a
	move	a,x:dma_empty_base
	move	a,r2
	move	#>DMA_OUT_SIZE-1,m2	; set modulus for dma buffer
	ENDIF

	IF OVERSAMPLE_OSC
	move	#>l_FIR_base,r3		; set register to base of FIR filter memory
	move	r3,x:FIR_x_ptr
	move	#>l_FIR_base,r4		; set register to base of FIR filter memory
	move	r4,x:FIR_y_ptr		; modulus set when coefficients loaded (HC)
	ENDIF

	move	#>SRC_BUFFER_SIZE-1,m1	; set moduli for srate conversion buffer
	move	#>SRC_BUFFER_SIZE-1,m7
	move	#>SRC_BUFFER_SIZE-1,m5

	move	#>PADSIZE,n5		; set n5 to padsize

	move	#>src_buffer_base,r5	; emptyPtr = src_buffer_base
	move	#>src_buffer_base,r7

	move	(r5)+n5			; fillPtr = src_buffer_base + padsize

	move	#>L_RANGE,n3		; set filter increments
	move	#>L_RANGE,n4


;  INITIALIZE INPUT SCALE FOR THE VOCAL TRACT
	move	#VT_SCALE,a
	move	a,x:vtScale

;  INITIALIZE TIME REGISTER
	move	#>L_RANGE,a1
	move	a,l:l_timeReg


;  UNMASK INTERRUPTS
	bset    #m_hcie,x:m_hcr		; enable host command interrupts
	move	#0,sr			; unmask interrupts

;  JUMP TO MAIN LOOP
	jmp	main



;***************************************************************************************
;  SUBROUTINE:	write_DMA_buffer
;
;  Writes one complete DMA output buffer to the host, using the NeXT specified DMA
;  protocol.
;
;  Input:	none
;  Output:	none
;***************************************************************************************

write_DMA_buffer

	IF SYNC_DMA
	bset	#m_hf2,x:m_hcr			; signal host no interactive input
	bclr	#DMA_OUT_DONE,x:x_STATUS_flags	; clear dma-out done flag
	writeHost #DMA_OUT_REQ			; request host for dma-out

_ackBeg	jclr	#m_hf1,x:m_hsr,_ackBeg	; loop until host acknowledges (HF1=1)

	do	#DMA_OUT_SIZE,_send_loop	; top of DMA buffer send loop
_send	 jclr	#m_htde,x:m_hsr,_send		; loop until htde bit of HSR is set
	 movep	x:(r6)+,x:m_htx			; send buffer element to host
_send_loop
	jset	#DMA_OUT_DONE,x:x_STATUS_flags,_endDMA ; if interrupt has set flags,
	jclr	#m_htde,x:m_hsr,_send_loop	; then go to end;  else keep
	movep	#0,x:m_htx			; sending 0s until interrupt sets flags
	jmp	_send_loop
_endDMA

_ackEnd	jset	#m_hf1,x:m_hsr,_ackEnd		; loop until host ack. has ended (HF1=0)

	bclr	#m_hf2,x:m_hcr			; signal host interactive input allowed
	rts


	ELSE
_buzz	jset	#m_htie,x:m_hcr,_buzz	; block if still emptying other buffer

	writeHost #DMA_OUT_REQ		; request host for dma-out

	move	x:dma_fill_base,a	; switch buffers and pointers
	move	x:dma_empty_base,b
	move	b,x:dma_fill_base
	move	b,r6
	move	a,x:dma_empty_base
	move	a,r2

	bset	#m_htie,x:m_hcr		; set host transmit interrupt enable (HTIE)

	rts
	ENDIF



;***************************************************************************************
;  SUBROUTINE:	update_parameters
;
;  Updates all values from the parameters just loaded from the host.  Conversions
;  of data are done as necessary, and the update flag bit is cleared.
;
;  Input:	none
;  Output:	none
;***************************************************************************************

update_parameters
	bclr	#m_hcie,x:m_hcr			; disable host command interrupts
	bclr	#PARAM_UPDATE,x:x_STATUS_flags	; clear status flag

	move	#DATA_TABLE,r4			; set pointer to beginning of table
	nop

;  CONCATENATE PHASE INCREMENT INTEGER AND FRACTIONAL PARTS
	clr	a	y:(r4)+,y0	; TABLE_INC_INT -> y0
	move	y:(r4)+,a0		; TABLE_INC_FRAC -> a0
	asl	a			; get rid of sign bit, left justify
	move	y0,a1			; concatenate integer part of increment
	move	a10,l:l_phaseInc	; store phase angle increment

;  CONVERT GLOTTAL SOURCE VOLUME TO AMPLITUDE, AND ALSO UPDATE WAVETABLE
	move	y:(r4)+,y0		; SOURCE_VOLUME -> y0
	jsr	convert_to_amp
	move	b,y:OSC_AMP

;  READ IN MASTER VOLUME, AND CONVERT TO MASTER_AMP
	move	y:(r4)+,y0		; MASTER_VOLUME -> y0
	jsr	convert_to_amp		; convert master volume to amplitude
	move	b,y:MASTER_AMP

;  READ IN CHANNELS & STEREO BALANCE, AND CONVERT TO BALANCE_L AND BALANCE_R
	move	y:(r4)+,a		; BALANCE -> a
	move	y:(r4)+,x0		; CHANNELS -> x0
	jsr	convert_balance		; convert balance to L & R values

;  READ IN GLOTTAL SOURCE WAVEFORM TYPE, AND SET WAVETABLE BASE
	move	y:(r4)+,a		; WAVEFORM_TYPE -> a
	jsr	set_waveform_type	; set the waveform type

;  READ IN TP, TN_MIN, TN_MAX, AND CREATE WAVE TABLE
	move	y:(r4)+,a		; TP -> y:TP
	move	a,y:TP
	move	y:(r4)+,a		; TN_MIN -> y:TN_MIN
	move	a,y:TN_MIN
	move	y:(r4)+,a		; TN_MAX -> y:TN_MAX
	move	a,y:TN_MAX
	IF VARIABLE_GP
	jsr	initializeWavetable	; rewrite the glottal pulse wavetable
	ENDIF

;  READ IN BREATHINESS, AND CALCULATE ANTI-BREATHINESS
	move	y:(r4)+,y0		; BREATHINESS -> y0
	move	y:y_unity,a		; calculate anti-breathiness
	sub	y0,a	y0,y:BREATHINESS
	move	a,y:ANTI_BREATHINESS	; anti_breathiness = 1.0 - breathiness

;  READ IN PULSE MODULATION (NO CONVERSION)
	move	y:(r4)+,a		; PULSE_MODULATION -> y:PULSE_MODULATION
	move	a,y:PULSE_MODULATION

;  READ IN CROSSMIX FACTOR, AND CALCULATE CROSSMIX AND ANTI-CROSSMIX VALUES
	move	y:(r4)+,x1		; CROSSMIX_FACTOR -> x1

	IF FIXED_CROSSMIX
	move	y:OSC_AMP,y0			; voicing amplitude -> y0
	move	y:y_unity,a			; 1.0 -> a
	sub	y0,a	 y0,y:crossmix		; a = 1.0 - ax	  y0 -> crossmix
	move	a,y:anti_crossmix		; a -> anti_crossmix
	ELSE
	move	y:OSC_AMP,y0			; current amplitude -> y0
	mpy	x1,y0,b	 #>@cvi(@pow(2,CROSSMIX_SCALE-1)),y0	; b = amp * mix_factor
	clr	a	 b,x1
	mpy	x1,y0,b	 y:y_unity,a0		; b *= 32 (scaled by 1/32 in host)
	cmp	a,b	 b0,y0			; (output is in b0)
	jle 	_next
	  move	a0,y0				; y0 = min(product, 1.0)
_next	move	y:y_unity,a
	sub	y0,a	 y0,y:crossmix
	move	a,y:anti_crossmix
	ENDIF

;  CONVERT ASPIRATION VOLUME TO AMPLITUDE
	move	y:(r4)+,y0		; ASP_VOLUME -> y0
	jsr	convert_to_amp
	move	b,y:ASP_AMP

;  CALCULATE BANDPASS FILTER COEFFICIENTS FROM CENTER FREQUENCY & BANDWIDTH
	move	y:(r4)+,x0		; CENTER_FREQUENCY -> x0
	move	y:(r4)+,y0		; BANDWIDTH -> y0
	jsr	bpConvert		; convert bandpass bw & cf into coefficients

;  CALCULATE FRICATION TAPS FROM FRICATION VOLUME AND POSITION
	move	y:(r4)+,y0		; FRICATION_VOLUME -> y0
	jsr	convert_to_amp		; output in b
	move	y:(r4)+,x0		; FRICATION_POSITION -> x0
	jsr	setFricationTaps	; set frication taps according to fr. position

;  READ IN DAMPING FACTOR (NO CONVERSION)
	move	y:(r4)+,a		; DAMPING -> y:DAMPING
	move	a,y:DAMPING

;  READ SCATTERING COEFFICIENTS, WHICH ARE USED DIRECTLY  */
	move	x:coeff_mem,r3
	do #19,_tableloop2
	  move	y:(r4)+,a
	  move	a,x:(r3)+
_tableloop2

;  READ IN MOUTH APERTURE COEFFICIENT, AND CALCULATE MOUTH FILTER COEFFICIENTS
	move	y:(r4)+,a		; MOUTH_COEFF -> a
	jsr	setMouthCoefficients	; set mouth radiation & reflection filter coef.

;  READ IN NOSE APERTURE COEFFICIENT, AND CALCUALTE NOSE FILTER COEFFICIENTS
	move	y:(r4)+,a		; NOSE_COEFF -> a
	jsr	setNoseCoefficients	; set nose radiation & reflection filter coef.

;  READ IN INTEGER AND FRACTIONAL PARTS OF THE TIME REGISTER INCREMENT, CONCATENATE
	move	y:(r4)+,a		; TIME_REG_INT -> a
	move	y:(r4)+,y0		; TIME_REG_FRAC -> y0
	move	y0,a0			; set time register increment by concatenating
	move	a,l:l_timeRegInc	; the integer and fractional parts

;  READ IN THROAT CUTOFF VALUE, CALCULATE THROAT FILTER COEFFICIENTS
	move	y:(r4)+,a		; THROAT_CUTOFF -> a
	jsr	setThroatCoefficients	; set the throat filter coefficients

;  READ IN THROAT VOLUME, AND CONVERT TO THROAT AMPLITUDE
	move	y:(r4)+,y0		; THROAT_VOLUME -> y0
	jsr	convert_to_amp
	move	b,y:throatGain

	bset	#m_hcie,x:m_hcr		; enable host command interrupts
	rts



;***************************************************************************************
;  INTERRUPT SERVICE ROUTINE:  dma_in_accepted
;
;  Sets the status flag when the host is ready to send the samples.  It reads an
;  integer, which is not used.
;
;  Input:	none
;  Output:	none
;***************************************************************************************

dma_in_accepted
	readHost x:x_temp				; The host sends a integer.
	bset	#DMA_IN_ACCEPTED,x:x_STATUS_flags	; But we don't really need it.
	rti



;***************************************************************************************
;  INTERRUPT SERVICE ROUTINE:  load_datatable
;
;  Reads the data table containing parameter values to the input table memory, and
;  sets the status flag so that these parameters are updated at the top of the
;  next loop.
;
;  Input:	none
;  Output:	none
;***************************************************************************************

load_datatable
	bclr	#m_hcie,x:m_hcr			; disable host command interrupts
	bset	#PARAM_UPDATE,x:x_STATUS_flags	; set status flag
	move	r4,x:x_r4_save			; save the current value of r4
	move	#DATA_TABLE,r4			; set r4 to input datatable base

	do #DATA_TABLE_SIZE,_end_loop
	 readHost y:(r4)+
_end_loop

	move	x:x_r4_save,r4			; restore the saved value of r4
	bset	#m_hcie,x:m_hcr			; enable host command interrupts
	rti



;***************************************************************************************
;  HOST COMMAND SERVICE ROUTINE:  load_wavetable 
;
;  Loads in the wavetable from the host.
;
;  Input:	none
;  Output:	none
;***************************************************************************************

load_wavetable
	bclr	#m_hcie,x:m_hcr			; disable host command interrupts
	move	r4,x:x_r4_save			; save the current value of r4
	move	#gp_wave_table,r4		; set r4 to gp wavetable base

	do #GP_TABLE_SIZE,_end_loop
	 readHost y:(r4)+
_end_loop

	move	x:x_r4_save,r4			; restore the saved value of r4
	bset	#m_hcie,x:m_hcr			; enable host command interrupts
	rti



;***************************************************************************************
;  HOST COMMAND SERVICE ROUTINE:  load_fir_coefficients
;
;  Loads in the table of FIR filter coefficients from the host.
;
;  Input:	none
;  Output:	none 
;***************************************************************************************

load_fir_coefficients
	bclr	#m_hcie,x:m_hcr		; disable host command interrupts
	move	r4,x:x_r4_save		; save the current value of r4
	move	a10,l:l_a_save		; save the current value of a
	move	x0,x:x_x0_save		; save the current value of x0

	readHost a			; read and store the tablesize
	move	a,x:x_FIR_size

	move	y:y_one,x0		; modulus = tablesize - 1
	sub	x0,a
	move	a,x:x_FIR_mod		; store modulus (used in FIR routine)

	move	#>l_FIR_base,r4		; set pointer to beginning of coefficient array
	move	x:x_FIR_size,a
	do a,_end_loop
	 readHost y:(r4)+		; read and store each coefficient
_end_loop

	move	x:x_r4_save,r4		; restore the saved value of r4
	move	l:l_a_save,a10		; restore the saved value of a
	move	x:x_x0_save,x0		; restore the saved value of x0
	bset	#m_hcie,x:m_hcr		; enable host command interrupts
	rti



;***************************************************************************************
;  HOST COMMAND SERVICE ROUTINE:  load_src_coefficients
;
;  Loads in both the table of sample rate conversion coefficients and the table of the
;  filter deltas from the host.
;
;  Input:	none
;  Output:	none
;***************************************************************************************

load_src_coefficients
	bclr	#m_hcie,x:m_hcr		; disable host command interrupts
	move	r4,x:x_r4_save		; save the current value of r4

	move	x:fbase_addr,r4		; set pointer to beginning of coefficient array
	do #FILTER_SIZE,_end_loop
	 readHost y:(r4)+		; read and store each coefficient
_end_loop

	move	#>filter_d_base,r4	; set pointer to beginning of delta array
	do #FILTER_SIZE,_end_loop2
	 readHost y:(r4)+		; read and store each delta
_end_loop2

	move	x:x_r4_save,r4		; restore the saved value of r4
	bset	#m_hcie,x:m_hcr		; enable host command interrupts
	rti



;***************************************************************************************
;  SUBROUTINE:  convert_to_amp
;
;  Converts dB value (a fraction equal to dB/64.0) to an amplitude value (0.0 to 1.0).
;
;  Input:	y0
;  Output:	b
;***************************************************************************************

convert_to_amp
	move	#>64,x1				; move scaling factor into x1
	mpy	y0,x1,a				; mult. input by scaling factor
	lsl	a				; put sign bit into a0 and
	asr	a	#>l_dbToAmpTable,b	; get conversion table base

	move	a1,y0		; get the table offset
	add	y0,b		; and add it to the table base
	move	b,r3		; and put the result into r3

	move	a0,x1		; get the fractional part of the scaled input
	move	x:(r3),b	; get the ampl value of the int part of the input
	move	y:(r3),y1	; get the corresponding delta value
	macr	x1,y1,b		; add frac * delta to b

	rts



;***************************************************************************************
;  SUBROUTINE:  betaFunction
;
;  Calculates the beta coefficient used to calculate the filter coefficients for
;  the bandpass filter.  Note that the input is bandwidth/sampleRate (varies from
;  0 to 0.5).
;
;  Input:	y0
;  Output:	b
;
;  Preserves:	x0
;***************************************************************************************

betaFunction
	move	#>betaTableSize-1,x1	; move scaling factor into x1
	mpy	y0,x1,a			; mult. input by scaling factor
	asl	a			; multiply by 2
	lsl	a			; put sign bit into a0 and
	asr	a	#>l_betaTable,b	; get conversion table base

	move	a1,y0		; get the table offset
	add	y0,b		; and add it to the table base
	move	b,r3		; and put the result into r3

	move	a0,x1		; get the fractional part of the scaled input
	move	y:(r3)+,b	; get the ampl value of the int part of the input

	move	y:(r3),a	; a = nextValue
	sub	b,a		; delta = nextValue - value
	move	a,y1

	macr	x1,y1,b		; b += frac * delta

	rts



;***************************************************************************************
;  SUBROUTINE:  sin
;
;  Calculate the sine function of the input value.  The input value varies from 0.0 to
;  1.0 (i.e. theta/2PI).
;
;  Input:	y0
;  Output:	b
;***************************************************************************************

sin
	move	#>SINE_TABLE_SIZE,x1		; move scaling factor into x1
	mpy	y0,x1,a				; mult. input by scaling factor
	lsl	a				; put sign bit into a0 and
	asr	a	#>sine_wave_table,b	; get conversion table base

	move	a1,y0		; get the table offset
	add	y0,b		; and add it to the table base
	move	b,r3		; and put the result into r3

	move	a0,x1		; get the fractional part of the scaled input
	move	y:(r3)+,b	; get the ampl value from the sine table
	move	y:(r3),a	; get the next value in the table
	sub	b,a		; calculate the table delta (a = a - b)
	move	a,y1		; move the delta into y1
	macr	x1,y1,b		; add frac * delta to base amplitude value

	rts



;***************************************************************************************
;  SUBROUTINE:  bpConvert
;
;  Converts bandpass center frequency and bandwidth values to filter coefficients.
;  Note that the inputs are cf/sampleRate and bw/sampleRate (i.e. vary from 0 to 0.5).
;
;  Input:	x0 (BANDPASS_CF), y0 (BANDPASS_BW)
;  Output:	x:ALPHA, y:BETA, y:GAMMA
;***************************************************************************************

bpConvert
	jsr	betaFunction		; calculate the beta coefficient (x0 preserved!)

	move	#@cvf(0.25),a		; add .25 to CF, so we can use the sin function
	add	x0,a	 b,x:BETA	; to calculate the cos of CF.  Store beta coeff.
	move	a,y0			; move (CF+0.25) to y0
	jsr	sin			; calculate cos(CF), output in b
	asr	b	 b,x0		; b /= 2
	move	x:BETA,y0
	macr	x0,y0,b  #@cvf(0.5),a	; b += beta * cos(CF)

	sub	y0,a	 b,x:GAMMA	; a = 0.5 - beta.   Store gamma coefficient
	asr	a			; a /= 2
	rnd	a			
	move	a,x:ALPHA		; Store alpha coefficient

	rts



;***************************************************************************************
;  SUBROUTINE:  convert_balance
;
;  Converts the channels value (1 or 2) and the balance value (-1.0 to +1.0) to left
;  and right channel scaling values.
;
;  Input:	x0 (channels), a (balance)
;  Output:	y:BALANCE_R, y:BALANCE_L
;***************************************************************************************

convert_balance
	jset	#1,x0,_stereo		; if 2 channels, do stereo scaling below

_mono	move	#@cvf(0.5),b
	move	b,y:BALANCE_R
	move	b,y:BALANCE_L
	rts

_stereo	asr	a	#@cvf(0.5),x0		; a /= 2
	add	x0,a	y:y_unity,b		; a += 0.5
	sub	a,b	a,y:BALANCE_R		; L = 1 - R	store R channel scale
	move	b,y:BALANCE_L			; store L channel scale
	rts



;***************************************************************************************
;  SUBROUTINE:   set_waveform_type
;
;  Sets the waveform type by setting the r0 and m0 registers, plus the x_tableMod value.
;
;  Input:	a
;  Output:	r0, m0, x:x_tableMod
;***************************************************************************************

set_waveform_type
	jset	#0,a,_sine
	 move	#>gp_wave_table,r0	; set register to base of glottal pulse table
	 move	#>GP_TABLE_SIZE-1,x0
	 move	x0,x:x_tableMod		; set mask to tablesize - 1
	 move	x0,m0			; set modulus for waveform table
	 rts

_sine	move	#>sine_wave_table,r0	; set register to base of sine table
	move	#>SINE_TABLE_SIZE-1,x0
	move	x0,x:x_tableMod		; set mask to tablesize - 1
	move	x0,m0			; set modulus for waveform table
	rts



	IF VARIABLE_GP
;***************************************************************************************
;  SUBROUTINE:  initializeWavetable
;
;  Initializes the glottal pulse wavetable according to the tnMin, tnMax, and tp
;  variables.
;
;  Input:	y:TN_MAX, y:TN_MIN, y:TP
;  Output:	gp_wave_table
;***************************************************************************************

initializeWavetable

	move	y:TN_MAX,a		; tnDelta = tnMax - tnMin
	move	y:TN_MIN,x0
	sub	x0,a	#>GP_TABLE_SIZE,y1
	move	a,x:x_tnDelta


	jmi	_negative		; div2 = rint(wavetableSize *
	 move	y:TN_MAX,x0		;   (tp + max(tnMin,tnMax))) - 1
_negative
	move	y:TP,a
	add	x0,a
	move	a,x0
	mpyr	x0,y1,a	 #>gp_wave_table,y0
	add	y0,a	 y:y_one,x0
	sub	x0,a	 y:TP,x1
	move	a,x:x_div2

	mpyr	x1,y1,b			; div1 = rint(wavetableSize * tp) - 1
	add	y0,b
	sub	x0,b
	move	b,x:x_div1

	move	b,r3			; create rising part of table
	sub	y0,b			; put div1 into r3
	move	b,x1			; tpLength = div1 - base
	jsr	reciprocal		; y0 =  1/tpLength

	move	y:y_unity,a		; put 1.0 into top of curve
	move	a,y:(r3)-
	move	y:y_one,y1
	sub	y1,b			; decrement loop count by 1

	do b,_end_loop1			; this loop increments backwards
	 movec	lc,x1			; put loop count into x1
	 mpy	x1,y0,b			; b = loopCount * 1/newTnLength
	 lsl	b			; put sign bit into b0
	 asr	b
	 move	b0,x0			; put fractional part of product into x0
	 mpyr	x0,x0,a	 #0.75,y1	; a = x^2
	 move	a,x1
	 mpy	x1,y1,a                 ; a = 0.75 * x^2
	 mpyr	x0,x1,b	 #0.5,y1	; b = x^3
	 move	b,x1
	 macr   -x1,y1,a		; a *=  -(0.5 * x^3)
	 asl	a
	 asl	a			; a *= 4
	 clr	a 	 a,y:(r3)-	; put value into the wavetable
_end_loop1

	move	a,y:(r3)		; put 0 into very 1st table entry


	move	#>GP_TABLE_SIZE,y1	; create closed part of table (all zeros)
	move	#>gp_wave_table,b
	add	y1,b	 x:x_div2,x1
	sub	x1,b	 x1,r3

	do b,_end_loop2
	 move	a,y:(r3)+
_end_loop2

	jsr	updateWavetable		; create falling part of table
					; according to current amplitude
	rts



;***************************************************************************************
;  SUBROUTINE:	updateWavetable
;
;  Updates the variable portion of the glottal pulse wavetable according to the voicing
;  amplitude.
;
;  Input:	y:TN_MAX, y:OSC_AMP, x:x_tnDelta, x:x_div1
;  Output:	gp_wave_table
;***************************************************************************************

updateWavetable
	move	y:TN_MAX,a
	move	y:OSC_AMP,y1
	move	x:x_tnDelta,x0		; actualTnLength = tnMax - (OSC_AMP * tnDelta)
	macr	-y1,x0,a  #>GP_TABLE_SIZE,y0

	move	a,x0
	mpyr	x0,y0,a	 y:y_one,x0
	sub	x0,a	 x:x_div1,y1
	add	y1,a	 a1,x1		; newTnLength=rint(actualTnLength * tableSize)-1
	move	a,r3
	move	a,x:x_newDiv2		; newDiv2 = newTnLength + div1

	jsr	reciprocal		; y0 =  1/newTnLength

	do x1,_end_loop1		; this loop increments backwards
	 movec	lc,x1			; put loop count into x1
	 mpy	x1,y0,b			; b = loopCount * 1/newTnLength
	 lsl	b			; put sign bit into b0, and
	 asr	b   y:y_unity,a		; put 1.0 into a
	 move	b0,x0			; put fractional part of product into x0
	 macr	-x0,x0,a		; a -= x^2
	 move 	a,y:(r3)-		; put value into the wavetable
_end_loop1

; ZERO REST OF TABLE HERE---REMEMBER ERROR IN FIRST VALUE CALCULATED ABOVE
	move	x:x_newDiv2,x0
	move	x0,r3			; move newDiv2 into r3
	clr	b	x:x_div2,a
	sub	x0,a	y:y_one,x1	
	add	x1,a			; a = div2 - newDiv2 + 1

	do	a,_end_loop2
	 move	b,y:(r3)+
_end_loop2

	rts



;***************************************************************************************
;  SUBROUTINE:	reciprocal
;
;  Calculates the positive reciprocal of the input.
;
;  Input:	x1 (divisor)
;  Output:	y0 (quotient)
;
;  overwrites a, y0
;  preserves x1
;***************************************************************************************

reciprocal
	move	y:y_one,a	; put dividend (1) into a1
	and	#$fe,ccr	; make sure carry bit is clear
	rep	#$18		; do division
	div	x1,a
	move	a0,y0		; put result into y0
	rts

	ENDIF



;***************************************************************************************
;  SUBROUTINE:	setFricationTaps
;
;  Sets the frication taps to according to frication position (x0) and amplitude (b).
;
;  Input:	x0 (FRICATION_POS), b (FRICATION_AMP)
;  Output:	y:y_tap0 to y:y_tap4
;***************************************************************************************

setFricationTaps
	clr	a	x:tap_mem,r3		; clear the tap memory
	rep	#NUMBER_TAPS
	 move	a,y:(r3)+

	move	#>POSITION_SCALE,y0		; move scaling factor into y0
	mpy	x0,y0,a	 b,y1			; mult. input by scaling factor
						; frication ampl. -> y1 (preserve!)
	lsl	a				; put sign bit into a0 and
	asr	a	 y:y_unity,b		; put 1.0 into b

	move	a0,x1				; store complement (frac.) in x1
	move	a1,y0				; put integer part into y0
	sub	x1,b   x:tap_mem,a		; calculate remainder; tablebase -> a
	add	y0,a   b,x0  			; add integer to tablebase; store
						; remainder; put frication ampl in y1
	move	a,r3				; put tap # into r3
	mpyr	x0,y1,a				; calculate first tap
	mpyr	x1,y1,b	a,y:(r3)+		; calculate second tap; store 1st tap
	move	b,y:(r3)			; store 2nd tap

	rts



;***************************************************************************************
;  SUBROUTINE:	setMouthCoefficients
;
;  Calculates the mouth filter coefficients from the input mouth coefficient.
;
;  Input:	a
;  Output:	x:fa10, x:fb11, x:fa20, x:fa21, x:fb21
;***************************************************************************************

setMouthCoefficients
	move	a,x:fa20			; a20 = coeff
	neg	a	y:y_unity,x0
	move	a,x:fb11			; b11 = -coeff
	move	a,x:fa21			; a21 = -coeff
	add	x0,a	a,x:fb21		; b21 = -coeff
	move	a,x:fa10			; a10 = 1.0 - coeff

	rts



;***************************************************************************************
;  SUBROUTINE:	setNoseCoefficients
;
;  Calculates the nose filter coefficients from the input nose coefficient.
;
;  Input:	a
;  Output:	x:nfa10, x:nfb11, x:nfa20, x:nfa21, x:nfb21
;***************************************************************************************

setNoseCoefficients
	move	a,x:nfa20			; a20 = coeff
	neg	a	y:y_unity,x0
	move	a,x:nfb11			; b11 = -coeff
	move	a,x:nfa21			; a21 = -coeff
	add	x0,a	a,x:nfb21		; b21 = -coeff
	move	a,x:nfa10			; a10 = 1.0 - coeff
	rts



;***************************************************************************************
;  SUBROUTINE:	setThroatCoefficients
;
;  Sets the throat filter coefficients from the input throat cutoff value (the cutoff
;  frequency divided by the sample rate, i.e. a value from 0 to 0.5).  These
;  coefficients assume addition in the difference equation:
;	y[n] = (ta0 * input) + (tb1 * y[n-1])
;
;  Input:	a
;  Output:	y:ta0, y:tb1
;***************************************************************************************

setThroatCoefficients
	asl	a	y:y_unity,x1		; a *= 2		1 -> x1
	neg	a	a,y:ta0			; a *= -1	 	ta0 = cutoff * 2
	add	x1,a				; a = -(cutoff * 2) + 1
	move	a,y:tb1				; tb1 = 1 - (cutoff * 2)
	rts



;***************************************************************************************
;  SUBROUTINE:	 dataEmpty
;
;  Empties the sample rate conversion (SRC) buffer while doing the sample rate
;  conversion.
;
;  Input:	src_buffer_base
;  Output:	dma_out_buffer
;***************************************************************************************

dataEmpty

;  CALCULATE AND STORE endPtr
	lua	(r5)-n5,r4
	move	r4,y:endPtr

;  index = emptyPtr
	move	r7,r1

;  GET CURRENT VALUE OF THE TIME REGISTER	
	move	l:l_timeReg,b

;  CONVERSION LOOP 
_topCL	neg	b	x:mask_l,y1	; complement timeReg.	L_MASK->y1
	and	y1,b	x:fbase_addr,a	; mask out N part	filter base->a
	lsl	b	b1,x1		; put sign bit in b0	L part->x1
	add	x1,a	x:base_diff,y1	; a += L part		delta filt base diff->y1
	add	y1,a	a,r3		; a += base diff	a->r3
	asr	b	a,r4		; put sign bit in b0	a->r4
	move	b0,x0			; interpolation->x0

	clr	a	x:(r3)+n3,b	y:(r4)+n4,y0	; get filter and filter delta
	do	#PADSIZE-1,_endloop		; do convolution
	 macr	x0,y0,b		x:(r1)+,x1	; b += interpolation * delta	x[n]->x1
	 move	b,y1		x:(r3)+n3,b	; b->y1	filter	value->b
	 mac	x1,y1,a		y:(r4)+n4,y0	; a += x[n] * (filt + (int. * delta))
_endloop


;***************************************************************************************
;  ROUTINE:	write_sample_stereo
;
;  Takes the input sample, and either creates a pseudo-mono signal by writing that
;  sample (scaled by 0.5) to both the left and right channels, or creates a
;  stereo signal by writing the left and right channels according the the balance
;  control (left and right channel scaling factors).  If the output buffer is full,
;  it is written to the host (and thus the DAC).
;
;  Input:	a
;  Output:	none
;***************************************************************************************

	move	a,x0	 y:BALANCE_L,y0	; signal in x0, L scaling -> y0
	mpy	x0,y0,a	 y:BALANCE_R,y1	; scale L channel, R scaling -> y1
	mpy	x0,y1,b	 a,x:(r6)+	; scale R channel, L value -> dma buffer
	move	b,x:(r6)+		; R value -> dma buffer

	move	x:dma_fill_base,x0	; put buffer base in x0
	move	r6,a			; put current index in a
	cmp	x0,a			; if (current index==buffer base)
	jseq	write_DMA_buffer	; then the buffer is full, so write it out



;***************************************************************************************
;  SUBROUTINE:	 dataEmpty (2nd part)
;***************************************************************************************

;  UPDATE TIME REGISTER
	move	l:l_timeReg,a			; timeRegister->a
	move	l:l_timeRegInc,b		; timeRegisterIncrement->b
	add	b,a	 #N_SCALE,y0		; a += increment    N_SCALE->y0
	tfr	a,b	 a,x0	y:endPtr,y1	; a->b	  a->x0	    endPtr->y1
	mpy	x0,y0,a	 x:mask_l,x1		; a = N part	    L_MASK->x1
	and	x1,b	 a,n7			; clear out N part  N part->n7
	move	b,l:l_timeReg			; store timeRegister
	move	(r7)+n7				; emptyPtr += nValue(timeRegister)

;  LOOP TEST
	move	r7,a				; emptyPtr->a
	cmp	y1,a	r7,r1			; index = emptyPtr
	jne	_topCL				; if (emptyPtr < endPtr) loop again

	rts
