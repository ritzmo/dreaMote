//
//  TagSourceDelegate.h
//  dreaMote
//
//  Created by Moritz Venn on 20.11.11.
//  Copyright (c) 2011 Moritz Venn. All rights reserved.
//

#import <Delegates/DataSourceDelegate.h>
#import <Objects/Generic/Tag.h>

@protocol TagSourceDelegate <DataSourceDelegate>
/*!
 @brief New object was created and should be added to list.

 @param anItem Tag to add.
 */
- (void)addTag:(Tag *)anItem;
@end
