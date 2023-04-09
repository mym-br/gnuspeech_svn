
#import <appkit/appkit.h>

/* Global access to main lists */
//PhoneList	*mainPhoneList;
//CategoryList	*mainCategoryList;
//SymbolList	*mainSymbolList;
//ParameterList	*mainParameterList;
//ParameterList	*mainMetaParameterList;

//EventList 	*eventList;

/* Global access to Data Managers */

//RuleList 	*ruleList;
//id		prototypeManager;
//id		stringParser;

int validPhone(char *token);

/*===========================================================================

	Author: Craig-Richard Taube-Schock
		Copyright (c) 1994, Trillium Sound Research Incorporated.
		All Rights Reserved.

=============================================================================

	Object: RealTimeController
	Purpose: Oversees the functioning of MONET in a real-time setting.

	Date: March 23, 1994

History:
	March 23, 1994
		Integrated into MONET.

===========================================================================*/

@interface RealTimeController:Object
{

}

- initWithFile: (const char *) fileName;
- synthesizeString: (const char *) string;
- setPitchMean: (double) aValue;
- setGlobalTempo: (double) aValue;
- setIntonation: (int) intonation;
- setSoftwareSynthesis: (int) newValue;

@end
