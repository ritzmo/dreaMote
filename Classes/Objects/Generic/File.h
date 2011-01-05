//
//  File.h
//  dreaMote
//
//  Created by Moritz Venn on 05.01.11.
//  Copyright 2011 Moritz Venn. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "FileProtocol.h"

/*!
 @brief Generic File.
 */
@interface GenericFile : NSObject <FileProtocol>
{
@private
	NSString *_sref; /*!< @brief Reference. */
	BOOL _isDirectory; /*!< @brief Directory?. */
	NSString *_root; /*!< @brief Root. */
	BOOL _valid; /*!< @brief Valid file? */
}

@end
