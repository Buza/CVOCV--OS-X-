/*
 *  CVOCVController.m
 *
 *  Created by buza on 10/02/08.
 *
 *  Brought to you by buzamoto. http://buzamoto.com
 */

#include "cv.h"
#import "CVOCVController.h"
#import "OpenCVProcessor.h"

//For IKImageView dealings.
#import "CGImageWrapper.h"

@implementation CVOCVController

static BOOL updated;
static BOOL grabImage;
static IplImage *capturedImage;

+ (void) grabImage
{
    grabImage = YES;
}

+ (IplImage*) capturedImage
{
    return capturedImage;
}

+ (BOOL) bgUpdated
{
    return updated;
}

+ (void) setViewed
{       
    updated = NO;
}

- (void)awakeFromNib
{
    // Create the capture session
	mCaptureSession = [[QTCaptureSession alloc] init];
    
    mOutput = [[QTCaptureDecompressedVideoOutput alloc] init];

    [mOutput setPixelBufferAttributes:[NSDictionary dictionaryWithObjectsAndKeys:
                                        [NSNumber numberWithDouble:320.0], (id)kCVPixelBufferWidthKey,
                                        [NSNumber numberWithDouble:240.0], (id)kCVPixelBufferHeightKey,
                                        [NSNumber numberWithUnsignedInt:kCVPixelFormatType_24RGB], (id)kCVPixelBufferPixelFormatTypeKey,
                                        nil]];
    
    [mOutput setDelegate:self];

    frameImage = (IplImage*)malloc(sizeof(IplImage));
    
    capturedImage = 0;
    
    (IplImage*)malloc(sizeof(IplImage));
    
	BOOL success = NO;
	NSError *error;
	
    //Find a device  
    QTCaptureDevice *videoDevice = [QTCaptureDevice defaultInputDeviceWithMediaType:QTMediaTypeVideo];
    success = [videoDevice open:&error];
    
    NSLog(@"Devices found: %@", [QTCaptureDevice inputDevices]);
    
    videoDevice = [[QTCaptureDevice inputDevices] objectAtIndex:2];
    
    NSLog(@"Selecting device %@", videoDevice);
    
    [videoDevice open:&error];
    
    if (error != nil) {
        NSLog(@"Had some trouble selecting that device. I'm leaving now.");
        return;
    }
    
    //Add the video device to the session as a device input
    if (videoDevice) {

		mCaptureVideoDeviceInput = [[QTCaptureDeviceInput alloc] initWithDevice:videoDevice];
		success = [mCaptureSession addInput:mCaptureVideoDeviceInput error:&error];
        
		if (!success) {
            NSLog(@"Couldn't set up the input device. I'm leaving now.");
            return;
		}
        
        success = [mCaptureSession addOutput:mOutput error:&error];
        
		if (!success) {
            NSLog(@"Couldn't set up the output device. I'm leaving now.");
            return;
		}
        
        [mCaptureView setCaptureSession:mCaptureSession];
        
        //Looks like we're good to go.
        [mCaptureSession startRunning];
        
        grabImage = NO;
        imageView.autoresizes = YES;
        
        
        /*
        //Display a nice temporary image in the third window before capture.
        NSString* imageName = [[NSBundle mainBundle] pathForResource:@"noimage" ofType:@"png"];
        NSImage* noImage = [[NSImage alloc] initWithContentsOfFile:imageName];
        
        if(noImage != nil) {
            NSBitmapImageRep *bRep = [[noImage representations] objectAtIndex:0];
            CGImageRef noImageCG = [bRep CGImage];
            [imageView setImage:noImageCG imageProperties:nil];
            [imageView zoomImageToFit:self];
        }
        [noImage release];
        */
        
        
        
	}
}

- (void)windowWillClose:(NSNotification *)notification
{
	[mCaptureSession stopRunning];
    
    if ([[mCaptureVideoDeviceInput device] isOpen])
        [[mCaptureVideoDeviceInput device] close];
}

- (void)dealloc
{
	[mCaptureSession release];
	[mCaptureVideoDeviceInput release];

    free(frameImage);
    if(capturedImage) {
        cvReleaseImage(&capturedImage);
    }
	
	[super dealloc];
}

//Create a CGImageRef from the video frame so we can send it to the ImageKitView.
static CGImageRef CreateCGImageFromPixelBuffer(CVImageBufferRef inImage, OSType inPixelFormat)
{
    CGColorSpaceRef colorSpace = CGColorSpaceCreateWithName(kCGColorSpaceGenericRGB);
    
    void *baseAddress = CVPixelBufferGetBaseAddress(inImage);
    size_t bytesPerRow = CVPixelBufferGetBytesPerRow(inImage);
    
    size_t width = CVPixelBufferGetWidth(inImage);
    size_t height = CVPixelBufferGetHeight(inImage);
    CGImageAlphaInfo alphaInfo = kCGImageAlphaNone;
    CGDataProviderRef provider = provider = CGDataProviderCreateWithData(NULL, baseAddress, bytesPerRow * height, NULL);

    CGImageRef image = CGImageCreate(width, height, 8, 24, bytesPerRow, colorSpace, alphaInfo, provider, NULL, false, kCGRenderingIntentDefault);
    
    // Once the image is created we can release our reference to the provider and the colorspace, they are retained by the image
    if (provider) {
        CGDataProviderRelease(provider);
    if (colorSpace) 
        CGColorSpaceRelease(colorSpace);
    }
    
    return image;
}

/*
 * Here, we would like to allow the user to capture video frames and send them to 
 * the special ImageKit view for background subtraction or other OpenCV-related tasks
 * that require a reference frame. If we don't call setImage: on the main thread,
 * we won't see an update. For the uninitiated, callback procedures like 
 * captureOutput: below are typically *not* called from the main thread. We also 
 * get to wrap our CGImageRef up into a custom Cocoa object just to hold it while 
 * we pass it to this method, because performSelectorOnMainThread takes an id.
 */
-(void) updateView:(CGImageWrapper*)wrappedImage
{
    [imageView setImage:wrappedImage.theImage imageProperties:nil];
    [imageView zoomImageToFit:self];

    [wrappedImage release];
}

/*
 * Here's one reference that I found moderately useful for this CoreVideo stuff:
 * http://developer.apple.com/documentation/graphicsimaging/Reference/CoreVideoRef/Reference/reference.html
 */
- (void)captureOutput:(QTCaptureOutput *)captureOutput didOutputVideoFrame:(CVImageBufferRef)videoFrame withSampleBuffer:(QTSampleBuffer *)sampleBuffer fromConnection:(QTCaptureConnection *)connection
{
    CVPixelBufferLockBaseAddress((CVPixelBufferRef)videoFrame, 0);
    
    //Fill in the OpenCV image struct from the data from CoreVideo.
    frameImage->nSize       = sizeof(IplImage);
    frameImage->ID          = 0;
    frameImage->nChannels   = 3;
    frameImage->depth       = IPL_DEPTH_8U;
    frameImage->dataOrder   = 0;
    frameImage->origin      = 0; //Top left origin.
    frameImage->width       = CVPixelBufferGetWidth((CVPixelBufferRef)videoFrame);
    frameImage->height      = CVPixelBufferGetHeight((CVPixelBufferRef)videoFrame);
    frameImage->roi         = 0; //Region of interest. (struct IplROI).
    frameImage->maskROI     = 0;
    frameImage->imageId     = 0;
    frameImage->tileInfo    = 0;
    frameImage->imageSize   = CVPixelBufferGetDataSize((CVPixelBufferRef)videoFrame);
    frameImage->imageData   = (char*)CVPixelBufferGetBaseAddress((CVPixelBufferRef)videoFrame);
    frameImage->widthStep   = CVPixelBufferGetBytesPerRow((CVPixelBufferRef)videoFrame);
    frameImage->imageDataOrigin = (char*)CVPixelBufferGetBaseAddress((CVPixelBufferRef)videoFrame);

    //If we were asked to capture a background frame. Do it now before we unlock the pixels.
    if(grabImage) {
        CGImageWrapper *iwrap = [[CGImageWrapper alloc] initWithCGImage:CreateCGImageFromPixelBuffer(videoFrame, kCVPixelFormatType_24RGB)];
        [self performSelectorOnMainThread:@selector(updateView:) withObject:iwrap waitUntilDone:YES];
        if(!capturedImage) {
            //capturedImage = (IplImage*)malloc(sizeof(IplImage));
            capturedImage = cvCreateImage(cvGetSize(frameImage), IPL_DEPTH_8U, 3); 
        }
        cvCopy(frameImage, capturedImage, 0);
        updated = YES;
        grabImage = NO;
    }
    
    //Process the frame, and get the result.
    //IplImage *resultImage = [OpenCVProcessor passThrough:frameImage];
    //IplImage *resultImage = [OpenCVProcessor noiseFilter:frameImage];
    //IplImage *resultImage = [OpenCVProcessor findSquares:frameImage];
    //IplImage *resultImage = [OpenCVProcessor hueSatHistogram:frameImage];
    //IplImage *resultImage = [OpenCVProcessor downsize8:frameImage];
    
    //Back project example. Hit the space bar to capture the reference image.
    //IplImage *resultImage = [OpenCVProcessor backProject:frameImage];
    
    
    IplImage *resultImage = [OpenCVProcessor cannyTest:frameImage];

    [self texturizeImage:resultImage];
    
    CVPixelBufferUnlockBaseAddress((CVPixelBufferRef)videoFrame, 0);
}

-(void) texturizeImage:(IplImage*) image
{
    int newIndex = openGLView->imageIndex;
    newIndex = (newIndex + 1) % IMAGE_CACHE_SIZE;
    openGLView->cvTextures[newIndex].texImage = image;
    openGLView->imageIndex = newIndex;
    [openGLView setNeedsDisplay:YES];
}

@end
