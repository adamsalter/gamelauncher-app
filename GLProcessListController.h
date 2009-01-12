//
//  GLProcessListController.h
//  GameLauncher
//
//  Created by Adam on 19/02/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <2STools/InterThreadMessaging.h>


@interface GLProcessListController : NSObject {
	NSThread *myThread;
}

+ (GLProcessListController *)sharedInstance;
- (void)startRunLoop:(NSThread *)sender;
- (NSThread *)myThread;

@end
