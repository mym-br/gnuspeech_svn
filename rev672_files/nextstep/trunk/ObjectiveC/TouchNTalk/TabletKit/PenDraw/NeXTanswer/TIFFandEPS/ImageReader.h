/* ImageReader.h
 *  Purpose: The application delegate.  This class reads in and saves out EPS
 * and TIFF images.
 *
 *  You may freely copy, distribute, and reuse the code in this example.
 *  NeXT disclaims any warranty of any kind, expressed or  implied, as to its fitness
 *  for any particular use.
 *
 */

#import <appkit/appkit.h>

@interface ImageReader:Object
{
    id saveReq;  	         /* save panel */
    id accessoryWindow;  /* accessory view for save panel */
    id formatMatrix;		 /* EPS/TIFF selection in save panel */
    id	DPIpopup, DPIvalue;  /* items in the save panel */
    						  /* related to TIFF resolution */
    id compressionType;	 /* JPEG vs LZW compression */
    id JPEGlabel;		 /* JPEG factor label */
    id JPEGvalue;		 /* JPEG compression factor */
}

/* Class methods */

/* Instance methods */
- openRequest:sender;
- saveRequest:sender;
- selectFormat:sender;
- selectCompression:sender;
- (BOOL)openFile:(const char *)fileName;
- (BOOL)saveTIFF: (const char *)fileName inWindow: window;
- (BOOL)saveEPS: (const char *)fileName  inWindow:window;

/* File extensions for files that can be read in and saved out */
const char *epsType = "eps";
const char *tiffType = "tiff";

#define POINTSPERINCH	72.0

/* These integers refer to the column number in the image format matrix */
/* for the accessory view of the save panel.  This refers to the format of */
/* the saved image only.  */
#define TIFF_FORMAT		0
#define EPS_FORMAT		1

/* These integers refer to the column number in the DPI radio button matrix */
/* that these buttons specify.  */
#define DPI_72		0
#define DPI_144		1
#define DPI_OTHER	2

/* These integers refer to the column number in the Compression radio */
/* button matrix that these buttons specify. */
#define LZW_COMPRESSION	0
#define JPEG_COMPRESSION	1

@end
