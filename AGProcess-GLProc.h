//
//  AGProcess_GLProc.h
//  GameLauncher
//
//  Created by Adam on 19/08/05.
//  Copyright 2005 2Sublime.com. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#include <Carbon/Carbon.h>
#import <ApplicationServices/ApplicationServices.h>
#import <2STools/AGProcess.h>
#import <CPS.h>

@interface AGProcess (GLProc)
- (BOOL)isRunning;
- (BOOL)moveToFrontProcess;
- (BOOL)quitGracefully;
- (BOOL)isEqual:(AGProcess *)proc;

@end


//taken from killeveryonebutme.h

#ifdef __cplusplus
extern "C" {
#endif
	
	//****************************************************
#pragma mark -
#pragma mark * typedef's, struct's, enums, defines, etc. *
	
	//****************************************************
#pragma mark -
#pragma mark * exported function prototypes *
	
OSStatus SendQuitAppleEventToApplication(ProcessSerialNumber ProcessToQuit);
	
#ifdef __cplusplus
}
#endif
