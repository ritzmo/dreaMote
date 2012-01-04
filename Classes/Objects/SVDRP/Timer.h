//
//  Timer.h
//  dreaMote
//
//  Created by Moritz Venn on 04.01.09.
//  Copyright 2009-2011 Moritz Venn. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <Objects/Generic/Timer.h>

/*!
 @brief Timer in SVDRP.
 */
@interface SVDRPTimer : GenericTimer

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
