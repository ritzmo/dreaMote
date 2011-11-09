//
//  DreamoteConfiguration.m
//  dreaMote
//
//  Created by Moritz Venn on 08.11.11.
//  Copyright (c) 2011 Moritz Venn. All rights reserved.
//

#import "DreamoteConfiguration.h"
#import "DreamoteIpadConfiguration.h"

#import "UIDevice+SystemVersion.h"

#import "Constants.h"

#import <View/GradientView.h>

#define darkBlueColor colorWithRed:0.1 green:0.15 blue:0.55 alpha:1

@interface DreamoteConfiguration()
- (void)styleNavigationBar:(UINavigationBar *)navigationBar;
@property (nonatomic, readonly) UIColor *sectionLabelColor;
@property (nonatomic, readonly) UIColor *sectionLabelShadowColor;
@end

@implementation DreamoteConfiguration

@synthesize currentTheme;

+ (DreamoteConfiguration *)singleton
{
	static DreamoteConfiguration *singleton = nil;
	static dispatch_once_t once;
	dispatch_once(&once, ^{
		if(IS_IPAD())
			singleton = [[DreamoteIpadConfiguration alloc] init];
		else
			singleton = [[DreamoteConfiguration alloc] init];
	});
	return singleton;
}

- (void)styleNavigationController:(UINavigationController *)navigationController
{
	[self styleNavigationBar:navigationController.navigationBar];
	[self styleToolbar:navigationController.toolbar];
}

- (void)styleNavigationBar:(UINavigationBar *)navigationBar
{
	const BOOL isIos5 = [UIDevice newerThanIos:5.0f];
	switch(currentTheme)
	{
		default:
		case THEME_DEFAULT:
			if(isIos5)
				navigationBar.titleTextAttributes = nil;
			navigationBar.barStyle = UIBarStyleDefault;
			navigationBar.tintColor = nil;
			break;
		case THEME_BLUE:
			if(isIos5)
				navigationBar.titleTextAttributes = nil;
			navigationBar.tintColor = [UIColor darkBlueColor];
			break;
		case THEME_HIGHCONTRAST:
			if(isIos5)
				navigationBar.titleTextAttributes = [NSDictionary dictionaryWithObjectsAndKeys:[self textColor], UITextAttributeTextColor, nil];
			navigationBar.barStyle = UIBarStyleBlack;
			navigationBar.tintColor = nil;
			break;
	}
}

- (void)styleToolbar:(UIToolbar *)toolbar
{
	switch(currentTheme)
	{
		default:
		case THEME_DEFAULT:
			toolbar.barStyle = UIBarStyleDefault;
			toolbar.tintColor = nil;
			break;
		case THEME_BLUE:
			toolbar.tintColor = [UIColor darkBlueColor];
			break;
		case THEME_HIGHCONTRAST:
			toolbar.barStyle = UIBarStyleBlack;
			toolbar.tintColor = nil;
			break;
	}
}

- (void)styleSearchBar:(UISearchBar *)searchBar
{
	switch(currentTheme)
	{
		default:
		case THEME_DEFAULT:
			searchBar.barStyle = UIBarStyleDefault;
			searchBar.tintColor = nil;
			break;
		case THEME_BLUE:
			searchBar.barStyle = UIBarStyleBlack;
			searchBar.tintColor = [UIColor darkBlueColor];
			break;
		case THEME_HIGHCONTRAST:
			// TODO: improve
			searchBar.barStyle = UIBarStyleBlack;
			searchBar.tintColor = nil;
			break;
	}
}

- (void)styleTableView:(UITableView *)tableView
{
	tableView.backgroundColor = self.backgroundColor;
	[tableView reloadData]; // force reload so the cells apply the new theme
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
#ifndef defaultSectionHeaderHeight
#define defaultSectionHeaderHeight 34
#endif
	if(currentTheme != THEME_DEFAULT)
		return 44.0;
	return defaultSectionHeaderHeight;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
	if(currentTheme != THEME_DEFAULT)
	{
		NSString *text = [tableView.dataSource tableView:tableView titleForHeaderInSection:section];
		if(text)
		{
			UIView *headerView = nil;
			UILabel *headerLabel = [[UILabel alloc] initWithFrame:CGRectZero];
			headerLabel.backgroundColor = [UIColor clearColor];
			headerLabel.opaque = NO;
			headerLabel.textColor = self.sectionLabelColor;
			headerLabel.font = [UIFont fontWithName:@"Helvetica" size:20]; // TODO: find a better & free font :D
			headerLabel.text = text;

			if(tableView.style == UITableViewStylePlain)
			{
				// NOTE: we might want to use an image for this, it annoys me when the gradient turns translucent (which an image won't :D)
				GradientView *gradientView = [[GradientView alloc] initWithFrame:CGRectMake(10.0, 0.0, 300.0, 44.0)];
				switch(currentTheme)
				{
					default:
						[gradientView gradientFrom:[UIColor colorWithRed:1 green:0 blue:0 alpha:.75] to:[UIColor colorWithRed:1 green:0 blue:0 alpha:.46]];
						break;
					case THEME_HIGHCONTRAST:
						[gradientView gradientFrom:[UIColor colorWithRed:.5 green:.5 blue:.5 alpha:.75] to:[UIColor colorWithRed:0 green:0 blue:0 alpha:.35]];
						gradientView.centerGradient = YES;
						break;
				}
				headerView = gradientView;
				headerLabel.frame = CGRectMake(10.0, 0.0, 300.0, 44.0);
			}
			else if(currentTheme == THEME_HIGHCONTRAST)
			{
				headerView = [[UIView alloc] initWithFrame:CGRectMake(10.0, 0.0, 300.0, 44.0)];
				headerView.backgroundColor = [UIColor clearColor];
				headerLabel.frame = CGRectMake(30.0, 0.0, 260.0, 44.0);
				headerLabel.shadowColor = self.sectionLabelShadowColor;
				headerLabel.shadowOffset = CGSizeMake(0,2);
			}
			[headerView addSubview:headerLabel];

			return headerView;
		}
	}
	return nil;
}

#pragma mark Properties

- (void)setCurrentTheme:(themeType)newCurrentTheme
{
	if(currentTheme == newCurrentTheme) return;
	currentTheme = newCurrentTheme;
	[[NSNotificationCenter defaultCenter] postNotificationName:kThemeChangedNotification object:nil userInfo:nil];
}

- (UIColor *)backgroundColor
{
	switch(currentTheme)
	{
		default:
		case THEME_DEFAULT:
			return [UIColor lightGrayColor];
		case THEME_BLUE:
			return [UIColor colorWithRed:0.95 green:0.95 blue:0.95 alpha:0.9];
		case THEME_HIGHCONTRAST:
			return [UIColor blackColor];
	}
}

- (UIColor *)textColor
{
	switch(currentTheme)
	{
		default:
			return [UIColor blackColor];
		case THEME_HIGHCONTRAST:
			return [UIColor grayColor];
	}
}

- (UIColor *)highlightedTextColor
{
	switch(currentTheme)
	{
		default:
			return [UIColor whiteColor];
		case THEME_HIGHCONTRAST:
			return [UIColor grayColor];
	}
}

- (UIColor *)detailsTextColor
{
	switch(currentTheme)
	{
		default:
			return [UIColor grayColor];
		case THEME_HIGHCONTRAST:
			return [UIColor darkGrayColor];
	}
}

- (UIColor *)highlightedDetailsTextColor
{
	switch(currentTheme)
	{
		default:
			return [UIColor whiteColor];
		case THEME_HIGHCONTRAST:
			return [UIColor darkGrayColor];
	}
}

- (UIColor *)sectionLabelColor
{
	switch(currentTheme)
	{
		default:
			return [UIColor whiteColor];
		case THEME_HIGHCONTRAST:
			return [UIColor lightGrayColor];
	}
}

- (UIColor *)sectionLabelShadowColor
{
	return [UIColor grayColor];
}

- (CGFloat)textFieldHeight
{
	return 30;
}

- (CGFloat)textViewHeight
{
	return 220;
}

- (CGFloat)textFieldFontSize
{
	return 18;
}

- (CGFloat)textViewFontSize
{
	return 18;
}

- (CGFloat)multiEpgFontSize
{
	return 10;
}

- (CGFloat)uiSmallRowHeight
{
	return 38;
}

- (CGFloat)uiRowHeight
{
	return 50;
}

- (CGFloat)uiRowLabelHeight
{
	return 22;
}

- (CGFloat)eventCellHeight
{
	return 48;
}

- (CGFloat)serviceCellHeight
{
	return 38;
}

- (CGFloat)serviceEventCellHeight
{
	return 50;
}

- (CGFloat)metadataCellHeight
{
	return 275;
}

- (CGFloat)autotimerCellHeight
{
	return 38;
}

- (CGFloat)packageCellHeight
{
	return 42;
}

- (CGFloat)multiEpgHeaderHeight
{
	return 25;
}

- (CGFloat)mainTextSize
{
	return 18;
}

- (CGFloat)mainDetailsSize
{
	return 14;
}

- (CGFloat)serviceTextSize
{
	return 16;
}

- (CGFloat)serviceEventServiceSize
{
	return 14;
}

- (CGFloat)serviceEventEventSize
{
	return 12;
}

- (CGFloat)eventNameTextSize
{
	return 14;
}

- (CGFloat)eventDetailsTextSize
{
	return 12;
}

- (CGFloat)timerServiceTextSize
{
	return 14;
}

- (CGFloat)timerNameTextSize
{
	return 12;
}

- (CGFloat)timerTimeTextSize
{
	return 12;
}

- (CGFloat)datePickerFontSize
{
	return 14;
}

- (CGFloat)autotimerNameTextSize
{
	return 16;
}

- (CGFloat)packageNameTextSize
{
	return 12;
}

- (CGFloat)packageVersionTextSize
{
	return 12;
}

@end
