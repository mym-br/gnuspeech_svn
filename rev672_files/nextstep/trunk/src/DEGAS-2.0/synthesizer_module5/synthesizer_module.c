/*  INCLUDE FILES  ***********************************************************/
#import <stdio.h>
#import <mach.h>
#import <cthreads.h>
#import <sound/sound.h>
#import <sound/sounddriver.h>
#import <dsp/dsp.h>
#import <math.h>
#import "synthesizer_module.h"

/*  DSP CORE FILE  */
#define DSPCORE "dspcore.h"

/*  EXTERNAL GLOBAL VARIABLES  ***********************************************/

/*  SYNTHESIZER READ POINTER INTO PAGED TABLE MEMORY  */
vm_address_t synth_read_ptr;

/*  SCALING GLOBALS  */
float scale_rc;


/*  STATIC GLOBAL VARIABLES (LOCAL TO THIS FILE)  ****************************/

/*  GLOBAL VARIABLES FOR SIGNALLING BETWEEN SYNTH AND CONTROL THREADS  */
static int synth_control;
static int synth_run_ack;
static int page_request;
static int page_request_ack;
static int stream_status;
static cthread_t synthesizer_cthread;
static thread_t main_thread, synthesizer_thread;

/*  MISC.  */
static kern_return_t k_err;
static port_t dev_port, owner_port, cmd_port, read_port, write_port, reply_port;
static DSPFix24 *wave_table;
static msg_header_t *reply_msg;

static int prefill_count;
static vm_address_t pad_page;


/*  STATIC GLOBAL FUNCTIONS (LOCAL TO THIS FILE)  ****************************/

static int initialize_synthesizer(void);
static void synthesizer(int arg);
static void await_synth_start(void);
static int grab_and_initialize_DSP(void);
static int relinquish_DSP(void);
static void request_new_page(void);
static void process_page(void);
static void flush_input_pages(void);
static void queue_page(void);
static void queue_pad_page(void);
static void resume_stream(void);
#if DEBUG
static void write_started(void *arg, int tag);
static void write_completed(void *arg, int tag);
static void under_run(void *arg, int tag);
#endif
static void await_write_done_message(void);
static void pause_synth(void);
static DSPFix24 *new_gp_table(float tp, float tn, int wave_table_size);



/******************************************************************************
*
*	function:	initialize_synthesizer
*
*	purpose:	Initializes variables used in synthesizer thread,
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

static int initialize_synthesizer(void)
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

  /*  ALLOCATE MEMORY FOR RETURN MESSAGE FROM SOUND DRIVER  */
  reply_msg = (msg_header_t *)malloc(MSG_SIZE_MAX);
  if (reply_msg == NULL)
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
*	function:	synthesizer
*
*	purpose:	Main event loop for synthesizer.  This function is
*                       forked by spawn_synthesizer_thread.
*
*	internal
*	functions:	flush_input_pages, relinquish_DSP, await_synth_start,
*                       request_new_page, process_page
*
*	library
*	functions:	none
*
******************************************************************************/

static void synthesizer(int arg)
{
  /*  WHEN THREAD SPAWNED, THE SYNTHESIZER WILL BE IN PAUSE STATE  */
  synth_control = ST_PAUSE;
  
  /*  JUMP TO MIDDLE OF LOOP WHERE WAITING FOR SYNTH START  */
  goto start;
  
  /*  EVENT LOOP  */
  while(1) {
    if (synth_control == ST_PAUSE) {
      flush_input_pages();
      relinquish_DSP();
      /*  BLOCK UNTIL CONTROL THREAD SIGNALS TO START  */
      start:  await_synth_start();
    }
    
    /*  REQUEST THE CONTROL THREAD TO UPDATE PAGE POINTER  */
    request_new_page();
    
    /*  SEND THE PAGE TO THE SYNTHESIS PROGRAM ON THE DSP  */
    process_page();
  }
}



/******************************************************************************
*
*	function:	await_synth_start
*
*	purpose:	Waits until control thread asks to start synthesizer,
*                       and then tries to grab the DSP/DAC device.  Returns
*                       an acknowledge depending upon success.
*
*	internal
*	functions:	grab_and_initialize_DSP
*
*	library
*	functions:	thread_switch, thread_suspend
*
******************************************************************************/

static void await_synth_start(void)
{
  /*  MAKE SURE VARIABLES ARE INITIALIZED  */
  page_request = ST_NO;
  synth_run_ack = page_request_ack = ST_NO_ACK;
  prefill_count = PREFILL_SIZE;

  while (1) {
    /*  PUT SYNTH THREAD TO SLEEP;  THE CONTROL THREAD MUST WAKE US UP  */
    thread_suspend(synthesizer_thread);
    /*  WAIT FOR CONTROL THREAD TO SIGNAL START  */
    while (synth_control == ST_PAUSE)
      thread_switch(main_thread, SWITCH_OPTION_NONE, 0);
    /*  TRY TO GRAB THE DSP.  IF SUCCESSFUL, SIGNAL TO THE CONTROL THREAD
	WITH ST_SUCCESS ACK.  IF THE DSP IS BUSY, SIGNAL TO THE CONTROL THREAD
	WITH THE ST_DSP_BUSY ACK, AND AWAIT ANOTHER START SIGNAL  */
    if (grab_and_initialize_DSP() == ST_NO_ERROR) {
      synth_run_ack = ST_SUCCESS;
      break;
    }
    else {
      synth_run_ack = ST_DSP_BUSY;
      synth_control = ST_PAUSE;
    }
  }
}



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
*                       snddriver_stream_control, set_resonator_coefficients
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

  /*  GET CONTROL OF DSP AND DAC  */
  dev_port = owner_port = 0;
  s_err = SNDAcquire(SND_ACCESS_DSP|SND_ACCESS_OUT,10,0,0,
		     NULL_NEGOTIATION_FUN,0,&dev_port,&owner_port); 
  if (s_err != SND_ERR_NONE)
    return(ST_ERROR);

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
  
  /*  SET UP HOST->DSP AND DSP->DAC STREAMS  */
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

  k_err = snddriver_stream_setup(dev_port, owner_port,
				 SNDDRIVER_STREAM_DSP_TO_SNDOUT_22,
			    	 DMA_OUT_SIZE, 2, 
				 LOW_WATER, HIGH_WATER,
				 &protocol, &write_port);
  if (k_err != KERN_SUCCESS)
    return(ST_ERROR);
  
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
  coefficients[1] = DSPFloatToFix24(b - 1.0); 
  coefficients[2] = DSPFloatToFix24(a - 1.0);

  k_err = snddriver_dsp_host_cmd(cmd_port, 
				 (u_int)HC_LOAD_FNR, 
				 SNDDRIVER_LOW_PRIORITY);  
  if (k_err != KERN_SUCCESS)
    return(ST_ERROR);

  k_err = snddriver_dsp_write(cmd_port,(void *)coefficients,3,
			      sizeof(DSPFix24), SNDDRIVER_LOW_PRIORITY);
  if (k_err != KERN_SUCCESS)
    return(ST_ERROR);


  /*  MAKE SURE STREAM IS IN PAUSED STATE  */
  k_err = snddriver_stream_control(read_port,0,SNDDRIVER_PAUSE_STREAM);
  if (k_err != KERN_SUCCESS)
    return(ST_ERROR);

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

  /*  GIVE UP CONTROL OVER DSP AND SOUND OUT  */
  s_err = SNDRelease(SND_ACCESS_DSP|SND_ACCESS_OUT,dev_port,owner_port);
  if (s_err != SND_ERR_NONE)
    return(ST_ERROR);
  else
    return (ST_NO_ERROR);
}



/******************************************************************************
*
*	function:	request_new_page
*
*	purpose:	Blocks until a new page is ready.
*
*	internal
*	functions:	none
*
*	library
*	functions:	thread_switch
*
******************************************************************************/

static void request_new_page(void)
{
  page_request_ack = ST_NO_ACK;
  page_request = ST_YES;

  /*  WAIT UNTIL WE GET AN ACK BACK  */
  while (page_request_ack == ST_NO_ACK)
    thread_switch(main_thread, SWITCH_OPTION_NONE, 0);

  /*  ONCE HERE, WE KNOW POINTER TO SYNTHESIZER PARAMETER
      PAGE HAS BEEN UPDATED BY THE CONTROL THREAD  */
  page_request = ST_NO;
  page_request_ack = ST_NO_ACK;
}



/******************************************************************************
*
*	function:	process_page
*
*	purpose:	Sends the page pointed to by synth_read_ptr to the
*                       synthesizer.  Does needed prefill at start to ensure
*                       uninterrupted sound out.
*
*	internal
*	functions:	queue_page, resume_stream, await_write_done_message
*
*	library
*	functions:	none
*
******************************************************************************/

static void process_page(void)
{
  if (prefill_count > 0) {
    queue_page();
    
    if ( (--prefill_count) == 0) {
      resume_stream();
      await_write_done_message();
    }
  }
  else {
    queue_page();
    await_write_done_message();
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
  register int i;

  /*  ENQUEUE A PAD PAGE (SILENCE);  ENSURES THAT DSP BUFFERS ARE FLUSHED  */
  queue_pad_page();

  /*  IF THE STREAM IS STILL PAUSED, THEN START IT  */
  /*  IN BOTH CASES, WAIT UNTIL ALL PAGES ARE WRITTEN  */
  if (stream_status != ST_RUN) {
    resume_stream();
    for (i = prefill_count; i < (PREFILL_SIZE+1); i++) {
      await_write_done_message();
    }
  }
  else {
    for (i = 1; i < (PREFILL_SIZE+1); i++) {
      await_write_done_message();
    }
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
				 0,
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
				 0,
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
*	function:	write_started, write_completed, under_run
*
*	purpose:	Handlers for messages from snddriver to reply port.
*
*	internal
*	functions:	none
*
*	library
*	functions:	fprintf
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


/******************************************************************************
*
*	function:	await_write_done_message
*
*	purpose:	Waits for write done message from snddriver.
*
*	internal
*	functions:	write_started, write_completed, under_run
*
*	library
*	functions:	msg_receive, snddriver_reply_handler, fprintf
*
******************************************************************************/

static void await_write_done_message(void)
{
#if DEBUG
  snddriver_handlers_t handlers = {0,0,write_started,write_completed,
				   0,0,0,under_run,0};
#endif

  /*  RECEIVE MESSAGES FROM SOUND DRIVER  */
  reply_msg->msg_size = MSG_SIZE_MAX;
  reply_msg->msg_local_port = reply_port;

  k_err = msg_receive(reply_msg, MSG_OPTION_NONE, 0);
  if (k_err == RCV_SUCCESS)
#if DEBUG
    k_err = snddriver_reply_handler(reply_msg,&handlers);
#else
    ;
#endif

 else
    fprintf(stderr,"msg_receive error = %-d\n",k_err);
}



/******************************************************************************
*
*	function:	pause_synth
*
*	purpose:	Sets the synth_control to paused state.
*
*	internal
*	functions:	none
*
*	library
*	functions:	none
*
******************************************************************************/

static void pause_synth(void)
{
  if (synth_control != ST_PAUSE)
    synth_control = ST_PAUSE;
}



/******************************************************************************
*
*	function:	new_gp_table
*
*	purpose:	Creates a glottal pulse wave table.
*
*	internal
*	functions:	nnint
*
*	library
*	functions:	calloc, DSPFloatToFix24, pow 
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
  t0_samples = nnint(t0 * wave_table_size);
  tp_samples = nnint(tp * wave_table_size);
  tn_samples = nnint(tn * wave_table_size);
  
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



/*****************************************************************************/
/*****************************************************************************/
/*****************************************************************************/
/*               EXTERNAL FUNCTIONS USED BY CONTROL THREAD                   */
/*****************************************************************************/
/*****************************************************************************/
/*****************************************************************************/



/******************************************************************************
*
*	function:	spawn_synthesizer_thread
*
*	purpose:	Forks the synthesizer thread and initializes it.
*
*	internal
*	functions:	initialize_synthesizer
*
*	library
*	functions:	cthread_fork, cthread_detach, cthread_thread,
*                       thread_self, thread_switch
*
******************************************************************************/

int spawn_synthesizer_thread(void)
{
  /*  INITIALIZE THE SYNTHESIZER THREAD  */
  initialize_synthesizer();

  /*  SPAWN THE SYNTH THREAD, AND SET GLOBAL THREAD IDENTIFIERS  */
  synthesizer_cthread = cthread_fork((void *)synthesizer, 0);
  cthread_detach(synthesizer_cthread);
  synthesizer_thread = cthread_thread(synthesizer_cthread);
  main_thread = thread_self();

  /*  HAND OFF TO SYNTHESIZER THREAD TO GET IT GOING  */
  thread_switch(synthesizer_thread, SWITCH_OPTION_NONE, 0);

  return(ST_NO_ERROR);
}



/******************************************************************************
*
*	function:	start_synthesizer
*
*	purpose:	Signals to the synthesizer thread that the synthesizer
*                       should start if the DSP and DAC are available.
*
*	internal
*	functions:	none
*
*	library
*	functions:	thread_switch, thread_resume
*
******************************************************************************/

int start_synthesizer(void)
{
  /*  IF SYNTH ALREADY RUNNING, RETURN  */
  if (synth_control == ST_RUN)
    return(ST_NO_ERROR);
  else {
    /*  TRY TO START SYNTH  */
    synth_run_ack = ST_NO_ACK;
    synth_control = ST_RUN;
    /*  WAKE UP THE SUSPENDED SYNTH THREAD  */
    while (thread_resume(synthesizer_thread) != KERN_SUCCESS)
      ;
    /*  WAIT UNTIL WE GET AN ACKNOWLEDGE BACK OF SOME SORT  */
    while (synth_run_ack == ST_NO_ACK)
      thread_switch(synthesizer_thread, SWITCH_OPTION_NONE, 0);

    /*  DEAL WITH ST_SUCCESS OR ST_DSP_BUSY ACK  */
    if (synth_run_ack == ST_SUCCESS)
      return(ST_NO_ERROR);
    else if (synth_run_ack == ST_DSP_BUSY)
      return(ST_ERROR);
  }
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
  /*  A BLOCKING REQUEST WAITS UNTIL SYNTH REQUESTS A PAGE.  A NON-BLOCKING
      REQUEST WILL RETURN IMMEDIATELY IF NO REQUEST IS QUEUED BY SYNTH  */
  if (blocking_request) {
    /*  WAIT UNTIL SYNTH THREAD REQUESTS A PAGE  */
    while (page_request == ST_NO)
      thread_switch(synthesizer_thread, SWITCH_OPTION_NONE, 0);
  }
  else {
    /*  IF NO REQUEST FOR A PAGE, RETURN IMMEDIATELY  */
    if (page_request == ST_NO)
      return;
  }

  /*  UPDATE POINTER SO IT POINTS AT NEW PAGE  */
  (*ptr_update_function)();

  /*  PUT SYNTH IN PAUSE STATE IF REQUESTED  */
  if (last_page)
    pause_synth();

  /*  TELL SYNTH THREAD WE'VE UPDATED PAGE POINTER  */
  page_request_ack = ST_SUCCESS;
  page_request = ST_NO;

  /*  HAND OFF TO SYNTHESIZER THREAD  */
  thread_switch(synthesizer_thread, SWITCH_OPTION_NONE, 0);
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
  
  /*  MAKE SURE TABLE SIZE IS AT LEAST 30  */
  if (data_table_size < 30)
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
  data_table[4] = DSPFloatToFix24(amplitude(OSC_VOL_DEF));
  
  /*  DEFAULT MASTER VOLUME  */
  data_table[5] = DSPFloatToFix24(amplitude(MASTER_VOL_DEF));
  
  /*  DEFAULT ASPIRATION VOLUME  */
  data_table[6] = DSPFloatToFix24(amplitude(ASP_VOL_DEF));
  
  /*  DEFAULT FRICATION VOLUME  */
  data_table[7] = DSPFloatToFix24(amplitude(FRIC_VOL_DEF));
  
  /*  DEFAULT BYPASS REGISTER  */
  data_table[8] = DSPIntToFix24(BYPASS_REG_DEF);

  /*  DEFAULT BALANCE  */
  data_table[9] = DSPFloatToFix24((BALANCE_DEF * 0.5) + 0.5);

  /*  DEFAULT NASAL BYPASS  */
  data_table[10] = DSPFloatToFix24(NASAL_BYPASS_DEF);
  
  /*  DEFAULT R1 FREQUENCY AND BANDWIDTH  */
  set_resonator_coefficients(R1_FREQ_DEF,R1_BW_DEF,&a,&b,&c);
  data_table[11] = DSPFloatToFix24(c);
  data_table[12] = DSPFloatToFix24(b - 1.0); 
  data_table[13] = DSPFloatToFix24(a - 1.0);
  
  /*  DEFAULT R2 FREQUENCY AND BANDWIDTH  */
  set_resonator_coefficients(R2_FREQ_DEF,R2_BW_DEF,&a,&b,&c);
  data_table[14] = DSPFloatToFix24(c);
  data_table[15] = DSPFloatToFix24(b - 1.0); 
  data_table[16] = DSPFloatToFix24(a - 1.0);
  
  /*  DEFAULT R3 FREQUENCY AND BANDWIDTH  */
  set_resonator_coefficients(R3_FREQ_DEF,R3_BW_DEF,&a,&b,&c);
  data_table[17] = DSPFloatToFix24(c);
  data_table[18] = DSPFloatToFix24(b - 1.0); 
  data_table[19] = DSPFloatToFix24(a - 1.0);
  
  /*  DEFAULT R4 FREQUENCY AND BANDWIDTH  */
  set_resonator_coefficients(R4_FREQ_DEF,R4_BW_DEF,&a,&b,&c);
  data_table[20] = DSPFloatToFix24(c);
  data_table[21] = DSPFloatToFix24(b - 1.0); 
  data_table[22] = DSPFloatToFix24(a - 1.0);
  
  /*  DEFAULT FRICATION RESONATOR FREQUENCY AND BANDWIDTH  */
  set_resonator_coefficients(FR_FREQ_DEF,FR_BW_DEF,&a,&b,&c);
  data_table[23] = DSPFloatToFix24(c);
  data_table[24] = DSPFloatToFix24(b - 1.0); 
  data_table[25] = DSPFloatToFix24(a - 1.0);

  /*  DEFAULT NASAL NOTCH FILTER FREQUENCY AND BANDWIDTH  */
  set_notch_filter_coefficients(NNF_FREQ_DEF,NNF_BW_DEF,&a,&b,&c,&d);
  data_table[26] = DSPFloatToFix24(a);
  data_table[27] = DSPFloatToFix24(b);
  data_table[28] = DSPFloatToFix24(c);
  data_table[29] = DSPFloatToFix24(d);

  
  /*  SET BALANCE OF TABLE TO ZERO  */
  for (i = 30; i < data_table_size; i++)
    data_table[i] = DSPIntToFix24(0);
  
  /*  RETURN THE NEWLY CREATED TABLE  */
  return(data_table);
}



/******************************************************************************
*
*	function:	nnint
*
*	purpose:	Returns nearest integer to the argument.
*
*	internal
*	functions:	none
*
*	library
*	functions:	none
*
******************************************************************************/

int nnint(float value)
{
  float remainder;
  int tr_value;
  
  tr_value = (int)value;

  remainder = value - (float)tr_value;
  if (remainder >= 0.5)
    return(tr_value + 1);
  else if (remainder <= -0.5)
    return(tr_value - 1);
  else
    return(tr_value);
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

void set_resonator_coefficients(float frequency, float bandwidth,
				float *a, float *b, float *c)
{
    float r;

    r = exp(-PIT * bandwidth);
    *c = -r * r;

    *b = 2.0 * r * cos(TWOPIT * frequency);
    *a = 1.0 - (*b) - (*c);
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
*	purpose:	Converts dB to amplitude value.
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
