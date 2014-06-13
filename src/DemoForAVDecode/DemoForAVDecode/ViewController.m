//
//  ViewController.m
//  DemoForAVDecode
//
//  Created by DarkLinden on M/31/2013.
//  Copyright (c) 2013 darklinden. All rights reserved.
//

#import "ViewController.h"
#import "VC_player.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [btn setFrame:CGRectMake(0.f, 0.f, 100.f, 30.f)];
    [btn setTitle:@"Play" forState:UIControlStateNormal];
    [btn addTarget:self action:@selector(play) forControlEvents:UIControlEventTouchUpInside];
    btn.center = self.view.center;
    [self.view addSubview:btn];
}

- (void)play
{
    VC_player *pVC_player = [[VC_player alloc] initWithNibName:@"VC_player" bundle:nil];
    pVC_player.stringPathOrUrl = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"test.mp4"];
    [self presentViewController:pVC_player animated:YES completion:NULL];
}

- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskAll;
}

- (BOOL)shouldAutorotate
{
    return YES;
}

@end
