//
//  RCEmulatorController.m
//  Untitled
//
//  Created by Moritz Venn on 23.07.08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <AudioToolbox/AudioServices.h>

#import "RCEmulatorController.h"
#import "RemoteConnectorObject.h"
#import "RCButton.h"
#import "Constants.h"

#define kTransitionDuration	0.6
#define kImageScale			0.45

@interface RCEmulatorController()
- (UIButton*)customButton:(CGRect)frame withImage:(NSString*)imagePath andKeyCode:(int)keyCode;
- (void)loadImage:(id)dummy;
- (void)flipView:(id)sender;
@end

@implementation RCEmulatorController

- (id)init
{
	if (self = [super init])
	{
		self.title = NSLocalizedString(@"Remote Control", @"Title of RCEmulatorController");
		_screenshotType = kScreenshotTypeOSD;
	}

	return self;
}

- (void)dealloc
{
	[toolbar release];
	[rcView release];
	[screenView release];
	[scrollView release];
	[imageView release];
	[screenshotButton release];

	[super dealloc];
}

- (void)viewWillAppear:(BOOL)animated
{
	_shouldVibrate = [[NSUserDefaults standardUserDefaults] boolForKey: kVibratingRC];

	if([[RemoteConnectorObject sharedRemoteConnector] hasFeature: kFeaturesScreenshot])
	{
		UIBarButtonItem *systemItem = [[UIBarButtonItem alloc]
									   initWithBarButtonSystemItem:UIBarButtonSystemItemDone
									   target:self action:@selector(flipView:)];

		// flex item used to separate the left groups items and right grouped items
		UIBarButtonItem *flexItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
																	target:nil
																	action:nil];

		// create a bordered style button with custom title
		UIBarButtonItem *osdItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"OSD", @"")
																	style:UIBarButtonItemStyleBordered
																	target:self
																	action:@selector(setOSDType:)];

		// create a bordered style button with custom title
		UIBarButtonItem *videoItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Video", @"")
																	style:UIBarButtonItemStyleBordered
																	target:self
																	action:@selector(setVideoType:)];

		// create a bordered style button with custom title
		UIBarButtonItem *bothItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"All", @"")
																	style:UIBarButtonItemStyleBordered
																	target:self
																	action:@selector(setBothType:)];
		
		NSArray *items;
		if([[RemoteConnectorObject sharedRemoteConnector] hasFeature: kFeaturesVideoScreenshot])
			items = [NSArray arrayWithObjects: systemItem, flexItem, osdItem, videoItem, bothItem, nil];
		else
			items = [NSArray arrayWithObjects: systemItem, flexItem, osdItem, bothItem, nil];
		[toolbar setItems:items animated:NO];

		[systemItem release];
		[flexItem release];
		[osdItem release];
		[videoItem release];
		[bothItem release];

		self.navigationItem.rightBarButtonItem = screenshotButton;

		if([screenView superview])
			[self loadImage: nil];
	}
	else
	{
		self.navigationItem.rightBarButtonItem = nil;

		if([screenView superview])
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
	screenshotButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"image-x-generic.png"] style:UIBarButtonItemStylePlain target:self action:@selector(flipView:)];

#pragma mark RC View

	// create the container view which we will use for transition animation (centered horizontally)
	rcView = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, self.view.bounds.size.width, self.view.bounds.size.height)];
	[self.view addSubview:rcView];

	UIButton *roundedButtonType;
	CGRect frame;

	CGFloat imageWidth;
	CGFloat imageHeight;
	CGFloat currX;
	CGFloat currY;

	/* Begin Keypad */
	imageWidth = 45;
	imageHeight = 35;
	
	// new row
	currX = kTopMargin;
	currY = 75;

	// 1
	frame = CGRectMake(currY, currX, imageWidth, imageHeight);
	roundedButtonType = [self customButton:frame withImage:@"key_1.png" andKeyCode: kButtonCode1];
	[rcView addSubview: roundedButtonType];
	[roundedButtonType release];
	currY += imageWidth + kTweenMargin;
	
	// 2
	frame = CGRectMake(currY, currX, imageWidth, imageHeight);
	roundedButtonType = [self customButton:frame withImage:@"key_2.png" andKeyCode: kButtonCode2];
	[rcView addSubview: roundedButtonType];
	[roundedButtonType release];
	currY += imageWidth + kTweenMargin;
	
	// 3
	frame = CGRectMake(currY, currX, imageWidth, imageHeight);
	roundedButtonType = [self customButton:frame withImage:@"key_3.png" andKeyCode: kButtonCode3];
	[rcView addSubview: roundedButtonType];
	[roundedButtonType release];
	
	// new row
	currX += imageHeight + kTweenMargin;
	currY = 75;
	
	// 4
	frame = CGRectMake(currY, currX, imageWidth, imageHeight);
	roundedButtonType = [self customButton:frame withImage:@"key_4.png" andKeyCode: kButtonCode4];
	[rcView addSubview: roundedButtonType];
	[roundedButtonType release];
	currY += imageWidth + kTweenMargin;
	
	// 5
	frame = CGRectMake(currY, currX, imageWidth, imageHeight);
	roundedButtonType = [self customButton:frame withImage:@"key_5.png" andKeyCode: kButtonCode5];
	[rcView addSubview: roundedButtonType];
	[roundedButtonType release];
	currY += imageWidth + kTweenMargin;
	
	// 6
	frame = CGRectMake(currY, currX, imageWidth, imageHeight);
	roundedButtonType = [self customButton:frame withImage:@"key_6.png" andKeyCode: kButtonCode6];
	[rcView addSubview: roundedButtonType];
	[roundedButtonType release];
	currY += imageWidth + kTweenMargin;
	
	// new row
	currX += imageHeight + kTweenMargin;
	currY = 75;
	
	// 7
	frame = CGRectMake(currY, currX, imageWidth, imageHeight);
	roundedButtonType = [self customButton:frame withImage:@"key_7.png" andKeyCode: kButtonCode7];
	[rcView addSubview: roundedButtonType];
	[roundedButtonType release];
	currY += imageWidth + kTweenMargin;
	
	// 8
	frame = CGRectMake(currY, currX, imageWidth, imageHeight);
	roundedButtonType = [self customButton:frame withImage:@"key_8.png" andKeyCode: kButtonCode8];
	[rcView addSubview: roundedButtonType];
	[roundedButtonType release];
	currY += imageWidth + kTweenMargin;
	
	// 9
	frame = CGRectMake(currY, currX, imageWidth, imageHeight);
	roundedButtonType = [self customButton:frame withImage:@"key_9.png" andKeyCode: kButtonCode9];
	[rcView addSubview: roundedButtonType];
	[roundedButtonType release];
	currY += imageWidth + kTweenMargin;
	
	// new row
	currX += imageHeight + kTweenMargin;
	currY = 75;
	
	// <
	frame = CGRectMake(currY, currX, imageWidth, imageHeight);
	roundedButtonType = [self customButton:frame withImage:@"key_leftarrow.png" andKeyCode: kButtonCodePrevious];
	[rcView addSubview: roundedButtonType];
	[roundedButtonType release];
	currY += imageWidth + kTweenMargin;
	
	// 0
	frame = CGRectMake(currY, currX, imageWidth, imageHeight);
	roundedButtonType = [self customButton:frame withImage:@"key_0.png" andKeyCode: kButtonCode0];
	[rcView addSubview: roundedButtonType];
	[roundedButtonType release];
	currY += imageWidth + kTweenMargin;
	
	// >
	frame = CGRectMake(currY, currX, imageWidth, imageHeight);
	roundedButtonType = [self customButton:frame withImage:@"key_rightarrow.png" andKeyCode: kButtonCodeNext];
	[rcView addSubview: roundedButtonType];
	[roundedButtonType release];
	currY += imageWidth + kTweenMargin;
	
	/* End Keypad */
	
	/* Begin Navigation pad */
	currX += 2*imageWidth; // currX is used as center here
	currY = 77;
	
	// ok
	frame = CGRectMake(currY+50, currX, imageWidth, imageHeight);
	roundedButtonType = [self customButton:frame withImage:@"key_ok.png" andKeyCode: kButtonCodeOK];
	[rcView addSubview: roundedButtonType];
	[roundedButtonType release];

	// left
	frame = CGRectMake(currY, currX, imageWidth, imageHeight);
	roundedButtonType = [self customButton:frame withImage:@"key_left.png" andKeyCode: kButtonCodeLeft];
	[rcView addSubview: roundedButtonType];
	[roundedButtonType release];
	
	// right
	frame = CGRectMake(currY+100, currX, imageWidth, imageHeight);
	roundedButtonType = [self customButton:frame withImage:@"key_right.png" andKeyCode: kButtonCodeRight];
	[rcView addSubview: roundedButtonType];
	[roundedButtonType release];
	
	// up
	frame = CGRectMake(currY+50, currX-40, imageWidth, imageHeight);
	roundedButtonType = [self customButton:frame withImage:@"key_up.png" andKeyCode: kButtonCodeUp];
	[rcView addSubview: roundedButtonType];
	[roundedButtonType release];
	
	// down
	frame = CGRectMake(currY+50, currX+40, imageWidth, imageHeight);
	roundedButtonType = [self customButton:frame withImage:@"key_down.png" andKeyCode: kButtonCodeDown];
	[rcView addSubview: roundedButtonType];
	[roundedButtonType release];

	/* Additional Buttons Navigation pad */
	// info
	frame = CGRectMake(currY, currX-40, imageWidth, imageHeight);
	roundedButtonType = [self customButton:frame withImage:@"key_info.png" andKeyCode: kButtonCodeInfo];
	[rcView addSubview: roundedButtonType];
	[roundedButtonType release];
	
	// audio
	frame = CGRectMake(currY, currX+40, imageWidth, imageHeight);
	roundedButtonType = [self customButton:frame withImage:@"key_audio.png" andKeyCode: kButtonCodeAudio];
	[rcView addSubview: roundedButtonType];
	[roundedButtonType release];
	
	// menu
	frame = CGRectMake(currY+100, currX-40, imageWidth, imageHeight);
	roundedButtonType = [self customButton:frame withImage:@"key_menu.png" andKeyCode: kButtonCodeMenu];
	[rcView addSubview: roundedButtonType];
	[roundedButtonType release];
	
	// video
	frame = CGRectMake(currY+100, currX+40, imageWidth, imageHeight);
	roundedButtonType = [self customButton:frame withImage:@"key_video.png" andKeyCode: kButtonCodeVideo];
	[rcView addSubview: roundedButtonType];
	[roundedButtonType release];

	/* End Navigation pad */

	/* Lower pad */#
	currX += 2*(imageHeight+kTweenMargin);
	currY = 50;

	// red
	frame = CGRectMake(currY, currX, imageWidth, imageHeight);
	roundedButtonType = [self customButton:frame withImage:@"key_red.png" andKeyCode: kButtonCodeRed];
	[rcView addSubview: roundedButtonType];
	[roundedButtonType release];
	currY += imageWidth + kTweenMargin;
	
	// green
	frame = CGRectMake(currY, currX, imageWidth, imageHeight);
	roundedButtonType = [self customButton:frame withImage:@"key_green.png" andKeyCode: kButtonCodeGreen];
	[rcView addSubview: roundedButtonType];
	[roundedButtonType release];
	currY += imageWidth + kTweenMargin;
	
	// yellow
	frame = CGRectMake(currY, currX, imageWidth, imageHeight);
	roundedButtonType = [self customButton:frame withImage:@"key_yellow.png" andKeyCode: kButtonCodeYellow];
	[rcView addSubview: roundedButtonType];
	[roundedButtonType release];
	currY += imageWidth + kTweenMargin;
	
	// blue
	frame = CGRectMake(currY, currX, imageWidth, imageHeight);
	roundedButtonType = [self customButton:frame withImage:@"key_blue.png" andKeyCode: kButtonCodeBlue];
	[rcView addSubview: roundedButtonType];
	[roundedButtonType release];

	// next row
	currX += imageHeight + kTweenMargin;
	currY = 50;

	// tv
	frame = CGRectMake(currY, currX, imageWidth, imageHeight);
	roundedButtonType = [self customButton:frame withImage:@"key_tv.png" andKeyCode: kButtonCodeTV];
	[rcView addSubview: roundedButtonType];
	[roundedButtonType release];
	currY += imageWidth + kTweenMargin;
	
	// radio
	frame = CGRectMake(currY, currX, imageWidth, imageHeight);
	roundedButtonType = [self customButton:frame withImage:@"key_radio.png" andKeyCode: kButtonCodeRadio];
	[rcView addSubview: roundedButtonType];
	[roundedButtonType release];
	currY += imageWidth + kTweenMargin;
	
	// text
	frame = CGRectMake(currY, currX, imageWidth, imageHeight);
	roundedButtonType = [self customButton:frame withImage:@"key_text.png" andKeyCode: kButtonCodeText];
	[rcView addSubview: roundedButtonType];
	[roundedButtonType release];
	currY += imageWidth + kTweenMargin;
	
	// help
	frame = CGRectMake(currY, currX, imageWidth, imageHeight);
	roundedButtonType = [self customButton:frame withImage:@"key_help.png" andKeyCode: kButtonCodeHelp];
	[rcView addSubview: roundedButtonType];
	[roundedButtonType release];

	/* End lower pad */
	
	/* Volume pad */
	currX = kTopMargin+25;
	currY = kLeftMargin+5;
	
	// up
	frame = CGRectMake(currY, currX, imageWidth, imageHeight);
	roundedButtonType = [self customButton:frame withImage:@"key_plus.png" andKeyCode: kButtonCodeVolUp];
	[rcView addSubview: roundedButtonType];
	[roundedButtonType release];
	currX += imageHeight + kTweenMargin;

	// down
	frame = CGRectMake(currY, currX, imageWidth, imageHeight);
	roundedButtonType = [self customButton:frame withImage:@"key_minus.png" andKeyCode: kButtonCodeVolDown];
	[rcView addSubview: roundedButtonType];
	[roundedButtonType release];
	
	/* End Volume pad */

	/* Bouquet pad */
	currX = kTopMargin+25;
	currY = 255;
	
	// up
	frame = CGRectMake(currY, currX, imageWidth, imageHeight);
	roundedButtonType = [self customButton:frame withImage:@"key_plus.png" andKeyCode: kButtonCodeBouquetUp];
	[rcView addSubview: roundedButtonType];
	[roundedButtonType release];
	currX += imageHeight + kTweenMargin;

	// down
	frame = CGRectMake(currY, currX, imageWidth, imageHeight);
	roundedButtonType = [self customButton:frame withImage:@"key_minus.png" andKeyCode: kButtonCodeBouquetDown];
	[rcView addSubview: roundedButtonType];
	[roundedButtonType release];

	/* End Bouquet pad */

	// mute
	currX = 140;
	currY = kLeftMargin+5;
	frame = CGRectMake(currY, currX, imageWidth, imageHeight);
	roundedButtonType = [self customButton:frame withImage:@"key_mute.png" andKeyCode: kButtonCodeMute];
	[rcView addSubview: roundedButtonType];
	[roundedButtonType release];
	
	// lame
	currX = 140;
	currY = 255;
	frame = CGRectMake(currY, currX, imageWidth, imageHeight);
	roundedButtonType = [self customButton:frame withImage:@"key_exit.png" andKeyCode: kButtonCodeLame];
	[rcView addSubview: roundedButtonType];
	[roundedButtonType release];

#pragma mark Screenshot View

	// ImageView for Screenshots
	frame = CGRectMake(0.0, 0.0, self.view.bounds.size.width, self.view.bounds.size.height);
	screenView = [[UIView alloc] initWithFrame: frame];

	toolbar = [UIToolbar new];
	toolbar.barStyle = UIBarStyleDefault;

	// size up the toolbar and set its frame
	[toolbar sizeToFit];
	CGFloat toolbarHeight = toolbar.frame.size.height;
	CGSize mainViewSize = screenView.bounds.size;
	toolbar.frame = CGRectMake(0.0,
							   mainViewSize.height - (toolbarHeight * 2.0) + 2.0,
							   mainViewSize.width,
							   toolbarHeight);
	[screenView addSubview:toolbar];

	frame = CGRectMake(0.0,
					   0.0,
					   mainViewSize.width,
					   mainViewSize.height - (toolbarHeight * 2.0) + 2.0);
	scrollView = [[UIScrollView alloc] initWithFrame: frame];
	scrollView.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
	scrollView.autoresizesSubviews = YES;
	screenView.clipsToBounds = NO;
	scrollView.contentMode = (UIViewContentModeScaleAspectFit);
	scrollView.delegate = self;
	scrollView.maximumZoomScale = 2.6;
	scrollView.minimumZoomScale = 1.0;
	scrollView.exclusiveTouch = NO;
	[screenView addSubview: scrollView];
	imageView = [[UIImageView alloc] initWithFrame: CGRectZero];
	imageView.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
	imageView.autoresizesSubviews = YES;
	imageView.contentMode = UIViewContentModeScaleAspectFit;
	[scrollView addSubview: imageView];
}

- (UIButton*)customButton:(CGRect)frame withImage:(NSString*)imagePath andKeyCode:(int)keyCode
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
	if ([screenView superview])
	{
		[screenView removeFromSuperview];
		[self.view addSubview: rcView];
	}
	else
	{
		[self loadImage: nil];
		[rcView removeFromSuperview];
		[self.view addSubview: screenView];
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

		imageView.image = image;
		scrollView.contentSize = size;
		imageView.frame = CGRectMake(0.0, 0.0, size.width, size.height);
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
	imageView.image = nil;
	toolbar.frame = CGRectInfinite;

	[super willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
	//[UIView beginAnimations:nil context:NULL];
	//[UIView setAnimationDuration: kTransitionDuration];

	// adjust size of screenView, toolbar & scrollView
	CGSize mainViewSize = self.view.bounds.size;
	screenView.frame = CGRectMake(0.0, 0.0, mainViewSize.width, mainViewSize.height);
	[toolbar sizeToFit];
	//mainViewSize = screenView.bounds.size;
	CGFloat toolbarHeight = toolbar.frame.size.height;
	CGFloat edgeY = mainViewSize.height - toolbarHeight;
	CGFloat width = mainViewSize.width;
	toolbar.frame = CGRectMake(0.0, edgeY, width, toolbarHeight);
	scrollView.frame = CGRectMake(0.0, 0.0, width, edgeY);

	// XXX: we load a new image as I'm currently unable to figure out how to readjust the old one
	if(screenView.superview)
		[self loadImage: nil];

	//[UIView commitAnimations];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	if([screenView superview])
		return YES;

	// RC should only be displayed in portrait mode
	return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark UIScrollView delegates

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView
{
    return imageView;
}

@end
