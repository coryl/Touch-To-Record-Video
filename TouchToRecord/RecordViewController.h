//
//  RecordViewController.h
//  TouchToRecord
//
//  Created by Cory on 2015-01-12.
//
//

#import <UIKit/UIKit.h>

#import <Foundation/Foundation.h>
#import <CoreMedia/CoreMedia.h>
#import <AVFoundation/AVFoundation.h>
#import "MBProgressHUD.h"

@interface RecordViewController : UIViewController <AVCaptureFileOutputRecordingDelegate> {
    AVCaptureMovieFileOutput *MovieFileOutput;
    AVPlayerItem *avPlayerItem;
    AVPlayer *avPlayer;
    AVPlayerLayer *avPlayerLayer;
    AVCaptureSession *session;
    BOOL allowRecording;
}

@property NSMutableArray *clipCollection;
@property NSTimer *timer;
@property UIView *progressBar;

@property CGFloat maximumTimeLimit;
@property CGFloat minimumTimeLimit;
@property BOOL maximumLimitReached;
@property BOOL minimumLimitReached;

@property UIButton *xButton;

@end
