/*  REVISION INFORMATION  *****************************************************

$Author: fedor $
$Date: 2003-01-18 05:04:51 $
$Revision: 1.2 $
$Source: /Users/dalmazio/cvsroot/gnuspeech/trillium/src/Synthesizer/oversampling_filter.h,v $
$State: Exp $


$Log: not supported by cvs2svn $
Revision 1.1  2002/03/21 16:49:54  rao
Initial import.

 * Revision 1.1.1.1  1994/05/20  00:22:01  len
 * Initial archive of TRM interactive Synthesizer.
 *

******************************************************************************/

/*  HEADER FILES  ************************************************************/
#include <dsp/dsp.h>                      /*  for function prototypes, below  */


/*  GLOBAL DEFINES  **********************************************************/

/*  OVERSAMPLING FIR FILTER CHARACTERISTICS  */
#define FIR_BETA             .2
#define FIR_GAMMA            .1
#define FIR_CUTOFF           .00000011921              /*  equal to 2^(-23)  */



/*  GLOBAL FUNCTIONS *********************************************************/
extern DSPFix24 *initializeFIR(double beta, double gamma, double cutoff,
			       int *numberTaps, DSPFix24 *FIRCoef);
