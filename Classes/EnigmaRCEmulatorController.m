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

	// create the rc view and prepare different frames used for orientations
	_portraitFrame = CGRectMake(0, 0, mainViewSize.width, mainViewSize.height);
	if(IS_IPAD())
	{
		if(usesAdvancedRemote)
			// XXX: wtf is wrong here? -20 ?!
			_landscapeFrame = CGRectMake(140, -20, mainViewSize.height - 140, mainViewSize.width);
		else
			_landscapeFrame = CGRectMake(140, 95, mainViewSize.height - 140, mainViewSize.width - 95);
	}
	else
	{
		// Make frame a little smaller than full screen to cut off advanced rc buttons
		_landscapeFrame = CGRectMake(85, 40, mainViewSize.height - 85, mainViewSize.width - 50);
	}
	rcView = [[UIView alloc] initWithFrame: _portraitFrame];
	[self.view addSubview:rcView];

	// initialize this
	currX = kTopMargin;
	currY = 74;

	/* Begin Keypad */
	// intialize view
	_portraitKeyFrame = CGRectMake(currY * factor, currX * factor, 135 * factor, 165 * factor);
	_keyPad = [[UIView alloc] initWithFrame: _portraitKeyFrame];
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
	currY = 80;

	/* Begin Navigation pad */
	currX += 2*imageWidth; // currX is used as center here
	//initialize view
	if(IS_IPAD())
	{
		if(usesAdvancedRemote)
			_landscapeNavigationFrame = CGRectMake(195, 237, 360, 285);
		else
			_landscapeNavigationFrame = CGRectMake(195, 95, 360, 285);
	}
	else
		_landscapeNavigationFrame = CGRectMake(80, 35, 150, 120);
	_portraitNavigationFrame = CGRectMake(currY * factor, (currX - 40) * factor, 150 * factor, 120 * factor);
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

@end
