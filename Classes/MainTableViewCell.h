//
//  MainTableViewCell.h
//  Untitled
//
//  Created by Moritz Venn on 08.03.08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MainTableViewCell : UITableViewCell
{
@private
	NSDictionary	*dataDictionary;
	UILabel			*nameLabel;
	UILabel			*explainLabel;
}

@property (nonatomic, retain) NSDictionary *dataDictionary;
@property (nonatomic, retain) UILabel *nameLabel;
@property (nonatomic, retain) UILabel *explainLabel;

@end
