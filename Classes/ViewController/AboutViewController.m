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
#import "Constants.h"
#import "UITableViewCell+EasyInit.h"

#import <Objects/Generic/Harddisk.h>

#import <TableViewCell/BaseTableViewCell.h>
#import <TableViewCell/MainTableViewCell.h> /* hdd */

@implementation AboutViewController

- (id)init
{
	if((self = [super init]))
	{
		self.title = NSLocalizedString(@"About Receiver", @"Title of AboutViewController");
		_about = nil;
		_xmlReader = nil;
	}
	
	return self;
}

/* layout */
- (void)loadView
{
	[super loadGroupedTableView];
	_tableView.delegate = self;
	_tableView.dataSource = self;
	[self theme];
}

- (void)fetchData
{
	BaseXMLReader *newXMLReader = nil;
	@try {
		_reloading = YES;
		newXMLReader = [[RemoteConnectorObject sharedRemoteConnector] getAbout:self];
	}
	@catch (NSException * e) {
#if IS_DEBUG()
		[e raise];
#endif
	}
	_xmlReader = newXMLReader;
}

- (void)emptyData
{
	_about = nil;
#if INCLUDE_FEATURE(Extra_Animation)
	NSIndexSet *idxSet = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, 3)];
	[_tableView reloadSections:idxSet withRowAnimation:UITableViewRowAnimationFade];
#else
	[_tableView reloadData];
#endif
	_xmlReader = nil;
}

#pragma mark -
#pragma mark DataSourceDelegate
#pragma mark -

- (void)dataSourceDelegateFinishedParsingDocument:(BaseXMLReader *)dataSource
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
	_about = about;
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

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
	if(_about == nil) return 0.0001;
	return [[DreamoteConfiguration singleton] tableView:tableView heightForHeaderInSection:section];
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
	if(_about == nil) return nil;
	return [[DreamoteConfiguration singleton] tableView:tableView viewForHeaderInSection:section];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
	if(_about == nil) return nil;
	switch (section)
	{
		case 0:
			return NSLocalizedString(@"Version Information", @"Title of section in About View containing versioning information");
		case 1:
			return (_about.hdd.count) ? NSLocalizedString(@"Harddisk", @"Title of section in About View containing harddisk information (if any)") : nil;
		case 2:
			return (_about.tuners != nil) ? NSLocalizedString(@"Tuners", @"Title of section in About View containing tuner information (if any)") : nil;
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
			return _about.hdd.count;
		case 2:
			return _about.tuners.count;
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
			if(!_about.hdd.count)
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
		sourceCell = [BaseTableViewCell reusableTableViewCellInView:tableView withIdentifier:kBaseCell_ID];

		sourceCell.textLabel.font = [UIFont boldSystemFontOfSize:kTextViewFontSize-1];
		sourceCell.textLabel.text = NSLocalizedString(@"No Data…", @"Placeholder if no data has been received yet.");
		[[DreamoteConfiguration singleton] styleTableViewCell:sourceCell inTableView:tableView];
		return [[DreamoteConfiguration singleton] styleTableViewCell:sourceCell inTableView:tableView];
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
											NSLocalizedString(@"GUI Version", @"Cell title with GUI version in About View"), @"title",
											_about.version, @"explainText", nil];
					break;
				case 1:
					dataDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
									  NSLocalizedString(@"Image Version", @"Cell title with Image version in About View"), @"title",
									  _about.imageVersion, @"explainText", nil];
					break;
				case 2:
					dataDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
									  NSLocalizedString(@"Receiver model", @"Cell title with Receiver model in About View"), @"title",
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
			NSUInteger row = indexPath.row;
			sourceCell = [MainTableViewCell reusableTableViewCellInView:tableView withIdentifier:kMainCell_ID];
			if(row < _about.hdd.count)
			{
				Harddisk *hdd = [_about.hdd objectAtIndex:indexPath.row];
				((MainTableViewCell *)sourceCell).dataDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
							hdd.model, @"title",
							[NSString stringWithFormat:NSLocalizedString(@"%@ of %@ free", @"Free space on harddisk (available of total free), includes size."), hdd.free, hdd.capacity], @"explainText", nil];
			}
			else
			{
				((MainTableViewCell *)sourceCell).dataDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
																	NSLocalizedString(@"Unknown", @"") , @"title",
																	@"", @"explainText", nil];
			}
			sourceCell.accessoryType = UITableViewCellAccessoryNone;
			break;
		}
		case 2:
		{
			sourceCell = [BaseTableViewCell reusableTableViewCellInView:tableView withIdentifier:kBaseCell_ID];

			sourceCell.textLabel.font = [UIFont boldSystemFontOfSize:kTextViewFontSize-1];
			sourceCell.textLabel.text = [_about.tuners objectAtIndex: indexPath.row];
			break;
		}
		default:
			break;
	}

	return [[DreamoteConfiguration singleton] styleTableViewCell:sourceCell inTableView:tableView];
}

#pragma mark - UIViewController delegate methods

- (void)viewWillAppear:(BOOL)animated
{
	if(!_reloading)
	{
		// Run this in our "temporary" queue
		if([[RemoteConnectorObject sharedRemoteConnector] hasFeature: kFeaturesAbout])
			[RemoteConnectorObject queueInvocationWithTarget:self selector:@selector(fetchData)];
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
