//
//  ControlViewController.m
//  dreaMote
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

- (UIButton *)create_InstantRecordButton
{
	UIButton *button = [[UIButton alloc] initWithFrame: CGRectMake(0.0, 0.0, kUIRowHeight, kUIRowHeight)];
	//UIImage *image = [UIImage imageNamed:@"preferences-desktop-screensaver.png"];
	//[button setImage:image forState:UIControlStateNormal];
	[button addTarget:self action:@selector(record:) forControlEvents:UIControlEventTouchUpInside];
	
	return [button autorelease];
}

- (UIButton *)create_StandbyButton
{
	UIButton *button = [[UIButton alloc] initWithFrame: CGRectMake(0.0, 0.0, kUIRowHeight, kUIRowHeight)];
	UIImage *image = [UIImage imageNamed:@"preferences-desktop-screensaver.png"];
	[button setImage:image forState:UIControlStateNormal];
	[button addTarget:self action:@selector(standby:) forControlEvents:UIControlEventTouchUpInside];

	return [button autorelease];
}

- (UIButton *)create_RebootButton
{
	UIButton *button = [[UIButton alloc] initWithFrame: CGRectMake(0.0, 0.0, kUIRowHeight, kUIRowHeight)];
	UIImage *image = [UIImage imageNamed:@"view-refresh.png"];
	[button setImage:image forState:UIControlStateNormal];
	[button addTarget:self action:@selector(reboot:) forControlEvents:UIControlEventTouchUpInside];

	return [button autorelease];
}

- (UIButton *)create_RestartButton
{
	UIButton *button = [[UIButton alloc] initWithFrame: CGRectMake(0.0, 0.0, kUIRowHeight, kUIRowHeight)];
	UIImage *image = [UIImage imageNamed:@"view-refresh.png"];
	[button setImage:image forState:UIControlStateNormal];
	[button addTarget:self action:@selector(restart:) forControlEvents:UIControlEventTouchUpInside];

	return [button autorelease];
}

- (UIButton *)create_ShutdownButton
{
	UIButton *button = [[UIButton alloc] initWithFrame: CGRectMake(0.0, 0.0, kUIRowHeight, kUIRowHeight)];
	UIImage *image = [UIImage imageNamed:@"system-shutdown.png"];
	[button setImage:image forState:UIControlStateNormal];
	[button addTarget:self action:@selector(shutdown:) forControlEvents:UIControlEventTouchUpInside];
	
	return [button autorelease];
}

- (void)record:(id)sender
{
	NSIndexPath *indexPath = [NSIndexPath indexPathForRow: 0 inSection: 1];
	[(UITableView *)self.view selectRowAtIndexPath: indexPath animated: YES scrollPosition: UITableViewScrollPositionNone];
	[[RemoteConnectorObject sharedRemoteConnector] instantRecord];
	[(UITableView *)self.view deselectRowAtIndexPath: indexPath animated: YES];
}

// XXX: we might want to merge these by using a custom button... targeting the remote connector directly does not work!
- (void)standby:(id)sender
{
	NSInteger section = [[RemoteConnectorObject sharedRemoteConnector] hasFeature: kFeaturesInstantRecord] ? 2 : 1;
	NSIndexPath *indexPath = [NSIndexPath indexPathForRow: 0 inSection: section];
	[(UITableView *)self.view selectRowAtIndexPath: indexPath animated:YES scrollPosition:UITableViewScrollPositionNone];
	[[RemoteConnectorObject sharedRemoteConnector] standby];
	[(UITableView *)self.view deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)reboot:(id)sender
{
	NSInteger section = [[RemoteConnectorObject sharedRemoteConnector] hasFeature: kFeaturesInstantRecord] ? 2 : 1;
	NSIndexPath *indexPath = [NSIndexPath indexPathForRow: 1 inSection: section];
	[(UITableView *)self.view selectRowAtIndexPath: indexPath animated:YES scrollPosition:UITableViewScrollPositionNone];
	[[RemoteConnectorObject sharedRemoteConnector] reboot];
	[(UITableView *)self.view deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)restart:(id)sender
{
	NSInteger section = [[RemoteConnectorObject sharedRemoteConnector] hasFeature: kFeaturesInstantRecord] ? 2 : 1;
	NSIndexPath *indexPath = [NSIndexPath indexPathForRow: 2 inSection: section];
	[(UITableView *)self.view selectRowAtIndexPath: indexPath animated:YES scrollPosition:UITableViewScrollPositionNone];
	[[RemoteConnectorObject sharedRemoteConnector] restart];
	[(UITableView *)self.view deselectRowAtIndexPath:indexPath animated:YES];
}

-(void)shutdown:(id)sender
{
	NSInteger section = [[RemoteConnectorObject sharedRemoteConnector] hasFeature: kFeaturesInstantRecord] ? 2 : 1;
	NSIndexPath *indexPath;
	if([[RemoteConnectorObject sharedRemoteConnector] hasFeature: kFeaturesGUIRestart])
		indexPath = [NSIndexPath indexPathForRow: 3 inSection: section];
	else
		indexPath = [NSIndexPath indexPathForRow: 2 inSection: section];
	[(UITableView *)self.view selectRowAtIndexPath: indexPath animated:YES scrollPosition:UITableViewScrollPositionNone];
	[[RemoteConnectorObject sharedRemoteConnector] shutdown];
	[(UITableView *)self.view deselectRowAtIndexPath:indexPath animated:YES];
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

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	// XXX: this is kinda hackish
	UITableViewCell *cell = [tableView cellForRowAtIndexPath: indexPath];
	@try {
		[((UIControl *)((DisplayCell *)cell).view) sendActionsForControlEvents: UIControlEventTouchUpInside];
	}
	@catch (NSException * e) {
		//
	}
	return nil;
}

// if you want the entire table to just be re-orderable then just return UITableViewCellEditingStyleNone
//
- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
	return UITableViewCellEditingStyleNone;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	if([[RemoteConnectorObject sharedRemoteConnector] hasFeature: kFeaturesInstantRecord])
		return 3;
	return 2;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
	switch (section) {
		case 0:
			return NSLocalizedString(@"Volume", @"");
		case 1:
			if([[RemoteConnectorObject sharedRemoteConnector] hasFeature: kFeaturesInstantRecord])
				return NSLocalizedString(@"Record", @"");
		case 2:
			return NSLocalizedString(@"Power", @"");
		default:
			return nil;
	}
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	switch(section) {
		case 0:
			return 2;
		case 1:
			if([[RemoteConnectorObject sharedRemoteConnector] hasFeature: kFeaturesInstantRecord])
				return 1;
		case 2:
			if([[RemoteConnectorObject sharedRemoteConnector] hasFeature: kFeaturesGUIRestart])
				return 4;
			return 3;
		default:
			return 0;
	}
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
			sourceCell.selectionStyle = UITableViewCellSelectionStyleNone;
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
			if([[RemoteConnectorObject sharedRemoteConnector] hasFeature: kFeaturesInstantRecord])
			{
				sourceCell.nameLabel.text = NSLocalizedString(@"Instant Record", @"");
				sourceCell.view = [self create_InstantRecordButton];
				break;
			}
		case 2:
			sourceCell.selectionStyle = UITableViewCellSelectionStyleBlue;
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
