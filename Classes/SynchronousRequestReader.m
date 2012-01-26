//
//  SynchronousRequestReader.m
//  dreaMote
//
//  Created by Moritz Venn on 17.01.11.
//  Copyright 2011 Moritz Venn. All rights reserved.
//

#import "SynchronousRequestReader.h"

#import <Constants.h>

#import <Delegates/AppDelegate.h>
#import <Connector/RemoteConnectorObject.h>

@interface SynchronousRequestReader()
@property (nonatomic, strong) NSMutableData *data;
@property (nonatomic, strong) NSURLResponse *response;
@property (nonatomic) BOOL running;
@end

@implementation SynchronousRequestReader

@synthesize data, response;
@synthesize error;
@synthesize running = _running;

- (id)init
{
	if((self = [super init]))
	{
		_running = YES;
	}
	return self;
}


+ (NSData *)sendSynchronousRequest:(NSURL *)url returningResponse:(NSURLResponse **)response error:(NSError **)error withTimeout:(NSTimeInterval)timeout
{
	SynchronousRequestReader *srr = [[SynchronousRequestReader alloc] init];
	NSURLRequest *request = [[NSURLRequest alloc] initWithURL:url
												  cachePolicy:NSURLRequestReloadIgnoringCacheData
											  timeoutInterval:timeout];
	NSURLConnection *con = nil;
	if(request)
		con = [[NSURLConnection alloc] initWithRequest:request delegate:srr];
#if IS_DEBUG()
	else
		[NSException raise:@"ExcSRRNoRequest" format:@""];

	if(!con)
		[NSException raise:@"ExcSRRNoConnection" format:@""];
#endif

	srr.running = YES;
	[APP_DELEGATE addNetworkOperation];
	while(con && srr.running)
	{
		[[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
	}
	[APP_DELEGATE removeNetworkOperation];
	[con cancel]; // just in case, cancel the connection

	// hand over response & error if requested
	if(response)
		*response = srr.response;
	if(error)
		*error = srr.error;

	return srr.data;
}

+ (NSData *)sendSynchronousRequest:(NSURL *)url returningResponse:(NSURLResponse **)response error:(NSError **)error
{
	return [SynchronousRequestReader sendSynchronousRequest:url returningResponse:response error:error withTimeout:kTimeout];
}

#pragma mark -
#pragma mark NSURLConnection delegate methods
#pragma mark -

- (BOOL)connection:(NSURLConnection *)connection canAuthenticateAgainstProtectionSpace:(NSURLProtectionSpace *)protectionSpace
{
	return YES;
}

- (void)connection:(NSURLConnection *)connection didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge
{
	if([challenge.protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust])
	{
		// TODO: ask user to accept certificate
		[challenge.sender useCredential:[NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust]
			 forAuthenticationChallenge:challenge];
		return;
	}
	else if([challenge previousFailureCount] < 2) // ssl might have failed already
	{
		NSURLCredential *creds = [RemoteConnectorObject getCredential];
		if(creds)
		{
			[challenge.sender useCredential:creds forAuthenticationChallenge:challenge];
			return;
		}
	}

	// NOTE: continue just swallows all errors while cancel gives a weird message,
	// but a weird message is better than no response
	//[challenge.sender continueWithoutCredentialForAuthenticationChallenge:challenge];
	[challenge.sender cancelAuthenticationChallenge:challenge];
}

- (NSCachedURLResponse *)connection:(NSURLConnection *)connection willCacheResponse:(NSCachedURLResponse *)cachedResponse
{
	return nil;
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)connectionError
{
	self.error = connectionError;
	_running = NO;
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)d
{
	[data appendData:d];
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)resp
{
	long long size = 0;
	if([resp respondsToSelector:@selector(expectedContentLength)])
		size = [(NSHTTPURLResponse *)resp expectedContentLength];
	if(size == NSURLResponseUnknownLength)
		size = 0;
	self.data = [[NSMutableData alloc] initWithCapacity:(NSUInteger)size];

	self.response = resp;
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
	_running = NO;
}

@end
