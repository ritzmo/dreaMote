//
//  SynchonousRequestReader.h
//  dreaMote
//
//  Created by Moritz Venn on 17.01.11.
//  Copyright 2011 Moritz Venn. All rights reserved.
//

#import <Foundation/Foundation.h>

/*!
 @brief Synchronous Downloader.

 Used to retrieve data via http(s) from remote hosts synchronously.
 */
@interface SynchronousRequestReader : NSObject
{
@protected
	BOOL _running; /*!< @brief Still downloading? */
}

/*!
 @brief Fetch data synchronously.

 @param url URL to download.
 @param response Can be used to retrieve the request.
 @param error Can be used to retrieve connection errors.
 @param timeout Timeout to use.
 @return Retrieved data.
 */
+ (NSData *)sendSynchronousRequest:(NSURL *)url returningResponse:(NSURLResponse **)response error:(NSError **)error withTimeout:(NSTimeInterval)timeout;

/*!
 @brief Fetch data synchronously using default timeout.

 @param url URL to download.
 @param response Can be used to retrieve the request.
 @param error Can be used to retrieve connection errors.
 @return Retrieved data.
 */
+ (NSData *)sendSynchronousRequest:(NSURL *)url returningResponse:(NSURLResponse **)response error:(NSError **)error;

/*!
 @brief Error.
 */
@property (nonatomic, strong) NSError *error;

@end
