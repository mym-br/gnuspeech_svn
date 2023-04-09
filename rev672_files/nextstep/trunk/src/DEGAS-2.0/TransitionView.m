
/* Generated by Interface Builder */

#import "TransitionView.h"
#import <appkit/NXImage.h>
#import <dpsclient/psops.h>
#import <dpsclient/wraps.h>

/*  GRAPHIC CONSTANTS  */
#define TOP_MARGIN	20.0
#define BOTTOM_MARGIN   28.0
#define LEFT_MARGIN	40.0
#define RIGHT_MARGIN    20.0

#define REGRESSION_HEIGHT 4.0
#define REGRESSION_Y	  ((BOTTOM_MARGIN - REGRESSION_HEIGHT)/2.0)

#define VERTICAL_DIV    14.0

/*  COLOURS  */
#define WHITE            1.0
#define LIGHT_GRAY       0.667
#define DARK_GRAY        0.333
#define BLACK            0.0

#define PLOT_FONT_SIZE   12.0
#define PERCENT_L_MARGIN 10.0

/*  NODE RECTANGLE  */
#define NODE_SIZE        6.0
#define NODE_OFFSET      (-NODE_SIZE/2.0)

@implementation TransitionView

+ alloc
{
    self = [super alloc];
    return self;
}

- initFrame:(NXRect *)viewFrame
{
    /*  INCORPORATE INITIALIZATIONS OF SUPERCLASS  */
    [super initFrame:viewFrame];

    /*  CREATE CACHES AND SET GRAPHICS  */
    [self makeBackgroundCache];
    [self makeBitmapCache];
    [self setFlipped:NO];
    [self setClipping:NO];
    [self allocateGState];

    /*  SET SOME GRAPHING CONSTANTS  */
    extent_width = bounds.size.width - (LEFT_MARGIN + RIGHT_MARGIN);
    extent_height = bounds.size.height - (TOP_MARGIN + BOTTOM_MARGIN);
    vertical_div_height = extent_height / VERTICAL_DIV;
    unity_extent_width = extent_width;
    unity_extent_height = extent_height - (4.0 * vertical_div_height); 

    graph_origin_x = LEFT_MARGIN;
    graph_origin_y = BOTTOM_MARGIN;
    zero_x = graph_origin_x;
    zero_y = graph_origin_y + (2.0 * vertical_div_height);
    one_x = zero_x + unity_extent_width;
    one_y = zero_y + unity_extent_height;
    

    /*  DRAW BACKGROUND  */
    [self createbackground];

    return self;
}

// makeBitmapCache creates the bitmap cache on which we draw
- makeBitmapCache
{
    cache = [[NXImage alloc] initSize:&bounds.size];
    [cache setFlipped:NO];
    [cache setUnique:YES];
    return self;
}

// makeBackgroundCache creates the bitmap cache on which we draw
- makeBackgroundCache
{
    backgroundcache = [[NXImage alloc] initSize:&bounds.size];
    [cache setFlipped:NO];
    [cache setUnique:YES];
    return self;
}




- drawSelf:(NXRect *)rects :(int)rectCount
{
    if (rectCount == 3) {  // Scrolling diagonally; use last two rectangles
	[backgroundcache composite:NX_COPY fromRect:rects+1 toPoint:&(rects+1)->origin];
	[backgroundcache composite:NX_COPY fromRect:rects+2 toPoint:&(rects+2)->origin];

	[cache composite:NX_PLUSD fromRect:rects+1 toPoint:&(rects+1)->origin];
	[cache composite:NX_PLUSD fromRect:rects+2 toPoint:&(rects+2)->origin];
    } else {
        [backgroundcache composite:NX_COPY fromRect:rects toPoint:&rects->origin];
	[cache composite:NX_PLUSD fromRect:rects toPoint:&rects->origin];
    }

    return self;
}




- createbackground
{
    int i;
    int fontobject1;
    static char *percent[] = {"-20%","-10%","0%","10%","20%","30%",
			      "40%","50%","60%","70%","80%","90%",
		              "100%","110%","120%"};

    /*  DEFINE FONT OBJECT  */
    PSfindfont("Times-Roman");
    PSscalefont(PLOT_FONT_SIZE);
    fontobject1 = DPSDefineUserObject(0);

    /*  WRITE ON CACHE BITMAP  */
    [backgroundcache lockFocus];

    /*  ERASE AREA AND DRAW BORDER  */
    PSsetalpha(1.0);
    NXDrawWhiteBezel(&bounds,&bounds);

    /*  DRAW IN GRID  */
    /*  HORIZONTAL LINES  */
    PSsetgray(LIGHT_GRAY);
    PSsetlinewidth(1.0);
    for (i = 0; i <= VERTICAL_DIV; i++) {
	PSmoveto(graph_origin_x, (graph_origin_y + (i * vertical_div_height)) );
	if ((i == 2) || (i == 7) || (i == 12)) {
	    PSsetlinewidth(2.0);
	    PSrlineto(unity_extent_width,0.0);
	    PSstroke();
	    PSsetlinewidth(1.0);
	}
	else {
	    PSrlineto(unity_extent_width,0.0);
	    PSstroke();
	}
    }
    /*  VERTICAL LINES  */
    PSsetgray(BLACK);
    PSsetlinewidth(2.0);
    PSmoveto(graph_origin_x, graph_origin_y);
    PSrlineto(0.0, extent_height);
    PSmoveto((graph_origin_x + unity_extent_width), graph_origin_y);
    PSrlineto(0.0, extent_height);
    PSstroke();
    /*  LEFT HAND PERCENTAGES  */
    PSsetfont(fontobject1);
    for (i = 0; i <= VERTICAL_DIV; i++) {
	PSmoveto(PERCENT_L_MARGIN, 
		((graph_origin_y + (i * vertical_div_height))-(PLOT_FONT_SIZE/2.0) + 1.0) );
	PSshow(percent[i]);
    }

    /*  FINISHED WRITING ON CACHE BITMAP  */
    [backgroundcache unlockFocus];
    return self;
}



- displayTransition:(specifierStructPtr)specifier
{
    int i;
    t_intervalPtr current_interval_ptr = NULL;
    int total_intervals;
    float current_x, current_y;

    /*  GET TOTAL NUMBER OF INTERVALS  */
    total_intervals = specifier->number_of_t_intervals;

    /*  FIND FIXED AND PROPORTIONAL SPACE AND NUMBER OF INTERVALS  */
    number_of_p_intervals = number_of_f_intervals = 0;
    fixed_total_duration = 0;
    current_interval_ptr = specifier->t_intervalHead;
    for (i = 0; i < total_intervals; i++) {
	if (current_interval_ptr->proportional)
	    number_of_p_intervals++;
	else {
	    number_of_f_intervals++;
	    fixed_total_duration += current_interval_ptr->duration.ival;
	}
	
        current_interval_ptr = current_interval_ptr->next;
    }
    proportional_space = unity_extent_width * 
	((float)number_of_p_intervals/(float)total_intervals);
    fixed_space = unity_extent_width * 
	((float)number_of_f_intervals/(float)total_intervals);
/*
printf("number_of_p_intervals = %-d\n",number_of_p_intervals);
printf("number_of_f_intervals = %-d\n",number_of_f_intervals);
printf("fixed_total_duration = %-d\n",fixed_total_duration);
printf("proportional_space = %f\n",proportional_space);
printf("fixed_space = %f\n",fixed_space);
*/

    /*  WRITE ON CACHE BITMAP  */
    [cache lockFocus];

    /*  CLEAR THE BITMAP  */
    [cache composite:NX_CLEAR fromRect:&bounds toPoint:&bounds.origin];

    /*  DRAW VERTICAL LINES, SHADING, CONNECTING LINE, AND NODES  */
    current_x = graph_origin_x;
    current_y = zero_y;
    current_interval_ptr = specifier->t_intervalHead;
    for (i = 0; i < total_intervals; i++) {
	float interval_extent;
	if (current_interval_ptr->proportional) {
	    interval_extent = proportional_space * current_interval_ptr->duration.fval;
	}
	else {
	    interval_extent = fixed_space *
		((float)(current_interval_ptr->duration.ival)/(float)fixed_total_duration);
	}

	/*  DRAW SHADED RECTANGLE IF FIXED INTERVAL  */
	if (!(current_interval_ptr->proportional)) {
	    PSsetalpha(0.333);
	    PSsetgray(BLACK);
	    PSrectfill(current_x, graph_origin_y, interval_extent, extent_height);
	}

	/*  DRAW VERTICAL LINE AND NODE (EXCEPT FOR FIRST INTERVAL)  */
        PSsetalpha(1.0);
	PSsetgray(BLACK);
	PSsetlinewidth(2.0);
	if (i != 0) {
	    PSrectfill(current_x + NODE_OFFSET, current_y + NODE_OFFSET,NODE_SIZE,NODE_SIZE);
	    PSmoveto(current_x, graph_origin_y);
	    PSrlineto(0.0, extent_height);
	}

	/*  DRAW CONNECTING LINE  */
	PSmoveto(current_x, current_y);
	PSrlineto(interval_extent, (current_interval_ptr->rise) * unity_extent_height);
	PSstroke();

	/*  DRAW REGRESSION BAR IF NECESSARY  */
	if (current_interval_ptr->regression)
	    PSrectfill(current_x, REGRESSION_Y, interval_extent, REGRESSION_HEIGHT);
	else {
	    PSsetgray(LIGHT_GRAY);
	    PSrectfill(current_x, REGRESSION_Y, interval_extent, REGRESSION_HEIGHT);
	}

	/*  UPDATE POINTER TO INTERVAL, CURRENT X, AND CURRENT Y  */
	current_x += interval_extent;
	current_y += ((current_interval_ptr->rise) * unity_extent_height);
        current_interval_ptr = current_interval_ptr->next;
    }

    [cache unlockFocus];
    [self display];
    return self;
}
@end
