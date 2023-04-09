
#import "DefaultMgr.h"
#import "WhosOnFirstDefaults.h"
#import <string.h>
#import <stdlib.h>

	
/*
	Revision Information
	$Author: rao $
	$Date: 2002-03-21 16:49:49 $
	$Revision: 1.1 $
	$Source: /Users/dalmazio/cvsroot/gnuspeech/trillium/ObjectiveC/WhosOnFirst/DefaultMgr.m,v $
	$State: Exp $
*/

/*===========================================================================

	File: DefaultMgr.m

	Purpose: All defaults database access/storage is handled in this
		file.

		This object provides two methods for each default database
		item.  One method sets the item and the other returns the 
		current value of the item.

		It has been programmed this way in order to make additions
		to the defaults database for WhosOnFirst easier.

	NOTE: All default "#defines" are in file "WhosOnFirstDefaults.h"

===========================================================================*/

@implementation DefaultMgr

+initialize
{
	NXRegisterDefaults(NXDEFAULT_OWNER, WhosOnFirstDefaults);
	return self;
}

- updateDefaults
{
	NXUpdateDefaults();
	return self;
}

- writeDefaults
{
	NXWriteDefaults(NXDEFAULT_OWNER, WhosOnFirstDefaults);
	return self;
}

- (BOOL)speakLogin
{
const char *temp;

	temp = NXGetDefaultValue(NXDEFAULT_OWNER, NXDEFAULT_SPEAK_LOGIN);
	if (!strcmp(temp,"NO")) return NO;
	else return YES;
}

- setSpeakLogin:(BOOL) value
{
	if(value)
		NXWriteDefault(NXDEFAULT_OWNER,NXDEFAULT_SPEAK_LOGIN,"YES");
	else
		NXWriteDefault(NXDEFAULT_OWNER,NXDEFAULT_SPEAK_LOGIN,"NO");
	return self;
}

- (BOOL)speakLogout
{
const char *temp;

	temp = NXGetDefaultValue(NXDEFAULT_OWNER, NXDEFAULT_SPEAK_LOGOUT);
	if (!strcmp(temp,"NO")) return NO;
	else return YES;
}

- setSpeakLogout:(BOOL) value
{
	if(value)
		NXWriteDefault(NXDEFAULT_OWNER,NXDEFAULT_SPEAK_LOGOUT,"YES");
	else
		NXWriteDefault(NXDEFAULT_OWNER,NXDEFAULT_SPEAK_LOGOUT,"NO");

	return self;
}

- (int) whenToSpeak
{
	return (atoi(NXGetDefaultValue(NXDEFAULT_OWNER, NXDEFAULT_WHEN_TO_SPEAK)));
}

- setWhenToSpeak:(int) value
{
char temp[15];

	sprintf(temp,"%d", value);
	NXWriteDefault(NXDEFAULT_OWNER,NXDEFAULT_WHEN_TO_SPEAK,temp);
	return self;
}

- (const char *) loginMessage
{
	return (NXGetDefaultValue(NXDEFAULT_OWNER, NXDEFAULT_LOGIN_MESSAGE));
}

- setLoginMessage:(const char *) message
{
	NXWriteDefault(NXDEFAULT_OWNER,NXDEFAULT_LOGIN_MESSAGE,message);
	return self;
}

- (const char *)logoutMessage
{
	return (NXGetDefaultValue(NXDEFAULT_OWNER, NXDEFAULT_LOGOUT_MESSAGE));
}

- setLogoutMessage:(const char *) message
{
	NXWriteDefault(NXDEFAULT_OWNER,NXDEFAULT_LOGOUT_MESSAGE,message);
	return self;
}

- (int)doubleClickAction
{
	return (atoi(NXGetDefaultValue(NXDEFAULT_OWNER, NXDEFAULT_DOUBLE_CLICK_ACTION)));
}

- setDoubleClickAction:(int) value
{
char temp[15];

	sprintf(temp,"%d", value);
	NXWriteDefault(NXDEFAULT_OWNER,NXDEFAULT_DOUBLE_CLICK_ACTION,temp);
	return self;
}

- (BOOL)doubleClickConfirm
{
const char *temp;

	temp = NXGetDefaultValue(NXDEFAULT_OWNER, NXDEFAULT_CONFIRM_DOUBLE_CLICK);
	if (!strcmp(temp,"NO")) return NO;
	else return YES;
}

- setDoubleClickConfirm:(BOOL) value
{

	if(value)
		NXWriteDefault(NXDEFAULT_OWNER,NXDEFAULT_CONFIRM_DOUBLE_CLICK,"YES");
	else
		NXWriteDefault(NXDEFAULT_OWNER,NXDEFAULT_CONFIRM_DOUBLE_CLICK,"NO");
	return self;
}

@end
