
#import <appkit/appkit.h>

@interface MyController:Object
{
	id	machPriorityField;
	id	machPrioritySlider;

	id	timeQuantumField;
	id	timeQuantumSlider;

	id	silencePrefillField;
	id	silencePrefillSlider;

	id	schedulingPolicyMatrix;

	id	killSwitch;

	id	serverVersionText;
	id	dictionaryVersionText;
	id	compiledVersionText;
	id	serverPIDText;

	id	connectPanel;

	id	mySpeech;
}

- appDidInit:sender;
- setServerInfo;

- newPriority:sender;

- newTimeQuantum:sender;
- newTimeQuantumText:sender;

- newPrefill:sender;
- newPrefillText:sender;

- newPolicy:sender;

- setValues:sender;
- restartServer:sender;

@end
