//
//  TimerXMLReader.h
//  dreaMote
//
//  Created by Moritz Venn on 31.12.08.
//  Copyright 2008-2010 Moritz Venn. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "BaseXMLReader.h"
#import "TimerSourceDelegate.h"

/*!
 @brief Enigma Timer XML Reader.
 */
@interface EnigmaTimerXMLReader : BaseXMLReader
{
@private
	NSObject<TimerSourceDelegate> *_delegate; /*!< @brief Delegate. */
}

/*!
 @brief Standard initializer.
 
 @param target Delegate.
 @return EnigmaTimerXMLReader instance.
 */
- (id)initWithDelegate:(NSObject<TimerSourceDelegate> *)delegate;

@end
