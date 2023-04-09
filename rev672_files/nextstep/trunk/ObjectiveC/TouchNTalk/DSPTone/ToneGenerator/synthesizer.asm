;; REVISION INFORMATION ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; $Author: len $
;; $Date: 1994/06/16 16:40:12 $
;; $Revision: 1.1.1.1 $
;; $Source: /cvsroot/ToneGenerator/synthesizer.asm,v $
;; $State: Exp $
;;
;;
;; $Log: synthesizer.asm,v $
;; Revision 1.1.1.1  1994/06/16  16:40:12  len
;; Initial archive of ToneGenerator application.
;;
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;   PROGRAM:	synthesizer.asm
;;
;;   AUTHOR:	Leonard Manzara
;;
;;   DATE:	June 14th, 1994
;;
;;   SUMMARY:	Synthesis program which generates tones for the Tone class.
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;  THESE FLAGS ARE USED FOR LOCAL EXPERIMENTATION AND DEBUGGING
DEBUG_56	set	0	; set to 1 for use with Bug56

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;  FORMATTING FOR LISTING FILE

	page 120,48,0,1,0	; Width, height, topmar, botmar, lmar
	opt cex,mex,mu
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;  INCLUDE FILE

	NOLIST
	include	'ioequlc.asm'
	LIST



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;  ORIGINS FOR PROGRAM MEMORY

	IF !DEBUG_56
ON_CHIP_PROGRAM_START	equ	$40
	ELSE
ON_CHIP_PROGRAM_START	equ	$A0
	ENDIF

OFF_CHIP_PROGRAM_START	equ	$2000


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;  INTERRUPT AND HOST COMMAND VECTORS

VEC_RESET		equ	$00	; reset vector
VEC_DMA_OUT_DONE	equ	$24	; host command: dma-out complete
VEC_START               equ	$2E	; host command: start synthesizing
VEC_STOP                equ	$30	; host command: stop synthesizing
VEC_SET_FREQUENCY       equ	$32	; host command: set frequency
VEC_SET_AMPLITUDE       equ	$34	; host command: set amplitude
VEC_SET_BALANCE		equ	$36	; host command: set balance
VEC_SET_WAVETABLE	equ	$38	; host command: set wavetable
VEC_SET_RATE		equ	$3A	; host command: set rate
VEC_LOAD_FIR_COEF	equ	$3C	; host command: load FIR coefficients



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;  MACROS

writeHost macro source
_one	jclr	#m_htde,x:m_hsr,_one	
	movep	source,x:m_htx
	endm
	

readHost macro	dest
_two	jclr	#m_hrdf,x:m_hsr,_two	
	movep	x:m_hrx,dest
	endm



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;  ON CHIP X, Y, AND LONG MEMORY STORAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;  LONG MEMORY
;;  Long memory occupies both x and y memory,
;;  so no x or y variables are allowed in this space.

l_a_save		equ	$3D	; $3D - $3D (1)
l_phaseInc		equ	$3E	; $3E - $3E (1)
l_currentPhase		equ	$3F	; $3F - $3F (1)
l_FIR_base		equ	$80	; $80 - $BF (64) x and y space for FIR filter



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;  X MEMORY

x_STATUS_flags		equ	$00	; status flags (use $00 for use with jset)
x_tableMod		equ	$01
x_x0_save		equ	$02
x_FIR_size		equ	$03
x_FIR_mod		equ	$04
x_lpn1			equ	$05


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;  Y MEMORY

;; INPUT FROM HOST
PHASE_INC_INT		equ	$00
PHASE_INC_FRAC		equ	$01
AMPLITUDE		equ	$02
BALANCE			equ	$03
NUMBER_HARMONICS	equ	$04
RATE			equ	$05


;; CONVERTED PARAMETERS
OSC_AMP			equ	$10
BALANCE_R               equ     $11
BALANCE_L               equ     $12
F_RATE			equ	$13
G_RATE			equ	$14
CUR_AMP			equ	$15



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;  STATUS FLAG BITS

DMA_OUT_DONE		equ	0	; indicates dma-out is complete
DMA_IN_DONE		equ	1	; indicates dma-in is complete
DMA_IN_ACCEPTED 	equ	2	; indicates dma-in accepted by host
RUN_STATUS		equ	3	; indicates if synth to run
PARAM_UPDATE		equ	4	; indicates if parameters need updating
UPDATE_FREQUENCY	equ	5	; frequency needs updating
UPDATE_AMPLITUDE	equ	6	; amplitude needs updating
UPDATE_BALANCE		equ	7	; balance needs updating
UPDATE_WAVETABLE	equ	8	; wavetable needs updating
UPDATE_RATE		equ	9	; rate needs updating



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;  OFF-CHIP X, Y AND PROGRAM MEMORY (CANNOT BE OVERLAID)
;;
;;  total offchip memory	$2000 - $3FFF	(8192)
;;
;;  reserved program memory	$2000 - 27FF	(2048)
;;  oscillator buffer		$2800 - $28FF	(256)
;;  free memory			$2900 - $2FFF	(1792)
;;  DMA output buffer 		$3000 - $37FF	(2048)
;;  free memory			$3800 - $3FFF	(2048)


;;  WAVETABLE MEMORY ALLOCATION
SINE_WAVE_TABLE		equ	$0100		; base address of sine wavetable
SINE_TABLE_SIZE		equ	256		; size of sine table (must match 68040)

OSC_WAVE_TABLE		equ	$2800		; base address of oscillator wavetable
OSC_TABLE_SIZE		equ	256		; size of oscillator table

;;  DMA OUTPUT BUFFERS MEMORY ALLOCATION
DMA_OUT_BUFFER		equ	$3000		; dma output buffer
DMA_OUT_SIZE    	equ     2048		; size of output buffer (must match 040)



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;  REGISTER USE
;;	r0	m0	n0	oscillator waveform table pointer
;;	r1	m1		sine waveform table pointer
;;	r2	m2
;;      r3      m3		FIR filter pointer
;;	r4	m4		FIR filter pointer
;;      r5      m5
;;	r6	m6		DMA buffer pointer
;;	r7	m7


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;  MISC. CONSTANTS

AMP_THRESHOLD	equ	0.01


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;  DMA MESSAGES

DMA_OUT_REQ	equ	$050001		; message to host to request dma-OUT
DMA_IN_REQ	equ	$040002		; message to host to request dma-IN 




;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;  INTERRUPT VECTORS

	IF !DEBUG_56

	org	p:VEC_RESET
	jmp	reset

	org	p:VEC_DMA_OUT_DONE	; DMA-OUT completed.
	bset	#DMA_OUT_DONE,x:x_STATUS_flags
	nop

	org	p:VEC_START
	bset	#RUN_STATUS,x:x_STATUS_flags
	nop

	org	p:VEC_STOP
	bclr	#RUN_STATUS,x:x_STATUS_flags
	nop

	org	p:VEC_SET_FREQUENCY
	jsr	set_frequency

	org	p:VEC_SET_AMPLITUDE
	jsr	set_amplitude

	org	p:VEC_SET_BALANCE
	jsr	set_balance

	org	p:VEC_SET_WAVETABLE
	jsr	set_wavetable

	org	p:VEC_SET_RATE
	jsr	set_rate

	ORG	P:VEC_LOAD_FIR_COEF
	jsr	load_fir_coefficients

	ENDIF



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;  RESET SUBROUTINE:  initializes the synthesizer

	org	p:ON_CHIP_PROGRAM_START
reset

;; SET UP CHIP
	bclr	#m_hcie,x:m_hcr		; disable host command interrupts
	bclr	#m_hrie,x:m_hcr		; disable host receive interrupt
					; (no interrupts while setting up)
	movec	#6,omr			; chip set to mode 2; ROM enabled
	bset	#0,x:m_pbc		; set port B to be host interface
	bset	#3,x:m_pcddr		; set pin 3 (pc3) of port C to be output
	bclr	#3,x:m_pcd		; zero to enable the external ram
	movep	#>$000000,x:m_bcr	; set 0 wait states for all external RAM
	movep	#>$000c00,x:m_ipr	; set interrupt priority register to
					; SSI=0, SCI=0, HOST=2
;; SET UP VARIABLES
	clr	a
	move	a10,l:l_currentPhase	; set current phase angle to 0
	move	a,y:OSC_AMP		; set oscil ampl to 0 (ready for interpolation)
	move	a,y:BALANCE_R		; clear balance variables
	move	a,y:BALANCE_L
	move	a,y:CUR_AMP		; clear current amplitude
	move	a,x:x_STATUS_flags	; clear status flags
	move	a,x:x_lpn1		; clear lowpass filter memory

;; SET UP REGISTERS
	move	#>OSC_WAVE_TABLE,r0	; set register to base of waveform table
	move	#>OSC_TABLE_SIZE-1,x0
	move	x0,x:x_tableMod		; set mask to tablesize - 1
	move	x0,m0			; set modulus for waveform table

	move	#>SINE_WAVE_TABLE,r1	; set register to base of waveform table
	move	#>SINE_TABLE_SIZE-1,m1	; set modulus for waveform table

	move	#>l_FIR_base,r3		; set register to base of FIR filter memory
	move	#>l_FIR_base,r4		; set register to base of FIR filter memory

	move	#>DMA_OUT_BUFFER,r6	; store base of dma buffer
	move	#>DMA_OUT_SIZE-1,m6	; set modulus for dma buffer

;; UNMASK INTERRUPTS
	bset    #m_hcie,x:m_hcr		; enable host command interrupts
	move	#0,sr			; unmask interrupts

;; LOOP HERE UNTIL SIGNALLED TO START BY THE HOST
wait	jclr	#RUN_STATUS,x:x_STATUS_flags,wait	; loop here if not running



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;  MAIN LOOP:  where samples are created


;;  RAMP AMPLITUDE TO ZERO, IF WE ARE SIGNALLED TO STOP, AND THEN AWAIT START SIGNAL
top	jset	#RUN_STATUS,x:x_STATUS_flags,_next	; continue, if not stopped
	 jsr	ramp_to_zero				; else, ramp to zero amplitude
	 jmp	wait					; and wait to restart

;; UPDATE PARAMETERS, IF A PARAMETER HAS JUST BEEN LOADED
_next	jsset	#PARAM_UPDATE,x:x_STATUS_flags,update_parameters

;; CALCULATE OUTPUT OF ASYMPTOTIC ENVELOPE GENERATOR
	jsr	envelope_generator		; output in y:CUR_AMP

;; GENERATE ONE SAMPLE OF WAVEFORM
	jsr	oversampling_oscillator		; output in a

;; PASS THE SIGNAL THROUGH A FIXED LOWPASS FILTER
	jsr	lowpass_filter

;; SCALE OUTPUT ACCORDING TO CURRENT AMPLITUDE FROM ENVELOPE GENERATOR
	move	y:CUR_AMP,y0   a,x0		; get current amplitude factor
	mpyr	x0,y0,a				; scale output signal

;; SCALE THE SAMPLE TO THE RIGHT 8 BITS, SINCE THE D/A USES THE LOWER 16 BITS
	move	a,x0	#@cvf(@pow(2,-8.0)),y0
	mpyr	x0,y0,a

;; OUTPUT THE SAMPLE
	jsr	write_sample_stereo		; put sample to DMA buffer

	jmp	top				; loop forever



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;  RAMP_TO_ZERO SUBROUTINE:  creates output until the signal is below the threshold

ramp_to_zero

;;  SET TARGET AMPLITUDE TO ZERO
	clr	a
	move	a,y:OSC_AMP

;; CALCULATE OUTPUT OF ASYMPTOTIC ENVELOPE GENERATOR
_top	jsr	envelope_generator		; output in a and y:CUR_AMP

;; IF ENVELOPE BELOW THRESHOLD, SIGNAL HOST AND RETURN
	move	#@cvf(AMP_THRESHOLD),x1
	cmp	x1,a
	jgt	_next				; if above threshold, continue
	 bset	#m_hf3,x:m_hcr			; else, set hf3
	 rts					; and return

;; GENERATE ONE SAMPLE OF WAVE
_next	jsr	oversampling_oscillator		; output in a

;; PASS THE SIGNAL THROUGH A FIXED LOWPASS FILTER
	jsr	lowpass_filter

;; SCALE OUTPUT ACCORDING TO CURRENT AMPLITUDE FROM THE ENVELOPE GENERATOR
	move	y:CUR_AMP,y0   a,x0		; get amplitude factor
	mpyr	x0,y0,a				; scale output signal

;; SCALE THE SAMPLE TO THE RIGHT 8 BITS  */
	move	a,x0	#@cvf(@pow(2,-8.0)),y0
	mpyr	x0,y0,a

;; OUTPUT THE SAMPLE
	jsr	write_sample_stereo		; put sample to DMA buffer

;; LOOP UNTIL BELOW THRESHOLD
	jmp	_top



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;  UPDATE_PARAMETERS SUBROUTINE:  convert input table values
;;  to synthesizer parameter values

update_parameters
	bclr	#m_hcie,x:m_hcr			; disable host command interrupts

	jsset	#UPDATE_FREQUENCY,x:x_STATUS_flags,convert_increment
	jsset	#UPDATE_AMPLITUDE,x:x_STATUS_flags,convert_amplitude
	jsset	#UPDATE_BALANCE,x:x_STATUS_flags,convert_balance
	jsset	#UPDATE_WAVETABLE,x:x_STATUS_flags,create_wavetable
	jsset	#UPDATE_RATE,x:x_STATUS_flags,convert_rate

	bclr	#PARAM_UPDATE,x:x_STATUS_flags	; clear status flag
	bset	#m_hcie,x:m_hcr			; enable host command interrupts
	rts



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;  CONVERT_INCREMENT SUBROUTINE:  creates phase increment from integer
;;  and fractional parts
;;
;;  input in y:PHASE_INC_FRAC and y:PHASE_INC_INT
;;  output in l:l_phaseInc

convert_increment
	clr	a
	move	y:PHASE_INC_FRAC,a0	; get frac. part of inc. from input table
	asl	a			; get rid of sign bit, left justify
	move	y:PHASE_INC_INT,a1	; get integer part of increment
	move	a10,l:l_phaseInc	; store phase angle increment
	bclr	#UPDATE_FREQUENCY,x:x_STATUS_flags	; clear status flag
	rts



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;  CONVERT_AMPLITUDE SUBROUTINE:  moves input amplitude to target value
;;  variablefor the envelope generator
;;
;;  input in y:AMPLITUDE
;;  output in y:OSC_AMP

convert_amplitude
	move	y:AMPLITUDE,a
	move	a,y:OSC_AMP
	bclr	#UPDATE_AMPLITUDE,x:x_STATUS_flags	; clear status flag
	rts



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;  CONVERT_BALANCE SUBROUTINE:  convert balance parameter to left and right factors
;;
;;  scaled input balance (-1.0 to +1.0) in y:BALANCE
;;
;;  right channel scale in y:BALANCE_R
;;  left channel scale in y:BALANCE_L

convert_balance
	move	y:BALANCE,a				; get balance value
	asr	a	#@cvf(0.5),x0			; a /= 2
	add	x0,a	#@cvf(0.9999998),b		; a += 0.5
	sub	a,b	a,y:BALANCE_R			; L = 1 - R  store R channel
	move	b,y:BALANCE_L				; store L channel scale
	bclr	#UPDATE_BALANCE,x:x_STATUS_flags	; clear status flag
	rts



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;  CREATE_WAVETABLE SUBROUTINE:  creates sawtooth waveform with specified
;;  number of harmonics.
;;
;;  input in y:NUMBER_HARMONICS
;;  output in array at r0

create_wavetable

;;  CLEAR WAVETABLE
	clr a
	do #OSC_TABLE_SIZE,_end_loop
	  move	a,y:(r0)+
_end_loop

;;  CREATE WAVETABLE WITH NUMBER OF HARMONICS SPECIFIED
	move	y:NUMBER_HARMONICS,b
	do 	b,_end_outer_loop
	 movec	lc,x1		; x1 = loopCount
	 move	x1,n1
	 jsr	reciprocal	; divisor in y0 (1/loopCount)
	 move	y0,a
	 asr	a		; divisor /= 2  this eliminates clipping
	 move	a,y0
	 move	#>SINE_WAVE_TABLE,r1
	 do #OSC_TABLE_SIZE,_end_inner_loop
	  move	y:(r0),a
	  move	y:(r1)+n1,x0
	  macr	x0,y0,a
	  move	a,y:(r0)+
_end_inner_loop
	 nop
_end_outer_loop
	nop

	bclr	#UPDATE_WAVETABLE,x:x_STATUS_flags	; clear status flag
	rts



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;  CCONVERT_RATE SUBROUTINE:  converts the envelope rate to F and G rates

convert_rate
	move	y:RATE,y1
	move	y1,y:F_RATE			; store F rate
	move	#@cvf(0.9999998),a
	sub	y1,a				; G rate = 1 - F rate
	move	a,y:G_RATE			; store G rate
	bclr	#UPDATE_RATE,x:x_STATUS_flags	; clear status flag
	rts



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;  RECIPROCAL SUBROUTINE:  calculates positive reciprocal
;;
;;  divisor in x1
;;  output (quotient) in y0
;;
;;  overwrites a, y0
;;  preserves x1

reciprocal
	move	#>1,a		; put dividend (1) into a1
	and	#$fe,ccr	; make sure carry bit is clear
	rep	#$18		; do division
	div	x1,a
	move	a0,y0		; put result into y0
	rts



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;  ENVELOPE_GENERATOR SUBROUTINE:  asymptotic envelope generator
;;
;;  input in y:CUR_AMP, y:G_RATE, y:F_RATE, y:OSC_AMP
;;  output in y:CUR_AMP (also a)

envelope_generator
	move	y:CUR_AMP,x1
	move	y:G_RATE,x0
	mpy	x0,x1,a			; a = G rate * current amplitude
	move	y:F_RATE,y0
	move	y:OSC_AMP,y1
	macr	y0,y1,a			; a += F rate * target amplitude
	move	a,y:CUR_AMP		; store calculated amplitude
	rts



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;  LOWPASS_FILTER SUBROUTINE:  one-zero lowpass filter (zero at pi)
;;
;;  input in a
;;  output in a

lowpass_filter
	move	x:x_lpn1,y0		; x[n-1] -> y0
	move	a,x0			; x[n] -> x0
	move	#@cvf(0.5),y1		; 0.5 -> y1
	mpy	x0,y1,a	 a,x:x_lpn1	; a = 0.5 * x[n]	store input as x[n-1]
	macr	y0,y1,a			; a += 0.5 * x[n-1]
	rts



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;  OVERSAMPLING_OSCILLATOR SUBROUTINE
;;
;;  output in a

oversampling_oscillator

;; GENERATE ONE SAMPLE USING LINEAR INTERPOLATING OSCILLATOR
	move	l:l_currentPhase,a	; get current phase angle in table
	move	l:l_phaseInc,b		; get phase angle increment
	add	b,a	x:x_tableMod,x1	; calc new current phase angle
					; uses 48 bit addition (int.frac)
	and	x1,a	#>1,y1		; wrap integer part of current phase
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

;;; MOVE THIS SAMPLE INTO THE INPUT OF THE FIR FILTER
	move	a,x:(r3)-		; put sample into input of FIR filter

;; GENERATE SECOND SAMPLE USING LINEAR INTERPOLATING OSCILLATOR
	move	l:l_currentPhase,a	; get current phase angle in table
	move	l:l_phaseInc,b		; get phase angle increment
	add	b,a	x:x_tableMod,x1	; calc new current phase angle
					; uses 48 bit addition (int.frac)
	and	x1,a	#>1,y1		; wrap integer part of current phase
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

;; FILTER THE TWO SAMPLES USING THE FIR FILTER
	clr	a	a,x:(r3)+	y:(r4)+,y0
	do x:x_FIR_mod,_end_loop
	 mac	x0,y0,a	x:(r3)+,x0	y:(r4)+,y0
_end_loop
	macr	x0,y0,a	(r3)-

	rts				; output in a is decimated signal



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;  WRITE_SAMPLE_STEREO SUBROUTINE
;;
;;  input in a

write_sample_stereo
	move	a,x0	 y:BALANCE_L,y0	; signal in x0, L scaling -> y0
	mpy	x0,y0,a	 y:BALANCE_R,y1	; scale L channel, R scaling -> y1
	mpy	x0,y1,b	 a,x:(r6)+	; scale R channel, L value -> dma buffer
	move	b,x:(r6)+		; R value -> dma buffer
	move	#>DMA_OUT_BUFFER,x0	; store base of dma buffer
	move	r6,a			; put current index in a
	cmp	x0,a			; if (current index==buffer base)
	jseq	write_DMA_buffer	; then the buffer is full, so write it out

	rts



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;  WRITE_DMA_BUFFER SUBROUTINE:  writes one complete DMA to
;;  the host, reading from the dma empty buffer.

write_DMA_buffer
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

_ackEnd	jset	#m_hf1,x:m_hsr,_ackEnd	; loop until host ack. has ended (HF1=0)

	bclr	#m_hf2,x:m_hcr			; signal host interactive input allowed
	rts



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;  SET_FREQUENCY HOST COMMAND SERVICE ROUTINE

set_frequency

	bclr	#m_hcie,x:m_hcr			; disable host command interrupts
	bset	#PARAM_UPDATE,x:x_STATUS_flags		; set status flag
	bset	#UPDATE_FREQUENCY,x:x_STATUS_flags	; set status flag

_one	jclr	#m_hrdf,x:m_hsr,_one
	movep	x:m_hrx,y:PHASE_INC_INT
_two	jclr	#m_hrdf,x:m_hsr,_two
	movep	x:m_hrx,y:PHASE_INC_FRAC

	bset	#m_hcie,x:m_hcr			; enable host command interrupts
	rti



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;  SET_AMPLITUDE HOST COMMAND SERVICE ROUTINE

set_amplitude
	bclr	#m_hcie,x:m_hcr			; disable host command interrupts
	bset	#PARAM_UPDATE,x:x_STATUS_flags		; set status flag
	bset	#UPDATE_AMPLITUDE,x:x_STATUS_flags	; set status flag

	readHost y:AMPLITUDE

	bset	#m_hcie,x:m_hcr			; enable host command interrupts
	rti



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;  SET_BALANCE HOST COMMAND SERVICE ROUTINE

set_balance
	bclr	#m_hcie,x:m_hcr			; disable host command interrupts
	bset	#PARAM_UPDATE,x:x_STATUS_flags		; set status flag
	bset	#UPDATE_BALANCE,x:x_STATUS_flags	; set status flag

	readHost y:BALANCE

	bset	#m_hcie,x:m_hcr			; enable host command interrupts
	rti



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;  SET_WAVETABLE HOST COMMAND INTERRUPT SERVICE ROUTINE

set_wavetable
	bclr	#m_hcie,x:m_hcr			; disable host command interrupts
	bset	#PARAM_UPDATE,x:x_STATUS_flags		; set status flag
	bset	#UPDATE_WAVETABLE,x:x_STATUS_flags	; set status flag

	readHost y:NUMBER_HARMONICS

	bset	#m_hcie,x:m_hcr			; enable host command interrupts
	rti



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;  SET_RATE HOST COMMAND INTERRUPT SERVICE ROUTINE

set_rate
	bclr	#m_hcie,x:m_hcr			; disable host command interrupts
	bset	#PARAM_UPDATE,x:x_STATUS_flags	; set status flag
	bset	#UPDATE_RATE,x:x_STATUS_flags	; set status flag

	readHost y:RATE

	bset	#m_hcie,x:m_hcr			; enable host command interrupts
	rti



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;  LOAD_FIR_COEFFICIENTS HOST COMMAND SERVICE SUBROUTINE

load_fir_coefficients
	bclr	#m_hcie,x:m_hcr		; disable host command interrupts
	move	a10,l:l_a_save		; save the current value of a
	move	x0,x:x_x0_save		; save the current value of x0

	readHost a			; read and store the tablesize
	move	a,x:x_FIR_size

	move	#>1,x0			; modulus = tablesize - 1
	sub	x0,a
	move	a,x:x_FIR_mod		; store modulus (used in FIR routine)
	move	a,m3			; store modulus (used in FIR routine)
	move	a,m4			; store modulus (used in FIR routine)

	move	#>l_FIR_base,r4		; set pointer to beginning of coefficient array
	do x:x_FIR_size,_end_loop
	 readHost y:(r4)+		; read and store each coefficient
_end_loop

	move	#>l_FIR_base,r4		; set register to base of FIR filter memory

	move	l:l_a_save,a10		; restore the saved value of a
	move	x:x_x0_save,x0		; restore the saved value of x0
	bset	#m_hcie,x:m_hcr		; enable host command interrupts
	rti
