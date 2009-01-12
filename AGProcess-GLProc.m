//
//  AGProcess_GLProc.m
//  GameLauncher
//
//  Created by Adam on 19/08/05.
//  Copyright 2005 2Sublime.com. All rights reserved.
//

#import "AGProcess-GLProc.h"


@implementation AGProcess (GLProc)

- (BOOL)isRunning
{
	if ([self state] != AGProcessStateExited) {
		return YES;
	}
	return NO;
}

- (BOOL)moveToFrontProcess
{
	CPSProcessSerNum CPSpsn = {
        kNoProcess, kNoProcess
    };
	ProcessSerialNumber psn;
	pid_t pid = process;
	OSStatus err = GetProcessForPID(pid , &psn);
	CPSpsn.lo = psn.highLongOfPSN;
	CPSpsn.hi = psn.lowLongOfPSN;
	
	err = CPSPostShowReq(&CPSpsn) || CPSSetFrontProcess(&CPSpsn);
	if (err != noErr) {
		NSLog(@"%@: Can't move process to front", command);
		return NO;
	}
	return YES;
}

- (BOOL)quitGracefully
{
	ProcessSerialNumber psn;
	pid_t pid = process;
	OSStatus err = GetProcessForPID(pid , &psn);
	err = SendQuitAppleEventToApplication(psn);
	if (err != noErr) {
		NSLog(@"%@: AEQuit event failed", command);
		return NO;
	}
	return YES;
}

- (BOOL)isEqual:(AGProcess *)proc
{
	return (process == [proc processIdentifier]);
}

@end


/*****************************************************
* **** taken from Apple Killeveryonebutme sample code *****
*
* SendQuitAppleEventToApplication(ProcessToQuit) 
*
* Purpose:  called to send a 'quit' AppleEvent to the process passed as parameter
*
* Inputs:   none
*
* Returns:  OSStatus			- error code (0 == no error) 
*/
OSStatus SendQuitAppleEventToApplication(ProcessSerialNumber ProcessToQuit)
{
    OSStatus status;
    AEDesc targetProcess = {typeNull, NULL};
    AppleEvent theEvent = {typeNull, NULL};
    AppleEvent eventReply = {typeNull, NULL}; 
	
    status = AECreateDesc(typeProcessSerialNumber, &ProcessToQuit, sizeof(ProcessToQuit), &targetProcess);
	require_noerr(status, AECreateDesc);
    
    status = AECreateAppleEvent(kCoreEventClass, kAEQuitApplication, &targetProcess, kAutoGenerateReturnID, kAnyTransactionID, &theEvent);
	require_noerr(status, AECreateAppleEvent);
    
    status = AESend(&theEvent, &eventReply, kAENoReply + kAEAlwaysInteract, kAENormalPriority, kAEDefaultTimeout, NULL, NULL);
	require_noerr(status, AESend);
    
AESend:
AECreateAppleEvent:
AECreateDesc:
		
		AEDisposeDesc(&eventReply); 
    AEDisposeDesc(&theEvent);
	AEDisposeDesc(&targetProcess);
	
    return(status);
}   // SendQuitAppleEventToApplication

