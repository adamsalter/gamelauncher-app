//
//  GLNagController.h
//  GameLauncher
//
//  Created by Adam on 6/06/05.
//  Copyright 2005 2Sublime.com. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <WebKit/WebKit.h>
#import <GLLauncherController.h>
#import <GLGUIController.h>

@interface GLNagController : NSObject {
	IBOutlet NSWindow *nagWindow;
	IBOutlet WebView *nagView;
	IBOutlet NSTextField *nagStatusText;
	BOOL nagScreenShowing;
	NSWindow *mainWindow;
	NSTimer *nagTimer;
}
+ (GLNagController *)sharedInstance;
- (IBAction)showNagScreen:(id)sender;
- (void)setNextNagTimer;
- (IBAction)nagOKPressed:(id)sender;
@end
