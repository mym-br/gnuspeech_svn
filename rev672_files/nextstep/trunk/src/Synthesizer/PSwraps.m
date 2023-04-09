
#include <math.h>
#include <AppKit/PSOperators.h>
#include <AppKit/NSStringDrawing.h>

void PSdownarrow(float x, float y, float width, float height)
{
  float headheight = 6;
  float halfheight = height / 2;
  float halfwidth = width / 2;

  float top = y + halfheight;
  float bottom = y - halfheight - 1;

  PSsetlinewidth(1);		

  PSmoveto(x, bottom);
  PSrlineto(-halfwidth, headheight);
  PSrlineto(width, 0);
  PSclosepath();
  PSfill();

  PSmoveto(x, bottom+headheight);
  PSlineto(x, top);
  PSstroke();
}

#define square(num) ((num*num))
#define cube(num)   ((num*num*num))

float
risefunction(float n2, float n3, float x, float height, 
	     float scale, float midy)
{
  float ddx = (n2 - x) / (n3 - x);

  return (cube(ddx) * -2 + square(ddx) * 3) * (height / 2) * scale + midy;
}

float
fallfunction(float n2, float n3, float tp, float height, 
	     float scale, float midy)
{
  float dx = (n2 - tp) / (n3 - tp);

  return ( square(dx) - 1 ) * height / 2 * scale + midy;
}

void PSglottalpulse(float x, float y, float width, float height,
                        float amplitude, float scale, float riseTime,
                        float fallTimeMin, float fallTimeMax)
{
  int i;
  float tp = x + riseTime*width / 100;
  float tnMin = tp + fallTimeMin * width / 100;
  float tnMax = tp + fallTimeMax * width / 100;
  float tndelta = tnMax - tnMin;
  float tn = tnMax - tndelta * amplitude;

  float maxx = x+width;
  float maxy = y+height;
  float midy = height / 2 + x;

  PSsetlinewidth(1);			// set linewidth and gray level
  PSsetgray(0);
  
  PSmoveto(x, midy);			// draw rise
  for (i=x+1; i <= tp; i++)
    {
      PSlineto(i, risefunction(i, tp, x, height, scale, midy));
    }
    
  PSlineto(tp, height / 2 * scale + midy );	// draw fall
  for (i=tp+1; i < tn; i++)
    {
      PSlineto(i, fallfunction(i, tn, tp, height, scale, midy));
    }
  PSlineto(maxx, midy);
  PSstroke();
}

void PSnotehead(float x, float y, float width, float height)
{
  float halfheight = height / 2;
  float neghalfheight = -halfheight;
  float halfwidth = width / 2;
  float negwidth = -width;

  PSmoveto(x-halfwidth, y);	// move to left side of note

  // trace top half of note
  PSrcurveto(0, halfheight-1, width, halfheight+1, width, 0);

  // trace bottom half of note
  PSrcurveto(0, neghalfheight+1, negwidth, neghalfheight-1, negwidth, 0);

  PSfill();				// fill the note
}

float
risefunction2(float n2, float n3, float x, float y, float height)
{
  float ddx = (n2 - x) / (n3 - x);

  return (cube(ddx) * -2 + square(ddx) * 3) * height + y;
}

float
fallfunction2(float n2, float n3, float tp, float y, float height)
{
  float dx = (n2 - tp) / (n3 - tp);

  return ( square(dx) - 1 ) * height + y;
}

void PSpulseparameter(float x, float y, float width, float height,
	                  float riseTime, float fallTimeMin, float fallTimeMax)
{
  int i;
  float tp = x + riseTime*width / 100;
  float tnMin = tp + fallTimeMin * width / 100;
  float tnMax = tp + fallTimeMax * width / 100;
  float tndelta = tnMax - tnMin;

  float maxx = x+width;
  float maxy = y+height;

  float ltgray = 2 / 3;
  float dkgray = 1 / 3;
  float black = 0;

  PSsetlinewidth(1);				// draw vertical lines
  PSsetgray(ltgray);
  PSmoveto(tp, y);
  PSrlineto(0, height);
  PSmoveto(tnMin, y);
  PSrlineto(0, height);
  PSmoveto(tnMax, y);
  PSrlineto(0, height);
  PSstroke();

  PSsetgray(dkgray);				// draw tnmax fall
  PSmoveto(tp, maxy);
  for (i = tp+1; i < tnMax; i++)
    {
      PSlineto(i, fallfunction2(y, tnMax, tp, y, height));
    }
  PSlineto(tnMax, y);
  PSlineto(maxx, y);
  PSstroke();
  
  PSsetgray(black);				// draw rise
  PSmoveto(x, y);
  for (i=x+1; i <= tp; i++)
    {
      PSlineto(i, risefunction2(i, tp, x, y, height));
    }

  PSlineto(tp, maxy);				// draw min fall
  for (i=tp+1; i < tnMin; i++)
    {
      PSlineto(i, fallfunction2(i, tnMin, tp, y, height));
    }
  PSlineto(tnMin, y);
  PSlineto(maxx, y);
  PSstroke();
}

void PSrectangle(float x, float y, float width, float height,
	             float linewidth, float graylevel)
{
  PSsetgray(graylevel);		// set graylevel and linewidth
  PSsetlinewidth(linewidth);
  PSrectstroke(x, y, width, height);
}

void PSsharp(float x, float y, float width, float height)
{
  float horizontalinsetfactor = 2 / 7;
  float horizontalinset = width * horizontalinsetfactor;

  float verticalinsetfactor = 2 / 7;
  float verticalinset = height * verticalinsetfactor;

  float slantfactor = 2 / 7;
  float slant = width * slantfactor;

  float center = y - slant / 2;

  float halfwidth = width / 2;
  float halfheight = height / 2;

  float vs1offset = slant * horizontalinset / width;
  float vs2offset = slant * (width-horizontalinset) / width;

  PSsetlinewidth(1);

  PSmoveto(x-halfwidth+horizontalinset,
	   center-halfheight + vs1offset);
  PSrlineto(0, height - slant / 2);

  PSmoveto(x+halfwidth-horizontalinset, 	// right vertical stroke
	   center-halfheight+vs2offset);
  PSrlineto(0, height - slant / 2);
  
  PSstroke();					// paint the vertical strokes

  PSsetlinewidth(3);				// set linewidth to wide

  PSmoveto(x-halfwidth,				// bottom horizontal stroke
	   center-halfheight+verticalinset);
  PSrlineto(width, slant);

  PSmoveto(x-halfwidth,				// bottom horizontal stroke
	   center+halfheight-verticalinset-slant);
  PSrlineto(width, slant);

  PSstroke();					// paint the horizontal strokes
}

#define angle(num)  ((num - x)/width * 360)

void PSsine(float x, float y, float width, float height, float amplitude)
{
  int i;
  float midy = height / 2 + x;
  float maxx = x+width;

  PSsetlinewidth(1);			// set linewidth and gray level
  PSsetgray(0);

  PSmoveto(x, midy);			// draw the sine waveform
  for (i=x+1; i<maxx; i++)
    {
      float sinepath = sin(angle(i)) * amplitude * height / 2 + midy;
      PSlineto(i, sinepath);
    }
  PSlineto(maxx, midy);
  PSstroke();
}

void PSuparrow(float x, float y, float width, float height)
{
  float headheight = 6;
  float halfheight = height / 2;
  float halfwidth = width / 2;

  float top = y+halfheight;
  float bottom = y-halfheight;

  PSsetlinewidth(1);			// set the linewidth
  
  PSmoveto(x, top);			// draw arrowhead
  PSrlineto(-halfwidth, -headheight);
  PSrlineto(width, 0);
  PSclosepath();
  PSfill();
  
  PSmoveto(x, top-headheight);	// draw stem
  PSlineto(x, bottom);
  PSstroke();
}

void
PSDoUserPath(float *coord, float points, int stroke)
{
  int i;
  PSmoveto(coord[0], coord[1]);
  for (i=1; i < points; i++)
    {
      PSlineto(coord[2*i], coord[2*i+1]);
    }
  PSstroke();
}

void 
PSstringwidth(const char *cstr, float *w, float *h)
{
  NSSize p;
  NSString *str;

  str = [NSString stringWithCString: cstr];
  p = [str sizeWithAttributes: nil];
  *w = p.width;
  *h = p.height;
}
