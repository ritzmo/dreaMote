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
@synthesize tableView = _tableView;

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
	_tableView.delegate = nil;
	_tableView.dataSource = nil;
}

#pragma mark UIViewController delegates

- (void)loadView
{
	_tableView = [[UITableView alloc] initWithFrame:[[UIScreen mainScreen] applicationFrame] style:UITableViewStylePlain];
	_tableView.delegate = self;
	_tableView.dataSource = self;
	_tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
	_tableView.sectionHeaderHeight = 0;
	_tableView.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
	if(IS_IPAD())
	{
		_tableView.rowHeight = kUIRowHeight;
		_tableView.backgroundView = [[UIView alloc] init];
	}

	UIBarButtonItem *button = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
																			target:self action:@selector(abortAction:)];
	self.navigationItem.leftBarButtonItem = button;

	self.view = _tableView;
	[self theme];
}

- (void)viewDidUnload
{
	_tableView = nil;
	[super viewDidUnload];
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
