
#import "Brain.h"
#import "FFTBrain.h"

@implementation Brain //;

- newFFT:sender
{
  id win;

  if ([NXApp loadNibSection:"FFT.nib" owner:self] == nil)
    return nil;

  if ([newFFT setUp])
    {
      win = [newFFT window];
      if (win)
	{
	  NXRect frame;
	  char buf[256];

	  [win getFrame:&frame];
	  NX_X(&frame) += offset;
	  NX_Y(&frame) -= offset;
	  if ( (offset += 24.0) > 100.0)
	    offset = 0.0;
	  sprintf(buf, [win title], ++FFTNum);
	  [win setTitle:buf];
	  [win placeWindowAndDisplay:&frame];
	  [win makeKeyAndOrderFront:nil];
	  return newFFT;
	}
    }

  return nil;
}

- loadFFTfile:sender
{
  char *types[] = {"fft", "snd", 0};
  const char * const *fnames;
  const char *directory;
  char buf[MAXPATHLEN+1];

  [[OpenPanel new] allowMultipleFiles:YES];
  /*if ([[OpenPanel new] runModalForDirectory:"/CraigsDisk/pub/fft" file:NULL types:types])*/
  if ([[OpenPanel new] runModalForTypes:types])
    {
      fnames = [[OpenPanel new] filenames];
      directory = [[OpenPanel new] directory];
      while (*fnames)
	{
	  strcpy(buf, directory);
	  strcat(buf, "/");
	  strcat(buf, *fnames);
	  if ([self newFFT:self])
	    [newFFT loadFile:buf];
	  fnames++;
	}
    }
  return self;
}

- resyncWindows:sender
{
  id fromWin = [sender window];
  id fromDel = [fromWin delegate];
  id winList = [NXApp windowList];
  int count = [winList count];
  int l;

  for (l=0; l<count; l++)
    {
      id win = [winList objectAt:l];
      id del = [win delegate];

      if ([del isKindOf:[FFTBrain class]])
	{
	  [del syncWith:fromDel];
	}
    }

  return self;
}

@end

@implementation Brain(ApplicationDelegate)

- appDidInit:sender
{
  [sender activateSelf:YES];
  return self;
}

- (BOOL) appAcceptsAnotherFile:sender
{
  return YES;
}

- (int)app:sender openFile:(const char *)filename type:(const char *)aType
{
  if ([self newFFT:self])
    if ([newFFT loadFile:filename])
      return YES;
  return NO;
}

@end
