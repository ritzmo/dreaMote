//
//  NSString+URLEncode.h
//  dreaMote
//
//  Created by Moritz Venn on 05.01.11.
//  Copyright 2011 Moritz Venn. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface NSString (URLEncode)

- (NSString *)urlencodeWithEncoding:(NSStringEncoding)stringEncoding;
- (NSString *)urlencode;

@end
