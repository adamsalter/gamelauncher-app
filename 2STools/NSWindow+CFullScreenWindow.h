//
//  CFullScreenWindow.h
//  SequenceGrabber
//
//  Created by Jonathan Wight on 10/20/2004.
//  Copyright 2004 Toxic Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import <Carbon/Carbon.h>


/*
 See:
 http://tuvix.apple.com/technotes/tn2002/tn2062.html
 For screen modes.
 */

@interface NSWindow (CFullScreenWindow)

- (id)initWithFSContentRect:(NSRect)contentRect styleMask:(unsigned int)aStyle backing:(NSBackingStoreType)bufferingType defer:(BOOL)flag;

- (void)makeFSKeyAndOrderFront:(id)inSender;
- (void)orderFrontFS:(id)inSender;
- (void)orderOutFS:(id)inSender;
- (BOOL)canBecomeKeyWindow;

- (NSSize)preferredScreenSize;
- (void)setPreferredScreenSize:(NSSize)inPreferredScreenSize;

- (BOOL)shouldChangeScreen;
- (void)setShouldChangeScreen:(BOOL)inShouldChangeScreen;

- (BOOL)shouldHideSystemUI;
- (void)setShouldHideSystemUI:(BOOL)inShouldHideSystemUI;

- (void)hideSystemUI;
- (void)revertSystemUI;

- (void)changeScreen;
- (void)revertScreen;

@end
