//
//  Timer.h
//  dreaMote
//
//  Created by Moritz Venn on 01.01.09.
//  Copyright 2008-2011 Moritz Venn. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "CXMLNode.h"

#import "TimerProtocol.h"
#import "ServiceProtocol.h"

/*!
 @brief Timer in Enigma.
 */
@interface EnigmaTimer : NSObject <TimerProtocol>
{
@private
	NSDate *_begin; /*!< @brief Begin. */
	NSDate *_end; /*!< @brief End. */
	NSString *_title; /*!< @brief Title. */
	BOOL _justplay; /*!< @brief Justplay? */
	NSObject<ServiceProtocol> *_service; /*!< @brief Service. */
	NSInteger _state; /*!< @brief State. */
	NSInteger _afterevent; /*!< @brief After Event Action. */
	double _duration; /*!< @brief Duration. */
	BOOL _isValid; /*!< @brief Valid or Fake Timer? */
	NSString *_timeString; /*!< @brief Cache for Begin/End Textual representation. */
	NSInteger _repeated; /*!< @brief Repeated Flags. */

	// Unfortunately we need a helpers...
	// Why I hear you ask? Because the values can actually evaluate to false
	// and the code would just re-read the values all over again...
	BOOL _typedataSet; /*!< @brief Flags were read. */

	CXMLNode *_node; /*!< @brief CXMLNode describing this Timer. */
}

/*!
 @brief Standard initializer.
 
 @param node Pointer to CXMLNode describing this Timer.
 @return EnigmaTimer instance.
 */
- (id)initWithNode: (CXMLNode *)node;

@end
