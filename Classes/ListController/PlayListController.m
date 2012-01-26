//
//  PlayListController.m
//  dreaMote
//
//  Created by Moritz Venn on 10.01.11.
//  Copyright 2011-2012 Moritz Venn. All rights reserved.
//

#import "PlayListController.h"

#import "RemoteConnectorObject.h"

@implementation PlayListController

@synthesize clearButton, playlist, saveButton, loadButton;

- (id)init
{
	if((self = [super init]))
	{
		self.title = NSLocalizedString(@"Playlist", @"Title of PlayListController");
		self.playlist = [[FileListView alloc] initWithFrame: [[UIScreen mainScreen] applicationFrame]];
		playlist.isPlaylist = YES;

		if([self respondsToSelector:@selector(setContentSizeForViewInPopover:)])
			self.contentSizeForViewInPopover = CGSizeMake(430.0f, 800.0f);
	}
	return self;
}

- (void)dealloc
{
	[self stopObservingThemeChanges];
}

- (void)loadView
{
	self.view = playlist;
	self.navigationItem.rightBarButtonItem = self.editButtonItem;
	[self theme];
}

- (void)viewDidLoad
{
	[self startObservingThemeChanges];
	[super viewDidLoad];
}

- (void)viewDidUnload
{
	[self stopObservingThemeChanges];
	[super viewDidUnload];
}

/* (un)set editing */
- (void)setEditing:(BOOL)editing animated:(BOOL)animated
{
	[super setEditing: editing animated: animated];
	[playlist setEditing: editing animated: animated];

	clearButton.enabled = !editing;
	if([[RemoteConnectorObject sharedRemoteConnector] hasFeature:kFeaturesMediaPlayerPlaylistHandling])
	{
		saveButton.enabled = !editing;
		loadButton.enabled = !editing;
	}
}

- (void)viewWillAppear:(BOOL)animated
{
	if(![[RemoteConnectorObject sharedRemoteConnector] hasFeature:kFeaturesMediaPlayerPlaylistHandling])
	{
		saveButton.enabled = NO;
		loadButton.enabled = NO;
	}
	[super viewWillAppear:animated];
}

- (UITableView *)tableView
{
	return playlist;
}

@end
