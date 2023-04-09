
/* Generated by Interface Builder */

#import "Categories.h"
#import "Template.h"
#import "PhoneDescription.h"
#import "Rule.h"
#import "reserved_symbol.h"
#import <appkit/appkit.h>

@implementation Categories

- appDidInit:sender
{
    /*  INITIALIZE POINTERS TO CATEGORY LIST  */
    number_of_categories = 0;
    categoryHead = NULL;

    /*  SET NUMBER OF CATEGORIES TO ZERO  */
    [categoryTotal setIntValue:number_of_categories];

    /*  SET TARGET AND ACTION OF CATEGORY BROWSER  */
    [categoryList setTarget:self];
    [categoryList setAction:(SEL)(@selector(categoryBrowserHit:))];
    [categoryList setDoubleAction:(SEL)(@selector(categoryBrowserDoubleHit:))];
    categoryCurrentRow = 0;
    [categoryModButton setEnabled:0];

    /*  SET FONT OF CATEGORY BROWSER  */
    fontObj = [Font newFont:FONTNAME size:FONTSIZE];
    [[categoryList matrixInColumn:0] setFont:fontObj];
    return self;
}



- categoryBrowserHit:sender
{
    /*  SET VARIABLE TO INDICATE SELECTED ROW  */
    categoryCurrentRow = [[sender matrixInColumn:0] selectedRow] + 1;

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
    /*  DELEGATE METHOD FOR NXBROWSER  */
    /*  MERELY UPDATE THE BROWSER WITH THE NUMBER OF ITEMS  */
    if (sender == categoryList) {
	return(number_of_categories);
    }
    else
    	return(0);
}

- browser:sender loadCell:cell atRow:(int)row inColumn:(int)column
{
    /*  NXBROWSER DELEGATE METHOD WHICH UPDATES PARTICULAR CELLS
        FROM THE DATA STORED IN LINKED LISTS  */
    int i, len;

    if (sender == categoryList) {
        categoryStructPtr current_ptr;
	char string[ROW_NUMBER_MAX+SYMBOL_LENGTH_MAX+1];

	/*  SEARCH THROUGH LIST TILL ITEM FOUND  */
	current_ptr = categoryHead;
	for (i = 0; i < row; i++)
	  current_ptr = current_ptr->next;
	/*  PUT ROW NUMBER AND SYMBOL IN CELL  */
	sprintf(string,"%-d.",row+1);
        len = strlen(string);
        for (i = 0; i < (ROW_NUMBER_MAX-len); i++)
	    strcat(string," ");
	strcat(string,current_ptr->symbol);
        [cell setStringValue:string];
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
    if (categoryCurrentRow == 0)
	[addCategoryField setIntValue:(number_of_categories+1) at:CATEGORY_ORDER];
    else
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
    int i;
    categoryStructPtr current_ptr;

    /*  MAKE SURE A CATEGORY HAS BEEN SELECTED  */
    if (categoryCurrentRow == 0) {
	NXBeep();
	return self;
    }

    /*  PUT PANEL IN PROPER RELATION TO CATEGORIES WINDOW  */
    [categoriesWindow getFrame:(NXRect *)&r];
    [modCategoryPanel moveTo:(NXCoord)r.origin.x+CATEGORY_X_OFFSET
		            :(NXCoord)r.origin.y+CATEGORY_Y_OFFSET];

    /*  PUT IN VALUES FOR CATEGORY CHOSEN  */
    current_ptr = categoryHead;
    for (i = 1; i < categoryCurrentRow; i++)
	current_ptr = current_ptr->next;
    [modCategoryField setStringValue:current_ptr->symbol at:CATEGORY_SYMBOL];
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
    categoryStructPtr temp_next, current_ptr, new_categoryStruct();
    char string[SYMBOL_LENGTH_MAX+1];

    /*  MAKE SURE STRING CONTAINS NO BLANKS  */
    strncpy(string,[addCategoryField stringValueAt:CATEGORY_SYMBOL],SYMBOL_LENGTH_MAX);
    string[SYMBOL_LENGTH_MAX] = '\0';
    len = strlen(string);
    if (len == 0) {
	NXBeep();
	NXRunAlertPanel("Illegal", "Symbol cannot contain blanks.", 
	                "OK", NULL, NULL);
	/*  PUT CURSOR IN FIRST FIELD  */
	[addCategoryField selectTextAt:CATEGORY_SYMBOL];
	return self;
    }
    for (i = 0; i < len; i++) {
	if (string[i] == ' ') {
	    NXBeep();
	    NXRunAlertPanel("Illegal", "Symbol cannot contain blanks.", 
	                "OK", NULL, NULL);
	    /*  PUT CURSOR IN FIRST FIELD  */
	    [addCategoryField selectTextAt:CATEGORY_SYMBOL];
	    return self;
	}
    }

    /*  MAKE SURE SYMBOL IS UNIQUE  */
    current_ptr = categoryHead;
    for (i = 0; i < number_of_categories; i++) {
	if (!strcmp(string,current_ptr->symbol)) {
	    NXBeep();
	    NXRunAlertPanel("Illegal", "Symbol \"%s\" has already\nbeen used at position %-d.", 
	                "OK", NULL, NULL, string, (i+1));
	    /*  PUT CURSOR IN FIRST FIELD  */
	    [addCategoryField selectTextAt:CATEGORY_SYMBOL];
	    return self;
	}
	current_ptr = current_ptr->next;
    }

    /*  MAKE SURE SYMBOL IS NOT USED AS PHONE IN TEMPLATE  */
    if ((i = [template usedAsPhoneSymbol:string]) != 0) {
	NXBeep();
        NXRunAlertPanel("Illegal",
           "Symbol \"%s\" has already been used\nas a phone symbol in template\nat position %-d.", 
           "OK", NULL, NULL, string, i);
	/*  PUT CURSOR IN FIRST FIELD  */
	[addCategoryField selectTextAt:CATEGORY_SYMBOL];
	return self;
    }

    /*  MAKE SURE SYMBOL IS NOT RESERVED SYMBOL  */
    if (reserved_symbol(string)) {
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
    if (order > (number_of_categories + 1) )
	order = number_of_categories + 1;
    else if (order <= 0)
	order = 1;

    /*  ADD NEW CATEGORY INTO LINKED LIST  */
    if (order == 1) {
	temp_next = categoryHead;
	categoryHead = new_categoryStruct();
        categoryHead->next = temp_next;
	strcpy(categoryHead->symbol,string);
    }
    else {
	current_ptr = categoryHead;
	for (i = 1; i < order; i++) {
	    if (i == (order-1)) {
		temp_next = current_ptr->next;
		current_ptr->next = new_categoryStruct();
		current_ptr->next->next = temp_next;
		strcpy(current_ptr->next->symbol,string);
		break;
	    }
	    current_ptr = current_ptr->next;
 	}
    }

    /*  UPDATE TOTAL NUMBER OF CATEGORIES  */
    [categoryTotal setIntValue:++number_of_categories];
    categoryCurrentRow = 0;

    /*  DISABLE MOD BUTTON  */
    [categoryModButton setEnabled:0];

    /*  RELOAD LIST INTO BROWSER  */
    [categoryList loadColumnZero];

    /*  SCROLL TO LATEST ITEM, SO IT CAN BE SEEN  */
    [[categoryList matrixInColumn:0] scrollCellToVisible:order-1 :0];

    /*  UPDATE DESIRED ORDER  */
    [addCategoryField setIntValue:(number_of_categories+1) at:CATEGORY_ORDER];

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
    categoryStructPtr next_temp, current_ptr;
    char string[SYMBOL_LENGTH_MAX+1];

    /*  GO TO STRUCT JUST BEFORE THE ONE TO DELETE,
        FREE STRUCT AND ADJUST LINKED LIST  */
    if (categoryCurrentRow == 1) {
        next_temp = categoryHead;
	categoryHead = categoryHead->next;
	strcpy(string,next_temp->symbol);
        free(next_temp);
    }
    else {
	current_ptr = categoryHead;
        for (i = 1; i < categoryCurrentRow; i++) {
	    if (i == categoryCurrentRow-1) {
		next_temp = current_ptr->next;
		current_ptr->next = current_ptr->next->next;
		strcpy(string,next_temp->symbol);
		free(next_temp);
		break;
	    }
            current_ptr = current_ptr->next;
        }
    }

    /*  DECREMENT TOTAL NUMBER OF CATEGORIES  */
    [categoryTotal setIntValue:--number_of_categories];
    i = categoryCurrentRow;
    if (i > number_of_categories)
	i--;
    categoryCurrentRow = 0;

    /*  DISABLE MOD BUTTON  */
    [categoryModButton setEnabled:0];

    /*  RELOAD LIST INTO BROWSER  */
    [categoryList loadColumnZero];

    /*  SCROLL TO ROW WHERE DELETION OCCURRED  */
    [[categoryList matrixInColumn:0] scrollCellToVisible:i-1 :0];

    /*  PROPAGATE DELETIONS IN PHONE DESCRIPTION OBJECT  */
    [phoneDescriptionObj propagateDeleteCategory:string];

    /*  CLOSE PANEL  */
    [modCategoryPanel close];
    [NXApp stopModal];
    return self;
}

- modCategoryOK:sender
{
    int i, order, len;
    categoryStructPtr next_temp, current_ptr, item_ptr;
    char string[SYMBOL_LENGTH_MAX+1];
    char old_string[SYMBOL_LENGTH_MAX+1];

    /*  MAKE SURE STRING CONTAINS NO BLANKS  */
    strncpy(string,[modCategoryField stringValueAt:CATEGORY_SYMBOL],SYMBOL_LENGTH_MAX);
    string[SYMBOL_LENGTH_MAX] = '\0';
    len = strlen(string);
    if (len == 0) {
	NXBeep();
	NXRunAlertPanel("Illegal", "Symbol cannot contain blanks.", 
	                "OK", NULL, NULL);
	/*  PUT CURSOR IN FIRST FIELD  */
	[modCategoryField selectTextAt:CATEGORY_SYMBOL];
	return self;
    }
    for (i = 0; i < len; i++) {
	if (string[i] == ' ') {
	    NXBeep();
	    NXRunAlertPanel("Illegal", "Symbol cannot contain blanks.", 
	                "OK", NULL, NULL);
	    /*  PUT CURSOR IN FIRST FIELD  */
	    [modCategoryField selectTextAt:CATEGORY_SYMBOL];
	    return self;
	}
    }

    /*  MAKE SURE SYMBOL IS UNIQUE  */
    current_ptr = categoryHead;
    for (i = 0; i < number_of_categories; i++) {
	if (!strcmp(string,current_ptr->symbol) && (i != categoryCurrentRow-1)) {
	    NXBeep();
	    NXRunAlertPanel("Illegal", "Symbol \"%s\" has already\nbeen used at position %-d.", 
	                "OK", NULL, NULL, string, (i+1));
	    /*  PUT CURSOR IN FIRST FIELD  */
	    [modCategoryField selectTextAt:CATEGORY_SYMBOL];
	    return self;
	}
	current_ptr = current_ptr->next;
    }

    /*  MAKE SURE SYMBOL IS NOT USED AS PHONE IN TEMPLATE  */
    if ((i = [template usedAsPhoneSymbol:string]) != 0) {
	NXBeep();
        NXRunAlertPanel("Illegal",
           "Symbol \"%s\" has already been used\nas a phone symbol in template\nat position %-d.", 
           "OK", NULL, NULL, string, i);
	/*  PUT CURSOR IN FIRST FIELD  */
	[modCategoryField selectTextAt:CATEGORY_SYMBOL];
	return self;
    }

    /*  MAKE SURE SYMBOL IS NOT RESERVED SYMBOL  */
    if (reserved_symbol(string)) {
	NXBeep();
        NXRunAlertPanel("Illegal",
           "Symbol \"%s\" is a reserved category symbol.", 
           "OK", NULL, NULL, string);
	/*  PUT CURSOR IN FIRST FIELD  */
	[modCategoryField selectTextAt:CATEGORY_SYMBOL];
	return self;
    }

    /*  TAKE OUT ITEM FROM LIST  */
    if (categoryCurrentRow == 1) {
        item_ptr = categoryHead;
	categoryHead = categoryHead->next;
    }
    else {
        item_ptr = NULL;
	current_ptr = categoryHead;
        for (i = 1; i < categoryCurrentRow; i++) {
	    if (i == categoryCurrentRow-1) {
		item_ptr = current_ptr->next;
		current_ptr->next = current_ptr->next->next;
		break;
	    }
            current_ptr = current_ptr->next;
        }
    }

    /*  GET DESIRED ORDER OF CATEGORY  */
    order = [modCategoryField intValueAt:CATEGORY_ORDER];

    /*  MAKE SURE ORDER IS IN RANGE  */
    if (order > number_of_categories)
	order = number_of_categories;
    else if (order <= 0)
	order = 1;

    /*  ADD CATEGORY BACK INTO LINKED LIST USING NEW VALUES  */
    if (order == 1) {
	next_temp = categoryHead;
	categoryHead = item_ptr;
        categoryHead->next = next_temp;
	strcpy(old_string,categoryHead->symbol);
	strcpy(categoryHead->symbol,string);
    }
    else {
	current_ptr = categoryHead;
	for (i = 1; i < order; i++) {
	    if (i == (order-1)) {
		next_temp = current_ptr->next;
		current_ptr->next = item_ptr;
		current_ptr->next->next = next_temp;
		strcpy(old_string,current_ptr->next->symbol);
		strcpy(current_ptr->next->symbol,string);
		break;
	    }
	    current_ptr = current_ptr->next;
 	}
    }
    categoryCurrentRow = 0;

    /*  DISABLE MOD BUTTON  */
    [categoryModButton setEnabled:0];

    /*  RELOAD LIST INTO BROWSER  */
    [categoryList loadColumnZero];

    /*  SCROLL TO CELL, SO IT CAN BE SEEN  */
    [[categoryList matrixInColumn:0] scrollCellToVisible:order-1 :0];

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
    categoryStructPtr current_ptr;
    int i;

    /*  MAKE SURE SYMBOL IS UNIQUE  */
    current_ptr = categoryHead;
    for (i = 0; i < number_of_categories; i++) {
	if (!strcmp(string,current_ptr->symbol)) {
	    return(i+1);
	}
	current_ptr = current_ptr->next;
    }

    return(0);
}


- (char *)symbolAtRow:(int)row
{
    int i;
    categoryStructPtr current_ptr;

    /*  SEARCH THROUGH LIST TILL ITEM FOUND  */
    current_ptr = categoryHead;
    for (i = 0; i < row; i++)
	current_ptr = current_ptr->next;

    /*  RETURN SYMBOL AT ROW NUMBER  */
    return ((char *)(current_ptr->symbol));
}



- (int)numberOfCategories
{
    return number_of_categories;
}



- saveToFile:(FILE *)fp1
{
    int i;
    categoryStructPtr current_category_ptr;

    /*  WRITE CATEGORY SYMBOLS TO FILE  */
    fwrite((char *)&number_of_categories,sizeof(number_of_categories),1,fp1);
    current_category_ptr = categoryHead;
    for (i = 0; i < number_of_categories; i++) {
	fwrite((char *)&(current_category_ptr->symbol),SYMBOL_LENGTH_MAX+1,1,fp1);
	current_category_ptr = current_category_ptr->next;
    }

    return self;
}



- readFromFile:(FILE *)fp1
{
    int i;
    categoryStructPtr current_category_ptr, temp_category_ptr, new_categoryStruct();

    /*  FIRST FREE ALL CURRENT CATEGORY MEMORY, IF NEEDED  */
    current_category_ptr = categoryHead;
    for (i = 0; i < number_of_categories; i++) {
	temp_category_ptr = current_category_ptr->next;
	free(current_category_ptr);
	current_category_ptr = temp_category_ptr;
    }

    /*  READ CATEGORY SYMBOLS FROM FILE  */
    fread((char *)&number_of_categories,sizeof(number_of_categories),1,fp1);
    categoryHead = NULL;
    for (i = 0; i < number_of_categories; i++) {
	if (i == 0) {
	    categoryHead = current_category_ptr = new_categoryStruct();
	}
	else {
	    current_category_ptr->next = new_categoryStruct();
	    current_category_ptr = current_category_ptr->next;	    
	}
	    fread((char *)&(current_category_ptr->symbol),SYMBOL_LENGTH_MAX+1,1,fp1);
	    current_category_ptr->next = NULL;
    }

    /*  RESET DISPLAY  */
    [categoryTotal setIntValue:number_of_categories];

    /*  RELOAD LIST INTO BROWSER  */
    [categoryList loadColumnZero];
    categoryCurrentRow = 0;

    return self;
}



categoryStructPtr new_categoryStruct()
{
return ( (categoryStructPtr) malloc(sizeof(categoryStruct)) );
}



@end
