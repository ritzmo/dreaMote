//
//  Timer.h
//  dreaMote
//
//  Created by Moritz Venn on 04.01.09.
//  Copyright 2009-2011 Moritz Venn. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "EventProtocol.h"
#import "TimerProtocol.h"
#import "ServiceProtocol.h"

/*!
 @brief Timer in SVDRP.
 */
@interface SVDRPTimer : NSObject <TimerProtocol>
{
@private
	NSString *_auxiliary; /*!< @brief ??? */
	NSString *_eit; /*!< @brief Event Id. */
	NSDate *_begin; /*!< @brief Begin. */
	NSDate *_end; /*!< @brief End. */
	NSString *_file; /*!< @brief ??? */
	NSInteger _flags; /*!< @brief ??? */
	BOOL _disabled; /*!< @brief Disabled? */
	NSString *_title; /*!< @brief Title. */
	NSString *_tdescription; /*!< @brief Description. */
	NSString *_repeat; /*!< @brief ??? */
	NSInteger _repeated; /*!< @brief ??? */
    NSInteger _repeatcount; /*!< @brief ??? */
	BOOL _justplay; /*!< @brief Justplay? */
	NSString *_lifetime; /*!< @brief ??? */
	NSString *_priority; /*!< @brief ??? */
	NSObject<ServiceProtocol> *_service; /*!< @brief Service. */
	NSString *_sref; /*!< @brief Service Reference. */
	NSString *_sname; /*!< @brief Service Name. */
	NSInteger _state; /*!< @brief State. */
	NSInteger _afterevent; /*!< @brief After Event Action. */
	BOOL _isValid; /*!< @brief Valid or Fake Timer? */
	NSString *_timeString; /*!< @brief Cache for Begin/End Textual representation. */
	NSString *_tid; /*!< @brief Timer Id. */
	BOOL _hasRepeatBegin; /*!< @brief ??? */
}


/*!
 @brief Generate string representation of Timer.
 
 @return String representation of Timer.
 */
- (NSString *)toString;



/*!
 @brief ???
 */
@property (nonatomic, strong) NSString *auxiliary;

/*!
 @brief ???
 */
@property (nonatomic, strong) NSString *lifetime;

/*!
 @brief ???
 */
@property (nonatomic, strong) NSString *file;

/*!
 @brief ???
 */
@property (nonatomic) NSInteger flags;

/*!
 @brief ???
 */
@property (nonatomic) BOOL hasRepeatBegin;

/*!
 @brief ???
 */
@property (nonatomic, strong) NSString *repeat;

/*!
 @brief Priority.
 */
@property (nonatomic, strong) NSString *priority;

/*!
 @brief Timer Id.
 */
@property (nonatomic, strong) NSString *tid;

@end
