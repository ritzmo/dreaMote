//
//  EventXMLReader.h
//  dreaMote
//
//  Created by Moritz Venn on 31.12.08.
//  Copyright 2008-2011 Moritz Venn. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "BaseXMLReader.h"
#import "EventSourceDelegate.h"
#import "NowNextSourceDelegate.h"

enum delegateType
{
	kDelegateTypeEvent,
	kDelegateTypeNow,
	kDelegateTypeNext,
};

/*!
 @brief Enigma2 Event XML Reader.
 */
@interface Enigma2EventXMLReader : BaseXMLReader
{
@private
	enum delegateType _delegateType; /*!< @brief Type of delegate. */
	NSObject *_delegate; /*!< @brief Delegate. */
}

/*!
 @brief Standard initializer.
 
 @param target Delegate.
 @return Enigma2EventXMLReader instance.
 */
- (id)initWithDelegate:(NSObject<EventSourceDelegate> *)delegate;

/*!
 @brief Standard initializer.
 
 @param target Delegate.
 @return Enigma2EventXMLReader instance.
 */
- (id)initWithNowDelegate:(NSObject<NowSourceDelegate> *)delegate;

/*!
 @brief Standard initializer.
 
 @param target Delegate.
 @return Enigma2EventXMLReader instance.
 */
- (id)initWithNextDelegate:(NSObject<NextSourceDelegate> *)delegate;

@end
