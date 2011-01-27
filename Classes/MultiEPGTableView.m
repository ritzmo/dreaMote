//
//  MultiEPGTableView.m
//  dreaMote
//
//  Created by Moritz Venn on 27.01.11.
//  Copyright 2011 Moritz Venn. All rights reserved.
//

#import "MultiEPGTableView.h"


@implementation MultiEPGTableView

@synthesize lastTouch = _lastTouch;

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
	const UITouch *touch = [[event allTouches] anyObject];
	_lastTouch = [touch locationInView: self];
	[super touchesBegan:touches withEvent:event];
}

- (void)touchesCancelled:(NSSet*)touches withEvent:(UIEvent*)event
{
	_lastTouch = CGPointZero;
	[super touchesCancelled:touches withEvent:event];
}

@end
