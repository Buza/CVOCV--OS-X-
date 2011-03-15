/*
 *  CVOCVView.m
 *
 *  Created by buza on 10/02/08.
 *
 *  Brought to you by buzamoto. http://buzamoto.com
 */

#include <OpenGL/OpenGL.h>

#import "CVOCVView.h"
#import "CVOCVController.h"

@implementation CVOCVView

static BOOL initialized = NO;

- (id) initWithFrame: (NSRect) frame
{
	GLuint attribs[] = 
	{
		NSOpenGLPFANoRecovery,
		NSOpenGLPFAWindow,
		NSOpenGLPFAAccelerated,
		NSOpenGLPFADoubleBuffer,
		NSOpenGLPFAColorSize, 24,
		NSOpenGLPFAAlphaSize, 8,
		NSOpenGLPFADepthSize, 24,
		NSOpenGLPFAStencilSize, 8,
		NSOpenGLPFAAccumSize, 0,
		0
	};
    
	NSOpenGLPixelFormat* fmt = [[NSOpenGLPixelFormat alloc] initWithAttributes: (NSOpenGLPixelFormatAttribute*) attribs]; 
	
	if (!fmt) {
		NSLog(@"Couldn't allocate an OpenGL Pixel format.");
    }

	return self = [super initWithFrame:frame pixelFormat: [fmt autorelease]];
}

- (void)dealloc 
{
    int i;
    for(i=0; i<IMAGE_CACHE_SIZE; i++) {
        glDeleteTextures(1, &(cvTextures[i].texId));
        if(cvTextures[i].texImage != 0) {
            cvReleaseImage(&(cvTextures[i].texImage));
        }
        
        #if defined USE_PBO
        glDeleteBuffers(1, &(cvTextures[i].pbId));
        #endif
    }
    
    [super dealloc];
}

-(void) reshape
{
    NSSize bound = [self bounds].size;
    
    glEnable(GL_TEXTURE_2D);
	glShadeModel(GL_SMOOTH);
	glHint(GL_PERSPECTIVE_CORRECTION_HINT, GL_NICEST);
    glViewport(0, 0, (GLfloat)bound.width,  (GLfloat)bound.height);
    
    GLdouble fovy = 30.0;
	GLdouble aspect = (GLfloat)bound.width/(GLfloat)bound.height;
	GLdouble zNear = 1.0;
	GLdouble zFar = 1000.0;
    gluPerspective(fovy,aspect,zNear,zFar);
}
	 
-(void) initialize
{
    GLuint tId[IMAGE_CACHE_SIZE];
    glGenTextures(IMAGE_CACHE_SIZE, tId);
    
    int i;
    for(i=0; i<IMAGE_CACHE_SIZE; i++) {
        cvTextures[i].texId = tId[i];
        cvTextures[i].initialized = 0;
    }
    
    #if defined USE_PBO
    
    GLuint pId[IMAGE_CACHE_SIZE];
    glGenBuffers(IMAGE_CACHE_SIZE, pId);
    for(i=0; i<IMAGE_CACHE_SIZE; i++) {
        cvTextures[i].pbId = pId[i];
    }
    GLenum textureType = GL_TEXTURE_2D;
	glBindBuffer(GL_PIXEL_UNPACK_BUFFER_ARB, 0);
	glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_WRAP_S,GL_CLAMP_TO_EDGE);
	glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_WRAP_T,GL_CLAMP_TO_EDGE);
	glTexImage2D(textureType, 0, GL_RGB, 320, 240, 0, GL_RGB, GL_UNSIGNED_BYTE, NULL);
    
    #endif
    
    //Create a display list for drawing our texture.
    rectList = glGenLists(1);
    
	glNewList(rectList, GL_COMPILE);
    
    glBegin(GL_QUADS);
        GLfloat sz = 1.0;
        glTexCoord2f(0.0f, 0.0f); glVertex3f(-sz, sz, 0.0f);
        glTexCoord2f(1.0f, 0.0f); glVertex3f( sz, sz, 0.0f);
        glTexCoord2f(1.0f, 1.0f); glVertex3f( sz,-sz, 0.0f);
        glTexCoord2f(0.0f, 1.0f); glVertex3f(-sz,-sz, 0.0f);
    glEnd();
	
	glEndList(); 

    imageIndex = -1;   
}

-(void) doPBO:(struct cvTexture*)cvTex
{
    #if defined USE_PBO
    
    size_t width = (cvTex->texImage)->width;
    size_t height = (cvTex->texImage)->height;
    size_t numBytes = width * height * 3;
    
    GLenum target = GL_PIXEL_UNPACK_BUFFER_ARB;
    glBindTexture(GL_TEXTURE_2D, cvTex->texId);
    glBindBuffer(target, cvTex->pbId);
    glBufferData(GL_PIXEL_UNPACK_BUFFER_ARB, numBytes, NULL, GL_DYNAMIC_DRAW); 
    void *pboMemory = glMapBuffer(target, GL_WRITE_ONLY);
    memcpy(pboMemory, (cvTex->texImage)->imageData, numBytes);
    glUnmapBuffer(target);
    glPixelStorei(GL_UNPACK_ROW_LENGTH, width);
    glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_WRAP_S,GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_WRAP_T,GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGB, width, height, 0, GL_RGB, GL_UNSIGNED_BYTE, NULL);
    glBindBuffer(target, 0);
    
    #endif
}

-(void) doTexture:(struct cvTexture*)cvTex
{
    glEnable(GL_TEXTURE_2D);
    glBindTexture(GL_TEXTURE_2D, cvTex->texId);
    glPixelStorei(GL_UNPACK_ALIGNMENT, 1);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGB, (cvTex->texImage)->width, (cvTex->texImage)->height, 
                 0, GL_RGB, GL_UNSIGNED_BYTE, (cvTex->texImage)->imageData);
    cvTex->initialized = 1;
}

- (void) drawRect: (NSRect) rect
{
    [[self openGLContext] makeCurrentContext]; 
    
    if(!initialized) {
        initialized = YES;
        [self initialize];
    }
    
    glClear(GL_COLOR_BUFFER_BIT);
    glEnable(GL_TEXTURE_2D);
    
    glLoadIdentity();

    if(index>=0) {
        
        //See if we can kill an old image.
        int killIndex = (imageIndex + (IMAGE_CACHE_SIZE - 1)) % IMAGE_CACHE_SIZE;
        struct cvTexture killTex =  cvTextures[killIndex];
        if(killTex.texImage != 0) {
            cvReleaseImage(&(killTex.texImage));
            cvTextures[killIndex].texImage = 0;
            cvTextures[killIndex].initialized = 0;
        }
        
        struct cvTexture texr =  cvTextures[imageIndex];
        
        #if defined USE_PBO
        if(!(texr.initialized)) {
            [self doPBO:&texr];    
        }
        #else
        if(!(texr.initialized)) {
            [self doTexture:&texr];    
        }
        #endif
        
        glTranslatef(0.0f, 0.0f,-1.0f);
        
        //Now just draw the texture using our display list.
        glCallList(rectList);
    }

	[[self openGLContext] flushBuffer];
}


- (BOOL)acceptsFirstResponder 
{
    //This allows this view to accept events.
    return YES;
}

//Here, we've bound the space bar to capturing the current image frame.
- (void)keyDown:(NSEvent *)theEvent 
{
    unichar c = [[theEvent charactersIgnoringModifiers] characterAtIndex:0];
    
    switch (c) {
        case ' ':
            [CVOCVController grabImage];
            break;
            
        case 'c':
            break;
    }
            
}

- (void)mouseDown:(NSEvent *)theEvent 
{
    NSPoint windowPoint = [theEvent locationInWindow];
    float x = windowPoint.x;
    float y = windowPoint.y;
}
- (void)mouseUp:(NSEvent *)theEvent 
{
}

- (void)mouseDragged:(NSEvent *)theEvent 
{
    NSPoint windowPoint = [theEvent locationInWindow];
    float x = windowPoint.x;
    float y = windowPoint.y;
}

- (void)scrollWheel:(NSEvent *)theEvent
{
}



@end
