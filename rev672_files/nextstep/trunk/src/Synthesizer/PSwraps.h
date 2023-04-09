
#ifndef PSwraps_H_INCLUDE_
#define PSwraps_H_INCLUDE_

extern void PSdownarrow(float x, float y, float width, float height);
extern void PSglottalpulse(float x, float y, float width, float height,
                        float amplitude, float scale, float riseTime,
                        float fallTimeMin, float fallTimeMax);
extern void PSnotehead(float x, float y, float width, float height);
extern void PSpulseparameter(float x, float y, float width, float height,
	                  float riseTime, float fallTimeMin, float fallTimeMax);
extern void PSrectangle(float x, float y, float width, float height,
	             float linewidth, float graylevel);
extern void PSsharp(float x, float y, float width, float height);
extern void PSsine(float x, float y, float width, float height, 
		float amplitude);
extern void PSuparrow(float x, float y, float width, float height);

extern void PSDoUserPath(float *coord, float points, int stroke);

extern void PSstringwidth(const char *cstr, float *w, float *h);

#endif
