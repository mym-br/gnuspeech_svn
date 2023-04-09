
/* Generated by Interface Builder */

#import <objc/Object.h>
#import <appkit/View.h>
#import <stdio.h>
#import "ParameterList.h"
#import "PhoneList.h"


/*  DEFINITIONS  */
#define SYMBOL_LENGTH_MAX       12
#define ROW_NUMBER_MAX          5
#define FLOAT_LENGTH_MAX        12
#define COLUMN1                 (ROW_NUMBER_MAX+SYMBOL_LENGTH_MAX+1)
#define COLUMN2                 (COLUMN1+FLOAT_LENGTH_MAX)
#define COLUMN3                 (COLUMN2+FLOAT_LENGTH_MAX)

#define FONTNAME                "Courier"
#define FONTSIZE                12.0

#define PHONE_SYMBOL_DEF	""  /*  put this in a global .h file  */

#define PHONE_SYMBOL            0
#define PHONE_ORDER		1

#define PARAM_SYMBOL_DEF	""   /*  put these in a global .h file  */
#define PARAM_MIN_DEF		100
#define PARAM_MAX_DEF		1000
#define PARAM_DEF_DEF		500

#define PARAM_SYMBOL		0
#define PARAM_MIN		1
#define PARAM_MAX		2
#define PARAM_DEF		3
#define PARAM_ORDER		4

#define SAMPLE_SIZE_MIN         1    /*  put these in a global .h file  */
#define SAMPLE_SIZE_MAX         100
#define SAMPLE_SIZE_DEF         2

/*  SUB WINDOW OFFSETS  */
#define PHONE_X_OFFSET          (32)
#define PHONE_Y_OFFSET          (-23)
#define PARAM_X_OFFSET          (248)
#define PARAM_Y_OFFSET          (-95)
#define SAMPLE_X_OFFSET          (0)
#define SAMPLE_Y_OFFSET          (-103)



/*  DATA STRUCTURES  */
struct _phoneStruct {
  char symbol[SYMBOL_LENGTH_MAX+1];
  struct _phoneStruct *next;
};

typedef struct _phoneStruct phoneStruct;
typedef phoneStruct *phoneStructPtr;

struct _parameterStruct {
  char symbol[SYMBOL_LENGTH_MAX+1];
  float minimum;
  float maximum;
  float Default;
  struct _parameterStruct *next;
};

typedef struct _parameterStruct parameterStruct;
typedef parameterStruct *parameterStructPtr;


@interface Template:Object
{
	id  categories;
	id  phoneDescriptionObj;
	id  ruleObj;
	id  fileManager;
	id  generate;
	id  synthesizeObj;
	id	templateWindow;

	id	phoneBrowser;
	id	parameterBrowser;

	id	phoneTotal;
	id	parameterTotal;
	id  setDisplay;

	id	addPhonePanel;
	id	modifyPhonePanel;
	id	addParameterPanel;
	id	modifyParameterPanel;
	id  setSamplePanel;

	id	addPhoneField;
	id	modPhoneField;
	id	addParameterField;
	id	modParameterField;
	id  setSampleField;

	id  phoneModButton;
	id  parameterModButton;

	NXRect r;

	int number_of_phones;
	phoneStructPtr phoneHead;
	int phoneCurrentRow;

	int number_of_parameters;
	parameterStructPtr parameterHead;
	int parameterCurrentRow;

	int sampleSize;

	id  fontObj;

	ParameterList	*parameterList;
}

- appDidInit:sender;

- setTitleBar:(char *)currentPath;

- phoneAdd:sender;
- phoneModify:sender;
- parameterAdd:sender;
- parameterModify:sender;
- setSample:sender;

- addPhoneCancel:sender;
- addPhoneAdd:sender;

- modPhoneCancel:sender;
- modPhoneDelete:sender;
- modPhoneOK:sender;

- addParamCancel:sender;
- addParamAdd:sender;

- modParamCancel:sender;
- modParamDelete:sender;
- modParamOK:sender;

- setSampleCancel:sender;
- setSampleSet:sender;

- loadDefaultTemplate:sender;
- loadTemplateFromFile:sender;

- phoneSelect:sender;
- parameterSelect:sender;

- setSampleSize:sender;

- (int)usedAsPhoneSymbol:(char *)string;
- (int)sampleValue;

- (int)numberOfPhones;
- (char *)phoneSymbol:(int)number;

- (int)numberOfParameters;
- (char *)parameterSymbol:(int)number;
- (float)parameterMinimum:(int)number;
- (float)parameterMaximum:(int)number;
- (float)parameterDefault:(int)number;
- (float)parameterSymMinimum:(char *)parameter;
- (float)parameterSymMaximum:(char *)parameter;
- (float)parameterSymDefault:(char *)parameter;
- (int)isParameter:(char *)parameter;

- saveToFile:(FILE *)fp1;
- ReadFromFile:(FILE *)fp1;

- updatePhoneBrowser;

@end
