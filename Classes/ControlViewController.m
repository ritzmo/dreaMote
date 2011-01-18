//
//  ControlViewController.m
//  dreaMote
//
//  Created by Moritz Venn on 10.03.08.
//  Copyright 2008-2011 Moritz Venn. All rights reserved.
//

#import "ControlViewController.h"

#import "RemoteConnectorObject.h"
#import "Constants.h"

#import "DisplayCell.h"

#import "Volume.h"

@interface ControlViewController()
/*!
 @brief start recording
 @param sender ui element
 */
- (void)record:(id)sender;

/*!
 @brief send receiver to standby
 @param sender ui element
 */
- (void)standby:(id)sender;

/*!
 @brief initiate reboot
 @param sender ui element
 */
- (void)reboot:(id)sender;

/*!
 @brief initiate restart of gui
 @param sender ui element
 */
- (void)restart:(id)sender;

/*!
 @brief initiate shutdown
 @param sender ui element
 */
-(void)shutdown:(id)sender;

/*!
 @brief toggle muted state
 @param sender ui element
 */
- (void)toggleMuted:(id)sender;

/*!
 @brief change volume
 @param volumeSlider ui element
 */
- (void)volumeChanged:(UISlider *)volumeSlider;
@end

@implementation ControlViewController

@synthesize switchControl = _switchControl;
@synthesize slider = _slider;

/* initialize */
- (id)init
{
	if((self = [super init]))
	{
		self.title = NSLocalizedString(@"Controls", @"Title of ControlViewController");
	}
	return self;
}

/* dealloc */
- (void)dealloc
{
	[_switchControl release];
	[_slider release];

	[super dealloc];
}

/* initiate download of volume state */
- (void)fetchVolume
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

	[[RemoteConnectorObject sharedRemoteConnector] getVolume: self];

	[pool release];
}

/* volume received */
- (void)addVolume: (GenericVolume *)volume
{
	if(volume == nil)
		return;

	_switchControl.on = volume.ismuted;
	_slider.value = (float)(volume.current);
}

/* layout */
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
	_slider.autoresizingMask = UIViewAutoresizingFlexibleWidth;

	_slider.minimumValue = 0;
	_slider.maximumValue = (float)[[RemoteConnectorObject sharedRemoteConnector] getMaxVolume];
	_slider.continuous = NO;

	// Muted
	_switchControl = [[UISwitch alloc] initWithFrame: CGRectMake(0, 0, 300, kSwitchButtonHeight)];
	[_switchControl addTarget:self action:@selector(toggleMuted:) forControlEvents:UIControlEventValueChanged];

	// in case the parent view draws with a custom color or gradient, use a transparent color
	_switchControl.backgroundColor = [UIColor clearColor];
}

- (UIButton *)createButton:(SEL)selector withImage:(NSString *)imageName
{
	UIButton *button = [[UIButton alloc] initWithFrame: CGRectMake(0, 0, kUIRowHeight, kUIRowHeight)];
	UIImage *image = [UIImage imageNamed:imageName];
	[button setImage:image forState:UIControlStateNormal];
	[button addTarget:self action:selector forControlEvents:UIControlEventTouchUpInside];
	
	return [button autorelease];
}

/* start recording */
- (void)record:(id)sender
{
	NSIndexPath *indexPath = [NSIndexPath indexPathForRow: 0 inSection: 1];
	[(UITableView *)self.view selectRowAtIndexPath: indexPath animated: YES scrollPosition: UITableViewScrollPositionNone];
	Result *result = [[RemoteConnectorObject sharedRemoteConnector] instantRecord];
	[(UITableView *)self.view deselectRowAtIndexPath: indexPath animated: YES];

	if(!result.result)
	{
		const UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Failed to start instant record", @"")
															  message:result.resulttext
															 delegate:nil
													cancelButtonTitle:@"OK"
													otherButtonTitles:nil];
		[alert show];
		[alert release];
	}
}

// TODO: we might want to merge these by using a custom button... targeting the remote connector directly does not work!
/* go to standby */
- (void)standby:(id)sender
{
	const NSInteger section = [[RemoteConnectorObject sharedRemoteConnector] hasFeature: kFeaturesInstantRecord] ? 2 : 1;
	NSIndexPath *indexPath = [NSIndexPath indexPathForRow: 0 inSection: section];
	[(UITableView *)self.view selectRowAtIndexPath: indexPath animated:YES scrollPosition:UITableViewScrollPositionNone];
	[[RemoteConnectorObject sharedRemoteConnector] standby];
	[(UITableView *)self.view deselectRowAtIndexPath:indexPath animated:YES];
}

/* reboot */
- (void)reboot:(id)sender
{
	const NSInteger section = [[RemoteConnectorObject sharedRemoteConnector] hasFeature: kFeaturesInstantRecord] ? 2 : 1;
	NSIndexPath *indexPath = [NSIndexPath indexPathForRow: 1 inSection: section];
	[(UITableView *)self.view selectRowAtIndexPath: indexPath animated:YES scrollPosition:UITableViewScrollPositionNone];
	[[RemoteConnectorObject sharedRemoteConnector] reboot];
	[(UITableView *)self.view deselectRowAtIndexPath:indexPath animated:YES];
}

/* restart gui */
- (void)restart:(id)sender
{
	const NSInteger section = [[RemoteConnectorObject sharedRemoteConnector] hasFeature: kFeaturesInstantRecord] ? 2 : 1;
	NSIndexPath *indexPath = [NSIndexPath indexPathForRow: 2 inSection: section];
	[(UITableView *)self.view selectRowAtIndexPath: indexPath animated:YES scrollPosition:UITableViewScrollPositionNone];
	[[RemoteConnectorObject sharedRemoteConnector] restart];
	[(UITableView *)self.view deselectRowAtIndexPath:indexPath animated:YES];
}

/* shutdown */
-(void)shutdown:(id)sender
{
	const NSInteger section = [[RemoteConnectorObject sharedRemoteConnector] hasFeature: kFeaturesInstantRecord] ? 2 : 1;
	const NSInteger row = [[RemoteConnectorObject sharedRemoteConnector] hasFeature: kFeaturesGUIRestart] ? 3: 2;
	NSIndexPath *indexPath = [NSIndexPath indexPathForRow: row inSection: section];
	[(UITableView *)self.view selectRowAtIndexPath: indexPath animated:YES scrollPosition:UITableViewScrollPositionNone];
	[[RemoteConnectorObject sharedRemoteConnector] shutdown];
	[(UITableView *)self.view deselectRowAtIndexPath:indexPath animated:YES];
}

/* toggle muted state */
- (void)toggleMuted:(id)sender
{
	[_switchControl setOn: [[RemoteConnectorObject sharedRemoteConnector] toggleMuted]];
}

/* change volume */
- (void)volumeChanged:(UISlider *)volumeSlider
{
	[[RemoteConnectorObject sharedRemoteConnector] setVolume:(NSInteger)[volumeSlider value]];
}

/* rotate with device */
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	return YES;
}

#pragma mark - UITableView delegates

/* select row */
- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	const UITableViewCell *cell = [tableView cellForRowAtIndexPath: indexPath];
	if([cell respondsToSelector: @selector(view)]
	   && [((DisplayCell *)cell).view respondsToSelector:@selector(sendActionsForControlEvents:)])
	{
		[(UIButton *)((DisplayCell *)cell).view sendActionsForControlEvents: UIControlEventTouchUpInside];
	}
	return nil;
}

/* no editing style for any row */
- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
	return UITableViewCellEditingStyleNone;
}

/* number of sections */
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	if([[RemoteConnectorObject sharedRemoteConnector] hasFeature: kFeaturesInstantRecord])
		return 3;
	return 2;
}

/* section titles */
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

/* number of rows */
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

/* determine which UITableViewCell to be used on a given row. */
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
				sourceCell.selectionStyle = UITableViewCellSelectionStyleBlue;
				sourceCell.nameLabel.text = NSLocalizedString(@"Instant Record", @"");
				sourceCell.view = [self createButton:@selector(record:) withImage:@"document-save.png"];
				break;
			}
		case 2:
			sourceCell.selectionStyle = UITableViewCellSelectionStyleBlue;
			switch (indexPath.row){
				case 0:
					sourceCell.nameLabel.text = NSLocalizedString(@"Standby", @"");
					sourceCell.view = [self createButton:@selector(standby:) withImage:@"preferences-desktop-screensaver.png"];
					break;
				case 1:
					sourceCell.nameLabel.text = NSLocalizedString(@"Reboot", @"");
					sourceCell.view = [self createButton:@selector(reboot:) withImage:@"view-refresh.png"];
					break;
				case 2:
					if([[RemoteConnectorObject sharedRemoteConnector] hasFeature: kFeaturesGUIRestart])
					{
						sourceCell.nameLabel.text = NSLocalizedString(@"Restart", @"");
						sourceCell.view = [self createButton:@selector(restart:) withImage:@"view-refresh.png"];
						break;
					}
				case 3:
					sourceCell.nameLabel.text = NSLocalizedString(@"Shutdown", @"");
					sourceCell.view = [self createButton:@selector(shutdown:) withImage:@"system-shutdown.png"];
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

#pragma mark - UIViewController delegate methods

/* about to appear */
- (void)viewWillAppear:(BOOL)animated
{
	// Spawn a thread to fetch the volume data so that the UI is not blocked while the 
	// application parses the XML file.
	[NSThread detachNewThreadSelector:@selector(fetchVolume) toTarget:self withObject:nil];
	
	[super viewWillAppear: animated];
}

/* did disappear */
- (void)viewDidDisappear:(BOOL)animated
{
	[super viewDidDisappear:animated];
}

@end
