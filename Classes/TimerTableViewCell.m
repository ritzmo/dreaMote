//
//  TimerTableViewCell.m
//  Untitled
//
//  Created by Moritz Venn on 09.03.08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "TimerTableViewCell.h"

#import "AppDelegateMethods.h"

@interface TimerTableViewCell()
- (UILabel *)newLabelWithPrimaryColor:(UIColor *)primaryColor selectedColor:(UIColor *)selectedColor fontSize:(CGFloat)fontSize bold:(BOOL)bold;
@end

@implementation TimerTableViewCell

@synthesize serviceNameLabel = _serviceNameLabel;
@synthesize timerNameLabel = _timerNameLabel;
@synthesize timerTimeLabel = _timerTimeLabel;


+ (void)initialize
{
	// TODO: anything to be done here?
}	

- (void)dealloc
{
	[super dealloc];
	
	[_serviceNameLabel dealloc];
	[_timerNameLabel dealloc];
	[_timerTimeLabel dealloc];
}

- (id)initWithFrame:(CGRect)frame reuseIdentifier:(NSString *)reuseIdentifier
{
	if (self = [super initWithFrame:frame reuseIdentifier:reuseIdentifier]) {
		UIView *myContentView = self.contentView;
		
		// A label that displays the Servicename.
		self.serviceNameLabel = [self newLabelWithPrimaryColor:[UIColor blackColor] selectedColor:[UIColor whiteColor] fontSize:14.0 bold:YES];
		self.serviceNameLabel.textAlignment = UITextAlignmentLeft; // default
		[myContentView addSubview:self.serviceNameLabel];
		[self.serviceNameLabel release];

		// A label that displays the Timername.
		self.timerNameLabel = [self newLabelWithPrimaryColor:[UIColor blackColor] selectedColor:[UIColor whiteColor] fontSize:12.0 bold:YES];
		self.timerNameLabel.textAlignment = UITextAlignmentLeft; // default
		[myContentView addSubview:self.timerNameLabel];
		[self.timerNameLabel release];

		// A label that displays the Timer time.
		self.timerTimeLabel = [self newLabelWithPrimaryColor:[UIColor blackColor] selectedColor:[UIColor whiteColor] fontSize:12.0 bold:NO];
		self.timerTimeLabel.textAlignment = UITextAlignmentLeft; // default
		[myContentView addSubview:self.timerTimeLabel];
		[self.timerTimeLabel release];
	}
	
	return self;
}

- (Timer *)timer
{
	return _timer;
}

- (void)setTimer:(Timer *)newTimer
{
	[newTimer retain];
	[_timer release];
	_timer = newTimer;
	
	self.serviceNameLabel.text = [[newTimer service] sname];
	self.timerNameLabel.text = [newTimer title];
	NSDateFormatter *format = [[[NSDateFormatter alloc] init] autorelease];
	[format setDateFormat: @"%d.%m. %H:%M"];
	self.timerTimeLabel.text = [NSString stringWithFormat: @"%@ - %@", [[format stringFromDate: [newTimer begin]] autorelease], [[format stringFromDate: [newTimer begin]] autorelease]];

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
		self.serviceNameLabel.frame = frame;

		// Place the other name label.
		frame = CGRectMake(boundsX + COLUMN_X, 26, MAX_WIDTH, 12);
		self.timerNameLabel.frame = frame;

		// Place the time label.
		frame = CGRectMake(boundsX + COLUMN_X, 41, MAX_WIDTH, 10);
		self.timerTimeLabel.frame = frame;
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
	
	self.serviceNameLabel.backgroundColor = backgroundColor;
	self.serviceNameLabel.highlighted = selected;
	self.serviceNameLabel.opaque = !selected;
	
	self.timerNameLabel.backgroundColor = backgroundColor;
	self.timerNameLabel.highlighted = selected;
	self.timerNameLabel.opaque = !selected;
	
	self.timerTimeLabel.backgroundColor = backgroundColor;
	self.timerTimeLabel.highlighted = selected;
	self.timerTimeLabel.opaque = !selected;
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
