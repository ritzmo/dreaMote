//
//  MultiEPGTableView.h
//  dreaMote
//
//  Created by Moritz Venn on 27.01.11.
//  Copyright 2011 Moritz Venn. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface MultiEPGTableView : UITableView
{
@private
	CGPoint _lastTouch;
}

@property (nonatomic) CGPoint lastTouch;

@end
