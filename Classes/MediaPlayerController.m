//
//  MediaPlayerController.m
//  dreaMote
//
//  Created by Moritz Venn on 01.05.11.
//  Copyright 2011 Moritz Venn. All rights reserved.
//

#import "MediaPlayerController.h"

#import "Constants.h"
#import "RecursiveFileAdder.h"
#import "RemoteConnectorObject.h"

#import "Result.h"
#import "RCButton.h"
#import "FileListView.h"
#import "FileProtocol.h"

#define kTransitionDuration	(CGFloat)0.6

@interface MediaPlayerController()
- (void)placeControls:(UIInterfaceOrientation)interfaceOrientation duration:(NSTimeInterval)duration;
- (void)fetchAbout;
- (void)fetchCurrent;
- (void)fetchCurrentDefer;
- (IBAction)addFolderQuestion:(id)sender;
- (IBAction)toggleAddPlay:(id)sender;
/*!
 @brief Assign toolbar elements.
 */
- (void)configureToolbar;

/*!
 @brief Popover Controller.
 */
@property (nonatomic, retain) UIPopoverController *popoverController;

/*!
 @brief Activity Indicator.
 */
@property (nonatomic, retain) UIActivityIndicatorView *activityIndicatorView;
@end

@implementation MediaPlayerController

@synthesize activityIndicatorView, popoverController;

- (id)init
{
	if((self = [super init]))
	{
		self.title = NSLocalizedString(@"MediaPlayer", @"Title of MediaPlayerController");
		_adding = YES;
		_massAdd = NO;
	}

	return self;
}

- (void)dealloc
{
	[_addPlayToggle release];
	[_fileList release];
	[_playlist release];
	[_controls release];
	[_timer release];
	[_currentXMLDoc release];
	[activityIndicatorView release];

	[super dealloc];
}

- (void)newTrackPlaying
{
	//
}

- (void)fetchCurrentDefer
{
	switch(_retrieveCurrentUsing)
	{
		case kRetrieveCurrentUsingAbout:
			[NSThread detachNewThreadSelector:@selector(fetchAbout) toTarget:self withObject:nil];
			break;
		case kRetrieveCurrentUsingCurrent:
			[NSThread detachNewThreadSelector:@selector(fetchCurrent) toTarget:self withObject:nil];
			break;
		default:
			[_timer invalidate];
			_timer = nil;
			break;
	}
}

- (void)fetchAbout
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	[_currentXMLDoc release];
	@try {
		_currentXMLDoc = [[[RemoteConnectorObject sharedRemoteConnector] getAbout: self] retain];
	}
	@catch (NSException * e) {
		_currentXMLDoc = nil;
	}
	[pool release];
}

- (void)fetchCurrent
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	[_currentXMLDoc release];
	@try {
		_currentXMLDoc = [[[RemoteConnectorObject sharedRemoteConnector] getCurrent: self] retain];
	}
	@catch (NSException * e) {
		_currentXMLDoc = nil;
	}
	[pool release];
}

- (void)sendCommand:(NSString *)command
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

	Result *result = [[RemoteConnectorObject sharedRemoteConnector] mediaplayerCommand:command];
	if(!result.result)
	{
		// Alert user
		const UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Sending command failed", @"") message:result.resulttext
															 delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
		[alert show];
		[alert release];
	}

	[pool release];
}

- (void)buttonPressed:(RCButton *)sender
{
	NSString *command;
	switch(sender.rcCode)
	{
		case kButtonCodeFRwd: command = @"previous"; break;
		case kButtonCodeFFwd: command = @"next"; break;
		case kButtonCodeStop: command = @"stop"; break;
		case kButtonCodePlayPause: command = @"pause"; break;
		default: return;
	}

	// Spawn a thread to send the request so that the UI is not blocked while
	// waiting for the response.
	[NSThread detachNewThreadSelector:@selector(sendCommand:)
							 toTarget:self
						   withObject: command];
}

- (UIButton*)newButton:(CGRect)frame withImage:(NSString*)imagePath andKeyCode:(int)keyCode
{
	RCButton *uiButton = [[RCButton alloc] initWithFrame: frame];
	uiButton.rcCode = keyCode;
	if(imagePath != nil){
		UIImage *image = [UIImage imageNamed:imagePath];
		[uiButton setBackgroundImage:image forState:UIControlStateHighlighted];
		[uiButton setBackgroundImage:image forState:UIControlStateNormal];
	}
	[uiButton addTarget:self action:@selector(buttonPressed:)
	   forControlEvents:UIControlEventTouchUpInside];

	return uiButton;
}

- (IBAction)flipView:(id)sender
{
	[UIView beginAnimations:nil context:NULL];
	[UIView setAnimationDuration: kTransitionDuration];
	if(!IS_IPAD())
		self.navigationItem.leftBarButtonItem = nil;

	[UIView setAnimationTransition:
				([_fileList superview] ? UIViewAnimationTransitionFlipFromRight : UIViewAnimationTransitionFlipFromLeft)
				forView: self.view
				cache: YES];

	if ([_fileList superview])
	{
		[_fileList removeFromSuperview];
		[self.navigationController setToolbarHidden:YES animated:YES];
	}
	else
	{
		[self.view addSubview: _fileList];
		[self.navigationController setToolbarHidden:NO animated:YES];
	}

	[UIView commitAnimations];

	// fix up frame on iphone
	if(!IS_IPAD())
		_fileList.frame = self.view.frame;
}

- (void)placeControls:(UIInterfaceOrientation)interfaceOrientation duration:(NSTimeInterval)duration
{
	CGRect frame = self.view.frame;
	if(duration && IS_IPAD())
	{
		const CGFloat width = frame.size.width;
		const CGFloat offset = self.tabBarController.tabBar.frame.size.height + self.navigationController.navigationBar.frame.size.height + 20;

		frame.size.width = frame.size.height + offset;
		frame.size.height = width - offset;
	}

	[UIView beginAnimations:nil context:NULL];
	[UIView setAnimationDuration: duration];

	if(UIInterfaceOrientationIsLandscape(interfaceOrientation))
	{
		_controls.frame = _landscapeControlsFrame;
		_fileList.frame = frame;
	}
	else
	{
		_controls.frame = _portraitControlsFrame;
		_fileList.frame = frame;
	}

	[UIView commitAnimations];
}

- (void)configureToolbar
{
	// "Add Folder" Button
	const UIBarButtonItem *addFolderItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Add Folder", @"")
																	style:UIBarButtonItemStyleBordered
																	target:self
																	action:@selector(addFolderQuestion:)];

	// flex item used to separate the left groups items and right grouped items
	const UIBarButtonItem *flexItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
																					target:nil
																					action:nil];

	// create a bordered style button with custom title
	[_addPlayToggle release];
	_addPlayToggle = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Adding to Playlist", @"")
																	style:UIBarButtonItemStyleBordered
																	target:self
																	action:@selector(toggleAddPlay:)];

	[self setToolbarItems:[NSArray arrayWithObjects:addFolderItem, flexItem, _addPlayToggle, nil] animated:NO];

	[addFolderItem release];
	[flexItem release];
}

- (IBAction)addFolderQuestion:(id)sender
{
	const UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:
							NSLocalizedString(@"Really add all items in this folder?", @"")
							delegate: self
							cancelButtonTitle:NSLocalizedString(@"Cancel", "")
							destructiveButtonTitle:NSLocalizedString(@"Add recursively", @"")
							otherButtonTitles: NSLocalizedString(@"Add", @""), nil];
	[actionSheet showFromTabBar:self.tabBarController.tabBar];
	[actionSheet release];
}

- (IBAction)toggleAddPlay:(id)sender
{
	_adding = !_adding;
	if(_adding)
		_addPlayToggle.title = NSLocalizedString(@"Adding to Playlist", @"");
	else
		_addPlayToggle.title = NSLocalizedString(@"Playing immediately", @"");
}

- (void)addCurrentFolder
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

	_massAdd = YES;
	[_fileList getFiles];
	_massAdd = NO;

	[_playlist refreshData];
	[activityIndicatorView stopAnimating];
	[activityIndicatorView removeFromSuperview];
	self.view.userInteractionEnabled = YES;
	self.activityIndicatorView = nil;

	[pool release];
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
	else // destructive or other
	{
		const BOOL recursive = (buttonIndex == actionSheet.destructiveButtonIndex);
		activityIndicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
		activityIndicatorView.frame = CGRectMake(0, 0, 40, 40);
		activityIndicatorView.center = self.view.center;
		[self.view addSubview: activityIndicatorView];
		self.view.userInteractionEnabled = NO;
		[activityIndicatorView startAnimating];

		if(recursive)
		{
			RecursiveFileAdder *rfa = [[RecursiveFileAdder alloc] initWithPath:_fileList.path];
			[rfa addFilesToDelegate:self];
			[rfa release];
		}
		else
		{
			[NSThread detachNewThreadSelector:@selector(addCurrentFolder) toTarget:self withObject:nil];
		}
	}
}

#pragma mark -
#pragma mark RecursiveFileAdderDelegate methods
#pragma mark -

- (void)recursiveFileAdder:(RecursiveFileAdder *)rfa addFile:(NSObject<FileProtocol> *)file
{
	[[RemoteConnectorObject sharedRemoteConnector] addTrack:file startPlayback:NO];
}

- (void)recursiveFileAdderDoneAddingFiles:(RecursiveFileAdder *)rfa
{
	[_playlist refreshData];

	[activityIndicatorView stopAnimating];
	[activityIndicatorView removeFromSuperview];
	self.view.userInteractionEnabled = YES;
	self.activityIndicatorView = nil;
}

#pragma mark -
#pragma mark UIViewController
#pragma mark -

- (void)viewWillAppear:(BOOL)animated
{
	if([[RemoteConnectorObject sharedRemoteConnector] hasFeature:kFeaturesAbout])
		_retrieveCurrentUsing = kRetrieveCurrentUsingAbout;
	else if([[RemoteConnectorObject sharedRemoteConnector] hasFeature:kFeaturesCurrent])
		_retrieveCurrentUsing = kRetrieveCurrentUsingCurrent;
	else
		_retrieveCurrentUsing = kRetrieveCurrentUsingNone;

	[_playlist refreshData];
	[self placeControls:self.interfaceOrientation duration:0];

	[self configureToolbar]; // need to know nav before doing this, so unable to do this in loadView
	if([_fileList superview])
		[self.navigationController setToolbarHidden:NO animated:YES];

	// only start timer if there is a known way to retrieve currently playing track
	if(_retrieveCurrentUsing != kRetrieveCurrentUsingNone)
	{
		// FIXME: interval should be configurable
		_timer = [NSTimer scheduledTimerWithTimeInterval: 10.0
											target: self selector:@selector(fetchCurrentDefer)
											userInfo: nil repeats: YES];
		[_timer fire];
	}

	[super viewWillAppear: animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
	[_timer invalidate];
	_timer = nil;
	// NOTE: animating this does only hide the items, not the bar…
	[self.navigationController setToolbarHidden:YES animated:NO];

	[super viewWillDisappear:animated];
}

- (void)loadView
{
	const CGFloat factor = (IS_IPAD()) ? 2.38f : 1.0f;
	const CGFloat imageWidth = 45;
	const CGFloat imageHeight = 35;
	CGRect frame;

	// setup our parent content view and embed it to your view controller
	UIView *contentView = [[UIView alloc] initWithFrame:[[UIScreen mainScreen] applicationFrame]];
	if(IS_IPAD())
	{
		contentView.backgroundColor = [UIColor colorWithRed:0.821f green:0.834f blue:0.860f alpha:1];
	}
	else
	{
		contentView.backgroundColor = [UIColor groupTableViewBackgroundColor];	// use the table view background color
	}

	// setup our content view so that it auto-rotates along with the UViewController
	contentView.autoresizesSubviews = YES;
	contentView.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);

	self.view = contentView;
	[contentView release];

	// file list
	frame = self.view.frame;
	_fileList = [[FileListView alloc] initWithFrame: frame];
	if(IS_IPAD())
		_fileList.autoresizingMask = UIViewAutoresizingNone;
	_fileList.path = @"/";
	_fileList.fileDelegate = self;

	// frontend
	if(IS_IPAD())
		// FIXME: wtf?!
		frame = CGRectMake(0, 0, self.view.frame.size.width, (self.view.frame.size.height - self.tabBarController.tabBar.frame.size.height - self.navigationController.navigationBar.frame.size.height) * 4 / 5);
	else
		frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height * 7/8);
	_playlist = [[FileListView alloc] initWithFrame:frame];
	_playlist.fileDelegate = self;
	_playlist.isPlaylist = YES;

	if(IS_IPAD())
	{
		_portraitControlsFrame = CGRectMake(0, 750, 768, 84);
		_landscapeControlsFrame = CGRectMake(143, 500, 911, 84);
	}
	else
	{
		_portraitControlsFrame = CGRectMake(0, 320, 320, 35);
		_landscapeControlsFrame = CGRectMake(85, 175, 367, 35);
	}
	_controls = [[UIView alloc] initWithFrame:_portraitControlsFrame];

	// controls
	UIButton *roundedButtonType;
	CGFloat localX = (_controls.frame.size.width / factor) / 2 - 2 * ((imageWidth + kTweenMargin));

	// prev
	frame = CGRectMake(localX * factor, 0, imageWidth * factor, imageHeight * factor);
	roundedButtonType = [self newButton:frame withImage:@"key_fr.png" andKeyCode: kButtonCodeFRwd];
	[_controls addSubview: roundedButtonType];
	[roundedButtonType release];
	localX += imageWidth + kTweenMargin;

	// stop
	frame = CGRectMake(localX * factor, 0, imageWidth * factor, imageHeight * factor);
	roundedButtonType = [self newButton:frame withImage:@"key_stop.png" andKeyCode: kButtonCodeStop];
	[_controls addSubview: roundedButtonType];
	[roundedButtonType release];
	localX += imageWidth + kTweenMargin;

	// play/pause
	frame = CGRectMake(localX * factor, 0, imageWidth * factor, imageHeight * factor);
	roundedButtonType = [self newButton:frame withImage:@"key_pp.png" andKeyCode: kButtonCodePlayPause];
	[_controls addSubview: roundedButtonType];
	[roundedButtonType release];
	localX += imageWidth + kTweenMargin;

	// next
	frame = CGRectMake(localX * factor, 0, imageWidth * factor, imageHeight * factor);
	roundedButtonType = [self newButton:frame withImage:@"key_ff.png" andKeyCode: kButtonCodeFFwd];
	[_controls addSubview: roundedButtonType];
	[roundedButtonType release];
	//localX += imageWidth + kTweenMargin;

	[self.view addSubview: _playlist];
	[self.view addSubview: _controls];

	self.navigationItem.rightBarButtonItem = self.editButtonItem;
	[self configureToolbar];
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated
{
	[super setEditing:editing animated:animated];
	[_playlist setEditing:editing animated:animated];

	if(editing)
	{
		UIBarButtonItem *barButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(flipView:)];
		self.navigationItem.leftBarButtonItem = barButtonItem;
		[barButtonItem release];
	}
	else
	{
		if([_fileList superview])
			[self flipView: nil];
		self.navigationItem.leftBarButtonItem = nil;
	}
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
	[super willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];

	[self placeControls: toInterfaceOrientation duration:duration];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return YES;
}

#pragma mark -
#pragma mark FileListDelegate methods
#pragma mark -

/* file was selected */
- (void)fileListView:(FileListView *)fileListView fileSelected:(NSObject<FileProtocol> *)file
{
	// playlist
	if([fileListView isEqual: _playlist])
	{
		Result *result = [[RemoteConnectorObject sharedRemoteConnector] playTrack:file];
		if(result.result)
		{
			if([_playlist selectPlayingByTitle:file.title])
				[self newTrackPlaying];
		}
		else
		{
			// Alert user
			const UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Unable to start playback", @"") message:result.resulttext
																 delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
			[alert show];
			[alert release];
		}
	}
	// filelist
	else
	{
		const BOOL startPlayback = (_massAdd) ? NO : !_adding;
		Result *result = [[RemoteConnectorObject sharedRemoteConnector] addTrack:file startPlayback:startPlayback];
		if(result.result)
		{
			if(!_massAdd)
				[_playlist refreshData];
		}
		else
		{
			// Alert user
			const UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Could not add song to playlist", @"") message:result.resulttext
																 delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
			[alert show];
			[alert release];
		}
	}
}

/* playlist item was removed */
- (void)fileListView:(FileListView *)fileListView fileRemoved:(NSObject<FileProtocol> *)file
{
	Result *result = [[RemoteConnectorObject sharedRemoteConnector] removeTrack:file];
	if(!result.result)
	{
		// Alert user
		const UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Removing track failed", @"") message:result.resulttext
															 delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
		[alert show];
		[alert release];
	}
	else
	{
		[fileListView removeFile:file];
	}
}

#pragma mark -
#pragma mark AboutSourceDelegate
#pragma mark -

- (void)addAbout:(NSObject <AboutProtocol>*)about
{
	NSString *sname = about.sname;
	// sname == nil indicates no support for sname in about
	if(sname == nil)
	{
		// try current if connector supports it, otherwise abort
		if([[RemoteConnectorObject sharedRemoteConnector] hasFeature:kFeaturesCurrent])
			_retrieveCurrentUsing = kRetrieveCurrentUsingCurrent;
		else
			_retrieveCurrentUsing = kRetrieveCurrentUsingNone;
	}
	else if([_playlist selectPlayingByTitle: sname])
		[self newTrackPlaying];
}

#pragma mark -
#pragma mark ServiceSourceDelegate
#pragma mark -

- (void)addService: (NSObject<ServiceProtocol> *)service
{
	if([_playlist selectPlayingByTitle: service.sname])
		[self newTrackPlaying];
}

#pragma mark -
#pragma mark EventSourceDelegate
#pragma mark -

- (void)addEvent: (NSObject<EventProtocol> *)event
{
	//
}

#pragma mark -
#pragma mark Split view support
#pragma mark -

- (void)splitViewController: (UISplitViewController*)svc willHideViewController:(UIViewController *)aViewController withBarButtonItem:(UIBarButtonItem*)barButtonItem forPopoverController: (UIPopoverController*)pc
{
	barButtonItem.title = aViewController.title;
	self.navigationItem.leftBarButtonItem = barButtonItem;
	self.popoverController = pc;
}


// Called when the view is shown again in the split view, invalidating the button and popover controller.
- (void)splitViewController: (UISplitViewController*)svc willShowViewController:(UIViewController *)aViewController invalidatingBarButtonItem:(UIBarButtonItem *)barButtonItem
{
	self.navigationItem.leftBarButtonItem = nil;
	self.popoverController = nil;
}

@end
