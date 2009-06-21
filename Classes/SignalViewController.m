//
//  SignalViewController.m
//  dreaMote
//
//  Created by Moritz Venn on 15.06.09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "SignalViewController.h"

#import "RemoteConnectorObject.h"
#import "Constants.h"

#import "Signal.h"

#import "DisplayCell.h"

@implementation SignalViewController

- (id)init
{
	if (self = [super init])
	{
		self.title = NSLocalizedString(@"Signal", @"Title of SignalViewController");
	}
	return self;
}

- (void)dealloc
{
	[_snr release];
	[_agc release];
	[_snrdBCell release];
	[_berCell release];

	[_timer invalidate];
	_timer = nil;

	[super dealloc];
}

- (void)viewWillAppear:(BOOL)animated
{
	// XXX: interval should be configurable
	_timer = [NSTimer scheduledTimerWithTimeInterval: 5.0
					target: self selector:@selector(fetchSignalDefer)
					userInfo: nil repeats: YES];
	[_timer fire];

	[super viewWillAppear: animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
	[_timer invalidate];
	_timer = nil;

	[super viewWillDisappear: animated];
}

- (void)fetchSignalDefer
{
	// Spawn a thread to fetch the signal data so that the UI is not blocked while the 
	// application parses the XML file.
	[NSThread detachNewThreadSelector:@selector(fetchSignal) toTarget:self withObject:nil];
}

- (void)fetchSignal
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

	[[RemoteConnectorObject sharedRemoteConnector] getSignal:self action:@selector(gotSignal:)];

	[pool release];
}

- (void)gotSignal:(id)anObject
{
	if(anObject == nil)
		return;

	Signal *signal = (Signal*)anObject; // just for convenience

	_snr.value = (float)(signal.snr);
	_agc.value = (float)(signal.agc);

	_hasSnrdB = signal.snrdb > -1;
	_snrdBCell.text = [NSString stringWithFormat: @"SNR %.2f dB", signal.snrdb];
	_berCell.text = [NSString stringWithFormat: @"%i BER", signal.ber];

	[(UITableView *)self.view reloadData];
}

- (void)loadView
{
	static NSString *kVanilla_ID = @"Vanilla_ID";

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

	// SNR
	_snr = [[UISlider alloc] initWithFrame: CGRectMake(0,0, 240, kSliderHeight)];

	// in case the parent view draws with a custom color or gradient, use a transparent color
	_snr.backgroundColor = [UIColor clearColor];

	_snr.minimumValue = 0.0;
	_snr.maximumValue = 100.0;
	_snr.continuous = NO;
	_snr.enabled = NO;

	// AGC
	_agc = [[UISlider alloc] initWithFrame: CGRectMake(0,0, 240, kSliderHeight)];

	// in case the parent view draws with a custom color or gradient, use a transparent color
	_agc.backgroundColor = [UIColor clearColor];

	_agc.minimumValue = 0.0;
	_agc.maximumValue = 100.0;
	_agc.continuous = NO;
	_agc.enabled = NO;

	// SNRdB
	UITableViewCell *sourceCell = [tableView dequeueReusableCellWithIdentifier: kVanilla_ID];
	if (sourceCell == nil) 
		sourceCell = [[[UITableViewCell alloc] initWithFrame: CGRectZero reuseIdentifier: kVanilla_ID] autorelease];
	
	sourceCell.textAlignment = UITextAlignmentCenter;
	sourceCell.textColor = [UIColor blackColor];
	sourceCell.font = [UIFont systemFontOfSize:kTextViewFontSize];
	sourceCell.selectionStyle = UITableViewCellSelectionStyleNone;
	sourceCell.indentationLevel = 1;
	_snrdBCell = [sourceCell retain];

	// BER
	sourceCell = [tableView dequeueReusableCellWithIdentifier: kVanilla_ID];
	if (sourceCell == nil) 
		sourceCell = [[[UITableViewCell alloc] initWithFrame: CGRectZero reuseIdentifier: kVanilla_ID] autorelease];
	
	sourceCell.textAlignment = UITextAlignmentCenter;
	sourceCell.textColor = [UIColor blackColor];
	sourceCell.font = [UIFont systemFontOfSize:kTextViewFontSize];
	sourceCell.selectionStyle = UITableViewCellSelectionStyleNone;
	sourceCell.indentationLevel = 1;
	_berCell = [sourceCell retain];
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
	if(section == 0)
		return NSLocalizedString(@"Percentage", @"");
	return NSLocalizedString(@"Exact", @"");	
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	if(section == 0)
		return 2;
	if(_hasSnrdB)
		return 2;
	return 1;
}

// to determine which UITableViewCell to be used on a given row.
//
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	UITableViewCell *sourceCell = nil;

	// we are creating a new cell, setup its attributes
	switch (indexPath.section) {
		case 0:
			sourceCell = [tableView dequeueReusableCellWithIdentifier:kDisplayCell_ID];
			if(sourceCell == nil)
				sourceCell = [[[DisplayCell alloc] initWithFrame:CGRectZero reuseIdentifier:kDisplayCell_ID] autorelease];

			sourceCell.selectionStyle = UITableViewCellSelectionStyleNone;
			if(indexPath.row == 0)
			{
				((DisplayCell *)sourceCell).nameLabel.text = NSLocalizedString(@"SNR", @"");
				((DisplayCell *)sourceCell).view = _snr;
			}
			else
			{
				((DisplayCell *)sourceCell).nameLabel.text = NSLocalizedString(@"AGC", @"");
				((DisplayCell *)sourceCell).view = _agc;
			}
			break;
		case 1:
			if(_hasSnrdB && indexPath.row == 0)
				sourceCell = _snrdBCell;
			else
				sourceCell = _berCell;
			break;
		default:
			break;
	}
	
	return sourceCell;
}

@end
