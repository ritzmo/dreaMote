//
//  PlayListCell.m
//  dreaMote
//
//  Created by Moritz Venn on 29.05.11.
//  Copyright 2011 Moritz Venn. All rights reserved.
//

#import "PlayListCell.h"

#import "Constants.h"

// cell identifier for this custom cell
NSString *kPlayListCell_ID = @"PlayListCell_ID";

@implementation PlayListCell

@synthesize file;

- (void)setFile:(NSObject<FileProtocol> *)newFile
{
	if(file == newFile) return;
	file = newFile;
	[self setNeedsDisplay];
}

- (void)drawContentRect:(CGRect)contentRect
{
	[super drawContentRect:contentRect];
	CGFloat offsetX = contentRect.origin.x;
	const CGFloat boundsWidth = contentRect.size.width;
	const CGFloat boundsHeight = contentRect.size.height;

	DreamoteConfiguration *singleton = [DreamoteConfiguration singleton];
	UIFont *primaryFont = [UIFont boldSystemFontOfSize:singleton.textViewFontSize-1];
	UIColor *primaryColor = nil;
	if(self.highlighted)
	{
		primaryColor =  singleton.highlightedTextColor;
	}
	else
	{
		primaryColor =  singleton.textColor;
	}
	[primaryColor set];

	if(self.imageView.image)
		offsetX += self.imageView.image.size.width + kLeftMargin;

	CGPoint point = CGPointMake(offsetX + kLeftMargin, (boundsHeight - primaryFont.lineHeight) / 2);
	CGFloat forWidth = boundsWidth - offsetX;
	[file.title drawAtPoint:point forWidth:forWidth withFont:primaryFont lineBreakMode:UILineBreakModeTailTruncation];
}

@end
