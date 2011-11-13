//
//  FastTableViewCell.m
//  dreaMote
//
//  Created by Moritz Venn on 13.11.11.
//  Copyright (c) 2011 Moritz Venn. All rights reserved.
//

#import "FastTableViewCell.h"

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

- (void)layoutSubviews
{
	CGRect b = [self bounds];
	b.size.width += 30; // allow extra width to slide for editing
	b.origin.x -= (self.editing && !self.showingDeleteConfirmation) ? 0 : 30; // start 30px left unless editing
	[contentView setFrame:b];
    [super layoutSubviews];
}

- (void)drawContentRect:(CGRect)rect
{
	//
}

@end
