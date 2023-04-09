/*===========================================================================

	This file contains NeXT sound file information. 

===========================================================================*/

typedef struct {
	int magic;          /* must be equal to SND_MAGIC */
	int dataLocation;   /* Offset or pointer to the raw data */
	int dataSize;       /* Number of bytes of data in the raw data */
	int dataFormat;     /* The data format code */
	int samplingRate;   /* The sampling rate */
	int channelCount;   /* The number of channels */
	char info[4];       /* Textual information relating to the sound. */
} SNDSoundStruct;


/*
 * The magic number must appear at the beginning of every SNDSoundStruct.
 * It is used for type checking and byte ordering information.
 */
#define SND_MAGIC ((int)0x2e736e64)

/*
 * NeXT data format codes. User-defined formats should be greater than 255.
 * Negative format numbers are reserved.
 */
#define SND_FORMAT_UNSPECIFIED          (0)
#define SND_FORMAT_MULAW_8              (1)
#define SND_FORMAT_LINEAR_16            (3)
#define SND_FORMAT_LINEAR_24            (4)
#define SND_FORMAT_LINEAR_32            (5)

/*===========================================================================

	The following are sampling rates for the sound files.  Please note
	that SND_RATE_FFT is NOT part of the NeXT standard.  

===========================================================================*/

#define SND_RATE_CODEC          (8012.8210513)
#define SND_RATE_LOW            (22050.0)
#define SND_RATE_HIGH           (44100.0)
#define SND_RATE_FFT		(11025)
