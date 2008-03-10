//
//  MyCustomCell.h
//  Untitled
//
//  Created by Moritz Venn on 09.03.08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MyCustomCell : UITableViewCell
{
	NSDictionary	*dataDictionary;
	UILabel			*nameLabel;
	UILabel			*explainLabel;
}

@property (nonatomic, retain) NSDictionary *dataDictionary;
@property (nonatomic, assign) UILabel *nameLabel;
@property (nonatomic, assign) UILabel *explainLabel;

@end
