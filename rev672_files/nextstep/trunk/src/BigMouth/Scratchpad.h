#import <appkit/Application.h>

@interface Scratchpad:Object
{
    id	mySpeaker;
    id  scratchpadWindow;
    id  speakFileButton;
    id  toFileButton;

    id  scratchpad;
    id  textObject;
    id  savePanel;

    int mode;

    char *textBuffer;
    NXStream *fileStream;
    char *filename;
    BOOL toFile;
}

- awakeFromNib;
- free;

- warnUser;

- speakAll:sender;
- speakSelection:sender;
- speakFileOnPasteboard:pasteboard;
- speakFile:sender;

- toFileButtonPushed:sender;

- repeat;

@end
