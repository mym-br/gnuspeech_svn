/*  REVISION INFORMATION  *****************************************************

$Author: len $
$Date: 1994/06/16 16:40:16 $
$Revision: 1.1.1.1 $
$Source: /cvsroot/ToneGenerator/oversampling_filter.h,v $
$State: Exp $


$Log: oversampling_filter.h,v $
 * Revision 1.1.1.1  1994/06/16  16:40:16  len
 * Initial archive of ToneGenerator application.
 *

******************************************************************************/

/*  HEADER FILES  ************************************************************/
#import <dsp/dsp.h>                      /*  for function prototypes, below  */


/*  GLOBAL DEFINES  **********************************************************/

/*  OVERSAMPLING FIR FILTER CHARACTERISTICS  */
#define FIR_BETA             .2
#define FIR_GAMMA            .1
#define FIR_CUTOFF           .00000011921              /*  equal to 2^(-23)  */



/*  GLOBAL FUNCTIONS *********************************************************/
extern DSPFix24 *initializeFIR(double beta, double gamma, double cutoff,
			       int *numberTaps, DSPFix24 *FIRCoef);
