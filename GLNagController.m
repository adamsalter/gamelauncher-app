//
//  GLNagController.m
//  GameLauncher
//
//  Created by Adam on 6/06/05.
//  Copyright 2005 2Sublime.com. All rights reserved.
//

#import "GLNagController.h"

@implementation GLNagController

static BOOL pageDidLoad = NO;
static BOOL firstLoad = YES;

#pragma mark Initialisation/Accessor Methods
static GLNagController *sharedInstance = nil;
+ (GLNagController *)sharedInstance
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
	//init
	nagScreenShowing = NO;
	mainWindow = [[GLGUIController sharedInstance] mainWindow];
	[nagWindow setLevel:NSFloatingWindowLevel];
	[nagWindow setHidesOnDeactivate:YES];
}

- (WebView *)nagView
{
	return nagView;
}

#pragma mark Action Methods
- (IBAction)showNagScreen:(id)sender
{
#ifdef __DEBUG__
	NSLog(@"%@: showNagScreen", [self class]);
#endif
	NSURL *url = [NSURL URLWithString:(NSString *)GLAdUrlText];
	//check if nagScreen.nib tampered with
	if (nagView == nil) {
		[[NSWorkspace sharedWorkspace] openURL:url];
		return;
	}
	//else
	//if launching, game should be front process.
	//move to front process to show utility window
	if (!([[GLLauncherController sharedInstance] isLaunching] || nagScreenShowing)) {
		pageDidLoad = NO;
		if (firstLoad) {
			[[nagView mainFrame] loadRequest:[NSURLRequest requestWithURL:url]];	
		} else {
			[[nagView mainFrame] reload];
		}
		[nagStatusText setStringValue:@""];
		[NSApp beginSheet:nagWindow
		   modalForWindow:mainWindow
			modalDelegate:self
		   didEndSelector:@selector(sheetDidEnd:returnCode:contextInfo:)
			  contextInfo:NULL];
		[mainWindow makeKeyAndOrderFront:nil];
		nagScreenShowing = YES;
	}
}

- (void)setNextNagTimer
{
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	int sinceLastAd = abs([defaults integerForKey:GLLaunchesSinceLastAdKey]);
	[defaults setInteger:(sinceLastAd+1) forKey:GLLaunchesSinceLastAdKey];
	
	// min/max declared at top
	if ([nagTimer isValid]) {
			[nagTimer invalidate];
		}
	if (nagTimer != nil) {
		[nagTimer release];
		nagTimer = nil;
	}
	srandom(time(NULL));
	float showAd = (abs(random())%(int)GLRandAdNum);
#ifdef __DEBUG__
	NSLog(@"%@: sinceLastAd:%d showAd:%d ", [self class], (int)sinceLastAd, (int)showAd);
#endif
	if (sinceLastAd >= showAd) {
		float interval = (abs(random())%(int)(GLMaxNagTime-GLMinNagTime))+GLMinNagTime;
#ifdef __DEBUG__
		NSLog(@"%@: setNextNagTimer with interval:%d", [self class], (int)interval);
#endif
		nagTimer = [[NSTimer scheduledTimerWithTimeInterval:interval
													 target:self
												   selector:@selector(showNagScreen:)
												   userInfo:nil
													repeats:NO] retain];
		
		
		[[NSRunLoop currentRunLoop] addTimer:nagTimer forMode:NSDefaultRunLoopMode];
	}
}

- (IBAction)nagOKPressed:(id)sender
{
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	[defaults setInteger:0 forKey:GLLaunchesSinceLastAdKey];
	[nagWindow orderOut:sender];
    [NSApp endSheet:nagWindow returnCode:0];
}

- (void)sheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode
		contextInfo:(void *)contextInfo
{
	nagScreenShowing = NO;
}

#pragma mark Window Delegate Methods
- (void)windowWillClose:(NSNotification *)aNotification
{
	nagScreenShowing = NO;
	pageDidLoad = NO;
}

#pragma mark WebUIDelegate methods
- (void)webView:(WebView *)sender setStatusText:(NSString *)newText
{
	NSString *statusText = @"";
	if (![newText isEqual:@""]) {
		statusText = [NSString stringWithFormat:@"Open \"%@\" in a new window", newText];
	}
	[nagStatusText setStringValue:statusText];
}



#pragma mark WebPolicyDelegate methods
- (void)webView:(WebView *)sender 
		decidePolicyForNewWindowAction:(NSDictionary *)actionInformation
		request:(NSURLRequest *)request
		newFrameName:(NSString *)frameName
		decisionListener:(id<WebPolicyDecisionListener>)listener
{
	//policy for new window request
	[listener ignore];
	[[NSWorkspace sharedWorkspace] openURL:[request URL]];
	[self nagOKPressed:self];
}

- (void)webView:(WebView *)sender decidePolicyForNavigationAction:(NSDictionary *)actionInformation
		request:(NSURLRequest *)request frame:(WebFrame *)frame 
		decisionListener:(id<WebPolicyDecisionListener>)listener
{
	//policy for navigation request
	if (pageDidLoad) {
		[listener ignore];
		[[NSWorkspace sharedWorkspace] openURL:[request URL]];
		[self nagOKPressed:self];
	} else {
		[listener use];
	}
}

#pragma mark WebFrameLoadDelegate methods
- (void)webView:(WebView *)sender didStartProvisionalLoadForFrame:(WebFrame *)frame
{
#ifdef __DEBUG__
	NSLog(@"%@: DidStartLoad", [self class]);
#endif
}

- (void)webView:(WebView *)sender didFinishLoadForFrame:(WebFrame *)frame
{
#ifdef __DEBUG__
	NSLog(@"%@: DidFinishLoad", [self class]);
#endif
	if ([frame isEqual:[frame findFrameNamed:@"_top"]]) {
		pageDidLoad = YES;
	}
}

- (void)webView:(WebView *)sender didFailProvisionalLoadWithError:(NSError *)error forFrame:(WebFrame *)frame
{
	if ([frame isEqual:[frame findFrameNamed:@"_top"]]) {
		NSURL *url = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"no_internet" ofType:@"html"]];
		[[nagView mainFrame] loadRequest:[NSURLRequest requestWithURL:url]];
		firstLoad = YES;
	}
}
@end
