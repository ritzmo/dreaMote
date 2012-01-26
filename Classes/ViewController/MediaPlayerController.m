//
//  MediaPlayerController.m
//  dreaMote
//
//  Created by Moritz Venn on 01.05.11.
//  Copyright 2011-2012 Moritz Venn. All rights reserved.
//

#import "MediaPlayerController.h"

#import "AppDelegate.h"

#import "Constants.h"
#import "RecursiveFileAdder.h"
#import "RemoteConnectorObject.h"
#import "UITableViewCell+EasyInit.h"

#import <ListController/ReloadableListController.h> // property tableView
#import <Objects/FileProtocol.h>
#import <Objects/Generic/Result.h>
#import <View/FileListView.h>
#import <View/RCButton.h>
#import <View/UIPromptView.h>

#import "MBProgressHUD.h"

#import <XMLReader/SaxXmlReader.h>

#define deleteExtraWidth	35
#define kTransitionDuration	(CGFloat)0.6

/*!
 @brief Tags used to identify action sheets.
 */
enum mediaPlayerTags
{
	TAG_NONE = 0,
	TAG_ADD = 1,
	TAG_EXIT = 2,
};

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
@property (nonatomic, strong) UIPopoverController *popoverController;

/*!
 @brief Activity Indicator.
 */
@property (nonatomic, strong) MBProgressHUD *progressHUD;
@end

@implementation MediaPlayerController

@synthesize popoverController, progressHUD;
@synthesize deleteButton = _deleteButton;
@synthesize shuffleButton = _shuffleButton;

- (id)init
{
	if((self = [super init]))
	{
		self.title = NSLocalizedString(@"MediaPlayer", @"Title of MediaPlayerController");
		_adding = YES;
		_massAdd = NO;

		_shuffleButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Shuffle", @"Shuffle button in MediaPlayer")
														style:UIBarButtonItemStyleBordered
													   target:self
													   action:@selector(shuffle:)];
		_deleteButton = [UIButton buttonWithType:UIButtonTypeCustom];
		[_deleteButton setTitleEdgeInsets:UIEdgeInsetsMake(-1, 0, 0, 0)];
		_deleteButton.titleLabel.font = [UIFont systemFontOfSize:17];
		[_deleteButton setBackgroundImage:[[UIImage imageNamed:@"delete.png"] stretchableImageWithLeftCapWidth:5.0 topCapHeight:0.0] forState:UIControlStateNormal];
		[_deleteButton setImage:[UIImage imageNamed:@"trashicon.png"] forState:UIControlStateNormal];
		NSString *text = NSLocalizedString(@"Delete", @"Delete button in MediaPlayer");
		CGSize textSize = [text sizeWithFont:_deleteButton.titleLabel.font];
		[_deleteButton setTitle:text forState:UIControlStateNormal];
		_deleteButton.frame = CGRectMake(0, 0, textSize.width + deleteExtraWidth, 33);
		[_deleteButton addTarget:self action:@selector(multiDelete:) forControlEvents:UIControlEventTouchUpInside];
		_deleteButton.enabled = NO;
	}

	return self;
}

- (void)dealloc
{
	[self stopObservingThemeChanges];
	[_closeSheet dismissWithClickedButtonIndex:_closeSheet.cancelButtonIndex animated:NO];
	progressHUD.delegate = nil;
}

- (void)newTrackPlaying
{
	//
}

- (void)fetchCurrentDefer
{
	if(_playlist.reloading) return;

	switch(_retrieveCurrentUsing)
	{
		case kRetrieveCurrentUsingAbout:
			[RemoteConnectorObject queueInvocationWithTarget:self selector:@selector(fetchAbout)];
			break;
		case kRetrieveCurrentUsingCurrent:
			[RemoteConnectorObject queueInvocationWithTarget:self selector:@selector(fetchCurrent)];
			break;
		default:
			[_timer invalidate];
			_timer = nil;
			break;
	}
}

- (void)fetchAbout
{
	SaxXmlReader *newReader = nil;
	@try {
		newReader = [[RemoteConnectorObject sharedRemoteConnector] getAbout:self];
	}
	@catch (NSException * e) {
#if IS_DEBUG()
		[e raise];
#endif
	}
	_xmlReader = newReader;
}

- (void)fetchCurrent
{
	SaxXmlReader *newReader = nil;
	@try {
		newReader = [[RemoteConnectorObject sharedRemoteConnector] getCurrent:self];
	}
	@catch (NSException * e) {
#if IS_DEBUG()
		[e raise];
#endif
	}
	_xmlReader = newReader;
}

- (void)sendCommand:(NSString *)command
{
	@autoreleasepool {

		Result *result = [[RemoteConnectorObject sharedRemoteConnector] mediaplayerCommand:command];
		if(!result.result)
		{
			// Alert user
			const UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Sending command failed", @"") message:result.resulttext
																 delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
			[alert show];
		}

	}
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

	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
		Result *result = [[RemoteConnectorObject sharedRemoteConnector] mediaplayerCommand:command];
		if(!result.result)
		{
			// Alert user
			const UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Sending command failed", @"") message:result.resulttext
																 delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
			[alert show];
		}
	});
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
	if(IS_IPHONE())
	{
		if([self.navigationItem respondsToSelector:@selector(leftBarButtonItems)])
			self.navigationItem.leftBarButtonItems = nil;
		else
			self.navigationItem.leftBarButtonItem = nil;
	}

	[UIView setAnimationTransition:
				([_fileList superview] ? UIViewAnimationTransitionFlipFromRight : UIViewAnimationTransitionFlipFromLeft)
				forView: self.view
				cache: YES];

	if ([_fileList superview])
	{
		[_fileList removeFromSuperview];
		[self hideToolbar];
	}
	else
	{
		[self.view addSubview: _fileList];
		[self showToolbar];
	}

	[UIView commitAnimations];

	// fix up frame on iphone
	if(!IS_IPAD())
		_fileList.frame = self.view.frame;
}

- (IBAction)showPlaylists:(id)sender
{
	[_fileList setPath:@"/etc/enigma2/playlist/"];

	// show filelist if not visible
	if(![_fileList superview])
		[self flipView:nil];
}

- (IBAction)clearPlaylist:(id)sender
{
	[_playlist.selectedFiles addObjectsFromArray:_playlist.files];
	[self multiDelete:nil];
}

- (IBAction)savePlaylist:(id)sender
{
	UIPromptView *alertView = [[UIPromptView alloc] initWithTitle:NSLocalizedString(@"Enter name of Playlist", @"Title of prompt requesting name for playlist to be saved in MediaPlayer")
														   message:nil
														  delegate:self
												 cancelButtonTitle:NSLocalizedString(@"Cancel", @"")
													 okButtonTitle:NSLocalizedString(@"Save", @"")
	];
	alertView.promptViewStyle = UIPromptViewStylePlainTextInput;
	[alertView show];
}

- (void)multiDeleteDefer
{
	@autoreleasepool {

		const NSArray *selectedFiles = [_playlist.selectedFiles copy]; // NOTE: create a copy to prevent mutation during enumeration
		NSUInteger count = selectedFiles.count;
		// XXX: we abuse the shuffle callbacks here...
		[self performSelectorOnMainThread:@selector(remainingShuffleActions:) withObject:[NSNumber numberWithUnsignedInteger:count] waitUntilDone:NO];
		for(NSObject<FileProtocol> *file in selectedFiles)
		{
			/*Result *result = */[[RemoteConnectorObject sharedRemoteConnector] removeTrack:file];
			// XXX: we silently ignore errors
			--count;
			[self performSelectorOnMainThread:@selector(remainingShuffleActions:) withObject:[NSNumber numberWithUnsignedInteger:count] waitUntilDone:NO];
		}
		[_playlist.selectedFiles removeAllObjects]; // XXX: assume we successfully removed all tracks
		[self performSelectorOnMainThread:@selector(finishedShuffling) withObject:nil waitUntilDone:NO];

	}
}

- (IBAction)multiDelete:(id)sender
{
	[popoverController dismissPopoverAnimated:YES];
	self.popoverController = nil;

	progressHUD = [[MBProgressHUD alloc] initWithView:self.view];
	[self.view addSubview:progressHUD];
	progressHUD.delegate = self;
	[progressHUD setLabelText:NSLocalizedString(@"Deleting", @"Label of Progress HUD in MediaPlayer when deleting multiple items from playlist")];
	[progressHUD setMode:MBProgressHUDModeDeterminate];
	progressHUD.progress = 0.0f;
	[progressHUD show:YES];
	progressHUD.taskInProgress = YES;

	NSString *text = NSLocalizedString(@"Delete", @"Delete button in MediaPlayer");
	CGSize textSize = [text sizeWithFont:_deleteButton.titleLabel.font];
	[_deleteButton setTitle:text forState:UIControlStateNormal];
	_deleteButton.frame = CGRectMake(0, 0, textSize.width + deleteExtraWidth, 33);
	_deleteButton.enabled = NO;
	_shuffleButton.enabled = NO;
	_progressActions = -1;
	[NSThread detachNewThreadSelector:@selector(multiDeleteDefer) toTarget:self withObject:nil];
}

- (IBAction)shuffle:(id)sender
{
	[popoverController dismissPopoverAnimated:YES];
	self.popoverController = nil;

	progressHUD = [[MBProgressHUD alloc] initWithView:self.view];
	[self.view addSubview:progressHUD];
	progressHUD.delegate = self;
	[progressHUD setLabelText:NSLocalizedString(@"Shuffling Playlist", @"Label of Progress HUD in MediaPlayer when shuffling playlist")];
	[progressHUD setMode:MBProgressHUDModeDeterminate];
	progressHUD.progress = 0.0f;
	[progressHUD show:YES];
	progressHUD.taskInProgress = YES;

	_deleteButton.enabled = NO;
	_shuffleButton.enabled = NO;
	_progressActions = -1;

	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
		[[RemoteConnectorObject sharedRemoteConnector] shufflePlaylist:self playlist:_playlist.files];
	});
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
	_addFolderItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Add Folder", @"Button in MediaPlayer to add current folder to playlist")
																	style:UIBarButtonItemStyleBordered
																	target:self
																	action:@selector(addFolderQuestion:)];

	// flex item used to separate the left groups items and right grouped items
	const UIBarButtonItem *flexItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
																					target:nil
																					action:nil];

	// create a bordered style button with custom title
	_addPlayToggle = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Adding to Playlist", @"Used in MediaPlayer, append tracks to playlist")
																	style:UIBarButtonItemStyleBordered
																	target:self
																	action:@selector(toggleAddPlay:)];

	NSArray *items = [[NSArray alloc] initWithObjects:_addFolderItem, flexItem, _addPlayToggle, nil];
	[self setToolbarItems:items animated:NO];

}

- (void)hideToolbar
{
	[self.navigationController setToolbarHidden:YES animated:YES];
}

- (void)showToolbar
{
	[self.navigationController setToolbarHidden:NO animated:YES];
}

- (IBAction)addFolderQuestion:(id)sender
{
	const UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:
							NSLocalizedString(@"Really add all items in this folder?", @"Used in MediaPlayer, choice presented to add current folder recursively or non-recursively to playlist")
							delegate: self
							cancelButtonTitle:NSLocalizedString(@"Cancel", "")
							destructiveButtonTitle:NSLocalizedString(@"Add recursively", @"Used in MediaPlayer, add shown folders recursively")
							otherButtonTitles: NSLocalizedString(@"Add", @"Used in MediaPlayer, add only the current folder"), nil];
	actionSheet.tag = TAG_ADD;
	actionSheet.actionSheetStyle = UIActionSheetStyleDefault;
	if(self.tabBarController == nil) // XXX: bug in MGSplitViewController?
		[actionSheet showInView:self.view];
	else
		[actionSheet showFromTabBar:self.tabBarController.tabBar];
}

- (IBAction)toggleAddPlay:(id)sender
{
	_adding = !_adding;
	if(_adding)
		_addPlayToggle.title = NSLocalizedString(@"Adding to Playlist", @"Used in MediaPlayer, append tracks to playlist");
	else
		_addPlayToggle.title = NSLocalizedString(@"Playing immediately", @"Used in MediaPlayer, append track to playlist and start playback");
}

- (void)addCurrentFolder
{
	@autoreleasepool {

		_massAdd = YES;
		[_fileList getFiles];
		_massAdd = NO;

		[_playlist refreshData];
	}
}

- (void)dismissActionSheet:(NSNotification *)notif
{
	[_closeSheet dismissWithClickedButtonIndex:_closeSheet.cancelButtonIndex animated:NO];
	_closeSheet = nil;
}

#pragma mark -
#pragma mark MediaPlayerShuffleDelegate
#pragma mark -

- (void)finishedShuffling
{
	progressHUD.taskInProgress = NO;
	[progressHUD hide:YES];

	_deleteButton.enabled = (_playlist.selectedFiles.count > 0); // XXX: might needlessly create a new array
	_shuffleButton.enabled = YES;
	_progressActions = -1;

	[_playlist refreshData];
}

- (void)remainingShuffleActions:(NSNumber *)count
{
	if(_progressActions == -1)
		_progressActions = [count integerValue];
	progressHUD.progress = 1 - ([count integerValue] / _progressActions);
}

#pragma mark -
#pragma mark MBProgressHUDDelegate
#pragma mark -

- (void)hudWasHidden:(MBProgressHUD *)hud
{
	[progressHUD removeFromSuperview];
	self.progressHUD = nil;
}

#pragma mark -
#pragma mark UIActionSheetDelegate methods
#pragma mark -

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
	if(actionSheet.tag == TAG_ADD)
	{
		if(buttonIndex == actionSheet.cancelButtonIndex)
		{
			// do nothing
		}
		else // destructive or other
		{
			const BOOL recursive = (buttonIndex == actionSheet.destructiveButtonIndex);
			UIView *baseView = nil;
			if(self.tabBarController == nil) // XXX: bug in MGSplitViewController?
				baseView = self.view;
			else
				baseView = self.tabBarController.view;
			progressHUD = [[MBProgressHUD alloc] initWithView:baseView];
			[baseView addSubview: progressHUD];
			progressHUD.delegate = self;

			if(recursive)
			{
				RecursiveFileAdder *rfa = [[RecursiveFileAdder alloc] initWithPath:_fileList.path];
				[rfa addFilesToDelegate:self];
				[progressHUD show:YES];
				progressHUD.taskInProgress = YES;
			}
			else
			{
				[progressHUD showWhileExecuting:@selector(addCurrentFolder) onTarget:self withObject:nil animated:YES];
			}
		}
	}
	else if(actionSheet.tag == TAG_EXIT)
	{
		if(buttonIndex == actionSheet.firstOtherButtonIndex)
		{
			// Spawn a thread to send the request so that the UI is not blocked while
			// waiting for the response.
			[NSThread detachNewThreadSelector:@selector(sendCommand:)
									 toTarget:self
								   withObject:@"exit"];
		}
		_closeSheet = nil;
	}
}

#pragma mark -
#pragma mark UIAlertViewDelegate methods
#pragma mark -

- (void)alertView:(UIAlertView *)alertView willDismissWithButtonIndex:(NSInteger)buttonIndex
{
#define promptView (UIPromptView *)alertView
	if(buttonIndex != alertView.cancelButtonIndex)
	{
		NSString *filename = [promptView promptFieldAtIndex:0].text;
		NSString *title = nil;
		NSString *message = nil;
		if(filename.length)
		{
			Result *result = [[RemoteConnectorObject sharedRemoteConnector] savePlaylist:filename];
			if(!result.result)
				message = result.resulttext;
		}
		else
			message = NSLocalizedString(@"You have to enter a filename to save the playlist", @"No filename entered when trying to save MediaPlayer playlist");

		if(message)
		{
			title = NSLocalizedString(@"Error", @"");
		}
		else
		{
			title = NSLocalizedString(@"Success", @"");
			message = NSLocalizedString(@"Playlist saved successfully.", @"Playlist was saved in MediaPlayer");
		}

		// Alert user
		const UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title
															  message:message
															 delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
		[alert show];
	}
#undef promptView
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

	progressHUD.taskInProgress = NO;
	[progressHUD hide:YES];
}

#pragma mark -
#pragma mark UIViewController
#pragma mark -

- (void)viewWillAppear:(BOOL)animated
{
	@synchronized(self)
	{
		UIActionSheet *sheet = _closeSheet;
		if(sheet)
		{
			[sheet dismissWithClickedButtonIndex:sheet.cancelButtonIndex animated:NO];
		}
	}

	if([[RemoteConnectorObject sharedRemoteConnector] hasFeature:kFeaturesAbout])
		_retrieveCurrentUsing = kRetrieveCurrentUsingAbout;
	else if([[RemoteConnectorObject sharedRemoteConnector] hasFeature:kFeaturesCurrent])
		_retrieveCurrentUsing = kRetrieveCurrentUsingCurrent;
	else
		_retrieveCurrentUsing = kRetrieveCurrentUsingNone;

	if(!_playlist.reloading)
		[_playlist refreshData];
	[self placeControls:self.interfaceOrientation duration:0];

	[self configureToolbar]; // need to know nav before doing this, so unable to do this in loadView
	if([_fileList superview])
		[self showToolbar];

	// only start timer if there is a known way to retrieve currently playing track
	if(_retrieveCurrentUsing != kRetrieveCurrentUsingNone)
	{
		// FIXME: interval should be configurable
		_timer = [NSTimer scheduledTimerWithTimeInterval: 10.0
											target: self selector:@selector(fetchCurrentDefer)
											userInfo: nil repeats: YES];
	}

	[super viewWillAppear: animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
	[_timer invalidate];
	_timer = nil;
	// NOTE: animating this does only hide the items, not the bar…
	[self.navigationController setToolbarHidden:YES animated:NO];

	// NOTE: I had some problems locally with the action sheet being shown twice, so avoid it :D
	@synchronized(self)
	{
		if(_closeSheet == nil)
		{
			// prompt: exit media player?
			_closeSheet = [[UIActionSheet alloc] initWithTitle:
								NSLocalizedString(@"Close MediaPlayer?", @"Title of action sheet when leaving MediaPlayer view.")
													  delegate:self
											 cancelButtonTitle:NSLocalizedString(@"No", "")
										destructiveButtonTitle:nil
											 otherButtonTitles:NSLocalizedString(@"Yes", ""), nil];
			_closeSheet.tag = TAG_EXIT;
			_closeSheet.actionSheetStyle = UIActionSheetStyleDefault;
			UITabBarController *tabBarController = self.tabBarController;
			UIView *view = nil;
			if(tabBarController == nil) // XXX: bug in MGSplitViewController?
			{
				if(self.view)
				{
#if IS_DEBUG()
					NSLog(@"no tabBarController but self.view");
#endif
					view = self.view;
				}
				else
				{
					tabBarController = APP_DELEGATE.tabBarController;
				}
			}

			if(view)
				[_closeSheet showInView:view];
			else if(tabBarController)
				[_closeSheet showFromTabBar:tabBarController.tabBar];
			else
			{
#if IS_DEBUG()
				[NSException raise:@"NeitherTabBarControllerNorView" format:@"unable to determine view to show actionSheet from."];
#else
				// ignore
#endif
			}
		}
		// ignore if another sheet is already shown
	}

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
	contentView.autoresizesSubviews = YES;
	contentView.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);

	self.view = contentView;

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
	localX += imageWidth + kTweenMargin;

	// stop
	frame = CGRectMake(localX * factor, 0, imageWidth * factor, imageHeight * factor);
	roundedButtonType = [self newButton:frame withImage:@"key_stop.png" andKeyCode: kButtonCodeStop];
	[_controls addSubview: roundedButtonType];
	localX += imageWidth + kTweenMargin;

	// play/pause
	frame = CGRectMake(localX * factor, 0, imageWidth * factor, imageHeight * factor);
	roundedButtonType = [self newButton:frame withImage:@"key_pp.png" andKeyCode: kButtonCodePlayPause];
	[_controls addSubview: roundedButtonType];
	localX += imageWidth + kTweenMargin;

	// next
	frame = CGRectMake(localX * factor, 0, imageWidth * factor, imageHeight * factor);
	roundedButtonType = [self newButton:frame withImage:@"key_ff.png" andKeyCode: kButtonCodeFFwd];
	[_controls addSubview: roundedButtonType];
	//localX += imageWidth + kTweenMargin;

	[self.view addSubview: _playlist];
	[self.view addSubview: _controls];

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
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[self stopObservingThemeChanges];
	_fileList.fileDelegate = nil;
	_fileList = nil;
	_playlist.fileDelegate = nil;
	_playlist = nil;
	_controls = nil;
	// NOTE: we deliberately don't release _closeSheet here, but it's pretty safe to assume that it's nil at this point

	[super viewDidUnload];
}

- (void)theme
{
	const DreamoteConfiguration *singleton = [DreamoteConfiguration singleton];
	// TODO: check if background is correct and should not be the grouped color
	self.view.backgroundColor = [singleton groupedTableViewBackgroundColor];
	[singleton styleTableView:_playlist isSlave:YES];
	[_playlist theme];
	[singleton styleTableView:_fileList isSlave:YES];
	[_fileList theme];
	[super theme];
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated
{
	[super setEditing:editing animated:animated];
	[_playlist setEditing:editing animated:animated];

	if(editing)
	{
		self.title = nil; // XXX: too little space on iPhone/iPod Touch

		const UIBarButtonItem *flipItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd
																						target:self
																						action:@selector(flipView:)];
		const UIBarButtonItem *deleteItem = [[UIBarButtonItem alloc] initWithCustomView:_deleteButton];
		// iOS 5.0+
		if([self.navigationItem respondsToSelector:@selector(leftBarButtonItems)])
		{
			self.navigationItem.leftBarButtonItems = [NSArray arrayWithObjects:flipItem, _shuffleButton, deleteItem, nil];
		}
		else
		{
			const CGFloat toolbarHeight = (UIInterfaceOrientationIsPortrait(self.interfaceOrientation)) ? 44.01f : 32.01f;
			UIToolbar *toolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, 190, toolbarHeight)];
			toolbar.autoresizesSubviews = YES;
			toolbar.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
			const UIBarButtonItem *flexItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
																							target:nil
																							action:nil];
			NSArray *items = [[NSArray alloc] initWithObjects:flipItem, _shuffleButton, deleteItem, flexItem, nil];
			[toolbar setItems:items animated:NO];
			UIBarButtonItem *buttonItem = [[UIBarButtonItem alloc] initWithCustomView:toolbar];

			self.navigationItem.leftBarButtonItem = buttonItem;

		}
	}
	else
	{
		self.title = NSLocalizedString(@"MediaPlayer", @"Title of MediaPlayerController");

		if([_fileList superview])
			[self flipView: nil];
		// iOS 5.0+
		if([self.navigationItem respondsToSelector:@selector(leftBarButtonItems)])
			self.navigationItem.leftBarButtonItems = nil;
		else
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
		}
	}
	// filelist
	else
	{
		const BOOL isPlaylist = (_massAdd) ? NO : [file.root isEqualToString:@"/etc/enigma2/playlist/"] && ([file.sref hasSuffix:@".e2pls"] || [file.sref hasSuffix:@".pls"] || [file.sref hasSuffix:@".m3u"]);
		const BOOL startPlayback = (_massAdd) ? NO : !_adding;

		// playlist handling
		if(isPlaylist)
		{
			Result *result = [[RemoteConnectorObject sharedRemoteConnector] loadPlaylist:file];
			NSString *title = nil;
			NSString *message = nil;
			if(result.result)
			{
				title = NSLocalizedString(@"Success", @"");
				message = NSLocalizedString(@"Playlist was loaded successfully.", @"New MediaPlayer playlist was loaded");
			}
			else
			{
				title = NSLocalizedString(@"Error", @"");
				message = result.resulttext;
			}

			// Alert user
			const UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title
																  message:message
																 delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
			[alert show];

			// flip view (presumably) back
			[self flipView:nil];
			return;
		}

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
		}
	}
}

- (void)fileListView:(FileListView *)fileListView fileMultiSelected:(NSObject<FileProtocol> *)file
{
#if IS_DEBUG()
	NSParameterAssert([fileListView isEqual:_playlist]);
#endif

	NSUInteger count = fileListView.selectedFiles.count;
	NSString *text;
	if(count)
	{
		text = [NSString stringWithFormat:@"%@ (%d)", NSLocalizedString(@"Delete", @"Delete button in MediaPlayer"), count];
		_deleteButton.enabled = YES;
	}
	else
	{
		text = NSLocalizedString(@"Delete", @"Delete button in MediaPlayer");
		_deleteButton.enabled = NO;
	}
	CGSize textSize = [text sizeWithFont:_deleteButton.titleLabel.font];
	[_deleteButton setTitle:text forState:UIControlStateNormal];
	if(_deleteButton.frame.size.width != textSize.width + deleteExtraWidth)
		_deleteButton.frame = CGRectMake(0, 0, textSize.width + deleteExtraWidth, 33);
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
#pragma mark DataSourceDelegate
#pragma mark -

- (void)dataSourceDelegate:(SaxXmlReader *)dataSource errorParsingDocument:(NSError *)error
{
	// we want the playlist to indicate errors, since this is a recurring event
	// the annoyance would be huge
}

- (void)dataSourceDelegateFinishedParsingDocument:(SaxXmlReader *)dataSource
{
	//
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

- (void)splitViewController: (id)svc willHideViewController:(UIViewController *)aViewController withBarButtonItem:(UIBarButtonItem*)barButtonItem forPopoverController: (UIPopoverController*)pc
{
	barButtonItem.title = aViewController.title;
	// HACK: force-remove background color
	if([aViewController isKindOfClass:[UINavigationController class]])
		aViewController.view.backgroundColor = nil;
	self.navigationItem.leftBarButtonItem = barButtonItem;
	self.popoverController = pc;
}

// Called when the view is shown again in the split view, invalidating the button and popover controller.
- (void)splitViewController: (id)svc willShowViewController:(UIViewController *)aViewController invalidatingBarButtonItem:(UIBarButtonItem *)barButtonItem
{
	if([aViewController isKindOfClass:[UINavigationController class]])
	{
		UIViewController *visibleViewController = ((UINavigationController *)aViewController).visibleViewController;
		if([visibleViewController respondsToSelector:@selector(tableView)])
		{
			UITableView *tableView = ((ReloadableListController *)visibleViewController).tableView;
			aViewController.view.backgroundColor = tableView.backgroundColor;
		}
	}

	self.navigationItem.leftBarButtonItem = nil;
	self.popoverController = nil;
}

@end
