//
//  ViewController.m
//  iOSPing
//
//  Created by Pedro Ontiveros on 11/14/15.
//  Copyright © 2015 Pedro Ontiveros. All rights reserved.
//

#import "ViewController.h"
#import "UIPingVC.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    self.title = @"iOS Util Ping";
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)onTouchPing:(id)sender
{
    UIPingVC *vc = [[UIPingVC alloc] initWithNibName:@"UIPingView" bundle:nil];
    [self.navigationController pushViewController:vc animated:YES];
}

@end
