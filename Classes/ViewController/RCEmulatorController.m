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

#import "UIDevice+SystemVersion.h"

#define kTransitionDuration	(CGFloat)0.6
#define kImageScaleHuge		((IS_IPAD()) ? (CGFloat)0.8 : (CGFloat)0.25)
#define kImageScale			((IS_IPAD()) ? (CGFloat)1.1 : (CGFloat)0.45)

@interface RCEmulatorController()
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
 @brief toggle standby
 @param sender ui element
 */
- (void)toggleStandby:(id)sender;

/*!
 @brief Change frames/views according to orientation
 */
- (void)manageViews:(UIInterfaceOrientation)interfaceOrientation;

/*!
 @brief Ask user if he wants to save current screenshot?
 */
- (void)maybeSavePicture:(UILongPressGestureRecognizer *)gesture;
@end

@implementation RCEmulatorController

@synthesize rcView, toolbar;

- (id)init
{
	if((self = [super init]))
	{
		self.title = NSLocalizedString(@"Remote Control", @"Title of RCEmulatorController");
		_screenshotType = kScreenshotTypeBoth;
	}

	return self;
}

- (void)dealloc
{
	[self stopObservingThemeChanges];
	[_queue cancelAllOperations];
}

- (void)configureToolbar:(BOOL)animated
{
	// flex item used to separate the left groups items and centered items
	const UIBarButtonItem *flexItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
																					target:nil
																					action:nil];

	// create a bordered style button with custom title
	const UIBarButtonItem *standbyItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Standby", @"")
																		  style:UIBarButtonItemStyleBordered
																		 target:self
																		 action:@selector(toggleStandby:)];

	NSMutableArray *items = [NSMutableArray array];

	if([[RemoteConnectorObject sharedRemoteConnector] hasFeature: kFeaturesScreenshot])
	{
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

		if(IS_IPHONE())
		{
			if([_screenView superview])
			{
				[items addObject:_screenshotButton];
				[items addObject:flexItem];
				[items addObject:osdItem];
				if([[RemoteConnectorObject sharedRemoteConnector] hasFeature: kFeaturesVideoScreenshot])
					[items addObject:videoItem];
				if([[RemoteConnectorObject sharedRemoteConnector] hasFeature: kFeaturesCombinedScreenshot])
					[items addObject:bothItem];
			}
			else
			{
				[items addObject:_screenshotButton];
				[items addObject:flexItem];
				[items addObject:standbyItem];
			}
		}
		else
		{
			[items addObject:_screenshotButton];
			[items addObject:flexItem];
			[items addObject:standbyItem];
			[items addObject:flexItem];
			[items addObject:osdItem];
			if([[RemoteConnectorObject sharedRemoteConnector] hasFeature: kFeaturesVideoScreenshot])
				[items addObject:videoItem];
			if([[RemoteConnectorObject sharedRemoteConnector] hasFeature: kFeaturesCombinedScreenshot])
				[items addObject:bothItem];
		}

	}
	else
	{
		[items addObject:flexItem];
		[items addObject:standbyItem];
		[items addObject:flexItem];
	}

	[toolbar setItems:items animated:animated];
}

- (void)viewWillAppear:(BOOL)animated
{
	_shouldVibrate = [[NSUserDefaults standardUserDefaults] boolForKey: kVibratingRC];

	[self configureToolbar:NO];

	if([_screenView superview])
	{
		if([[RemoteConnectorObject sharedRemoteConnector] hasFeature: kFeaturesScreenshot])
			[self loadImage: nil];
		else
			[self flipView: nil];
	}

	// eventually fix toolbar size
	[toolbar sizeToFit];
	const CGFloat toolbarHeight = toolbar.frame.size.height;
	const CGFloat width = self.view.frame.size.width;
	toolbar.frame = CGRectMake(0, -1, width, toolbarHeight);
	// XXX: hackish
	[self didRotateFromInterfaceOrientation:self.interfaceOrientation];

	// fix up views
	if(_navigationPad != nil)
		[self manageViews:self.interfaceOrientation];

	[super viewWillAppear: animated];
}

- (void)loadView
{
	UIView *backView = [[UIView alloc] initWithFrame:[[UIScreen mainScreen] applicationFrame]];
	backView.autoresizesSubviews = YES;
	backView.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
	contentView = [[UIView alloc] initWithFrame:backView.frame];
	contentView.autoresizesSubviews = YES;
	contentView.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);

	[backView addSubview:contentView];
	self.view = backView;

	// Flip Button
	_screenshotButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Screenshot", @"")
														style:UIBarButtonItemStyleBordered
														target:self
														action:@selector(flipView:)];

	CGSize mainViewSize = self.view.bounds.size;
	CGRect frame;

	toolbar = [UIToolbar new];
	toolbar.barStyle = UIBarStyleDefault;

	// size up the toolbar and set its frame
	[toolbar sizeToFit];
	const CGFloat toolbarOrigin = -1;
	const CGFloat toolbarHeight = toolbar.frame.size.height;
	toolbar.frame = CGRectMake(0,
								toolbarOrigin,
								mainViewSize.width,
								toolbarHeight);
	[self.view addSubview:toolbar];

	// ImageView for Screenshots
	frame = CGRectMake(0, toolbarOrigin + toolbarHeight, mainViewSize.width, mainViewSize.height - (toolbarOrigin + toolbarHeight) - self.tabBarController.tabBar.frame.size.height - self.navigationController.navigationBar.frame.size.height);
	_screenView = [[UIView alloc] initWithFrame: frame];

	frame.origin.y = 0;
	_scrollView = [[ZoomingScrollView alloc] initWithFrame: frame];
	_scrollView.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
	_scrollView.autoresizesSubviews = YES;
	_screenView.clipsToBounds = NO;
	_scrollView.contentMode = (UIViewContentModeScaleAspectFit);
	_scrollView.delegate = self;
	_scrollView.maximumZoomScale = (CGFloat)2.6;
	_scrollView.minimumZoomScale = (CGFloat)1.0;
	_scrollView.exclusiveTouch = NO;

	UILongPressGestureRecognizer *longPressGesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(maybeSavePicture:)];
	longPressGesture.minimumPressDuration = 1;
	[_scrollView addGestureRecognizer:longPressGesture];

	[_screenView addSubview: _scrollView];
	_imageView = [[UIImageView alloc] initWithFrame: CGRectZero];
	_imageView.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
	_imageView.autoresizesSubviews = YES;
	_imageView.contentMode = UIViewContentModeScaleAspectFit;
	[_scrollView addSubview: _imageView];

	// not really view-related, but as we only need this when visible...
	_queue = [[NSOperationQueue alloc] init];
}

- (void)viewDidLoad
{
	[self startObservingThemeChanges];
	[super viewDidLoad];
}

- (void)viewDidUnload
{
	[self stopObservingThemeChanges];
	toolbar = nil;
	rcView = nil;

	contentView = nil;
	_screenView = nil;
	_scrollView = nil;
	_imageView = nil;
	_screenshotButton = nil;

	_keyPad = nil;
	_navigationPad = nil;

	[_queue cancelAllOperations];
	_queue = nil;

	[super viewDidUnload];
}

- (void)theme
{
	contentView.backgroundColor = [DreamoteConfiguration singleton].groupedTableViewBackgroundColor;
	self.view.backgroundColor = contentView.backgroundColor;

	[super theme];
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
				forView:contentView
				cache:YES];

	if ([_screenView superview])
	{
		[_screenView removeFromSuperview];
		_screenshotButton.title = NSLocalizedString(@"Screenshot", @"");
		[contentView addSubview: rcView];
	}
	else
	{
		[self loadImage: nil];
		[rcView removeFromSuperview];
		_screenshotButton.title = NSLocalizedString(@"Done", @"");
		[contentView addSubview:_screenView];
	}

	[UIView commitAnimations];
	[self configureToolbar:NO];
}

- (void)loadImage:(id)dummy
{
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
		NSData *data = [[RemoteConnectorObject sharedRemoteConnector] getScreenshot:_screenshotType];
		UIImage * image = [UIImage imageWithData: data];
		if(image != nil)
		{
			CGFloat scale = image.size.width > 720 ? kImageScaleHuge : kImageScale;
			const CGFloat scaledWidth = image.size.width*scale;
			const CGFloat scaledHeight = image.size.height*scale;
			[_imageView performSelectorOnMainThread:@selector(setImage:) withObject:image waitUntilDone:NO];
			_scrollView.contentSize = CGSizeMake(scaledWidth, scaledHeight);
			_scrollView.zoomScale = 1.0f;
			_imageView.frame = CGRectMake(0, 0, scaledWidth, scaledHeight);
		}
	});
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
	NSInvocationOperation *operation = [[NSInvocationOperation alloc] initWithTarget:self
																			selector:@selector(sendButton:)
																			  object:[NSNumber numberWithInteger: sender.rcCode]];
	[_queue addOperation:operation];
}

- (IBAction)buttonPressedIB:(UIButton *)sender
{
	NSInvocationOperation *operation = [[NSInvocationOperation alloc] initWithTarget:self
																			selector:@selector(sendButton:)
																			  object:[NSNumber numberWithInteger: sender.tag]];
	[_queue addOperation:operation];
}

- (void)toggleStandby:(id)sender
{
	[[RemoteConnectorObject sharedRemoteConnector] standby];
}

- (void)sendButtonInternal: (NSInteger)rcCode
{
	if([[RemoteConnectorObject sharedRemoteConnector] sendButton: rcCode]
	   && _shouldVibrate)
		AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
}

- (void)sendButton: (NSNumber *)rcCode
{
	[self sendButtonInternal: [rcCode integerValue]];
}

- (void)maybeSavePicture:(UILongPressGestureRecognizer *)gesture
{
	if(gesture.state == UIGestureRecognizerStateBegan)
	{
		const UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:
											NSLocalizedString(@"Do you want to save this picture?", @"Shown when touching screenshots for 1s, asks to save to libary")
																	   delegate: self
															  cancelButtonTitle:NSLocalizedString(@"Cancel", "")
														 destructiveButtonTitle:nil
															  otherButtonTitles:NSLocalizedString(@"Save", @""), nil];
		actionSheet.actionSheetStyle = UIActionSheetStyleDefault;
		if(self.tabBarController == nil)
			[actionSheet showInView:self.view];
		else
			[actionSheet showFromTabBar:self.tabBarController.tabBar];
	}
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
    [toolbar performSelector:@selector(sizeToFit)
                         withObject:nil
                         afterDelay:(0.5f * duration)];

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
	// adjust size of _screenView & _scrollView
	CGRect frame = toolbar.frame;
	frame.origin.y += frame.size.height;
	frame.size.height = self.view.frame.size.height - frame.origin.y;
	contentView.frame = self.view.frame;
	_screenView.frame = frame;
	frame.origin.y = 0;
	_scrollView.frame = frame;

	// FIXME: we load a new image as I'm currently unable to figure out how to readjust the old one
	if(_screenView.superview)
		[self loadImage: nil];
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

#pragma mark -
#pragma mark UIActionSheetDelegate methods
#pragma mark -

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
	if(buttonIndex == actionSheet.cancelButtonIndex)
	{
		// do nothing
	}
	else // other
	{
		UIImageWriteToSavedPhotosAlbum(_imageView.image, nil, nil, nil);
	}
}

#pragma mark UIScrollView delegates

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)_scrollView
{
    return _imageView;
}

@end
