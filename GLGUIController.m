//
//  GLLauncherController.h
//  GameLauncher
//
//  Created by Adam on 25/05/05.
//  Copyright 2005 2Sublime.com. All rights reserved.
//

#import "GLGUIController.h"

@implementation GLGUIController

static BOOL alwaysOnTop;
static BOOL	shouldMini;

#pragma mark Initialisation/Accessors
static GLGUIController *sharedInstance = nil;
+ (GLGUIController *)sharedInstance
{
    return sharedInstance ? sharedInstance : [[self alloc] init];
}

- (void)awakeFromNib
{
}

- (id)init 
{
    if (sharedInstance) {
        [self dealloc];
    } else {
        sharedInstance = [super init];
		//threads
		[NSThread prepareForInterThreadMessages];
		mainThread = [NSThread currentThread];
		[NSThread detachNewThreadSelector:@selector(startRunLoop:)
								 toTarget:[GLLauncherController sharedInstance]
							   withObject:mainThread];
		//defaults
		defaults = [NSUserDefaults standardUserDefaults];
		//applistview
		applicationList = [NSMutableArray new];
		//notifications
		[[NSNotificationCenter defaultCenter] 
				addObserver:self
				selector:@selector(startProcessTableTimerNotification:)
				name:GLStartProcessTableTimerNotification
				object:nil];
		[[NSNotificationCenter defaultCenter] 
				addObserver:self
				   selector:@selector(stopProcessTableTimerNotification:)
					   name:GLStopProcessTableTimerNotification
					 object:nil];
		[[NSNotificationCenter defaultCenter] 
				addObserver:self
				   selector:@selector(reloadProcessTableNotification:)
					   name:GLReloadProcessTableNotification
					 object:nil];
		[[NSNotificationCenter defaultCenter] 
				addObserver:self
				   selector:@selector(startProgressIndTimerNotification:)
					   name:GLStartProgressTimerNotification
					 object:nil];
		[[NSNotificationCenter defaultCenter] 
				addObserver:self
				   selector:@selector(stopProgressIndTimerNotification:)
					   name:GLStopProgressTimerNotification
					 object:nil];
		[[NSNotificationCenter defaultCenter] 
				addObserver:self
				   selector:@selector(hideSystemUINotification:)
					   name:GLHideSystemUINotification
					 object:nil];
		[[NSNotificationCenter defaultCenter] 
				addObserver:self
				   selector:@selector(revertSystemUINotification:)
					   name:GLRevertSystemUINotification
					 object:nil];
		[[NSNotificationCenter defaultCenter] 
				addObserver:self
				   selector:@selector(launcherBeginQuitAllNotification:)
					   name:GLBeginQuitAllNotification
					 object:nil];
		[[NSNotificationCenter defaultCenter] 
				addObserver:self
				   selector:@selector(launcherWillLaunchNotification:)
					   name:GLWillLaunchNotification
					 object:nil];
		[[NSNotificationCenter defaultCenter] 
				addObserver:self
				   selector:@selector(launcherBeginRelaunchAllNotification:)
					   name:GLBeginRelaunchAllNotification
					 object:nil];
		[[NSNotificationCenter defaultCenter] 
				addObserver:self
				   selector:@selector(launcherDidFinishLaunchingNotification:)
					   name:GLDidFinishLaunchingNotification
					 object:nil];
    }
    return sharedInstance;
}

- (void) dealloc
{
	[applicationList release];
	[super dealloc];
}

- (void)applicationDidFinishLaunching:(NSNotification *)notification
{
	//check for last crash
	UKCrashReporterCheckForCrash();
	//set main window position
	BOOL quitSuccess = [defaults boolForKey:GLQuitSuccessKey];
	if (!quitSuccess) {
		[mainWindow center];
		[defaults setObject:[NSNumber numberWithBool:NO] forKey:GLQuitSuccessKey];
	}
	//update defaults if this is first run
	NSMutableDictionary *initDefaults = [NSMutableDictionary dictionary];
	[initDefaults setValue:[NSNumber numberWithBool:YES]
					forKey:GLAppFirstRunKey];
	[initDefaults setValue:[NSNumber numberWithBool:YES]
					forKey:GLProcessEnabledToggleKey];
	[initDefaults setObject:[NSMutableDictionary dictionary]
					 forKey:GLSelectedApplicationsListKey];
	[initDefaults setObject:GLInitLaunchAppPath
					 forKey:GLLaunchAppPathKey];
	[initDefaults setObject:NSStringFromRect([mainWindow frame]) forKey:GLMaxiWindowSizeKey];
	NSRect miniFrame;
	miniFrame.size = [mainWindow minSize];
	miniFrame.origin.x = [mainWindow frame].origin.x;
	miniFrame.origin.y = [mainWindow frame].origin.y +
		[mainWindow frame].size.height -
		[mainWindow minSize].height;
	[initDefaults setObject:NSStringFromRect(miniFrame) forKey:GLMiniWindowSizeKey];
	[[NSUserDefaults standardUserDefaults] registerDefaults:initDefaults];
	
	[self initGUI];
}

- (void)initGUI
{
	//reload application selected
	[self setLaunchAppPath:[defaults stringForKey:GLLaunchAppPathKey]];
	//process enabled toggle
	processEnabledToggle = [defaults boolForKey:GLProcessEnabledToggleKey];
	[self updateProcessToggleGUI];
	//set tableview sorting
	NSData *data = [defaults dataForKey:GLTableSortDescriptorsKey];
	if (data) {
		[applicationListView setSortDescriptors:(NSArray *)[NSUnarchiver unarchiveObjectWithData:data]];
	}
	//load selected applictions
	selectedApplicationsDefaultsDict = [NSMutableDictionary dictionaryWithDictionary:[defaults objectForKey:GLSelectedApplicationsListKey]];
	[selectedApplicationsDefaultsDict retain];
	selectedApplications = [NSMutableDictionary dictionaryWithDictionary:[selectedApplicationsDefaultsDict objectForKey:[NSString stringWithFormat:@"%d", processEnabledToggle]]];
	[selectedApplications retain];
	//start table update timer
	[[NSNotificationCenter defaultCenter]
			postNotificationName:GLStartProcessTableTimerNotification object:self];
	//setup main window
	//set window title
	srandom(time(NULL));
	int i = (abs(random())%[NSLocalizedStringFromTable(@"GLAltWindowTitleNum", GLLocalizablePlist, @"GLAltWindowTitleNum") intValue])+1;
	NSString *quote = [NSString stringWithFormat:@"GLAltWindowTitle%d",i];
	NSString *windowTitle = @"\n";
	windowTitle = [windowTitle stringByAppendingFormat:@" %@", [NSString
			stringWithString:NSLocalizedStringFromTable(@"CFBundleName", @"InfoPlist", @"CFBundleName")]];
	windowTitle = [windowTitle stringByAppendingFormat:@" %@", [NSString
			stringWithString:NSLocalizedStringFromTable(quote, GLLocalizablePlist, @"GLAltWindowTitle")]];
	[mainWindow setTitle:windowTitle];
	//unround window
	if ([mainWindow respondsToSelector:@selector(setBottomCornerRounded:)])
		[mainWindow setBottomCornerRounded:NO];
	//	[mainWindow setFrame:NSRectFromString([defaults stringForKey:GLMaxiWindowSizeKey]) display:NO];
	// Now show the window... (By default we've set it in IB not to be visible at start)
	[mainWindow makeKeyAndOrderFront:nil];
	[mainWindow makeMainWindow];
	//kick off nag screen thread
	[NSBundle loadNibNamed:@"NagWebView" owner:self];
	if (![defaults boolForKey:GLAppFirstRunKey]) {
		[[GLNagController sharedInstance] setNextNagTimer];
	}
}

- (void)updateProcessToggleGUI
{
	[toggleAllButton setToolTip:@"Toggle selection state"];
	if (processEnabledToggle) {
		//set icon to minus
		[toggleAllButton setImage:[[NSImage alloc] initWithContentsOfFile:
			[[NSBundle mainBundle] pathForResource:@"bt-remove" ofType:@"png"]]];
		[toggleAllButton setAlternateImage:[[NSImage alloc] initWithContentsOfFile:
			[[NSBundle mainBundle] pathForResource:@"bt-remove_p" ofType:@"png"]]];
	} else {
		//set icon to tick
		[toggleAllButton setImage:[[NSImage alloc] initWithContentsOfFile:
			[[NSBundle mainBundle] pathForResource:@"bt-add" ofType:@"png"]]];
		[toggleAllButton setAlternateImage:[[NSImage alloc] initWithContentsOfFile:
			[[NSBundle mainBundle] pathForResource:@"bt-add_p" ofType:@"png"]]];
	}	
}

- (void)updateMainWindowZoomGUI
{
	if (!isMini) {
		[defaults setObject:NSStringFromRect([mainWindow frame]) forKey:GLMaxiWindowSizeKey];
	} else {
		[defaults setObject:NSStringFromRect([mainWindow frame]) forKey:GLMiniWindowSizeKey];
	}
	isMini = !isMini;
	[mainWindow setFrame:[self mainWindowFrame] display:YES animate:YES];
}

- (NSRect)mainWindowFrame
{
	NSRect newWinFrame;
	if (isMini) {
		newWinFrame = NSRectFromString([defaults stringForKey:GLMiniWindowSizeKey]);
		[quitCurrentAppMenuItem setEnabled:NO];
		[toggleAllButton setHidden:YES];
		[applicationListView setHidden:YES];
		[mainWindow setShowsResizeIndicator:NO];
		[[NSNotificationCenter defaultCenter]
			postNotificationName:GLStopProcessTableTimerNotification
						  object:self];
	} else {
		newWinFrame = NSRectFromString([defaults stringForKey:GLMaxiWindowSizeKey]);
		[quitCurrentAppMenuItem setEnabled:YES];
		[toggleAllButton setHidden:NO];
		[applicationListView setHidden:NO];
		[mainWindow setShowsResizeIndicator:YES];
		[[NSNotificationCenter defaultCenter]
			postNotificationName:GLStartProcessTableTimerNotification
						  object:self];
	}
	return newWinFrame;	
}

#pragma mark accessor methods
- (NSWindow *)mainWindow
{
	return mainWindow;
}

- (NSThread *)mainThread
{
	return mainThread;
}

- (GLPreferences *)preferences
{
	return [GLPreferences sharedInstance];
}

- (NSArray *)applicationList
{
	return [NSArray arrayWithArray:applicationList];
}

- (NSString *)launchAppPath
{
	return launchAppPath;
}

- (BOOL)isMini
{
	return isMini;
}

#pragma mark Action Methods
//browser button
- (IBAction)browseForApp:(id)sender
{
	NSOpenPanel *panel = [NSOpenPanel openPanel];
	
	if (![[GLLauncherController sharedInstance] isLaunching]) {
		[panel beginSheetForDirectory:nil
				file:nil
				types:[NSArray arrayWithObject:@"app"]
				modalForWindow:[browseButton window]
				modalDelegate:self
				didEndSelector:@selector(openPanelDidEnd:returnCode:contextInfo:)
				contextInfo:NULL];
	}
}

- (void)setLaunchAppPath:(NSString *)path
{
	if ((path != nil)&&
			([[NSFileManager defaultManager] fileExistsAtPath:path])){
		[path retain];
		[launchAppPath release];
		launchAppPath = path;
		[quitAllAndLaunchButton setEnabled:YES];
		[launchMenuItem setEnabled:YES];
		[imageWell setImage:[[NSWorkspace sharedWorkspace]
				iconForFile:path]];
		[launchAppName	setStringValue:[[launchAppPath lastPathComponent] stringByDeletingPathExtension]];
		[defaults setObject:path forKey:@"GLLaunchAppPath"];
		[self addToRecentDocs:[NSURL fileURLWithPath:path]];
} else {
		//application not found
		launchAppPath = nil;
		[quitAllAndLaunchButton setEnabled:NO];
		[launchMenuItem setEnabled:NO];
		NSImage *image = [NSImage imageNamed:@"GLQuestion.png"];
		[imageWell setImage:image];
		[launchAppName setStringValue:@""];
	}
}

- (void)addToRecentDocs:(NSURL *)newURL
{
	//maxdocs declared at top
	NSDocumentController *docController = [NSDocumentController sharedDocumentController];
	[docController noteNewRecentDocumentURL:newURL];	
	NSMutableArray *recentDocs = [NSMutableArray arrayWithArray:[docController recentDocumentURLs]];
	if ([recentDocs count] > GLMaxRecentDocs) {
		[recentDocs removeObjectAtIndex:GLMaxRecentDocs];
		[recentDocs insertObject:newURL atIndex:0];
		[docController clearRecentDocuments:self];
		NSEnumerator *enumerator = [recentDocs reverseObjectEnumerator];
		NSURL *docURL;
		while ((docURL = [enumerator nextObject])) {
			[docController noteNewRecentDocumentURL:docURL];	
		}
	}
}

//button pressed
- (IBAction)quitAllAndLaunch:(id)sender
{
	NSThread *launchThread = [[GLLauncherController sharedInstance] myThread];
	if ((![[GLLauncherController sharedInstance] isLaunching]) &&
			(launchAppPath != nil)) {
        [[GLLauncherController sharedInstance] performSelector:@selector(doQuitAllAndLaunch)
					 inThread:launchThread];
	} else {
		//cancel launch
		[quitAllAndLaunchButton setEnabled:NO];
		[launchMenuItem setEnabled:NO];
        [[GLLauncherController sharedInstance] cancelLaunch];
	}
}

- (IBAction)quitSelectedApp:(id)sender
{
	int selectedRow = [applicationListView selectedRow];
	NSThread *launchThread = [[GLLauncherController sharedInstance] myThread];
	if (selectedRow >= 0) {
		GLProcess *process = [applicationList objectAtIndex:selectedRow];
        [[GLLauncherController sharedInstance] performSelector:@selector(quitProcess:)
													withObject:process
													  inThread:launchThread];
	}
}

//menu item
- (void)showHelp:(id)sender
{
	NSString *filePath = [[NSBundle mainBundle] pathForResource:@"About GameLauncher" ofType:@"pdf"];
	[[NSWorkspace sharedWorkspace] openFile:filePath];
}

//menu item
- (IBAction)buyProfessionalLink:(id)sender
{
	NSString *buyproUrlText = NSLocalizedStringFromTable(GLBuyProUrlKey, GLLocalizablePlist, GLBuyProUrlKey);
	[[NSWorkspace sharedWorkspace]
			openURL:[NSURL URLWithString:buyproUrlText]];
}

//menu item
- (IBAction)advertiseLink:(id)sender
{
	NSString *advertiseUrlText = NSLocalizedStringFromTable(GLAdvertiseUrlKey, GLLocalizablePlist, GLAdvertiseUrlKey);
	[[NSWorkspace sharedWorkspace]
			openURL:[NSURL URLWithString:advertiseUrlText]];
}

//menu item
- (IBAction)toggleAllProcesses:(id)sender
{
	[selectedApplicationsDefaultsDict setObject:selectedApplications
								 forKey:[NSString stringWithFormat:@"%d", processEnabledToggle]];
	processEnabledToggle = !processEnabledToggle;
	[self updateProcessToggleGUI];
	if (processEnabledToggle == NO) {
		[selectedApplications release];
		selectedApplications = [[NSMutableDictionary dictionary] retain];
		[selectedApplicationsDefaultsDict setObject:selectedApplications
											 forKey:[NSString stringWithFormat:@"%d", processEnabledToggle]];
	} else {
		[selectedApplications release];
		selectedApplications = [[defaults objectForKey:GLSelectedApplicationsListKey]
								objectForKey:[NSString stringWithFormat:@"%d", processEnabledToggle]];
		selectedApplications = [NSMutableDictionary dictionaryWithDictionary:selectedApplications];
		[selectedApplications retain];
	}
	[defaults setObject:selectedApplicationsDefaultsDict forKey:GLSelectedApplicationsListKey];
	[defaults setObject:[NSNumber numberWithBool:processEnabledToggle] forKey:GLProcessEnabledToggleKey];
	NSArray *enumArray = [NSArray arrayWithArray:applicationList];
	NSEnumerator *enumerator = [enumArray objectEnumerator];
	GLProcess *process;
	while ((process = [enumerator nextObject])) {
		if ([selectedApplications valueForKey:[process command]]) {
			[process setEnabled:!processEnabledToggle];				
		} else {
			[process setEnabled:processEnabledToggle];
		}
	}
	[applicationListView reloadData];
}


#pragma mark reloadProcessTable
- (void)updateProcessTableGUI
{
	NSMutableArray *newApplicationList = [NSMutableArray 
			arrayWithArray:[GLProcess allUserApplications]];
	NSMutableArray *enumArray = [NSMutableArray arrayWithArray:applicationList];
	NSEnumerator *enumerator = [enumArray objectEnumerator];
	GLProcess *process;
	BOOL processTableChanged = NO;
	while ((process = [enumerator nextObject])) {
		int procIndex = [newApplicationList indexOfObject:process];
		if (procIndex == NSNotFound) {
			[applicationList removeObject:process];
			processTableChanged = YES;
		} else {
			[newApplicationList removeObjectAtIndex:procIndex];
		}
	}
	if ([newApplicationList count]) {
		enumerator = [newApplicationList objectEnumerator];
		while ((process = [enumerator nextObject])) {
			if ([selectedApplications valueForKey:[process command]]) {
				[process setEnabled:!processEnabledToggle];				
			} else {
				[process setEnabled:processEnabledToggle];
			}
		}
		[applicationList addObjectsFromArray:newApplicationList];
		processTableChanged = YES;
	}
	if (processTableChanged) {
		[applicationList sortUsingDescriptors:[applicationListView sortDescriptors]];
		[applicationListView reloadData];
		[applicationListView setNeedsDisplay:YES];
	}
}

- (void)updateProgressIndicatorGUI
{
	[progressIndicator setDoubleValue:[[GLLauncherController sharedInstance] launchProgress]];
}

#pragma mark OpenPanel delegate
- (void)openPanelDidEnd:(NSOpenPanel *)openPanel
			 returnCode:(int)returnCode
			contextInfo:(void *)x
{
	if (returnCode == NSOKButton) {
		[self setLaunchAppPath:[openPanel filename]];
	}
}

#pragma mark Application Delegate Methods
- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender
{
	if ([[GLLauncherController sharedInstance] isLaunching]) {
		//show alert and ask if ok to quit
		NSAlert *quitAlert = [[NSAlert alloc] init];
		[quitAlert setMessageText:NSLocalizedStringFromTable(GLShouldQuitTitle, GLLocalizablePlist, GLShouldQuitTitle)];
		NSString *infText = NSLocalizedStringFromTable(GLShouldQuitMsg, GLLocalizablePlist, GLShouldQuitMsg);
		NSString *newLine = [NSString stringWithFormat: @"%C", NSLineSeparatorCharacter];
		AGRegex *regex = [AGRegex regexWithPattern:@"\\\\n"];
		NSString *match = [regex replaceWithString:newLine inString:infText]; 
		[quitAlert setInformativeText:match];
		[quitAlert addButtonWithTitle:NSLocalizedStringFromTable(GLShouldQuitBut1, GLLocalizablePlist, GLShouldQuitBut1)];
		[quitAlert addButtonWithTitle:NSLocalizedStringFromTable(GLShouldQuitBut2, GLLocalizablePlist, GLShouldQuitBut2)];
		[quitAlert addButtonWithTitle:NSLocalizedStringFromTable(GLShouldQuitBut3, GLLocalizablePlist, GLShouldQuitBut3)];
		int quitRequestButton = [quitAlert runModal];
		if (quitRequestButton == NSAlertFirstButtonReturn) {
			//quit immediately
		} else if (quitRequestButton == NSAlertSecondButtonReturn) {
			//relaunch then quit
			quitRequested = YES;
			[[GLLauncherController sharedInstance] cancelLaunch];
			return NSTerminateCancel;
		} else {	
			//cancel
			return NSTerminateCancel;			
		}
	}
	if (isMini) {
		isMini = NO;
		[mainWindow orderOut:self];
		[mainWindow setFrame:[self mainWindowFrame] display:NO animate:NO];
	}
	[defaults setObject:[NSNumber numberWithBool:YES] forKey:GLQuitSuccessKey];
	[defaults setObject:[NSNumber numberWithBool:NO] forKey:GLAppFirstRunKey];
	return NSTerminateNow;
}

- (void)applicationWillHide:(NSNotification *)aNotification
{
	NSNotificationCenter *notify = [NSNotificationCenter defaultCenter];
	[notify postNotificationName:GLStopProcessTableTimerNotification object:self];	
}

- (void)applicationWillUnhide:(NSNotification *)aNotification
{
	NSNotificationCenter *notify = [NSNotificationCenter defaultCenter];
	[notify postNotificationName:GLStartProcessTableTimerNotification object:self];
}

- (BOOL)application:(NSApplication *)theApp openFile:(NSString *)filePath
{
	[self setLaunchAppPath:filePath];
	return YES;
}

- (void)application:(NSApplication *)sender openFiles:(NSArray *)filenames
{
	[self setLaunchAppPath:[filenames lastObject]];
	[[NSApplication sharedApplication] replyToOpenOrPrint:NSApplicationDelegateReplySuccess];
}


#pragma mark Window Delegate Methods
- (BOOL)windowShouldClose:(id)sender
{
	if (![[GLLauncherController sharedInstance] isLaunching]) {
		[mainWindow orderOut:self];
		[NSApp terminate:self];
		return YES;
	} else {
		return NO;
	}
}

- (NSRect)windowWillUseStandardFrame:(NSWindow *)sender defaultFrame:(NSRect)defaultFrame
{
	//this is the zoom function call
#ifdef __DEBUG__
	NSLog(@"%@: windowWillUseStandardFrame:defaultFrame:", [self class]);
#endif
	if (!isMini) {
		[defaults setObject:NSStringFromRect([mainWindow frame]) forKey:GLMaxiWindowSizeKey];
	} else {
		[defaults setObject:NSStringFromRect([mainWindow frame]) forKey:GLMiniWindowSizeKey];
	}
	isMini = !isMini;
	return [self mainWindowFrame];
}

- (BOOL)windowShouldZoom:(NSWindow *)sender toFrame:(NSRect)newFrame
{
	//window should change size
#ifdef __DEBUG__
	NSLog(@"%@: windowShouldZoom:toFrame:", [self class]);
#endif
	[mainWindow setFrame:newFrame display:YES animate:YES];
	return YES;	
}

- (NSSize)windowWillResize:(NSWindow *)sender toSize:(NSSize)proposedFrameSize
{
	//lock resizing on mini window
	if (isMini) {
		if (NSEqualSizes([sender frame].size, [sender minSize])) {
			proposedFrameSize = [sender frame].size;
		}
	} else {
		//check that main window can't be resized too small
		if (proposedFrameSize.height < ([sender minSize].height + 67.0)){
			proposedFrameSize.height = ([sender minSize].height + 67.0);
		}
	}
	return proposedFrameSize;
}

//Window delegate method
- (void)openDocument:(id)sender
{
	[self browseForApp:sender];
}

#pragma mark Notification delegates
- (void)startProcessTableTimerNotification:(NSNotification *)notification
{
#ifdef __DEBUG__
	NSLog(@"%@: startProcessTableTimerNotification:", [self class]);
#endif
	if ([refreshTimer isValid]) {
		[refreshTimer invalidate];
	}
	if (refreshTimer != nil) {
		[refreshTimer release];
	}
	float speedDelta = [[GLPreferences sharedInstance] computerSpeed];
	refreshTimer = [[NSTimer timerWithTimeInterval:0.3*speedDelta
										   target:self
										 selector:@selector(updateProcessTableGUI)
										 userInfo:nil
										  repeats:YES] retain];
	[[NSRunLoop currentRunLoop] addTimer:refreshTimer
				  forMode:NSDefaultRunLoopMode];
	[self updateProcessTableGUI];
}

//notification delegate
- (void)stopProcessTableTimerNotification:(NSNotification *)notification
{
#ifdef __DEBUG__
	NSLog(@"%@: stopProcessTableTimerNotification:", [self class]);
#endif
	if ([refreshTimer isValid]) {
		[refreshTimer invalidate];
	}
}

//notification delegate
- (void)reloadProcessTableNotification:(NSNotification *)notification
{
	[self updateProcessTableGUI];
}

- (void)startProgressIndTimerNotification:(NSNotification *)notification
{
#ifdef __DEBUG__
	NSLog(@"%@: startProgressIndTimerNotification:", [self class]);
#endif
	if ([progressTimer isValid]) {
		[progressTimer invalidate];
	}
	if (progressTimer != nil) {
		[progressTimer release];
	}
	float speedDelta = [[GLPreferences sharedInstance] computerSpeed];
	progressTimer = [[NSTimer timerWithTimeInterval:0.3*speedDelta
											target:self
										  selector:@selector(updateProgressIndicatorGUI)
										  userInfo:nil
										   repeats:YES] retain];
	[[NSRunLoop currentRunLoop] addTimer:progressTimer
								 forMode:NSDefaultRunLoopMode];
	[self updateProgressIndicatorGUI];
}

- (void)stopProgressIndTimerNotification:(NSNotification *)notification
{
#ifdef __DEBUG__
	NSLog(@"%@: stopProgressIndTimerNotification:", [self class]);
#endif
	if ([progressTimer isValid]) {
		[progressTimer invalidate];
	}
	[progressIndicator setDoubleValue:0.0];
}

- (void)hideSystemUINotification:(NSNotification *)notification
{
#ifdef __DEBUG__
	NSLog(@"%@: hideSystemUINotification:", [self class]);
#endif
	[mainWindow hideSystemUI];
}

- (void)revertSystemUINotification:(NSNotification *)notification
{
#ifdef __DEBUG__
	NSLog(@"%@: revertSystemUINotification:", [self class]);
#endif
	[mainWindow revertSystemUI];
}

- (void)launcherBeginQuitAllNotification:(NSNotification *)notification
{
#ifdef __DEBUG__
	NSLog(@"%@: launcherBeginQuitAllNotification:", [self class]);
#endif
	NSNotificationCenter *notify = [NSNotificationCenter defaultCenter];
	[notify postNotificationName:GLReloadProcessTableNotification
						  object:self];	
	[notify postNotificationName:GLStartProgressTimerNotification
						  object:self];	
	[notify postNotificationName:GLHideSystemUINotification
						  object:self];
	[quitAllAndLaunchButton setTitle:NSLocalizedStringFromTable(GLAbortButton, GLLocalizablePlist, GLAbortButton)];
	[launchMenuItem setTitle:NSLocalizedStringFromTable(GLAbortButton, GLLocalizablePlist, GLAbortButton)];
	[browseButton setEnabled:NO];
	[imageWell setEnabled:NO];
	[browseMenuItem setEnabled:NO];
	alwaysOnTop = [[GLPreferences sharedInstance] alwaysOnTopDuringLaunch];
	shouldMini = !isMini && alwaysOnTop;
	if (alwaysOnTop) {
		[mainWindow setLevel:NSFloatingWindowLevel];
	}
	if (shouldMini) {
		[self updateMainWindowZoomGUI];
	}
}

- (void)launcherWillLaunchNotification:(NSNotification *)notification
{
#ifdef __DEBUG__
	NSLog(@"%@: launcherWillLaunchNotification:", [self class]);
#endif
	NSNotificationCenter *notify = [NSNotificationCenter defaultCenter];
	[notify postNotificationName:GLRevertSystemUINotification
						  object:self];
	[notify postNotificationName:GLStopProgressTimerNotification
						  object:self];	
	if (alwaysOnTop) {
		[mainWindow setLevel:NSNormalWindowLevel];	
	}
	[quitAllAndLaunchButton setEnabled:NO];
	[quitAllAndLaunchButton setTitle:NSLocalizedStringFromTable(GLLaunchButton, GLLocalizablePlist, GLLaunchButton)];
	[launchMenuItem setEnabled:NO];
	[launchMenuItem setTitle:NSLocalizedStringFromTable(GLLaunchButton, GLLocalizablePlist, GLLaunchButton)];
}

- (void)launcherBeginRelaunchAllNotification:(NSNotification *)notification
{
#ifdef __DEBUG__
	NSLog(@"%@: launcherBeginRelaunchAllNotification:", [self class]);
#endif
	NSNotificationCenter *notify = [NSNotificationCenter defaultCenter];
	[notify postNotificationName:GLStartProgressTimerNotification
						  object:self];	
	if (alwaysOnTop) {
		[mainWindow setLevel:NSFloatingWindowLevel];
	}
}

- (void)launcherDidFinishLaunchingNotification:(NSNotification *)notification
{
#ifdef __DEBUG__
	NSLog(@"%@: launcherDidFinishLaunchingNotification:", [self class]);
#endif
	NSNotificationCenter *notify = [NSNotificationCenter defaultCenter];
	[notify postNotificationName:GLStopProgressTimerNotification
						  object:self];	
	//back to  normal
	[quitAllAndLaunchButton setTitle:NSLocalizedStringFromTable(GLLaunchButton, GLLocalizablePlist, GLLaunchButton)];
	[quitAllAndLaunchButton setEnabled:YES];
	[quitAllAndLaunchButton setState:NSOffState];
	[launchMenuItem setTitle:NSLocalizedStringFromTable(GLLaunchButton, GLLocalizablePlist, GLLaunchButton)];
	[launchMenuItem setEnabled:YES];
	[browseMenuItem setEnabled:YES];
	[browseButton setEnabled:YES];
	[imageWell setEnabled:YES];
	[applicationListView displayIfNeeded];
	[[GLProcess currentProcess] moveToFrontProcess];	
	[[GLNagController sharedInstance] setNextNagTimer];
	[mainWindow setLevel:NSNormalWindowLevel];
	shouldMini = isMini && shouldMini;
	if (shouldMini) {
		[self updateMainWindowZoomGUI];
	}
	if (quitRequested) {
		[NSApp terminate:self];
	}
}

#pragma mark tableView Delegates

#pragma mark tableView datasouce
- (int)numberOfRowsInTableView:(NSTableView *)aTableView
{
	return [applicationList count];
}


- (void)drawIcon:(NSImage *)image inRect:(NSRect)destRect {
	float sqrmodifier = (destRect.size.width - destRect.size.height)/2;
	if (sqrmodifier < 0) {
		sqrmodifier = abs(sqrmodifier);
		destRect.size.height -= sqrmodifier;
		destRect.origin.y += sqrmodifier;
	}
	if (sqrmodifier > 0) {
		sqrmodifier = abs(sqrmodifier);
		destRect.size.width -= sqrmodifier;
		destRect.origin.x += sqrmodifier;
	}
    [image drawInRect:destRect 
			 fromRect:NSMakeRect(0.0f, 0.0f, [image size].width, [image size].height)
			operation:NSCompositeSourceOver
			 fraction:1.0f];
}

//tableView datasouce
- (id)tableView:(NSTableView *)aTableView 
		objectValueForTableColumn:(NSTableColumn *)aTableColumn
		row:(int)row
{
	GLProcess *process = [applicationList objectAtIndex:row];
	
	[[aTableColumn dataCell] setEnabled:(![[GLLauncherController sharedInstance] isLaunching])];
	
	if ([[aTableColumn identifier] isEqual:@"imagecell"]) {
		IconFamily *iconFamily = [IconFamily iconFamilyWithIconOfFile:[process path]];
		NSImage *theIcon = [iconFamily imageWithAllReps];
		NSSize canvasSize = NSMakeSize(GLTableIconSize, GLTableIconSize);
		NSRect srcRect = NSMakeRect(0.0f, 0.0f, [theIcon size].width, [theIcon size].height);
		NSRect destRect = NSMakeRect(0.5f, 0.5f, canvasSize.width-0.5f, canvasSize.height-0.5f);
		NSImage *canvas = [[[NSImage alloc] initWithSize:canvasSize] autorelease];
		[canvas lockFocus];
		[theIcon drawInRect:destRect fromRect:srcRect
				 operation:NSCompositeSourceOver fraction:1.0f];
		[canvas unlockFocus];
		return canvas;
	} else if ([[aTableColumn identifier] isEqual:@"checkbox"]) {
		return [NSNumber numberWithBool:[process enabled]];
	} else if ([[aTableColumn identifier] isEqual:@"pid"]) {
		return [NSNumber numberWithInt:[process processIdentifier]];
	} else if ([[aTableColumn identifier] isEqual:@"application"]) {
		return [process annotatedCommand];
	} else if ([[aTableColumn identifier] isEqual:@"path"]) {
		return [process path];
	}
	return nil;
}

//tableView change object value
- (void)tableView:(NSTableView *)aTableView
		setObjectValue:(id)anObject
		forTableColumn:(NSTableColumn *)aTableColumn
		row:(int)row
{
	if ([[GLLauncherController sharedInstance] isLaunching])
		return;
	// only checkbox column accepts input
	// no need to check which column
	GLProcess *process = [applicationList objectAtIndex:row];
	
	[process setEnabled:[anObject boolValue]];
	if (processEnabledToggle != [anObject boolValue]){
		//add to selected list
		[selectedApplications setValue:[NSNumber numberWithBool:YES] forKey:[process command]];
	} else {
		//remove from selected list
		[selectedApplications removeObjectForKey:[process command]];
	}
	
	//update defaults
	[selectedApplicationsDefaultsDict setObject:selectedApplications
								 forKey:[NSString stringWithFormat:@"%d", processEnabledToggle]];
	[defaults setObject:selectedApplicationsDefaultsDict forKey:GLSelectedApplicationsListKey];
	
	//check sort descriptors for "enabled"
	//if yes then re-sort table
	NSEnumerator *enumerator = [[applicationListView sortDescriptors] objectEnumerator];
	NSSortDescriptor *tempSort;
	while ((tempSort = [enumerator nextObject])) {
		if ([[tempSort key] isEqual:@"enabled"]) {
			[applicationList sortUsingDescriptors:[applicationListView sortDescriptors]];
			[applicationListView reloadData];
			[applicationListView selectRowIndexes:[NSIndexSet 
								indexSetWithIndex:[applicationList indexOfObject:process]]
							 byExtendingSelection:NO];
		}
	}
	[applicationListView setNeedsDisplay:YES];
}

- (void)tableView:(NSTableView *)tableView sortDescriptorsDidChange:(NSArray *)oldDescriptors
{
	[applicationList sortUsingDescriptors:[tableView sortDescriptors]];
	[tableView reloadData];
	//save to defaults
	NSData *theData=[NSArchiver archivedDataWithRootObject:[tableView sortDescriptors]];
	[defaults setObject:theData forKey:GLTableSortDescriptorsKey];
}
@end
