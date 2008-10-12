//
//  ConfigListController.m
//  Untitled
//
//  Created by Moritz Venn on 09.03.08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "ConfigListController.h"

#import "RemoteConnectorObject.h"
#import "Constants.h"

#import "DisplayCell.h"

#import "ConfigViewController.h"

@implementation ConfigListController

- (id)init
{
	self = [super init];
	if (self) {
		self.title = NSLocalizedString(@"Configuration", @"Default Title of ConfigListController");
		_connections = [[RemoteConnectorObject getConnections] retain];
	}
	return self;
}

- (void)dealloc
{
	[_connections release];

	[super dealloc];
}

- (void)loadView
{
	self.navigationItem.rightBarButtonItem = self.editButtonItem;

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
	vibrateInRC = [[UISwitch alloc] initWithFrame: CGRectMake(0, 0, 300, kSwitchButtonHeight)];
	[vibrateInRC setOn: [[NSUserDefaults standardUserDefaults] boolForKey: kVibratingRC]];

	// in case the parent view draws with a custom color or gradient, use a transparent color
	vibrateInRC.backgroundColor = [UIColor clearColor];
	vibrateInRC.enabled = NO;
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated;
{
	[super setEditing: editing animated: animated];
	[(UITableView*)self.view setEditing: editing animated: animated];

	vibrateInRC.enabled = editing;

	if(editing)
	{
		[(UITableView*)self.view insertRowsAtIndexPaths: [NSArray arrayWithObject: [NSIndexPath indexPathForRow:0 inSection:0]]
						 withRowAnimation: UITableViewRowAnimationFade];
	}
	else
	{
		[(UITableView*)self.view deleteRowsAtIndexPaths: [NSArray arrayWithObject: [NSIndexPath indexPathForRow:0 inSection:0]]
						 withRowAnimation: UITableViewRowAnimationFade];

		[[NSUserDefaults standardUserDefaults] setBool: vibrateInRC.on forKey: kVibratingRC];
	}
	
	[(UITableView*)self.view reloadData];
}

#pragma mark	-
#pragma mark		Table View
#pragma mark	-

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	if(indexPath.section != 0)
		return nil;

	UIViewController *targetViewController = [ConfigViewController withConnection: [_connections objectAtIndex: indexPath.row]: indexPath.row];
	[self.navigationController pushViewController: targetViewController animated: YES];
	[targetViewController release];

	return nil;
}

// utility routine leveraged by 'cellForRowAtIndexPath' to determine which UITableViewCell to be used on a given section.
//
- (UITableViewCell *)obtainTableCellForSection:(NSInteger)section
{
	static NSString *kVanilla_ID = @"Vanilla_ID";
	
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

// to determine which UITableViewCell to be used on a given row.
//
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	NSInteger section = indexPath.section;
	NSInteger row = indexPath.row;
	UITableViewCell *sourceCell = [self obtainTableCellForSection: section];
	
	// we are creating a new cell, setup its attributes
	switch(section)
	{
		case 0:
			sourceCell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
			if(self.editing)
			{
				if(row == 0)
					sourceCell.text = NSLocalizedString(@"New Connection", @"");
				else
					sourceCell.text = [(NSDictionary *)[_connections objectAtIndex: row - 1] objectForKey: kRemoteHost];
			}
			else
			{
				if([[[NSUserDefaults standardUserDefaults] objectForKey: kActiveConnection] integerValue] == row)
					sourceCell.image = [UIImage imageNamed:@"segment_check.png"];
				else if([RemoteConnectorObject getConnectedId] == row)
					sourceCell.image = [UIImage imageNamed:@"connected.png"];
				else
					sourceCell.image = nil;
				sourceCell.text = [(NSDictionary *)[_connections objectAtIndex: row] objectForKey: kRemoteHost];
			}
			break;
		case 1:
			((DisplayCell *)sourceCell).view = vibrateInRC;
			((DisplayCell *)sourceCell).text = NSLocalizedString(@"Vibrate in RC", @"");
			break;
		default:
			break;
	}

	return sourceCell;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView 
{
	return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section 
{
	if(section == 0)
	{
		if(self.editing)
			return [_connections count] + 1;
		return [_connections count];
	}
	return 1;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
	if(section == 0)
		return NSLocalizedString(@"Configured Connections", @"");
	return nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation: (UIInterfaceOrientation)interfaceOrientation
{
	return YES;
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
	if(indexPath.section != 0)
		return UITableViewCellEditingStyleNone;

	if(indexPath.row == 0)
		return UITableViewCellEditingStyleInsert;
	return UITableViewCellEditingStyleDelete;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
	// If row is deleted, remove it from the list.
	if (editingStyle == UITableViewCellEditingStyleDelete)
	{
		NSInteger currentDefault = [[[NSUserDefaults standardUserDefaults] objectForKey: kActiveConnection] integerValue];
		if(currentDefault > indexPath.row - 1)
			[[NSUserDefaults standardUserDefaults] setObject: [NSNumber numberWithInteger: currentDefault - 1] forKey: kActiveConnection];
		else if(currentDefault == indexPath.row - 1)
			[[NSUserDefaults standardUserDefaults] setObject: [NSNumber numberWithInteger: 0] forKey: kActiveConnection];

		[_connections removeObjectAtIndex: indexPath.row - 1];
		[tableView deleteRowsAtIndexPaths: [NSArray arrayWithObject: indexPath]
						 withRowAnimation: UITableViewRowAnimationFade];
	}
	else if(editingStyle == UITableViewCellEditingStyleInsert)
	{
		UIViewController *targetViewController = [ConfigViewController newConnection];
		[self.navigationController pushViewController: targetViewController animated: YES];
		[targetViewController release];

		[self setEditing: NO animated: NO];
	}
}

#pragma mark - UIViewController delegate methods

- (void)viewWillAppear:(BOOL)animated
{
	[(UITableView *)self.view reloadData];
}

@end
