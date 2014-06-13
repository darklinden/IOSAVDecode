//
//  VC_player.m
//  DemoForAVDecode
//
//  Created by DarkLinden on J/8/2013.
//  Copyright (c) 2013 darklinden. All rights reserved.
//

#import "VC_player.h"
#import "AVDecoder.h"

@interface VC_player () <AVDecoderDelegate>
@property (nonatomic,   weak) IBOutlet UIView       *pV_controller;
@property (nonatomic,   weak) IBOutlet UISlider     *pSlider_play;
@property (nonatomic,   weak) IBOutlet UIButton     *pBtn_play;
@property (nonatomic,   weak) IBOutlet UIButton     *pBtn_pause;
@property (nonatomic, strong) AVDecoder             *decoder;
@end

@implementation VC_player

- (void)viewDidLoad
{
    [super viewDidLoad];
    AVTileGLView *tileView = [[AVTileGLView alloc] initWithFrame:self.view.bounds];
    self.decoder = [AVDecoder createDecoderRenderView:tileView
                                      stringPathOrUrl:self.stringPathOrUrl
                                             delegate:self];
    
    [self.view insertSubview:tileView belowSubview:self.pV_controller];
}

- (void)playStopWithError:(EN_Video_Play_Error)errortType
{
    NSLog(@"%s %d", __FUNCTION__, errortType);
    if (errortType == Video_Play_Error_SuccessEnded) {
        self.pSlider_play.value = 0;
        self.pBtn_pause.hidden = YES;
        self.pBtn_play.hidden = NO;
    }
}

- (void)playedSecond:(NSTimeInterval)playedSecond
            duration:(NSTimeInterval)duration
{
    //    NSLog(@"%lf / %lf", playedSecond, duration);
    if (self.pSlider_play.state == UIControlStateNormal)
        self.pSlider_play.value = playedSecond / duration;
}

- (IBAction)pBtn_play_clicked:(id)sender
{
    [self.decoder play];
    self.pBtn_pause.hidden = NO;
    self.pBtn_play.hidden = YES;
}

- (IBAction)pBtn_pause_clicked:(id)sender
{
    [self.decoder pause];
    self.pBtn_pause.hidden = YES;
    self.pBtn_play.hidden = NO;
}

- (IBAction)pBtn_back_clicked:(id)sender
{
    [self.decoder seekWithIncreaseTime:-10];
    self.pBtn_pause.hidden = NO;
    self.pBtn_play.hidden = YES;
}

- (IBAction)pBtn_forward_clicked:(id)sender
{
    [self.decoder seekWithIncreaseTime:10];
    self.pBtn_pause.hidden = NO;
    self.pBtn_play.hidden = YES;
}

- (IBAction)pSlider_play_changed:(id)sender {
    NSTimeInterval pos = self.pSlider_play.value * self.decoder.getDuration;
    [self.decoder seekWithTime:pos];
    self.pBtn_pause.hidden = NO;
    self.pBtn_play.hidden = YES;
}

- (IBAction)pBtn_stop_clicked:(id)sender {
    [self.decoder stop];
    self.pBtn_pause.hidden = YES;
    self.pBtn_play.hidden = NO;
}

- (IBAction)pBtn_close_clicked:(id)sender {
    [self.decoder exit_play];
    [self dismissViewControllerAnimated:YES completion:NULL];
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
