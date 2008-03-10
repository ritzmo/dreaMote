//
//  ControlViewController.m
//  Untitled
//
//  Created by Moritz Venn on 10.03.08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "ControlViewController.h"

#import "AppDelegateMethods.h"
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
	// TODO: we might need to clean up our old timer list or cache results and reload only in certain situations
	id applicationDelegate = [[UIApplication sharedApplication] delegate];
	self.volume = [applicationDelegate getVolume];
	self.switchControl.on = ([[self.volume ismuted] isLike: @"True"]) ? YES: NO;
	self.slider.value = [[self.volume current] floatValue];

	[super viewWillAppear: animated];

}


- (void)loadView
{
	// setup our parent content view and embed it to your view controller
	UIView *contentView = [[UIView alloc] initWithFrame:[[UIScreen mainScreen] applicationFrame]];
	contentView.backgroundColor = [UIColor blackColor];
	self.view = contentView;
	[contentView release];

	// make sure our subview autoresize in case you decide to support rotated orientations
	self.view.autoresizesSubviews = YES;	

	CGFloat yCoord = kTopMargin;

	// create a label for our volume slider (should fix the color though)
	CGRect frame = CGRectMake(kLeftMargin, yCoord, self.view.bounds.size.width - kRightMargin - kLeftMargin, kLabelHeight);
	UILabel *label = [[UILabel alloc] initWithFrame:frame];
	label.textAlignment = UITextAlignmentLeft;
	label.text = NSLocalizedString(@"Volume:", @"");
	label.font = [UIFont boldSystemFontOfSize:17.0];
	label.textColor = [UIColor colorWithRed:76.0/255.0 green:86.0/255.0 blue:108.0/255.0 alpha:1.0];
	label.backgroundColor = [UIColor clearColor];
	[self.view addSubview:label];
	[label release];

	// Volume
	yCoord += kLabelHeight;

	frame = CGRectMake(kLeftMargin, yCoord, self.view.bounds.size.width - kRightMargin - kLeftMargin, kSliderHeight);
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

	frame = CGRectMake(kLeftMargin, yCoord, self.view.bounds.size.width - kRightMargin - kLeftMargin, kLabelHeight);
	label = [[UILabel alloc] initWithFrame:frame];
	label.textAlignment = UITextAlignmentLeft;
	label.text = NSLocalizedString(@"Mute:", @"");
	label.font = [UIFont boldSystemFontOfSize:17.0];
	label.textColor = [UIColor colorWithRed:76.0/255.0 green:86.0/255.0 blue:108.0/255.0 alpha:1.0];
	label.backgroundColor = [UIColor clearColor];
	[self.view addSubview:label];
	[label release];

	// Muted
	yCoord += kLabelHeight;

	frame = CGRectMake(kLeftMargin + 96.0, yCoord, kSwitchButtonWidth, kSwitchButtonHeight);
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
	[roundedButtonType setTitle:NSLocalizedString(@"Standby", @"") forStates:UIControlStateNormal];
	[roundedButtonType addTarget:self action:@selector(standby:) forControlEvents:UIControlEventTouchUpInside];
	[self.view addSubview: roundedButtonType];

	// Reboot
	yCoord += kStdButtonHeight + kTweenMargin;

	roundedButtonType = [UIButton buttonWithType:UIButtonTypeRoundedRect];
	roundedButtonType.frame = CGRectMake(	(self.view.bounds.size.width - kWideButtonWidth) / 2.0,
											yCoord,
											kWideButtonWidth,
											kStdButtonHeight);
	[roundedButtonType setTitle:NSLocalizedString(@"Reboot", @"") forStates:UIControlStateNormal];
	[roundedButtonType addTarget:self action:@selector(reboot:) forControlEvents:UIControlEventTouchUpInside];
	[self.view addSubview: roundedButtonType];

	// Restart
	yCoord += kStdButtonHeight + kTweenMargin;

	roundedButtonType = [UIButton buttonWithType:UIButtonTypeRoundedRect];
	roundedButtonType.frame = CGRectMake(	(self.view.bounds.size.width - kWideButtonWidth) / 2.0,
											yCoord,
											kWideButtonWidth,
											kStdButtonHeight);
	[roundedButtonType setTitle:NSLocalizedString(@"Restart", @"") forStates:UIControlStateNormal];
	[roundedButtonType addTarget:self action:@selector(restart:) forControlEvents:UIControlEventTouchUpInside];
	[self.view addSubview: roundedButtonType];

	// Shutdown
	yCoord += kStdButtonHeight + kTweenMargin;

	roundedButtonType = [UIButton buttonWithType:UIButtonTypeRoundedRect];
	roundedButtonType.frame = CGRectMake(	(self.view.bounds.size.width - kWideButtonWidth) / 2.0,
											yCoord,
											kWideButtonWidth,
											kStdButtonHeight);
	[roundedButtonType setTitle:NSLocalizedString(@"Shutdown", @"") forStates:UIControlStateNormal];
	[roundedButtonType addTarget:self action:@selector(shutdown:) forControlEvents:UIControlEventTouchUpInside];
	[self.view addSubview: roundedButtonType];
}

// TODO: try to merge :-)

- (void)standby:(id)sender
{
	id applicationDelegate = [[UIApplication sharedApplication] delegate];
	[applicationDelegate standby];
}

- (void)reboot:(id)sender
{
	id applicationDelegate = [[UIApplication sharedApplication] delegate];
	[applicationDelegate reboot];
}

- (void)restart:(id)sender
{
	id applicationDelegate = [[UIApplication sharedApplication] delegate];
	[applicationDelegate restart];
}

- (void)shutdown:(id)sender
{
	id applicationDelegate = [[UIApplication sharedApplication] delegate];
	[applicationDelegate shutdown];
}

- (void)toggleMuted:(id)sender
{
	id applicationDelegate = [[UIApplication sharedApplication] delegate];
	[applicationDelegate toggleMuted];
}

- (void)volumeChanged:(id)sender
{
	// XXX: this is called twice (wtf?) but we ignore this for now
	//self.volume.current = [NSString stringWithFormat: @"%f", [(UISlider*)sender value]];

	id applicationDelegate = [[UIApplication sharedApplication] delegate];
	[applicationDelegate setVolume:(int)[(UISlider*)sender value]];
}

@end
