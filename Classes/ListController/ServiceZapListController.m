//
//  ServiceZapListController.m
//  dreaMote
//
//  Created by Moritz Venn on 13.02.11.
//  Copyright 2011-2012 Moritz Venn. All rights reserved.
//

#import "ServiceZapListController.h"

#import <Constants.h>
#import <Connector/RemoteConnectorObject.h>

#import <Categories/UITableViewCell+EasyInit.h>
#import <Categories/UIDevice+SystemVersion.h>

#import <Delegates/AppDelegate.h>

#import <TableViewCell/BaseTableViewCell.h>

@interface ServiceZapListController()
/*!
 @brief Hide action sheet if visible.
 */
- (void)dismissActionSheet:(NSNotification *)notif;
@property (nonatomic, strong) UIActionSheet *actionSheet;
@end

@implementation ServiceZapListController

@synthesize callback;
@synthesize actionSheet = _actionSheet;
@synthesize tableView = _tableView;

+ (BOOL)canStream
{
	return [[RemoteConnectorObject sharedRemoteConnector] hasFeature:kFeaturesStreaming]
		&& [self streamPlayerInstalled];
}

+ (BOOL)streamPlayerInstalled
{
	const UIApplication *sharedApplication = [UIApplication sharedApplication];
	return	[sharedApplication canOpenURL:[NSURL URLWithString:@"oplayer:///"]]
		||	[sharedApplication canOpenURL:[NSURL URLWithString:@"oplayerlite:///"]]
		||	[sharedApplication canOpenURL:[NSURL URLWithString:@"buzzplayer:///"]]
		||	[sharedApplication canOpenURL:[NSURL URLWithString:@"yxp:///"]]
		||	[sharedApplication canOpenURL:[NSURL URLWithString:@"goodplayer:///"]]
		||	[sharedApplication canOpenURL:[NSURL URLWithString:@"aceplayer:///"]];
}

+ (NSString *)playerName:(zapAction)playerAction
{
	switch(playerAction)
	{
		default:
		case zapActionMax:
			return NSLocalizedString(@"Always ask", @"");
		case zapActionRemote:
			return NSLocalizedString(@"Zap on receiver", @"");
		case zapActionOPlayer:
			return @"OPlayer";
		case zapActionOPlayerLite:
			return @"OPlayer Lite";
		case zapActionBuzzPlayer:
			return @"BUZZ Player";
		case zapActionYxplayer:
			return @"yxplayer";
		case zapActionGoodPlayer:
			return @"GoodPlayer";
		case zapActionAcePlayer:
			return @"AcePlayer";
	}
}

+ (NSArray *)playerNames
{
	const UIApplication *sharedApplication = [UIApplication sharedApplication];
	NSMutableArray *arr = [NSMutableArray arrayWithCapacity:zapActionMax];
	[arr addObject:NSLocalizedString(@"Zap on receiver", @"")];
	if([sharedApplication canOpenURL:[NSURL URLWithString:@"oplayer:///"]])
		[arr addObject:@"OPlayer"];
	if([sharedApplication canOpenURL:[NSURL URLWithString:@"oplayerlite:///"]])
		[arr addObject:@"OPlayer Lite"];
	if([sharedApplication canOpenURL:[NSURL URLWithString:@"buzzplayer:///"]])
		[arr addObject:@"BUZZ Player"];
	if([sharedApplication canOpenURL:[NSURL URLWithString:@"yxp:///"]])
		[arr addObject:@"yxplayer"];
	if([sharedApplication canOpenURL:[NSURL URLWithString:@"goodplayer:///"]])
		[arr addObject:@"GoodPlayer"];
	if([sharedApplication canOpenURL:[NSURL URLWithString:@"aceplayer:///"]])
		[arr addObject:@"AcePlayer"];
	[arr addObject:NSLocalizedString(@"Always ask", @"")];
	return arr;
}

+ (zapAction)zapActionForIndex:(NSInteger)index
{
	const UIApplication *sharedApplication = [UIApplication sharedApplication];
	if(index > zapActionRemote && ![sharedApplication canOpenURL:[NSURL URLWithString:@"oplayer:///"]])
		++index;
	if(index > zapActionOPlayer && ![sharedApplication canOpenURL:[NSURL URLWithString:@"oplayerlite:///"]])
		++index;
	if(index > zapActionOPlayerLite && ![sharedApplication canOpenURL:[NSURL URLWithString:@"buzzplayer:///"]])
		++index;
	if(index > zapActionBuzzPlayer && ![sharedApplication canOpenURL:[NSURL URLWithString:@"yxp:///"]])
		++index;
	if(index > zapActionYxplayer && ![sharedApplication canOpenURL:[NSURL URLWithString:@"goodplayer:///"]])
		++index;
	if(index > zapActionGoodPlayer && ![sharedApplication canOpenURL:[NSURL URLWithString:@"aceplayer:///"]])
		++index;
	return index;
}

+ (NSInteger)indexForZapAction:(zapAction)action
{
	const UIApplication *sharedApplication = [UIApplication sharedApplication];
	NSInteger index = action;
	if(action > zapActionRemote && ![sharedApplication canOpenURL:[NSURL URLWithString:@"oplayer:///"]])
		--index;
	if(action > zapActionOPlayer && ![sharedApplication canOpenURL:[NSURL URLWithString:@"oplayerlite:///"]])
		--index;
	if(action > zapActionOPlayerLite && ![sharedApplication canOpenURL:[NSURL URLWithString:@"buzzplayer:///"]])
		--index;
	if(action > zapActionBuzzPlayer && ![sharedApplication canOpenURL:[NSURL URLWithString:@"yxp:///"]])
		--index;
	if(action > zapActionYxplayer && ![sharedApplication canOpenURL:[NSURL URLWithString:@"goodplayer:///"]])
		--index;
	if(action > zapActionGoodPlayer && ![sharedApplication canOpenURL:[NSURL URLWithString:@"aceplayer:///"]])
		--index;
	return index;
}

+ (ServiceZapListController *)showAlert:(zap_callback_t)callback fromTabBar:(UITabBar *)tabBar
{
	ServiceZapListController *zlc = [[ServiceZapListController alloc] init];
	zlc.callback = callback;
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
	if(tabBar == nil)
		tabBar = APP_DELEGATE.tabBarController.tabBar;
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

		self.contentSizeForViewInPopover = CGSizeMake(220.0f, 250.0f);
	}
	return self;
}

- (void)dealloc
{
	[self stopObservingThemeChanges];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidEnterBackgroundNotification object:nil];
	_tableView.delegate = nil;
	_tableView.dataSource = nil;

	[_actionSheet dismissWithClickedButtonIndex:_actionSheet.cancelButtonIndex animated:NO];
}

- (void)loadView
{
	_tableView = [[UITableView alloc] initWithFrame:[[UIScreen mainScreen] applicationFrame] style:UITableViewStylePlain];
	_tableView.delegate = self;
	_tableView.dataSource = self;
	_tableView.rowHeight = 38;
	_tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
	_tableView.sectionHeaderHeight = 0;
	_tableView.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
	_tableView.backgroundView = [[UIView alloc] init];

	self.view = _tableView;
	[self theme];
}

- (void)theme
{
	UIColor *color = [DreamoteConfiguration singleton].backgroundColor;
	_tableView.backgroundView.backgroundColor =  color ? color : [UIColor whiteColor];
}

- (void)viewDidLoad
{
	[self startObservingThemeChanges];
	[super viewDidLoad];
}

- (void)viewDidUnload
{
	[self stopObservingThemeChanges];
	_tableView = nil;
	[super viewDidUnload];
}

- (void)viewWillAppear:(BOOL)animated
{
	_tableView.allowsSelection = YES;

	hasAction[zapActionRemote] = YES;
	hasAction[zapActionOPlayer] = [[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"oplayer:///"]];
	hasAction[zapActionOPlayerLite] = [[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"oplayerlite:///"]];
	hasAction[zapActionBuzzPlayer] = [[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"buzzplayer:///"]];
	hasAction[zapActionYxplayer] = [[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"yxp:///"]];
	hasAction[zapActionGoodPlayer] = [[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"goodplayer:///"]];
	hasAction[zapActionAcePlayer] = [[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"aceplayer:///"]];
	[_tableView reloadData];
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
	UITableViewCell *cell = [BaseTableViewCell reusableTableViewCellInView:tableView withIdentifier:kBaseCell_ID];

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
	switch((zapAction)row)
	{
		default:
		case zapActionRemote:
			cell.textLabel.text = NSLocalizedString(@"Zap on receiver", @"");
			break;
		case zapActionOPlayer:
			cell.textLabel.text = @"OPlayer";
			break;
		case zapActionOPlayerLite:
			cell.textLabel.text = @"OPlayer Lite";
			break;
		case zapActionBuzzPlayer:
			cell.textLabel.text = @"BUZZ Player";
			break;
		case zapActionYxplayer:
			cell.textLabel.text = @"yxplayer";
			break;
		case zapActionGoodPlayer:
			cell.textLabel.text = @"GoodPlayer";
			break;
		case zapActionAcePlayer:
			cell.textLabel.text = @"AcePlayer";
			break;
	}

	return [[DreamoteConfiguration singleton] styleTableViewCell:cell inTableView:tableView];
}

/* select row */
- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	zap_callback_t call = callback;
	callback = nil;
	if(!call) return nil;

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
	call(self, row);
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
		zapAction action = [ServiceZapListController zapActionForIndex:buttonIndex];
		zap_callback_t call = callback;
		callback = nil;
		if(call)
			call(self, action);
	}
}

@end
