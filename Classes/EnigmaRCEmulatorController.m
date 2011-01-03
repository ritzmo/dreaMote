//
//  EnigmaRCEmulatorController.m
//  dreaMote
//
//  Created by Moritz Venn on 23.07.08.
//  Copyright 2008-2011 Moritz Venn. All rights reserved.
//

#import "EnigmaRCEmulatorController.h"
#import "RemoteConnector.h"
#import "RemoteConnectorObject.h"
#import "Constants.h"

@interface EnigmaRCEmulatorController()
/*!
 @brief Change frames/views according to orientation
 */
- (void)manageViews:(UIInterfaceOrientation)interfaceOrientation;
@end

@implementation EnigmaRCEmulatorController

#if 0
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
	if((self = [super initWithNibName: @"EnigmaRCEmulator" bundle: nil]))
	{
		//
	}
	return self;
}

- (void)viewDidLoad
{
	[self.view addSubview: self.rcView];
}
#endif

- (void)dealloc
{
	[_keyPad release];
	[_navigationPad release];

	[super dealloc];
}

- (void)loadView
{
	const CGFloat factor = (IS_IPAD()) ? 2.38f : 1.0f;
	const CGFloat imageWidth = 45;
	const CGFloat imageHeight = 35;
	const BOOL usesAdvancedRemote = [RemoteConnectorObject usesAdvancedRemote];
	CGFloat currX, localX;
	CGFloat currY, localY;
	UIButton *roundedButtonType;
	CGRect frame;

	[super loadView];

	const CGSize mainViewSize = self.view.bounds.size;

	// create the rc views (i think its easier to have two views than to keep track of all buttons and add/remove them as pleased)
	_portraitFrame = CGRectMake(0, 0, mainViewSize.width, mainViewSize.height);
	if(IS_IPAD())
		_landscapeFrame = CGRectMake(140, 95, mainViewSize.width - 140, mainViewSize.height - 95);
	else
		_landscapeFrame = CGRectMake(75, 30, mainViewSize.width - 75, mainViewSize.height - 30);
	rcView = [[UIView alloc] initWithFrame: _portraitFrame];
	[self.view addSubview:rcView];

	// initialize this
	currX = kTopMargin;
	currY = 74;

	/* Begin Keypad */
	// intialize view
	frame = CGRectMake(currY * factor, currX * factor, 165 * factor, 135 * factor);
	_keyPad = [[UIView alloc] initWithFrame: frame];
	// new row
	localX = 0;
	localY = 0;

	// 1
	frame = CGRectMake(localY * factor, localX * factor, imageWidth * factor, imageHeight * factor);
	roundedButtonType = [self newButton:frame withImage:@"key_1.png" andKeyCode: kButtonCode1];
	[_keyPad addSubview: roundedButtonType];
	[roundedButtonType release];
	localY += imageWidth + kTweenMargin;

	// 2
	frame = CGRectMake(localY * factor, localX * factor, imageWidth * factor, imageHeight * factor);
	roundedButtonType = [self newButton:frame withImage:@"key_2.png" andKeyCode: kButtonCode2];
	[_keyPad addSubview: roundedButtonType];
	[roundedButtonType release];
	localY += imageWidth + kTweenMargin;

	// 3
	frame = CGRectMake(localY * factor, localX * factor, imageWidth * factor, imageHeight * factor);
	roundedButtonType = [self newButton:frame withImage:@"key_3.png" andKeyCode: kButtonCode3];
	[_keyPad addSubview: roundedButtonType];
	[roundedButtonType release];

	// new row
	localX += imageHeight + kTweenMargin;
	localY = 0;

	// 4
	frame = CGRectMake(localY * factor, localX * factor, imageWidth * factor, imageHeight * factor);
	roundedButtonType = [self newButton:frame withImage:@"key_4.png" andKeyCode: kButtonCode4];
	[_keyPad addSubview: roundedButtonType];
	[roundedButtonType release];
	localY += imageWidth + kTweenMargin;

	// 5
	frame = CGRectMake(localY * factor, localX * factor, imageWidth * factor, imageHeight * factor);
	roundedButtonType = [self newButton:frame withImage:@"key_5.png" andKeyCode: kButtonCode5];
	[_keyPad addSubview: roundedButtonType];
	[roundedButtonType release];
	localY += imageWidth + kTweenMargin;

	// 6
	frame = CGRectMake(localY * factor, localX * factor, imageWidth * factor, imageHeight * factor);
	roundedButtonType = [self newButton:frame withImage:@"key_6.png" andKeyCode: kButtonCode6];
	[_keyPad addSubview: roundedButtonType];
	[roundedButtonType release];
	//localY += imageWidth + kTweenMargin;

	// new row
	localX += imageHeight + kTweenMargin;
	localY = 0;

	// 7
	frame = CGRectMake(localY * factor, localX * factor, imageWidth * factor, imageHeight * factor);
	roundedButtonType = [self newButton:frame withImage:@"key_7.png" andKeyCode: kButtonCode7];
	[_keyPad addSubview: roundedButtonType];
	[roundedButtonType release];
	localY += imageWidth + kTweenMargin;

	// 8
	frame = CGRectMake(localY * factor, localX * factor, imageWidth * factor, imageHeight * factor);
	roundedButtonType = [self newButton:frame withImage:@"key_8.png" andKeyCode: kButtonCode8];
	[_keyPad addSubview: roundedButtonType];
	[roundedButtonType release];
	localY += imageWidth + kTweenMargin;

	// 9
	frame = CGRectMake(localY * factor, localX * factor, imageWidth * factor, imageHeight * factor);
	roundedButtonType = [self newButton:frame withImage:@"key_9.png" andKeyCode: kButtonCode9];
	[_keyPad addSubview: roundedButtonType];
	[roundedButtonType release];
	//localY += imageWidth + kTweenMargin;

	// new row
	localX += imageHeight + kTweenMargin;
	localY = 0;

	// <
	frame = CGRectMake(localY * factor, localX * factor, imageWidth * factor, imageHeight * factor);
	roundedButtonType = [self newButton:frame withImage:@"key_leftarrow.png" andKeyCode: kButtonCodePrevious];
	[_keyPad addSubview: roundedButtonType];
	[roundedButtonType release];
	localY += imageWidth + kTweenMargin;

	// 0
	frame = CGRectMake(localY * factor, localX * factor, imageWidth * factor, imageHeight * factor);
	roundedButtonType = [self newButton:frame withImage:@"key_0.png" andKeyCode: kButtonCode0];
	[_keyPad addSubview: roundedButtonType];
	[roundedButtonType release];
	localY += imageWidth + kTweenMargin;

	// >
	frame = CGRectMake(localY * factor, localX * factor, imageWidth * factor, imageHeight * factor);
	roundedButtonType = [self newButton:frame withImage:@"key_rightarrow.png" andKeyCode: kButtonCodeNext];
	[_keyPad addSubview: roundedButtonType];
	[roundedButtonType release];
	//localY += imageWidth + kTweenMargin;

	[rcView addSubview: _keyPad];
	/* End Keypad */

	// add offset generated by key pad
	currX += localX;
	currY = 77;

	/* Begin Navigation pad */
	currX += 2*imageWidth; // currX is used as center here
	//initialize view
	_landscapeNavigationFrame = CGRectMake(80 * factor, 35 * factor, 80 * factor, 100 * factor);
	_portraitNavigationFrame = CGRectMake(77 * factor, (currX - 40) * factor, 80 * factor, 100 * factor);
	_navigationPad = [[UIView alloc] initWithFrame:_portraitNavigationFrame];
	// internal offset
	localX = 40;
	localY = 0;

	// ok
	frame = CGRectMake((localY+50) * factor, localX * factor, imageWidth * factor, imageHeight * factor);
	roundedButtonType = [self newButton:frame withImage:@"key_ok.png" andKeyCode: kButtonCodeOK];
	[_navigationPad addSubview: roundedButtonType];
	[roundedButtonType release];

	// left
	frame = CGRectMake(localY * factor, localX * factor, imageWidth * factor, imageHeight * factor);
	roundedButtonType = [self newButton:frame withImage:@"key_left.png" andKeyCode: kButtonCodeLeft];
	[_navigationPad addSubview: roundedButtonType];
	[roundedButtonType release];

	// right
	frame = CGRectMake((localY+100) * factor, localX * factor, imageWidth * factor, imageHeight * factor);
	roundedButtonType = [self newButton:frame withImage:@"key_right.png" andKeyCode: kButtonCodeRight];
	[_navigationPad addSubview: roundedButtonType];
	[roundedButtonType release];

	// up
	frame = CGRectMake((localY+50) * factor, (localX-40) * factor, imageWidth * factor, imageHeight * factor);
	roundedButtonType = [self newButton:frame withImage:@"key_up.png" andKeyCode: kButtonCodeUp];
	[_navigationPad addSubview: roundedButtonType];
	[roundedButtonType release];

	// down
	frame = CGRectMake((localY+50) * factor, (localX+40) * factor, imageWidth * factor, imageHeight * factor);
	roundedButtonType = [self newButton:frame withImage:@"key_down.png" andKeyCode: kButtonCodeDown];
	[_navigationPad addSubview: roundedButtonType];
	[roundedButtonType release];

	/* Additional Buttons Navigation pad */
	// info
	frame = CGRectMake(localY * factor, (localX-40) * factor, imageWidth * factor, imageHeight * factor);
	roundedButtonType = [self newButton:frame withImage:@"key_info.png" andKeyCode: kButtonCodeInfo];
	[_navigationPad addSubview: roundedButtonType];
	[roundedButtonType release];

	frame = CGRectMake(localY * factor, (localX+40) * factor, imageWidth * factor, imageHeight * factor);
	// help
	if(usesAdvancedRemote)
	{
		roundedButtonType = [self newButton:frame withImage:@"key_help_round.png" andKeyCode: kButtonCodeHelp];
	}
	// audio
	else
	{
		roundedButtonType = [self newButton:frame withImage:@"key_audio.png" andKeyCode: kButtonCodeAudio];
	}
	[_navigationPad addSubview: roundedButtonType];
	[roundedButtonType release];

	// menu
	frame = CGRectMake((localY+100) * factor, (localX-40) * factor, imageWidth * factor, imageHeight * factor);
	roundedButtonType = [self newButton:frame withImage:@"key_menu.png" andKeyCode: kButtonCodeMenu];
	[_navigationPad addSubview: roundedButtonType];
	[roundedButtonType release];

	frame = CGRectMake((localY+100) * factor, (localX+40) * factor, imageWidth * factor, imageHeight * factor);
	// PVR
	if(usesAdvancedRemote)
	{
		roundedButtonType = [self newButton:frame withImage:@"key_pvr.png" andKeyCode: kButtonCodePVR];
	}
	// video
	else
	{
		roundedButtonType = [self newButton:frame withImage:@"key_video.png" andKeyCode: kButtonCodeVideo];
	}
	[_navigationPad addSubview: roundedButtonType];
	[roundedButtonType release];

	[rcView addSubview: _navigationPad];
	/* End Navigation pad */

	/* Lower pad */
	currX += 2*(imageHeight+kTweenMargin);
	currY = 50;

	// red
	frame = CGRectMake(currY * factor, currX * factor, imageWidth * factor, imageHeight * factor);
	roundedButtonType = [self newButton:frame withImage:@"key_red.png" andKeyCode: kButtonCodeRed];
	[rcView addSubview: roundedButtonType];
	[roundedButtonType release];
	currY += imageWidth + kTweenMargin;
	
	// green
	frame = CGRectMake(currY * factor, currX * factor, imageWidth * factor, imageHeight * factor);
	roundedButtonType = [self newButton:frame withImage:@"key_green.png" andKeyCode: kButtonCodeGreen];
	[rcView addSubview: roundedButtonType];
	[roundedButtonType release];
	currY += imageWidth + kTweenMargin;
	
	// yellow
	frame = CGRectMake(currY * factor, currX * factor, imageWidth * factor, imageHeight * factor);
	roundedButtonType = [self newButton:frame withImage:@"key_yellow.png" andKeyCode: kButtonCodeYellow];
	[rcView addSubview: roundedButtonType];
	[roundedButtonType release];
	currY += imageWidth + kTweenMargin;
	
	// blue
	frame = CGRectMake(currY * factor, currX * factor, imageWidth * factor, imageHeight * factor);
	roundedButtonType = [self newButton:frame withImage:@"key_blue.png" andKeyCode: kButtonCodeBlue];
	[rcView addSubview: roundedButtonType];
	[roundedButtonType release];

	// next row
	currX += imageHeight + kTweenMargin;
	currY = 50;

	// tv
	frame = CGRectMake(currY * factor, currX * factor, imageWidth * factor, imageHeight * factor);
	roundedButtonType = [self newButton:frame withImage:@"key_tv.png" andKeyCode: kButtonCodeTV];
	[rcView addSubview: roundedButtonType];
	[roundedButtonType release];
	currY += imageWidth + kTweenMargin;
	
	// radio
	frame = CGRectMake(currY * factor, currX * factor, imageWidth * factor, imageHeight * factor);
	roundedButtonType = [self newButton:frame withImage:@"key_radio.png" andKeyCode: kButtonCodeRadio];
	[rcView addSubview: roundedButtonType];
	[roundedButtonType release];
	currY += imageWidth + kTweenMargin;
	
	// text
	frame = CGRectMake(currY * factor, currX * factor, imageWidth * factor, imageHeight * factor);
	roundedButtonType = [self newButton:frame withImage:@"key_text.png" andKeyCode: kButtonCodeText];
	[rcView addSubview: roundedButtonType];
	[roundedButtonType release];
	currY += imageWidth + kTweenMargin;

	frame = CGRectMake(currY * factor, currX * factor, imageWidth * factor, imageHeight * factor);
	// record
	if(usesAdvancedRemote)
	{
		roundedButtonType = [self newButton:frame withImage:@"key_rec.png" andKeyCode: kButtonCodeRecord];
	}
	// help
	else
	{
		roundedButtonType = [self newButton:frame withImage:@"key_help.png" andKeyCode: kButtonCodeHelp];
	}
	[rcView addSubview: roundedButtonType];
	[roundedButtonType release];

	/* End lower pad */
	
	/* Volume pad */
	currX = kTopMargin+25;
	currY = kLeftMargin+5;
	
	// up
	frame = CGRectMake(currY * factor, currX * factor, imageWidth * factor, imageHeight * factor);
	roundedButtonType = [self newButton:frame withImage:@"key_plus.png" andKeyCode: kButtonCodeVolUp];
	[rcView addSubview: roundedButtonType];
	[roundedButtonType release];
	currX += imageHeight + kTweenMargin;

	// down
	frame = CGRectMake(currY * factor, currX * factor, imageWidth * factor, imageHeight * factor);
	roundedButtonType = [self newButton:frame withImage:@"key_minus.png" andKeyCode: kButtonCodeVolDown];
	[rcView addSubview: roundedButtonType];
	[roundedButtonType release];
	
	/* End Volume pad */

	/* Bouquet pad */
	currX = kTopMargin+25;
	currY = 255;
	
	// up
	frame = CGRectMake(currY * factor, currX * factor, imageWidth * factor, imageHeight * factor);
	roundedButtonType = [self newButton:frame withImage:@"key_plus.png" andKeyCode: kButtonCodeBouquetUp];
	[rcView addSubview: roundedButtonType];
	[roundedButtonType release];
	currX += imageHeight + kTweenMargin;

	// down
	frame = CGRectMake(currY * factor, currX * factor, imageWidth * factor, imageHeight * factor);
	roundedButtonType = [self newButton:frame withImage:@"key_minus.png" andKeyCode: kButtonCodeBouquetDown];
	[rcView addSubview: roundedButtonType];
	[roundedButtonType release];

	/* End Bouquet pad */

	// mute
	currX = 140;
	currY = kLeftMargin+5;
	frame = CGRectMake(currY * factor, currX * factor, imageWidth * factor, imageHeight * factor);
	roundedButtonType = [self newButton:frame withImage:@"key_mute.png" andKeyCode: kButtonCodeMute];
	[rcView addSubview: roundedButtonType];
	[roundedButtonType release];
	
	// lame
	currX = 140;
	currY = 255;
	frame = CGRectMake(currY * factor, currX * factor, imageWidth * factor, imageHeight * factor);
	roundedButtonType = [self newButton:frame withImage:@"key_exit.png" andKeyCode: kButtonCodeLame];
	[rcView addSubview: roundedButtonType];
	[roundedButtonType release];
	
	if(usesAdvancedRemote)
	{
		// play/pause
		currX = 210;
		currY = kLeftMargin + 5;
		frame = CGRectMake(currY * factor, currX * factor, imageWidth * factor, imageHeight * factor);
		roundedButtonType = [self newButton:frame withImage:@"key_pp.png" andKeyCode: kButtonCodePlayPause];
		[rcView addSubview: roundedButtonType];
		[roundedButtonType release];

		// stop
		currX += imageHeight + kTweenMargin;
		frame = CGRectMake(currY * factor, currX * factor, imageWidth * factor, imageHeight * factor);
		roundedButtonType = [self newButton:frame withImage:@"key_stop.png" andKeyCode: kButtonCodeStop];
		[rcView addSubview: roundedButtonType];
		[roundedButtonType release];

		// ff
		currX = 210;
		currY = 255;
		frame = CGRectMake(currY * factor, currX * factor, imageWidth * factor, imageHeight * factor);
		roundedButtonType = [self newButton:frame withImage:@"key_ff.png" andKeyCode: kButtonCodeFFwd];
		[rcView addSubview: roundedButtonType];
		[roundedButtonType release];

		// rwd
		currX += imageHeight + kTweenMargin;
		frame = CGRectMake(currY * factor, currX * factor, imageWidth * factor, imageHeight * factor);
		roundedButtonType = [self newButton:frame withImage:@"key_fr.png" andKeyCode: kButtonCodeFRwd];
		[rcView addSubview: roundedButtonType];
		[roundedButtonType release];
	}
}

/* alter views */
- (void)manageViews:(UIInterfaceOrientation)interfaceOrientation
{
	if(UIInterfaceOrientationIsLandscape(interfaceOrientation))
	{
		[_keyPad removeFromSuperview];
		_navigationPad.frame = _landscapeNavigationFrame;
		rcView.frame = _landscapeFrame;
	}
	else
	{
		if(![_keyPad superview])
			[rcView addSubview: _keyPad];
		_navigationPad.frame = _portraitNavigationFrame;
		rcView.frame = _portraitFrame;
	}
}

/* view is going to appear */
- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];

	[self manageViews:self.interfaceOrientation];
}

/* about to rotate */
- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
	[super willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];

	[self manageViews:toInterfaceOrientation];
}

/* allow rotation */
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return YES;
}

@end
