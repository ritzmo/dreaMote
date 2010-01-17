//
//  RCEmulatorController.m
//  dreaMote
//
//  Created by Moritz Venn on 23.07.08.
//  Copyright 2008-2010 Moritz Venn. All rights reserved.
//

#import <AudioToolbox/AudioServices.h>

#import "RCEmulatorController.h"
#import "RemoteConnectorObject.h"
#import "RCButton.h"
#import "Constants.h"

#define kTransitionDuration	(CGFloat)0.6
#define kImageScale			(CGFloat)0.45

@interface RCEmulatorController()
/*!
 @brief entry point of thread which loads the screenshot
 @param dummy ui element
 */
- (void)loadImageThread:(id)dummy;

/*!
 @param set screenshot type to osd
 @param sender ui element
 */
- (void)setOSDType:(id)sender;

/*!
 @param set screenshot type to video
 @param sender ui element
 */
- (void)setVideoType:(id)sender;

/*!
 @param set screenshot type to both
 @param sender ui element
 */
- (void)setBothType:(id)sender;

/*!
 @param a button was pressed
 @param sender ui element
 */
- (void)buttonPressed:(RCButton *)sender;

@end

@implementation RCEmulatorController

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

	[super dealloc];
}

- (void)viewWillAppear:(BOOL)animated
{
	_shouldVibrate = [[NSUserDefaults standardUserDefaults] boolForKey: kVibratingRC];

	if([[RemoteConnectorObject sharedRemoteConnector] hasFeature: kFeaturesScreenshot])
	{
		const UIBarButtonItem *systemItem = [[UIBarButtonItem alloc]
									   initWithBarButtonSystemItem:UIBarButtonSystemItemDone
									   target:self action:@selector(flipView:)];

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
			items = [NSArray arrayWithObjects: systemItem, flexItem, osdItem, videoItem, bothItem, nil];
		else
			items = [NSArray arrayWithObjects: systemItem, flexItem, osdItem, bothItem, nil];
		[_toolbar setItems:items animated:NO];

		[systemItem release];
		[flexItem release];
		[osdItem release];
		[videoItem release];
		[bothItem release];

		self.navigationItem.rightBarButtonItem = _screenshotButton;

		if([_screenView superview])
			[self loadImage: nil];
	}
	else
	{
		self.navigationItem.rightBarButtonItem = nil;

		if([_screenView superview])
			[self flipView: nil];
	}

	[super viewWillAppear: animated];
}

- (void)loadView
{
	// setup our parent content view and embed it to your view controller
	UIView *contentView = [[UIView alloc] initWithFrame:[[UIScreen mainScreen] applicationFrame]];
	contentView.backgroundColor = [UIColor groupTableViewBackgroundColor];	// use the table view background color

	// setup our content view so that it auto-rotates along with the UViewController
	contentView.autoresizesSubviews = YES;
	contentView.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);

	self.view = contentView;
	[contentView release];

	// Flip Button
	_screenshotButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"image-x-generic.png"] style:UIBarButtonItemStylePlain target:self action:@selector(flipView:)];

	CGSize mainViewSize = self.view.bounds.size;
	CGRect frame;

	// ImageView for Screenshots
	frame = CGRectMake(0, 0, mainViewSize.width, mainViewSize.height);
	_screenView = [[UIView alloc] initWithFrame: frame];

	_toolbar = [UIToolbar new];
	_toolbar.barStyle = UIBarStyleDefault;

	// size up the _toolbar and set its frame
	[_toolbar sizeToFit];
	const CGFloat _toolbarHeight = _toolbar.frame.size.height;
	mainViewSize = _screenView.bounds.size;
	_toolbar.frame = CGRectMake(0,
							   mainViewSize.height - (_toolbarHeight * 2) + 2,
							   mainViewSize.width,
							   _toolbarHeight);
	[_screenView addSubview:_toolbar];

	frame = CGRectMake(0,
					   0,
					   mainViewSize.width,
					   mainViewSize.height - (_toolbarHeight * 2) + 2);
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

- (void)flipView:(id)sender
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
		[self.view addSubview: rcView];
	}
	else
	{
		[self loadImage: nil];
		[rcView removeFromSuperview];
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
	[self loadImage: nil];
}

- (void)setVideoType:(id)sender
{
	_screenshotType = kScreenshotTypeVideo;
	[self loadImage: nil];
}

- (void)setBothType:(id)sender
{
	_screenshotType = kScreenshotTypeBoth;
	[self loadImage: nil];
}

- (void)buttonPressed:(RCButton *)sender
{
	// Spawn a thread to send the request so that the UI is not blocked while
	// waiting for the response.
	[NSThread detachNewThreadSelector:@selector(sendButton:)
							toTarget:self
							withObject: [NSNumber numberWithInteger: sender.rcCode]];
}

- (void)sendButton: (NSNumber *)rcCode
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

	if([[RemoteConnectorObject sharedRemoteConnector] sendButton: [rcCode integerValue]]
			&& _shouldVibrate)
		AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);

	[pool release];
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
	_imageView.image = nil;
	_toolbar.frame = CGRectInfinite;

	[super willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
	//[UIView beginAnimations:nil context:NULL];
	//[UIView setAnimationDuration: kTransitionDuration];

	// adjust size of _screenView, _toolbar & _scrollView
	CGSize mainViewSize = self.view.bounds.size;
	_screenView.frame = CGRectMake(0, 0, mainViewSize.width, mainViewSize.height);
	[_toolbar sizeToFit];
	//mainViewSize = _screenView.bounds.size;
	CGFloat _toolbarHeight = _toolbar.frame.size.height;
	CGFloat edgeY = mainViewSize.height - _toolbarHeight;
	CGFloat width = mainViewSize.width;
	_toolbar.frame = CGRectMake(0, edgeY, width, _toolbarHeight);
	_scrollView.frame = CGRectMake(0, 0, width, edgeY);

	// FIXME: we load a new image as I'm currently unable to figure out how to readjust the old one
	if(_screenView.superview)
		[self loadImage: nil];

	//[UIView commitAnimations];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	if([_screenView superview])
		return YES;

	// RC should only be displayed in portrait mode
	return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark UIScrollView delegates

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)_scrollView
{
    return _imageView;
}

@end
