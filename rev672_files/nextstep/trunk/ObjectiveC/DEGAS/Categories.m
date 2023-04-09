
/* Generated by Interface Builder */

#import "Categories.h"
#import "CategoryNode.h"
#import "Template.h"
#import "PhoneDescription.h"
#import "Rule.h"
#import "reserved_symbol.h"
#import <appkit/appkit.h>

@implementation Categories

- appDidInit:sender
{
	/* Init category List object */
	categoryList = [[CategoryList alloc] initCount: 20];
	[categoryList addCategory:"phone"];

	/*  SET NUMBER OF CATEGORIES TO ZERO  */
	[categoryTotal setIntValue:[categoryList count]];

	/*  SET TARGET AND ACTION OF CATEGORY BROWSER  */
	[categoryBrowser setTarget:self];
	[categoryBrowser setAction:(SEL)(@selector(categoryBrowserHit:))];
	[categoryBrowser setDoubleAction:(SEL)(@selector(categoryBrowserDoubleHit:))];
	categoryCurrentRow = 0;
	[categoryModButton setEnabled:0];

	/*  SET FONT OF CATEGORY BROWSER  */
	fontObj = [Font newFont:FONTNAME size:FONTSIZE];
	[[categoryBrowser matrixInColumn:0] setFont:fontObj];
	return self;
}



- categoryBrowserHit:sender
{
	/*  SET VARIABLE TO INDICATE SELECTED ROW  */
	categoryCurrentRow = [[sender matrixInColumn:0] selectedRow];

	/*  ENABLE MOD BUTTON  */
	[categoryModButton setEnabled:1];

	return self;
}



- categoryBrowserDoubleHit:sender
{
	/*  SAME AS USING THE MODIFY BUTTON  */
	[self modCategory:self];
	return self;
}



- (int)browser:sender fillMatrix:matrix inColumn:(int)column
{
//	printf("Browser: fillMatrix\n");
	/*  DELEGATE METHOD FOR NXBROWSER  */
	/*  MERELY UPDATE THE BROWSER WITH THE NUMBER OF ITEMS  */
	if (sender == categoryBrowser) 
	{
		return([categoryList count]);
	}
	else
		return(0);
}

- browser:sender loadCell:cell atRow:(int)row inColumn:(int)column
{
CategoryNode *currentNode;

//	printf("Browser: loadCell\n");

	if (sender == categoryBrowser)
	{
		/* Get CategoryNode Object From Category List (indexed by row) */
		currentNode = [categoryList objectAt:row];

		[cell setStringValue:[currentNode symbol]];
	}

	/*  INDICATE THAT THE CELL IS A LEAF NODE  */
	[cell setLeaf:YES];
	return self;
}




- addCategory:sender
{
	/*  PUT IN DEFAULT VALUES INTO CATEGORY FIELD  */
	[addCategoryField setStringValue:CATEGORY_SYMBOL_DEF at:CATEGORY_SYMBOL];

	/*  PUT IN DEFAULT FOR ORDER  */
	[addCategoryField setIntValue:categoryCurrentRow at:CATEGORY_ORDER];

	/*  PUT CURSOR IN FIRST FIELD  */
	[addCategoryField selectTextAt:CATEGORY_SYMBOL];

	/*  PUT PANEL IN PROPER RELATION TO CATEGORIES WINDOW  */
	[categoriesWindow getFrame:(NXRect *)&r];
	[addCategoryPanel moveTo:(NXCoord)r.origin.x+CATEGORY_X_OFFSET
			 :(NXCoord)r.origin.y+CATEGORY_Y_OFFSET];

	/*  MAKE PANEL VISIBLE  */
	[addCategoryPanel makeKeyAndOrderFront:self];

	/*  MAKE SURE PANEL IS MODAL  */
	[NXApp runModalFor:addCategoryPanel];
	return self;
}

- modCategory:sender
{
CategoryNode *currentNode;

	/*  PUT PANEL IN PROPER RELATION TO CATEGORIES WINDOW  */
	[categoriesWindow getFrame:(NXRect *)&r];
	[modCategoryPanel moveTo:(NXCoord)r.origin.x+CATEGORY_X_OFFSET
		:(NXCoord)r.origin.y+CATEGORY_Y_OFFSET];

	/*  PUT IN VALUES FOR CATEGORY CHOSEN  */
	currentNode = [categoryList objectAt:categoryCurrentRow];

	[modCategoryField setStringValue:[currentNode symbol] at:CATEGORY_SYMBOL];
	[modCategoryField setIntValue:categoryCurrentRow at:CATEGORY_ORDER];

	/*  PUT CURSOR AT SYMBOL FIELD  */
	[modCategoryField selectTextAt:CATEGORY_SYMBOL];

	/*  MAKE PANEL VISIBLE  */
	[modCategoryPanel makeKeyAndOrderFront:self];

	/*  MAKE SURE PANEL IS MODAL  */
	[NXApp runModalFor:modCategoryPanel];
	return self;
}




- addCategoryCancel:sender
{
	/*  CLOSE THE PANEL  */
	[addCategoryPanel close];
	[NXApp stopModal];
	return self;
}

- addCategoryAdd:sender
{
int order, i, len;
char string[SYMBOL_LENGTH_MAX+1];
CategoryNode *currentNode;

	/*  MAKE SURE STRING CONTAINS NO BLANKS  */
	strncpy(string,[addCategoryField stringValueAt:CATEGORY_SYMBOL],SYMBOL_LENGTH_MAX);
	string[SYMBOL_LENGTH_MAX] = '\0';
	len = strlen(string);
	if (len == 0)
	{
		NXBeep();
		NXRunAlertPanel("Illegal", "Symbol cannot contain blanks.", 
					"OK", NULL, NULL);
		/*  PUT CURSOR IN FIRST FIELD  */
		[addCategoryField selectTextAt:CATEGORY_SYMBOL];
		return self;
	}

	for (i = 0; i < len; i++) 
	{
		if (string[i] == ' ')
		{
			NXBeep();
			NXRunAlertPanel("Illegal", "Symbol cannot contain blanks.", 
						"OK", NULL, NULL);
			/*  PUT CURSOR IN FIRST FIELD  */
			[addCategoryField selectTextAt:CATEGORY_SYMBOL];
			return self;
		}
	}

	/*  MAKE SURE SYMBOL IS UNIQUE  */
	if (![self symbolUnique:string])
	{
		NXBeep();
		NXRunAlertPanel("Illegal", "Symbol \"%s\" has already\nbeen used.", 
				"OK", NULL, NULL, string);
		/*  PUT CURSOR IN FIRST FIELD  */
		[addCategoryField selectTextAt:CATEGORY_SYMBOL];
		return self;
	}

	/*  MAKE SURE SYMBOL IS NOT USED AS PHONE IN TEMPLATE  */
	if ((i = [template usedAsPhoneSymbol:string]) != 0)
	{
		NXBeep();
		NXRunAlertPanel("Illegal",
		   "Symbol \"%s\" has already been used\nas a phone symbol in template\nat position %-d.", 
		   "OK", NULL, NULL, string, i);
		/*  PUT CURSOR IN FIRST FIELD  */
		[addCategoryField selectTextAt:CATEGORY_SYMBOL];
		return self;
	}

	/*  MAKE SURE SYMBOL IS NOT RESERVED SYMBOL  */
	if (reserved_symbol(string))
	{
		NXBeep();
		NXRunAlertPanel("Illegal",
		   "Symbol \"%s\" is a reserved symbol.", 
		   "OK", NULL, NULL, string);
		/*  PUT CURSOR IN FIRST FIELD  */
		[addCategoryField selectTextAt:CATEGORY_SYMBOL];
		return self;
	}
	
	/*  GET DESIRED ORDER OF CATEGORY  */
	order = [addCategoryField intValueAt:CATEGORY_ORDER];

	/*  MAKE SURE ORDER IS IN RANGE  */
	if (order > [categoryList count] )
		order = [categoryList count];
	else if (order < 0)
		order = 0;

	/*  ADD NEW CATEGORY INTO LINKED LIST  */

	currentNode = [[CategoryNode alloc] initWithSymbol:string];
	[categoryList insertObject: currentNode at:order];

	/*  UPDATE TOTAL NUMBER OF CATEGORIES  */
	[categoryTotal setIntValue:[categoryList count]];
	categoryCurrentRow = 0;

	/*  DISABLE MOD BUTTON  */
	[categoryModButton setEnabled:0];

	/*  RELOAD LIST INTO BROWSER  */
	[categoryBrowser loadColumnZero];

	/*  SCROLL TO LATEST ITEM, SO IT CAN BE SEEN  */
	[[categoryBrowser matrixInColumn:0] scrollCellToVisible:order-1 :0];

	/*  UPDATE DESIRED ORDER  */
	[addCategoryField setIntValue:[categoryList count] at:CATEGORY_ORDER];

	/*  PUT CURSOR IN FIRST FIELD  */
	[addCategoryField selectTextAt:CATEGORY_SYMBOL];

	return self;
}



- modCategoryCancel:sender
{
	/*  CLOSE THE PANEL  */
	[modCategoryPanel close];
	[NXApp stopModal];
	return self;
}

- modCategoryDelete:sender
{
int i;
CategoryNode *currentNode;

	if (!strcmp([[categoryList objectAt: categoryCurrentRow] symbol], "phone"))
	{
		NXBeep();
		NXRunAlertPanel("Illegal",
		   "Cannot remove \"phone\" category.", 
		   "OK", NULL, NULL);

		return self;
	}

	currentNode = [categoryList removeObjectAt: categoryCurrentRow];

	/*  DECREMENT TOTAL NUMBER OF CATEGORIES  */
	[categoryTotal setIntValue:[categoryList count]];
	i = categoryCurrentRow;
	if (i > [categoryList count])
	i--;
	categoryCurrentRow = 0;

	/*  DISABLE MOD BUTTON  */
	[categoryModButton setEnabled:0];

	/*  RELOAD LIST INTO BROWSER  */
	[categoryBrowser loadColumnZero];

	/*  SCROLL TO ROW WHERE DELETION OCCURRED  */
	[[categoryBrowser matrixInColumn:0] scrollCellToVisible:i-1 :0];

	/*  PROPAGATE DELETIONS IN PHONE DESCRIPTION OBJECT  */
	/* NOTE: This would be better as Object ids because of the use of the List object */
	[phoneDescriptionObj propagateDeleteCategory:[currentNode symbol]];
	[currentNode free];

	/*  CLOSE PANEL  */
	[modCategoryPanel close];
	[NXApp stopModal];
	return self;
}

- modCategoryOK:sender
{
int i, order, len;
char string[SYMBOL_LENGTH_MAX+1];
char old_string[SYMBOL_LENGTH_MAX+1];
CategoryNode *currentNode;

	bzero(old_string, SYMBOL_LENGTH_MAX+1);
	bzero(string, SYMBOL_LENGTH_MAX+1);

	/*  MAKE SURE STRING CONTAINS NO BLANKS  */
	strncpy(string,[modCategoryField stringValueAt:CATEGORY_SYMBOL],SYMBOL_LENGTH_MAX);
	string[SYMBOL_LENGTH_MAX] = '\0';
	len = strlen(string);
	if (len == 0)
	{
		NXBeep();
		NXRunAlertPanel("Illegal", "Symbol cannot contain blanks.", 
					"OK", NULL, NULL);
		/*  PUT CURSOR IN FIRST FIELD  */
		[modCategoryField selectTextAt:CATEGORY_SYMBOL];
		return self;
	}
	for (i = 0; i < len; i++)
	{
		if (string[i] == ' ')
		{
			NXBeep();
			NXRunAlertPanel("Illegal", "Symbol cannot contain blanks.", 
					"OK", NULL, NULL);
			/*  PUT CURSOR IN FIRST FIELD  */
			[modCategoryField selectTextAt:CATEGORY_SYMBOL];
			return self;
		}
	}

	/*  MAKE SURE SYMBOL IS UNIQUE  */
	if (![self symbolUnique:string])
	{
		NXBeep();
		NXRunAlertPanel("Illegal", "Symbol \"%s\" has already\nbeen used.", 
				"OK", NULL, NULL, string);
		/*  PUT CURSOR IN FIRST FIELD  */
		[modCategoryField selectTextAt:CATEGORY_SYMBOL];
		return self;
	}

	/*  MAKE SURE SYMBOL IS NOT USED AS PHONE IN TEMPLATE  */
	if ((i = [template usedAsPhoneSymbol:string]) != 0)
	{
		NXBeep();
		NXRunAlertPanel("Illegal",
		   "Symbol \"%s\" has already been used\nas a phone symbol in template\nat position %-d.", 
		   "OK", NULL, NULL, string, i);
		/*  PUT CURSOR IN FIRST FIELD  */
		[modCategoryField selectTextAt:CATEGORY_SYMBOL];
		return self;
	}

	/*  MAKE SURE SYMBOL IS NOT RESERVED SYMBOL  */
	if (reserved_symbol(string))
	{
		NXBeep();
		NXRunAlertPanel("Illegal",
		   "Symbol \"%s\" is a reserved category symbol.", 
		   "OK", NULL, NULL, string);
		/*  PUT CURSOR IN FIRST FIELD  */
		[modCategoryField selectTextAt:CATEGORY_SYMBOL];
		return self;
	}

	/*  TAKE OUT ITEM FROM LIST  */
	currentNode = [categoryList removeObjectAt:categoryCurrentRow];
	strcpy(old_string, [currentNode symbol]);
	[currentNode setSymbol:string];

	/*  GET DESIRED ORDER OF CATEGORY  */
	order = [modCategoryField intValueAt:CATEGORY_ORDER];

	/*  MAKE SURE ORDER IS IN RANGE  */
	if (order > [categoryList count])
		order = [categoryList count];
	else 
	if (order <= 0)
		order = 0;

	/*  ADD CATEGORY BACK INTO LINKED LIST USING NEW VALUES  */
	[categoryList insertObject: currentNode at: order];

	categoryCurrentRow = 0;

	/*  DISABLE MOD BUTTON  */
	[categoryModButton setEnabled:0];

	/*  RELOAD LIST INTO BROWSER  */
	[categoryBrowser loadColumnZero];

	/*  SCROLL TO CELL, SO IT CAN BE SEEN  */
	[[categoryBrowser matrixInColumn:0] scrollCellToVisible:order-1 :0];

	/*  PROPAGATE ANY CHANGE OF NAME IN PHONE DESCRIPTION OBJECT  */
	if (strcmp(old_string,string))
		[phoneDescriptionObj propagateModCategory:old_string :string];


	/*  CLOSE PANEL  */
	[modCategoryPanel close];
	[NXApp stopModal];
	return self;
}


- (int)usedAsCategorySymbol:(char *)string
{
int i;
	for (i = 0; i < [categoryList count]; i++)
		if (!strcmp(string, [[categoryList objectAt:i] symbol] ))
			return (i);
	return (-1);
}


- (char *)symbolAtRow:(int)row
{

	return ([[categoryList objectAt: row] symbol]);
}


- (int)numberOfCategories
{
	return [categoryList count];
}


/* ===========================================================================

	saveToFile: and ReadFromFile: must be re-written to use archived
	objects

===========================================================================*/

- saveToFile:(FILE *)fp1
{
int i, count;
char tempString[SYMBOL_LENGTH_MAX+1];

	count = [categoryList count];

	/*  WRITE CATEGORY SYMBOLS TO FILE  */
	fwrite(&count,sizeof(int),1,fp1);

	for (i = 0; i < count; i++)
	{
		bzero(tempString, SYMBOL_LENGTH_MAX+1);
		strcpy(tempString, [[categoryList objectAt:i] symbol]);
		fwrite(tempString, SYMBOL_LENGTH_MAX+1, 1, fp1);
	}

	return self;
}



- ReadFromFile:(FILE *)fp1
{
int i, count;

CategoryNode *currentNode;
char tempString[SYMBOL_LENGTH_MAX+1];

	/* free any existing objects */
	[categoryList freeObjects];


	/* Load in the count */
	fread(&count,sizeof(int),1,fp1);

	for (i = 0; i < count; i++)
	{
		fread(tempString,SYMBOL_LENGTH_MAX+1,1,fp1);
		currentNode = [[CategoryNode alloc] initWithSymbol: tempString];
		[categoryList addObject:currentNode];
	}

	if (![categoryList findSymbol: "phone"])
		[categoryList addCategory:"phone"];
		
	/*  RESET DISPLAY  */
	[categoryTotal setIntValue:[categoryList count]];

	/*  RELOAD LIST INTO BROWSER  */
	[categoryBrowser loadColumnZero];
	categoryCurrentRow = 0;

	return self;
}



categoryStructPtr new_categoryStruct()
{
return ( (categoryStructPtr) malloc(sizeof(categoryStruct)) );
}

-(BOOL) symbolUnique: (char *) aSymbol
{
int i;
	for (i = 0; i < [categoryList count]; i++)
		if (!strcmp(aSymbol, [[categoryList objectAt:i] symbol] ))
			return (FALSE);
	return TRUE;
}

- (CategoryList *) categoryList
{
	return categoryList;
}


@end
