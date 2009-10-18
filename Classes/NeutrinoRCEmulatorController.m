//
//  NeutrinoRCEmulatorController.m
//  dreaMote
//
//  Created by Moritz Venn on 23.07.08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <AudioToolbox/AudioServices.h>

#import "NeutrinoRCEmulatorController.h"
#import "RemoteConnector.h"
#import "Constants.h"

@implementation NeutrinoRCEmulatorController

- (id)init
{
	if (self = [super init])
	{
		self.title = NSLocalizedString(@"Remote Control", @"Title of RCEmulatorController");
	}

	return self;
}

- (void)loadView
{
	[super loadView];

	CGSize mainViewSize = self.view.bounds.size;
	CGRect frame;

#pragma mark RC View

	// create the rc views (i think its easier to have two views than to keep track of all buttons and add/remove them as pleased)
	frame = CGRectMake(0.0, 0.0, mainViewSize.width, mainViewSize.height);
	rcView = [[UIView alloc] initWithFrame: frame];
	[self.view addSubview:rcView];

	UIButton *roundedButtonType;

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
	roundedButtonType = [self newButton:frame withImage:@"key_1.png" andKeyCode: kButtonCode1];
	[rcView addSubview: roundedButtonType];
	[roundedButtonType release];
	currY += imageWidth + kTweenMargin;
	
	// 2
	frame = CGRectMake(currY, currX, imageWidth, imageHeight);
	roundedButtonType = [self newButton:frame withImage:@"key_2.png" andKeyCode: kButtonCode2];
	[rcView addSubview: roundedButtonType];
	[roundedButtonType release];
	currY += imageWidth + kTweenMargin;
	
	// 3
	frame = CGRectMake(currY, currX, imageWidth, imageHeight);
	roundedButtonType = [self newButton:frame withImage:@"key_3.png" andKeyCode: kButtonCode3];
	[rcView addSubview: roundedButtonType];
	[roundedButtonType release];
	
	// new row
	currX += imageHeight + kTweenMargin;
	currY = 75;
	
	// 4
	frame = CGRectMake(currY, currX, imageWidth, imageHeight);
	roundedButtonType = [self newButton:frame withImage:@"key_4.png" andKeyCode: kButtonCode4];
	[rcView addSubview: roundedButtonType];
	[roundedButtonType release];
	currY += imageWidth + kTweenMargin;
	
	// 5
	frame = CGRectMake(currY, currX, imageWidth, imageHeight);
	roundedButtonType = [self newButton:frame withImage:@"key_5.png" andKeyCode: kButtonCode5];
	[rcView addSubview: roundedButtonType];
	[roundedButtonType release];
	currY += imageWidth + kTweenMargin;
	
	// 6
	frame = CGRectMake(currY, currX, imageWidth, imageHeight);
	roundedButtonType = [self newButton:frame withImage:@"key_6.png" andKeyCode: kButtonCode6];
	[rcView addSubview: roundedButtonType];
	[roundedButtonType release];
	//currY += imageWidth + kTweenMargin;
	
	// new row
	currX += imageHeight + kTweenMargin;
	currY = 75;
	
	// 7
	frame = CGRectMake(currY, currX, imageWidth, imageHeight);
	roundedButtonType = [self newButton:frame withImage:@"key_7.png" andKeyCode: kButtonCode7];
	[rcView addSubview: roundedButtonType];
	[roundedButtonType release];
	currY += imageWidth + kTweenMargin;
	
	// 8
	frame = CGRectMake(currY, currX, imageWidth, imageHeight);
	roundedButtonType = [self newButton:frame withImage:@"key_8.png" andKeyCode: kButtonCode8];
	[rcView addSubview: roundedButtonType];
	[roundedButtonType release];
	currY += imageWidth + kTweenMargin;
	
	// 9
	frame = CGRectMake(currY, currX, imageWidth, imageHeight);
	roundedButtonType = [self newButton:frame withImage:@"key_9.png" andKeyCode: kButtonCode9];
	[rcView addSubview: roundedButtonType];
	[roundedButtonType release];
	//currY += imageWidth + kTweenMargin;
	
	// new row
	currX += imageHeight + kTweenMargin;
	currY = 75;

	currY += imageWidth + kTweenMargin;
	
	// 0
	frame = CGRectMake(currY, currX, imageWidth, imageHeight);
	roundedButtonType = [self newButton:frame withImage:@"key_0.png" andKeyCode: kButtonCode0];
	[rcView addSubview: roundedButtonType];
	[roundedButtonType release];
	//currY += imageWidth + kTweenMargin;

	/* End Keypad */
	
	/* Begin Navigation pad */
	currX += 2*imageWidth; // currX is used as center here
	currY = 77;
	
	// ok
	frame = CGRectMake(currY+50, currX, imageWidth, imageHeight);
	roundedButtonType = [self newButton:frame withImage:@"key_ok.png" andKeyCode: kButtonCodeOK];
	[rcView addSubview: roundedButtonType];
	[roundedButtonType release];

	// left
	frame = CGRectMake(currY, currX, imageWidth, imageHeight);
	roundedButtonType = [self newButton:frame withImage:@"key_left.png" andKeyCode: kButtonCodeLeft];
	[rcView addSubview: roundedButtonType];
	[roundedButtonType release];
	
	// right
	frame = CGRectMake(currY+100, currX, imageWidth, imageHeight);
	roundedButtonType = [self newButton:frame withImage:@"key_right.png" andKeyCode: kButtonCodeRight];
	[rcView addSubview: roundedButtonType];
	[roundedButtonType release];
	
	// up
	frame = CGRectMake(currY+50, currX-40, imageWidth, imageHeight);
	roundedButtonType = [self newButton:frame withImage:@"key_up.png" andKeyCode: kButtonCodeUp];
	[rcView addSubview: roundedButtonType];
	[roundedButtonType release];
	
	// down
	frame = CGRectMake(currY+50, currX+40, imageWidth, imageHeight);
	roundedButtonType = [self newButton:frame withImage:@"key_down.png" andKeyCode: kButtonCodeDown];
	[rcView addSubview: roundedButtonType];
	[roundedButtonType release];

	/* Additional Buttons Navigation pad */
	// menu
	frame = CGRectMake(currY+100, currX-40, imageWidth, imageHeight);
	roundedButtonType = [self newButton:frame withImage:@"key_menu.png" andKeyCode: kButtonCodeMenu];
	[rcView addSubview: roundedButtonType];
	[roundedButtonType release];
	
	/* End Navigation pad */

	/* Lower pad */#
	currX += 2*(imageHeight+kTweenMargin);
	currY = 50;

	// red
	frame = CGRectMake(currY, currX, imageWidth, imageHeight);
	roundedButtonType = [self newButton:frame withImage:@"key_red.png" andKeyCode: kButtonCodeRed];
	[rcView addSubview: roundedButtonType];
	[roundedButtonType release];
	currY += imageWidth + kTweenMargin;
	
	// green
	frame = CGRectMake(currY, currX, imageWidth, imageHeight);
	roundedButtonType = [self newButton:frame withImage:@"key_green.png" andKeyCode: kButtonCodeGreen];
	[rcView addSubview: roundedButtonType];
	[roundedButtonType release];
	currY += imageWidth + kTweenMargin;
	
	// yellow
	frame = CGRectMake(currY, currX, imageWidth, imageHeight);
	roundedButtonType = [self newButton:frame withImage:@"key_yellow.png" andKeyCode: kButtonCodeYellow];
	[rcView addSubview: roundedButtonType];
	[roundedButtonType release];
	currY += imageWidth + kTweenMargin;
	
	// blue
	frame = CGRectMake(currY, currX, imageWidth, imageHeight);
	roundedButtonType = [self newButton:frame withImage:@"key_blue.png" andKeyCode: kButtonCodeBlue];
	[rcView addSubview: roundedButtonType];
	[roundedButtonType release];

	// next row
	currX += imageHeight + kTweenMargin;
	currY = 50;

	// tv
	frame = CGRectMake(currY, currX, imageWidth, imageHeight);
	roundedButtonType = [self newButton:frame withImage:@"key_tv.png" andKeyCode: kButtonCodeTV];
	[rcView addSubview: roundedButtonType];
	[roundedButtonType release];
	currY += imageWidth + kTweenMargin;
	
	// radio
	frame = CGRectMake(currY, currX, imageWidth, imageHeight);
	roundedButtonType = [self newButton:frame withImage:@"key_radio.png" andKeyCode: kButtonCodeRadio];
	[rcView addSubview: roundedButtonType];
	[roundedButtonType release];
	currY += imageWidth + kTweenMargin;

	currY += imageWidth + kTweenMargin;

	// help
	frame = CGRectMake(currY, currX, imageWidth, imageHeight);
	roundedButtonType = [self newButton:frame withImage:@"key_help.png" andKeyCode: kButtonCodeHelp];
	[rcView addSubview: roundedButtonType];
	[roundedButtonType release];

	/* End lower pad */
	
	/* Volume pad */
	currX = kTopMargin+25;
	currY = kLeftMargin+5;
	
	// up
	frame = CGRectMake(currY, currX, imageWidth, imageHeight);
	roundedButtonType = [self newButton:frame withImage:@"key_plus.png" andKeyCode: kButtonCodeVolUp];
	[rcView addSubview: roundedButtonType];
	[roundedButtonType release];
	currX += imageHeight + kTweenMargin;

	// down
	frame = CGRectMake(currY, currX, imageWidth, imageHeight);
	roundedButtonType = [self newButton:frame withImage:@"key_minus.png" andKeyCode: kButtonCodeVolDown];
	[rcView addSubview: roundedButtonType];
	[roundedButtonType release];
	
	/* End Volume pad */

	// mute
	currX = 140;
	currY = kLeftMargin+5;
	frame = CGRectMake(currY, currX, imageWidth, imageHeight);
	roundedButtonType = [self newButton:frame withImage:@"key_mute.png" andKeyCode: kButtonCodeMute];
	[rcView addSubview: roundedButtonType];
	[roundedButtonType release];
	
	// lame
	currX = 140;
	currY = 255;
	frame = CGRectMake(currY, currX, imageWidth, imageHeight);
	roundedButtonType = [self newButton:frame withImage:@"key_exit.png" andKeyCode: kButtonCodeLame];
	[rcView addSubview: roundedButtonType];
	[roundedButtonType release];
}

@end
