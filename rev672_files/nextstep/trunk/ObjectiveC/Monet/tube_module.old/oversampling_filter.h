/*  REVISION INFORMATION  *****************************************************

$Author: rao $
$Date: 2002-03-21 16:49:48 $
$Revision: 1.1 $
$Source: /Users/dalmazio/cvsroot/gnuspeech/trillium/ObjectiveC/Monet/tube_module.old/oversampling_filter.h,v $
$State: Exp $


$Log: not supported by cvs2svn $
 * Revision 1.1.1.1  1994/09/06  21:45:53  len
 * Initial archive into CVS.
 *

******************************************************************************/



/*  HEADER FILES  ************************************************************/
#import <dsp/dsp.h>                      /*  for function prototypes, below  */


/*  GLOBAL FUNCTIONS *********************************************************/
extern DSPFix24 *initializeFIR(double beta, double gamma, double cutoff,
			       int *numberTaps, DSPFix24 *FIRCoef);


/*  GLOBAL DEFINES  **********************************************************/

/*  OVERSAMPLING FIR FILTER CHARACTERISTICS  */
#define FIR_BETA             .2
#define FIR_GAMMA            .1
#define FIR_CUTOFF           .00000011921              /*  equal to 2^(-23)  */
