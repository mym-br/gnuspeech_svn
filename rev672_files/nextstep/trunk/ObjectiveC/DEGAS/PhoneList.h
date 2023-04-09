
#import <objc/Object.h>
#import <objc/List.h>
#import "Phone.h"

@interface PhoneList:List
{
}

- (Phone *) findPhone: (const char *) phone;
- binarySearchPhone:(const char *) searchPhone index:(int *) index;
- addPhone: (const char *) phone;
- addPhoneObject: (Phone *) phone;

@end
