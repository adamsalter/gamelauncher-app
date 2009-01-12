//
//  GLPreferences.h
//  GameLauncher
//
//  Created by Adam on 22/06/05.
//  Copyright 2005 2Sublime.com. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <GLGUIController.h>


@interface GLPreferences : NSObject {
	IBOutlet NSWindow *prefWin;
	IBOutlet NSTabView *tabView;
	//Speed
	IBOutlet NSSlider *speedSlider;
	float computerSpeed;
	//AlwaysOnTop
	IBOutlet NSButton *alwaysOnTopCheck;
	int alwaysOnTopDuringLaunch;
	//About box
    IBOutlet id appNameField;
    IBOutlet id copyrightField;
    IBOutlet id creditsField;
    IBOutlet id versionField;
    IBOutlet id buyproField;
	//about box scroll
    NSTimer *scrollTimer;
    float currentPosition;
    float maxScrollHeight;
    NSTimeInterval startTime;
    BOOL returnToTop;
	BOOL pauseAboutScroll;
}
+ (GLPreferences *)sharedInstance;
- (void)initGUI;
- (void)loadAboutBox;
- (IBAction)showAboutTab:(id)sender;
- (IBAction)pauseAboutScroll:(id)sender;
- (IBAction)showOptionsTab:(id)sender;
- (IBAction)showLicenceTab:(id)sender;
- (IBAction)setComputerSpeed:(id)sender;
- (float)computerSpeed;
- (IBAction)setAlwaysOnTopDuringLaunch:(id)sender;
- (BOOL)alwaysOnTopDuringLaunch;
@end
