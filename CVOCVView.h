/*
 *  CVOCVView.h
 *
 *  Created by buza on 10/02/08.
 *
 *  Brought to you by buzamoto. http://buzamoto.com
 */

#include "cv.h"
#import <Cocoa/Cocoa.h>

#define glReportError()                             \
{                                                   \
    GLenum error=glGetError();                      \
    if(GL_NO_ERROR!=error)                          \
    {                                               \
        printf("GL error at %s:%d: %s\n",__FILE__,__LINE__,(char*)gluErrorString(error));   \
    }                                               \
}                                                   \

//Uncomment to use PBOs instead of direct texture uploading.
#define USE_PBO

#define IMAGE_CACHE_SIZE 3

struct cvTexture {
    GLuint texId;
    #if defined USE_PBO
    GLuint pbId;
    #endif
    IplImage *texImage;
    short initialized;
};

@interface CVOCVView : NSOpenGLView 
{
    @public
    
        int imageIndex;
        struct cvTexture cvTextures[IMAGE_CACHE_SIZE];
    
        GLuint rectList;
}

//If we want to draw using PBOs.
-(void) doPBO:(struct cvTexture*)cvTex;

//If we want to draw using textures.
-(void) doTexture:(struct cvTexture*)cvTex;

@end
