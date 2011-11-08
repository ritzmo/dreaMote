//
//  SVDRPRCEmulatorController.m
//  dreaMote
//
//  Created by Moritz Venn on 23.07.08.
//  Copyright 2008-2011 Moritz Venn. All rights reserved.
//

#import "SVDRPRCEmulatorController.h"
#import "RemoteConnector.h"
#import "Constants.h"

@implementation SVDRPRCEmulatorController

- (void)loadView
{
	const CGFloat factor = (IS_IPAD()) ? 2.2f : 0.9f;
	const CGFloat imageWidth = 45;
	const CGFloat imageHeight = 35;
	const CGFloat rightOffset = (IS_IPAD()) ? 20 : 23;
	CGFloat currX, localX;
	CGFloat currY, localY;
	UIButton *roundedButtonType;
	CGRect frame;

	[super loadView];

	CGSize mainViewSize = self.view.bounds.size;

	// create the rc view and prepare different frames used for orientations
	_portraitFrame = CGRectMake(0, toolbar.frame.size.height, mainViewSize.width, mainViewSize.height - toolbar.frame.size.height);
	if(IS_IPAD())
		_landscapeFrame = CGRectMake(140, 130, mainViewSize.height - 140, mainViewSize.width - 130);
	else
		_landscapeFrame = CGRectMake(85, 50, mainViewSize.height - 85, mainViewSize.width - 50);
	// Workaround when starting in landscape mode
	if(UIInterfaceOrientationIsLandscape(self.interfaceOrientation))
		_portraitFrame.origin.y += 10;
	rcView = [[UIView alloc] initWithFrame: _portraitFrame];
	[self.view addSubview:rcView];

	// initialize this
	currX = kTopMargin;
	currY = 74 + rightOffset;

	/* Begin Keypad */
	// intialize view
	_portraitKeyFrame = CGRectMake(currY * factor, currX * factor, 155 * factor, 185 * factor);
	_keyPad = [[UIView alloc] initWithFrame: _portraitKeyFrame];
	// new row
	localX = 0;
	localY = 0;

	// 1
	frame = CGRectMake(localY * factor, localX * factor, imageWidth * factor, imageHeight * factor);
	roundedButtonType = [self newButton:frame withImage:@"key_1.png" andKeyCode: kButtonCode1];
	[_keyPad addSubview: roundedButtonType];
	localY += imageWidth + kTweenMargin;
	
	// 2
	frame = CGRectMake(localY * factor, localX * factor, imageWidth * factor, imageHeight * factor);
	roundedButtonType = [self newButton:frame withImage:@"key_2.png" andKeyCode: kButtonCode2];
	[_keyPad addSubview: roundedButtonType];
	localY += imageWidth + kTweenMargin;
	
	// 3
	frame = CGRectMake(localY * factor, localX * factor, imageWidth * factor, imageHeight * factor);
	roundedButtonType = [self newButton:frame withImage:@"key_3.png" andKeyCode: kButtonCode3];
	[_keyPad addSubview: roundedButtonType];
	
	// new row
	localX += imageHeight + kTweenMargin;
	localY = 0;
	
	// 4
	frame = CGRectMake(localY * factor, localX * factor, imageWidth * factor, imageHeight * factor);
	roundedButtonType = [self newButton:frame withImage:@"key_4.png" andKeyCode: kButtonCode4];
	[_keyPad addSubview: roundedButtonType];
	localY += imageWidth + kTweenMargin;
	
	// 5
	frame = CGRectMake(localY * factor, localX * factor, imageWidth * factor, imageHeight * factor);
	roundedButtonType = [self newButton:frame withImage:@"key_5.png" andKeyCode: kButtonCode5];
	[_keyPad addSubview: roundedButtonType];
	localY += imageWidth + kTweenMargin;
	
	// 6
	frame = CGRectMake(localY * factor, localX * factor, imageWidth * factor, imageHeight * factor);
	roundedButtonType = [self newButton:frame withImage:@"key_6.png" andKeyCode: kButtonCode6];
	[_keyPad addSubview: roundedButtonType];
	//localY += imageWidth + kTweenMargin;
	
	// new row
	localX += imageHeight + kTweenMargin;
	localY = 0;
	
	// 7
	frame = CGRectMake(localY * factor, localX * factor, imageWidth * factor, imageHeight * factor);
	roundedButtonType = [self newButton:frame withImage:@"key_7.png" andKeyCode: kButtonCode7];
	[_keyPad addSubview: roundedButtonType];
	localY += imageWidth + kTweenMargin;
	
	// 8
	frame = CGRectMake(localY * factor, localX * factor, imageWidth * factor, imageHeight * factor);
	roundedButtonType = [self newButton:frame withImage:@"key_8.png" andKeyCode: kButtonCode8];
	[_keyPad addSubview: roundedButtonType];
	localY += imageWidth + kTweenMargin;
	
	// 9
	frame = CGRectMake(localY * factor, localX * factor, imageWidth * factor, imageHeight * factor);
	roundedButtonType = [self newButton:frame withImage:@"key_9.png" andKeyCode: kButtonCode9];
	[_keyPad addSubview: roundedButtonType];
	//localY += imageWidth + kTweenMargin;
	
	// new row
	localX += imageHeight + kTweenMargin;
	localY = 0;
	
	// <
	frame = CGRectMake(localY * factor, localX * factor, imageWidth * factor, imageHeight * factor);
	roundedButtonType = [self newButton:frame withImage:@"key_leftarrow.png" andKeyCode: kButtonCodePrevious];
	[_keyPad addSubview: roundedButtonType];
	localY += imageWidth + kTweenMargin;
	
	// 0
	frame = CGRectMake(localY * factor, localX * factor, imageWidth * factor, imageHeight * factor);
	roundedButtonType = [self newButton:frame withImage:@"key_0.png" andKeyCode: kButtonCode0];
	[_keyPad addSubview: roundedButtonType];
	localY += imageWidth + kTweenMargin;
	
	// >
	frame = CGRectMake(localY * factor, localX * factor, imageWidth * factor, imageHeight * factor);
	roundedButtonType = [self newButton:frame withImage:@"key_rightarrow.png" andKeyCode: kButtonCodeNext];
	[_keyPad addSubview: roundedButtonType];
	//localY += imageWidth + kTweenMargin;

	[rcView addSubview: _keyPad];
	/* End Keypad */
	
	// add offset generated by key pad
	currX += localX;
	currY = 80 + rightOffset;

	/* Begin Navigation pad */
	currX += 2*imageWidth; // currX is used as center here
	//initialize view
	if(IS_IPAD())
		_landscapeNavigationFrame = CGRectMake(222, 85, 360, 285);
	else
		_landscapeNavigationFrame = CGRectMake(95, 37, 150, 120);
	_portraitNavigationFrame = CGRectMake(currY * factor, (currX - 40) * factor, 150 * factor, 120 * factor);
	_navigationPad = [[UIView alloc] initWithFrame:_portraitNavigationFrame];
	// internal offset
	localX = 40;
	localY = 0;

	// ok
	frame = CGRectMake((localY+50) * factor, localX * factor, imageWidth * factor, imageHeight * factor);
	roundedButtonType = [self newButton:frame withImage:@"key_ok.png" andKeyCode: kButtonCodeOK];
	[_navigationPad addSubview: roundedButtonType];

	// left
	frame = CGRectMake(localY * factor, localX * factor, imageWidth * factor, imageHeight * factor);
	roundedButtonType = [self newButton:frame withImage:@"key_left.png" andKeyCode: kButtonCodeLeft];
	[_navigationPad addSubview: roundedButtonType];
	
	// right
	frame = CGRectMake((localY+100) * factor, localX * factor, imageWidth * factor, imageHeight * factor);
	roundedButtonType = [self newButton:frame withImage:@"key_right.png" andKeyCode: kButtonCodeRight];
	[_navigationPad addSubview: roundedButtonType];
	
	// up
	frame = CGRectMake((localY+50) * factor, (localX-40) * factor, imageWidth * factor, imageHeight * factor);
	roundedButtonType = [self newButton:frame withImage:@"key_up.png" andKeyCode: kButtonCodeUp];
	[_navigationPad addSubview: roundedButtonType];
	
	// down
	frame = CGRectMake((localY+50) * factor, (localX+40) * factor, imageWidth * factor, imageHeight * factor);
	roundedButtonType = [self newButton:frame withImage:@"key_down.png" andKeyCode: kButtonCodeDown];
	[_navigationPad addSubview: roundedButtonType];

	/* Additional Buttons Navigation pad */
	// info
	frame = CGRectMake(localY * factor, (localX-40) * factor, imageWidth * factor, imageHeight * factor);
	roundedButtonType = [self newButton:frame withImage:@"key_info.png" andKeyCode: kButtonCodeInfo];
	[_navigationPad addSubview: roundedButtonType];
	
	// audio
	frame = CGRectMake(localY * factor, (localX+40) * factor, imageWidth * factor, imageHeight * factor);
	roundedButtonType = [self newButton:frame withImage:@"key_audio.png" andKeyCode: kButtonCodeAudio];
	[_navigationPad addSubview: roundedButtonType];
	
	// menu
	frame = CGRectMake((localY+100) * factor, (localX-40) * factor, imageWidth * factor, imageHeight * factor);
	roundedButtonType = [self newButton:frame withImage:@"key_menu.png" andKeyCode: kButtonCodeMenu];
	[_navigationPad addSubview: roundedButtonType];
	
	// video
	frame = CGRectMake((localY+100) * factor, (localX+40) * factor, imageWidth * factor, imageHeight * factor);
	roundedButtonType = [self newButton:frame withImage:@"key_video.png" andKeyCode: kButtonCodeVideo];
	[_navigationPad addSubview: roundedButtonType];

	[rcView addSubview: _navigationPad];
	/* End Navigation pad */

	/* Lower pad */#
	currX += 2*(imageHeight+kTweenMargin);
	currY = 50 + rightOffset;

	// red
	frame = CGRectMake(currY * factor, currX * factor, imageWidth * factor, imageHeight * factor);
	roundedButtonType = [self newButton:frame withImage:@"key_red.png" andKeyCode: kButtonCodeRed];
	[rcView addSubview: roundedButtonType];
	currY += imageWidth + kTweenMargin;
	
	// green
	frame = CGRectMake(currY * factor, currX * factor, imageWidth * factor, imageHeight * factor);
	roundedButtonType = [self newButton:frame withImage:@"key_green.png" andKeyCode: kButtonCodeGreen];
	[rcView addSubview: roundedButtonType];
	currY += imageWidth + kTweenMargin;
	
	// yellow
	frame = CGRectMake(currY * factor, currX * factor, imageWidth * factor, imageHeight * factor);
	roundedButtonType = [self newButton:frame withImage:@"key_yellow.png" andKeyCode: kButtonCodeYellow];
	[rcView addSubview: roundedButtonType];
	currY += imageWidth + kTweenMargin;
	
	// blue
	frame = CGRectMake(currY * factor, currX * factor, imageWidth * factor, imageHeight * factor);
	roundedButtonType = [self newButton:frame withImage:@"key_blue.png" andKeyCode: kButtonCodeBlue];
	[rcView addSubview: roundedButtonType];

	// next row
	currX += imageHeight + kTweenMargin;
	currY = 50 + rightOffset;

	// tv
	frame = CGRectMake(currY * factor, currX * factor, imageWidth * factor, imageHeight * factor);
	roundedButtonType = [self newButton:frame withImage:@"key_tv.png" andKeyCode: kButtonCodeTV];
	[rcView addSubview: roundedButtonType];
	currY += imageWidth + kTweenMargin;
	
	// radio
	frame = CGRectMake(currY * factor, currX * factor, imageWidth * factor, imageHeight * factor);
	roundedButtonType = [self newButton:frame withImage:@"key_radio.png" andKeyCode: kButtonCodeRadio];
	[rcView addSubview: roundedButtonType];
	currY += imageWidth + kTweenMargin;
	
	// text
	frame = CGRectMake(currY * factor, currX * factor, imageWidth * factor, imageHeight * factor);
	roundedButtonType = [self newButton:frame withImage:@"key_text.png" andKeyCode: kButtonCodeText];
	[rcView addSubview: roundedButtonType];
	currY += imageWidth + kTweenMargin;
	
	// help
	frame = CGRectMake(currY * factor, currX * factor, imageWidth * factor, imageHeight * factor);
	roundedButtonType = [self newButton:frame withImage:@"key_help.png" andKeyCode: kButtonCodeHelp];
	[rcView addSubview: roundedButtonType];

	/* End lower pad */
	
	/* Volume pad */
	currX = kTopMargin + 25;
	currY = kLeftMargin + 5 + rightOffset;
	
	// up
	frame = CGRectMake(currY * factor, currX * factor, imageWidth * factor, imageHeight * factor);
	roundedButtonType = [self newButton:frame withImage:@"key_plus.png" andKeyCode: kButtonCodeVolUp];
	[rcView addSubview: roundedButtonType];
	currX += imageHeight + kTweenMargin;

	// down
	frame = CGRectMake(currY * factor, currX * factor, imageWidth * factor, imageHeight * factor);
	roundedButtonType = [self newButton:frame withImage:@"key_minus.png" andKeyCode: kButtonCodeVolDown];
	[rcView addSubview: roundedButtonType];
	
	/* End Volume pad */

	/* Bouquet pad */
	currX = kTopMargin + 25;
	currY = 255 + rightOffset;
	
	// up
	frame = CGRectMake(currY * factor, currX * factor, imageWidth * factor, imageHeight * factor);
	roundedButtonType = [self newButton:frame withImage:@"key_plus.png" andKeyCode: kButtonCodeBouquetUp];
	[rcView addSubview: roundedButtonType];
	currX += imageHeight + kTweenMargin;

	// down
	frame = CGRectMake(currY * factor, currX * factor, imageWidth * factor, imageHeight * factor);
	roundedButtonType = [self newButton:frame withImage:@"key_minus.png" andKeyCode: kButtonCodeBouquetDown];
	[rcView addSubview: roundedButtonType];

	/* End Bouquet pad */

	// mute
	currX = 140;
	currY = kLeftMargin + 5 + rightOffset;
	frame = CGRectMake(currY * factor, currX * factor, imageWidth * factor, imageHeight * factor);
	roundedButtonType = [self newButton:frame withImage:@"key_mute.png" andKeyCode: kButtonCodeMute];
	[rcView addSubview: roundedButtonType];
	
	// lame
	currX = 140;
	currY = 255 + rightOffset;
	frame = CGRectMake(currY * factor, currX * factor, imageWidth * factor, imageHeight * factor);
	roundedButtonType = [self newButton:frame withImage:@"key_exit.png" andKeyCode: kButtonCodeLame];
	[rcView addSubview: roundedButtonType];

	[self theme];
}

@end
