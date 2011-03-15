
CVOCV: A CoreVideo-based OpenCV experimentation environment.
------------------------------------------------------------

CVOCV was built in order to create an extremely simple and
lightweight OpenCV experimentation environment for
OS X 10.5.x. Using CoreVideo makes it possible to send
video frames to OpenCV with a minimal amount of computational
overhead.

Usage
-----

At the heart of CVOCV is the 'captureOutput' method found in
CVOCVController.m. This is a callback procedure that is invoked
by CoreVideo to provide direct access to the pixels coming from 
a video input device. To experiment with the existing examples 
offered by CVOCV, simply uncomment one of the lines in the 
captureOutput method.

For example, the line

IplImage *resultImage = [OpenCVProcessor cannyTest:frameImage];

in captureOutput will create an OpenCV-processed image from the
current input frame, and send the pixels to OpenGL to be rendered.

For users that would like to implement their own examples, simply
look at OpenCVProcessor.m for examples.

Reference Images
----------------

Version 0.012 features support for static image referencing. 
See the backProject example for a reference on how to use
the saved background image. Currently, the background image can
be taken as a snapshot from the video stream by hitting the
space bar. Future CVOCV versions will include ROI support and
other OpenCV manipulations on the captured image.

A Note on Cameras
-----------------

If you have multiple cameras connected to your computer, you may
need to change the parameters to the following procedure invocation
in the awakeFromNib procedure in CVOCVController.m:
    
videoDevice = [[QTCaptureDevice inputDevices] objectAtIndex:2];

The index may be different depending on the device you would like 
to select.

You can determine the appropriate device index from the console 
output of the following function:

NSLog(@"Devices found: %@", [QTCaptureDevice inputDevices]);

Contributions
-------------

Contributions in the form of elegant, demonstrative examples are
welcome and encouraged. Contact me if you have something you
think would make a nice addition to this project.

Notes
-----

Thanks to the OpenFrameworks team for providing the compiled OS X
OpenCV library, which is used by CVOCV.

http://openframeworks.cc

-----

2008 Kyle Buza
buza@buzamoto.com

