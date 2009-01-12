//
//  ProcessList.h
//  GameLauncher
//
//  Created by Adam on 23/05/05.
//  Copyright 2005 2Sublime.com. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <ApplicationServices/ApplicationServices.h>
#import <2STools/AGProcess.h>
#import <AGProcess-GLProc.h>
#import <2STools/AGRegex.h>
#import <CPS.h>

@interface GLProcess : AGProcess {
	BOOL enabled;
	BOOL processInfoLoaded;
	ProcessSerialNumber psn;
	NSDictionary *processInfo;
}

+ (NSArray *)allUserApplications;
- (NSArray *)arguments;
- (BOOL)enabled;
- (void)setEnabled:(BOOL)enableProc;
- (NSString *)path;
- (NSString *)executable;
- (int)pid;

@end
