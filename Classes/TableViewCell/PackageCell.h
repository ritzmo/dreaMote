//
//  PackageCell.h
//  dreaMote
//
//  Created by Moritz Venn on 17.10.11.
//  Copyright 2011 Moritz Venn. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <TableViewCell/MultiSelectionTableViewCell.h>

#import <Objects/Generic/Package.h>

// cell identifier for this custom cell
extern NSString *kPackageCell_ID;

@interface PackageCell : MultiSelectionTableViewCell

@property (nonatomic, strong) Package *package;

@end