/*  REVISION INFORMATION  *****************************************************

$Author: fedor $
$Date: 2003-01-18 05:04:50 $
$Revision: 1.2 $
$Source: /Users/dalmazio/cvsroot/gnuspeech/trillium/src/Synthesizer/ParameterEstimation.h,v $
$State: Exp $


$Log: not supported by cvs2svn $
Revision 1.1  2002/03/21 16:49:54  rao
Initial import.


******************************************************************************/



/*  HEADER FILES  ************************************************************/
#import <AppKit/AppKit.h>



/*  GLOBAL DEFINES  **********************************************************/
#define NUMBER_RADII     8
#define NUMBER_FORMANTS  3

#define MINIMUM          0
#define MAXIMUM          1



@interface ParameterEstimation:NSObject
{
    id	estimationButton;
    id	estimationForm;
    id	fixedMatrix;
    id	formantMatrix;
    id	iterationField;
    id	parameterEstimationWindow;
    id	radiiMatrix;
    id	sweepToneForm;
    id	targetMatrix;
    id  controller;

    float radius[2][NUMBER_RADII];
    BOOL radiusFixed[NUMBER_RADII];
    float formantTarget[NUMBER_FORMANTS];
    int maximumIterations;
    float convergence;
    float allowableError;
    float sweepToneStart;
    float sweepToneEnd;
    float sweepToneIncrement;
    
    int currentIteration;
    float formantCurrent[NUMBER_FORMANTS];
    float formantError[NUMBER_FORMANTS];
}

- (void)defaultInstanceVariables;
- (void)awakeFromNib;
- (void)displayAndSynthesizeIvars;

- (void)saveToStream:(NSArchiver *)typedStream;
- (void)openFromStream:(NSArchiver *)typedStream;

- (void)setRunning:(BOOL)flag;
- (void)windowWillMiniaturize:sender;

- (void)estimationButtonPushed:sender;
- (void)estimationFormEntered:sender;
- (void)radiiMatrixEntered:sender;
- (void)fixedMatrixEntered:sender;
- (void)sweepToneFormEntered:sender;
- (void)targetMatrixEntered:sender;

@end
