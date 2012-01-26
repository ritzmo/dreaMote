//
//  File.h
//  dreaMote
//
//  Created by Moritz Venn on 05.01.11.
//  Copyright 2011-2012 Moritz Venn. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <Objects/FileProtocol.h>

/*!
 @brief Generic File.
 */
@interface GenericFile : NSObject <FileProtocol>

/*!
 @brief Init with existing fie.
 
 @note Required to create a copy.
 @param file File to copy.
 @return File instance.
 */
- (id)initWithFile: (NSObject<FileProtocol> *)file;

@end
