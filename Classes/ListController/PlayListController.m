//
//  PlayListController.m
//  dreaMote
//
//  Created by Moritz Venn on 10.01.11.
//  Copyright 2011 Moritz Venn. All rights reserved.
//

#import "PlayListController.h"

#import "RemoteConnectorObject.h"

@implementation PlayListController

@synthesize clearButton = _clearButton;
@synthesize playlist = _playlist;
@synthesize saveButton = _saveButton;
@synthesize loadButton = _loadButton;

- (id)init
{
	if((self = [super init]))
	{
		self.title = NSLocalizedString(@"Playlist", @"Title of PlayListController");
		_playlist = [[FileListView alloc] initWithFrame: [[UIScreen mainScreen] applicationFrame]];
		_playlist.isPlaylist = YES;

		if([self respondsToSelector:@selector(setContentSizeForViewInPopover:)])
			self.contentSizeForViewInPopover = CGSizeMake(430.0f, 800.0f);
	}
	return self;
}


- (void)loadView
{
	self.view = _playlist;
	self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

/* (un)set editing */
- (void)setEditing:(BOOL)editing animated:(BOOL)animated
{
	[super setEditing: editing animated: animated];
	[_playlist setEditing: editing animated: animated];

	_clearButton.enabled = !editing;
	if([[RemoteConnectorObject sharedRemoteConnector] hasFeature:kFeaturesMediaPlayerPlaylistHandling])
	{
		_saveButton.enabled = !editing;
		_loadButton.enabled = !editing;
	}
}

- (void)viewWillAppear:(BOOL)animated
{
	if(![[RemoteConnectorObject sharedRemoteConnector] hasFeature:kFeaturesMediaPlayerPlaylistHandling])
	{
		_saveButton.enabled = NO;
		_loadButton.enabled = NO;
	}
	[super viewWillAppear:animated];
}

@end
