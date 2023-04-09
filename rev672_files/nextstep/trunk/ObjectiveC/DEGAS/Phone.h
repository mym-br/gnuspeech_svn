
#import <objc/Object.h>
#import <objc/List.h>
#import "TargetList.h"
#import "CategoryList.h"

/*
struct _phoneDescription {
  char symbol[SYMBOL_LENGTH_MAX+1];
  int duration;
  struct {
      int type;
      int fixed;
      float prop;
  } transition_duration;
  struct _phoneDescription *next;
  targetPtr targetHead;
  categoryPtr categoryHead;
  int number_of_categories;
};
*/

@interface Phone:Object
{
	char 	*phoneSymbol;
	int	duration;

	CategoryList	*categoryList;
	TargetList	*targetList;

	int 	type;
	int	fixed;
	float	prop;
}

- init;
- initWithSymbol:(const char *) newSymbol;
- free;

- setSymbol:(char *) newSymbol;
- (const char *) symbol;
- setDuration: (int) newDuration;
- (int) duration;

- setType:(int) newType;
- (int) type;
- setFixed:(int) newFixed;
- (int) fixed;
- setProp:(float) newProp;
- (float) prop;

- addToCategoryList: (CategoryNode *) aCategory;
- (CategoryList *) categoryList;

- (TargetList *) targetList;

@end
