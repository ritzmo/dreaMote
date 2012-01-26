//
//  AutoTimerFilterViewController.m
//  dreaMote
//
//  Created by Moritz Venn on 31.03.11.
//  Copyright 2011-2012 Moritz Venn. All rights reserved.
//

#import "AutoTimerFilterViewController.h"

#import "Constants.h"
#import "UITableViewCell+EasyInit.h"

#import <TableViewCell/BaseTableViewCell.h>

@interface AutoTimerFilterViewController()
/*!
 @brief stop editing
 @param sender ui element
 */
- (void)cancelEdit:(id)sender;

/*!
 @brief done editing
 */
- (void)doneAction:(id)sender;

/*!
 @brief Animate View up or down.
 Animate the entire view up or down, to prevent the keyboard from covering the text field.

 @param movedUp YES if moving down again.
 */
- (void)setViewMovedUp:(BOOL)movedUp;
@end

@implementation AutoTimerFilterViewController

@synthesize callback;
@synthesize tableView = _tableView;

/*!
 @brief Keyboard offset.
 The amount of vertical shift upwards to keep the text field in view as the keyboard appears.
 */
#define kOFFSET_FOR_KEYBOARD					100

/*! @brief The duration of the animation for the view shift. */
#define kVerticalOffsetAnimationDuration		(CGFloat)0.30

/* initialize */
- (id)init
{
	if((self = [super init]))
	{
		self.title = NSLocalizedString(@"Filter", @"Default title of AutoTimerFilterViewController");

		self.modalPresentationStyle = UIModalPresentationFormSheet;
		self.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
	}
	return self;
}

- (NSString *)currentText
{
	return currentText;
}

- (void)setCurrentText:(NSString *)newText
{
	if(currentText == newText) return;

	currentText = newText;

	oldText = newText;

	filterTextfield.text = newText;
	[_tableView reloadData];
}

- (BOOL)include
{
	return include;
}

- (void)setInclude:(BOOL)newInclude
{
	oldInclude = newInclude;

	if(include == newInclude) return;
	include = newInclude;
	[_tableView reloadData];
}

- (autoTimerWhereType)filterType
{
	return filterType;
}

- (void)setFilterType:(autoTimerWhereType)newFilterType
{
	if(filterType == newFilterType) return;
	filterType = newFilterType;
	[_tableView reloadData];
}

/* layout */
- (void)loadView
{
	// create and configure the table view
	_tableView = [[UITableView alloc] initWithFrame:[[UIScreen mainScreen] applicationFrame] style:UITableViewStyleGrouped];	
	_tableView.delegate = self;
	_tableView.dataSource = self;
	_tableView.rowHeight = kUIRowHeight;
	_tableView.autoresizesSubviews = YES;
	_tableView.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
	if(IS_IPAD())
		_tableView.backgroundView = [[UIView alloc] init];

	self.view = _tableView;

	_cancelButtonItem = [[UIBarButtonItem alloc]
						 initWithBarButtonSystemItem: UIBarButtonSystemItemCancel
						 target: self
						 action: @selector(cancelEdit:)];
	self.navigationItem.leftBarButtonItem = _cancelButtonItem;

	UIBarButtonItem *button = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
																			target:self action:@selector(doneAction:)];
	self.navigationItem.rightBarButtonItem = button;

	filterTextfield = [[UITextField alloc] initWithFrame:CGRectZero];
	filterTextfield.text = currentText;
	filterTextfield.leftView = nil;
	filterTextfield.leftViewMode = UITextFieldViewModeNever;
	filterTextfield.borderStyle = UITextBorderStyleRoundedRect;
	filterTextfield.textColor = [UIColor blackColor];
	filterTextfield.font = [UIFont systemFontOfSize:kTextFieldFontSize];
	filterTextfield.backgroundColor = [UIColor whiteColor];
	filterTextfield.autocorrectionType = UITextAutocorrectionTypeNo;
	filterTextfield.keyboardType = UIKeyboardTypeDefault;
	filterTextfield.returnKeyType = UIReturnKeyDone;
	filterTextfield.clearButtonMode = UITextFieldViewModeWhileEditing;
	filterTextfield.placeholder = NSLocalizedStringFromTable(@"<filter text>", @"AutoTimer", @"Placeholder of Textfield in Filter Editor");

	[self theme];
}

- (void)viewDidUnload
{
	_cancelButtonItem = nil;
	filterTextfield = nil;
	_tableView = nil;

	[super viewDidUnload];
}

/* cancel */
- (void)cancelEdit:(id)sender
{
	autotimerfilter_callback_t call = callback;
	callback = nil;
	if(call)
		call(NO, nil, filterType, include, oldText, oldInclude);
}

/* finish */
- (void)doneAction:(id)sender
{
	autotimerfilter_callback_t call = callback;
	callback = nil;
	if(call)
	{
		__unsafe_unretained NSString *text = nil;

		if(filterType == autoTimerWhereDayOfWeek)
			text = currentText;
		else
			text = filterTextfield.text;

		if([text isEqualToString:@""])
			text = nil;

		call(YES, text, filterType, include, oldText, oldInclude);
	}
}

/* rotate with device */
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	return YES;
}

#pragma mark - UITableView delegates

/* title for section */
- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
	return nil;
}

/* number of sections */
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return 2;
}

/* number of rows */
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	if(section == 0)
		return 2;

	if(filterType == autoTimerWhereDayOfWeek)
		return 9;
	return 1;
}

/* to determine which UITableViewCell to be used on a given row. */
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	UITableViewCell *cell = nil;

	if(indexPath.section == 0)
	{
		cell = [BaseTableViewCell reusableTableViewCellInView:tableView withIdentifier:kBaseCell_ID];
		if(indexPath.row == 0)
		{
			cell.textLabel.text = NSLocalizedStringFromTable(@"Include", @"AutoTimer", @"Include Filter");
			cell.accessoryType = include ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
		}
		else
		{
			cell.textLabel.text = NSLocalizedStringFromTable(@"Exclude", @"AutoTimer", @"Exclude Filter");
			cell.accessoryType = include ? UITableViewCellAccessoryNone : UITableViewCellAccessoryCheckmark;
		}
	}
	else if(filterType == autoTimerWhereDayOfWeek)
	{
		cell = [BaseTableViewCell reusableTableViewCellInView:tableView withIdentifier:kBaseCell_ID];
		switch(indexPath.row)
		{
			case 0:
				cell.textLabel.text = NSLocalizedString(@"Monday", @"");
				cell.accessoryType = [currentText isEqualToString:@"0"] ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
				break;
			case 1:
				cell.textLabel.text = NSLocalizedString(@"Tuesday", @"");
				cell.accessoryType = [currentText isEqualToString:@"1"] ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
				break;
			case 2:
				cell.textLabel.text = NSLocalizedString(@"Wednesday", @"");
				cell.accessoryType = [currentText isEqualToString:@"2"] ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
				break;
			case 3:
				cell.textLabel.text = NSLocalizedString(@"Thursday", @"");
				cell.accessoryType = [currentText isEqualToString:@"3"] ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
				break;
			case 4:
				cell.textLabel.text = NSLocalizedString(@"Friday", @"");
				cell.accessoryType = [currentText isEqualToString:@"4"] ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
				break;
			case 5:
				cell.textLabel.text = NSLocalizedString(@"Saturday", @"");
				cell.accessoryType = [currentText isEqualToString:@"5"] ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
				break;
			case 6:
				cell.textLabel.text = NSLocalizedString(@"Sunday", @"");
				cell.accessoryType = [currentText isEqualToString:@"6"] ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
				break;
			case 7:
				cell.textLabel.text = NSLocalizedStringFromTable(@"Sat-Sun", @"AutoTimer", @"weekday filter");
				cell.accessoryType = [currentText isEqualToString:@"weekend"] ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
				break;
			case 8:
				cell.textLabel.text = NSLocalizedStringFromTable(@"Mon-Fri", @"AutoTimer", @"weekday filter");
				cell.accessoryType = [currentText isEqualToString:@"weekday"] ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
				break;
			default:
				break;
		}
	}
	else 
	{
		cell = [CellTextField reusableTableViewCellInView:tableView withIdentifier:kCellTextField_ID];
		((CellTextField *)cell).delegate = self;
		((CellTextField *)cell).view = filterTextfield;
	}

	[[DreamoteConfiguration singleton] styleTableViewCell:cell inTableView:tableView];
	return cell;
}

/* row selected */
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
	UITableViewCell *cell = nil;

	if(indexPath.section == 0)
	{
		// nothing changed
		if((include && indexPath.row == 0) || (!include && indexPath.row == 1)) return;

		cell = [tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:include?0:1 inSection:0]];
		include = !include;
	}
	else if(filterType == autoTimerWhereDayOfWeek)
	{
		NSInteger selectedItem;
		if([currentText isEqualToString:@"weekend"])
			selectedItem = 7;
		else if([currentText isEqualToString:@"weekday"])
			selectedItem = 8;
		else
			selectedItem = [currentText integerValue];

		if(indexPath.row == 7)
			currentText = @"weekend";
		else if(indexPath.row == 8)
			currentText = @"weekday";
		else
			currentText = [NSString stringWithFormat:@"%d", indexPath.row];

		cell = [tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:selectedItem inSection:1]];
	}

	if(cell)
	{
		cell.accessoryType = UITableViewCellAccessoryNone;

		cell = [tableView cellForRowAtIndexPath:indexPath];
		cell.accessoryType = UITableViewCellAccessoryCheckmark;
	}
}

#pragma mark -
#pragma mark <EditableTableViewCellDelegate> Methods and editing management
#pragma mark -

- (BOOL)cellShouldBeginEditing:(EditableTableViewCell *)cell
{
	return YES;
}

- (void)cellDidEndEditing:(EditableTableViewCell *)cell
{
	// Restore the position of the main view if it was animated to make room for the keyboard.
	if(self.view.frame.origin.y < 0)
		[self setViewMovedUp:NO];
}

// Animate the entire view up or down, to prevent the keyboard from covering the author field.
- (void)setViewMovedUp:(BOOL)movedUp
{
	[UIView beginAnimations:nil context:NULL];
	[UIView setAnimationDuration:kVerticalOffsetAnimationDuration];
	// Make changes to the view's frame inside the animation block. They will be animated instead
	// of taking place immediately.
	CGRect rect = self.view.frame;
	if (movedUp)
	{
		// If moving up, not only decrease the origin but increase the height so the view 
		// covers the entire screen behind the keyboard.
		rect.origin.y -= kOFFSET_FOR_KEYBOARD;
		rect.size.height += kOFFSET_FOR_KEYBOARD;
	}
	else
	{
		// If moving down, not only increase the origin but decrease the height.
		rect.origin.y += kOFFSET_FOR_KEYBOARD;
		rect.size.height -= kOFFSET_FOR_KEYBOARD;
	}
	self.view.frame = rect;

	[UIView commitAnimations];
}

- (void)keyboardWillShow:(NSNotification *)notif
{
	// The keyboard will be shown. If the user is editing the description, adjust the display so
	// that the description field will not be covered by the keyboard.
	if(IS_IPHONE())
	{
		if(self.view.frame.origin.y >= 0)
			[self setViewMovedUp:YES];
		else if(self.view.frame.origin.y < 0)
			[self setViewMovedUp:NO];
	}
}

#pragma mark -
#pragma mark UIViewController delegate methods
#pragma mark -

- (void)viewWillAppear:(BOOL)animated
{
	// watch the keyboard so we can adjust the user interface if necessary.
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(keyboardWillShow:)
												 name:UIKeyboardWillShowNotification
											   object:self.view.window];
}

- (void)viewWillDisappear:(BOOL)animated
{
	// unregister for keyboard notifications while not visible.
	[[NSNotificationCenter defaultCenter] removeObserver:self
													name:UIKeyboardWillShowNotification
												  object:nil];
}

@end
