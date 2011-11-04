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

#import "UIDevice+SystemVersion.h"

@interface ServiceZapListController()
/*!
 @brief Hide action sheet if visible.
 */
- (void)dismissActionSheet:(NSNotification *)notif;
@property (nonatomic, strong) UIActionSheet *actionSheet;
@end

@implementation ServiceZapListController

@synthesize zapDelegate;
@synthesize actionSheet = _actionSheet;

+ (BOOL)canStream
{
	return [[RemoteConnectorObject sharedRemoteConnector] hasFeature:kFeaturesStreaming]
		&& (
			[[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"oplayer:///"]]
		|| [[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"oplayerlite:///"]]
		|| [[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"buzzplayer:///"]]
		|| [[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"yxp:///"]]
		|| [[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"goodplayer:///"]]
		|| [[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"aceplayer:///"]]
		);
}

+ (ServiceZapListController *)showAlert:(NSObject<ServiceZapListDelegate> *)delegate fromTabBar:(UITabBar *)tabBar
{
	ServiceZapListController *zlc = [[ServiceZapListController alloc] init];
	zlc.zapDelegate = delegate;
	UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:NSLocalizedString(@"Select type of zap", @"")
															 delegate:zlc
													cancelButtonTitle:nil
											   destructiveButtonTitle:nil
													otherButtonTitles:nil];
	zlc.actionSheet = actionSheet;
	[zlc.actionSheet addButtonWithTitle:NSLocalizedString(@"Zap on receiver", @"")];
	if([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"oplayer:///"]])
		[zlc.actionSheet addButtonWithTitle:@"OPlayer"];
	if([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"oplayerlite:///"]])
		[zlc.actionSheet addButtonWithTitle:@"OPlayer Lite"];
	if([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"buzzplayer:///"]])
		[zlc.actionSheet addButtonWithTitle:@"BUZZ Player"];
	if([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"yxp:///"]])
		[zlc.actionSheet addButtonWithTitle:@"yxplayer"];
	if([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"goodplayer:///"]])
		[zlc.actionSheet addButtonWithTitle:@"GoodPlayer"];
	if([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"aceplayer:///"]])
		[zlc.actionSheet addButtonWithTitle:@"AcePlayer"];

	zlc.actionSheet.cancelButtonIndex = [zlc.actionSheet addButtonWithTitle:NSLocalizedString(@"Cancel", @"")];
	[zlc.actionSheet showFromTabBar:tabBar];

	[[NSNotificationCenter defaultCenter] addObserver:zlc selector:@selector(dismissActionSheet:) name:UIApplicationDidEnterBackgroundNotification object:nil];

	return zlc;
}

+ (void)openStream:(NSURL *)streamingURL withAction:(zapAction)action
{
	NSURL *url = nil;
	switch(action)
	{
		default: break;
		case zapActionOPlayer:
			url = [NSURL URLWithString:[NSString stringWithFormat:@"oplayer://%@", [streamingURL absoluteURL]]];
			break;
		case zapActionOPlayerLite:
			url = [NSURL URLWithString:[NSString stringWithFormat:@"oplayerlite://%@", [streamingURL absoluteURL]]];
			break;
		case zapActionBuzzPlayer:
			url = [NSURL URLWithString:[NSString stringWithFormat:@"buzzplayer://%@", [streamingURL absoluteURL]]];
			break;
		case zapActionYxplayer:
			url = [NSURL URLWithString:[NSString stringWithFormat:@"yxp://%@", [streamingURL absoluteURL]]];
			break;
		case zapActionGoodPlayer:
			url = [NSURL URLWithString:[NSString stringWithFormat:@"goodplayer://%@", [streamingURL absoluteURL]]];
			break;
		case zapActionAcePlayer:
			url = [NSURL URLWithString:[NSString stringWithFormat:@"aceplayer://%@", [streamingURL absoluteURL]]];
			break;
	}
	if(url)
		[[UIApplication sharedApplication] openURL:url];
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
	((UITableView *)self.view).delegate = nil;
	((UITableView *)self.view).dataSource = nil;

	[_actionSheet dismissWithClickedButtonIndex:_actionSheet.cancelButtonIndex animated:NO];
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
}

- (void)viewWillAppear:(BOOL)animated
{
	((UITableView *)self.view).allowsSelection = YES;

	hasAction[zapActionRemote] = YES;
	hasAction[zapActionOPlayer] = [[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"oplayer:///"]];
	hasAction[zapActionOPlayerLite] = [[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"oplayerlite:///"]];
	hasAction[zapActionBuzzPlayer] = [[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"buzzplayer:///"]];
	hasAction[zapActionYxplayer] = [[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"yxp:///"]];
	hasAction[zapActionGoodPlayer] = [[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"goodplayer:///"]];
	hasAction[zapActionAcePlayer] = [[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"aceplayer:///"]];
}

- (void)dismissActionSheet:(NSNotification *)notif
{
	[_actionSheet dismissWithClickedButtonIndex:_actionSheet.cancelButtonIndex animated:NO];
	_actionSheet = nil;
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
		if(!hasAction[zapActionOPlayer] && row > zapActionRemote)
			++row;
		if(!hasAction[zapActionOPlayerLite] && row > zapActionOPlayer)
			++row;
		if(!hasAction[zapActionBuzzPlayer] && row > zapActionOPlayerLite)
			++row;
		if(!hasAction[zapActionYxplayer] && row > zapActionBuzzPlayer)
			++row;
		if(!hasAction[zapActionGoodPlayer] && row > zapActionYxplayer)
			++row;
		if(!hasAction[zapActionAcePlayer] && row > zapActionGoodPlayer)
			++row;
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
		case zapActionGoodPlayer:
			TABLEVIEWCELL_TEXT(cell) = @"GoodPlayer";
			break;
		case zapActionAcePlayer:
			TABLEVIEWCELL_TEXT(cell) = @"AcePlayer";
			break;
	}
	return cell;
}

/* select row */
- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	if(!zapDelegate) return nil;
	NSInteger row = indexPath.row;

	//if([[RemoteConnectorObject sharedRemoteConnector] hasFeature:kFeaturesStreaming])
	{
		if(!hasAction[zapActionOPlayer] && row > zapActionRemote)
			++row;
		if(!hasAction[zapActionOPlayerLite] && row > zapActionOPlayer)
			++row;
		if(!hasAction[zapActionBuzzPlayer] && row > zapActionOPlayerLite)
			++row;
		if(!hasAction[zapActionYxplayer] && row > zapActionBuzzPlayer)
			++row;
		if(!hasAction[zapActionGoodPlayer] && row > zapActionYxplayer)
			++row;
		if(!hasAction[zapActionAcePlayer] && row > zapActionGoodPlayer)
			++row;
	}
	[zapDelegate serviceZapListController:self selectedAction:(zapAction)row];
	return indexPath;
}

/* row selected */
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
	tableView.allowsSelection = NO;
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
	id<UIActionSheetDelegate> delegate = nil;
	@synchronized(self)
	{
		delegate = actionSheet.delegate;
		actionSheet.delegate = nil;
	}

	if(buttonIndex == actionSheet.cancelButtonIndex)
	{
		// do nothing
	}
	else
	{
		if(![[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"oplayer:///"]] && buttonIndex > zapActionRemote)
			++buttonIndex;
		if(![[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"oplayerlite:///"]] && buttonIndex > zapActionOPlayer)
			++buttonIndex;
		if(![[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"buzzplayer:///"]] && buttonIndex > zapActionOPlayerLite)
			++buttonIndex;
		if(![[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"yxp:///"]] && buttonIndex > zapActionBuzzPlayer)
			++buttonIndex;
		if(![[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"goodplayer:///"]] && buttonIndex > zapActionYxplayer)
			++buttonIndex;
		//if(![[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"aceplayer:///"]] && buttonIndex > zapActionGoodPlayer)
		//	++buttonIndex;

		[zapDelegate serviceZapListController:self selectedAction:(zapAction)buttonIndex];
	}
}

@end
