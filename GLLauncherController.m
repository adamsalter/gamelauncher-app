//
//  GLLauncherController.m
//  GameLauncher
//
//  Created by Adam on 25/05/05.
//  Copyright 2005 2Sublime.com. All rights reserved.
//

#import "GLLauncherController.h"
#import <GLGUIController.h>


@implementation GLLauncherController

static GLLauncherController *sharedInstance = nil;
+ (GLLauncherController *)sharedInstance
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
	launchNotificationPath = [NSString string];
}

- (void)startRunLoop:(NSThread *)sender
{
    [NSAutoreleasePool new];
	
	mainThread = [sender retain];
    myThread = [[NSThread currentThread] retain];
    [NSThread prepareForInterThreadMessages];
	
    [[NSRunLoop currentRunLoop] run];
}

- (BOOL)isLaunching
{
	return isLaunching;
}

- (NSThread *)myThread
{
	return myThread;
}

- (double)launchProgress
{
	return launchProgress;
}

- (void)doQuitAllAndLaunch
{
	//handles quitting all applications,
	//launching new applications,
	//and relaunching old applications
#ifdef __DEBUG__
	NSLog(@"%@: begin \"doQuitAllAndLaunch:\"", [self class]);
#endif
	isLaunching = YES;
	NSNotificationCenter *notify = [NSNotificationCenter defaultCenter];

	//update speedDelta and alwaysOnTop
	[notify postNotificationName:GLBeginQuitAllNotification
						  object:self
						inThread:mainThread];	
	speedDelta = [[GLPreferences sharedInstance] computerSpeed];
	
	//generate list of selected applications
	NSArray *applicationList = [[GLGUIController sharedInstance] applicationList];
	NSMutableArray *quitList;
	quitList = [NSMutableArray array];
	NSEnumerator *enumerator = [applicationList objectEnumerator];
	GLProcess *process;
	while ((process = [enumerator nextObject])) {
		if ([process enabled]) {
			[quitList addObject:process];
		}
	}
	
	//Sort list by process ID
	NSSortDescriptor *tempSort = [[NSSortDescriptor new] initWithKey:@"pid" ascending:NO];
	[quitList sortUsingDescriptors:[NSArray arrayWithObject:tempSort]];

	//Quit applications
	NSArray *listOfQuitApplications = [self
			quitAllSelectedApplications:quitList];

	//Launch app
	if (longLaunchAnswer != kCancelLaunch) {
		//quit dashboard
		//if 10.4 or greater
		if (([[[NSCoder alloc] init] systemVersion] >= 1000) &&
			([listOfQuitApplications count] > 0)){
			[[GLProcess processForCommand:@"Dock"] quitGracefully];
		}
		//update
		[notify postNotificationName:GLWillLaunchNotification
							  object:self
							inThread:mainThread];	
		
		/* LAUNCH GAME */
		didLaunch = YES;
		[self waitUntilExitAppWithPath:[[GLGUIController sharedInstance] launchAppPath]];
		didLaunch = NO;
		
	}

	//Relaunch quit apps
	[notify postNotificationName:GLBeginRelaunchAllNotification
						  object:self
						inThread:mainThread];	

	[self relaunchAllSelectedApplications:listOfQuitApplications];

	//send final notifications
	[notify postNotificationName:GLDidFinishLaunchingNotification
						  object:self
						inThread:mainThread];	
	isLaunching = NO;
#ifdef __DEBUG__
	NSLog(@"%@: end \"doQuitAllAndLaunch:\"", [self class]);
#endif
	return;
}

- (void)cancelLaunch
{
	longLaunchAnswer = kCancelLaunch;
	NSNotificationCenter *notify = [NSNotificationCenter defaultCenter];
	[notify postNotificationName:GLRevertSystemUINotification
						  object:self
						inThread:mainThread];
	if (didLaunch) {
		GLProcess *proc = (GLProcess*)[GLProcess processForProcessIdentifier:[launchTask processIdentifier]];
		[self quitProcess:proc];
	}
}

- (NSArray *)quitAllSelectedApplications:(NSArray *)quitList
{
	NSEnumerator *enumerator;
	//Most recent apps quit first.
	enumerator = [quitList objectEnumerator];
	GLProcess *process;
	//BOOL didQuitGracefully = YES;
	double increment = (100.0/[quitList count]);
	double progress = 0.0;
	GLLaunchQueryState quitAnswer = kStateUndefined;
	NSMutableArray *listOfQuitApplications = [NSMutableArray array];
	while ((process = [enumerator nextObject])) {
		quitAnswer = [self quitProcess:process];
		if (quitAnswer == kSkipApplication) {
			//do nothing
		}
		if (quitAnswer == kCancelLaunch) {
			//cancel and return
			break;
		}
		//update progress bar
		progress = progress + increment;
		launchProgress = progress;
		//add to relaunch list
		if (quitAnswer != kSkipApplication) {
			[listOfQuitApplications addObject:process];
		}
	}
	if (quitAnswer != kCancelLaunch) {
		launchProgress = 99.0;
	}
	NSArray *retArr = [NSArray arrayWithArray:listOfQuitApplications];
	[listOfQuitApplications release];
	return [retArr retain];
}

- (GLLaunchQueryState)quitProcess:(GLProcess *)process
{
	speedDelta = [[GLPreferences sharedInstance] computerSpeed];
	BOOL longLaunchQuestion;
	NSDate *timeOutStart = [NSDate date];
	longLaunchQuestion = NO;
	longLaunchAnswer = kStateUndefined;
	[process quitGracefully];
	while (([process isRunning]) &&
		   ((longLaunchAnswer == kStateUndefined) ||
			(longLaunchAnswer == kContinueWaiting))) {
		if (longLaunchAnswer == kContinueWaiting) {
			longLaunchAnswer = kStateUndefined;
			longLaunchQuestion = NO;
			timeOutStart = [NSDate date];
		}
		[NSThread sleepUntilDate:[NSDate 
					dateWithTimeIntervalSinceNow:0.5]];
		double waitTime = [[NSDate date] timeIntervalSinceDate:timeOutStart];
		//NSLog(@"%f", waitTime);
		if ((waitTime > speedDelta) && !longLaunchQuestion) {
			//show sheet and ask what to do
			[slowLaunchSheetIcon setImage:[[NSWorkspace sharedWorkspace]
				iconForFile:[process path]]];
			[slowLaunchSheetApplicationName setStringValue:[process command]];
			[NSApp beginSheet:slowLaunchSheet
			   modalForWindow:[[GLGUIController sharedInstance] mainWindow]
				modalDelegate:self
			   didEndSelector:@selector(sheetDidEnd:returnCode:contextInfo:)
				  contextInfo:NULL];
			longLaunchQuestion = YES;
		}
	}
	if (longLaunchQuestion &&
		(longLaunchAnswer == kStateUndefined)) {
		//process exited while question being asked
		[slowLaunchSheet orderOut:self];
		[NSApp endSheet:slowLaunchSheet returnCode:kStateUndefined];
	}
	if (longLaunchAnswer == kKillApplication) {
		[process terminate];
	}
	return longLaunchAnswer;
}

/*
 Used to launch game
 Waits until app quits.
 */
- (void)waitUntilExitAppWithPath:(NSString *)path
{
	launchTask = [self launchTaskWithPath:path args:[NSArray array]];
	NSLog(@"%@ launched", [[path pathComponents] lastObject]);
	[NSThread sleepUntilDate:[NSDate 
					dateWithTimeIntervalSinceNow:speedDelta/3]];
	[[GLProcess processForProcessIdentifier:[launchTask processIdentifier]] moveToFrontProcess];
	[launchTask waitUntilExit];
	int status = [launchTask terminationStatus];
	if (status != 0) {
		NSAlert *crashAlert = [[NSAlert alloc] init];
		[crashAlert setMessageText:NSLocalizedStringFromTable(GLAlertAppCrashTitle, GLLocalizablePlist, GLShouldQuitTitle)];
		NSString *temp = [NSString stringWithFormat:NSLocalizedStringFromTable(GLAlertAppCrashMsg, GLLocalizablePlist, GLAlertAppCrashMsg), [[path pathComponents] lastObject], status];
		[crashAlert setInformativeText:temp];
		[crashAlert addButtonWithTitle:NSLocalizedStringFromTable(GLAlertAppCrashBut1, GLLocalizablePlist, GLAlertAppCrashBut1)];
		[crashAlert addButtonWithTitle:NSLocalizedStringFromTable(GLAlertAppCrashBut2, GLLocalizablePlist, GLAlertAppCrashBut2)];
		int quitRequestButton = [crashAlert runModal];
		if (quitRequestButton == NSAlertFirstButtonReturn) {
			//relaunch
			[self waitUntilExitAppWithPath:path];
		} else {	
			//cancel
		}
	}
#ifdef __DEBUG__
	NSLog(@"++++++ %@ finished launch with status (%d) ++++++", [[path pathComponents] lastObject], status);
#endif
}

- (NSString *)runCommandLine:(NSString *)command withArguments:(NSArray *)args
{
	NSTask *task = [[NSTask alloc] init];
	NSPipe *newPipe = [NSPipe pipe];
	NSFileHandle *readHandle = [newPipe fileHandleForReading];
	NSData *inData;
	NSString *tempString;
	[task setCurrentDirectoryPath:NSHomeDirectory()];
	[task setLaunchPath:command];
	[task setArguments:args];
	[task setStandardOutput:newPipe];
	[task setStandardError:newPipe];
	[task launch];
	inData = [readHandle readDataToEndOfFile];
	tempString = [[NSString alloc] initWithData:inData encoding:NSASCIIStringEncoding];
	[task release];
	[tempString autorelease];
	return tempString;
}

-(NSString *)resolveAliasInPath:(NSString *)path
{
	NSString *resolvedPath = nil;
	CFURLRef url;
	
	url = CFURLCreateWithFileSystemPath(NULL /*allocator*/, (CFStringRef)path,
										kCFURLPOSIXPathStyle, NO /*isDirectory*/);
	if (url != NULL)
	{
		FSRef fsRef;
		if (CFURLGetFSRef(url, &fsRef))
		{
			Boolean targetIsFolder, wasAliased;
			if (FSResolveAliasFile (&fsRef, true /*resolveAliasChains*/, 
									&targetIsFolder, &wasAliased) == noErr && wasAliased)
			{
				CFURLRef resolvedUrl = CFURLCreateFromFSRef(NULL, &fsRef);
				if (resolvedUrl != NULL)
				{
					resolvedPath = (NSString*)
					CFURLCopyFileSystemPath(resolvedUrl,
											kCFURLPOSIXPathStyle);
					CFRelease(resolvedUrl);
				}
			} else {
				UInt8 fsPath[PATH_MAX];
				FSRefMakePath(&fsRef, fsPath, PATH_MAX);
				resolvedPath = [[NSString alloc] initWithUTF8String:(char *)fsPath];
			}
		}
		CFRelease(url);
	}
	
	if (resolvedPath==nil)
		resolvedPath = [[NSString alloc] initWithString:path];
	
	return [resolvedPath autorelease];
}

- (NSTask *)launchTaskWithPath:(NSString *)path args:(NSArray *)args
{
#ifdef __DEBUG__
	NSLog(@"%@: launchTaskWithPath:%@ args:%@", [self class], path, [args description]);
#endif
    NSTask *aTask = [[NSTask alloc] init];
	NSString *runDir, *executable, *name;
	name = [[path pathComponents] lastObject];
	executable = [[NSBundle bundleWithPath:path] executablePath];
	runDir = [path stringByDeletingLastPathComponent];
	if (executable == nil) {
		// Application is Carbon
		executable = @"/System/Library/Frameworks/Carbon.framework/Versions/Current/Support/LaunchCFMApp";
		args = [NSArray arrayWithObject:path];
	} else {
		executable = [self resolveAliasInPath:executable];
		NSString *fileType = [self runCommandLine:@"/usr/bin/file" withArguments:[NSArray arrayWithObject:executable]];
		AGRegex *regex = [AGRegex regexWithPattern:@"Mach-O"];
		AGRegexMatch *match = nil;
		match = [regex findInString:fileType];
		if (!match) {
			// Application is Carbon
			args = [NSArray arrayWithObject:executable];
			runDir = [executable stringByDeletingLastPathComponent];
			executable = @"/System/Library/Frameworks/Carbon.framework/Versions/Current/Support/LaunchCFMApp";
		}
	}
	
	/* set arguments */
	[aTask setLaunchPath:executable];
	[aTask setArguments:args];
	[aTask setCurrentDirectoryPath:runDir];
	[aTask launch];
	return [aTask autorelease];
}

- (void)relaunchProcess:(GLProcess *)process args:(NSArray *)args
{
	NSString *name;
	name = [[[process path] pathComponents] lastObject];
	if ([args count] == 0) {
		[[NSWorkspace sharedWorkspace] launchApplication:[process path]];
#ifdef __DEBUG__
		NSLog(@"%@: %@(pid%d) relaunched (NSWorkspace) args:()", [self class], name, [process pid]);
#endif
	} else {
		//Note:launches as a child of current process
		//     not good once GameLauncher quits.
		[self launchTaskWithPath:[process path] args:args];
#ifdef __DEBUG__
		NSLog(@"%@: %@(pid%d) relaunched (NSTask) args:%@", [self class], name, [process pid], args);
#endif
	}
}

- (void)relaunchAllSelectedApplications:(NSArray *)relaunchList
{
	NSEnumerator *enumerator;
	enumerator = [relaunchList reverseObjectEnumerator];
	GLProcess *process;
	//Note: launchProgress may not equal 100.0
	// if launch is cancelled.
	double progress = launchProgress;
	double decrement = (progress/[relaunchList count]);
	NSNotificationCenter *notify = [[NSWorkspace sharedWorkspace] notificationCenter];
	[notify addObserver:self selector:@selector(appDidLaunch:)
				   name:NSWorkspaceDidLaunchApplicationNotification
				 object:nil];
	//launchNotificationPath used to check through notifications
	//speeds relaunch times
	while ((process = [enumerator nextObject])) {
		if (![GLProcess processForCommand:[process command]]) {
			[self relaunchProcess:process args:[process arguments]];
			NSDate *waitDate = [NSDate dateWithTimeIntervalSinceNow:speedDelta];
			while (![[NSDate date] isGreaterThan:waitDate] && 
					![launchNotificationPath isEqualToString:[process path]]){
				[NSThread sleepUntilDate:[NSDate 
					dateWithTimeIntervalSinceNow:speedDelta/3]];
			}
		}
		//update progress bar
		progress = progress - decrement;
		launchProgress = progress;
	}
	[notify removeObserver:self];
	launchProgress = 0.0;
}

#pragma mark NSNotification observer selectors
- (void)appDidLaunch:(NSNotification *)notification
{
	[launchNotificationPath release];
	launchNotificationPath = [[[notification userInfo] valueForKey:@"NSApplicationPath"] retain];
}

#pragma mark Sheet Delegate Actions

- (IBAction)cancelLaunch:(id)sender
{
	[slowLaunchSheet orderOut:sender];
    [NSApp endSheet:slowLaunchSheet returnCode:kCancelLaunch];
}

- (IBAction)continueWaiting:(id)sender
{
	int returnCode = [[radioList selectedCell] tag];
	[slowLaunchSheet orderOut:sender];
    [NSApp endSheet:slowLaunchSheet returnCode:returnCode];
}

- (void)sheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode
		contextInfo:(void *)contextInfo
{
	longLaunchAnswer = returnCode;
	if (longLaunchAnswer == kCancelLaunch) {
		[self cancelLaunch];
	}
}

@end
