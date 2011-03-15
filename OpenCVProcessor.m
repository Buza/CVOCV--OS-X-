/*
 *  OpenCVProcessor.m
 *
 *  Created by buza on 10/02/08.
 *
 *  Brought to you by buzamoto. http://buzamoto.com
 */

#include "cv.h"

#import "CVOCVController.h"
#import "OpenCVProcessor.h"

@implementation OpenCVProcessor

//A quicksort comparison function.
static int qsort_carea_compare( const void* _a, const void* _b) 
{
	int out = 0;
    
	CvSeq* a = *((CvSeq **)_a);
	CvSeq* b = *((CvSeq **)_b);
    
	float areaa = fabs(cvContourArea(a, CV_WHOLE_SEQ));
	float areab = fabs(cvContourArea(b, CV_WHOLE_SEQ));
    
	if(areaa > areab) {
        out = -1; 
    }
	else {
        out =  1; 
    }
    
	return out;
}

/*!
 * @function passThrough
 * @discussion The most trivial example. Does nothing but pass the image through, unmodified.
 * @updated 2008-12-23
 */
+ (IplImage *) passThrough:(IplImage *)frame
{
    //First, we need to create our "result" image, that OpenGL will use to display.
    // (The openGL renderer will destroy this when it needs to.)
    IplImage *texImage = cvCreateImage(cvSize(320, 240), IPL_DEPTH_8U, 3);
    
    //Process the image.
    // ...
    
    //Copy the result into our newly allocated image, and pass it on.
    cvCopy(frame, texImage, 0);
    return texImage;
}

/*!
 * @function hsv
 * @discussion Display the image as HSV instead of RGB.
 * @updated 2008-12-23
 */
+ (IplImage *) hsv:(IplImage *)frame
{
    IplImage *texImage = cvCreateImage(cvSize(320, 240), IPL_DEPTH_8U, 3);
    
    cvCvtColor(frame, texImage, CV_RGB2HSV);
    
    return texImage;
}


/*!
 * @function downsize4
 * @discussion Gaussian pyramid downsize by four. Resize up for display by nearest neighbor sampling. 
 * @updated 2009-1-22
 */
+ (IplImage *) downsize4:(IplImage *)frame
{
    IplImage *texImage = cvCreateImage(cvSize(320, 240), IPL_DEPTH_8U, 3);
    IplImage *pyr = cvCreateImage(cvSize(320/2, 240/2), IPL_DEPTH_8U, 3);
    IplImage *pyr2 = cvCreateImage(cvSize(320/4, 240/4), IPL_DEPTH_8U, 3);
    
    cvPyrDown(frame, pyr, IPL_GAUSSIAN_5x5);
    cvPyrDown(pyr, pyr2, IPL_GAUSSIAN_5x5);
    
    cvResize(pyr2, texImage, CV_INTER_NN);
    
    cvReleaseImage(&pyr);
    cvReleaseImage(&pyr2);
    
    return texImage;
}

/*!
 * @function downsize8
 * @discussion Gaussian pyramid downsize by eight. Resize up for display by nearest neighbor sampling. 
 * @updated 2009-1-22
 */
+ (IplImage *) downsize8:(IplImage *)frame
{
    IplImage *texImage = cvCreateImage(cvSize(320, 240), IPL_DEPTH_8U, 3);
    IplImage *pyr = cvCreateImage(cvSize(320/2, 240/2), IPL_DEPTH_8U, 3);
    IplImage *pyr2 = cvCreateImage(cvSize(320/4, 240/4), IPL_DEPTH_8U, 3);
    IplImage *pyr3 = cvCreateImage(cvSize(320/8, 240/8), IPL_DEPTH_8U, 3);
    IplImage *pyr4 = cvCreateImage(cvSize(320/16, 240/16), IPL_DEPTH_8U, 3);
    
    cvPyrDown(frame, pyr, IPL_GAUSSIAN_5x5);
    cvPyrDown(pyr, pyr2, IPL_GAUSSIAN_5x5);
    cvPyrDown(pyr2, pyr3, IPL_GAUSSIAN_5x5);
    cvPyrDown(pyr3, pyr4, IPL_GAUSSIAN_5x5);
    
    cvResize(pyr4, texImage, CV_INTER_NN);
    
    cvReleaseImage(&pyr);
    cvReleaseImage(&pyr2);
    cvReleaseImage(&pyr3);
    cvReleaseImage(&pyr4);
    
    return texImage;
}

/*!
 * @function erode
 * @discussion Perform image erosion. Erosion computes a local minimum over the area of the kernel. 
 * @updated 2009-1-22
 */
+ (IplImage *) erode:(IplImage *)frame
{
    IplImage *texImage = cvCreateImage(cvSize(320, 240), IPL_DEPTH_8U, 3);
    cvCopy(frame, texImage, 0);
    
    //Default number of iterations is 1. We'll do a few iterations to make the effect more pronounced.
    cvErode(texImage, texImage, NULL, 3);
    
    return texImage;
}

/*!
 * @function dilate
 * @discussion Perform image dilation. Dilation computes a local maximum over the area of the kernel. Used to find connected components.
 * @updated 2009-1-22
 */
+ (IplImage *) dilate:(IplImage *)frame
{
    IplImage *texImage = cvCreateImage(cvSize(320, 240), IPL_DEPTH_8U, 3);
    cvCopy(frame, texImage, 0);
    
    //Default number of iterations is 1. We'll do a few iterations to make the effect more pronounced.
    cvDilate(texImage, texImage, NULL, 3);
    
    return texImage;
}

/*!
 * @function open
 * @discussion Perform image opening with a custom kernel.
 * @updated 2009-1-22
 */
+ (IplImage *) open:(IplImage *)frame
{
    IplImage *texImage = cvCreateImage(cvSize(320, 240), IPL_DEPTH_8U, 3);
    cvCopy(frame, texImage, 0);
    
    IplConvKernel* openKernel = cvCreateStructuringElementEx(3, 3, 1, 1, CV_SHAPE_RECT, NULL);
    
    //Default number of iterations is 1. We'll do a few iterations to make the effect more pronounced.
    cvMorphologyEx(texImage, texImage, NULL, (IplConvKernel *)openKernel, CV_MOP_OPEN, 3);
    
    return texImage;
}

/*!
 * @function close
 * @discussion Perform image closing with a custom kernel.
 * @updated 2009-1-22
 */
+ (IplImage *) close:(IplImage *)frame
{
    IplImage *texImage = cvCreateImage(cvSize(320, 240), IPL_DEPTH_8U, 3);
    cvCopy(frame, texImage, 0);
    
    IplConvKernel* closeKernel = cvCreateStructuringElementEx(7, 7, 3, 3, CV_SHAPE_RECT, NULL);
    
    //Default number of iterations is 1. We'll do a few iterations to make the effect more pronounced.
    cvMorphologyEx(texImage, texImage, NULL, (IplConvKernel *)closeKernel, CV_MOP_CLOSE, 3);
    
    return texImage;
}

/*!
 * @function adaptiveThresh
 * @discussion Perform adaptive thresholding.
 * @updated 2009-1-22
 */
+ (IplImage *) adaptiveThresh:(IplImage *)frame
{
    IplImage *grayTex = cvCreateImage(cvSize(320, 240), IPL_DEPTH_8U, 1);
    IplImage *grayTemp = cvCreateImage(cvSize(320, 240), IPL_DEPTH_8U, 1);
    
    cvCvtColor(frame, grayTex, CV_RGB2GRAY);
    
    int type =  CV_THRESH_BINARY;           //CV_THRESH_BINARY_INV; 
    int method = CV_ADAPTIVE_THRESH_MEAN_C; //CV_ADAPTIVE_THRESH_GAUSSIAN_C; 
    
    int blockSize = 73; 
    double offset = 15; 
    
    cvAdaptiveThreshold(grayTex, grayTemp, 255, method, type, blockSize, offset); 
    
    IplImage *result = cvCreateImage(cvSize(320, 240), IPL_DEPTH_8U, 3);
    cvCvtColor(grayTemp, result, CV_GRAY2RGB);
    
    cvReleaseImage(&grayTex);
    cvReleaseImage(&grayTemp);
    
    return result;
}

/*!
 * @function meanShift
 * @discussion Perform mean-shift segmentation.
 * @updated 2009-1-22
 */
+ (IplImage *) meanShift:(IplImage *)frame
{
    IplImage *result = cvCreateImage(cvSize(320, 240), IPL_DEPTH_8U, 3);
    
    CvTermCriteria criteria = cvTermCriteria(CV_TERMCRIT_ITER | CV_TERMCRIT_EPS, 5, 1); 
    
    //Increasing the spatialRadius costs a lot in terms of performance.
    cvPyrMeanShiftFiltering(frame, result, 5, 40, 2, criteria);
    
    return result;
}

/*!
 * @function findSquares
 * @discussion Find squares. Modified version of the 'squres.c' OpenCV example program.
 * @updated 2008-12-23
 */
+ (IplImage *) findSquares:(IplImage *)img
{
    CvMemStorage* storage = cvCreateMemStorage(0);
    
    double s, t;
    int i, c, l, N = 11;
    
    //The minimum area of the squares we want to find.
    int minArea = 500;
    
    CvSeq* contours;
    CvSize sz = cvSize(img->width & -2, img->height & -2);
    IplImage* timg = cvCloneImage(img);
    IplImage* gray = cvCreateImage(sz, IPL_DEPTH_8U, 1); 
    IplImage* pyr = cvCreateImage(cvSize(sz.width/2, sz.height/2), 8, 3 );
    IplImage* tgray;
    CvSeq* result;
    
    // create empty sequence that will contain points -
    // 4 points per square (the square's vertices)
    CvSeq* squares = cvCreateSeq(0, sizeof(CvSeq), sizeof(CvPoint), storage);
    
    // select the maximum ROI in the image
    // with the width and height divisible by 2
    cvSetImageROI(timg, cvRect(0, 0, sz.width, sz.height));
    
    // down-scale and upscale the image to filter out the noise
    cvPyrDown(timg, pyr, 7);
    cvPyrUp(pyr, timg, 7);
    tgray = cvCreateImage(sz, 8, 1);
    
    //Declare some variables
    CvPoint *pt0, *pt1, *pt2;
    double dx1, dy1, dx2, dy2;
    
    // find squares in every color plane of the image
    for(c = 0; c < 3; c++) {
        // extract the c-th color plane
        cvSetImageCOI( timg, c+1);
        cvCopy(timg, tgray, 0);
        
        // try several threshold levels
        for(l = 0; l < N; l++) {
            // hack: use Canny instead of zero threshold level.
            // Canny helps to catch squares with gradient shading   
            if(l == 0) {
                // apply Canny. Take the upper threshold from slider
                // and set the lower to 0 (which forces edges merging) 
                cvCanny(tgray, gray, 0, 250, 5);
                // dilate canny output to remove potential
                // holes between edge segments 
                cvDilate(gray, gray, 0, 1);
            }
            else {
                // apply threshold if l!=0:
                //     tgray(x,y) = gray(x,y) < (l+1)*255/N ? 255 : 0
                cvThreshold(tgray, gray, (l+1)*255/N, 255, CV_THRESH_BINARY);
            }
            
            // find contours and store them all as a list
            cvFindContours(gray, storage, &contours, sizeof(CvContour),
                           CV_RETR_LIST, CV_CHAIN_APPROX_SIMPLE, cvPoint(0,0));
            
            // test each contour
            while(contours) {
                // approximate contour with accuracy proportional
                // to the contour perimeter
                
                double perim = cvContourPerimeter(contours);
                if(perim < 0) {
                    contours = contours->h_next;
                    continue;
                }
                
                result = cvApproxPoly(contours, sizeof(CvContour), storage,
                                      CV_POLY_APPROX_DP, cvContourPerimeter(contours)*0.02, 0);
                
                // square contours should have 4 vertices after approximation
                // relatively large area (to filter out noisy contours)
                // and be convex.
                // Note: absolute value of an area is used because
                // area may be positive or negative - in accordance with the
                // contour orientation
                
                int area = fabs(cvContourArea(result, CV_WHOLE_SEQ));
                int res = cvCheckContourConvexity(result);
                int tot = result->total;
                
                if(tot == 4 && area > minArea && res) {
                    
                    s = 0;
                    
                    for(i = 0; i < 5; i++) {
                        // find minimum angle between joint
                        // edges (maximum of cosine)
                        if(i >= 2) {
                            pt1 = (CvPoint*)cvGetSeqElem(result,i);
                            pt2 = (CvPoint*)cvGetSeqElem(result,i-2);
                            pt0 = (CvPoint*)cvGetSeqElem(result,i-1);
                            
                            dx1 = pt1->x - pt0->x;
                            dy1 = pt1->y - pt0->y;
                            dx2 = pt2->x - pt0->x;
                            dy2 = pt2->y - pt0->y;
                            
                            double ang = (dx1*dx2 + dy1*dy2)/sqrt((dx1*dx1 + dy1*dy1)*(dx2*dx2 + dy2*dy2) + 1e-10);
                            t = fabs(ang);
                            
                            s = s > t ? s : t;
                        }
                    }
                    
                    // if cosines of all angles are small
                    // (all angles are ~90 degree) then write quandrange
                    // vertices to resultant sequence 
                    if(s < 0.3) {
                        for(i = 0; i < 4; i++) {
                            cvSeqPush(squares, (CvPoint*)cvGetSeqElem(result, i ));
                        }
                    }
                }
                
                // take the next contour
                contours = contours->h_next;
            }
        }
    }
    
    cvReleaseImage(&gray);
    cvReleaseImage(&pyr);
    cvReleaseImage(&tgray);
    cvReleaseImage(&timg);
    
    CvSeqReader reader;
    IplImage* cpy = cvCloneImage(img);
    
    // initialize reader of the sequence
    cvStartReadSeq(squares, &reader, 0);
    
    // read 4 sequence elements at a time (all vertices of a square)
    for(i = 0; i < squares->total; i += 4) {
        CvPoint pt[4], *rect = pt;
        int count = 4;
        
        // read 4 vertices
        CV_READ_SEQ_ELEM( pt[0], reader );
        CV_READ_SEQ_ELEM( pt[1], reader );
        CV_READ_SEQ_ELEM( pt[2], reader );
        CV_READ_SEQ_ELEM( pt[3], reader );
        
        // draw the square as a closed polyline 
        cvPolyLine(cpy, &rect, &count, 1, 1, CV_RGB(255,0,0), 2, CV_AA, 0);
    }
    
    cvReleaseMemStorage(&storage);
    
    return cpy;
}

/*!
 * @function noiseFilter
 * @discussion Remove image noise by performing the down- and up- sampling steps of Gaussian pyramid decomposition.
 * @updated 2008-12-25
 */
+ (IplImage *) noiseFilter:(IplImage *)frame
{
    IplImage *texImage = cvCreateImage(cvSize(320, 240), IPL_DEPTH_8U, 3);
    
    CvSize sz = cvSize( frame->width & -2, frame->height & -2 );
    IplImage* timg = cvCloneImage(frame);
    IplImage* pyr = cvCreateImage(cvSize(sz.width/2, sz.height/2), IPL_DEPTH_8U, 3);

    cvPyrDown(timg, pyr, 7);
    cvPyrUp(pyr, texImage, 7);
    
    cvReleaseImage(&pyr);
    cvReleaseImage(&timg);

    return texImage;
}

/*!
 * @function blobDetect
 * @discussion Blob detection.
 * @updated 2008-12-25
 */
+ (IplImage *) blobDetect:(IplImage *)frame
{
    IplImage *texImage = cvCloneImage(frame);
    IplImage *frameTemp = cvCreateImage(cvSize(320, 240), IPL_DEPTH_8U, 1);
    
    CvSize sz = cvSize(frame->width & -2, frame->height & -2);
    cvSetImageCOI(frame, 1);
    IplImage* tgray = cvCreateImage(sz, 8, 1); 
    CvSeq* contour_list = NULL;
    CvMemStorage* contour_storage = cvCreateMemStorage(1000);
    cvCopy(frame, tgray, 0);
    CvContourRetrievalMode  retrieve_mode = CV_RETR_LIST;
    
    
    cvThreshold(tgray, frameTemp, 60, 255, CV_THRESH_BINARY_INV );
    
    cvFindContours(frameTemp, contour_storage, &contour_list,
                   sizeof(CvContour), retrieve_mode, CV_CHAIN_APPROX_SIMPLE, cvPoint(0,0));

    CvSeq* contour_ptr = contour_list;

    int nCvSeqsFound = 0;

    int minArea = 100;
    int maxArea = 340*240/4;

    CvSeq* cvSeqBlobs[150];
    
    while((contour_ptr != NULL)) {
        float area = fabs(cvContourArea(contour_ptr, CV_WHOLE_SEQ));
        
        if( (area > minArea) && (area < maxArea) ) {
            if (nCvSeqsFound < 150) {
                cvSeqBlobs[nCvSeqsFound] = contour_ptr;
                nCvSeqsFound++;
            }
        }
        contour_ptr = contour_ptr->h_next;
    }

    CvMoments* moments = (CvMoments*)malloc(sizeof(CvMoments));
    int i = 0;
    for(i=0; i<nCvSeqsFound; i++) {
        CvRect rect	= cvBoundingRect(cvSeqBlobs[i], 0);
        CvPoint pt[4], *rect2 = pt;
        
        pt[0] = cvPoint(rect.x,rect.y);
        pt[1] = cvPoint(rect.x + rect.width,rect.y);
        pt[2] = cvPoint(rect.x + rect.width,rect.y+rect.height);
        pt[3] = cvPoint(rect.x,rect.y+rect.height);

        int count = 4;
        cvPolyLine( texImage, &rect2, &count, 1, 1, CV_RGB(0,0,255), 1, CV_AA, 0 );
    }
    
    free(moments);
    cvReleaseImage(&tgray);
    cvReleaseImage(&frameTemp);
    
    return texImage;
}

/*!
 * @function cannyTest
 * @discussion Canny edge detection.
 * @updated 2008-12-25
 */
+ (IplImage *) cannyTest:(IplImage *)frame
{
    IplImage *texImage = cvCreateImage(cvSize(320, 240), IPL_DEPTH_8U, 3);
    
    CvSize sz = cvSize(frame->width & -2, frame->height & -2);
    IplImage* timg = cvCloneImage(frame);
    IplImage* gray = cvCreateImage(sz, IPL_DEPTH_8U, 1); 
    IplImage* tgray =  cvCreateImage(sz, IPL_DEPTH_8U, 1);
    
    cvSetImageCOI(frame, 1);
    
    cvCopy(frame, tgray, 0);
    cvCanny(tgray, gray, 0, 5, 5);
    
    cvDilate(gray, gray, 0, 1);

    cvCvtColor(gray, texImage, CV_GRAY2RGB);

    cvReleaseImage(&gray);
    cvReleaseImage(&tgray);
    cvReleaseImage(&timg);
    
    return texImage;
}

/*!
 * @function houghLinesProbabilistic
 * @discussion Find lines in a binary image using the probabilistic Hough transform example from the OpenCV documentation.
 * @updated 2008-12-25
 */
+ (IplImage *) houghLinesProbabilistic:(IplImage *)frame
{
    CvSize sz = cvGetSize(frame);
    
    IplImage* tgray =  cvCreateImage(sz, IPL_DEPTH_8U, 1);
    IplImage* dst = cvCreateImage(sz, IPL_DEPTH_8U, 1);
    IplImage* color_dst = cvCreateImage(sz, IPL_DEPTH_8U, 3);
    CvMemStorage* storage = cvCreateMemStorage(0);
    
    cvCvtColor(frame, tgray, CV_RGB2GRAY);
    
    cvCanny(tgray, dst, 50, 200, 3);
    cvCvtColor( dst, color_dst, CV_GRAY2BGR );
    
    CvSeq* lines = cvHoughLines2(dst, storage, CV_HOUGH_PROBABILISTIC, 1, CV_PI/180, 50, 50, 10);
    
    int i;
    for(i = 0; i < lines->total; i++) {
        CvPoint* line = (CvPoint*)cvGetSeqElem(lines,i);
        cvLine( color_dst, line[0], line[1], CV_RGB(255,0,0), 1, CV_AA, 0);
    }
    
    cvReleaseImage(&dst);
    cvReleaseImage(&tgray);
    cvReleaseMemStorage(&storage);
    
    return color_dst;
}

/*!
 * @function houghLinesStandard
 * @discussion Find lines in a binary image using the Hough transform example from the OpenCV documentation.
 * @updated 2008-12-25
 */
+ (IplImage *) houghLinesStandard:(IplImage *)frame
{
    CvSize sz = cvGetSize(frame);
    
    IplImage* tgray =  cvCreateImage(sz, IPL_DEPTH_8U, 1);
    IplImage* dst = cvCreateImage(sz, IPL_DEPTH_8U, 1);
    IplImage* color_dst = cvCreateImage(sz, IPL_DEPTH_8U, 3);
    CvMemStorage* storage = cvCreateMemStorage(0);
    
    cvCvtColor(frame, tgray, CV_RGB2GRAY);
    
    cvCanny(tgray, dst, 50, 200, 3);
    cvCvtColor(dst, color_dst, CV_GRAY2BGR);
    CvSeq* lines = cvHoughLines2(dst, storage, CV_HOUGH_STANDARD, 1, CV_PI/180, 100, 0, 0);
    
    int i;
    for(i = 0; i < MIN(lines->total,100); i++) {
        float* line = (float*)cvGetSeqElem(lines,i);
        float rho = line[0];
        float theta = line[1];
        CvPoint pt1, pt2;
        double a = cos(theta), b = sin(theta);
        double x0 = a*rho, y0 = b*rho;
        pt1.x = cvRound(x0 + 1000*(-b));
        pt1.y = cvRound(y0 + 1000*(a));
        pt2.x = cvRound(x0 - 1000*(-b));
        pt2.y = cvRound(y0 - 1000*(a));
        cvLine(color_dst, pt1, pt2, CV_RGB(255,0,0), 1, CV_AA, 0);
    }
    
    cvReleaseImage(&dst);
    cvReleaseImage(&tgray);
    cvReleaseMemStorage(&storage);
    
    return color_dst;
}


/*!
 * @function houghCircles
 * @discussion Find circles in a binary image using the Hough transform example from the OpenCV documentation.
 * @updated 2008-12-25
 */
+ (IplImage *) houghCircles:(IplImage *)frame
{
    CvSize sz = cvGetSize(frame);
    
    IplImage *texImage = cvCreateImage(sz, IPL_DEPTH_8U, 3);
    
    cvCopy(frame, texImage, 0);
    
    IplImage* gray = cvCreateImage(cvGetSize(frame), IPL_DEPTH_8U, 1);
    CvMemStorage* storage = cvCreateMemStorage(0);
    cvCvtColor(frame, gray, CV_BGR2GRAY);
    cvSmooth(gray, gray, CV_GAUSSIAN, 9, 9, 0, 0); // smooth it, otherwise a lot of false circles may be detected
    CvSeq* circles = cvHoughCircles(gray, storage, CV_HOUGH_GRADIENT, 2, gray->height/4, 200, 100, 0, 1000);
    int i;
    for( i = 0; i < circles->total; i++ )
    {
        float* p = (float*)cvGetSeqElem( circles, i );
        cvCircle(texImage, cvPoint(cvRound(p[0]),cvRound(p[1])), 3, CV_RGB(0,255,0), -1, 8, 0);
        cvCircle(texImage, cvPoint(cvRound(p[0]),cvRound(p[1])), cvRound(p[2]), CV_RGB(255,0,0), 3, 8, 0);
    }

    //cvReleaseImage(&dst);
    cvReleaseImage(&gray);
    cvReleaseMemStorage(&storage);
    
    return texImage;
}

/*!
 * @function opticalFlowLK
 * @discussion Optical flow using the Lucas & Kanade Technique.
 * @updated 2008-12-28
 */
+ (IplImage *) opticalFlowLK:(IplImage *)frame
{
    static IplImage *prevFrame = 0;
    
    CvSize sz = cvGetSize(frame);
    
    IplImage *grayflow = cvCreateImage(sz, IPL_DEPTH_8U, 1);
    IplImage *flow = cvCreateImage(sz, IPL_DEPTH_8U, 3);
    
    if(prevFrame == 0) {
        IplImage *prevFrameAlloc = cvCreateImage(sz, IPL_DEPTH_8U, 3);
        cvCopy(frame, prevFrameAlloc, 0);
        prevFrame = prevFrameAlloc;
    }
    
    CvSize window = cvSize(9,9);
    
    IplImage *grayCur = cvCreateImage(sz, IPL_DEPTH_8U, 1);
    IplImage *grayPrev = cvCreateImage(sz, IPL_DEPTH_8U, 1);
    
    cvCvtColor(frame, grayCur, CV_RGB2GRAY);
    cvCvtColor(prevFrame, grayPrev, CV_RGB2GRAY);
    
    IplImage *velXImage = cvCreateImage(sz, IPL_DEPTH_32F, 1);
    IplImage *velYImage = cvCreateImage(sz, IPL_DEPTH_32F, 1);
    
    cvCalcOpticalFlowLK(grayCur, grayPrev, window, velXImage, velYImage);
    
    cvConvertScale(velXImage, grayflow, 4, 0);
    cvCvtColor(grayflow, flow, CV_GRAY2RGB);
    
    cvReleaseImage(&velXImage);
    cvReleaseImage(&velYImage);
    cvReleaseImage(&grayCur);
    cvReleaseImage(&grayPrev);
    cvReleaseImage(&prevFrame);
    cvReleaseImage(&grayflow);
    
    IplImage *prevFrameAlloc = cvCreateImage(sz, IPL_DEPTH_8U, 3);
    cvCopy(frame, prevFrameAlloc, 0);
    prevFrame = prevFrameAlloc;
    
    return flow;
    //return [OpenCVProcessor blobDetect:flow];
}

/*!
 * @function opticalFlowPyrLK
 * @discussion Optical flow using the iterative Lucas & Kanade Technique in pyramids.
 * @updated 2008-12-28
 */
+ (IplImage *) opticalFlowPyrLK:(IplImage *)frame
{
    static IplImage *prevFrame = 0;
    
    CvSize sz = cvGetSize(frame);
    
    IplImage *grayflow = cvCreateImage(sz, IPL_DEPTH_8U, 1);
    IplImage *flow = cvCreateImage(sz, IPL_DEPTH_8U, 3);
    cvCopy(frame, flow, 0);
    
    if(prevFrame == 0) {
        IplImage *prevFrameAlloc = cvCreateImage(sz, IPL_DEPTH_8U, 3);
        cvCopy(frame, prevFrameAlloc, 0);
        prevFrame = prevFrameAlloc;
    }
    
    CvSize window = cvSize(4,4);
    
    IplImage *grayCur = cvCreateImage(sz, IPL_DEPTH_8U, 1);
    IplImage *grayPrev = cvCreateImage(sz, IPL_DEPTH_8U, 1);
    
    cvCvtColor(frame, grayCur, CV_RGB2GRAY);
    cvCvtColor(prevFrame, grayPrev, CV_RGB2GRAY);
    
    int step = 7;
    int numFeatures = step * step;
    
    CvPoint2D32f cvsrc[numFeatures];
    CvPoint2D32f cvdst[numFeatures];
    
    //We don't really need to compute this each time. Should only need do it once.
    int i, j;
    for(i=0; i<step; i++) {
      for(j=0; j<step; j++) {
          cvsrc[i*step + j].x = 40 + j * 40;
          cvsrc[i*step + j].y = 30 + 30 * i;
      }
    }

    char status[numFeatures];
    CvTermCriteria term = cvTermCriteria(CV_TERMCRIT_ITER | CV_TERMCRIT_EPS, 20, .3);
    
    cvCalcOpticalFlowPyrLK(grayCur, grayPrev, 0, 0, cvsrc, cvdst, numFeatures, window, 1, status, 0, term, 0);

    //Arrow drawing from David Stavens' document "The OpenCV Library: Computing Optical Flow".
    // http://robots.stanford.edu/cs223b05/notes/
    for(i = 0; i < numFeatures; i++)
    {
        if (status[i] == 0) continue;
        
        int line_thickness = 1;

        CvScalar line_color; line_color = CV_RGB(0,0,255);

        CvPoint p,q;
        p.x = (int) cvsrc[i].x;
        p.y = (int) cvsrc[i].y;
        q.x = (int) cvdst[i].x;
        q.y = (int) cvdst[i].y;
        
        double angle; angle = atan2((double) p.y - q.y, (double) p.x - q.x);
        double hypotenuse; hypotenuse = sqrt((p.y - q.y)*(p.y - q.y) + (p.x - q.x)*(p.x - q.x));

        q.x = (int) (p.x - 0.5 * hypotenuse * cos(angle));
        q.y = (int) (p.y - 0.5 * hypotenuse * sin(angle));

        cvLine(flow, p, q, line_color, line_thickness, CV_AA, 0);

        p.x = (int) (q.x + 4.5 * cos(angle + pi / 4));
        p.y = (int) (q.y + 4.5 * sin(angle + pi / 4));
        cvLine(flow, p, q, line_color, line_thickness, CV_AA, 0);
        p.x = (int) (q.x + 4.5 * cos(angle - pi / 4));
        p.y = (int) (q.y + 4.5 * sin(angle - pi / 4));
        cvLine(flow, p, q, line_color, line_thickness, CV_AA, 0);
    }
        
    cvReleaseImage(&grayCur);
    cvReleaseImage(&grayPrev);
    cvReleaseImage(&prevFrame);
    cvReleaseImage(&grayflow);
    
    IplImage *prevFrameAlloc = cvCreateImage(sz, IPL_DEPTH_8U, 3);
    cvCopy(frame, prevFrameAlloc, 0);
    prevFrame = prevFrameAlloc;
    
    return flow;
}

/*!
 * @function opticalFlowBM
 * @discussion Optical flow using block matching.
 * @updated 2009-1-1
 */
+ (IplImage *) opticalFlowBM:(IplImage *)frame
{
    static IplImage *prevFrame = 0;
    
    CvSize sz = cvGetSize(frame);
    
    IplImage *grayflow = cvCreateImage(sz, IPL_DEPTH_8U, 1);
    IplImage *flow = cvCreateImage(sz, IPL_DEPTH_8U, 3);
    
    if(prevFrame == 0) {
        IplImage *prevFrameAlloc = cvCreateImage(sz, IPL_DEPTH_8U, 3);
        cvCopy(frame, prevFrameAlloc, 0);
        prevFrame = prevFrameAlloc;
    }
    
    //Note: window.width must be a common divisor of 320 and 240.
    CvSize window = cvSize(8, 8);
    CvSize shift = cvSize(4, 4);
    CvSize range = cvSize(6, 6);
    
    IplImage *grayCur = cvCreateImage(sz, IPL_DEPTH_8U, 1);
    IplImage *grayPrev = cvCreateImage(sz, IPL_DEPTH_8U, 1);
    
    cvCvtColor(frame, grayCur, CV_RGB2GRAY);
    cvCvtColor(prevFrame, grayPrev, CV_RGB2GRAY);
    
    IplImage *velXImage = cvCreateImage(cvSize(320/window.width, 240/window.width), IPL_DEPTH_32F, 1);
    IplImage *velYImage = cvCreateImage(cvSize(320/window.width, 240/window.width), IPL_DEPTH_32F, 1);
    IplImage *tmp = cvCreateImage(sz, IPL_DEPTH_32F, 1);
    
    cvCalcOpticalFlowBM(grayCur, grayPrev, window, shift, range, 0, velXImage, velYImage);
    
    cvResize(velYImage, tmp, CV_INTER_NN);
    cvConvertScale(tmp, grayflow, 8, 0);
    cvCvtColor(grayflow, flow, CV_GRAY2RGB);
    
    cvReleaseImage(&velXImage);
    cvReleaseImage(&velYImage);
    cvReleaseImage(&grayCur);
    cvReleaseImage(&grayPrev);
    cvReleaseImage(&prevFrame);
    cvReleaseImage(&grayflow);
    cvReleaseImage(&tmp);
    
    IplImage *prevFrameAlloc = cvCreateImage(sz, IPL_DEPTH_8U, 3);
    cvCopy(frame, prevFrameAlloc, 0);
    prevFrame = prevFrameAlloc;
    
    return flow;
}


/*!
 * @function motion
 * @discussion Motion tracking taken from the OpenCV examples (motempl.c)
 * @updated 2008-12-31
 */
+ (IplImage *) motion:(IplImage *)img
{
    static const int diff_threshold = 30;
    
    //The result image.
    IplImage *dst = cvCreateImage(cvSize(320, 240), IPL_DEPTH_8U, 3);
    
    //Various tracking parameters (in seconds)
    static const double MHI_DURATION = 1;
    static const double MAX_TIME_DELTA = 0.5;
    static const double MIN_TIME_DELTA = 0.05;
    
    //Number of cyclic frame buffer used for motion detection 
    //  (should, probably, depend on FPS)
    static const int N = 4;
    
    //Ting image buffer
    static IplImage **buf = 0;
    static int last = 0;
    
    //Temporary images
    static IplImage *mhi = 0; 
    static IplImage *orient = 0;
    static IplImage *mask = 0;
    static IplImage *segmask = 0;
    static CvMemStorage* storage = 0;
    
    //Get current time in seconds
    double timestamp = (double)clock()/CLOCKS_PER_SEC; 
    
    //Get current frame size
    CvSize size = cvSize(img->width,img->height);
    
    int i, idx1 = last, idx2;
    IplImage* silh;
    CvSeq* seq;
    CvRect comp_rect;
    double count;
    double angle;
    CvPoint center;
    double magnitude;          
    CvScalar color;
    
    // allocate images at the beginning or
    // reallocate them if the frame size is changed
    if(!mhi || mhi->width != size.width || mhi->height != size.height) {
        if(buf == 0) {
            buf = (IplImage**)malloc(N*sizeof(buf[0]));
            memset(buf, 0, N*sizeof(buf[0]));
        }
        
        for( i = 0; i < N; i++ ) {
            cvReleaseImage(&buf[i]);
            buf[i] = cvCreateImage(size, IPL_DEPTH_8U, 1);
            cvZero(buf[i]);
        }
        cvReleaseImage(&mhi);
        cvReleaseImage(&orient);
        cvReleaseImage(&segmask);
        cvReleaseImage(&mask);
        
        mhi = cvCreateImage(size, IPL_DEPTH_32F, 1);
        cvZero(mhi);
        orient = cvCreateImage(size, IPL_DEPTH_32F, 1);
        segmask = cvCreateImage(size, IPL_DEPTH_32F, 1);
        mask = cvCreateImage(size, IPL_DEPTH_8U, 1);
    }
    
    cvCvtColor(img, buf[last], CV_BGR2GRAY); 
    
    idx2 = (last + 1) % N; 
    last = idx2;
    
    silh = buf[idx2];
    
    //Get difference between frames
    cvAbsDiff(buf[idx1], buf[idx2], silh);
    
    cvThreshold(silh, silh, diff_threshold, 1, CV_THRESH_BINARY);
    cvUpdateMotionHistory(silh, mhi, timestamp, MHI_DURATION);
    
    cvCvtScale(mhi, mask, 255./MHI_DURATION, (MHI_DURATION - timestamp)*255./MHI_DURATION);
    cvZero(dst);
    cvCvtPlaneToPix(mask, 0, 0, 0, dst);
    
    //Calculate motion gradient orientation and valid orientation mask
    cvCalcMotionGradient(mhi, mask, orient, MAX_TIME_DELTA, MIN_TIME_DELTA, 3);
    
    if(!storage) {
        storage = cvCreateMemStorage(0);
    }
    else {
        cvClearMemStorage(storage);
    }
    
    //Segment motion: get sequence of motion components
    //  segmask is marked motion components map. It is not used further
    seq = cvSegmentMotion(mhi, segmask, storage, timestamp, MAX_TIME_DELTA);
    
    //Iterate through the motion components,
    //  One more iteration (i == -1) corresponds to the whole image (global motion)
    for(i = -1; i < seq->total; i++) {
        
        if(i < 0) {
            comp_rect = cvRect(0, 0, size.width, size.height);
            color = CV_RGB(255,255,255);
            magnitude = 100;
        } else {
            comp_rect = ((CvConnectedComp*)cvGetSeqElem(seq, i ))->rect;
            if(comp_rect.width + comp_rect.height < 100) {
                continue;
            }
            color = CV_RGB(255,0,0);
            magnitude = 30;
        }
        
        //Select component ROI
        cvSetImageROI(silh, comp_rect);
        cvSetImageROI(mhi, comp_rect);
        cvSetImageROI(orient, comp_rect);
        cvSetImageROI(mask, comp_rect);
        
        //Calculate orientation
        angle = cvCalcGlobalOrientation(orient, mask, mhi, timestamp, MHI_DURATION);
        
        //Adjust for images with top-left origin
        angle = 360.0 - angle;
        
        //Calculate number of points within silhouette ROI
        count = cvNorm(silh, 0, CV_L1, 0);
        
        cvResetImageROI(mhi);
        cvResetImageROI(orient);
        cvResetImageROI(mask);
        cvResetImageROI(silh);
        
        //Check for the case of little motion
        if(count < comp_rect.width*comp_rect.height * 0.05) {
            continue;
        }
        
        //Draw a clock with arrow indicating the direction
        center = cvPoint((comp_rect.x + comp_rect.width/2),
                         (comp_rect.y + comp_rect.height/2));
        
        cvCircle(dst, center, cvRound(magnitude*1.2), color, 3, CV_AA, 0);
        cvLine(dst, center, cvPoint(cvRound( center.x + magnitude*cos(angle*CV_PI/180)),
                                    cvRound( center.y - magnitude*sin(angle*CV_PI/180))), color, 3, CV_AA, 0);
    }
    
    return dst;
}

/*!
 * @function hueSatHistogram
 * @discussion Calculate the hue saturation histogram of an image. From the O'Reilly book "Learning OpenCV".
 * @updated 2009-1-14
 */
+ (IplImage *) hueSatHistogram:(IplImage *)frame
{
    CvSize sz = cvGetSize(frame);
    
    // Compute the HSV image and decompose it into separate planes.
    IplImage* hsv = cvCreateImage( sz, IPL_DEPTH_8U, 3 ); 
    cvCvtColor(frame, hsv, CV_BGR2HSV ); 
    IplImage* h_plane  = cvCreateImage( sz, IPL_DEPTH_8U, 1 ); 
    IplImage* s_plane  = cvCreateImage( sz, IPL_DEPTH_8U, 1 ); 
    IplImage* v_plane  = cvCreateImage( sz, IPL_DEPTH_8U, 1 ); 
    IplImage* planes[] = { h_plane, s_plane }; 
    cvCvtPixToPlane( hsv, h_plane, s_plane, v_plane, 0 ); 
    
    // Build the histogram and compute its contents. 
    int h_bins = 30, s_bins = 32; 
    CvHistogram* hist; 
    
    int    hist_size[] = { h_bins, s_bins }; 
    float  h_ranges[]  = { 0, 180 }; // hue is [0,180] 
    float  s_ranges[]  = { 0, 255 }; 
    float* ranges[]    = { h_ranges, s_ranges }; 
    hist = cvCreateHist(2,hist_size, CV_HIST_ARRAY, ranges, 1); 
     
    cvCalcHist( planes, hist, 0, 0 ); //Compute histogram 
    cvNormalizeHist( hist, 1.0 );     //Normalize it
    
    // Create an image to use to visualize our histogram. 
    int scale = 10; 
    IplImage* hist_img = cvCreateImage(cvSize( h_bins * scale, s_bins * scale ), IPL_DEPTH_8U, 3); 
    cvZero( hist_img ); 
    
    // populate our visualization with little gray squares. 
    float max_value = 0; 
    cvGetMinMaxHistValue( hist, 0, &max_value, 0, 0 );
    
    int h, s;
    for( h = 0; h < h_bins; h++ ) { 
        for( s = 0; s < s_bins; s++ ) {
            float bin_val = cvQueryHistValue_2D( hist, h, s ); 
            int intensity = cvRound( bin_val * 255 / max_value ); 
            cvRectangle(hist_img, cvPoint( h*scale, s*scale ), cvPoint( (h+1)*scale - 1, (s+1)*scale - 1), 
                        CV_RGB(intensity,intensity,intensity), 
                        CV_FILLED, 8, 0); 
        } 
    } 
    
    cvReleaseImage(&hsv);
    cvReleaseImage(&h_plane);
    cvReleaseImage(&s_plane);
    cvReleaseImage(&v_plane);
    
    return hist_img;
}

/*!
 * @function backProject
 * @discussion Determine how well the pixels in the incoming image match to an existing histogram.
 * @updated 2009-1-14
 */
+ (IplImage *) backProject:(IplImage *)frame
{
    static CvHistogram* hist = 0;
    
    if(hist == 0 || [CVOCVController bgUpdated]) {
        //Try to grab the saved frame as a reference point. 
        // If an image has not yet been taken, just retun the input image.
        IplImage *bgImage = [CVOCVController capturedImage];
        
        if(!bgImage) {
            IplImage *texImage = cvCreateImage(cvSize(320, 240), IPL_DEPTH_8U, 3);
            cvCopy(frame, texImage, 0);
            return texImage;
        } else {
            
            [CVOCVController setViewed];
            
            //Calculate a histogram of the background image.
            CvSize sz = cvGetSize(bgImage);
            
            // Compute the HSV image and decompose it into separate planes.
            IplImage* hsv = cvCreateImage(sz, IPL_DEPTH_8U, 3); 
            cvCvtColor(bgImage, hsv, CV_BGR2HSV); 
            IplImage* h_plane  = cvCreateImage(sz, IPL_DEPTH_8U, 1); 
            IplImage* s_plane  = cvCreateImage(sz, IPL_DEPTH_8U, 1); 
            IplImage* v_plane  = cvCreateImage(sz, IPL_DEPTH_8U, 1); 
            IplImage* planes[] = { h_plane, s_plane }; 
            cvCvtPixToPlane(hsv, h_plane, s_plane, v_plane, 0); 
            
            // Build the histogram and compute its contents. 
            int h_bins = 30, s_bins = 32; 

            int    hist_size[] = { h_bins, s_bins }; 
            float  h_ranges[]  = { 0, 180 }; // hue is [0,180] 
            float  s_ranges[]  = { 0, 255 }; 
            float* ranges[]    = { h_ranges, s_ranges }; 
            hist = cvCreateHist(2, hist_size, CV_HIST_ARRAY, ranges, 1); 
            
            cvCalcHist(planes, hist, 0, 0); //Compute histogram
            
            //Since we're using byte images here, don't normalize the histogram.
            //cvNormalizeHist(hist, 1.0); 
            
            //Clean up our mess.
            cvReleaseImage(&hsv);
            cvReleaseImage(&h_plane);
            cvReleaseImage(&s_plane);
            cvReleaseImage(&v_plane);
        }
    }
    
    //OK, so we have our histogram taken from the background image.
    assert(hist);
    
    //Now, we use this histogram to compare what we've got in the incoming image.
    CvSize sz = cvGetSize(frame);
    
    // Compute the HSV image and decompose it into separate planes.
    IplImage* hsv = cvCreateImage(sz, IPL_DEPTH_8U, 3); 
    cvCvtColor(frame, hsv, CV_BGR2HSV); 
    IplImage* h_plane  = cvCreateImage(sz, IPL_DEPTH_8U, 1); 
    IplImage* s_plane  = cvCreateImage(sz, IPL_DEPTH_8U, 1); 
    IplImage* v_plane  = cvCreateImage(sz, IPL_DEPTH_8U, 1); 
    IplImage* planes[] = { h_plane, s_plane }; 
    cvCvtPixToPlane(hsv, h_plane, s_plane, v_plane, 0);
    
    IplImage* backProjectionGray = cvCreateImage(sz, IPL_DEPTH_8U, 1);
    IplImage* backProjectionUp = cvCreateImage(sz, IPL_DEPTH_8U, 1);
    IplImage* backProjection = cvCreateImage(sz, IPL_DEPTH_8U, 3);
    
    cvCalcBackProject(planes, backProjectionGray, hist);

    cvConvertScale(backProjectionGray, backProjectionUp, 1, 0);
    cvCvtColor(backProjectionUp, backProjection, CV_GRAY2RGB);
    
    cvReleaseImage(&backProjectionGray);
    cvReleaseImage(&backProjectionUp);
    cvReleaseImage(&hsv);
    cvReleaseImage(&h_plane);
    cvReleaseImage(&s_plane);
    cvReleaseImage(&v_plane);
    
    return backProjection;
}

@end
