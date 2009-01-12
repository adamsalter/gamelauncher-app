//
//  ProcessList.m
//  GameLauncher
//
//  Created by Adam on 23/05/05.
//  Copyright 2005 2Sublime.com. All rights reserved.
//

#import "GLProcess.h"

@implementation GLProcess

- (BOOL)isSystemProcess
{
	//is gamelauncher process?
	if (process == [[GLProcess currentProcess] processIdentifier]) {
		return YES;
	}
	//is other important process?
	NSString *systemProcs = NSLocalizedString(@"GLSystemProcs", @"GLSystemProcs");
	AGRegex *regex = [AGRegex regexWithPattern:[self command]];
	AGRegexMatch *match = nil;
	match = [regex findInString:systemProcs];
	if (match) {
		return YES;
	}
	//or is deamon process? (No PSN)
	pid_t pid = process;
	if (GetProcessForPID(pid , &psn) != 0) {
		return YES;
	}
	return NO;
}

+ (NSArray *)allUserApplications
{
	NSArray *userProcList = [GLProcess userProcesses];
	NSEnumerator *enumerator = [userProcList objectEnumerator];
	GLProcess *proc;
	NSMutableArray *returnList = [NSMutableArray array];
	while ((proc = [enumerator nextObject])) {
		if (![proc isSystemProcess]) {
			[returnList addObject:proc];
		}
	}
	return returnList;
}

- (NSArray *)arguments
{
	NSString *searchString = @"-psn_[0-9,_]*";
    NSMutableArray *args = [NSMutableArray array];
	[args addObjectsFromArray:[super arguments]];
	AGRegex *regex = [AGRegex regexWithPattern:searchString options:0];
    AGRegexMatch *match = nil;
	NSEnumerator *enumerator = [args objectEnumerator];
	NSString *arg;
	while ((arg = [enumerator nextObject])) {
		match = [regex findInString:arg];
		if (match) {
			break;
		}
	}
	if (match) {
		[args removeObject:arg];
	}
	return (NSArray *)args;
}

- (BOOL)enabled
{
	return enabled;
}

- (void)setEnabled:(BOOL)enableProc
{
	enabled = enableProc;
}

- (void)loadProcessInfo
{
	pid_t pid = process;
	OSStatus err = GetProcessForPID(pid, &psn);
	if (err == 0) {
		processInfo = (NSDictionary *) 
		ProcessInformationCopyDictionary(&psn,
										 kProcessDictionaryIncludeAllInformationMask);
	}
	processInfoLoaded = YES;
}

- (NSString *)path
{
	if (!processInfoLoaded)
		[self loadProcessInfo];
	if (processInfo)
		return [processInfo valueForKey:@"BundlePath"];
	else
		return command;
}

- (NSString *)executable
{
	if (!processInfoLoaded)
		[self loadProcessInfo];
	if (processInfo)
		return [processInfo valueForKey:@"CFBundleExecutable"];
	else
		return command;
}

- (int)pid
{
	return [self processIdentifier];
}

@end
