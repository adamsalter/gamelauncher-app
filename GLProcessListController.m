//
//  GLProcessListController.m
//  GameLauncher
//
//  Created by Adam on 19/02/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "GLProcessListController.h"


@implementation GLProcessListController

static GLProcessListController *sharedInstance = nil;
+ (GLProcessListController *)sharedInstance
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

- (void)startRunLoop:(NSThread *)sender
{
    [NSAutoreleasePool new];
	
    myThread = [NSThread currentThread];
    [NSThread prepareForInterThreadMessages];
	
    [[NSRunLoop currentRunLoop] run];
}

- (NSThread *)myThread
{
	return myThread;
}

@end
