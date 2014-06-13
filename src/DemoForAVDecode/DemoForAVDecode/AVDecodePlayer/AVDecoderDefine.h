/***********************************************************
 * FileName         : AVDecoderDefine.h
 * Version Number   : 1.0
 * Date             : 2013-06-03
 * Author           : darklinden
 * Change log (ID, Date, Author, Description) :
    $$$ Revision 1.0, 2013-06-03, darklinden, Create File with ffplay.
 ************************************************************/

//此h文件为提出来的一些用到的define和结构, 不要动

#ifndef DemoForAVDecode_AVDecoderDefine_h
#define DemoForAVDecode_AVDecoderDefine_h

//ffmpeg
#include "libavutil/avstring.h"
#include "libavutil/colorspace.h"
#include "libavutil/mathematics.h"
#include "libavutil/pixdesc.h"
#include "libavutil/imgutils.h"
#include "libavutil/dict.h"
#include "libavutil/parseutils.h"
#include "libavutil/samplefmt.h"
#include "libavutil/avassert.h"
#include "libavutil/time.h"
#include "libavformat/avformat.h"
#include "libavdevice/avdevice.h"
#include "libswscale/swscale.h"
#include "libavutil/opt.h"
#include "libavcodec/avfft.h"
#include "libswresample/swresample.h"
#include "libavfilter/avfilter.h"

//sdl
#include "SDL.h"
#include "SDL_thread.h"

#define MAX_QUEUE_SIZE (15 * 1024 * 1024)
#define MIN_FRAMES 5

/* SDL audio buffer size, in samples. Should be small to have precise
 A/V sync as SDL does not have hardware buffer fullness info. */
#define SDL_AUDIO_BUFFER_SIZE 1024

/* no AV sync correction is done if below the AV sync threshold */
#define AV_SYNC_THRESHOLD 0.01
/* no AV correction is done if too big error */
#define AV_NOSYNC_THRESHOLD 10.0

/* maximum audio speed change to get correct sync */
#define SAMPLE_CORRECTION_PERCENT_MAX 10

/* we use about AUDIO_DIFF_AVG_NB A-V differences to make the average */
#define AUDIO_DIFF_AVG_NB   20

/* NOTE: the size must be big enough to compensate the hardware audio buffersize size */
/* TODO: We assume that a decoded and resampled frame fits into this buffer */
#define SAMPLE_ARRAY_SIZE (8 * 65536)

typedef struct PacketQueue {
    AVPacketList *first_pkt, *last_pkt;
    int nb_packets;
    int size;
    int abort_request;
    SDL_mutex *mutex;
    SDL_cond *cond;
} PacketQueue;

#define VIDEO_PICTURE_QUEUE_SIZE 4
#define SUBPICTURE_QUEUE_SIZE 4

typedef struct VideoPicture {
    double pts;                                  ///< presentation time stamp for this picture
    int64_t pos;                                 ///< byte position in file
    int skip;
    SDL_Overlay *bmp;
    int width, height; /* source height & width */
    AVRational sample_aspect_ratio;
    int allocated;
    int reallocate;
    
#if CONFIG_AVFILTER
    AVFilterBufferRef *picref;
#endif
} VideoPicture;

typedef struct SubPicture {
    double pts; /* presentation time stamp for this picture */
    AVSubtitle sub;
} SubPicture;

typedef struct AudioParams {
    int freq;
    int channels;
    int channel_layout;
    enum AVSampleFormat fmt;
} AudioParams;

enum {
    AV_SYNC_AUDIO_MASTER, /* default choice */
    AV_SYNC_VIDEO_MASTER,
    AV_SYNC_EXTERNAL_CLOCK, /* synchronize to an external clock */
};

//高清指标
#define HDWIDTHHEIGHTTOTAL 600000 // This is roughly between 480p and 720p

typedef enum {
    AV_RENDER_TYPE_UNKNOWN = 0,
    AV_RENDER_TYPE_YUV,
    AV_RENDER_TYPE_RGB
} EN_AV_RENDER_TYPE;

#endif
