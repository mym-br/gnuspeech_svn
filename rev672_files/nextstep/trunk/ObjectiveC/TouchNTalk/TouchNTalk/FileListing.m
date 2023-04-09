/*
 *    Filename:	FileListing.m 
 *    Created :	Tue Jul  6 18:25:03 1993 
 *    Author  :	Dale Brisinda
 *		<dale@pegasus.cuc.ab.ca>
 *
 *    Last modified on "Fri Jul  9 17:27:13 1993"
 *
 * $Id: FileListing.m,v 1.2 1994/06/03 19:28:24 dale Exp $
 *
 * $Log: FileListing.m,v $
 * Revision 1.2  1994/06/03  19:28:24  dale
 * Changed "LastEditDate" to "Last modified on" within header.
 *
 * Revision 1.1  1993/07/14  22:11:48  dale
 * Initial revision
 *
 */

#import <libc.h>
#import "FileListing.h"

@implementation FileListing

/* This method is the designated initializer for the class. We initialize all the file listing
 * attributes for the first file listing string that is matched in the stream. The stream should
 * contain at least one file listing string of the same form obtained by typing "ls -alg <filename>"
 * in a shell (or equivalent). The stream file pointer must be positioned so that it begins at the 
 * start of a file listing string. If an error occurred and we were not able to get all the required
 * information, we return nil, otherwise we return self.
 */
- initFromStream:(NXStream *)stream
{
    char garbage[MAXPATHLEN];

    [super init];
    if (NXScanf(stream, "%s%d%s%s%d%s%d%* :%* %s", permissions, &hardlinks, owner, group, 
		&sizeInBytes, month, &day, filename) != 8) {   // unsuccesful read
	if (NXScanf(stream, "%s", filename) != 1) {   // must be year instead of hour and minute
	    [self free];
	    return nil;
	}
    }
    if (permissions[0] == 'l') {   // throw out the "-> ..." portion of the symbolic link listing
	NXScanf(stream, " -> %s", garbage);
    }
    return self;
}

/* We initialize all the file listing attributes for the file listing string supplied. This string 
 * should contain the same output as that obtained when typing "ls -lgALd <filename>" in a shell (or
 * equivalent). Returns self. NOT IMPLEMENTED.
 */
- initFromString:(const char *)fileListing
{
    return nil;
}

/* We initialize all the file listing attributes for the file path supplied by using the "ls -lgALd" 
 * command. Once the string is obtained, we pass it to -initFromString:. All instance variables are 
 * then loaded with the appropriate values. Returns self. NOT IMPLEMENTED.
 */
- initFromFilePath:(const char *)filePath
{
    return nil;
}

/* All set methods that take const char strings as arguments, only look at the required number of 
 * characters as defined in the class definitions. All return self.
 */

- setPermissions:(const char *)thePermissions
{
    if (thePermissions && thePermissions[0] != (char)0) {
	strncpy(permissions, thePermissions, FL_PERMISSIONS_LEN);
	permissions[FL_PERMISSIONS_LEN-1] = (char)0;
    } else {
	permissions[0] = (char)0;
    }
    return self;
}

- setFilename:(const char *)aFilename
{
    if (aFilename && aFilename[0] != (char)0) {
	strncpy(filename, aFilename, FL_FILENAME_LEN);
	filename[FL_FILENAME_LEN-1] = (char)0;
    } else {
	filename[0] = (char)0;
    }
    return self;
}

- setOwner:(const char *)theOwner
{
    if (theOwner && theOwner[0] != (char)0) {
	strncpy(owner, theOwner, FL_OWNER_LEN);
	owner[FL_OWNER_LEN-1] = (char)0;
    } else {
	owner[0] = (char)0;
    }
    return self;
}

- setGroup:(const char *)theGroup
{
    if (theGroup && theGroup[0] != (char)0) {
	strncpy(group, theGroup, FL_GROUP_LEN);
	group[FL_GROUP_LEN-1] = (char)0;
    } else {
	group[0] = (char)0;
    }
    return self;
}

- setMonth:(const char *)theMonth
{
    if (theMonth && theMonth[0] != (char)0) {
	strncpy(month, theMonth, FL_MONTH_LEN);
	month[FL_MONTH_LEN-1] = (char)0;
    } else {
	month[0] = (char)0;
    }
    return self;
}

- setDay:(int)theDay
{
    day = theDay;
    return self;
}

- setHardlinks:(int)numLinks
{
    hardlinks = numLinks;
    return self;
}

- setSizeInBytes:(int)numBytes
{
    sizeInBytes = numBytes;
    return self;
}

- setTag:(int)aTag
{
    tag = aTag;
    return self;
}

- (const char *)permissions
{
    if (permissions[0] == (char)0) {
	return NULL;
    }
    return permissions;
}
    
- (const char * )filename
{
    if (filename[0] == (char)0) {
	return NULL;
    }
    return filename;
}

- (const char *)owner
{
    if (owner[0] == (char)0) {
	return NULL;
    }
    return owner;
}

- (const char *)group
{
    if (group[0] == (char)0) {
	return NULL;
    }
    return group;
}

- (const char *)month
{
    if (month[0] == (char)0) {
	return NULL;
    }
    return month;
}

- (BOOL)isSymbolicLink
{
    if (permissions[0] == 'l') {
	return YES;
    }
    return NO;
}

- (BOOL)isDirectory
{
    if (permissions[0] == 'd') {
	return YES;
    }
    return NO;
}

- (BOOL)isFile
{
    if (permissions[0] == '-') {
	return YES;
    }
    return NO;
}

- (int)day
{
    return day;
}

- (int)hardlinks
{
    return hardlinks;
}

- (int)sizeInBytes
{
    return sizeInBytes;
}

- (int)tag
{
    return tag;
}

@end
