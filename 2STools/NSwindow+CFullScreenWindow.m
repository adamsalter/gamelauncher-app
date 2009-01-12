//
//  CFullScreenWindow.m
//  SequenceGrabber
//
//  Created by Jonathan Wight on 10/20/2004.
//  Copyright 2004 Toxic Software. All rights reserved.
//

#import "NSWindow+CFullScreenWindow.h"

#import <ApplicationServices/ApplicationServices.h>
#import <Carbon/Carbon.h>

@implementation NSWindow (CFullScreenWindow)

//note these will not be released : BAD
static CFDictionaryRef savedScreenMode;
static SystemUIMode savedUIMode;
static SystemUIOptions savedUIOptions;
static NSSize preferredScreenSize;
static BOOL shouldChangeScreen = NO;
static BOOL shouldHideSystemUI = YES;

static SEL selector;
static id sender;


- (id)initWithFSContentRect:(NSRect)contentRect styleMask:(unsigned int)aStyle backing:(NSBackingStoreType)bufferingType defer:(BOOL)flag
{
if ((self = [self initWithContentRect:contentRect styleMask:NSBorderlessWindowMask backing:bufferingType defer:flag]) != NULL)
	{
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidChangeScreenParametersNotificationHandler:) name:NSApplicationDidChangeScreenParametersNotification object:[NSApplication sharedApplication]]; 

	[self setPreferredScreenSize:[self frame].size];

	[self setShouldChangeScreen:YES];
	[self setShouldHideSystemUI:YES];

	[self setBackgroundColor:[NSColor whiteColor]];
	[self setAlphaValue:1.0f];
	[self setOpaque:YES];
	[self setHasShadow:NO];
	}
return(self);
}

#pragma mark -

- (void)makeFSKeyAndOrderFront:(id)inSender
{
[self hideSystemUI];
//
if ([self shouldChangeScreen] == YES && selector == NULL)
	{
	selector = @selector(makeKeyAndOrderFront:);
	[sender release];
	sender = [inSender retain];
	[self changeScreen];
	}
else
	{
	[self makeKeyAndOrderFront:inSender];
	}
}

- (void)orderFrontFS:(id)inSender
{
[self hideSystemUI];
//
if ([self shouldChangeScreen] == YES && selector == NULL)
	{
	selector = @selector(orderFront:);
	[sender release];
	sender = [inSender retain];
	[self changeScreen];
	}
else
	{
	[self orderFront:inSender];
	}
}

- (void)orderOutFS:(id)inSender
{
[self revertSystemUI];
//
if ([self shouldChangeScreen] == YES && selector == NULL)
	{
	selector = @selector(orderOut:);
	[sender release];
	sender = [inSender retain];
	[self revertScreen];
	}
else
	{
	[self orderOut:inSender];
	}
}

- (BOOL)canBecomeKeyWindow
{
	return(YES);
}

#pragma mark -

- (NSSize)preferredScreenSize
{
return(preferredScreenSize);
}

- (void)setPreferredScreenSize:(NSSize)inPreferredScreenSize
{
preferredScreenSize = inPreferredScreenSize;
}

- (BOOL)shouldChangeScreen
{
return(shouldChangeScreen);
}

- (void)setShouldChangeScreen:(BOOL)inShouldChangeScreen
{
shouldChangeScreen = inShouldChangeScreen;
}

- (BOOL)shouldHideSystemUI
{
return(shouldHideSystemUI);
}

- (void)setShouldHideSystemUI:(BOOL)inShouldHideSystemUI
{
shouldHideSystemUI = inShouldHideSystemUI;
}

#pragma mark -

- (void)hideSystemUI
{
if ([self shouldHideSystemUI] == YES)
	{
	OSStatus theStatus = noErr;
	// ### Save current UI settings...
	GetSystemUIMode(&savedUIMode, &savedUIOptions);
	// ### Change UI settings...
	/*theStatus = SetSystemUIMode(kUIModeAllHidden, kUIOptionDisableAppleMenu | kUIOptionDisableProcessSwitch | kUIOptionDisableForceQuit | kUIOptionDisableSessionTerminate | kUIOptionDisableHide);*/
	theStatus = SetSystemUIMode(kUIModeContentSuppressed, 0);
	if (theStatus != noErr)
		[NSException raise:NSGenericException format:@"SetSystemUIMode() failed (%d).", theStatus];
	}
}

- (void)revertSystemUI
{
OSStatus theStatus = noErr;
theStatus = SetSystemUIMode(savedUIMode, savedUIOptions);
if (theStatus != noErr)
	[NSException raise:NSGenericException format:@"SetSystemUIMode() failed (%d).", theStatus];
}

#pragma mark -

- (void)changeScreen
{
if ([self shouldChangeScreen] == YES)
	{
	savedScreenMode = CGDisplayCurrentMode(kCGDirectMainDisplay);
	if (savedScreenMode == NULL)
		[NSException raise:NSGenericException format:@"CGDisplayCurrentMode() failed."];

	const NSSize theSize = [self preferredScreenSize];

	boolean_t theExactMatchFlag = NO;
	CFDictionaryRef theBestMode = CGDisplayBestModeForParameters(kCGDirectMainDisplay, 32, theSize.width, theSize.height, &theExactMatchFlag);
	if (theBestMode == NULL)
		[NSException raise:NSGenericException format:@"CGDisplayBestModeForParameters() failed."];

	OSStatus theStatus = CGDisplaySwitchToMode(kCGDirectMainDisplay, theBestMode); 
	if (theStatus != noErr)
		[NSException raise:NSGenericException format:@"CGDisplaySwitchToMode() failed (%d).", theStatus];
	}
}

- (void)revertScreen
{
OSStatus theStatus = CGDisplayCapture(kCGDirectMainDisplay);
if (theStatus != noErr)
	[NSException raise:NSGenericException format:@"CGDisplayCapture() failed (%d).", theStatus];
theStatus = CGDisplaySwitchToMode(kCGDirectMainDisplay, savedScreenMode); 
if (theStatus != noErr)
	[NSException raise:NSGenericException format:@"CGDisplaySwitchToMode() failed (%d).", theStatus];
CFRelease(savedScreenMode);	
savedScreenMode = NULL;
	
	
theStatus = CGDisplayRelease(kCGDirectMainDisplay);
if (theStatus != noErr)
	[NSException raise:NSGenericException format:@"CGDisplayRelease() failed (%d).", theStatus];
}

#pragma mark -

- (void)applicationDidChangeScreenParametersNotificationHandler:(NSNotification *)inNotification
{
if ([self shouldChangeScreen] == YES && selector != NULL)
	{
	[self setFrame:[[self screen] frame] display:YES];
	//
	[self performSelector:selector withObject:sender];
	selector = NULL;
	[sender release];
	sender = NULL;
	}
}

@end
