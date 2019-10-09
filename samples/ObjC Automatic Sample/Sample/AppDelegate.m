/*
 * Copyright © 2011, 2019 Acoustic, L.P. All rights reserved.
 *
 * NOTICE: This file contains material that is confidential and proprietary to
 * Acoustic, L.P. and/or other developers. No license is granted under any intellectual or
 * industrial property rights of Acoustic, L.P. except as may be provided in an agreement with
 * Acoustic, L.P. Any unauthorized copying or distribution of content from this file is
 * prohibited.
 */

#if __has_feature(modules)
@import UserNotifications;
@import MessageUI;
@import AcousticMobilePush;
#else
#import <UserNotifications/UserNotifications.h>
#import <AcousticMobilePush/AcousticMobilePush.h>
#import <MessageUI/MessageUI.h>
#endif

#import "AppDelegate.h"
#import "MailDelegate.h"

// Action Plugins
#import "ActionMenuPlugin.h"
#import "AddToCalendarPlugin.h"
#import "AddToPassbookPlugin.h"
#import "SnoozeActionPlugin.h"
#import "DisplayWebViewPlugin.h"
#import "TextInputActionPlugin.h"
#import "ExamplePlugin.h"
#import "CarouselAction.h"

// MCE Inbox Plugins
#import "MCEInboxActionPlugin.h"
#import "MCEInboxPostTemplate.h"
#import "MCEInboxDefaultTemplate.h"

// MCE InApp Plugins
#import "MCEInAppVideoTemplate.h"
#import "MCEInAppImageTemplate.h"
#import "MCEInAppBannerTemplate.h"

#import "RegistrationVC.h"
#import "MainVC.h"

@interface MyAlertController : UIAlertController

@end

@implementation MyAlertController
- (void)presentViewController:(UIViewController *)viewControllerToPresent animated:(BOOL)flag completion:(void (^)(void))completion
{
    NSLog(@"Do customizations here or replace with a duck typed class");
    [super presentViewController:viewControllerToPresent animated:flag completion:completion];
}
@end

@interface AppDelegate ()
@property NSString * string;
@end

@interface MCEPersistentStorage : NSObject
@property(class, nonatomic, readonly) MCEPersistentStorage * sharedInstance NS_SWIFT_NAME(shared);
@property NSDate * lastInboxSync;
@end


@implementation AppDelegate

// This method updates the badge count when the number of unread messages changes.
// If you have additional user messages that should be reflected, that can be done here.
-(void)inboxUpdate {
    int unreadCount = [[MCEInboxDatabase sharedInstance] unreadMessageCount];
    dispatch_async(dispatch_get_main_queue(), ^{
        [UIApplication.sharedApplication setApplicationIconBadgeNumber: unreadCount];
    });
}

- (BOOL)application:(UIApplication *)app openURL:(NSURL *)url options:(NSDictionary<UIApplicationOpenURLOptionsKey,id> *)options {
    UIAlertController * controller = [UIAlertController alertControllerWithTitle:@"Custom URL Clicked" message:url.absoluteString preferredStyle:UIAlertControllerStyleAlert];
    [controller addAction: [UIAlertAction actionWithTitle:@"Okay" style: UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        [controller dismissViewControllerAnimated:TRUE completion:^{
            
        }];
    }]];
    [self.window.rootViewController presentViewController:controller animated:true completion:^{
        
    }];
    
    return true;
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    MCEPersistentStorage.sharedInstance.lastInboxSync = [[NSDate alloc]initWithTimeIntervalSince1970:1];
    
    
    UISplitViewController *splitViewController = (UISplitViewController *)self.window.rootViewController;
    UINavigationController *navigationController = [splitViewController.viewControllers lastObject];
    navigationController.topViewController.navigationItem.leftBarButtonItem = splitViewController.displayModeButtonItem;
    splitViewController.delegate = self;

    if(@available(iOS 12.0, *)) {
        MCESdk.sharedInstance.openSettingsForNotification = ^(UNNotification *notification) {
            UIAlertController * alert = [UIAlertController alertControllerWithTitle:@"Should show app settings for notifications" message:nil preferredStyle:UIAlertControllerStyleAlert];
            [alert addAction: [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                
            }]];
            [[MCESdk.sharedInstance findCurrentViewController] presentViewController:alert animated:true completion: ^{
                
            }];
        };
    }
    
    [self inboxUpdate];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(inboxUpdate) name: InboxCountUpdate object:nil];

    [[NSUserDefaults standardUserDefaults]registerDefaults:@{@"action":@"update",@"standardType":@"dial", @"standardDialValue":@"\"8774266006\"", @"standardUrlValue":@"\"http://acoustic.co\"", @"customType":@"sendEmail", @"customValue":@"{\"subject\":\"Hello from Sample App\", \"body\": \"This is an example email body\", \"recipient\":\"fake-email@fake-site.com\"}", @"categoryId":@"example",@"button1":@"Accept",@"button2":@"Reject"}];
    
    if([UNUserNotificationCenter class]) {
        [application registerForRemoteNotifications];

        // iOS 10+ Example static action category:
        UNNotificationAction * acceptAction = [UNNotificationAction actionWithIdentifier:@"Accept" title:@"Accept" options:UNNotificationActionOptionForeground];
        UNNotificationAction * fooAction = [UNNotificationAction actionWithIdentifier:@"Foo" title:@"Foo" options:UNNotificationActionOptionForeground];
        UNNotificationAction * rejectAction = [UNNotificationAction actionWithIdentifier:@"Reject" title:@"Reject" options:UNNotificationActionOptionDestructive];
        UNNotificationCategory * category = [UNNotificationCategory categoryWithIdentifier:@"example" actions:@[acceptAction, fooAction, rejectAction] intentIdentifiers:@[] options:UNNotificationCategoryOptionCustomDismissAction];
        NSSet * applicationCategories = [NSSet setWithObject: category];
        
        // iOS 10+ Push Message Registration
        NSUInteger options = 0;
#ifdef __IPHONE_12_0
        if(@available(iOS 12.0, *)) {
            options = UNAuthorizationOptionAlert|UNAuthorizationOptionSound|UNAuthorizationOptionBadge|UNAuthorizationOptionCarPlay|UNAuthorizationOptionProvidesAppNotificationSettings;
        }
        else
#endif
        {
            options = UNAuthorizationOptionAlert|UNAuthorizationOptionSound|UNAuthorizationOptionBadge|UNAuthorizationOptionCarPlay;
        }

        UNUserNotificationCenter * center = [UNUserNotificationCenter currentNotificationCenter];
        [center requestAuthorizationWithOptions: options completionHandler:^(BOOL granted, NSError * _Nullable error) {
            [center setNotificationCategories: applicationCategories];
        }];
    } else if ([UIApplication.sharedApplication respondsToSelector:@selector(registerUserNotificationSettings:)]) {
        // iOS 8+ Example static action category:
        UIMutableUserNotificationAction * acceptAction = [[UIMutableUserNotificationAction alloc] init];
        [acceptAction setIdentifier: @"Accept"];
        [acceptAction setTitle: @"Accept"];
        [acceptAction setActivationMode: UIUserNotificationActivationModeForeground];
        [acceptAction setDestructive: false];
        [acceptAction setAuthenticationRequired: false];
        
        UIMutableUserNotificationAction * rejectAction = [[UIMutableUserNotificationAction alloc] init];
        [rejectAction setIdentifier: @"Reject"];
        [rejectAction setTitle: @"Reject"];
        [rejectAction setActivationMode: UIUserNotificationActivationModeBackground];
        [rejectAction setDestructive: true];
        [rejectAction setAuthenticationRequired: false];
        
        UIMutableUserNotificationCategory * category = [[UIMutableUserNotificationCategory alloc] init];
        [category setIdentifier: @"example"];
        [category setActions: @[acceptAction, rejectAction] forContext: UIUserNotificationActionContextDefault];
        [category setActions: @[acceptAction, rejectAction] forContext: UIUserNotificationActionContextMinimal];
        NSSet * applicationCategories = [NSSet setWithObject: category];
        
        // iOS 8+ Push Message Registration
        UIUserNotificationSettings *settings = [UIUserNotificationSettings settingsForTypes:UIUserNotificationTypeBadge|UIUserNotificationTypeSound|UIUserNotificationTypeAlert categories: applicationCategories];
        [UIApplication.sharedApplication registerUserNotificationSettings:settings];
        [UIApplication.sharedApplication registerForRemoteNotifications];
    } else {
        // iOS < 8 Push Message Registration
#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wdeprecated-declarations"
        UIRemoteNotificationType myTypes = UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeAlert | UIRemoteNotificationTypeSound;
        [UIApplication.sharedApplication registerForRemoteNotificationTypes:myTypes];
#pragma GCC diagnostic pop
    }
    
    return YES;
}

-(void)application:(UIApplication *)application didReceiveLocalNotification:(UILocalNotification *)notification
{
    [[MCEInAppManager sharedInstance] processPayload: notification.userInfo];
}

-(instancetype)init
{
    if(MCERegistrationDetails.sharedInstance.userInvalidated) {
        [MCESdk.sharedInstance manualInitialization];
    }
    
    if(self=[super init])
    {
        MCESdk.sharedInstance.presentNotification = ^BOOL(NSDictionary * userInfo){
            NSLog(@"Checking if should present notification!");
            
            // return FALSE if you don't want the notification to show to the user when the app is active
            return TRUE;
        };
        [MCESdk sharedInstance].customAlertControllerClass = [MyAlertController class];

        // MCE Inbox plugins
        [MCEInboxActionPlugin registerPlugin];
        [MCEInboxPostTemplate registerTemplate];
        [MCEInboxDefaultTemplate registerTemplate];
        
        // MCE InApp Plugins
        [MCEInAppVideoTemplate registerTemplate];
        [MCEInAppImageTemplate registerTemplate];
        [MCEInAppBannerTemplate registerTemplate];
        
        // Action Plugins
        [ActionMenuPlugin registerPlugin];
        [ExamplePlugin registerPlugin];
        [AddToCalendarPlugin registerPlugin];
        [AddToPassbookPlugin registerPlugin];
        [SnoozeActionPlugin registerPlugin];
        [DisplayWebViewPlugin registerPlugin];
        [TextInputActionPlugin registerPlugin];
        [CarouselAction registerPlugin];
        
        // Custom Send Email Plugin Example
        [[MCEActionRegistry sharedInstance] registerTarget:[[MailDelegate alloc] init] withSelector:@selector(sendEmail:) forAction:@"sendEmail"];
    }
    return self;
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wstrict-prototypes"
- (void)application:(UIApplication *)application handleActionWithIdentifier:(nullable NSString *)identifier forRemoteNotification:(NSDictionary *)userInfo withResponseInfo:(NSDictionary *)responseInfo completionHandler:(void (^)(void))completionHandler
#pragma clang diagnostic pop
{
    NSLog(@"responseInfo: %@", responseInfo);
}

#pragma mark Process Static Category No Choice Made
- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler
{
    if(userInfo[@"aps"] && [userInfo[@"aps"][@"category"] isEqual: @"example"])
    {
        [[[MCESdk.sharedInstance.alertViewClass alloc] initWithTitle:@"Static category handler" message:@"Static Category, no choice made" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil]show];
    }
    completionHandler(UIBackgroundFetchResultNewData);
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wstrict-prototypes"

#pragma mark Process Static Category Choice Made
- (void)application:(UIApplication *)application handleActionWithIdentifier:(nullable NSString *)identifier forRemoteNotification:(NSDictionary *)userInfo completionHandler:(void (^)(void))completionHandler
#pragma clang diagnostic pop
{
    if(userInfo[@"aps"] && [userInfo[@"aps"][@"category"] isEqual: @"example"])
    {
        NSLog(@"Static Category, %@ button clicked", identifier);

        NSDictionary * values = userInfo[@"category-values"];
        if(values)
        {
            NSString * name = values[@"name"];
            NSNumber * quantity = values[@"quantity"];
            NSNumber * persist = values[@"persist"];
            NSDictionary * other = values[@"other"];
            if(name && quantity && persist && other)
            {
                NSString * message = other[@"deniedMessage"];
                if([identifier isEqual:@"Accept"])
                {
                    [[[MCESdk.sharedInstance.alertViewClass alloc] initWithTitle:@"Static category handler" message:[NSString stringWithFormat: @"User pressed %@ for %@ quantity %@", identifier, name, quantity] delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil]show];
                    return;
                }
                if([identifier isEqual:@"Reject"])
                {
                    [[[MCESdk.sharedInstance.alertViewClass alloc] initWithTitle:@"Static category handler" message:[NSString stringWithFormat: @"User Pressed %@ persistance %d, reason %@", identifier, [persist boolValue], message] delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil]show];
                    return;
                }
            }
        }
        
        [[[MCESdk.sharedInstance.alertViewClass alloc] initWithTitle:@"Static category handler" message:[NSString stringWithFormat: @"Static Category, %@ button clicked", identifier] delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil]show];

        // Send event to Xtify Servers
        NSString * eventName = @"Name of event";
        NSString * eventType = @"Type of event";
        NSDictionary * attributes = @{};
        
        NSString * attribution=nil;
        if(userInfo[@"mce"] && userInfo[@"mce"][@"attribution"])
        {
            attribution = userInfo[@"mce"][@"attribution"];
        }
        
        NSString * mailingId=nil;
        if(userInfo[@"mce"] && userInfo[@"mce"][@"mailingId"])
        {
            mailingId = userInfo[@"mce"][@"mailingId"];
        }
        
        MCEEvent * event = [[MCEEvent alloc] init];
        [event fromDictionary: @{ @"name":eventName, @"type":eventType, @"timestamp":[[NSDate alloc]init], @"attributes": attributes}];
        if(attribution)
        {
            event.attribution=attribution;
        }
        if(mailingId)
        {
            event.mailingId=mailingId;
        }
        
        [[MCEEventService sharedInstance] addEvent:event immediate:FALSE];
    }
    completionHandler();
}

- (BOOL)splitViewController:(UISplitViewController *)splitViewController
collapseSecondaryViewController:(UIViewController *)secondaryViewController
  ontoPrimaryViewController:(UIViewController *)primaryViewController {
    return YES;
}

@end
