//
//  AutoTimerViewController.m
//  dreaMote
//
//  Created by Moritz Venn on 10.03.08.
//  Copyright 2008-2011 Moritz Venn. All rights reserved.
//

#import "AutoTimerViewController.h"

#import "BouquetListController.h"
#import "ServiceListController.h"
#import "DatePickerController.h"

#import "RemoteConnectorObject.h"
#import "Constants.h"

#import "CellTextField.h"
#import "DisplayCell.h"
#import "ServiceTableViewCell.h"

#import "NSDateFormatter+FuzzyFormatting.h"
#import "UITableViewCell+EasyInit.h"

#import "Objects/Generic/Result.h"
#import "Objects/Generic/Service.h"
#import "Objects/Generic/AutoTimer.h"

enum sectionIds
{
	titleSection = 0,
	matchSection = 1,
	generalSection = 2,
	timespanSection = 3,
	durationSection = 4,
	servicesSection = 5,
	bouquetSection = 6,
	aftereventSection = 7,
	locationSection = 8,
	filterTitleSection = 9,
	filterSdescSection = 10,
	filterDescSection = 11,
	filterWeekdaySection = 12,
	maxSection = 13,
};

/*!
 @brief Private functions of AutoTimerViewController.
 */
@interface AutoTimerViewController()
/*!
 @brief stop editing
 @param sender ui element
 */
- (void)cancelEdit:(id)sender;

/*!
 @brief Toggle visibility of maxduration
 @param sender ui element
 */
- (void)showHideMaxduration:(id)sender;

@property (nonatomic, retain) UIPopoverController *popoverController;
@property (nonatomic, readonly) AfterEventViewController *afterEventViewController;
@property (nonatomic, readonly) UIViewController *afterEventNavigationController;
@property (nonatomic, readonly) UIViewController *bouquetListController;
@property (nonatomic, readonly) DatePickerController *datePickerController;
@property (nonatomic, readonly) UIViewController *datePickerNavigationController;
@property (nonatomic, readonly) UIViewController *locationListController;
@end

@implementation AutoTimerViewController

@synthesize delegate = _delegate;
@synthesize popoverController;

- (id)init
{
	if((self = [super init]))
	{
		self.title = NSLocalizedString(@"AutoTimer", @"Default title of AutoTimerViewController");

		_creatingNewTimer = NO;
		_bouquetListController = nil;
		_datePickerController = nil;
		_afterEventViewController = nil;
		_popoverButtonItem = nil;
	}
	return self;
}

+ (AutoTimerViewController *)newWithAutoTimer:(AutoTimer *)ourTimer
{
	AutoTimerViewController *autoTimerViewController = [[AutoTimerViewController alloc] init];
	autoTimerViewController.timer = ourTimer;
	autoTimerViewController.creatingNewTimer = NO;

	return autoTimerViewController;
}

+ (AutoTimerViewController *)newAutoTimer
{
	AutoTimerViewController *autoTimerViewController = [[AutoTimerViewController alloc] init];
	AutoTimer *newTimer = [AutoTimer timer];
	autoTimerViewController.timer = newTimer;
	autoTimerViewController.creatingNewTimer = YES;

	return autoTimerViewController;
}

- (void)dealloc
{
	[_timer release];
	[_delegate release];

	[_titleField release];
	[_matchField release];
	[_maxdurationField release];
	[_timerEnabled release];
	[_exactSearch release];
	[_sensitiveSearch release];
	[_overrideAlternatives release];
	[_timerJustplay release];
	[_avoidDuplicateDescription release];

	[_cancelButtonItem release];
	[_popoverButtonItem release];
	[popoverController release];

	[_afterEventNavigationController release];
	[_afterEventViewController release];
	[_bouquetListController release];
	[_datePickerController release];
	[_datePickerNavigationController release];
	[_locationListController release];

	[super dealloc];
}

- (void)didReceiveMemoryWarning
{
	[_afterEventNavigationController release];
	[_afterEventViewController release];
	[_bouquetListController release];
	[_datePickerController release];
	[_datePickerNavigationController release];
	[_locationListController release];

	_afterEventNavigationController = nil;
	_afterEventViewController = nil;
	_bouquetListController = nil;
	_datePickerController = nil;
	_datePickerNavigationController = nil;
	_locationListController = nil;

	[super didReceiveMemoryWarning];
}

#pragma mark -
#pragma mark Properties
#pragma mark -

- (UIViewController *)afterEventNavigationController
{
	if(IS_IPAD())
	{
		if(_afterEventNavigationController == nil)
		{
			_afterEventNavigationController = [[UINavigationController alloc] initWithRootViewController:self.afterEventViewController];
			_afterEventNavigationController.modalPresentationStyle = _afterEventViewController.modalPresentationStyle;
			_afterEventNavigationController.modalTransitionStyle = _afterEventViewController.modalTransitionStyle;
		}
		return _afterEventNavigationController;
	}
	return _afterEventViewController;
}

- (AfterEventViewController *)afterEventViewController
{
	if(_afterEventViewController == nil)
	{
		_afterEventViewController = [[AfterEventViewController alloc] init];
		[_afterEventViewController setDelegate: self];
	}
	return _afterEventViewController;
}

- (UIViewController *)bouquetListController
{
	if(_bouquetListController == nil)
	{
		UIViewController *rootViewController = nil;
		const BOOL forceSingleBouquet =
			[[RemoteConnectorObject sharedRemoteConnector] hasFeature: kFeaturesSingleBouquet]
			&& ![[RemoteConnectorObject sharedRemoteConnector] hasFeature: kFeaturesBouquets];

		if(forceSingleBouquet || (!IS_IPAD() && [RemoteConnectorObject isSingleBouquet]))
		{
			rootViewController = [[ServiceListController alloc] init];
			[(ServiceListController *)rootViewController setDelegate: self];
		}
		else
		{
			rootViewController = [[BouquetListController alloc] init];
			[(BouquetListController *)rootViewController setServiceDelegate: self];
		}

		if(IS_IPAD())
		{
			_bouquetListController = [[UINavigationController alloc] initWithRootViewController:rootViewController];
			_bouquetListController.modalPresentationStyle = rootViewController.modalPresentationStyle;
			_bouquetListController.modalPresentationStyle = rootViewController.modalPresentationStyle;

			[rootViewController release];
		}
		else
			_bouquetListController = rootViewController;
	}
	return _bouquetListController;
}

- (UIViewController *)datePickerNavigationController
{
	if(IS_IPAD())
	{
		if(_datePickerNavigationController == nil)
		{
			_datePickerNavigationController = [[UINavigationController alloc] initWithRootViewController:self.datePickerController];
			_datePickerNavigationController.modalPresentationStyle = _datePickerController.modalPresentationStyle;
			_datePickerNavigationController.modalTransitionStyle = _datePickerController.modalTransitionStyle;
		}
		return _datePickerNavigationController;
	}
	return _datePickerController;
}

- (DatePickerController *)datePickerController
{
	if(_datePickerController == nil)
		_datePickerController = [[DatePickerController alloc] init];
	return _datePickerController;
}

- (UIViewController *)locationListController
{
	if(_locationListController == nil)
	{
		LocationListController *rootViewController = [[LocationListController alloc] init];
		[rootViewController setDelegate: self];

		if(IS_IPAD())
		{
			_locationListController = [[UINavigationController alloc] initWithRootViewController:rootViewController];
			_locationListController.modalPresentationStyle = rootViewController.modalPresentationStyle;
			_locationListController.modalTransitionStyle = rootViewController.modalTransitionStyle;
		}
		else
			_locationListController = rootViewController;
	}
	return _locationListController;
}

- (AutoTimer *)timer
{
	return _timer;
}

- (void)setTimer:(AutoTimer *)newTimer
{
	if(_timer != newTimer)
	{
		[_timer release];
		_timer = [newTimer retain];

		// stop editing
		_shouldSave = NO;
		[self cellShouldBeginEditing: nil];
		[self setEditing: NO animated: YES];
	}

	_titleField.text = _timer.name;
	_matchField.text = _timer.match;
	if(_timer.maxduration == -1)
		_maxdurationField.text = nil;
	else
		_maxdurationField.text = [NSString stringWithFormat:@"%d", _timer.maxduration];
	_timerEnabled.on = _timer.enabled;
	_exactSearch.on = _timer.searchType == SEARCH_TYPE_EXACT;
	_sensitiveSearch.on = _timer.searchCase == CASE_SENSITIVE;
	_overrideAlternatives.on = _timer.overrideAlternatives;
	_timerJustplay.on = _timer.justplay;
	_avoidDuplicateDescription.on = _timer.avoidDuplicateDescription;
	_maxdurationSwitch.on = (_timer.maxduration > 0);

	[(UITableView *)self.view reloadData];
	[(UITableView *)self.view
						scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]
						atScrollPosition:UITableViewScrollPositionTop
						animated:NO];

	// Eventually remove popover
	if(self.popoverController != nil) {
        [self.popoverController dismissPopoverAnimated:YES];
    }
}

- (BOOL)creatingNewTimer
{
	return _creatingNewTimer;
}

- (void)setCreatingNewTimer: (BOOL)newValue
{
	if(newValue)
		self.title = NSLocalizedString(@"New AutoTimer", @"");
	else
		self.title = NSLocalizedString(@"AutoTimer", @"Default title of AutoTimerViewController");

	_shouldSave = NO;
	_creatingNewTimer = newValue;

	[self setEditing:YES animated:YES];
}

#pragma mark -
#pragma mark Helper methods
#pragma mark -

- (NSString *)format_BeginEnd: (NSDate *)dateTime
{
	const NSDateFormatter *format = [[NSDateFormatter alloc] init];
	[format setDateStyle:NSDateFormatterFullStyle];
	[format setTimeStyle:NSDateFormatterShortStyle];
	NSString *dateString = [format fuzzyDate: dateTime];
	[format release];
	return dateString;
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

	returnTextField.keyboardType = UIKeyboardTypeDefault;
	returnTextField.returnKeyType = UIReturnKeyDone;

	// has a clear 'x' button to the right
	returnTextField.clearButtonMode = UITextFieldViewModeWhileEditing;

	return returnTextField;
}

- (UITextField *)newTitleField
{
	UITextField *field = [self allocTextField];
	field.text = _timer.name;
	field.placeholder = NSLocalizedStringFromTable(@"<enter title>", @"AutoTimer", @"Placeholder of AutoTimer Title field");
	return field;
}

- (UITextField *)newMatchField
{
	UITextField *field = [self allocTextField];
	field.text = _timer.match;
	field.placeholder = NSLocalizedStringFromTable(@"<text to find in title>", @"AutoTimer", @"Placeholder of AutoTimer Match field");
	return field;
}

- (UITextField *)newMaxdurationField
{
	UITextField *field = [self allocTextField];
	if(_timer.maxduration == -1)
		field.text = nil;
	else
		field.text = [NSString stringWithFormat:@"%d", _timer.maxduration];
	field.placeholder = NSLocalizedStringFromTable(@"<maximum duration>", @"AutoTimer", @"Placeholder of AutoTimer Maxduration field");
	field.keyboardType = UIKeyboardTypeNumberPad;
	return field;
}

- (void)showHideMaxduration:(id)sender
{
	// XXX: nothing to be done yet, maxduration currently has its own section
}

#pragma mark -
#pragma mark UView
#pragma mark -

- (void)loadView
{
	self.navigationItem.rightBarButtonItem = self.editButtonItem;

	_cancelButtonItem = [[UIBarButtonItem alloc]
						initWithBarButtonSystemItem: UIBarButtonSystemItemCancel
						target: self
						action: @selector(cancelEdit:)];
	self.navigationItem.leftBarButtonItem = _cancelButtonItem;

	// create and configure the table view
	UITableView *tableView = [[UITableView alloc] initWithFrame:[[UIScreen mainScreen] applicationFrame] style:UITableViewStyleGrouped];
	tableView.delegate = self;
	tableView.dataSource = self;
	tableView.rowHeight = kUIRowHeight;

	// setup our content view so that it auto-rotates along with the UViewController
	tableView.autoresizesSubviews = YES;
	tableView.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);

	self.view = tableView;
	[tableView release];

	_titleField = [self newTitleField];
	_matchField = [self newMatchField];
	_maxdurationField = [self newMaxdurationField];

	// Enabled
	_timerEnabled = [[UISwitch alloc] initWithFrame:CGRectMake(0, 0, 300, kSwitchButtonHeight)];
	_timerEnabled.on = _timer.enabled;
	_timerEnabled.backgroundColor = [UIColor clearColor];

	// Exact
	_exactSearch = [[UISwitch alloc] initWithFrame:CGRectMake(0, 0, 300, kSwitchButtonHeight)];
	_exactSearch.on = _timer.searchType == SEARCH_TYPE_EXACT;
	_exactSearch.backgroundColor = [UIColor clearColor];

	// Case-Sensitive
	_sensitiveSearch = [[UISwitch alloc] initWithFrame:CGRectMake(0, 0, 300, kSwitchButtonHeight)];
	_sensitiveSearch.on = _timer.searchCase == CASE_SENSITIVE;
	_sensitiveSearch.backgroundColor = [UIColor clearColor];

	// overrideAlternatives
	_overrideAlternatives = [[UISwitch alloc] initWithFrame:CGRectMake(0, 0, 300, kSwitchButtonHeight)];
	_overrideAlternatives.on = _timer.overrideAlternatives;
	_overrideAlternatives.backgroundColor = [UIColor clearColor];

	// Justplay
	_timerJustplay = [[UISwitch alloc] initWithFrame: CGRectMake(0, 0, 300, kSwitchButtonHeight)];
	_timerJustplay.on = _timer.justplay;
	_timerJustplay.backgroundColor = [UIColor clearColor];

	// avoidDuplicateDescription
	_avoidDuplicateDescription = [[UISwitch alloc] initWithFrame: CGRectMake(0, 0, 300, kSwitchButtonHeight)];
	_avoidDuplicateDescription.on = _timer.avoidDuplicateDescription;
	_avoidDuplicateDescription.backgroundColor = [UIColor clearColor];

	// maxduration enable/disable
	_maxdurationSwitch = [[UISwitch alloc] initWithFrame: CGRectMake(0, 0, 300, kSwitchButtonHeight)];
	[_maxdurationSwitch addTarget:self action:@selector(showHideMaxduration:) forControlEvents:UIControlEventValueChanged];
	_maxdurationSwitch.on = (_timer.maxduration > 0);
	_maxdurationSwitch.backgroundColor = [UIColor clearColor];

	// default editing mode depends on our mode
	_shouldSave = NO;
	[self setEditing: _creatingNewTimer];
}

#pragma mark -
#pragma mark UIViewController
#pragma mark -

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
		if(IS_IPAD())
			self.navigationItem.leftBarButtonItem = _popoverButtonItem;
		else
			self.navigationItem.leftBarButtonItem = _cancelButtonItem;
	}
	else if(_shouldSave)
	{
		NSString *message = nil;

		// TODO: apply changes

		// Try to commit changes if no error occured
		if(!message)
		{
			if(_creatingNewTimer)
			{
				// TODO: add new autotimer

				Result *result = nil;//[[RemoteConnectorObject sharedRemoteConnector] addTimer: _timer];
				if(!result.result)
					message = [NSString stringWithFormat: NSLocalizedString(@"Error adding AutoTimer: %@", @""), result.resulttext];
				else
				{
					[_delegate AutoTimerViewController:self timerWasAdded:_timer];
					[self.navigationController popViewControllerAnimated: YES];
				}
			}
			else
			{
				// TODO: edit autotimer

				Result *result = nil;//[[RemoteConnectorObject sharedRemoteConnector] editTimer: _oldTimer: _timer];
				if(!result.result)
					message = [NSString stringWithFormat: NSLocalizedString(@"Error editing AutoTimer: %@", @""), result.resulttext];
				else
				{
					[_delegate AutoTimerViewController:self timerWasEdited:_timer];
					[self.navigationController popViewControllerAnimated: YES];
				}
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
			[notification release];

			[_delegate AutoTimerViewController:self editingWasCanceled:_timer];
			return;
		}

		self.navigationItem.leftBarButtonItem = _popoverButtonItem;
	}
	else
	{
		self.navigationItem.leftBarButtonItem = _popoverButtonItem;
	}

	_shouldSave = editing;
	[super setEditing: editing animated: animated];
	[(UITableView *)self.view setEditing:editing animated:animated];

	// TODO: notifiy cells/other elements of change in editing

	[(UITableView *)self.view reloadData];
}

- (void)cancelEdit:(id)sender
{
	_shouldSave = NO;
	[self cellShouldBeginEditing:nil];
	[self setEditing:NO animated:YES];
	[self.navigationController popViewControllerAnimated:YES];
}

/* rotate with device */
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return YES;
}

#pragma mark -
#pragma mark DatePickerController callbacks
#pragma mark -

- (void)fromSelected: (NSDate *)newDate
{
	if(newDate == nil)
		return;

	_timer.from = newDate;
	// TODO: change label text
}

- (void)toSelected: (NSDate *)newDate
{
	if(newDate == nil)
		return;

	_timer.to = newDate;
	// TODO: change label text
}

- (void)beforeSelected: (NSDate *)newDate
{
	if(newDate == nil)
		return;

	_timer.before = newDate;
	// TODO: change label text
}

- (void)afterSelected: (NSDate *)newDate
{
	if(newDate == nil)
		return;

	_timer.after = newDate;
	// TODO: change label text
}

#pragma mark -
#pragma mark BouquetListDelegate methods
#pragma mark -

- (void)bouquetSelected:(NSObject<ServiceProtocol> *)newBouquet
{
	if(newBouquet == nil)
		return;

	// TODO: add bouquet to list

	// copy service for convenience reasons
	[_timer.bouquets addObject:[[newBouquet copy] autorelease]];
	//[(UITableView *)self.view reloadSections:[NSIndexSet indexSetWithIndex:4] withRowAnimation:UITableViewRowAnimationFade];
}

#pragma mark -
#pragma mark ServiceListDelegate methods
#pragma mark -

- (void)serviceSelected: (NSObject<ServiceProtocol> *)newService
{
	if(newService == nil)
		return;

	// TODO: add service to list

	// copy service for convenience reasons
	[_timer.services addObject:[[newService copy] autorelease]];
	//[(UITableView *)self.view reloadSections:[NSIndexSet indexSetWithIndex:3] withRowAnimation:UITableViewRowAnimationFade];
}

#pragma mark -
#pragma mark AfterEventDelegate methods
#pragma mark -

- (void)setAfterEventText:(UITableViewCell *)cell
{
	if(cell == nil)
		return;

	if(_timer.afterEventAction == kAfterEventNothing)
		TABLEVIEWCELL_TEXT(cell) = NSLocalizedString(@"Nothing", @"After Event");
	else if(_timer.afterEventAction == kAfterEventStandby)
		TABLEVIEWCELL_TEXT(cell) = NSLocalizedString(@"Standby", @"");
	else if(_timer.afterEventAction == kAfterEventDeepstandby)
		TABLEVIEWCELL_TEXT(cell) = NSLocalizedString(@"Deep Standby", @"");
	else if(_timer.afterEventAction == kAfterEventAuto)
		TABLEVIEWCELL_TEXT(cell) = NSLocalizedString(@"Auto", @"");
	else //if(_timer.afterEventAction == kAfterEventMax)
		TABLEVIEWCELL_TEXT(cell) = NSLocalizedString(@"Default Action", @"");
}

- (void)afterEventSelected: (NSNumber *)newAfterEvent
{
	if(newAfterEvent == nil)
		return;

	_timer.afterEventAction = [newAfterEvent integerValue];

	UITableViewCell *cell = [(UITableView *)self.view cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:aftereventSection]];
	[self setAfterEventText:cell];
}

#pragma mark -
#pragma mark LocationListDelegate methods
#pragma mark -

- (void)locationSelected:(NSObject <LocationProtocol>*)newLocation
{
	if(newLocation == nil)
		return;

	_timer.location = newLocation.fullpath;

	UITableViewCell *cell = [(UITableView *)self.view cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:locationSection]];
	if(cell == nil)
		return;

	cell.textLabel.text = newLocation.fullpath;
}

#pragma mark -
#pragma mark UITableView delegates
#pragma mark -

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return maxSection;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
	switch(section)
	{
		case titleSection:
			return NSLocalizedString(@"Title", @"");
		case matchSection:
			return NSLocalizedString(@"Match", @"");
		case generalSection:
			return NSLocalizedString(@"General", @"in timer settings dialog");
		case durationSection:
			return NSLocalizedString(@"Max. Duration", @"");
		case timespanSection:
			return NSLocalizedStringFromTable(@"Timespan", @"AutoTimer", @"section header for timespan");
		case servicesSection:
			return NSLocalizedStringFromTable(@"Services", @"AutoTimer", @"section header for service restriction");
		case bouquetSection:
			return NSLocalizedStringFromTable(@"Bouquets", @"AutoTimer", @"section header for bouquet restriction");
		case aftereventSection:
			return NSLocalizedString(@"After Event", @"");
		case locationSection:
			return NSLocalizedString(@"Location", @"");
		case filterSdescSection:
			return NSLocalizedString(@"Filter: Shortdescription", @"");
		case filterDescSection:
			return NSLocalizedString(@"Filter: Description", @"");
		case filterTitleSection:
			return NSLocalizedString(@"Filter: Title", @"");
		case filterWeekdaySection:
			return NSLocalizedString(@"Filter: Weekday", @"");
		default:
			return nil;
	}
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	switch(section)
	{
		case titleSection:
		case matchSection:
		case aftereventSection:
		case locationSection:
			return 1;
		case generalSection:
			return 6;
		case durationSection:
			return 2;
		case timespanSection:
			return 3;
		case servicesSection:
			return _timer.services.count + (self.editing ? 1 : 0);
		case bouquetSection:
			return _timer.bouquets.count + (self.editing ? 1 : 0);
		case filterSdescSection:
			return _timer.includeShortdescription.count + _timer.excludeShortdescription.count + (self.editing ? 1 : 0);
		case filterDescSection:
			return _timer.includeDescription.count + _timer.excludeDescription.count + (self.editing ? 1 : 0);
		case filterTitleSection:
			return _timer.includeTitle.count + _timer.excludeTitle.count + (self.editing ? 1 : 0);
		case filterWeekdaySection:
			return _timer.includeDayOfWeek.count + _timer.excludeDayOfWeek.count + (self.editing ? 1 : 0);
		default:
			return 0;
	}
}

// to determine which UITableViewCell to be used on a given row.
//
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	const NSInteger section = indexPath.section;
	NSUInteger row = indexPath.row;
	UITableViewCell *cell = nil;

	switch(section)
	{
		case titleSection:
			cell = [CellTextField reusableTableViewCellInView:tableView withIdentifier:kCellTextField_ID];
			_titleCell = (CellTextField *)cell;
			_titleCell.delegate = self;
			_titleCell.view = _titleField;
			break;
		case matchSection:
			cell = [CellTextField reusableTableViewCellInView:tableView withIdentifier:kCellTextField_ID];
			_matchCell = (CellTextField *)cell;
			_matchCell.delegate = self;
			_matchCell.view = _matchField;
			break;
		case generalSection:
			cell = [DisplayCell reusableTableViewCellInView:tableView withIdentifier:kDisplayCell_ID];
			break;
		case durationSection:
			if(row == 0)
			{
				cell = [DisplayCell reusableTableViewCellInView:tableView withIdentifier:kDisplayCell_ID];
				((DisplayCell *)cell).view = _maxdurationSwitch;
				cell.textLabel.text = NSLocalizedString(@"Enabled", @"");
				cell.textLabel.font = [UIFont systemFontOfSize:kTextViewFontSize];
			}
			else
			{
				cell = [CellTextField reusableTableViewCellInView:tableView withIdentifier:kCellTextField_ID];
				_maxdurationCell = (CellTextField *)cell;
				_maxdurationCell.delegate = self;
				_maxdurationCell.view = _maxdurationField;
			}
			break;
		case timespanSection:
		{
			switch(row)
			{
				case 0:
					cell = [DisplayCell reusableTableViewCellInView:tableView withIdentifier:kDisplayCell_ID];
					cell.textLabel.text = NSLocalizedString(@"Enabled", @"");
					cell.textLabel.font = [UIFont systemFontOfSize:kTextViewFontSize];
					break;
				case 1:
					cell = [UITableViewCell reusableTableViewCellInView:tableView withIdentifier:kVanilla_ID];
					cell.textLabel.text = NSLocalizedStringFromTable(@"From: %@", @"AutoTimer", @"timespan from");
					cell.accessoryType = UITableViewCellAccessoryNone;
					cell.editingAccessoryType = UITableViewCellAccessoryDisclosureIndicator;
					cell.textLabel.font = [UIFont systemFontOfSize:kTextViewFontSize];
					break;
				case 2:
					cell = [UITableViewCell reusableTableViewCellInView:tableView withIdentifier:kVanilla_ID];
					cell.textLabel.text = NSLocalizedStringFromTable(@"To: %@", @"AutoTimer", @"timespan to");
					cell.accessoryType = UITableViewCellAccessoryNone;
					cell.editingAccessoryType = UITableViewCellAccessoryDisclosureIndicator;
					cell.textLabel.font = [UIFont systemFontOfSize:kTextViewFontSize];
					break;
			}
			break;
		}
		case servicesSection:
		{
			if(self.editing)
			{
				if(row == 0)
				{
					cell = [UITableViewCell reusableTableViewCellInView:tableView withIdentifier:kVanilla_ID];
					cell.textLabel.text = NSLocalizedStringFromTable(@"New Service", @"AutoTimer", @"add new service filter");
					cell.editingAccessoryType = UITableViewCellAccessoryDisclosureIndicator;
					cell.textLabel.font = [UIFont systemFontOfSize:kTextViewFontSize];
					break;
				}
				else
					--row;
			}

			cell = [ServiceTableViewCell reusableTableViewCellInView:tableView withIdentifier:kServiceCell_ID];
			((ServiceTableViewCell *)cell).serviceNameLabel.font = [UIFont systemFontOfSize:kTextViewFontSize];
			((ServiceTableViewCell *)cell).service = [_timer.services objectAtIndex:row];
			cell.accessoryType = UITableViewCellAccessoryNone;
			cell.editingAccessoryType = UITableViewCellAccessoryDisclosureIndicator;
			break;
		}
		case bouquetSection:
		{
			if(self.editing)
			{
				if(row == 0)
				{
					cell = [UITableViewCell reusableTableViewCellInView:tableView withIdentifier:kVanilla_ID];
					cell.textLabel.text = NSLocalizedStringFromTable(@"New Bouquet", @"AutoTimer", @"add new bouquet filter");
					cell.editingAccessoryType = UITableViewCellAccessoryDisclosureIndicator;
					cell.textLabel.font = [UIFont systemFontOfSize:kTextViewFontSize];
					break;
				}
				else
					--row;
			}

			cell = [ServiceTableViewCell reusableTableViewCellInView:tableView withIdentifier:kServiceCell_ID];
			((ServiceTableViewCell *)cell).serviceNameLabel.font = [UIFont systemFontOfSize:kTextViewFontSize];
			((ServiceTableViewCell *)cell).service = [_timer.bouquets objectAtIndex:row];
			cell.accessoryType = UITableViewCellAccessoryNone;
			cell.editingAccessoryType = UITableViewCellAccessoryDisclosureIndicator;
			break;
		}
		case aftereventSection:
			cell = [UITableViewCell reusableTableViewCellInView:tableView withIdentifier:kVanilla_ID];
			cell.accessoryType = UITableViewCellAccessoryNone;
			cell.editingAccessoryType = UITableViewCellAccessoryDisclosureIndicator;
			cell.textLabel.font = [UIFont systemFontOfSize:kTextViewFontSize];
			[self setAfterEventText:cell];
			break;
		case locationSection:
			cell = [UITableViewCell reusableTableViewCellInView:tableView withIdentifier:kVanilla_ID];
			cell.accessoryType = UITableViewCellAccessoryNone;
			cell.editingAccessoryType = UITableViewCellAccessoryDisclosureIndicator;
			cell.textLabel.text = (_timer.location) ? _timer.location : NSLocalizedString(@"Default Location", @"");
			cell.textLabel.font = [UIFont systemFontOfSize:kTextViewFontSize];
			break;
		case filterSdescSection:
		{
			cell = [UITableViewCell reusableTableViewCellInView:tableView withIdentifier:kVanilla_ID];
			cell.textLabel.font = [UIFont systemFontOfSize:kTextViewFontSize];
			if(self.editing)
			{
				if(row == 0)
				{
					cell.textLabel.text = NSLocalizedStringFromTable(@"New Filter", @"AutoTimer", @"add new filter");
					cell.editingAccessoryType = UITableViewCellAccessoryDisclosureIndicator;
					break;
				}
				else
					--row;
			}

			if(row < _timer.includeShortdescription.count)
			{
				cell.textLabel.text = [_timer.includeShortdescription objectAtIndex:row];
				cell.accessoryType = UITableViewCellAccessoryCheckmark;
				cell.editingAccessoryType = UITableViewCellAccessoryCheckmark;
				break;
			}

			row -= _timer.includeShortdescription.count;
			cell.textLabel.text = [_timer.excludeShortdescription objectAtIndex:row];
			cell.accessoryType = UITableViewCellAccessoryNone;
			cell.editingAccessoryType = UITableViewCellAccessoryNone;
			break;
		}
		case filterDescSection:
		{
			cell = [UITableViewCell reusableTableViewCellInView:tableView withIdentifier:kVanilla_ID];
			cell.textLabel.font = [UIFont systemFontOfSize:kTextViewFontSize];
			if(self.editing)
			{
				if(row == 0)
				{
					cell.textLabel.text = NSLocalizedStringFromTable(@"New Filter", @"AutoTimer", @"add new filter");
					cell.editingAccessoryType = UITableViewCellAccessoryDisclosureIndicator;
					break;
				}
				else
					--row;
			}

			if(row < _timer.includeDescription.count)
			{
				cell.textLabel.text = [_timer.includeDescription objectAtIndex:row];
				cell.accessoryType = UITableViewCellAccessoryCheckmark;
				cell.editingAccessoryType = UITableViewCellAccessoryCheckmark;
				break;
			}

			row -= _timer.includeDescription.count;
			cell.textLabel.text = [_timer.excludeDescription objectAtIndex:row];
			cell.accessoryType = UITableViewCellAccessoryNone;
			cell.editingAccessoryType = UITableViewCellAccessoryNone;
			break;
		}
		case filterTitleSection:
		{
			cell = [UITableViewCell reusableTableViewCellInView:tableView withIdentifier:kVanilla_ID];
			cell.textLabel.font = [UIFont systemFontOfSize:kTextViewFontSize];
			if(self.editing)
			{
				if(row == 0)
				{
					cell.textLabel.text = NSLocalizedStringFromTable(@"New Filter", @"AutoTimer", @"add new filter");
					cell.editingAccessoryType = UITableViewCellAccessoryDisclosureIndicator;
					break;
				}
				else
					--row;
			}

			if(row < _timer.includeTitle.count)
			{
				cell.textLabel.text = [_timer.includeTitle objectAtIndex:row];
				cell.accessoryType = UITableViewCellAccessoryCheckmark;
				cell.editingAccessoryType = UITableViewCellAccessoryCheckmark;
				break;
			}

			row -= _timer.includeTitle.count;
			cell.textLabel.text = [_timer.excludeTitle objectAtIndex:row];
			cell.accessoryType = UITableViewCellAccessoryNone;
			cell.editingAccessoryType = UITableViewCellAccessoryNone;
			break;
		}
		case filterWeekdaySection:
		{
			cell = [UITableViewCell reusableTableViewCellInView:tableView withIdentifier:kVanilla_ID];
			cell.textLabel.font = [UIFont systemFontOfSize:kTextViewFontSize];
			if(self.editing)
			{
				if(row == 0)
				{
					cell.textLabel.text = NSLocalizedStringFromTable(@"New Filter", @"AutoTimer", @"add new filter");
					cell.editingAccessoryType = UITableViewCellAccessoryDisclosureIndicator;
					break;
				}
				else
					--row;
			}
			// XXX: we should translate the weekdays

			if(row < _timer.includeDayOfWeek.count)
			{
				cell.textLabel.text = [_timer.includeDayOfWeek objectAtIndex:row];
				cell.accessoryType = UITableViewCellAccessoryCheckmark;
				cell.editingAccessoryType = UITableViewCellAccessoryCheckmark;
				break;
			}

			row -= _timer.includeDayOfWeek.count;
			cell.textLabel.text = [_timer.excludeDayOfWeek objectAtIndex:row];
			cell.accessoryType = UITableViewCellAccessoryNone;
			cell.editingAccessoryType = UITableViewCellAccessoryNone;
			break;
		}
	}

	return cell;
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
	// services, bouquets, filters can be removed
	switch(indexPath.section)
	{
		case servicesSection:
		case bouquetSection:
		case filterTitleSection:
		case filterSdescSection:
		case filterDescSection:
		case filterWeekdaySection:
			if(indexPath.row == 0)
				return UITableViewCellEditingStyleInsert;
			return UITableViewCellEditingStyleDelete;
		default:
			return UITableViewCellEditingStyleNone;
	}
}

- (BOOL)tableView:(UITableView *)tableView shouldIndentWhileEditingRowAtIndexPath:(NSIndexPath *)indexPath
{
	// services, bouquets, filters can be removed
	switch(indexPath.section)
	{
		case servicesSection:
		case bouquetSection:
		case filterTitleSection:
		case filterSdescSection:
		case filterDescSection:
		case filterWeekdaySection:
			return YES;
		default:
			return NO;
	}
}

- (NSIndexPath *)tableView:(UITableView *)tv willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	// TODO: implement
	return nil;
}

#pragma mark -
#pragma mark <EditableTableViewCellDelegate> Methods and editing management
#pragma mark -

- (BOOL)cellShouldBeginEditing:(EditableTableViewCell *)cell
{
	if(![cell isEqual:_titleCell])
		[_titleCell stopEditing];
	if(![cell isEqual:_matchCell])
		[_matchCell stopEditing];
	if(![cell isEqual:_maxdurationCell])
		[_maxdurationCell stopEditing];

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
	if(_titleCell.isInlineEditing)
		indexPath = [NSIndexPath indexPathForRow:0 inSection:0];
	else if(_matchCell.isInlineEditing)
		indexPath = [NSIndexPath indexPathForRow:0 inSection:1];
	else if(_maxdurationCell.isInlineEditing)
		indexPath = [NSIndexPath indexPathForRow:1 inSection:3];
	else return;

	if(UIInterfaceOrientationIsLandscape(self.interfaceOrientation))
		scrollPosition = UITableViewScrollPositionTop;
	[(UITableView *)self.view scrollToRowAtIndexPath:indexPath atScrollPosition:scrollPosition animated:YES];
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

- (void)viewDidDisappear:(BOOL)animated
{
	[_afterEventNavigationController release];
	[_afterEventViewController release];
	[_bouquetListController release];
	[_datePickerController release];
	[_datePickerNavigationController release];
	[_locationListController release];

	_afterEventNavigationController = nil;
	_afterEventViewController = nil;
	_bouquetListController = nil;
	_datePickerController = nil;
	_datePickerNavigationController = nil;
	_locationListController = nil;
}

#pragma mark -
#pragma mark Split view support
#pragma mark -

- (void)splitViewController:(MGSplitViewController*)svc willHideViewController:(UIViewController *)aViewController withBarButtonItem:(UIBarButtonItem*)barButtonItem forPopoverController: (UIPopoverController*)pc
{
	barButtonItem.title = aViewController.title;
	[_popoverButtonItem release];
	_popoverButtonItem = [barButtonItem retain];

	// assign popover button if there is no left button assigned.
	if(!self.navigationItem.leftBarButtonItem)
	{
		self.navigationItem.leftBarButtonItem = barButtonItem;
	}
	self.popoverController = pc;
}


// Called when the view is shown again in the split view, invalidating the button and popover controller.
- (void)splitViewController:(MGSplitViewController*)svc willShowViewController:(UIViewController *)aViewController invalidatingBarButtonItem:(UIBarButtonItem *)barButtonItem
{
	[_popoverButtonItem release];
	_popoverButtonItem = nil;
	if([self.navigationItem.leftBarButtonItem isEqual: barButtonItem])
	{
		[self.navigationItem setLeftBarButtonItem:nil animated:YES];
	}
	self.popoverController = nil;
}

@end
