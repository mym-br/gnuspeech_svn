/*******************************************************************************
 *
 *  Copyright 1991-2009 David R. Hill, Leonard Manzara, Craig Schock
 *
 *  Contributors: David Hill
 *
 *  This program is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation, either version 3 of the License, or
 *  (at your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 *******************************************************************************
 *
 *  tube.h
 *  Synthesizer
 *
 *  Created by David Hill on 3/29/06.
 *
 *  Version: 0.7.3
 *
 ******************************************************************************/

#ifndef TUBE_H_
#define TUBE_H_



#define TOTAL_REGIONS 8
#define TOTAL_SECTIONS            10
#define TEMPERATURE_DEF		32.0
#define TABLE_LENGTH              512
#define GLOT_PITCH_DEF 0.0
#define GLOT_VOL_DEF 60
#define CIRC_BUFF_SIZE			2048



//static void *currentPointer;

int tube_initializeSynthesizer();
void tube_stopSynthesizer();
void tube_getCircBuff(float *bufferCopy);

double amplitude(double decibelLevel);
double frequency(double pitch);
// FUNCTION TO RETURN MODIFIED BESSEL FUNCTION OF THE FIRST KIND, ORDER 0
double Izero2(double x);

/* FUNCTIONS TO ALLOW OBJECTIVE-C TO ACCESS THE SYNTHESIS VARIABLES */
void tube_setGlotPitch(float value);
void tube_setGlotVol(float value);
void tube_setAspVol(float value);
void tube_setFricVol(float value);
void tube_setFricPos(float value);
void tube_setFricCF(float value);
void tube_setFricBW(float value);
void tube_setRadius(float value, int index);
void tube_setVelumRadius(float value);
void tube_setWaveformType(int value);
void tube_setTp(float value);
void tube_setTnMin(float value);
void tube_setTnMax(float value);
void tube_setBreathiness(float value);
void tube_setLength(float value);
void tube_setTemperature(float value);
void tube_setLossFactor(float value);
void tube_setApScale(float value);
void tube_setMouthCoef(float value);
void tube_setNoseCoef(float value);
void tube_setNoseRadius(float value, int index);
void tube_setThroatCutoff(float value);
void tube_setThroatVol(float value);
void tube_setModulation(int value);
void tube_setMixOffset(float value);
void tube_setActualTubeLength(float value);
void tube_setControlPeriod(int value);
void tube_setSampleRate(int value);

/* FUNCTIONS TO ALLOW INTERFACE OBJECTIVE-C ACCESS TO DEFAULT TUBE PARAMETERS */
float tube_getGlotPitchDefault();
float tube_getGlotVolDefault();
float tube_getAspVolDefault();
float tube_getFricVolDefault();
float tube_getFricPosDefault();
float tube_getFricCFDefault();
float tube_getFricBWDefault();
float tube_getRadiusDefault(int index);
float tube_getVelumRadiusDefault();
int tube_getWaveformTypeDefault();
float tube_getTpDefault();
float tube_getTnMinDefault();
float tube_getTnMaxDefault();
float tube_getBreathinessDefault();
float tube_getLengthDefault();
float tube_getTemperatureDefault();
float tube_getLossFactorDefault();
float tube_getApScaleDefault();
float tube_getMouthCoefDefault();
float tube_getNoseCoefDefault();
float tube_getNoseRadiusDefault(int index);
float tube_getThroatCutoffDefault();
float tube_getThroatVolDefault();
int tube_getModulationDefault();
float tube_getMixOffsetDefault();

/* FUNCTIONS TO ALLOW INTERFACE OBJECTIVE-C ACCESS TO TUBE PARAMETERS */
float tube_getGlotPitch();
float tube_getGlotVol();
float tube_getAspVol();
float tube_getFricVol();
float tube_getFricPos();
float tube_getFricCF();
float tube_getFricBW();
float tube_getRadius(int index);
float tube_getVelumRadius();
int tube_getWaveformType();
float tube_getTp();
float tube_getTnMin();
float tube_getTnMax();
float tube_getBreathiness();
float tube_getLength();
float tube_getTemperature();
float tube_getLossFactor();
float tube_getApScale();
float tube_getMouthCoef();
float tube_getNoseCoef();
float tube_getNoseRadius(int index);
float tube_getThroatCutoff();
float tube_getThroatVol();
int tube_getModulation();
float tube_getMixOffset();
float tube_getActualTubeLength();
int tube_getControlPeriod();
float tube_getControlRate();
int tube_getSampleRate();
float tube_getWavetable(int index);

#endif /*TUBE_H_*/
