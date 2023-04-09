/*  REVISION INFORMATION  *****************************************************

$Author: len $
$Date: 1994/06/16 16:40:12 $
$Revision: 1.1.1.1 $
$Source: /cvsroot/ToneGenerator/conversion.h,v $
$State: Exp $


$Log: conversion.h,v $
 * Revision 1.1.1.1  1994/06/16  16:40:12  len
 * Initial archive of ToneGenerator application.
 *

******************************************************************************/


/*  GLOBAL FUNCTIONS *********************************************************/
extern float frequencyOf(float pitch);
extern float pitchOf(float frequency);
extern float amplitudeOf(float decibelLevel);
extern float volumeOf(float amplitude);
extern float rate(float rampTime, int sampleRate, float dbDecay);
