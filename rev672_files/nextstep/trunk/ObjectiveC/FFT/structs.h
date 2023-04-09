/*===========================================================================
	File: Structs.h
	Purpose: This file holds the structure definition for all FFT
		analysis files


	debug history

		Sat, Sep. 19, 1992: Upgraded for 550 spec.

		Nov 25, 1990: Documentation

===========================================================================*/

/* Magic number for Analysis files */
#define ANA_MAGIC	0xFAC87D34

/* Header definition */
struct _FFTheader {
	unsigned int anaMagic;		/* Magic number. Used to identify file */
	int hanning;			/* Hanning window used? */
	int slide;			/* Window slide (in samples) */
	int num_windows;		/* Total number of windows */
	int bin_size;			/* Size of bin. (in samples) 512, 256 or 128 */
	int sampling_rate;		/* for 550, should be 11025 */
	char comment[100];		/* User comment */
};

/* Data definition */
struct _data512 {
	float data[256];		/* 1 window = 256 floats */
					/* in 21.53 Hz increments */
};

struct _data256 {
	float data[128];		/* 1 window = 128 floats */
					/* in 43.07 Hz increments */
};

struct _data128 {
	float data[64];		/* 1 window = 64 floats */
					/* in 86.13 Hz increments */
};

