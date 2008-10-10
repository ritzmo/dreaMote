//
//  EventViewController.m
//  Untitled
//
//  Created by Moritz Venn on 09.03.08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "EventViewController.h"

#import "TimerViewController.h"
#import "CellTextView.h"
#import "CellTextField.h"
#import "DisplayCell.h"
#import "Constants.h"

#import "FuzzyDateFormatter.h"

@interface EventViewController()
- (UILabel *)fieldLabelWithFrame:(CGRect)frame title:(NSString *)title;
@end

@implementation EventViewController

@synthesize event = _event;
@synthesize service = _service;

- (id)init
{
	if (self = [super init])
	{
		self.event = nil;
		self.title = NSLocalizedString(@"Event", @"");
	}
	
	return self;
}

+ (EventViewController *)withEvent: (Event *) newEvent
{
	EventViewController *eventViewController = [[EventViewController alloc] init];

	eventViewController.event = newEvent;
	eventViewController.title = newEvent.title;
	eventViewController.service = [[Service alloc] init];
	
	return eventViewController;
}

+ (EventViewController *)withEventAndService: (Event *) newEvent: (Service *) newService
{
	EventViewController *eventViewController = [[EventViewController alloc] init];

	eventViewController.event = newEvent;
	eventViewController.title = newEvent.title;
	eventViewController.service = newService;
	
	return eventViewController;
}

- (void)dealloc
{
	[_event release];
	[_service release];

	[super dealloc];
}

- (void)loadView
{
	// create and configure the table view
	UITableView *tableView = [[UITableView alloc] initWithFrame:[[UIScreen mainScreen] applicationFrame] style:UITableViewStyleGrouped];	
	tableView.delegate = self;
	tableView.dataSource = self;

	// setup our content view so that it auto-rotates along with the UViewController
	tableView.autoresizesSubviews = YES;
	tableView.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);

	self.view = tableView;
	[tableView release];
}

- (void)addTimer: (id)sender
{
	TimerViewController *targetViewController = [TimerViewController withEventAndService: _event: _service];
	[self.navigationController pushViewController: targetViewController animated: YES];
	[targetViewController release];
}

- (UILabel *)fieldLabelWithFrame:(CGRect)frame title:(NSString *)title
{
	UILabel *label = [[[UILabel alloc] initWithFrame:frame] autorelease];
	
	label.textAlignment = UITextAlignmentLeft;
	label.text = title;
	label.font = [UIFont boldSystemFontOfSize:17.0];
	label.textColor = [UIColor colorWithRed:76.0/255.0 green:86.0/255.0 blue:108.0/255.0 alpha:1.0];
	label.backgroundColor = [UIColor clearColor];
	
	return label;
}

- (UITextView *)create_Summary
{
	CGRect frame = CGRectMake(0, 0, 100, kTextViewHeight);
	UITextView *myTextView = [[[UITextView alloc] initWithFrame:frame] autorelease];
	myTextView.textColor = [UIColor blackColor];
	myTextView.font = [UIFont fontWithName:kFontName size:kTextViewFontSize];
	myTextView.delegate = self;
	myTextView.editable = NO;
	myTextView.backgroundColor = [UIColor whiteColor];
	
	// We display short description (or title) and extended description (if available) in our textview
	NSMutableString *text = [[NSMutableString alloc] init];
	if([_event.sdescription length])
	{
		[text appendString: _event.sdescription];
	}
	else
	{
		[text appendString: _event.title];
	}
	
	if([_event.edescription length])
	{
		[text appendString: @"\n\n"];
		[text appendString: _event.edescription];
	}
	
	myTextView.text = text;

	[text release];
	
	return myTextView;
}

- (NSString *)format_BeginEnd: (NSDate *)dateTime
{
	// Date Formatter
	FuzzyDateFormatter *format = [[[FuzzyDateFormatter alloc] init] autorelease];
	[format setDateStyle:NSDateFormatterMediumStyle];
	[format setTimeStyle:NSDateFormatterShortStyle];
	
	return [format stringFromDate: dateTime];
}

- (UIButton *)create_AddTimerButton
{
	UIButton *button = [UIButton buttonWithType:UIButtonTypeContactAdd];
	button.frame = CGRectMake(0.0, 0.0, 25.0, 25.0);
	[button addTarget:self action:@selector(addTimer:) forControlEvents:UIControlEventTouchUpInside];
	
	return button;
}

#pragma mark UITextView delegate methods

- (void)textViewDidBeginEditing:(UITextView *)textView
{
	// we don't allow editing
}

- (void)saveAction:(id)sender
{
	// we don't allow editing
}

#pragma mark - UITableView delegates

// if you want the entire table to just be re-orderable then just return UITableViewCellEditingStyleNone
//
- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
	return UITableViewCellEditingStyleNone;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return 4;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
	switch (section) {
		case 0:
			return NSLocalizedString(@"Description", @"");
		case 1:
			return NSLocalizedString(@"Begin", @"");
		case 2:
			return NSLocalizedString(@"End", @"");
		default:
			return nil;
	}
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	return 1;
}

// to determine specific row height for each cell, override this.  In this example, each row is determined
// buy the its subviews that are embedded.
//
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	CGFloat result;

	switch (indexPath.section)
	{
		case 0:
		{
			result = kTextViewHeight;
			break;
		}
		case 1:
		case 2:
		{
			result = kTextFieldHeight;
			break;
		}
		case 3:
		{
			result = kUIRowHeight;
			break;
		}
	}
	
	return result;
}

// to determine which UITableViewCell to be used on a given row.
//
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	static NSString *kVanilla_ID = @"Vanilla_ID";
		
	NSInteger section = indexPath.section;
	UITableViewCell *sourceCell = nil;
	
	// we are creating a new cell, setup its attributes
	switch (section) {
		case 0:
			sourceCell = [tableView dequeueReusableCellWithIdentifier:kCellTextView_ID];
			if(sourceCell == nil)
				sourceCell = [[[CellTextView alloc] initWithFrame:CGRectZero reuseIdentifier:kCellTextView_ID] autorelease];
			
			((CellTextView *)sourceCell).view = [self create_Summary];
			break;
		case 1:
		case 2:
			sourceCell = [tableView dequeueReusableCellWithIdentifier: kVanilla_ID];
			if (sourceCell == nil) 
				sourceCell = [[[UITableViewCell alloc] initWithFrame: CGRectZero reuseIdentifier: kVanilla_ID] autorelease];
			
			sourceCell.textAlignment = UITextAlignmentCenter;
			sourceCell.textColor = [UIColor blackColor];
			sourceCell.font = [UIFont systemFontOfSize:kTextViewFontSize];
			sourceCell.selectionStyle = UITableViewCellSelectionStyleNone;
			
			sourceCell.text = (section == 1) ? [self format_BeginEnd: _event.begin] : [self format_BeginEnd: _event.end];
			break;
		case 3:
			sourceCell = [tableView dequeueReusableCellWithIdentifier:kDisplayCell_ID];
			if(sourceCell == nil)
				sourceCell = [[[DisplayCell alloc] initWithFrame:CGRectZero reuseIdentifier:kDisplayCell_ID] autorelease];

			((DisplayCell *)sourceCell).nameLabel.text = NSLocalizedString(@"Add Timer", @"");
			((DisplayCell *)sourceCell).view = [self create_AddTimerButton];
		default:
			break;
	}
	
	return sourceCell;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	// Return YES for supported orientations
	return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

@end
