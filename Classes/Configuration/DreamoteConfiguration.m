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
#import "EGORefreshTableHeaderView.h"

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

- (NSArray *)themeNames
{
	return [NSArray arrayWithObjects:NSLocalizedString(@"Default", @"Name of default theme"),
			NSLocalizedString(@"Blue", @"Name of blue theme"),
			NSLocalizedString(@"Dark", @"Name of dark theme"),
			NSLocalizedString(@"Night", @"Name of night theme"),
			nil];
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
		case THEME_NIGHT:
			if(isIos5)
				navigationBar.titleTextAttributes = [NSDictionary dictionaryWithObjectsAndKeys:[self textColor], UITextAttributeTextColor, nil];
			navigationBar.barStyle = UIBarStyleBlack;
			navigationBar.tintColor = nil;
			break;
		case THEME_DARK:
			if(isIos5)
				navigationBar.titleTextAttributes = [NSDictionary dictionaryWithObjectsAndKeys:[self textColor], UITextAttributeTextColor, nil];
			navigationBar.barStyle = UIBarStyleBlack;
			navigationBar.tintColor = [UIColor colorWithRed:.17 green:.17 blue:.17 alpha:1];
			break;
	}
}

- (void)styleTabBar:(UITabBar *)tabBar
{
	const BOOL isIos5 = [UIDevice newerThanIos:5.0f];
	if(isIos5)
	{
		switch(currentTheme)
		{
			default:
				tabBar.tintColor = nil;
				tabBar.selectedImageTintColor = nil;
				break;
			case THEME_BLUE:
				tabBar.tintColor = [UIColor colorWithRed:0 green:0 blue:.4 alpha:1];
				tabBar.selectedImageTintColor = [UIColor colorWithRed:0.95 green:0.95 blue:0.95 alpha:1];
				break;
			case THEME_NIGHT:
				tabBar.tintColor = [UIColor blackColor];
				tabBar.selectedImageTintColor = [UIColor darkGrayColor];
				break;
			case THEME_DARK:
				tabBar.tintColor = [UIColor colorWithRed:.17 green:.17 blue:.17 alpha:1];
				tabBar.selectedImageTintColor = [UIColor colorWithRed:.33 green:.33 blue:.33 alpha:1];;
				break;
		}
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
		case THEME_NIGHT:
			toolbar.barStyle = UIBarStyleBlack;
			toolbar.tintColor = nil;
			break;
		case THEME_DARK:
			toolbar.tintColor = [UIColor colorWithRed:.17 green:.17 blue:.17 alpha:1];
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
		case THEME_NIGHT:
			// TODO: improve
			searchBar.barStyle = UIBarStyleBlack;
			searchBar.tintColor = nil;
			break;
		case THEME_DARK:
			searchBar.barStyle = UIBarStyleBlack;
			searchBar.tintColor = [UIColor colorWithWhite:.1 alpha:1];
			break;
	}
}

- (void)styleTableView:(UITableView *)tableView
{
	[self styleTableView:tableView isSlave:NO];
}

- (void)styleTableView:(UITableView *)tableView isSlave:(BOOL)slave
{
	UIColor *backgroundColor = nil;
	if(slave && currentTheme == THEME_DARK)
		backgroundColor = self.groupedTableViewBackgroundColor;
	else
		backgroundColor = (tableView.style == UITableViewStyleGrouped) ? self.groupedTableViewBackgroundColor : self.backgroundColor;
	tableView.backgroundColor = backgroundColor;
	NSIndexPath *indexPath = [tableView indexPathForSelectedRow];
	[tableView reloadData]; // force reload so the cells apply the new theme
	if(indexPath)
		[tableView selectRowAtIndexPath:indexPath animated:YES scrollPosition:UITableViewScrollPositionNone];
}

- (UITableViewCell *)styleTableViewCell:(UITableViewCell *)cell inTableView:(UITableView *)tableView
{
	return [self styleTableViewCell:cell inTableView:tableView asSlave:NO multiSelected:NO];
}

- (UITableViewCell *)styleTableViewCell:(UITableViewCell *)cell inTableView:(UITableView *)tableView asSlave:(BOOL)slave
{
	return [self styleTableViewCell:cell inTableView:tableView asSlave:slave multiSelected:NO];
}

- (UITableViewCell *)styleTableViewCell:(UITableViewCell *)cell inTableView:(UITableView *)tableView asSlave:(BOOL)slave multiSelected:(BOOL)selected
{
	switch(currentTheme)
	{
		default:
		case THEME_DEFAULT:
		{
			if(tableView.style == UITableViewStylePlain)
			{
				// remove old background views
				cell.selectedBackgroundView = nil;
				if(![cell.backgroundView isMemberOfClass:[UIView class]])
					cell.backgroundView = nil;

				// create a new background view only if selected
				if(!cell.backgroundView && selected)
					cell.backgroundView = [[UIView alloc] init];
				if(selected)
					cell.backgroundView.backgroundColor = [UIColor colorWithRed:223.0f/255.0f green:230.0f/255.0f blue:250.0f/255.0f alpha:1.0f];
				else
					cell.backgroundView.backgroundColor = [UIColor clearColor];
			}
			if(cell.selectionStyle == UITableViewCellSelectionStyleGray)
				cell.selectionStyle = UITableViewCellSelectionStyleBlue;
			cell.backgroundColor = [UIColor whiteColor];
			break;
		}
		case THEME_BLUE:
		{
			if(tableView.style == UITableViewStyleGrouped)
			{
				if(cell.selectionStyle == UITableViewCellSelectionStyleGray)
					cell.selectionStyle = UITableViewCellSelectionStyleBlue;
				cell.backgroundColor = self.backgroundColor;
			}
			else
			{
				UIImage *image = selected ? [UIImage imageNamed:@"Cell_BlueSelected.png"] : [UIImage imageNamed:@"Cell_Blue.png"];
				cell.backgroundView = [[UIImageView alloc] initWithImage:image];
				cell.backgroundColor = nil;
				image = [UIImage imageNamed:@"CellHighlighted_Blue.png"];
				cell.selectedBackgroundView = [[UIImageView alloc] initWithImage:image];
			}
			break;
		}
		case THEME_NIGHT:
		{
			UIColor *backgroundColor = nil;
			if(tableView.style == UITableViewStylePlain)
			{
				// remove old background views
				cell.selectedBackgroundView = nil;
				if(![cell.backgroundView isMemberOfClass:[UIView class]])
					cell.backgroundView = nil;

				// create a new background view only if selected
				if(!cell.backgroundView && selected)
					cell.backgroundView = [[UIView alloc] init];
				if(selected)
					cell.backgroundView.backgroundColor = [UIColor colorWithRed:.12 green:.12 blue:.12 alpha:1];
				else
					cell.backgroundView.backgroundColor = [UIColor clearColor];
			}
			else
				backgroundColor = [UIColor colorWithRed:.12 green:.12 blue:.12 alpha:1];
			if(cell.selectionStyle == UITableViewCellSelectionStyleBlue)
				cell.selectionStyle = UITableViewCellSelectionStyleGray;
			cell.backgroundColor = backgroundColor;
			break;
		}
		case THEME_DARK:
		{
			UIColor *backgroundColor = nil;
			if(tableView.style == UITableViewStylePlain)
			{
				if(selected)
					slave = !slave;
				backgroundColor = nil;
				UIImage *image = slave ? [UIImage imageNamed:@"Cell_DarkGroup.png"] : [UIImage imageNamed:@"Cell_Dark.png"];
				cell.backgroundView = [[UIImageView alloc] initWithImage:image];
				cell.selectedBackgroundView = nil;
			}
			else
				backgroundColor = [UIColor colorWithRed:.35 green:.35 blue:.35 alpha:1];
			if(cell.selectionStyle == UITableViewCellSelectionStyleBlue)
				cell.selectionStyle = UITableViewCellSelectionStyleGray;
			cell.backgroundColor = backgroundColor;
			break;
		}
	}
	return cell;
}

- (void)styleRefreshHeader:(EGORefreshTableHeaderView *)refreshHeader
{
	const BOOL isIos5 = [UIDevice newerThanIos:5.0f];
	switch(currentTheme)
	{
		default:
			refreshHeader.statusLabel.textColor = [UIColor colorWithRed:87.0f/255.0f green:108.0f/255.0f blue:137.0f/255.0f alpha:1.0f];
			refreshHeader.statusLabel.shadowColor = [UIColor colorWithWhite:0.9f alpha:1.0f];
			refreshHeader.arrorImage.contents = (id)[UIImage imageNamed:@"blueArrow.png"].CGImage;
			if(isIos5)
				refreshHeader.activityView.color = nil;
			refreshHeader.activityView.activityIndicatorViewStyle = UIActivityIndicatorViewStyleGray;
			break;
		case THEME_NIGHT:
			refreshHeader.statusLabel.textColor = self.textColor;
			refreshHeader.arrorImage.contents = (id)[UIImage imageNamed:@"grayArrow.png"].CGImage;
			refreshHeader.statusLabel.shadowColor = nil;
			refreshHeader.activityView.activityIndicatorViewStyle = UIActivityIndicatorViewStyleGray;
			if(isIos5)
				refreshHeader.activityView.color = self.textColor;
			break;
		case THEME_DARK:
			refreshHeader.statusLabel.textColor = self.textColor;
			refreshHeader.statusLabel.shadowColor = nil;
			refreshHeader.arrorImage.contents = (id)[UIImage imageNamed:@"whiteArrow.png"].CGImage;
			refreshHeader.activityView.activityIndicatorViewStyle = UIActivityIndicatorViewStyleWhite;
			if(isIos5)
				refreshHeader.activityView.color = self.textColor;
			break;
	}
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
#ifndef defaultSectionHeaderHeight
#define defaultSectionHeaderHeight 34
#endif
	if(currentTheme == THEME_DEFAULT)
		return defaultSectionHeaderHeight;
	return 40.0;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
	if(currentTheme == THEME_DEFAULT)
		return nil;
	NSString *text = [tableView.dataSource tableView:tableView titleForHeaderInSection:section];
	if(!text)
		return nil;

	UIView *headerView = nil;
	CGRect labelFrame;
	UIColor *color = nil;
	UIFont *font = nil;
	switch(currentTheme)
	{
		default:
		//case THEME_BLUE:
		{
			if(tableView.style == UITableViewStylePlain)
			{
				UIImage *image = [UIImage imageNamed:@"Header_Blue.png"];
				headerView = [[UIImageView alloc] initWithImage:image];
				labelFrame = headerView.frame;
				labelFrame.origin.x += 10; labelFrame.size.width -= 10;
				font = [UIFont fontWithName:@"Georgia" size:20];
			}
			else
			{
				headerView = [[UIView alloc] initWithFrame:CGRectMake(10.0, 0.0, 300.0, 40.0)];
				headerView.backgroundColor = [UIColor clearColor];
				labelFrame = CGRectMake(IS_IPAD() ? 50 : 13, 0, 260, 40);
				color = [UIColor darkBlueColor];
				font = [UIFont fontWithName:@"Georgia-Italic" size:17];
			}
			break;
		}
		case THEME_NIGHT:
		{
			if(tableView.style == UITableViewStylePlain)
			{
				GradientView *gradientView = [[GradientView alloc] initWithFrame:CGRectMake(10.0, 0.0, 300.0, 44.0)];
				[gradientView gradientFrom:[UIColor colorWithHue:0 saturation:0 brightness:.2 alpha:.75] to:[UIColor colorWithHue:0 saturation:0 brightness:0 alpha:.35] center:YES];
				headerView = gradientView;
				labelFrame = CGRectMake(10.0, 0.0, 300.0, 40.0);
			}
			else
			{
				headerView = [[UIView alloc] initWithFrame:CGRectMake(10.0, 0.0, 300.0, 44.0)];
				headerView.backgroundColor = [UIColor clearColor];
				labelFrame = CGRectMake(IS_IPAD() ? 30 : 13, 0, 260, 40);
			}
			font = [UIFont fontWithName:@"Helvetica" size:20];
			break;
		}
		case THEME_DARK:
		{
			if(tableView.style == UITableViewStylePlain)
			{
				GradientView *gradientView = [[GradientView alloc] initWithFrame:CGRectMake(10.0, 0.0, 300.0, 44.0)];
				[gradientView gradientFrom:[UIColor colorWithRed:.35 green:.35 blue:.35 alpha:.75] to:[UIColor colorWithRed:.17 green:.17 blue:.17 alpha:.46] center:YES];
				headerView = gradientView;
				labelFrame = CGRectMake(10.0, 0.0, 300.0, 40.0);
				font = [UIFont fontWithName:@"Georgia" size:20];
			}
			else
			{
				headerView = [[UIView alloc] initWithFrame:CGRectMake(10.0, 0.0, 300.0, 44.0)];
				headerView.backgroundColor = [UIColor clearColor];
				labelFrame = CGRectMake(IS_IPAD() ? 45 : 13, 0, 260, 40);
				font = [UIFont fontWithName:@"Georgia-Italic" size:18];
			}
			break;
		}
	}

	if(headerView)
	{
		UILabel *headerLabel = [[UILabel alloc] initWithFrame:labelFrame];
		headerLabel.backgroundColor = [UIColor clearColor];
		headerLabel.opaque = NO;
		headerLabel.textColor = color ? color : self.sectionLabelColor;
		headerLabel.font = font;
		headerLabel.text = text;
		UIColor *shadowColor = self.sectionLabelShadowColor;
		if(shadowColor)
		{
			headerLabel.shadowColor = shadowColor;
			headerLabel.shadowOffset = CGSizeMake(0, 1);
		}
		[headerView addSubview:headerLabel];

		return headerView;
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
			return [UIColor whiteColor];
		case THEME_BLUE:
			return [UIColor colorWithRed:0.95 green:0.95 blue:0.95 alpha:1];
		case THEME_NIGHT:
			return [UIColor blackColor];
		case THEME_DARK:
			return [UIColor colorWithRed:.33 green:.33 blue:.33 alpha:1];
	}
}

- (UIColor *)groupedTableViewBackgroundColor
{
	switch(currentTheme)
	{
		default:
			return [UIColor groupTableViewBackgroundColor];
		case THEME_NIGHT:
			return [UIColor blackColor];
		case THEME_DARK:
			return [UIColor colorWithRed:.18 green:.18 blue:.18 alpha:1];
	}
}

// NOTE: redundant to styling the theme as we DON'T use this function there, but needed for display cells.
- (UIColor *)groupedTableViewCellColor
{
	switch(currentTheme)
	{
		default:
			return self.backgroundColor;
		case THEME_NIGHT:
			return [UIColor colorWithRed:.12 green:.12 blue:.12 alpha:1];
	}
}

- (UIColor *)textColor
{
	switch(currentTheme)
	{
		default:
			return [UIColor blackColor];
		case THEME_NIGHT:
			return [UIColor grayColor];
		case THEME_DARK:
			return [UIColor whiteColor];
	}
}

- (UIColor *)highlightedTextColor
{
	switch(currentTheme)
	{
		default:
			return [UIColor whiteColor];
		case THEME_NIGHT:
			return [UIColor grayColor];
	}
}

- (UIColor *)detailsTextColor
{
	switch(currentTheme)
	{
		default:
			return [UIColor grayColor];
		case THEME_NIGHT:
			return [UIColor darkGrayColor];
		case THEME_DARK:
			return [UIColor lightGrayColor];
	}
}

- (UIColor *)highlightedDetailsTextColor
{
	switch(currentTheme)
	{
		default:
			return [UIColor whiteColor];
		case THEME_NIGHT:
			return [UIColor darkGrayColor];
	}
}

- (UIColor *)tintColor
{
	switch(currentTheme)
	{
		default:
			return nil;
		case THEME_BLUE:
			return [UIColor colorWithRed:0.16 green:0.36 blue:0.66 alpha:1];
		case THEME_DARK:
			return [UIColor colorWithRed:.33 green:.33 blue:.33 alpha:1];
		case THEME_NIGHT:
			return [UIColor colorWithHue:0 saturation:0 brightness:.05 alpha:1];
	}
}

- (UIColor *)sectionLabelColor
{
	switch(currentTheme)
	{
		default:
			return [UIColor whiteColor];
		case THEME_BLUE:
			return [UIColor colorWithRed:0.95 green:0.95 blue:0.95 alpha:1];
		case THEME_NIGHT:
			return [UIColor lightGrayColor];
	}
}

- (UIColor *)sectionLabelShadowColor
{
	switch(currentTheme)
	{
		default:
			return nil;
		case THEME_NIGHT:
		case THEME_DARK:
			return [UIColor grayColor];
	}
}

- (UIImage *)sliderImage
{
	switch(currentTheme)
	{
		default:
			return nil;
		case THEME_BLUE:
			return [[UIImage imageNamed:@"Slider_Blue.png"] stretchableImageWithLeftCapWidth:10.0 topCapHeight:0.0];
		case THEME_DARK:
			return [[UIImage imageNamed:@"Slider_Dark.png"] stretchableImageWithLeftCapWidth:10.0 topCapHeight:0.0];
		case THEME_NIGHT:
			return [[UIImage imageNamed:@"Slider_Night.png"] stretchableImageWithLeftCapWidth:10.0 topCapHeight:0.0];
	}
}

- (UIImage *)multiEpgCurrentBackground
{
	switch(currentTheme)
	{
		case THEME_BLUE:
			return [UIImage imageNamed:@"Mepg_Current_Blue.png"];
		case THEME_DARK:
			return [UIImage imageNamed:@"Cell_Dark.png"];
		default:
			return nil;
	}
}

- (UIColor *)multiEpgCurrentFillColor
{
	switch(currentTheme)
	{
		default:
			return [UIColor greenColor];
		case THEME_NIGHT:
			return [UIColor lightGrayColor];
	}
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

- (CGFloat)timerCellHeight
{
	return 50;
}

- (CGFloat)simulatedTimerCellHeight
{
	return 65;
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
