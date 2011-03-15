/*
 *  OpenCVProcessor.h
 *
 *  Created by buza on 10/02/08.
 *
 *  Brought to you by buzamoto. http://buzamoto.com
 */

/*
 * This class holds the OpenCV examples.
 * 
 * In order to implement your own, just follow the simple 'passThrough'
 * example. All that CVOCV expects you to do in your function is to
 * return a newly allocated image in RGB format. The renderer will 
 * deallocate this image when necessary. All other resources you allocate
 * however, should be released on your own.
 *
 */

#import <Cocoa/Cocoa.h>

@interface OpenCVProcessor : NSObject 
{

}

//Passthrough operation.
+ (IplImage *) passThrough:(IplImage *)frame;

//Color conversion.
+ (IplImage *) hsv:(IplImage *)frame;

//Image resizing.
+ (IplImage *) downsize4:(IplImage *)frame;
+ (IplImage *) downsize8:(IplImage *)frame;

//Image morphology.
+ (IplImage *) erode:(IplImage *)frame;
+ (IplImage *) dilate:(IplImage *)frame;
+ (IplImage *) open:(IplImage *)frame;
+ (IplImage *) close:(IplImage *)frame;
+ (IplImage *) adaptiveThresh:(IplImage *)frame;

//Image segmentation.
+ (IplImage *) meanShift:(IplImage *)frame;

//Image processing.
+ (IplImage *) cannyTest:(IplImage *)frame;
+ (IplImage *) blobDetect:(IplImage *)frame;
+ (IplImage *) noiseFilter:(IplImage *)frame;
+ (IplImage *) findSquares:(IplImage *)img;

//Feature detection.
+ (IplImage *) houghLinesStandard:(IplImage *)frame;
+ (IplImage *) houghLinesProbabilistic:(IplImage *)frame;
+ (IplImage *) houghCircles:(IplImage *)frame;

//Movement tracking.
+ (IplImage *) motion:(IplImage *)img;

//Optical flow.
+ (IplImage *) opticalFlowBM:(IplImage *)frame;
+ (IplImage *) opticalFlowLK:(IplImage *)frame;
+ (IplImage *) opticalFlowPyrLK:(IplImage *)frame;

//Histograms.
+ (IplImage *) hueSatHistogram:(IplImage *)frame;
+ (IplImage *) backProject:(IplImage *)frame;


@end
