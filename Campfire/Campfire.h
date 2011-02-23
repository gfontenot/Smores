//
//  Campfire.h
//  Smores
//
//  Created by Gordon on 1/3/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ASIHTTPRequestDelegate.h"
#import "CampfireConnectionDelegate.h"

@class ASINetworkQueue;

@interface Campfire : NSObject <ASIHTTPRequestDelegate> {
	
	id <CampfireConnectionDelegate> delegate;
	
@private
	ASINetworkQueue *streamingQueue;
    NSString *baseURI;
	NSString *api_token;
	NSString *authValue;
	NSMutableData *responseData;
	NSMutableArray *availableRoomIDs;
	NSDictionary *me;
	NSMutableDictionary *allUsers;
	
}
@property (nonatomic, retain) id <CampfireConnectionDelegate> delegate;
@property (nonatomic, retain) NSString *authValue;
@property (nonatomic, retain) NSString *baseURI;
@property (nonatomic, retain) NSString *api_token;
@property (nonatomic, retain) NSMutableArray *availableRoomIDs;
@property (nonatomic, retain) NSDictionary *me;
@property (retain) ASINetworkQueue *streamingQueue;

- (id)initWithBaseDomain:(NSString *)base_domain andUser:(NSString *)user;
- (void)connectToRoom:(NSString *)room_id andBeginStream:(BOOL)startStream;
- (void)makeAPICall:(NSString *)url_string withAuth:(BOOL)auth forMethod:(NSString *)httpMethod synchronously:(BOOL)synchronous;
- (void)storeUsersInRoom:(NSString *)room_id;
- (NSString *)userNameForID:(NSString *)user_id roomID:(NSString *)room_id;
- (void)storeAvailableRooms;
- (void)storeUserInfo;
- (void)stopListening;
- (void)startListening;
@end