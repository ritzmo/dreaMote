//
//  ServiceProtocol.h
//  dreaMote
//
//  Created by Moritz Venn on 01.01.09.
//  Copyright 2008-2012 Moritz Venn. All rights reserved.
//

#import <Foundation/Foundation.h>

/*!
 @brief Protocol of a Service.
 */
@protocol ServiceProtocol

/*!
 @brief Service Reference.
 */
@property (nonatomic, strong) NSString *sref;

/*!
 @brief Name.
 */
@property (nonatomic, strong) NSString *sname;

/*!
 @brief Valid or Fake Service.
 */
@property (nonatomic, readonly, getter = isValid) BOOL valid;

/*!
 @brief Picon already loaded?
 */
@property (nonatomic, readonly) BOOL piconLoaded;

/*!
 @brief Picon.
 */
@property (nonatomic, readonly) UIImage *picon;



/*!
 @brief Check equality with another Service.
 
 @param otherService Service to check equality with.
 @return YES if equal.
 */
- (BOOL)isEqualToService: (NSObject<ServiceProtocol> *)otherService;

@end
