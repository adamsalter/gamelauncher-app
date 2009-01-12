/*-*- Mode: ObjC; tab-width: 4; indent-tabs-mode: nil; c-basic-offset: 4  -*-*/
/*
 * InterThreadMessaging -- InterThreadMessaging.h
 * Created by toby on Tue Jun 19 2001.
 *
 */

#import "InterThreadMessaging.h"

@interface Test : NSObject
{
    @public
    NSThread *_testThread;
}

@end

@implementation Test

- init
{
    _testThread = nil;
    return self;
}

- (void) waitForSomething
{
    [NSAutoreleasePool new];

    [[NSNotificationCenter defaultCenter]
        addObserver:self
        selector:@selector(ping:)
        name:@"Ping"
        object:nil];

    _testThread = [NSThread currentThread];
    [NSThread prepareForInterThreadMessages];

    [[NSRunLoop currentRunLoop] run];
}

- (void) ping:(NSNotification *)notification
{
    NSLog(@"thread main pinged");
}

- (void) aMethodWithNoArguments
{
    NSLog(@"thread main aMethodWithNoArguments");
}

- (void) aMethodWithOneArgument:(id)arg
{
    NSLog(@"thread main aMethodWithOneArgument:%@", arg);
}

- (void) aMethodWithTwoArguments:(id)arg :(id)anotherArg
{
    NSLog(@"thread main aMethodWithTwoArguments:%@ :%@", arg, anotherArg);
}

- (void) postNotifications:(id)idValue;
{
    int threadId = [idValue intValue];

    while (1)
    {
        NSAutoreleasePool *pool = [NSAutoreleasePool new];

        NSLog(@"thread %d    post Ping", threadId);
        [[NSNotificationCenter defaultCenter]
            postNotificationName:@"Ping"
            object:self
            inThread:_testThread];
        sleep((int)(2.0 * (float)rand() / (float)RAND_MAX));

        NSLog(@"thread %d    invoke aMethodWithNoArguments", threadId);
        [self performSelector:@selector(aMethodWithNoArguments) inThread:_testThread];
        sleep((int)(2.0 * (float)rand() / (float)RAND_MAX));

        NSLog(@"thread %d    invoke aMethodWithOneArgument:Hi", threadId);
        [self performSelector:@selector(aMethodWithOneArgument:)
              withObject:@"Hi"
              inThread:_testThread];
        sleep((int)(2.0 * (float)rand() / (float)RAND_MAX));

        NSLog(@"thread %d    invoke aMethodWithTwoArguments:Hello :world!",
              threadId);
        [self performSelector:@selector(aMethodWithTwoArguments::)
              withObject:@"Hello"
              withObject:@"world!"
              inThread:_testThread];
        sleep((int)(2.0 * (float)rand() / (float)RAND_MAX));

        [pool release];
    }
}

@end

int
main ()
{
    Test *t;

    [NSAutoreleasePool new];

    t = [Test new];

    [NSThread detachNewThreadSelector:@selector(waitForSomething)
              toTarget:t
              withObject:nil];

    while (nil == t->_testThread) {
        sched_yield();
    }
    sleep(1);

    [NSThread detachNewThreadSelector:@selector(postNotifications:)
              toTarget:t
              withObject:@"1"];
    [NSThread detachNewThreadSelector:@selector(postNotifications:)
              toTarget:t
              withObject:@"2"];

    [t postNotifications:@"3"];
    
    return 0;
}

