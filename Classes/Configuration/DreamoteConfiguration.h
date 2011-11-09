//
//  DreamoteConfiguration.h
//  dreaMote
//
//  Created by Moritz Venn on 08.11.11.
//  Copyright (c) 2011 Moritz Venn. All rights reserved.
//

#import <Foundation/Foundation.h>

// theme constants
typedef enum {
	THEME_DEFAULT = 0,
	THEME_BLUE,
	THEME_HIGHCONTRAST,
	THEME_MAX,
} themeType;

@interface DreamoteConfiguration : NSObject

+ (DreamoteConfiguration *)singleton;

- (void)styleNavigationController:(UINavigationController *)navigationController;
- (void)styleToolbar:(UIToolbar *)toolbar;
- (void)styleSearchBar:(UISearchBar *)searchBar;
- (void)styleTableView:(UITableView *)tableView;
- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section;
- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section;

@property (nonatomic) themeType currentTheme;
@property (nonatomic, readonly) UIColor *backgroundColor;
@property (nonatomic, readonly) UIColor *groupedTableViewBackgroundColor;
@property (nonatomic, readonly) UIColor *textColor;
@property (nonatomic, readonly) UIColor *highlightedTextColor;
@property (nonatomic, readonly) UIColor *detailsTextColor;
@property (nonatomic, readonly) UIColor *highlightedDetailsTextColor;
@property (nonatomic, readonly) CGFloat textFieldHeight;
@property (nonatomic, readonly) CGFloat textViewHeight;
@property (nonatomic, readonly) CGFloat textFieldFontSize;
@property (nonatomic, readonly) CGFloat textViewFontSize;
@property (nonatomic, readonly) CGFloat multiEpgFontSize;
@property (nonatomic, readonly) CGFloat uiSmallRowHeight;
@property (nonatomic, readonly) CGFloat uiRowHeight;
@property (nonatomic, readonly) CGFloat uiRowLabelHeight;
@property (nonatomic, readonly) CGFloat eventCellHeight;
@property (nonatomic, readonly) CGFloat serviceCellHeight;
@property (nonatomic, readonly) CGFloat serviceEventCellHeight;
@property (nonatomic, readonly) CGFloat metadataCellHeight;
@property (nonatomic, readonly) CGFloat autotimerCellHeight;
@property (nonatomic, readonly) CGFloat packageCellHeight;
@property (nonatomic, readonly) CGFloat multiEpgHeaderHeight;
@property (nonatomic, readonly) CGFloat mainTextSize;
@property (nonatomic, readonly) CGFloat mainDetailsSize;
@property (nonatomic, readonly) CGFloat serviceTextSize;
@property (nonatomic, readonly) CGFloat serviceEventServiceSize;
@property (nonatomic, readonly) CGFloat serviceEventEventSize;
@property (nonatomic, readonly) CGFloat eventNameTextSize;
@property (nonatomic, readonly) CGFloat eventDetailsTextSize;
@property (nonatomic, readonly) CGFloat timerServiceTextSize;
@property (nonatomic, readonly) CGFloat timerNameTextSize;
@property (nonatomic, readonly) CGFloat timerTimeTextSize;
@property (nonatomic, readonly) CGFloat datePickerFontSize;
@property (nonatomic, readonly) CGFloat autotimerNameTextSize;
@property (nonatomic, readonly) CGFloat packageNameTextSize;
@property (nonatomic, readonly) CGFloat packageVersionTextSize;

@end
