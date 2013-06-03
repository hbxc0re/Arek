//
//  PasswordUtilityAppDelegate.m
//  PasswordUtility
//
//  Created by Zack Smith on 11/16/11.
//  Copyright 2011 318 All rights reserved.
//

#import "PasswordUtilityAppDelegate.h"
#import "Plugins.h"
#import "GlobalStatus.h"
#import "Constants.h"


@implementation PasswordUtilityAppDelegate

@synthesize window;
@synthesize oldPassword;

# pragma mark -
# pragma mark Method Overrides
# pragma mark -

-(id)init
{
    // Super init
	[ super init];
	if(debugEnabled)NSLog(@"Init OK App Delegate Controller Initialized");
	setuid(0);

	// Read in our Settings
	[ self readInSettings];
	// Register for Notifications
	//NetCheckInProgressNotification
	[[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(networkCheckInProgress) 
                                                 name:NetCheckInProgressNotification
                                               object:nil];
	//NetCheckFinishedNotification
	[[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(networkCheckFinished) 
                                                 name:NetCheckFinishedNotification
                                               object:nil];
	//NetCheckPassedNotification
	[[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(closeNetworkCheckPanel) 
                                                 name:NetCheckPassedNotification
                                               object:nil];
	
	//ScriptCompletedNotification
	[[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(reloadLevelIndicator:) 
                                                 name:ScriptCompletedNotification
                                               object:nil];
	
	//PluginsHaveLoadedNotfication
	[[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(quit) 
                                                 name:PluginsHaveLoadedNotfication
                                               object:nil];
	
	// Init our controller
	if (!globalStatusController) {
		globalStatusController = [[GlobalStatus alloc] init];
	}
	// And Return
	if (!self) return nil;
    return self;
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
	// Stop Lion from saving state
	// This seems not to work when called from root
	// https://github.com/macbrained/PasswordUtility/issues/9
	if([[NSUserDefaults standardUserDefaults] objectForKey: @"ApplePersistenceIgnoreState"] == nil)
		[[NSUserDefaults standardUserDefaults] setBool: YES forKey:@"ApplePersistenceIgnoreState"];
	// Show the progress panel
	[self displayNetworkPanel];
	// Start our network Script
	[NSThread detachNewThreadSelector:@selector(netCheckScript)
							 toTarget:self
						   withObject:nil];
}

- (void)awakeFromNib {
	
	NSUserDefaults *standardDefaults = [NSUserDefaults standardUserDefaults];
	// Check to make sure we are running by our helper.
	// /path/to/app -helper yes
	
	BOOL helper = ([standardDefaults objectForKey:@"helper"] != nil);
	if (!helper) {
		NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
		// Activate Our Application
		[NSApp arrangeInFront:self];
		[NSApp activateIgnoringOtherApps:YES];
		// Display a standard alert
		NSAlert *alert = [[NSAlert alloc] init];
		[alert addButtonWithTitle:@"Ok"];
		[alert setMessageText:@"Invalid Launch Type"];
		[alert setInformativeText:@"This tool is not meant to be launched directly"];
		[alert setAlertStyle:NSWarningAlertStyle];
		[alert runModal];
		[alert release];
		[pool release];
		[NSApp terminate:self];
	}
	// Set the we need a Window Resize
	windowNeedsResize = YES;
	[self closeAllBoxes];
	// Start By Expanding Old Progress Bar
	[mainButton setAction:@selector(expandOldPasswordBox:)];
	[userPictureView setHidden:YES];
	NSString *guessUnixID = [self checkUserScript];
	
	// Check if we were able to guess UNIXID
	if (![guessUnixID length] == 0) {
		[unixIdField setStringValue:guessUnixID];
		[mainButton setEnabled:YES];
	}
	else {
		[mainButton setEnabled:NO];
	}


}
# pragma mark -
# pragma mark Delegate Methods
# pragma mark -

- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
    [super dealloc];
}


- (void)windowWillClose:(NSNotification *)aNotification {
	// Quit the app when the window closes
	// BugFix for https://github.com/macbrained/PasswordUtility/issues/5
	[NSApp terminate:self];
}

# pragma mark -
# pragma mark Methods
# pragma mark -

- (void)readInSettings 
{ 	
	mainBundle = [NSBundle bundleForClass:[self class]];
	NSString *settingsPath = [mainBundle pathForResource:SettingsFileResourceID
												  ofType:@"plist"];
	settings = [[NSDictionary alloc] initWithContentsOfFile:settingsPath];
	debugEnabled = [[settings objectForKey:@"debugEnabled"] boolValue];
}




-(IBAction)focusOnVerifyField:(id)sender
{
	[verifyNewPasswordField becomeFirstResponder];
}

- (void)controlTextDidChange:(NSNotification *)nd
{
	if (![[unixIdField stringValue] length] == 0 ) {
		[mainButton setEnabled:YES];
	}
}

# pragma mark -
# pragma mark NSProgressIndicator  - mainProgressIndicator
# pragma mark -

-(void)startUnixIdProgressIndicator
{
	[ unixIdProgressIndicator startAnimation:self];
}

-(void)stopUnixIdProgressIndicator
{
	[ unixIdProgressIndicator stopAnimation:self];
}

-(void)startMainProgressIndicator
{
	[ mainProgressIndicator startAnimation:self];

}

-(void)stopMainProgressIndicator
{

	[ mainProgressIndicator stopAnimation:self];
	
}

-(void)stopNewPasswordProgressIndicator
{
	
	[ newPasswordProgressIndicator stopAnimation:self];
	
}
-(void)startNewPasswordProgressIndicator
{
	
	[ newPasswordProgressIndicator startAnimation:self];
	
}


#pragma mark -

-(NSString *)checkUserScript
{
	NSTask * task;
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	task = [[NSTask alloc] init];
	
	NSData *data;
	// Start
	NSPipe *pipe = [NSPipe pipe];
	
	//_fileHandle = [pipe fileHandleForReading];
	//[_fileHandle readInBackgroundAndNotify];
	// Grab both our system profile outputs
	NSString *getUserPicture = [mainBundle pathForResource:@"checkUser"
													ofType:@"sh"];
	[task setLaunchPath:getUserPicture];
	[task setArguments:[NSArray arrayWithObjects:nil]];
	[task setStandardOutput: pipe];
	//Set to help with Xcode debug log issues
	[task setStandardInput:[NSPipe pipe]];
	[task setStandardError: pipe];
	[task launch];
	//NSData *readData;
	NSFileHandle *file;
	file = [pipe fileHandleForReading];
	data = [file readDataToEndOfFile];
	// We now have our full results in a NSString
	NSString *text = [[NSString alloc] initWithData:data 
										   encoding:NSASCIIStringEncoding];
	if(debugEnabled)NSLog(@"Found Guess UserName: (%@)",text);
	[pool release];
	return text;
}

-(void)hideMainBoxContent:(BOOL)hide
{
	[alertIcon setHidden:hide];
	[alertTextField setHidden:hide];
	[opengConnectButton setHidden:hide];
	[notNowButton setHidden:hide];
	[tryAgainButton setHidden:hide];
}




-(BOOL)checkBindScript
{
	NSTask *task;
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	[self startNewPasswordProgressIndicator];
	// Notify panel to start showing progress bar
	
	[[NSNotificationCenter defaultCenter]
	 postNotificationName:NetCheckInProgressNotification
	 object:self];
	if ([[settings objectForKey:@"checkNetwork"] boolValue]) {
		return YES;
	}
	
	task = [[NSTask alloc] init];
	
	NSData *data;
	// Start
	NSPipe *pipe = [NSPipe pipe];
	
	//_fileHandle = [pipe fileHandleForReading];
	//[_fileHandle readInBackgroundAndNotify];
	// Grab both our system profile outputs
	NSString *getUserPicture = [mainBundle pathForResource:@"checkBind"
													ofType:@"sh"];
	[task setLaunchPath:getUserPicture];
	// Pass our new credentials to the script
	[task setArguments:[NSArray arrayWithObjects:@"-u",
						[unixIdField stringValue],
						@"-p",
						[newPasswordField stringValue],
						nil]];
	[task setStandardOutput: pipe];
	//Set to help with Xcode debug log issues
	[task setStandardInput:[NSPipe pipe]];
	[task setStandardError: pipe];
	[task launch];
	[task waitUntilExit];
	NSFileHandle *file;
	file = [pipe fileHandleForReading];
	data = [file readDataToEndOfFile];
	
	// Post Finished Notifications
	int exit = [task terminationStatus];
	
	// BOOL Return value based on exit code
	[self stopNewPasswordProgressIndicator];
	[ pool release];
	if (exit == 0)
	{
		return YES;
	}
	else {

		return NO;
	}
	return NO;
}


-(BOOL)netCheckScript
{
	NSTask *task;
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	// Notify panel to start showing progress bar
	
	[[NSNotificationCenter defaultCenter]
	 postNotificationName:NetCheckInProgressNotification
	 object:self];
	
	// Check override for testing
	if ([[settings objectForKey:@"checkNetwork"] boolValue]) {
		if(debugEnabled)NSLog(@"Overriding network check");
		//NetCheckFinishedNotification
		[[NSNotificationCenter defaultCenter]
		 postNotificationName:NetCheckPassedNotification
		 object:self];
		return YES;
	}
	
	task = [[NSTask alloc] init];
	
	NSData *data;
	// Start
	NSPipe *pipe = [NSPipe pipe];
	
	//_fileHandle = [pipe fileHandleForReading];
	//[_fileHandle readInBackgroundAndNotify];
	// Grab both our system profile outputs
	NSString *getUserPicture = [mainBundle pathForResource:@"netCheck"
													ofType:@"sh"];
	[task setLaunchPath:getUserPicture];
	[task setArguments:[NSArray arrayWithObjects:nil]];
	[task setStandardOutput: pipe];
	//Set to help with Xcode debug log issues
	[task setStandardInput:[NSPipe pipe]];
	[task setStandardError: pipe];
	[task launch];
	//NSData *readData;
	NSFileHandle *file;
	file = [pipe fileHandleForReading];
	data = [file readDataToEndOfFile];
	[task waitUntilExit];

	// We now have our full results in a NSString
	NSString *text = [[NSString alloc] initWithData:data 
										   encoding:NSASCIIStringEncoding];
	if(debugEnabled)NSLog(@"Network Script Ran (%@)",text);

	// Post Finished Notifications
	int exit = [task terminationStatus];
	[ pool release];
	// BOOL Return value based on exit code
	if (exit == 0) {
		//NetCheckFinishedNotification
		[[NSNotificationCenter defaultCenter]
		 postNotificationName:NetCheckPassedNotification
		 object:self];
		return YES;
	}
	else {
		//NetCheckPassedNotification
		[[NSNotificationCenter defaultCenter]
		 postNotificationName:NetCheckFinishedNotification
		 object:self];
		return NO;
	}
	return NO;
}

-(NSString *)getUserPictureScript
{
	NSTask       *task;
	task = [[NSTask alloc] init];
	
	
	NSData *data;
	// Start
	NSPipe *pipe = [NSPipe pipe];
	// Grab both our system profile outputs
	NSString *getUserPicture = [mainBundle pathForResource:@"getUserDetails"
													ofType:@"sh"];
	[task setLaunchPath:getUserPicture];
	[task setArguments:[NSArray arrayWithObjects:@"-u",
						[unixIdField stringValue],
						nil]];
	[task setStandardOutput: pipe];
	//Set to help with Xcode debug log issues
	[task setStandardInput:[NSPipe pipe]];
	[task setStandardError: pipe];
	[task launch];
	//NSData *readData;
	NSFileHandle *file;
	file = [pipe fileHandleForReading];
	data = [file readDataToEndOfFile];
	// We now have our full results in a NSString
	NSString *text = [[NSString alloc] initWithData:data 
										   encoding:NSASCIIStringEncoding];
	
	
	NSArray *components = [text componentsSeparatedByString:@"<result>"];
	NSString *returnValue ;
	if ([components count] > 0) {
		NSString *afterOpenBracket = [components objectAtIndex:1];
		components = [afterOpenBracket componentsSeparatedByString:@"</result>"];
		returnValue = [components objectAtIndex:0];
	}
	else {
		returnValue = UserPictureInvalidOutput;
	}
	
	
	
	if(debugEnabled)NSLog(@"Found Picture URL: (%@)",returnValue);
	
	
	return returnValue;
}


# pragma mark IKImageView
-(void)setUserPicture:(NSString *)userPictureLocation
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	NSURL *userPictureURL;
	userPictureURL = [NSURL URLWithString:userPictureLocation];
	[userPictureView performSelectorOnMainThread:@selector(setImageWithURL:)
									  withObject:userPictureURL
								   waitUntilDone:false];
	[userPictureView setHidden:NO];
	[pool release];

}

- (IBAction)cancelOperation:(id)sender
{
	[self displayCancelWarning];
}

- (IBAction)updateUsersPassword:(id)sender
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	if ([[ newPasswordField stringValue] isEqualToString:[verifyNewPasswordField stringValue]]) {
		if (![self checkBindScript]) {
			// Display and alert
			[self displayInvalidNewCredentials];
			// Reset the field to first responder
			[newPasswordField becomeFirstResponder];
			return;
		}
		plugins	= [[ Plugins alloc] init];
		
		// Set our script values
		plugins.userName = [unixIdField stringValue];
		plugins.oldPassword = [oldPasswordField stringValue];
		plugins.newPassword = [newPasswordField stringValue];
		
		[self expandMainProgressBox];
		[self startMainProgressIndicator];
		
		[NSThread detachNewThreadSelector:@selector(runPluginScripts:)
								 toTarget:plugins
							   withObject:self];
		
		[mainButton setAction:@selector(cancelOperation:)];
		[mainButton setEnabled:NO];
	}
	else {
		// Display an alert telling the user of the mismatch
		[self displayPasswordMismatchAlert];
		// Set focus on the new password field
		[newPasswordField becomeFirstResponder];

	}

	[pool release];
}

# pragma mark NSBox


- (IBAction)expandOldPasswordBox:(id)sender
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	[self startUnixIdProgressIndicator];
	// Process the User Picture
	NSString *userPhotoURL = [ self getUserPictureScript];
	if ([userPhotoURL isEqualTo:UserPictureInvalidOutput]) {
		[self displayInvalidUnixID];
		[self stopUnixIdProgressIndicator];
	}
	else {
		// ZS: Moved here as retries were not working.
		// Grey out the field so users cannot change it.
		[unixIdField setEditable:NO];
		[unixIdField setEnabled:NO];
		[self setUserPicture:userPhotoURL];
		[self stopUnixIdProgressIndicator];
		// Once done then
		NSRect frame = [window frame];
		// The extra +10 accounts for the space between the box and its neighboring views
		CGFloat sizeChange = [ oldPasswordBox frame].size.height;
		// Make the window bigger.
		frame.size.height += sizeChange;
		// Move the origin.
		frame.origin.y -= sizeChange;
		[window setFrame:frame display:YES animate:YES];
		// Show the extra box.
		[oldPasswordBox setHidden:NO];
		[mainButton setAction:@selector(expandNewPasswordBox:)];
		[self showOldPasswordToggle:self];
		
	}
	[pool release];
}

- (IBAction)expandNewPasswordBox:(id)sender
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	// Grey out the old password field
	[oldPasswordField setEditable:NO];
	[oldPasswordField setEnabled:NO];
	[oldPasswordClearField setEditable:NO];
	[oldPasswordClearField setEnabled:NO];
	NSRect frame = [window frame];
	// The extra +10 accounts for the space between the box and its neighboring views
	CGFloat sizeChange = [ newPasswordBox frame].size.height;
	// Make the window bigger.
	frame.size.height += sizeChange;
	// Move the origin.
	frame.origin.y -= sizeChange;
	[window setFrame:frame display:YES animate:YES];
	// Show the extra box.
	[newPasswordBox setHidden:NO];
	[newPasswordField becomeFirstResponder];
	// Override the Return Key
	[mainButton setEnabled:NO];
	[newPasswordField setAction:@selector(focusOnVerifyField:)];
	[mainButton setAction:@selector(updateUsersPassword:)];	
	[pool release];
	
}


- (void)openNetMainBox
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	[netMainBox setHidden:YES];
	NSRect frame = [networkCheckPanel frame];
	// The extra +10 accounts for the space between the box and its neighboring views
	CGFloat sizeChange = [ netMainBox frame].size.height;
	// Make the window bigger.
	frame.size.height += sizeChange;
	// Move the origin.
	frame.origin.y -= sizeChange;
	[networkCheckPanel setFrame:frame display:YES animate:YES];
	// Show the extra box.
	[netMainBox setHidden:NO];
	[self hideMainBoxContent:NO];
	[pool release];

	
}
- (void)openNetProgressBox
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	[netProgressBox setHidden:YES];
	NSRect frame = [networkCheckPanel frame];
	// The extra +10 accounts for the space between the box and its neighboring views
	CGFloat sizeChange = [ netProgressBox frame].size.height;
	// Make the window bigger.
	frame.size.height += sizeChange;
	// Move the origin.
	frame.origin.y -= sizeChange;
	[networkCheckPanel setFrame:frame display:YES animate:YES];
	// Show the extra box.
	[netProgressBox setHidden:NO];
	[pool release];

	
}

- (void)expandMainProgressBox
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	[newPasswordField setEditable:NO];
	[verifyNewPasswordField setEditable:NO];

	NSRect frame = [window frame];
	// The extra +10 accounts for the space between the box and its neighboring views
	CGFloat sizeChange = [ mainProgressBox frame].size.height;
	// Make the window bigger.
	frame.size.height += sizeChange;
	// Move the origin.
	frame.origin.y -= sizeChange;
	[window setFrame:frame display:YES animate:YES];
	// Show the extra box.
	[mainProgressBox setHidden:NO];
	[ mainButton setTitle:@"Cancel"];
	[ mainButton setHidden:YES];
	
	// Grab the number of scripts we have
	NSDictionary * scriptPlugins = [ settings objectForKey:@"scriptPlugins"];
	NSDictionary * mainRunLoopScripts = [ scriptPlugins objectForKey:@"mainRunLoopScripts"];
	
	// Enumerate our Script headers (Menu Headers)
	for(NSString *header in mainRunLoopScripts){
		NSDictionary *scriptHeader = [mainRunLoopScripts objectForKey:header];
		NSArray * itemScripts = [scriptHeader objectForKey:@"itemScripts"];
		// Set the number of scripts
		numberOfScripts = [ NSNumber numberWithInt:[itemScripts count]];
		// Set the level indicator
	}
	if(debugEnabled)NSLog(@"Found: %d scripts for this run loop",[numberOfScripts intValue]);

	[ scriptIndicator setMaxValue: [numberOfScripts doubleValue]];

	[pool release];
}

- (void)closeNetMainBox
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	[netMainBox setHidden:YES];
	NSRect frame = [networkCheckPanel frame];
	CGFloat sizeChange = [netMainBox frame].size.height;
	
	// Make the window smaller.
	frame.size.height -= sizeChange;
	// Move the origin.
	frame.origin.y += sizeChange;
	[networkCheckPanel setFrame:frame display:YES animate:YES];
	// Hide the extra box.
	//--------------------------
	[pool release];
}

- (void)closeNetProgressBox
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	[netProgressBox setHidden:YES];
	NSRect frame = [networkCheckPanel frame];
	CGFloat sizeChange = [netProgressBox frame].size.height;
	
	// Make the window smaller.
	frame.size.height -= sizeChange;
	// Move the origin.
	frame.origin.y += sizeChange;
	[networkCheckPanel setFrame:frame display:YES animate:YES];
	// Hide the extra box.
	//--------------------------
	[pool release];
}
# pragma mark -
# pragma mark Main Progress Bar
# pragma mark -




- (void)closeAllBoxes
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	if (windowNeedsResize) {
		NSRect frame = [window frame];
		CGFloat sizeChange = [mainProgressBox frame].size.height;
		
		// Make the window smaller.
		frame.size.height -= sizeChange;
		// Move the origin.
		frame.origin.y += sizeChange;
		[window setFrame:frame display:YES animate:YES];
		// Hide the extra box.
		[mainProgressBox setHidden:YES];
		//--------------------------
		
		frame = [window frame];
		sizeChange = [newPasswordBox frame].size.height;
		
		// Make the window smaller.
		frame.size.height -= sizeChange;
		// Move the origin.
		frame.origin.y += sizeChange;
		[window setFrame:frame display:YES animate:YES];
		// Hide the extra box.
		[newPasswordBox setHidden:YES];
		//--------------------------
		
		frame = [window frame];
		sizeChange = [oldPasswordBox frame].size.height ;
		
		// Make the window smaller.
		frame.size.height -= sizeChange;
		// Move the origin.
		frame.origin.y += sizeChange;
		[window setFrame:frame display:NO animate:NO];
		// Hide the extra box.
		[oldPasswordBox setHidden:YES];
		
		
	}
	windowNeedsResize = NO;
	[pool release];
}

- (void)quit
{
	// If we have been flagged then display the alert
	if (processComplete) {
		[self saveLastRunDate];
		[self performSelectorOnMainThread:@selector(displayProcessCompeletePanel)
							   withObject:nil
							waitUntilDone:TRUE];
	}
}

# pragma mark -
# pragma mark NSNotification
# pragma mark -

- (void) reloadLevelIndicator:(NSNotification *) notification
{	
	NSDictionary *userinfo = [notification userInfo];
	NSNumber *currentScriptNumber = [userinfo objectForKey:@"currentScriptNumber"];
	if(debugEnabled) \
		if(debugEnabled)NSLog(@"DEBUG: Receieved notification of script %d completion",[currentScriptNumber intValue]);

	[scriptIndicator setIntValue:[currentScriptNumber intValue]];
	// If we have reached the end of the line then
	if (numberOfScripts == currentScriptNumber ) {
		// ZS Disabled this as its not working right
		//windowNeedsResize = YES;
		//[self closeAllBoxes];
		[mainButton setEnabled:NO];
		[self stopMainProgressIndicator];
		// Set this var to let the util know to show the alert
		processComplete = YES;
		// Quit the app when done
		[self quit];

	}
}

-(void)networkCheckInProgress
{
	if ([netProgressBox isHidden]) {
		[self openNetProgressBox];
	}
	if (![netMainBox isHidden]) {
		[self closeNetMainBox];
	}

}

-(void)networkCheckFinished
{
	if ([netMainBox isHidden]) {
		[self openNetMainBox];
	}
	if (![netProgressBox isHidden]) {
		[self closeNetProgressBox];
	}
}

# pragma mark -
# pragma mark NSPanel & NSAlert
# pragma mark -


-(void)displayNetworkPanel
{
	[NSApp beginSheet:networkCheckPanel
	   modalForWindow:window
		modalDelegate:self
	   didEndSelector:NULL
		  contextInfo:nil];
}


-(void)displayPasswordMismatchAlert
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	// Activate Our Application
	[NSApp arrangeInFront:self];
	[NSApp activateIgnoringOtherApps:YES];
	// Display a standard alert
	NSAlert *alert = [[NSAlert alloc] init];
	[alert addButtonWithTitle:@"Cancel"];
	[alert setMessageText:@"Passwords do not match"];
	[alert setInformativeText:@"Please retype your NEW passwords again."];
	[alert setAlertStyle:NSWarningAlertStyle];
	[alert runModal];
	[alert release];
	[pool release];
}

-(void)displayInvalidUnixID
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	// Activate Our Application
	[NSApp arrangeInFront:self];
	[NSApp activateIgnoringOtherApps:YES];
	// Display a standard alert
	NSAlert *alert = [[NSAlert alloc] init];
	[alert addButtonWithTitle:@"Ok"];
	[alert setMessageText:@"UnixID not found"];
	[alert setInformativeText:@"Please check the Genentech UnixID entered"];
	[alert setAlertStyle:NSWarningAlertStyle];
	[alert runModal];
	[alert release];
	[pool release];
}


-(void)displayProcessCompeletePanel
{
	[NSApp beginSheet:processCompletePanel
	   modalForWindow:window
		modalDelegate:self
	   didEndSelector:NULL
		  contextInfo:nil];
}

-(void)saveLastRunDate
{
	// Updated to only save run date if process is complete
	NSMutableDictionary *saveDict;
	NSFileManager * fileManager = [[NSFileManager alloc] init];
	if ([fileManager fileExistsAtPath:[settings objectForKey:@"saveFilePath"]]) {
		saveDict = [[ NSMutableDictionary alloc] initWithContentsOfFile:[settings objectForKey:@"saveFilePath"]];
	}
	else {
		saveDict = [[ NSMutableDictionary alloc] init];
	}

	[saveDict setObject:[NSDate date] forKey:@"LastRunDate"];
	[saveDict writeToFile:[settings objectForKey:@"saveFilePath"]atomically:NO];
	
}


- (void)displayCancelWarning
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	// Activate Our Application
	[NSApp arrangeInFront:self];
	[NSApp activateIgnoringOtherApps:YES];
	// Display a standard alert
	NSAlert *alert = [[NSAlert alloc] init];
	[alert addButtonWithTitle:@"Ok"];
	[alert setMessageText:@"Reset In Progress"];
	[alert setInformativeText:@"The system is currently updating your password"];
	[alert setAlertStyle:NSWarningAlertStyle];
	[alert runModal];
	[alert release];
	[pool release];
}

- (void)displayInvalidNewCredentials
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	// Activate Our Application
	[NSApp arrangeInFront:self];
	[NSApp activateIgnoringOtherApps:YES];
	// Display a standard alert
	NSAlert *alert = [[NSAlert alloc] init];
	[alert addButtonWithTitle:@"Ok"];
	[alert setMessageText:@"Invalid NEW Password"];
	[alert setInformativeText:@"The new password you entered is not correct"];
	[alert setAlertStyle:NSWarningAlertStyle];
	[alert runModal];
	[alert release];
	[pool release];
}

- (void)openPageInSafari:(NSString *)url
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	NSDictionary* errorDict;
	NSAppleEventDescriptor* returnDescriptor = NULL;
	NSAppleScript* scriptObject = [[NSAppleScript alloc] initWithSource:
								   [NSString stringWithFormat:
									@"\
									tell app \"Safari\"\n\
									activate \n\
									make new document at end of documents\n\
									set URL of document 1 to \"%@\"\n\
									end tell\n\
									",url]];
	returnDescriptor = [scriptObject executeAndReturnError: &errorDict];
	[scriptObject release];
	[pool release];
	
}

-(void)closeNetworkCheckPanel
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	if(debugEnabled)NSLog(@"Was told to close network panel");
	[networkCheckPanel orderOut:nil];
    [NSApp endSheet:networkCheckPanel];
	[pool release];
}

-(void)closeProcessCompletePanel
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	if(debugEnabled)NSLog(@"Was told to close process complete panel");
	[processCompletePanel orderOut:nil];
    [NSApp endSheet:processCompletePanel];
	[pool release];
}

# pragma mark -
# pragma mark IBAction Methods
# pragma mark -

- (IBAction)showOldPasswordToggle:(id)sender
{
	if ([togglePasswordButton state] == NSOffState) {
		[oldPasswordField setHidden:NO];
		[oldPasswordField becomeFirstResponder];
		[oldPasswordClearField setHidden:YES];
	}
	else {
		[oldPasswordField setHidden:YES];
		[oldPasswordClearField setHidden:NO];
		[oldPasswordClearField becomeFirstResponder];
	}

}

- (IBAction)processCompleteOKButtonPressed:(id)sender
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	if(debugEnabled)NSLog(@"Process complete OK button pressed");
	[self closeProcessCompletePanel];
	[self softReboot];
	[NSApp terminate:self];
	[pool release];
}

- (void)softReboot
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	NSDictionary* errorDict;
	NSAppleEventDescriptor* returnDescriptor = NULL;
	NSAppleScript* scriptObject = [[NSAppleScript alloc] initWithSource:
									   [NSString stringWithFormat:
										@"\
										tell app \"Finder\"\n\
										restart \n\
										end tell\n\
									"]];
	returnDescriptor = [scriptObject executeAndReturnError: &errorDict];
	[scriptObject release];
	[pool release];
}

- (IBAction)opengConnectButtonPressed:(id)sender
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	if(debugEnabled)NSLog(@"Open gConnect button pressed");
	// ZS Updated to pull value from settings.plist
	[self openPageInSafari:[settings objectForKey:@"gConnectURL"]];
	[pool release];
}

- (IBAction)notNowButtonPressed:(id)sender
{
	[self closeNetworkCheckPanel];
	[self quit];
}

- (IBAction)tryAgainButtonPressed:(id)sender
{
	// Start our network Script
	[NSThread detachNewThreadSelector:@selector(netCheckScript)
							 toTarget:self
						   withObject:nil];
}



@end
