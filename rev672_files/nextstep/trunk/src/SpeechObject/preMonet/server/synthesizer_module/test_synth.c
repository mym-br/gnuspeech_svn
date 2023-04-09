/*  REVISION INFORMATION  *****************************************************

$Author: rao $
$Date: 2002-03-21 16:49:54 $
$Revision: 1.1 $
$Source: /Users/dalmazio/cvsroot/gnuspeech/trillium/src/SpeechObject/preMonet/server/synthesizer_module/test_synth.c,v $
$State: Exp $


$Log: not supported by cvs2svn $
 * Revision 1.3  1993/12/14  20:16:47  len
 * Rewrote the module so that it is single-threaded.
 *
 * Revision 1.2  1993/11/26  04:59:26  len
 * Added the ability to send sound directly to file.
 *
 * Revision 1.1.1.1  1993/11/25  23:00:48  len
 * Initial archive of production code for the 1.0 TTS_Server (tag v5).
 *

******************************************************************************/

/*  INCLUDES  ****************************************************************/
#import <mach/mach_error.h>
#import "synthesizer_module.h"   /* NEEDED WHEN USING THE SYNTHESIZER MODULE */


/*  DEFINES  *****************************************************************/
#define PAGES_MAX 200          /*  ARBITRARY LIMIT  */


/*  GLOBAL VARIABLES (LOCAL TO THIS FILE)  ***********************************/
static int blocking, consumer_index;



/******************************************************************************
*
*	function:	main
*
*	purpose:	Example of a program which uses the synthesizer module.
*                       It spawns the synthesizer thread, and then allows the
*                       user to synthesize an arbitrary number of default
*                       synthesizer control tables.  The function
*                       "update_synth_ptr" is an example of a user supplied
*                       function used by "await_request_new_page" to update
*                       the synth_read_ptr.
*
*	internal
*	functions:	update_synth_ptr
*
*	library
*	functions:	initialize_synthesizer_module, new_default_data_table,
*                       fprintf, printf, scanf, getchar, vm_deallocate,
*                       mach_error, vm_allocate, start_synthesizer,
*                       await_request_new_page, set_synthesizer_output
*
******************************************************************************/

void main(void)
{
  int npages, oldnpages = 0, i, j, k;
  int writeToFile = 0, numberChunks = 0;
  kern_return_t k_error;
  DSPFix24 *page_start = NULL, *page_index;
  DSPFix24 *default_table;

  /*  USER SUPPLIED FUNCTION TO UPDATE THE GLOBAL synth_read_ptr  */
  void update_synth_ptr();


  /*  INITIALIZE THE SYNTHESIZER MODULE  */
  /*  THIS FUNCTION MUST BE INVOKED BEFORE ANY OTHER SYNTHESIZER
      MODULE FUNCTIONS ARE CALLED  */
  if (initialize_synthesizer_module() == ST_ERROR) {
    fprintf(stderr, "Aborting.  Could not initialize synthesizer module.\n");
    exit(-1);
  }


  /*  CREATE A DEFAULT SYNTHESIZER CONTROL TABLE  */
  default_table = new_default_data_table(DATA_TABLE_SIZE);
  if (default_table == NULL) {
    fprintf(stderr,"Couldn't create default data table.\n");
    exit(-1);
  }


  /*  QUERY FOR NUMBER OF PAGES TO CREATE  */
  while (1) {
    qnpages:
    printf("\nEnter desired number of pages:  ");
    scanf("%d",&npages);
    if (npages < 1 || npages > PAGES_MAX) {
      printf("  Illegal number of pages.  Try again.\n");
      goto qnpages;
    }
    
    /*  DEALLOCATE PAGES OF MEMORY IF ALREADY ALLOCATED BEFORE  */
    if (page_start != NULL) {
      k_error = vm_deallocate(task_self(), (vm_address_t)page_start,
			      (vm_size_t)(vm_page_size * oldnpages));
      if (k_error != KERN_SUCCESS) {
	mach_error("Trouble freeing memory", k_error);
	exit(-1);
      }
    }  
    
    /*  ALLOCATE REQUESTED NUMBER OF PAGES  */
    k_error = vm_allocate(task_self(), (vm_address_t *)&page_start, 
			  (vm_size_t)(vm_page_size * npages), 1);
    if (k_error != KERN_SUCCESS) {
      mach_error("vm_allocate returned value of ", k_error); 
      exit(-1);
    }
    oldnpages = npages;
    
    /*  FILL UP THE PAGES WITH THE DEFAULT TABLE  */
    page_index = page_start;
    for (i = 0; i < npages; i++) {
      for (j = 0; j < TABLES_PER_PAGE; j++) {
	for (k = 0; k < DATA_TABLE_SIZE; k++) {
	  *(page_index++) = default_table[k];
	}
      }
    }


    /*  QUERY USER IF BLOCKING  */
    printf("Blocking? (0 or 1):  ");
    scanf("%d",&blocking);

    
    /*  QUERY USER IF WRITE TO FILE  */
    printf("Write to file? (0 or 1):  ");
    scanf("%d",&writeToFile);
    if (writeToFile) {
      printf("Number Chunks?:  ");
      scanf("%d",&numberChunks);
    }

    
    /*  QUERY USER TO START SOUND OUT  */
    getchar();
    printf("Push return to continue:  ");
    getchar();
    

    /*  SYNTHESIZE TO FILE  */
    if (writeToFile) {
      /*  SYNTHESIZER MUST BE IN PAUSE STATE  */
      if (synth_status == ST_PAUSE) {

	/*  SET THE OUTPUT TO FILE  */
	set_synthesizer_output("/tmp/file.snd", getuid(), getgid(), numberChunks);

	/*  PROCESS EACH CHUNK  */
	while (numberChunks--) {
	  /*  LOOP UNTIL READY FOR NEXT CHUNK  */
	  while (synth_status == ST_RUN)
	    ;

	  /*  INITIALIZE THE SYNTHESIZER  */
	  if (start_synthesizer() != ST_NO_ERROR) {
	    fprintf(stderr,"DSP busy\n");
	    exit(-1);
	  }

	  /*  SEND THE PAGES TO THE SYNTHESIZER THREAD  */
	  /*  THE synth_read_ptr IS BACKED UP ONE PAGE, SINCE THE
	      update_synth_ptr FUNCTION ADVANCES THE POINTER *BEFORE*
	      THE PAGE IS SENT TO THE SYNTHESIZER  */
	  synth_read_ptr = (vm_address_t)page_start - vm_page_size;

	  if (blocking) {
	    for (i = 0; i < npages; i++) {
	      /*  BLOCK WHILE WAITING; ALSO, MAKE SURE TO SIGNAL THE LAST PAGE  */
	      await_request_new_page(ST_YES,
				     (i == (npages-1)) ? ST_YES : ST_NO,
				     update_synth_ptr);
	    }
	  }
	  else {
	    consumer_index = 0;
	    while (consumer_index < npages) {
	      /*  DON'T BLOCK WHILE WAITING; MAKE SURE TO SIGNAL THE LAST PAGE  */
	      await_request_new_page(ST_NO,
				     (consumer_index == (npages-1)) ? ST_YES : ST_NO,
				     update_synth_ptr);
	    }
	  }
	}
      }
      /*  EXIT IF SYNTHESIZER STILL RUNNING  */
      else {
	  fprintf(stderr,"synth_status still ST_RUN\n");
	  exit(-1);
      }
    }
    /*  SYNTHESIZE TO DAC  */
    else {
      /*  SYNTHESIZER MUST BE IN PAUSE STATE  */
      if (synth_status == ST_PAUSE) {
	/*  INDICATE THAT OUTPUT IS TO DAC (I.E. NOT TO FILE)  */
	set_synthesizer_output(NULL, 0, 0, 0);

	/*  INITIALIZE THE SYNTHESIZER  */
	if (start_synthesizer() != ST_NO_ERROR) {
	  fprintf(stderr,"DSP busy\n");
	  exit(-1);
	}

	/*  SEND THE PAGES TO THE SYNTHESIZER THREAD  */
	/*  THE synth_read_ptr IS BACKED UP ONE PAGE, SINCE THE
	    update_synth_ptr FUNCTION ADVANCES THE POINTER *BEFORE*
	    THE PAGE IS SENT TO THE SYNTHESIZER  */
	synth_read_ptr = (vm_address_t)page_start - vm_page_size;
	
	if (blocking) {
	  for (i = 0; i < npages; i++) {
	    /*  BLOCK WHILE WAITING; ALSO, MAKE SURE TO SIGNAL THE LAST PAGE  */
	    await_request_new_page(ST_YES,
				   (i == (npages-1)) ? ST_YES : ST_NO,
				   update_synth_ptr);
	  }
	}
	else {
	  consumer_index = 0;
	  while (consumer_index < npages) {
	    /*  DON'T BLOCK WHILE WAITING; MAKE SURE TO SIGNAL THE LAST PAGE  */
	    await_request_new_page(ST_NO,
				   (consumer_index == (npages-1)) ? ST_YES : ST_NO,
				   update_synth_ptr);
	  }
	}
      }
      /*  EXIT IF SYNTHESIZER STILL RUNNING  */
      else {
	  fprintf(stderr,"synth_status still ST_RUN\n");
	  exit(-1);
      }
    }
  }
}



/******************************************************************************
*
*	function:	update_synth_ptr
*
*	purpose:	A user supplied function which updates the
*                       synth_read_ptr as needed by the synthesizer module
*                       function "await_request_new_page".
*
*	internal
*	functions:	none
*
*	library
*	functions:	none
*
******************************************************************************/

void update_synth_ptr(void)
{
  synth_read_ptr += vm_page_size;
  if (!blocking)
    consumer_index++;
}
