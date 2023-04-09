
#include <stdlib.h>
#include <math.h>


/* 
	Note: This file is copyright Hartman Technica and has been
	ripped to shreds by Craig-Richard Taube-Schock.  It still
	remains Copyright Hartman Technica and Craig will re-instate
	the propper copyright notices when possible.  This process
	hasn't been a high priority at the moment.

	This file is used and shredded with permission from Harman Technica

*/


/* CALCULATE THE POLYNOMIAL

   used in the numerator and denominator of the expression for 
   the Kaiser_Bessel window coefficients. This is shown as I0(x)
   in the Harris paper. It is defined as an infinite sum, but 
   it can be shown that it converges for all x. We assume here 
   that it has been adequately summed when the next term does not 
   affect a sum at the highest available precision. 

   NOTE that this routine will NEVER be translated to DSP code, but 
   it may be adapted to precalculate coefficients to be installed 
   as a literal table in the DSP.
*/
double KB_poly (double argument)
{
double arg;
long double k, k_factorial, old_poly, new_poly, term;
  
/* Because pow() works by multiplication of logarithms, it deals 
   poorly with powers of zero, which are needed if <argument>
   is zero; so we special case this. 
*/
	if(argument == 0.0)
		return(0.0);

	arg = (double)argument;
	new_poly = 1.0;
	arg /= 2.0;
	k = 1.0;
	k_factorial = 1.0;
  
/* Add terms to the polynomial until they are too small to make 
   any difference.
*/
	do
	{
		term = pow (arg, k) / k_factorial;
		term *= term;
		old_poly = new_poly;
		new_poly += term;
		k += 1.0;
		k_factorial *= k;
	} while (new_poly != old_poly);
	return (new_poly);
}


/* COMPUTE KAISER-BESSEL COEFFICIENTS.

   Since the Kaiser-Bessel window is symmetrical, we compute only half
   the coefficients and apply them symmetrically: this saves both time
   and space. The Kaiser-Bessel window is canonically odd, with a single
   unity coefficient at the centre (represented in the coefficient array
   as KB_coefs[0]), and zeroes at both ends. Other than the zero'th
   coefficient, (which being unity need not be applied at all), all
   coefficients should be applied twice; the Nth coefficient is applied 
   N samples above and N samples below the window centre.

   NOTE that this routine will NEVER be translated to DSP code, but 
   it may be adapted to precalculate coefficients to be installed 
   as a literal table in the DSP.
*/
void init_KB_coefs(unsigned short half_window_size, double KB_alpha, double *KB_coefs)
{
double num, denom, offset;
unsigned short i;

	KB_coefs[0] = 1.0;
	denom = KB_poly(KB_alpha * M_PI);
  
	for (i = 1; i < half_window_size; i++)
	{
		offset = (double) i / (double) half_window_size;
		num = KB_poly(KB_alpha * M_PI *  sqrt(1.0 - (offset * offset)));
		KB_coefs[i] = num / denom;
	}
}

