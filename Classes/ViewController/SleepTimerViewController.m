//
//  SleepTimerViewController.m
//  dreaMote
//
//  Created by Moritz Venn on 02.06.11.
//  Copyright 2011 Moritz Venn. All rights reserved.
//

#import "SleepTimerViewController.h"

#import "DatePickerController.h"

#import "RemoteConnectorObject.h"
#import "Constants.h"

#import "DisplayCell.h"

#import "UITableViewCell+EasyInit.h"

enum generalSectionItems
{
	enabledRow = 0,
	timeRow,
	actionRow,
	maxRow,
};

/*!
 @brief Private functions of SleepTimerViewController.
 */
@interface SleepTimerViewController()
/*!
 @brief stop editing
 @param sender ui element
 */
- (void)cancelEdit:(id)sender;

@property (nonatomic, strong) SleepTimer *settings;
@end

@implementation SleepTimerViewController

@synthesize settings;

- (id)init
{
	if((self = [super init]))
	{
		self.title = NSLocalizedString(@"Sleep Timer", @"Default title of SleepTimerViewController");
	}
	return self;
}


#pragma mark -
#pragma mark Helper methods
#pragma mark -

- (UITextField *)allocTextField
{
	UITextField *returnTextField = [[UITextField alloc] initWithFrame:CGRectZero];
	
	returnTextField.leftView = nil;
	returnTextField.leftViewMode = UITextFieldViewModeNever;
	returnTextField.borderStyle = UITextBorderStyleRoundedRect;
	returnTextField.textColor = [UIColor blackColor];
	returnTextField.font = [UIFont systemFontOfSize:kTextFieldFontSize];
	returnTextField.backgroundColor = [UIColor whiteColor];
	// no auto correction support
	returnTextField.autocorrectionType = UITextAutocorrectionTypeNo;

	// NOTE: number pad does not have dismiss button on the iphone...
	if(IS_IPAD())
		returnTextField.keyboardType = UIKeyboardTypeNumberPad;
	returnTextField.returnKeyType = UIReturnKeyDone;

	// has a clear 'x' button to the right
	returnTextField.clearButtonMode = UITextFieldViewModeWhileEditing;

	return returnTextField;
}

- (UITextField *)newTimeField
{
	UITextField *field = [self allocTextField];
	field.text = [NSString stringWithFormat:@"%d", settings.time];
	field.placeholder = NSLocalizedString(@"<min.>", @"Placeholder for SleepTimer duration field");
	return field;
}

#pragma mark -
#pragma mark UView
#pragma mark -

- (void)loadView
{
	[super loadGroupedTableView];
	_tableView.delegate = self;
	_tableView.dataSource = self;
	_tableView.rowHeight = kUIRowHeight;
	_tableView.allowsSelectionDuringEditing = YES;

	_cancelButtonItem = [[UIBarButtonItem alloc]
						initWithBarButtonSystemItem: UIBarButtonSystemItemCancel
						target: self
						action: @selector(cancelEdit:)];

	self.navigationItem.leftBarButtonItem = _cancelButtonItem;
	self.navigationItem.rightBarButtonItem = self.editButtonItem;

	_time = [self newTimeField];

	// enabled
	_enabled = [[UISwitch alloc] initWithFrame:CGRectMake(0, 0, 300, kSwitchButtonHeight)];
	_enabled.on = settings.enabled;
	_enabled.backgroundColor = [UIColor clearColor];

	// shutdown after refresh
	_shutdown = [[UISwitch alloc] initWithFrame:CGRectMake(0, 0, 300, kSwitchButtonHeight)];
	_shutdown.on = settings.action == sleeptimerShutdown;
	_shutdown.backgroundColor = [UIColor clearColor];

	[self setEditing:YES animated:YES];
}

- (void)viewDidUnload
{
	_cancelButtonItem = nil;
	_time = nil;
	_timeCell = nil; // references _time
	_enabled = nil;
	_shutdown = nil;

	[super viewDidUnload];
}

#pragma mark -
#pragma mark UIViewController
#pragma mark -

- (void)setEditing:(BOOL)editing animated:(BOOL)animated
{
	if(editing)
	{
		self.navigationItem.leftBarButtonItem = _cancelButtonItem;
	}
	else if(_shouldSave)
	{
		settings.enabled = _enabled.on;
		settings.action = _shutdown.on ? sleeptimerShutdown : sleeptimerStandby;
		settings.time = [_time.text integerValue];

		_expectReturn = YES;
		[[RemoteConnectorObject sharedRemoteConnector] setSleepTimerSettings:settings delegate:self];

		// NOTE: don't end editing here, we wait for the asynchronous callback
		editing = YES;

		self.navigationItem.leftBarButtonItem = nil;
	}
	else
	{
		self.navigationItem.leftBarButtonItem = nil;
	}

	_shouldSave = editing;
	[super setEditing: editing animated: animated];
	[_tableView reloadData];
}

- (void)cancelEdit:(id)sender
{
	_shouldSave = NO;
	[self setEditing:NO animated:YES];
	[self.navigationController popViewControllerAnimated:YES];
}

/* rotate with device */
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return YES;
}

- (void)emptyData
{
	[_tableView reloadData];
}

- (void)fetchData
{
	_reloading = YES;
	[[RemoteConnectorObject sharedRemoteConnector] getSleepTimerSettings:self];
}

#pragma mark -
#pragma mark SleepTimerSourceDelegate
#pragma mark -

- (void)addSleepTimer:(SleepTimer *)anItem
{
	if(_expectReturn)
	{
		// enabled differs -> assume error and show message
		if(settings.enabled != anItem.enabled)
		{
			const UIAlertView *notification = [[UIAlertView alloc]
											   initWithTitle:NSLocalizedString(@"Error", @"")
											   message:settings.text
											   delegate:nil
											   cancelButtonTitle:@"OK"
											   otherButtonTitles:nil];
			[notification show];
		}
		else
		{
			_shouldSave = NO;
			[self setEditing:NO animated:YES];
		}
		_expectReturn = NO;
	}
	self.settings = anItem;
	_enabled.on = settings.enabled;
	_shutdown.on = settings.action == sleeptimerShutdown;
	_time.text = [NSString stringWithFormat:@"%d", settings.time];
}

#pragma mark -
#pragma mark UITableView delegates
#pragma mark -

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
	return NSLocalizedString(@"General", @"in timer settings dialog");
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	return maxRow;
}

// to determine which UITableViewCell to be used on a given row.
//
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	NSUInteger row = indexPath.row;
	UITableViewCell *cell = nil;

	switch(row)
	{
		case enabledRow:
			cell = [DisplayCell reusableTableViewCellInView:tableView withIdentifier:kDisplayCell_ID];
			((DisplayCell *)cell).view = _enabled;
			cell.textLabel.text = NSLocalizedString(@"Enabled", @"");
			break;
		case timeRow:
			// TODO: wtf is going wrong here? can't reuse the same cell (disappears), so for now just work around this
			{
				_timeCell = [[CellTextField alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
				_timeCell.view = _time;
				_timeCell.textLabel.font = [UIFont systemFontOfSize:kTextViewFontSize];
				_timeCell.textLabel.text = NSLocalizedString(@"Duration", @"SleepTimer Duration Cell Label");
				_timeCell.fixedWidth = 94.0f;
			}
			cell = _timeCell;
			break;
		case actionRow:
			cell = [DisplayCell reusableTableViewCellInView:tableView withIdentifier:kDisplayCell_ID];
			((DisplayCell *)cell).view = _shutdown;
			cell.textLabel.text = NSLocalizedString(@"Shutdown", @"Toggle Shutdown/Standby of SleepTimer");
			break;
		default: break;
	}
	return cell;
}

#pragma mark -
#pragma mark <EditableTableViewCellDelegate> Methods and editing management
#pragma mark -

- (BOOL)cellShouldBeginEditing:(EditableTableViewCell *)cell
{
	if(![cell isEqual:_timeCell])
		[_timeCell stopEditing];
	return self.editing;
}

- (void)cellDidEndEditing:(EditableTableViewCell *)cell
{
	//
}

- (void)keyboardWillShow:(NSNotification *)notif
{
	NSIndexPath *indexPath;
	UITableViewScrollPosition scrollPosition = UITableViewScrollPositionMiddle;
	if(_timeCell.isInlineEditing)
		indexPath = [NSIndexPath indexPathForRow:timeRow inSection:0];
	else return;

	if(UIInterfaceOrientationIsLandscape(self.interfaceOrientation))
		scrollPosition = UITableViewScrollPositionTop;
	[_tableView scrollToRowAtIndexPath:indexPath atScrollPosition:scrollPosition animated:YES];
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

	[self setEditing:YES animated:YES];
	[self emptyData];
	[RemoteConnectorObject queueInvocationWithTarget:self selector:@selector(fetchData)];
}

- (void)viewWillDisappear:(BOOL)animated
{
	// unregister for keyboard notifications while not visible.
	[[NSNotificationCenter defaultCenter] removeObserver:self
													name:UIKeyboardWillShowNotification
												  object:nil];
}

@end
