//
//  MediaPlayerDetailsController.m
//  dreaMote
//
//  Created by Moritz Venn on 10.01.11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "MediaPlayerDetailsController.h"

#import "Constants.h"
#import "DisplayCell.h"
#import "MainTableViewCell.h"
#import "RemoteConnectorObject.h"

@interface MediaPlayerDetailsController()
- (void)emptyData;
- (void)fetchCoverart;
- (void)fetchData;
@end


@implementation MediaPlayerDetailsController

/* dealloc */
- (void)dealloc
{
	[_currentTrack release];
	[_currentCover release];
	[_metadataXMLDoc release];

	[super dealloc];
}

/* getter of playlist */
- (FileListView *)playlist
{
	return _playlist;
}

/* setter of playlist */
- (void)setPlaylist:(FileListView *)new
{
	if([new isEqual: _playlist]) return;
	
	[_playlist release];
	_playlist = [new retain];
	_playlist.fileDelegate = self;
}

- (void)loadView
{
	UITableView *tableView = [[UITableView alloc] initWithFrame:[[UIScreen mainScreen] applicationFrame] style:UITableViewStyleGrouped];
	tableView.delegate = self;
	tableView.dataSource = self;
	tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;

	// setup our content view so that it auto-rotates along with the UViewController
	tableView.autoresizesSubviews = YES;
	tableView.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);

	self.view = tableView;
	[tableView release];
	
	// file list
	_fileList = [[FileListView alloc] initWithFrame: self.view.frame];
	_fileList.path = @"/";
	_fileList.fileDelegate = self;
}

/* new track started playing */
- (void)newTrackPlaying
{
	[self emptyData];

	// playing track changed, update local metadata
	[NSThread detachNewThreadSelector:@selector(fetchData) toTarget:self withObject:nil];
}

/* fetch contents */
- (void)fetchData
{	
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	[_metadataXMLDoc release];
	_metadataXMLDoc = [[[RemoteConnectorObject sharedRemoteConnector] getMetadata:self] retain];
	[pool release];
}

/* remove content data */
- (void)emptyData
{
	[_currentTrack release];
	_currentTrack = nil;
	[_currentCover release];
	_currentCover = nil;
	NSIndexSet *idxSet = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, 2)];
	[(UITableView *)self.view reloadSections:idxSet withRowAnimation:UITableViewRowAnimationRight];
	[_metadataXMLDoc release];
	_metadataXMLDoc = nil;
}

/* fetch coverart */
- (void)fetchCoverart
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	NSData *imageData = [[RemoteConnectorObject sharedRemoteConnector] getFile:_currentTrack.coverpath];
	[_currentCover release];
	_currentCover = [[UIImage alloc] initWithData:imageData];
	NSIndexSet *idxSet = [NSIndexSet indexSetWithIndex:1];
	[(UITableView *)self.view reloadSections:idxSet withRowAnimation:UITableViewRowAnimationRight];
	[pool release];
}

#pragma mark - UITableView delegates

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	if(indexPath.section != 2) return nil;

	// FIXME: this is kinda hackish
	const UITableViewCell *cell = [tableView cellForRowAtIndexPath: indexPath];
	@try {
		[((UIControl *)((DisplayCell *)cell).view) sendActionsForControlEvents: UIControlEventTouchUpInside];
	}
	@catch (NSException * e) {
		//
	}
	return nil;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return 3;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
	switch(section)
	{
		case 0:
			if([[RemoteConnectorObject sharedRemoteConnector] hasFeature:kFeaturesMediaPlayerMetadata]
				&& _currentTrack != nil)
				return NSLocalizedString(@"Now Playing", @"");
			return nil;
		case 1:
			if([[RemoteConnectorObject sharedRemoteConnector] hasFeature:kFeaturesMediaPlayerMetadata]
				&& [[RemoteConnectorObject sharedRemoteConnector] hasFeature:kFeaturesFileDownload]
				&& _currentCover != nil)
				return NSLocalizedString(@"Coverart", @"");
			return nil;
		case 2:
			return NSLocalizedString(@"Controls", @"");
		default:
			return nil;
	}
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	switch(section)
	{
		case 0:
			if([[RemoteConnectorObject sharedRemoteConnector] hasFeature:kFeaturesMediaPlayerMetadata]
				&& _currentTrack != nil)
				return 5;
			return 0;
		case 1:
			if([[RemoteConnectorObject sharedRemoteConnector] hasFeature:kFeaturesMediaPlayerMetadata]
				&& [[RemoteConnectorObject sharedRemoteConnector] hasFeature:kFeaturesFileDownload]
				&& _currentCover != nil)
				return 1;
			return 0;
		case 2:
			return 4;
		default:
			return 0;
	}
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	if(indexPath.section == 1) return 250;
	return kUIRowHeight;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	UITableViewCell *sourceCell = nil;

	switch(indexPath.section)
	{
		case 0:
		{
			NSDictionary *dataDictionary = nil;
			sourceCell = [tableView dequeueReusableCellWithIdentifier:kMainCell_ID];
			if(sourceCell == nil)
				sourceCell = [[[MainTableViewCell alloc] initWithFrame:CGRectZero reuseIdentifier:kMainCell_ID] autorelease];

			switch(indexPath.row)
			{
				case 0:
					dataDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
									  NSLocalizedString(@"Title", @""), @"title",
									  _currentTrack.title, @"explainText", nil];
					break;
				case 1:
					dataDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
									  NSLocalizedString(@"Artist", @""), @"title",
									  _currentTrack.artist, @"explainText", nil];
					break;
				case 2:
					dataDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
									  NSLocalizedString(@"Album", @""), @"title",
									  _currentTrack.album, @"explainText", nil];
					break;
				case 3:
					dataDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
									  NSLocalizedString(@"Year", @""), @"title",
									  _currentTrack.year, @"explainText", nil];
					break;
				case 4:
					dataDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
									  NSLocalizedString(@"Genre", @""), @"title",
									  _currentTrack.genre, @"explainText", nil];
					break;
				default: break;
			}

			((MainTableViewCell *)sourceCell).dataDictionary = dataDictionary;
			sourceCell.accessoryType = UITableViewCellAccessoryNone;
			break;
		}
		case 1:
		{
			UIImageView *imageView = [[UIImageView alloc] initWithImage: _currentCover];
			imageView.frame = CGRectMake(0, 0, 250, 250);
			sourceCell = [tableView dequeueReusableCellWithIdentifier:kDisplayCell_ID];
			if(sourceCell == nil)
				sourceCell = [[[DisplayCell alloc] initWithFrame:CGRectZero reuseIdentifier:kDisplayCell_ID] autorelease];

			((DisplayCell *)sourceCell).nameLabel.text = nil;
			((DisplayCell *)sourceCell).view = imageView;
			[imageView release];
			break;
		}
		case 2:
		{
			sourceCell = [tableView dequeueReusableCellWithIdentifier:kDisplayCell_ID];
			if(sourceCell == nil)
				sourceCell = [[[DisplayCell alloc] initWithFrame:CGRectZero reuseIdentifier:kDisplayCell_ID] autorelease];

			switch(indexPath.row)
			{
				case 0:
					((DisplayCell *)sourceCell).nameLabel.text = NSLocalizedString(@"Previous", @"");
					((DisplayCell *)sourceCell).view = [[self newButton:CGRectMake(0, 0, kUIRowHeight-2, kUIRowHeight-2) withImage:@"key_fr.png" andKeyCode: kButtonCodeFRwd] autorelease];
					break;
				case 1:
					((DisplayCell *)sourceCell).nameLabel.text = NSLocalizedString(@"Stop", @"");
					((DisplayCell *)sourceCell).view = [[self newButton:CGRectMake(0, 0, kUIRowHeight-2, kUIRowHeight-2) withImage:@"key_stop.png" andKeyCode: kButtonCodeStop] autorelease];
					break;
				case 2:
					((DisplayCell *)sourceCell).nameLabel.text = NSLocalizedString(@"Play/Pause", @"");
					((DisplayCell *)sourceCell).view = [[self newButton:CGRectMake(0, 0, kUIRowHeight-2, kUIRowHeight-2) withImage:@"key_pp.png" andKeyCode: kButtonCodePlayPause] autorelease];
					break;
				case 3:
					((DisplayCell *)sourceCell).nameLabel.text = NSLocalizedString(@"Next", @"");
					((DisplayCell *)sourceCell).view = [[self newButton:CGRectMake(0, 0, kUIRowHeight-2, kUIRowHeight-2) withImage:@"key_ff.png" andKeyCode: kButtonCodeFFwd] autorelease];
					break;
				default: break;
			}
		}	
		default: break;
	}

	return sourceCell;
}

#pragma mark -
#pragma mark MetadataSourceDelegate
#pragma mark -

- (void)addMetadata:(NSObject <MetadataProtocol>*)anItem
{
	if(anItem == nil) return;
	[_currentTrack release];
	_currentTrack = [anItem retain];
	NSMutableIndexSet *idxSet = [NSMutableIndexSet indexSetWithIndex:0];

	if(!(_currentTrack.coverpath == nil || [_currentTrack.coverpath isEqualToString: @""]))
		[NSThread detachNewThreadSelector:@selector(fetchCoverart) toTarget:self withObject:nil];
	else
	{
		[_currentCover release];
		_currentCover = nil;
		[idxSet addIndex:1];
	}
	[(UITableView *)self.view reloadSections:idxSet withRowAnimation:UITableViewRowAnimationRight];
}

@end
