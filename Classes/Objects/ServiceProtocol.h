//
//  ServiceProtocol.h
//  Untitled
//
//  Created by Moritz Venn on 01.01.09.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol ServiceProtocol

@property (nonatomic, retain) NSString *sref;
@property (nonatomic, retain) NSString *sname;
@property (nonatomic, readonly, getter = isValid) BOOL valid;

- (NSArray *)nodesForXPath: (NSString *)xpath error: (NSError **)error;

@end
