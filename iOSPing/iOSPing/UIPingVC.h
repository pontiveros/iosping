//
//  UIPingVC.h
//  iOSWorkshop
//
//  Created by Pedro Ontiveros on 9/6/15.
//  Copyright © 2015 Pedro Ontiveros. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SimplePing.h"

@interface UIPingVC : UIViewController<SimplePingDelegate>

@property (nonatomic, assign) IBOutlet UITextField *remote;
@property (nonatomic, assign) IBOutlet UITextView  *console;
@property (nonatomic, retain) NSTimer  *sendTimer;
@property (nonatomic, retain) SimplePing *pinger;

@end