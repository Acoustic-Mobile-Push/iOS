/*
 * Copyright © 2011, 2019 Acoustic, L.P. All rights reserved.
 *
 * NOTICE: This file contains material that is confidential and proprietary to
 * Acoustic, L.P. and/or other developers. No license is granted under any intellectual or
 * industrial property rights of Acoustic, L.P. except as may be provided in an agreement with
 * Acoustic, L.P. Any unauthorized copying or distribution of content from this file is
 * prohibited.
 */
#import "MainVC.h"

#if __has_feature(modules)
@import AcousticMobilePush;
#else
#import <AcousticMobilePush/AcousticMobilePush.h>
#endif

@interface MainVC ()
@property (nonatomic, strong) id previewingContext;
@end

@implementation MainVC

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self inboxUpdate];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self.version setText: [NSString stringWithFormat: @"Native SDK v%@", MCESdk.sharedInstance.sdkVersion]];
    
    if ([self isForceTouchAvailable]) {
        self.previewingContext = [self registerForPreviewingWithDelegate:self sourceView:self.view];
    }
    
    // Show Inbox counts on main page
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(inboxUpdate) name: InboxCountUpdate object:nil];
    if(MCERegistrationDetails.sharedInstance.mceRegistered)
    {
        [[MCEInboxQueueManager sharedInstance] syncInbox];
    }
    else
    {
        [NSNotificationCenter.defaultCenter addObserverForName: MCERegisteredNotification object:nil queue:NSOperationQueue.mainQueue usingBlock:^(NSNotification * _Nonnull note) {
            [[MCEInboxQueueManager sharedInstance] syncInbox];
        }];
    }
}

// Show Inbox counts on main page
-(void)inboxUpdate
{
    int unreadCount = [[MCEInboxDatabase sharedInstance] unreadMessageCount];
    int messageCount = [[MCEInboxDatabase sharedInstance] messageCount];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        NSString * subtitle = @"";
        if(MCERegistrationDetails.sharedInstance.mceRegistered)
        {
            subtitle = [NSString stringWithFormat:@"%d messages, %d unread", messageCount, unreadCount];
        }
        self.inboxCell.detailTextLabel.text = subtitle;
        self.altInboxCell.detailTextLabel.text = subtitle;
        [self.tableView reloadData];
    });
}

- (BOOL)isForceTouchAvailable
{
    if ([self.traitCollection respondsToSelector:@selector(forceTouchCapability)]) {
        return self.traitCollection.forceTouchCapability == UIForceTouchCapabilityAvailable;
    }
    return NO;
}

- (UIViewController *)previewingContext:(id<UIViewControllerPreviewing>)previewingContext viewControllerForLocation:(CGPoint)location{
    
    CGPoint cellPostion = [self.tableView convertPoint:location fromView:self.view];
    NSIndexPath *path = [self.tableView indexPathForRowAtPoint:cellPostion];
    
    if (path) {
        UITableViewCell *tableCell = [self.tableView cellForRowAtIndexPath:path];
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
        
        if(tableCell.restorationIdentifier)
        {
            UIViewController *previewController = [storyboard instantiateViewControllerWithIdentifier: tableCell.restorationIdentifier];
            if(previewController)
            {
                previewingContext.sourceRect = [self.view convertRect:tableCell.frame fromView:self.tableView];
                return previewController;
            }
        }
    }
    return nil;
}

-(void)previewingContext:(id<UIViewControllerPreviewing>)previewingContext commitViewController:(UIViewController *)viewControllerToCommit
{
    [self.navigationController pushViewController:viewControllerToCommit animated:TRUE];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell * cell = [tableView cellForRowAtIndexPath:indexPath];
    NSString * identifier = cell.accessibilityIdentifier;
    if(!identifier) {
        NSLog(@"Couldn't determine view controller to show!");
        return;
    }
    UIViewController * viewController = [self.storyboard instantiateViewControllerWithIdentifier: identifier];
    if(viewController) {
        if(UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPad) {
            UINavigationController * navigationController = [[UINavigationController alloc] initWithRootViewController: viewController];
            viewController.navigationItem.leftBarButtonItem = self.splitViewController.displayModeButtonItem;
            [self.splitViewController showDetailViewController:navigationController sender:self];
            
        } else {
            [self.navigationController pushViewController:viewController animated:true];
        }
    } else {
        NSLog(@"Couldn't find view controller to show!");
        return;
    }
}

@end
