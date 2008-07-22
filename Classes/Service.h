//
//  Service.h
//  Untitled
//
//  Created by Moritz Venn on 08.03.08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Service : NSObject
{
@private
	NSString *_sref;
	NSString *_sname;
}

- (NSString *)getServiceReference;
- (NSString *)getServiceName;

@property (nonatomic, retain) NSString *sref;
@property (nonatomic, retain) NSString *sname;

@end
