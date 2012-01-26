//
//  FileProtocol.h
//  dreaMote
//
//  Created by Moritz Venn on 05.01.11.
//  Copyright 2011-2012 Moritz Venn. All rights reserved.
//

#import <Foundation/Foundation.h>

/*!
 @brief Protocol of a File.
 */
@protocol FileProtocol

/*!
 @brief File title.
 */
@property (nonatomic, strong) NSString *title;

/*!
 @brief File Reference.
 */
@property (nonatomic, strong) NSString *sref;

/*!
 @brief Actually a directory?
 */
@property (nonatomic) BOOL isDirectory;

/*!
 @brief Root folder.
 */
@property (nonatomic, strong) NSString *root;

/*!
 @brief Valid or Fake File.
 */
@property (nonatomic) BOOL valid;

@end
