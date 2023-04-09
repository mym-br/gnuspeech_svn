#include "errors.h"
#include <stdlib.h>
#include <mach_error.h>
#include <stdio.h>

void check_mach_error(int error_code, char *error_message)
{
  if (error_code != KERN_SUCCESS) {
    mach_error(error_message, error_code);
    exit(1);
  }
}

static char *snddriver_error_list[] = {
  "sound success",
  "sound message sent to wrong port",
  "unknown sound message id",
  "bad parameter list in sound message",
  "can't allocate memory for recording",
  "sound service in use",
  "sound service requires ownership",
  "DSP channel not initialized",
  "can't find requested sound resource",
  "bad DSP mode for sending data commands",
  "external pager support not implemented",
  "sound data not properly aligned"
  };

char *snddriver_error_string(int error)
{
//  return ((error >= SND_NO_ERROR)?
//	  snddriver_error_list[error-SND_NO_ERROR]:
//	  "unrecognized sound error message");
  return (snddriver_error_list[error]);
}

void check_snddriver_error(int error_code, char *error_message)
{
  if ((error_code != 0)) {
    fprintf(stderr,"%s: %s (%d)\n", error_message,
	    (error_code < 0)?
	    mach_error_string(error_code):
	    snddriver_error_string(error_code),
	    error_code);
    exit(1);
  }
}

void check_snd_error(int error_code, char *error_message)
{
  if ((error_code != 0) && (error_code != SND_ERR_NONE)) {
    fprintf(stderr,"%s: %s (%d)\n", error_message,
	    (error_code < 0)?
	    mach_error_string(error_code):
	    SNDSoundError(error_code),
	    error_code);
    exit(1);
  }
}
