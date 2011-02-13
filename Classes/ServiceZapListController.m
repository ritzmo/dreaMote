//
//  ServiceZapListController.m
//  dreaMote
//
//  Created by Moritz Venn on 13.02.11.
//  Copyright 2011 Moritz Venn. All rights reserved.
//

#import "ServiceZapListController.h"

#import "Constants.h"
#import "RemoteConnectorObject.h"

@implementation ServiceZapListController

@synthesize zapDelegate = _zapDelegate;

- (id)init
{
	if((self = [super init]))
	{
		self.title = NSLocalizedString(@"Select type of zap", @"Title of ServiceZapListController");

		if([self respondsToSelector:@selector(setContentSizeForViewInPopover:)])
			self.contentSizeForViewInPopover = CGSizeMake(220.0f, 250.0f);
	}
	return self;
}

- (void)dealloc
{
	[_zapDelegate release];

	[super dealloc];
}

- (void)loadView
{
	UITableView *tableView = [[UITableView alloc] initWithFrame:[[UIScreen mainScreen] applicationFrame] style:UITableViewStylePlain];
	tableView.delegate = self;
	tableView.dataSource = self;
	tableView.rowHeight = 38;
	tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
	tableView.sectionHeaderHeight = 0;
	tableView.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);

	self.view = tableView;
	[tableView release];
}

#pragma mark	-
#pragma mark	UITableView delegate methods
#pragma mark	-

/* create cell for given row */
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	NSInteger row = indexPath.row;
	UITableViewCell *cell = (UITableViewCell *)[tableView dequeueReusableCellWithIdentifier: kVanilla_ID];
	if(cell == nil)
		cell = [[[UITableViewCell alloc] initWithFrame: CGRectZero reuseIdentifier: kVanilla_ID] autorelease];

	TABLEVIEWCELL_FONT(cell) = [UIFont boldSystemFontOfSize:kTextViewFontSize-1];
	//if([[RemoteConnectorObject sharedRemoteConnector] hasFeature:kFeaturesStreaming])
	{
		if(![[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"oplayer:///"]] && row > 0)
			++row;
		//if(![[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"oplayerlite:///"]] && row > 1)
		//	++row;
	}
	switch((zapAction)row)
	{
		default:
		case zapActionRemote:
			TABLEVIEWCELL_TEXT(cell) = NSLocalizedString(@"Zap on receiver", @"");
			break;
		case zapActionOPlayer:
			TABLEVIEWCELL_TEXT(cell) = NSLocalizedString(@"OPlayer", @"");
			break;
		case zapActionOPlayerLite:
			TABLEVIEWCELL_TEXT(cell) = NSLocalizedString(@"OPlayer Lite", @"");
			break;
	}
	return cell;
}

/* select row */
- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	if(!_zapDelegate) return nil;
	NSInteger row = indexPath.row;

	//if([[RemoteConnectorObject sharedRemoteConnector] hasFeature:kFeaturesStreaming])
	{
		if(![[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"oplayer:///"]] && row > 0)
			++row;
		//if(![[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"oplayerlite:///"]] && row > 1)
		//	++row;
	}
	[_zapDelegate serviceZapListController:self selectedAction:(zapAction)row];
	return indexPath;
}

/* row selected */
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
}

/* number of sections */
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return 1;
}

/* number of rows */
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	NSInteger row = 1;
	//if([[RemoteConnectorObject sharedRemoteConnector] hasFeature:kFeaturesStreaming])
	{
		if([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"oplayer:///"]])
			++row;
		if([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"oplayerlite:///"]])
			++row;
	}
	return row;
}

@end
