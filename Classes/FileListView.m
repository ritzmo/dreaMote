//
//  FileListView.m
//  dreaMote
//
//  Created by Moritz Venn on 05.01.11.
//  Copyright 2011 Moritz Venn. All rights reserved.
//

#import "FileListView.h"

#import "Constants.h"
#import "RemoteConnectorObject.h"

#import "Objects/FileProtocol.h"

@interface FileListView()
- (void)fetchData;
@end

@implementation FileListView

@synthesize fileDelegate = _fileDelegate;
@synthesize isPlaylist = _isPlaylist;

- (id)initWithFrame:(CGRect)frame
{
	if((self = [super initWithFrame:frame]))
	{
        self.delegate = self;
		self.dataSource = self;
		self.rowHeight = 38;
		self.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
		self.sectionHeaderHeight = 0;
		self.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);

		_files = [[NSMutableArray alloc] init];
		_playing = NSNotFound;
		_reloading = NO;

		// add header view
		_refreshHeaderView = [[EGORefreshTableHeaderView alloc] initWithFrame:CGRectMake(0.0f, 0.0f - self.bounds.size.height, self.bounds.size.width, self.bounds.size.height)];
		_refreshHeaderView.delegate = self;
		[self addSubview:_refreshHeaderView];
    }
    return self;
}

- (void)dealloc
{
	[_path release];
	[_files release];
	[_fileDelegate release];
	[_fileXMLDoc release];
	[_refreshHeaderView release];

    [super dealloc];
}

- (NSString *)path
{
	return _path;
}

- (void)setPath:(NSString *)new
{
	// Same bouquet assigned, abort
	if([_path isEqualToString: new]) return;

	// Free old bouquet, retain new one
	[_path release];
	_path = [new retain];

	// Free Caches and reload data
	[_files removeAllObjects];
	NSIndexSet *idxSet = [NSIndexSet indexSetWithIndex: 0];
	[self reloadSections:idxSet withRowAnimation:UITableViewRowAnimationRight];
	[_fileXMLDoc release];
	_fileXMLDoc = nil;

	// Spawn a thread to fetch the files so that the UI is not blocked while the
	// application parses the XML file.
	[NSThread detachNewThreadSelector:@selector(fetchData) toTarget:self withObject:nil];
}

/* add file to list */
- (void)addFile: (NSObject<FileProtocol> *)file
{
	if(file != nil)
	{
		[_files addObject: file];
#ifdef ENABLE_LAGGY_ANIMATIONS
		[self insertRowsAtIndexPaths: [NSArray arrayWithObject: [NSIndexPath indexPathForRow:[_files count]-1 inSection:0]]
									   withRowAnimation: UITableViewRowAnimationTop];
	}
	else
#else
	}
#endif
	{
		[_refreshHeaderView egoRefreshScrollViewDataSourceDidFinishedLoading:self];
		[self reloadData];
		_reloading = NO;
	}
}

/* start download of file list */
- (void)fetchData
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	[_fileXMLDoc release];
	_reloading = YES;
	if(self.isPlaylist)
		_fileXMLDoc = [[[RemoteConnectorObject sharedRemoteConnector] fetchPlaylist: self] retain];
	else
		_fileXMLDoc = [[[RemoteConnectorObject sharedRemoteConnector] fetchFiles: self path: _path] retain];
	[pool release];
}

/* select file by name */
- (void)selectPlayingByTitle:(NSString *)filename
{
	NSUInteger idx = 0;
	for(NSObject<FileProtocol> *file in _files)
	{
		if([file.title isEqualToString: filename])
		{
			if(_playing != idx)
			{
				NSMutableArray *idxPaths = [NSMutableArray arrayWithObject:[NSIndexPath indexPathForRow:idx inSection:0]];
				if(_playing != NSNotFound)
					[idxPaths addObject:[NSIndexPath indexPathForRow:_playing inSection: 0]];

				_playing = idx;
				[self reloadRowsAtIndexPaths:idxPaths withRowAnimation:UITableViewRowAnimationFade];
			}
			return;
		}
		++idx;
	}
}

/* re-download data */
- (void)refreshData
{
	// Free Caches and reload data
	[_files removeAllObjects];
	NSIndexSet *idxSet = [NSIndexSet indexSetWithIndex: 0];
	[self reloadSections:idxSet withRowAnimation:UITableViewRowAnimationRight];
	[_fileXMLDoc release];
	_fileXMLDoc = nil;

	// Spawn a thread to fetch the files so that the UI is not blocked while the
	// application parses the XML file.
	[NSThread detachNewThreadSelector:@selector(fetchData) toTarget:self withObject:nil];
}

/* remove file from list */
- (void)removeFile:(NSObject<FileProtocol> *)file
{
	NSInteger idx = [_files indexOfObject:file];
	NSIndexPath *path = [NSIndexPath indexPathForRow:idx inSection:0];
	[_files removeObjectAtIndex:idx];
	[self deleteRowsAtIndexPaths:[NSArray arrayWithObject:path] withRowAnimation:UITableViewRowAnimationFade];
}

#pragma mark	-
#pragma mark	UITableView delegate methods
#pragma mark	-

/* create cell for given row */
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	UITableViewCell *cell = (UITableViewCell *)[tableView dequeueReusableCellWithIdentifier: kVanilla_ID];
	if(cell == nil)
		cell = [[[UITableViewCell alloc] initWithFrame: CGRectZero reuseIdentifier: kVanilla_ID] autorelease];

	TABLEVIEWCELL_FONT(cell) = [UIFont boldSystemFontOfSize:kTextViewFontSize-1];
	NSObject<FileProtocol> *file = [_files objectAtIndex:indexPath.row];
	TABLEVIEWCELL_TEXT(cell) = file.title;

	if(indexPath.row == _playing)
		TABLEVIEWCELL_IMAGE(cell) = [UIImage imageNamed:@"audio-volume-high.png"];
	else
		TABLEVIEWCELL_IMAGE(cell) = nil;

	return cell;
}

/* select row */
- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	// See if we have a valid file
	NSObject<FileProtocol> *file = [_files objectAtIndex: indexPath.row];
	if(!file.valid)
		return nil;
	// if we're in playlist mode and we have a delegate call it back
	else if(_isPlaylist)
	{
		if(_fileDelegate != nil)
			[_fileDelegate fileListView:self fileSelected:file];
		return nil;
	}
	// change current folder or ask what to do with file
	else
	{
		if(file.isDirectory)
		{
			self.path = file.sref;
			return nil;
		}
		else if(_fileDelegate != nil)
			[_fileDelegate fileListView:self fileSelected:file];
	}
	return indexPath;
}

/* edit action */
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
	NSObject<FileProtocol> *file = [_files objectAtIndex: indexPath.row];
	[_fileDelegate fileListView:self fileRemoved:file];
}

/* row selected */
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
}

/* editing style */
- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
	return UITableViewCellEditingStyleDelete;
}

/* number of sections */
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return 1;
}

/* number of rows */
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	return [_files count];
}

#pragma mark -
#pragma mark UIScrollViewDelegate Methods
#pragma mark -

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
	[_refreshHeaderView egoRefreshScrollViewDidScroll:scrollView];
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
	[_refreshHeaderView egoRefreshScrollViewDidEndDragging:scrollView];
}

#pragma mark -
#pragma mark EGORefreshTableHeaderDelegate Methods
#pragma mark -

- (void)egoRefreshTableHeaderDidTriggerRefresh:(EGORefreshTableHeaderView*)view
{
	[self refreshData];
}

- (BOOL)egoRefreshTableHeaderDataSourceIsLoading:(EGORefreshTableHeaderView*)view
{
	return _reloading;
}

@end
