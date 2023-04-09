/*  REVISION INFORMATION  *****************************************************

$Author: rao $
$Date: 2002-03-21 16:49:54 $
$Revision: 1.1 $
$Source: /Users/dalmazio/cvsroot/gnuspeech/trillium/src/SpeechObject/preMonet/server/synthesizer_module/current_values_to_table.c,v $
$State: Exp $


$Log: not supported by cvs2svn $
 * Revision 1.4  1993/11/30  22:30:33  len
 * Fixed a bug in DSP code.  Created the scaled_volume()
 * function, which checks volume ranges before scaling
 * them to a fractional number.
 *
 * Revision 1.3  1993/11/29  18:43:16  len
 * Moved calculatation of amplitudes and resonator coefficients to the
 * DSP from the host.
 *
 * Revision 1.2  1993/11/26  05:16:13  len
 * Added RCS header to current_values_to_table.[ch].
 *

******************************************************************************/

/*  HEADER FILES  ************************************************************/
#import "current_values_to_table.h"
#import "synthesizer_module.h"
#import "structs.h"
#import <dsp/dsp.h>
#import <TextToSpeech/TTS_types.h>


/*  EXTERNAL GLOBAL VARIABLES  ***********************************************/
/*  These should really be #import'ed from a header file.  */
extern float current_values[14];        /* Current values to be put into table */
extern DSPFix24 *cur_index_in;          /* Pointer into Table buffer */
extern int cur_page_in, cur_page_out;   /* Producer/consumer variables */
extern struct _calc_info calc_info;




/******************************************************************************
*
*	function:	current_values_to_table
*
*	purpose:	(added by Craig)
*                       
*			
*       arguments:      none
*                       
*	internal
*	functions:	convert_to_frequency, amplitude,
*                       set_resonator_coefficients,
*                       set_notch_filter_coefficients
*
*	library
*	functions:	DSPIntToFix24, DSPFloatToFix24, sin
*
******************************************************************************/

void current_values_to_table(void)
{
  float temp, table_inc, rc_scale, a, b, c, d;
  

  /*  FX parameters Micro & Macro intonation and Minimalization. */
  temp = -15.0 + calc_info.pitch_offset;

  if (calc_info.intonation & TTS_INTONATION_MICRO)
    temp += current_values[11];
  
  if (calc_info.intonation & TTS_INTONATION_MACRO)
    temp += current_values[13];
  
  if (calc_info.intonation & TTS_INTONATION_DECLIN)
    temp += current_values[12];

#if DEBUG  
  printf("temp = %f  fx:%f  min:%f  mac: %f\n", temp, current_values[11],
	 current_values[12], current_values[13]);
#endif
  
  temp = convert_to_frequency(temp);
  

  /*  CONVERT EACH TABLE TO APPROPRIATE DSP VALUES, WRITE TO VM  */
  /*  CONVERT VOICING OSCILLATOR FREQUENCY TO INCREMENT AND SCALING FACTOR  */
  table_inc = (float)(WAVE_TABLE_SIZE * temp)/SAMPLE_RATE;
  *(cur_index_in++) = DSPIntToFix24((int)table_inc);
  *(cur_index_in++) = DSPFloatToFix24(table_inc - (float)((int)table_inc));
  
  rc_scale = scale_rc / (2.0 * sin(temp * PI_DIV_SR));
  *(cur_index_in++) = DSPIntToFix24((int)rc_scale);
  *(cur_index_in++) = DSPFloatToFix24(rc_scale - (float)((int)rc_scale));
  
  /*  VOICING OSCILLATOR VOLUME  */
  *(cur_index_in++) = DSPFloatToFix24(scaled_volume(current_values[0]));
  
  /*  MASTER VOLUME  */
  *(cur_index_in++) = DSPFloatToFix24(scaled_volume(calc_info.volume));
  
  /*  ASPIRATION VOLUME  */
  *(cur_index_in++) = DSPFloatToFix24(scaled_volume(current_values[5]));
  
  /*  FRICATION VOLUME  */
  *(cur_index_in++) = DSPFloatToFix24(scaled_volume(current_values[6]));
  
  /*  BYPASS REGISTER  */
  *(cur_index_in++) = DSPIntToFix24(0);
  
  /*  STEREO BALANCE  */
  *(cur_index_in++) = DSPFloatToFix24((calc_info.balance * 0.5) + 0.5);
  
  /*  NASAL BYPASS  */
  *(cur_index_in++) = DSPFloatToFix24(current_values[10]);
  
  /*  R1 FREQUENCY AND BANDWIDTH  */
  *(cur_index_in++) = DSPFloatToFix24(current_values[1]/SAMPLE_RATE);
  *(cur_index_in++) = DSPFloatToFix24(R1_BW_DEF/SAMPLE_RATE);
  
  /*  R2 FREQUENCY AND BANDWIDTH  */
  *(cur_index_in++) = DSPFloatToFix24(current_values[2]/SAMPLE_RATE);
  *(cur_index_in++) = DSPFloatToFix24(R2_BW_DEF/SAMPLE_RATE);
  
  /*  R3 FREQUENCY AND BANDWIDTH  */
  *(cur_index_in++) = DSPFloatToFix24(current_values[3]/SAMPLE_RATE);
  *(cur_index_in++) = DSPFloatToFix24(R3_BW_DEF/SAMPLE_RATE);
  
  /*  R4 FREQUENCY AND BANDWIDTH  */
  *(cur_index_in++) = DSPFloatToFix24(current_values[4]/SAMPLE_RATE);
  *(cur_index_in++) = DSPFloatToFix24(R4_BW_DEF/SAMPLE_RATE);
  
  /*  FRICATION RESONATOR FREQUENCY AND BANDWIDTH  */
  *(cur_index_in++) = DSPFloatToFix24(current_values[7]/SAMPLE_RATE);
  *(cur_index_in++) = DSPFloatToFix24(current_values[8]/SAMPLE_RATE);
  
  /*  NASAL NOTCH FILTER FREQUENCY AND BANDWIDTH  */
  set_notch_filter_coefficients(current_values[9],NNF_BW_DEF,&a,&b,&c,&d);
  *(cur_index_in++) = DSPFloatToFix24(a);
  *(cur_index_in++) = DSPFloatToFix24(b);
  *(cur_index_in++) = DSPFloatToFix24(c);
  *(cur_index_in++) = DSPFloatToFix24(d);
  
  /*  SET BALANCE OF TABLE TO ZERO  */
  *(cur_index_in++) = DSPIntToFix24(0);
  *(cur_index_in++) = DSPIntToFix24(0);
  *(cur_index_in++) = DSPIntToFix24(0);
  *(cur_index_in++) = DSPIntToFix24(0);
  *(cur_index_in++) = DSPIntToFix24(0);
  *(cur_index_in++) = DSPIntToFix24(0);
  *(cur_index_in++) = DSPIntToFix24(0);
}
