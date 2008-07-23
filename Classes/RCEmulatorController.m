//
//  RCEmulatorController.m
//  Untitled
//
//  Created by Moritz Venn on 23.07.08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "RCEmulatorController.h"
#import "RemoteConnectorObject.h"
#import "Constants.h"

@interface RCEmulatorController()
- (UIButton*)customButton:(CGRect)frame withImage:(NSString*)imagePath action:(SEL)action;
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
	roundedButtonType = [self customButton:frame withImage:@"key_1.png" action:@selector(onePressed:)];
	[self.view addSubview: roundedButtonType];
	currY += imageWidth + kTweenMargin;
	
	// 2
	frame = CGRectMake(currY, currX, imageWidth, imageHeight);
	roundedButtonType = [self customButton:frame withImage:@"key_2.png" action:@selector(twoPressed:)];
	[self.view addSubview: roundedButtonType];
	currY += imageWidth + kTweenMargin;
	
	// 3
	frame = CGRectMake(currY, currX, imageWidth, imageHeight);
	roundedButtonType = [self customButton:frame withImage:@"key_3.png" action:@selector(threePressed:)];
	[self.view addSubview: roundedButtonType];
	
	// new row
	currX += imageHeight + kTweenMargin;
	currY = 75;
	
	// 4
	frame = CGRectMake(currY, currX, imageWidth, imageHeight);
	roundedButtonType = [self customButton:frame withImage:@"key_4.png" action:@selector(fourPressed:)];
	[self.view addSubview: roundedButtonType];
	currY += imageWidth + kTweenMargin;
	
	// 5
	frame = CGRectMake(currY, currX, imageWidth, imageHeight);
	roundedButtonType = [self customButton:frame withImage:@"key_5.png" action:@selector(fivePressed:)];
	[self.view addSubview: roundedButtonType];
	currY += imageWidth + kTweenMargin;
	
	// 6
	frame = CGRectMake(currY, currX, imageWidth, imageHeight);
	roundedButtonType = [self customButton:frame withImage:@"key_6.png" action:@selector(sixPressed:)];
	[self.view addSubview: roundedButtonType];
	currY += imageWidth + kTweenMargin;
	
	// new row
	currX += imageHeight + kTweenMargin;
	currY = 75;
	
	// 7
	frame = CGRectMake(currY, currX, imageWidth, imageHeight);
	roundedButtonType = [self customButton:frame withImage:@"key_7.png" action:@selector(sevenPressed:)];
	[self.view addSubview: roundedButtonType];
	currY += imageWidth + kTweenMargin;
	
	// 8
	frame = CGRectMake(currY, currX, imageWidth, imageHeight);
	roundedButtonType = [self customButton:frame withImage:@"key_8.png" action:@selector(eightPressed:)];
	[self.view addSubview: roundedButtonType];
	currY += imageWidth + kTweenMargin;
	
	// 9
	frame = CGRectMake(currY, currX, imageWidth, imageHeight);
	roundedButtonType = [self customButton:frame withImage:@"key_9.png" action:@selector(ninePressed:)];
	[self.view addSubview: roundedButtonType];
	currY += imageWidth + kTweenMargin;
	
	// new row
	currX += imageHeight + kTweenMargin;
	currY = 75;
	
	// <
	frame = CGRectMake(currY, currX, imageWidth, imageHeight);
	roundedButtonType = [self customButton:frame withImage:@"key_leftarrow.png" action:@selector(leftArrowPressed:)];
	[self.view addSubview: roundedButtonType];
	currY += imageWidth + kTweenMargin;
	
	// 0
	frame = CGRectMake(currY, currX, imageWidth, imageHeight);
	roundedButtonType = [self customButton:frame withImage:@"key_0.png" action:@selector(zeroPressed:)];
	[self.view addSubview: roundedButtonType];
	currY += imageWidth + kTweenMargin;
	
	// >
	frame = CGRectMake(currY, currX, imageWidth, imageHeight);
	roundedButtonType = [self customButton:frame withImage:@"key_rightarrow.png" action:@selector(rightArrowPressed:)];
	[self.view addSubview: roundedButtonType];
	currY += imageWidth + kTweenMargin;
	
	/* End Keypad */
	
	/* Begin Navigation pad */
	currX += 2*imageWidth; // currX is used as center here
	currY = 77;
	
	// ok
	frame = CGRectMake(currY+50, currX, imageWidth, imageHeight);
	roundedButtonType = [self customButton:frame withImage:@"key_ok.png" action:@selector(okPressed:)];
	[self.view addSubview: roundedButtonType];

	// left
	frame = CGRectMake(currY, currX, imageWidth, imageHeight);
	roundedButtonType = [self customButton:frame withImage:@"key_left.png" action:@selector(leftPressed:)];
	[self.view addSubview: roundedButtonType];
	
	// right
	frame = CGRectMake(currY+100, currX, imageWidth, imageHeight);
	roundedButtonType = [self customButton:frame withImage:@"key_right.png" action:@selector(rightPressed:)];
	[self.view addSubview: roundedButtonType];
	
	// up
	frame = CGRectMake(currY+50, currX-40, imageWidth, imageHeight);
	roundedButtonType = [self customButton:frame withImage:@"key_up.png" action:@selector(upPressed:)];
	[self.view addSubview: roundedButtonType];
	
	// down
	frame = CGRectMake(currY+50, currX+40, imageWidth, imageHeight);
	roundedButtonType = [self customButton:frame withImage:@"key_down.png" action:@selector(downPressed:)];
	[self.view addSubview: roundedButtonType];

	/* Additional Buttons Navigation pad */
	// info
	frame = CGRectMake(currY, currX-40, imageWidth, imageHeight);
	roundedButtonType = [self customButton:frame withImage:@"key_info.png" action:@selector(infoPressed:)];
	[self.view addSubview: roundedButtonType];
	
	// audio
	frame = CGRectMake(currY, currX+40, imageWidth, imageHeight);
	roundedButtonType = [self customButton:frame withImage:@"key_audio.png" action:@selector(audioPressed:)];
	[self.view addSubview: roundedButtonType];
	
	// menu
	frame = CGRectMake(currY+100, currX-40, imageWidth, imageHeight);
	roundedButtonType = [self customButton:frame withImage:@"key_menu.png" action:@selector(menuPressed:)];
	[self.view addSubview: roundedButtonType];
	
	// video
	frame = CGRectMake(currY+100, currX+40, imageWidth, imageHeight);
	roundedButtonType = [self customButton:frame withImage:@"key_video.png" action:@selector(videoPressed:)];
	[self.view addSubview: roundedButtonType];

	/* End Navigation pad */

	/* Lower pad */#
	currX += 2*(imageHeight+kTweenMargin);
	currY = 50;

	// red
	frame = CGRectMake(currY, currX, imageWidth, imageHeight);
	roundedButtonType = [self customButton:frame withImage:@"key_red.png" action:@selector(redPressed:)];
	[self.view addSubview: roundedButtonType];
	currY += imageWidth + kTweenMargin;
	
	// green
	frame = CGRectMake(currY, currX, imageWidth, imageHeight);
	roundedButtonType = [self customButton:frame withImage:@"key_green.png" action:@selector(greenPressed:)];
	[self.view addSubview: roundedButtonType];
	currY += imageWidth + kTweenMargin;
	
	// yellow
	frame = CGRectMake(currY, currX, imageWidth, imageHeight);
	roundedButtonType = [self customButton:frame withImage:@"key_yellow.png" action:@selector(yellowPressed:)];
	[self.view addSubview: roundedButtonType];
	currY += imageWidth + kTweenMargin;
	
	// blue
	frame = CGRectMake(currY, currX, imageWidth, imageHeight);
	roundedButtonType = [self customButton:frame withImage:@"key_blue.png" action:@selector(bluePressed:)];
	[self.view addSubview: roundedButtonType];

	// next row
	currX += imageHeight + kTweenMargin;
	currY = 50;

	// tv
	frame = CGRectMake(currY, currX, imageWidth, imageHeight);
	roundedButtonType = [self customButton:frame withImage:@"key_tv.png" action:@selector(tvPressed:)];
	[self.view addSubview: roundedButtonType];
	currY += imageWidth + kTweenMargin;
	
	// radio
	frame = CGRectMake(currY, currX, imageWidth, imageHeight);
	roundedButtonType = [self customButton:frame withImage:@"key_radio.png" action:@selector(radioPressed:)];
	[self.view addSubview: roundedButtonType];
	currY += imageWidth + kTweenMargin;
	
	// text
	frame = CGRectMake(currY, currX, imageWidth, imageHeight);
	roundedButtonType = [self customButton:frame withImage:@"key_text.png" action:@selector(textPressed:)];
	[self.view addSubview: roundedButtonType];
	currY += imageWidth + kTweenMargin;
	
	// help
	frame = CGRectMake(currY, currX, imageWidth, imageHeight);
	roundedButtonType = [self customButton:frame withImage:@"key_help.png" action:@selector(helpPressed:)];
	[self.view addSubview: roundedButtonType];

	/* End lower pad */
	
	/* Volume pad */
	currX = kTopMargin+25;
	currY = kLeftMargin+5;
	
	// up
	frame = CGRectMake(currY, currX, imageWidth, imageHeight);
	roundedButtonType = [self customButton:frame withImage:@"key_plus.png" action:@selector(volUpPressed:)];
	[self.view addSubview: roundedButtonType];
	currX += imageHeight + kTweenMargin;

	// down
	frame = CGRectMake(currY, currX, imageWidth, imageHeight);
	roundedButtonType = [self customButton:frame withImage:@"key_minus.png" action:@selector(volDownPressed:)];
	[self.view addSubview: roundedButtonType];
	
	/* End Volume pad */

	/* Bouquet pad */
	currX = kTopMargin+25;
	currY = 255;
	
	// up
	frame = CGRectMake(currY, currX, imageWidth, imageHeight);
	roundedButtonType = [self customButton:frame withImage:@"key_plus.png" action:@selector(bouquetUpPressed:)];
	[self.view addSubview: roundedButtonType];
	currX += imageHeight + kTweenMargin;

	// down
	frame = CGRectMake(currY, currX, imageWidth, imageHeight);
	roundedButtonType = [self customButton:frame withImage:@"key_minus.png" action:@selector(bouquetDownPressed:)];
	[self.view addSubview: roundedButtonType];

	/* End Bouquet pad */

	// mute
	currX = 140;
	currY = kLeftMargin+5;
	frame = CGRectMake(currY, currX, imageWidth, imageHeight);
	roundedButtonType = [self customButton:frame withImage:@"key_mute.png" action:@selector(mutePressed:)];
	[self.view addSubview: roundedButtonType];
	
	// lame
	currX = 140;
	currY = 255;
	frame = CGRectMake(currY, currX, imageWidth, imageHeight);
	roundedButtonType = [self customButton:frame withImage:@"key_exit.png" action:@selector(lamePressed:)];
	[self.view addSubview: roundedButtonType];
}

- (UIButton*)customButton:(CGRect)frame withImage:(NSString*)imagePath action:(SEL)action
{
	UIButton *uiButton = [UIButton buttonWithType: UIButtonTypeCustom];
	uiButton.frame = frame;
	//uiButon.backgroundColor = backColor;
	if(imagePath != nil){
		UIImage *image = [UIImage imageNamed:imagePath];
		[uiButton setBackgroundImage:image forState:UIControlStateHighlighted];
		[uiButton setBackgroundImage:image forState:UIControlStateNormal];
	}
	[uiButton addTarget:self action:action forControlEvents:UIControlEventTouchUpInside];

	return uiButton;
}

- (void)okPressed:(id)sender
{
	[[RemoteConnectorObject sharedRemoteConnector] sendButton: kButtonCodeOK];
}

- (void)upPressed:(id)sender
{
	[[RemoteConnectorObject sharedRemoteConnector] sendButton: kButtonCodeUp];
}

- (void)downPressed:(id)sender
{
	[[RemoteConnectorObject sharedRemoteConnector] sendButton: kButtonCodeDown];
}

- (void)leftPressed:(id)sender
{
	[[RemoteConnectorObject sharedRemoteConnector] sendButton: kButtonCodeLeft];
}

- (void)rightPressed:(id)sender
{
	[[RemoteConnectorObject sharedRemoteConnector] sendButton: kButtonCodeRight];
}

- (void)onePressed:(id)sender
{
	[[RemoteConnectorObject sharedRemoteConnector] sendButton: kButtonCode1];
}

- (void)twoPressed:(id)sender
{
	[[RemoteConnectorObject sharedRemoteConnector] sendButton: kButtonCode2];
}

- (void)threePressed:(id)sender
{
	[[RemoteConnectorObject sharedRemoteConnector] sendButton: kButtonCode3];
}

- (void)fourPressed:(id)sender
{
	[[RemoteConnectorObject sharedRemoteConnector] sendButton: kButtonCode4];
}

- (void)fivePressed:(id)sender
{
	[[RemoteConnectorObject sharedRemoteConnector] sendButton: kButtonCode5];
}

- (void)sixPressed:(id)sender
{
	[[RemoteConnectorObject sharedRemoteConnector] sendButton: kButtonCode6];
}

- (void)sevenPressed:(id)sender
{
	[[RemoteConnectorObject sharedRemoteConnector] sendButton: kButtonCode7];
}

- (void)eightPressed:(id)sender
{
	[[RemoteConnectorObject sharedRemoteConnector] sendButton: kButtonCode8];
}

- (void)ninePressed:(id)sender
{
	[[RemoteConnectorObject sharedRemoteConnector] sendButton: kButtonCode9];
}

- (void)zeroPressed:(id)sender
{
	[[RemoteConnectorObject sharedRemoteConnector] sendButton: kButtonCode0];
}

- (void)leftArrowPressed:(id)sender
{
	[[RemoteConnectorObject sharedRemoteConnector] sendButton: kButtonCodePrevious];
}

- (void)rightArrowPressed:(id)sender
{
	[[RemoteConnectorObject sharedRemoteConnector] sendButton: kButtonCodeNext];
}

- (void)volUpPressed:(id)sender
{
	[[RemoteConnectorObject sharedRemoteConnector] sendButton: kButtonCodeVolUp];
}

- (void)volDownPressed:(id)sender
{
	[[RemoteConnectorObject sharedRemoteConnector] sendButton: kButtonCodeVolDown];
}

- (void)bouquetUpPressed:(id)sender
{
	[[RemoteConnectorObject sharedRemoteConnector] sendButton: kButtonCodeBouquetUp];
}

- (void)bouquetDownPressed:(id)sender
{
	[[RemoteConnectorObject sharedRemoteConnector] sendButton: kButtonCodeBouquetDown];
}

- (void)lamePressed:(id)sender
{
	[[RemoteConnectorObject sharedRemoteConnector] sendButton: kButtonCodeLame];
}

- (void)mutePressed:(id)sender
{
	[[RemoteConnectorObject sharedRemoteConnector] sendButton: kButtonCodeMute];
}

- (void)redPressed:(id)sender
{
	[[RemoteConnectorObject sharedRemoteConnector] sendButton: kButtonCodeRed];
}

- (void)greenPressed:(id)sender
{
	[[RemoteConnectorObject sharedRemoteConnector] sendButton: kButtonCodeGreen];
}

- (void)yellowPressed:(id)sender
{
	[[RemoteConnectorObject sharedRemoteConnector] sendButton: kButtonCodeYellow];
}

- (void)bluePressed:(id)sender
{
	[[RemoteConnectorObject sharedRemoteConnector] sendButton: kButtonCodeBlue];
}

- (void)tvPressed:(id)sender
{
	[[RemoteConnectorObject sharedRemoteConnector] sendButton: kButtonCodeTV];
}

- (void)radioPressed:(id)sender
{
	[[RemoteConnectorObject sharedRemoteConnector] sendButton: kButtonCodeRadio];
}

- (void)textPressed:(id)sender
{
	[[RemoteConnectorObject sharedRemoteConnector] sendButton: kButtonCodeText];
}

- (void)helpPressed:(id)sender
{
	[[RemoteConnectorObject sharedRemoteConnector] sendButton: kButtonCodeHelp];
}

- (void)infoPressed:(id)sender
{
	[[RemoteConnectorObject sharedRemoteConnector] sendButton: kButtonCodeInfo];
}

- (void)audioPressed:(id)sender
{
	[[RemoteConnectorObject sharedRemoteConnector] sendButton: kButtonCodeAudio];
}

- (void)videoPressed:(id)sender
{
	[[RemoteConnectorObject sharedRemoteConnector] sendButton: kButtonCodeVideo];
}

- (void)menuPressed:(id)sender
{
	[[RemoteConnectorObject sharedRemoteConnector] sendButton: kButtonCodeMenu];
}

@end
