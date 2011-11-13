//
//  FastTableViewCell.h
//  dreaMote
//
//  Created by Moritz Venn on 13.11.11.
//  Copyright (c) 2011 Moritz Venn. All rights reserved.
//

#import "BaseTableViewCell.h"

@protocol FastTableViewCellProtocol
- (void)drawContentRect:(CGRect)rect;
@end

@interface FastTableViewCell : BaseTableViewCell<FastTableViewCellProtocol>

@end
