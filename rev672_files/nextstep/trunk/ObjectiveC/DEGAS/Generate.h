
/* Generated by Interface Builder */

#import <objc/Object.h>
#import <appkit/View.h>
#import <streams/streams.h>

#define FILTER_X_OFFSET       (8)
#define FILTER_Y_OFFSET       (16)

#define FONTNAME                "Courier"
#define FONTSIZE                12.0

#define SYMBOL_LENGTH_MAX       12
#define ROW_NUMBER_MAX          5

struct _filterParam {
  char symbol[SYMBOL_LENGTH_MAX+1];
  struct _filterParam *next;
};

typedef struct _filterParam filterParam;
typedef filterParam *filterParamPtr;

@interface Generate:Object
{
    id	template;
    id	categories;
    id	phoneDescription;
    id	rule;
    id  fileManager;

    id  generateWindow;
    id  filterAddPanel;
    id  filterModPanel;

    id	filterList;
    id	filterTotal;
    id  filterModButton;

    id  filterAddList;
    id  filterAddParam;
    id  filterAddOrder;
    id  filterAddOKButton;

    id  filterModParam;
    id  filterModOrder;

    id	logText;
    id  log;
    id  clearLogButton;
    id  saveLogButton;
    id  printLogButton;

    id	commentText;
    id  comment;

    id	progressChart;

    NXRect r;

    int number_of_parameters;
    filterParamPtr parameterHead;
    int parameterCurrentRow;

    int filterAddCurrentRow;

    id  fontObj;
}

- appDidInit:sender;

- setTitleBar:(char *)currentPath;


- filterAdd:sender;
- filterAddOK:sender;
- filterAddCancel:sender;

- filterModify:sender;
- filterModifyOK:sender;
- filterModifyCancel:sender;
- filterModifyDelete:sender;

- clearLog:sender;
- saveLog:sender;
- printLog:sender;

- generate:sender;

- logWrite:(char *)buffer;

- saveToFile:(FILE *)fp1;
- ReadFromFile:(FILE *)fp1;

@end