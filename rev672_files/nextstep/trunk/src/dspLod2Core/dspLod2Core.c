/*  REVISION INFORMATION  *****************************************************

$Author: rao $
$Date: 2002-03-21 16:49:54 $
$Revision: 1.1 $
$Source: /Users/dalmazio/cvsroot/gnuspeech/trillium/src/dspLod2Core/dspLod2Core.c,v $
$State: Exp $


$Log: not supported by cvs2svn $
 * Revision 1.1.1.1  1995/01/09  22:41:42  len
 * Initial archive of dspLod2Core.
 *

******************************************************************************/

/******************************************************************************
*
*     dspLod2Core.c
*     
*     This program converts the DSP code contained in the .lod file (output
*     from the dsp assembler) to a printable form in a header file suitable
*     for inclusion by c programs.  This output header file declares a static
*     array of bytes, which represents SNDSoundStruct, which can be loaded
*     by the SNDBootDSP system function (or substitute for Intel systems).
*
******************************************************************************/



/*  HEADER FILES  ************************************************************/
#import <sound/sound.h>
#import <sound/sounddriver.h>
#import <dsp/dsp.h>
#import <stdlib.h>


/*  LOCAL DEFINES  ***********************************************************/
#define OUTPUTFILE_NAME_DEF   "dspcore.h"
#define COLUMNS_DEF           12
#define SUCCESS               0
#define FAILURE               (-1)


/*  GLOBAL VARIABLES (LOCAL TO THIS FILE)  ***********************************/
static FILE *fp;
static char *inputFile, outputFile[MAXPATHLEN+1];
static int columns = COLUMNS_DEF;
static int headerSize, dataSize, totalSize;
static int currentColumn, currentByte;


/*  GLOBAL FUNCTIONS (LOCAL TO THIS FILE)  ***********************************/
static int translate(SNDSoundStruct *dspStruct);
static int translateHeader(SNDSoundStruct *dspStruct);
static int translateData(SNDSoundStruct *dspStruct);
static int translateInt(int value);
static int formatByte(char byte);




/******************************************************************************
*
*	function:	main
*
*	purpose:	Controls overall execution of the program.
*                       
*       arguments:      argc - number of command line arguments
*                       argv[0] - program name
*                       argv[1] - input file name
*                       argv[2] - output file name (optional)
*                       
*	internal
*	functions:	translate
*
*	library
*	functions:	fprintf, exit, strcpy, SNDReadDSPfile, fopen, fclose
*
******************************************************************************/

void main(int argc, char *argv[])
{
    int s_err;
    SNDSoundStruct *dspStruct;
    FILE *fopen();


    /*  MAKE SURE RIGHT NUMBER OF ARGUMENTS  */
    if ((argc < 2) || (argc > 3)) {
	fprintf(stderr,"Usage:  dspLod2Core infile.lod [outfile.h]\n");
	exit(FAILURE);
    }

    /*  MAKE INPUT FILE NAME GLOBALLY AVAILABLE  */
    inputFile = argv[1];

    /*  SUPPLY DEFAULT OUTPUT FILE NAME, IF NONE GIVEN  */
    if (argc == 2)
        strcpy(outputFile, OUTPUTFILE_NAME_DEF);
    else
        strcpy(outputFile, argv[2]);

    /*  PARSE THE .LOD ASSEMBLY FILE AND PUT INTO STRUCT  */
    s_err = SNDReadDSPfile(inputFile, &dspStruct, NULL);
    if (s_err != SND_ERR_NONE) {
	fprintf(stderr, "Cannot find or parse %s: %s\n",
		inputFile, SNDSoundError(s_err));
	exit(FAILURE);
    }

    /*  OPEN THE OUTPUT FILE  */
    fp = fopen(outputFile, "w");
    if (fp == NULL) {
        fprintf(stderr, "Cannot open %s for writing\n", outputFile);
	exit(FAILURE);
    }

    /*  TRANSLATE THE DSPSTRUCT, AND WRITE INTO OUTPUT FILE  */
    s_err = translate(dspStruct);
    if (s_err) {
        fprintf(stderr, "Error translating %s\n", inputFile);
	exit(FAILURE);
    }

    /*  CLOSE THE OUTPUT FILE  */
    fclose(fp);
}



/******************************************************************************
*
*	function:	translate
*
*	purpose:	Translates the SNDSoundStruct containing the DSP
*                       memory core file into printed format.
*			
*       arguments:      dspStruct - the SNDSoundStruct to be translated
*                       
*	internal
*	functions:	translateHeader, translateData
*
*	library
*	functions:	fprintf
*
******************************************************************************/

static int translate(SNDSoundStruct *dspStruct)
{
    /*  SET THE COLUMN AND BYTE COUNTS TO INITIAL VALUES  */
    currentColumn = 1;
    currentByte = 1;

    /*  FIND HEADER SIZE, DATASIZE, AND TOTAL SIZE OF THE DSP CORE OBJECT  */
    headerSize = dspStruct->dataLocation;
    dataSize = dspStruct->dataSize;
    totalSize = headerSize + dataSize;

    /*  WRITE OUT FILE INFORMATION  */
    fprintf(fp, "/*\n");
    fprintf(fp, " *   Include file:  %s\n", outputFile);
    fprintf(fp, " *   Created by dspLod2Core from %s\n", inputFile);
    fprintf(fp, " */\n\n");

    /*  WRITE OUT C DECLARATION  */
    fprintf(fp, "static char dspcore[%-d] = {\n", totalSize);

    /*  WRITE OUT HEADER  */
    translateHeader(dspStruct);

    /*  WRITE OUT DSP CORE DATA  */
    translateData(dspStruct);

    /*  WRITE OUT END OF STRUCT  */
    fprintf(fp, "};\n");
    
    return(SUCCESS);
}



/******************************************************************************
*
*	function:	translateHeader
*
*	purpose:	Prints the header in the SNDSoundStruct to file.
*                       Note that "endian" conversion of integer values
*                       are performed when necessary.
*			
*       arguments:      dspStruct - the SNDSoundStruct being translated
*                       
*	internal
*	functions:	NXSwapHostIntToBig
*
*	library
*	functions:	translateInt, formatByte
*
******************************************************************************/

static int translateHeader(SNDSoundStruct *dspStruct)
{
    int i, *intPtr;
    char *bytePtr;


    /*  SET THE INTEGER POINTER TO THE START OF THE DSP STRUCT  */
    intPtr = (int *)dspStruct;
    
    /*  STRUCT STARTS WITH SIX INTEGERS  */
    for (i = 0; i < 6; i++, intPtr++)
        translateInt(NXSwapHostIntToBig(*intPtr));

    /*  SET BYTE POINTER TO START OF INFO STRING  */
    bytePtr = (char *)&(dspStruct->info);

    /*  REMAINDER OF HEADER IS CHARACTER INFORMATION  */
    for (i = 24; i < headerSize; i++, bytePtr++)
        formatByte(*bytePtr);

    return(SUCCESS);
}



/******************************************************************************
*
*	function:	translateData
*
*	purpose:	Prints the DSP code contained in the data portion of
*                       the SNDSoundStruct to file.  Note that "endian"
*                       conversion of integer values are performed if
*                       necessary.
*
*       arguments:      dspStruct - the SNDSoundStruct being translated
*                       
*	internal
*	functions:	translateInt
*
*	library
*	functions:	NXSwapHostIntToBig
*
******************************************************************************/

static int translateData(SNDSoundStruct *dspStruct)
{
    int numberInstructions, i, *intPtr;


    /*  CALCULATE NUMBER OF DSP INSTRUCTIONS  */
    numberInstructions = dataSize / 4;

    /*  SET THE INTEGER POINTER TO THE START OF THE DATA SEGMENT  */
    intPtr = (int *)((char *)dspStruct + headerSize);

    /*  DATA CONSISTS OF DSP INSTRUCTIONS PACKED IN 4 BYTE INTEGERS  */
    for (i = 0; i < numberInstructions; i++, intPtr++)
        translateInt(NXSwapHostIntToBig(*intPtr));

    return(SUCCESS);
}



/******************************************************************************
*
*	function:	translateInt
*
*	purpose:	Prints the integer value to file.
*			
*       arguments:      value - the integer to be printed
*                       
*	internal
*	functions:	formatByte
*
*	library
*	functions:	none
*
******************************************************************************/

static int translateInt(int value)
{
    int i;
    char *bytePtr = (char *)&value;


    /*  FORMAT EACH BYTE OF THE INTEGER, IN LEFT-TO-RIGHT ORDER  */
    for (i = 0; i < 4; i++, bytePtr++) {
        formatByte(*bytePtr);
    }

    return(SUCCESS);
}



/******************************************************************************
*
*	function:	formatByte
*
*	purpose:	Prints the byte value to file, doing all necessary
*                       formatting.
*			
*       arguments:      byte - the byte value to be printed
*                       
*	internal
*	functions:	
*
*	library
*	functions:	fprintf, 
*
******************************************************************************/

static int formatByte(char byte)
{
    /*  PRINT THE BYTE OUT TO FILE  */
    fprintf(fp, "0x%02X", (int)byte & 0x000000FF);

    /*  ADD A COMMA, UNLESS AT END  */
    if (currentByte != totalSize) {
        fprintf(fp, ",");

	/*  ADD A SPACE EVERY 4 COLUMNS, EXCEPT AFTER LAST COLUMN  */
	if ((currentColumn != columns) && !(currentColumn % 4))
	    fprintf(fp, " ");
    }

    /*  IF LAST COLUMN, ADD A NEWLINE CHARACTER, AND MOD COLUMN COUNT  */
    if (currentColumn == columns) {
        fprintf(fp, "\n");
	currentColumn = 0;
    }

    /*  INCREMENT THE BYTE AND COLUMN COUNT  */
    currentByte++;
    currentColumn++;

    return(SUCCESS);
}
