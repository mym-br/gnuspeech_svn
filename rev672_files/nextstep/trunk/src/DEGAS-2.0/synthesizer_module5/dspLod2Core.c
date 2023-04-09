/*  THIS PROGRAM CONVERTS dsp.lod TO dspcore.h */


#import <sound/sound.h>
#import <sound/sounddriver.h>
#import <dsp/dsp.h>
#import <stdlib.h>


void main(int argc, char *argv[])
{
  SNDSoundStruct *dspStruct;
  char *struct_ptr;
  int s_err, end, i, j;
  FILE *fopen(), *fp1;

  /*  MAKE SURE RIGHT NUMBER OF ARGUMENTS  */
  if (argc != 2) {
    fprintf(stderr,"Usage:  dspLod2Core infile.lod\n");
    exit(-1);
  }
  
  /*  PARSE THE .LOD ASSEMBLY FILE AND PUT INTO STRUCT  */
  s_err = SNDReadDSPfile(argv[1],&dspStruct,NULL);
  if (s_err != SND_ERR_NONE) {
    fprintf(stderr,"Cannot find or parse %s: %s\n",argv[1],SNDSoundError(s_err));
    exit(-1);
  }

  /*  OPEN THE DSPCORE.H FILE  */
  fp1 = fopen("dspcore.h","w");
  struct_ptr = (char *)dspStruct;
  end = (dspStruct->dataLocation) + (dspStruct->dataSize);
  
  /*  CREATE DSPCORE.H FILE  */
  fprintf(fp1,"/*\n *  Created by dspLod2Core from dsp.lod\n */\n\n");
  fprintf(fp1,"static char dspcore[%-d] = {\n",end);
  for (i = 0, j = 1; i < end; i++, struct_ptr++, j++) {
    fprintf(fp1,"%4d",(int)*struct_ptr);
    if(i != (end-1))
      fprintf(fp1,",");
    if (j >= 10) {
      j = 0;
      fprintf(fp1,"\n");
    }
  }
  fprintf(fp1,"};");
  fclose(fp1);
}
