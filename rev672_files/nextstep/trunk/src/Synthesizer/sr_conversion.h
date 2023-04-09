/*  REVISION INFORMATION  *****************************************************

$Author: fedor $
$Date: 2003-01-18 05:04:51 $
$Revision: 1.2 $
$Source: /Users/dalmazio/cvsroot/gnuspeech/trillium/src/Synthesizer/sr_conversion.h,v $
$State: Exp $


$Log: not supported by cvs2svn $
Revision 1.1  2002/03/21 16:49:54  rao
Initial import.

 * Revision 1.1.1.1  1994/05/20  00:22:02  len
 * Initial archive of TRM interactive Synthesizer.
 *

******************************************************************************/

/*  HEADER FILES  ************************************************************/
#ifdef HAVE_DSP_
#include <dsp/dsp.h>                      /*  for function prototypes, below  */
#endif


/*  GLOBAL FUNCTIONS *********************************************************/
#ifdef HAVE_DSP_
extern void initialize_sr_conversion(int zero_crossings, int l_bits, float beta,
				     float lp_cutoff, DSPFix24 *h[],
				     DSPFix24 *hDelta[], int *filterLength);
#endif
extern double Izero(double x);
