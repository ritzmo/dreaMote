//
//  SynchonousRequestReader.m
//  dreaMote
//
//  Created by Moritz Venn on 17.01.11.
//  Copyright 2011 Moritz Venn. All rights reserved.
//

#import "SynchonousRequestReader.h"

#import "Constants.h"

@interface SynchonousRequestReader()
- (BOOL)connection:(NSURLConnection *)connection canAuthenticateAgainstProtectionSpace:(NSURLProtectionSpace *)protectionSpace;
- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error;
- (void)connection:(NSURLConnection *)connection didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge;
- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data;
- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response;
- (NSCachedURLResponse *)connection:(NSURLConnection *)connection willCacheResponse:(NSCachedURLResponse *)cachedResponse;
- (void)connectionDidFinishLoading:(NSURLConnection *)connection;

@property (nonatomic, retain) NSData *data;
@property (nonatomic, retain) NSError *error;
@property (nonatomic, retain) NSURLResponse *response;
@property (nonatomic) BOOL running;
@end

@implementation SynchonousRequestReader

@synthesize data = _data;
@synthesize error = _error;
@synthesize response = _response;
@synthesize running = _running;

- (id)init
{
	if((self = [super init]))
	{
		_data = [[NSMutableData alloc] init];
		_running = YES;
	}
	return self;
}

- (void)dealloc
{
	[_data release];
	[_error release];
	[_response release];

	[super dealloc];
}

+ (NSData *)sendSynchronousRequest:(NSURL *)url returningResponse:(NSURLResponse **)response error:(NSError **)error withTimeout:(NSTimeInterval)timeout
{
	SynchonousRequestReader *srr = [[SynchonousRequestReader alloc] init];
	NSData *data = [srr.data retain];
	NSURLRequest *request = [NSURLRequest requestWithURL:url
											 cachePolicy:NSURLRequestReloadIgnoringCacheData
										 timeoutInterval:kDefaultTimeout];
	NSURLConnection *con = [[NSURLConnection alloc] initWithRequest:request delegate:srr];

	[UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
	do
	{
		[[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
	} while(srr.running);
	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;

	// hand over response & error if requested
	if(response)
		*response = [[srr.response retain] autorelease];
	if(error)
		*error = [[srr.error retain] autorelease];

	[con release];
	[srr release];
	return [data autorelease];
}

+ (NSData *)sendSynchronousRequest:(NSURL *)url returningResponse:(NSURLResponse **)response error:(NSError **)error
{
	return [SynchonousRequestReader sendSynchronousRequest:url returningResponse:response error:error withTimeout:kDefaultTimeout];
	
}

#pragma mark -
#pragma mark NSURLConnection delegate methods
#pragma mark -

- (BOOL)connection:(NSURLConnection *)connection canAuthenticateAgainstProtectionSpace:(NSURLProtectionSpace *)protectionSpace
{
	return [protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust];
}

- (void)connection:(NSURLConnection *)connection didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge
{
	if([challenge.protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust])
	{
		// TODO: ask user to accept certificate
		[challenge.sender useCredential:[NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust]
			 forAuthenticationChallenge:challenge];
	}
	else
	{
		// NOTE: continue just swallows all errors while cancel gives a weird message,
		// but a weird message is better than no response
		//[challenge.sender continueWithoutCredentialForAuthenticationChallenge:challenge];
		[challenge.sender cancelAuthenticationChallenge:challenge];
	}
}

- (NSCachedURLResponse *)connection:(NSURLConnection *)connection willCacheResponse:(NSCachedURLResponse *)cachedResponse
{
	return nil;
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
	self.error = error;
	_running = NO;
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
	[_data appendData:data];
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
	self.response = response;
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
	_running = NO;
}

@end
