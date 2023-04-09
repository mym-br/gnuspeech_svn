/*  REVISION INFORMATION  *****************************************************

$Author: rao $
$Date: 2002-03-21 16:49:46 $
$Revision: 1.1 $
$Source: /Users/dalmazio/cvsroot/gnuspeech/trillium/ObjectiveC/DEGAS/synthesizer_module.c,v $
$State: Exp $


$Log: not supported by cvs2svn $
 * Revision 1.6  1993/12/14  20:16:42  len
 * Rewrote the module so that it is single-threaded.
 *
 * Revision 1.5  1993/12/13  17:59:09  len
 * Changed all kernel thread calls to cthread calls.  This allows the module
 * to work under NS 3.2, at the expense of some increased latency.
 *
 * Revision 1.4  1993/11/30  22:30:37  len
 * Fixed a bug in DSP code.  Created the scaled_volume()
 * function, which checks volume ranges before scaling
 * them to a fractional number.
 *
 * Revision 1.3  1993/11/29  18:43:21  len
 * Moved calculatation of amplitudes and resonator coefficients to the
 * DSP from the host.
 *
 * Revision 1.2  1993/11/26  04:59:22  len
 * Added the ability to send sound directly to file.
 *
 * Revision 1.1.1.1  1993/11/25  23:00:47  len
 * Initial archive of production code for the 1.0 TTS_Server (tag v5).
 *

******************************************************************************/

/*  INCLUDE FILES  ***********************************************************/
#import "synthesizer_module.h"
#import <stdio.h>
#import <sound/sound.h>
#import <sound/sounddriver.h>
#import <dsp/dsp.h>
#import <math.h>
#import <appkit/nextstd.h>
#import <streams/streams.h>
#import <sys/time.h>
#import <sys/types.h>
#import <sys/timeb.h>


/*  LOCAL DEFINES  ***********************************************************/
/*  DSP CORE FILE  */
#define DSPCORE         "dspcore.h"

#define INFINITE_WAIT   0
#define POLL            1



/*  EXTERNAL GLOBAL VARIABLES  ***********************************************/
/*  SYNTHESIZER READ POINTER INTO PAGED TABLE MEMORY  */
vm_address_t synth_read_ptr;

/*  STATUS FLAG FOR INTER-THREAD COMMUNICATION  */
int synth_status;

/*  SCALING GLOBALS  */
float scale_rc;



/*  STATIC GLOBAL VARIABLES (LOCAL TO THIS FILE)  ****************************/
/*  GLOBAL VARIABLES FOR SIGNALLING BETWEEN FUNCTIONS  */
static int stream_status;
static int prefill_count;
static vm_address_t pad_page;

/*  MISC.  */
static kern_return_t k_err;
static port_t dev_port, owner_port, cmd_port, read_port, write_port, reply_port;
static port_t file_reply_port;
static DSPFix24 *wave_table;
static msg_header_t *reply_msg, *file_reply_msg;


/*  GLOBAL VARIABLES FOR WRITING TO FILE  */
static int outputMode = ST_OUT_DSP;
static int chunkNumber = 0;
static char file_path[MAXPATHLEN+1];
static int file_uid = 0, file_gid = 0;
NXStream *fileStream = NULL;



/*  STATIC GLOBAL FUNCTIONS (LOCAL TO THIS FILE)  ****************************/
static int grab_and_initialize_DSP(void);
static int relinquish_DSP(void);
static void flush_input_pages(void);
static void queue_page(void);
static void queue_pad_page(void);
static void resume_stream(void);
#if DEBUG
static void write_started(void *arg, int tag);
static void write_completed(void *arg, int tag);
static void under_run(void *arg, int tag);
#endif
static void recorded_data(void *arg, int tag, void *data, int nbytes);
static int await_write_done_message(int mode);
static double timeStamp(void);
static DSPFix24 *new_gp_table(float tp, float tn, int wave_table_size);
static void write_file(void);



/******************************************************************************
*
*	function:	grab_and_initialize_DSP
*
*	purpose:	Does initialization and setup necessary to gain control
*                       of the DSP and DAC device, and does stream setup.
*
*	internal
*	functions:	none
*
*	library
*	functions:	SNDAcquire, snddriver_set_ramp,
*                       snddriver_set_sndout_bufsize,
*                       snddriver_get_dsp_cmd_port, snddriver_stream_setup,
*                       snddriver_dsp_protocol, SNDBootDSP, 
*                       snddriver_dsp_host_cmd, snddriver_dsp_write,
*                       snddriver_stream_control, set_resonator_coefficients,
*                       NXOpenMemory
*
******************************************************************************/

static int grab_and_initialize_DSP(void)
{
  int s_err, protocol;
  SNDSoundStruct *dspStruct;
  float a, b, c;
  DSPFix24 coefficients[3];

  /*  INCLUDE DSP CORE FILE  */
  #include DSPCORE

  /*  GET CONTROL OF DEVICES  */
  if (outputMode == ST_OUT_DSP) {
    /*  GET CONTROL OF DSP AND DAC  */
    dev_port = owner_port = 0;
    s_err = SNDAcquire(SND_ACCESS_DSP|SND_ACCESS_OUT,10,0,0,
		       NULL_NEGOTIATION_FUN,0,&dev_port,&owner_port); 
    if (s_err != SND_ERR_NONE)
      return(ST_ERROR);
  }
  else {
    /*  GET CONTROL OF DSP ONLY  */
    dev_port = owner_port = 0;
    s_err = SNDAcquire(SND_ACCESS_DSP,10,0,0,
		       NULL_NEGOTIATION_FUN,0,&dev_port,&owner_port); 
    if (s_err != SND_ERR_NONE)
      return(ST_ERROR);
  }

  /*  SET RAMPING OFF (NOT NEEDED, AND IT SLOWS SOUND OUT)  */
  k_err = snddriver_set_ramp(dev_port,0);
  if (k_err != KERN_SUCCESS)
    return(ST_ERROR);

  /*  SET THE SOUND OUT BUFFER SIZE SMALLER SO NO GLITCHES IN SOUND OUT  */
  k_err = snddriver_set_sndout_bufsize(dev_port,owner_port,DMA_OUT_SIZE);
  if (k_err != KERN_SUCCESS)
    return(ST_ERROR);

  /*  GET THE DSP COMMAND PORT  */
  k_err = snddriver_get_dsp_cmd_port(dev_port,owner_port,&cmd_port);
  if (k_err != KERN_SUCCESS)
    return(ST_ERROR);
  

  /*  SET UP HOST->DSP, AND DSP->DAC OR DSP->HOST STREAMS  */
  /*  NOTE:  DMA_IN_SIZE MULTIPLIED BY 2, SINCE EACH DSPFix24
      IS SENT AS TWO 2-BYTE WORDS  */
  protocol = SNDDRIVER_DSP_PROTO_RAW;
  k_err = snddriver_stream_setup(dev_port, owner_port,
    				 SNDDRIVER_DMA_STREAM_TO_DSP,
				 DMA_IN_SIZE*2, 2,
				 LOW_WATER, HIGH_WATER,
				 &protocol, &read_port);
  if (k_err != KERN_SUCCESS)
    return(ST_ERROR);
  
  if (outputMode == ST_OUT_DSP) {
    k_err = snddriver_stream_setup(dev_port, owner_port,
				   SNDDRIVER_STREAM_DSP_TO_SNDOUT_22,
				   DMA_OUT_SIZE, 2, 
				   LOW_WATER, HIGH_WATER,
				   &protocol, &write_port);
    if (k_err != KERN_SUCCESS)
      return(ST_ERROR);
  }
  else {
    k_err = snddriver_stream_setup(dev_port, owner_port,
				   SNDDRIVER_DMA_STREAM_FROM_DSP,
				   DMA_OUT_SIZE, 2, 
				   LOW_WATER, HIGH_WATER,
				   &protocol, &write_port);
    if (k_err != KERN_SUCCESS)
      return(ST_ERROR);
  }


  /*  SET THE DSP PROTOCOL  */
  k_err = snddriver_dsp_protocol(dev_port, owner_port, protocol);
  if (k_err != KERN_SUCCESS)
    return(ST_ERROR);


  /*  BOOT THE DSP WITH THE .lod IMAGE CONTAINED IN DSPCORE.H FILE  */
  /*  THE DSPCORE.H FILE IS MADE BY RUNNING dspLod2Core ON THE .lod FILE  */
  dspStruct = (SNDSoundStruct *)dspcore;
  s_err = SNDBootDSP(dev_port, owner_port, dspStruct);
  if (s_err != SND_ERR_NONE)
    return(ST_ERROR);

  /*  SEND THE WAVEFORM TO THE DSP  */
  k_err = snddriver_dsp_host_cmd(cmd_port, 
				 (u_int)HC_LOAD_WAVEFORM, 
				 SNDDRIVER_LOW_PRIORITY);  
  if (k_err != KERN_SUCCESS)
    return(ST_ERROR);

  k_err = snddriver_dsp_write(cmd_port,(void *)wave_table,WAVE_TABLE_SIZE,
			      sizeof(DSPFix24), SNDDRIVER_LOW_PRIORITY);
  if (k_err != KERN_SUCCESS)
    return(ST_ERROR);


  /*  SEND FIXED NASAL RESONATOR COEFFICIENTS TO THE DSP
      (THESE ARE NOT UNDER PARAMETRIC CONTROL, BUT ARE FIXED)  */
  set_resonator_coefficients(FNR_FREQ_DEF,FNR_BW_DEF,&a,&b,&c);
  coefficients[0] = DSPFloatToFix24(c);
  coefficients[1] = DSPFloatToFix24(b);
  coefficients[2] = DSPFloatToFix24(a);

  k_err = snddriver_dsp_host_cmd(cmd_port, 
				 (u_int)HC_LOAD_FNR, 
				 SNDDRIVER_LOW_PRIORITY);  
  if (k_err != KERN_SUCCESS)
    return(ST_ERROR);

  k_err = snddriver_dsp_write(cmd_port,(void *)coefficients,3,
			      sizeof(DSPFix24), SNDDRIVER_LOW_PRIORITY);
  if (k_err != KERN_SUCCESS)
    return(ST_ERROR);


  /*  MAKE SURE STREAM TO DSP IS IN PAUSED STATE  */
  k_err = snddriver_stream_control(read_port,0,SNDDRIVER_PAUSE_STREAM);
  if (k_err != KERN_SUCCESS)
    return(ST_ERROR);

  /*  SET UP MEMORY STREAM FOR FILE OUTPUT, UNLESS STREAM ALREADY SET UP  */
  if ((outputMode == ST_OUT_FILE) && (fileStream == NULL))
    fileStream = NXOpenMemory(NULL, 0, NX_READWRITE);

  /*  SET STREAM STATUS TO PAUSE  */
  stream_status = ST_PAUSE;

  /*  IF WE GET HERE, THEN THE DSP IS INITIALIZED AND READY TO GO  */
  return(ST_NO_ERROR);
}



/******************************************************************************
*
*	function:	relinquish_DSP
*
*	purpose:	Gives up control of the DSP and DAC devices.
*
*	internal
*	functions:	none
*
*	library
*	functions:	SNDRelease
*
******************************************************************************/

static int relinquish_DSP(void)
{
  int s_err;
  
  if (outputMode == ST_OUT_DSP) {
    /*  GIVE UP CONTROL OVER DSP AND SOUND OUT  */
    s_err = SNDRelease(SND_ACCESS_DSP|SND_ACCESS_OUT,dev_port,owner_port);
    if (s_err != SND_ERR_NONE)
      return(ST_ERROR);
    else
      return (ST_NO_ERROR);
  }
  else {
    /*  GIVE UP CONTROL OVER DSP  */
    s_err = SNDRelease(SND_ACCESS_DSP,dev_port,owner_port);
    if (s_err != SND_ERR_NONE)
      return(ST_ERROR);
    else
      return (ST_NO_ERROR);
  }
}



/******************************************************************************
*
*	function:	flush_input_pages
*
*	purpose:	Appends a pad page to the stream, and waits until
*                       stream to synthesizer is done.
*
*	internal
*	functions:	queue_pad_page, resume_stream, await_write_done_message
*
*	library
*	functions:	none
*
******************************************************************************/

static void flush_input_pages(void)
{
  int i, j;

  /*  ENQUEUE A PAD PAGE (SILENCE);  ENSURES THAT DSP BUFFERS ARE FLUSHED  */
  queue_pad_page();

  /*  QUEUE SILENCE BETWEEN CHUNKS, IF NEEDED  */
  if ((outputMode == ST_OUT_FILE) && (chunkNumber > 1)) {
    for (j = 0; j < INTER_CHUNK_SILENCE; j++)
      queue_pad_page();
  }

  /*  IF THE STREAM IS STILL PAUSED, THEN START IT  */
  if (stream_status != ST_RUN)
    resume_stream();

  /*  WAIT UNTIL ALL PAGES ARE WRITTEN (INCLUDING ADDITIONAL PAD PAGE)  */
  for (i = prefill_count; i < (PREFILL_SIZE+1); i++)
    await_write_done_message(INFINITE_WAIT);

  /*  WAIT UNTIL ALL INTER-CHUNK SILENCE PAGES ARE WRITTEN  */
  if ((outputMode == ST_OUT_FILE) && (chunkNumber > 1)) {
    for (j = 0; j < INTER_CHUNK_SILENCE; j++)
      await_write_done_message(INFINITE_WAIT);
  }
}



/******************************************************************************
*
*	function:	queue_page
*
*	purpose:	Writes the page pointed to by synth_read_ptr to the
*                       stream to the DSP.
*
*	internal
*	functions:	none
*
*	library
*	functions:	snddriver_stream_start_writing
*
******************************************************************************/

static void queue_page(void)
{
  snddriver_stream_start_writing(read_port,
				 (void *)synth_read_ptr,
				 (vm_page_size / sizeof(short)),
				 1,
				 0,0,
				 0,1,0,0,0,0, reply_port);
}



/******************************************************************************
*
*	function:	queue_pad_page
*
*	purpose:	Writes the pad page (silence) to the stream
*                       to the DSP.
*
*	internal
*	functions:	none
*
*	library
*	functions:	snddriver_stream_start_writing
*
******************************************************************************/

static void queue_pad_page(void)
{
  snddriver_stream_start_writing(read_port,
				 (void *)pad_page,
				 (vm_page_size / sizeof(short)),
				 1,
				 0,0,
				 0,1,0,0,0,0, reply_port);
}



/******************************************************************************
*
*	function:	resume_stream
*
*	purpose:	Starts the stream to the DSP.
*
*	internal
*	functions:	none
*
*	library
*	functions:	snddriver_stream_control, snddriver_dsp_host_cmd
*
******************************************************************************/

static void resume_stream(void)
{
  /*  SET STREAM STATUS VARIABLE  */
  stream_status = ST_RUN;

  /*  UNPAUSE STREAM TO DSP  */
  snddriver_stream_control(read_port,0,SNDDRIVER_RESUME_STREAM);

  /*  SEND START HOST COMMAND TO DSP  */
  snddriver_dsp_host_cmd(cmd_port, (u_int)HC_START, SNDDRIVER_LOW_PRIORITY);
}



/******************************************************************************
*
*	function:	write_started, write_completed, under_run,
*                       recorded_data
*
*	purpose:	Handlers for messages from snddriver to reply port,
*                       and file reply port.
*
*	internal
*	functions:	none
*
*	library
*	functions:	fprintf, NXWrite, vm_deallocate, task_self
*
******************************************************************************/

#if DEBUG
static void write_started(void *arg, int tag)
{
  fprintf(stderr,"Started playing... %d \n",tag);
}

static void write_completed(void *arg, int tag)
{
  fprintf(stderr,"Playing done... %d\n",tag);
}

static void under_run(void *arg, int tag)
{
  fprintf(stderr,"Under run... %d\n",tag);
}
#endif

static void recorded_data(void *arg, int tag, void *data, int nbytes)
{
  #if DEBUG
  fprintf(stderr,"Recorded data... %d %d\n", tag, nbytes);
  #endif

  /*  WRITE DATA TO STREAM  */
  NXWrite(fileStream, data, nbytes);

  /*  DEALLOCATE MEMORY PASSED IN  */
  vm_deallocate(task_self(), (pointer_t)data, nbytes);
}



/******************************************************************************
*
*	function:	await_write_done_message
*
*	purpose:	Waits for write done message from snddriver.
*
*	internal
*	functions:	write_started, write_completed, under_run,
*                       recorded_data
*
*	library
*	functions:	msg_receive, snddriver_reply_handler, fprintf,
*                       snddriver_stream_start_reading
*
******************************************************************************/

static int await_write_done_message(int mode)
{
  static int count = 0;
  static double startTime;
  #if DEBUG
  snddriver_handlers_t handlers = {0,0,write_started,write_completed,
				   0,0,0,under_run,recorded_data};
  #else
  snddriver_handlers_t handlers = {0,0,0,0,0,0,0,0,recorded_data};
  #endif


  /*  READ FROM THE DSP, IF OUTPUT MODE IS FILE, CLEARING ANY OLD MESSAGES  */
  /*  THIS HACK IS NECESSARY WHEN NOT IN DEBUGGING MODE  */
  if (outputMode == ST_OUT_FILE) {
    while (1) {
      snddriver_stream_start_reading(write_port,
				     NULL,
				     DMA_OUT_SIZE,
				     2,
				     0,0,0,0,0,0, file_reply_port);
      
      /*  RECEIVE MESSAGES FROM SOUND DRIVER  */
      file_reply_msg->msg_size = MSG_SIZE_MAX;
      file_reply_msg->msg_local_port = file_reply_port;
      
      /*  WAIT FOR MESSAGE  */
      k_err = msg_receive(file_reply_msg, RCV_TIMEOUT, 0);
      if (k_err == RCV_TIMED_OUT)
	/*  BREAK OUT OF LOOP IF NO MORE MESSAGES  */
	break;
      else if (k_err == RCV_SUCCESS)
	/*  HANDLE DATA FROM DSP, BY WRITING IT TO FILE  */
	k_err = snddriver_reply_handler(file_reply_msg, &handlers);
    }
  }



  /*  RECEIVE MESSAGES FROM SOUND DRIVER  */
  reply_msg->msg_size = MSG_SIZE_MAX;
  reply_msg->msg_local_port = reply_port;


  /*  WAIT FOR MESSAGE USING msg_receive AND TIMEOUT OF 3 SECONDS  */
  if (mode == INFINITE_WAIT) {
    /*  WAIT FOR MESSAGE  */
    k_err = msg_receive(reply_msg, RCV_TIMEOUT, 3000);
    if (k_err == RCV_TIMED_OUT) {
      /*  THIS ONLY HAPPENS UNDER VERY HEAVY LOADS (SWAPPING)  */
      relinquish_DSP();
      NXLogError("TTS Server:  Sound Driver failed under heavy load (iw).");
      exit(-1);
    }
    #if DEBUG
    else if (k_err == RCV_SUCCESS)
      k_err = snddriver_reply_handler(reply_msg, &handlers);
    #endif
  }
  /*  SEE IF MESSAGE IS WAITING FOR US  */
  else if (mode == POLL) {
    /*  WAIT FOR MESSAGE  */
    k_err = msg_receive(reply_msg, RCV_TIMEOUT, 0);
    if (k_err == RCV_TIMED_OUT) {
      /*  TIME STAMP FIRST TIME THE PORT IS POLLED  */
      if (++count == 1)
	startTime = timeStamp();
      else {
	if ((timeStamp() - startTime) > 3.0) {
	  /*  THIS ONLY HAPPENS UNDER VERY HEAVY LOADS (SWAPPING)  */
	  relinquish_DSP();
	  NXLogError("TTS Server:  Sound Driver failed under heavy load (p).");
	  exit(-1);
	}
      }
      return(ST_NO_PAGE_REQUEST);
    }
    #if DEBUG
    else if (k_err == RCV_SUCCESS)
      k_err = snddriver_reply_handler(reply_msg, &handlers);
    #endif
    
    /*  RESET COUNT TO ZERO  */
    count = 0;
  }


  /*  READ FROM THE DSP, IF OUTPUT MODE IS FILE  */
  if (outputMode == ST_OUT_FILE) {
    while (1) {
      snddriver_stream_start_reading(write_port,
				     NULL,
				     DMA_OUT_SIZE,
				     2,
				     0,0,0,0,0,0, file_reply_port);
      
      /*  RECEIVE MESSAGES FROM SOUND DRIVER  */
      file_reply_msg->msg_size = MSG_SIZE_MAX;
      file_reply_msg->msg_local_port = file_reply_port;
      
      /*  WAIT FOR MESSAGE  */
      k_err = msg_receive(file_reply_msg, RCV_TIMEOUT, 100);
      if (k_err == RCV_TIMED_OUT)
	/*  BREAK OUT OF LOOP IF NO MORE MESSAGES  */
	break;
      else if (k_err == RCV_SUCCESS)
	/*  HANDLE DATA FROM DSP, BY WRITING IT TO FILE  */
	k_err = snddriver_reply_handler(file_reply_msg, &handlers);
    }
  }

  /*  IF HERE, WE ACTUALLY NEED A NEW PAGE  */
  return(ST_PAGE_REQUEST);
}



/******************************************************************************
*
*	function:	timeStamp
*
*	purpose:	Returns the current time as a time stamp.  This is
*                       a double, the fractional number of seconds since
*			a system start time.  Resolution is to milliseconds.

*       arguments:      none
*                       
*	internal
*	functions:	none
*
*	library
*	functions:	ftime
*
******************************************************************************/

static double timeStamp(void)
{
  struct timeb tp;
  void ftime();
  
  ftime(&tp);
  return( (double)tp.time + (double)tp.millitm / 1000.0);
}
  


/******************************************************************************
*
*	function:	new_gp_table
*
*	purpose:	Creates a glottal pulse wave table.
*
*	internal
*	functions:	none
*
*	library
*	functions:	calloc, DSPFloatToFix24, pow, rint
*
******************************************************************************/

static DSPFix24 *new_gp_table(float tp, float tn, int wave_table_size)
{
  int i, j = 0, t0_samples, tp_samples, tn_samples;
  float t0;
  
  /*  ALLOCATE MEMORY FOR THE TABLE  */
  DSPFix24 *gp_table = (DSPFix24 *) calloc(wave_table_size,sizeof(DSPFix24));
  if (gp_table == NULL)
    return(NULL);
  
  /*  SEGMENT THE TABLE  */
  t0 = 1.0 - (tp + tn);
  t0_samples = (int)rint(t0 * wave_table_size);
  tp_samples = (int)rint(tp * wave_table_size);
  tn_samples = (int)rint(tn * wave_table_size);
  
  /*  CALCULATE ZERO PART  */
  for (i = 0; i < t0_samples; i++)
    gp_table[j++] = DSPFloatToFix24(0.0);
  
  /*  CALCULATE TP  */
  for (i = 0; i < tp_samples; i++)
    gp_table[j++] = DSPFloatToFix24(MAX_TABLE_VALUE *
			   (3.0 * pow(((float)i/(float)tp_samples),2.0)
			    - 2.0 * pow(((float)i/(float)tp_samples),3.0)));
  
  /*  CALCULATE TN  */
  for (i = 0; i < tn_samples; i++)
    gp_table[j++] = DSPFloatToFix24(MAX_TABLE_VALUE *
			   (1.0 - pow(((float)i/(float)tn_samples),2.0)));
  
  return(gp_table);
}



/******************************************************************************
*
*	function:	write_file
*
*	purpose:	Writes the samples stored in fileStream to a .snd
*                       type file with the pathname provided.  The uid and gid
*                       of the file are changed to that of the client.  The
*                       NXStream is deallocated here.
*                       
*			
*       arguments:      none
*                       
*	internal
*	functions:	none
*
*	library
*	functions:	fopen, NXGetMemoryBuffer, fwrite, fclose, chown,
*                       NXCloseMemory
*
******************************************************************************/

static void write_file(void)
{
  SNDSoundStruct sound;
  FILE *fopen(), *fd;
  char *streambuf;
  int len, maxlen;

  /*  OPEN THE OUTPUT FILE  */
  fd = fopen(file_path, "w");

  /*  GET THE MEMORY BUFFER FOR THE FILE STREAM  */
  NXGetMemoryBuffer(fileStream, &streambuf, &len, &maxlen);

  /*  INITIALIZE THE SOUND STRUCT  */
  sound.magic = SND_MAGIC;
  sound.dataLocation = sizeof(sound);
  sound.dataSize = len;
  sound.dataFormat = SND_FORMAT_LINEAR_16;
  sound.samplingRate = SND_RATE_LOW;
  sound.channelCount = 2;
  sound.info[0] = '\0';

  /*  WRITE THE STRUCT TO FILE  */
  fwrite((char *)&sound, 1, sizeof(sound), fd);

  /*  WRITE THE MEMORY BUFFER TO FILE (AFTER THE HEADER)  */
  fwrite(streambuf, 1, len, fd);

  /*  CLOSE THE FILE  */
  fclose(fd);

  /*  CHANGE UID AND GID OF FILE TO OWNER AND GROUP OF THE USER  */
  chown(file_path, file_uid, file_gid);

  /*  DEALLOCATE THE MEMORY STREAM  */
  NXCloseMemory(fileStream, NX_FREEBUFFER);
  fileStream = NULL;
}



/*****************************************************************************/
/*****************************************************************************/
/*****************************************************************************/
/*               EXTERNAL FUNCTIONS USED BY CONTROL MODULE                   */
/*****************************************************************************/
/*****************************************************************************/
/*****************************************************************************/



/******************************************************************************
*
*	function:	initialize_synthesizer_module
*
*	purpose:	Initializes variables used in synthesizer module,
*                       and allocates the necessary memory and ports.
*
*	internal
*	functions:	new_gp_table
*
*	library
*	functions:	port_allocate, malloc, vm_allocate, pow,
*                       exp, DSPFloatToFix24, port_set_backlog
*
******************************************************************************/

int initialize_synthesizer_module(void)
{
  /*  CREATE THE GLOTTAL SOURCE WAVEFORM  */
  wave_table = new_gp_table(TP,TN,WAVE_TABLE_SIZE);
  if (wave_table == NULL)
    return(ST_ERROR);

  /*  ALLOCATE A PORT FOR REPLIES FROM THE SOUND DRIVER  */
  k_err = port_allocate(task_self(),&reply_port);
  if (k_err != KERN_SUCCESS)
    return(ST_ERROR);

  /*  ENLARGE REPLY QUEUE TO MAXIMUM ALLOWED SIZE  */
  k_err = port_set_backlog(task_self(), reply_port, PORT_BACKLOG_MAX);
  if (k_err != KERN_SUCCESS)
    return(ST_ERROR);

  /*  ALLOCATE A PORT FOR FILE REPLIES FROM THE SOUND DRIVER  */
  k_err = port_allocate(task_self(),&file_reply_port);
  if (k_err != KERN_SUCCESS)
    return(ST_ERROR);

  /*  ENLARGE FILE REPLY QUEUE TO MAXIMUM ALLOWED SIZE  */
  k_err = port_set_backlog(task_self(), file_reply_port, PORT_BACKLOG_MAX);
  if (k_err != KERN_SUCCESS)
    return(ST_ERROR);

  /*  ALLOCATE MEMORY FOR RETURN MESSAGE FROM SOUND DRIVER  */
  reply_msg = (msg_header_t *)malloc(MSG_SIZE_MAX);
  if (reply_msg == NULL)
    return(ST_ERROR);

  /*  ALLOCATE MEMORY FOR FILE RETURN MESSAGE FROM SOUND DRIVER  */
  file_reply_msg = (msg_header_t *)malloc(MSG_SIZE_MAX);
  if (file_reply_msg == NULL)
    return(ST_ERROR);

  /*  CREATE A PAD PAGE (FULL OF ZEROS)  */
  k_err = vm_allocate(task_self(), (vm_address_t *)&pad_page,
			(vm_size_t)vm_page_size, 1);
  if (k_err != KERN_SUCCESS)
    return(ST_ERROR);
  
  /*  COMPUTE SCALING CONSTANTS  */
  scale_rc = pow(10.0,((PRECASC_SCALE*(1.0 - OSC_PER_SCALE)) / 20.0));
  
  /*  IF WE GET HERE, THEN INITIALIZED WITH NO ERRORS  */
  return(ST_NO_ERROR);
}



/******************************************************************************
*
*	function:	set_synthesizer_output
*
*	purpose:	Used by the control thread to set the output mode to
*                       either file or dsp.  Set to file mode if path is non-
*                       NULL, and the other arguments are set.  If NULL, then
*                       set to dsp mode, and the other arguments are ignored.
*                       
*			
*       arguments:      path, uid, gid, number_chunks
*                       
*	internal
*	functions:	none
*
*	library
*	functions:	strcpy
*
******************************************************************************/

void set_synthesizer_output(char *path, int uid, int gid, int number_chunks)
{
  /*  IF PATH NOT NULL, SET OUTPUT MODE TO FILE, COPY PATH & IDS  */
  if (path) {
    outputMode = ST_OUT_FILE;
    strcpy(file_path, path);
    chunkNumber = number_chunks;
    file_uid = uid;
    file_gid = gid;
  }
  /*  ELSE, SET OUTPUT MODE TO DSP  */
  else {
    outputMode = ST_OUT_DSP;
    file_path[0] = '\0';
    chunkNumber = 0;
    file_uid = -1;
    file_gid = -1;
  }
}      



/******************************************************************************
*
*	function:	start_synthesizer
*
*	purpose:	Grabs control of the DSP/Sound hardware, initializes
*                       it, and initializes other variables.
*
*	internal
*	functions:	grab_and_initialize_DSP
*
*	library
*	functions:	none
*
******************************************************************************/

int start_synthesizer(void)
{
  /*  TRY TO GET CONTROL OVER THE SOUND/DSP HARDWARE  */
  if (grab_and_initialize_DSP() == ST_ERROR)
    return(ST_ERROR);

  /*  INITIALIZE THE PREFILL_COUNT AND SYNTHESIZER STATUS  */
  prefill_count = PREFILL_SIZE;
  synth_status = ST_RUN;

  return(ST_NO_ERROR);
}



/******************************************************************************
*
*	function:	await_request_new_page
*
*	purpose:	Does a blocking or non-blocking wait for synthesizer
*                       request for a new page.  If last_page is set to ST_YES,
*                       then the synthesizer is stopped after the page pointed
*                       at by synth_read_ptr is processed.  The user must
*                       supply a function to update this pointer -- the result
*                       provided by this function is the page that is sent to
*                       the synthesizer.
*
*	internal
*	functions:	pause_synth
*
*	library
*	functions:	thread_switch
*
******************************************************************************/

void await_request_new_page(int blocking_request, int last_page, 
			    void (*ptr_update_function)())
{
  if (prefill_count > 0) {
    /*  UPDATE POINTER TO INPUT PAGE  */
    (*ptr_update_function)();

    /*  QUEUE THAT PAGE TO THE STREAM TO THE SYNTHESIZER  */
    queue_page();

    /*  ONCE WE ENOUGH PAGES QUEUED, START THE STREAM TO THE SYNTHESIZER  */
    if ( (--prefill_count) == 0)
      resume_stream();
  }
  else {
    if (blocking_request) {
      /*  CHECK REPLY PORT WITH INFINITE TIME OUT  */
      await_write_done_message(INFINITE_WAIT);
    }
    else {
      /*  POLL REPLY PORT WITH 0 TIME OUT; IF NO PAGE REQUEST, RETURN  */
      if (await_write_done_message(POLL) == ST_NO_PAGE_REQUEST)
	return;
    }

    /*  UPDATE POINTER TO INPUT PAGE  */
    (*ptr_update_function)();

    /*  QUEUE THAT PAGE TO THE STREAM TO THE SYNTHESIZER  */
    queue_page();
  }

  /*  DEAL WITH LAST PAGE  */
  if (last_page) {
    /*  FLUSH ALL INPUT PAGES  */
    flush_input_pages();

    /*  GIVE UP CONTROL OVER THE DSP AND SOUND OUT HARDWARE  */
    relinquish_DSP();

    /*  WRITE TO FILE, IF NECESSARY  */
    if ((outputMode == ST_OUT_FILE) && (--chunkNumber <= 0))
      write_file();

    /*  SET SYNTHESIZER STATUS TO PAUSE  */
    synth_status = ST_PAUSE;
  }
}



/******************************************************************************
*
*	function:	new_pad_table
*
*	purpose:	Allocates a pad table (silence).
*
*	internal
*	functions:	none
*
*	library
*	functions:	calloc
*
******************************************************************************/

DSPFix24 *new_pad_table(int data_table_size)
{
  return ( (DSPFix24 *) calloc(data_table_size,sizeof(DSPFix24)) );
}




/******************************************************************************
*
*	function:	new_default_data_table
*
*	purpose:	Allocates a default table.  Produces an "aw" sound.
*
*	internal
*	functions:	amplitude, set_resonator_coefficients
*                       set_notch_filter_coefficients
*
*	library
*	functions:	calloc, sin, DSPIntToFix24, DSPFloatToFix24
*
******************************************************************************/

DSPFix24 *new_default_data_table(int data_table_size)
{
  float table_inc, rc_scale;
  float a, b, c, d;
  int i;
  DSPFix24 *data_table;
  
  /*  MAKE SURE TABLE SIZE IS AT LEAST 25  */
  if (data_table_size < 25)
    return(NULL);
  
  /*  ALLOCATE MEMORY FOR DATA TABLE  */
  data_table = (DSPFix24 *) calloc(data_table_size,sizeof(DSPFix24));
  if (data_table == NULL)
    return(NULL);
  
  /*  DEFAULT OSCILLATOR FREQUENCY  */
  table_inc = (float)(WAVE_TABLE_SIZE * OSC_FREQ_DEF)/SAMPLE_RATE;
  data_table[0] = DSPIntToFix24((int)table_inc);
  data_table[1] = DSPFloatToFix24(table_inc - (float)((int)table_inc));
  rc_scale = scale_rc / (2.0 * sin(OSC_FREQ_DEF * PI_DIV_SR));
  data_table[2] = DSPIntToFix24((int)rc_scale);
  data_table[3] = DSPFloatToFix24(rc_scale - (float)((int)rc_scale));
  
  /*  DEFAULT OSCILLATOR VOLUME  */
  data_table[4] = DSPFloatToFix24(scaled_volume(OSC_VOL_DEF));
  
  /*  DEFAULT MASTER VOLUME  */
  data_table[5] = DSPFloatToFix24(scaled_volume(MASTER_VOL_DEF));
  
  /*  DEFAULT ASPIRATION VOLUME  */
  data_table[6] = DSPFloatToFix24(scaled_volume(ASP_VOL_DEF));
  
  /*  DEFAULT FRICATION VOLUME  */
  data_table[7] = DSPFloatToFix24(scaled_volume(FRIC_VOL_DEF));
  
  /*  DEFAULT BYPASS REGISTER  */
  data_table[8] = DSPIntToFix24(BYPASS_REG_DEF);

  /*  DEFAULT BALANCE  */
  data_table[9] = DSPFloatToFix24((BALANCE_DEF * 0.5) + 0.5);

  /*  DEFAULT NASAL BYPASS  */
  data_table[10] = DSPFloatToFix24(NASAL_BYPASS_DEF);
  
  /*  DEFAULT R1 FREQUENCY AND BANDWIDTH  */
  data_table[11] = DSPFloatToFix24(R1_FREQ_DEF/SAMPLE_RATE);
  data_table[12] = DSPFloatToFix24(R1_BW_DEF/SAMPLE_RATE);
  
  /*  DEFAULT R2 FREQUENCY AND BANDWIDTH  */
  data_table[13] = DSPFloatToFix24(R2_FREQ_DEF/SAMPLE_RATE);
  data_table[14] = DSPFloatToFix24(R2_BW_DEF/SAMPLE_RATE);
  
  /*  DEFAULT R3 FREQUENCY AND BANDWIDTH  */
  data_table[15] = DSPFloatToFix24(R3_FREQ_DEF/SAMPLE_RATE);
  data_table[16] = DSPFloatToFix24(R3_BW_DEF/SAMPLE_RATE);
  
  /*  DEFAULT R4 FREQUENCY AND BANDWIDTH  */
  data_table[17] = DSPFloatToFix24(R4_FREQ_DEF/SAMPLE_RATE);
  data_table[18] = DSPFloatToFix24(R4_BW_DEF/SAMPLE_RATE);
  
  /*  DEFAULT FRICATION RESONATOR FREQUENCY AND BANDWIDTH  */
  data_table[19] = DSPFloatToFix24(FR_FREQ_DEF/SAMPLE_RATE);
  data_table[20] = DSPFloatToFix24(FR_BW_DEF/SAMPLE_RATE);

  /*  DEFAULT NASAL NOTCH FILTER FREQUENCY AND BANDWIDTH  */
  set_notch_filter_coefficients(NNF_FREQ_DEF,NNF_BW_DEF,&a,&b,&c,&d);
  data_table[21] = DSPFloatToFix24(a);
  data_table[22] = DSPFloatToFix24(b);
  data_table[23] = DSPFloatToFix24(c);
  data_table[24] = DSPFloatToFix24(d);

  
  /*  SET BALANCE OF TABLE TO ZERO  */
  for (i = 25; i < data_table_size; i++)
    data_table[i] = DSPIntToFix24(0);
  
  /*  RETURN THE NEWLY CREATED TABLE  */
  return(data_table);
}



/******************************************************************************
*
*	function:	set_bypass
*
*	purpose:	Sets a bit off or on in the specified bypass register.
*
*	internal
*	functions:	none
*
*	library
*	functions:	none
*
******************************************************************************/

void set_bypass(int value, int pos, int *bypass_register)
{
    /*  TURN OFF BIT AT pos POSITION  */
    *bypass_register &= (~(1 << pos));

    /*  IF value IS NON-ZERO, THEN SET THE BIT  */
    if (value)
	*bypass_register |= (1 << pos);
}



/******************************************************************************
*
*	function:	bypass_value
*
*	purpose:	Returns a 1 if the specified bit is set, 0 otherwise.
*
*	internal
*	functions:	none
*
*	library
*	functions:	none
*
******************************************************************************/

int bypass_value(int pos, int *bypass_register)
{
    /*  RETURN A 1, IF BYPASS HAS BIT SET AT pos POSITION  */
    /*  ELSE RETURN 0  */
    if (*bypass_register & (1 << pos))
	return(1);
    else
	return(0);
}



/******************************************************************************
*
*	function:	set_resonator_coefficients
*
*	purpose:	Calculates the coefficient values for resonator filters
*                       given the frequency and bandwidth.
*
*	internal
*	functions:	none
*
*	library
*	functions:	exp, cos
*
******************************************************************************/

void set_resonator_coefficients(frequency, bandwidth, a, b, c)
     float frequency, bandwidth, *a, *b, *c;
{
    float r;

    r = exp(-PIT * bandwidth);
    *c = -(r * r) / 2.0;

    *b = r * cos(TWOPIT * frequency);
    *a = 0.5 - (*b) - (*c);
}





/******************************************************************************
*
*	function:	set_notch_filter_coefficients
*
*	purpose:	Calculates the notch filter coefficients given
*                       the frequency and bandwidth.
*
*	internal
*	functions:	none
*
*	library
*	functions:	cos, tan
*
******************************************************************************/

void set_notch_filter_coefficients(float frequency, float bandwidth, float *a,
				   float *b, float *c, float *d)
{
    float cos_theta, x;

    cos_theta = cos(frequency * TWO_PI_DIV_SR);
    x = tan(bandwidth * PI_DIV_SR);

    *d = -0.5 * ((1.0 - x) / (1.0 + x));
    *a = (0.5 - (*d)) / 2.0;
    *b = -2.0 * (*a) * cos_theta;
    *c = (0.5 - (*d)) * cos_theta;
}




/******************************************************************************
*
*	function:	amplitude
*
*	purpose:	Converts dB to amplitude value. (Now obsolete)
*
*	internal
*	functions:	none
*
*	library
*	functions:	pow
*
******************************************************************************/

float amplitude(float decibel_level)
{
    /*  CONVERT 0-60 RANGE TO -60-0 RANGE  */
    decibel_level -= VOL_MAX;

    /*  IF -60 OR LESS, RETURN AMPLITUDE OF 0  */
    if (decibel_level <= (-VOL_MAX))
	return(0.0);

    /*  IF 0 OR GREATER, RETURN AMPLITUDE OF 1  */
    if (decibel_level >= 0.0)
	return(1.0);

    /*  ELSE RETURN INVERSE LOG VALUE  */
    return(pow(10.0,(decibel_level/20.0)));
}



/******************************************************************************
*
*	function:	scaled_volume
*
*	purpose:	Converts 0-60 dB to a fractional value suitable for
*                       the conversion routines now on the DSP.
*
*	internal
*	functions:	none
*
*	library
*	functions:	none
*
******************************************************************************/

float scaled_volume(float decibel_level)
{
  /*  MAKE SURE THE DECIBEL_LEVEL IS IN RANGE  */
  if (decibel_level < 0.0)
    decibel_level = 0.0;
  else if (decibel_level > (float)VOL_MAX)
    decibel_level = (float)VOL_MAX;

  /*  RETURN THE RIGHT SHIFTED (FRACTIONAL) VALUE  */
  return(decibel_level/AMPLITUDE_SCALE);
}



/******************************************************************************
*
*	function:	convert_to_pitch
*
*	purpose:	Converts a given frequency to (fractional) semitone;
*                       0 = middle C.
*
*	internal
*	functions:	none
*
*	library
*	functions:	log10, pow
*
******************************************************************************/

float convert_to_pitch(float frequency)
{
    return(12.0 *
	   log10(frequency/(PITCH_BASE * pow(2.0,(PITCH_OFFSET/12.0)))) *
	   LOG_FACTOR);
}



/******************************************************************************
*
*	function:	convert_to_frequency
*
*	purpose:	Converts a given pitch (0 = middle C) to the
*                       corresponding frequency.
*
*	internal
*	functions:	none
*
*	library
*	functions:	pow
*
******************************************************************************/

float convert_to_frequency(float pitch)
{
    return(PITCH_BASE * pow(2.0,(((float)(pitch+PITCH_OFFSET))/12.0)));
}
