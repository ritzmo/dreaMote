//
//  SearchHistoryListController.m
//  dreaMote
//
//  Created by Moritz Venn on 13.01.11.
//  Copyright 2011-2012 Moritz Venn. All rights reserved.
//

#import "SearchHistoryListController.h"

#import "Constants.h"
#import "UITableViewCell+EasyInit.h"

#import "BaseTableViewCell.h"

@implementation SearchHistoryListController

@synthesize historyDelegate = _historyDelegate;
@synthesize tableView = _tableView;

- (id)init
{
	if((self = [super init]))
	{
		self.title = NSLocalizedString(@"History", @"Title of SearchHistoryListController");

		NSString *finalPath = [kHistoryPath stringByExpandingTildeInPath];
		_history = [NSMutableArray arrayWithContentsOfFile:finalPath];
		if(_history == nil) // no history yet
			_history = [[NSMutableArray alloc] init];

		self.contentSizeForViewInPopover = CGSizeMake(370.0f, 450.0f);
    }
    return self;
}

- (void)dealloc
{
	[self stopObservingThemeChanges];
}

- (void)loadView
{
	_tableView = [[UITableView alloc] initWithFrame:[[UIScreen mainScreen] applicationFrame] style:UITableViewStylePlain];
	_tableView.delegate = self;
	_tableView.dataSource = self;
	_tableView.rowHeight = 38;
	_tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
	_tableView.sectionHeaderHeight = 0;
	_tableView.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
	_tableView.backgroundView = [[UIView alloc] init];

	self.view = _tableView;

	self.navigationItem.rightBarButtonItem = self.editButtonItem;
	[self theme];
}

- (void)theme
{
	UIColor *color = [DreamoteConfiguration singleton].backgroundColor;
	_tableView.backgroundView.backgroundColor =  color ? color : [UIColor whiteColor];
}

- (void)viewDidLoad
{
	[self startObservingThemeChanges];
	[super viewDidLoad];
}

- (void)viewDidUnload
{
	[self stopObservingThemeChanges];
	_tableView = nil;
	[super viewDidUnload];
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated
{
	if(!editing)
		[self saveHistory];

	[super setEditing:editing animated:animated];
	[_tableView setEditing:editing animated:animated];
}

- (void)prepend:(NSString *)new
{
	// eventually remove first
	[_history removeObject:new];

	// make one item shorter then max
	NSUInteger historyLength = [[NSUserDefaults standardUserDefaults] integerForKey:kSearchHistoryLength] - 1;
	while([_history count] > historyLength)
	{
		[_history removeLastObject];
	}

	// prepend
	[_history insertObject:new atIndex:0];

	// reload data
	[_tableView reloadData];
}

- (void)saveHistory
{
	NSString *finalPath = [kHistoryPath stringByExpandingTildeInPath];
    [_history writeToFile:finalPath atomically:YES];
}

#pragma mark	-
#pragma mark	UITableView delegate methods
#pragma mark	-

/* create cell for given row */
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	UITableViewCell *cell = [BaseTableViewCell reusableTableViewCellInView:tableView withIdentifier:kBaseCell_ID];

	cell.textLabel.font = [UIFont boldSystemFontOfSize:kTextViewFontSize-1];
	cell.textLabel.text = [_history objectAtIndex:indexPath.row];

	[[DreamoteConfiguration singleton] styleTableViewCell:cell inTableView:tableView];
	return cell;
}

/* select row */
- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	if(!_historyDelegate) return nil;
	[_historyDelegate startSearch:[_history objectAtIndex:indexPath.row]];
	return indexPath;
}

/* edit action */
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
	[_history removeObjectAtIndex:indexPath.row];
	if(!tableView.editing)
		[self saveHistory];
	[tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationFade];
}

/* row selected */
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
}

/* editing style */
- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
	return UITableViewCellEditingStyleDelete;
}

/* number of sections */
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return 1;
}

/* number of rows */
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	return [_history count];
}

@end
