#import <objc/Object.h>

/* The states that the player can be in. */
typedef enum {
  PLA_STOPPED,
  PLA_PAUSED,
  PLA_RUNNING,
  N_PLA_STATES
  } Pla_state_t;
  
@interface Player:Object
{
  int bytesPlayed;		/* # of bytes played since setup */
  id delegate;			/* the target of notification messages */
  Pla_state_t playerState;	/* current state of the player object */
  int regionSize;		/* # of bytes per call to playData */
  int regionCount;		/* # of regions queued in advance */
  vm_address_t *regions;	/* an array of regions */
  int regionIndex;		/* the current region */
}

+ new;			/* Factory method to instantiate a new player object. */

- free;			/* Free the Player object and any associated storage. */
- prepare;		/* Prepare to play, state => PLA_PAUSED */
- run;			/* Start playback, state => PLA_RUNNING */
- pause;		/* Pause the playback, state => PLA_PAUSED */
- stop;			/* Stop playing, state => PLA_STOPPED */
- (Pla_state_t)state;	/* Returns the current state of the player object */
- (int)bytesPlayed;	/* Returns the number of bytes played since the last call to setup */
- delegate;		/* Returns the current delegate. */
- setDelegate:anObject; /* Sets the delegate of the recoder */
- (int)regionSize;	/* Returns the current region size. */
- setRegionSize:(int)nbytes;	/* Set the size of each region to nbytes big. */
- (int)regionCount;		/* Returns the number of regions in the region queue. */
- setRegionCount:(int)nregions;	/* Set the number of regions in the region queue. */

- freeRegions;		/* Free all the regions in the region queue. */
- setupRegions:(int)size:(int)count;	/* Create count regions of the given size. */

@end

/*** Description of the Player's delegate ***/

@interface PlayerDelegate:Object

- willPlay :player;	/* Called whenever the player is about to start playing. */
- didPlay :player;	/* Called whenever the player stops playing. */
- playData :player :(char *)data :(int)nbytes;	/* Called whenever the player wants more sound data. */

@end




