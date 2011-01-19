//
//  SignalViewController.m
//  dreaMote
//
//  Created by Moritz Venn on 15.06.09.
//  Copyright 2009-2011 Moritz Venn. All rights reserved.
//

#import "SignalViewController.h"

#import "RemoteConnectorObject.h"
#import "Constants.h"

#import "Signal.h"

#import "DisplayCell.h"

@interface SignalViewController()
/*!
 @brief spawn a new thread to fetch signal data
 This selector is called on a regular basis through the timer that is active
 when the view is in forgeground.
 It simply spawns a new thread to fetch the signal data in background rather
 than in foreground.
 */
- (void)fetchSignalDefer;

/*!
 @brief entry point of thread which fetches signal data
 */
- (void)fetchSignal;
@end

@implementation SignalViewController

- (id)init
{
	if((self = [super init]))
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
	// FIXME: interval should be configurable
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

	[[RemoteConnectorObject sharedRemoteConnector] getSignal: self];

	[pool release];
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

	// SNR
	_snr = [[UISlider alloc] initWithFrame: CGRectMake(0, 0, 240, kSliderHeight)];

	// in case the parent view draws with a custom color or gradient, use a transparent color
	_snr.backgroundColor = [UIColor clearColor];
	_snr.autoresizingMask = UIViewAutoresizingFlexibleWidth;

	_snr.minimumValue = 0;
	_snr.maximumValue = 100;
	_snr.continuous = NO;
	_snr.enabled = NO;

	// AGC
	_agc = [[UISlider alloc] initWithFrame: CGRectMake(0, 0, 240, kSliderHeight)];

	// in case the parent view draws with a custom color or gradient, use a transparent color
	_agc.backgroundColor = [UIColor clearColor];
	_agc.autoresizingMask = UIViewAutoresizingFlexibleWidth;

	_agc.minimumValue = 0;
	_agc.maximumValue = 100;
	_agc.continuous = NO;
	_agc.enabled = NO;

	// SNRdB
	UITableViewCell *sourceCell = [tableView dequeueReusableCellWithIdentifier: kVanilla_ID];
	if (sourceCell == nil) 
		sourceCell = [[[UITableViewCell alloc] initWithFrame: CGRectZero reuseIdentifier: kVanilla_ID] autorelease];
	
	TABLEVIEWCELL_ALIGN(sourceCell) = UITextAlignmentCenter;
	TABLEVIEWCELL_COLOR(sourceCell) = [UIColor blackColor];
	TABLEVIEWCELL_FONT(sourceCell) = [UIFont systemFontOfSize:kTextViewFontSize];
	sourceCell.selectionStyle = UITableViewCellSelectionStyleNone;
	sourceCell.indentationLevel = 1;
	_snrdBCell = [sourceCell retain];

	// BER
	sourceCell = [tableView dequeueReusableCellWithIdentifier: kVanilla_ID];
	if (sourceCell == nil) 
		sourceCell = [[[UITableViewCell alloc] initWithFrame: CGRectZero reuseIdentifier: kVanilla_ID] autorelease];
	
	TABLEVIEWCELL_ALIGN(sourceCell) = UITextAlignmentCenter;
	TABLEVIEWCELL_COLOR(sourceCell) = [UIColor blackColor];
	TABLEVIEWCELL_FONT(sourceCell) = [UIFont systemFontOfSize:kTextViewFontSize];
	sourceCell.selectionStyle = UITableViewCellSelectionStyleNone;
	sourceCell.indentationLevel = 1;
	_berCell = [sourceCell retain];
}

/* rotate with device */
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	return YES;
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

#pragma mark -
#pragma mark DataSourceDelegate
#pragma mark -

- (void)dataSourceDelegate:(BaseXMLReader *)dataSource errorParsingDocument:(CXMLDocument *)document error:(NSError *)error
{
	// Alert user
	const UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Failed to retrieve data", @"")
														  message:[error localizedDescription]
														 delegate:nil
												cancelButtonTitle:@"OK"
												otherButtonTitles:nil];
	[alert show];
	[alert release];

	// stop timer
	[_timer invalidate];
	_timer = nil;
}

- (void)dataSourceDelegate:(BaseXMLReader *)dataSource finishedParsingDocument:(CXMLDocument *)document
{
	[(UITableView *)self.view reloadData];
}

#pragma mark -
#pragma mark SignalSourceDelegate
#pragma mark -

- (void)addSignal: (GenericSignal *)signal
{
	if(signal == nil)
		return;
	
	_snr.value = (float)(signal.snr);
	_agc.value = (float)(signal.agc);
	
	_hasSnrdB = signal.snrdb > -1;
	TABLEVIEWCELL_TEXT(_snrdBCell) = [NSString stringWithFormat: @"SNR %.2f dB", signal.snrdb];
	TABLEVIEWCELL_TEXT(_berCell) = [NSString stringWithFormat: @"%i BER", signal.ber];
}

@end
