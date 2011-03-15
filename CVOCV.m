
#include "cv.h"
#import "PuckCameraController.h"

@implementation PuckCameraController

static int qsort_carea_compare(const void* _a, const void* _b);

- (void)awakeFromNib
{
    // Create the capture session
	mCaptureSession = [[QTCaptureSession alloc] init];
    
    mOutput = [[QTCaptureDecompressedVideoOutput alloc] init];
    
    [mOutput setPixelBufferAttributes:[NSDictionary dictionaryWithObjectsAndKeys:
                                        [NSNumber numberWithDouble:320.0], (id)kCVPixelBufferWidthKey,
                                        [NSNumber numberWithDouble:240.0], (id)kCVPixelBufferHeightKey,
                                        [NSNumber numberWithUnsignedInt:kCVPixelFormatType_32RGBA], (id)kCVPixelBufferPixelFormatTypeKey,
                                        nil]];
    
    [mOutput setDelegate:self];
    
    //Allocate all the things we might need.
    trans32f    = cvCreateImage(cvSize(320,240), IPL_DEPTH_32F, 1);
    trans8u     = cvCreateImage(cvSize(320,240), IPL_DEPTH_8U,  1);
    threshIm    = cvCreateImage(cvSize(320,240), IPL_DEPTH_8U,  1);
    im          = (IplImage*)malloc(sizeof(IplImage));
    moments     = (CvMoments*)malloc(sizeof(CvMoments));
    
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
    cvReleaseImage(&trans32f);
    cvReleaseImage(&trans8u);
    cvReleaseImage(&threshIm);
    free(im);
    free(moments);
	
	[super dealloc];
}

//http://developer.apple.com/documentation/GraphicsImaging/Reference/CoreVideoRef/Reference/reference.html
- (void)captureOutput:(QTCaptureOutput *)captureOutput didOutputVideoFrame:(CVImageBufferRef)videoFrame withSampleBuffer:(QTSampleBuffer *)sampleBuffer fromConnection:(QTCaptureConnection *)connection
{
    //Clear out our image.
    memset(im, 0, sizeof(IplImage));
    
    memset(moments, 0, sizeof(CvMoments));
    
    CVPixelBufferLockBaseAddress((CVPixelBufferRef)videoFrame, 0);
    
    /*
     //Region of interest struct organization.
     typedef struct _IplROI {
        int  coi;  //Channel of interest. (0 means 'all')
        int  xOffset;
        int  yOffset;
        int  width;
        int  height;
     } IplROI;
     */
    
    //Fill it in.
    im->nSize       = sizeof(IplImage);
    im->ID          = 0;
    im->nChannels   = 1;
    im->depth       = IPL_DEPTH_32S;
    im->dataOrder   = 0;
    im->origin      = 0; //Top left origin. Guessing.
    im->width       = CVPixelBufferGetWidth((CVPixelBufferRef)videoFrame);
    im->height      = CVPixelBufferGetHeight((CVPixelBufferRef)videoFrame);
    im->roi         = 0; //Region of interest. (struct IplROI)
    im->maskROI     = 0;
    im->imageId     = 0;
    im->tileInfo    = 0;
    im->imageSize   = CVPixelBufferGetDataSize((CVPixelBufferRef)videoFrame);
    im->imageData   = (char*)CVPixelBufferGetBaseAddress((CVPixelBufferRef)videoFrame);
    im->widthStep   = CVPixelBufferGetBytesPerRow((CVPixelBufferRef)videoFrame);
    im->imageDataOrigin = (char*)CVPixelBufferGetBaseAddress((CVPixelBufferRef)videoFrame);
    
    cvConvertScale(im, trans32f, 1, 0);

    cvConvertScale(trans32f, trans8u, 1, 0);
    
    const int threshValue = 128;
    //cvThreshold(trans8u, threshIm, threshValue, 255, CV_THRESH_BINARY);
    
    CvSeq* contour_list = NULL;
	CvMemStorage* contour_storage = cvCreateMemStorage(1000);

    //Retrieval mode:
    // -CV_RETR_EXTERNAL retrieves only the extreme outer contours (list);
    // -CV_RETR_LIST retrieves all the contours (list); (and holes)
    // -CV_RETR_CCOMP retrieves the two-level hierarchy (list of connected components);
    // -CV_RETR_TREE retrieves the complete hierarchy (tree).
    
    //Method:
    // -CV_CHAIN_CODE outputs contours in the Freeman chain code.
    // -CV_CHAIN_APPROX_NONE translates all the points from the chain code into points;
    // -CV_CHAIN_APPROX_SIMPLE compresses horizontal, vertical, and diagonal segments, that is, it leaves only their ending points.
    // -CV_CHAIN_APPROX_TC89_L1, CV_CHAIN_APPROX_TC89_KCOS are two versions of the Teh-Chin approximation algorithm.
    
	CvContourRetrievalMode  retrieve_mode = CV_RETR_LIST;
	cvFindContours(trans8u, contour_storage, &contour_list,
                   sizeof(CvContour), retrieve_mode, CV_CHAIN_APPROX_SIMPLE);

    CvSeq* contour_ptr = contour_list;
    
	int nCvSeqsFound = 0;
    
    int minArea = 20;
    int maxArea = (340*240)/4;
    
	// put the contours from the linked list, into an array for sorting
	while( (contour_ptr != NULL) ) {
        float area = fabs(cvContourArea(contour_ptr, CV_WHOLE_SEQ));
        
        if( (area > minArea) && (area < maxArea) ) {
            if (nCvSeqsFound < MAX_NUM_CONTOURS_TO_FIND) {
				cvSeqBlobs[nCvSeqsFound] = contour_ptr;
                nCvSeqsFound++;
            }
		}
        contour_ptr = contour_ptr->h_next;
    }
    
    if(nCvSeqsFound > 0) {
		qsort(cvSeqBlobs, nCvSeqsFound, sizeof(CvSeq*), qsort_carea_compare);
	}
    
    if(nCvSeqsFound > 0) {
        //float area = cvContourArea(cvSeqBlobs[0], CV_WHOLE_SEQ);
        CvRect rect	= cvBoundingRect(cvSeqBlobs[0], 0);
        cvMoments(cvSeqBlobs[0], moments);
        
        int centx = (int)(moments->m10 / moments->m00);
        int centy = (int)(moments->m01 / moments->m00);
        NSLog(@"cent x %d cent y %d width %d height %d ", centx, centy, rect.width, rect.height);
    }
    
    CVPixelBufferUnlockBaseAddress((CVPixelBufferRef)videoFrame, 0);
}

//Because I'm lazy like that.
static int qsort_carea_compare(const void* _a, const void* _b) 
{
	int out = 0;
	CvSeq* a = *((CvSeq **)_a);
	CvSeq* b = *((CvSeq **)_b);
	// use opencv to calc size, then sort based on size
	float areaa = fabs(cvContourArea(a, CV_WHOLE_SEQ));
	float areab = fabs(cvContourArea(b, CV_WHOLE_SEQ));
	// note, based on the -1 / 1 flip
	// we sort biggest to smallest, not smallest to biggest
	if( areaa > areab ) { out = -1; }
	else {                out =  1; }
	return out;
}

@end
