//
//  RecordViewController.m
//  TouchToRecord
//
//  Created by Cory on 2015-01-12.
//
//

#import "RecordViewController.h"
#import <QuartzCore/QuartzCore.h>

@interface RecordViewController ()

@end

@implementation RecordViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.view.backgroundColor = [UIColor blackColor];
    
    [self initializeCamera];
    
    self.clipCollection = [[NSMutableArray alloc] init];
    
    self.progressBar = [[UIView alloc] initWithFrame:CGRectMake(0, self.view.frame.size.width, 0, 75)];
    self.progressBar.backgroundColor = [UIColor colorWithRed:255.0/255.0 green:220.0/255.0 blue:93.0/255.0 alpha:1];
    [self.view addSubview:self.progressBar];
    
    self.maximumTimeLimit = 6; //the maximum time limit in seconds
    self.minimumTimeLimit = 3; //the minimum time required for a video
    
    UIView *tapView = [[UIView alloc] initWithFrame:self.view.frame];
    [self.view addSubview:tapView];
    
    UILongPressGestureRecognizer *longPressGesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleTouch:)];
    longPressGesture.minimumPressDuration = 0.0001;
    [tapView addGestureRecognizer:longPressGesture];
    
    self.xButton = [UIButton  buttonWithType:UIButtonTypeCustom];
    self.xButton.frame = CGRectMake(0, self.progressBar.frame.origin.y + self.progressBar.frame.size.height + 10, 150, 40);
    [self.xButton setTitle:@"Clear" forState:UIControlStateNormal];
    [self.xButton sizeToFit];
    self.xButton.center = CGPointMake(self.view.frame.size.width/2, self.xButton.center.y);
    [self.xButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self.xButton addTarget:self action:@selector(clearVideo) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.xButton];
    
    self.switchCameraButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.switchCameraButton setImage:[UIImage imageNamed:@"camera.png"] forState:UIControlStateNormal];
    [self.switchCameraButton setFrame:CGRectMake(self.view.frame.size.width - 42, 10, 42, 42)];
    [self.switchCameraButton addTarget:self action:@selector(switchCamera) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.switchCameraButton];
}

-(void)switchCamera{
    //Change camera source
    if(session)
    {
        //Indicate that some changes will be made to the session
        [session beginConfiguration];
        
        //Remove existing input. Go through all the current inputs, which includes microphone and one camera. Identify that camera type:
        AVCaptureInput *currentCameraInput;
        for(AVCaptureInput *currentInput in session.inputs){
            if(((AVCaptureDeviceInput*)currentInput).device.position == AVCaptureDevicePositionBack || ((AVCaptureDeviceInput*)currentInput).device.position == AVCaptureDevicePositionFront)
            {
                //Found either the front cam or back cam
                currentCameraInput = currentInput;
            }

        }
        
        [session removeInput:currentCameraInput];
        
        //Get new input
        AVCaptureDevice *newCamera = nil;
        if(((AVCaptureDeviceInput*)currentCameraInput).device.position == AVCaptureDevicePositionBack)
        {
            NSLog(@"selecting front camera");
            newCamera = [self cameraWithPosition:AVCaptureDevicePositionFront];
        }
        else
        {
            NSLog(@"selecting back camera");
            newCamera = [self cameraWithPosition:AVCaptureDevicePositionBack];
        }
        
        //Add input to session
        NSLog(@"trying to add input to session");
        AVCaptureDeviceInput *newVideoInput = [[AVCaptureDeviceInput alloc] initWithDevice:newCamera error:nil];
        [session addInput:newVideoInput];
        
        //Commit all the configuration changes at once
        [session commitConfiguration];
    }
}

// Find a camera with the specified AVCaptureDevicePosition, returning nil if one is not found
- (AVCaptureDevice *) cameraWithPosition:(AVCaptureDevicePosition) position
{
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    for (AVCaptureDevice *device in devices)
    {
        if ([device position] == position){
            NSLog(@"found a device at position");
            return device;
        }
        
    }
    return nil;
}

-(void)timerLoop{
    CGFloat increment = self.view.frame.size.width/self.maximumTimeLimit * 0.05;
    if (self.progressBar.frame.size.width < self.view.frame.size.width) {
        CGFloat percentProgress = self.progressBar.frame.size.width/self.view.frame.size.width;
        CGFloat minimumTimeLimitAsPercentage = self.minimumTimeLimit/self.maximumTimeLimit;
        
        if(percentProgress >= minimumTimeLimitAsPercentage && !self.minimumLimitReached){
            self.minimumLimitReached = YES;
            //Use this flag to set a next/publish button if you want to allow the user to finalize whatever they've recorded.
        }
        
        [UIView animateWithDuration:.05
                         animations:^{
                             
                             self.progressBar.frame = CGRectMake(self.progressBar.frame.origin.x, self.progressBar.frame.origin.y, self.progressBar.frame.size.width + increment, self.progressBar.frame.size.height);
                         }
                         completion:^(BOOL finished){

                         }];
    } else if (self.progressBar.frame.size.width >= self.view.frame.size.width){
        self.maximumLimitReached = YES;
        [self stopRecording];
    }
    
}

-(void)handleTouch:(UILongPressGestureRecognizer *)sender{
    if(sender.state == UIGestureRecognizerStateBegan){
        [self startRecording];
    } else if (sender.state == UIGestureRecognizerStateEnded){
        [self stopRecording];
    }
}

-(void)startRecording{
    if(!self.maximumLimitReached){
        NSTimeInterval timeStamp = [[NSDate date] timeIntervalSince1970];
        NSString *timeStampString = [NSString stringWithFormat:@"%@", [NSNumber numberWithInt:timeStamp]];
        NSURL *tmpDirURL = [NSURL fileURLWithPath:NSTemporaryDirectory() isDirectory:YES];
        NSURL *fileURL = [[tmpDirURL URLByAppendingPathComponent:timeStampString] URLByAppendingPathExtension:@"mov"];
        
        allowRecording = YES;
        [MovieFileOutput startRecordingToOutputFileURL:fileURL recordingDelegate:self];
    }
  
}

-(void)stopRecording{
    allowRecording = NO;
    [MovieFileOutput stopRecording];
    if([self.timer isValid])[self.timer invalidate];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (void)captureOutput:(AVCaptureFileOutput *)captureOutput
didFinishRecordingToOutputFileAtURL:(NSURL *)outputFileURL
      fromConnections:(NSArray *)connections
                error:(NSError *)error
{
    
    BOOL RecordedSuccessfully = YES;
    if ([error code] != noErr)
    {
        // A problem occurred: Find out if the recording was successful.
        id value = [[error userInfo] objectForKey:AVErrorRecordingSuccessfullyFinishedKey];
        if (value)
        {
            RecordedSuccessfully = [value boolValue];
        }
    }
    if (RecordedSuccessfully)
    {
        [self cropVideo:outputFileURL];

        if(self.maximumLimitReached){
            [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        }
    }
}

-(void)cropVideo:(NSURL*)videoURL{
    // input file
    AVAsset* asset = [AVAsset assetWithURL:videoURL];
    
    AVMutableComposition *composition = [AVMutableComposition composition];
    [composition  addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
    
    // input clip
    AVAssetTrack *clipVideoTrack = [[asset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
    
    // make it square
    AVMutableVideoComposition* videoComposition = [AVMutableVideoComposition videoComposition];
    CGSize renderSize =  CGSizeMake(clipVideoTrack.naturalSize.height, clipVideoTrack.naturalSize.height);
    videoComposition.renderSize = renderSize;
    videoComposition.frameDuration = CMTimeMake(1, 60);
    
    AVMutableVideoCompositionInstruction *instruction = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
    instruction.timeRange = CMTimeRangeMake(kCMTimeZero, CMTimeMakeWithSeconds(60, 30) );
    
    // rotate to portrait
    AVMutableVideoCompositionLayerInstruction* transformer = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:clipVideoTrack];
    CGAffineTransform t1 = CGAffineTransformMakeTranslation(clipVideoTrack.naturalSize.height, -(clipVideoTrack.naturalSize.width - clipVideoTrack.naturalSize.height) /2 );
    CGAffineTransform t2 = CGAffineTransformRotate(t1, M_PI_2);
    
    CGAffineTransform finalTransform = t2;
    [transformer setTransform:finalTransform atTime:kCMTimeZero];
    instruction.layerInstructions = [NSArray arrayWithObject:transformer];
    videoComposition.instructions = [NSArray arrayWithObject: instruction];
    
    // export
    AVAssetExportSession *exporter = [[AVAssetExportSession alloc] initWithAsset:asset presetName:AVAssetExportPresetHighestQuality] ;
    exporter.videoComposition = videoComposition;
   
    //Remove any prevouis videos at that path (we'll write new file with same name)
    [[NSFileManager defaultManager]  removeItemAtURL:videoURL error:nil];
    
    exporter.outputURL=videoURL;
    exporter.outputFileType=AVFileTypeQuickTimeMovie;
    
    [exporter exportAsynchronouslyWithCompletionHandler:^(void){
                dispatch_async(dispatch_get_main_queue(), ^{
                    //Call when finished
                    [self exportDidFinish:exporter];
        });
        
    }];
}

-(void)exportDidFinish:(AVAssetExportSession *)exportSession{
    if (exportSession.status == AVAssetExportSessionStatusCompleted) {
        AVAsset *asset = [AVAsset assetWithURL:exportSession.outputURL];
        Float64 assetDuration = CMTimeGetSeconds(asset.duration);
        NSNumber *clipDuration = [NSNumber numberWithFloat:assetDuration];
        NSURL *clipURL = exportSession.outputURL;
        
        NSDictionary *clipDict = [[NSDictionary alloc] initWithObjectsAndKeys:
                                  clipURL, @"url",
                                  clipDuration, @"duration",
                                  nil];
        
        [self.clipCollection addObject:clipDict];
        
        if(self.maximumLimitReached) [self mergeAllVideos];
    }
}

-(void)clearVideo{
    if(![session isRunning])[session startRunning];
    [self stopRecording];
    [avPlayerLayer removeFromSuperlayer];
    [avPlayer pause];
    
    [self.clipCollection removeAllObjects];
    allowRecording = YES;
    self.maximumLimitReached = NO;
    self.progressBar.frame = CGRectMake(self.progressBar.frame.origin.x, self.progressBar.frame.origin.y , 0, self.progressBar.frame.size.height);
}

-(void)mergeAllVideos{
    [session stopRunning];
    // 1 - Create AVMutableComposition object. This object will hold your AVMutableCompositionTrack instances.
    AVMutableComposition *mixComposition = [[AVMutableComposition alloc] init];
    // 2 - Video track
    AVMutableCompositionTrack *videoTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeVideo
                                                                        preferredTrackID:kCMPersistentTrackID_Invalid];
    
    AVMutableCompositionTrack *audioTrack = [mixComposition
                                             addMutableTrackWithMediaType:AVMediaTypeAudio
                                             preferredTrackID:kCMPersistentTrackID_Invalid];
    
    //Go through every asset, add its video and audio to their respective compositionTrack
    CMTime endOfPreviousTrack = kCMTimeZero;
    for(int i = 0; i < self.clipCollection.count; i++){
        NSURL *url = [[self.clipCollection objectAtIndex:i] objectForKey:@"url"];
        AVAsset *asset = [AVAsset assetWithURL:url];
        
        [videoTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, asset.duration) ofTrack:[[asset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0] atTime:endOfPreviousTrack error:nil];
        [audioTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, asset.duration)
                            ofTrack:[[asset tracksWithMediaType:AVMediaTypeAudio] objectAtIndex:0] atTime:endOfPreviousTrack error:nil];
        
        endOfPreviousTrack = CMTimeAdd(endOfPreviousTrack, asset.duration);
    }
    
    
    NSURL *tmpDirURL = [NSURL fileURLWithPath:NSTemporaryDirectory() isDirectory:YES];
    NSURL *fileURL = [[tmpDirURL URLByAppendingPathComponent:@"final"] URLByAppendingPathExtension:@"mov"];
    
    [[NSFileManager defaultManager]  removeItemAtURL:fileURL error:nil];

    // 5 - Create exporter
    AVAssetExportSession *mergeExporter = [[AVAssetExportSession alloc] initWithAsset:mixComposition
                                                                      presetName:AVAssetExportPresetHighestQuality];
    mergeExporter.outputURL=fileURL;
    mergeExporter.outputFileType = AVFileTypeQuickTimeMovie;
    mergeExporter.shouldOptimizeForNetworkUse = YES;
    [mergeExporter exportAsynchronouslyWithCompletionHandler:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            [MBProgressHUD hideHUDForView:self.view animated:YES];

            AVAsset *asset = [AVAsset assetWithURL:mergeExporter.outputURL];
            //NSLog(@"final video length is %f", CMTimeGetSeconds(asset.duration));
            avPlayerItem =[[AVPlayerItem alloc]initWithAsset:asset];
            avPlayer = [[AVPlayer alloc]initWithPlayerItem:avPlayerItem];
            avPlayerLayer =[AVPlayerLayer playerLayerWithPlayer:avPlayer];
            [avPlayerLayer setFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.width)];
            [self.view.layer addSublayer:avPlayerLayer];
            [avPlayer seekToTime:kCMTimeZero];
            
            [[NSNotificationCenter defaultCenter] addObserver:self
                                                     selector:@selector(playerItemDidReachEnd:)
                                                         name:AVPlayerItemDidPlayToEndTimeNotification
                                                       object:[avPlayer currentItem]];
            
            [avPlayer play];
        });
    }];
}

- (void)playerItemDidReachEnd:(NSNotification *)notification {
    [avPlayerItem seekToTime:kCMTimeZero];
    [avPlayer play];
    
}
-(void)initializeCamera{
    //Capture Session
    session = [[AVCaptureSession alloc]init];
    session.sessionPreset = AVCaptureSessionPresetHigh;
    
    //Add device
    AVCaptureDevice *device =
    [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    
    //Video Input
    AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:device error:nil];
    
    if (!input)
    {
        NSLog(@"No Input");
    }
    
    [session addInput:input];
    
    //Audio input:
    AVCaptureDevice *audioDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeAudio];
    AVCaptureDeviceInput * audioInput = [AVCaptureDeviceInput deviceInputWithDevice:audioDevice error:nil];
    [session addInput:audioInput];
    
    //Output
    AVCaptureVideoDataOutput *output = [[AVCaptureVideoDataOutput alloc] init];
    [session addOutput:output];
    output.videoSettings =
    @{ (NSString *)kCVPixelBufferPixelFormatTypeKey : @(kCVPixelFormatType_32BGRA) };
    
    //Preview Layer
    AVCaptureVideoPreviewLayer *previewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:session];
    
    previewLayer.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.width);
    previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    [self.view.layer addSublayer:previewLayer];
    
    
    //ADD MOVIE FILE OUTPUT
    MovieFileOutput = [[AVCaptureMovieFileOutput alloc] init];
    
    //Float64 TotalSeconds = 60;			//Total seconds
    //int32_t preferredTimeScale = 30;	//Frames per second
    
    //CMTime maxDuration = CMTimeMakeWithSeconds(TotalSeconds, preferredTimeScale);	//<<SET MAX DURATION
    //MovieFileOutput.maxRecordedDuration = maxDuration;
    
    //MovieFileOutput.minFreeDiskSpaceLimit = 1024 * 1024;						//<<SET MIN FREE SPACE IN BYTES FOR RECORDING TO CONTINUE ON A VOLUME
    if ([session canAddOutput:MovieFileOutput])
        [session addOutput:MovieFileOutput];
   
    //Start capture session
    [session startRunning];
}


- (void)captureOutput:(AVCaptureFileOutput *)captureOutput
didStartRecordingToOutputFileAtURL:(NSURL *)fileURL
      fromConnections:(NSArray *)connections{
    if(!self.timer.valid && allowRecording){
        self.timer = [NSTimer scheduledTimerWithTimeInterval:0.05 target:self selector:@selector(timerLoop) userInfo:nil repeats:YES];
        [self.timer fire];
    } else {
        [self stopRecording];
    }
}

-(void)dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


@end
