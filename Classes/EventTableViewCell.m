//
//  EventTableViewCell.m
//  Untitled
//
//  Created by Moritz Venn on 09.03.08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "EventTableViewCell.h"

@interface EventTableViewCell()
- (UILabel *)newLabelWithPrimaryColor:(UIColor *)primaryColor selectedColor:(UIColor *)selectedColor fontSize:(CGFloat)fontSize bold:(BOOL)bold;
@end

@implementation EventTableViewCell

@synthesize eventNameLabel = _eventNameLabel;
@synthesize eventTimeLabel = _eventTimeLabel;


+ (void)initialize
{
	// TODO: anything to be done here?
}	

- (void)dealloc
{
	[super dealloc];
	
	[_eventNameLabel dealloc];
	[_eventTimeLabel dealloc];
}

- (id)initWithFrame:(CGRect)frame reuseIdentifier:(NSString *)reuseIdentifier
{
	if (self = [super initWithFrame:frame reuseIdentifier:reuseIdentifier]) {
		UIView *myContentView = self.contentView;
		
		// A label that displays the Eventname.
		self.eventNameLabel = [self newLabelWithPrimaryColor:[UIColor blackColor] selectedColor:[UIColor whiteColor] fontSize:14.0 bold:YES];
		self.eventNameLabel.textAlignment = UITextAlignmentLeft; // default
		[myContentView addSubview:self.eventNameLabel];
		[self.eventNameLabel release];
		
		// A label that displays the Eventtime.
		self.eventTimeLabel = [self newLabelWithPrimaryColor:[UIColor blackColor] selectedColor:[UIColor whiteColor] fontSize:10.0 bold:NO];
		self.eventTimeLabel.textAlignment = UITextAlignmentLeft; // default
		[myContentView addSubview:self.eventTimeLabel];
		[self.eventTimeLabel release];
	}
	
	return self;
}

- (Event *)event
{
	return _event;
}

- (void)setEvent:(Event *)newEvent
{
	[newEvent retain];
	[_event release];
	_event = newEvent;
	
	self.eventNameLabel.text = [newEvent title];
	NSDateFormatter *format = [[[NSDateFormatter alloc] init] autorelease];
	[format setDateStyle:NSDateFormatterMediumStyle];
	[format setTimeStyle:NSDateFormatterShortStyle];
	NSString *begin = [format stringFromDate: [_event begin]];
	[format setDateStyle:NSDateFormatterNoStyle];
	NSString *end = [format stringFromDate: [_event end]];
	self.eventTimeLabel.text = [NSString stringWithFormat: @"%@ - %@", begin, end];

	[self setNeedsDisplay];
}

- (void)layoutSubviews
{
#define COLUMN_X 5.0
#define MAX_WIDTH 305.0
	
	[super layoutSubviews];
	CGRect contentRect = self.contentView.bounds;
	
	// In this example we will never be editing, but this illustrates the appropriate pattern
	if (!self.editing) {
		CGFloat boundsX = contentRect.origin.x;
		CGRect frame;
		
		// Place the name label.
		frame = CGRectMake(boundsX + COLUMN_X, 7, MAX_WIDTH, 14);
		self.eventNameLabel.frame = frame;

		// Place the time label.
		frame = CGRectMake(boundsX + COLUMN_X, 30, MAX_WIDTH, 10);
		self.eventTimeLabel.frame = frame;
	}
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
	/*
	 Views are drawn most efficiently when they are opaque and do not have a clear background, so in newLabelForMainText: the labels are made opaque and given a white background.  To show selection properly,   |however, the views need to be transparent (so that the selection color shows through).  
	 */
	[super setSelected:selected animated:animated];
	
	UIColor *backgroundColor = nil;
	if (selected) {
		backgroundColor = [UIColor clearColor];
	} else {
		backgroundColor = [UIColor whiteColor];
	}
	
	self.eventNameLabel.backgroundColor = backgroundColor;
	self.eventNameLabel.highlighted = selected;
	self.eventNameLabel.opaque = !selected;
	
	self.eventTimeLabel.backgroundColor = backgroundColor;
	self.eventTimeLabel.highlighted = selected;
	self.eventTimeLabel.opaque = !selected;
}

- (UILabel *)newLabelWithPrimaryColor:(UIColor *)primaryColor selectedColor:(UIColor *)selectedColor fontSize:(CGFloat)fontSize bold:(BOOL)bold
{
	/*
	 Create and configure a label.
	 */
	
	UIFont *font;
	if (bold) {
		font = [UIFont boldSystemFontOfSize:fontSize];
	} else {
		font = [UIFont systemFontOfSize:fontSize];
	}
	
	/*
	 Views are drawn most efficiently when they are opaque and do not have a clear background, so set these defaults.  To show selection properly, however, the views need to be transparent (so that the	  |selection color shows through).  This is handled in setSelected:animated:.
	 */
	UILabel *newLabel = [[UILabel alloc] initWithFrame:CGRectZero];
	newLabel.backgroundColor = [UIColor whiteColor];
	newLabel.opaque = YES;
	newLabel.textColor = primaryColor;
	newLabel.highlightedTextColor = selectedColor;
	newLabel.font = font;
	
	return newLabel;
}

@end
