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
//  GPParamView.m
//  Synthesizer
//
//  Created by David Hill in 2006.
//
//  Version: 0.7.3
//
////////////////////////////////////////////////////////////////////////////////

#import "GPParamView.h"

#import <math.h>

#import "tube.h"



@implementation GPParamView : ChartView
- (id)initWithFrame:(NSRect)frameRect
{
	if ((self = [super initWithFrame:frameRect]) != nil) {
		// Add initialization code here
		[self setAxesWithScale:WX_SCALE_DIVS xScaleOrigin:WX_SCALE_ORIGIN xScaleSteps:WX_SCALE_STEPS
				xLabelInterval:WX_LABEL_INTERVAL yScaleDivs:WY_SCALE_DIVS yScaleOrigin:WY_SCALE_ORIGIN
				   yScaleSteps:WY_SCALE_STEPS yLabelInterval:WY_LABEL_INTERVAL];
	}
	return self;
}

- (NSPoint)graphOrigin;
{
    NSPoint graphOrigin;
	
	graphOrigin = [self bounds].origin;
	graphOrigin.x += GPLEFT_MARGIN;
	graphOrigin.y += GPBOTTOM_MARGIN;
    return graphOrigin;
}


- (void)drawGrid;
{
    NSBezierPath *bezierPath;
    NSRect bounds;
    NSPoint graphOrigin;
    float sectionHeight, sectionWidth;
    int index;
	
	// Draw in best fit grid markers
	
	bounds = [self bounds];
    graphOrigin = [self graphOrigin];
	sectionHeight = (bounds.size.height - graphOrigin.y - GPTOP_MARGIN)/_yScaleDivs;
	sectionWidth = (bounds.size.width - graphOrigin.x - GPRIGHT_MARGIN)/_xScaleDivs;
	
    [[NSColor lightGrayColor] set];
	NSPoint aPoint;
	
	//	First Y-axis grid lines
	
    [[NSColor lightGrayColor] set];
	
    bezierPath = [[NSBezierPath alloc] init];
    [bezierPath setLineWidth:1];
	for (index = 0; index <= _yScaleDivs; index++) {
		
		aPoint.x = graphOrigin.x;
		aPoint.y = graphOrigin.y + index * sectionHeight;
        [bezierPath moveToPoint:aPoint];
		
        aPoint.x = bounds.size.width - GPRIGHT_MARGIN;
        [bezierPath lineToPoint:aPoint];
		
    }
    [bezierPath stroke];
    [bezierPath release];
	
	/* then X-axis grid lines */
	
	bezierPath = [[NSBezierPath alloc] init];
    [bezierPath setLineWidth:1];
	for (index = 0; index <= WX_SCALE_DIVS; index++) {
		
		aPoint.y = graphOrigin.y;
        aPoint.x = graphOrigin.x + index * sectionWidth;
        [bezierPath moveToPoint:aPoint];
		
        aPoint.y =bounds.size.height - GPTOP_MARGIN;
        [bezierPath lineToPoint:aPoint];
		
    }
    [bezierPath stroke];
    [bezierPath release];
	
}

- (void)drawRect:(NSRect)rect  // This method overrides the ChartView method
{
	NSRect viewRect = [self bounds];
	[[NSColor whiteColor] set];
	[NSBezierPath fillRect:viewRect];
	[self drawGrid];
	[self drawGlottalPulseAmplitude];
	
	
	// PROTOTYPE GLOTTAL PULSE NOT DRAWN FOR SINE WAVE
	if (tube_getWaveformType() == 1)
		return;	
	else {
		
		//NSLog(@"In GPPV: drawGlottalPulseAmplitude");
		
		NSLog(@"waveform in drawGlottalPulse is %d", tube_getWaveformType());
		
		NSBezierPath *bezierPath;
		//float myHeight;
		int index;
		NSPoint currentPoint;
		NSRect bounds;
		NSPoint graphOrigin, start;
		int i, j;
		bounds = [self bounds];
		//NSLog(@"myHeight is %f", myHeight);
		graphOrigin.x = (float) GPLEFT_MARGIN;
		graphOrigin.y = (float) GPBOTTOM_MARGIN;
		//NSLog(@" Graph origin is %f %f, height %f", graphOrigin.x, graphOrigin.y, bounds.size.height); // Took out myHeight
		//initializeWavetable(tube_getGlotVol());

		
		// CREATE NEW GLOTTAL PULSE ACCORDING TO Tp, TnMin, and TnMax AND UPDATE SYNTHESIZER WAVETABLE
		// Copy the current wavetable values
		float *tempFloatWavetable = (float *)calloc(TABLE_LENGTH, sizeof(float));
			
			/*  ALLOCATE MEMORY FOR WAVETABLE  */
			//wavetable = (double *)calloc(TABLE_LENGTH, sizeof(double));
			NSLog(@"Tp is %f, TnMin is %f, and TnMax is %f",tube_getTp(), tube_getTnMin(), tube_getTnMax());
			/*  CALCULATE WAVE TABLE PARAMETERS  */
			int tableDiv1 = rint(TABLE_LENGTH * (tube_getTp() / 100.0));
			int tableDiv2 = rint(TABLE_LENGTH * ((tube_getTp() + tube_getTnMax()) / 100.0));
			double tnLength = tableDiv2 - tableDiv1;
			//tnDelta = rint(TABLE_LENGTH * ((tube_getTnMax() - tube_getTnMin()) / 100.0));
			//basicIncrement = (double) TABLE_LENGTH / tube_getSampleRate();
			//currentPosition = 0;

			//  INITIALIZE THE TEMP WAVETABLE 
			//if (waveform == PULSE) {
				//  CALCULATE RISE PORTION OF WAVE TABLE
				for (i = 0; i < tableDiv1; i++) {
					double x = (double)i / (double)tableDiv1;
					double x2 = x * x;
					double x3 = x2 * x;
					tempFloatWavetable[i] = (3.0 * x2) - (2.0 * x3);
				}
				
				/*  CALCULATE FALL PORTION OF WAVE TABLE  */
				for (i = tableDiv1, j = 0; i < tableDiv2; i++, j++) {
					double x = (double)j / tnLength;
					tempFloatWavetable[i] = 1.0 - (x * x);
				}
				
				/*  SET CLOSED PORTION OF WAVE TABLE  */
				for (i = tableDiv2; i < TABLE_LENGTH; i++)
					tempFloatWavetable[i] = 0.0;
			


		[[NSColor lightGrayColor] set];
		bezierPath = [[NSBezierPath alloc] init];
		[bezierPath setLineWidth:1];
		//NSLog(@"Waveform value is %d %d %f", waveform, tube_getWaveformType(), myHeight);
		start.x = graphOrigin.x;
		start.y = graphOrigin.y + ((bounds.size.height - (float) GPTOP_MARGIN - (float) GPBOTTOM_MARGIN) * tube_getWaveformType() / 2)
		          + (float) (GPX_SCALE_FACTOR/(tube_getWaveformType() + 1) * tempFloatWavetable[0]);
		//NSLog(@"Waveform value after set start is %d %d, start (x,y) %f %f, height %f", waveform, tube_getWaveformType(), start.x, start.y, myHeight);
		[bezierPath moveToPoint:start];
		//NSLog(@"The wave table value at index 100 is %f", tempFloatWavetable[100]);
		for (index = 1; index < 512; index++) {
			currentPoint.x = graphOrigin.x + ((float) index) * (bounds.size.width - graphOrigin.x - (float) GPLEFT_MARGIN - (float) GPRIGHT_MARGIN )/512;
			currentPoint.y = graphOrigin.y + ((bounds.size.height - (float) GPTOP_MARGIN - (float) GPBOTTOM_MARGIN) * tube_getWaveformType() / 2)
			                 + (float) (GPX_SCALE_FACTOR/(tube_getWaveformType() + 1) * tempFloatWavetable[index]);
			[bezierPath lineToPoint:currentPoint];
		}

		[bezierPath stroke];
		[bezierPath release];

		for (i = 0; i < 512; i++)  {  // move current data to transform buffer
			tempFloatWavetable[i] = tube_getWavetable(i);
		}
		
		//NSLog(@" Graph origin is %f %f, height %f %f", graphOrigin.x, graphOrigin.y, bounds.size.height, myHeight);
		[[NSColor blackColor] set];
		bezierPath = [[NSBezierPath alloc] init];
		[bezierPath setLineWidth:1];
		//NSLog(@"Waveform value is %d %d %f", waveform, tube_getWaveformType(), myHeight);
		start.x = graphOrigin.x;
		start.y = graphOrigin.y + ((bounds.size.height - (float) GPTOP_MARGIN - (float) GPBOTTOM_MARGIN) * tube_getWaveformType() / 2)
		          + (float) (GPX_SCALE_FACTOR/(tube_getWaveformType() + 1) * tempFloatWavetable[0]);
		//NSLog(@"Waveform value after set start is %d %d, start (x,y) %f %f, height %f", tube_getWaveformType(), tube_getWaveformType(), start.x, start.y, myHeight);
		[bezierPath moveToPoint:start];
		//NSLog(@"The wave table value at index 100 is %f", tempFloatWavetable[100]);
		for (index = 1; index < 512; index++) {
			currentPoint.x = graphOrigin.x + ((float) index) * (bounds.size.width - graphOrigin.x - (float) GPLEFT_MARGIN - (float) GPRIGHT_MARGIN )/512;
			currentPoint.y = graphOrigin.y + ((bounds.size.height - (float) GPTOP_MARGIN - (float) GPBOTTOM_MARGIN) * tube_getWaveformType() / 2)
			                 + (float) (GPX_SCALE_FACTOR/(tube_getWaveformType() + 1) * tempFloatWavetable[index]);
			[bezierPath lineToPoint:currentPoint];
		}
		
		[bezierPath stroke];
		[bezierPath release];
		free(tempFloatWavetable);
		
		bezierPath = [[NSBezierPath alloc] init];
		
		[[NSColor lightGrayColor] set];
		
		[bezierPath setLineWidth:1];
		
		// Set up Tp grid line
		
		currentPoint.x = graphOrigin.x + tube_getTp() * (bounds.size.width - graphOrigin.x - GPLEFT_MARGIN - GPRIGHT_MARGIN)/100;
		currentPoint.y = graphOrigin.y + bounds.size.height - (float) GPTOP_MARGIN - (float) GPBOTTOM_MARGIN;
        [bezierPath moveToPoint:currentPoint];
		
        currentPoint.y = graphOrigin.y;
        [bezierPath lineToPoint:currentPoint];
		NSLog(@"Done Tp grid line");
		
		// Set up TnMin line
		
		currentPoint.x = graphOrigin.x + (tube_getTp() + tube_getTnMin()) * (bounds.size.width - graphOrigin.x - GPLEFT_MARGIN - GPRIGHT_MARGIN)/100;
		currentPoint.y = graphOrigin.y + bounds.size.height - (float) GPTOP_MARGIN - (float) GPBOTTOM_MARGIN;
        [bezierPath moveToPoint:currentPoint];
		
        currentPoint.y = graphOrigin.y;
        [bezierPath lineToPoint:currentPoint];
		
		// Set up TnMax line
		
		float tn =  tube_getTnMax() - tube_getTnMin();
		
		currentPoint.x = graphOrigin.x + (tube_getTp() + tube_getTnMin() + tn) * (bounds.size.width - graphOrigin.x - GPLEFT_MARGIN - GPRIGHT_MARGIN)/100;
		currentPoint.y = graphOrigin.y + bounds.size.height - (float) GPTOP_MARGIN - (float) GPBOTTOM_MARGIN;
        [bezierPath moveToPoint:currentPoint];
		
        currentPoint.y = graphOrigin.y;
        [bezierPath lineToPoint:currentPoint];
		
		
		[bezierPath stroke];
		[bezierPath release];
		//NSLog(@"Leaving GPPV: drawGlottalPulseAmplitude");
		
	}
	
	
}


- (void)drawGlottalPulseAmplitude


{
	
	[self setNeedsDisplay:YES];	
	
}




@end
