/*
 *    Filename:	FileListing.h 
 *    Created :	Tue Jul  6 18:00:03 1993 
 *    Author  :	Dale Brisinda
 *		<dale@pegasus.cuc.ab.ca>
 *
 *    Last modified on "Fri Jul  9 16:23:38 1993"
 *
 * $Id: FileListing.h,v 1.2 1994/06/03 19:28:24 dale Exp $
 *
 * $Log: FileListing.h,v $
 * Revision 1.2  1994/06/03  19:28:24  dale
 * Changed "LastEditDate" to "Last modified on" within header.
 *
 * Revision 1.1  1993/07/14  22:11:48  dale
 * Initial revision
 *
 */

#import <objc/Object.h>

/* Length of character string instance variables. */
#define FL_PERMISSIONS_LEN 16
#define FL_FILENAME_LEN    256
#define FL_OWNER_LEN       16
#define FL_GROUP_LEN       16
#define FL_MONTH_LEN       16

@interface FileListing:Object
{
    char permissions[FL_PERMISSIONS_LEN];   // file permissions
    char filename[FL_FILENAME_LEN];         // name of file
    char owner[FL_OWNER_LEN];               // owner name of file
    char group[FL_GROUP_LEN];               // group name of file
    char month[FL_MONTH_LEN];               // month (3 chars) of last modification

    int day;                // day of last modification
    int hardlinks;          // number of hard links to file
    int sizeInBytes;        // size of file in bytes
    int tag;                // tag associated with object
}

/* GENERAL METHODS */
- initFromStream:(NXStream *)stream;
- initFromString:(const char *)fileListing;
- initFromFilePath:(const char *)filePath;

/* SET METHODS */
- setPermissions:(const char *)thePermissions;
- setFilename:(const char *)aFilename;
- setOwner:(const char *)theOwner;
- setGroup:(const char *)theGroup;
- setMonth:(const char *)theMonth;
- setDay:(int)theDay;
- setHardlinks:(int)numLinks;
- setSizeInBytes:(int)numBytes;
- setTag:(int)aTag;

/* QUERY METHODS */
- (const char *)permissions;
- (const char * )filename;
- (const char *)owner;
- (const char *)group;
- (const char *)month;

- (BOOL)isSymbolicLink;
- (BOOL)isDirectory;
- (BOOL)isFile;

- (int)day;
- (int)hardlinks;
- (int)sizeInBytes;
- (int)tag;

@end
