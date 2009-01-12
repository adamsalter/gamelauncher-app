//
//  GLLauncherController.h
//  GameLauncher
//
//  Created by Adam on 25/05/05.
//  Copyright 2005 2Sublime.com. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <GLProcess.h>
#import <GLPreferences.h>
#import <GLLauncherController.h>
#import <GLNagController.h>
#import <2STools/InterThreadMessaging.h>
#import <2STools/IconFamily.h>
#import <2STools/NSWindow+CFullScreenWindow.h>
#import <2STools/UKCrashReporter.h>


@interface GLGUIController : NSObject
{
	IBOutlet NSWindow *mainWindow;
  IBOutlet NSTableView *applicationListView;
  IBOutlet NSImageView *imageWell;
	IBOutlet NSButton *quitAllAndLaunchButton;
	IBOutlet NSMenuItem *launchMenuItem;
	IBOutlet NSMenuItem *browseMenuItem;
	IBOutlet NSMenuItem *quitCurrentAppMenuItem;
	IBOutlet NSButton *browseButton;
	IBOutlet NSButton *toggleAllButton;
	IBOutlet NSTextField *launchAppName;
	IBOutlet NSProgressIndicator *progressIndicator;
	@protected
		NSUserDefaults *defaults;
		NSString *launchAppPath;
		NSMutableArray *applicationList;
		NSMutableDictionary *selectedApplications;
		NSMutableDictionary *selectedApplicationsDefaultsDict;
		NSThread *mainThread;
		NSTimer *refreshTimer, *progressTimer;
		BOOL isMini;
		BOOL quitRequested;
		BOOL processEnabledToggle;
}

+ (GLGUIController *)sharedInstance;

- (void)initGUI;
- (void)updateProcessToggleGUI;
- (void)updateMainWindowZoomGUI;
- (void)updateProcessTableGUI;
- (void)updateProgressIndicatorGUI;

- (NSWindow *)mainWindow;
- (NSThread *)mainThread;
- (NSArray *)applicationList;
- (NSString *)launchAppPath;
- (void)setLaunchAppPath:(NSString *)path;
- (BOOL)isMini;

- (NSRect)mainWindowFrame;
- (void)addToRecentDocs:(NSURL *)newURL;

- (IBAction)browseForApp:(id)sender;
- (IBAction)quitAllAndLaunch:(id)sender;
- (IBAction)quitSelectedApp:(id)sender;
- (IBAction)buyProfessionalLink:(id)sender;
- (IBAction)advertiseLink:(id)sender;
- (IBAction)toggleAllProcesses:(id)sender;

@end

@interface NSWindow (roundedBottom)

- setBottomCornerRounded:(BOOL)roundBottom;

@end
