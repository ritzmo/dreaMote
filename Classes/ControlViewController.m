//
//  ControlViewController.m
//  Untitled
//
//  Created by Moritz Venn on 10.03.08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "ControlViewController.h"

#import "RemoteConnectorObject.h"
#import "Constants.h"

#import "DisplayCell.h"

#import "Volume.h"

@implementation ControlViewController

@synthesize switchControl = _switchControl;
@synthesize slider = _slider;

- (id)init
{
	if (self = [super init])
	{
		self.title = NSLocalizedString(@"Controls", @"Title of ControlViewController");
	}
	return self;
}

- (void)dealloc
{
	[_switchControl release];
	[_slider release];

	[super dealloc];
}

- (void)viewWillAppear:(BOOL)animated
{
	// Spawn a thread to fetch the volume data so that the UI is not blocked while the 
	// application parses the XML file.
	[NSThread detachNewThreadSelector:@selector(fetchVolume) toTarget:self withObject:nil];

	[super viewWillAppear: animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
	[super viewDidDisappear:animated];
}

- (void)fetchVolume
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

	[[RemoteConnectorObject sharedRemoteConnector] getVolume:self action:@selector(gotVolume:)];

	[pool release];
}

- (void)gotVolume:(id)newVolume
{
	if(newVolume == nil)
		return;

	Volume *volume = (Volume*)newVolume; // just for convenience

	_switchControl.on = volume.ismuted;
	_slider.value = (float)(volume.current);
}

- (void)loadView
{
	// create and configure the table view
	UITableView *tableView = [[UITableView alloc] initWithFrame:[[UIScreen mainScreen] applicationFrame] style:UITableViewStyleGrouped];	
	tableView.delegate = self;
	tableView.dataSource = self;
	tableView.rowHeight = kUIRowHeight;

	// setup our content view so that it auto-rotates along with the UViewController
	tableView.autoresizesSubviews = YES;
	tableView.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);

	self.view = tableView;
	[tableView release];

	// Volume
	_slider = [[UISlider alloc] initWithFrame: CGRectMake(0,0, 280, kSliderHeight)];
	[_slider addTarget:self action:@selector(volumeChanged:) forControlEvents:UIControlEventValueChanged];

	// in case the parent view draws with a custom color or gradient, use a transparent color
	_slider.backgroundColor = [UIColor clearColor];

	_slider.minimumValue = 0.0;
	_slider.maximumValue = (float)[[RemoteConnectorObject sharedRemoteConnector] getMaxVolume];
	_slider.continuous = NO;

	// Muted
	_switchControl = [[UISwitch alloc] initWithFrame: CGRectMake(0, 0, 300, kSwitchButtonHeight)];
	[_switchControl addTarget:self action:@selector(toggleMuted:) forControlEvents:UIControlEventValueChanged];

	// in case the parent view draws with a custom color or gradient, use a transparent color
	_switchControl.backgroundColor = [UIColor clearColor];
}

- (UIButton *)create_StandbyButton
{
	UIButton *roundedButtonType = [UIButton buttonWithType:UIButtonTypeRoundedRect];
	roundedButtonType.frame = CGRectMake(0, 0, 25.0, 25.0);
	[roundedButtonType addTarget:self action:@selector(standby:) forControlEvents:UIControlEventTouchUpInside];

	return roundedButtonType;
}

- (UIButton *)create_RebootButton
{
	UIButton *roundedButtonType = [UIButton buttonWithType:UIButtonTypeRoundedRect];
	roundedButtonType.frame = CGRectMake(0, 0, 25.0, 25.0);
	[roundedButtonType addTarget:self action:@selector(reboot:) forControlEvents:UIControlEventTouchUpInside];

	return roundedButtonType;
}

- (UIButton *)create_RestartButton
{
	UIButton *roundedButtonType = [UIButton buttonWithType:UIButtonTypeRoundedRect];
	roundedButtonType.frame = CGRectMake(0, 0, 25.0, 25.0);
	[roundedButtonType addTarget:self action:@selector(restart:) forControlEvents:UIControlEventTouchUpInside];

	return roundedButtonType;
}

- (UIButton *)create_ShutdownButton
{
	UIButton *roundedButtonType = [UIButton buttonWithType:UIButtonTypeRoundedRect];
	roundedButtonType.frame = CGRectMake(0, 0, 25.0, 25.0);
	[roundedButtonType addTarget:self action:@selector(shutdown:) forControlEvents:UIControlEventTouchUpInside];

	return roundedButtonType;
}

// XXX: these should be merged
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

- (void)volumeChanged:(UISlider *)volumeSlider
{
	[[RemoteConnectorObject sharedRemoteConnector] setVolume:(NSInteger)[volumeSlider value]];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	// Return YES for supported orientations
	return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - UITableView delegates

// if you want the entire table to just be re-orderable then just return UITableViewCellEditingStyleNone
//
- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
	return UITableViewCellEditingStyleNone;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return 2;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
	switch (section) {
		case 0:
			return NSLocalizedString(@"Volume", @"");
		case 1:
			return NSLocalizedString(@"Power", @"");
		default:
			return nil;
	}
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	if(section == 1)
		return ([[RemoteConnectorObject sharedRemoteConnector] hasFeature: kFeaturesGUIRestart]) ? 4 : 3;
	return 2;
}

// to determine which UITableViewCell to be used on a given row.
//
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	DisplayCell *sourceCell = (DisplayCell *)[tableView dequeueReusableCellWithIdentifier:kDisplayCell_ID];
	if(sourceCell == nil)
		sourceCell = [[[DisplayCell alloc] initWithFrame:CGRectZero reuseIdentifier:kDisplayCell_ID] autorelease];

	// we are creating a new cell, setup its attributes
	switch (indexPath.section) {
		case 0:
			if(indexPath.row == 0)
			{
				sourceCell.nameLabel.text = nil;
				sourceCell.view = _slider;
			}
			else
			{
				sourceCell.nameLabel.text = NSLocalizedString(@"Mute", @"");
				sourceCell.view = _switchControl;
			}
			break;
		case 1:
			switch (indexPath.row){
				case 0:
					sourceCell.nameLabel.text = NSLocalizedString(@"Standby", @"");
					sourceCell.view = [self create_StandbyButton];
					break;
				case 1:
					sourceCell.nameLabel.text = NSLocalizedString(@"Reboot", @"");
					sourceCell.view = [self create_RebootButton];
					break;
				case 2:
					if([[RemoteConnectorObject sharedRemoteConnector] hasFeature: kFeaturesGUIRestart])
					{
						sourceCell.nameLabel.text = NSLocalizedString(@"Restart", @"");
						sourceCell.view = [self create_RestartButton];
						break;
					}
				case 3:
					sourceCell.nameLabel.text = NSLocalizedString(@"Shutdown", @"");
					sourceCell.view = [self create_ShutdownButton];
					break;
				default:
					break;
			}
			break;	
		default:
			break;
	}
	
	return sourceCell;
}

@end
