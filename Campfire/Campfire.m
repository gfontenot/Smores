//
//  Campfire.m
//  Smores
//
//  Created by Gordon on 1/3/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "Campfire.h"
#import "JSON.h"
#import "ASIHTTPRequest.h"
#import "ASIFormDataRequest.h"
#import "ASINetworkQueue.h"

@implementation Campfire

@synthesize authValue;
@synthesize baseURI;
@synthesize api_token;
@synthesize delegate;
@synthesize availableRoomIDs;
@synthesize streamingQueue;
@synthesize me;


- (id)initWithBaseDomain:(NSString *)base_domain andUser:(NSString *)user {
    if ((self = [super init])) {
		self.baseURI = [NSString stringWithFormat:@"https://%@.campfirenow.com", base_domain];
		self.api_token = user;
		self.availableRoomIDs = [[NSMutableArray alloc] init];
		[self setStreamingQueue:[ASINetworkQueue queue]];
		[self.streamingQueue setRequestDidFailSelector:@selector(requestFailed:)];
		[self storeAvailableRooms];
		[self storeUserInfo];
		allUsers = [[NSMutableDictionary alloc] init];
    }
    return self;
}

- (void)dealloc {
    // Clean-up code here.
    
	self.baseURI = nil;
	self.api_token = nil;
    [super dealloc];
}

- (void)stopListening {
	[self.streamingQueue cancelAllOperations];
}

- (void)startListening {
	[self.streamingQueue go];
}

- (void)storeAvailableRooms {
	__block ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@/rooms.json", baseURI]]];
	[request setUsername:self.api_token];
	[request setPassword:@"X"];
	[request setCompletionBlock:^{
		NSString *responseString = [[NSString alloc] initWithData:[request responseData] encoding:NSUTF8StringEncoding];
		NSDictionary *responseDict = [responseString JSONValue];
		[responseString release];
		NSArray *rooms = [responseDict valueForKey:@"rooms"];
		for (NSDictionary *room in rooms) {
			[self.availableRoomIDs addObject:[room valueForKey:@"id"]];
		}
	}];
	[request startSynchronous];
}

- (void)storeUserInfo {
	__block ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@/users/me.json", baseURI]]];
	[request setUsername:self.api_token];
	[request setPassword:@"X"];
	[request setCompletionBlock:^{
		NSString *responseString = [[NSString alloc] initWithData:[request responseData] encoding:NSUTF8StringEncoding];
		NSDictionary *responseDict = [responseString JSONValue];
		[responseString release];
		self.me = [responseDict valueForKey:@"user"];
	}];
	[request startSynchronous];
}

- (void)connectToRoom:(NSString *)room_id andBeginStream:(BOOL)startStream {
	NSString *api_url = [NSString stringWithFormat:@"%@/room/%@/join.json", baseURI, room_id];
	[self makeAPICall:api_url withAuth:YES forMethod:@"POST" synchronously:YES];
	[self storeUsersInRoom:room_id];

	if (startStream) {
		NSString *api_url = [NSString stringWithFormat:@"https://streaming.campfirenow.com/room/%@/live.json", room_id];
		[self makeAPICall:api_url withAuth:YES forMethod:@"GET" synchronously:NO];
	}
	
}

- (void)storeUsersInRoom:(NSString *)room_id {
	__block ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@/room/%@.json", baseURI, room_id]]];
	[request setUsername:self.api_token];
	[request setPassword:@"X"];
	[request setCompletionBlock:^{
		NSString *responseString = [[NSString alloc] initWithData:[request responseData] encoding:NSUTF8StringEncoding];
		NSDictionary *responseDict = [responseString JSONValue];
		[responseString release];
		NSArray *userList = [[responseDict valueForKey:@"room"] valueForKey:@"users"];
		for (NSDictionary *user in userList) {
			NSMutableDictionary *userInfo = [[NSMutableDictionary alloc] init];
			for (NSString *key in user) {
				if (![key isEqualToString:@"id"]) {
					[userInfo setValue:[user valueForKey:key] forKey:key];
				}
			}
			
			[allUsers setValue:userInfo forKey:[[user valueForKey:@"id"] stringValue]];
		}
	}];
	[request startSynchronous];
}

-(NSString *)userNameForID:(NSString *)user_id roomID:(NSString *)room_id {
	
	if (![allUsers objectForKey:user_id]) {
		NSLog(@"User not found");
		[self storeUsersInRoom:room_id];
	}
	
	NSDictionary *user = [allUsers objectForKey:user_id];
	
	return [user valueForKey:@"name"];
}

- (void)makeAPICall:(NSString *)url_string withAuth:(BOOL)auth forMethod:(NSString *)httpMethod synchronously:(BOOL)synchronous {
	
	responseData = [[NSMutableData data] retain];
	
	ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:[NSURL URLWithString:url_string]];
	if (httpMethod == @"POST") {
		[request appendPostData:[@"Join room" dataUsingEncoding:NSUTF8StringEncoding]];
	}
	if (auth) {
		[request setUsername:self.api_token];
		[request setPassword:@"X"];
	}
	[request setDelegate:self];
	if (synchronous) {
		[request startSynchronous];
	} else {
		[self.streamingQueue addOperation:request];
	}
}

- (void)request:(ASIHTTPRequest *)request didReceiveData:(NSData *)data {
	if ([data length] > 1 && [[request responseStatusMessage] compare:@"HTTP/1.1 200 OK"] == NSOrderedSame) {
		NSString *responseString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
		
		[delegate campfireConnectionDidRecieveInformation:responseString];
		[responseString release];
		
	}
}

- (void)requestFailed:(ASIHTTPRequest *)request {
	NSLog(@"Connection lost");
	[delegate campfireConnectionDidFail];
}


@end
