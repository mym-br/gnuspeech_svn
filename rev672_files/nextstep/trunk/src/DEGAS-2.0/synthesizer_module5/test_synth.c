/*  INCLUDES  ****************************************************************/

#import <mach_error.h>
#import "synthesizer_module.h"   /* NEEDED WHEN USING THE SYNTHESIZER MODULE */


/*  DEFINES  *****************************************************************/

#define PAGES_MAX 200          /*  ARBITRARY LIMIT  */



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
*	functions:	spawn_synthesizer_thread, new_default_data_table,
*                       fprintf, printf, scanf, getchar, vm_deallocate,
*                       mach_error, vm_allocate, start_synthesizer,
*                       await_request_new_page
*
******************************************************************************/

void main(void)
{
  int npages, oldnpages = 0, i, j, k;
  kern_return_t k_error;
  DSPFix24 *page_start = NULL, *page_index;
  DSPFix24 *default_table;

  /*  USER SUPPLIED FUNCTION TO UPDATE THE GLOBAL synth_read_ptr  */
  void update_synth_ptr();


  /*  SPAWN THE SYNTHESIZER THREAD  */
  /*  THIS FUNCTION MUST BE USED FIRST BEFORE ANY OTHER SYNTHESIZER
      MODULE FUNCTIONS CAN BE USED  */
  spawn_synthesizer_thread();

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
    
    /*  QUERY USER TO START SOUND OUT  */
    getchar();
    printf("Push return to continue:  ");
    getchar();
    
    /*  START THE SYNTHESIZER  */
    if (start_synthesizer() != ST_NO_ERROR) {
      fprintf(stderr,"DSP busy\n");
      exit(-1);
    }
    
    /*  SEND THE PAGES TO THE SYNTHESIZER THREAD  */
    /*  THE synth_read_ptr IS BACKED UP ONE PAGE, SINCE THE
	update_synth_ptr FUNCTION ADVANCES THE POINTER *BEFORE*
	THE PAGE IS SENT TO THE SYNTHESIZER  */
    synth_read_ptr = (vm_address_t)page_start - vm_page_size;
    for (i = 0; i < npages; i++) {
      /*  BLOCK WHILE WAITING; ALSO, MAKE SURE TO SIGNAL THE LAST PAGE  */
      await_request_new_page(ST_YES,
			     (i == (npages-1)) ? ST_YES : ST_NO,
			     update_synth_ptr);
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
}
