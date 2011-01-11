//
//  RCEmulatorController.m
//  dreaMote
//
//  Created by Moritz Venn on 23.07.08.
//  Copyright 2008-2011 Moritz Venn. All rights reserved.
//

#import <AudioToolbox/AudioServices.h>

#import "RCEmulatorController.h"
#import "RemoteConnectorObject.h"
#import "RCButton.h"
#import "Constants.h"

#define kTransitionDuration	(CGFloat)0.6
#define kImageScale			((IS_IPAD()) ? (CGFloat)1.0 : (CGFloat)0.45)

@interface RCEmulatorController()
/*!
 @brief entry point of thread which loads the screenshot
 @param dummy ui element
 */
- (void)loadImageThread:(id)dummy;

/*!
 @brief set screenshot type to osd
 @param sender ui element
 */
- (void)setOSDType:(id)sender;

/*!
 @brief set screenshot type to video
 @param sender ui element
 */
- (void)setVideoType:(id)sender;

/*!
 @brief set screenshot type to both
 @param sender ui element
 */
- (void)setBothType:(id)sender;

/*!
 @brief a button was pressed
 @param sender ui element
 */
- (void)buttonPressed:(RCButton *)sender;

/*!
 @brief Change frames/views according to orientation
 */
- (void)manageViews:(UIInterfaceOrientation)interfaceOrientation;
@end

@implementation RCEmulatorController

@synthesize rcView;

- (id)init
{
	if((self = [super init]))
	{
		self.title = NSLocalizedString(@"Remote Control", @"Title of RCEmulatorController");
		_screenshotType = kScreenshotTypeOSD;
	}

	return self;
}

- (void)dealloc
{
	[_toolbar release];
	[rcView release];

	[_screenView release];
	[_scrollView release];
	[_imageView release];
	[_screenshotButton release];

	[_keyPad release];
	[_navigationPad release];

	[super dealloc];
}

- (void)viewWillAppear:(BOOL)animated
{
	_shouldVibrate = [[NSUserDefaults standardUserDefaults] boolForKey: kVibratingRC];

	if([[RemoteConnectorObject sharedRemoteConnector] hasFeature: kFeaturesScreenshot])
	{
		// flex item used to separate the left groups items and right grouped items
		const UIBarButtonItem *flexItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
																	target:nil
																	action:nil];

		// create a bordered style button with custom title
		const UIBarButtonItem *osdItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"OSD", @"")
																	style:UIBarButtonItemStyleBordered
																	target:self
																	action:@selector(setOSDType:)];

		// create a bordered style button with custom title
		const UIBarButtonItem *videoItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Video", @"")
																	style:UIBarButtonItemStyleBordered
																	target:self
																	action:@selector(setVideoType:)];

		// create a bordered style button with custom title
		const UIBarButtonItem *bothItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"All", @"")
																	style:UIBarButtonItemStyleBordered
																	target:self
																	action:@selector(setBothType:)];
		
		NSArray *items;
		if([[RemoteConnectorObject sharedRemoteConnector] hasFeature: kFeaturesVideoScreenshot])
			items = [NSArray arrayWithObjects: _screenshotButton, flexItem, osdItem, videoItem, bothItem, nil];
		else
			items = [NSArray arrayWithObjects: _screenshotButton, flexItem, osdItem, bothItem, nil];
		[_toolbar setItems:items animated:NO];

		[flexItem release];
		[osdItem release];
		[videoItem release];
		[bothItem release];

		if([_screenView superview])
			[self loadImage: nil];
	}
	else
	{
		if([_screenView superview])
			[self flipView: nil];
	}

	// eventually fix toolbar size
	[_toolbar sizeToFit];
	const CGFloat _toolbarHeight = _toolbar.frame.size.height;
	const CGFloat width = self.view.frame.size.width;
	_toolbar.frame = CGRectMake(0, -1, width, _toolbarHeight);

	// fix up views
	if(_navigationPad != nil)
		[self manageViews:self.interfaceOrientation];

	[super viewWillAppear: animated];
}

- (void)loadView
{
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

	// Flip Button
	_screenshotButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Screenshot", @"")
														style:UIBarButtonItemStyleBordered
														target:self
														action:@selector(flipView:)];

	CGSize mainViewSize = self.view.bounds.size;
	CGRect frame;

	_toolbar = [UIToolbar new];
	_toolbar.barStyle = UIBarStyleDefault;

	// size up the _toolbar and set its frame
	[_toolbar sizeToFit];
	const CGFloat _toolbarHeight = _toolbar.frame.size.height;
	_toolbar.frame = CGRectMake(0,
								-1,
								mainViewSize.width,
								_toolbarHeight);
	[self.view addSubview:_toolbar];

	// ImageView for Screenshots
	frame = CGRectMake(0, _toolbarHeight, mainViewSize.width, mainViewSize.height - _toolbarHeight - self.tabBarController.tabBar.frame.size.height - self.navigationController.navigationBar.frame.size.height);
	_screenView = [[UIView alloc] initWithFrame: frame];

	frame.origin.y = 0;
	_scrollView = [[UIScrollView alloc] initWithFrame: frame];
	_scrollView.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
	_scrollView.autoresizesSubviews = YES;
	_screenView.clipsToBounds = NO;
	_scrollView.contentMode = (UIViewContentModeScaleAspectFit);
	_scrollView.delegate = self;
	_scrollView.maximumZoomScale = (CGFloat)2.6;
	_scrollView.minimumZoomScale = (CGFloat)1.0;
	_scrollView.exclusiveTouch = NO;
	[_screenView addSubview: _scrollView];
	_imageView = [[UIImageView alloc] initWithFrame: CGRectZero];
	_imageView.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
	_imageView.autoresizesSubviews = YES;
	_imageView.contentMode = UIViewContentModeScaleAspectFit;
	[_scrollView addSubview: _imageView];
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

	[UIView setAnimationTransition:
				([rcView superview] ? UIViewAnimationTransitionFlipFromLeft : UIViewAnimationTransitionFlipFromRight)
				forView: self.view
				cache: YES];

	if ([_screenView superview])
	{
		[_screenView removeFromSuperview];
		_screenshotButton.title = NSLocalizedString(@"Screenshot", @"");
		[self.view addSubview: rcView];
	}
	else
	{
		[self loadImage: nil];
		[rcView removeFromSuperview];
		_screenshotButton.title = NSLocalizedString(@"Done", @"");
		[self.view addSubview: _screenView];
	}

	[UIView commitAnimations];
}

- (void)loadImage:(id)dummy
{
	[NSThread detachNewThreadSelector:@selector(loadImageThread:) toTarget:self withObject:nil];
}

- (void)loadImageThread:(id)dummy
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

	NSData *data = [[RemoteConnectorObject sharedRemoteConnector] getScreenshot: _screenshotType];
	UIImage * image = [UIImage imageWithData: data];
	if(image != nil)
	{
		CGSize size = CGSizeMake(image.size.width*kImageScale, image.size.height*kImageScale);

		_imageView.image = image;
		_scrollView.contentSize = size;
		_imageView.frame = CGRectMake(0, 0, size.width, size.height);
	}

	[pool release];
}

- (void)setOSDType:(id)sender
{
	_screenshotType = kScreenshotTypeOSD;
	if([_screenView superview])
		[self loadImage: nil];
	else
		[self flipView: nil];
}

- (void)setVideoType:(id)sender
{
	_screenshotType = kScreenshotTypeVideo;
	if([_screenView superview])
		[self loadImage: nil];
	else
		[self flipView: nil];
}

- (void)setBothType:(id)sender
{
	_screenshotType = kScreenshotTypeBoth;
	if([_screenView superview])
		[self loadImage: nil];
	else
		[self flipView: nil];
}

- (void)buttonPressed:(RCButton *)sender
{
	// Spawn a thread to send the request so that the UI is not blocked while
	// waiting for the response.
	[NSThread detachNewThreadSelector:@selector(sendButton:)
							toTarget:self
							withObject: [NSNumber numberWithInteger: sender.rcCode]];
}

- (IBAction)buttonPressedIB:(UIButton *)sender
{
	// Spawn a thread to send the request so that the UI is not blocked while
	// waiting for the response.
	[NSThread detachNewThreadSelector:@selector(sendButton:)
							toTarget:self
							withObject: [NSNumber numberWithInteger: sender.tag]];
}

- (void)sendButtonInternal: (NSInteger)rcCode
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

	if([[RemoteConnectorObject sharedRemoteConnector] sendButton: rcCode]
	   && _shouldVibrate)
		AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);

	[pool release];
}

- (void)sendButton: (NSNumber *)rcCode
{
	[self sendButtonInternal: [rcCode integerValue]];
}

/* alter views */
- (void)manageViews:(UIInterfaceOrientation)interfaceOrientation
{
	if(UIInterfaceOrientationIsLandscape(interfaceOrientation))
	{
		_keyPad.frame = CGRectMake(74, -600, 0, 0);
		_navigationPad.frame = _landscapeNavigationFrame;
		rcView.frame = _landscapeFrame;
	}
	else
	{
		_keyPad.frame = _portraitKeyFrame;
		_navigationPad.frame = _portraitNavigationFrame;
		rcView.frame = _portraitFrame;
	}
}

/* about to rotate */
- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
	_imageView.image = nil;
	_toolbar.frame = CGRectInfinite;

	if(_navigationPad != nil)
	{
		[UIView beginAnimations:nil context:NULL];
		[UIView setAnimationDuration: duration];
		[self manageViews:toInterfaceOrientation];
		[UIView commitAnimations];
	}

	[super willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
}

/* finished rotation */
- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
	//[UIView beginAnimations:nil context:NULL];
	//[UIView setAnimationDuration: kTransitionDuration];

	// adjust size of _screenView, _toolbar & _scrollView
	CGSize mainViewSize = self.view.bounds.size;
	[_toolbar sizeToFit];
	const CGFloat _toolbarHeight = _toolbar.frame.size.height;
	const CGFloat width = mainViewSize.width;
	_toolbar.frame = CGRectMake(0, -1, width, _toolbarHeight);
	_screenView.frame = CGRectMake(0, _toolbarHeight, width, mainViewSize.height - _toolbarHeight);
	_scrollView.frame = CGRectMake(0, 0, width, mainViewSize.height);

	// FIXME: we load a new image as I'm currently unable to figure out how to readjust the old one
	if(_screenView.superview)
		[self loadImage: nil];

	//[UIView commitAnimations];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	if([_screenView superview])
		return YES;

	// RC should only be displayed in (either) portrait mode unless we have a _navigationPad
	return _navigationPad != nil
		|| (interfaceOrientation == UIInterfaceOrientationPortrait)
		|| (interfaceOrientation == UIInterfaceOrientationPortraitUpsideDown);
}

#pragma mark UIScrollView delegates

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)_scrollView
{
    return _imageView;
}

@end
