//
//  Constants.m
//  PasswordUtility
//
//  Created by Zack Smith on 8/22/11.
//  Copyright 2011 318. All rights reserved.
//

#import "Constants.h"


@implementation Constants
// Standard Notfications
// Standard Notfications
NSString * const SettingsFileResourceID = @"com.gene.settings";

# pragma mark NSNotifications
//Plugin Notifications
NSString * const PluginsHaveLoadedNotfication = @"PluginsHaveLoadedNotfication";
NSString * const NetCheckInProgressNotification = @"NetCheckInProgressNotification";
NSString * const NetCheckFinishedNotification = @"NetCheckFinishedNotification";
NSString * const NetCheckPassedNotification = @"NetCheckPassedNotification";
NSString * const ScriptCompletedNotification = @"ScriptCompletedNotification";
NSString * const StatusUpdateNotification = @"StatusUpdateNotification";
NSString * const ReceiveStatusUpdateNotification = @"ReceiveStatusUpdateNotification";
NSString * const RequestStatusUpdateNotification = @"RequestStatusUpdateNotification";

// NSTask constants
NSString * const TaskPassed = @"Passed";
NSString * const TaskWarning = @"Warning";
NSString * const TaskCritical = @"Critical";

NSString * const UserPictureInvalidOutput = @"invalid";



@end
