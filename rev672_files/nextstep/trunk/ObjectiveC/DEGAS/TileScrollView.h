
/* Generated by Interface Builder */

#import <appkit/ScrollView.h>


#define U_TILE_HEIGHT_DEF    25.0
#define L_TILE_HEIGHT_DEF    30.0
#define LS_TILE_WIDTH_DEF    120.0
#define RS_TILE_WIDTH_DEF    25.0

#define ADJUST               1.0

#define PARAM_SEP            25.0
#define STRETCHBOX_HEIGHT    5.0

#define SMALL_FONT_SIZE      10.0
#define LARGE_FONT_SIZE      14.0


@interface TileScrollView:ScrollView
{
    id  synthesize;
    id  template;
    id  rule;
    id  phoneDescriptionObj;

    id  upperTileClipView;
    id  lowerTileClipView;
    id  leftTileClipView;
    id  rightTileClipView;
    id  corner1ClipView, corner2ClipView, corner3ClipView, corner4ClipView;

    id  mainImageView, mainImage;
    id  upperTileImageView, upperTileImage;
    id  lowerTileImageView, lowerTileImage;
    id  leftTileImageView, leftTileImage;
    id  rightTileImageView, rightTileImage;
    id  corner3TileImageView, corner3TileImage;
    id  corner4TileImageView, corner4TileImage;


    NXCoord upperTileHeight;
    NXCoord lowerTileHeight;
    NXCoord leftTileWidth;
    NXCoord rightTileWidth;

    NXSize mainImageSize;
    NXSize upperTileImageSize;
    NXSize lowerTileImageSize;
    NXSize leftTileImageSize;
    NXSize rightTileImageSize;
    NXSize corner3TileImageSize;
    NXSize corner4TileImageSize;

    id crosshairCursor;
    int trackingTag;
}

- initFrame:(const NXRect *)theFrame;
- free;

- tile;
- scrollClip:aClipView to:(NXPoint *)aPoint;

- setUpperTileDocView:aView;
- upperTileDocView;

- setLowerTileDocView:aView;
- lowerTileDocView;

- setLeftTileDocView:aView;
- leftTileDocView;

- setRightTileDocView:aView;
- rightTileDocView;

- setCorner3TileDocView:aView;
- corner3TileDocView;

- diphoneDisplay:sender;

@end