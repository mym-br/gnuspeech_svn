/***************************************************************************
 *  Copyright 1991, 1992, 1993, 1994, 1995, 1996, 2001, 2002, 2007, 2008,  *
 *            2009                                                         *
 *    David R. Hill, Leonard Manzara, Craig Schock,                        *
 *    Steve Nygard, Dalmazio Brisinda, Marcelo Y. Matuda                   *
 *                                                                         *
 *  This program is free software: you can redistribute it and/or modify   *
 *  it under the terms of the GNU General Public License as published by   *
 *  the Free Software Foundation, either version 3 of the License, or      *
 *  (at your option) any later version.                                    *
 *                                                                         *
 *  This program is distributed in the hope that it will be useful,        *
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of         *
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the          *
 *  GNU General Public License for more details.                           *
 *                                                                         *
 *  You should have received a copy of the GNU General Public License      *
 *  along with this program.  If not, see <http://www.gnu.org/licenses/>.  *
 ***************************************************************************/

//
// $Id: TRMSynthesizer.h,v 1.4 2008-11-08 07:45:34 dbrisinda Exp $
//

#import <Foundation/NSObject.h>
#import <Foundation/NSData.h>
#import <Tube/TubeModel.h>

#ifdef GNUSTEP
#import <portaudio.h>
#else
#import <AudioUnit/AudioUnit.h>
#endif

@class MMSynthesisParameters;

#ifdef GNUSTEP
typedef struct {
    const void *buffer;
    unsigned long size; // in bytes
    unsigned long position;
    int channels;
} PaCallbackData;
#endif

@interface TRMSynthesizer : NSObject
{
    TRMInputData *inputData;
    NSMutableData *soundData;

#ifdef GNUSTEP
    PaCallbackData paCallbackData;
    BOOL paInitialized;
    PaStream *paStream;
#else
    AudioUnit outputUnit;
#endif

    int bufferLength;
    int bufferIndex;

    BOOL shouldSaveToSoundFile;
    NSString *filename;
}

- (id)init;
- (void)dealloc;

- (void)setupSynthesisParameters:(MMSynthesisParameters *)synthesisParameters;
- (void)removeAllParameters;
- (void)addParameters:(float *)values;

- (BOOL)shouldSaveToSoundFile;
- (void)setShouldSaveToSoundFile:(BOOL)newFlag;

- (NSString *)filename;
- (void)setFilename:(NSString *)newFilename;

- (int)fileType;
- (void)setFileType:(int)newFileType;

- (void)synthesize;
- (void)convertSamplesIntoData:(TRMSampleRateConverter *)sampleRateConverter;
- (void)startPlaying;

- (BOOL)stopPlaying;
- (void)setupSoundDevice;

#ifndef GNUSTEP
- (void)fillBuffer:(AudioBuffer *)ioData;
#endif

@end
