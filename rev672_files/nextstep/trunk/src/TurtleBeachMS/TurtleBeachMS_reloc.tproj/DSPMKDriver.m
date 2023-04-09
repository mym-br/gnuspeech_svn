/* DSPMKDriver.m by David A. Jaffe */

#import <driverkit/i386/directDevice.h>
#import <driverkit/i386/IOEISADeviceDescription.h>
#import <driverkit/generalFuncs.h>
#import <driverkit/interruptMsg.h>
#import <kernserv/kern_server_types.h>
#import <kernserv/prototypes.h>
#import "DSPMKDriver.h"

#define MAX_UNITS 16 /* Must match <dsp/DSPObject.h> DSP_MAXDSPS */

typedef struct _DSPMKDriverSubclassVars {
    int maxUnitNumber;
    DSPMKDriver *driverObjects[MAX_UNITS];
} DSPMKDriverSubclassVars;  

static DSPMKDriverSubclassVars classVars = {0};
/* DSPMKDriverSubclassVars are variables that we'll change to 
 * "class variables" if it's ever possible to have shared abstract 
 * super-classes in Driver Kit code.  Similarly, in that case, there will
 * be a separate classVars for each subclass.
 */

@implementation DSPMKDriver

+ (BOOL)probe:deviceDescription
  /*
   * Probe, configure board and init new instance.  This method is 
   * documented in the IODevice spec sheet.
   */
{
    id driver;
    IOEISADeviceDescription
      *devDesc = (IOEISADeviceDescription *)deviceDescription;
    if (classVars.maxUnitNumber == MAX_UNITS) {
	IOLog("Mididriver: Too many MIDI devices installed.  Maximum allowed = %d\n",
	      MAX_UNITS);
	return NO;
    }
    if ([devDesc numPortRanges] < 1) {
	printf("Wrong number of port ranges.\n");
	return NO;
    }

    // added by len
    if ([devDesc numInterrupts] != 1) {
	IOLog("DSPMKDriver:  Wrong number of interrupts.\n");
	return NO;
    }
    // end addition

    driver = [self alloc];
    if (driver == nil) {
      IOLog("Can't allocate mididriver object.\n");
      return NO;
    }
    /* Perform more device-specific validation, e.g. checking to make 
     * sure the I/O port range is large enough.  Make sure the 
     * hardware is really there. Return NO if anything is wrong. */
    
    return [driver initFromDeviceDescription:devDesc] != nil;
}

- initFromDeviceDescription:deviceDescription
{
  /*
   * Init the new instance.  This method is documented in the i386-specific
   * part of the IODirectDevice spec sheet.
   */
    char name[80];
    const IORange *range; 
    /* 
     * If the resources specified in this driver's bundle 
     * (in /usr/Devices/Mididriver.config/*.table) are already reserved,
     * [super initFromDeviceDescription:] will return nil.
     */
    if ([super initFromDeviceDescription:deviceDescription] == nil)
    	return nil;
    range = [deviceDescription portRangeList];
    baseIO = range->start;

    // added by len
    irq = [deviceDescription interrupt];
    // end addition

    sprintf(name,"%s%d",[[self class] name],classVars.maxUnitNumber);
//    IOLog("%s IO base address == 0x%x\n",name,baseIO); 

    // added by len
    IOLog("%s IO base address == 0x%x  IRQ == %d\n",name,baseIO,irq); 
    // end addition

    [self setName:name];
    [self setUnit:classVars.maxUnitNumber];
    /* Make it possible for MIG interface to find us */
    classVars.driverObjects[classVars.maxUnitNumber++] = self;
    [self setDeviceKind:"DSP"]; /* Added Sept. 5, 94 */
    [self setLocation:NULL];
    [self registerDevice];

    // added by len
    /*  Initialize messaging variables  */
    [self setMessagingOn:0];
    [self initOutputQueue];
    [self resetDMAOut];

    /*  Enable interrupts and IO thread  */
    [self startIOThread];
    [self enableAllInterrupts];
    // end addition

    return self; 
}

-_returnCharValue:(const char *)theValue 
  inArray:(unsigned char *)parameterArray
  count : (unsigned int *)count
{
    const char  *param;
    unsigned int length;
    unsigned int maxCount = *count;
    param = theValue;
    length = strlen(param);
    if(length >= maxCount) {
      length = maxCount - 1;
    }
    *count = length + 1;
    strncpy(parameterArray, param, length);
    parameterArray[length] = '\0';
    return self;
}

- (IOReturn)getCharValues   : (unsigned char *)parameterArray
               forParameter : (IOParameterName)parameterName
                      count : (unsigned int *)count
{
  /* 
   * This method is documented in the IODevice spec sheet.
   */
    if(strcmp(parameterName, DSPDRIVER_PAR_MONITOR) == 0){
      [self _returnCharValue:[[self class] monitorFileName]
       inArray:parameterArray 
       count:count];
      return IO_R_SUCCESS;
    }
    else if(strcmp(parameterName, DSPDRIVER_PAR_SERIALPORTDEVICE) == 0){
      [self _returnCharValue:[[self class] serialPortDeviceName]
       inArray:parameterArray 
       count:count];
      return IO_R_SUCCESS;
    }
    else if(strcmp(parameterName, DSPDRIVER_PAR_ORCHESTRA) == 0){
      [self _returnCharValue:[[self class] orchestraName]
       inArray:parameterArray 
       count:count];
      return IO_R_SUCCESS;
    }
    else if(strcmp(parameterName, DSPDRIVER_PAR_WAITSTATES) == 0){
      [self _returnCharValue:[[self class] waitStates]
       inArray:parameterArray 
       count:count];
      return IO_R_SUCCESS;
    }
    else { 
	/* Pass parameters we don't recognize to our superclass. */
        return [super getCharValues:parameterArray 
            forParameter:parameterName count:count];
    }
}

#import "dspdriver_server.c"

#import "dspdriverServer.c"

@end
