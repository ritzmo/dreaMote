//
//  ConfigListController.m
//  dreaMote
//
//  Created by Moritz Venn on 09.03.08.
//  Copyright 2008-2010 Moritz Venn. All rights reserved.
//

#import "ConfigListController.h"

#import "RemoteConnectorObject.h"
#import "Constants.h"

#import "DisplayCell.h"

#import "ConfigViewController.h"

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
@end

@implementation ConfigListController

/* initialize */
- (id)init
{
	if((self = [super init]))
	{
		self.title = NSLocalizedString(@"Configuration", @"Default Title of ConfigListController");
		_connections = [[RemoteConnectorObject getConnections] retain];
		_shouldSave = NO;
		_viewWillReapper = NO;
	}
	return self;
}

/* dealloc */
- (void)dealloc
{
	[_connections release];
	[_vibrateInRC release];
	[_connectionTest release];
	[_simpleRemote release];

	[super dealloc];
}

/* layout */
- (void)loadView
{
	UITableView *tableView = [[UITableView alloc] initWithFrame:[[UIScreen mainScreen] applicationFrame] style:UITableViewStyleGrouped];
	tableView.delegate = self;
	tableView.dataSource = self;
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

	// in case the parent view draws with a custom color or gradient, use a transparent color
	_vibrateInRC.backgroundColor = [UIColor clearColor];
	_vibrateInRC.enabled = NO;

	// Connectivity test
	_connectionTest = [[UISwitch alloc] initWithFrame: CGRectMake(0, 0, 300, kSwitchButtonHeight)];
	[_connectionTest setOn: [[NSUserDefaults standardUserDefaults] boolForKey: kConnectionTest]];
	
	// in case the parent view draws with a custom color or gradient, use a transparent color
	_connectionTest.backgroundColor = [UIColor clearColor];
	_connectionTest.enabled = NO;
	
	// Simple remote
	_simpleRemote = [[UISwitch alloc] initWithFrame: CGRectMake(0, 0, 300, kSwitchButtonHeight)];
	[_simpleRemote setOn: [[NSUserDefaults standardUserDefaults] boolForKey: kPrefersSimpleRemote]];
	
	// in case the parent view draws with a custom color or gradient, use a transparent color
	_simpleRemote.backgroundColor = [UIColor clearColor];
	_simpleRemote.enabled = NO;

	// add edit button
	self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

/* (un)set editing */
- (void)setEditing:(BOOL)editing animated:(BOOL)animated
{
	[super setEditing: editing animated: animated];
	[(UITableView*)self.view setEditing: editing animated: animated];

	_vibrateInRC.enabled = editing;
	_connectionTest.enabled = editing;
	_simpleRemote.enabled = editing;

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

	// Save if supposed to
	if(!editing && _shouldSave)
	{
		[[NSUserDefaults standardUserDefaults] setBool: _vibrateInRC.on forKey: kVibratingRC];
		[[NSUserDefaults standardUserDefaults] setBool: _connectionTest.on forKey: kConnectionTest];
		[[NSUserDefaults standardUserDefaults] setBool: _simpleRemote.on forKey: kPrefersSimpleRemote];
	}

	// If we did not save this time we are supposed to save if this is opened again
	_shouldSave = YES;

	// Make sure the UITableView notices the changes we made
	[(UITableView*)self.view reloadData];
}

#pragma mark	-
#pragma mark		Table View
#pragma mark	-

/* select row */
- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	// Only do something in section 0
	if(indexPath.section != 0)
		return nil;

	// FIXME: seen some crashlogs which supposedly ran into this case...
	if([_connections count] <= indexPath.row)
	{
		NSLog(@"ERROR: about to select out of bounds, aborting...");
		return nil;
	}

	// Open ConfigViewController for selected item
	UIViewController *targetViewController = [ConfigViewController withConnection: [_connections objectAtIndex: indexPath.row]: indexPath.row];
	[self.navigationController pushViewController: targetViewController animated: YES];

	return indexPath;
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
			sourceCell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
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
			TABLEVIEWCELL_FONT(sourceCell) = [UIFont boldSystemFontOfSize:kTextViewFontSize-1];

			break;

		/* Misc configuration items */
		case 1:
			switch(row)
			{
				/* Simple remote */
				case 0:
					((DisplayCell *)sourceCell).nameLabel.text = NSLocalizedString(@"Simple Remote", @"");
					((DisplayCell *)sourceCell).view = _simpleRemote;
					break;
				/* Vibration */
				case 1:
					((DisplayCell *)sourceCell).nameLabel.text = NSLocalizedString(@"Vibrate in RC", @"");
					((DisplayCell *)sourceCell).view = _vibrateInRC;
					break;
				/* Connectivity check */
				case 2:
					((DisplayCell *)sourceCell).nameLabel.text = NSLocalizedString(@"Check Connectivity", @"");
					((DisplayCell *)sourceCell).view = _connectionTest;
					break;
				default:
					break;
			}
			break;
		default:
			break;
	}

	return sourceCell;
}

/* number of section */
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView 
{
	return 2;
}

/* number of rows in given section */
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section 
{
	if(section == 0)
	{
		if(self.editing)
			return [_connections count] + 1;
		return [_connections count];
	}
	return 3;
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
			[(UITableView *)self.view reloadData];
		}

		// Remove item
		[_connections removeObjectAtIndex: index];
		[tableView deleteRowsAtIndexPaths: [NSArray arrayWithObject: indexPath]
						 withRowAnimation: UITableViewRowAnimationFade];
	}
	// Add new connection
	else if(editingStyle == UITableViewCellEditingStyleInsert)
	{
		_viewWillReapper = YES;

		UIViewController *targetViewController = [ConfigViewController newConnection];
		[self.navigationController pushViewController: targetViewController animated: YES];
		[targetViewController release];
	}
}

#pragma mark - UIViewController delegate methods

/* about to appear */
- (void)viewWillAppear:(BOOL)animated
{
	// Fix defaults
	if(!_viewWillReapper)
		[_vibrateInRC setOn: [[NSUserDefaults standardUserDefaults] boolForKey: kVibratingRC]];

	// Assume we won't reappear, will be fixed if we actually do so
	_viewWillReapper = NO;

	// this UIViewController is about to re-appear, make sure we remove the current selection in our table view
	NSIndexPath *tableSelection = [(UITableView *)self.view indexPathForSelectedRow];
	[(UITableView *)self.view reloadData];
	[(UITableView *)self.view selectRowAtIndexPath:tableSelection animated:NO scrollPosition:UITableViewScrollPositionNone];
	[(UITableView *)self.view deselectRowAtIndexPath:tableSelection animated:YES];
}

/* about to hide */
- (void)viewWillDisappear:(BOOL)animated
{
	// XXX: I'd actually do this in background (e.g. viewDidDisappear) but this won't reset the editButtonItem
	if(self.editing && !_viewWillReapper)
	{
		_shouldSave = NO;
		[self setEditing: NO animated: YES];
	}
}

@end
