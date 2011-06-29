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
#import "UITableViewCell+EasyInit.h"

@interface ServiceZapListController()
/*!
 @brief Hide action sheet if visible.
 */
- (void)dismissActionSheet:(NSNotification *)notif;
@property (nonatomic, retain) UIActionSheet *actionSheet;
@end

@implementation ServiceZapListController

@synthesize zapDelegate = _zapDelegate;
@synthesize actionSheet = _actionSheet;

+ (BOOL)canStream
{
	return [[RemoteConnectorObject sharedRemoteConnector] hasFeature:kFeaturesStreaming]
		&& (
			[[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"oplayer:///"]]
		|| [[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"oplayerlite:///"]]
		|| [[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"buzzplayer:///"]]
		|| [[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"yxp:///"]]
		);
}

+ (ServiceZapListController *)showAlert:(NSObject<ServiceZapListDelegate> *)delegate fromTabBar:(UITabBar *)tabBar
{
	ServiceZapListController *zlc = [[ServiceZapListController alloc] init];
	zlc.zapDelegate = delegate;
	zlc.actionSheet = [[UIActionSheet alloc] initWithTitle:NSLocalizedString(@"Select type of zap", @"")
																   delegate:zlc
														  cancelButtonTitle:nil
													 destructiveButtonTitle:nil
														  otherButtonTitles:nil];
	[zlc.actionSheet.delegate retain];
	[zlc.actionSheet addButtonWithTitle:NSLocalizedString(@"Zap on receiver", @"")];
	if([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"oplayer:///"]])
		[zlc.actionSheet addButtonWithTitle:@"OPlayer"];
	if([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"oplayerlite:///"]])
		[zlc.actionSheet addButtonWithTitle:@"OPlayer Lite"];
	if([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"buzzplayer:///"]])
		[zlc.actionSheet addButtonWithTitle:@"BUZZ Player"];
	if([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"yxp:///"]])
		[zlc.actionSheet addButtonWithTitle:@"yxplayer"];

	zlc.actionSheet.cancelButtonIndex = [zlc.actionSheet addButtonWithTitle:NSLocalizedString(@"Cancel", @"")];
	[zlc.actionSheet showFromTabBar:tabBar];

	[[NSNotificationCenter defaultCenter] addObserver:zlc selector:@selector(dismissActionSheet:) name:UIApplicationDidEnterBackgroundNotification object:nil];

	return [zlc autorelease];
}

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
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[_actionSheet release];
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

- (void)viewWillAppear:(BOOL)animated
{
	hasAction[zapActionRemote] = YES;
	hasAction[zapActionOPlayer] = [[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"oplayer:///"]];
	hasAction[zapActionOPlayerLite] = [[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"oplayerlite:///"]];
	hasAction[zapActionBuzzPlayer] = [[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"buzzplayer:///"]];
	hasAction[zapActionYxplayer] = [[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"yxp:///"]];
}

- (void)dismissActionSheet:(NSNotification *)notif
{
	[_actionSheet dismissWithClickedButtonIndex:_actionSheet.cancelButtonIndex animated:NO];
}

#pragma mark	-
#pragma mark	UITableView delegate methods
#pragma mark	-

/* create cell for given row */
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	NSInteger row = indexPath.row;
	UITableViewCell *cell = [UITableViewCell reusableTableViewCellInView:tableView withIdentifier:kVanilla_ID];

	TABLEVIEWCELL_FONT(cell) = [UIFont boldSystemFontOfSize:kTextViewFontSize-1];
	if([[RemoteConnectorObject sharedRemoteConnector] hasFeature:kFeaturesStreaming])
	{
		if(!hasAction[zapActionOPlayer] && row > 0)
			++row;
		if(!hasAction[zapActionOPlayerLite] && row > 1)
			++row;
		if(!hasAction[zapActionBuzzPlayer] && row > 2)
			++row;
		//if(!hasAction[zapActionYxplayer] && row > 3)
		//	++row;
	}
	switch((zapAction)row)
	{
		default:
		case zapActionRemote:
			TABLEVIEWCELL_TEXT(cell) = NSLocalizedString(@"Zap on receiver", @"");
			break;
		case zapActionOPlayer:
			TABLEVIEWCELL_TEXT(cell) = @"OPlayer";
			break;
		case zapActionOPlayerLite:
			TABLEVIEWCELL_TEXT(cell) = @"OPlayer Lite";
			break;
		case zapActionBuzzPlayer:
			TABLEVIEWCELL_TEXT(cell) = @"BUZZ Player";
			break;
		case zapActionYxplayer:
			TABLEVIEWCELL_TEXT(cell) = @"yxplayer";
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
		if(!hasAction[zapActionOPlayer] && row > 0)
			++row;
		if(!hasAction[zapActionOPlayerLite] && row > 1)
			++row;
		if(!hasAction[zapActionBuzzPlayer] && row > 2)
			++row;
		//if(!hasAction[zapActionYxplayer] && row > 3)
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
	NSInteger row = 0;
	NSInteger i = 0;
	for(i = 0; i < zapActionMax; ++i)
	{
		if(hasAction[i])
			++row;
	}
	return row;
}

#pragma mark -
#pragma mark UIActionSheetDelegate methods
#pragma mark -

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
	if(buttonIndex == actionSheet.cancelButtonIndex)
	{
		// do nothing
	}
	else
	{
		if(![[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"oplayer:///"]] && buttonIndex > 0)
			++buttonIndex;
		if(![[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"oplayerlite:///"]] && buttonIndex > 1)
			++buttonIndex;
		if(![[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"buzzplayer:///"]] && buttonIndex > 2)
			++buttonIndex;
		//if(![[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"yxp:///"]] && buttonIndex > 3)
		//	++buttonIndex;

		[_zapDelegate serviceZapListController:self selectedAction:(zapAction)buttonIndex];
	}
	[actionSheet.delegate release];
	actionSheet.delegate = nil;
}

@end
