//
//  SignalSourceDelegate.h
//  dreaMote
//
//  Created by Moritz Venn on 26.06.09.
//  Copyright 2009-2012 Moritz Venn. All rights reserved.
//

#import "Signal.h"

#import "DataSourceDelegate.h"

/*!
 @brief SignalSourceDelegate.

 Objects wanting to be called back by a Signal Source (e.g. Sat Finder)
 need to implement this Protocol.
 */
@protocol SignalSourceDelegate <DataSourceDelegate>

/*!
 @brief New object was created and should be added to list.
 
 @param anItem Signal to add.
 */
- (void)addSignal: (GenericSignal *)anItem;

@end

