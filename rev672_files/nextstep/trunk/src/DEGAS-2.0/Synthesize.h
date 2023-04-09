
/* Generated by Interface Builder */

#import <objc/Object.h>
#import "Rule.h"
#import "synthesizer_module.h"

#define SYNTH_SWITCH_FORMANT     0      /*  ADD OTHER SYNTH TYPES HERE  */
#define NUMBER_SYNTH_PARAMETERS  20

#define FORMANT_PARAM_1        "ax"     /*  PARTICULAR PARAMETER NAMES FOR FORMANT SYNTH  */
#define FORMANT_PARAM_2        "micro"
#define FORMANT_PARAM_3        "ah1"
#define FORMANT_PARAM_4        "ah2"
#define FORMANT_PARAM_5        "fh2"
#define FORMANT_PARAM_6        "bwh2"
#define FORMANT_PARAM_7        "nb"
#define FORMANT_PARAM_8        "fnnf"
#define FORMANT_PARAM_9        "bwnnf"
#define FORMANT_PARAM_10       "f1"
#define FORMANT_PARAM_11       "bw1"
#define FORMANT_PARAM_12       "f2"
#define FORMANT_PARAM_13       "bw2"
#define FORMANT_PARAM_14       "f3"
#define FORMANT_PARAM_15       "bw3"
#define FORMANT_PARAM_16       "f4"
#define FORMANT_PARAM_17       "bw4"
#define FORMANT_PARAM_18       "mv"
#define FORMANT_PARAM_19       "bal"
#define FORMANT_PARAM_20       "br"


#define SPEED_SWITCH_REGRESS   0
#define SPEED_SWITCH_ALL       1
#define SPEED_DEFAULT          1.0
#define SPEED_MINIMUM          0.2
#define SPEED_MAXIMUM          2.0

#define PITCH_SWITCH_PITCH     0
#define PITCH_SWITCH_FREQ      1
#define PITCH_TEXT_PITCH       "Pitch in semitones"
#define PITCH_TEXT_FREQ        "Frequency in Hz"
#define PITCH_PITCH_DEFAULT    (-15)
#define PITCH_PITCH_MINIMUM    (-45)
#define PITCH_PITCH_MAXIMUM    (45)
#define PITCH_FREQ_DEFAULT     110.0
#define PITCH_FREQ_MINIMUM     20.0
#define PITCH_FREQ_MAXIMUM     3520.0

#define PITCH_BASE             220.0
#define PITCH_OFFSET           3     /*  MIDDLE C = 0  */
#define LOG_FACTOR             3.32193

#define MICRO_INTON_DEF        0.0
#define GUARD_TABLES           10


#define DISPLAY_SWITCH_ALL     0
#define DISPLAY_SWITCH_SYNTH   1
#define DISPLAY_SWITCH_FILTER  2

#define DISPLAY_HSCALE_DEFAULT 2
#define DISPLAY_HSCALE_MINIMUM 1
#define DISPLAY_HSCALE_MAXIMUM 10

#define DISPLAY_VSCALE_DEFAULT 100
#define DISPLAY_VSCALE_MINIMUM 50
#define DISPLAY_VSCALE_MAXIMUM 250

#define MARKER_DEFAULT         "/"
#define SILENT_PHONE_DEFAULT   "^"

#define ON                     1
#define OFF                    0

#define ERROR                  (-1)
#define NO_ERROR               0

#define INPUT_PHONE            0
#define INPUT_DIPHONE          1

#define DIPHONE_LENGTH_MAX     ((2*SYMBOL_LENGTH_MAX)+1)
#define DIPHONE_SPACING        "  "




struct _phoneListType {
    char symbol[SYMBOL_LENGTH_MAX+1];
    struct _phoneListType *next;
};
typedef struct _phoneListType phoneListType;
typedef phoneListType *phoneListPtr;

struct _diphoneList {
    char symbol1[SYMBOL_LENGTH_MAX+1];
    char symbol2[SYMBOL_LENGTH_MAX+1];
    float length;
    struct _diphoneList *next;
};
typedef struct _diphoneList diphoneList;
typedef diphoneList *diphoneListPtr;

struct _synthParameterList {
    int calculated;
    float value;
    float delta;
};
typedef struct _synthParameterList synthParameterList;
typedef synthParameterList *synthParameterListPtr;



@interface Synthesize:Object
{
    id  template;
    id  rule;
    id  phoneDescriptionObj;

    id	synthesizeWindow;
    id	diphoneView;

    id	diphoneForm;
    id	parameterForm;
    id	sampleForm;
    id  timeForm;
    id	valueForm;

    id	entryForm;
    id	resultForm;

    id	preferencesPanel;

    id	typeSwitch;

    id	speedSwitch;
    id	speedSlider;
    id	speedForm;

    id	pitchSwitch;
    id	pitchSlider;
    id	pitchForm;
    id	pitchText;

    id	displaySwitch;
    id	redisplaySwitch;
    id  gridSwitch;
    id	hscaleSlider;
    id	hscaleForm;
    id	vscaleSlider;
    id	vscaleForm;

    id	markerForm;
    id	silentPhoneForm;
    id	silentSwitchPhones;
    id  silentSwitchDiphones;


    int synthesizer_type;

    int synthesizer_speed_type;
    float synthesizer_speed;

    int pitch_type;
    struct {
	int pitch;
	float frequency;
    } pitch;

    int display_type;
    int redisplay;
    int grid;
    int hscale_value, vscale_value;
    int display_vscale, display_hscale, display_sample_length;

    char diphone_marker;
    char silent_phone[SYMBOL_LENGTH_MAX+1];
    int add_silent_phones;
    int add_silent_diphones;

    diphoneListPtr diphoneDisplayHead;
    int number_of_diphones_display;

    diphoneListPtr diphoneSynthHead;
    int number_of_diphones_synth;

    filterParamPtr displayParameterHead;
    int number_of_display_parameters;

    int npages;
    DSPFix24 *page_start;


}

- appDidInit:sender;

- setTitleBar:(char *)currentPath;

- display:sender;
- synthesize:sender;
- (int)evaluateInput:(diphoneListPtr *)diphoneHead:(int *)number_of_diphones;

- typeSwitchHit:sender;

- speedSwitchHit:sender;
- speedSliderMoved:sender;

- pitchSwitchHit:sender;
- pitchSliderMoved:sender;

- displaySwitchHit:sender;
- redisplaySwitchHit:sender;
- gridSwitchHit:sender;
- hscaleSliderMoved:sender;
- vscaleSliderMoved:sender;

- markerEntered:sender;
- silentPhoneEntered:sender;
- silentSwitchPhonesHit:sender;
- silentSwitchDiphonesHit:sender;

- defaultSwitchHit:sender;

- (int)numberOfDisplayParameters:(filterParamPtr *)listHead;
- (int)numberOfDisplayDiphones:(diphoneListPtr *)listHead;
- (char)diphoneMarker;

- (int)grid;
- (int)vscale;
- (int)hscale;

- (int)speedType;
- (float)speedFactor;

- trackMouse:(NXPoint *)location;
- stopTrackingMouse;
- setDisplayDuration:(float)diphoneDuration for:(int)diphoneNumber;

- formantSynthesizer;

- saveToFile:(FILE *)fp1;
- readFromFile:(FILE *)fp1;

@end
