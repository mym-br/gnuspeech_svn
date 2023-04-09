/*  REVISION INFORMATION  *****************************************************

$Author: fedor $
$Date: 2003-01-18 05:04:51 $
$Revision: 1.2 $
$Source: /Users/dalmazio/cvsroot/gnuspeech/trillium/src/Synthesizer/dsp_control.h,v $
$State: Exp $


$Log: not supported by cvs2svn $
Revision 1.1  2002/03/21 16:49:54  rao
Initial import.

 * Revision 1.2  1994/09/13  21:42:41  len
 * Folded in optimizations made in synthesizer.asm.
 *
 * Revision 1.1.1.1  1994/05/20  00:21:52  len
 * Initial archive of TRM interactive Synthesizer.
 *

******************************************************************************/

#ifdef HAVE_DSP
#import <dsp/dsp.h>               /*  needed for function prototypes, below  */
#endif


/*  GLOBAL FUNCTIONS *********************************************************/
extern void initialize_synthesizer(void);
extern void free_synthesizer(void);
extern int grab_and_initialize_DSP(int analysis_enabled);
extern int relinquish_DSP(void);
extern int start_synthesizer(void);
extern int stop_synthesizer(void);
#ifdef HAVE_DSP
extern int write_datatable(DSPFix24 *datatable, int size);
#endif
extern int write_bandlimited_gp(float riseTime, float fallTime,
				int topHarmonic, float rolloff);
extern short int *stereoSoundBuffer(void);


/*  LOCAL DEFINES  ***********************************************************/

/*  COMPILATION FLAGS  */
#define OVERSAMPLE_OSC       1     /*  SET TO 1 FOR 2X OVERSAMPLING OSC   */
#define VARIABLE_GP          1     /*  SET TO 1 FOR VARIABLE GP  */
#define FIXED_CROSSMIX       0     /*  SET TO 1 FOR FIXED CROSSMIX (60 dB)  */
#define SYNC_DMA             1     /*  SET TO 1 FOR SYNCH. DMA OUPUT  */


/*  ERROR RETURN VALUES  */
#define ST_NO_ERROR          0
#define ST_ERROR             1

/*  DSP CORE FILE  */
#define DSPCORE "dspcore.h"

/*  DMA TRANSFER VARIABLES  (THESE MUST ALL MATCH WITH THE DSP)  */
#if SYNC_DMA
#define DMA_OUT_SIZE         1024     /*  DMA-OUT BUFFER SIZE (2 BYTE WORDS) */
#else
#define DMA_OUT_SIZE         512      /*  DMA-OUT BUFFER SIZE (2 BYTE WORDS) */
#endif

#define LOW_WATER            (48*1024)
#define HIGH_WATER           (512*1024)

/*  OSCILLATOR WAVETABLE SIZES  */
#define SINE_TABLE_SIZE      256         /*  MUST MATCH DSP  */
#define GP_TABLE_SIZE        256         /*  MUST MATCH DSP  */

#if !VARIABLE_GP
#define ROLLOFF_FACTOR       0.5
#endif

#if OVERSAMPLE_OSC
#define OVERSAMPLE           2.0         /*  WE USE 2X OVERSAMPLING OSCILLATOR  */
#else
#define OVERSAMPLE           1.0         /*  NO OVERSAMPLING  */
#endif


/*  HOST COMMANDS  */
#define HC_LOAD_DATATABLE  (0x30>>1)   /*  MUST MATCH DSP  */
#define HC_START           (0x32>>1)   /*  MUST MATCH DSP  */
#define HC_STOP            (0x34>>1)   /*  MUST MATCH DSP  */
#define HC_LOAD_FIR_COEF   (0x36>>1)   /*  MUST MATCH DSP  */
#define HC_LOAD_SR_COEF    (0x38>>1)   /*  MUST MATCH DSP  */
#define HC_LOAD_WAVETABLE  (0x3A>>1)   /*  MUST MATCH DSP  */

/*  MISC. CONSTANTS  */
#define OUTPUT_SRATE       22050.0          /*  ACTUAL OUTPUT D/A RATE USED  */
#define MAX_SIZE           0.9999998        /*  LARGEST + NUMBER IN DSP  */
#define MAX_SAMPLE_SIZE    32768.0          /*  LARGEST SIGNED SHORT INT  */

/*  SAMPLE RATE CONVERSION CONSTANTS  */
#define L_BITS             6                /*  MUST AGREE WITH DSP  */
#define M_BITS             24               /*  MUST AGREE WITH DSP  */
#define FRACTION_BITS      (L_BITS + M_BITS)
#define ZERO_CROSSINGS     13               /*  MUST AGREE WITH DSP  */
#define BETA               5.658            /*  KAISER WINDOW PARAMETER  */
#define LP_CUTOFF          (11.0/13.0)      /*  SRC CUTOFF FRQ (0.846 OF NYQUIST)  */
