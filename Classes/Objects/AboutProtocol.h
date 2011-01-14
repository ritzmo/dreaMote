//
//  AboutProtocol.h
//  dreaMote
//
//  Created by Moritz Venn on 08.01.11.
//  Copyright 2011 Moritz Venn. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "Generic/Harddisk.h"

/*!
 @brief Interface of About.
 */
@protocol AboutProtocol

/*!
 @brief Receiver System Version.
 */
@property (nonatomic, readonly) NSString *version;

/*!
 @brief Receiver Image Version.
 */
@property (nonatomic, readonly) NSString *imageVersion;

/*!
 @brief Receiver Model.
 */
@property (nonatomic, readonly) NSString *model;

/*!
 @brief Installed Harddisk.
 */
@property (nonatomic, readonly) Harddisk *hdd;

/*!
 @brief Installed Tuners.
 */
@property (nonatomic, readonly) NSArray *tuners;

/*!
 @brief Current Service Name.
 */
@property (nonatomic, readonly) NSString *sname;

@end
