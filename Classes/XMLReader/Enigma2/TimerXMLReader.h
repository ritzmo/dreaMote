//
//  TimerXMLReader.h
//  dreaMote
//
//  Created by Moritz Venn on 31.12.08.
//  Copyright 2008-2011 Moritz Venn. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "BaseXMLReader.h"
#import "TimerSourceDelegate.h"

/*!
 @brief Enigma2 Timer XML Reader.
 */
@interface Enigma2TimerXMLReader : BaseXMLReader
{
@private
	NSObject<TimerSourceDelegate> *_delegate; /*!< @brief Delegate. */
}

/*!
 @brief Standard initializer.
 
 @param target Delegate.
 @return Enigma2TimerXMLReader instance.
 */
- (id)initWithDelegate:(NSObject<TimerSourceDelegate> *)delegate;

@end
