//
//  UITableViewCell+EasyInit.h
//  dreaMote
//
//  Created by Moritz Venn on 22.03.11.
//  Copyright 2011-2012 Moritz Venn. All rights reserved.
//

#import <Foundation/Foundation.h>

/*!
 @brief Convenience functions for table view cell initialization.
 */
@interface UITableViewCell (EasyInit)
/*!
 @brief Reusable cell with default style.

 @param tableView Table view to request cell from.
 @param identifier Identifier used by cell.
 @return Reusable cell or newly created one.
 */
+ (id)reusableTableViewCellInView:(UITableView *)tableView withIdentifier:(NSString *)identifier;

/*!
 @brief Reusable cell with custom style.

 @param style Style to use in initialization.
 @param tableView Table view to request cell from.
 @param identifier Identifier used by cell.
 @return Reusable cell or newly created one.
 */
+ (id)reusableTableViewCellWithStyle:(UITableViewCellStyle)style inTableView:(UITableView *)tableView withIdentifier:(NSString *)identifier;
@end
