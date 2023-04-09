/*===========================================================================

	Player.m - an object to play digital sounds.
	Author: Robert D. Poor, NeXT Technical Support
	Copyright 1989 NeXT, Inc.  Next, Inc. is furnishing this software
	for example purposes only and assumes no liability for its use.
	06-Dec-89

===========================================================================*/

/*===========================================================================

	The Player object provides a common superclass for a family of
	playing objects.  (Currently this is a family of one, the
	DACPlayer object, but this could be extended to play data out
	over the DSP port.  The Player object keeps track of the current
	playing state and translates stop/pause/play messages into
	lower level messages (playerPrepare, playerStart, etc).

	This object must be subclassed in order to do anything useful.
	See the DACPlayer for an example.

===========================================================================*/

#import <stdlib.h>
#import <stdio.h>
#import <appkit/Panel.h>
#import <sound/sounddriver.h>
#import <sound/soundstruct.h>
#import "Player.h"
#import "errors.h"

@implementation Player:Object

+ new
{
	self = [super new];

	bytesPlayed = 0;
	playerState = PLA_STOPPED;
	regions = NULL;
	[self setupRegions:4*vm_page_size:3];		/* allocate some regions */

	return self;
}

- free
{
	[self freeRegions];
	return [super free];
}

- stop
{
	NXRunAlertPanel("Alert", "The method %s must be implemented in a subclass", NULL,
			NULL,NULL,"stop");
	return self;
}

- prepare
{
	NXRunAlertPanel("Alert", "The method %s must be implemented in a subclass",NULL,
			NULL,NULL,"prepare");
	return self;
}

- run
{
	NXRunAlertPanel("Alert", "The method %s must be implemented in a subclass",
			NULL,NULL,NULL,"run");
	return self;
}

- pause
{
	NXRunAlertPanel("Alert", "The method %s must be implemented in a subclass",
			NULL,NULL,NULL,"pause");
	return self;
}

- (Pla_state_t)state
{
	return playerState;
}

- (int)bytesPlayed
{
	return bytesPlayed;
}

- delegate
{
	return delegate;
}

- setDelegate:anObject
{
	delegate = anObject;
}

- (int)regionSize
{
	return regionSize;
}

- setRegionSize:(int)nbytes
{
	return [self setupRegions:nbytes:regionCount];
}

- (int)regionCount
{
	return regionCount;
}

- setRegionCount:(int)nregions
{
	return [self setupRegions:regionSize:nregions];
}

- freeRegions		/* Release any allocated regions. */
{
	int i, r;

	if (regions)
	{
		for (i=0;i<regionCount;i++)
	    		r = vm_deallocate(task_self(), regions[i], regionSize);

		free(regions);
		regions = NULL;
	}
	return self;
}

- setupRegions:(int)size:(int)count
{
	int i,r;

	[self freeRegions];

	/* update regionSize and regionCount and allocate fresh regions */
	regionSize = size;
	regionCount = count;
	regions = malloc(count*sizeof(vm_address_t));

	for (i=0;i<regionCount;i++)
		r = vm_allocate(task_self(), &regions[i], regionSize, TRUE);

	return self;
}

@end



