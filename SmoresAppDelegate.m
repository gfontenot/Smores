//
//  SmoresAppDelegate.m
//  Smores
//
//  Created by Gordon on 2/22/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "SmoresAppDelegate.h"
#import "Campfire.h"
#import "JSON.h"

@implementation SmoresAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
	
	NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
	
	if (![prefs stringForKey:@"api_key"]) {
		[self showLoginPane:self];
	} else {
		[self campfireLogin];
	}
	
	[GrowlApplicationBridge setGrowlDelegate:nil];
	
	allUsers = [[NSMutableDictionary alloc] init];
	
	smoresStatusItem = [[[NSStatusBar systemStatusBar] statusItemWithLength:NSSquareStatusItemLength] retain];
	
	NSImage *statusImage = [NSImage imageNamed:@"smores-status"];
	[smoresStatusItem setImage:statusImage];
	alertIconDisplayed = NO;
	[smoresStatusItem setHighlightMode:YES];
	
	[smoresStatusItem setMenu:smoresStatusMenu];
}

- (void)campfireConnectionDidRecieveInformation:(NSString *)responseString {
	NSMutableArray *responseArray = [[responseString componentsSeparatedByString:@"}"] mutableCopy];
	[responseArray removeLastObject];
	for (NSString *messageItem in responseArray) {
		NSDictionary *messageDict = [[NSString stringWithFormat:@"%@}", messageItem] JSONValue];
		if (![[messageDict objectForKey:@"type"] isEqualToString:@"TimestampMessage"]) {
			
			if ([notificationTimer isValid]) {
				[notificationTimer invalidate];
			}
			
			if (alertIconDisplayed) {
				notificationTimer = [NSTimer scheduledTimerWithTimeInterval:90 target:self selector:@selector(toggleStatusIcon) userInfo:nil repeats:NO];
				[notificationTimer retain];
			} else {
				[self toggleStatusIcon];
			}
			
			NSString *msgString = [messageDict valueForKey:@"body"];
			NSString *regex = [NSString stringWithFormat:@".*%@.*", [campfireConnection.me valueForKey:@"name"]];
			
			NSPredicate *regexTest = [NSPredicate predicateWithFormat:@"SELF MATCHES[cd] %@", regex];
			
			if ([regexTest evaluateWithObject:msgString] == YES) {
				
				if (![allUsers objectForKey:[messageDict valueForKey:@"user_id"]]) {
					[campfireConnection listUsersInRoom:[messageDict valueForKey:@"room_id"]];
				}
				
				
				NSDictionary *user = [allUsers objectForKey:[messageDict valueForKey:@"user_id"]];
				
				NSString *userName = [user valueForKey:@"name"];
				
				NSString *titleString = [NSString stringWithFormat:@"Campfire mention from %@", userName];
				
				[self growlAlert:msgString title:titleString];
			}
		}
	}
}

- (void)storeUserList:(NSArray *)userList forRoomID:(NSString *)room_id {
	for (NSDictionary *user in userList) {
		NSMutableDictionary *userInfo = [[NSMutableDictionary alloc] init];
		for (NSString *key in user) {
			if (![key isEqualToString:@"id"]) {
				[userInfo setValue:[user valueForKey:key] forKey:key];
			}
		}
		
		[allUsers setValue:userInfo forKey:[user valueForKey:@"id"]];
		
	}
}


- (IBAction)showLoginPane:(id)sender {
	
	if ([[NSUserDefaults standardUserDefaults] stringForKey:@"api_key"]) {
		[apiKeyField setStringValue:[[NSUserDefaults standardUserDefaults] stringForKey:@"api_key"]];
		[baseDomainField setStringValue:[[NSUserDefaults standardUserDefaults] stringForKey:@"base_domain"]];
	}
	
	[loginWindow makeKeyAndOrderFront:NSApp];
	
}

- (IBAction)savePrefs:(id)sender {
	
	if([[baseDomainField stringValue] isEqualToString:@""] || [[apiKeyField stringValue]isEqualToString:@""]) {
		NSAlert *loginAlert = [NSAlert alertWithMessageText:@"You must supply both an API Key and a Base Domain name to continue." defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:@""];
		[loginAlert beginSheetModalForWindow:loginWindow modalDelegate:nil didEndSelector:nil contextInfo:nil];
	} else {
		NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
		[prefs setObject:[apiKeyField stringValue] forKey:@"api_key"];
		[prefs setObject:[baseDomainField stringValue] forKey:@"base_domain"];
		[prefs synchronize];
		[loginWindow close];
		
		[self campfireLogin];	
	}
}

- (void)toggleStatusIcon {
	
	alertIconDisplayed = !alertIconDisplayed;
	
	
	NSImage *statusImage = [NSImage imageNamed:[NSString stringWithFormat:@"smores-status%@", (alertIconDisplayed) ? @"-alert" : @""]];
	[smoresStatusItem setImage:statusImage];
	
}

- (void)campfireLogin {
	
	[campfireConnection stopListening];
	
	campfireConnection = [[Campfire alloc] initWithBaseDomain:[[NSUserDefaults standardUserDefaults] stringForKey:@"base_domain"] andUser:[[NSUserDefaults standardUserDefaults] stringForKey:@"api_key"]];
	campfireConnection.delegate = self;
	
	for (NSString *roomID in campfireConnection.availableRoomIDs) {
		[campfireConnection connectToRoom:roomID andBeginStream:YES];
	}
	
	[campfireConnection startListening];
	
}

- (void)growlAlert:(NSString *)message title:(NSString *)title {
	[GrowlApplicationBridge notifyWithTitle:title description:message notificationName:@"test" iconData:nil priority:0 isSticky:NO clickContext:nil];
}

@end
