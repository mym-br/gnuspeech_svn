/*  REVISION INFORMATION  *****************************************************

$Author: fedor $
$Date: 2003-01-18 05:04:50 $
$Revision: 1.2 $
$Source: /Users/dalmazio/cvsroot/gnuspeech/trillium/src/Synthesizer/dsp_control.c,v $
$State: Exp $


$Log: not supported by cvs2svn $
Revision 1.1  2002/03/21 16:49:54  rao
Initial import.

 * Revision 1.4  1994/09/13  21:42:39  len
 * Folded in optimizations made in synthesizer.asm.
 *
 * Revision 1.3  1994/07/13  03:40:02  len
 * Added Mono/Stereo sound output option and changed file format.
 *
 * Revision 1.2  1994/06/17  21:06:27  len
 * Fixed a bug which occasionally led to interrupted sound out.
 *
 * Revision 1.1.1.1  1994/05/20  00:21:49  len
 * Initial archive of TRM interactive Synthesizer.
 *

******************************************************************************/

/*  INCLUDE FILES  ***********************************************************/
#include "dsp_control.h"

#ifdef HAVE_DSP

#include "oversampling_filter.h"
#include "sr_conversion.h"
#include "fft.h"
#include <stdio.h>
#include <mach/mach.h>
#include <mach/cthreads.h>
#include <sound/sound.h>
#include <sound/sounddriver.h>
#include <dsp/dsp.h>
#include <math.h>


/*  LOCAL DEFINES  ***********************************************************/
#define NO                0
#define YES               1
#define PREFILL_SIZE      4

/*  PRIORITY OF MAIN THREAD, WHEN USING TWO THREADS (FOR ANALYSIS)  */
#define NORMAL_PRIORITY   16
#define LOWERED_PRIORITY  12

/*  GLOBAL FUNCTIONS (LOCAL TO THIS FILE)  ***********************************/
static void synthesizer_thread(int arg);
static void recorded_data(void *arg, int tag, void *data, int nbytes);

#if OVERSAMPLE_OSC
static int load_FIR_coefficients(void);
#endif

static int load_SR_coefficients(void);


/*  GLOBAL VARIABLES (LOCAL TO THIS FILE)  ***********************************/
static kern_return_t k_err;
static port_t dev_port, owner_port, cmd_port, write_port, 
              read_port, reply_port;
static msg_header_t *reply_msg;
static cthread_t synthesizer_cthread;
static int running, prefill;

static int numberTaps;
static DSPFix24 *FIRCoefficients;

static int filterLength;
static DSPFix24 *h, *hDelta;

static int getData = NO;

static short int soundBuffer[DMA_OUT_SIZE];




/******************************************************************************
*
*	function:	initialize_synthesizer
*
*	purpose:	Initializes data and data arrays for use
*                       with the DSP.
*			
*       arguments:      none
*                       
*	internal
*	functions:	initializeFIR, initialize_sr_conversion
*
*	library
*	functions:	none
*
******************************************************************************/

void initialize_synthesizer(void)
{
    /*  INITIALIZE FIR FILTER COEFFICIENTS  */
    #if OVERSAMPLE_OSC
    FIRCoefficients = initializeFIR(FIR_BETA, FIR_GAMMA, FIR_CUTOFF,
				    &numberTaps, FIRCoefficients);
    #endif

    /*  INITIALIZE SAMPLING RATE CONVERSION FILTER COEFFICIENTS  */
    initialize_sr_conversion(ZERO_CROSSINGS, L_BITS, BETA, LP_CUTOFF,
			     &h, &hDelta, &filterLength);
}



/******************************************************************************
*
*	function:	free_synthesizer
*
*	purpose:	Frees memory used to initialize the synthesizer.
*			
*       arguments:      none
*                       
*	internal
*	functions:	none
*
*	library
*	functions:	cfree
*
******************************************************************************/

void free_synthesizer(void)
{
    #if OVERSAMPLE_OSC
    cfree((char *)FIRCoefficients);
    #endif

    cfree((char *)h);
    cfree((char *)hDelta);
}



/******************************************************************************
*
*	function:	grab_and_initialize_DSP
*
*	purpose:	Does initialization and setup necessary to gain control
*                       of the DSP and DAC device, does stream setup, and does
*                       loading of coefficient table.
*
*	internal
*	functions:	none
*
*	library
*	functions:	SNDAcquire, snddriver_set_ramp,
*                       snddriver_set_sndout_bufsize,
*                       snddriver_get_dsp_cmd_port, snddriver_stream_setup,
*                       snddriver_dsp_protocol, SNDBootDSP, 
*                       snddriver_stream_control, load_FIR_coefficients
*                       load_SR_coefficients, snddriver_stream_control,
*                       cthread_fork
*
******************************************************************************/

int grab_and_initialize_DSP(int analysis_enabled)
{
    int s_err, protocol;
    SNDSoundStruct *dspStruct;

    /*  INCLUDE DSP CORE FILE  */
    #include DSPCORE


    /*  GET CONTROL OF DSP AND DAC  */
    dev_port = owner_port = 0;
    s_err = SNDAcquire(SND_ACCESS_DSP|SND_ACCESS_OUT,10,0,0,
		       NULL_NEGOTIATION_FUN,0,&dev_port,&owner_port); 
    if (s_err != SND_ERR_NONE)
	return(ST_ERROR);

    /*  SET RAMPING OFF (NOT NEEDED, AND IT SLOWS SOUND OUT)  */
    k_err = snddriver_set_ramp(dev_port,0);
    if (k_err != KERN_SUCCESS)
	return(ST_ERROR);

    /*  SET THE SOUND OUT BUFFER SIZE SMALLER SO NO GLITCHES IN SOUND OUT  */
    k_err = snddriver_set_sndout_bufsize(dev_port, owner_port, 128);
    if (k_err != KERN_SUCCESS)   /*  never set less than 128  */
	return(ST_ERROR);

    /*  GET THE DSP COMMAND PORT  */
    k_err = snddriver_get_dsp_cmd_port(dev_port,owner_port,&cmd_port);
    if (k_err != KERN_SUCCESS)
	return(ST_ERROR);

    /*  INITIALIZE THE PROTOCOL VARIABLE  */
    protocol = SNDDRIVER_DSP_PROTO_RAW;

    /*  SET UP ONE OR MORE STREAMS, ACCORDING TO NEED  */
    if (analysis_enabled) {
	/*  SET UP DSP->HOST STREAM  */
	k_err = snddriver_stream_setup(dev_port, owner_port,
				       SNDDRIVER_DMA_STREAM_FROM_DSP,
				       DMA_OUT_SIZE, 2,
				       LOW_WATER, HIGH_WATER,
				       &protocol, &read_port);
	if (k_err != KERN_SUCCESS)
	    return(ST_ERROR);
	
	/*  SET UP HOST->DAC STREAM  */
	k_err = snddriver_stream_setup(dev_port, owner_port,
				       SNDDRIVER_STREAM_TO_SNDOUT_22,
				       DMA_OUT_SIZE, 2,
				       LOW_WATER, HIGH_WATER,
				       &protocol, &write_port);
	if (k_err != KERN_SUCCESS)
	    return(ST_ERROR);
	
	/*  PAUSE THE HOST->DAC STREAM, SO WE CAN PREFILL SOME BUFFERS  */
	snddriver_stream_control(write_port, 0, SNDDRIVER_PAUSE_STREAM);
    }
    else {
	/*  SET UP DSP->DAC STREAM, STEREO OUTPUT  */
	k_err = snddriver_stream_setup(dev_port, owner_port,
				       SNDDRIVER_STREAM_DSP_TO_SNDOUT_22,
				       DMA_OUT_SIZE, 2, 
				       LOW_WATER, HIGH_WATER,
				       &protocol, &write_port);
	if (k_err != KERN_SUCCESS)
	    return(ST_ERROR);
    }
    

    /*  SET THE DSP PROTOCOL  */
    k_err = snddriver_dsp_protocol(dev_port, owner_port, protocol);
    if (k_err != KERN_SUCCESS)
	return(ST_ERROR);


    /*  BOOT THE DSP WITH THE .lod IMAGE CONTAINED IN DSPCORE.H FILE  */
    /*  THE DSPCORE.H FILE IS MADE BY RUNNING dspLod2Core ON THE .lod FILE  */
    dspStruct = (SNDSoundStruct *)dspcore;
    s_err = SNDBootDSP(dev_port, owner_port, dspStruct);
    if (s_err != SND_ERR_NONE)
	return(ST_ERROR);

    /*  LOAD FIR COEFFICIENTS  */
    #if OVERSAMPLE_OSC
    if (load_FIR_coefficients() == ST_ERROR)
	return(ST_ERROR);
    #endif

    /*  LOAD THE SAMPLE RATE CONVERSTION COEFFICIENTS AND DELTAS  */
    if (load_SR_coefficients() == ST_ERROR)
	return(ST_ERROR);

    /*  FORK SYNTHESIZER THREAD, IF WE NEED IT FOR DATA ANALYSIS  */
    if (analysis_enabled) {
	synthesizer_cthread = cthread_fork((void *)synthesizer_thread, 0);
	/*  DEPRESS THE PRIORITY OF MAIN THREAD, SO NO INTERRUPTIONS OF SOUND  */
	cthread_priority(cthread_self(), LOWERED_PRIORITY, FALSE);
    }

    /*  IF WE GET HERE, THEN THE DSP IS INITIALIZED AND READY TO GO  */
    return(ST_NO_ERROR);
}



/******************************************************************************
*
*	function:	relinquish_DSP
*
*	purpose:	Gives up control of the DSP and DAC devices.
*
*	internal
*	functions:	none
*
*	library
*	functions:	SNDRelease
*
******************************************************************************/

int relinquish_DSP(void)
{
    int s_err;

    /*  RESET MAIN THREAD BACK TO NORMAL PRIORITY  */
    cthread_priority(cthread_self(), NORMAL_PRIORITY, FALSE);

    /*  GIVE UP CONTROL OVER DSP AND SOUND OUT  */
    s_err = SNDRelease(SND_ACCESS_DSP|SND_ACCESS_OUT, dev_port, owner_port);
    if (s_err != SND_ERR_NONE)
	return(ST_ERROR);
    else
	return (ST_NO_ERROR);
}



/******************************************************************************
*
*	function:	start_synthesizer
*
*	purpose:	Sends a start host command to the DSP.
*
*	internal
*	functions:	none
*
*	library
*	functions:	snddriver_dsp_host_cmd
*
******************************************************************************/

int start_synthesizer(void)
{
    /*  SET RUNNING STATUS FLAG ON  */
    running = YES;

    /*  SIGNAL THE DSP TO START SYNTHESIZING  */
    k_err = snddriver_dsp_host_cmd(cmd_port, HC_START, SNDDRIVER_LOW_PRIORITY);
    if (k_err != KERN_SUCCESS)
	return(ST_ERROR);
    else
	return(ST_NO_ERROR);
}



/******************************************************************************
*
*	function:	stop_synthesizer
*
*	purpose:	Sends a stop host command to the DSP.
*
*	internal
*	functions:	none
*
*	library
*	functions:	snddriver_dsp_host_cmd
*
******************************************************************************/

int stop_synthesizer(void)
{
    /*  SET RUNNING STATUS FLAG OFF  */
    running = NO;

    /*  SIGNAL THE DSP TO STOP SYNTHESIZING  */
    k_err = snddriver_dsp_host_cmd(cmd_port, HC_STOP, SNDDRIVER_LOW_PRIORITY);
    if (k_err != KERN_SUCCESS)
	return(ST_ERROR);
    else
	return(ST_NO_ERROR);
}



/******************************************************************************
*
*	function:	write_datatable
*
*	purpose:	Sends datatable to the DSP, even if the DSP is
*                       currently sending sound out to the DAC.
*			
*       arguments:      datatable - array of DSPFix24's to send to the DSP.
*                       size - size of the datatable array.
*                       
*	internal
*	functions:	none
*
*	library
*	functions:	snddriver_dspcmd_req_condition, snddriver_dsp_host_cmd,
*                       snddriver_dsp_write
*
******************************************************************************/

int write_datatable(DSPFix24 *datatable, int size)
{
    /*  DON'T SEND HC DURING OUTPUT (I.E. WHILE DSP SETS HF2 TO 1)  */
    k_err =  snddriver_dspcmd_req_condition(cmd_port, SNDDRIVER_ISR_HF2, 0,
					    SNDDRIVER_LOW_PRIORITY, PORT_NULL);
    if (k_err != KERN_SUCCESS)
	return(ST_ERROR);

    k_err = snddriver_dsp_host_cmd(cmd_port, HC_LOAD_DATATABLE,
				   SNDDRIVER_LOW_PRIORITY);
    if (k_err != KERN_SUCCESS)
	return(ST_ERROR);
    else {
	k_err = snddriver_dsp_write(cmd_port, datatable, size, sizeof(DSPFix24),
				    SNDDRIVER_LOW_PRIORITY);
	if (k_err != KERN_SUCCESS)
	    return(ST_ERROR);
    }

  return(ST_NO_ERROR);
}



/******************************************************************************
*
*	function:	load_FIR_coefficients
*
*	purpose:	Writes the oversampling oscillator FIR filter
*                       coefficients to the DSP.  Note that the size of the
*                       array is sent first.
*			
*       arguments:      none
*                       
*	internal
*	functions:	none
*
*	library
*	functions:	snddriver_dspcmd_req_condition, snddriver_dsp_host_cmd,
*                        snddriver_dsp_write, DSPIntToFix24
*
******************************************************************************/

int load_FIR_coefficients(void)
{
    /*  DON'T SEND HC DURING OUTPUT (I.E. WHILE DSP SETS HF2 TO 1)  */
    k_err =  snddriver_dspcmd_req_condition(cmd_port, SNDDRIVER_ISR_HF2, 0,
					    SNDDRIVER_LOW_PRIORITY, PORT_NULL);
    if (k_err != KERN_SUCCESS)
	return(ST_ERROR);

    /*  SEND THE HOST COMMAND  */
    k_err = snddriver_dsp_host_cmd(cmd_port, HC_LOAD_FIR_COEF,
				   SNDDRIVER_LOW_PRIORITY);
    if (k_err != KERN_SUCCESS)
	return(ST_ERROR);
    else {
	DSPFix24 size = DSPIntToFix24(numberTaps);
	/*  SEND SIZE OF THE ARRAY FIRST  */
	k_err = snddriver_dsp_write(cmd_port, &size, 1,
				    sizeof(DSPFix24), SNDDRIVER_LOW_PRIORITY);
	if (k_err != KERN_SUCCESS)
	    return(ST_ERROR);

	/*  SEND THE ARRAY ITSELF  */
	k_err = snddriver_dsp_write(cmd_port, FIRCoefficients, numberTaps,
				    sizeof(DSPFix24), SNDDRIVER_LOW_PRIORITY);
	if (k_err != KERN_SUCCESS)
	    return(ST_ERROR);
    }

  return(ST_NO_ERROR);
}



/******************************************************************************
*
*	function:	load_SR_coefficients
*
*	purpose:	Writes the sampling rate conversion coefficients and
*                       deltas to the DSP.
*			
*       arguments:      none
*                       
*	internal
*	functions:	none
*
*	library
*	functions:	snddriver_dspcmd_req_condition, snddriver_dsp_host_cmd,
*                       snddriver_dsp_write
*
******************************************************************************/

int load_SR_coefficients(void)
{
    /*  DON'T SEND HC DURING OUTPUT (I.E. WHILE DSP SETS HF2 TO 1)  */
    k_err =  snddriver_dspcmd_req_condition(cmd_port, SNDDRIVER_ISR_HF2, 0,
					    SNDDRIVER_LOW_PRIORITY, PORT_NULL);
    if (k_err != KERN_SUCCESS)
	return(ST_ERROR);

    /*  SEND THE HOST COMMAND  */
    k_err = snddriver_dsp_host_cmd(cmd_port, HC_LOAD_SR_COEF,
				   SNDDRIVER_LOW_PRIORITY);
    if (k_err != KERN_SUCCESS)
	return(ST_ERROR);
    else {
	/*  SEND THE SAMPLE RATE CONVERSION COEFFICIENTS  */
	k_err = snddriver_dsp_write(cmd_port, h, filterLength,
				    sizeof(DSPFix24), SNDDRIVER_LOW_PRIORITY);
	if (k_err != KERN_SUCCESS)
	    return(ST_ERROR);

	/*  SEND THE DELTA VALUES  */
	k_err = snddriver_dsp_write(cmd_port, hDelta, filterLength,
				    sizeof(DSPFix24), SNDDRIVER_LOW_PRIORITY);
	if (k_err != KERN_SUCCESS)
	    return(ST_ERROR);
    }

  return(ST_NO_ERROR);
}



/******************************************************************************
*
*	function:	write_bandlimited_gp
*
*	purpose:	Creates a table which contains one cycle of a band-
*                       limited glottal pulse, with the specified rise time,
*                       fall time, top harmonic, and roll-off factor.
*			
*       arguments:      riseTime - rise time of the glottal pulse (0.0 - 0.5)
*                       fallTime - fall time of the glottal pulse (0.0 - 0.5)
*                       topHarmonic - harmonics above this are set to 0
*                       rolloff - factor used to rolloff upper harmonics
*	internal
*	functions:	four1
*
*	library
*	functions:	pow, DSPFloatToFix24, snddriver_dspcmd_req_condition,
*                       snddriver_dsp_host_cmd, snddriver_dsp_write
*
******************************************************************************/

int write_bandlimited_gp(float riseTime, float fallTime,
			 int topHarmonic, float rolloff)
{
    float wavetable[GP_TABLE_SIZE], complexTable[GP_TABLE_SIZE*2];
    float maxSample = 0.0, scale;
    DSPFix24 table[GP_TABLE_SIZE];
    int i, j, tableDiv1, tableDiv2, tnLength, zeroHarmonics;
    int numberHarmonics = GP_TABLE_SIZE / 2;

    /*  GENERATE THE GLOTTAL PULSE WAVEFORM  */
    tableDiv1 = (int)rint(GP_TABLE_SIZE * riseTime);
    tableDiv2 = (int)rint(GP_TABLE_SIZE * (riseTime + fallTime));
    tnLength = tableDiv2 - tableDiv1;
    /*  CALCULATE RISE PORTION  */
    for (i = 0; i < tableDiv1; i++) {
	double x = (double)i / (double)tableDiv1;
	double x2 = x * x;
	double x3 = x2 * x;
	wavetable[i] = (3.0 * x2) - (2.0 * x3);
    }
    /*  CALCULATE FALL PORTION  */
    for (i = tableDiv1, j = 0; i < tableDiv2; i++, j++) {
	double x = (double)j / tnLength;
	wavetable[i] = 1.0 - (x * x);
    }
    /*  CALCULATE CLOSED PORTION  */
    for (i = tableDiv2; i < GP_TABLE_SIZE; i++)
	wavetable[i] = 0.0;


    /*  CONVERT INTO COMPLEX NUMBERS  */
    for (i = 0, j = 0; i < GP_TABLE_SIZE; i++) {
	complexTable[j++] = wavetable[i];
	complexTable[j++] = 0.0;
    }

    /*  PERFORM AN FFT ON THE WAVEFORM  */
    four1(complexTable, GP_TABLE_SIZE, 1);

    /*  REDUCE OR ELIMINATE HIGHER HARMONICS  */
    zeroHarmonics = numberHarmonics - topHarmonic;
    /*  ZERO NYQUIST HARMONIC  */
    complexTable[GP_TABLE_SIZE] = complexTable[GP_TABLE_SIZE+1] = 0.0;
    /*  ZERO OUT HARMONICS HARMONICS ABOVE CUTOFF  */
    for (i = 1; i < zeroHarmonics; i++) {
	int rightReal = GP_TABLE_SIZE + (i * 2);
	int rightImaginary = rightReal + 1;
	int leftReal = GP_TABLE_SIZE - (i * 2);
	int leftImaginary = leftReal + 1;

	complexTable[rightReal] = complexTable[rightImaginary] = 0.0;
	complexTable[leftReal] = complexTable[leftImaginary] = 0.0;
    }
    /*  SMOOTHLY ATTENUATE LOWER HARMONICS  */
    for (i = 1, j = zeroHarmonics; i <= topHarmonic; i++, j++) {
	int rightReal = GP_TABLE_SIZE + (j * 2);
	int rightImaginary = rightReal + 1;
	int leftReal = GP_TABLE_SIZE - (j * 2);
	int leftImaginary = leftReal + 1;
	float factor = (1.0 - pow(rolloff,(double)i)) / (float)GP_TABLE_SIZE;
	
	complexTable[rightReal] *= factor;
	complexTable[rightImaginary] *= factor;
	complexTable[leftReal] *= factor;
	complexTable[leftImaginary] *= factor;
    }
    /*  ALSO SCALE DC COMPONENT  */
    complexTable[0] *= ((1.0 - pow(rolloff,(double)i)) / (float)GP_TABLE_SIZE);
    complexTable[1] *= ((1.0 - pow(rolloff,(double)i)) / (float)GP_TABLE_SIZE);
    

    /*  TRANSFORM BACK TO TIME DOMAIN, USING IFFT  */
    four1(complexTable, GP_TABLE_SIZE, -1);

    /*  USE ONLY THE REAL PART  */
    for (i = 0, j = 0; i < GP_TABLE_SIZE; i++, j+=2) {
	wavetable[i] = complexTable[j];
	if (wavetable[i] > maxSample)
	    maxSample = wavetable[i];
    }

    /*  SCALE SO THAT VALUES STAY IN RANGE, AND CONVERT TO DSPFIX24s  */
    scale = MAX_SIZE / maxSample;
    for (i = 0; i < GP_TABLE_SIZE; i++)
	table[i] = DSPFloatToFix24(wavetable[i] * scale);

    /*  LOAD THE WAVETABLE ONTO THE DSP  */
    /*  DON'T SEND HC DURING OUTPUT (I.E. WHILE DSP SETS HF2 TO 1)  */
    k_err =  snddriver_dspcmd_req_condition(cmd_port, SNDDRIVER_ISR_HF2, 0,
					    SNDDRIVER_LOW_PRIORITY, PORT_NULL);
    if (k_err != KERN_SUCCESS)
	return(ST_ERROR);

    /*  SEND THE HOST COMMAND  */
    k_err = snddriver_dsp_host_cmd(cmd_port, HC_LOAD_WAVETABLE,
				   SNDDRIVER_LOW_PRIORITY);
    if (k_err != KERN_SUCCESS)
	return(ST_ERROR);
    else {
	/*  SEND THE WAVETABLE  */
	k_err = snddriver_dsp_write(cmd_port, table, GP_TABLE_SIZE,
				    sizeof(DSPFix24), SNDDRIVER_LOW_PRIORITY);
	if (k_err != KERN_SUCCESS)
	    return(ST_ERROR);
    }

    return(ST_NO_ERROR);
}



/******************************************************************************
*
*	function:	stereoSoundBuffer
*
*	purpose:	Returns a pointer to a buffer filled with sound
*                       samples, taken from the stream between the DSP and
*			the host.
*
*       arguments:      none
*                       
*	internal
*	functions:	none
*
*	library
*	functions:	cthread_yield
*
******************************************************************************/

short int *stereoSoundBuffer(void)
{
    /*  TELL OTHER THREAD WE WANT DATA  */
    getData = YES;

    /*  WAIT TILL OTHER THREAD HAS COPIED DATA INTO BUFFER  */
    while (getData)
	cthread_yield();

    /*  RETURN POINTER TO THE BUFFER  */
    return(soundBuffer);
}



/******************************************************************************
*
*	function:	synthesizer_thread
*
*	purpose:	This function is used to manage the stream of data
*                       from the DSP to the host, and then to the DAC.  
*			
*       arguments:      arg - not used.
*                       
*	internal
*	functions:	recorded_data
*
*	library
*	functions:	port_allocate, task_self, port_set_backlog, malloc,
*                       snddriver_stream_start_reading, msg_receive,
*                       snddriver_reply_handler, port_deallocate, free,
*                       cthread_exit
*
******************************************************************************/

void synthesizer_thread(int arg)
{
    kern_return_t k_err;
    snddriver_handlers_t handlers = {0,0,0,0,0,0,0,0,recorded_data};

    /*  RAISE THE PRIORITY UP TO NORMAL PRIORITY AFTER FORK  */
    cthread_priority(cthread_self(), NORMAL_PRIORITY, FALSE);

    /*  ALLOCATE A PORT FOR REPLIES FROM THE SOUND DRIVER  */
    port_allocate(task_self(), &reply_port);

    /*  ENLARGE REPLY QUEUE TO MAXIMUM ALLOWED SIZE  */
    port_set_backlog(task_self(), reply_port, PORT_BACKLOG_MAX);

    /*  ALLOCATE MEMORY FOR RETURN MESSAGE FROM SOUND DRIVER  */
    reply_msg = (msg_header_t *)malloc(MSG_SIZE_MAX);


    /*  DON'T PROCEED UNTIL THE SYNTHESIZER HAS STARTED  */
    while (running == NO)
	;

    /*  INITIALIZE PREFILL COUNTER  */
    prefill = PREFILL_SIZE;

    /*  LOOP WHERE DATA IS READ INTO THE CPU, ANALYZED IF ASKED
	FOR, AND THEN TRANSFERRED TO THE DAC  */
    while (running) {
	/*  ASK FOR A DATA BUFFER FROM THE DSP  */
	snddriver_stream_start_reading(read_port,
				       NULL,
				       DMA_OUT_SIZE,
				       2,
				       0,0,0,0,0,0, reply_port);

	/*  RECEIVE MESSAGES FROM SOUND DRIVER  */
	reply_msg->msg_size = MSG_SIZE_MAX;
	reply_msg->msg_local_port = reply_port;

	/*  WAIT FOR MESSAGE  */
	k_err = msg_receive(reply_msg, RCV_TIMEOUT, 1000);
	if (k_err == RCV_TIMED_OUT)
	    /*  BREAK OUT OF LOOP IF WE TIME OUT  */
	    break;
	else if (k_err == RCV_SUCCESS)
	    /*  HANDLE DATA FROM DSP  */
	    k_err = snddriver_reply_handler(reply_msg, &handlers);
    }


    /*  DEALLOCATE REPLY PORT  */
    port_deallocate(task_self(), reply_port);

    /*  DEALLOCATE MEMORY FOR RETURN MESSAGE FROM SOUND DRIVER  */
    free((char *)reply_msg);

    /*  THIS THREAD IS DONE  */
    cthread_exit(0);
}



/******************************************************************************
*
*	function:	recorded_data
*
*	purpose:	This function handles messages from the sound driver
*                       that indicate that data has been received from the
*                       DSP.  If there is a request for analysis data, data
*                       is copied to a buffer.  Data is then passed on to the
*                       DAC via a DMA stream.
*			
*       arguments:      arg - not used.
*                       tag - not used.
*                       data - a pointer to memory containing sound data.
*                       nbytes - not used.
*                       
*	internal
*	functions:	none
*
*	library
*	functions:	snddriver_stream_start_writing,
*                       snddriver_stream_control, cthread_yield
*
******************************************************************************/

static void recorded_data(void *arg, int tag, void *data, int nbytes)
{
    /*  RETRIEVE A SOUND DATA BUFFER FOR ANALYSIS, IF ASKED FOR  */
    if (getData) {
	int i;
	short int *inputBuffer = (short int *)data;
	/*  COPY DATA INTO BUFFER  */
	for (i = 0; i < DMA_OUT_SIZE; i++)
	    soundBuffer[i] = inputBuffer[i];
	getData = NO;
    }


    /*  SEND DATA TO DAC, DEALLOCATING THE DATA AS WE GO  */
    snddriver_stream_start_writing(write_port,
				   data,
				   DMA_OUT_SIZE,
				   0,0,1,
				   0,0,0,0,0,0, reply_port);
  
    /*  DON'T START STREAM TO DAC UNTIL WE'VE PREFILLED SOME BUFFERS  */
    if ((prefill--) == 0)
	snddriver_stream_control(write_port, 0, SNDDRIVER_RESUME_STREAM);

    /*  YIELD TO CONTROL THREAD  */
    cthread_yield();
}

#else
/* No DSP */
void initialize_synthesizer(void)
{
}

void free_synthesizer(void)
{
}

int grab_and_initialize_DSP(int analysis_enabled)
{
  return 0;
}

int relinquish_DSP(void)
{
  return 0;
}

int start_synthesizer(void)
{
  return 0;
}

int stop_synthesizer(void)
{
  return 0;
}

int write_bandlimited_gp(float riseTime, float fallTime,
                                int topHarmonic, float rolloff)
{
  return 0;
}

short int *stereoSoundBuffer(void)
{
  return 0;
}

#endif

