//
//  MainViewController.m
//  kxmovie
//
//  Created by Kolyvan on 18.10.12.
//  Copyright (c) 2012 Konstantin Boukreev . All rights reserved.
//
//  https://github.com/kolyvan/kxmovie
//  this file is part of KxMovie
//  KxMovie is licenced under the LGPL v3, see lgpl-3.0.txt

#import "MainViewController.h"
#import "KxMovieViewController.h"
#import "ODRefreshControl.h"

@interface MainViewController () <UIAlertViewDelegate>
{
    NSMutableArray *_localMovies;
    NSMutableArray *_remoteMovies;
    ODRefreshControl *pODRefreshControl;
}
@property (strong, nonatomic) UITableView *tableView;
@end

@implementation MainViewController

- (id)init
{
    self = [super init];
    if (self) {
        self.title = @"Movies";
        self.tabBarItem = [[UITabBarItem alloc] initWithTabBarSystemItem:UITabBarSystemItemFeatured tag: 0];
        
        _remoteMovies = [NSMutableArray arrayWithObjects:
            @"http://eric.cast.ro/stream2.flv",
            @"http://liveipad.wasu.cn/cctv2_ipad/z.m3u8",                          
            @"http://www.wowza.com/_h264/BigBuckBunny_175k.mov",
            // @"http://www.wowza.com/_h264/BigBuckBunny_115k.mov",
            @"rtsp://184.72.239.149/vod/mp4:BigBuckBunny_115k.mov",
            @"http://santai.tv/vod/test/test_format_1.3gp",
            @"http://santai.tv/vod/test/test_format_1.mp4",
        
            //@"rtsp://184.72.239.149/vod/mp4://BigBuckBunny_175k.mov",
            //@"http://santai.tv/vod/test/BigBuckBunny_175k.mov",
        
            @"rtmp://aragontvlivefs.fplive.net/aragontvlive-live/stream_normal_abt",
            @"rtmp://ucaster.eu:1935/live/_definst_/discoverylacajatv",
            @"rtmp://edge01.fms.dutchview.nl/botr/bunny.flv",
                         nil];
        
    }
    return self;
}

- (void)loadView
{
    self.view = [[UIView alloc] initWithFrame:[[UIScreen mainScreen] applicationFrame]];
    self.view.backgroundColor = [UIColor lightGrayColor];
    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
    self.tableView.backgroundColor = [UIColor clearColor];
    //self.tableView.backgroundView = [[UIImageView alloc] initWithImage:image];
    self.tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleBottomMargin;
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
    
    [self.view addSubview:self.tableView];
    
    UIBarButtonItem *btn = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addUrl)];
    self.navigationItem.rightBarButtonItem = btn;
}

- (void)addUrl
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"add url" message:nil delegate:self cancelButtonTitle:@"cancel" otherButtonTitles:@"ok", nil];
    alert.alertViewStyle = UIAlertViewStylePlainTextInput;
    [alert show];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (alertView.alertViewStyle == UIAlertViewStylePlainTextInput) {
        UITextField *pTf_url = [alertView textFieldAtIndex:0];
        if (pTf_url.text.length > 0) {
            [_remoteMovies addObject:pTf_url.text];
            [self.tableView reloadData];
        }
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    pODRefreshControl = [ODRefreshControl newWithScroll:self.tableView
                                                actType:ODRefreshActivityTypeDefault actView:nil];
    [pODRefreshControl addTarget:self action:@selector(dropViewDidBeginRefreshing:) forControlEvents:UIControlEventValueChanged];
}

- (void)dropViewDidBeginRefreshing:(ODRefreshControl *)refreshControl
{
    double delayInSeconds = 1.0;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        [self reloadMovies];
        [refreshControl endRefreshing];
    });
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];    
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self reloadMovies];
    [self.tableView reloadData];
}

- (void) reloadMovies
{
    NSMutableArray *ma = [NSMutableArray array];
    NSFileManager *fm = [[NSFileManager alloc] init];
    NSString *folder = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,
                                                            NSUserDomainMask,
                                                            YES) lastObject];
    NSArray *contents = [fm contentsOfDirectoryAtPath:folder error:nil];
    
    for (NSString *filename in contents) {
        
        if (filename.length > 0 &&
            [filename characterAtIndex:0] != '.') {
            
            NSString *path = [folder stringByAppendingPathComponent:filename];
            NSDictionary *attr = [fm attributesOfItemAtPath:path error:nil];
            if (attr) {
                id fileType = [attr valueForKey:NSFileType];
                if ([fileType isEqual: NSFileTypeRegular] ||
                    [fileType isEqual: NSFileTypeSymbolicLink]) {
                    
                    NSString *ext = path.pathExtension.lowercaseString;
                    
//                    if ([ext isEqualToString:@"mp3"] ||
//                        [ext isEqualToString:@"caff"]||
//                        [ext isEqualToString:@"aiff"]||
//                        [ext isEqualToString:@"ogg"] ||
//                        [ext isEqualToString:@"wma"] ||
//                        [ext isEqualToString:@"m4a"] ||
//                        [ext isEqualToString:@"m4v"] ||
//                        [ext isEqualToString:@"wmv"] ||
//                        [ext isEqualToString:@"3gp"] ||
//                        [ext isEqualToString:@"mp4"] ||
//                        [ext isEqualToString:@"mov"] ||
//                        [ext isEqualToString:@"avi"] ||
//                        [ext isEqualToString:@"mkv"] ||
//                        [ext isEqualToString:@"mpeg"]||
//                        [ext isEqualToString:@"mpg"] ||
//                        [ext isEqualToString:@"flv"] ||
//                        [ext isEqualToString:@"vob"]) {
                    
                        [ma addObject:path];
//                    }
                }
            }
        }
    }
    
    _localMovies = [ma copy];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 2;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    switch (section) {
        case 0:     return @"Remote";
        case 1:     return @"Local";
    }
    return @"";
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    switch (section) {
        case 0:     return _remoteMovies.count;
        case 1:     return _localMovies.count;
    }
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentifier = @"Cell";
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                      reuseIdentifier:cellIdentifier];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    
    NSString *path;
    
    if (indexPath.section == 0) {
        
        path = _remoteMovies[indexPath.row];
        
    } else {
        
        path = _localMovies[indexPath.row];
    }

    cell.textLabel.text = path.lastPathComponent;
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *path;
    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
    
    if (indexPath.section == 0) {
        
        path = _remoteMovies[indexPath.row];
        
    } else {
        
        path = _localMovies[indexPath.row];
    }
    
    // increase buffering for .wmv, it solves problem with delaying audio frames
    if ([path.pathExtension isEqualToString:@"wmv"])
        parameters[KxMovieParameterMinBufferedDuration] = @(5.0);
    
    // disable deinterlacing for iPhone, because it's complex operation can cause stuttering
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
        parameters[KxMovieParameterDisableDeinterlacing] = @(YES);
    
    // disable buffering
    //parameters[KxMovieParameterMinBufferedDuration] = @(0.0f);
    //parameters[KxMovieParameterMaxBufferedDuration] = @(0.0f);
    
    KxMovieViewController *vc = [KxMovieViewController movieViewControllerWithContentPath:path
                                                                               parameters:parameters];
    [self presentViewController:vc animated:YES completion:nil];
    //[self.navigationController pushViewController:vc animated:YES];    
}

- (BOOL)tableView:(UITableView *)tableView
commitEditingStyle:(UITableViewCellEditingStyle)editingStyle
forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        [tableView beginUpdates];
        [tableView deleteRowsAtIndexPaths:@[indexPath]
                         withRowAnimation:UITableViewRowAnimationAutomatic];
        [_remoteMovies removeObjectAtIndex:indexPath.row];
        [tableView endUpdates];
    }
    return YES;
}

@end
