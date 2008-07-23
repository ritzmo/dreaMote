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
	
	const CGFloat imageWidth = 45;
	const CGFloat imageHeight = 35;
	CGFloat currX;
	CGFloat currY;

	// ok
	//frame = CGRectMake(0, 0, imageWidth, imageHeight);
	//roundedButtonType = [self customButton:frame withImage:@"key_ok.png" action:@selector(onePressed:)];
	//[self.view addSubview: roundedButtonType];
	
	// 1
	currX = kTopMargin;
	currY = kLeftMargin;
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
	currY = kLeftMargin;
	
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
	currY = kLeftMargin;
	
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
	currY = kLeftMargin;
	
	// <
	//frame = CGRectMake(currY, currX, imageWidth, imageHeight);
	//roundedButtonType = [self customButton:frame withImage:@"key_left.png" action:@selector(leftPressed:)];
	//[self.view addSubview: roundedButtonType];
	currY += imageWidth + kTweenMargin;
	
	// 0
	frame = CGRectMake(currY, currX, imageWidth, imageHeight);
	roundedButtonType = [self customButton:frame withImage:@"key_0.png" action:@selector(zeroPressed:)];
	[self.view addSubview: roundedButtonType];
	currY += imageWidth + kTweenMargin;
	
	// >
	//frame = CGRectMake(currY, currX, imageWidth, imageHeight);
	//roundedButtonType = [self customButton:frame withImage:@"key_right.png" action:@selector(rightPressed:)];
	//[self.view addSubview: roundedButtonType];
	currY += imageWidth + kTweenMargin;
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


@end
