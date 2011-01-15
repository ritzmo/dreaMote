//
//  ServiceEventTableViewCell.m
//  dreaMote
//
//  Created by Moritz Venn on 15.01.11.
//  Copyright 2011 Moritz Venn. All rights reserved.
//

#import "Constants.h"
#import "ServiceEventTableViewCell.h"

/*!
 @brief Cell identifier for this cell.
 */
NSString *kServiceEventCell_ID = @"ServiceEventCell_ID";

/*!
 @brief Private functions of ServiceTableViewCell.
 */
@interface ServiceEventTableViewCell()
/*!
 @brief Private helper to create a label.
 */
- (UILabel *)newLabelWithPrimaryColor:(UIColor *) primaryColor selectedColor:(UIColor *) selectedColor fontSize:(CGFloat) fontSize bold:(BOOL) bold;
@end

@implementation ServiceEventTableViewCell

@synthesize formatter = _formatter;
@synthesize serviceNameLabel = _serviceNameLabel;

/* dealloc */
- (void)dealloc
{
	[_formatter release];
	[_next release];
	[_nextLabel release];
	[_nextTimeLabel release];
	[_now release];
	[_nowLabel release];
	[_serviceNameLabel release];
	[_nowTimeLabel release];

	[super dealloc];
}

/* initialize */
- (id)initWithFrame:(CGRect)frame reuseIdentifier:(NSString *)reuseIdentifier
{
#ifdef __IPHONE_3_0
	if((self = [super initWithStyle: UITableViewCellStyleDefault reuseIdentifier: reuseIdentifier]))
#else
	if((self = [super initWithFrame: frame reuseIdentifier: reuseIdentifier]))
#endif
	{
		const UIView *myContentView = self.contentView;

		// you can do this here specifically or at the table level for all cells
		self.accessoryType = UITableViewCellAccessoryDisclosureIndicator;

		// A label that displays the Servicename.
		_serviceNameLabel = [self newLabelWithPrimaryColor: [UIColor blackColor]
											 selectedColor: [UIColor whiteColor]
												  fontSize: kServiceEventServiceSize
													  bold: YES];
		_serviceNameLabel.textAlignment = UITextAlignmentLeft; // default
		[myContentView addSubview: _serviceNameLabel];

		// label that might be used to display currently playing event
		_nowLabel = [self newLabelWithPrimaryColor: [UIColor blackColor]
									 selectedColor: [UIColor whiteColor]
										  fontSize: kServiceEventEventSize
											  bold:	NO];
		[myContentView addSubview: _nowLabel];

		_nowTimeLabel = [self newLabelWithPrimaryColor: [UIColor blackColor]
									 selectedColor: [UIColor whiteColor]
										  fontSize: kServiceEventEventSize
											  bold:	NO];
		[myContentView addSubview: _nowTimeLabel];

		_nextLabel = [self newLabelWithPrimaryColor: [UIColor blackColor]
									 selectedColor: [UIColor whiteColor]
										  fontSize: kServiceEventEventSize
											  bold:	NO];
		[myContentView addSubview: _nextLabel];

		_nextTimeLabel = [self newLabelWithPrimaryColor: [UIColor blackColor]
									  selectedColor: [UIColor whiteColor]
										   fontSize: kServiceEventEventSize
											   bold:	NO];
		[myContentView addSubview: _nextTimeLabel];
	}

	return self;
}

/* getter for now property */
- (NSObject<EventProtocol> *)now
{
	return _now;
}

/* setter for service property */
- (void)setNow:(NSObject<EventProtocol> *)new
{
	// Abort if same event assigned
	if([_now isEqual:new]) return;

	// Free old event, assign new one
	[_now release];
	_now = [new retain];

	if(new.valid)
	{
		NSDate *beginDate = new.begin;
		const NSObject<ServiceProtocol> *service = new.service;
		const BOOL serviceValid = service.valid;

		// Check if valid event data
		if(beginDate)
		{
			// Check if cache already generated
			if(new.timeString == nil)
			{
				// Not generated, do so...
				[_formatter setDateStyle:NSDateFormatterNoStyle];
				const NSString *begin = [_formatter stringFromDate: beginDate];
				const NSString *end = [_formatter stringFromDate: new.end];
				if(begin && end)
					new.timeString = [NSString stringWithFormat: @"%@ - %@", begin, end];
			}

			_nowLabel.text = new.title;
			_nowTimeLabel.text = new.timeString;
		}
		else
		{
			if(serviceValid)
				_nowLabel.text = NSLocalizedString(@"No EPG", @"Placeholder text in Now/Next-ServiceList if no EPG data present");
			else
				_nowLabel.text = nil;

			_nowTimeLabel.text = nil;
		}
		_serviceNameLabel.text = service.sname;
		
		if(serviceValid)
			self.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
		else
			self.accessoryType = UITableViewCellAccessoryNone;
	}
	else
	{
		_serviceNameLabel.text = new.title;
		_nowLabel.text = nil;
		_nowTimeLabel.text = nil;
		_nextLabel.text = nil;
		_nextTimeLabel.text = nil;
	}

	[self setNeedsDisplay];
}

/* getter of next property */
- (NSObject<EventProtocol> *)next
{
	return _next;
}

/* setter of next property */
- (void)setNext:(NSObject<EventProtocol> *)new
{
	// Abort if same event assigned
	if([_next isEqual:new]) return;

	// Free old event, assign new one
	[_next release];
	_next = [new retain];

	NSDate *beginDate = new.begin;

	// Check if valid event data
	if(beginDate)
	{
		// Check if cache already generated
		if(new.timeString == nil)
		{
			// Not generated, do so...
			[_formatter setDateStyle:NSDateFormatterNoStyle];
			const NSString *begin = [_formatter stringFromDate: beginDate];
			const NSString *end = [_formatter stringFromDate: new.end];
			if(begin && end)
				new.timeString = [NSString stringWithFormat: @"%@ - %@", begin, end];
		}

		_nextLabel.text = new.title;
		_nextTimeLabel.text = new.timeString;
	}
	else
	{
		_nextLabel.text = nil;
		_nextTimeLabel.text = nil;
	}

	[self setNeedsDisplay];
}

/* layout */
- (void)layoutSubviews
{
	[super layoutSubviews];
	const CGRect contentRect = self.contentView.bounds;
	
	if(!_now.service.valid)
	{
		const CGRect frame = CGRectMake(kLeftMargin, (contentRect.size.height - kServiceEventServiceSize) / 2 , contentRect.size.width - kRightMargin, kServiceEventServiceSize + 5);
		_serviceNameLabel.frame = frame;
	}
	else
	{
		const NSInteger offset = (IS_IPAD()) ? 3 : 3;
		NSInteger timeWidth = 0;
		NSString *localeIdentifier = [[NSLocale componentsFromLocaleIdentifier:[[NSLocale currentLocale] localeIdentifier]] objectForKey:NSLocaleLanguageCode];
		if([localeIdentifier isEqualToString:@"de"])
			timeWidth = (IS_IPAD()) ? 100 : 80;
		else // tested for en_US
			timeWidth = (IS_IPAD()) ? 150 : 110;

		// Base frame
		CGRect frame = CGRectMake(kLeftMargin, 1, contentRect.size.width - kRightMargin, kServiceEventServiceSize + offset);
		_serviceNameLabel.frame = frame;

		frame.origin.y += frame.size.height;
		frame.size.width = timeWidth;
		frame.size.height = kServiceEventEventSize + offset;
		_nowTimeLabel.frame = frame;

		frame.origin.x += frame.size.width + 5;
		frame.size.width = contentRect.size.width - frame.origin.x - kRightMargin;
		_nowLabel.frame = frame;

		frame.origin.x = contentRect.origin.x + kLeftMargin;
		frame.origin.y += frame.size.height;
		frame.size.width = timeWidth;
		_nextTimeLabel.frame = frame;

		frame.origin.x += frame.size.width + 5;
		frame.size.width = contentRect.size.width - frame.origin.x - kRightMargin;
		_nextLabel.frame = frame;
	}
}

/* (de)select */
- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
	[super setSelected:selected animated:animated];

	_serviceNameLabel.highlighted = selected;
}

/* Create and configure a label. */
- (UILabel *)newLabelWithPrimaryColor:(UIColor *) primaryColor selectedColor:(UIColor *) selectedColor fontSize:(CGFloat) fontSize bold:(BOOL) bold
{
	UIFont *font;
	UILabel *newLabel;

	if (bold) {
		font = [UIFont boldSystemFontOfSize:fontSize];
	} else {
		font = [UIFont systemFontOfSize:fontSize];
	}

	newLabel = [[UILabel alloc] initWithFrame:CGRectZero];
	newLabel.backgroundColor = [UIColor clearColor];
	newLabel.opaque = NO;
	newLabel.textColor = primaryColor;
	newLabel.highlightedTextColor = selectedColor;
	newLabel.font = font;
	
	return newLabel;
}

@end
