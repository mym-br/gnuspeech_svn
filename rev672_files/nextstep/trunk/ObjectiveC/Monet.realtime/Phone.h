
#import <objc/Object.h>
#import <objc/List.h>
#import "TargetList.h"
#import "CategoryList.h"

/*===========================================================================

	Author: Craig-Richard Taube-Schock
		Copyright (c) 1994, Trillium Sound Research Incorporated.
		All Rights Reserved.

=============================================================================

	Object: Phone.
	Purpose: This object stores the information pertinent to one phone or
		"posture".

	Instance Variables:
		phoneSymbol: (char *) String which holds the symbol 
			representing this phone.
		comment: (char *) string which holds any user comment made
			regarding this phone.

		categoryList: List of categories which this phone is a member
			of.
		parameterList: List of parameter target values for this phone.
		metaParameterList: List of meta-parameter target values for
			this phone.
		symbolList: List of symbol definitions for this phone.

	Import Files:

		"TargetList.h":  for access to TargetList methods.
		"CategoryList.h": for access to CategoryList methods.

	NOTES:

	categoryList:  Of the objects in this list, only those which are 
		"native" belong to the phone object.  When freeing, free
		only native objects using the "freeNativeCategories" method 
		in the CategoryList Object.  

	See "data_relationships" document for information about the 
		parameterList, metaParameterList and symbolList variables.

===========================================================================*/

@interface Phone:Object
{
	char 	*phoneSymbol;
	char	*comment;

	CategoryList	*categoryList;
	TargetList	*parameterList;
	TargetList	*metaParameterList;
	TargetList	*symbolList;

}

/* init and free methods */
- init;
- free;

/* Comment and Symbol methods */
- (const char *) symbol;

/* Access to category List instance variable */
- addToCategoryList: (CategoryNode *) aCategory;
- (CategoryList *) categoryList;

/* Access to target lists */
- (TargetList *) parameterList;
- (TargetList *) metaParameterList;
- (TargetList *) symbolList;

/* Archiving methods */
- read:(NXTypedStream *)stream;
- write:(NXTypedStream *)stream;

@end
