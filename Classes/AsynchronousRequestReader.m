//
//  AsynchronousRequestReader.m
//  dreaMote
//
//  Created by Moritz Venn on 13.02.12.
//  Copyright (c) 2012 Moritz Venn. All rights reserved.
//

#import "AsynchronousRequestReader.h"

#import <Constants.h>

@interface SynchronousRequestReader()
- (void)sendSynchronousRequest:(NSURL *)url withTimeout:(NSTimeInterval)timeout;
- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)connectionError;
- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)d;
- (void)connectionDidFinishLoading:(NSURLConnection *)connection;
@end

@implementation AsynchronousRequestReader

@synthesize dataReceivedBlock, errorBlock, finishedBlock;

+ (void)sendAsynchronousRequest:(NSURL *)url receivedBlock:(asynchronousRequestReaderDataReceived_t)receivedBlock errorBlock:(asynchronousRequestReaderError_t)errorBlock finishedBlock:(asynchronousRequestReaderFinished_t)finishedBlock
{
	AsynchronousRequestReader *arr = [[AsynchronousRequestReader alloc] init];
	arr.dataReceivedBlock = receivedBlock;
	arr.errorBlock = errorBlock;
	arr.finishedBlock = finishedBlock;

	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
		[arr sendSynchronousRequest:url withTimeout:kTimeout];
	});
}

+ (NSData *)sendSynchronousRequest:(NSURL *)url returningResponse:(NSURLResponse **)response error:(NSError **)error withTimeout:(NSTimeInterval)timeout
{
#if IS_DEBUG()
	[NSException raise:@"ExcWrongClass" format:@"Tried to send synchronous request using %@", [self class]];
#endif
	return nil;
}

#pragma mark - NSURLConnection delegate methods

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)connectionError
{
	if(errorBlock)
		errorBlock(connectionError);
	[super connection:connection didFailWithError:connectionError];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)d
{
	if(dataReceivedBlock)
		dataReceivedBlock(d);
	[super connection:connection didReceiveData:d];
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)resp
{
	// ignore
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
	if(finishedBlock)
		finishedBlock();
	[super connectionDidFinishLoading:connection];
}

@end
