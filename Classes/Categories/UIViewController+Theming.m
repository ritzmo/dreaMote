//
//  UIViewController+Theming.m
//  dreaMote
//
//  Created by Moritz Venn on 08.11.11.
//  Copyright (c) 2011 Moritz Venn. All rights reserved.
//

#import "UIViewController+Theming.h"

#import "Constants.h"
#import "DreamoteConfiguration.h"

@interface UIViewController(Theming_Private)
- (void)doTheme:(NSNotification *)note;
@end

@implementation UIViewController(Theming)

- (void)theme
{
	DreamoteConfiguration *singleton = [DreamoteConfiguration singleton];
	if(self.navigationController)
		[singleton styleNavigationController:self.navigationController];
	if([self respondsToSelector:@selector(searchBar)])
		[singleton styleSearchBar:[(id)self searchBar]];
	if([self respondsToSelector:@selector(toolbar)])
		[singleton styleToolbar:[(id)self toolbar]];
	if([self respondsToSelector:@selector(tableView)])
		[singleton styleTableView:[(id)self tableView]];
}

- (void)doTheme:(NSNotification *)note
{
	[self theme];
}

- (void)startObservingThemeChanges
{
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(doTheme:) name:kThemeChangedNotification object:nil];
}

- (void)stopObservingThemeChanges
{
	[[NSNotificationCenter defaultCenter] removeObserver:self name:kThemeChangedNotification object:nil];
}

@end
