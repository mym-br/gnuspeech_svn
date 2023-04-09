/*
 *    Filename : dsp_control.h 
 *    Created  : Mon Jul 25 00:07:21 1994 
 *    Author   : Len Manzara
 *
 *    Last modified on "Mon Jul 25 00:07:31 1994"
 *
 * $Id: dsp_control.h,v 1.1 1994/07/25 06:22:00 dale Exp $
 *
 * $Log: dsp_control.h,v $
 * Revision 1.1  1994/07/25  06:22:00  dale
 * Initial revision
 *
 */


/*  GLOBAL FUNCTIONS *********************************************************/
extern void initialize_synthesizer(void);
extern void free_synthesizer(void);
extern int grab_and_initialize_DSP(void);
extern int relinquish_DSP(void);
extern int start_synthesizer(void);
extern int stop_synthesizer(void);
extern int set_frequency(float frequency);
extern int set_amplitude(float amplitude);
extern int set_balance(float balance);
extern int set_wavetable(int numberHarmonics);
extern int set_ramptime(float ramptime);



/*  GLOBAL DEFINES  **********************************************************/
/*  ERROR RETURN VALUES  */
#define ST_NO_ERROR        0
#define ST_ERROR           1

/*  DSP CORE FILE  */
#define DSPCORE            "dspcore.h"

/*  DMA TRANSFER VARIABLES  (THESE MUST ALL MATCH WITH THE DSP)  */
#define DMA_OUT_SIZE       2048       /*  DMA-OUT BUFFER SIZE (2 BYTE WORDS) */
#define LOW_WATER          (48*1024)
#define HIGH_WATER         (512*1024)

/*  OSCILLATOR WAVETABLE SIZE  */
#define WAVETABLE_SIZE     256         /*  MUST MATCH DSP  */

/*  HOST COMMANDS  */
#define HC_START           (0x2E>>1)   /*  MUST MATCH DSP  */
#define HC_STOP            (0x30>>1)   /*  MUST MATCH DSP  */
#define HC_SET_FREQUENCY   (0x32>>1)   /*  MUST MATCH DSP  */
#define HC_SET_AMPLITUDE   (0x34>>1)   /*  MUST MATCH DSP  */
#define HC_SET_BALANCE     (0x36>>1)   /*  MUST MATCH DSP  */
#define HC_SET_WAVETABLE   (0x38>>1)   /*  MUST MATCH DSP  */
#define HC_SET_RATE        (0x3A>>1)   /*  MUST MATCH DSP  */
#define HC_LOAD_FIR_COEF   (0x3C>>1)   /*  MUST MATCH DSP  */

/*  MISC. CONSTANTS  */
#define OUTPUT_SRATE       44100.0     /*  ACTUAL OUTPUT D/A RATE USED  */
#define MAX_SIZE           0.9999998   /*  LARGEST POSITIVE NUMBER IN DSP  */

#define OVERSAMPLE         2.0         /*  WE USE 2X OVERSAMPLING OSC.  */
#define DB_DECAY           60.0        /*  DECAY CURVE USED FOR ASYM. EG  */
#define TIMEOUT_DEF        5.0         /*  DEFAULT TIMEOUT IN SECONDS  */
