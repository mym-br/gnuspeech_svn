/* ImageReader.m
 *  Purpose: The application delegate.  This class reads in and saves out EPS
 * and TIFF images.
 *
 *  You may freely copy, distribute, and reuse the code in this example.
 *  NeXT disclaims any warranty of any kind, expressed or  implied, as to its fitness
 *  for any particular use.
 *
 */

#import "ImageReader.h"
#import "ImageView.h"

@implementation ImageReader : Object

/* -windowWillClose:
 * 	Window delegate method.  Called before a window is about to be
 * closed.  If the last window is being closed, dim the "Save Image..."
 * menu item.
 */
- windowWillClose:sender
{
    int cnt;
    id menu = [NXApp mainMenu];
    id matrix = [menu itemList];
    id menuCell = [matrix cellAt: 1:0];  /* Location of the "Save..." menu item */
   
    /* The minimum window count for this app is 2 when there */
    /* are no open TIFF/EPS windows -- if 3 or more windows are */
    /* open, then the "Save Image..." menu item should be enabled. */
    NXCountWindows(&cnt);
    if (cnt <= 3)
    	[menuCell setEnabled: NO];
    return self;
}

/* -windowDidBecomeMain:
 * 	Window delegate method.  Called after the window has become main.
 * The theory being if any main windows exist, then enable the "Save Image..."
 * menu item.
 */
- windowDidBecomeMain:sender
{
    id menu = [NXApp mainMenu];
    id matrix = [menu itemList];
    id menuCell = [matrix cellAt: 1:0];

    [menuCell setEnabled:YES];
    return self;
}

/* -appDidInit:
 * 	Application delegate method.  Called after application has been initialized 
 * and before any events are received.   
 */
- appDidInit:sender
{
    /* Ensure that a required file type has been set for the */
    /* save panel.  Also initializes the save panel instance */
    /* variable */
    saveReq = [SavePanel new];
    [saveReq setRequiredFileType: tiffType];
    
    /* The default TIFF compression is LZW.  Disable JPEG */
    /* factor text field. */
    [JPEGvalue setEnabled:NO];
    return self;
}

/*  - openRequest:
 * 	Called when the user selects "Open Image..." from the menu.  Both EPS 
 * and TIFF images are supported.
 */
- openRequest:sender
{
    id 			openReq;
    const char	*fileName;
    const char	*const fileTypes[] = {tiffType, epsType, NULL};  
    
    openReq = [OpenPanel new];
    if ([openReq runModalForTypes:fileTypes] && (fileName =[openReq filename])) 
    {
	[self openFile:fileName];
    }
    return self;
}

/* -openFile:
 * 	Does the work of creating a window exactly the size of the image [tiff or eps].  
 * Then creates an instance of ImageView and replaces the contentView of the 
 * window with the ImageView instance.
 */
-(BOOL) openFile:(const char *)fileName
{
    id  anImage, window, view;
    NXRect	rect;
    char title[100], *name;
    
    /* Read in the EPS or TIFF image */
    anImage = [[NXImage alloc] initFromFile:fileName];
    if ([anImage lastRepresentation] == nil)
    	return NO;

    /* We will be scaling this image */
    [anImage setScalable: YES];

    /* Create an instance of ImageView */
    if ((view = [[ImageView alloc] initFromImage: anImage]) == nil)
	return NO;
    
    /* Create a new window the size of the image */
    [view getFrame:&rect];
    window = [[Window alloc] initContent:&rect
			style:NX_TITLEDSTYLE
			backing:NX_RETAINED
			buttonMask:NX_CLOSEBUTTONMASK
			defer:NO];
    /* Set the window delegate */
    [window setDelegate:self];
			
    /* Replace the current contentView of the window with my new view */
    /*   and free up the old contentView */
    [[window setContentView:view] free];
    [window center];  /* Put the window in the center of the screen */
 
     /* Set the title of the window to be the title of the file */
    name = rindex(fileName, '/');
    sprintf (title, "%s", name ? name+1 : fileName);
    [window setTitle:title];
    [window makeKeyAndOrderFront:self];
    [window display];
    return YES;
}

/* selectFormat:
 * 	This method is called when the user selects a button in the formatMatrix.
 * It dims or brightens other panel items, as appropriate.  For example, if saving
 * an image as EPS, the DPI matrix needs to be dimmed as it is not applicable.
 */
- selectFormat:sender
{    
    switch ([formatMatrix selectedCol])
    {
    case TIFF_FORMAT:
    	[DPIpopup setEnabled:YES];
	[DPIvalue setEnabled:YES];
	[compressionType setEnabled:YES];
	[saveReq setRequiredFileType: tiffType];
        [self selectCompression: nil];
    	break;
    case EPS_FORMAT:
    	[DPIpopup setEnabled:NO];
	[DPIvalue setEnabled:NO];
	[compressionType setEnabled:NO];
	[saveReq setRequiredFileType: epsType];
        [JPEGlabel setTextGray: NX_DKGRAY];
	[JPEGvalue setEnabled:NO];
    	break;
    }
    return self;
}

/* selectCompression:
 * 	This method is called when the user selects a button in the 
 * compressionType matrix.  It dims or brightens the JPEG value
 * field, as appropriate.
 */
- selectCompression:sender
{
    switch ([compressionType selectedCol])
    {
    case LZW_COMPRESSION:
        [JPEGlabel setTextGray: NX_DKGRAY];
	[JPEGvalue setEnabled:NO];
        break;
    case JPEG_COMPRESSION:
        [JPEGlabel setTextGray: NX_BLACK];
	[JPEGvalue setEnabled:YES];
        break;
    }
    return self;
}

/* -saveRequest:
 * 	This method is called when the user selects "Save Image..." from the menu.
 * An accessory view is installed in the save panel which allows the user to specify
 * saving the image as either EPS or TIFF.  In the case of TIFF, the user must
 * provide a DPI value.
 */
- saveRequest:sender
{
    id window;
    const char *fileName, *title;
    char name[100], *extension;
    int cnt;
    
    window = [NXApp keyWindow];
    /* can't save anything if no windows are available */
    if (window == nil) return self;  
    title = [window title];
    /* Yank off the extension */
    extension = index(title, '.');
    cnt = (int)extension-(int)title;
    strncpy(name, title, cnt);
    name[cnt] = '\0';
    
    /* 
     * Insert my accessory view into the save panel.
     * This view allows [forces] the user to select either EPS or TIFF when 
     * saving the image.  If the image is to be saved as TIFF, the user must 
     * supply a DPI value -- the default resolution is 72DPI. 
     */
    if ([saveReq accessoryView] == nil)
    	[saveReq setAccessoryView: [accessoryWindow contentView]];

    if ([saveReq runModalForDirectory: "."  file: name] && 
       (fileName =[saveReq filename])) 
    {
    	switch ([formatMatrix selectedCol])
	{
	case TIFF_FORMAT:
	    [self saveTIFF:fileName inWindow: window];
	    break;
	case EPS_FORMAT:
	    [self saveEPS:fileName inWindow: window];
	    break;
	}
    }
    return self;
}
    
/* -saveTIFF: inWindow:
 *	This method saves a specified view to disk with the specified 
 * fileName using the TIFF format.  An instance of NXBitmapImageRep 
 * is created with the desired resolution,  then written to a stream and 
 * then to disk using LZW compression.  The instance of NXBitmapImageRep 
 * is then freed.
 */
- (BOOL)saveTIFF: (const char *)fileName inWindow: window
{
    id tiffImage, theImage;
    NXSize  origSize, newSize;
    NXRect rect;
    int	 	DPI;
    BOOL error = NO;
    NXStream *s;
    float factor;
    char *dpiInput;
    
    /* Get the original size and squirrel that away. */
    /* We'll be changing the size to reflect the desired DPI of the TIFF file */
    /* and then image it at that resolution. */
    theImage = [[window contentView] image];
    [theImage getSize:&origSize];
    dpiInput = (char *)[DPIpopup title];
    sscanf(dpiInput,"%d",&DPI);
    newSize.width = origSize.width * (float)DPI/ POINTSPERINCH;
    newSize.height = origSize.height * (float)DPI/ POINTSPERINCH;
    [theImage setSize: &newSize];
   
    /* Create a tiff image at the desired size */
    [theImage lockFocus];
    rect.origin.x = rect.origin.y = 0.0;
    rect.size = newSize;
    tiffImage = [[NXBitmapImageRep alloc] initData: NULL  fromRect: &rect];
    [theImage unlockFocus];
    [theImage setSize: &origSize];
    [tiffImage setSize: &origSize];
    
    if (!tiffImage)
    	return NO;
	
    s = NXOpenMemory (NULL, 0, NX_READWRITE);
    if (s) 
    {
        switch ([compressionType selectedCol])
	{
	case LZW_COMPRESSION:
	    [tiffImage  writeTIFF:s usingCompression:NX_TIFF_COMPRESSION_LZW];
	    break;
	case JPEG_COMPRESSION:
	    if ([tiffImage bitsPerSample] < 4)
	    {
	    	NXRunAlertPanel("TIFFandEPS Save Error", 
		  "JPEG compression requires 4 or 8 bits per sample for grayscale or RGB",
		   NULL, NULL, NULL);
		error = YES;
		break;
	    }
	    factor = [JPEGvalue floatValue];
	    if (factor < 1.0) factor = 1.0;
	    if (factor > 255.0) factor = 255.0;
	    [tiffImage writeTIFF:s usingCompression:NX_TIFF_COMPRESSION_JPEG
	    	andFactor: factor];
	    break;
	}
	NXFlush (s);
	if (!error)
	{
	    if (NXSaveToFile (s, fileName)) 
	    {
	        error = YES;
	        perror (fileName);
	    } 
	}
	NXCloseMemory (s, NX_FREEBUFFER);
    }
    else error = YES;
    [tiffImage free];
    return (error ? NO : YES);
}

/* -saveEPS: inWindow:
 *	This method saves a specified view to disk with the specified 
 * fileName using the EPS format.  To do this the copyPSCode 
 * method of view is used on the view with the result going to a stream 
 * and then to disk.
 */
- (BOOL)saveEPS: (const char *)fileName inWindow: window
{
    NXRect rect;
    BOOL error = NO;
    NXStream *s;
    
    s = NXOpenMemory(NULL, 0, NX_WRITEONLY);
    if (s)
    {
    	[[window contentView] getFrame:&rect];
    	[[window contentView] copyPSCodeInside:&rect to:s]; 
    	NXFlush(s);   
    	if (NXSaveToFile (s, fileName)) 
    	{ 
	    error = YES;
	    perror (fileName);
    	} 
    	NXCloseMemory(s, NX_FREEBUFFER);
    }
    else error = YES;
    return (error? NO : YES);
}

@end
