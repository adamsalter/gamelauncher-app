//
//  GLImageView.h
//  GameLauncher
//
//  Created by Adam on 22/06/05.
//  Copyright 2005 2Sublime.com. All rights reserved.
//

#import "GLImageView-Delegate.h"

@implementation GLImageView

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    [self registerForDraggedTypes:[NSArray arrayWithObjects:NSFilenamesPboardType, nil]];
    return self;
}

- (void)dealloc
{
    [self unregisterDraggedTypes];
    [super dealloc];
}

- (void)awakeFromNib
{
	[self setEnabled:YES];
	[self setImageScaling:NSScaleToFit];
	[self setImageFrameStyle:NSImageFrameGrayBezel];
}

- (void)drawRect:(NSRect)rect
{
	[super drawRect:rect];
	if (highlighted) {
		NSColor *hlColor = [[NSColor selectedTextBackgroundColor] shadowWithLevel:0.2];
		[hlColor set];
		[NSBezierPath setDefaultLineWidth:2.5];
		[NSBezierPath strokeRect:NSInsetRect(rect, 7.0, 7.0)];
	}
}

- (void)viewDidEndLiveResize
{
	[self setNeedsDisplay:YES];
}

#pragma mark Dragging destination
- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender
{
    if ((NSDragOperationGeneric & [sender draggingSourceOperationMask]) 
		== NSDragOperationGeneric)
    {
		highlighted = YES;
		[self setNeedsDisplay:YES];
        return NSDragOperationGeneric;
    }
    else
    {
        return NSDragOperationNone;
    }
}

- (void)draggingExited:(id <NSDraggingInfo>)sender
{
	highlighted = NO;
	[self setNeedsDisplay:YES];
}

/*- (NSDragOperation)draggingUpdated:(id <NSDraggingInfo>)sender
{
    if ((NSDragOperationGeneric & [sender draggingSourceOperationMask]) 
		== NSDragOperationGeneric)
    {
        return NSDragOperationGeneric;
    }
    else
    {
        return NSDragOperationNone;
    }
}

- (void)draggingEnded:(id <NSDraggingInfo>)sender
{
}*/

- (BOOL)prepareForDragOperation:(id <NSDraggingInfo>)sender
{
	return YES;
}

- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender
{
    NSPasteboard *paste = [sender draggingPasteboard];
	//gets the dragging-specific pasteboard from the sender
    NSArray *types = [NSArray arrayWithObjects:NSFilenamesPboardType, nil];
	//a list of types that we can accept
    NSString *desiredType = [paste availableTypeFromArray:types];
    NSData *carriedData = [paste dataForType:desiredType];
	
    if (nil == carriedData)
    {
        //the operation failed for some reason
        NSRunAlertPanel(@"Paste Error", @"Sorry, but the operation failed", 
						nil, nil, nil);
        return NO;
    }
    else
    {
        if ([desiredType isEqualToString:NSFilenamesPboardType])
        {
            //we have a list of file names in an NSData object
			//be caseful since this method returns id.  
			//We just happen to know that it will be an array.
            NSArray *fileArray = 
			[paste propertyListForType:@"NSFilenamesPboardType"];
            NSString *path = [fileArray objectAtIndex:0];
            [[GLGUIController sharedInstance] setLaunchAppPath:path];
			
        }
    }
    [self setNeedsDisplay:YES];    //redraw us with the new image
    return YES;
}

- (void)concludeDragOperation:(id <NSDraggingInfo>)sender
{
	highlighted = NO;
	[self setNeedsDisplay:YES];
}

/*
#pragma mark Dragging Destination
 - (unsigned int)draggingEntered:(id <NSDraggingInfo>)sender
 {
	 NSLog(@"Dragging Entered");
	 if ([sender draggingSource] != self) {
		 NSPasteboard *pb = [sender draggingPasteboard];
		 NSString *type = [pb availableTypeFromArray:[NSArray
					arrayWithObject:NSFilenamesPboardType]];
		 if (type != nil) {
//			 [imageWell highlight:YES
//						withFrame:[imageWell bounds]
//						   inView:nil]
//			 [imageWell setNeedsDisplay:YES];
		 }
	 }
 }
 
 - (void)draggingExited:(id <NSDraggingInfo>)sender
 {
	 NSLog(@"Dragging Exited");
	 [imageWell setNeedsDisplay:YES];
 }
 
 - (BOOL)prepareForDragOperation:(id <NSDraggingInfo>)sender
 {
	 return YES;
 }
 
 - (BOOL)performDragOperation:(id <NSDraggingInfo>)sender
 {
	 NSPasteboard *pb = [sender draggingPasteboard];
	 if (![self readStringFromPasteboard:pb]) {
		 NSLog(@"Error: Couldn't read from dragging pasteboard");
		 return NO;
	 }
	 return YES;
 }
 
 - (void)concludeDragOperation:(id <NSDraggingInfo>)sender
 {
	 NSLog(@"Conclude dragging operation");
	 [imageWell setNeedsDisplay:YES];
 }
 
 - (BOOL)readStringFromPasteboard:(NSPasteboard *)pb
 {
	 NSString *value;
	 NSString *type;
	 
	 //is there a string in pb?
	 type = [pb availableTypeFromArray:[NSArray
					arrayWithObject:NSFilenamesPboardType]];
	 if (type) {
		 //read the string from pb
		 value = [pb stringForType:NSFilenamesPboardType];
		 NSLog(@"%@", value);
		 return YES;
	 }
	 return NO;
 }
 */
@end
