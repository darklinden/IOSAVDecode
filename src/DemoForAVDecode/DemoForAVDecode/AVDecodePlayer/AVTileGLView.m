/***********************************************************
 * FileName         : AVTileGLView.m
 * Version Number   : 1.0
 * Date             : 2013-06-03
 * Author           : darklinden
 * Change log (ID, Date, Author, Description) :
    $$$ Revision 1.0, 2013-06-03, darklinden, Create File With KxMovieGLView.
 ************************************************************/

#import "AVTileGLView.h"

//OpenGLES & QuartzCore
#import <QuartzCore/QuartzCore.h>
#import <OpenGLES/EAGLDrawable.h>
#import <OpenGLES/EAGL.h>
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>

//ffmpeg
#include "libavformat/avformat.h"
#include "libswscale/swscale.h"
#include "libswresample/swresample.h"
#include "libavutil/pixdesc.h"
#include "libavcodec/avcodec.h"

#import "AVDecoderDefine.h"

//////////////////////////////////////////////////////////////////////////////////////////

#pragma mark - shaders

NSString *const vertexShaderString = @" \
attribute vec4 position;\
attribute vec2 texcoord;\
uniform mat4 modelViewProjectionMatrix;\
varying vec2 v_texcoord;\
\
void main()\
{ \
gl_Position = modelViewProjectionMatrix * position; \
v_texcoord = texcoord.xy;\
}";

NSString *const rgbFragmentShaderString = @"\
varying highp vec2 v_texcoord;\
uniform sampler2D s_texture;\
\
void main()\
{\
gl_FragColor = texture2D(s_texture, v_texcoord);\
}";

NSString *const yuvFragmentShaderString = @"\
varying highp vec2 v_texcoord;\
uniform sampler2D s_texture_y;\
uniform sampler2D s_texture_u;\
uniform sampler2D s_texture_v;\
\
void main()\
{\
highp float y = texture2D(s_texture_y, v_texcoord).r;\
highp float u = texture2D(s_texture_u, v_texcoord).r - 0.5;\
highp float v = texture2D(s_texture_v, v_texcoord).r - 0.5;\
\
highp float r = y +             1.402 * v;\
highp float g = y - 0.344 * u - 0.714 * v;\
highp float b = y + 1.772 * u;\
\
gl_FragColor = vec4(r,g,b,1.0);\
}";

static BOOL validateProgram(GLuint prog)
{
	GLint status;
	
    glValidateProgram(prog);
    
#ifdef DEBUG
    GLint logLength;
    glGetProgramiv(prog, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0)
    {
        GLchar *log = (GLchar *)malloc(logLength);
        glGetProgramInfoLog(prog, logLength, &logLength, log);
        NSLog(@"Program validate log:\n%s", log);
        free(log);
    }
#endif
    
    glGetProgramiv(prog, GL_VALIDATE_STATUS, &status);
    if (status == GL_FALSE) {
		NSLog(@"Failed to validate program %d", prog);
        return NO;
    }
	
	return YES;
}

static GLuint compileShader(GLenum type, NSString *shaderString)
{
	GLint status;
	const GLchar *sources = (GLchar *)shaderString.UTF8String;
	
    GLuint shader = glCreateShader(type);
    if (shader == 0 || shader == GL_INVALID_ENUM) {
        NSLog(@"Failed to create shader %d", type);
        return 0;
    }
    
    glShaderSource(shader, 1, &sources, NULL);
    glCompileShader(shader);
	
#ifdef DEBUG
	GLint logLength;
    glGetShaderiv(shader, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0)
    {
        GLchar *log = (GLchar *)malloc(logLength);
        glGetShaderInfoLog(shader, logLength, &logLength, log);
        NSLog(@"Shader compile log:\n%s", log);
        free(log);
    }
#endif
    
    glGetShaderiv(shader, GL_COMPILE_STATUS, &status);
    if (status == GL_FALSE) {
        glDeleteShader(shader);
		NSLog(@"Failed to compile shader:\n");
        return 0;
    }
    
	return shader;
}

static void mat4f_LoadOrtho(float left, float right, float bottom, float top, float near, float far, float* mout)
{
	float r_l = right - left;
	float t_b = top - bottom;
	float f_n = far - near;
	float tx = - (right + left) / (right - left);
	float ty = - (top + bottom) / (top - bottom);
	float tz = - (far + near) / (far - near);
    
	mout[0] = 2.0f / r_l;
	mout[1] = 0.0f;
	mout[2] = 0.0f;
	mout[3] = 0.0f;
	
	mout[4] = 0.0f;
	mout[5] = 2.0f / t_b;
	mout[6] = 0.0f;
	mout[7] = 0.0f;
	
	mout[8] = 0.0f;
	mout[9] = 0.0f;
	mout[10] = -2.0f / f_n;
	mout[11] = 0.0f;
	
	mout[12] = tx;
	mout[13] = ty;
	mout[14] = tz;
	mout[15] = 1.0f;
}

#pragma mark - interface & implement

enum {
	ATTRIBUTE_VERTEX,
   	ATTRIBUTE_TEXCOORD,
};

@interface AVTileGLView ()
{
    //for opengles
    EAGLContext         *_context;
    GLuint              _framebuffer;
    GLuint              _renderbuffer;
    GLint               _backingWidth;
    GLint               _backingHeight;
    GLuint              _program;
    GLint               _uniformMatrix;
    GLfloat             _vertices[8];
    
    //for render rgb
    GLint               _uniformSampler;
    GLuint              _texture;
    
    //for render yuv
    GLint               _uniformSamplers[3];
    GLuint              _textures[3];
    
    size_t              render_width;
    size_t              render_height;
    size_t              render_rgb_linesize;
    
    UInt8               *render_rgb_bytes;
    size_t              render_rgb_len;
    UInt8               *render_yuv_luma_bytes;
    size_t              render_yuv_luma_len;
    UInt8               *render_yuv_chromaB_bytes;
    size_t              render_yuv_chromaB_len;
    UInt8               *render_yuv_chromaR_bytes;
    size_t              render_yuv_chromaR_len;
}

@property (unsafe_unretained) EN_AV_RENDER_TYPE renderType;
@property (nonatomic, strong) NSRecursiveLock   *drawLock;

//prepare one frame using render context & frame
- (void)prepareWithContext:(AVCodecContext *)avContext
                     frame:(AVFrame *)avFrame;

//play one frame using render context & frame
- (void)render;

@end

@implementation AVTileGLView

#pragma mark - life circle

+ (Class)layerClass
{
	return [CAEAGLLayer class];
}

- (void)setupViewContentAndLock
{
    self.contentMode = UIViewContentModeScaleAspectFit;
    self.autoresizingMask = UIViewAutoresizingFlexibleWidth
    | UIViewAutoresizingFlexibleTopMargin
    | UIViewAutoresizingFlexibleRightMargin
    | UIViewAutoresizingFlexibleLeftMargin
    | UIViewAutoresizingFlexibleHeight
    | UIViewAutoresizingFlexibleBottomMargin;
    
    self.drawLock = [[NSRecursiveLock alloc] init];
    
    render_width = 0;
    render_height = 0;
    render_rgb_linesize = 0;
    render_rgb_bytes = NULL;
    render_rgb_len = 0;
    render_yuv_luma_bytes = NULL;
    render_yuv_luma_len = 0;
    render_yuv_chromaB_bytes = NULL;
    render_yuv_chromaB_len = 0;
    render_yuv_chromaR_bytes = NULL;
    render_yuv_chromaR_len = 0;
}

- (id)init
{
    self = [super init];
    if (self) {
        [self setupViewContentAndLock];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self setupViewContentAndLock];
    }
    return self;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setupViewContentAndLock];
    }
    return self;
}

- (void)setUpGL
{
    [self clearUpGL];
    CAEAGLLayer *eaglLayer = (CAEAGLLayer*)self.layer;
    eaglLayer.opaque = YES;
    eaglLayer.drawableProperties = [NSDictionary dictionaryWithObjectsAndKeys:
                                    [NSNumber numberWithBool:FALSE], kEAGLDrawablePropertyRetainedBacking,
                                    kEAGLColorFormatRGBA8, kEAGLDrawablePropertyColorFormat, nil];
    
    _context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    
    if (!_context ||
        ![EAGLContext setCurrentContext:_context]) {
        NSLog(@"failed to setup EAGLContext");
        return;
    }
    
    glGenFramebuffers(1, &_framebuffer);
    glGenRenderbuffers(1, &_renderbuffer);
    glBindFramebuffer(GL_FRAMEBUFFER, _framebuffer);
    glBindRenderbuffer(GL_RENDERBUFFER, _renderbuffer);
    [_context renderbufferStorage:GL_RENDERBUFFER fromDrawable:(CAEAGLLayer*)self.layer];
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_WIDTH, &_backingWidth);
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_HEIGHT, &_backingHeight);
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, _renderbuffer);
    
    GLenum status = glCheckFramebufferStatus(GL_FRAMEBUFFER);
    if (status != GL_FRAMEBUFFER_COMPLETE) {
        
        NSLog(@"failed to make complete framebuffer object %x", status);
        return;
    }
    
    GLenum glError = glGetError();
    if (GL_NO_ERROR != glError) {
        NSLog(@"failed to setup GL %x", glError);
        return;
    }
    
    if (![self loadShaders]) {
        return;
    }
    
    _vertices[0] = -1.0f;  // x0
    _vertices[1] = -1.0f;  // y0
    _vertices[2] =  1.0f;  // ..
    _vertices[3] = -1.0f;
    _vertices[4] = -1.0f;
    _vertices[5] =  1.0f;
    _vertices[6] =  1.0f;  // x3
    _vertices[7] =  1.0f;  // y3
    
    [self updateVertices];
    
    NSLog(@"OK setup GL");
}

- (void)clearUpGL
{
    //for rgb
    if (_texture) {
        glDeleteTextures(1, &_texture);
        _texture = 0;
    }
    
    //for yuv
    if (_textures[0]) {
        glDeleteTextures(3, _textures);
    }
    
    if (_framebuffer) {
        glDeleteFramebuffers(1, &_framebuffer);
        _framebuffer = 0;
    }
    
    if (_renderbuffer) {
        glDeleteRenderbuffers(1, &_renderbuffer);
        _renderbuffer = 0;
    }
    
    if (_program) {
        glDeleteProgram(_program);
        _program = 0;
    }
	
	if ([EAGLContext currentContext] == _context) {
		[EAGLContext setCurrentContext:nil];
	}
    
    _context = nil;
}

- (void)dealloc
{
    [self clearUpGL];
    
    if (render_rgb_bytes) {
        free(render_rgb_bytes);
    }
    
    if (render_yuv_luma_bytes) {
        free(render_yuv_luma_bytes);
    }
    
    if (render_yuv_chromaB_bytes) {
        free(render_yuv_chromaB_bytes);
    }
    
    if (render_yuv_chromaR_bytes) {
        free(render_yuv_chromaR_bytes);
    }
    
    self.drawLock = nil;
}

#pragma mark - render

- (BOOL)isValid
{
    if (!self.renderType) {
        return NO;
    }
    
    BOOL _isValid = NO;
    
    switch (self.renderType) {
        case AV_RENDER_TYPE_RGB:
        {
            _isValid = (_texture != 0);
        }
            break;
        case AV_RENDER_TYPE_YUV:
        {
            _isValid = (_textures[0] != 0);
        }
        default:
            break;
    }
    
    return _isValid;
}

- (NSString *)fragmentShader
{
    if (!self.renderType) {
        return yuvFragmentShaderString;
    }
    
    NSString *_fragmentShader = nil;
    
    switch (self.renderType) {
        case AV_RENDER_TYPE_RGB:
        {
            _fragmentShader = rgbFragmentShaderString;
        }
            break;
        case AV_RENDER_TYPE_YUV:
        {
            _fragmentShader = yuvFragmentShaderString;
        }
        default:
            break;
    }
    
    return yuvFragmentShaderString;
}

- (void)resolveUniforms:(GLuint)program
{
    if (!self.renderType) {
        return;
    }
    
    switch (self.renderType) {
        case AV_RENDER_TYPE_RGB:
        {
            _uniformSampler = glGetUniformLocation(program, "s_texture");
        }
            break;
        case AV_RENDER_TYPE_YUV:
        {
            _uniformSamplers[0] = glGetUniformLocation(program, "s_texture_y");
            _uniformSamplers[1] = glGetUniformLocation(program, "s_texture_u");
            _uniformSamplers[2] = glGetUniformLocation(program, "s_texture_v");
        }
        default:
            break;
    }
}

static void copyBufferData(UInt8 *src,
                           size_t linesize,
                           size_t width,
                           size_t height,
                           UInt8 **des_buffer,
                           size_t *des_len)
{
    width = MIN(linesize, width);
    size_t buffer_len_needed = width * height;
    
    if (*des_len < buffer_len_needed) {
        if (*des_buffer) {
            free(*des_buffer);
        }
        *des_buffer = malloc(buffer_len_needed);
        *des_len = buffer_len_needed;
    }
    else {
        if (*des_buffer && *des_len) {
            memset(*des_buffer, '\0', *des_len);
        }
    }
    
    UInt8 *dst = *des_buffer;
    for (NSUInteger i = 0; i < height; ++i) {
        memcpy(dst, src, width);
        dst += width;
        src += linesize;
    }
}

- (void)prepareWithContext:(AVCodecContext *)avContext
                     frame:(AVFrame *)avFrame
{
    [self.drawLock lock];
    EN_AV_RENDER_TYPE tmpRenderType = AV_RENDER_TYPE_UNKNOWN;
    
    if (avContext) {
        render_width = avContext->width;
        render_height = avContext->height;
        
        if (avFrame) {
            if (avContext->pix_fmt == AV_PIX_FMT_YUV420P
                || avContext->pix_fmt == AV_PIX_FMT_YUVJ420P) {
                
                tmpRenderType = AV_RENDER_TYPE_YUV;
                
                copyBufferData(avFrame->data[0],
                               avFrame->linesize[0],
                               avContext->width,
                               avContext->height,
                               &render_yuv_luma_bytes,
                               &render_yuv_luma_len);
                
                //                        renderTmp.luma = copyFrameData(avFrame->data[0],
                //                                                       avFrame->linesize[0],
                //                                                       avContext->width,
                //                                                       avContext->height);
                
                copyBufferData(avFrame->data[1],
                               avFrame->linesize[1],
                               avContext->width / 2,
                               avContext->height / 2,
                               &render_yuv_chromaB_bytes,
                               &render_yuv_chromaB_len);
                //
                //                        renderTmp.chromaB = copyFrameData(avFrame->data[1],
                //                                                          avFrame->linesize[1],
                //                                                          avContext->width / 2,
                //                                                          avContext->height / 2);
                
                copyBufferData(avFrame->data[2],
                               avFrame->linesize[2],
                               avContext->width / 2,
                               avContext->height / 2,
                               &render_yuv_chromaR_bytes,
                               &render_yuv_chromaR_len);
                //
                //                        renderTmp.chromaR = copyFrameData(avFrame->data[2],
                //                                                          avFrame->linesize[2],
                //                                                          avContext->width / 2,
                //                                                          avContext->height / 2);
            }
            else {
                tmpRenderType = AV_RENDER_TYPE_RGB;
                
                struct SwsContext   *_swsContext = NULL;
                BOOL                _pictureAlloc;
                AVPicture           _picture;
                
                _pictureAlloc = avpicture_alloc(&_picture,
                                                PIX_FMT_RGB24,
                                                avContext->width,
                                                avContext->height);
                
                if (_pictureAlloc) {
                    avpicture_free(&_picture);
                    NSLog(@"avpicture_alloc failed");
                    return;
                }
                
                _swsContext = sws_getCachedContext(_swsContext,
                                                   avContext->width,
                                                   avContext->height,
                                                   avContext->pix_fmt,
                                                   avContext->width,
                                                   avContext->height,
                                                   PIX_FMT_RGB24,
                                                   SWS_FAST_BILINEAR,
                                                   NULL,
                                                   NULL,
                                                   NULL);
                
                if (!_swsContext) {
                    avpicture_free(&_picture);
                    sws_freeContext(_swsContext);
                    NSLog(@"sws_getCachedContext failed");
                    return;
                }
                
                sws_scale(_swsContext,
                          (const uint8_t **)avFrame->data,
                          avFrame->linesize,
                          0,
                          avContext->height,
                          _picture.data,
                          _picture.linesize);
                
                render_rgb_linesize = _picture.linesize[0];
                
                size_t buffer_len_needed = render_rgb_linesize * avContext->height;
                
                if (render_rgb_len < buffer_len_needed) {
                    if (render_rgb_bytes) {
                        free(render_rgb_bytes);
                    }
                    render_rgb_bytes = malloc(buffer_len_needed);
                    render_rgb_len = buffer_len_needed;
                }
                else {
                    if (render_rgb_bytes && render_rgb_len) {
                        memset(render_rgb_bytes, '\0', render_rgb_len);
                    }
                }
                
                memcpy(render_rgb_bytes, _picture.data[0], buffer_len_needed);
                
                if (_swsContext) {
                    sws_freeContext(_swsContext);
                }
                
                if (&_picture) {
                    avpicture_free(&_picture);
                }
            }
        }
    }
    
    if (tmpRenderType != self.renderType) {
        self.renderType = tmpRenderType;
        if ([NSThread isMainThread]) {
            [self setUpGL];
        }
        else {
            [self performSelectorOnMainThread:@selector(setUpGL) withObject:nil waitUntilDone:YES];
        }
    }
    [self.drawLock unlock];
}

- (void)drawNext
{
    if (self.renderType == AV_RENDER_TYPE_RGB
        && !render_rgb_len) {
        return;
    }
    
    if (self.renderType == AV_RENDER_TYPE_YUV
        && (!render_yuv_luma_len || !render_yuv_chromaB_len || !render_yuv_chromaR_len)){
        return;
    }
    
    
    const NSUInteger frameWidth = render_width;
    const NSUInteger frameHeight = render_height;
    
        switch (self.renderType) {
            case AV_RENDER_TYPE_RGB:
            {
                glPixelStorei(GL_UNPACK_ALIGNMENT, 1);
                
                if (0 == _texture) {
                    glGenTextures(1, &_texture);
                }
                
                glBindTexture(GL_TEXTURE_2D, _texture);
                
                glTexImage2D(GL_TEXTURE_2D,
                             0,
                             GL_RGB,
                             frameWidth,
                             frameHeight,
                             0,
                             GL_RGB,
                             GL_UNSIGNED_BYTE,
                             render_rgb_bytes);
                
                glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
                glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
                glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
                glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
            }
                break;
            case AV_RENDER_TYPE_YUV:
            {
                glPixelStorei(GL_UNPACK_ALIGNMENT, 1);
                
                if (0 == _textures[0]) {
                    glGenTextures(3, _textures);
                }
                
                const UInt8 *pixels[3] = {render_yuv_luma_bytes, render_yuv_chromaB_bytes, render_yuv_chromaR_bytes};
                const NSUInteger widths[3]  = {frameWidth, frameWidth / 2, frameWidth / 2};
                const NSUInteger heights[3] = {frameHeight, frameHeight / 2, frameHeight / 2};
                
                for (int i = 0; i < 3; ++i) {
                    glBindTexture(GL_TEXTURE_2D, _textures[i]);
                    
                    glTexImage2D(GL_TEXTURE_2D,
                                 0,
                                 GL_LUMINANCE,
                                 widths[i],
                                 heights[i],
                                 0,
                                 GL_LUMINANCE,
                                 GL_UNSIGNED_BYTE,
                                 pixels[i]);
                    
                    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
                    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
                    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
                    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
                }
            }
            default:
                break;
        }
    
}

- (BOOL)prepareRender
{
    BOOL _prepareRender = NO;
    
    switch (self.renderType) {
        case AV_RENDER_TYPE_RGB:
        {
            if (_texture != 0) {
                glActiveTexture(GL_TEXTURE0);
                glBindTexture(GL_TEXTURE_2D, _texture);
                glUniform1i(_uniformSampler, 0);
                
                _prepareRender = YES;
            }
        }
            break;
        case AV_RENDER_TYPE_YUV:
        {
            if (_textures[0] != 0) {
                for (int i = 0; i < 3; ++i) {
                    glActiveTexture(GL_TEXTURE0 + i);
                    glBindTexture(GL_TEXTURE_2D, _textures[i]);
                    glUniform1i(_uniformSamplers[i], i);
                }
                
                _prepareRender = YES;
            }
        }
        default:
            break;
    }
    
    return _prepareRender;
}

#pragma mark -

- (void)layoutSubviews
{
    if (self.renderType == AV_RENDER_TYPE_UNKNOWN) {
        return;
    }
    
    [self.drawLock lock];
    glBindRenderbuffer(GL_RENDERBUFFER, _renderbuffer);
    [_context renderbufferStorage:GL_RENDERBUFFER fromDrawable:(CAEAGLLayer*)self.layer];
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_WIDTH, &_backingWidth);
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_HEIGHT, &_backingHeight);
    
    GLenum status = glCheckFramebufferStatus(GL_FRAMEBUFFER);
    if (status != GL_FRAMEBUFFER_COMPLETE) {
        NSLog(@"failed to make complete framebuffer object %x", status);
    }
    else {
        NSLog(@"OK setup GL framebuffer %d:%d", _backingWidth, _backingHeight);
    }
    
    [self updateVertices];
    [self render];
    [self.drawLock unlock];
}

- (void)setContentMode:(UIViewContentMode)contentMode
{
    [super setContentMode:contentMode];
    [self updateVertices];
    
    if (self.isValid) {
        [self render];
    }
}

- (BOOL)loadShaders
{
    BOOL result = NO;
    GLuint vertShader = 0, fragShader = 0;
    
	_program = glCreateProgram();
	
    vertShader = compileShader(GL_VERTEX_SHADER, vertexShaderString);
	if (!vertShader)
        goto exit;
    
	fragShader = compileShader(GL_FRAGMENT_SHADER, self.fragmentShader);
    if (!fragShader)
        goto exit;
    
	glAttachShader(_program, vertShader);
	glAttachShader(_program, fragShader);
	glBindAttribLocation(_program, ATTRIBUTE_VERTEX, "position");
    glBindAttribLocation(_program, ATTRIBUTE_TEXCOORD, "texcoord");
	
	glLinkProgram(_program);
    
    GLint status;
    glGetProgramiv(_program, GL_LINK_STATUS, &status);
    if (status == GL_FALSE) {
		NSLog(@"Failed to link program %d", _program);
        goto exit;
    }
    
    result = validateProgram(_program);
    
    _uniformMatrix = glGetUniformLocation(_program, "modelViewProjectionMatrix");
    [self resolveUniforms:_program];
	
exit:
    
    if (vertShader)
        glDeleteShader(vertShader);
    if (fragShader)
        glDeleteShader(fragShader);
    
    if (result) {
        
        NSLog(@"OK setup GL programm");
        
    } else {
        
        glDeleteProgram(_program);
        _program = 0;
    }
    
    return result;
}

- (void)updateVertices
{
    const BOOL fit = (self.contentMode == UIViewContentModeScaleAspectFit);
    const float width   = render_width;
    const float height  = render_height;
    
    const float dH = (float)_backingHeight / height;
    const float dW = (float)_backingWidth / width;
    const float dd = fit ? MIN(dH, dW) : MAX(dH, dW);
    const float h = (height * dd / (float)_backingHeight);
    const float w = (width  * dd / (float)_backingWidth );
    
    _vertices[0] = - w;
    _vertices[1] = - h;
    _vertices[2] =   w;
    _vertices[3] = - h;
    _vertices[4] = - w;
    _vertices[5] =   h;
    _vertices[6] =   w;
    _vertices[7] =   h;
}

- (void)render
{
    [self.drawLock lock];
    static const GLfloat texCoords[] = {
        0.0f, 1.0f,
        1.0f, 1.0f,
        0.0f, 0.0f,
        1.0f, 0.0f,
    };
    
    [EAGLContext setCurrentContext:_context];
    
    glBindFramebuffer(GL_FRAMEBUFFER, _framebuffer);
    glViewport(0, 0, _backingWidth, _backingHeight);
    glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT);
    glUseProgram(_program);
    
    [self drawNext];
    
    if ([self prepareRender]) {
        
        GLfloat modelviewProj[16];
        mat4f_LoadOrtho(-1.0f, 1.0f, -1.0f, 1.0f, -1.0f, 1.0f, modelviewProj);
        glUniformMatrix4fv(_uniformMatrix, 1, GL_FALSE, modelviewProj);
        
        glVertexAttribPointer(ATTRIBUTE_VERTEX, 2, GL_FLOAT, 0, 0, _vertices);
        glEnableVertexAttribArray(ATTRIBUTE_VERTEX);
        glVertexAttribPointer(ATTRIBUTE_TEXCOORD, 2, GL_FLOAT, 0, 0, texCoords);
        glEnableVertexAttribArray(ATTRIBUTE_TEXCOORD);
        
#if 0
        if (!validateProgram(_program))
        {
            NSLog(@"Failed to validate program");
            return;
        }
#endif
        
        glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    }
    
    glBindRenderbuffer(GL_RENDERBUFFER, _renderbuffer);
    [_context presentRenderbuffer:GL_RENDERBUFFER];
    
    [self.drawLock unlock];
}

@end
