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
		contentView = [[FastCellContentView alloc] initWithFrame:self.bounds];
		contentView.backgroundColor = [UIColor clearColor];
		contentView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
		contentView.contentMode = UIViewContentModeRedraw;
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

- (void)drawContentRect:(CGRect)rect
{
	//
}

@end
