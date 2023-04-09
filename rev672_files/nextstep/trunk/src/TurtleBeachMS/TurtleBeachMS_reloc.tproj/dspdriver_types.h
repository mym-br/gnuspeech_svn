#ifndef __MK_dspdriver_types_H___
#define __MK_dspdriver_types_H___
/*
 *	File:	<dsp/dspdriver_types.h>
 *	Author:	David Jaffe
 *      DSP driver typedefs, defines, etc.
 */


#ifndef _DSPDRIVER_TYPES_
#define _DSPDRIVER_TYPES_

#import <mach/kern_return.h>
#import <mach/message.h>
#import <mach/port.h>

/* error codes */
#define DSPDRIVER_ERROR_BUSY 100
#define DSPDRIVER_ERROR_NOT_OWNER 101
#define DSPDRIVER_ERROR_TIMEOUT 102
#define DSPDRIVER_ERROR_BAD_UNIT_OR_DRIVER 103
#define DSPDRIVER_ERROR_BAD_ID 104
#define DSPDRIVER_ERROR_UNKNOWN_ERROR 105

/* DSP_MAX_BYTES is the maximum number of data bytes that can be
 * sent to or received from the driver in a single package. 
 */
#define DSP_MAX_BYTES 2048
#define DSP_MAX_SHORTS (DSP_MAX_BYTES/2)
#define DSP_MAX_WORDS (DSP_MAX_BYTES/4)
#define DSP_MAX_PACKED (DSP_MAX_BYTES/3)
#define DSP_MAX_PACKED_BYTES (3*(DSP_MAX_PACKED))

/* DSP_MAX_MSG_SIZE is the maximum size of the message you
 * can receive from the driver. 
 */
#define DSP_MAX_MSG_SIZE 5120  // More than enough
   
/* Mig foolishness */
typedef int *DSPWordPtr;
typedef short *DSPShortPtr;
typedef char *DSPCharPtr;

// added by len
typedef int *DSPPagePtr;
// end addition

#endif _DSPDRIVER_TYPES_

#endif
