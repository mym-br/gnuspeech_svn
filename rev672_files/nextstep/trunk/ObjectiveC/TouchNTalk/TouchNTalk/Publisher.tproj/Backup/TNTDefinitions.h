/*
 *    Filename:	TNTDefinitions.h 
 *    Created :	Tue Jun  1 16:00:55 1993 
 *    Author  :	Dale Brisinda
 *		<dale@pegasus.cuc.ab.ca>
 *
 *    Last modified on "Tue Jul 26 14:23:38 1994"
 *
 * $Id: TNTDefinitions.h,v 1.1 1994/07/26 20:24:02 dale Exp $
 *
 * $Log: TNTDefinitions.h,v $
 * Revision 1.1  1994/07/26  20:24:02  dale
 * Initial revision
 *
 */

/* Name of app-wrapper. */
#define TNT_APP_WRAPPER              "TouchNTalk.app"

/* Name of help document. */
#define TNT_HELP_DOCUMENT            "HelpDocument"

/* File extension definitions. */
#define TNT_FILE_EXTENSION           "tnt"

/* TNT default server name registered with network name server. */
#define TNT_SERVER_NAME              "TNTServer"

/* Number of lines per page that are published. */
#define TNT_LINES_PER_PAGE           66

/* Viewable tactile display configuration. */
#define TNT_TACTILE_DISPLAY_LINES    40
#define TNT_TACTILE_DISPLAY_COLUMNS  80

/* Viewable SIL configuration. */
#define TNT_SIL_LINES                1
#define TNT_SIL_COLUMNS              80

/* Width and height of visual tactile display in pixels. */
#define TNT_TACTILE_DISPLAY_WIDTH    647.0
#define TNT_TACTILE_DISPLAY_HEIGHT   684.0

/* Holo sets. */
#define TNT_HOLO_SET1                0
#define TNT_HOLO_SET2                1

/* Bookmark definitions. */
#define TNT_MAX_BOOKMARK_LEN         256

/* Number of soft functions (one-based). */
#define TNT_SOFT_FUNCTIONS           10

/* Operation modes. */
#define TNT_NORMAL                   0   // default mode
#define TNT_LOCATE                   1   // temporary mode WITHIN current window
#define TNT_HELP                     2   // mode for help window
#define TNT_OPEN                     3   // mode for open window
#define TNT_SAVE                     4   // mode for save window
#define TNT_SHELL                    5   // mode for shell window
#define TNT_WINDOWS                  6   // mode for document selection window

/* Default font information. */
#define TNT_DEFAULT_FONT             "Ohlfs"
#define TNT_DEFAULT_FONT_SIZE        12.0

/* Cursor blink rate (seconds). */
#define TNT_CURSOR_BLINK_RATE        0.7

/* Library tablet reader used with TouchNTalk. */
#define TNT_TABLET_READER            "SummaMMBinaryReader.bundle"

/* Tablet report modes. */
#define TNT_CONFIGURE_REPORT         "@I "     // continuous stream of events
#define TNT_NORMAL_REPORT1           "@I!"     // event mode w/ location hysteresis of 1
#define TNT_NORMAL_REPORT2           "@I\""    // event mode w/ location hysteresis of 2
#define TNT_NORMAL_REPORT3           "@I#"     // event mode w/ location hysteresis of 3
#define TNT_NORMAL_REPORT4           "@I$"     // event mode w/ location hysteresis of 4
#define TNT_NORMAL_REPORT5           "@I%"     // event mode w/ location hysteresis of 5

/* Tablet resolutions. */
#define TNT_1xDISPLAY_RES            "r\x64\x04\x4b\x03"   // 1120x832 display resolution
#define TNT_2xDISPLAY_RES            "r\xc7\x08\x8a\x06"   // 2240x1664 display resolution
#define TNT_3xDISPLAY_RES            "r\x2a\x0d\xc8\x09"   // 3360x2496 display resolution
#define TNT_4xDISPLAY_RES            "r\x82\x11\x07\x0d"   // 4480x3328 display resolution

/* Amount added to sides of region/groove bounding boxes in tablet resolution points. */
#define TNT_WIDTH_SAFETY                   5   // groove width safety
#define TNT_LENGTH_SAFETY                  2   // groove length safety

/* Tablet region definitions. */
#define TNT_DEADZONE                 0   // also a groove definition
#define TNT_SOFTAREA                 1
#define TNT_LEFTHOLO                 2
#define TNT_TOPHOLO                  3
#define TNT_RIGHTAREA                4
#define TNT_TACTILEAREA              5
#define TNT_SILAREA                  6
#define TNT_PREVAREA                 7
#define TNT_NEXTAREA                 8

/* Tablet groove definitions. These definitions are used in conjunction with the tablet region
 * definitions in order to identify a particular groove within a region. Specific tactile area groove 
 * definitions are not defined since they all behave identically. Like all other groove definitions,
 * the grooves in the tactile area are identified by the groove number in that region. The grooves in
 * the tactile area region are numbered from 1 to 40, top to bottom.
 */
#define TNT_SOFT_FUNCTION            1   // SOFTAREA groove definition
#define TNT_LEFTHOLO1                1   // LEFTHOLO groove definitions
#define TNT_LEFTHOLO2                2   // LEFTHOLO ...
#define TNT_LEFTHOLO3                3   // LEFTHOLO ...
#define TNT_LEFTHOLO4                4   // LEFTHOLO ...
#define TNT_PAGE_LOCATOR             1   // TOPHOLO groove definitions
#define TNT_BOOKMARK_HOLO            2   // TOPHOLO ...
#define TNT_HORIZ_PAGESCROLL         3   // TOPHOLO ...
#define TNT_CURSOR_LOCATOR           1   // RIGHTAREA groove definitions
#define TNT_VERT_PAGESCROLL          2   // RIGHTAREA ...
#define TNT_SIL                      1   // SILAREA groove definition
#define TNT_PREVPAGE                 1   // PREVAREA groove definition
#define TNT_NEXTPAGE                 1   // NEXTAREA groove definition

/* Tablet region orientations. */
#define TNT_NO_SHAPE                 0
#define TNT_SQUARE_SHAPE             1
#define TNT_VERTICAL_SHAPE           2
#define TNT_HORIZONTAL_SHAPE         3

/* Region groove count definitions. */
#define TNT_NO_GROOVES               0
#define TNT_SOFTAREA_GROOVES         1
#define TNT_LEFTHOLO_GROOVES         4
#define TNT_TOPHOLO_GROOVES          3
#define TNT_RIGHTAREA_GROOVES        2
#define TNT_TACTILEAREA_GROOVES      40
#define TNT_SILAREA_GROOVES          1
#define TNT_PREVAREA_GROOVES         1
#define TNT_NEXTAREA_GROOVES         1

/* Tablet region/groove partitions. */
#define TNT_NO_PARTS                 0
#define TNT_SOFTAREA_PARTS           TNT_SOFT_FUNCTIONS
#define TNT_LEFTHOLO_PARTS           40
#define TNT_PAGELOCATOR_PARTS        1   // default (UNTITLED document)
#define TNT_BOOKMARKHOLO_PARTS       1   // default (UNTITLED document)
#define TNT_HORIZ_PAGESCROLL_PARTS   80
#define TNT_RIGHTAREA_PARTS          40
#define TNT_TACTILEAREA_PARTS        80
#define TNT_SILAREA_PARTS            80
#define TNT_PREVAREA_PARTS           1
#define TNT_NEXTAREA_PARTS           1

/* TouchNTalk application-defined event subtype. */
#define TNT_EVENT                    1

/* NXEvent (TNT_EVENT) region access macro. */
#define TNT_REGION                   ctxt
#define TNT_GROOVE                   window
#define TNT_APPSUBTYPE               flags

/* NXEvent (TNT_EVENT) S component access macros. */
#define TNT_SUBTYPE                  data.compound.subtype
#define TNT_PARTITION                data.compound.misc.S[0]
#define TNT_CLICKS                   data.compound.misc.S[1]
#define TNT_DIRECTION                data.compound.misc.S[2]
#define TNT_VELOCITY                 data.compound.misc.S[3]

/* TouchNTalk event types. */
#define TNT_STYLUSUP                 1   // stylus raised off tablet or moved out of region/groove
#define TNT_STYLUSDOWN               2   // stylus placed on tablet or in new region/groove
#define TNT_STYLUSMOVED              3   // stylus in tablet proximity and moved
#define TNT_STYLUSTIPDOWN            4   // stylus tip button was clicked
#define TNT_STYLUSBARRELDOWN         5   // stylus barrel button was clicked

/* Frequency limit definitions (Hz). */
#define TNT_FREQ_OFF                 0.0
#define TNT_FREQ_INCR                10.0
#define TNT_FREQ_MIN                 100.0
#define TNT_FREQ_MAX                 1000.0

/* Pitch limit defintions (semitones). */
#define TNT_PITCH_MIN               -35.0
#define TNT_PITCH_MAX                45.0

/* Harmonic and volume defaults (dB). */
#define TNT_VOLUME_VARIATION         30.0   // volume variation between highest and lowest pitch
#define TNT_HARMONICS                8.0    // number of harmonics in tone
#define TNT_BASE_VOLUME              54.0   // base volume for lowest pitch

/* Direction definitions (degrees). */
#define TNT_NODIRECTION              (-1)
#define TNT_EAST                     0
#define TNT_NORTHEAST                45
#define TNT_NORTH                    90
#define TNT_NORTHWEST                135
#define TNT_WEST                     180
#define TNT_SOUTHWEST                225
#define TNT_SOUTH                    270
#define TNT_SOUTHEAST                315

/* Direction macros. In vertical grooves we are only interested in vertical movement, whereas in 
 * horizontal grooves we are only interested in horizontal movement. Similarly, we are only interested
 * in diagonal movement in the page turning grooves. 
 */
#define NORTH(d)                     ((d) > TNT_EAST && (d) < TNT_WEST)
#define SOUTH(d)                     ((d) > TNT_WEST)
#define EAST(d)                      ((d) > TNT_SOUTH && (d) < TNT_NORTH && (d) >= 0)
#define WEST(d)                      ((d) > TNT_NORTH && (d) < TNT_SOUTH)
#define NORTHEAST(d)                 ((d) > TNT_EAST && (d) < TNT_NORTH)
#define NORTHWEST(d)                 ((d) > TNT_NORTH && (d) < TNT_WEST)
#define SOUTHEAST(d)                 ((d) > TNT_SOUTH)
#define SOUTHWEST(d)                 ((d) > TNT_WEST && (d) < TNT_SOUTH)
