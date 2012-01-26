//
//  EPGRefreshViewController.m
//  dreaMote
//
//  Created by Moritz Venn on 15.04.11.
//  Copyright 2011 Moritz Venn. All rights reserved.
//

#import "EPGRefreshViewController.h"

#import "BouquetListController.h"
#import "DatePickerController.h"
#import "ServiceListController.h"
#import "SimpleSingleSelectionListController.h"

#import "RemoteConnectorObject.h"
#import "Constants.h"

#import <TableViewCell/DisplayCell.h>
#import <TableViewCell/ServiceTableViewCell.h>

#import "NSDateFormatter+FuzzyFormatting.h"
#import "UITableViewCell+EasyInit.h"
#import "UIDevice+SystemVersion.h"

#import <Objects/Generic/Result.h>
#import <Objects/Generic/Service.h>

enum sectionIds
{
	startSection = 0,
	generalSection = 1,
	serviceSection = 2,
	bouquetSection = 3,
	maxSection = 4,
};

enum startSectionItems
{
	startRow = 0,
	lastscanRow = 1,
};

enum generalSectionItems
{
	enabledRow = 0,
	beginRow = 1,
	endRow = 2,
	adapterRow = 3,
	forceRow = 4,
	delay_standbyRow = 5,
	intervalRow = 6,
	wakeupRow = 7,
	aftereventRow = 8,
	inherit_autotimerRow = 9,
	parse_autotimerRow = 10,
	maxGeneralRow = 11,
};

/*!
 @brief Private functions of EPGRefreshViewController.
 */
@interface EPGRefreshViewController()
/*!
 @brief stop editing
 @param sender ui element
 */
- (void)cancelEdit:(id)sender;

@property (nonatomic, strong) UIPopoverController *popoverController;
@property (nonatomic, strong) EPGRefreshSettings *settings;
@property (unsafe_unretained, nonatomic, readonly) UIViewController *bouquetListController;
@property (unsafe_unretained, nonatomic, readonly) UIViewController *serviceListController;
@end

@implementation EPGRefreshViewController

@synthesize popoverController, settings;

- (id)init
{
	if((self = [super init]))
	{
		self.title = NSLocalizedString(@"EPGRefresh", @"Default title of EPGRefreshViewController");

		_dateFormatter = [[NSDateFormatter alloc] init];
		services = [[NSMutableArray alloc] init];
		bouquets = [[NSMutableArray alloc] init];
	}
	return self;
}

- (void)didReceiveMemoryWarning
{
	_bouquetListController = nil;
	_serviceListController = nil;

	[super didReceiveMemoryWarning];
}

#pragma mark -
#pragma mark Properties
#pragma mark -

- (UIViewController *)bouquetListController
{
	if(_bouquetListController == nil)
	{
		BouquetListController *rootViewController = [[BouquetListController alloc] init];
		[rootViewController setBouquetDelegate:self];

		if(IS_IPAD())
		{
			_bouquetListController = [[UINavigationController alloc] initWithRootViewController:rootViewController];
			_bouquetListController.modalPresentationStyle = rootViewController.modalPresentationStyle;
			_bouquetListController.modalPresentationStyle = rootViewController.modalPresentationStyle;

		}
		else
			_bouquetListController = rootViewController;
	}
	return _bouquetListController;
}

- (UIViewController *)serviceListController
{
	if(_serviceListController == nil)
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
			_serviceListController = [[UINavigationController alloc] initWithRootViewController:rootViewController];
			_serviceListController.modalPresentationStyle = rootViewController.modalPresentationStyle;
			_serviceListController.modalPresentationStyle = rootViewController.modalPresentationStyle;

		}
		else
			_serviceListController = rootViewController;
	}
	return _serviceListController;
}

#pragma mark -
#pragma mark Helper methods
#pragma mark -

- (NSString *)format_Time:(NSDate *)dateTime withDateStyle:(NSDateFormatterStyle)dateStyle
{
	NSString *dateString = nil;
	if(dateTime)
	{
		[_dateFormatter setDateStyle:dateStyle];
		[_dateFormatter setTimeStyle:NSDateFormatterShortStyle];
		dateString = [_dateFormatter fuzzyDate:dateTime];
	}
	else
		dateString = NSLocalizedString(@"unset", @"option (e.g. autotimer timespan, autotimer timeframe, manual vps time, ...) unset");
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
	field.placeholder = NSLocalizedStringFromTable(@"<time to stay on service>", @"EPGRefresh", @"Time to stay on service");
	return field;
}

- (UITextField *)newDelayField
{
	UITextField *field = [self allocTextField];
	field.text = [NSString stringWithFormat:@"%d", settings.delay_standby];
	field.placeholder = NSLocalizedStringFromTable(@"<delay if not in standby/in use>", @"EPGRefresh", @"Delay if not in standby/in use");
	return field;
}

- (NSString *)logicalToHumanReadableAdapterName:(NSString *)adapter
{
	if([adapter isEqualToString:@"pip"])
		return NSLocalizedStringFromTable(@"Picture in Picture", @"EPGRefresh", @"Adapter name");
	else if([adapter isEqualToString:@"pip_hidden"])
		return NSLocalizedStringFromTable(@"Picture in Picture (hidden)", @"EPGRefresh", @"Adapter name");
	else if([adapter isEqualToString:@"record"])
		return NSLocalizedStringFromTable(@"Fake Recording", @"EPGRefresh", @"Adapter name");

	return NSLocalizedStringFromTable(@"Main Picture", @"EPGRefresh", @"Adapter name");
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

	_interval = [self newIntervalField];
	_delay = [self newDelayField];

	// enabled
	_enabled = [[UISwitch alloc] initWithFrame:CGRectMake(0, 0, 300, kSwitchButtonHeight)];
	_enabled.on = settings.enabled;
	_enabled.backgroundColor = [UIColor clearColor];

	// force refresh
	_force = [[UISwitch alloc] initWithFrame:CGRectMake(0, 0, 300, kSwitchButtonHeight)];
	_force.on = settings.force;
	_force.backgroundColor = [UIColor clearColor];

	// wakeup for refresh
	_wakeup = [[UISwitch alloc] initWithFrame:CGRectMake(0, 0, 300, kSwitchButtonHeight)];
	_wakeup.on = settings.wakeup;
	_wakeup.backgroundColor = [UIColor clearColor];

	// shutdown after refresh
	_shutdown = [[UISwitch alloc] initWithFrame:CGRectMake(0, 0, 300, kSwitchButtonHeight)];
	_shutdown.on = settings.afterevent;
	_shutdown.backgroundColor = [UIColor clearColor];

	// inherit services from autotimer
	_inherit = [[UISwitch alloc] initWithFrame:CGRectMake(0, 0, 300, kSwitchButtonHeight)];
	_inherit.on = settings.inherit_autotimer;
	_inherit.backgroundColor = [UIColor clearColor];

	// parse autotimers after refresh
	_parse = [[UISwitch alloc] initWithFrame:CGRectMake(0, 0, 300, kSwitchButtonHeight)];
	_parse.on = settings.parse_autotimer;
	_parse.backgroundColor = [UIColor clearColor];

	[self setEditing:YES animated:YES];

	[self theme];
}

- (void)theme
{
	if([UIDevice newerThanIos:5.0f])
	{
		UIColor *tintColor = [DreamoteConfiguration singleton].tintColor;
		_enabled.onTintColor = tintColor;
		_force.onTintColor = tintColor;
		_wakeup.onTintColor = tintColor;
		_shutdown.onTintColor = tintColor;
		_inherit.onTintColor = tintColor;
		_parse.onTintColor = tintColor;
	}
	[super theme];
}

- (void)viewDidUnload
{
	_cancelButtonItem = nil;
	_interval = nil;
	 // depends on _interval
	_intervalCell = nil;
	_delay = nil;
	 // depends on _delay
	_delayCell = nil;
	_enabled = nil;
	_force = nil;
	_wakeup = nil;
	_shutdown = nil;
	_inherit = nil;
	_parse = nil;

	[super viewDidUnload];
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

		settings.enabled = _enabled.on;
		if(settings.enabled && !settings.begin && !settings.end)
		{
			message = NSLocalizedString(@"You have to provide a timespan to refresh automatically.", @"User requested automated EPG refresh but no timespan given.");
		}

		settings.force = _force.on;
		settings.wakeup = _wakeup.on;
		settings.afterevent = _shutdown.on;
		settings.inherit_autotimer = _inherit.on;
		settings.parse_autotimer = _parse.on;
		settings.interval = [_interval.text integerValue];
		settings.delay_standby = [_delay.text integerValue];

		// Try to commit changes if no error occured
		if(!message)
		{
			Result *result = [[RemoteConnectorObject sharedRemoteConnector] setEPGRefreshSettings:settings andServices:services andBouquets:bouquets];
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

		self.navigationItem.leftBarButtonItem = _popoverButtonItem;
	}
	else
	{
		self.navigationItem.leftBarButtonItem = _popoverButtonItem;
	}

	_shouldSave = editing;
	[super setEditing: editing animated: animated];
	[_tableView setEditing:editing animated:animated];

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
	[services removeAllObjects];
	[bouquets removeAllObjects];
	[_tableView reloadData];
}

- (void)fetchData
{
	pendingRequests = 2;
	_reloading = YES;
	[[RemoteConnectorObject sharedRemoteConnector] getEPGRefreshSettings:self];
	[[RemoteConnectorObject sharedRemoteConnector] getEPGRefreshServices:self];
}

#pragma mark -
#pragma mark DataSourceDelegate
#pragma mark -

- (void)dataSourceDelegate:(SaxXmlReader *)dataSource errorParsingDocument:(NSError *)error
{
	// show one error message at the most
	if(--pendingRequests == 0)
	{
		if([error domain] == NSURLErrorDomain)
		{
			if([error code] == 404)
			{
				const UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Failed to retrieve data", @"Title of Alert when retrieving remote data failed.")
																	  message:NSLocalizedString(@"Page not found.\nPlugin not installed?", @"Connection failure with 404 in AutoTimer/EPGRefresh. Plugin probably too old or not installed.")
																	 delegate:nil
															cancelButtonTitle:@"OK"
															otherButtonTitles:nil];
				[alert show];
				error = nil;
			}
		}
		[super dataSourceDelegate:dataSource errorParsingDocument:error];
	}
}

- (void)dataSourceDelegateFinishedParsingDocument:(SaxXmlReader *)dataSource
{
	if(--pendingRequests == 0)
	{
		_reloading = NO;
		[_refreshHeaderView egoRefreshScrollViewDataSourceDidFinishedLoading:_tableView];
		[_tableView reloadData];
	}
}

#pragma mark -
#pragma mark ServiceSourceDelegate
#pragma mark -

- (void)addService:(NSObject<ServiceProtocol> *)anItem
{
	// XXX: enigma2 specific code, but this is pretty much an enigma2-exclusive feature
	const NSArray *comps = [anItem.sref componentsSeparatedByString:@":"];
	const NSString *type = [comps objectAtIndex:1];
	if([type isEqualToString:@"7"]) // check if this is sane…
		[bouquets addObject:anItem];
	else
		[services addObject:anItem];
}

#pragma mark -
#pragma mark EPGRefreshSettingsDelegate
#pragma mark -

- (void)epgrefreshSettingsRead:(EPGRefreshSettings *)anItem
{
	self.settings = anItem;
	_enabled.on = settings.enabled;
	_force.on = settings.force;
	_wakeup.on = settings.wakeup;
	_shutdown.on = settings.afterevent;
	_inherit.on = settings.inherit_autotimer;
	_parse.on = settings.parse_autotimer;
	_interval.text = [NSString stringWithFormat:@"%d", settings.interval];
	_delay.text = [NSString stringWithFormat:@"%d", settings.delay_standby];
	/*UITableViewCell *cell = [_tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:beginRow inSection:generalSection]];
	cell.textLabel.text = [NSString stringWithFormat:NSLocalizedStringFromTable(@"From: %@", @"AutoTimer", @"timespan from"), [self format_Time:settings.begin withDateStyle:NSDateFormatterNoStyle]];
	cell = [_tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:endRow inSection:generalSection]];
	cell.textLabel.text = [NSString stringWithFormat:NSLocalizedStringFromTable(@"To: %@", @"AutoTimer", @"timespan to"), [self format_Time:settings.end withDateStyle:NSDateFormatterNoStyle]];*/
}

#pragma mark -
#pragma mark DatePickerController callbacks
#pragma mark -

- (void)fromSelected: (NSDate *)newDate
{
	if(newDate == nil)
		return;

	settings.begin = newDate;

	UITableViewCell *cell = [_tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:beginRow inSection:generalSection]];
	cell.textLabel.text = [NSString stringWithFormat:NSLocalizedStringFromTable(@"From: %@", @"AutoTimer", @"timespan from"), [self format_Time:newDate withDateStyle:NSDateFormatterNoStyle]];
}

- (void)toSelected: (NSDate *)newDate
{
	if(newDate == nil)
		return;

	settings.end = newDate;

	UITableViewCell *cell = [_tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:endRow inSection:generalSection]];
	cell.textLabel.text = [NSString stringWithFormat:NSLocalizedStringFromTable(@"To: %@", @"AutoTimer", @"timespan to"), [self format_Time:newDate withDateStyle:NSDateFormatterNoStyle]];
}

#pragma mark -
#pragma mark BouquetListDelegate methods
#pragma mark -

- (void)bouquetSelected:(NSObject<ServiceProtocol> *)newBouquet
{
	if(newBouquet == nil)
		return;

	for(NSObject<ServiceProtocol> *bouquet in bouquets)
	{
		if([bouquet isEqualToService:newBouquet]) return;
	}

	// copy service for convenience reasons
	[bouquets addObject:[newBouquet copy]];
	[_tableView reloadSections:[NSIndexSet indexSetWithIndex:bouquetSection] withRowAnimation:UITableViewRowAnimationFade];
}

#pragma mark -
#pragma mark ServiceListDelegate methods
#pragma mark -

- (void)serviceSelected: (NSObject<ServiceProtocol> *)newService
{
	if(newService == nil)
		return;

	for(NSObject<ServiceProtocol> *service in services)
	{
		if([service isEqualToService:newService]) return;
	}

	// copy service for convenience reasons
	[services addObject:[newService copy]];
	[_tableView reloadSections:[NSIndexSet indexSetWithIndex:serviceSection] withRowAnimation:UITableViewRowAnimationFade];
}

#pragma mark -
#pragma mark UITableView delegates
#pragma mark -

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return maxSection;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
	switch(section)
	{
		case serviceSection:
			if(!([services count] || self.editing))
				return 0.0001;
			return [[DreamoteConfiguration singleton] tableView:tableView heightForHeaderInSection:section];
		case bouquetSection:
			if(!([bouquets count] || self.editing))
				return 0.0001;
			/* FALL THROUGH */
		case generalSection:
			return [[DreamoteConfiguration singleton] tableView:tableView heightForHeaderInSection:section];
		case startSection:
			return 0; // we want some spacing at the top
		default:
			return 0.0001;
	}
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
	switch(section)
	{
		case serviceSection:
			if(!([services count] || self.editing))
				return nil;
			return [[DreamoteConfiguration singleton] tableView:tableView viewForHeaderInSection:section];
		case bouquetSection:
			if(!([bouquets count] || self.editing))
				return nil;
			/* FALL THROUGH */
		case generalSection:
			return [[DreamoteConfiguration singleton] tableView:tableView viewForHeaderInSection:section];
		default:
			return nil;
	}
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
	switch(section)
	{
		case generalSection:
			return NSLocalizedString(@"General", @"in timer settings dialog");
		case serviceSection:
			if(!([services count] || self.editing))
				return nil;
			return NSLocalizedStringFromTable(@"Services", @"EPGRefresh", @"section header for service to refresh");
		case bouquetSection:
			if(!([bouquets count] || self.editing))
				return nil;
			return NSLocalizedStringFromTable(@"Bouquets", @"EPGRefresh", @"section header for bouquet to refresh");
		default:
			return nil;
	}
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	switch(section)
	{
		case startSection:
			return (settings.lastscan > 0) ? 2 : 1;
		case generalSection:
		{
			NSInteger rowCount = maxGeneralRow;
			if(!settings.canDoBackgroundRefresh) --rowCount;
			if(!settings.hasAutoTimer) rowCount -= 2;
			return rowCount;
		}
		case serviceSection:
			return services.count + (self.editing ? 1 : 0);
		case bouquetSection:
			return bouquets.count + (self.editing ? 1 : 0);
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
		case startSection:
		{
			cell = [BaseTableViewCell reusableTableViewCellInView:tableView withIdentifier:kBaseCell_ID];
			cell.editingAccessoryType = UITableViewCellAccessoryNone;
			cell.textLabel.textAlignment = UITextAlignmentCenter;
			switch(row)
			{
				case startRow:
					cell.textLabel.font = [UIFont boldSystemFontOfSize:kTextViewFontSize-1];
					cell.textLabel.text = NSLocalizedStringFromTable(@"Start refresh", @"EPGRefresh", @"start manual refresh of epg");
					break;
				case lastscanRow:
					cell.textLabel.font = [UIFont systemFontOfSize:kTextViewFontSize-1];
					cell.textLabel.text = [NSString stringWithFormat:NSLocalizedStringFromTable(@"Last refresh: %@", @"EPGRefresh", @"Time of last refresh if given by remote end"), [self format_Time:[NSDate dateWithTimeIntervalSince1970:settings.lastscan] withDateStyle:NSDateFormatterShortStyle]];
					break;
			}
			break;
		}
		case generalSection:
		{
			// adjust row
			if(!settings.canDoBackgroundRefresh && row >= adapterRow) ++row;

			switch(row)
			{
				case enabledRow:
					cell = [DisplayCell reusableTableViewCellInView:tableView withIdentifier:kDisplayCell_ID];
					((DisplayCell *)cell).view = _enabled;
					cell.textLabel.text = NSLocalizedStringFromTable(@"Refresh automatically", @"EPGRefresh", @"Toggle 'Refresh EPG automatically'");
					break;
				case beginRow:
					cell = [BaseTableViewCell reusableTableViewCellInView:tableView withIdentifier:kBaseCell_ID];
					cell.editingAccessoryType = UITableViewCellAccessoryDisclosureIndicator;
					cell.textLabel.font = [UIFont systemFontOfSize:kTextViewFontSize];
					cell.textLabel.text = [NSString stringWithFormat:NSLocalizedStringFromTable(@"From: %@", @"AutoTimer", @"timespan from"), [self format_Time:settings.begin withDateStyle:NSDateFormatterNoStyle]];
					break;
				case endRow:
					cell = [BaseTableViewCell reusableTableViewCellInView:tableView withIdentifier:kBaseCell_ID];
					cell.editingAccessoryType = UITableViewCellAccessoryDisclosureIndicator;
					cell.textLabel.font = [UIFont systemFontOfSize:kTextViewFontSize];
					cell.textLabel.text = [NSString stringWithFormat:NSLocalizedStringFromTable(@"To: %@", @"AutoTimer", @"timespan to"), [self format_Time:settings.end withDateStyle:NSDateFormatterNoStyle]];
					break;
				case adapterRow:
					cell = [BaseTableViewCell reusableTableViewCellInView:tableView withIdentifier:kBaseCell_ID];
					cell.editingAccessoryType = UITableViewCellAccessoryDisclosureIndicator;
					cell.textLabel.font = [UIFont systemFontOfSize:kTextViewFontSize];
					cell.textLabel.adjustsFontSizeToFitWidth = YES;
					cell.textLabel.text = [NSString stringWithFormat:NSLocalizedStringFromTable(@"Refresh using: %@", @"EPGRefresh", @"Refresh using different Adapter"), [self logicalToHumanReadableAdapterName:settings.adapter]];
					break;
				case forceRow:
					cell = [DisplayCell reusableTableViewCellInView:tableView withIdentifier:kDisplayCell_ID];
					((DisplayCell *)cell).view = _force;
					cell.textLabel.text = NSLocalizedStringFromTable(@"Force refresh if in use", @"EPGRefresh", @"Force EPG refresh even if receiver is not in standby or timers are active");
					break;
				case delay_standbyRow:
					if(_delayCell == nil)
					{
						_delayCell = [[CellTextField alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
						_delayCell.view = _delay;
						_delayCell.textLabel.font = [UIFont systemFontOfSize:kTextViewFontSize];
						_delayCell.textLabel.text = NSLocalizedStringFromTable(@"Delay if busy (min.)", @"EPGRefresh", @"Label for cell 'delay refresh if not in standby (minutes)'");
						_delayCell.fixedWidth = 94.0f;
					}
					cell = _delayCell;
					break;
				case intervalRow:
					if(_intervalCell == nil)
					{
						_intervalCell = [[CellTextField alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
						_intervalCell.view = _interval;
						_intervalCell.textLabel.font = [UIFont systemFontOfSize:kTextViewFontSize];
						_intervalCell.fixedWidth = 94.0f;
					}
					// this could change, so always set this label not just on initialization
					if(settings.interval_in_seconds)
						_intervalCell.textLabel.text = NSLocalizedStringFromTable(@"Time on service (sec.)", @"EPGRefresh", @"Label for cell 'Time to stay on service (seconds)'");
					else
						_intervalCell.textLabel.text = NSLocalizedStringFromTable(@"Time on service (min.)", @"EPGRefresh", @"Label for cell 'Time to stay on service (minutes)'");
					cell = _intervalCell;
					break;
				case wakeupRow:
					cell = [DisplayCell reusableTableViewCellInView:tableView withIdentifier:kDisplayCell_ID];
					((DisplayCell *)cell).view = _wakeup;
					cell.textLabel.text = NSLocalizedStringFromTable(@"Wakeup for refresh", @"EPGRefresh", @"Wakeup from Deep Standby for EPG refresh");
					break;
				case aftereventRow:
					cell = [DisplayCell reusableTableViewCellInView:tableView withIdentifier:kDisplayCell_ID];
					((DisplayCell *)cell).view = _shutdown;
					cell.textLabel.text = NSLocalizedStringFromTable(@"Shutdown after refresh", @"EPGRefresh", @"Shutdown after refreshing EPG");
					break;
				case inherit_autotimerRow:
					cell = [DisplayCell reusableTableViewCellInView:tableView withIdentifier:kDisplayCell_ID];
					((DisplayCell *)cell).view = _inherit;
					cell.textLabel.text = NSLocalizedStringFromTable(@"Add AutoTimer services", @"EPGRefresh", @"Inherit services from AutoTimer");
					break;
				case parse_autotimerRow:
					cell = [DisplayCell reusableTableViewCellInView:tableView withIdentifier:kDisplayCell_ID];
					((DisplayCell *)cell).view = _parse;
					cell.textLabel.text = NSLocalizedStringFromTable(@"Parse AutoTimer", @"EPGRefresh", @"Search EPG for AutoTimers after refresh");
					break;
				default:
					break;
			}
			break;
		}
		case serviceSection:
		{
			if(self.editing)
			{
				if(row == 0)
				{
					cell = [BaseTableViewCell reusableTableViewCellInView:tableView withIdentifier:kBaseCell_ID];
					cell.textLabel.text = NSLocalizedStringFromTable(@"New Service", @"AutoTimer", @"add new service filter");
					cell.textLabel.textAlignment = UITextAlignmentLeft;
					cell.editingAccessoryType = UITableViewCellAccessoryDisclosureIndicator;
					cell.textLabel.font = [UIFont systemFontOfSize:kTextViewFontSize];
					break;
				}
				else
					--row;
			}

			cell = [ServiceTableViewCell reusableTableViewCellInView:tableView withIdentifier:kServiceCell_ID];
			((ServiceTableViewCell *)cell).font = [UIFont systemFontOfSize:kTextViewFontSize];
			((ServiceTableViewCell *)cell).service = [services objectAtIndex:row];
			cell.accessoryType = UITableViewCellAccessoryNone;
			cell.editingAccessoryType = UITableViewCellAccessoryNone;
			break;
		}
		case bouquetSection:
		{
			if(self.editing)
			{
				if(row == 0)
				{
					cell = [BaseTableViewCell reusableTableViewCellInView:tableView withIdentifier:kBaseCell_ID];
					cell.textLabel.text = NSLocalizedStringFromTable(@"New Bouquet", @"AutoTimer", @"add new bouquet filter");
					cell.textLabel.textAlignment = UITextAlignmentLeft;
					cell.editingAccessoryType = UITableViewCellAccessoryDisclosureIndicator;
					cell.textLabel.font = [UIFont systemFontOfSize:kTextViewFontSize];
					break;
				}
				else
					--row;
			}

			cell = [ServiceTableViewCell reusableTableViewCellInView:tableView withIdentifier:kServiceCell_ID];
			((ServiceTableViewCell *)cell).font = [UIFont systemFontOfSize:kTextViewFontSize];
			((ServiceTableViewCell *)cell).service = [bouquets objectAtIndex:row];
			cell.accessoryType = UITableViewCellAccessoryNone;
			cell.editingAccessoryType = UITableViewCellAccessoryNone;
			break;
		}
	}

	[[DreamoteConfiguration singleton] styleTableViewCell:cell inTableView:tableView];
	return cell;
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
	if(!tableView.editing)
		return UITableViewCellEditingStyleNone;

	// services, bouquets, filters can be removed
	switch(indexPath.section)
	{
		case serviceSection:
		case bouquetSection:
			if(tableView.editing && indexPath.row == 0)
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
		case serviceSection:
		case bouquetSection:
			return YES;
		default:
			return NO;
	}
}

- (void)tableView:(UITableView *)tv commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
	UIViewController *targetViewController = nil;
	NSUInteger row = indexPath.row;
	if(tv.editing) --row;

	switch(indexPath.section)
	{
		case serviceSection:
		{
			if(editingStyle == UITableViewCellEditingStyleInsert)
			{
				targetViewController = self.serviceListController;
			}
			else
			{
				[services removeObjectAtIndex:row];
				[tv deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath]
						  withRowAnimation:UITableViewRowAnimationFade];
			}
			break;
		}
		case bouquetSection:
		{
			if(editingStyle == UITableViewCellEditingStyleInsert)
			{
				targetViewController = self.bouquetListController;
			}
			else
			{
				[bouquets removeObjectAtIndex:row];
				[tv deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath]
						  withRowAnimation:UITableViewRowAnimationFade];
			}
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
			_willReappear = YES;
			[self.navigationController pushViewController: targetViewController animated:YES];
		}
	}
}

- (void)tableView:(UITableView *)tv didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	NSUInteger row = indexPath.row;
	UIViewController *targetViewController = nil;
	switch(indexPath.section)
	{
		case startSection:
		{
			if(indexPath.row != startRow) break;

			Result *result = [[RemoteConnectorObject sharedRemoteConnector] startEPGRefresh];
			if(!result.result)
			{
				const UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error", @"")
																	  message:[NSString stringWithFormat:NSLocalizedString(@"Received response: %@.", @"Generic Placeholder for system-supplied error (and possibly success) messages"), result.resulttext]
																	 delegate:nil
															cancelButtonTitle:@"OK"
															otherButtonTitles:nil];
				[alert show];
			}
			break;
		}
		case generalSection:
		{
			// adjust row
			if(!settings.canDoBackgroundRefresh && row >= adapterRow) ++row;

			if(row == beginRow || row == endRow)
			{
				DatePickerController *vc = [[DatePickerController alloc] init];
				if(IS_IPAD())
				{
					targetViewController = [[UINavigationController alloc] initWithRootViewController:vc];
					targetViewController.modalPresentationStyle = vc.modalPresentationStyle;
					targetViewController.modalTransitionStyle = vc.modalTransitionStyle;
				}
				else
					targetViewController = vc;

				if(row == beginRow)
				{
					vc.date = [settings.begin copy];
					vc.callback = ^(NSDate *date){[self fromSelected:date];};
				}
				else if(row == endRow)
				{
					vc.date = [settings.end copy];
					vc.callback = ^(NSDate *date){[self toSelected:date];};
				}
			}
			else if(row == adapterRow)
			{
				const BOOL isIpad = IS_IPAD();
				NSArray *lookupTable = [NSArray arrayWithObjects:@"main", @"pip", @"pip_hidden", @"record", nil];
				SimpleSingleSelectionListController *vc = [SimpleSingleSelectionListController withItems:
														   [NSArray arrayWithObjects:
															NSLocalizedStringFromTable(@"Main Picture", @"EPGRefresh", @"Adapter name"),
															NSLocalizedStringFromTable(@"Picture in Picture", @"EPGRefresh", @"Adapter name"),
															NSLocalizedStringFromTable(@"Picture in Picture (hidden)", @"EPGRefresh", @"Adapter name"),
															NSLocalizedStringFromTable(@"Fake Recording", @"EPGRefresh", @"Adapter name"), nil]
																							andSelection:[lookupTable indexOfObject:settings.adapter]
																								andTitle:NSLocalizedString(@"EPGRefresh Adapter", @"Default title of EPGRefreshAdapterViewController")];
				vc.callback = ^(NSUInteger selection, BOOL isFinal, BOOL canceling)
				{
					if(!canceling)
					{
						if(!isIpad && !isFinal)
							return NO;

						settings.adapter = [lookupTable objectAtIndex:selection];
						UITableViewCell *cell = [tv cellForRowAtIndexPath:indexPath];
						cell.textLabel.text = [NSString stringWithFormat:NSLocalizedStringFromTable(@"Refresh using: %@", @"EPGRefresh", @"Refresh using different Adapter"), [self logicalToHumanReadableAdapterName:settings.adapter]];
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
			}
			break;
		}
		case serviceSection:
			if(self.editing && row == 0)
				targetViewController = self.serviceListController;
			break;
		case bouquetSection:
			if(self.editing && row == 0)
				targetViewController = self.bouquetListController;
			break;
		default:
			break;
	}

	if(targetViewController)
	{
		if(IS_IPAD())
			[self.navigationController presentModalViewController:targetViewController animated:YES];
		else
		{
			_willReappear = YES;
			[self.navigationController pushViewController: targetViewController animated:YES];
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
	if(![cell isEqual:_delayCell])
		[_delayCell stopEditing];

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
		indexPath = [NSIndexPath indexPathForRow:intervalRow inSection:generalSection];
	else if(_delayCell.isInlineEditing)
		indexPath = [NSIndexPath indexPathForRow:delay_standbyRow inSection:generalSection];
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

	if(!_willReappear)
	{
		[self emptyData];
		[RemoteConnectorObject queueInvocationWithTarget:self selector:@selector(fetchData)];
	}
	_willReappear = NO;
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
	_bouquetListController = nil;
	_serviceListController = nil;
}

#pragma mark -
#pragma mark Split view support
#pragma mark -

- (void)splitViewController:(MGSplitViewController*)svc willHideViewController:(UIViewController *)aViewController withBarButtonItem:(UIBarButtonItem*)barButtonItem forPopoverController: (UIPopoverController*)pc
{
	barButtonItem.title = aViewController.title;
	// HACK: force-remove background color
	if([aViewController isKindOfClass:[UINavigationController class]])
		aViewController.view.backgroundColor = nil;
	_popoverButtonItem = barButtonItem;

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
	if([aViewController isKindOfClass:[UINavigationController class]])
	{
		UIViewController *visibleViewController = ((UINavigationController *)aViewController).visibleViewController;
		if([visibleViewController respondsToSelector:@selector(tableView)])
		{
			UITableView *tableView = ((ReloadableListController *)visibleViewController).tableView;
			aViewController.view.backgroundColor = tableView.backgroundColor;
		}
	}

	_popoverButtonItem = nil;
	if([self.navigationItem.leftBarButtonItem isEqual: barButtonItem])
	{
		[self.navigationItem setLeftBarButtonItem:nil animated:YES];
	}
	self.popoverController = nil;
}

@end
