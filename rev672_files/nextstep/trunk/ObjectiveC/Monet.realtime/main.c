#import <stdio.h>
#import "structs.h"

#import "RealTimeController.h"

struct _calc_info calc_info;

float *tg_parameters = NULL;
int *tg_count = NULL;

main()
{
RealTimeController *realTime;

	calc_info.status = IDLE;
	realTime = [[RealTimeController alloc] initWithFile:"/LocalLibrary/TextToSpeech/system/diphones.monet"];

	printf("Here we go \n");
	[realTime synthesizeString:"/c // /3 # h_e./*l_uh_uu / ^ // /0 /_h_ah_uu ar_r /l /*y_uu # // /c"];
	printf("Here we go \n");
	[realTime synthesizeString:"/c // /3 # h_e./*l_uh_uu / ^ // /0 /_h_ah_uu ar_r /l /*y_uu # // /c"];
	printf("Here we go \n");
	[realTime synthesizeString:"/c // /3 # h_e./*l_uh_uu / ^ // /0 /_h_ah_uu ar_r /l /*y_uu # // /c"];
	printf("Here we go \n");


	exit(0);
}

poll_port(x)
int x;
{
	return 0;
}