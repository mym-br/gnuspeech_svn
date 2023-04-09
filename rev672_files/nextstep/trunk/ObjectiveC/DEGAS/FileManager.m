
/* Generated by Interface Builder */

#import "FileManager.h"
#import "Template.h"
#import "Categories.h"
#import "PhoneDescription.h"
#import "Rule.h"
#import "Generate.h"
#import "Synthesize.h"
#import <appkit/appkit.h>
#import <stdio.h>
#import <string.h>
#import <libc.h>


#define SUFFIX               "degas"
#define DB_SUFFIX            "degas_db"
#define LOG_SUFFIX           "degas_log"
#define DEFAULT_FILENAME     "untitled.degas"
#define MAGIC_NUMBER         0x2e646567


@implementation FileManager

- appDidInit:sender
{
    /*  CREATE OPEN PANEL  */
    openPanel = [OpenPanel new];

    /*  CREATE SAVE PANEL, SET TITLE AND SUFFIX  */
    savePanel = [SavePanel new];
    [savePanel setRequiredFileType:SUFFIX];
    [savePanel setTitle:"Save as"];

    /*  SET DEFAULT CURRENT FILE NAME, DIRECTORY NAME, PATH NAME  */
    strcpy(currentFile,DEFAULT_FILENAME);
    getwd(currentDirectory);
    strcpy(currentPath,currentDirectory);
    strcat(currentPath,"/");
    strcat(currentPath,currentFile);

    /*  SET TITLES FOR MOST WINDOWS  */
    [self setTitles];

    return self;
}



- save:sender
{
    FILE *fopen(), *fp1;
    int magic = MAGIC_NUMBER;

    /*  TRY TO OPEN FILE  */
    if ((fp1 = fopen(currentPath,"w")) == NULL) {
	NXBeep();
	NXRunAlertPanel("File Error","Could not create file:  %s\nin:  %s\nfor some reason.",
			"OK",NULL,NULL,currentFile,currentDirectory);
	return self;
    }

    /*  WRITE MAGIC NUMBER TO FILE  */
    fwrite(&magic,sizeof(magic),1,fp1);

    /*  WRITE DATA TO FILE FROM EACH OBJECT  */
    [template saveToFile:(FILE *)fp1];
    [categories saveToFile:(FILE *)fp1];
    [phones saveToFile:(FILE *)fp1];
    [rule saveToFile:(FILE *)fp1];
    [generate saveToFile:(FILE *)fp1];
    [synthesize saveToFile:(FILE *)fp1];

    /*  CLOSE THE FILE  */
    fclose(fp1);

    return self;
}

- saveAs:sender
{
    /*  RUN MODAL SAVE PANEL  */
    if ([savePanel runModalForDirectory:currentDirectory file:currentFile]) {
	/*  GET CURRENT FILE, DIRECTORY, AND PATH NAMES  */
	strcpy(currentFile,strrchr([savePanel filename],'/')+1);
	strcpy(currentDirectory,[savePanel directory]);
	strcpy(currentPath,[savePanel filename]);
	/*  SAVE TO CURRENT PATHNAME AS SET IN SAVE PANEL  */
	[self save:self];
	/*  SET TITLES FOR MOST WINDOWS  */
	[self setTitles];
    }
    return self;
}



- saveLogAs:log
{
    char logPath[MAXPATHLEN], logDirectory[MAXPATHLEN], logFile[256];
    int n, fd;
    NXStream *stream;

    /*  USE A DIFFERENT SUFFIX FOR LOG FILES  */
    [savePanel setRequiredFileType:LOG_SUFFIX];

    /*  USE CURRENT DB FILE NAME WITH LOG SUFFIX  */
    if (strrchr(dbPath,'.') != NULL) {
	n = strlen(dbPath) - strlen(strrchr(dbPath,'.')+1);
	logPath[0] = '\0';
	strncat(logPath,dbPath,n);
	strcat(logPath,LOG_SUFFIX);
    }
    else {
	strcpy(logPath,dbPath);
	strcat(logPath,".");
	strcat(logPath,LOG_SUFFIX);
    }
    /*  GET JUST FILE NAME FROM PATHNAME  */
    strcpy(logFile,strrchr(logPath,'/')+1);

    /*  RUN MODAL SAVE PANEL  */
    if ([savePanel runModalForDirectory:dbDirectory file:logFile]) {
	/*  GET NAME OF LOG FILE  */
	strcpy(logPath,[savePanel filename]);
	strcpy(logFile,strrchr([savePanel filename],'/')+1);
	strcpy(logDirectory,[savePanel directory]);
	/*  TRY TO OPEN FILE  */
	fd = open(logPath, O_WRONLY|O_CREAT|O_TRUNC, 0644);
	if (fd < 0) {
	    NXBeep();
	    NXRunAlertPanel("File Error","Could not create file:  %s\nin:  %s\nfor some reason.",
			    "OK",NULL,NULL,logFile,logDirectory);
	    return self;
	}
	stream = NXOpenFile(fd,NX_WRITEONLY);
	/*  WRITE LOG OUT TO FILE  */
	[log writeText:stream];
	/*  CLOSE STREAM AND FILE  */
	NXClose(stream);
	close(fd);
    }

    /*  RESTORE ORIGINAL SUFFIX  */
    [savePanel setRequiredFileType:SUFFIX];

    return self;
}



- open:sender
{
    char *fileTypes[] = {SUFFIX,NULL};
    FILE *fopen(), *fp1;
    int magic;

    /*  RUN MODAL OPEN PANEL  */
    if ([openPanel runModalForDirectory:currentDirectory file:NULL types:fileTypes]) {
	/*  GET CURRENT FILE, DIRECTORY, AND PATH NAMES  */
	strcpy(currentFile,strrchr([openPanel filename],'/')+1);
	strcpy(currentDirectory,[openPanel directory]);
	strcpy(currentPath,[openPanel filename]);

	/*  TRY TO OPEN FILE  */
	if ((fp1 = fopen(currentPath,"r")) == NULL) {
	    NXBeep();
	    NXRunAlertPanel("File Error","Could not read file:  %s\nin:  %s\nfor some reason.",
			    "OK",NULL,NULL,currentFile,currentDirectory);
	    return self;
	}

	/*  CHECK FOR MAGIC NUMBER  */
	fread(&magic,sizeof(magic),1,fp1);
	if (magic != MAGIC_NUMBER) {
	    NXBeep();
	    NXRunAlertPanel("File Error","%s is corrupted.\nTry another file.",
			    "OK",NULL,NULL,currentFile);
	    fclose(fp1);
	    return self;
	}

	/*  USE FILE TO INITIALIZE OTHER OBJECTS  */
	[template ReadFromFile:fp1];
	[categories ReadFromFile:(FILE *)fp1];
	[phones ReadFromFile:(FILE *)fp1];
	[rule ReadFromFile:(FILE *)fp1];
	[generate ReadFromFile:(FILE *)fp1];
	[synthesize ReadFromFile:(FILE *)fp1];

	/*  SET TITLES FOR MOST WINDOWS  */
	[self setTitles];

	/*  CLOSE THE FILE  */
	fclose(fp1);

    }
    return self;
}



- (int)openDBFile:(FILE **)fp
{
    char dbFile[256];
    int n;

    /*  USE A DIFFERENT SUFFIX FOR DB FILES  */
    [savePanel setRequiredFileType:DB_SUFFIX];

    /*  USE CURRENT FILE NAME WITH DB SUFFIX  */
    if (strrchr(currentPath,'.') != NULL) {
	n = strlen(currentPath) - strlen(strrchr(currentPath,'.')+1);
	dbPath[0] = '\0';
	strncat(dbPath,currentPath,n);
	strcat(dbPath,DB_SUFFIX);
    }
    else {
	strcpy(dbPath,currentPath);
	strcat(dbPath,".");
	strcat(dbPath,DB_SUFFIX);
    }
    /*  GET JUST FILE NAME FROM PATHNAME  */
    strcpy(dbFile,strrchr(dbPath,'/')+1);

    /*  RUN MODAL SAVE PANEL  */
    if ([savePanel runModalForDirectory:currentDirectory file:dbFile]) {
	/*  GET NAME OF DB FILE  */
	strcpy(dbPath,[savePanel filename]);
	strcpy(dbFile,strrchr([savePanel filename],'/')+1);
	strcpy(dbDirectory,[savePanel directory]);
	/*  TRY TO OPEN FILE  */
	if ((*fp = fopen(dbPath,"w")) == NULL) {
	    NXBeep();
	    NXRunAlertPanel("File Error","Could not create file:  %s\nin:  %s\nfor some reason.",
			    "OK",NULL,NULL,dbFile,dbDirectory);
	    /*  RESTORE ORIGINAL SUFFIX  */
	    [savePanel setRequiredFileType:SUFFIX];
	    return(-1);
	}
	/*  RESTORE ORIGINAL SUFFIX  */
	[savePanel setRequiredFileType:SUFFIX];
	return(0);
    }

    /*  RESTORE ORIGINAL SUFFIX  */
    [savePanel setRequiredFileType:SUFFIX];
    return(-1);

}



- setTitles
{
    [template setTitleBar:currentPath];
    [phones setTitleBar:currentPath];
    [rule setTitleBar:currentPath];
    [generate setTitleBar:currentPath];
    [synthesize setTitleBar:currentPath];

    return self;
}


- (char *)currentPath
{
    return ((char *)currentPath);
}



- (char *)dbPath
{
    return ((char *)dbPath);
}

@end

