//
//  ColoredAccessoryView.h
//  dreaMote
//
//  Based on DTCustomColoredAccessory from http://www.cocoanetics.com/2010/10/custom-colored-disclosure-indicators/
//
//  Created by Moritz Venn on 09.11.11.
//  Copyright (c) 2011 Moritz Venn. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ColoredAccessoryView : UIControl

+ (ColoredAccessoryView *)accessoryViewWithColor:(UIColor *)color andHighlightedColor:(UIColor *)highlightedColor forAccessoryType:(UITableViewCellAccessoryType)accessoryType;

@property (nonatomic, assign) UITableViewCellAccessoryType accessoryType;
@property (nonatomic, strong) UIColor *accessoryColor;
@property (nonatomic, strong) UIColor *highlightedColor;

@end
