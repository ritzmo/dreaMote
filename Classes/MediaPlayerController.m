//
//  MediaPlayerController.m
//  dreaMote
//
//  Created by Moritz Venn on 01.05.11.
//  Copyright 2011 Moritz Venn. All rights reserved.
//

#import "MediaPlayerController.h"
#import "RemoteConnectorObject.h"
#import "Constants.h"

#import "Result.h"
#import "RCButton.h"
#import "FileListView.h"
#import "FileProtocol.h"

#define kTransitionDuration	(CGFloat)0.6

@interface MediaPlayerController()
/*!
 @brief Create custom Button.
 
 @param frame Button Frame.
 @param imagePath Path to Button Image.
 @param keyCode RC Code.
 @return UIButton instance.
 */
- (UIButton*)newButton:(CGRect)frame withImage:(NSString*)imagePath andKeyCode:(int)keyCode;
- (void)placeControls:(UIInterfaceOrientation)interfaceOrientation duration:(NSTimeInterval)duration;
@end

@implementation MediaPlayerController

- (id)init
{
	if((self = [super init]))
	{
		self.title = NSLocalizedString(@"MediaPlayer", @"Title of MediaPlayerController");
	}

	return self;
}

- (void)dealloc
{
	[_fileList release];
	[_playlist release];
	[_frontend release];
	[_controls release];

	[super dealloc];
}

- (void)viewWillAppear:(BOOL)animated
{
	[_playlist refreshData];
	[self placeControls:self.interfaceOrientation duration:0];

	[super viewWillAppear: animated];
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
	// FIXME: wtf?!
	frame = CGRectMake(0, 0, self.view.frame.size.height - self.tabBarController.tabBar.frame.size.height - self.navigationController.navigationBar.frame.size.height, self.view.frame.size.height - self.tabBarController.tabBar.frame.size.height - self.navigationController.navigationBar.frame.size.height);
	_fileList = [[FileListView alloc] initWithFrame: frame];
	_fileList.path = @"/";
	_fileList.fileDelegate = self;

	// frontend
	_frontend = [[UIView alloc] initWithFrame:frame];
	_frontend.autoresizesSubviews = YES;
	_frontend.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
	if(IS_IPAD())
		frame = CGRectMake(0, 0, _frontend.frame.size.width, _frontend.frame.size.height * 4 / 5);
	else
		frame = CGRectMake(0, 0, _frontend.frame.size.width, _frontend.frame.size.height);
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
		_portraitControlsFrame = CGRectMake(0, 300, 320, 35);
		_landscapeControlsFrame = CGRectMake(85, 170, 367, 35);
	}
	_controls = [[UIView alloc] initWithFrame:_portraitControlsFrame];
	
	NSLog(@"%.2f %.2f %.2f %.2f", _portraitControlsFrame.origin.x, _portraitControlsFrame.origin.y, _portraitControlsFrame.size.width, _portraitControlsFrame.size.height);
	NSLog(@"%.2f %.2f %.2f %.2f", _landscapeControlsFrame.origin.x, _landscapeControlsFrame.origin.y, _landscapeControlsFrame.size.width, _landscapeControlsFrame.size.height);

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

	[_frontend addSubview: _controls];
	[_frontend addSubview: _playlist];
	[self.view addSubview: _frontend];
	
	self.navigationItem.rightBarButtonItem = self.editButtonItem;
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
	self.navigationItem.leftBarButtonItem = nil;

	[UIView setAnimationTransition:
				([_frontend superview] ? UIViewAnimationTransitionFlipFromLeft : UIViewAnimationTransitionFlipFromRight)
				forView: self.view
				cache: YES];

	if ([_fileList superview])
	{
		[_fileList removeFromSuperview];
	}
	else
	{
		[self.view addSubview: _fileList];
	}

	[UIView commitAnimations];
}

- (void)placeControls:(UIInterfaceOrientation)interfaceOrientation duration:(NSTimeInterval)duration
{
	[UIView beginAnimations:nil context:NULL];
	[UIView setAnimationDuration: duration];

	if(UIInterfaceOrientationIsLandscape(interfaceOrientation))
	{
		_controls.frame = _landscapeControlsFrame;
	}
	else
	{
		_controls.frame = _portraitControlsFrame;
	}

	[UIView commitAnimations];
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
		[[RemoteConnectorObject sharedRemoteConnector] playTrack:file];
	}
	// filelist
	else
	{
		[[RemoteConnectorObject sharedRemoteConnector] addTrack:file startPlayback:NO];
		[_playlist refreshData];
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

@end
