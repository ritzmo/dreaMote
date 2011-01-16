//
//  CurrentXMLReader.h
//  dreaMote
//
//  Created by Moritz Venn on 26.10.09.
//  Copyright 2009-2011 Moritz Venn. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "BaseXMLReader.h"
#import "EventSourceDelegate.h"
#import "ServiceSourceDelegate.h"

/*!
 @brief Enigma2 getcurrent XML Reader.
 */
@interface Enigma2CurrentXMLReader : BaseXMLReader
{
}

/*!
 @brief Standard initializer.
 
 @param target Delegate.
 @return Enigma2CurrentXMLReader instance.
 */
- (id)initWithDelegate:(NSObject<EventSourceDelegate,ServiceSourceDelegate> *)delegate;

@end
