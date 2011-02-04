//
//  ZoomingScrollView.m
//  dreaMote
//
//  Created by Moritz Venn on 04.02.11.
//  Copyright 2011 Moritz Venn. All rights reserved.
//

#import "ZoomingScrollView.h"

@implementation ZoomingScrollView

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
	UITouch *touch = [touches anyObject];
	if([touch tapCount] == 2)
	{
		if(self.zoomScale > 1)
		{
			[self setZoomScale:1 animated:YES];
		}
		else
		{
			// zoom to center until i figure out how to zoom to point
			CGPoint point;
			point.x = self.contentSize.width / 2;
			point.y = self.contentSize.height / 2;
			[self setZoomScale:self.maximumZoomScale animated:YES];
			[self setContentOffset:point animated:NO];
		}
	}

	[super touchesEnded:touches withEvent:event];
}

@end
