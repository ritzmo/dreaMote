//
//  ConnectionListController.m
//  dreaMote
//
//  Created by Moritz Venn on 23.06.11.
//  Copyright 2011 Moritz Venn. All rights reserved.
//

#import "ConnectionListController.h"

#import "Constants.h"

#import "ConnectionTableViewCell.h"
#import "UITableViewCell+EasyInit.h"

@interface ConnectionListController()
/*!
 @brief Abort.
 */
- (void)abortAction:(id)sender;

@property (nonatomic, retain) NSArray *connections;
@property (nonatomic, retain) ConfigViewController *configView;
@end

@implementation ConnectionListController

@synthesize connections = _connections;
@synthesize configView = _configView;

+ (ConnectionListController *)newWithConnections:(NSArray *)connections andConfigView:(ConfigViewController *)configView
{
	ConnectionListController *tv = [[ConnectionListController alloc] init];
	tv.connections = connections;
	tv.configView = configView;

	return [tv autorelease];
}

- (id)init
{
	if((self = [super init]))
	{
		self.title = NSLocalizedString(@"Select Connection", @"Default title of ConnectionListController");
		if([self respondsToSelector:@selector(modalPresentationStyle)])
		{
			self.modalPresentationStyle = UIModalPresentationFormSheet;
			self.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
		}
	}
	return self;
}

- (void)dealloc
{
	[_connections release];
	[_configView release];

	[super dealloc];
}

#pragma mark UIViewController delegates

- (void)loadView
{
	UITableView *tableView = [[UITableView alloc] initWithFrame:[[UIScreen mainScreen] applicationFrame] style:UITableViewStylePlain];
	tableView.delegate = self;
	tableView.dataSource = self;
	tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
	tableView.sectionHeaderHeight = 0;
	tableView.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);

	if(IS_IPAD())
		tableView.rowHeight = kUIRowHeight;

	UIBarButtonItem *button = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
																			target:self action:@selector(abortAction:)];
	self.navigationItem.leftBarButtonItem = button;
	[button release];

	self.view = tableView;
	[tableView release];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	return YES;
}

- (void)abortAction:(id)sender
{
	if(IS_IPAD())
		[self.navigationController dismissModalViewControllerAnimated:YES];
	else
		[self.navigationController popViewControllerAnimated:YES];
}

#pragma mark UITableView delegates

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	return [_connections count];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	NSMutableDictionary *con = [[_connections objectAtIndex:indexPath.row] mutableCopy];
	_configView.connection = con;
	[con release];

	if(IS_IPAD())
		[self.navigationController dismissModalViewControllerAnimated:YES];
	else
		[self.navigationController popViewControllerAnimated:YES];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	ConnectionTableViewCell *cell = [ConnectionTableViewCell reusableTableViewCellInView:tableView withIdentifier:kConnectionCell_ID];

	cell.dataDictionary = [_connections objectAtIndex:indexPath.row];

	return cell;
}

@end
