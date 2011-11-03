//
//  UITableViewCell+EasyInit.m
//  dreaMote
//
//  Created by Moritz Venn on 22.03.11.
//  Copyright 2011 Moritz Venn. All rights reserved.
//

#import "UITableViewCell+EasyInit.h"

@implementation UITableViewCell (EasyInit)

+ (id)reusableTableViewCellInView:(UITableView *)tableView withIdentifier:(NSString *)identifier
{
	return [self reusableTableViewCellWithStyle:UITableViewCellStyleDefault inTableView:tableView withIdentifier:identifier];
}

+ (id)reusableTableViewCellWithStyle:(UITableViewCellStyle)style inTableView:(UITableView *)tableView withIdentifier:(NSString *)identifier
{
	id cell = [tableView dequeueReusableCellWithIdentifier:identifier];
	if(!cell)
		cell = [[[self class] alloc] initWithStyle:style reuseIdentifier:identifier];
	return cell;
}

@end
