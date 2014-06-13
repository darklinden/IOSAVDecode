/***********************************************************
 * FileName         : AVTileGLView.h
 * Version Number   : 1.0
 * Date             : 2013-06-03
 * Author           : darklinden
 * Change log (ID, Date, Author, Description) :
    $$$ Revision 1.0, 2013-06-03, darklinden, Create File With KxMovieGLView.
 ************************************************************/

#import <UIKit/UIKit.h>

/*
 * 此view用于绘制播放画面, 当做普通view使用即可
 * 已知问题: 在播放过程中旋转/设置frame时可能会导致问题(crash / view展示不正确等), 解决中
 */
@interface AVTileGLView : UIView

@end
