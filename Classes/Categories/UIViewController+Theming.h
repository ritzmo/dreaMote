//
//  UIViewController+Theming.h
//  dreaMote
//
//  Created by Moritz Venn on 08.11.11.
//  Copyright (c) 2011 Moritz Venn. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIViewController(Theming)

- (void)startObservingThemeChanges;
- (void)theme;
- (void)stopObservingThemeChanges;

@end
