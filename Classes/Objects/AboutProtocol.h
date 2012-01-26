//
//  AboutProtocol.h
//  dreaMote
//
//  Created by Moritz Venn on 08.01.11.
//  Copyright 2011-2012 Moritz Venn. All rights reserved.
//

#import <Foundation/Foundation.h>

//#import <Objects/Generic/Harddisk.h>

/*!
 @brief Interface of About.
 */
@protocol AboutProtocol

/*!
 @brief Receiver System Version.
 */
@property (nonatomic, strong) NSString *version;

/*!
 @brief Receiver Image Version.
 */
@property (nonatomic, strong) NSString *imageVersion;

/*!
 @brief Receiver Model.
 */
@property (nonatomic, strong) NSString *model;

/*!
 @brief Installed Harddisk(s).
 */
@property (nonatomic, strong) NSArray *hdd;

/*!
 @brief Installed Tuners.
 */
@property (nonatomic, strong) NSArray *tuners;

/*!
 @brief Current Service Name.
 */
@property (nonatomic, strong) NSString *sname;

@end
