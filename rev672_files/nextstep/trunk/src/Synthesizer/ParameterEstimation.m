/*  REVISION INFORMATION  *****************************************************

$Author: fedor $
$Date: 2003-01-18 05:04:50 $
$Revision: 1.2 $
$Source: /Users/dalmazio/cvsroot/gnuspeech/trillium/src/Synthesizer/ParameterEstimation.m,v $
$State: Exp $


$Log: not supported by cvs2svn $
Revision 1.1  2002/03/21 16:49:54  rao
Initial import.


******************************************************************************/



/*  HEADER FILES  ************************************************************/
#import "ParameterEstimation.h"



/*  LOCAL DEFINES  ***********************************************************/
#define RADIUS_MIN           0.0
#define RADIUS_MAX           3.0

#define RADIUS_MIN_DEF       RADIUS_MIN
#define RADIUS_MAX_DEF       RADIUS_MAX

#define RADIUS_FIXED_DEF     NO

#define TARGET_F1_MIN        100.0
#define TARGET_F1_MAX        1000.0
#define TARGET_F1_DEF        500.0

#define TARGET_F2_MIN        400.0
#define TARGET_F2_MAX        3000.0
#define TARGET_F2_DEF        1500.0

#define TARGET_F3_MIN        1000.0
#define TARGET_F3_MAX        4000.0
#define TARGET_F3_DEF        2500.0

#define MAX_INTERATIONS_MIN  0
#define MAX_INTERATIONS_MAX  1000
#define MAX_INTERATIONS_DEF  100

#define CONVERGENCE_MIN      1.0
#define CONVERGENCE_MAX      99.0
#define CONVERGENCE_DEF      50.0

#define ERROR_MIN            1.0
#define ERROR_MAX            100.0
#define ERROR_DEF            5.0

#define ST_START_MIN         20.0
#define ST_START_MAX         (TARGET_F1_MIN - 10.0)
#define ST_START_DEF         (TARGET_F1_MIN - 10.0)

#define ST_END_MIN           (TARGET_F3_MAX + 10.0)
#define ST_END_MAX           5000.0
#define ST_END_DEF           (TARGET_F3_MAX + 10.0)

#define ST_INC_MIN           (ERROR_MIN/2.0)
#define ST_INC_MAX           (ERROR_MAX/2.0)
#define ST_INC_DEF           (ERROR_DEF/2.0)

#define F1                   0
#define F2                   1
#define F3                   2

#define FORMANT_CURRENT      0
#define FORMANT_ERROR        1

#define ESTIMATION_FIELDS    3
#define ITERATIONS           0
#define CONVERGENCE          1
#define ERROR                2

#define ST_FIELDS            3
#define ST_START             0
#define ST_END               1
#define ST_INC               2



@implementation ParameterEstimation

- init
{
    /*  DO REGULAR INITIALIZATION  */
    [super init];

    /*  SET DEFAULT INSTANCE VARIABLES  */
    [self defaultInstanceVariables];

    return self;
}



- (void)dealloc
{
    /*  DO REGULAR FREE  */
    { [super dealloc]; return; };
}



- (void)defaultInstanceVariables
{
    int i;

    /*  SET DEFAULTS  */
    for (i = 0; i < NUMBER_RADII; i++) {
	radius[MINIMUM][i] = RADIUS_MIN_DEF;
	radius[MAXIMUM][i] = RADIUS_MAX_DEF;
	radiusFixed[i] = RADIUS_FIXED_DEF;
    }
    radiusFixed[0] = YES;

    formantTarget[0] = TARGET_F1_DEF;
    formantTarget[1] = TARGET_F2_DEF;
    formantTarget[2] = TARGET_F3_DEF;

    maximumIterations = MAX_INTERATIONS_DEF;
    convergence = CONVERGENCE_DEF;
    allowableError = ERROR_DEF;
    sweepToneStart = ST_START_DEF;
    sweepToneEnd = ST_END_DEF;
    sweepToneIncrement = ST_INC_DEF; 
}



- (void)awakeFromNib
{
    NSArray *list;
    int i;

    /*  USE OPTIMIZED DRAWING IN THE WINDOW  */
    [parameterEstimationWindow useOptimizedDrawing:YES];

    /*  SAVE THE FRAME FOR THE WINDOW  */
    [parameterEstimationWindow setFrameAutosaveName:@"estimationWindow"];

    /*  SET FORMAT OF FIELDS  */
    list = [radiiMatrix cells];
    for (i = 0; i < [list count]; i++)
	[[list objectAtIndex:i] setFloatingPointFormat:NO left:2 right:2];

    list = [targetMatrix cells];
    for (i = 0; i < [list count]; i++)
	[[list objectAtIndex:i] setFloatingPointFormat:NO left:4 right:1];

    list = [formantMatrix cells];
    for (i = 0; i < [list count]; i++)
	[[list objectAtIndex:i] setFloatingPointFormat:NO left:4 right:1];

    list = [estimationForm cells];
    [[list objectAtIndex:0] setFloatingPointFormat:NO left:3 right:0];
    for (i = 1; i < [list count]; i++)
	[[list objectAtIndex:i] setFloatingPointFormat:NO left:3 right:1];

    list = [sweepToneForm cells];
    for (i = 0; i < [list count]; i++)
	[[list objectAtIndex:i] setFloatingPointFormat:NO left:4 right:1];
}



- (void)displayAndSynthesizeIvars
{
    int i;


    /*  DISPLAY RADII MINIMUM, MAXIMUM AND FIXED VALUES  */
    for (i = 0; i < NUMBER_RADII; i++) {
	[[radiiMatrix cellAtRow:MINIMUM column:i] setFloatValue:radius[MINIMUM][i]];
	[[radiiMatrix cellAtRow:MAXIMUM column:i] setFloatValue:radius[MAXIMUM][i]];
	[[fixedMatrix cellAtRow:0 column:i] setIntValue:radiusFixed[i]];
    }

    /*  DISPLAY FORMANT TARGET VALUES  */
    for (i = 0; i < NUMBER_FORMANTS; i++)
	[[targetMatrix cellAtRow:0 column:i] setFloatValue:formantTarget[i]];

    /*  DISPLAY ESTIMATION VALUES  */
    [[estimationForm cellAtIndex:ITERATIONS] setIntValue:maximumIterations];
    [[estimationForm cellAtIndex:CONVERGENCE] setFloatValue:convergence];
    [[estimationForm cellAtIndex:ERROR] setFloatValue:allowableError];

    /*  DISPLAY SWEEP TONE VALUES  */
    [[sweepToneForm cellAtIndex:ST_START] setFloatValue:sweepToneStart];
    [[sweepToneForm cellAtIndex:ST_END] setFloatValue:sweepToneEnd];
    [[sweepToneForm cellAtIndex:ST_INC] setFloatValue:sweepToneIncrement];

    /*  BLANK OUT OTHER DISPLAYS  */
    for (i = 0; i < NUMBER_FORMANTS; i++) {
	[[formantMatrix cellAtRow:FORMANT_CURRENT column:i] setStringValue:@""];
	[[formantMatrix cellAtRow:FORMANT_ERROR column:i] setStringValue:@""];
    }
    [iterationField setStringValue:@""];


    /*  DISPLAY CHANGES TO SUBVIEWS OF WINDOW  */
    [parameterEstimationWindow displayIfNeeded]; 
}



- (void)windowWillMiniaturize:sender
{
    [sender setMiniwindowImage:[NSImage imageNamed:@"Synthesizer.tiff"]];
}



- (void)saveToStream:(NSArchiver *)typedStream
{
    /*  WRITE INSTANCE VARIABLES TO TYPED STREAM  */
    [typedStream encodeArrayOfObjCType:"f" count:(2 * NUMBER_RADII) at:radius];
    [typedStream encodeArrayOfObjCType:"c" count:NUMBER_RADII at:radiusFixed];
    [typedStream encodeArrayOfObjCType:"f" count:NUMBER_FORMANTS at:formantTarget];
    [typedStream encodeValuesOfObjCTypes:"ifffff", &maximumIterations,
		 &convergence, &allowableError, &sweepToneStart,
		 &sweepToneEnd, &sweepToneIncrement]; 
}



- (void)openFromStream:(NSArchiver *)typedStream
{
    /*  READ INSTANCE VARIABLES FROM TYPED STREAM  */
    [typedStream decodeArrayOfObjCType:"f" count:(2 * NUMBER_RADII) at:radius];
    [typedStream decodeArrayOfObjCType:"c" count:NUMBER_RADII at:radiusFixed];
    [typedStream decodeArrayOfObjCType:"f" count:NUMBER_FORMANTS at:formantTarget];
    [typedStream decodeValuesOfObjCTypes:"ifffff", &maximumIterations,
		&convergence, &allowableError, &sweepToneStart,
		&sweepToneEnd, &sweepToneIncrement];

    /*  DISPLAY THE NEW VALUES  */
    [self displayAndSynthesizeIvars]; 
}

#ifdef NeXT
- (void)_openFromStream:(NXTypedStream *)typedStream
{
    /*  READ INSTANCE VARIABLES FROM TYPED STREAM  */
    NXReadArray(typedStream, "f", (2 * NUMBER_RADII), radius);
    NXReadArray(typedStream, "c", NUMBER_RADII, radiusFixed);
    NXReadArray(typedStream, "f", NUMBER_FORMANTS, formantTarget);
    NXReadTypes(typedStream, "ifffff", &maximumIterations,
		&convergence, &allowableError, &sweepToneStart,
		&sweepToneEnd, &sweepToneIncrement);

    /*  DISPLAY THE NEW VALUES  */
    [self displayAndSynthesizeIvars]; 
}
#endif




- (void)setRunning:(BOOL)flag
{
    /*  ENABLE/DISABLE ESTIMATION BUTTON, ACCORDING TO STATE  */
    if (flag)
	[estimationButton setEnabled:NO];
    else
	[estimationButton setEnabled:YES]; 
}



- (void)estimationButtonPushed:sender
{
     
}



- (void)estimationFormEntered:sender
{
    int row;
    BOOL rangeError = NO;
    float value;

    /*  GET THE CURRENT VALUE OF THE TEXT FIELD  */
    value = [sender floatValue];

    /*  GET ROW NUMBER OF TEXT CELL  */
    row = [sender selectedRow];

    /*  CORRECT OUT-OF-RANGE VALUES  */
    if (row == ITERATIONS) {
	if (value < MAX_INTERATIONS_MIN) {
	    value = MAX_INTERATIONS_MIN;
	    rangeError = YES;
	}
	else if (value > MAX_INTERATIONS_MAX) {
	    value = MAX_INTERATIONS_MAX;
	    rangeError = YES;
	}
	/*  STORE VALUE IN INSTANCE VARIABLE  */
	maximumIterations = (int)value;
    }
    else if (row == CONVERGENCE) {
	if (value < CONVERGENCE_MIN) {
	    value = CONVERGENCE_MIN;
	    rangeError = YES;
	}
	else if (value > CONVERGENCE_MAX) {
	    value = CONVERGENCE_MAX;
	    rangeError = YES;
	}
	/*  STORE VALUE IN INSTANCE VARIABLE  */
	convergence = value;
    }
    else if (row == ERROR) {
	if (value < ERROR_MIN) {
	    value = ERROR_MIN;
	    rangeError = YES;
	}
	else if (value > ERROR_MAX) {
	    value = ERROR_MAX;
	    rangeError = YES;
	}
	/*  STORE VALUE IN INSTANCE VARIABLE  */
	allowableError = value;
    }

    /*  IF RANGE ERROR, BEEP & SELECT THE OUT OF RANGE CELL  */
    if (rangeError) {
	NSBeep();
	if (row == ITERATIONS)
	    [[sender selectedCell] setIntValue:(int)value];
	else
	    [[sender selectedCell] setFloatValue:value];
	[sender selectTextAtIndex:row];
    }
    /*  ELSE, SELECT THE CELL IN THE NEXT ROW OR COLUMN  */
    else {
	if (++row >= ESTIMATION_FIELDS)
	    [sweepToneForm selectTextAtIndex:0];
	else
	    [sender selectTextAtIndex:row];
    } 
}



- (void)radiiMatrixEntered:sender
{
    int column, row;
    BOOL rangeError = NO;
    float value;

    /*  GET THE CURRENT VALUE OF THE TEXT FIELD  */
    value = [sender floatValue];

    /*  GET ROW AND COLUMN NUMBERS OF TEXT CELL  */
    column = [sender selectedColumn];
    row = [sender selectedRow];

    /*  CORRECT OUT-OF-RANGE VALUES  */
    if (row == MINIMUM) {
	if (value < RADIUS_MIN) {
	    value = RADIUS_MIN;
	    rangeError = YES;
	}
	else if (value > radius[MAXIMUM][column]) {
	    value = radius[MAXIMUM][column];
	    rangeError = YES;
	}
    }
    else {
	if (value < radius[MINIMUM][column]) {
	    value = radius[MINIMUM][column];
	    rangeError = YES;
	}
	else if (value > RADIUS_MAX) {
	    value = RADIUS_MAX;
	    rangeError = YES;
	}
    }

    /*  SET THE VALUE OF THE INSTANCE VARIABLE  */
    radius[row][column] = value;

    /*  IF RANGE ERROR, BEEP & SELECT THE OUT OF RANGE CELL  */
    if (rangeError) {
	NSBeep();
	[[sender selectedCell] setFloatValue:value];
	[sender selectTextAtRow:row column:column];
    }
    /*  ELSE, SELECT THE CELL IN THE NEXT ROW OR COLUMN  */
    else {
	if (row == 0)
	    [sender selectTextAtRow:1 column:column];
	else {
	    if (++column >= NUMBER_RADII)
		[targetMatrix selectTextAtRow:0 column:0];
	    else
		[sender selectTextAtRow:0 column:column];
	}
    } 
}



- (void)fixedMatrixEntered:sender
{
    /*  SET THE VALUE OF THE INSTANCE VARIABLE  */
    radiusFixed[[sender selectedColumn]] = [[sender selectedCell] state]; 
}



- (void)sweepToneFormEntered:sender
{
    int row;
    BOOL rangeError = NO;
    float value;

    /*  GET THE CURRENT VALUE OF THE TEXT FIELD  */
    value = [sender floatValue];

    /*  GET ROW NUMBER OF TEXT CELL  */
    row = [sender selectedRow];

    /*  CORRECT OUT-OF-RANGE VALUES  */
    if (row == ST_START) {
	if (value < ST_START_MIN) {
	    value = ST_START_MIN;
	    rangeError = YES;
	}
	else if (value > ST_START_MAX) {
	    value = ST_START_MAX;
	    rangeError = YES;
	}
	/*  STORE VALUE IN INSTANCE VARIABLE  */
	sweepToneStart = value;
    }
    else if (row == ST_END) {
	if (value < ST_END_MIN) {
	    value = ST_END_MIN;
	    rangeError = YES;
	}
	else if (value > ST_END_MAX) {
	    value = ST_END_MAX;
	    rangeError = YES;
	}
	/*  STORE VALUE IN INSTANCE VARIABLE  */
	sweepToneEnd = value;
    }
    else if (row == ST_INC) {
	if (value < ST_INC_MIN) {
	    value = ST_INC_MIN;
	    rangeError = YES;
	}
	else if (value > ST_INC_MAX) {
	    value = ST_INC_MAX;
	    rangeError = YES;
	}
	/*  STORE VALUE IN INSTANCE VARIABLE  */
	sweepToneIncrement = value;
    }

    /*  IF RANGE ERROR, BEEP & SELECT THE OUT OF RANGE CELL  */
    if (rangeError) {
	NSBeep();
	[[sender selectedCell] setFloatValue:value];
	[sender selectTextAtIndex:row];
    }
    /*  ELSE, SELECT THE CELL IN THE NEXT ROW OR COLUMN  */
    else {
	if (++row >= ST_FIELDS)
	    [radiiMatrix selectTextAtRow:0 column:0];
	else
	    [sender selectTextAtIndex:row];
    } 
}



- (void)targetMatrixEntered:sender
{
    int column;
    BOOL rangeError = NO;
    float value;

    /*  GET THE CURRENT VALUE OF THE TEXT FIELD  */
    value = [sender floatValue];

    /*  GET ROW AND COLUMN NUMBERS OF TEXT CELL  */
    column = [sender selectedColumn];

    /*  CORRECT OUT-OF-RANGE VALUES  */
    if (column == F1) {
	if (value < TARGET_F1_MIN) {
	    value = TARGET_F1_MIN;
	    rangeError = YES;
	}
	else if (value > TARGET_F1_MAX) {
	    value = TARGET_F1_MAX;
	    rangeError = YES;
	}
	/*  MAKE SURE F1 DOESN'T GET TO CLOSE TO F2  */
	if (value > (formantTarget[F2] - 100.0)) {
	    value = formantTarget[F2] - 100.0;
	    rangeError = YES;
	}
    }
    else if (column == F2) {
	if (value < TARGET_F2_MIN) {
	    value = TARGET_F2_MIN;
	    rangeError = YES;
	}
	else if (value > TARGET_F2_MAX) {
	    value = TARGET_F2_MAX;
	    rangeError = YES;
	}
	/*  MAKE SURE F2 DOESN'T GET TO CLOSE TO F1 OR F3  */
	if (value < (formantTarget[F1] + 100.0)) {
	    value = formantTarget[F1] + 100.0;
	    rangeError = YES;
	}
	if (value > (formantTarget[F3] - 100.0)) {
	    value = formantTarget[F3] - 100.0;
	    rangeError = YES;
	}
    }
    else if (column == F3) {
	if (value < TARGET_F3_MIN) {
	    value = TARGET_F3_MIN;
	    rangeError = YES;
	}
	else if (value > TARGET_F3_MAX) {
	    value = TARGET_F3_MAX;
	    rangeError = YES;
	}
	/*  MAKE SURE F3 DOESN'T GET TO CLOSE TO F2  */
	if (value < (formantTarget[F2] + 100.0)) {
	    value = formantTarget[F2] + 100.0;
	    rangeError = YES;
	}
    }

    /*  SET THE VALUE OF THE INSTANCE VARIABLE  */
    formantTarget[column] = value;

    /*  IF RANGE ERROR, BEEP & SELECT THE OUT OF RANGE CELL  */
    if (rangeError) {
	NSBeep();
	[[sender selectedCell] setFloatValue:value];
	[sender selectTextAtRow:0 column:column];
    }
    /*  ELSE, SELECT THE CELL IN THE NEXT ROW OR COLUMN  */
    else {
	if (++column >= NUMBER_FORMANTS)
	    [estimationForm selectTextAtIndex:0];
	else
	    [sender selectTextAtRow:0 column:column];
    } 
}


@end
