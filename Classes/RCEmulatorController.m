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
- (UIButton*)customButton:(CGRect)frame withAction:(SEL)action andImage:(NSString*)image;
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
	
	CGFloat yCoord = kTopMargin;
	CGFloat xCoord = (self.view.bounds.size.width - kWideButtonWidth) / 2.0;
	CGRect frame;
	UIButton *roundedButtonType;

	// add ok button
	frame = CGRectMake(xCoord, yCoord, kWideButtonWidth, kStdButtonHeight);
	roundedButtonType = [self customButton:frame withAction:@selector(okPressed:) andImage:nil];
	//[roundedButtonType setTitle:NSLocalizedString(@"OK", @"") forState:UIControlStateNormal];
	[self.view addSubview: roundedButtonType];
}

- (UIButton*)customButton:(CGRect)frame withAction:(SEL)action andImage:(NSString*)image
{
	UIButton *roundedButtonType = [UIButton buttonWithType:UIButtonTypeRoundedRect];
	roundedButtonType.frame = frame;
	//roundedButtonType.backgroundColor = backColor;
	if(image != nil)
		[roundedButtonType setImage:[UIImage imageNamed:image] forState:UIControlStateNormal|UIControlStateHighlighted|UIControlStateDisabled|UIControlStateSelected];
	[roundedButtonType addTarget:self action:action forControlEvents:UIControlEventTouchUpInside];

	return roundedButtonType;
}

- (void)okPressed:(id)sender
{
	[[RemoteConnectorObject sharedRemoteConnector] sendButton: kButtonCodeOK];
}

@end
