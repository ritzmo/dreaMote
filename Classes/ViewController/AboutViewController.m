//
//  AboutViewController.m
//  dreaMote
//
//  Created by Moritz Venn on 08.01.11.
//  Copyright 2011 Moritz Venn. All rights reserved.
//

#import "AboutViewController.h"

#import "RemoteConnectorObject.h"

#import "AboutProtocol.h"
#import "MainTableViewCell.h" /* hdd */
#import "Constants.h"
#import "UITableViewCell+EasyInit.h"

@implementation AboutViewController

- (id)init
{
	if((self = [super init]))
	{
		self.title = NSLocalizedString(@"About Receiver", @"");
		_about = nil;
		_aboutXMLDoc = nil;
	}
	
	return self;
}

- (void)dealloc
{
	[_about release];
	[_aboutXMLDoc release];

	[super dealloc];
}

/* layout */
- (void)loadView
{
	[super loadGroupedTableView];
	_tableView.delegate = self;
	_tableView.dataSource = self;
}

- (void)fetchData
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	CXMLDocument *newXMLDoc = nil;
	@try {
		_reloading = YES;
		newXMLDoc = [[RemoteConnectorObject sharedRemoteConnector] getAbout:self];
	}
	@catch (NSException * e) {
#if IS_DEBUG()
		[e raise];
#endif
	}
	SafeRetainAssign(_aboutXMLDoc, newXMLDoc);
	[pool release];
}

- (void)emptyData
{
	SafeRetainAssign(_about, nil);
#if INCLUDE_FEATURE(Extra_Animation)
	NSIndexSet *idxSet = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, 3)];
	[_tableView reloadSections:idxSet withRowAnimation:UITableViewRowAnimationFade];
#else
	[_tableView reloadData];
#endif
	SafeRetainAssign(_aboutXMLDoc, nil);
}

#pragma mark -
#pragma mark DataSourceDelegate
#pragma mark -

- (void)dataSourceDelegate:(BaseXMLReader *)dataSource finishedParsingDocument:(CXMLDocument *)document
{
	[_refreshHeaderView egoRefreshScrollViewDataSourceDidFinishedLoading:_tableView];
	_reloading = NO;
#if INCLUDE_FEATURE(Extra_Animation)
	NSIndexSet *idxSet = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, 3)];
	[_tableView reloadSections:idxSet withRowAnimation:UITableViewRowAnimationFade];
#else
	[_tableView reloadData];
#endif
}

#pragma mark -
#pragma mark AboutSourceDelegate
#pragma mark -

- (void)addAbout: (NSObject<AboutProtocol> *)about
{
	SafeRetainAssign(_about, about);
}

#pragma mark - UITableView delegates

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	return nil;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return 3;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
	if(_about == nil) return nil;
	switch (section)
	{
		case 0:
			return NSLocalizedString(@"Version Information", @"");
		case 1:
			return (_about.hdd != nil) ? NSLocalizedString(@"Harddisk", @"") : nil;
		case 2:
			return (_about.tuners != nil) ? NSLocalizedString(@"Tuners", @"") : nil;
		default:
			return nil;
	}
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	if(_about == nil)
	{
		if(section == 0) return 1;
		return 0;
	}

	switch(section)
	{
		case 0:
			return 3;
		case 1:
			if(_about.hdd == nil)
				return 0;
			return 1;
		case 2:
			if(_about.tuners == nil)
				return 0;
			return [_about.tuners count];
		default:
			return 0;
	}
}

// to determine specific row height for each cell, override this.  In this example, each row is determined
// buy the its subviews that are embedded.
//
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	if(_about == nil) return kUIRowHeight;
	switch (indexPath.section)
	{
		case 1:
		{
			if(_about.hdd == nil)
				return 0;
			break;
		}
		case 2:
		{
			if(_about.tuners == nil)
				return 0;
			break;
		}
		case 0:
		default:
			break;
	}
	
	return kUIRowHeight;
}

// to determine which UITableViewCell to be used on a given row.
//
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	NSInteger section = indexPath.section;
	UITableViewCell *sourceCell = nil;

	// special handling if about not yet set, can only be row 0 of section 0
	if(_about == nil)
	{
		sourceCell = [UITableViewCell reusableTableViewCellInView:tableView withIdentifier:kVanilla_ID];

		TABLEVIEWCELL_FONT(sourceCell) = [UIFont boldSystemFontOfSize:kTextViewFontSize-1];
		TABLEVIEWCELL_TEXT(sourceCell) = NSLocalizedString(@"No Data…", @"");
		return sourceCell;
	}

	// we are creating a new cell, setup its attributes
	switch(section)
	{
		case 0:
		{
			NSDictionary *dataDictionary = nil;
			sourceCell = [MainTableViewCell reusableTableViewCellInView:tableView withIdentifier:kMainCell_ID];

			switch(indexPath.row)
			{
				case 0:
					dataDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
											NSLocalizedString(@"GUI Version", @""), @"title",
											_about.version, @"explainText", nil];
					break;
				case 1:
					dataDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
									  NSLocalizedString(@"Image Version", @""), @"title",
									  _about.imageVersion, @"explainText", nil];
					break;
				case 2:
					dataDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
									  NSLocalizedString(@"Receiver model", @""), @"title",
									  _about.model, @"explainText", nil];
					break;
				default: break;
			}

			((MainTableViewCell *)sourceCell).dataDictionary = dataDictionary;
			sourceCell.accessoryType = UITableViewCellAccessoryNone;
			break;
		}
		case 1:
		{
			sourceCell = [MainTableViewCell reusableTableViewCellInView:tableView withIdentifier:kMainCell_ID];

			((MainTableViewCell *)sourceCell).dataDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
							_about.hdd.model, @"title",
							[NSString stringWithFormat:NSLocalizedString(@"%@ of %@ free", @""), _about.hdd.free, _about.hdd.capacity], @"explainText", nil];
			sourceCell.accessoryType = UITableViewCellAccessoryNone;
			break;
		}
		case 2:
		{
			sourceCell = [UITableViewCell reusableTableViewCellInView:tableView withIdentifier:kVanilla_ID];

			TABLEVIEWCELL_FONT(sourceCell) = [UIFont boldSystemFontOfSize:kTextViewFontSize-1];
			TABLEVIEWCELL_TEXT(sourceCell) = [_about.tuners objectAtIndex: indexPath.row];
			break;
		}
		default:
			break;
	}
	
	return sourceCell;
}

#pragma mark - UIViewController delegate methods

- (void)viewWillAppear:(BOOL)animated
{
	if(!_reloading)
	{
		// Spawn a thread to fetch the event data so that the UI is not blocked while the
		// application parses the XML file.
		if([[RemoteConnectorObject sharedRemoteConnector] hasFeature: kFeaturesAbout])
			[NSThread detachNewThreadSelector:@selector(fetchData) toTarget:self withObject:nil];
	}
}

- (void)viewWillDisappear:(BOOL)animated
{
	if(!_reloading)
		[self emptyData];
}

/* rotate with device */
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return YES;
}

@end
