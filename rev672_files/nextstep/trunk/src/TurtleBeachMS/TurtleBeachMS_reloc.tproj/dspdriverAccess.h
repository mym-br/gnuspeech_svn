#ifndef __MK_dspdriverAccess_H___
#define __MK_dspdriverAccess_H___
/*
  dspdriverAccess.h.
  David Jaffe, CCRMA, Stanford University.
  Feb. 1994
*/
typedef unsigned int dsp_id;

/************  Set-up functions ****************************/

/* To use a DSP, you must first "add" it, then "open" it, then "reset" it. 
 */
extern int dsp_addDsp(dsp_id dspId,const char *driver,int unit);
/* dspId must not have been added yet. */

extern int dsp_open(dsp_id dspId);  
extern int dsp_close(dsp_id dspId); 
extern int dsp_reset(dsp_id dspId,char on);

extern void 
  setDSPDriverErrorProc(void (*errFunc)(dsp_id dspId,
					char *caller,
					char *errorMessage,
					int errorCode));
/* Use this to register an error function.  Otherwise, errors are
 * printed to stderr.  Note that stderr is not thread-safe.
 * Hence if you access the dspdriver in other than the main
 * thread, you should probably register your own error handler.
 */

/* Simple low level functions *************************/
extern char dsp_getICR(dsp_id dspId);
extern char dsp_getCVR(dsp_id dspId);
extern char dsp_getISR(dsp_id dspId);
extern char dsp_getIVR(dsp_id dspId);

extern void dsp_putICR(dsp_id dspId, char b);
extern void dsp_putCVR(dsp_id dspId, char b);
extern void dsp_putIVR(dsp_id dspId, char b);

extern void dsp_putTXRaw(dsp_id dspId,char high,char med,char low);
extern void dsp_getRXRaw(dsp_id dspId,char *high,char *med,char *low);

extern int dsp_getHI(dsp_id dspId); /* Returns: ICR|CVR|ISR|IVR packed */

/**************** Word I/O with checking of ISR bits ******/
extern void dsp_putTX(dsp_id dspId,char high,char med,char low);
/* Like dsp_putTXRaw, but waits for TXDE to be set. */

extern void dsp_getRX(dsp_id dspId,char *high,char *med,char *low);
/* Like dsp_getRXRaw but waits for ISR&1 (RXDF) to be set. */


/**************** Array (TX/RX) I/O with checking of ISR bits ******/
extern void dsp_putArray(dsp_id dspId,int *arr,unsigned int count);
/* Like dsp_putTX, but puts a whole array of 24-bit numbers, right-justified   
   in 32-bits
   */

extern void dsp_getArray(dsp_id dspId,int *arr,unsigned int count);
/* Like dsp_getRX but gets a whole array.
   arr must point to at least count elements 
   */

extern void dsp_putShortArray(dsp_id dspId,short *arr,unsigned int count);
/* Like dsp_putTX but puts a whole array of 16-bit numbers.  These numbers
   are sign extended into TXH */

extern void dsp_putLeftArray(dsp_id dspId,int *arr,unsigned int count);
/* Like dsp_putTX but puts a whole array of 24-bit numbers, left-justified
   in 32-bits
   */

extern void dsp_putByteArray(dsp_id dspId,char *arr,unsigned int count);
/* Like dsp_putTX but puts a whole array of bytes.  These numbers are
   sign extended into TXH and TXM 
   */

extern void dsp_putPackedArray(dsp_id dspId,char *arr,unsigned int count);
/* Like dsp_putTX but puts a whole array of 24-bit packed numbers.  
   Note that count is the number of 24-bit numbers, not the number of bytes.
   */

/******************* Special Music Kit functions. *************/
extern void dsp_executeMKTimedMessage(dsp_id dspId,int highWord,int lowWord,
				      int opCode);
    /* Special Music Kit function for finishing a timed message */

extern void dsp_executeMKHostMessage(dsp_id dspId);
    /* Special Music Kit function for executing a Host Message, which
     * is assumed already written to the HMS.
     */



// added by len

#import <mach/mach_types.h>


extern void dsp_putPage(dsp_id dspId, vm_address_t pageAddress,
			int regionTag, boolean_t msgStarted,
			boolean_t msgCompleted, port_t reply_port);
    /* Puts a page of ints (actually 2048 DSPFix24s), located at
     * the vm allocated by the user at pageAddress, to the DSP.
     * A mach message is returned to the reply_port if the caller
     * sets the write started or completed flag.  This function
     * partially replaces the functionality of the
     * snddriver_start_writing function found on black hardware.
     * This function does not rely on messaging (i.e. interrupts)
     * used in the following three functions, so it can be used
     * like the other "put" functions above.  However, this function
     * is somewhat more efficient since the data is mapped, not copied,
     * using out-of-line mach messaging.
     */

extern void dsp_setMessaging(dsp_id dspId, boolean_t flag);
    /* Turns DSP messaging (i.e. "DSP-initiated DMA") on or off.
     * Messaging should be turned on once the DSP has been booted
     * and code loaded, using the functions above.  Reseting the
     * DSP always turns off messaging.  Once messaging is on, you
     * can use the following two functions to send or receive data
     * efficiently.
     */

extern void dsp_queuePage(dsp_id dspId, vm_address_t pageAddress,
			  int regionTag, boolean_t msgStarted,
			  boolean_t msgCompleted, port_t reply_port);
    /* Queues a page of 2048 DSPFix24s to the driver.  This queue is
     * a circular buffer which can hold up to 16 pages, so be sure the
     * DSP starts reading data before the queue overfills.  The DSP
     * reads data from the queue using the "DMA stream" protocol found
     * on black hardware (i.e. the DSP initiates the transfer by sending
     * a $040002 to the host, and then follows the handshaking sequence).
     * A mach message is returned to the reply_port if the msgStarted or
     * msgCompleted flags are set.  This function provides a minimal
     * emulation of the snddriver_start_writing function found on black
     * hardware.  It is efficient since the data is mapped, not copied,
     * using out-of-line mach messaging, and the data is sent to the DSP
     * when the DSP messages (interrupts) the host.
     */

extern void dsp_setShortSwappedReturn(dsp_id dspId, int regionTag,
				      int wordCount, port_t reply_port);
    /* Sets the reply_port, region tag, and buffer size for returning
     * 16 bit sample data to the host.  The wordCount is the buffer size
     * used by the DSP for one transfer to the host.  The host must
     * use msg_receive to get this data, and must deallocate the vm
     * sent in the out-of-line message.  (The user should implement
     * a function that emulates snddriver_reply_handler(), to read the
     * reply messages the driver now generates in this, and the above,
     * function).  The DSP sends data to the host using the "DMA stream"
     * protocol on found on black hardware (i.e. the DSP initiates the
     * transfer by sending a $050001 to the host, and then follows the
     * established handshaking sequence).  This function provides
     * a minimal emulation of the snddriver_start_reading function on
     * black hardware.  It is efficient since data is mapped in out-of-line
     * mach messages, and the data is sent immediately when the DSP
     * interrupts (i.e. messages) the host.  Note that the host takes the
     * lower two bytes of data transferred, and swaps them, so that the
     * returned region contains big-endian short (16 bit) ints.  This means
     * that the data can be immediately stored in a sndstruct, since all
     * sample data (as well as the header) is stored big-endian on file.
     */
// end addition

#endif
