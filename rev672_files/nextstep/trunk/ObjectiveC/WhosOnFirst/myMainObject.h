
/* myMainObject.h */

#import <appkit/Application.h>
#import <appkit/Window.h>
#import <appkit/NXImage.h>
#import <appkit/graphics.h>
#import <dpsclient/psops.h>
#import <dpsclient/wraps.h>
#import <libc.h>
#import <strings.h>
#import <defaults/defaults.h>

#import "IconView.h"
#import "structs.h"

int nextX, nextY;
int startX, startY;
struct record *users, *last;
NXStream *utmpFile;
id c_self;

@interface myMainObject:Object
{
	id icon;		/* Pointer to Icon View */
	id iconWindow;		/* Pointer to Icon Window */
	id mySpeech;
	id scrollView;
	id iconMatrix;
	id localInfoMgr;
	id owner;

	id mailParser;
}

- appDidInit:sender;
- (const char *) appDirectory;
- newIconUser: (const char *)name tty: (const char *)ttystr host:(const char *)host xcoord: (float)x ycoord: (float)y;
- terminate:sender;

- app: sender applicationDidLaunch:(const char *)appName;
- app: sender applicationDidTerminate:(const char *)appName;


@end
