
#import "FFTScrollView.h"
#import "FFTScaleView.h"
#import "FFTView.h"

@implementation FFTScrollView

- initFrame:(const NXRect *)frameRect
{
  NXRect scaleRect, clipRect;

  /*printf("FFTScrollView - initFrame: *is* being called.\n");*/
  [super initFrame:frameRect];

  [self setBorderType:NX_LINE];
  [self setHorizScrollerRequired:YES];
  /*[self setVertScrollerRequired:YES];*/

  /*[contentView getFrame:&clipRect];
  NXDivideRect(&clipRect, &scaleRect, 50.0, NX_XMIN);
  [contentView setFrame:&clipRect];*/
  NXSetRect(&scaleRect, 0.0, 0.0, 0.0, 0.0);
  
  scaleView = [[FFTScaleView alloc] initFrame:&scaleRect];
  [self addSubview:scaleView];

  NXSetRect(&clipRect, 0.0, 0.0, 500.0, 256.0+50.0);
  /*if ([self setDocView:[[MyView alloc] initFrame:&clipRect]] != nil)
    printf("FFTScrollView - initFrame:, There's a doc view you should get rid of!\n");*/
  if ([self setDocView:[[FFTView alloc] initFrame:&clipRect]] != nil)
    printf("FFTScrollView - initFrame:, There's a doc view you should get rid of!\n");

  /*
   *  There's a wee bug that this masks.  The top line of the
   *  FFT doesn't seem to be drawn properly...
   */
  [self setBackgroundGray:NX_WHITE];
  [self tile];  /* hack? */

  return self;
}

- drawSelf:(const NXRect *)rects :(int)rectCount
{
  /*PSsetgray(NX_LTGRAY);*/
  PSsetgray(NX_WHITE);
  PSrectfill(NX_X(&bounds),NX_Y(&bounds),NX_WIDTH(&bounds),NX_HEIGHT(&bounds));
  /*NXDrawWhiteBezel(&bounds, &bounds);*/
  /*[[self window] flushWindow];
  NXPing();
  sleep(1);*/
  [super drawSelf:rects:rectCount];
  /*[[self window] flushWindow];
  NXPing();
  sleep(1);*/
  /*printf("FFTScrollView - drawSelf: *is* being called.\n");*/

  /*PSsetgray(NX_WHITE);
  PSmoveto(0.0, NX_HEIGHT(&bounds)/2);
  PSlineto(NX_WIDTH(&bounds), NX_HEIGHT(&bounds)/2);
  PSstroke();*/

  return self;
}

- tile
{
  NXRect scaleRect, clipRect;

  /*printf("FFTScrollView - tile\n");*/

  [super tile];

  [contentView getFrame:&clipRect];
  NXDivideRect(&clipRect, &scaleRect, 50.0, NX_XMIN);
  [contentView setFrame:&clipRect];
  [scaleView setFrame:&scaleRect];

  return self;
}

- printPSCode:sender
{
  printf("FFTScrollView - printPSCode:\n");

  [self setAutodisplay:NO];
  [self setBorderType:NX_NONE];
  [self setHorizScrollerRequired:NO];

  [super printPSCode:sender];

  [self setBorderType:NX_LINE];
  [self setHorizScrollerRequired:YES];
  [self setAutodisplay:YES];
  return self;
}

- scaleView
{
  return scaleView;
}

@end
