//
//  AboutSourceDelegate.h
//  dreaMote
//
//  Created by Moritz Venn on 08.01.11.
//  Copyright 2011 Moritz Venn. All rights reserved.
//

#import "AboutProtocol.h"

#import "DataSourceDelegate.h"

/*!
 @brief AboutSourceDelegate.

 Objects wanting to be called back by a About Source (e.g. Receiver information)
 need to implement this Protocol.
 */
@protocol AboutSourceDelegate <DataSourceDelegate>

/*!
 @brief New object was created and should be added to list.
 
 @param anItem About to add.
 */
- (void)addAbout: (NSObject<AboutProtocol> *)anItem;

@end

