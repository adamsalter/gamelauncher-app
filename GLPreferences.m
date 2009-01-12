//
//  GLPreferences.m
//  GameLauncher
//
//  Created by Adam on 22/06/05.
//  Copyright 2005 2Sublime.com. All rights reserved.
//

#import "GLPreferences.h"


@implementation GLPreferences

#pragma mark Initialisation/Accessor Methods
static GLPreferences *sharedInstance = nil;
+ (GLPreferences *)sharedInstance
{
    return sharedInstance ? sharedInstance : [[self alloc] init];
}

- (id)init 
{
    if (sharedInstance) {
        [self dealloc];
    } else {
        sharedInstance = [super init];
    }
    
    return sharedInstance;
}

- (void)awakeFromNib
{
#ifdef __DEBUG__
	//check version
	NSDictionary *infoDict = [[NSBundle mainBundle] infoDictionary];
	if ([[infoDict valueForKey:@"CFBundleVersion"] intValue] < 1.5)
		NSLog(@"%@: Version:%@", [self class], [infoDict valueForKey:@"CFBundleVersion"]);
#endif
	//update defaults if this is first run
	NSMutableDictionary *initDefaults = [NSMutableDictionary dictionary];
	[initDefaults setValue:[NSNumber numberWithFloat:GLInitSpeed]
					forKey:GLSpeedKey];
	[initDefaults setValue:[NSNumber numberWithInt:GLInitOnTopState]
					forKey:GLAlwaysOnTopKey];
	[[NSUserDefaults standardUserDefaults] registerDefaults:initDefaults];

	[self initGUI];
}

- (void)initGUI
{
	//set computer speed slider
	computerSpeed = [[NSUserDefaults standardUserDefaults] floatForKey:GLSpeedKey];
	if ((computerSpeed < GLMinSpeed) || (computerSpeed > GLMaxSpeed)) {
		computerSpeed = GLInitSpeed;
	}
	[speedSlider setFloatValue:computerSpeed];
	//set alwaysontop checkbox
	alwaysOnTopDuringLaunch = [[[NSUserDefaults standardUserDefaults] stringForKey:GLAlwaysOnTopKey] intValue];
	[alwaysOnTopCheck setState:alwaysOnTopDuringLaunch];
	
	[self loadAboutBox];
}

- (IBAction)showAboutTab:(id)sender
{
    // Show the window
	[prefWin setTitle:NSLocalizedStringFromTable(@"GLAboutWinTitle", GLLocalizablePlist, @"GLAboutWinTitle")];
	[tabView selectTabViewItemAtIndex:0];
    [[tabView window] makeKeyAndOrderFront:nil];
}

- (IBAction)showOptionsTab:(id)sender
{
    // Show the window
	[prefWin setTitle:NSLocalizedStringFromTable(@"GLPrefsWinTitle", GLLocalizablePlist, @"GLPrefsWinTitle")];
	[tabView selectTabViewItemAtIndex:1];
    [[tabView window] makeKeyAndOrderFront:nil];
}

- (IBAction)showLicenceTab:(id)sender
{
    // Show the window
	[prefWin setTitle:NSLocalizedStringFromTable(@"GLLicenseWinTitle", GLLocalizablePlist, @"GLLicenseWinTitle")];
	[tabView selectTabViewItemAtIndex:2];
    [[tabView window] makeKeyAndOrderFront:nil];
}

- (void)loadAboutBox
{
	if (appNameField)
    {
        NSWindow *theWindow;
        NSString *creditsPath;
        NSAttributedString *creditsString;
        NSString *appName;
        NSString *versionString;
        NSString *copyrightString;
        NSDictionary *infoDictionary;
        CFBundleRef localInfoBundle;
        NSDictionary *localInfoDict;
		theWindow = [appNameField window];
        
        // Get the info dictionary (Info.plist)
        infoDictionary = [[NSBundle mainBundle] infoDictionary];
		// Get the localized info dictionary (InfoPlist.strings)
        localInfoBundle = CFBundleGetMainBundle();
        localInfoDict = (NSDictionary *)CFBundleGetLocalInfoDictionary( localInfoBundle );
		// Setup the app name field
        appName = [localInfoDict objectForKey:@"CFBundleName"];
        [appNameField setStringValue:appName];
        
        // Setup the version field
        versionString = [infoDictionary objectForKey:@"CFBundleVersion"];
        [versionField setStringValue:[NSString stringWithFormat:@"Version %@", 
			versionString]];
		// Setup our credits
        creditsPath = [[NSBundle mainBundle] pathForResource:@"Credits" 
													  ofType:@"rtf"];
		
        creditsString = [[NSAttributedString alloc] initWithPath:creditsPath 
											  documentAttributes:nil];
        
        [creditsField replaceCharactersInRange:NSMakeRange( 0, 0 ) 
									   withRTF:[creditsString RTFFromRange:
										   NSMakeRange( 0, [creditsString length] ) 
														documentAttributes:nil]];
		
		//Setup buy professional info
		creditsPath = [[NSBundle mainBundle] pathForResource:@"Buy-Pro" 
													  ofType:@"rtf"];
		
        creditsString = [[NSAttributedString alloc] initWithPath:creditsPath 
											  documentAttributes:nil];
        
        [buyproField replaceCharactersInRange:NSMakeRange( 0, 0 ) 
									   withRTF:[creditsString RTFFromRange:
										   NSMakeRange( 0, [creditsString length] ) 
														documentAttributes:nil]];
		
		[creditsString release];
		// Setup the copyright field
        copyrightString = [localInfoDict objectForKey:@"NSHumanReadableCopyright"];
        [copyrightField setStringValue:copyrightString];
        
        // Prepare some scroll info
		NSLayoutManager *layoutManager = [creditsField layoutManager];
		NSTextContainer *textContainer = [creditsField textContainer];
		(void) [layoutManager glyphRangeForTextContainer:textContainer];
		maxScrollHeight = [layoutManager usedRectForTextContainer:textContainer].size.height;
		maxScrollHeight -= [creditsField visibleRect].size.height;
		//NSLog(@"%f", maxScrollHeight);
        
		currentPosition = -1.0;
		pauseAboutScroll = NO;
    }
}

- (void)scrollCredits:(NSTimer *)timer
{
    if ([NSDate timeIntervalSinceReferenceDate] >= startTime) {
        if (currentPosition > maxScrollHeight) {
            returnToTop = YES;
            startTime = [NSDate timeIntervalSinceReferenceDate] + 6.0;
			currentPosition = maxScrollHeight;
        } else if (currentPosition < 0.0) {
            returnToTop = NO;
            // Reset the startTime
            startTime = [NSDate timeIntervalSinceReferenceDate] + 6.0;
			currentPosition = 0.0;
        } else {
            // Increment the scroll position
			if (returnToTop) {
				currentPosition -= 20;
			} else {
				currentPosition += 1.5;
			}
        }
		[creditsField scrollPoint:NSMakePoint( 0, currentPosition )];
    }
}

#pragma mark Window Delegate Methods
- (void)windowDidBecomeKey:(NSNotification *)notification
{
	if (pauseAboutScroll)
		return;
	double timerInterval = 0.05;
    scrollTimer = [NSTimer scheduledTimerWithTimeInterval:timerInterval 
												   target:self 
												 selector:@selector(scrollCredits:) 
												 userInfo:nil 
												  repeats:YES];
}

- (void)windowDidResignKey:(NSNotification *)notification
{
	if (scrollTimer) {
		[scrollTimer invalidate];
		scrollTimer = nil;
	}
}

- (IBAction)pauseAboutScroll:(id)sender
{
	if ([sender state] == NSOnState){
		pauseAboutScroll = YES;
		[scrollTimer invalidate];
		scrollTimer = nil;
	} else {
		pauseAboutScroll = NO;
		double timerInterval = 0.05;
		scrollTimer = [NSTimer scheduledTimerWithTimeInterval:timerInterval 
													   target:self 
													 selector:@selector(scrollCredits:) 
													 userInfo:nil 
													  repeats:YES];
	}
}

#pragma mark Computer Speed Options
- (IBAction)setComputerSpeed:(id)sender
{
	computerSpeed = [sender floatValue];
	//set defaults
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSNumber *temp = [NSNumber numberWithFloat:computerSpeed];
	[defaults setObject:temp forKey:@"GLComputerSpeed"];
}

- (float)computerSpeed
{
	return computerSpeed;
}

- (IBAction)setAlwaysOnTopDuringLaunch:(id)sender
{
	alwaysOnTopDuringLaunch = [sender state];
	//set defaults
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSNumber *temp = [NSNumber numberWithInt:alwaysOnTopDuringLaunch];
	[defaults setObject:temp forKey:@"GLAlwaysOnTopDuringLaunch"];
}

- (BOOL)alwaysOnTopDuringLaunch
{
	return alwaysOnTopDuringLaunch;
}

#pragma mark NSTabView Delegate

@end
