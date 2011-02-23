//
//  CampfireConnectionDelegate.h
//  Smores
//
//  Created by Gordon on 1/4/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

@protocol CampfireConnectionDelegate <NSObject>

- (void)campfireConnectionDidRecieveInformation:(NSString *)responseString;
- (void)campfireConnectionDidFail;

@end
