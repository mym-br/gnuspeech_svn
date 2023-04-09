/******************************************************************************
*
*     test_parser_module.c
*
*     Be sure to change the paths to various files below to reflect the
*     current set up.
*
******************************************************************************/

/*  HEADER FILES  ************************************************************/
#import "parser_module.h"
#import "preditorDict.h"
#import "mainDict.h"
#import <TextToSpeech/TTS_types.h>
#import <stdio.h>
#import <ctype.h>


/*  LOCAL DEFINES  ***********************************************************/
#define SYSTEM_PATH         "/LocalLibrary/TextToSpeech/system"
#define DEGAS_PATHNAME      "/LocalLibrary/TextToSpeech/system/current.degas"
#define PREDITOR_APP_DICT   "/Accounts/schock/test.preditor"
#define PREDITOR_USER_DICT  "/Accounts/schock/personal.preditor"
#define BUFFER_SIZE         8192



/******************************************************************************
*
*	function:	main
*
*	purpose:	Tests functionality of parser_module.
*			
*       arguments:      none
*                       
*	internal
*	functions:	
*
*	library
*	functions:	
*
******************************************************************************/

void main(void)
{
  char c, answer[16], filename[24], input[1024], *output = NULL;
  FILE *fp, *fopen();
  int i, error;
  short order[4];
  preditorDict appDict, userDict;

  /*  PARAMETER LIST;  ORDER & NUMBER OF PARAMETERS CAN VARY;
      BE SURE TO END LIST WITH A NULL  */
  char *parameters[] = {"ax","f1","f2","f3","f4","ah1","ah2",
                        "fh2","bwh2","fnnf","nb","micro",NULL};


//  /*  INITIALIZE DIPHONE MODULE WITH SPECIFIED FILE AND PARAMETER LIST  */
//  if (init_diphone_module(DEGAS_PATHNAME,parameters,NULL) != 0) {
//    printf("Could not init diphone module\nAborting...\n");
//    return;
//  }

  /*  INITIALIZE PARSER MODULE  */
  init_parser_module();

  /*  INITIALIZE DICTIONARY AND CACHE  */
  init_mainDict(SYSTEM_PATH);
  
  printf("Version: %s\n", DictionaryVersion());
  printf("Compiled Version: %s\n", CompiledDictionaryVersion());
  /*  INITIALIZE DICTIONARY ORDER AND DICTIONARY PATHS  */
  preditor_open_dict(&appDict, PREDITOR_APP_DICT);
  preditor_open_dict(&userDict, PREDITOR_USER_DICT);

  order[0] = TTS_NUMBER_PARSER;
  order[1] = TTS_USER_DICTIONARY;
  order[2] = TTS_APPLICATION_DICTIONARY;
  order[3] = TTS_MAIN_DICTIONARY;

  set_dict_data(order,&userDict,&appDict);


  /*  ASK USER FOR ESCAPE CHARACTER AND INPUT FILE NAME  */
 query:
  /*  QUERY FOR ESCAPE CHARACTER  */
  printf("\nEnter esc char: ");
  scanf("%c",&c);   getchar();
  if (c == '\0' || !isascii(c)) {
    printf("Escape character must be ascii, and not NULL.\nTry again.\n");
    goto query;
  }
  
  /*  SET ESCAPE CODE  */
  set_escape_code(c);


 query2:
  /*  QUERY FOR PARSER INPUT FILENAME  */
  printf("Enter parser input filename:  ");
  scanf("%s",&filename);
  

 repeat:
  /*  OPEN FILE  */
  if ((fp = fopen(filename,"r")) == NULL) {
    printf("\nCan't find %s\nTry again.\n",filename);
    goto query2;
  }


  /*  COPY CONTENTS TO BUFFER  */
  i = 0;
  while ( ((c = getc(fp)) != EOF) && (i < BUFFER_SIZE-1) )
    input[i++] = c;
  input[i] = '\0';

  /*  PASS INPUT TO PARSER  */
  if ((error = parser(input,&output)) != TTS_PARSER_SUCCESS) {
    printf("\nError at pos %-3d\n",error);
  }
  else {
    /*  PRINT CONTENTS OF OUTPUT BUFFER  */
    printf("\nOUTPUT\n<begin>%s<end>\n",output);
  }

  /*  CLOSE FILE  */
  fclose(fp);

  /*  REPEAT?  */
  printf("\nRepeat?:  ");
  scanf("%s", &answer);
  if (answer[0] != 'n')
    goto repeat;
}
