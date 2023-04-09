
#import <appkit/appkit.h>

#ifdef SPEECH
#import <TextToSpeech/TextToSpeech.h>
#endif

#define INFO_TALK		0
#define INFO_TTY_PROCESS	1
#define INFO_USER_PROCESS	2
#define INFO_LOGOUT		3

#define SPEECHOFF		0
#define ANYUSER			1
#define OTHERUSERS		2
#define REMOTEUSERS		3

@interface InfoMgr:Object
{
	id	defaultManager;
	id	mainObject;

	id	generalView;
	id	iconInfoView;
	id	infoView;
	id	speechView;
	id	TextToSpeechView;
	id	WorkSpaceView;
	id	speechControlView;
	id	window;
	id	scrollView;

	id	whenToSpeak;
	id	speakLog;
	id	doubleClickAction;
	id	confirmDoubleClick;
	id	speakMessages;

#ifdef SPEECH
	TextToSpeech *mySpeech;
#endif
}

- init;
- initDefaults;
- switchViews:sender;
-(int) doubleClickEvent;
-(int) confirmDoubleClick:(const char *) message;
- cleanUp;
- enableSpeech:sender;
- notifyLaunch: (const char *) appName;
- notifyTerminate: (const char *) appName;

#ifdef SPEECH
- initSpeech:(const char *) dictPath;
- speakLoginMessage:(const char *) user tty:(const char *) tty host:(const char *) host;
- speakLogoutMessage:(const char *) user tty:(const char *) tty host:(const char *) host;
- speakFormatString:(const char *) format name:(const char *) user tty:(const char *) tty host:(const char *) host;
#endif


@end
