//
//  FastTableViewCell.m
//  dreaMote
//
//  Created by Moritz Venn on 13.11.11.
//  Copyright (c) 2011 Moritz Venn. All rights reserved.
//

#import "FastTableViewCell.h"

#import <QuartzCore/QuartzCore.h>

@interface FastCellContentView : UIView
@end

@implementation FastCellContentView
- (void)setFrame:(CGRect)newFrame
{
	if(!CGRectEqualToRect(self.frame, newFrame))
	{
		[super setFrame:newFrame];
		[self setNeedsDisplay];
	}
}
- (void)drawRect:(CGRect)rect
{
	[(FastTableViewCell *)[self superview] drawContentRect:rect];
}
@end

@interface FastTableViewCell()
@property (nonatomic, strong) FastCellContentView *contentView;
@end

@implementation FastTableViewCell

@synthesize contentView;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
	if((self = [super initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseIdentifier]))
	{
		contentView = [[FastCellContentView alloc] initWithFrame:CGRectZero];
		contentView.backgroundColor = [UIColor clearColor];
		contentView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
		contentView.contentMode = UIViewContentModeLeft;
		[self addSubview:contentView];
	}
	return self;
}

// TODO: forward background, so we can make the view opaque

- (void)setNeedsDisplay
{
	[super setNeedsDisplay];
	[contentView setNeedsDisplay];
}

- (void)setHighlighted:(BOOL)highlighted animated:(BOOL)animated
{
	if(highlighted != self.highlighted)
	{
		[super setHighlighted:highlighted animated:animated];
		if(highlighted != self.selected)
			[self setNeedsDisplay];
	}
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
	if(selected != self.selected)
	{
		[super setSelected:selected animated:animated];
		if(selected == self.highlighted)
			[self setNeedsDisplay];
	}
}

- (void)addSublayer:(CALayer *)layer
{
	[contentView.layer addSublayer:layer];
}

- (void)drawContentRect:(CGRect)rect
{
	//
}

@end
