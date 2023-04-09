/*
 *    Filename : oversampling_filter.h 
 *    Created  : Mon Jul 25 00:06:44 1994 
 *    Author   : Len Manzara
 *
 *    Last modified on "Mon Jul 25 00:06:54 1994"
 *
 * $Id: oversampling_filter.h,v 1.1 1994/07/25 06:22:26 dale Exp $
 *
 * $Log: oversampling_filter.h,v $
 * Revision 1.1  1994/07/25  06:22:26  dale
 * Initial revision
 *
 * Revision 1.1  1994/07/25  06:08:50  dale
 * Initial revision
 *
 */


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
