//
//  SearchHistoryLengthEditorController.m
//  dreaMote
//
//  Created by Moritz Venn on 17.10.11.
//  Copyright 2011 Moritz Venn. All rights reserved.
//

#import "SearchHistoryLengthEditorController.h"

#import "Constants.h"
#import "UITableViewCell+EasyInit.h"
#import "CellTextField.h"

@interface SearchHistoryLengthEditorController()
/*!
 @brief done editing
 */
- (void)doneAction:(id)sender;

@property (nonatomic, assign) NSInteger length;
@end

@implementation SearchHistoryLengthEditorController
@synthesize length = _length;

/* initialize */
- (id)init
{
	if((self = [super init]))
	{
		self.title = NSLocalizedString(@"Search History Length", @"Default title of SearchHistoryLengthEditorController");

		if([self respondsToSelector:@selector(modalPresentationStyle)])
		{
			self.modalPresentationStyle = UIModalPresentationFormSheet;
			self.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
		}
	}
	return self;
}

/* create SearchHistoryLengthEditorController with given length entered */
+ (SearchHistoryLengthEditorController *)withLength:(NSInteger)length
{
	SearchHistoryLengthEditorController *vc = [[SearchHistoryLengthEditorController alloc] init];
	vc.length = length;
	return vc;
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

	_lengthTextField = [[UITextField alloc] initWithFrame:CGRectZero];
	
	_lengthTextField.leftView = nil;
	_lengthTextField.leftViewMode = UITextFieldViewModeNever;
	_lengthTextField.borderStyle = UITextBorderStyleRoundedRect;
    _lengthTextField.textColor = [UIColor blackColor];
	_lengthTextField.font = [UIFont systemFontOfSize:kTextFieldFontSize];
    _lengthTextField.backgroundColor = [UIColor whiteColor];
	// no auto correction support
	_lengthTextField.autocorrectionType = UITextAutocorrectionTypeNo;
	_lengthTextField.autocapitalizationType = UITextAutocapitalizationTypeNone;
	_lengthTextField.keyboardType = UIKeyboardTypeNumberPad;
	_lengthTextField.returnKeyType = UIReturnKeyDone;
	// has a clear 'x' button to the right
	_lengthTextField.clearButtonMode = UITextFieldViewModeWhileEditing;
	// contents
	_lengthTextField.placeholder = NSLocalizedString(@"<history length>", @"");
	_lengthTextField.text = [NSString stringWithFormat:@"%d", _length];

	UIBarButtonItem *button = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
																			target:self action:@selector(doneAction:)];
	self.navigationItem.rightBarButtonItem = button;
}

/* finish */
- (void)doneAction:(id)sender
{
	if(IS_IPAD())
		[self.navigationController dismissModalViewControllerAnimated:YES];
	else
		[self.navigationController popViewControllerAnimated:YES];
}

/* rotate with device */
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	return YES;
}

#pragma mark - UITableView delegates

/* title for section */
- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
	return nil;
}

/* rows in section */
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	return 1;
}

/* to determine which UITableViewCell to be used on a given row. */
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	CellTextField *cell = [CellTextField reusableTableViewCellInView:tableView withIdentifier:kCellTextField_ID];
	cell.view = _lengthTextField;

	return cell;
}

/* set delegate */
- (void)setDelegate:(NSObject<SearchHistoryLengthEditorDelegate> *)delegate
{
	_delegate = delegate;
}

#pragma mark - UIViewController delegate methods

/* about to disappear */
- (void)viewWillDisappear:(BOOL)animated
{
	NSInteger length = [_lengthTextField.text integerValue];

	NSUserDefaults *stdDefaults = [NSUserDefaults standardUserDefaults];
	[stdDefaults setObject:[NSNumber numberWithInteger:length] forKey:kSearchHistoryLength];
	[stdDefaults synchronize];

	[_delegate performSelectorOnMainThread:@selector(didSetLength) withObject:nil waitUntilDone:NO];
}

@end
