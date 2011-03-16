//
//  ConfigListController.m
//  dreaMote
//
//  Created by Moritz Venn on 09.03.08.
//  Copyright 2008-2011 Moritz Venn. All rights reserved.
//

#import "ConfigListController.h"

#import "NSArray+ArrayFromData.h"
#import "NSData+Base64.h"
#import "RemoteConnectorObject.h"
#import "Constants.h"

#import "DisplayCell.h"

#import "AboutDreamoteViewController.h"
#import "ConfigViewController.h"

#define kMultiEPGRowTag 99

/*!
 @brief Private functions of ConfigListController.
 */
@interface ConfigListController()
/*!
 @brief Utility routine leveraged by 'cellForRowAtIndexPath' to determine which UITableViewCell
 to be used on a given section.
 
 @param section Section
 @return UITableViewCell instance
 */
- (UITableViewCell *)obtainTableCellForSection:(NSInteger)section;
- (void)simpleRemoteChanged:(id)sender;
- (void)vibrationChanged:(id)sender;
- (void)rereadData:(NSNotification *)note;
@end

@implementation ConfigListController

/* initialize */
- (id)init
{
	if((self = [super init]))
	{
		self.title = NSLocalizedString(@"Configuration", @"Default Title of ConfigListController");
		_connections = [[RemoteConnectorObject getConnections] retain];

		// listen to changes in available connections
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(rereadData:) name:kReconnectNotification object:nil];
	}
	return self;
}

/* dealloc */
- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];

	[_connections release];
	[_vibrateInRC release];
	[_simpleRemote release];

	[super dealloc];
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
	[tableView release];
	
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

	// add edit button
	self.navigationItem.rightBarButtonItem = self.editButtonItem;
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
	[[NSNotificationCenter defaultCenter] postNotificationName:kReconnectNotification object:self userInfo:nil];
}

- (void)vibrationChanged:(id)sender
{
	[[NSUserDefaults standardUserDefaults] setBool: _vibrateInRC.on forKey: kVibratingRC];
}

- (void)rereadData:(NSNotification *)note
{
	[_connections release];
	_connections = [[RemoteConnectorObject getConnections] retain];

	// just in case, read them too
	[_vibrateInRC setOn: [[NSUserDefaults standardUserDefaults] boolForKey: kVibratingRC]];
	[_simpleRemote setOn: [[NSUserDefaults standardUserDefaults] boolForKey: kPrefersSimpleRemote]];

	[(UITableView *)self.view reloadData];
}

#pragma mark -
#pragma mark MultiEPGIntervalDelegate
#pragma mark -

- (void)didSetInterval
{
	NSIndexPath *idx = nil;
	if(IS_IPAD())
		idx = [NSIndexPath indexPathForRow:1 inSection:1];
	else
		idx = [NSIndexPath indexPathForRow:2 inSection:1];

	[(UITableView *)self.view reloadRowsAtIndexPaths:[NSArray arrayWithObject:idx] withRowAnimation:UITableViewRowAnimationNone];
}

#pragma mark	-
#pragma mark		Table View
#pragma mark	-

/* select row */
- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	if(indexPath.section == 1)
	{
#if IS_FULL()
		UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
		if(cell.tag == kMultiEPGRowTag)
			return indexPath;
#endif
		return nil;
	}
	return indexPath;
}

/* row was selected */
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	if(indexPath.section == 2)
	{
		if(indexPath.row == 0)
		{
			UIViewController *welcomeController = [[AboutDreamoteViewController alloc] initWithWelcomeType:welcomeTypeFull];
			[self presentModalViewController:welcomeController animated:YES];
			[welcomeController release];
			[tableView deselectRowAtIndexPath:indexPath animated:YES];
		}
#if IS_LITE()
		else if(indexPath.row == 1)
		{
			NSUserDefaults *stdDefaults = [NSUserDefaults standardUserDefaults];
			NSData *data = [NSData dataWithContentsOfFile:[kConfigPath stringByExpandingTildeInPath]];
			NSString *importString = [data base64EncodedString];
			NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:
						@"dreaMote:///settings?import:%@&%@:%i&%@:%i&%@:%i&%@:%i",
										   importString,
										   kActiveConnection, [stdDefaults integerForKey:kActiveConnection],
										   kVibratingRC, [stdDefaults boolForKey: kVibratingRC],
										   kMessageTimeout, [stdDefaults integerForKey:kMessageTimeout],
										   kPrefersSimpleRemote, [stdDefaults boolForKey:kPrefersSimpleRemote]]];
			[[UIApplication sharedApplication] openURL:url];
		}
#endif
	}
	else if(indexPath.section == 0)
	{
		NSUInteger upperBound = [_connections count];
		if(self.editing) ++upperBound;

		// FIXME: seen some crashlogs which supposedly ran into this case...
		if(indexPath.row < upperBound)
		{
			// open ConfigViewController if editing
			if(self.editing)
			{
				// new connection
				if(indexPath.row == 0)
				{
					UIViewController *targetViewController = [ConfigViewController newConnection];
					[self.navigationController pushViewController: targetViewController animated: YES];
					[targetViewController release];
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
				const NSUInteger connectedIdx = [RemoteConnectorObject getConnectedId];

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
					[notification release];
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
						[notification release];
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
						[[NSNotificationCenter defaultCenter] postNotificationName:kReconnectNotification object:self userInfo:nil];
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
#if IS_FULL()
	else if(indexPath.section == 1)
	{
		UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
		if(cell.tag == kMultiEPGRowTag)
		{
			NSNumber *timeInterval = [[NSUserDefaults standardUserDefaults] objectForKey:kMultiEPGInterval];
			MultiEPGIntervalViewController *vc = [MultiEPGIntervalViewController withInterval:[timeInterval integerValue] / 60];
			[vc setDelegate:self];
			if(IS_IPAD())
			{
				UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:vc];
				navController.modalPresentationStyle = vc.modalPresentationStyle;
				navController.modalPresentationStyle = vc.modalPresentationStyle;

				[self.navigationController presentModalViewController:navController animated:YES];
				[navController release];
			}
			else
			{
				[self.navigationController pushViewController:vc animated:YES];
			}
		}

		[tableView deselectRowAtIndexPath:indexPath animated:YES];
	}
#endif
	else
		[tableView deselectRowAtIndexPath:indexPath animated:YES];
}

/* indent when editing? */
- (BOOL)tableView:(UITableView *)tableView shouldIndentWhileEditingRowAtIndexPath:(NSIndexPath *)indexPath
{
	// Only indent section 0
	return (indexPath.section == 0);
}

/* cell for section */
- (UITableViewCell *)obtainTableCellForSection:(NSInteger)section
{
	UITableViewCell *cell = nil;

	switch(section)
	{
		case 2:
		case 0:
			cell = [(UITableView *)self.view dequeueReusableCellWithIdentifier: kVanilla_ID];
			if (cell == nil) 
				cell = [[[UITableViewCell alloc] initWithFrame: CGRectZero reuseIdentifier: kVanilla_ID] autorelease];
			break;
		case 1:
			cell = [(UITableView *)self.view dequeueReusableCellWithIdentifier: kDisplayCell_ID];
			if(cell == nil)
				cell = [[[DisplayCell alloc] initWithFrame:CGRectZero reuseIdentifier:kDisplayCell_ID] autorelease];
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
	UITableViewCell *sourceCell = [self obtainTableCellForSection: section];
	
	// we are creating a new cell, setup its attributes
	switch(section)
	{
		/* Connections */
		case 0:
			sourceCell.accessoryType = UITableViewCellAccessoryNone;
			sourceCell.editingAccessoryType = UITableViewCellAccessoryDisclosureIndicator;
			TABLEVIEWCELL_FONT(sourceCell) = [UIFont boldSystemFontOfSize:kTextViewFontSize-1];

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
		case 1:
			sourceCell.tag = 0;
			switch(row)
			{
				/* Simple remote */
				case 0:
					((DisplayCell *)sourceCell).nameLabel.text = NSLocalizedString(@"Simple Remote", @"");
					((DisplayCell *)sourceCell).view = _simpleRemote;
					break;
				/* Vibration */
				case 1:
					if(!IS_IPAD())
					{
						((DisplayCell *)sourceCell).nameLabel.text = NSLocalizedString(@"Vibrate in RC", @"");
						((DisplayCell *)sourceCell).view = _vibrateInRC;
						break;
					}
					/* FALL THROUGH */
#if IS_FULL()
				/* Multi-EPG interval */
				case 2:
				{
					NSNumber *timeInterval = [[NSUserDefaults standardUserDefaults] objectForKey:kMultiEPGInterval];
					UILabel *timeLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 300, kSwitchButtonHeight)];
					timeLabel.font = [UIFont systemFontOfSize:kTextViewFontSize];
					timeLabel.textAlignment = UITextAlignmentRight;
					timeLabel.text = [NSString stringWithFormat:NSLocalizedString(@"%d min", @"Minutes"), [timeInterval integerValue] / 60];
					((DisplayCell *)sourceCell).nameLabel.text = NSLocalizedString(@"Multi-EPG Interval", @"Configuration item to choose timespan displayed by MultiEPG");
					((DisplayCell *)sourceCell).view = timeLabel;
					sourceCell.tag = kMultiEPGRowTag;
					[timeLabel release];
					break;
				}
#endif
				default:
					break;
			}
			break;
		case 2:
#if IS_LITE()
			if(row == 1)
			{
				sourceCell.accessoryType = UITableViewCellAccessoryNone;
				TABLEVIEWCELL_FONT(sourceCell) = [UIFont boldSystemFontOfSize:kTextViewFontSize-1];
				TABLEVIEWCELL_IMAGE(sourceCell) = nil;
				TABLEVIEWCELL_ALIGN(sourceCell) = UITextAlignmentCenter;
				TABLEVIEWCELL_TEXT(sourceCell) = NSLocalizedString(@"Export to dreaMote", @"export data from lite to full version");
				break;
			}
#endif
			sourceCell.accessoryType = UITableViewCellAccessoryNone;
			TABLEVIEWCELL_FONT(sourceCell) = [UIFont boldSystemFontOfSize:kTextViewFontSize-1];
			TABLEVIEWCELL_IMAGE(sourceCell) = nil;
			TABLEVIEWCELL_ALIGN(sourceCell) = UITextAlignmentCenter;
			TABLEVIEWCELL_TEXT(sourceCell) = NSLocalizedString(@"Show Help", @"show welcome screen (help)");
			break;
		default:
			break;
	}

	return sourceCell;
}

/* number of section */
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView 
{
	return 3;
}

/* number of rows in given section */
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section 
{
	switch(section)
	{
		case 0:
			if(self.editing)
				return [_connections count] + 1;
			return [_connections count];
		case 1:
		{
			NSInteger baseCount = (IS_IPAD()) ? 1 : 2;
#if IS_FULL()
			++baseCount;
#endif
			return baseCount;
		}
		case 2:
#if IS_FULL()
			return 1;
#else
			return ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"dreaMote://"]]) ? 2 : 1;
#endif
		default:
			return 0;
	}
}

/* section header */
- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
	if(section == 0)
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
	if(indexPath.section != 0)
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
		[[NSNotificationCenter defaultCenter] postNotificationName:kReconnectNotification object:self userInfo:nil];
	}
	// Add new connection
	else if(editingStyle == UITableViewCellEditingStyleInsert)
	{
		[tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
		UIViewController *targetViewController = [ConfigViewController newConnection];
		[self.navigationController pushViewController: targetViewController animated: YES];
		[targetViewController release];
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
}

/* did hide */
- (void)viewDidDisappear:(BOOL)animated
{
	// in case we changed something, sometimes changes got lost
	[[NSUserDefaults standardUserDefaults] synchronize];

	// unset editing if not going into a subview
	if(self.editing && [(UITableView *)self.view indexPathForSelectedRow] == nil)
		[self setEditing:NO animated:animated];
}

@end
