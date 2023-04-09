////////////////////////////////////////////////////////////////////////////////
//
//  Copyright 1991-2009 David R. Hill, Leonard Manzara, Craig Schock
//  
//  Contributors: David Hill
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program.  If not, see <http://www.gnu.org/licenses/>.
//
////////////////////////////////////////////////////////////////////////////////
//
//  Controller.m
//  Synthesizer
//
//  Created by David Hill in 2006.
//
//  Version: 0.7.3
//
////////////////////////////////////////////////////////////////////////////////

#import "Controller.h"

#import "tube.h"

#ifdef GNUSTEP
# include <jack/ringbuffer.h>
#endif

#import <math.h>

#define TONE_FREQ (440.0)
//#define TONE_FREQ 400.0
#define SUCCESS 0
#define LOSS_FACTOR_MIN	0.0
#define LOSS_FACTOR_MAX	5.0

#import "TubeSection.h"
#import "VelumSlider.h"

#ifdef GNUSTEP
jack_local_data_t jackData;
#endif



#ifdef GNUSTEP
/*******************************************************************************
 * The process callback for this JACK application is called in a
 * special realtime thread once for each audio cycle.
 */
int
jackProcessCallback(jack_nframes_t nframes, void *arg)
{
	jack_local_data_t *data = (jack_local_data_t*) arg;

	jack_default_audio_sample_t* out = (jack_default_audio_sample_t*) jack_port_get_buffer(data->outputPort, nframes);

	size_t targetBytes = nframes * sizeof(jack_default_audio_sample_t);
	if (jack_ringbuffer_read_space(data->ringBuffer) < targetBytes) {
		memset(out, 0, targetBytes);
	} else {
		jack_ringbuffer_read(data->ringBuffer, (char*) out, targetBytes);
	}

	return 0; // ok
}

/*******************************************************************************
 * JACK calls this function if the server ever shuts down or
 * decides to disconnect the client.
 */
void
jackShutdownCallback(void *arg)
{
}
#else
//=============================================================================
//	IO Management (from AudioHardware.h documentation)
//
//	These routines allow a client to send and receive data on a given device.
//	They also provide support for tracking where in a stream of data the
//	hardware is at currently.
//=============================================================================

//-----------------------------------------------------------------------------
//	AudioDeviceIOProc
//
//	This is a client supplied routine that the HAL calls to do an
//	IO transaction for a given device. All input and output is presented
//	to the client simultaneously for processing. The inNow parameter
//	is the time that should be used as the basis of now rather than
//	what might be provided by a query to the device's clock. This is necessary
//	because time will continue to advance while this routine is executing
//	making retrieving the current time from the appropriate parameter
//	unreliable for synch operations. The time stamp for theInputData represents
//	when the data was recorded. For the output, the time stamp represents
//	when the first sample will be played. In all cases, each time stamp is
//	accompanied by its mapping into host time.
//
//	The format of the actual data depends of the sample format of the streams
//	on the device as specified by its properties. It may be raw or compressed,
//	interleaved or not interleaved as determined by the requirements of the
//	device and its settings.
//
//	If the data for either the input or the output is invalid, the time stamp
//	will have a value of 0. This happens when a device doesn't have any inputs
//	or outputs.
//
//	On exiting, the IOProc should set the mDataByteSize field of each AudioBuffer
//	(if any) in the output AudioBufferList. On input, this value is set to the
//	size of the buffer, so it will only need to be changed for cases where
//	the number of bytes for the buffer size (kAudioDevicePropertyBufferFrameSize)
//	of the IO transaction. This may be the case for compressed formats like AC-3.
//-----------------------------------------------------------------------------


OSStatus sineIOProc (AudioDeviceID inDevice,
                     const AudioTimeStamp *inNow,
                     const AudioBufferList *inInputData,
                     const AudioTimeStamp *inInputTime,
                     AudioBufferList *outOutputData,
                     const AudioTimeStamp *inOutputTime,
                     void *inClientData)

{
    Controller *controller;
	int size;
	int sampleCount;
	float *buf; // , rate;
	
    controller = (Controller *)inClientData;
    size = outOutputData->mBuffers[0].mDataByteSize;
    sampleCount = size / sizeof(float);
    buf = (float *)malloc(sampleCount * sizeof(float));
	
	int i;
	while (circBuff2Count < 512) ;
	for (i = 0; i < sampleCount/2; i++) {
		buf[2*i] = getCircBuff2();
		buf[2*i+1] = buf[2*i];
	}
	
    memcpy(outOutputData->mBuffers[0].mData, buf, size); // move data
	
    free(buf);
	
    return noErr;
}
#endif



@implementation Controller


- (id)init;
{
    if ([super init] == nil)
        return nil;

    _deviceReady = NO;
#ifndef GNUSTEP
    _device = kAudioDeviceUnknown;
#endif
    _isPlaying = NO;
    toneFrequency = TONE_FREQ;
	NSNotificationCenter *nc;
	nc = [NSNotificationCenter defaultCenter];
	[nc addObserver:self
		   selector:@selector(sliderMoved:)
			   name:@"SliderMoved"
			 object:nil];
		NSLog(@"Registered Controller as observer with notification centre\n");
	NSLog(@"We have init");
		[nc addObserver:self selector:@selector(handleFricArrowMoved:)
			   name:@"FricArrowMoved"
			 object:nil];
	NSLog(@"Registered noiseSource as FricArrowMoved notification observer");

    return self;
}

- (void)awakeFromNib;
{
    NSLog(@"awaking...");
    [_mainWindow makeKeyAndOrderFront:self];
	toneFrequency = TONE_FREQ;
	[toneFrequencyTextField setFloatingPointFormat:(BOOL)NO left:(unsigned)4 right:(unsigned)1];
    [toneFrequencyTextField setFloatValue:toneFrequency];
    [toneFrequencySlider setFloatValue:toneFrequency];
	//NSLog(@"Tone Frequency is %f", toneFrequency);
	
	[tubeLengthField setFloatingPointFormat:(BOOL)NO left:(unsigned)2 right:(unsigned)2];
	[temperatureField setFloatingPointFormat:(BOOL)NO left:(unsigned)2 right:(unsigned)2];
	
	[actualLengthField setFloatingPointFormat:(BOOL)NO left:2 right:4];
	[sampleRateField setFloatingPointFormat:(BOOL)NO left:6 right:0];
	[controlPeriodField setFloatingPointFormat:(BOOL)NO left:3 right:0];
	
	[stereoBalanceField setFloatingPointFormat:(BOOL)NO left:(unsigned)2 right:(unsigned)2];
	[breathinessField setFloatingPointFormat:(BOOL)NO left:(unsigned)2 right:(unsigned)2];
	[lossFactorField setFloatingPointFormat:(BOOL)NO left:(unsigned)2 right:(unsigned)2];
	[tpField setFloatingPointFormat:(BOOL)NO left:(unsigned)2 right:(unsigned)2];
	[tnMinField setFloatingPointFormat:(BOOL)NO left:(unsigned)2 right:(unsigned)2];

	[tnMaxField setFloatingPointFormat:(BOOL)NO left:(unsigned)2 right:(unsigned)2];
	[throatCutOff setFloatingPointFormat:(BOOL)NO left:(unsigned)2 right:(unsigned)2];
	[throatVolumeField setFloatingPointFormat:(BOOL)NO left:(unsigned)2 right:(unsigned)2];
	[apertureScalingField setFloatingPointFormat:(BOOL)NO left:(unsigned)2 right:(unsigned)2];
	[mouthCoefField setFloatingPointFormat:(BOOL)NO left:(unsigned)2 right:(unsigned)2];
	[noseCoefField setFloatingPointFormat:(BOOL)NO left:(unsigned)2 right:(unsigned)2];
	[mixOffsetField setFloatingPointFormat:(BOOL)NO left:(unsigned)2 right:(unsigned)2];
	[glottalVolumeField setFloatingPointFormat:(BOOL)NO left:(unsigned)2 right:(unsigned)2];
	[pitchField setFloatingPointFormat:(BOOL)NO left:(unsigned)2 right:(unsigned)2];
	[aspVolField setFloatingPointFormat:(BOOL)NO left:(unsigned)2 right:(unsigned)2];
	[fricVolField setFloatingPointFormat:(BOOL)NO left:(unsigned)2 right:(unsigned)2];
	[fricPosField setFloatingPointFormat:(BOOL)NO left:(unsigned)2 right:(unsigned)1];
	[fricCFField setFloatingPointFormat:(BOOL)NO left:(unsigned)4 right:(unsigned)0];
	[fricBWField setFloatingPointFormat:(BOOL)NO left:(unsigned)3 right:(unsigned)1];
	[fricativeArrow setFricationPosition:(float)7.0];
	
	[self setDefaults];

	//initializeSynthesizer();
}

- (void)setDefaults

{

	//int initSynthResult;
	
	tube_setLength(LENGTH_DEF);
	tube_setTemperature(TEMPERATURE_DEF);
	NSLog(@"Controller.m:180 Temperature is %f", tube_getTemperature());
	//tube_setBalance(BALANCE_DEF);
	tube_setBreathiness(BREATHINESS_DEF);
	tube_setLossFactor(LOSSFACTOR_DEF);
	tube_setTp(RISETIME_DEF);
	tube_setTnMin(FALLTIMEMIN_DEF);
	tube_setTnMax(FALLTIMEMAX_DEF);
	tube_setThroatCutoff(THROATCUTOFF_DEF);
	tube_setThroatVol(THROATVOLUME_DEF);
	tube_setApScale(APSCALE_DEF);
	tube_setMouthCoef(MOUTHCOEF_DEF);
	tube_setNoseCoef(NOSECOEF_DEF);
	tube_setMixOffset(MIXOFFSET_DEF);
	tube_setGlotVol(GLOTVOL_DEF);
	tube_setGlotPitch(GLOTPITCH_DEF);
	tube_setAspVol(ASPVOL_DEF);
	tube_setFricVol(FRIC_VOL_DEF);
	tube_setFricPos(FRIC_POS_DEF);
	tube_setFricCF(FRIC_CF_DEF);
	tube_setFricBW(FRIC_BW_DEF);
	

	[tubeLengthField setFloatValue:tube_getLength()];
	[tubeLengthSlider setFloatValue:tube_getLength()];
	[temperatureField setFloatValue:tube_getTemperature()];
	[temperatureSlider setFloatValue:tube_getTemperature()];
	//[stereoBalanceField setIntValue:tube_getBalance()];
	[stereoBalanceField setIntValue:0];
	[breathinessField setFloatValue:tube_getBreathiness()];
	[lossFactorField setFloatValue:tube_getLossFactor()];
	[tpField setFloatValue:tube_getTp()];
	[tnMinField setFloatValue:tube_getTnMin()];
	[tnMaxField setFloatValue:tube_getTnMax()];
	[harmonicsSwitch selectCellAtRow:0 column:1];
	[throatCutOff setFloatValue:tube_getThroatCutoff()];
	[throatVolumeField setFloatValue:tube_getThroatVol()];
	[apertureScalingField setFloatValue:tube_getApScale()];
	[mouthCoefField setFloatValue:tube_getMouthCoef()];
	[noseCoefField setFloatValue:tube_getNoseCoef()];
	[mixOffsetField setFloatValue:tube_getMixOffset()];
	[glottalVolumeField setFloatValue:tube_getGlotVol()];
	[glottalVolumeSlider setFloatValue:tube_getGlotVol()];
	[pitchField setFloatValue:tube_getGlotPitch()];
	NSLog(@"Controller.m:219 glotPitch is %f", tube_getGlotPitch());
	[pitchSlider setFloatValue:tube_getGlotPitch()];
	[aspVolField setFloatValue:tube_getAspVol()];
	[aspVolSlider setFloatValue:tube_getAspVol()];
	[aspVolSlider setMaxValue:ASP_VOL_MAX];
	[fricVolField setFloatValue:tube_getFricVol()];
	[fricVolSlider setFloatValue:tube_getFricVol()];
	[fricPosField setFloatValue:tube_getFricPos()];
	[fricPosSlider setFloatValue:tube_getFricPos()];
	[fricCFField setFloatValue:tube_getFricCF()];
	//NSLog(@"SampleRate prior to fricSliderSet is %f", tube_getSampleRate());
	[fricCFSlider setMaxValue:(tube_getSampleRate() / 2.0)];
	[fricCFSlider setMinValue:FRIC_CF_MIN];
	[fricCFSlider setFloatValue:tube_getFricCF()];
	[fricBWField setFloatValue:tube_getFricBW()];
	[fricBWSlider setMaxValue:(tube_getSampleRate() / 2.0)];
	[fricBWSlider setMinValue:FRIC_BW_MIN];
	[fricBWSlider setFloatValue:tube_getFricBW()];

	
	//initSynthResult = initializeSynthesizer();
	//if (initSynthResult == SUCCESS) NSLog(@"Controller.m:240 synthesizer initialisation succeeded");
	//NSLog(@"Controller.m:241glotPitch is %f", tube_getGlotPitch());
	
	[rS1 setValue:tube_getRadiusDefault(0)];
	tube_setRadius(tube_getRadiusDefault(0), 0);
	[rS2 setValue:tube_getRadiusDefault(1)];
	tube_setRadius(tube_getRadiusDefault(1), 1);
	[rS3 setValue:tube_getRadiusDefault(2)];
	tube_setRadius(tube_getRadiusDefault(2), 2);
	[rS4 setValue:tube_getRadiusDefault(3)];
	tube_setRadius(tube_getRadiusDefault(3), 3);
	[rS5 setValue:tube_getRadiusDefault(4)];
	tube_setRadius(tube_getRadiusDefault(4), 4);
	[rS6 setValue:tube_getRadiusDefault(5)];
	tube_setRadius(tube_getRadiusDefault(5), 5);
	[rS7 setValue:tube_getRadiusDefault(6)];
	tube_setRadius(tube_getRadiusDefault(6), 6);
	[rS8 setValue:tube_getRadiusDefault(7)];
	tube_setRadius(tube_getRadiusDefault(7), 7);
	NSLog(@"Controller.m:247 Set r8 to %f", tube_getRadiusDefault(7));
	
	[nS1 setValue:tube_getNoseRadiusDefault(1)];
	tube_setNoseRadius(tube_getNoseRadiusDefault(1), 1);
	[nS2 setValue:tube_getNoseRadiusDefault(2)];
	tube_setNoseRadius(tube_getNoseRadiusDefault(2), 2);
	[nS3 setValue:tube_getNoseRadiusDefault(3)];
	tube_setNoseRadius(tube_getNoseRadiusDefault(3), 3);
	[nS4 setValue:tube_getNoseRadiusDefault(4)];
	tube_setNoseRadius(tube_getNoseRadiusDefault(4), 4);
	[nS5 setValue:tube_getNoseRadiusDefault(5)];
	tube_setNoseRadius(tube_getNoseRadiusDefault(5), 5);
	
	[vS setValue:tube_getVelumRadiusDefault()];
	tube_setVelumRadius(tube_getVelumRadiusDefault());

	[self adjustSampleRate];
	
	NSLog(@"Controller.m:262 Sample rate is %d", tube_getSampleRate());



}


- (IBAction)saveOutputFile:(id)sender
{
	
}


- (float)toneFrequency;
{
    return toneFrequency;
}

- (void)setToneFrequency:(float)newValue;
{
    toneFrequency = newValue;
}

- (IBAction)updateToneFrequency:(id)sender;
{
    float fr;

    fr = [sender floatValue];
    [self setToneFrequency:fr];
    [toneFrequencyTextField setFloatValue:fr];
    [toneFrequencySlider setFloatValue:fr];
}

- (IBAction)playSine:(id)sender;
{
    if (_isPlaying == YES) {
		NSLog(@"Controller/playSine/_isPlaying");
		return;
	}

#ifdef GNUSTEP
	if (jackData.client != NULL) {
		NSLog(@"Controller/playSine/jackData.client != NULL");
		return;
	}

	// Allocate the input ringbuffer.
	jackData.ringBuffer = jack_ringbuffer_create(JACK_RINGBUFFER_SIZE);
	if (jackData.ringBuffer == NULL) {
		NSLog(@"Cannot allocate the ringbuffer.");
		return;
	}

	const char *clientName = JACK_CLIENT_NAME;
	jack_status_t status;

	// Open a client connection to the JACK server.
	jackData.client = jack_client_open(clientName, JackNullOption, &status, 0);
	if (jackData.client == NULL) {
		NSLog(@"jack_client_open() failed, status = 0x%02x. Unable to connect to the JACK server.", status);
		return;
	}
	if (status & JackServerStarted) {
		NSLog(@"JACK server started.");
	}
	if (status & JackNameNotUnique) {
		clientName = jack_get_client_name(jackData.client);
		NSLog(@"Unique name '%s' assigned.", clientName);
	}

	// Tell the JACK server to call 'jackProcessCallback()' whenever there is work to be done.
	jack_set_process_callback(jackData.client, jackProcessCallback, &jackData);

	// Tell the JACK server to call 'jackShutdownCallback()' if it ever shuts down, either entirely,
	// or if it just decides to stop calling us.
	jack_on_shutdown(jackData.client, jackShutdownCallback, NULL);

	// Create the output port.
	jack_port_t *outputPort = jack_port_register(jackData.client, "output", JACK_DEFAULT_AUDIO_TYPE, JackPortIsOutput, 0);
	if (outputPort == NULL) {
		NSLog(@"No more JACK ports available.");
		jack_client_close(jackData.client);
		jackData.client = NULL;
		return;
	}
	jackData.outputPort = outputPort;

	// Get the output sample rate.
	jackData.sampleRate = jack_get_sample_rate(jackData.client);
	NSLog(@"Output sample rate: %d", jackData.sampleRate);

	// Start the tube thread.
	tube_initializeSynthesizer();

	// Tell the JACK server that we are ready to roll. Our jackProcessCallback() callback will start running now.
	if (jack_activate(jackData.client)) {
		NSLog(@"Cannot activate the client.");
		jack_client_close(jackData.client);
		jackData.client = NULL;
		return;
	}

	// Connect the ports. You can't do this before the client is
	// activated, because we can't make connections to clients
	// that aren't running. Note the confusing (but necessary)
	// orientation of the driver backend ports: playback ports are
	// "input" to the backend, and capture ports are "output" from it.
	const char **ports = jack_get_ports(jackData.client, NULL, NULL, JackPortIsPhysical | JackPortIsInput);
	if (ports == NULL) {
		NSLog(@"No physical playback ports.");
		jack_client_close(jackData.client);
		jackData.client = NULL;
		return;
	}

	int i;
	for (i = 0; i < 2 && ports[i]; i++) {
		if (jack_connect(jackData.client, jack_port_name(jackData.outputPort), ports[i])) {
			free(ports);
			NSLog(@"Cannot connect the output ports.");
			jack_client_close(jackData.client);
			jackData.client = NULL;
			return;
		}
	}
	free(ports);
#else
	//threadFlag = [NSThread isMultiThreaded];
	//NSLog(@"Controller.m:322 Is the application multithreaded: answer = %threadFlagFlag is %d", [NSThread isMultiThreaded], threadFlag);
    OSStatus err = noErr;
	
	//initializeSynthesizer();
	
	//Make sure the "fixed" parameters get updated (maybe need to change the way they are handled)
	if (tube_getThreadFlag() == 0) initializeSynthesizer(); //  If it is not already running, this includes starting the synthesize thread which also detaches itself
	//NSLog(@"Controller.m:340 threadFlag is %d", tube_getThreadFlag());

    err = AudioDeviceAddIOProc(_device, sineIOProc, (void *)self);
    if (err != noErr)
        return;
	
    err = AudioDeviceStart(_device, sineIOProc);
    if (err != noErr)
        return;
#endif	
    _isPlaying = YES;
	[runStopButton setState:NSOnState];
	[analysis setRunning];
}

- (IBAction)stopPlaying:(id)sender;
{
	NSLog(@"Stop");
	//NSLog(@"Controller.m:351 Is the application multithreaded: answer = %d threadFlag is %d", [NSThread isMultiThreaded], threadFlag);
	//pthread_testcancel(threadID);  // Stop playing and cancel detached thread

	[runStopButton setState:NSOffState];
	[analysis setRunning];

    if (_isPlaying == YES) {
#ifdef GNUSTEP
		if (jack_client_close(jackData.client)) {
			NSLog(@"Error in jack_client_close().");
		}
		jackData.client = NULL;

		// Stop the tube thread.
		tube_stopSynthesizer();

		jack_ringbuffer_free(jackData.ringBuffer);
#else
		//NSLog(@"About to stop thread");

		OSStatus err = AudioDeviceStop(_device, sineIOProc);
		//NSLog(@"Stopped AudioDevice, error is %d", err);
        if (err != noErr) {
			NSLog(@"Stop has problem with Is Playing");
			return;
		}

        err = AudioDeviceRemoveIOProc(_device, sineIOProc);
		//NSLog(@"Removed AudioDevice, error is %d", err);

        if (err != noErr) {
			NSLog(@"Stop has problem with Is Playing");
			return;
		}
#endif
	}

	_isPlaying = NO;

	NSLog(@"Stop has succeeded");
	//NSLog(@"Controller.m:376 Is the application multithreaded: answer = %d threadFlag is %d", [NSThread isMultiThreaded], threadFlag);
}

// Note: this notification method only takes effect if File's Owner delegate outlet
// is connected to the controller

- (void)applicationDidFinishLaunching:(NSNotification *)notification;
{
	//double *temp = getActualTubeLength();
    NSLog(@"Did finish launching...");
    [self setupSoundDevice];
	//NSLog(@"Actual tube length after launch is %f", tube_getActualTubeLength());
	//temp = getActualTubeLength();
	//NSLog(@"Temp is %f", *temp);
	//[actualLengthField  setFloatValue:tube_getActualTubeLength()];
	//[actualLengthField setDoubleValue:*temp];
	//NSLog(@"Actual tube length after launch is %f", tube_getActualTubeLength());
	//NSLog(@"Actual tube length after launch is %f", tube_getActualTubeLength());

#ifndef GNUSTEP
    NSLog(@"buffer size : %d", _bufferSize);
#endif
	[self setDefaults];

}

- (void)setupSoundDevice;
{
#ifndef GNUSTEP
    OSStatus err;
    UInt32 count, bufferSize;
    AudioDeviceID device = kAudioDeviceUnknown;
    AudioStreamBasicDescription format;

    _deviceReady = NO;
    // get the default output device for the HAL
    count = sizeof(AudioDeviceID);
    err = AudioHardwareGetProperty(kAudioHardwarePropertyDefaultOutputDevice, &count, (void *)&device);
    if (err != noErr) {
        NSLog(@"Failed to get default output device");
        return;
    }

    // get the buffersize that the default device uses for IO
    count = sizeof(UInt32);
    err = AudioDeviceGetProperty(device, 0, false, kAudioDevicePropertyBufferSize, &count, &bufferSize);
    if (err != noErr)
        return;

    // get a description of the data format used by the default device
    count = sizeof(AudioStreamBasicDescription);
    err = AudioDeviceGetProperty(device, 0, false, kAudioDevicePropertyStreamFormat, &count, &format);
    if (err != noErr)
        return;

    NSLog(@"format:");
    NSLog(@"sample rate: %f", format.mSampleRate);
    NSLog(@"format id: %d", format.mFormatID);
    NSLog(@"format flags: %x", format.mFormatFlags);
    NSLog(@"bytes per packet: %d", format.mBytesPerPacket);


    // we want linear pcm
    if (format.mFormatID != kAudioFormatLinearPCM)
        return;

    // everything is ok so fill in these globals
    _device = device;
    _bufferSize = bufferSize;
    _format = format;

    _deviceReady = YES;
#endif
}

#ifndef GNUSTEP
- (UInt32)bufferSize;
{
    return _bufferSize;
}
#endif

- (double)sRate; //sampleRate;
{
#ifdef GNUSTEP
	if (_isPlaying == YES) {
		return jackData.sampleRate;
	}
#else
    //NSLog(@"Setting sample rate");
	if (_deviceReady)
        return _format.mSampleRate;
#endif
    return 44100.0;
}

- (IBAction)runButtonPushed:(id)sender
{
	if (_isPlaying == NO)

		[self playSine:self];

	else [self stopPlaying:sender];

}


- (IBAction)loadDefaultsButtonPushed:(id)sender
{
	
	[self setDefaults];
	NSNotificationCenter *nc;
	nc = [NSNotificationCenter defaultCenter];
	//NSLog(@"Sending notification SynthDefaultsReloaded");
	[nc postNotificationName:@"SynthDefaultsReloaded" object:self];
	tube_initializeSynthesizer();
	
}

- (IBAction)saveToDefaultsButtonPushed:(id)sender
{
	
}

- (IBAction)loadFileButtonPushed:(id)sender
{
	
}


- (IBAction)glottalWaveformSelected:(id)sender
{
	
}

- (IBAction)noisePulseModulationSelected:(id)sender
{
	
}

- (IBAction)samplingRateSelected:(id)sender
{
	
}

- (IBAction)monoStereoSelected:(id)sender
{
	
}

/*
- (IBAction)tpFieldEntered:(id)sender
{
	
}

- (IBAction)tnMinFieldEntered:(id)sender
{
	
}

- (IBAction)tnMaxFieldEntered:(id)sender
{
	
}

*/

- (IBAction)tubeLengthFieldEntered:(id)sender
{
	int error = 0;
	double tempTubeLength = [tubeLengthField doubleValue];
	if (tempTubeLength > MAX_TUBE_LENGTH) {
		tempTubeLength = MAX_TUBE_LENGTH;
		error = 1;
	}
	if (tempTubeLength < MIN_TUBE_LENGTH) {
		tempTubeLength = MIN_TUBE_LENGTH;
		error = 1;
	}
	//NSLog(@"Controller.m:546 tubeLengthField is %f", tempTubeLength);
	[tubeLengthSlider setDoubleValue:tempTubeLength];
	[tubeLengthField setDoubleValue:tempTubeLength];
	tube_setLength(tempTubeLength); // (double) [tubeLengthField doubleValue];
	[self adjustSampleRate];
	//NSLog(@"Controller.m:529 Sample rate changed, due to tube length change, to %f", (tube_getSampleRate() / 2.0));
	// Reset maximum value for fricative bandwidth according to sample rate and adjust field and slider if necessary

	tube_initializeSynthesizer();

	[fricCFSlider setMaxValue:(tube_getSampleRate() / 2.0f)];
	if ([fricCFField floatValue] > (tube_getSampleRate() / 2.0f)) {
		[fricCFField setFloatValue:(tube_getSampleRate() / 2.0f)];
		[fricCFSlider setFloatValue:(tube_getSampleRate() / 2.0f)];
	}
	[fricCFSlider setMaxValue:(tube_getSampleRate() / 2.0f)];

	if ([fricBWField floatValue] > (tube_getSampleRate() / 2.0f)) {
		[fricBWField setFloatValue:(tube_getSampleRate() / 2.0f)];
		[fricBWSlider setFloatValue:(tube_getSampleRate() / 2.0f)];
	}
	[fricBWSlider setMaxValue:(tube_getSampleRate() / 2.0f)];
	
	if (error == 1) NSBeep();
	

}

- (IBAction)temperatureFieldEntered:(id)sender
{

	int error = 0;
	double tempTemp = [temperatureField doubleValue];
	if (tempTemp > MAX_TEMP) {
		tempTemp = MAX_TEMP;
		error = 1;
	}
	if (tempTemp < MIN_TEMP) {
		tempTemp = MIN_TEMP;
		error = 1;
	}

	
	[temperatureSlider setDoubleValue:[temperatureField doubleValue]];
	[temperatureField setDoubleValue:tempTemp];
	tube_setTemperature(tempTemp);
	[self adjustSampleRate];
	NSLog(@"Controller.m:551 Sample rate changed, due to temperature field change, to %f", (tube_getSampleRate() / 2.0));
	// Reset maximum value for fricative bandwidth according to sample rate and adjust field and slider if necessary

	tube_initializeSynthesizer();

	[fricCFSlider setMaxValue:(tube_getSampleRate() / 2.0f)];
	if ([fricCFField floatValue] > (tube_getSampleRate() / 2.0f)) {
		[fricCFField setFloatValue:(tube_getSampleRate() / 2.0f)];
	}
	[fricCFSlider setFloatValue:(tube_getSampleRate() / 2.0f)];
	
	if ([fricBWField floatValue] > (tube_getSampleRate() / 2.0f)) {
		[fricBWField setFloatValue:(tube_getSampleRate() / 2.0f)];
		[fricBWSlider setFloatValue:(tube_getSampleRate() / 2.0f)];
	}
	[fricBWSlider setMaxValue:(tube_getSampleRate() / 2.0f)];
	
	if (error == 1) NSBeep();
	
}

- (IBAction)stereoBalanceFieldEntered:(id)sender
{
	
}

- (IBAction)breathinessFieldEntered:(id)sender
{
	
}

- (IBAction)lossFactorFieldEntered:(id)sender
{
	
	BOOL rangeError = NO;
	
    /*  GET CURRENT ROUNDED VALUE FROM FIELD  */
    double currentValue = ([sender doubleValue]);
	
    /*  MAKE SURE VALUE IS IN RANGE  */
    if (currentValue < LOSS_FACTOR_MIN) {
		rangeError = YES;
		currentValue = LOSS_FACTOR_MIN;
    }
    else if (currentValue > LOSS_FACTOR_MAX) {
		rangeError = YES;
		currentValue = LOSS_FACTOR_MAX;
    }
	
    /*  SET THE FIELD TO THE ROUNDED, CORRECTED VALUE  */
    [sender setFloatValue:currentValue];
	
    /*  IF CURRENT VALUE IS DIFFERENT FROM PREVIOUS VALUE, DEAL WITH IT  */
    if (currentValue != tube_getLossFactor()) {
		
		/*  SET INSTANCE VARIABLE  */
		tube_setLossFactor(currentValue);
		
		tube_initializeSynthesizer();
		
		/*  SET SLIDER TO NEW VALUE  */
		[lossFactorSlider setFloatValue:tube_getLossFactor()];
		
		/*  SEND ASPIRATION VOLUME TO SYNTHESIZER  */
		//[synthesizer setAspirationVolume:aspirationVolume];
		//tube_setAspVol(currentValue);
		NSLog(@"Controller.m:615 lossFactor is %f", tube_getLossFactor());
		
		/*  SET DIRTY BIT  */
		[self setDirtyBit];
		
	}
	
	
	// tube_setLossFactor([lossFactorField floatValue]);
	// [lossFactorSlider setFloatValue:tube_getLossFactor()];
	// NSLog(@"Controller.m:625 lossFactor is %f", tube_getLossFactor());

}

- (IBAction)throatCutoffFieldEntered:(id)sender
{
	
}

- (IBAction)throatVolumeFieldEntered:(id)sender
{
	
}

- (IBAction)apertureScalingFieldEntered:(id)sender
{
	
}

- (IBAction)mouthApertureCoefficientFieldEntered:(id)sender
{
	
}

- (IBAction)noseApertureCoefficientFieldEntered:(id)sender
{
	
}

- (IBAction)mixOffsetFieldEntered:(id)sender
{
	
}

- (IBAction)n1RadiusFieldEntered:(id)sender
{
	
}

- (IBAction)n2RadiusFieldEntered:(id)sender
{
	
}

- (IBAction)n3RadiusFieldEntered:(id)sender
{
	
}

- (IBAction)n4RadiusFieldEntered:(id)sender
{
	
}

- (IBAction)n5RadiusFieldEntered:(id)sender
{
	
}

- (IBAction)glottalVolumeFieldEntered:(id)sender
{
	
}

- (IBAction)pitchFieldEntered:(id)sender
{
	//[pitchScale drawPitch:(int)pitch Cents:(int)cents Volume:(float)volume];
}

- (IBAction)aspVolFieldEntered:(id)sender
{
	BOOL rangeError = NO;
	
    /*  GET CURRENT ROUNDED VALUE FROM FIELD  */
    int currentValue = (int)rint([sender doubleValue]);
	
    /*  MAKE SURE VALUE IS IN RANGE  */
    if (currentValue < VOLUME_MIN) {
		rangeError = YES;
		currentValue = VOLUME_MIN;
    }
    else if (currentValue > VOLUME_MAX) {
		rangeError = YES;
		currentValue = VOLUME_MAX;
    }
	
    /*  SET THE FIELD TO THE ROUNDED, CORRECTED VALUE  */
    [sender setIntValue:currentValue];
	
    /*  IF CURRENT VALUE IS DIFFERENT FROM PREVIOUS VALUE, DEAL WITH IT  */
    if (currentValue != tube_getAspVol()) {
		/*  SET INSTANCE VARIABLE  */
		tube_setAspVol(currentValue);
		NSLog(@"Controller.m:651 aspVol is %f", tube_getAspVol());
		
		/*  SET SLIDER TO NEW VALUE  */
		[aspVolSlider setIntValue:rint(tube_getAspVol())];
		
		/*  SEND ASPIRATION VOLUME TO SYNTHESIZER  */
		//[synthesizer setAspirationVolume:aspirationVolume];
		
		/*  SET DIRTY BIT  */
		[self setDirtyBit];
    }
	
    /*  BEEP AND HIGHLIGHT FIELD IF RANGE ERROR  */
    if (rangeError) {
		NSBeep();
		//[sender selectText:self];
    } 
	
}

- (IBAction)fricVolFieldEntered:(id)sender
{
	BOOL rangeError = NO;
	
	/*  GET CURRENT VALUE FROM SLIDER  */
    int currentValue = [sender intValue];
	NSLog(@"In fricVolFieldEntered, value %d",currentValue);
	
    /*  CORRECT OUT OF RANGE VALUES  */
    if (currentValue < FRIC_VOL_MIN) {
		rangeError = YES;
		currentValue = FRIC_VOL_MIN;
    }
    else if (currentValue > FRIC_VOL_MAX) {
		rangeError = YES;
		currentValue = FRIC_VOL_MAX;
    }
	
    /*  ADJUST SOUND IF VALUE IS DIFFERENT FROM OLD VALUE  */
    if (currentValue != (int)tube_getFricVol()) {
		/*  SET FRICATION VOLUME  */
		tube_setFricVol((float) currentValue);
		
		/*  SET FIELD TO VALUE  */
		[fricVolSlider setFloatValue:tube_getFricVol()];
		
		/*  SEND PARAMETER TO THE SYNTHESIZER  */
		//[synthesizer setFricationVolume:fricationVolume];
		tube_setFricVol((float) currentValue);
		
		/*  SET DIRTY BIT  */
		[self setDirtyBit];
    } 
	if (rangeError) {
		NSBeep();
		[sender setFloatValue:currentValue];
	}
}

- (IBAction)fricPosFieldEntered:(id)sender
{
	BOOL rangeError = NO;
	
    /*  GET CURRENT VALUE FROM FIELD  */
    float currentValue = [sender floatValue];
	
    /*  CORRECT OUT OF RANGE VALUES  */
    if (currentValue < FRIC_POS_MIN) {
		rangeError = YES;
		currentValue = FRIC_POS_MIN;
    }
    else if (currentValue > FRIC_POS_MAX) {
		rangeError = YES;
		currentValue = FRIC_POS_MAX;
    }
	
    /*  IF CURRENT VALUE IS DIFFERENT FROM PREVIOUS VALUE, DEAL WITH IT  */
    if (currentValue != tube_getFricPos()) {
		/*  SET INSTANCE VARIABLE  */
		tube_setFricPos(currentValue);
		//NSLog(@"Controller.m:845 new fricPos field is %f and currentValue is %f", tube_getFricPos(), currentValue);
		
		/*  SET SLIDER TO NEW VALUE  */
		[fricPosSlider setFloatValue:tube_getFricPos()];
		
		// SET FRICATIVE ARROW TO REQUIRED SPOT
		[self injectFricationAt:(float)currentValue];
		
		/*  SEND FRICATION POSITION TO SYNTHESIZER  */
		//[synthesizer setFricationPosition:fricationPosition];
		
		/*  SET DIRTY BIT  */
		[self setDirtyBit];
    }
	
    /*  BEEP AND HIGHLIGHT FIELD IF RANGE ERROR  */
    if (rangeError) {
		NSBeep();
		[sender setFloatValue:currentValue];
		tube_initializeSynthesizer();

    } 
}

- (IBAction)fricCFFieldEntered:(id)sender
{
	
    BOOL rangeError = NO;
	
    /*  GET CURRENT ROUNDED VALUE FROM FIELD  */
    int currentValue = (int)rint([sender doubleValue]);
	double maxValue = tube_getSampleRate() / 2.0;
	NSLog(@"In fricCFFieldEntered, value is %d, maxValue is %f, sample rate %f", currentValue, maxValue, tube_getSampleRate());
	
    /*  CORRECT OUT OF RANGE VALUES  */
    if (currentValue < FRIC_CF_MIN) {
		rangeError = YES;
		currentValue = FRIC_CF_MIN;
    }
    else if (currentValue > maxValue) {
		NSLog(@"SampleRate is %f", maxValue);
		rangeError = YES;
		currentValue = (int)maxValue;
    }
	
    /*  SET THE FIELD TO THE ROUNDED, CORRECTED VALUE  */
    [sender setIntValue:currentValue];
	
    /*  IF CURRENT VALUE IS DIFFERENT FROM PREVIOUS VALUE, DEAL WITH IT  */
    if (currentValue != tube_getFricCF()) {
		/*  SET INSTANCE VARIABLE  */
		tube_setFricCF(currentValue);
		
		/*  SET SLIDER TO NEW VALUE  */
		[fricCFSlider setFloatValue:tube_getFricCF()];
		
		/*  DISPLAY NEW FREQUENCY RESPONSE  */
		//[bandpassView drawCenterFrequency:centerFrequency bandwidth:bandwidth sampleRate:[resonantSystem sampleRate] scale:responseScale];
		
		/*  SEND CENTER FREQUENCY TO SYNTHESIZER  */
		//[synthesizer setFricationCenterFrequency:centerFrequency];
		
		/*  SET DIRTY BIT  */
		[self setDirtyBit];
    }
	NSLog(@"Range error is %d", rangeError);
    /*  BEEP AND HIGHLIGHT FIELD IF RANGE ERROR  */
    if (rangeError) {
		NSBeep();
		//[sender selectText:self];
    } 
	
}

- (IBAction)fricBWFieldEntered:(id)sender
{
	BOOL rangeError = NO;
	
    /*  GET CURRENT ROUNDED VALUE FROM FIELD  */
    int currentValue = (int)rint([sender doubleValue]);
	double maxValue = tube_getSampleRate() / 2.0;
	NSLog(@"In fricBWFieldEntered, value is %d, maxValue is %f, sample rate %d", currentValue, maxValue, tube_getSampleRate());
	
    /*  CORRECT OUT OF RANGE VALUES  */
    if (currentValue < FRIC_BW_MIN) {
		rangeError = YES;
		currentValue = FRIC_BW_MIN;
    }
    else if (currentValue > maxValue) {
		NSLog(@"SampleRate is %f", maxValue);
		rangeError = YES;
		currentValue = (int)maxValue;
    }
	
    /*  SET THE FIELD TO THE ROUNDED, CORRECTED VALUE  */
    [sender setIntValue:currentValue];
	
    /*  IF CURRENT VALUE IS DIFFERENT FROM PREVIOUS VALUE, DEAL WITH IT  */
    if (currentValue != (int)tube_getFricBW()) {
		/*  SET INSTANCE VARIABLE  */
		tube_setFricBW((float) currentValue);
		
		/*  SET SLIDER TO NEW VALUE  */
		[fricBWSlider setIntValue:(int)tube_getFricBW()];
		
		/*  DISPLAY NEW FREQUENCY RESPONSE  */
		//[bandpassView drawCenterFrequency:centerFrequency bandwidth:bandwidth sampleRate:[resonantSystem sampleRate] scale:responseScale];
		
		/*  SEND CENTER FREQUENCY TO SYNTHESIZER  */
		//[synthesizer setFricationCenterFrequency:centerFrequency];
		
		/*  SET DIRTY BIT  */
		[self setDirtyBit];
    }
	NSLog(@"Range error is %d", rangeError);
    /*  BEEP AND HIGHLIGHT FIELD IF RANGE ERROR  */
    if (rangeError) {
		NSBeep();
		//[sender selectText:self];
    } 
	
}


- (IBAction)r1RadiusFieldEntered:(id)sender
{

}

- (IBAction)r2RadiusFieldEntered:(id)sender
{
	
}

- (IBAction)r3RadiusFieldEntered:(id)sender
{
	
}

- (IBAction)r4RadiusFieldEntered:(id)sender
{
	
}

- (IBAction)r5RadiusFieldEntered:(id)sender
{
	
}

- (IBAction)r6RadiusFieldEntered:(id)sender
{
	
}

- (IBAction)r7RadiusFieldEntered:(id)sender
{
	
}

- (IBAction)r8RadiusFieldEntered:(id)sender
{
	
}

- (IBAction)vRadiusFieldEntered:(id)sender;
{
	
}

/*

- (IBAction)tpSliderMoved:(id)sender
{
	
}

- (IBAction)tnMinSliderMoved:(id)sender
{
	
}

- (IBAction)tnMaxSliderMoved:(id)sender
{
	
}

*/

- (IBAction)tubeLengthSliderMoved:(id)sender
{
	[tubeLengthField setDoubleValue:[tubeLengthSlider doubleValue]];
	tube_setLength([tubeLengthSlider floatValue]);
	[self adjustSampleRate];
	//NSLog(@"Controller.m:944 Sample rate changed, due to tube length change, to %f", (tube_getSampleRate() / 2.0));

	tube_initializeSynthesizer();

	[fricCFSlider setMaxValue:(tube_getSampleRate() / 2.0f)];
	if ([fricCFField floatValue] > (tube_getSampleRate() / 2.0f)) {
		[fricCFField setFloatValue:(tube_getSampleRate() / 2.0f)];
		[fricCFSlider setFloatValue:(tube_getSampleRate() / 2.0f)];
	}

	
	if ([fricBWField floatValue] > (tube_getSampleRate() / 2.0f)) {
		[fricBWField setFloatValue:(tube_getSampleRate() / 2.0f)];
		[fricBWSlider setFloatValue:(tube_getSampleRate() / 2.0f)];
	}
	[fricBWSlider setMaxValue:(tube_getSampleRate() / 2.0f)];
	

}

- (IBAction)temperatureSliderMoved:(id)sender
{
	[temperatureField setDoubleValue:[temperatureSlider doubleValue]];
	tube_setTemperature([temperatureSlider floatValue]);
	[self adjustSampleRate];
	//NSLog(@"Sample rate changed, due to temperature slider change, to %f", (tube_getSampleRate() / 2.0));

	tube_initializeSynthesizer();

	[fricCFSlider setMaxValue:(tube_getSampleRate() / 2.0f)];
	if ([fricCFField floatValue] > (tube_getSampleRate() / 2.0f)) {
		[fricCFField setFloatValue:(tube_getSampleRate() / 2.0f)];
		[fricCFSlider setFloatValue:(tube_getSampleRate() / 2.0f)];
	}
	
	
	if ([fricBWField floatValue] > (tube_getSampleRate() / 2.0f)) {
		[fricBWField setFloatValue:(tube_getSampleRate() / 2.0f)];
		[fricBWSlider setFloatValue:(tube_getSampleRate() / 2.0f)];
	}
	[fricBWSlider setMaxValue:(tube_getSampleRate() / 2.0f)];
	
}

- (IBAction)stereoBalanceSliderMoved:(id)sender
{
	
}

- (IBAction)breathinessSliderMoved:(id)sender
{
	
}

- (IBAction)lossFactorSliderMoved:(id)sender
{
	
	BOOL rangeError = NO;
	
    /*  GET CURRENT ROUNDED VALUE FROM FIELD  */
    float currentValue = ([sender floatValue]);
	
    /*  MAKE SURE VALUE IS IN RANGE  */
    if (currentValue < LOSS_FACTOR_MIN) {
		rangeError = YES;
		currentValue = LOSS_FACTOR_MIN;
    }
    else if (currentValue > LOSS_FACTOR_MAX) {
		rangeError = YES;
		currentValue = LOSS_FACTOR_MAX;
    }
	
    /*  SET THE FIELD TO THE ROUNDED, CORRECTED VALUE  */
    [sender setFloatValue:currentValue];
	
    /*  IF CURRENT VALUE IS DIFFERENT FROM PREVIOUS VALUE, DEAL WITH IT  */
    if (currentValue != tube_getLossFactor()) {
		
	/*  SET INSTANCE VARIABLE  */
	tube_setLossFactor(currentValue);

	tube_initializeSynthesizer();
			
	/*  SET SLIDER TO NEW VALUE  */
		[lossFactorField setFloatValue:tube_getLossFactor()];
		
	/*  SEND ASPIRATION VOLUME TO SYNTHESIZER  */
		//[synthesizer setAspirationVolume:aspirationVolume];
		//tube_setAspVol(currentValue);
		NSLog(@"Controller.m:1059 lossFactor is %f", tube_getLossFactor());
		
		/*  SET DIRTY BIT  */
		[self setDirtyBit];
		
		}
	
	// tube_setLossFactor([lossFactorSlider floatValue]);
	// [lossFactorField setFloatValue:tube_getLossFactor()];

}

- (IBAction)throatCutoffSliderMoved:(id)sender
{
	
}

- (IBAction)throatVolumeSliderMoved:(id)sender
{
	
}

- (IBAction)apertureScalingSliderMoved:(id)sender
{
	
}

- (IBAction)mouthApertureCoefficientSliderMoved:(id)sender
{
	
}

- (IBAction)noseApertureCoefficientSliderMoved:(id)sender
{
	
}

- (IBAction)mixOffsetSliderMoved:(id)sender
{
	
}

- (IBAction)n1RadiusSliderMoved:(id)sender
{
	
}

- (IBAction)n2RadiusSliderMoved:(id)sender
{
	
}

- (IBAction)n3RadiusSliderMoved:(id)sender
{
	
}

- (IBAction)n4RadiusSliderMoved:(id)sender
{
	
}

- (IBAction)n5RadiusSliderMoved:(id)sender
{
	
}

- (IBAction)glottalVolumeSliderMoved:(id)sender
{
	
}

/*
- (IBAction)pitchSliderMoved:(id)sender
{
	tube_setGlotPitch([pitchSlider floatValue]);
	NSLog(@"Pitch is now %f", tube_getGlotPitch());
}
*/

- (IBAction)aspVolSliderMoved:(id)sender
{
	BOOL rangeError = NO;
	
    /*  GET CURRENT ROUNDED VALUE FROM FIELD  */
    int currentValue = (int) rint([sender doubleValue]);
	
    /*  MAKE SURE VALUE IS IN RANGE  */
    if (currentValue < VOLUME_MIN) {
		rangeError = YES;
		currentValue = VOLUME_MIN;
    }
    else if (currentValue > VOLUME_MAX) {
		rangeError = YES;
		currentValue = VOLUME_MAX;
    }
	
    /*  SET THE FIELD TO THE ROUNDED, CORRECTED VALUE  */
    [sender setIntValue:currentValue];
	
    /*  IF CURRENT VALUE IS DIFFERENT FROM PREVIOUS VALUE, DEAL WITH IT  */
    if (currentValue != tube_getAspVol()) {
		/*  SET INSTANCE VARIABLE  */
		tube_setAspVol((float) currentValue);
		
		/*  SET SLIDER TO NEW VALUE  */
		[aspVolField setDoubleValue:rint(tube_getAspVol())];
		
		/*  SEND ASPIRATION VOLUME TO SYNTHESIZER  */
		//[synthesizer setAspirationVolume:aspirationVolume];
		//tube_setAspVol(currentValue);
		NSLog(@"Controller.m: aspVol is %f", tube_getAspVol());
		
		/*  SET DIRTY BIT  */
		[self setDirtyBit];
    }
	
    /*  BEEP AND HIGHLIGHT FIELD IF RANGE ERROR  */
    if (rangeError) {
		NSBeep();
		//[sender selectText:self];
    } 
	
}

- (IBAction)fricVolSliderMoved:(id)sender
{
	BOOL rangeError = NO;
	
    /*  GET CURRENT VALUE FROM FIELD  */
    int currentValue = rint([sender doubleValue]);
	NSLog(@"Controller.m:1089 In fricVolSliderMoved %d", currentValue);

	
    /*  CORRECT OUT OF RANGE VALUES  */
    if (currentValue < FRIC_VOL_MIN) {
		rangeError = YES;
		currentValue = FRIC_VOL_MIN;
    }
    else if (currentValue > FRIC_VOL_MAX) {
		rangeError = YES;
		currentValue = FRIC_VOL_MAX;
    }
	
    /*  SET THE FIELD TO THE ROUNDED, CORRECTED VALUE  */
    [fricVolField setIntValue:currentValue];
	
    /*  IF CURRENT VALUE IS DIFFERENT FROM PREVIOUS VALUE, DEAL WITH IT  */
    if (currentValue != (int)tube_getFricVol()) {
		/*  SET INSTANCE VARIABLE  */
		tube_setFricVol(currentValue);
		
		/*  SET SLIDER TO NEW VALUE  */
		[fricVolField setFloatValue:tube_getFricVol()];
		
		/*  SEND FRICATION VOLUME TO SYNTHESIZER  */
		//[synthesizer setFricationVolume:fricationVolume];
		//*((float *) getFricVol());
		
		/*  SET DIRTY BIT  */
		[self setDirtyBit];
    }
	
    /*  BEEP AND HIGHLIGHT FIELD IF RANGE ERROR  */
    if (rangeError)
		NSBeep();
	//	[sender selectText:self];
    //} 
}

- (IBAction)fricPosSliderMoved:(id)sender
{
	BOOL rangeError = NO;
	
    //  GET CURRENT VALUE FROM SLIDER  
    float currentValue = [sender floatValue];
	NSLog(@"In fricPosSliderMoved value %f", currentValue);
	
    //  CORRECT OUT OF RANGE VALUES  
    if (currentValue < FRIC_POS_MIN) {
		rangeError = YES;
		currentValue = FRIC_POS_MIN;
    }
    else if (currentValue > FRIC_POS_MAX) {
		rangeError = YES;
		currentValue = FRIC_POS_MAX;
    }
	
    /*  IF CURRENT VALUE IS DIFFERENT FROM PREVIOUS VALUE, DEAL WITH IT  */
    if (currentValue != tube_getFricPos()) {
		/*  SET INSTANCE VARIABLE  */
		tube_setFricPos(currentValue);
		//NSLog(@"Controller.m:1319 new fricPos slider is %d and currentValue is %f", tube_getFricPos(), currentValue);
		
		/*  SET POSITION FIELD TO NEW VALUE  */
		[fricPosField setFloatValue:tube_getFricPos()];
		
		// SET FRICATIVE ARROW TO REQUIRED SPOT
		[self injectFricationAt:currentValue];
		
		/*  DISPLAY POSITION OF FRICATION IN RESONANT SYSTEM  */
		//[resonantSystem injectFricationAt:fricationPosition];
		
		/*  SEND FRICATION POSITION TO SYNTHESIZER  */
		//[synthesizer setFricationPosition:fricationPosition];
		
		/*  SET DIRTY BIT  */
		[self setDirtyBit];
    }
	
    /*  BEEP AND HIGHLIGHT FIELD IF RANGE ERROR  */
    if (rangeError) {
		NSBeep();
		[sender setFloatValue:currentValue];
		//[sender selectText:self];
    } 
	
}

- (IBAction)fricCFSliderMoved:(id)sender
{
	
    BOOL rangeError = NO;
	
    /*  GET CURRENT ROUNDED VALUE FROM SLIDER  */
    int currentValue = rint([sender doubleValue]);
	double maxValue = tube_getSampleRate() / 2.0;
	NSLog(@"In fricCFSliderMoved, value is %d, maxValue is %f, sample rate %d", currentValue, maxValue, tube_getSampleRate());
	
    /*  CORRECT OUT OF RANGE VALUES  */
    if (currentValue < FRIC_CF_MIN) {
		rangeError = YES;
		currentValue = FRIC_CF_MIN;
    }
    else if (currentValue > (int)maxValue) {
		NSLog(@"SampleRate is %f", maxValue);
		rangeError = YES;
		currentValue = maxValue;
    }
	
    /*  SET THE SLIDER TO THE ROUNDED, CORRECTED VALUE  */
    [sender setIntValue:currentValue];
	
    /*  IF CURRENT VALUE IS DIFFERENT FROM PREVIOUS VALUE, DEAL WITH IT  */
    if (currentValue != (int)tube_getFricCF()) {
		/*  SET INSTANCE VARIABLE  */
		tube_setFricCF(currentValue);
		
		/*  SET FIELD TO NEW VALUE  */
		[fricCFField setFloatValue:tube_getFricCF()];
		
		/*  DISPLAY NEW FREQUENCY RESPONSE  */
		//[bandpassView drawCenterFrequency:centerFrequency bandwidth:bandwidth sampleRate:[resonantSystem sampleRate] scale:responseScale];
		
		/*  SEND CENTER FREQUENCY TO SYNTHESIZER  */
		//[synthesizer setFricationCenterFrequency:centerFrequency];
		
		/*  SET DIRTY BIT  */
		[self setDirtyBit];
    }
	NSLog(@"Range error is %d", rangeError);
    /*  BEEP AND HIGHLIGHT FIELD IF RANGE ERROR  */
    if (rangeError) {
		NSBeep();
		//[sender selectText:self];
    } 
	
	
}

- (IBAction)fricBWSliderMoved:(id)sender
{
	BOOL rangeError = NO;
	
    /*  GET CURRENT ROUNDED VALUE FROM SLIDER  */
    int currentValue = rint([sender doubleValue]);
	double maxValue = tube_getSampleRate() / 2.0;
	NSLog(@"In fricBWSliderMoved, value is %d, maxValue is %f, sample rate %d", currentValue, maxValue, tube_getSampleRate());
	
    /*  CORRECT OUT OF RANGE VALUES  */
    if (currentValue < FRIC_BW_MIN) {
		rangeError = YES;
		currentValue = FRIC_BW_MIN;
    }
    else if (currentValue > (int)maxValue) {
		NSLog(@"SampleRate is %f", maxValue);
		rangeError = YES;
		currentValue = maxValue;
    }
	
    /*  SET THE SLIDER TO THE ROUNDED, CORRECTED VALUE  */
    [sender setIntValue:currentValue];
	
    /*  IF CURRENT VALUE IS DIFFERENT FROM PREVIOUS VALUE, DEAL WITH IT  */
    if (currentValue != (int)tube_getFricBW()) {
		/*  SET INSTANCE VARIABLE  */
		tube_setFricBW(currentValue);
		
		/*  SET FIELD TO NEW VALUE  */
		[fricBWField setFloatValue:tube_getFricBW()];
		
		/*  DISPLAY NEW FREQUENCY RESPONSE  */
		//[bandpassView drawCenterFrequency:centerFrequency bandwidth:bandwidth sampleRate:[resonantSystem sampleRate] scale:responseScale];
		
		/*  SEND CENTER FREQUENCY TO SYNTHESIZER  */
		//[synthesizer setFricationCenterFrequency:centerFrequency];
		
		/*  SET DIRTY BIT  */
		[self setDirtyBit];
    }
	NSLog(@"Range error is %d", rangeError);
    /*  BEEP AND HIGHLIGHT FIELD IF RANGE ERROR  */
    if (rangeError) {
		NSBeep();
		//[sender selectText:self];
    } 
	
}

- (IBAction)r1RadiusSliderMoved:(id)sender
{

}

- (IBAction)r2RadiusSliderMoved:(id)sender
{
	
}

- (IBAction)r3RadiusSliderMoved:(id)sender
{
	
}

- (IBAction)r4RadiusSliderMoved:(id)sender
{
	
}

- (IBAction)r5RadiusSliderMoved:(id)sender
{
	
}

- (IBAction)r6RadiusSliderMoved:(id)sender
{
	
}

- (IBAction)r7RadiusSliderMoved:(id)sender
{
	
}

- (IBAction)r8RadiusSliderMoved:(id)sender
{
	
}

- (IBAction)vSliderMoved:(id)sender
{
	
}

- (void)sliderMoved:(NSNotification *)originator

// This method handles the section sliders associated with nose, velum and oropharynx sections
// based on a notification from the associated slider object which also supplies tag info.  The
// slider objects that need attention (TubeSection and VelumSlider) post a notification and this
// method picks it up and deals with it.

{

	int sectionId;
	float radius;
	
	sectionId = [[[originator userInfo] objectForKey:@"sliderId"] shortValue];
	radius = [[[originator userInfo] objectForKey:@"radius"] floatValue];
	//NSLog(@"In sliderMoved id is %d and radius is %f", sectionId, radius);
	if (sectionId == 14) {
		tube_setVelumRadius(radius);
	}	
	else {
		if (sectionId > 8) {
			tube_setNoseRadius(radius, sectionId - 8);
			NSLog(@"Nasal section ID is %d radius %f", sectionId, radius);
		}

		else {
			tube_setRadius(radius, sectionId - 1);
			NSLog(@"Current oral section is R%d and radius %f", sectionId, tube_getRadius(sectionId - 1));
			}
	}
}

- (void)setDirtyBit
{
	
}

#if 0
/*  Set methods to link Objective-C code and C modules  */

- (void)csetGlotPitch:(float) value
{
	setGlotPitch(value);
}

- (void)csetGlotVol:(float) value
{
	
}

- (void)csetAspVol:(float) value
{
	
}

- (void)csetFricVol:(float) value
{
	
}

- (void)csetfricPos:(float) value
{
	
}

- (void)csetFricCF:(float) value
{
	
}

- (void)csetFricBW:(float) value
{
	
}

- (void)csetRadius:(float) value: (int) index
{

}

- (void)csetVelum:(float) value
{
	
}

- (void)csetVolume:(double) value
{
	
}

- (void)csetWaveform:(int) value
{
	
}

- (void)csetTp:(double) value
{
	
}

- (void)csetTnMin:(double) value
{
	
}

- (void)csetTnMax:(double) value
{
	
}

- (void)csetBreathiness:(double) value
{
	
}

- (void)csetLength:(double) value
{
	
}

- (void)csetTemperature:(double) value
{
	
}

- (void)csetLossFactor:(double) value
{
	
}

- (void)csetApScale:(double) value
{
	
}

- (void)csetMouthCoef:(double) value
{
	
}

- (void)csetNoseCoef:(double) value
{
	
}

- (void)csetNoseRadius:(double) value: (int) index
{
	
}

- (void)csetThroatCoef:(double) value
{
	
}

- (void)csetModulation:(int) value
{
	
}

- (void)csetMixOffset:(double) value
{
	
}

- (void)csetThroatCutoff:(double) value
{
	
}

- (void)csetThroatVolume:(double) value
{
	
}
#endif

- (void)adjustToNewSampleRate
{
    int nyquistFrequency;
	
	NSLog(@"Controller.m:1525 In Controller: adjusting to new sample rate");
	
    /* CALCULATE NYQUIST FREQUENCY  */
    nyquistFrequency = (int)rint(tube_getSampleRate() / 2.0);
	//NSLog(@"Controller.m:1529 Nyquist freq is %d", nyquistFrequency);
	
    /*  SET THE MAXIMUM FOR THE SLIDERS  */
    [mouthCoefSlider setMaxValue:nyquistFrequency];
    [noseCoefSlider setMaxValue:nyquistFrequency];
	
    /*  CHANGE MOUTH FILTER COEFFICIENT, IF NECESSARY  */
    if (tube_getMouthCoef() > nyquistFrequency) {
		tube_setMouthCoef(nyquistFrequency);
		
		/*  RE-INITIALIZE MOUTH FILTER OBJECTS  */
		[mouthCoefSlider setFloatValue:tube_getMouthCoef()];
		[mouthCoefField setFloatValue:tube_getMouthCoef()];
		//[synthesizer setMouthFilterCoefficient:mouthFilterCoefficient]; **** 
    }
	
    /*  CHANGE NOSE FILTER COEFFICIENT, IF NECESSARY  */
    if (tube_getNoseCoef() > nyquistFrequency) {
		tube_setNoseCoef(nyquistFrequency);
		
		/*  RE-INITIALIZE NOSE FILTER OBJECTS  */
		[noseCoefSlider setFloatValue:tube_getNoseCoef()];
		[noseCoefField setFloatValue:tube_getNoseCoef()];
		//[synthesizer setNoseFilterCoefficient:noseFilterCoefficient]; **** 
    }
	
    /*  RE-DISPLAY APERTURE FREQUENCY RESPONSES  */
    //[mouthFrequencyResponse drawFrequencyResponse:mouthFilterCoefficient sampleRate:sampleRate scale:mouthResponseScale]; **** 
    //[noseFrequencyResponse drawFrequencyResponse:noseFilterCoefficient sampleRate:sampleRate scale:noseResponseScale]; **** 
	
	// Redisplay tube sample rate and control period

    [sampleRateField setIntValue:tube_getSampleRate()];
    [controlPeriodField setIntValue:tube_getControlPeriod()];
	
}



- (void)adjustSampleRate
{
    /*  CALCULATE SAMPLE RATE, CONTROL PERIOD, ACTUAL LENGTH  */
    [self calculateSampleRate];
	
    /*  DISPLAY THESE VALUES  */
    [actualLengthField setFloatValue:tube_getActualTubeLength()];
    [sampleRateField setIntValue:tube_getSampleRate()];
    [controlPeriodField setIntValue:tube_getControlPeriod()];
	
    /*  REDISPLAY APERTURE, NOISE SOURCE, AND THROAT FREQUENCY RESPONSES  */
    [self adjustToNewSampleRate];
    //[noiseSource adjustToNewSampleRate]; **** 
    //[throat adjustToNewSampleRate]; **** 
	
    /*  SEND APPROPRIATE VALUES TO THE SYNTHESIZER  */
    //[synthesizer setActualLength:actualLength sampleRate:sampleRate controlPeriod:controlPeriod]; **** 
	
    
    /*  SET DIRTY BIT  */
    [self setDirtyBit]; 
}


- (void)injectFricationAt:(float)position
{
    /*  DRAW ARROW WHERE FRICATION IS TO BE INJECTED  */
    [fricativeArrow setFricationPosition:position]; 
}


- (void)setTitle:(NSString *)path
{
    [_mainWindow setTitleWithRepresentedFilename:path];
}

- (void)calculateSampleRate
{
    double c; //, speedOfSound();
	
	//NSLog(@"Controller.m:1582 Control period is %d sample rate is %d actual tube length is %f control rate is %f temperature is %f",
		 // tube_getControlPeriod(), tube_getSampleRate(), tube_getLength(), tube_getControlRate(), tube_getTemperature());
	
    /*  CALCULATE THE SPEED OF SOUND AT CURRENT TEMPERATURE  */
    c = (331.4 + (0.6 * tube_getTemperature()));
	//NSLog(@"Controller.m:1587 Speed of Sound is %f control rate is %f", c, tube_getControlRate());

	/*  CALCULATE THE CONTROL PERIOD  */
    tube_setControlPeriod((int)rint((c * TOTAL_SECTIONS * 100.0) /
											  (tube_getLength() * tube_getControlRate()))); //CONTROL_RATE));

	NSLog(@"Controller.m:1593 Control period is %d sample rate is %d actual tube length is %f",
		  tube_getControlPeriod(), tube_getSampleRate(), tube_getLength());

    /*  CALCULATE THE NEAREST SAMPLE RATE  */
    tube_setSampleRate(tube_getControlPeriod() * tube_getControlRate()); // CONTROL_RATE * tube_getControlPeriod();

	//NSLog(@"Controller.m:1599 Control period is %d sample rate is %d actual tube length is %f",
		 // tube_getControlPeriod(), tube_getSampleRate(), tube_getLength());
	
    /*  CALCULATE THE ACTUAL LENGTH OF THE TUBE  */
	tube_setActualTubeLength((c * TOTAL_SECTIONS * 100.0) / tube_getSampleRate());

	//NSLog(@"In Controller.m 1606: Control period is %d sample rate is %d actual tube length is %f",
		 // tube_getControlPeriod(), tube_getSampleRate(), tube_getLength());
}

- (void)handleFricArrowMoved:(NSNotification *)note
{
	NSLog(@"Controller.m:1612 Received FricArrowMoved notification: %@", note);
	
	/*  GET CURRENT VALUE FROM SLIDER  */
    float currentValue = [[note object] floatValue];
	
    /*  IF CURRENT VALUE IS DIFFERENT FROM PREVIOUS VALUE, DEAL WITH IT  */
    if (currentValue != tube_getFricPos()) {
		/*  SET INSTANCE VARIABLE  */
		tube_setFricPos(currentValue);
		NSLog(@"fricationPosition = %f", tube_getFricPos());
		
		/*  SET FIELD TO VALUE  */
		[fricPosField setIntValue:currentValue];
		
		/*  SET SLIDER TO NEW VALUE  */
		[fricPosSlider setFloatValue:tube_getFricPos()];
		
		/*  SEND FRICATION POSITION TO SYNTHESIZER  */
		//[synthesizer setFricationPosition:fricationPosition];
		//tube_setFricPos(currentValue);
		
		/*  SET DIRTY BIT  */
		[self setDirtyBit];
		}
    }
	
- (BOOL)tubeRunState
{
	return _isPlaying;
}

@end
