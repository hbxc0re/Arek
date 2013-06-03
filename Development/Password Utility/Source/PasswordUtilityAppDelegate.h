//
//  PasswordUtilityAppDelegate.h
//  PasswordUtility
//
//  Created by Zack Smith on 11/16/11.
//  Copyright 2011 318 All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Quartz/Quartz.h>
#import <ApplicationServices/ApplicationServices.h>
@class IKImageView;

@class Plugins;
@class GlobalStatus;


@interface PasswordUtilityAppDelegate : NSObject {
    NSWindow *window;
	// Out Image Kit
	IBOutlet IKImageView *userPictureView;

	// Our Text Fields
	IBOutlet NSTextField *unixIdField;
	IBOutlet NSSecureTextField *oldPasswordField;
	IBOutlet NSTextField *oldPasswordClearField;
	
	IBOutlet NSButton *togglePasswordButton;

	IBOutlet NSSecureTextField *newPasswordField;
	IBOutlet NSSecureTextField *verifyNewPasswordField;
	// Our Progress Indicator
	IBOutlet NSProgressIndicator *unixIdProgressIndicator;
	IBOutlet NSProgressIndicator *oldPasswordProgressIndicator;
	IBOutlet NSProgressIndicator *newPasswordProgressIndicator;
	IBOutlet NSProgressIndicator *mainProgressIndicator;
	IBOutlet NSProgressIndicator *netProgressIndicator;

	// Out Buttons
	IBOutlet NSButton *mainButton;
	// NSImageView - Our User Picture
	IBOutlet NSImageView *mainPicture;
	// NSBox
	IBOutlet NSBox *oldPasswordBox;
	IBOutlet NSBox *newPasswordBox;
	IBOutlet NSBox *mainProgressBox;
	
	// Our NSPanel Boxes
	IBOutlet NSBox *netProgressBox;
	IBOutlet NSBox *netMainBox;
	// NSPanels
	IBOutlet NSPanel *networkCheckPanel;
	IBOutlet NSPanel *processCompletePanel;

	// Our Network Check Panel
	IBOutlet NSImageView *alertIcon;
	IBOutlet NSTextField *alertTextField;

	IBOutlet NSButton *opengConnectButton;
	IBOutlet NSButton *notNowButton;
	IBOutlet NSButton *tryAgainButton;
	
	IBOutlet NSString *oldPassword;
	IBOutlet NSLevelIndicator *scriptIndicator;
	
	BOOL windowNeedsResize;
	BOOL debugEnabled;
	BOOL processComplete;
	// Our Custom classes
	Plugins *plugins;
		
	// Reference to this bundle
	NSBundle *mainBundle;
	NSDictionary *settings;
	NSNumber *numberOfScripts;
	
	GlobalStatus  *globalStatusController;



}

@property (assign) IBOutlet NSWindow *window;

@property (retain) NSString* oldPassword;

- (void)readInSettings;
- (void)closeAllBoxes;
// Display NSAlert Methods -- should consolidate
- (void)displayPasswordMismatchAlert;
- (void)displayInvalidUnixID;
- (void)displayCancelWarning;
- (void)displayInvalidNewCredentials;
// User Picture Stuff
- (void)setUserPicture:(NSString *)userPictureLocation;
- (void)stopMainProgressIndicator;
- (void)stopMainProgressIndicator;
- (void)startUnixIdProgressIndicator;
- (void)stopUnixIdProgressIndicator;
- (void)startNewPasswordProgressIndicator;
- (void)stopNewPasswordProgressIndicator;

- (void)expandMainProgressBox;
- (void)displayNetworkPanel;
- (NSString *)getUserPictureScript;
- (NSString *)checkUserScript;

// Our Various Button Actions
- (IBAction)expandOldPasswordBox:(id)sender;
- (IBAction)expandNewPasswordBox:(id)sender;
- (IBAction)updateUsersPassword:(id)sender;
- (IBAction)focusOnVerifyField:(id)sender;
- (IBAction)cancelOperation:(id)sender;


- (void)openPageInSafari:(NSString *)url;
// Out NSButton Methods


- (IBAction)opengConnectButtonPressed:(id)sender;
- (IBAction)notNowButtonPressed:(id)sender;
- (IBAction)tryAgainButtonPressed:(id)sender;
- (IBAction)processCompleteOKButtonPressed:(id)sender;
- (IBAction)showOldPasswordToggle:(id)sender;
// NSPanel Methods
- (void)closeNetworkCheckPanel;
- (void)closeProcessCompletePanel;
- (BOOL)netCheckScript;

- (void)openNetProgressBox;
- (void)openNetMainBox;
- (void)closeNetProgressBox;
- (void)closeNetMainBox;
- (void)quit;

- (void)networkCheckInProgress;
- (void)networkCheckFinished;
- (void)hideMainBoxContent:(BOOL)hide;
- (BOOL)checkBindScript;
- (void)displayProcessCompeletePanel;
- (void) reloadLevelIndicator:(NSNotification *) notification;
- (void)saveLastRunDate;
- (void)softReboot;
@end
