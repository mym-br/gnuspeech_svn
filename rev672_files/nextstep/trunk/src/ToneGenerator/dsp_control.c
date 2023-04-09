/*  REVISION INFORMATION  *****************************************************

$Author: rao $
$Date: 2002-03-21 16:49:54 $
$Revision: 1.1 $
$Source: /Users/dalmazio/cvsroot/gnuspeech/trillium/src/ToneGenerator/dsp_control.c,v $
$State: Exp $


$Log: not supported by cvs2svn $
 * Revision 1.1.1.1  1994/06/16  16:40:12  len
 * Initial archive of ToneGenerator application.
 *

******************************************************************************/


/*  INCLUDE FILES  ***********************************************************/
#import "dsp_control.h"
#import "oversampling_filter.h"
#import "conversion.h"
#import <sound/sound.h>
#import <sound/sounddriver.h>
#import <dsp/dspreg.h>
#import <dsp/dsp.h>
#import <math.h>


/*  GLOBAL FUNCTIONS (LOCAL TO THIS FILE)  ***********************************/
static int load_FIR_coefficients(void);


/*  GLOBAL VARIABLES (LOCAL TO THIS FILE)  ***********************************/
static kern_return_t k_err;
static port_t dev_port, owner_port, cmd_port, write_port, reply_port;
static msg_header_t *reply_msg;

static int numberTaps;
static DSPFix24 *FIRCoefficients;

static float timeout;




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
*	functions:	initializeFIR
*
*	library
*	functions:	none
*
******************************************************************************/

void initialize_synthesizer(void)
{
    /*  ALLOCATE A REPLY PORT  */
    port_allocate(task_self(), &reply_port);
    
    /*  ALLOCATE MEMORY FOR RETURN MESSAGE FROM SOUND DRIVER  */
    reply_msg = (msg_header_t *)malloc(MSG_SIZE_MAX);

    /*  INITIALIZE FIR FILTER COEFFICIENTS  */
    FIRCoefficients = initializeFIR(FIR_BETA, FIR_GAMMA, FIR_CUTOFF,
				    &numberTaps, FIRCoefficients);

    /*  INITIALIZE TIMEOUT VALUE  */
    timeout = TIMEOUT_DEF;
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
    /*  DEALLOCATE THE REPLY PORT  */
    port_deallocate(task_self(), reply_port);

    /*  FREE MEMORY USED FOR THE REPLY MESSAGE  */
    free(reply_msg);

    /*  FREE MEMORY USED FOR THE FIR COEFFICIENTS  */
    cfree((char *)FIRCoefficients);
}



/******************************************************************************
*
*	function:	grab_and_initialize_DSP
*
*	purpose:	Does initialization and setup necessary to gain control
*                       of the DSP and DAC device, does stream setup.
*
*	internal
*	functions:	none
*
*	library
*	functions:	SNDAcquire, snddriver_set_ramp,
*                       snddriver_set_sndout_bufsize,
*                       snddriver_get_dsp_cmd_port, snddriver_stream_setup,
*                       snddriver_dsp_protocol, SNDBootDSP, 
*
******************************************************************************/

int grab_and_initialize_DSP(void)
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
    k_err = snddriver_set_sndout_bufsize(dev_port, owner_port, 512);
    if (k_err != KERN_SUCCESS)   /*  never set less than 512  */
	return(ST_ERROR);

    /*  GET THE DSP COMMAND PORT  */
    k_err = snddriver_get_dsp_cmd_port(dev_port,owner_port,&cmd_port);
    if (k_err != KERN_SUCCESS)
	return(ST_ERROR);

    /*  INITIALIZE THE PROTOCOL VARIABLE  */
    protocol = SNDDRIVER_DSP_PROTO_RAW;

    /*  SET UP DSP->DAC STREAM  */
    k_err = snddriver_stream_setup(dev_port, owner_port,
				   SNDDRIVER_STREAM_DSP_TO_SNDOUT_44,
				   DMA_OUT_SIZE, 2, 
				   LOW_WATER, HIGH_WATER,
				   &protocol, &write_port);
    if (k_err != KERN_SUCCESS)
	return(ST_ERROR);

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
    if (load_FIR_coefficients() == ST_ERROR)
	return(ST_ERROR);

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
*	functions:	snddriver_dsp_host_cmd, snddriver_dspcmd_req_condition,
*                       msg_receive
*
******************************************************************************/

int stop_synthesizer(void)
{
    /*  SIGNAL THE DSP TO STOP SYNTHESIZING  */
    k_err = snddriver_dsp_host_cmd(cmd_port, HC_STOP, SNDDRIVER_LOW_PRIORITY);
    if (k_err != KERN_SUCCESS)
	return(ST_ERROR);

    /*  TELL DRIVER TO SEND US A MESSAGE WHEN HF3 IS SET BY THE DSP  */
    k_err = snddriver_dspcmd_req_condition(cmd_port, SNDDRIVER_ISR_HF3,
					   SNDDRIVER_ISR_HF3,
					   SNDDRIVER_LOW_PRIORITY, reply_port);
    if (k_err != KERN_SUCCESS)
	return(ST_ERROR);

    /*  INITIALIZE MESSAGE RECEIVE  */
    reply_msg->msg_size = MSG_SIZE_MAX;
    reply_msg->msg_local_port = reply_port;

    /*  WAIT FOR RETURN MESSAGE, TIMING OUT AFTER TIMEOUT SEC., IF NEEDED  */
    k_err = msg_receive(reply_msg, RCV_TIMEOUT, (int)(timeout * 1000));
    if (k_err == RCV_TIMED_OUT) 
	return(ST_ERROR);

    /*  THE DSP SIGNALLED THAT ITS BUFFERS ARE FLUSHED, SO RETURN  */
    return(ST_NO_ERROR);
}



/******************************************************************************
*
*	function:	set_frequency
*
*	purpose:	Sets the frequency of the tone being generated
*                       by the DSP.
*			
*       arguments:      frequency - the frequency in Hz.
*                       
*	internal
*	functions:	none
*
*	library
*	functions:	DSPIntToFix24, DSPFloatToFix24,
*                       snddriver_dspcmd_req_condition, snddriver_dsp_host_cmd,
*                       snddriver_dsp_write
*
******************************************************************************/

int set_frequency(float frequency)
{
    DSPFix24 datatable[2];
    float inc;


    /*  CONVERT FREQUENCY VALUE INTO A TABLE INCREMENT  */
    inc = WAVETABLE_SIZE * frequency / (OUTPUT_SRATE * OVERSAMPLE);
    datatable[0] = DSPIntToFix24((int)inc);
    datatable[1] = DSPFloatToFix24(inc - (float)((int)inc));
    
    /*  DON'T SEND HC DURING OUTPUT (I.E. WHILE DSP SETS HF2 TO 1)  */
    k_err =  snddriver_dspcmd_req_condition(cmd_port, SNDDRIVER_ISR_HF2, 0,
					    SNDDRIVER_LOW_PRIORITY, PORT_NULL);
    if (k_err != KERN_SUCCESS)
	return(ST_ERROR);

    /*  ISSUE THE HOST COMMAND, AND TRANSFER THE DATA  */
    k_err = snddriver_dsp_host_cmd(cmd_port, HC_SET_FREQUENCY,
				   SNDDRIVER_LOW_PRIORITY);
    if (k_err != KERN_SUCCESS)
	return(ST_ERROR);
    else {
	k_err = 
	    snddriver_dsp_write(cmd_port, datatable, 2, sizeof(DSPFix24),
				SNDDRIVER_LOW_PRIORITY);
	if (k_err != KERN_SUCCESS)
	    return(ST_ERROR);
    }

    return(ST_NO_ERROR);
}



/******************************************************************************
*
*	function:	set_amplitude
*
*	purpose:	Sets the amplitude of the tone being generated
*                       on the DSP.
*			
*       arguments:      amplitude - amplitude value (0.0 - 1.0)
*                       
*	internal
*	functions:	none
*
*	library
*	functions:	DSPFloatToFix24, snddriver_dspcmd_req_condition
*                       snddriver_dsp_host_cmd, snddriver_dsp_write
*
******************************************************************************/

int set_amplitude(float amplitude)
{
    DSPFix24 datatable[1];


    /*  CONVERT AMPLITUDE VALUE INTO FIXED POINT  */
    datatable[0] = DSPFloatToFix24(amplitude);

    /*  DON'T SEND HC DURING OUTPUT (I.E. WHILE DSP SETS HF2 TO 1)  */
    k_err =  snddriver_dspcmd_req_condition(cmd_port, SNDDRIVER_ISR_HF2, 0,
					    SNDDRIVER_LOW_PRIORITY, PORT_NULL);
    if (k_err != KERN_SUCCESS)
	return(ST_ERROR);

    /*  ISSUE THE HOST COMMAND, AND TRANSFER THE DATA  */
    k_err = snddriver_dsp_host_cmd(cmd_port, HC_SET_AMPLITUDE,
				   SNDDRIVER_LOW_PRIORITY);
    if (k_err != KERN_SUCCESS)
	return(ST_ERROR);
    else {
	k_err = 
	    snddriver_dsp_write(cmd_port, datatable, 1, sizeof(DSPFix24),
				SNDDRIVER_LOW_PRIORITY);
	if (k_err != KERN_SUCCESS)
	    return(ST_ERROR);
    }

    return(ST_NO_ERROR);
}



/******************************************************************************
*
*	function:	set_balance
*
*	purpose:	Sets the balance of the tone being generated
*                       on the DSP.
*			
*       arguments:      balance - balance value (-1.0 to +1.0)
*                       
*	internal
*	functions:	none
*
*	library
*	functions:	DSPFloatToFix24, snddriver_dsp_host_cmd,
*                       snddriver_dspcmd_req_condition, snddriver_dsp_write
*
******************************************************************************/

int set_balance(float balance)
{
    DSPFix24 datatable[1];


    /*  CONVERT BALANCE VALUE INTO FIXED POINT  */
    datatable[0] = DSPFloatToFix24(balance);
    
    /*  DON'T SEND HC DURING OUTPUT (I.E. WHILE DSP SETS HF2 TO 1)  */
    k_err =  snddriver_dspcmd_req_condition(cmd_port, SNDDRIVER_ISR_HF2, 0,
					    SNDDRIVER_LOW_PRIORITY, PORT_NULL);
    if (k_err != KERN_SUCCESS)
	return(ST_ERROR);

    /*  ISSUE THE HOST COMMAND, AND TRANSFER THE DATA  */
    k_err = snddriver_dsp_host_cmd(cmd_port, HC_SET_BALANCE,
				   SNDDRIVER_LOW_PRIORITY);
    if (k_err != KERN_SUCCESS)
	return(ST_ERROR);
    else {
	k_err = 
	    snddriver_dsp_write(cmd_port, datatable, 1, sizeof(DSPFix24),
				SNDDRIVER_LOW_PRIORITY);
	if (k_err != KERN_SUCCESS)
	    return(ST_ERROR);
    }

    return(ST_NO_ERROR);
}



/******************************************************************************
*
*	function:	set_wavetable
*
*	purpose:	Sets the number of harmonics of the waveform used
*                       to synthesize the tone on the DSP.
*			
*       arguments:      numberHarmonics - the number of harmonics used in
*                       the quasi-sawtooth waveform.
*	internal
*	functions:	none
*
*	library
*	functions:	DSPFloatToFix24, snddriver_dspcmd_req_condition,
*                       snddriver_dsp_host_cmd, snddriver_dsp_write
*
******************************************************************************/

int set_wavetable(int numberHarmonics)
{
    DSPFix24 datatable[1];


    /*  CONVERT NUMBER OF HARMONICS VALUE INTO FIXED POINT  */
    datatable[0] = DSPIntToFix24(numberHarmonics);
    
    /*  DON'T SEND HC DURING OUTPUT (I.E. WHILE DSP SETS HF2 TO 1)  */
    k_err =  snddriver_dspcmd_req_condition(cmd_port, SNDDRIVER_ISR_HF2, 0,
					    SNDDRIVER_LOW_PRIORITY, PORT_NULL);
    if (k_err != KERN_SUCCESS)
	return(ST_ERROR);

    /*  ISSUE THE HOST COMMAND, AND TRANSFER THE DATA  */
    k_err = snddriver_dsp_host_cmd(cmd_port, HC_SET_WAVETABLE,
				   SNDDRIVER_LOW_PRIORITY);
    if (k_err != KERN_SUCCESS)
	return(ST_ERROR);
    else {
	k_err = 
	    snddriver_dsp_write(cmd_port, datatable, 1, sizeof(DSPFix24),
				SNDDRIVER_LOW_PRIORITY);
	if (k_err != KERN_SUCCESS)
	    return(ST_ERROR);
    }

    return(ST_NO_ERROR);
}



/******************************************************************************
*
*	function:	set_ramptime
*
*	purpose:	Sets the ramptime (rate) for the asymptotic envelope
*                       generator.
*			
*       arguments:      ramptime - ramp time in secons.
*                       
*	internal
*	functions:	rate
*
*	library
*	functions:	DSPFloatToFix24, snddriver_dspcmd_req_condition,
*                       snddriver_dsp_host_cmd, snddriver_dsp_write
*
******************************************************************************/

int set_ramptime(float ramptime)
{
    DSPFix24 datatable[1];

    /*  STORE TIMEOUT VALUE  */
    timeout = ramptime;

    /*  CONVERT RAMPTIME INTO FIXED POINT RATE VALUE  */
    datatable[0] = DSPFloatToFix24(rate(ramptime, OUTPUT_SRATE, DB_DECAY));
    
    /*  DON'T SEND HC DURING OUTPUT (I.E. WHILE DSP SETS HF2 TO 1)  */
    k_err =  snddriver_dspcmd_req_condition(cmd_port, SNDDRIVER_ISR_HF2, 0,
					    SNDDRIVER_LOW_PRIORITY, PORT_NULL);
    if (k_err != KERN_SUCCESS)
	return(ST_ERROR);

    /*  ISSUE THE HOST COMMAND, AND TRANSFER THE DATA  */
    k_err = snddriver_dsp_host_cmd(cmd_port, HC_SET_RATE,
				   SNDDRIVER_LOW_PRIORITY);
    if (k_err != KERN_SUCCESS)
	return(ST_ERROR);
    else {
	k_err =  snddriver_dsp_write(cmd_port, datatable, 1, sizeof(DSPFix24),
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
*	functions:	snddriver_dsp_host_cmd,, snddriver_dsp_host_cmd,
*                       DSPIntToFix24, snddriver_dsp_write
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
