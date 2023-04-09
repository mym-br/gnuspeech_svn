/*  HEADER FILES  ************************************************************/
#import "PositionView.h"
#import <AppKit/NSGraphicsContext.h>


/*  LOCAL DEFINES  ***********************************************************/
#define SECTION_WIDTH    41.0
#define MARGIN           4.0
#define COMBINED_WIDTH   (SECTION_WIDTH + MARGIN)
#define OFFSET           (SECTION_WIDTH / 2.0)
#define INTERSECTION     (1.75/7.0)


@implementation PositionView

- initWithFrame:(NSRect)frameRect
{
    void getAppDirectory();
    char filename[MAXPATHLEN+1];

    /*  DO REGULAR INITIALIZATION  */
    [super initWithFrame:frameRect];

    /*  ALLOCATE NXIMAGE  */
    background =
	[[NSImage allocWithZone:[self zone]] initWithSize:(frameRect.size)];

    /*  FIND APPLICATION DIRECTORY PATH NAME  */
    getAppDirectory(filename);

    /*  APPEND TIFF FILENAME  */
    strcat(filename, "/downArrow.tiff");

    /*  ALLOCATE SPACE FOR TIFF IMAGE OF ARROW  */
    arrow = [[NSImage allocWithZone:[self zone]] init];
    [arrow addRepresentations:[NSImageRep imageRepsWithContentsOfFile:[NSString stringWithCString:filename]]];

    /*  GET THE SIZE OF THE ARROW IMAGE  */
    arrowSize = [arrow size];

    /*  CALCULATE SOME DRAWING CONSTANTS  */
    offset = OFFSET - (arrowSize.width / 2.0);
    arrowPosition.y = 0.0;
    
    return self;
}



- (void)dealloc
{
    /*  FREE NXIMAGES  */
    [background release];
    [arrow release];

    /*  DO REGULAR FREE  */
    { [super dealloc]; return; };
}



- (void)drawPosition:(float)position
{
    /*  CALCULATE PLACEMENT OF THE ARROW TIFF  */
    arrowPosition.x = (position * COMBINED_WIDTH) + offset;

    /*  LOCK FOCUS ON NXIMAGE  */
    [background lockFocus];

    /*  CLEAR THE NXIMAGE  */
    PSsetgray(NSLightGray);
    PSrectfill(NSMinX([self bounds]), NSMinY([self bounds]),
	       NSWidth([self bounds]), NSHeight([self bounds]));

    /*  DRAW INTERSECTING LINE  */
    PSsetgray(NSBlack);
    PSsetlinewidth(2.0);
    PSmoveto((NSMinX([self bounds]) + (INTERSECTION * NSWidth([self bounds]))) - 1.0,
	     NSMinY([self bounds]));
    PSrlineto(0.0, NSHeight([self bounds]));
    PSstroke();

    /*  DRAW ARROW  */
    [arrow compositeToPoint:arrowPosition operation:NSCompositePlusDarker];

    /*  UNLOCK FOCUS ON NXIMAGE  */
    [background unlockFocus];

    /*  DISPLAY THE BACKGROUND  */
    [self display]; 
}



- (void)drawRect:(NSRect)rects
{
    [background compositeToPoint:(rects.origin) operation:NSCompositeSourceOver];
}



/******************************************************************************
*
*	function:	getAppDirectory
*
*	purpose:	Finds the path name of the application directory.
*			
*       arguments:      appDirectory
*                       
*	internal
*	functions:	none
*
*	library
*	functions:	strcpy, rindex, sprintf, popen, fscanf, pclose,
*                       chdir, getwd
*
******************************************************************************/

void getAppDirectory (char *appDirectory)
{
    FILE *process;
    char command[256];
    char *suffix;

    strcpy(appDirectory, [[[[NSProcessInfo processInfo] arguments] objectAtIndex:0] cString]);
    /*  IF ABSOLUTE PATH REMOVE EXECUTABLE NAME  */
    if (appDirectory[0] == '/') { 
        if (suffix = rindex(appDirectory,'/')) 
            *suffix  = '\0'; 
    } else {
	sprintf(command,"which '%s'\n",[[[[NSProcessInfo processInfo] arguments] objectAtIndex:0] cString]);
	process=popen(command,"r");
	fscanf(process,"%s",appDirectory);
	pclose(process);
	/*  REMOVE EXECUTABLE NAME  */
	if (suffix = rindex(appDirectory,'/')) 
	    *suffix  = '\0'; 
	chdir(appDirectory);
	getwd(appDirectory);
    }  
}

@end
