//
//  PlayListCell.h
//  dreaMote
//
//  Created by Moritz Venn on 29.05.11.
//  Copyright 2011-2012 Moritz Venn. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <TableViewCell/MultiSelectionTableViewCell.h>

#import <Objects/FileProtocol.h>

// cell identifier for this custom cell
extern NSString *kPlayListCell_ID;

@interface PlayListCell : MultiSelectionTableViewCell

/*!
 @brief Currently displayed file.
 */
@property (nonatomic, strong) NSObject<FileProtocol> *file;

@end
