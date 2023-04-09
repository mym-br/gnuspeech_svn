/*  REVISION INFORMATION  *****************************************************

$Author: rao $
$Date: 2002-03-21 16:49:46 $
$Revision: 1.1 $
$Source: /Users/dalmazio/cvsroot/gnuspeech/trillium/ObjectiveC/DEGAS/synthesizer_module.h,v $
$State: Exp $


$Log: not supported by cvs2svn $
 * Revision 1.6  1993/12/14  20:29:07  len
 * Changed the PREFILL_SIZE to 6 from 4.  Seems to help most sound out
 * interruptions.
 *
 * Revision 1.5  1993/12/14  20:16:46  len
 * Rewrote the module so that it is single-threaded.
 *
 * Revision 1.4  1993/11/30  22:30:39  len
 * Fixed a bug in DSP code.  Created the scaled_volume()
 * function, which checks volume ranges before scaling
 * them to a fractional number.
 *
 * Revision 1.3  1993/11/29  18:43:23  len
 * Moved calculatation of amplitudes and resonator coefficients to the
 * DSP from the host.
 *
 * Revision 1.2  1993/11/26  04:59:24  len
 * Added the ability to send sound directly to file.
 *
 * Revision 1.1.1.1  1993/11/25  23:00:47  len
 * Initial archive of production code for the 1.0 TTS_Server (tag v5).
 *

******************************************************************************/

/*  INCLUDE FILES (NECESSARY FOR PROTOTYPES)  ********************************/
#import <dsp/dsp.h>


/*  FUNCTION PROTOTYPES  *****************************************************/

/*  THESE FUNCTIONS CONTROL THE SYNTHESIS MODULE  */
extern int initialize_synthesizer_module(void);
extern void set_synthesizer_output(char *path, int uid, int gid,
				   int number_chunks);
extern int start_synthesizer(void);
extern void await_request_new_page(int blocking_request, int last_page, 
				   void (*ptr_update_function)());


/*  THESE FUNCTIONS HELP TO CREATE SYNTHESIZER CONTROL TABLES  */
extern DSPFix24 *new_pad_table(int data_table_size);
extern DSPFix24 *new_default_data_table(int data_table_size);
extern void set_bypass(int value, int pos, int *bypass_register);
extern int bypass_value(int pos, int *bypass_register);
extern void set_resonator_coefficients(float frequency, float bandwidth,
				       float *a, float *b, float *c);
extern void set_notch_filter_coefficients(float frequency, float bandwidth,
					  float *a, float *b, 
					  float *c, float *d);
extern float amplitude(float decibel_level);
extern float scaled_volume(float decibel_level);
extern float convert_to_pitch(float frequency);
extern float convert_to_frequency(float pitch);



/*  GLOBAL VARIABLES  ********************************************************/
/*  GLOBAL VARIABLE USED BY SYNTHESIZER THREAD TO READ A PAGE OF
    SYNTHESIZER CONTROL TABLES  */
extern vm_address_t synth_read_ptr;

/*  VARIABLE TO SIGNAL TO OTHER THREAD WHEN SYNTHESIZER ACTIVE  */
extern int synth_status;

/*  THE FOLLOWING IS CALCULATED WITH initialize_synthesizer_module(),
    AND THUS THIS FUNCTION MUST BE INVOKED BEFORE USING THIS VARIABLE  */
extern float scale_rc;



/*  GLOBAL DEFINITIONS  *****************************************************/
/*  SYNTH THREAD DEFS USED FOR SIGNALLING BETWEEN MODULES  */
#define ST_PAUSE             0
#define ST_RUN               1

#define ST_NO                0
#define ST_YES               1

#define ST_NO_ERROR          0
#define ST_ERROR             1

#define ST_OUT_DSP           0
#define ST_OUT_FILE          1

#define ST_NO_PAGE_REQUEST   0
#define ST_PAGE_REQUEST      1


/*  SOUND CHARACTERISTICS  */
#define TP                   0.40        /*  GLOTTAL PULSE RISE TIME PROPORTION  */
#define TN                   0.16        /*  GLOTTAL PULSE FALL TIME PROPORTION  */
#define INTER_CHUNK_SILENCE  7           /*  # PAGES BETWEEN CHUNKS (FILE ONLY)  */

/*  PITCH VARIABLES  */
#define PITCH_BASE           220.0
#define PITCH_OFFSET         3           /*  MIDDLE C = 0  */
#define LOG_FACTOR           3.32193

/*  DMA TRANSFER VARIABLES  (THESE MUST ALL MATCH WITH THE DSP)  */
#define DMA_IN_SIZE          2048        /*  DMA-IN BUFFER SIZE (4 BYTE WORDS)  */
#define DMA_OUT_SIZE         1024        /*  DMA-OUT BUFFER SIZE (2 BYTE WORDS) */
#define LOW_WATER            (48*1024)
#define HIGH_WATER           (512*1024)
#define WAVE_TABLE_SIZE      256         /*  MAXIMUM IS 512  */
#define DATA_TABLE_SIZE      32          /*  SIZE OF SYNTHESIZER CONTROL TABLE  */
#define JUNK_SKIP            7           /*  UNUSED PART OF TABLE (32 - 25 = 7)  */
#define TABLES_PER_PAGE      64          /*  (TABLES_PER_DMA in DSP)  */
#define PREFILL_SIZE         6           /*  # PAGES BEFORE SOUND OUT STARTS  */

/*  HOST COMMANDS  */
#define HC_LOAD_WAVEFORM     (0x30>>1)   /*  MUST MATCH DSP  */
#define HC_START             (0x32>>1)   /*  MUST MATCH DSP  */
#define HC_LOAD_FNR          (0x36>>1)   /*  MUST MATCH DSP  */

/*  SCALING GLOBALS  */
#define MAX_TABLE_VALUE      0.9999998   /*  MAX. FLOATING POINT VALUE OF DSPFix24  */
#define VOL_MAX              60          /*  RANGE OF ALL VOLUME CONTROLS  */
#define ASP_SCALE            -35         /*  SCALING OF ASP. NOISE IN dB  */
#define FRIC_SCALE           -54         /*  SCALING OF FRIC. NOISE IN dB  */
#define PRECASC_SCALE        -38         /*  PRECASCADE SCALING IN dB  */
#define OSC_PER_SCALE        .75         /*  % OF PRECASCADE SCALING ATTRIBUTED
                                             TO OSC.  R.C. GETS (1.0 - value)  */
#define AMPLITUDE_SCALE      64.0        /*  DIVISOR FOR AMPLITUDE SCALING  */


/*  MATH GLOBALS  */
#define PI                       3.14159265358979
#define TWO_PI                   (2.0 * PI)
#define SAMPLE_RATE              22050.0
#define NYQUIST_RATE             (SAMPLE_RATE/2.0)
#define PIT                      (PI / SAMPLE_RATE)
#define TWOPIT                   (2.0 * PIT)
#define PI_DIV_SR                (PI / SAMPLE_RATE)
#define TWO_PI_DIV_SR            (TWO_PI / SAMPLE_RATE)


/*  BYPASS REGISTER BIT FLAGS (MUST MATCH DSP)  */
#define RC_BYPASS                0
#define FNR_BYPASS               1
#define NNF_BYPASS               2
#define F1_BYPASS                3
#define F2_BYPASS                4
#define F3_BYPASS                5
#define F4_BYPASS                6
#define AM_BYPASS                7
#define FR_BYPASS                8


/*  DEFAULT DATA TABLE VALUES  */
#define OSC_FREQ_DEF         110.0
#define OSC_VOL_DEF          60.0
#define MASTER_VOL_DEF       60.0
#define ASP_VOL_DEF          0.0
#define FRIC_VOL_DEF         0.0
#define BYPASS_REG_DEF       0
#define BALANCE_DEF          0.0
#define NASAL_BYPASS_DEF     1.0
#define R1_FREQ_DEF          640.0
#define R1_BW_DEF            50.0
#define R2_FREQ_DEF          1230.0
#define R2_BW_DEF            90.0
#define R3_FREQ_DEF          2550.0
#define R3_BW_DEF            200.0
#define R4_FREQ_DEF          3300.0
#define R4_BW_DEF            250.0
#define FR_FREQ_DEF          3300.0
#define FR_BW_DEF            250.0
#define NNF_FREQ_DEF         455.0
#define NNF_BW_DEF           100.0
#define FNR_FREQ_DEF         270.0
#define FNR_BW_DEF           100.0
