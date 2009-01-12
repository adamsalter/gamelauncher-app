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


enum GLLaunchQueryState {
	kStateUndefined		=	-1,
	kContinueWaiting	=	0,
	kSkipApplication	=	1,
	kKillApplication	=	2,
	kCancelLaunch		=	3
};

typedef int GLLaunchQueryState;

@interface GLLauncherController : NSObject {
	@public
		IBOutlet NSWindow *slowLaunchSheet;
		IBOutlet NSImageView *slowLaunchSheetIcon;
		IBOutlet NSTextField *slowLaunchSheetApplicationName;
		IBOutlet NSMatrix *radioList;
	@protected
		BOOL isLaunching;
		BOOL didLaunch;
		NSTask *launchTask;
		NSThread *myThread, *mainThread;
		float speedDelta;
		NSString *launchNotificationPath;
		GLLaunchQueryState longLaunchAnswer;
		double launchProgress;
}
//note: sigleton class
+ (GLLauncherController *)sharedInstance;
- (void)startRunLoop:(NSThread *)sender;
- (BOOL)isLaunching;
- (NSThread *)myThread;
- (void)doQuitAllAndLaunch;
- (double)launchProgress;
- (void)cancelLaunch;
- (NSArray *)quitAllSelectedApplications:(NSArray *)quitList;
- (GLLaunchQueryState)quitProcess:(GLProcess *)process;
- (void)waitUntilExitAppWithPath:(NSString *)path;
- (void)relaunchProcess:(GLProcess *)process args:(NSArray *)args;
- (NSTask *)launchTaskWithPath:(NSString *)path args:(NSArray *)args;
- (void)relaunchAllSelectedApplications:(NSArray *)launchList;
- (IBAction)cancelLaunch:(id)sender;
- (IBAction)continueWaiting:(id)sender;
@end

