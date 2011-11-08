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

@property (nonatomic, strong) NSArray *connections;
@property (nonatomic, strong) NSObject<ConnectionListDelegate> *connectionDelegate;
@end

@implementation ConnectionListController

@synthesize connections = _connections;
@synthesize connectionDelegate = _delegate;

+ (ConnectionListController *)newWithConnections:(NSArray *)connections andDelegate:(NSObject<ConnectionListDelegate> *)delegate
{
	ConnectionListController *tv = [[ConnectionListController alloc] init];
	tv.connections = connections;
	tv.connectionDelegate = delegate;

	return tv;
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
	((UITableView *)self.view).delegate = nil;
	((UITableView *)self.view).dataSource = nil;
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

	self.view = tableView;
	[self theme];
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
	NSObject<ConnectionListDelegate> *delegate = _delegate;
	if(IS_IPAD())
		[self.navigationController dismissModalViewControllerAnimated:YES];
	else
		// do NOT animate this, as our parent will animate another transition
		[self.navigationController popViewControllerAnimated:NO];

	[delegate connectionSelected:con];
	_delegate = nil;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	ConnectionTableViewCell *cell = [ConnectionTableViewCell reusableTableViewCellInView:tableView withIdentifier:kConnectionCell_ID];

	cell.dataDictionary = [_connections objectAtIndex:indexPath.row];

	return cell;
}

@end
