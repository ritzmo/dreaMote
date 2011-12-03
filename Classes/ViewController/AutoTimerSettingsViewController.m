//
//  AutoTimerSettingsViewController.m
//  dreaMote
//
//  Created by Moritz Venn on 03.12.11.
//  Copyright (c) 2011 Moritz Venn. All rights reserved.
//

#import "AutoTimerSettingsViewController.h"

#import <Constants.h>

#import <Categories/UIDevice+SystemVersion.h>
#import <Categories/UITableViewCell+EasyInit.h>

#import <Connector/RemoteConnectorObject.h>

#import <ListController/SimpleSingleSelectionListController.h>

#import <Objects/Generic/Result.h>

#import <TableViewCell/BaseTableViewCell.h>
#import <TableViewCell/DisplayCell.h>

@interface AutoTimerSettingsViewController()
- (void)cancelEdit:(id)sender;
- (void)keyboardWillShow:(NSNotification *)notif;
@property (nonatomic, strong) NSArray *refreshTexts;
@property (nonatomic, strong) NSArray *editorTexts;
@end

enum sectionItems
{
	autopollRow = 0,
	intervalRow,
	try_guessingRow,
	refreshRow,
	editorRow,
	disabled_on_conflictRow,
	addsimilar_on_conflictRow,
	show_in_extensionsmenuRow,
	fastscanRow,
	notifconflictRow,
	notifSimilarRow,
	maxdaysRow,
	maxRow,
};

@implementation AutoTimerSettingsViewController

@synthesize settings, willReappear;
@synthesize refreshTexts, editorTexts;

- (id)init
{
	if((self = [super init]))
	{
		self.title = NSLocalizedStringFromTable(@"Settings", @"AutoTimer", @"Default title of AutoTimerSettingsViewController");

		if(refreshTexts == nil)
		{
			refreshTexts = [[NSArray alloc] initWithObjects:
							NSLocalizedStringFromTable(@"None", @"AutoTimer", @"Type of timers to modify: None"),
							NSLocalizedStringFromTable(@"AutoTimers", @"AutoTimer", @"Type of timers to modify: Only AutoTimers created during this session"),
							NSLocalizedStringFromTable(@"All timers", @"AutoTimer", @"Type of timers to modify: All timers"),
							nil ];
		}
		if(editorTexts == nil)
		{
			editorTexts = [[NSArray alloc] initWithObjects:
						   NSLocalizedStringFromTable(@"Classic", @"AutoTimer", @"Editor Type: Regular Editor"),
						   NSLocalizedStringFromTable(@"Wizard", @"AutoTimer", @"Editor Type: Wizard"),
						   nil];
		}
	}
	return self;
}

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

- (UITextField *)newIntervalField
{
	UITextField *field = [self allocTextField];
	field.text = [NSString stringWithFormat:@"%d", settings.interval];
	field.placeholder = NSLocalizedStringFromTable(@"<hours>", @"AutoTimer", @"Placeholder for interval field in AutoTimer settings (time in hours between automated polling)");
	return field;
}

- (UITextField *)newMaxdaysField
{
	UITextField *field = [self allocTextField];
	field.text = [NSString stringWithFormat:@"%d", settings.maxdays];
	field.placeholder = NSLocalizedStringFromTable(@"<days>", @"AutoTimer", @"Placeholder for maxdays field in AutoTimer settings (add timer for days on the next X days)");
	return field;
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated
{
	if(editing)
	{
		/*!
		 @note don't show cancel button on ipad, it should be clear that unless you confirm
		 the changes through the "done" button they are not applied. on the iphone however
		 we might be deeper into the navigation stack and therefore have a back button there
		 that we prefer to override. the ipad either has no button or the popover button
		 which we'd rather keep.
		 */
		if(IS_IPHONE())
		{
			self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc]
													 initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
													 target:self
													 action:@selector(cancelEdit:)];
		}
	}
	else if(_shouldSave)
	{
		NSString *message = nil;

		settings.autopoll = _autopoll.on;
		settings.interval = [_interval.text integerValue];
		if(settings.autopoll && settings.interval <= 0)
		{
			message = NSLocalizedStringFromTable(@"Automated Search for events requires a valid interval to be set!", @"AutoTimer", @"User requested autopoll but interval is equal to or less than 0.");
		}

		settings.try_guessing = _try_guessing.on;
		settings.disabled_on_conflict = _disabled_on_conflict.on;
		settings.addsimilar_on_conflict = _addsimilar_on_conflict.on;
		settings.show_in_extensionsmenu = _show_in_extensionsmenu.on;
		settings.fastscan = _fastscan.on;
		settings.notifconflict = _notifconflict.on;
		settings.notifsimilar = _notifsimilar.on;
		settings.maxdays = [_maxdays.text integerValue];

		if(settings.maxdays < 0)
		{
			message = NSLocalizedStringFromTable(@"", @"AutoTimer", @"");
		}

		// Try to commit changes if no error occured
		if(!message)
		{
			Result *result = [[RemoteConnectorObject sharedRemoteConnector] setAutoTimerSettings:settings];
			if(!result.result)
			{
				if(result.resulttext)
					message = result.resulttext;
				else
					message = NSLocalizedString(@"Unknown Error.", @"Remote host did return error code but no specific message.");
			}
		}

		// Show error message if one occured
		if(message != nil)
		{
			const UIAlertView *notification = [[UIAlertView alloc]
											   initWithTitle:NSLocalizedString(@"Error", @"")
											   message:message
											   delegate:nil
											   cancelButtonTitle:@"OK"
											   otherButtonTitles:nil];
			[notification show];
			return;
		}

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

- (void)emptyData
{
	// anything to do?
}

- (void)fetchData
{
	_reloading = YES;
	[[RemoteConnectorObject sharedRemoteConnector] getAutoTimerSettings:self];
}

#pragma mark - View lifecycle

- (void)loadView
{
	[super loadGroupedTableView];
	_tableView.delegate = self;
	_tableView.dataSource = self;
	_tableView.rowHeight = kUIRowHeight;
	_tableView.allowsSelectionDuringEditing = YES;

	self.navigationItem.rightBarButtonItem = self.editButtonItem;

	_interval = [self newIntervalField];
	_maxdays = [self newMaxdaysField];

	_autopoll = [[UISwitch alloc] initWithFrame:CGRectMake(0, 0, 300, kSwitchButtonHeight)];
	_autopoll.on = settings.autopoll;
	_autopoll.backgroundColor = [UIColor clearColor];

	_try_guessing = [[UISwitch alloc] initWithFrame:CGRectMake(0, 0, 300, kSwitchButtonHeight)];
	_try_guessing.on = settings.try_guessing;
	_try_guessing.backgroundColor = [UIColor clearColor];

	_disabled_on_conflict = [[UISwitch alloc] initWithFrame:CGRectMake(0, 0, 300, kSwitchButtonHeight)];
	_disabled_on_conflict.on = settings.disabled_on_conflict;
	_disabled_on_conflict.backgroundColor = [UIColor clearColor];

	_addsimilar_on_conflict = [[UISwitch alloc] initWithFrame:CGRectMake(0, 0, 300, kSwitchButtonHeight)];
	_addsimilar_on_conflict.on = settings.addsimilar_on_conflict;
	_addsimilar_on_conflict.backgroundColor = [UIColor clearColor];

	_show_in_extensionsmenu = [[UISwitch alloc] initWithFrame:CGRectMake(0, 0, 300, kSwitchButtonHeight)];
	_show_in_extensionsmenu.on = settings.show_in_extensionsmenu;
	_show_in_extensionsmenu.backgroundColor = [UIColor clearColor];

	_fastscan = [[UISwitch alloc] initWithFrame:CGRectMake(0, 0, 300, kSwitchButtonHeight)];
	_fastscan.on = settings.fastscan;
	_fastscan.backgroundColor = [UIColor clearColor];

	_notifconflict = [[UISwitch alloc] initWithFrame:CGRectMake(0, 0, 300, kSwitchButtonHeight)];
	_notifconflict.on = settings.notifconflict;
	_notifconflict.backgroundColor = [UIColor clearColor];

	_notifsimilar = [[UISwitch alloc] initWithFrame:CGRectMake(0, 0, 300, kSwitchButtonHeight)];
	_notifsimilar.on = settings.notifsimilar;
	_notifsimilar.backgroundColor = [UIColor clearColor];

	[self setEditing:YES animated:YES];

	[self theme];
}

- (void)theme
{
	if([UIDevice newerThanIos:5.0f])
	{
		UIColor *tintColor = [DreamoteConfiguration singleton].tintColor;
		_autopoll.onTintColor = tintColor;
		_try_guessing.onTintColor = tintColor;
		_disabled_on_conflict.onTintColor = tintColor;
		_addsimilar_on_conflict.onTintColor = tintColor;
		_show_in_extensionsmenu.onTintColor = tintColor;
		_fastscan.onTintColor = tintColor;
		_notifconflict.onTintColor = tintColor;
		_notifsimilar.onTintColor = tintColor;
	}
	[super theme];
}

- (void)viewDidUnload
{
	_interval = nil;
	_intervalCell = nil;
	_maxdays = nil;
	_maxdaysCell = nil;
	_autopoll = nil;
	_try_guessing = nil;
	_disabled_on_conflict = nil;
	_addsimilar_on_conflict = nil;
	_show_in_extensionsmenu = nil;
	_fastscan = nil;
	_notifconflict = nil;
	_notifsimilar = nil;
    [super viewDidUnload];
}

- (void)viewWillAppear:(BOOL)animated
{
	if(IS_IPHONE() && !self.navigationItem.leftBarButtonItem)
	{
		self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc]
												 initWithBarButtonSystemItem: UIBarButtonSystemItemCancel
												 target:self
												 action:@selector(cancelEdit:)];
	}

	// watch the keyboard so we can adjust the user interface if necessary.
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(keyboardWillShow:)
												 name:UIKeyboardWillShowNotification
											   object:self.view.window];

	if(!willReappear)
	{
		[self emptyData];
		[RemoteConnectorObject queueInvocationWithTarget:self selector:@selector(fetchData)];
	}
	willReappear = NO;
}

- (void)viewWillDisappear:(BOOL)animated
{
	// unregister for keyboard notifications while not visible.
	[[NSNotificationCenter defaultCenter] removeObserver:self
													name:UIKeyboardWillShowNotification
												  object:nil];
}

/* rotate with device */
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return YES;
}

#pragma mark -
#pragma mark DataSourceDelegate methods
#pragma mark -

- (void)dataSourceDelegateFinishedParsingDocument:(BaseXMLReader *)dataSource
{
	_reloading = NO;
	[_refreshHeaderView egoRefreshScrollViewDataSourceDidFinishedLoading:_tableView];
	[_tableView reloadData];
}

#pragma mark -
#pragma mark AutoTimerSettingsSourceDelegate methods
#pragma mark -

- (void)autotimerSettingsRead:(AutoTimerSettings *)anItem
{
	settings = anItem;
	_interval.text = [NSString stringWithFormat:@"%d", settings.interval];
	_maxdays.text = [NSString stringWithFormat:@"%d", settings.maxdays];
	_autopoll.on = settings.autopoll;
	_try_guessing.on = settings.try_guessing;
	_disabled_on_conflict.on = settings.disabled_on_conflict;
	_addsimilar_on_conflict.on = settings.addsimilar_on_conflict;
	_show_in_extensionsmenu.on = settings.show_in_extensionsmenu;
	_fastscan.on = settings.fastscan;
	_notifconflict.on = settings.notifconflict;
	_notifsimilar.on = settings.notifsimilar;
}

#pragma mark -
#pragma mark UITableView delegates
#pragma mark -

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	return maxRow;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	NSUInteger row = indexPath.row;
	UITableViewCell *cell = nil;

	switch(row)
	{
		default: break;
		case autopollRow:
			cell = [DisplayCell reusableTableViewCellInView:tableView withIdentifier:kDisplayCell_ID];
			((DisplayCell *)cell).view = _autopoll;
			cell.textLabel.text = NSLocalizedStringFromTable(@"", @"AutoTimer", @"");
			break;
		case intervalRow:
			if(_intervalCell == nil)
			{
				_intervalCell = [[CellTextField alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
				_intervalCell.view = _interval;
				_intervalCell.textLabel.font = [UIFont systemFontOfSize:kTextViewFontSize];
				_intervalCell.textLabel.text = NSLocalizedStringFromTable(@"", @"AutoTimer", @"Label for cell ''");
				_intervalCell.fixedWidth = 94.0f;
			}
			cell = _intervalCell;
			break;
		case try_guessingRow:
			cell = [DisplayCell reusableTableViewCellInView:tableView withIdentifier:kDisplayCell_ID];
			((DisplayCell *)cell).view = _try_guessing;
			cell.textLabel.text = NSLocalizedStringFromTable(@"", @"AutoTimer", @"");
			break;
		case refreshRow:
			cell = [BaseTableViewCell reusableTableViewCellInView:tableView withIdentifier:kBaseCell_ID];
			cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
			cell.textLabel.font = [UIFont systemFontOfSize:kTextViewFontSize];
			cell.textLabel.adjustsFontSizeToFitWidth = YES;
			cell.textLabel.text = [NSString stringWithFormat:NSLocalizedStringFromTable(@"Modify timers: %@", @"AutoTimer", @""), [refreshTexts objectAtIndex:settings.refresh]];
			break;
		case editorRow:
			cell = [BaseTableViewCell reusableTableViewCellInView:tableView withIdentifier:kBaseCell_ID];
			cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
			cell.textLabel.font = [UIFont systemFontOfSize:kTextViewFontSize];
			cell.textLabel.adjustsFontSizeToFitWidth = YES;
			cell.textLabel.text = [NSString stringWithFormat:NSLocalizedStringFromTable(@"Editor for new Timers: %@", @"AutoTimer", @""), [editorTexts objectAtIndex:settings.editor]];
			break;
		case disabled_on_conflictRow:
			cell = [DisplayCell reusableTableViewCellInView:tableView withIdentifier:kDisplayCell_ID];
			((DisplayCell *)cell).view = _disabled_on_conflict;
			cell.textLabel.text = NSLocalizedStringFromTable(@"", @"AutoTimer", @"");
			break;
		case addsimilar_on_conflictRow:
			cell = [DisplayCell reusableTableViewCellInView:tableView withIdentifier:kDisplayCell_ID];
			((DisplayCell *)cell).view = _addsimilar_on_conflict;
			cell.textLabel.text = NSLocalizedStringFromTable(@"", @"AutoTimer", @"");
			break;
		case show_in_extensionsmenuRow:
			cell = [DisplayCell reusableTableViewCellInView:tableView withIdentifier:kDisplayCell_ID];
			((DisplayCell *)cell).view = _show_in_extensionsmenu;
			cell.textLabel.text = NSLocalizedStringFromTable(@"", @"AutoTimer", @"");
			break;
		case fastscanRow:
			cell = [DisplayCell reusableTableViewCellInView:tableView withIdentifier:kDisplayCell_ID];
			((DisplayCell *)cell).view = _fastscan;
			cell.textLabel.text = NSLocalizedStringFromTable(@"", @"AutoTimer", @"");
			break;
		case notifconflictRow:
			cell = [DisplayCell reusableTableViewCellInView:tableView withIdentifier:kDisplayCell_ID];
			((DisplayCell *)cell).view = _notifconflict;
			cell.textLabel.text = NSLocalizedStringFromTable(@"", @"AutoTimer", @"");
			break;
		case notifSimilarRow:
			cell = [DisplayCell reusableTableViewCellInView:tableView withIdentifier:kDisplayCell_ID];
			((DisplayCell *)cell).view = _notifsimilar;
			cell.textLabel.text = NSLocalizedStringFromTable(@"", @"AutoTimer", @"");
			break;
		case maxdaysRow:
			if(_maxdaysCell == nil)
			{
				_maxdaysCell = [[CellTextField alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
				_maxdaysCell.view = _maxdays;
				_maxdaysCell.textLabel.font = [UIFont systemFontOfSize:kTextViewFontSize];
				_maxdaysCell.textLabel.text = NSLocalizedStringFromTable(@"", @"AutoTimer", @"Label for cell ''");
				_maxdaysCell.fixedWidth = 94.0f;
			}
			cell = _maxdaysCell;
			break;
	}

	return [[DreamoteConfiguration singleton] styleTableViewCell:cell inTableView:tableView];
}

- (void)tableView:(UITableView *)tv didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	UIViewController *targetViewController = nil;
	const NSInteger row = indexPath.row;
	switch(row)
	{
		case refreshRow:
		case editorRow:
		{
			const BOOL isIpad = IS_IPAD();
			const BOOL isRefresh = (row == refreshRow);
			SimpleSingleSelectionListController *vc = nil;
			if(isRefresh)
				vc = [SimpleSingleSelectionListController withItems:refreshTexts andSelection:settings.refresh andTitle:NSLocalizedStringFromTable(@"Modify Timers", @"AutoTimer", @"Title of timer modification behavior selection.")];
			else
				vc = [SimpleSingleSelectionListController withItems:editorTexts andSelection:settings.editor andTitle:NSLocalizedStringFromTable(@"Timer Editor", @"AutoTimer", @"Title of (new) timer editor selector.")];
			vc.callback = ^(NSUInteger selection, BOOL isFinal, BOOL canceling)
			{
				if(!canceling)
				{
					if(!isIpad && !isFinal)
						return NO;

					UITableViewCell *cell = [tv cellForRowAtIndexPath:indexPath];
					if(isRefresh)
					{
						settings.refresh = selection;
						cell.textLabel.text = [NSString stringWithFormat:NSLocalizedStringFromTable(@"Modify timers: %@", @"AutoTimer", @""), [refreshTexts objectAtIndex:settings.refresh]];
					}
					else
					{
						settings.editor = selection;
						cell.textLabel.text = [NSString stringWithFormat:NSLocalizedStringFromTable(@"Editor for new Timers: %@", @"AutoTimer", @""), [editorTexts objectAtIndex:settings.editor]];
					}
				}
				else if(!isIpad)
					[self.navigationController popToViewController:self animated:YES];

				if(isIpad)
					[self dismissModalViewControllerAnimated:YES];
				return YES;
			};
			if(isIpad)
			{
				targetViewController = [[UINavigationController alloc] initWithRootViewController:vc];
				targetViewController.modalPresentationStyle = vc.modalPresentationStyle;
				targetViewController.modalTransitionStyle = vc.modalTransitionStyle;
			}
			else
				targetViewController = vc;
			break;
		}
		default:
			break;
	}
	if(targetViewController)
	{
		if(IS_IPAD())
			[self.navigationController presentModalViewController:targetViewController animated:YES];
		else
		{
			willReappear = YES;
			[self.navigationController pushViewController:targetViewController animated:YES];
		}
	}
	[tv deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark -
#pragma mark <EditableTableViewCellDelegate> Methods and editing management
#pragma mark -

- (BOOL)cellShouldBeginEditing:(EditableTableViewCell *)cell
{
	if(![cell isEqual:_intervalCell])
		[_intervalCell stopEditing];
	if(![cell isEqual:_maxdaysCell])
		[_maxdaysCell stopEditing];

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
	if(_intervalCell.isInlineEditing)
		indexPath = [NSIndexPath indexPathForRow:intervalRow inSection:0];
	else if(_maxdaysCell.isInlineEditing)
		indexPath = [NSIndexPath indexPathForRow:maxdaysRow inSection:0];
	else return;

	if(UIInterfaceOrientationIsLandscape(self.interfaceOrientation))
		scrollPosition = UITableViewScrollPositionTop;
	[_tableView scrollToRowAtIndexPath:indexPath atScrollPosition:scrollPosition animated:YES];
}

@end
