//
//  SearchHistoryListController.m
//  dreaMote
//
//  Created by Moritz Venn on 13.01.11.
//  Copyright 2011 Moritz Venn. All rights reserved.
//

#import "SearchHistoryListController.h"

#import "Constants.h"

#define MAX_HISTORY_LENGTH ((IS_IPAD()) ? 12 : 9)


@implementation SearchHistoryListController

@synthesize historyDelegate = _historyDelegate;

- (id)init
{
	if((self = [super init]))
	{
		self.title = NSLocalizedString(@"History", @"Title of SearchHistoryListController");

		NSString *finalPath = [kHistoryPath stringByExpandingTildeInPath];
		_history = [[NSMutableArray arrayWithContentsOfFile:finalPath] retain];
		if(_history == nil) // no history yet
			_history = [[NSMutableArray alloc] init];

		if([self respondsToSelector:@selector(setContentSizeForViewInPopover:)])
			self.contentSizeForViewInPopover = CGSizeMake(370.0f, 450.0f);
    }
    return self;
}

- (void)dealloc
{
	[_history release];

    [super dealloc];
}

- (void)loadView
{
	UITableView *tableView = [[UITableView alloc] initWithFrame:[[UIScreen mainScreen] applicationFrame] style:UITableViewStylePlain];
	tableView.delegate = self;
	tableView.dataSource = self;
	tableView.rowHeight = 38;
	tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
	tableView.sectionHeaderHeight = 0;
	tableView.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
	
	self.view = tableView;
	[tableView release];
	
	self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated
{
	if(!editing)
		[self saveHistory];

	[super setEditing:editing animated:animated];
	[(UITableView *)self.view setEditing:editing animated:animated];
}

- (void)prepend:(NSString *)new
{
	// eventually remove first
	[_history removeObject:new];

	// make one item shorter then max
	while([_history count] > MAX_HISTORY_LENGTH - 1)
	{
		[_history removeLastObject];
	}

	// prepend
	[_history insertObject:new atIndex:0];

	// reload data
	[(UITableView *)self.view reloadData];
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
	UITableViewCell *cell = (UITableViewCell *)[tableView dequeueReusableCellWithIdentifier: kVanilla_ID];
	if(cell == nil)
		cell = [[[UITableViewCell alloc] initWithFrame: CGRectZero reuseIdentifier: kVanilla_ID] autorelease];

	TABLEVIEWCELL_FONT(cell) = [UIFont boldSystemFontOfSize:kTextViewFontSize-1];
	TABLEVIEWCELL_TEXT(cell) = [_history objectAtIndex:indexPath.row];
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
