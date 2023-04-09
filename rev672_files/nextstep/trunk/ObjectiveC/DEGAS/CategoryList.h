
#import <objc/Object.h>
#import <objc/List.h>
#import "CategoryNode.h"

@interface CategoryList:List
{
}

- findSymbol:(char *) searchSymbol;
- addCategory:(const char *) newCategory;
- addNativeCategory:(const char *) newCategory;
- freeNativeCategories;

@end
