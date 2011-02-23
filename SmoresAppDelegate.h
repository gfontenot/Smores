//
//  SmoresAppDelegate.h
//  Smores
//
//  Created by Gordon on 2/22/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "CampfireConnectionDelegate.h"
#import "Growl.framework/Headers/GrowlApplicationBridge.h"

@class Campfire;

@interface SmoresAppDelegate : NSObject <NSApplicationDelegate, CampfireConnectionDelegate, GrowlApplicationBridgeDelegate> {
    NSStatusItem *smoresStatusItem;
	IBOutlet NSMenu *smoresStatusMenu;
	IBOutlet NSMenuItem *smoresPrefMenuItem;

	IBOutlet NSWindow *loginWindow;
	IBOutlet NSTextField *apiKeyField;
	IBOutlet NSTextField *baseDomainField;
	
	Campfire *campfireConnection;
	
	NSTimer *notificationTimer;
	
	BOOL alertIconDisplayed;
	
	NSMutableDictionary *allUsers;
}

- (void)toggleStatusIcon;
- (void)growlAlert:(NSString *)message title:(NSString *)title;
- (IBAction)savePrefs:(id)sender;
- (IBAction)showLoginPane:(id)sender;
- (void)campfireLogin;

@end
