//
//  ControlViewController.m
//  Untitled
//
//  Created by Moritz Venn on 10.03.08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "ControlViewController.h"

//#import "AppDelegateMethods.h"
#import "RemoteConnectorObject.h"
#import "Constants.h"

@implementation ControlViewController

@synthesize volume = _volume;
@synthesize switchControl = _switchControl;
@synthesize slider = _slider;

- (id)init
{
	if (self = [super init])
	{
		self.title = NSLocalizedString(@"Controls", @"");
	}
	return self;
}

- (void)dealloc
{
	[_volume release];
	[_switchControl release];
	[_slider release];

	[super dealloc];
}

- (void)viewWillAppear:(BOOL)animated
{
	[_volume release];
	_volume = [[[RemoteConnectorObject sharedRemoteConnector] getVolume] retain];
	self.switchControl.on = [self.volume ismuted];
	self.slider.value = (float)[self.volume current];

	[super viewWillAppear: animated];

}

+ (UILabel *)fieldLabelWithFrame:(CGRect)frame title:(NSString *)title
{
	UILabel *label = [[[UILabel alloc] initWithFrame:frame] autorelease];
	
	label.textAlignment = UITextAlignmentLeft;
	label.text = title;
	label.font = [UIFont boldSystemFontOfSize:17.0];
	label.textColor = [UIColor colorWithRed:76.0/255.0 green:86.0/255.0 blue:108.0/255.0 alpha:1.0];
	label.backgroundColor = [UIColor clearColor];

	return label;
}

- (void)loadView
{
	UIColor *backgroundColor = [UIColor colorWithRed:197.0/255.0 green:204.0/255.0 blue:211.0/255.0 alpha:1.0];

	// setup our parent content view and embed it to your view controller
	UIView *contentView = [[UIView alloc] initWithFrame:[[UIScreen mainScreen] applicationFrame]];
	contentView.backgroundColor = backgroundColor;
	self.view = contentView;
	[contentView release];

	// make sure our subview autoresize in case you decide to support rotated orientations
	self.view.autoresizesSubviews = YES;	

	CGFloat yCoord = kTopMargin;

	// XXX: we might want to make volume control more webif-like (left aligned slider next to a button to mute)

	// create a label for our volume slider (should fix the color though)
	CGRect frame = CGRectMake(kLeftMargin,
						yCoord,
						self.view.bounds.size.width - kRightMargin - kLeftMargin,
						kLabelHeight);
	[self.view addSubview:[ControlViewController fieldLabelWithFrame:frame title:NSLocalizedString(@"Volume:", @"")]];

	// Volume
	yCoord += kLabelHeight;

	frame = CGRectMake(kLeftMargin,
						yCoord,
						self.view.bounds.size.width - kRightMargin - kLeftMargin,
						kSliderHeight);
	_slider = [[UISlider alloc] initWithFrame:frame];
	[_slider addTarget:self action:@selector(volumeChanged:) forControlEvents:UIControlEventTouchUpInside];
	// in case the parent view draws with a custom color or gradient, use a transparent color
	_slider.backgroundColor = [UIColor clearColor];
	_slider.minimumValue = 0.0;
	_slider.maximumValue = 100.0;
	_slider.continuous = YES;
	_slider.value = 50.0;
	[self.view addSubview:_slider];

	// create a label for our muted switch (should fix the color though)
	yCoord += kSliderHeight + kTweenMargin*2;

	frame = CGRectMake(kLeftMargin,
						yCoord,
						self.view.bounds.size.width - kRightMargin - kLeftMargin,
						kLabelHeight);
	[self.view addSubview:[ControlViewController fieldLabelWithFrame:frame title:NSLocalizedString(@"Mute:", @"")]];

	// Muted
	yCoord += kLabelHeight;

	frame = CGRectMake(kLeftMargin + 96.0,
						yCoord,
						kSwitchButtonWidth,
						kSwitchButtonHeight);
	_switchControl = [[UISwitch alloc] initWithFrame:frame];
	[_switchControl addTarget:self action:@selector(toggleMuted:) forControlEvents:UIControlEventTouchUpInside];
	// in case the parent view draws with a custom color or gradient, use a transparent color
	_switchControl.backgroundColor = [UIColor clearColor];
	[self.view addSubview:_switchControl];

	// Standby
	yCoord += kSwitchButtonHeight + kTweenMargin*3;

	UIButton *roundedButtonType = [UIButton buttonWithType:UIButtonTypeRoundedRect];
	roundedButtonType.frame = CGRectMake(	(self.view.bounds.size.width - kWideButtonWidth) / 2.0,
											yCoord,
											kWideButtonWidth,
											kStdButtonHeight);
	roundedButtonType.backgroundColor = backgroundColor;
	[roundedButtonType setTitle:NSLocalizedString(@"Standby", @"") forState:UIControlStateNormal];
	[roundedButtonType addTarget:self action:@selector(standby:) forControlEvents:UIControlEventTouchUpInside];
	[self.view addSubview: roundedButtonType];

	// Reboot
	yCoord += kStdButtonHeight + kTweenMargin;

	roundedButtonType = [UIButton buttonWithType:UIButtonTypeRoundedRect];
	roundedButtonType.frame = CGRectMake(	(self.view.bounds.size.width - kWideButtonWidth) / 2.0,
											yCoord,
											kWideButtonWidth,
											kStdButtonHeight);
	roundedButtonType.backgroundColor = backgroundColor;
	[roundedButtonType setTitle:NSLocalizedString(@"Reboot", @"") forState:UIControlStateNormal];
	[roundedButtonType addTarget:self action:@selector(reboot:) forControlEvents:UIControlEventTouchUpInside];
	[self.view addSubview: roundedButtonType];

	// Restart
	yCoord += kStdButtonHeight + kTweenMargin;

	roundedButtonType = [UIButton buttonWithType:UIButtonTypeRoundedRect];
	roundedButtonType.frame = CGRectMake(	(self.view.bounds.size.width - kWideButtonWidth) / 2.0,
											yCoord,
											kWideButtonWidth,
											kStdButtonHeight);
	roundedButtonType.backgroundColor = backgroundColor;
	[roundedButtonType setTitle:NSLocalizedString(@"Restart", @"") forState:UIControlStateNormal];
	[roundedButtonType addTarget:self action:@selector(restart:) forControlEvents:UIControlEventTouchUpInside];
	[self.view addSubview: roundedButtonType];

	// Shutdown
	yCoord += kStdButtonHeight + kTweenMargin;

	roundedButtonType = [UIButton buttonWithType:UIButtonTypeRoundedRect];
	roundedButtonType.frame = CGRectMake(	(self.view.bounds.size.width - kWideButtonWidth) / 2.0,
											yCoord,
											kWideButtonWidth,
											kStdButtonHeight);
	roundedButtonType.backgroundColor = backgroundColor;
	[roundedButtonType setTitle:NSLocalizedString(@"Shutdown", @"") forState:UIControlStateNormal];
	[roundedButtonType addTarget:self action:@selector(shutdown:) forControlEvents:UIControlEventTouchUpInside];
	[self.view addSubview: roundedButtonType];
}

// TODO: try to merge :-)

- (void)standby:(id)sender
{
	[[RemoteConnectorObject sharedRemoteConnector] standby];
}

- (void)reboot:(id)sender
{
	[[RemoteConnectorObject sharedRemoteConnector] reboot];
}

- (void)restart:(id)sender
{
	[[RemoteConnectorObject sharedRemoteConnector] restart];
}

- (void)shutdown:(id)sender
{
	[[RemoteConnectorObject sharedRemoteConnector] shutdown];
}

- (void)toggleMuted:(id)sender
{
	[_switchControl setOn: [[RemoteConnectorObject sharedRemoteConnector] toggleMuted]];
}

- (void)volumeChanged:(id)sender
{
	// XXX: this is called twice (wtf?) but we ignore this for now
	[[RemoteConnectorObject sharedRemoteConnector] setVolume:(int)[(UISlider*)sender value]];
}

@end
