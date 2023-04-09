#import "diphone_module.h"
#import <stdio.h>
#import <sys/param.h>
#import <mach.h>
#import <stdlib.h>

void main(void)
{
  vm_address_t diphone_page;
  char phone1[13], phone2[13], category[13], parameter[13];

  /*  PLACE TO STORE FULL PATHNAMES  */
  char degas_pathname[MAXPATHLEN];
  char cache_preload_pathname[MAXPATHLEN];

  /*  PARAMETER LIST;  ORDER & NUMBER OF PARAMETERS CAN VARY;
      BE SURE TO END LIST WITH A NULL  */
  char *parameters[] = {"ax","f1","f2","f3","f4","ah1","ah2",
			"fh2","bwh2","fnnf","nb","micro",NULL};

  /*  ASK FOR FULL DEGAS FILE PATH NAME  */
  printf("Enter DEGAS file full path name:  ");
  scanf("%s",&degas_pathname);

  /*  ASK FOR COMPLETE DIPHONE PRELOAD PATH NAME  */
  printf("Enter diphone preload file full path name:  ");
  scanf("%s",&cache_preload_pathname);

  /*  INITIALIZE DIPHONE MODULE WITH SPECIFIED FILE AND PARAMETER LIST  */
  if (init_diphone_module(degas_pathname,parameters,cache_preload_pathname) != 0) {
    printf("Could not init diphone module\nAborting...\n");
    exit(-1);
  }


  /*  TEST CALCULATION OF DIPHONE, OTHER FUNCTION CALLS  */
  for (;;) {
    /*  QUERY FOR DIPHONE  */
   query1:
    printf("\nEnter phone 1:  ");
    scanf("%s",&phone1);
    if (!validPhone(phone1)) {
      printf(" %s is NOT a valid phone\n",phone1);
      goto query1;
    }

   query2:
    printf("Enter phone 2:  ");
    scanf("%s",&phone2);
    if (!validPhone(phone2)) {
      printf(" %s is NOT a valid phone\n\n",phone2);
      goto query2;
    }

    /*  GIVE ADDRESS AND DURATION OF CALCULATED DIPHONE  */
    diphone_page = paged_diphone(phone1,phone2);
    printf(" diphone_page = 0x%-X\n",diphone_page);
    printf(" diphone duration = %-d\n",diphone_duration(phone1,phone2));

    /*  QUERY FOR PHONE & CATEGORY; TELL IF A MEMBER OF CATEGORY  */
   query3:
    printf("Enter a phone:  ");
    scanf("%s",&phone1);
    if (!validPhone(phone1)) {
      printf(" %s is NOT a valid phone\n",phone1);
      goto query3;
    }

    printf("Enter a category:  ");
    scanf("%s",&category);
    if (phoneInCategory(phone1,category))
      printf(" %s IS a %s.\n",phone1,category);
    else
      printf(" %s is NOT a %s.\n",phone1,category);

    /*  QUERY FOR PHONE AND PARAMETER; GIVE TARGET VALUE OF THAT PARAMETER  */
   query4:
    printf("Enter a phone:  ");
    scanf("%s",&phone1);
    if (!validPhone(phone1)) {
      printf(" %s is NOT a valid phone\n",phone1);
      goto query4;
    }
    printf("Enter a parameter:  ");
    scanf("%s",&parameter);
    printf(" Target value for %s is:  %.2f\n",parameter,targetValue(phone1,parameter));
  }
}
