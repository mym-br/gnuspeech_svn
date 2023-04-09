
#import <appkit/appkit.h>

@interface MyController:Object
{
	id	passwordField;
	id	regStatusField;
	id	regButton;
	id	mySpeech;

	int	passwordTries;
}

- appDidInit:sender;
- registerDemo:sender;

@end
