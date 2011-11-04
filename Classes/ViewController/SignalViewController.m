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
#import "UITableViewCell+EasyInit.h"

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

/*!
 @brief Start new refresh timer.
 */
- (void)startTimer;

/*!
 @brief Start tone generation.
 @note Does not start tone generation if already running or not enabled.
 */
- (void)startAudio;

/*!
 @brief Stop tone generation.
 */
- (void)stopAudio;

/*!
 @brief Refresh interval was changed.
 @param sender ui element
 */
- (void)intervalChanged:(id)sender;

/*!
 @brief Refresh interval accepted.
 @param sender ui element
 */
- (void)intervalSet:(id)sender;

/*!
 @brief Tone generation started/stopped.
 @param sender ui element
 */
- (void)audioToggleSwitched:(id)sender;
@end

OSStatus RenderTone(
					void *inRefCon,
					AudioUnitRenderActionFlags 	*ioActionFlags,
					const AudioTimeStamp 		*inTimeStamp,
					UInt32 						inBusNumber,
					UInt32 						inNumberFrames,
					AudioBufferList 			*ioData)
{
	// Fixed amplitude is good enough for our purposes
	const double amplitude = 0.25;

	// Get the tone parameters out of the view controller
	SignalViewController *viewController = (__bridge SignalViewController *)inRefCon;
	double theta = viewController->theta;
	double theta_increment = 2.0 * M_PI * viewController->frequency / viewController->sampleRate;

	// This is a mono tone generator so we only need the first buffer
	const int channel = 0;
	Float32 *buffer = (Float32 *)ioData->mBuffers[channel].mData;

	// Generate the samples
	for(UInt32 frame = 0; frame < inNumberFrames; ++frame)
	{
		buffer[frame] = (Float32)(sin(theta) * amplitude);

		theta += theta_increment;
		if (theta > 2.0 * M_PI)
		{
			theta -= 2.0 * M_PI;
		}
	}

	// Store the theta back in the view controller
	viewController->theta = theta;

	return noErr;
}

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
	((UITableView *)self.view).delegate = nil;
	((UITableView *)self.view).dataSource = nil;

	[_timer invalidate];
	_timer = nil;
}

- (void)createToneUnit
{
	// Configure the search parameters to find the default playback output unit
	// (called the kAudioUnitSubType_RemoteIO on iOS but
	// kAudioUnitSubType_DefaultOutput on Mac OS X)
	AudioComponentDescription defaultOutputDescription;
	defaultOutputDescription.componentType = kAudioUnitType_Output;
	defaultOutputDescription.componentSubType = kAudioUnitSubType_RemoteIO;
	defaultOutputDescription.componentManufacturer = kAudioUnitManufacturer_Apple;
	defaultOutputDescription.componentFlags = 0;
	defaultOutputDescription.componentFlagsMask = 0;

	// Get the default playback output unit
	AudioComponent defaultOutput = AudioComponentFindNext(NULL, &defaultOutputDescription);
	NSAssert(defaultOutput, @"Can't find default output");

	// Create a new unit based on this that we'll use for output
	OSErr err = AudioComponentInstanceNew(defaultOutput, &toneUnit);
	NSAssert1(toneUnit, @"Error creating unit: %ld", err);

	// Set our tone rendering function on the unit
	AURenderCallbackStruct input;
	input.inputProc = RenderTone;
	input.inputProcRefCon = (__bridge void *)(self);
	err = AudioUnitSetProperty(toneUnit,
							   kAudioUnitProperty_SetRenderCallback,
							   kAudioUnitScope_Input,
							   0,
							   &input,
							   sizeof(input));
	NSAssert1(err == noErr, @"Error setting callback: %ld", err);

	// Set the format to 32 bit, single channel, floating point, linear PCM
	const int four_bytes_per_float = 4;
	const int eight_bits_per_byte = 8;
	AudioStreamBasicDescription streamFormat;
	streamFormat.mSampleRate = sampleRate;
	streamFormat.mFormatID = kAudioFormatLinearPCM;
	streamFormat.mFormatFlags = kAudioFormatFlagsNativeFloatPacked | kAudioFormatFlagIsNonInterleaved;
	streamFormat.mBytesPerPacket = four_bytes_per_float;
	streamFormat.mFramesPerPacket = 1;
	streamFormat.mBytesPerFrame = four_bytes_per_float;
	streamFormat.mChannelsPerFrame = 1;
	streamFormat.mBitsPerChannel = four_bytes_per_float * eight_bits_per_byte;
	err = AudioUnitSetProperty (toneUnit,
								kAudioUnitProperty_StreamFormat,
								kAudioUnitScope_Input,
								0,
								&streamFormat,
								sizeof(AudioStreamBasicDescription));
	NSAssert1(err == noErr, @"Error setting stream format: %ld", err);
}

- (void)viewWillAppear:(BOOL)animated
{
	sampleRate = 44100;
	_refreshInterval = [[NSUserDefaults standardUserDefaults] doubleForKey:kSatFinderInterval];
	AudioSessionSetActive(true);
	[self startTimer];
	[self startAudio];

	[super viewWillAppear: animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
	[_timer invalidate];
	_timer = nil;
	_refreshInterval = 999;

	[self stopAudio];
	AudioSessionSetActive(false);

	[super viewWillDisappear: animated];
}

- (void)fetchSignalDefer
{
	// Run this in our "temporary" queue
	[RemoteConnectorObject queueInvocationWithTarget:self selector:@selector(fetchSignal)];
}

- (void)fetchSignal
{
	[[RemoteConnectorObject sharedRemoteConnector] getSignal: self];
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

	// Interval Slider
	_interval = [[UISlider alloc] initWithFrame: CGRectMake(0, 0, (IS_IPAD()) ? 300 : 200, kSliderHeight)];
	_interval.backgroundColor = [UIColor clearColor];
	_interval.autoresizingMask = UIViewAutoresizingNone;
	_interval.minimumValue = 0;
	_interval.maximumValue = 32; // we never reach the maximum, so we use 32 instead of 31 as max value
	_interval.continuous = YES;
	_interval.enabled = YES;
	_interval.value = [[NSUserDefaults standardUserDefaults] floatForKey:kSatFinderInterval];
	[_interval addTarget:self action:@selector(intervalChanged:) forControlEvents:UIControlEventValueChanged];
	[_interval addTarget:self action:@selector(intervalSet:) forControlEvents:UIControlEventTouchUpInside | UIControlEventTouchUpOutside];

	// Audio switch
	_audioToggle = [[UISwitch alloc] initWithFrame: CGRectMake(0, 0, 300, kSwitchButtonHeight)];
	[_audioToggle setOn: [[NSUserDefaults standardUserDefaults] boolForKey: kSatFinderAudio]];
	[_audioToggle addTarget:self action:@selector(audioToggleSwitched:) forControlEvents:UIControlEventValueChanged];
	_audioToggle.backgroundColor = [UIColor clearColor];
}

- (void)viewDidUnload
{
	_snr = nil;
	_agc = nil;
	_audioToggle = nil;
	_interval = nil;

	[self stopAudio];
	AudioSessionSetActive(false);

	[super viewDidUnload];
}

/* rotate with device */
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	return YES;
}

- (NSString *)getIntervalTitle:(double)interval
{
	if(interval <= 0)
	{
		return NSLocalizedString(@"instant", @"instant sat finder refresh");
	}
	else if(interval >= 31)
	{
		return NSLocalizedString(@"never", @"don't refresh sat finder");
	}
	return [NSString stringWithFormat:NSLocalizedString(@"%.0f sec", @"sat finder refresh interval"), interval];
}

- (void)startTimer
{
	[_timer invalidate];
	_timer = nil;
	if(_refreshInterval <= 0) // handle instant refresh differently
	{
		[self fetchSignalDefer];
	}
	else if(_refreshInterval < 31) // 31 == "never"
	{
		_timer = [NSTimer scheduledTimerWithTimeInterval:_refreshInterval
												  target:self selector:@selector(fetchSignalDefer)
												userInfo:nil   repeats:YES];
		[_timer fire];
	}
}

- (void)startAudio
{
	@synchronized(self)
	{
		if(toneUnit == nil && [[NSUserDefaults standardUserDefaults] boolForKey:kSatFinderAudio])
		{
			// start playback
			[self createToneUnit];
			OSErr err = AudioUnitInitialize(toneUnit);
			NSAssert1(err == noErr, @"Error initializing unit: %ld", err);
			err = AudioOutputUnitStart(toneUnit);
			NSAssert1(err == noErr, @"Error starting unit: %ld", err);
		}
	}
}

- (void)stopAudio
{
	@synchronized(self)
	{
		if(toneUnit)
		{
			// stop audio playback
			AudioOutputUnitStop(toneUnit);
			AudioUnitUninitialize(toneUnit);
			AudioComponentInstanceDispose(toneUnit);
			toneUnit = nil;
		}
	}
}

- (void)intervalSet:(id)sender
{
	_refreshInterval = (double)(int)_interval.value;
	[[NSUserDefaults standardUserDefaults] setDouble:_refreshInterval forKey:kSatFinderInterval];
	[(UITableView *)self.view reloadSections:[NSIndexSet indexSetWithIndex:2] withRowAnimation:UITableViewRowAnimationNone];

	// start new timer
	[self startTimer];
}

- (void)intervalChanged:(id)sender
{
	UITableViewCell *cell = [(UITableView *)self.view cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:2]];
	cell.textLabel.text = [self getIntervalTitle:(double)(int)_interval.value];
}

- (void)audioToggleSwitched:(id)sender
{
	const BOOL shouldRun = _audioToggle.on;
	[[NSUserDefaults standardUserDefaults] setBool:shouldRun forKey:kSatFinderAudio];
#if IS_DEBUG()
	const BOOL wasRunning = (toneUnit != nil);
	if(wasRunning == shouldRun)
		[NSException raise:@"ExcAudioToggleDidNotChange" format:@"AudioUnit was already created as the toggle changed to 'on' or off"];
#endif

	if(shouldRun)
		[self startAudio];
	else
		[self stopAudio];
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
	return 4;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
	switch(section)
	{
		case 0:	
			return NSLocalizedString(@"Percentage", @"Title of percentage section of SatFinder");
		case 1:
			return NSLocalizedString(@"Exact", @"Title of exact section of SatFinder");
		case 2:
			return NSLocalizedString(@"Interval", @"Title of refresh Interval section of SatFinder");
		case 3:
		default:
			return nil;
	}
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	switch(section)
	{
		case 0:
			return 2;
		case 1:
			return (_hasSnrdB) ? 2 : 1;
		case 2:
		case 3:
			return 1;
		default:
			return 0;
	}
}

// to determine which UITableViewCell to be used on a given row.
//
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	UITableViewCell *sourceCell = nil;

	// we are creating a new cell, setup its attributes
	switch (indexPath.section) {
		case 0:
			sourceCell = [DisplayCell reusableTableViewCellInView:tableView withIdentifier:kDisplayCell_ID];

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
			sourceCell = [UITableViewCell reusableTableViewCellInView:tableView withIdentifier:kVanilla_ID];

			sourceCell.textLabel.textAlignment = UITextAlignmentCenter;
			sourceCell.textLabel.textColor = [UIColor blackColor];
			sourceCell.textLabel.font = [UIFont systemFontOfSize:kTextViewFontSize];
			sourceCell.selectionStyle = UITableViewCellSelectionStyleNone;
			sourceCell.indentationLevel = 1;
			// NOTE: there is no useful default text, so don't set any
			break;
		case 2:
			sourceCell = [DisplayCell reusableTableViewCellInView:tableView withIdentifier:kDisplayCell_ID];

			sourceCell.selectionStyle = UITableViewCellSelectionStyleNone;
			((DisplayCell *)sourceCell).nameLabel.text = [self getIntervalTitle:[[NSUserDefaults standardUserDefaults] doubleForKey:kSatFinderInterval]];
			((DisplayCell *)sourceCell).view = _interval;
			break;
		case 3:
			sourceCell = [DisplayCell reusableTableViewCellInView:tableView withIdentifier:kDisplayCell_ID];

			sourceCell.selectionStyle = UITableViewCellSelectionStyleNone;
			sourceCell.textLabel.text = NSLocalizedString(@"Enable audio", @"Toggle in Signal Finder which is responsible for starting/stopping the tone generator");
			((DisplayCell *)sourceCell).view = _audioToggle;
			break;
		default:
			break;
	}
	
	return sourceCell;
}

#pragma mark -
#pragma mark DataSourceDelegate
#pragma mark -

- (void)dataSourceDelegate:(BaseXMLReader *)dataSource errorParsingDocument:(NSError *)error
{
	// Alert user
	const UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Failed to retrieve data", @"Title of Alert when retrieving remote data failed.")
														  message:[error localizedDescription]
														 delegate:nil
												cancelButtonTitle:@"OK"
												otherButtonTitles:nil];
	[alert show];

	// stop timer
	[_timer invalidate];
	_timer = nil;
	[self stopAudio];
}

- (void)dataSourceDelegateFinishedParsingDocument:(BaseXMLReader *)dataSource
{
	// NOTE: no reason for this reload
	//[(UITableView *)self.view reloadSections:[NSIndexSet indexSetWithIndex:1] withRowAnimation:UITableViewRowAnimationNone];

	if(_refreshInterval <= 0)
		[self fetchSignalDefer];
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

	const BOOL oldSnrdB =_hasSnrdB;
	_hasSnrdB = signal.snrdb > -1;

	// there is a weird glitch that prevents the second row from being shown unless we do a full reload, so do it here
	// while we still know that we need to do one.
	if(oldSnrdB != _hasSnrdB)
		[(UITableView *)self.view reloadData];

	UITableViewCell *cell = [(UITableView *)self.view cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:1]];
	if(_hasSnrdB)
	{
		cell.textLabel.text = [NSString stringWithFormat: @"SNR %.2f dB", signal.snrdb];
		cell = [(UITableView *)self.view cellForRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:1]];
	}
	cell.textLabel.text = [NSString stringWithFormat: @"%i BER", signal.ber];

	// calculate frequency for audio signal
	const NSInteger fMin = 200;
	const NSInteger fMax = 3000;
	frequency = fMin + (signal.snr * fMax / 100);
}

@end
