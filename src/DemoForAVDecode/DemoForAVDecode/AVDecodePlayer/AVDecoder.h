/***********************************************************
 * FileName         : AVDecoder.h
 * Version Number   : 1.0
 * Date             : 2013-06-03
 * Author           : darklinden
 * Change log (ID, Date, Author, Description) :
    $$$ Revision 1.0, 2013-06-03, darklinden, Create File with ffplay.
 ************************************************************/

#import <Foundation/Foundation.h>
#import "AVTileGLView.h"

//播放错误信息提示
typedef enum {
    //没有错误, 初始值
    Video_Play_Error_None = 0,
    
    //没有错误, 成功播放结束
    Video_Play_Error_SuccessEnded,
    
    //文件/stream输入错误
    Video_Play_Error_Input,
    
    //sdl创建线程失败
    Video_Play_Error_SDLError,
    
    //打开stream失败
    Video_Play_Error_OpenStreamError,
    
    //stream寻找解码器失败, 可能是解码不支持
    Video_Play_Error_StreamFindCodecError,
    
    //stream打开解码器失败, 可能是解码器不匹配
    Video_Play_Error_StreamOpenCodecError,
    
    //互斥锁设置失败
    Video_Play_Error_LockMgrInitError,
    
    //高清视频错误: 视频分辨率过高, 可能导致内存问题
    Video_Play_Error_HDError
    
} EN_Video_Play_Error;

//播放状态
typedef enum {
    //播放已终止, 初始值
    Video_Play_State_Stop = 0,
    
    //播放中
    Video_Play_State_Playing = 10000,
    
    //播放暂停
    Video_Play_State_Pause = 1
    
} EN_Video_Play_State;

@protocol AVDecoderDelegate <NSObject>

//回调函数, 每展示一帧调用一次, 调用时返回当前播放的时间点与总时间长度, 用以计算进度
- (void)playedSecond:(NSTimeInterval)playedSecond
            duration:(NSTimeInterval)duration;

//回调函数, 播放结束时调用, 返回errorType参见EN_Video_Play_Error定义
- (void)playStopWithError:(EN_Video_Play_Error)errortType;
@end

@class AVTileGLView;
@interface AVDecoder : NSObject

//当前播放的视频文件的路径/url, 如在播放时替换此变量可能导致未知错误
@property (nonatomic,   copy) NSString             *stringPathOrUrl;

//播放器的当前播放状态, 添加了置播放状态的响应, 如在播放时直接置pause可暂停
@property (unsafe_unretained) EN_Video_Play_State  playerState;

//创建用于播放的decoder, 需要指明播放器的展示view和播放器回调的delegate, 为了避免出错此处屏蔽了创建对象后对这两个参数的修改.
+ (id)createDecoderRenderView:(AVTileGLView *)tileView
              stringPathOrUrl:(NSString *)stringPathOrUrl
                     delegate:(id<AVDecoderDelegate>)delegate;

//播放
- (void)play;

//暂停, 再次调用play将继续
- (void)pause;

//停止播放, 再次调用play将从开头播放
- (void)stop;

//退出播放, 播放器将不能再使用
- (void)exit_play;

//前进/后退一段时间, 时间单位为秒, 超出播放范围0~duration的将自动调整至播放范围以内
- (void)seekWithIncreaseTime:(NSTimeInterval)time;

//移置某一位置播放, 时间单位为秒, 超出播放范围0~duration的将自动调整至播放范围以内
- (void)seekWithTime:(NSTimeInterval)time;

//播放的总秒数, 只有在开始播放的时候才能获取到正确的值
- (NSTimeInterval)getDuration;

@end
