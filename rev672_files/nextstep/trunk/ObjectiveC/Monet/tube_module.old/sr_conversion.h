/*  REVISION INFORMATION  *****************************************************

$Author: rao $
$Date: 2002-03-21 16:49:48 $
$Revision: 1.1 $
$Source: /Users/dalmazio/cvsroot/gnuspeech/trillium/ObjectiveC/Monet/tube_module.old/sr_conversion.h,v $
$State: Exp $


$Log: not supported by cvs2svn $
 * Revision 1.1.1.1  1994/09/06  21:45:50  len
 * Initial archive into CVS.
 *

******************************************************************************/



/*  HEADER FILES  ************************************************************/
#import <dsp/dsp.h>                      /*  for function prototypes, below  */


/*  GLOBAL FUNCTIONS *********************************************************/
extern void initialize_sr_conversion(int zero_crossings, int l_bits,
				     float beta, float lp_cutoff,
				     DSPFix24 *h[], DSPFix24 *hDelta[],
				     int *filterLength);
extern double Izero(double x);


/*  GLOBAL DEFINES  **********************************************************/

/*  SAMPLE RATE CONVERSION CONSTANTS  */
#define L_BITS               6                      /*  MUST AGREE WITH DSP  */
#define M_BITS               24                     /*  MUST AGREE WITH DSP  */
#define FRACTION_BITS        (L_BITS + M_BITS)
#define ZERO_CROSSINGS       13                     /*  MUST AGREE WITH DSP  */
#define BETA                 5.658              /*  KAISER WINDOW PARAMETER  */
#define LP_CUTOFF            (11.0/13.0)        /*  SRC CUTOFF FRQ (0.846
						    OF NYQUIST)  */
