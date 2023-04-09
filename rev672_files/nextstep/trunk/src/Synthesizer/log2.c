/*  REVISION INFORMATION  *****************************************************

$Author: fedor $
$Date: 2003-01-18 05:04:51 $
$Revision: 1.2 $
$Source: /Users/dalmazio/cvsroot/gnuspeech/trillium/src/Synthesizer/log2.c,v $
$State: Exp $


$Log: not supported by cvs2svn $
Revision 1.1  2002/03/21 16:49:54  rao
Initial import.

 * Revision 1.1.1.1  1994/05/20  00:21:47  len
 * Initial archive of TRM interactive Synthesizer.
 *

******************************************************************************/

#include <math.h>

double log2(double value)
{
  return (log10(value) / log10(2.0));
}
