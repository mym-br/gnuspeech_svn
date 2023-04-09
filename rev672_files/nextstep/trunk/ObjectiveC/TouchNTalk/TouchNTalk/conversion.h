/*
 *    Filename : conversion.h 
 *    Created  : Mon Jul 25 00:06:11 1994 
 *    Author   : Len Manzara
 *
 *    Last modified on "Mon Jul 25 00:06:22 1994"
 *
 * $Id: conversion.h,v 1.1 1994/07/25 06:21:34 dale Exp $
 *
 * $Log: conversion.h,v $
 * Revision 1.1  1994/07/25  06:21:34  dale
 * Initial revision
 *
 * Revision 1.1  1994/07/25  06:11:30  dale
 * Initial revision
 *
 */


/*  GLOBAL FUNCTIONS *********************************************************/
extern float frequencyOf(float pitch);
extern float pitchOf(float frequency);
extern float amplitudeOf(float decibelLevel);
extern float volumeOf(float amplitude);
extern float rate(float rampTime, int sampleRate, float dbDecay);
