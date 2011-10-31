//
//  ConfigListController.m
//  dreaMote
//
//  Created by Moritz Venn on 09.03.08.
//  Copyright 2008-2011 Moritz Venn. All rights reserved.
//

#import "ConfigListController.h"

#import "Constants.h"
#import "NSArray+ArrayFromData.h"
#import "NSData+Base64.h"
#import "RemoteConnectorObject.h"
#import "UITableViewCell+EasyInit.h"

#import "DisplayCell.h"

#import "AboutDreamoteViewController.h"
#import "ConfigViewController.h"
#import "ConnectionListController.h"

#define kMultiEPGRowTag 99
#define kTimeoutRowTag 100
#define kHistoryLengthRowTag 101

enum sectionIds
{
	connectionSection = 0,
	settingsSection = 1,
	buttonSection = 2,
	maxSection = 3,
};

enum settingsRows
{
	simpleRemoteRow = 0,
	separateEventsRow = 1,
	vibrationRow = 2,
	timeoutRow = 3,
	historyLengthRow = 4,
#if IS_FULL()
	multiEpgRow = 5,
#endif
};

/*!
 @brief Private functions of ConfigListController.
 */
@interface ConfigListController()
/*!
 @brief Utility routine leveraged by 'cellForRowAtIndexPath' to determine which UITableViewCell
 to be used for a given index path.

 @param indexPath IndexPath
 @return UITableViewCell instance
 */
- (UITableViewCell *)obtainTableCellForIndexPath:(NSIndexPath *)indexPath;
- (void)simpleRemoteChanged:(id)sender;
- (void)vibrationChanged:(id)sender;
- (void)separateEventsChanged:(id)sender;
- (void)rereadData:(NSNotification *)note;

@property (nonatomic,strong) MBProgressHUD *progressHUD;
@end

/*!
 @brief AutoConfiguration related methods of ConfigListController.
 */
@interface ConfigListController(AutoConfiguration)
/*!
 @brief Start AutoConfiguration process.
 */
- (void)doAutoConfiguration;
@end

@implementation ConfigListController

@synthesize progressHUD;

/* initialize */
- (id)init
{
	if((self = [super init]))
	{
		self.title = NSLocalizedString(@"Configuration", @"Default Title of ConfigListController");
		_connections = [RemoteConnectorObject getConnections];

		// listen to changes in available connections
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(rereadData:) name:kReconnectNotification object:nil];
	}
	return self;
}

/* dealloc */
- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];

	((UITableView *)self.view).delegate = nil;
	((UITableView *)self.view).dataSource = nil;

	progressHUD.delegate = nil;
}

/* layout */
- (void)loadView
{
	UITableView *tableView = [[UITableView alloc] initWithFrame:[[UIScreen mainScreen] applicationFrame] style:UITableViewStyleGrouped];
	tableView.delegate = self;
	tableView.dataSource = self;
	tableView.allowsSelectionDuringEditing = YES;
	//tableView.rowHeight = 48.0;
	//tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;

	// setup our content view so that it auto-rotates along with the UViewController
	tableView.autoresizesSubviews = YES;
	tableView.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);

	self.view = tableView;

	// RC Vibration
	_vibrateInRC = [[UISwitch alloc] initWithFrame: CGRectMake(0, 0, 300, kSwitchButtonHeight)];
	[_vibrateInRC setOn: [[NSUserDefaults standardUserDefaults] boolForKey: kVibratingRC]];
	[_vibrateInRC addTarget:self action:@selector(vibrationChanged:) forControlEvents:UIControlEventValueChanged];

	// in case the parent view draws with a custom color or gradient, use a transparent color
	_vibrateInRC.backgroundColor = [UIColor clearColor];

	// Simple remote
	_simpleRemote = [[UISwitch alloc] initWithFrame: CGRectMake(0, 0, 300, kSwitchButtonHeight)];
	[_simpleRemote setOn: [[NSUserDefaults standardUserDefaults] boolForKey: kPrefersSimpleRemote]];
	[_simpleRemote addTarget:self action:@selector(simpleRemoteChanged:) forControlEvents:UIControlEventValueChanged];

	// in case the parent view draws with a custom color or gradient, use a transparent color
	_simpleRemote.backgroundColor = [UIColor clearColor];

	// Simple remote
	_sepEventsByDay = [[UISwitch alloc] initWithFrame: CGRectMake(0, 0, 300, kSwitchButtonHeight)];
	[_sepEventsByDay setOn: [[NSUserDefaults standardUserDefaults] boolForKey: kSeparateEpgByDay]];
	[_sepEventsByDay addTarget:self action:@selector(separateEventsChanged:) forControlEvents:UIControlEventValueChanged];
	_sepEventsByDay.backgroundColor = [UIColor clearColor];

	// add edit button
	self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)viewDidUnload
{
	SafeRetainAssign(_vibrateInRC, nil);
	SafeRetainAssign(_simpleRemote, nil);
	SafeRetainAssign(_sepEventsByDay, nil);

	[super viewDidUnload];
}

/* (un)set editing */
- (void)setEditing:(BOOL)editing animated:(BOOL)animated
{
	[super setEditing: editing animated: animated];

	/*_vibrateInRC.enabled = editing;
	_simpleRemote.enabled = editing;*/

	// Animate if requested
	if(animated)
	{
		if(editing)
		{
			[(UITableView*)self.view insertRowsAtIndexPaths: [NSArray arrayWithObject:
											[NSIndexPath indexPathForRow:0 inSection:0]]
							withRowAnimation: UITableViewRowAnimationFade];
		}
		else
		{
			[(UITableView*)self.view deleteRowsAtIndexPaths: [NSArray arrayWithObject:
											[NSIndexPath indexPathForRow:0 inSection:0]]
							withRowAnimation: UITableViewRowAnimationFade];
		}
	}
	else
	{
		[(UITableView*)self.view reloadData];
	}
	[(UITableView*)self.view setEditing: editing animated: animated];
}

- (void)simpleRemoteChanged:(id)sender
{
	[[NSUserDefaults standardUserDefaults] setBool: _simpleRemote.on forKey: kPrefersSimpleRemote];

	// we need to post a notification so the main view reloads the rc
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[[NSNotificationCenter defaultCenter] postNotificationName:kReconnectNotification object:self userInfo:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(rereadData:) name:kReconnectNotification object:nil];
}

- (void)vibrationChanged:(id)sender
{
	[[NSUserDefaults standardUserDefaults] setBool: _vibrateInRC.on forKey: kVibratingRC];
}

- (void)separateEventsChanged:(id)sender
{
	[[NSUserDefaults standardUserDefaults] setBool:_sepEventsByDay.on forKey:kSeparateEpgByDay];
}

- (void)rereadData:(NSNotification *)note
{
	_connections = [RemoteConnectorObject getConnections];

	// just in case, read them too
	[_vibrateInRC setOn:[[NSUserDefaults standardUserDefaults] boolForKey:kVibratingRC]];
	[_simpleRemote setOn:[[NSUserDefaults standardUserDefaults] boolForKey:kPrefersSimpleRemote]];
	[_sepEventsByDay setOn:[[NSUserDefaults standardUserDefaults] boolForKey:kSeparateEpgByDay]];

	[(UITableView *)self.view reloadData];
}

#pragma mark -
#pragma mark MultiEPGIntervalDelegate
#pragma mark -
#if IS_FULL()

- (void)didSetInterval
{
	NSInteger row = multiEpgRow;
	if(IS_IPAD() && vibrationRow < multiEpgRow)
		--row;
	NSIndexPath *idx = [NSIndexPath indexPathForRow:row inSection:settingsSection];

	[(UITableView *)self.view reloadRowsAtIndexPaths:[NSArray arrayWithObject:idx] withRowAnimation:UITableViewRowAnimationNone];
}

#endif
#pragma mark -
#pragma mark TimeoutSelection
#pragma mark -

- (void)didSetTimeout
{
	NSInteger row = timeoutRow;
	if(IS_IPAD() && vibrationRow < timeoutRow)
		--row;
	NSIndexPath *idx = [NSIndexPath indexPathForRow:row inSection:settingsSection];

	[(UITableView *)self.view reloadRowsAtIndexPaths:[NSArray arrayWithObject:idx] withRowAnimation:UITableViewRowAnimationNone];
}

#pragma mark -
#pragma mark SearchHistoryLengthEditorDelegate
#pragma mark -

- (void)didSetLength
{
	NSInteger row = historyLengthRow;
	if(IS_IPAD() && vibrationRow < historyLengthRow)
		--row;
	NSIndexPath *idx = [NSIndexPath indexPathForRow:row inSection:settingsSection];
	[(UITableView *)self.view reloadRowsAtIndexPaths:[NSArray arrayWithObject:idx] withRowAnimation:UITableViewRowAnimationNone];
}

#pragma mark	-
#pragma mark		Table View
#pragma mark	-

/* select row */
- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	if(indexPath.section == settingsSection)
	{
		UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
		if(cell.tag == kTimeoutRowTag
		   || cell.tag == kHistoryLengthRowTag
#if IS_FULL()
		   || cell.tag == kMultiEPGRowTag
#endif
		   )
			return indexPath;

		return nil;
	}
	return indexPath;
}

/* row was selected */
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	if(indexPath.section == buttonSection)
	{
		if(indexPath.row == 0)
		{
			UIViewController *welcomeController = [[AboutDreamoteViewController alloc] initWithWelcomeType:welcomeTypeFull];
			[self presentModalViewController:welcomeController animated:YES];
		}
		else if(indexPath.row == 1)
		{
			progressHUD = [[MBProgressHUD alloc] initWithView:self.view];
			progressHUD.delegate = self;
			[self.view addSubview: progressHUD];
			self.navigationItem.rightBarButtonItem.enabled = NO;
			[progressHUD setLabelText:NSLocalizedString(@"Searching…", @"Label of Progress HUD during AutoConfiguration")];
			[progressHUD setMode:MBProgressHUDModeIndeterminate];
			[progressHUD show:YES];
			progressHUD.taskInProgress = YES;

			[NSThread detachNewThreadSelector:@selector(doAutoConfiguration) toTarget:self withObject:nil];
		}
#if IS_LITE()
		else if(indexPath.row == 2)
		{
			NSUserDefaults *stdDefaults = [NSUserDefaults standardUserDefaults];
			NSData *data = [NSData dataWithContentsOfFile:[kConfigPath stringByExpandingTildeInPath]];
			NSString *importString = [data base64EncodedString];
			NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:
						@"dreaMote:///settings?import:%@&%@:%i&%@:%i&%@:%i&%@:%i&%@:%i&%@:%d&%@:%i",
										   importString,
										   kActiveConnection, [stdDefaults integerForKey:kActiveConnection],
										   kVibratingRC, [stdDefaults boolForKey: kVibratingRC],
										   kMessageTimeout, [stdDefaults integerForKey:kMessageTimeout],
										   kPrefersSimpleRemote, [stdDefaults boolForKey:kPrefersSimpleRemote],
										   kTimeoutKey, kTimeout,
										   kSearchHistoryLength, [stdDefaults integerForKey:kSearchHistoryLength],
										   kSeparateEpgByDay, [stdDefaults boolForKey:kSeparateEpgByDay]]];
			[[UIApplication sharedApplication] openURL:url];
		}
#endif
		[tableView deselectRowAtIndexPath:indexPath animated:YES];
	}
	else if(indexPath.section == connectionSection)
	{
		NSInteger upperBound = [_connections count];
		if(self.editing) ++upperBound;

		// FIXME: seen some crashlogs which supposedly ran into this case...
		if(indexPath.row < upperBound)
		{
			[RemoteConnectorObject cancelPendingOperations];

			// open ConfigViewController if editing
			if(self.editing)
			{
				// new connection
				if(indexPath.row == 0)
				{
					UIViewController *targetViewController = [ConfigViewController newConnection];
					[self.navigationController pushViewController: targetViewController animated: YES];
				}
				// edit existing one
				else
				{
					UIViewController *tvc = [ConfigViewController withConnection:[_connections objectAtIndex:indexPath.row-1] :indexPath.row-1];
					[self.navigationController pushViewController:tvc animated:YES];
				}
			}
			// else connect to this host
			else
			{
				const NSInteger connectedIdx = [RemoteConnectorObject getConnectedId];

				if(![RemoteConnectorObject connectTo:indexPath.row])
				{
					// error connecting... what now?
					UIAlertView *notification = [[UIAlertView alloc]
												 initWithTitle:NSLocalizedString(@"Error", @"")
													   message:NSLocalizedString(@"Unable to connect to host.\nPlease restart the application.", @"")
													  delegate:nil
											 cancelButtonTitle:@"OK"
											 otherButtonTitles:nil];
					[notification show];
				}
				// did connect
				else
				{
					const NSError *error = nil;
					const BOOL doAbort = ![[RemoteConnectorObject sharedRemoteConnector] isReachable:&error];
					// error without doAbort means e.g. old version
					if(error)
					{
						UIAlertView *notification = [[UIAlertView alloc]
													 initWithTitle:doAbort ? NSLocalizedString(@"Error", @"") : NSLocalizedString(@"Warning", @"")
													 message:[error localizedDescription]
													 delegate:nil
											cancelButtonTitle:@"OK"
											otherButtonTitles:nil];
						[notification show];
					}

					// not reachable
					if(doAbort)
					{
						[RemoteConnectorObject connectTo:connectedIdx];
						[tableView deselectRowAtIndexPath:indexPath animated:YES];
					}
					// connected to new host
					else if(connectedIdx != indexPath.row)
					{
						NSArray *reloads = [NSArray arrayWithObjects:[NSIndexPath indexPathForRow:connectedIdx inSection:0], indexPath, nil];
						[tableView reloadRowsAtIndexPaths:reloads withRowAnimation:UITableViewRowAnimationFade];

						// post notification
						[[NSNotificationCenter defaultCenter] removeObserver:self];
						[[NSNotificationCenter defaultCenter] postNotificationName:kReconnectNotification object:self userInfo:nil];
						[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(rereadData:) name:kReconnectNotification object:nil];
					}
					// connected to same host
					else
					{
						[tableView deselectRowAtIndexPath:indexPath animated:YES];
					}
				}
			}

		}
		else
		{
			NSLog(@"ERROR: about to select out of bounds, aborting...");
		}
	}
	else if(indexPath.section == settingsSection)
	{
		UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];

		if(cell.tag == kTimeoutRowTag)
		{
			TimeoutSelectionViewController *vc = [TimeoutSelectionViewController withTimeout:kTimeout];
			vc.delegate = self;
			if(IS_IPAD())
			{
				UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:vc];
				navController.modalPresentationStyle = vc.modalPresentationStyle;
				navController.modalPresentationStyle = vc.modalPresentationStyle;

				[self.navigationController presentModalViewController:navController animated:YES];
			}
			else
			{
				[self.navigationController pushViewController:vc animated:YES];
			}
		}
		else if(cell.tag == kHistoryLengthRowTag)
		{
			SearchHistoryLengthEditorController *vc = [SearchHistoryLengthEditorController withLength:[[NSUserDefaults standardUserDefaults] integerForKey:kSearchHistoryLength]];
			vc.delegate = self;
			if(IS_IPAD())
			{
				UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:vc];
				navController.modalPresentationStyle = vc.modalPresentationStyle;
				navController.modalPresentationStyle = vc.modalPresentationStyle;

				[self.navigationController presentModalViewController:navController animated:YES];
			}
			else
			{
				[self.navigationController pushViewController:vc animated:YES];
			}
		}
#if IS_FULL()
		else if(cell.tag == kMultiEPGRowTag)
		{
			NSNumber *timeInterval = [[NSUserDefaults standardUserDefaults] objectForKey:kMultiEPGInterval];
			MultiEPGIntervalViewController *vc = [MultiEPGIntervalViewController withInterval:[timeInterval integerValue] / 60];
			vc.delegate = self;
			if(IS_IPAD())
			{
				UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:vc];
				navController.modalPresentationStyle = vc.modalPresentationStyle;
				navController.modalPresentationStyle = vc.modalPresentationStyle;

				[self.navigationController presentModalViewController:navController animated:YES];
			}
			else
			{
				[self.navigationController pushViewController:vc animated:YES];
			}
		}
#endif
		[tableView deselectRowAtIndexPath:indexPath animated:YES];
	}
	else
		[tableView deselectRowAtIndexPath:indexPath animated:YES];
}

/* indent when editing? */
- (BOOL)tableView:(UITableView *)tableView shouldIndentWhileEditingRowAtIndexPath:(NSIndexPath *)indexPath
{
	// Only indent section 0
	return (indexPath.section == connectionSection);
}

/* cell for section */
- (UITableViewCell *)obtainTableCellForIndexPath:(NSIndexPath *)indexPath
{
	UITableViewCell *cell = nil;

	switch(indexPath.section)
	{
		case buttonSection:
		case connectionSection:
			cell = [UITableViewCell reusableTableViewCellInView:(UITableView *)self.view withIdentifier:kVanilla_ID];
			break;
		case settingsSection:
			cell = [DisplayCell reusableTableViewCellInView:(UITableView *)self.view withIdentifier:kDisplayCell_ID];
			((DisplayCell *)cell).nameLabel.adjustsFontSizeToFitWidth = NO;
			break;
		default:
			break;
	}

	return cell;
}

/* determine which UITableViewCell to be used on a given row. */
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	const NSInteger section = indexPath.section;
	NSInteger row = indexPath.row;
	NSString *hostTitle = nil;
	UITableViewCell *sourceCell = [self obtainTableCellForIndexPath:indexPath];

	// we are creating a new cell, setup its attributes
	switch(section)
	{
		/* Connections */
		case connectionSection:
			sourceCell.accessoryType = UITableViewCellAccessoryNone;
			sourceCell.editingAccessoryType = UITableViewCellAccessoryDisclosureIndicator;
			TABLEVIEWCELL_FONT(sourceCell) = [UIFont boldSystemFontOfSize:kTextViewFontSize-1];
			TABLEVIEWCELL_ALIGN(sourceCell) = UITextAlignmentLeft;

			/*!
			 @brief When editing we add a fake first item to the list so cover this here.
			 */
			if(self.editing)
			{
				// Setup fake item and abort
				if(row == 0)
				{
					TABLEVIEWCELL_IMAGE(sourceCell) = nil;
					TABLEVIEWCELL_TEXT(sourceCell) = NSLocalizedString(@"New Connection", @"");
					break;
				}

				// Fix index in list
				row--;
			}

			// Set image for cell
			if([[NSUserDefaults standardUserDefaults] integerForKey: kActiveConnection] == row)
				TABLEVIEWCELL_IMAGE(sourceCell) = [UIImage imageNamed:@"emblem-favorite.png"];
			else if([RemoteConnectorObject getConnectedId] == row)
				TABLEVIEWCELL_IMAGE(sourceCell) = [UIImage imageNamed:@"network-wired.png"];
			else
				TABLEVIEWCELL_IMAGE(sourceCell) = nil;

			// Title handling
			hostTitle = [(NSDictionary *)[_connections objectAtIndex: row] objectForKey: kRemoteName];
			if(![hostTitle length])
				hostTitle = [(NSDictionary *)[_connections objectAtIndex: row] objectForKey: kRemoteHost];
			TABLEVIEWCELL_TEXT(sourceCell) = hostTitle;

			break;

		/* Misc configuration items */
		case settingsSection:
			sourceCell.tag = 0;
			if(row >= vibrationRow && IS_IPAD())
				++row;

			switch(row)
			{
				/* Simple remote */
				case simpleRemoteRow:
					((DisplayCell *)sourceCell).nameLabel.text = NSLocalizedString(@"Simple Remote", @"");
					((DisplayCell *)sourceCell).view = _simpleRemote;
					break;
				/* Separate events by day */
				case separateEventsRow:
					((DisplayCell *)sourceCell).nameLabel.adjustsFontSizeToFitWidth = YES;
					((DisplayCell *)sourceCell).nameLabel.text = NSLocalizedString(@"Separate events by day", @"Toggle to enable sections in event lists");
					((DisplayCell *)sourceCell).view = _sepEventsByDay;
					break;
				/* Vibration */
				case vibrationRow:
					if(!IS_IPAD())
					{
						((DisplayCell *)sourceCell).nameLabel.text = NSLocalizedString(@"Vibrate in RC", @"");
						((DisplayCell *)sourceCell).view = _vibrateInRC;
					}
					break;
				/* Timeout */
				case timeoutRow:
				{
					UILabel *timeLabel = [[UILabel alloc] initWithFrame:CGRectZero];
					timeLabel.backgroundColor = [UIColor clearColor];
					timeLabel.font = [UIFont systemFontOfSize:kTextViewFontSize];
					timeLabel.textAlignment = UITextAlignmentRight;
					timeLabel.text = [NSString stringWithFormat:NSLocalizedString(@"%d sec", @"Seconds"), kTimeout];
					timeLabel.frame = CGRectMake(0, 0, [timeLabel sizeThatFits:timeLabel.bounds.size].width, kSwitchButtonHeight);;
					((DisplayCell *)sourceCell).nameLabel.text = NSLocalizedString(@"Connection Timeout", @"Configuration item to choose connection timeout");
					((DisplayCell *)sourceCell).view = timeLabel;
					sourceCell.tag = kTimeoutRowTag;
					break;
				}
				/* Search History Length */
				case historyLengthRow:
				{
					UILabel *lengthLabel = [[UILabel alloc] initWithFrame:CGRectZero];
					lengthLabel.backgroundColor = [UIColor clearColor];
					lengthLabel.font = [UIFont systemFontOfSize:kTextViewFontSize];
					lengthLabel.textAlignment = UITextAlignmentRight;
					lengthLabel.text = [NSString stringWithFormat:@"%d", [[NSUserDefaults standardUserDefaults] integerForKey:kSearchHistoryLength]];
					lengthLabel.frame = CGRectMake(0, 0, [lengthLabel sizeThatFits:lengthLabel.bounds.size].width, kSwitchButtonHeight);;
					sourceCell.textLabel.text = NSLocalizedString(@"Search History Length", @"Label of cell in config which gives search history length");
					((DisplayCell *)sourceCell).view = lengthLabel;
					sourceCell.tag = kHistoryLengthRowTag;
					break;
				}
#if IS_FULL()
				/* Multi-EPG interval */
				case multiEpgRow:
				{
					NSNumber *timeInterval = [[NSUserDefaults standardUserDefaults] objectForKey:kMultiEPGInterval];
					UILabel *timeLabel = [[UILabel alloc] initWithFrame:CGRectZero];
					timeLabel.backgroundColor = [UIColor clearColor];
					timeLabel.font = [UIFont systemFontOfSize:kTextViewFontSize];
					timeLabel.textAlignment = UITextAlignmentRight;
					timeLabel.text = [NSString stringWithFormat:NSLocalizedString(@"%d min", @"Minutes"), [timeInterval integerValue] / 60];
					timeLabel.frame = CGRectMake(0, 0, [timeLabel sizeThatFits:timeLabel.bounds.size].width, kSwitchButtonHeight);;
					((DisplayCell *)sourceCell).nameLabel.text = NSLocalizedString(@"Multi-EPG Interval", @"Configuration item to choose timespan displayed by MultiEPG");
					((DisplayCell *)sourceCell).view = timeLabel;
					sourceCell.tag = kMultiEPGRowTag;
					break;
				}
#endif
				default:
					break;
			}
			break;
		case buttonSection:
		{
			switch(row)
			{
				case 0:
					sourceCell.accessoryType = UITableViewCellAccessoryNone;
					TABLEVIEWCELL_FONT(sourceCell) = [UIFont boldSystemFontOfSize:kTextViewFontSize-1];
					TABLEVIEWCELL_IMAGE(sourceCell) = nil;
					TABLEVIEWCELL_ALIGN(sourceCell) = UITextAlignmentCenter;
					TABLEVIEWCELL_TEXT(sourceCell) = NSLocalizedString(@"Show Help", @"show welcome screen (help)");
					break;
				case 1:
					sourceCell.accessoryType = UITableViewCellAccessoryNone;
					TABLEVIEWCELL_FONT(sourceCell) = [UIFont boldSystemFontOfSize:kTextViewFontSize-1];
					TABLEVIEWCELL_IMAGE(sourceCell) = nil;
					TABLEVIEWCELL_ALIGN(sourceCell) = UITextAlignmentCenter;
					TABLEVIEWCELL_TEXT(sourceCell) = NSLocalizedString(@"Search Connections", @"Start AutoConfiguration from ConfigListController");
					break;
#if IS_LITE()
				case 2:
					sourceCell.accessoryType = UITableViewCellAccessoryNone;
					TABLEVIEWCELL_FONT(sourceCell) = [UIFont boldSystemFontOfSize:kTextViewFontSize-1];
					TABLEVIEWCELL_IMAGE(sourceCell) = nil;
					TABLEVIEWCELL_ALIGN(sourceCell) = UITextAlignmentCenter;
					TABLEVIEWCELL_TEXT(sourceCell) = NSLocalizedString(@"Export to dreaMote", @"export data from lite to full version");
					break;
#endif
				default: break;
			}
			break;
		}
		default:
			break;
	}
	return sourceCell;
}

/* number of section */
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return maxSection;
}

/* number of rows in given section */
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	switch(section)
	{
		case connectionSection:
			if(self.editing)
				return [_connections count] + 1;
			return [_connections count];
		case settingsSection:
		{
			NSInteger baseCount = (IS_IPAD()) ? 4 : 5;
#if IS_FULL()
			++baseCount;
#endif
			return baseCount;
		}
		case buttonSection:
#if IS_FULL()
			return 2;
#else
			return ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"dreaMote://"]]) ? 3 : 2;
#endif
		default:
			return 0;
	}
}

/* section header */
- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
	if(section == connectionSection)
		return NSLocalizedString(@"Configured Connections", @"");
	return nil;
}

/* rotate with device */
- (BOOL)shouldAutorotateToInterfaceOrientation: (UIInterfaceOrientation)interfaceOrientation
{
	return YES;
}

/* editing style */
- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
	// Only custom style in section 0
	if(indexPath.section != connectionSection)
		return UITableViewCellEditingStyleNone;

	// First row is fake "new connection" item
	if(indexPath.row == 0)
		return UITableViewCellEditingStyleInsert;
	return UITableViewCellEditingStyleDelete;
}

/* edit action */
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
	// If row is deleted, remove it from the list.
	if (editingStyle == UITableViewCellEditingStyleDelete)
	{
		NSUserDefaults *stdDefaults = [NSUserDefaults standardUserDefaults];
		NSInteger currentDefault = [stdDefaults integerForKey: kActiveConnection];
		NSInteger currentConnected = [RemoteConnectorObject getConnectedId];
		NSInteger index = indexPath.row;
		if(self.editing) --index;

		// Shift index
		if(currentDefault > index)
			[stdDefaults setObject: [NSNumber numberWithInteger: currentDefault - 1] forKey: kActiveConnection];
		// Default to 0 if current default connection removed
		else if(currentDefault == index)
		{
			[stdDefaults setObject: [NSNumber numberWithInteger: 0] forKey: kActiveConnection];
			[RemoteConnectorObject disconnect];
			[tableView reloadData];
		}
		// connected is removed
		if(currentConnected == index && currentConnected != currentDefault)
		{
			[RemoteConnectorObject disconnect];
			[tableView reloadData];
		}

		// Remove item
		[_connections removeObjectAtIndex: index];
		[tableView deleteRowsAtIndexPaths: [NSArray arrayWithObject: indexPath]
						 withRowAnimation: UITableViewRowAnimationFade];

		// post notification
		[[NSNotificationCenter defaultCenter] removeObserver:self];
		[[NSNotificationCenter defaultCenter] postNotificationName:kReconnectNotification object:self userInfo:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(rereadData:) name:kReconnectNotification object:nil];
	}
	// Add new connection
	else if(editingStyle == UITableViewCellEditingStyleInsert)
	{
		[tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
		UIViewController *targetViewController = [ConfigViewController newConnection];
		[self.navigationController pushViewController: targetViewController animated: YES];
	}
}

#pragma mark - UIViewController delegate methods

/* about to appear */
- (void)viewWillAppear:(BOOL)animated
{
	// this UIViewController is about to re-appear, make sure we remove the current selection in our table view
	NSIndexPath *tableSelection = [(UITableView *)self.view indexPathForSelectedRow];
	[(UITableView *)self.view reloadData];
	[(UITableView *)self.view selectRowAtIndexPath:tableSelection animated:NO scrollPosition:UITableViewScrollPositionNone];
	[(UITableView *)self.view deselectRowAtIndexPath:tableSelection animated:YES];

	// start bonjour search
	[RemoteConnectorObject start];
}

/* did hide */
- (void)viewDidDisappear:(BOOL)animated
{
	// in case we changed something, sometimes changes got lost
	[[NSUserDefaults standardUserDefaults] synchronize];

	// unset editing if not going into a subview
	if(self.editing && [(UITableView *)self.view indexPathForSelectedRow] == nil)
		[self setEditing:NO animated:animated];

	// end bonjour search
	[RemoteConnectorObject stop];
}

#pragma mark - ConnectionListDelegate methods

- (void)connectionSelected:(NSMutableDictionary *)dictionary
{
	UIViewController *tvc = [ConfigViewController withConnection:dictionary :-1];
	[self.navigationController pushViewController:tvc animated:YES];
}

#pragma mark -
#pragma mark MBProgressHUDDelegate
#pragma mark -

- (void)hudWasHidden:(MBProgressHUD *)hud
{
	self.navigationItem.rightBarButtonItem.enabled = YES;
	[progressHUD removeFromSuperview];
	self.progressHUD = nil;
}

#pragma mark AutoConfiguration

- (void)doAutoConfiguration
{
	@autoreleasepool {

		NSArray *connections = [RemoteConnectorObject autodetectConnections];

		progressHUD.taskInProgress = NO;
		[progressHUD hide:YES];

		NSUInteger len = connections.count;
		if(len == 0)
		{
			const UIAlertView *notification = [[UIAlertView alloc]
											   initWithTitle:NSLocalizedString(@"Error", @"")
											   message:NSLocalizedString(@"Unable to find valid connection data.", @"")
											   delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
			[notification show];
		}
		else
		{
			ConnectionListController *tv = [ConnectionListController newWithConnections:connections andDelegate:self];
			if(IS_IPAD())
			{
				UIViewController *nc = [[UINavigationController alloc] initWithRootViewController:tv];
				nc.modalPresentationStyle = tv.modalPresentationStyle;
				nc.modalTransitionStyle = tv.modalTransitionStyle;
				[self.navigationController presentModalViewController:nc animated:YES];
			}
			else
			{
				[self.navigationController pushViewController:tv animated:YES];
			}
		}

	}
}

@end
