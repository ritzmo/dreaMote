//
//  RCEmulatorController.m
//  Untitled
//
//  Created by Moritz Venn on 23.07.08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "RCEmulatorController.h"
#import "RemoteConnectorObject.h"
#import "RCButton.h"
#import "Constants.h"

@interface RCEmulatorController()
- (UIButton*)customButton:(CGRect)frame withImage:(NSString*)imagePath andKeyCode:(int)keyCode;
@end


@implementation RCEmulatorController

- (id)init
{
	if (self = [super init])
	{
		self.title = NSLocalizedString(@"Remote Control Title", @"");
	}

	return self;
}

- (void)dealloc
{
	[super dealloc];
}

- (void)loadView
{
	UIColor *backColor = [UIColor colorWithRed:197.0/255.0 green:204.0/255.0 blue:211.0/255.0 alpha:1.0];
	
	// setup our parent content view and embed it to your view controller
	UIView *contentView = [[UIView alloc] initWithFrame:[[UIScreen mainScreen] applicationFrame]];
	contentView.backgroundColor = backColor;
	self.view = contentView;
	self.view.autoresizesSubviews = YES;
	
	[contentView release];

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
	[self.view addSubview: roundedButtonType];
	currY += imageWidth + kTweenMargin;
	
	// 2
	frame = CGRectMake(currY, currX, imageWidth, imageHeight);
	roundedButtonType = [self customButton:frame withImage:@"key_2.png" andKeyCode: kButtonCode2];
	[self.view addSubview: roundedButtonType];
	currY += imageWidth + kTweenMargin;
	
	// 3
	frame = CGRectMake(currY, currX, imageWidth, imageHeight);
	roundedButtonType = [self customButton:frame withImage:@"key_3.png" andKeyCode: kButtonCode3];
	[self.view addSubview: roundedButtonType];
	
	// new row
	currX += imageHeight + kTweenMargin;
	currY = 75;
	
	// 4
	frame = CGRectMake(currY, currX, imageWidth, imageHeight);
	roundedButtonType = [self customButton:frame withImage:@"key_4.png" andKeyCode: kButtonCode4];
	[self.view addSubview: roundedButtonType];
	currY += imageWidth + kTweenMargin;
	
	// 5
	frame = CGRectMake(currY, currX, imageWidth, imageHeight);
	roundedButtonType = [self customButton:frame withImage:@"key_5.png" andKeyCode: kButtonCode5];
	[self.view addSubview: roundedButtonType];
	currY += imageWidth + kTweenMargin;
	
	// 6
	frame = CGRectMake(currY, currX, imageWidth, imageHeight);
	roundedButtonType = [self customButton:frame withImage:@"key_6.png" andKeyCode: kButtonCode6];
	[self.view addSubview: roundedButtonType];
	currY += imageWidth + kTweenMargin;
	
	// new row
	currX += imageHeight + kTweenMargin;
	currY = 75;
	
	// 7
	frame = CGRectMake(currY, currX, imageWidth, imageHeight);
	roundedButtonType = [self customButton:frame withImage:@"key_7.png" andKeyCode: kButtonCode7];
	[self.view addSubview: roundedButtonType];
	currY += imageWidth + kTweenMargin;
	
	// 8
	frame = CGRectMake(currY, currX, imageWidth, imageHeight);
	roundedButtonType = [self customButton:frame withImage:@"key_8.png" andKeyCode: kButtonCode8];
	[self.view addSubview: roundedButtonType];
	currY += imageWidth + kTweenMargin;
	
	// 9
	frame = CGRectMake(currY, currX, imageWidth, imageHeight);
	roundedButtonType = [self customButton:frame withImage:@"key_9.png" andKeyCode: kButtonCode9];
	[self.view addSubview: roundedButtonType];
	currY += imageWidth + kTweenMargin;
	
	// new row
	currX += imageHeight + kTweenMargin;
	currY = 75;
	
	// <
	frame = CGRectMake(currY, currX, imageWidth, imageHeight);
	roundedButtonType = [self customButton:frame withImage:@"key_leftarrow.png" andKeyCode: kButtonCodePrevious];
	[self.view addSubview: roundedButtonType];
	currY += imageWidth + kTweenMargin;
	
	// 0
	frame = CGRectMake(currY, currX, imageWidth, imageHeight);
	roundedButtonType = [self customButton:frame withImage:@"key_0.png" andKeyCode: kButtonCode0];
	[self.view addSubview: roundedButtonType];
	currY += imageWidth + kTweenMargin;
	
	// >
	frame = CGRectMake(currY, currX, imageWidth, imageHeight);
	roundedButtonType = [self customButton:frame withImage:@"key_rightarrow.png" andKeyCode: kButtonCodeNext];
	[self.view addSubview: roundedButtonType];
	currY += imageWidth + kTweenMargin;
	
	/* End Keypad */
	
	/* Begin Navigation pad */
	currX += 2*imageWidth; // currX is used as center here
	currY = 77;
	
	// ok
	frame = CGRectMake(currY+50, currX, imageWidth, imageHeight);
	roundedButtonType = [self customButton:frame withImage:@"key_ok.png" andKeyCode: kButtonCodeOK];
	[self.view addSubview: roundedButtonType];

	// left
	frame = CGRectMake(currY, currX, imageWidth, imageHeight);
	roundedButtonType = [self customButton:frame withImage:@"key_left.png" andKeyCode: kButtonCodeLeft];
	[self.view addSubview: roundedButtonType];
	
	// right
	frame = CGRectMake(currY+100, currX, imageWidth, imageHeight);
	roundedButtonType = [self customButton:frame withImage:@"key_right.png" andKeyCode: kButtonCodeRight];
	[self.view addSubview: roundedButtonType];
	
	// up
	frame = CGRectMake(currY+50, currX-40, imageWidth, imageHeight);
	roundedButtonType = [self customButton:frame withImage:@"key_up.png" andKeyCode: kButtonCodeUp];
	[self.view addSubview: roundedButtonType];
	
	// down
	frame = CGRectMake(currY+50, currX+40, imageWidth, imageHeight);
	roundedButtonType = [self customButton:frame withImage:@"key_down.png" andKeyCode: kButtonCodeDown];
	[self.view addSubview: roundedButtonType];

	/* Additional Buttons Navigation pad */
	// info
	frame = CGRectMake(currY, currX-40, imageWidth, imageHeight);
	roundedButtonType = [self customButton:frame withImage:@"key_info.png" andKeyCode: kButtonCodeInfo];
	[self.view addSubview: roundedButtonType];
	
	// audio
	frame = CGRectMake(currY, currX+40, imageWidth, imageHeight);
	roundedButtonType = [self customButton:frame withImage:@"key_audio.png" andKeyCode: kButtonCodeAudio];
	[self.view addSubview: roundedButtonType];
	
	// menu
	frame = CGRectMake(currY+100, currX-40, imageWidth, imageHeight);
	roundedButtonType = [self customButton:frame withImage:@"key_menu.png" andKeyCode: kButtonCodeMenu];
	[self.view addSubview: roundedButtonType];
	
	// video
	frame = CGRectMake(currY+100, currX+40, imageWidth, imageHeight);
	roundedButtonType = [self customButton:frame withImage:@"key_video.png" andKeyCode: kButtonCodeVideo];
	[self.view addSubview: roundedButtonType];

	/* End Navigation pad */

	/* Lower pad */#
	currX += 2*(imageHeight+kTweenMargin);
	currY = 50;

	// red
	frame = CGRectMake(currY, currX, imageWidth, imageHeight);
	roundedButtonType = [self customButton:frame withImage:@"key_red.png" andKeyCode: kButtonCodeRed];
	[self.view addSubview: roundedButtonType];
	currY += imageWidth + kTweenMargin;
	
	// green
	frame = CGRectMake(currY, currX, imageWidth, imageHeight);
	roundedButtonType = [self customButton:frame withImage:@"key_green.png" andKeyCode: kButtonCodeGreen];
	[self.view addSubview: roundedButtonType];
	currY += imageWidth + kTweenMargin;
	
	// yellow
	frame = CGRectMake(currY, currX, imageWidth, imageHeight);
	roundedButtonType = [self customButton:frame withImage:@"key_yellow.png" andKeyCode: kButtonCodeYellow];
	[self.view addSubview: roundedButtonType];
	currY += imageWidth + kTweenMargin;
	
	// blue
	frame = CGRectMake(currY, currX, imageWidth, imageHeight);
	roundedButtonType = [self customButton:frame withImage:@"key_blue.png" andKeyCode: kButtonCodeBlue];
	[self.view addSubview: roundedButtonType];

	// next row
	currX += imageHeight + kTweenMargin;
	currY = 50;

	// tv
	frame = CGRectMake(currY, currX, imageWidth, imageHeight);
	roundedButtonType = [self customButton:frame withImage:@"key_tv.png" andKeyCode: kButtonCodeTV];
	[self.view addSubview: roundedButtonType];
	currY += imageWidth + kTweenMargin;
	
	// radio
	frame = CGRectMake(currY, currX, imageWidth, imageHeight);
	roundedButtonType = [self customButton:frame withImage:@"key_radio.png" andKeyCode: kButtonCodeRadio];
	[self.view addSubview: roundedButtonType];
	currY += imageWidth + kTweenMargin;
	
	// text
	frame = CGRectMake(currY, currX, imageWidth, imageHeight);
	roundedButtonType = [self customButton:frame withImage:@"key_text.png" andKeyCode: kButtonCodeText];
	[self.view addSubview: roundedButtonType];
	currY += imageWidth + kTweenMargin;
	
	// help
	frame = CGRectMake(currY, currX, imageWidth, imageHeight);
	roundedButtonType = [self customButton:frame withImage:@"key_help.png" andKeyCode: kButtonCodeHelp];
	[self.view addSubview: roundedButtonType];

	/* End lower pad */
	
	/* Volume pad */
	currX = kTopMargin+25;
	currY = kLeftMargin+5;
	
	// up
	frame = CGRectMake(currY, currX, imageWidth, imageHeight);
	roundedButtonType = [self customButton:frame withImage:@"key_plus.png" andKeyCode: kButtonCodeVolUp];
	[self.view addSubview: roundedButtonType];
	currX += imageHeight + kTweenMargin;

	// down
	frame = CGRectMake(currY, currX, imageWidth, imageHeight);
	roundedButtonType = [self customButton:frame withImage:@"key_minus.png" andKeyCode: kButtonCodeVolDown];
	[self.view addSubview: roundedButtonType];
	
	/* End Volume pad */

	/* Bouquet pad */
	currX = kTopMargin+25;
	currY = 255;
	
	// up
	frame = CGRectMake(currY, currX, imageWidth, imageHeight);
	roundedButtonType = [self customButton:frame withImage:@"key_plus.png" andKeyCode: kButtonCodeBouquetUp];
	[self.view addSubview: roundedButtonType];
	currX += imageHeight + kTweenMargin;

	// down
	frame = CGRectMake(currY, currX, imageWidth, imageHeight);
	roundedButtonType = [self customButton:frame withImage:@"key_minus.png" andKeyCode: kButtonCodeBouquetDown];
	[self.view addSubview: roundedButtonType];

	/* End Bouquet pad */

	// mute
	currX = 140;
	currY = kLeftMargin+5;
	frame = CGRectMake(currY, currX, imageWidth, imageHeight);
	roundedButtonType = [self customButton:frame withImage:@"key_mute.png" andKeyCode: kButtonCodeMute];
	[self.view addSubview: roundedButtonType];
	
	// lame
	currX = 140;
	currY = 255;
	frame = CGRectMake(currY, currX, imageWidth, imageHeight);
	roundedButtonType = [self customButton:frame withImage:@"key_exit.png" andKeyCode: kButtonCodeLame];
	[self.view addSubview: roundedButtonType];
}

- (UIButton*)customButton:(CGRect)frame withImage:(NSString*)imagePath andKeyCode:(int)keyCode
{
	RCButton *uiButton = [[RCButton alloc] initWithFrame: frame];
	uiButton.frame = frame;
	uiButton.rcCode = keyCode;
	if(imagePath != nil){
		UIImage *image = [UIImage imageNamed:imagePath];
		[uiButton setBackgroundImage:image forState:UIControlStateHighlighted];
		[uiButton setBackgroundImage:image forState:UIControlStateNormal];
	}
	[uiButton addTarget:self action:@selector(buttonPressed:) forControlEvents:UIControlEventTouchUpInside];

	return uiButton;
}

- (void)buttonPressed:(id)sender
{
	[[RemoteConnectorObject sharedRemoteConnector] sendButton: ((RCButton*)sender).rcCode];
}

@end
